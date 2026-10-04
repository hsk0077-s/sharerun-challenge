"""심폐소생권 and 세이프가드.

Prices come from ``config/item_prices``. Purchase and use of these two
items are idempotent on ``request_id``: the ledger document id is the
request, so a retry does not debit DIA or inventory twice.

심폐소생권 (12 DIA): one use fills the missed days of a broken streak when
the break is still inside 72 hours. At most two uses per KST month.
Coach+ receives one ticket each month, recorded as its own ledger row.

세이프가드 (8 DIA): at most two held. One held ticket covers exactly one
missed day (yesterday) while the day before still counts, so the streak
does not break. A purchase applies that cover immediately when yesterday
already needs it. The app also asks once per day.
"""

from datetime import date, datetime, time, timedelta, timezone
import re

from fastapi import HTTPException
from google.cloud.firestore_v1 import SERVER_TIMESTAMP

from app.models.secured_actions import SecuredActionResult
from app.services.item_price_config import (
    CPR_ITEM_ID,
    SAFEGUARD_ITEM_ID,
    read_item_prices,
)
from app.services.wallet_funding import move_currency

_KST = timezone(timedelta(hours=9))
_REQUEST_ID = re.compile(r"^[A-Za-z0-9_-]{8,64}$")
_CPR_WINDOW = timedelta(hours=72)
_CPR_USES_PER_MONTH = 2
_SAFEGUARD_HOLD_CAP = 2
_LOOKBACK_DAYS = 10
_AUTO_SAFEGUARD_PREFIX = "safeguard-auto-"


def require_request_id(request_id: str | None) -> str:
    text = (request_id or "").strip()
    if _REQUEST_ID.fullmatch(text) is None:
        raise HTTPException(status_code=400, detail="request_id is required.")
    return text


def metric_qualifies(data: dict | None) -> bool:
    """A day counts when it has steps, km, or a server streak cover."""
    if not data:
        return False
    if data.get("streakCovered") in ("cpr", "safeguard"):
        return True
    return _positive_number(data.get("steps")) or _positive_number(data.get("km"))


def is_rest_pause(data: dict | None) -> bool:
    """A rest day pauses the streak. It is not a run and not a cover."""
    if not data or metric_qualifies(data):
        return False
    return data.get("streakPaused") == "rest"


def kst_today(now: datetime) -> date:
    current = now if now.tzinfo else now.replace(tzinfo=timezone.utc)
    return current.astimezone(_KST).date()


def kst_month_key(now: datetime) -> str:
    return kst_today(now).strftime("%Y-%m")


def kst_week_key(now: datetime) -> str:
    """Monday of the KST week, YYYY-MM-DD. Same marker as the streak DIA week."""
    today = kst_today(now)
    monday = today - timedelta(days=today.weekday())
    return monday.isoformat()


def cpr_restore_days(metrics: dict[date, dict], today: date, now: datetime) -> list[date]:
    """Missed days that reconnect a broken streak inside the 72-hour window.

    The streak breaks at 00:00 KST on the day after the first missed day
    (yesterday with no record still continues the streak). Raises
    ``not_broken`` or ``window``.
    """
    gap_end = _gap_end(metrics, today)
    if gap_end is None:
        raise ValueError("not_broken")
    last = _previous_qualifying(metrics, gap_end)
    if last is None:
        raise ValueError("not_broken")
    first_missed = last + timedelta(days=1)
    gap: list[date] = []
    day = first_missed
    while day <= gap_end:
        data = metrics.get(day)
        # A rest pause is not a miss to fill. CPR must not turn it into a run.
        if not metric_qualifies(data) and not is_rest_pause(data):
            gap.append(day)
        day += timedelta(days=1)
    if not gap:
        raise ValueError("not_broken")
    break_at = datetime.combine(gap[0] + timedelta(days=1), time.min, tzinfo=_KST)
    current = now if now.tzinfo else now.replace(tzinfo=timezone.utc)
    if current > break_at + _CPR_WINDOW:
        raise ValueError("window")
    return gap


def safeguard_target(metrics: dict[date, dict], today: date) -> date | None:
    """Yesterday, when that single day is the only miss before a live streak.

    A rest pause is not that miss, and it is not overwritten with a cover.
    Pauses between the miss and the last run still count as connected.
    """
    yesterday = today - timedelta(days=1)
    if metric_qualifies(metrics.get(yesterday)) or is_rest_pause(metrics.get(yesterday)):
        return None
    if not _connects_through_pauses(metrics, yesterday - timedelta(days=1)):
        return None
    return yesterday


def purchase_streak_item(
    service,
    transaction,
    uid: str,
    item_id: str,
    request_id: str,
    user_ref,
    now: datetime | None = None,
) -> SecuredActionResult:
    current = now or datetime.now(timezone.utc)
    request_id = require_request_id(request_id)
    prices = read_item_prices(service.firebase_service.db, transaction)
    catalog = service.SHOP_CATALOG.get(item_id)
    if catalog is None or item_id not in prices:
        raise HTTPException(status_code=404, detail="Shop item not found.")
    cost = int(prices[item_id])

    ledger_ref = _ledger_ref(service, _purchase_doc_id(uid, item_id, request_id))
    if _exists(ledger_ref, transaction):
        user = _user(user_ref, transaction)
        return _purchase_result(user, "already_purchased", "Purchase already recorded.")

    user = _user(user_ref, transaction)
    inventory_ref = user_ref.collection("shopInventory").document(item_id)
    quantity = _quantity(inventory_ref, transaction)
    if item_id == SAFEGUARD_ITEM_ID and quantity >= _SAFEGUARD_HOLD_CAP:
        raise HTTPException(status_code=400, detail="Safeguard hold cap is 2.")
    wallet = user.get("wallet") or {}
    balance = int(wallet.get("diamondBalance") or 0)
    if balance < cost:
        raise HTTPException(status_code=400, detail="Insufficient Diamond balance.")

    moved = move_currency(wallet, diamond=-cost)
    held = quantity + 1
    covered: list[str] = []
    if item_id == SAFEGUARD_ITEM_ID and held >= 1:
        metrics = _load_metrics(service, transaction, uid, kst_today(current))
        target = safeguard_target(metrics, kst_today(current))
        if target is not None:
            covered = [target.isoformat()]
            held -= 1

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
            "diamondAmount": -cost,
            "itemId": item_id,
            "requestId": request_id,
            "createdAt": SERVER_TIMESTAMP,
            **moved["ledger"],
        },
    )
    if covered:
        _cover_days(
            service,
            transaction,
            uid,
            covered,
            kind="safeguard",
            request_id=request_id,
        )
        transaction.set(
            _ledger_ref(service, _use_doc_id(uid, item_id, f"{request_id}_hold")),
            {
                "uid": uid,
                "type": "shop_item_use",
                "itemId": item_id,
                "requestId": f"{request_id}_hold",
                "quantityAmount": -1,
                "coveredDays": covered,
                "createdAt": SERVER_TIMESTAMP,
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


def use_streak_item(
    service,
    transaction,
    uid: str,
    item_id: str,
    request_id: str,
    user_ref,
    now: datetime | None = None,
) -> SecuredActionResult:
    current = now or datetime.now(timezone.utc)
    request_id = require_request_id(request_id)
    if item_id not in service.SHOP_CATALOG:
        raise HTTPException(status_code=404, detail="Shop item not found.")
    auto = item_id == SAFEGUARD_ITEM_ID and request_id.startswith(_AUTO_SAFEGUARD_PREFIX)

    ledger_ref = _ledger_ref(service, _use_doc_id(uid, item_id, request_id))
    if _exists(ledger_ref, transaction):
        return SecuredActionResult(
            accepted=True,
            status="already_used",
            reason="Item use already recorded.",
        )

    user = _user(user_ref, transaction)
    today = kst_today(current)
    metrics = _load_metrics(service, transaction, uid, today)
    inventory_ref = user_ref.collection("shopInventory").document(item_id)
    quantity = _quantity(inventory_ref, transaction)

    if item_id == CPR_ITEM_ID:
        try:
            gap = cpr_restore_days(metrics, today, current)
        except ValueError as exc:
            _raise_cpr(str(exc))
            raise
        month = kst_month_key(current)
        uses = _month_uses(user, month)
        if uses >= _CPR_USES_PER_MONTH:
            raise HTTPException(status_code=400, detail="CPR monthly use cap is 2.")
        if quantity < 1:
            raise HTTPException(status_code=400, detail="No item to use.")
        covered = [day.isoformat() for day in gap]
        transaction.update(
            user_ref,
            {
                "cprUseMonth": {"monthKey": month, "count": uses + 1},
                "updatedAt": SERVER_TIMESTAMP,
            },
        )
        kind = "cpr"
    else:
        target = safeguard_target(metrics, today)
        if target is None:
            if auto:
                return SecuredActionResult(
                    accepted=True,
                    status="not_needed",
                    reason="No missed day to protect.",
                )
            raise HTTPException(status_code=400, detail="No missed day to protect.")
        if quantity < 1:
            if auto:
                return SecuredActionResult(
                    accepted=True,
                    status="no_item",
                    reason="No item to use.",
                )
            raise HTTPException(status_code=400, detail="No item to use.")
        covered = [target.isoformat()]
        kind = "safeguard"

    transaction.set(inventory_ref, {"quantity": quantity - 1}, merge=True)
    _cover_days(service, transaction, uid, covered, kind=kind, request_id=request_id)
    transaction.set(
        ledger_ref,
        {
            "uid": uid,
            "type": "shop_item_use",
            "itemId": item_id,
            "requestId": request_id,
            "quantityAmount": -1,
            "coveredDays": covered,
            "createdAt": SERVER_TIMESTAMP,
        },
    )
    return SecuredActionResult(accepted=True, status="used", reason="Item used.")


def maybe_grant_coach_plus_cpr(service, uid: str) -> None:
    """Grant when Coach+ is active. Never fails the caller (shop catalog)."""
    try:
        user_ref = service.firebase_service.db.collection("users").document(uid)
        snapshot = user_ref.get()
        if not snapshot.exists:
            return
        user = snapshot.to_dict() or {}
        now = datetime.now(timezone.utc)
        if user.get("cprFreeGrantMonth") == kst_month_key(now) or not _coach_plus_active(
            user, now
        ):
            return
        transaction = service.firebase_service.db.transaction()
        service.commit_cpr_grant(transaction, uid, user_ref)
    except Exception:
        return


def grant_coach_plus_cpr(
    service,
    transaction,
    uid: str,
    user_ref,
    now: datetime | None = None,
) -> None:
    """One free 심폐소생권 per KST month while Coach+ is active. Idempotent."""
    current = now or datetime.now(timezone.utc)
    month = kst_month_key(current)
    user_snapshot = user_ref.get(transaction=transaction)
    if not user_snapshot.exists:
        return
    user = user_snapshot.to_dict() or {}
    if user.get("cprFreeGrantMonth") == month or not _coach_plus_active(user, current):
        return
    ledger_ref = _ledger_ref(service, f"cpr_free_{uid}_{month}")
    if _exists(ledger_ref, transaction):
        transaction.update(
            user_ref,
            {"cprFreeGrantMonth": month, "updatedAt": SERVER_TIMESTAMP},
        )
        return
    inventory_ref = user_ref.collection("shopInventory").document(CPR_ITEM_ID)
    quantity = _quantity(inventory_ref, transaction)
    title = service.SHOP_CATALOG[CPR_ITEM_ID]["title"]
    transaction.set(
        inventory_ref,
        {
            "itemId": CPR_ITEM_ID,
            "title": title,
            "quantity": quantity + 1,
            "purchasedAt": SERVER_TIMESTAMP,
        },
        merge=True,
    )
    transaction.set(
        ledger_ref,
        {
            "uid": uid,
            "type": "cpr_coach_plus_grant",
            "itemId": CPR_ITEM_ID,
            "quantityAmount": 1,
            "diamondAmount": 0,
            "monthKey": month,
            "createdAt": SERVER_TIMESTAMP,
        },
    )
    transaction.update(
        user_ref,
        {"cprFreeGrantMonth": month, "updatedAt": SERVER_TIMESTAMP},
    )


def _gap_end(metrics: dict[date, dict], today: date) -> date | None:
    if metric_qualifies(metrics.get(today)):
        run_start = today
        while metric_qualifies(metrics.get(run_start - timedelta(days=1))):
            run_start -= timedelta(days=1)
        gap_end = run_start - timedelta(days=1)
        if _pause_bridge(metrics, gap_end):
            return None
        return gap_end
    yesterday = today - timedelta(days=1)
    if metric_qualifies(metrics.get(yesterday)) or _pause_bridge(metrics, yesterday):
        return None
    return yesterday


def _pause_bridge(metrics: dict[date, dict], day: date) -> bool:
    """True when ``day`` is a rest pause that still reaches a qualifying day."""
    if not is_rest_pause(metrics.get(day)):
        return False
    return _connects_through_pauses(metrics, day)


def _connects_through_pauses(metrics: dict[date, dict], day: date) -> bool:
    probe = day
    for _ in range(_LOOKBACK_DAYS):
        data = metrics.get(probe)
        if metric_qualifies(data):
            return True
        if is_rest_pause(data):
            probe -= timedelta(days=1)
            continue
        return False
    return False


def _previous_qualifying(metrics: dict[date, dict], gap_end: date) -> date | None:
    probe = gap_end
    for _ in range(_LOOKBACK_DAYS):
        probe -= timedelta(days=1)
        if metric_qualifies(metrics.get(probe)):
            return probe
    return None


def _raise_cpr(code: str) -> None:
    if code == "window":
        raise HTTPException(
            status_code=400,
            detail="Streak break is outside 72 hours.",
        )
    raise HTTPException(status_code=400, detail="Streak is not broken.")


def _cover_days(service, transaction, uid: str, days: list[str], *, kind: str, request_id: str) -> None:
    parent = (
        service.firebase_service.db.collection("users")
        .document(uid)
        .collection("daily_metrics")
    )
    for day in days:
        transaction.set(
            parent.document(day),
            {
                "streakCovered": kind,
                "coveredAt": SERVER_TIMESTAMP,
                "coveredByRequestId": request_id,
            },
            merge=True,
        )


def _load_metrics(service, transaction, uid: str, today: date) -> dict[date, dict]:
    parent = (
        service.firebase_service.db.collection("users")
        .document(uid)
        .collection("daily_metrics")
    )
    found: dict[date, dict] = {}
    for offset in range(_LOOKBACK_DAYS + 1):
        day = today - timedelta(days=offset)
        snapshot = parent.document(day.isoformat()).get(transaction=transaction)
        if snapshot.exists:
            found[day] = snapshot.to_dict() or {}
    return found


def _month_uses(user: dict, month: str) -> int:
    raw = user.get("cprUseMonth") or {}
    if not isinstance(raw, dict) or raw.get("monthKey") != month:
        return 0
    return int(raw.get("count") or 0)


def _coach_plus_active(user: dict, now: datetime) -> bool:
    raw = (user.get("coachPlus") or {}).get("activeUntil")
    if not isinstance(raw, str) or not raw.strip():
        return False
    try:
        until = datetime.fromisoformat(raw.strip())
    except ValueError:
        return False
    if until.tzinfo is None:
        until = until.replace(tzinfo=timezone.utc)
    current = now if now.tzinfo else now.replace(tzinfo=timezone.utc)
    return until > current


def _purchase_doc_id(uid: str, item_id: str, request_id: str) -> str:
    return f"shop_buy_{uid}_{item_id}_{request_id}"


def _use_doc_id(uid: str, item_id: str, request_id: str) -> str:
    return f"shop_use_{uid}_{item_id}_{request_id}"


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
    return int((snapshot.to_dict() or {}).get("quantity") or 0)


def _balances(wallet: dict) -> tuple[int, int, int]:
    return (
        int(wallet.get("shareBalance") or 0),
        int(wallet.get("diamondBalance") or 0),
        int(wallet.get("valueTokenBalance") or 0),
    )


def _purchase_result(user: dict, status: str, reason: str) -> SecuredActionResult:
    wallet = user.get("wallet") or {}
    share, diamonds, value = _balances(wallet)
    return SecuredActionResult(
        accepted=True,
        status=status,
        reason=reason,
        share_balance=share,
        diamond_balance=diamonds,
        value_token_balance=value,
    )


def _positive_number(value: object) -> bool:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        return False
    return value > 0
