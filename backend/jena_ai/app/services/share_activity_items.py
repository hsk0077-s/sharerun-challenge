"""부스트 런 and 만보기 부화기.

Prices come from ``config/item_prices`` and are SHARE, not DIA. Purchase
and use are idempotent on ``request_id``. A retry does not debit SHARE
or inventory twice. Spends take free SHARE first.

부스트 런 (120 SHARE): one use per KST day. For 15 minutes, SHARE credited
by the pedometer harvest is doubled. The extra SHARE, not the base, is
capped at +240 per KST day. The hourly step cap and the daily harvest
cap still limit the base. VALUE, DIA, donations, race SHARE, records,
and rankings are not read here.

만보기 부화기 (1,200 SHARE): one active incubator. Each server-accepted
step after activation counts. At 30,000 steps it hatches 민트 러닝화.
If that cosmetic is already owned, it credits 500 SHARE instead. Never DIA.
"""

from dataclasses import dataclass
from datetime import datetime, timedelta, timezone

from fastapi import HTTPException
from google.cloud.firestore_v1 import SERVER_TIMESTAMP

from app.models.secured_actions import SecuredActionResult
from app.services.cosmetics import SHOE_SKIN, read_cosmetics_catalog
from app.services.item_price_config import (
    BOOST_RUN_ITEM_ID,
    STEP_INCUBATOR_ITEM_ID,
    read_item_prices,
)
from app.services.streak_protection import kst_today, require_request_id
from app.services.wallet_funding import move_currency

BOOST_WINDOW = timedelta(minutes=15)
BOOST_EXTRA_DAILY_CAP = 240
INCUBATOR_STEP_GOAL = 30_000
HATCH_COSMETIC_ID = "shoe_mint"
HATCH_FALLBACK_SHARE = 500
_ALREADY_BOOSTED = "Boost run already used today."
_ALREADY_INCUBATING = "An incubator is already active."


@dataclass(frozen=True)
class ActivitySharePlan:
    extra_share: int = 0
    hatch_share: int = 0
    boost_state: dict | None = None
    incubator_state: dict | None = None
    hatch_doc_id: str = ""
    hatch_fields: dict | None = None
    cosmetic_id: str = ""
    cosmetic_fields: dict | None = None


def plan_activity_share(
    service,
    transaction,
    user: dict,
    user_ref,
    *,
    base_share: int,
    accepted_steps: int,
    now: datetime,
) -> ActivitySharePlan:
    """Reads only. Harvest applies the plan in the same transaction."""
    extra, boost_state = _boost_extra(user, base_share, now)
    incubator_state, hatch = _incubator_progress(
        service,
        transaction,
        user,
        user_ref,
        accepted_steps,
    )
    if hatch is None:
        return ActivitySharePlan(
            extra_share=extra,
            boost_state=boost_state,
            incubator_state=incubator_state,
        )
    return ActivitySharePlan(
        extra_share=extra,
        hatch_share=int(hatch["share"]),
        boost_state=boost_state,
        incubator_state=incubator_state,
        hatch_doc_id=hatch["doc_id"],
        hatch_fields=hatch["fields"],
        cosmetic_id=hatch["cosmetic_id"],
        cosmetic_fields=hatch["cosmetic_fields"],
    )


def purchase_share_activity_item(
    service,
    transaction,
    uid: str,
    item_id: str,
    request_id: str,
    user_ref,
) -> SecuredActionResult:
    request_id = require_request_id(request_id)
    prices = read_item_prices(service.firebase_service.db, transaction)
    catalog = service.SHOP_CATALOG.get(item_id)
    if catalog is None or item_id not in prices:
        raise HTTPException(status_code=404, detail="Shop item not found.")
    cost = int(prices[item_id])
    ledger_ref = _ledger_ref(service, f"shop_buy_{uid}_{item_id}_{request_id}")
    if _exists(ledger_ref, transaction):
        user = _user(user_ref, transaction)
        return _wallet_result(user, "already_purchased", "Purchase already recorded.")

    user = _user(user_ref, transaction)
    wallet = user.get("wallet")
    if not isinstance(wallet, dict):
        wallet = {}
        user["wallet"] = wallet
    moved = move_currency(wallet, share=-cost)
    inventory_ref = user_ref.collection("shopInventory").document(item_id)
    held = _quantity(inventory_ref, transaction) + 1
    transaction.update(
        user_ref,
        {**moved["updates"], "updatedAt": SERVER_TIMESTAMP},
    )
    transaction.set(
        inventory_ref,
        {
            "itemId": item_id,
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
            "shareAmount": -cost,
            "itemId": item_id,
            "quantityAmount": 1,
            "requestId": request_id,
            "createdAt": SERVER_TIMESTAMP,
            **moved["ledger"],
        },
    )
    share, diamonds, value = _balances(wallet)
    return SecuredActionResult(
        accepted=True,
        status="purchased",
        reason=f"Purchased {catalog['title']}.",
        share_balance=share,
        diamond_balance=diamonds,
        value_token_balance=value,
    )


def use_share_activity_item(
    service,
    transaction,
    uid: str,
    item_id: str,
    request_id: str,
    user_ref,
    now=None,
) -> SecuredActionResult:
    if item_id == BOOST_RUN_ITEM_ID:
        return _use_boost(service, transaction, uid, request_id, user_ref, now)
    if item_id == STEP_INCUBATOR_ITEM_ID:
        return _use_incubator(service, transaction, uid, request_id, user_ref, now)
    raise HTTPException(status_code=404, detail="Shop item not found.")


def _use_boost(service, transaction, uid, request_id, user_ref, now) -> SecuredActionResult:
    current = _aware(now or datetime.now(timezone.utc))
    request_id = require_request_id(request_id)
    ledger_ref = _ledger_ref(service, f"shop_use_{uid}_{BOOST_RUN_ITEM_ID}_{request_id}")
    if _exists(ledger_ref, transaction):
        return _wallet_result(
            _user(user_ref, transaction),
            "already_used",
            "Boost run already recorded.",
        )
    user = _user(user_ref, transaction)
    day = kst_today(current).isoformat()
    state = user.get("boostRun") if isinstance(user.get("boostRun"), dict) else {}
    if state.get("useDayKey") == day:
        raise HTTPException(status_code=400, detail=_ALREADY_BOOSTED)
    already = (
        _non_negative_int(state.get("extraShare"))
        if state.get("extraDayKey") == day
        else 0
    )
    _consume(transaction, user_ref, BOOST_RUN_ITEM_ID)
    expires = (current + BOOST_WINDOW).isoformat()
    transaction.update(
        user_ref,
        {
            "boostRun": {
                "useDayKey": day,
                "activatedAt": current.isoformat(),
                "expiresAt": expires,
                "extraDayKey": day,
                "extraShare": already,
                "requestId": request_id,
            },
            "updatedAt": SERVER_TIMESTAMP,
        },
    )
    transaction.set(
        ledger_ref,
        {
            "uid": uid,
            "type": "shop_item_use",
            "itemId": BOOST_RUN_ITEM_ID,
            "requestId": request_id,
            "quantityAmount": -1,
            "dayKey": day,
            "expiresAt": expires,
            "createdAt": SERVER_TIMESTAMP,
        },
    )
    return _wallet_result(user, "used", "Boost run is active for 15 minutes.")


def _use_incubator(service, transaction, uid, request_id, user_ref, now) -> SecuredActionResult:
    current = _aware(now or datetime.now(timezone.utc))
    request_id = require_request_id(request_id)
    ledger_ref = _ledger_ref(
        service, f"shop_use_{uid}_{STEP_INCUBATOR_ITEM_ID}_{request_id}"
    )
    if _exists(ledger_ref, transaction):
        return _wallet_result(
            _user(user_ref, transaction),
            "already_used",
            "Step incubator already recorded.",
        )
    user = _user(user_ref, transaction)
    state = user.get("stepIncubator") if isinstance(user.get("stepIncubator"), dict) else {}
    if state.get("status") == "active":
        raise HTTPException(status_code=400, detail=_ALREADY_INCUBATING)
    _consume(transaction, user_ref, STEP_INCUBATOR_ITEM_ID)
    transaction.update(
        user_ref,
        {
            "stepIncubator": {
                "status": "active",
                "steps": 0,
                "requestId": request_id,
                "startedAt": current.isoformat(),
            },
            "updatedAt": SERVER_TIMESTAMP,
        },
    )
    transaction.set(
        ledger_ref,
        {
            "uid": uid,
            "type": "shop_item_use",
            "itemId": STEP_INCUBATOR_ITEM_ID,
            "requestId": request_id,
            "quantityAmount": -1,
            "createdAt": SERVER_TIMESTAMP,
        },
    )
    return _wallet_result(user, "used", "Step incubator is counting verified steps.")


def _boost_extra(user: dict, base_share: int, now: datetime) -> tuple[int, dict | None]:
    state = user.get("boostRun")
    if not isinstance(state, dict) or base_share <= 0:
        return 0, None
    expires = _parse_time(state.get("expiresAt"))
    current = _aware(now)
    if expires is None or current >= expires:
        return 0, None
    day = kst_today(current).isoformat()
    already = (
        _non_negative_int(state.get("extraShare"))
        if state.get("extraDayKey") == day
        else 0
    )
    extra = min(base_share, max(0, BOOST_EXTRA_DAILY_CAP - already))
    if extra <= 0:
        return 0, None
    next_state = dict(state)
    next_state["extraDayKey"] = day
    next_state["extraShare"] = already + extra
    return extra, next_state


def _incubator_progress(service, transaction, user, user_ref, accepted_steps):
    state = user.get("stepIncubator")
    if not isinstance(state, dict) or state.get("status") != "active":
        return None, None
    if accepted_steps <= 0:
        return None, None
    steps = _non_negative_int(state.get("steps")) + accepted_steps
    next_state = dict(state)
    next_state["steps"] = steps
    next_state["status"] = "active"
    if steps < INCUBATOR_STEP_GOAL:
        return next_state, None
    request_id = state.get("requestId")
    if not isinstance(request_id, str) or not request_id.strip():
        request_id = "hatch"
    cosmetic, share = _hatch_reward(service, transaction, user_ref)
    next_state["status"] = "hatched"
    next_state["rewardItemId"] = cosmetic["id"] if cosmetic else ""
    next_state["rewardShare"] = share
    fields = {
        "uid": user_ref.id,
        "type": "step_incubator_hatch",
        "itemId": STEP_INCUBATOR_ITEM_ID,
        "requestId": request_id,
        "steps": steps,
    }
    cosmetic_fields = None
    cosmetic_id = ""
    if cosmetic is not None:
        cosmetic_id = cosmetic["id"]
        fields["rewardItemId"] = cosmetic_id
        cosmetic_fields = {
            "itemId": cosmetic_id,
            "title": cosmetic["name"],
            "quantity": 1,
            "category": cosmetic["category"],
            "season": cosmetic["season"],
            "limited": cosmetic["limited"],
            "asset": cosmetic["asset"],
            "accent": cosmetic["accent"],
            "source": STEP_INCUBATOR_ITEM_ID,
            "purchasedAt": SERVER_TIMESTAMP,
        }
    else:
        fields["shareAmount"] = share
    return next_state, {
        "share": share,
        "doc_id": f"step_incubator_{user_ref.id}_{request_id}",
        "fields": fields,
        "cosmetic_id": cosmetic_id,
        "cosmetic_fields": cosmetic_fields,
    }


def _hatch_reward(service, transaction, user_ref):
    catalog = read_cosmetics_catalog(service.firebase_service.db, transaction)
    item = None
    for row in catalog["items"]:
        if row["id"] == HATCH_COSMETIC_ID and row["category"] == SHOE_SKIN:
            item = row
            break
    if item is None:
        return None, HATCH_FALLBACK_SHARE
    owned = _quantity(
        user_ref.collection("shopInventory").document(HATCH_COSMETIC_ID),
        transaction,
    )
    if owned >= 1:
        return None, HATCH_FALLBACK_SHARE
    return item, 0


def _consume(transaction, user_ref, item_id: str) -> None:
    inventory_ref = user_ref.collection("shopInventory").document(item_id)
    quantity = _quantity(inventory_ref, transaction)
    if quantity < 1:
        raise HTTPException(status_code=400, detail="No item to use.")
    transaction.set(inventory_ref, {"quantity": quantity - 1}, merge=True)


def _parse_time(value: object) -> datetime | None:
    if isinstance(value, datetime):
        return _aware(value)
    if not isinstance(value, str) or not value:
        return None
    try:
        return _aware(datetime.fromisoformat(value))
    except ValueError:
        return None


def _aware(value: datetime) -> datetime:
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value


def _non_negative_int(value: object) -> int:
    if isinstance(value, bool):
        return 0
    if isinstance(value, int):
        return value if value > 0 else 0
    if isinstance(value, float) and value.is_integer():
        number = int(value)
        return number if number > 0 else 0
    return 0


def _ledger_ref(service, doc_id: str):
    return service.firebase_service.db.collection("walletTransactions").document(doc_id)


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
    return _non_negative_int((snapshot.to_dict() or {}).get("quantity"))


def _balances(wallet: dict) -> tuple[int, int, int]:
    return (
        int(wallet.get("shareBalance") or 0),
        int(wallet.get("diamondBalance") or 0),
        int(wallet.get("valueTokenBalance") or 0),
    )


def _wallet_result(user: dict, status: str, reason: str) -> SecuredActionResult:
    share, diamonds, value = _balances(user.get("wallet") or {})
    return SecuredActionResult(
        accepted=True,
        status=status,
        reason=reason,
        share_balance=share,
        diamond_balance=diamonds,
        value_token_balance=value,
    )
