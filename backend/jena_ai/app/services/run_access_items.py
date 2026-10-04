"""코치 원포인트권 and 추가 참가권.

Prices come from ``config/item_prices``. Purchase is idempotent on
``request_id``: the ledger document id is the request, so a retry does
not debit DIA twice. Spends take free DIA first, same as other shop buys.

코치 원포인트권 (5 DIA): one use per KST day. Using it marks that run so
the app can speak Coach+ pace cues. Consumed when the run starts. An
active Coach+ subscription does not spend a ticket.

추가 참가권 (10 DIA, or 3 for 25): two uses per KST day. There is no
per-user daily race-join counter. A non-prize room refuses entry when
it is not recruiting, or when ``maxParticipants`` is already filled.
One ticket opens those two blocks. Cancelled, BEP-cancelled, and
completed rooms stay closed. A room with ``prizeTier`` rejects the
ticket; prize races take SHARE or free tickets only.
"""

from datetime import datetime, timezone

from fastapi import HTTPException
from google.cloud.firestore_v1 import SERVER_TIMESTAMP

from app.models.secured_actions import SecuredActionResult
from app.services.item_price_config import (
    COACH_ONE_POINT_ITEM_ID,
    EXTRA_ENTRY_ITEM_ID,
    EXTRA_ENTRY_PACK_ITEM_ID,
    read_item_prices,
)
from app.services.streak_protection import kst_today, require_request_id
from app.services.wallet_funding import move_currency

_COACH_USES_PER_DAY = 1
_EXTRA_ENTRY_USES_PER_DAY = 2
_PACK_QUANTITY = 3
_TERMINAL_RACE_STATUSES = frozenset(
    {"cancelled", "cancelled_bep_not_met", "completed"}
)
_GRANT = {
    COACH_ONE_POINT_ITEM_ID: (COACH_ONE_POINT_ITEM_ID, 1),
    EXTRA_ENTRY_ITEM_ID: (EXTRA_ENTRY_ITEM_ID, 1),
    EXTRA_ENTRY_PACK_ITEM_ID: (EXTRA_ENTRY_ITEM_ID, _PACK_QUANTITY),
}


def extra_entry_opens_closed(status: object) -> bool:
    """True when a ticket may enter a room that is not recruiting."""
    if status == "recruiting" or status in _TERMINAL_RACE_STATUSES:
        return False
    return True


def purchase_run_access_item(
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
    grant = _GRANT.get(item_id)
    if catalog is None or grant is None or item_id not in prices:
        raise HTTPException(status_code=404, detail="Shop item not found.")
    cost = int(prices[item_id])
    inventory_id, quantity_grant = grant

    ledger_ref = _ledger_ref(service, _purchase_doc_id(uid, item_id, request_id))
    if _exists(ledger_ref, transaction):
        user = _user(user_ref, transaction)
        return _purchase_result(user, "already_purchased", "Purchase already recorded.")

    user = _user(user_ref, transaction)
    wallet = user.get("wallet") or {}
    balance = int(wallet.get("diamondBalance") or 0)
    if balance < cost:
        raise HTTPException(status_code=400, detail="Insufficient Diamond balance.")

    moved = move_currency(wallet, diamond=-cost)
    inventory_ref = user_ref.collection("shopInventory").document(inventory_id)
    held = _quantity(inventory_ref, transaction) + quantity_grant
    inventory_title = service.SHOP_CATALOG[inventory_id]["title"]
    transaction.update(
        user_ref,
        {**moved["updates"], "updatedAt": SERVER_TIMESTAMP},
    )
    transaction.set(
        inventory_ref,
        {
            "itemId": inventory_id,
            "title": inventory_title,
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
            "inventoryItemId": inventory_id,
            "quantityAmount": quantity_grant,
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


def use_coach_one_point(
    service,
    transaction,
    uid: str,
    request_id: str,
    user_ref,
    now: datetime | None = None,
) -> SecuredActionResult:
    """Spend one ticket for this run, or report that Coach+ already covers it."""
    current = now or datetime.now(timezone.utc)
    request_id = require_request_id(request_id)
    ledger_ref = _ledger_ref(
        service, _use_doc_id(uid, COACH_ONE_POINT_ITEM_ID, request_id)
    )
    if _exists(ledger_ref, transaction):
        return SecuredActionResult(
            accepted=True,
            status="already_used",
            reason="Coach one-point ticket already used for this run.",
        )

    user = _user(user_ref, transaction)
    if _coach_plus_active(user, current):
        return SecuredActionResult(
            accepted=True,
            status="subscriber",
            reason="Coach+ is active. Ticket was not used.",
        )

    day = kst_today(current).isoformat()
    uses = _day_count(user, "coachOnePointUseDay", day)
    if uses >= _COACH_USES_PER_DAY:
        raise HTTPException(
            status_code=400,
            detail="Coach one-point daily use cap is 1.",
        )
    inventory_ref = user_ref.collection("shopInventory").document(
        COACH_ONE_POINT_ITEM_ID
    )
    quantity = _quantity(inventory_ref, transaction)
    if quantity < 1:
        raise HTTPException(status_code=400, detail="No item to use.")

    transaction.set(inventory_ref, {"quantity": quantity - 1}, merge=True)
    transaction.update(
        user_ref,
        {
            "coachOnePointUseDay": {"dayKey": day, "count": uses + 1},
            "coachOnePointRun": {"requestId": request_id, "dayKey": day},
            "updatedAt": SERVER_TIMESTAMP,
        },
    )
    transaction.set(
        ledger_ref,
        {
            "uid": uid,
            "type": "shop_item_use",
            "itemId": COACH_ONE_POINT_ITEM_ID,
            "requestId": request_id,
            "quantityAmount": -1,
            "createdAt": SERVER_TIMESTAMP,
        },
    )
    return SecuredActionResult(
        accepted=True,
        status="used",
        reason="Coach one-point ticket used for this run.",
    )


def consume_extra_entry_ticket(
    service,
    transaction,
    uid: str,
    user_ref,
    tournament_id: str,
    now: datetime | None = None,
) -> None:
    """Spend one ticket inside the join transaction. Raises when it cannot."""
    current = now or datetime.now(timezone.utc)
    user = _user(user_ref, transaction)
    day = kst_today(current).isoformat()
    uses = _day_count(user, "extraEntryUseDay", day)
    if uses >= _EXTRA_ENTRY_USES_PER_DAY:
        raise HTTPException(
            status_code=400,
            detail="Extra entry daily use cap is 2.",
        )
    inventory_ref = user_ref.collection("shopInventory").document(EXTRA_ENTRY_ITEM_ID)
    quantity = _quantity(inventory_ref, transaction)
    if quantity < 1:
        raise HTTPException(status_code=400, detail="No extra entry ticket.")

    use_id = _use_doc_id(uid, EXTRA_ENTRY_ITEM_ID, tournament_id)
    ledger_ref = _ledger_ref(service, use_id)
    if _exists(ledger_ref, transaction):
        return

    transaction.set(inventory_ref, {"quantity": quantity - 1}, merge=True)
    transaction.update(
        user_ref,
        {
            "extraEntryUseDay": {"dayKey": day, "count": uses + 1},
            "updatedAt": SERVER_TIMESTAMP,
        },
    )
    transaction.set(
        ledger_ref,
        {
            "uid": uid,
            "type": "shop_item_use",
            "itemId": EXTRA_ENTRY_ITEM_ID,
            "tournamentId": tournament_id,
            "requestId": tournament_id,
            "quantityAmount": -1,
            "createdAt": SERVER_TIMESTAMP,
        },
    )


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


def _day_count(user: dict, field: str, day: str) -> int:
    raw = user.get(field) or {}
    if not isinstance(raw, dict) or raw.get("dayKey") != day:
        return 0
    try:
        return int(raw.get("count") or 0)
    except (TypeError, ValueError):
        return 0


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
