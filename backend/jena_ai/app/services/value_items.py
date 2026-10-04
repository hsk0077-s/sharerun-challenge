"""휴식일 지정권 and 기부 매칭권.

Prices and caps come from ``config/item_prices``. Purchase and use are
idempotent on ``request_id``. VALUE is spent as honor currency. It is not
converted into SHARE, DIA, or won.

휴식일 지정권: one free use per KST week, not kept as inventory. An extra
ticket costs 50 VALUE and is held until used. The designated day pauses
the streak. It is not a run and it is not a CPR or safeguard cover.

기부 매칭권: 100 VALUE once per user per KST month. The company adds
1,000원 to the run donation pool under the company name, with the user's
name on the row. No receipt and no user money. The company month cap
rejects the request before VALUE is debited.
"""

from datetime import date, datetime, timedelta, timezone

from fastapi import HTTPException
from google.cloud.firestore_v1 import SERVER_TIMESTAMP

from app.models.secured_actions import SecuredActionResult
from app.services.item_price_config import (
    DONATION_MATCH_COMPANY_CAP_ID,
    DONATION_MATCH_ID,
    DONATION_MATCH_USER_MONTHLY_ID,
    DONATION_MATCH_WON_ID,
    ITEM_PRICES_CONFIG_ID,
    REST_DAY_FREE_PER_WEEK_ID,
    REST_DAY_TICKET_ID,
    resolve_item_prices,
)
from app.services.streak_protection import (
    is_rest_pause,
    kst_month_key,
    kst_today,
    kst_week_key,
    metric_qualifies,
    require_request_id,
)

COMPANY_SPONSOR_NAME = "SRC"
DONATION_CHARITY = "UNICEF"
DONATION_LEDGER = "donationLedger"
DONATION_POOLS = "donationPools"


def purchase_value_item(
    service,
    transaction,
    uid: str,
    item_id: str,
    request_id: str,
    user_ref,
    now: datetime | None = None,
) -> SecuredActionResult:
    if item_id == DONATION_MATCH_ID:
        return apply_donation_match(
            service, transaction, uid, request_id, user_ref, now=now
        )
    if item_id != REST_DAY_TICKET_ID:
        raise HTTPException(status_code=404, detail="Shop item not found.")
    return _purchase_rest_day(
        service, transaction, uid, request_id, user_ref, now=now
    )


def use_value_item(
    service,
    transaction,
    uid: str,
    item_id: str,
    request_id: str,
    user_ref,
    rest_day: str | None = None,
    now: datetime | None = None,
) -> SecuredActionResult:
    if item_id == DONATION_MATCH_ID:
        return apply_donation_match(
            service, transaction, uid, request_id, user_ref, now=now
        )
    if item_id != REST_DAY_TICKET_ID:
        raise HTTPException(status_code=404, detail="Shop item not found.")
    return _use_rest_day(
        service,
        transaction,
        uid,
        request_id,
        user_ref,
        rest_day,
        now=now,
    )


def apply_donation_match(
    service,
    transaction,
    uid: str,
    request_id: str,
    user_ref,
    now: datetime | None = None,
) -> SecuredActionResult:
    current = now or datetime.now(timezone.utc)
    request_id = require_request_id(request_id)
    month = kst_month_key(current)
    prices, sponsor = _load_config(service, transaction)
    price = int(prices[DONATION_MATCH_ID])
    won = int(prices[DONATION_MATCH_WON_ID])
    user_cap = int(prices[DONATION_MATCH_USER_MONTHLY_ID])
    company_cap = int(prices[DONATION_MATCH_COMPANY_CAP_ID])

    wallet_ref = _ledger_ref(service, _purchase_doc_id(uid, DONATION_MATCH_ID, request_id))
    donation_ref = _donation_ref(service, f"donation_match_{uid}_{request_id}")
    pool_ref = _pool_ref(service, month)
    already = _exists(wallet_ref, transaction)
    user = _user(user_ref, transaction)
    pool_snap = pool_ref.get(transaction=transaction)
    pool = pool_snap.to_dict() if pool_snap.exists else {}
    if already:
        return _balances_result(user, "already_matched", "Donation match already recorded.")

    if _month_count(user, month) >= user_cap:
        raise HTTPException(status_code=400, detail="Donation match monthly cap reached.")
    total = int(pool.get("totalWon") or 0)
    if total + won > company_cap:
        raise HTTPException(status_code=400, detail="Donation match company cap reached.")

    wallet = user.get("wallet") or {}
    balance = int(wallet.get("valueTokenBalance") or 0)
    if balance < price:
        raise HTTPException(status_code=400, detail="Insufficient Value balance.")

    contributor = _contributor_name(user)
    next_balance = balance - price
    transaction.update(
        user_ref,
        {
            "wallet.valueTokenBalance": next_balance,
            "donationMatchMonth": {"monthKey": month, "count": _month_count(user, month) + 1},
            "updatedAt": SERVER_TIMESTAMP,
        },
    )
    transaction.set(
        pool_ref,
        {
            "monthKey": month,
            "sponsorName": sponsor,
            "totalWon": total + won,
            "capWon": company_cap,
            "updatedAt": SERVER_TIMESTAMP,
        },
    )
    transaction.set(
        wallet_ref,
        {
            "uid": uid,
            "type": "donation_match",
            "itemId": DONATION_MATCH_ID,
            "requestId": request_id,
            "valueAmount": -price,
            "companyWon": won,
            "sponsorName": sponsor,
            "contributorName": contributor,
            "receiptIssued": False,
            "createdAt": SERVER_TIMESTAMP,
        },
    )
    transaction.set(
        donation_ref,
        {
            "uid": uid,
            "type": "donation_match",
            "itemId": DONATION_MATCH_ID,
            "requestId": request_id,
            "monthKey": month,
            "sponsorName": sponsor,
            "donationTarget": DONATION_CHARITY,
            "contributorName": contributor,
            "valueAmount": -price,
            "companyWon": won,
            "receiptIssued": False,
            "createdAt": SERVER_TIMESTAMP,
        },
    )
    share, diamonds, _value = _balances(wallet)
    return SecuredActionResult(
        accepted=True,
        status="matched",
        reason=f"{sponsor} added {won} won for {contributor}.",
        share_balance=share,
        diamond_balance=diamonds,
        value_token_balance=next_balance,
    )


def _purchase_rest_day(
    service,
    transaction,
    uid: str,
    request_id: str,
    user_ref,
    now: datetime | None = None,
) -> SecuredActionResult:
    del now
    request_id = require_request_id(request_id)
    prices, _sponsor = _load_config(service, transaction)
    cost = int(prices[REST_DAY_TICKET_ID])
    catalog = service.SHOP_CATALOG[REST_DAY_TICKET_ID]
    ledger_ref = _ledger_ref(service, _purchase_doc_id(uid, REST_DAY_TICKET_ID, request_id))
    already = _exists(ledger_ref, transaction)
    user = _user(user_ref, transaction)
    inventory_ref = user_ref.collection("shopInventory").document(REST_DAY_TICKET_ID)
    quantity = _quantity(inventory_ref, transaction)
    if already:
        return _balances_result(user, "already_purchased", "Purchase already recorded.")

    wallet = user.get("wallet") or {}
    balance = int(wallet.get("valueTokenBalance") or 0)
    if balance < cost:
        raise HTTPException(status_code=400, detail="Insufficient Value balance.")

    held = quantity + 1
    next_balance = balance - cost
    transaction.update(
        user_ref,
        {
            "wallet.valueTokenBalance": next_balance,
            "updatedAt": SERVER_TIMESTAMP,
        },
    )
    transaction.set(
        inventory_ref,
        {
            "itemId": REST_DAY_TICKET_ID,
            "title": catalog["title"],
            "quantity": held,
            "purchasedAt": SERVER_TIMESTAMP,
        },
        merge=True,
    )
    transaction.set(
        ledger_ref,
        {
            "uid": uid,
            "type": "shop_purchase",
            "itemId": REST_DAY_TICKET_ID,
            "requestId": request_id,
            "valueAmount": -cost,
            "quantityAmount": 1,
            "createdAt": SERVER_TIMESTAMP,
        },
    )
    share, diamonds, _value = _balances(wallet)
    return SecuredActionResult(
        accepted=True,
        status="purchased",
        reason=f"Purchased {catalog['title']}.",
        share_balance=share,
        diamond_balance=diamonds,
        value_token_balance=next_balance,
    )


def _use_rest_day(
    service,
    transaction,
    uid: str,
    request_id: str,
    user_ref,
    rest_day: str | None,
    now: datetime | None = None,
) -> SecuredActionResult:
    current = now or datetime.now(timezone.utc)
    request_id = require_request_id(request_id)
    today = kst_today(current)
    week = kst_week_key(current)
    prices, _sponsor = _load_config(service, transaction)
    free_cap = int(prices[REST_DAY_FREE_PER_WEEK_ID])
    day = _parse_rest_day(rest_day, today)

    ledger_ref = _ledger_ref(service, _use_doc_id(uid, REST_DAY_TICKET_ID, request_id))
    already = _exists(ledger_ref, transaction)
    user = _user(user_ref, transaction)
    inventory_ref = user_ref.collection("shopInventory").document(REST_DAY_TICKET_ID)
    quantity = _quantity(inventory_ref, transaction)
    day_ref = (
        service.firebase_service.db.collection("users")
        .document(uid)
        .collection("daily_metrics")
        .document(day.isoformat())
    )
    day_snap = day_ref.get(transaction=transaction)
    day_data = day_snap.to_dict() if day_snap.exists else {}
    if already:
        return _balances_result(user, "already_used", "Item use already recorded.")
    if metric_qualifies(day_data):
        raise HTTPException(status_code=400, detail="That day already counts.")
    if is_rest_pause(day_data):
        raise HTTPException(status_code=400, detail="That day is already a rest day.")

    used_free = _free_used(user, week)
    free = used_free < free_cap
    if not free and quantity < 1:
        raise HTTPException(status_code=400, detail="No item to use.")

    if free:
        transaction.update(
            user_ref,
            {
                "restDayFreeWeek": {"weekKey": week, "count": used_free + 1},
                "updatedAt": SERVER_TIMESTAMP,
            },
        )
    else:
        transaction.set(inventory_ref, {"quantity": quantity - 1}, merge=True)
    transaction.set(
        day_ref,
        {
            "streakPaused": "rest",
            "pausedAt": SERVER_TIMESTAMP,
            "pausedByRequestId": request_id,
        },
        merge=True,
    )
    transaction.set(
        ledger_ref,
        {
            "uid": uid,
            "type": "shop_item_use",
            "itemId": REST_DAY_TICKET_ID,
            "requestId": request_id,
            "pausedDay": day.isoformat(),
            "freeWeek": free,
            "valueAmount": 0,
            "quantityAmount": 0 if free else -1,
            "createdAt": SERVER_TIMESTAMP,
        },
    )
    return _balances_result(user, "used", "Rest day designated.")


def _load_config(service, transaction) -> tuple[dict[str, int], str]:
    raw = None
    try:
        snapshot = (
            service.firebase_service.db.collection("config")
            .document(ITEM_PRICES_CONFIG_ID)
            .get(transaction=transaction)
        )
        if snapshot.exists:
            raw = snapshot.to_dict()
    except Exception:
        raw = None
    prices = resolve_item_prices(raw if isinstance(raw, dict) else None)
    return prices, _sponsor_name(raw)


def _sponsor_name(raw: object) -> str:
    if not isinstance(raw, dict):
        return COMPANY_SPONSOR_NAME
    name = raw.get("donation_match_sponsor")
    if not isinstance(name, str):
        return COMPANY_SPONSOR_NAME
    text = name.strip()
    if not text or len(text) > 40:
        return COMPANY_SPONSOR_NAME
    return text


def _parse_rest_day(raw: str | None, today: date) -> date:
    text = (raw or "").strip()
    if not text:
        return today
    try:
        day = date.fromisoformat(text)
    except ValueError:
        raise HTTPException(status_code=400, detail="Rest day must be today or yesterday.") from None
    if day not in (today, today - timedelta(days=1)):
        raise HTTPException(status_code=400, detail="Rest day must be today or yesterday.")
    return day


def _free_used(user: dict, week: str) -> int:
    raw = user.get("restDayFreeWeek") or {}
    if not isinstance(raw, dict) or raw.get("weekKey") != week:
        return 0
    return int(raw.get("count") or 0)


def _month_count(user: dict, month: str) -> int:
    raw = user.get("donationMatchMonth") or {}
    if not isinstance(raw, dict) or raw.get("monthKey") != month:
        return 0
    return int(raw.get("count") or 0)


def _contributor_name(user: dict) -> str:
    name = user.get("nickname")
    if not isinstance(name, str) or not name.strip():
        return "회원"
    return name.strip()[:12]


def _purchase_doc_id(uid: str, item_id: str, request_id: str) -> str:
    return f"shop_buy_{uid}_{item_id}_{request_id}"


def _use_doc_id(uid: str, item_id: str, request_id: str) -> str:
    return f"shop_use_{uid}_{item_id}_{request_id}"


def _ledger_ref(service, doc_id: str):
    return service.firebase_service.db.collection("walletTransactions").document(doc_id)


def _donation_ref(service, doc_id: str):
    return service.firebase_service.db.collection(DONATION_LEDGER).document(doc_id)


def _pool_ref(service, month: str):
    return service.firebase_service.db.collection(DONATION_POOLS).document(month)


def _exists(ref, transaction) -> bool:
    return bool(ref.get(transaction=transaction).exists)


def _user(user_ref, transaction) -> dict:
    snapshot = user_ref.get(transaction=transaction)
    if not snapshot.exists:
        raise HTTPException(status_code=404, detail="User not found.")
    return snapshot.to_dict() or {}


def _quantity(inventory_ref, transaction) -> int:
    snapshot = inventory_ref.get(transaction=transaction)
    if not snapshot.exists:
        return 0
    return int((snapshot.to_dict() or {}).get("quantity") or 0)


def _balances(wallet: dict) -> tuple[int, int, int]:
    return (
        int(wallet.get("shareBalance") or 0),
        int(wallet.get("diamondBalance") or 0),
        int(wallet.get("valueTokenBalance") or 0),
    )


def _balances_result(user: dict, status: str, reason: str) -> SecuredActionResult:
    share, diamonds, value = _balances(user.get("wallet") or {})
    return SecuredActionResult(
        accepted=True,
        status=status,
        reason=reason,
        share_balance=share,
        diamond_balance=diamonds,
        value_token_balance=value,
    )
