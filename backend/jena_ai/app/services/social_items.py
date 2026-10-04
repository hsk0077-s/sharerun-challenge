"""친구 고스트 페이스, 크루 응원 깃발, and crew creation prices.

Prices come from ``config/item_prices``. Purchase and use are idempotent
on ``request_id``: the ledger document id is the request, so a retry does
not debit DIA or inventory twice. Spends take free DIA first.

친구 고스트 페이스 (5 DIA, or 10 uses for 40): one use compares this run
with one friend's verified recorded run. Racing your own best does not
spend a ticket and does not write a ledger row. The pace is display-only.
Rankings and records are not written.

크루 응원 깃발 (15 DIA): one flag per crew per KST day. While it is up,
each member's race SHARE reward is 10% higher. VALUE, DIA, records, and
rankings stay as they were. The bonus is applied when that SHARE is
credited, not when the flag is planted.
"""

from datetime import datetime, timezone

from fastapi import HTTPException
from google.cloud.firestore_v1 import SERVER_TIMESTAMP

from app.models.secured_actions import SecuredActionResult
from app.services.item_price_config import (
    CREW_CHEER_FLAG_ITEM_ID,
    FRIEND_GHOST_ITEM_ID,
    FRIEND_GHOST_PACK_ITEM_ID,
    read_item_prices,
)
from app.services.streak_protection import kst_today, require_request_id
from app.services.wallet_funding import move_currency

_PACK_QUANTITY = 10
CHEER_SHARE_PERCENT = 10
_GRANT = {
    FRIEND_GHOST_ITEM_ID: (FRIEND_GHOST_ITEM_ID, 1),
    FRIEND_GHOST_PACK_ITEM_ID: (FRIEND_GHOST_ITEM_ID, _PACK_QUANTITY),
    CREW_CHEER_FLAG_ITEM_ID: (CREW_CHEER_FLAG_ITEM_ID, 1),
}


def cheer_bonus_share(base_share: int) -> int:
    """10% of a race SHARE reward. Zero when the race paid no SHARE."""
    if base_share <= 0:
        return 0
    return base_share * CHEER_SHARE_PERCENT // 100


def cheered_share(base_share: int, *, cheer_active: bool) -> int:
    if not cheer_active:
        return base_share
    return base_share + cheer_bonus_share(base_share)


def crew_has_cheer(crew: dict | None, day: str) -> bool:
    if not isinstance(crew, dict):
        return False
    flag = crew.get("cheerFlag")
    return isinstance(flag, dict) and flag.get("dayKey") == day


def member_crew_id(user: dict) -> str:
    crew = user.get("crewId")
    if isinstance(crew, str) and crew.strip():
        return crew.strip()
    owned = user.get("ownedCrewId")
    if isinstance(owned, str) and owned.strip():
        return owned.strip()
    return ""


def positive_share_reward(raw: object) -> int:
    if isinstance(raw, bool):
        return 0
    if isinstance(raw, int):
        return raw if raw > 0 else 0
    if isinstance(raw, float) and raw.is_integer():
        number = int(raw)
        return number if number > 0 else 0
    return 0


def purchase_social_item(
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
        return _wallet_result(user, "already_purchased", "Purchase already recorded.")

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


def use_friend_ghost(
    service,
    transaction,
    uid: str,
    request_id: str,
    friend_uid: str | None,
    activity_id: str | None,
    user_ref,
) -> SecuredActionResult:
    """Spend one ticket to follow a friend's verified run. Own best is free."""
    request_id = require_request_id(request_id)
    ledger_ref = _ledger_ref(service, _use_doc_id(uid, FRIEND_GHOST_ITEM_ID, request_id))
    existing = ledger_ref.get(transaction=transaction)
    if existing.exists:
        row = existing.to_dict() or {}
        return SecuredActionResult(
            accepted=True,
            status="already_used",
            reason="Friend ghost pace already used for this run.",
            pace_sec_per_km=_pace_or_none(row.get("paceSecPerKm")),
        )

    friend = (friend_uid or "").strip()
    if not friend or friend == uid:
        pace = _own_pace(service, transaction, uid, activity_id)
        return SecuredActionResult(
            accepted=True,
            status="own_best",
            reason="Own best pace stays free.",
            pace_sec_per_km=pace,
        )

    activity_key, pace = _friend_pace(service, transaction, friend, activity_id)
    user = _user(user_ref, transaction)
    inventory_ref = user_ref.collection("shopInventory").document(FRIEND_GHOST_ITEM_ID)
    quantity = _quantity(inventory_ref, transaction)
    if quantity < 1:
        raise HTTPException(status_code=400, detail="No item to use.")

    transaction.set(inventory_ref, {"quantity": quantity - 1}, merge=True)
    transaction.update(
        user_ref,
        {
            "friendGhostRun": {
                "requestId": request_id,
                "friendUid": friend,
                "activityId": activity_key,
                "paceSecPerKm": pace,
            },
            "updatedAt": SERVER_TIMESTAMP,
        },
    )
    transaction.set(
        ledger_ref,
        {
            "uid": uid,
            "type": "shop_item_use",
            "itemId": FRIEND_GHOST_ITEM_ID,
            "requestId": request_id,
            "quantityAmount": -1,
            "friendUid": friend,
            "activityId": activity_key,
            "paceSecPerKm": pace,
            "createdAt": SERVER_TIMESTAMP,
        },
    )
    share, diamonds, value = _balances(user.get("wallet") or {})
    return SecuredActionResult(
        accepted=True,
        status="used",
        reason="Friend ghost pace is ready for this run.",
        share_balance=share,
        diamond_balance=diamonds,
        value_token_balance=value,
        pace_sec_per_km=pace,
    )


def use_crew_cheer(
    service,
    transaction,
    uid: str,
    request_id: str,
    user_ref,
    now=None,
) -> SecuredActionResult:
    """Plant one flag on the caller's crew. A second flag the same day is free."""
    current = now or datetime.now(timezone.utc)
    request_id = require_request_id(request_id)
    ledger_ref = _ledger_ref(service, _use_doc_id(uid, CREW_CHEER_FLAG_ITEM_ID, request_id))
    if _exists(ledger_ref, transaction):
        user = _user(user_ref, transaction)
        return _wallet_result(user, "already_used", "Crew cheer flag already planted.")

    user = _user(user_ref, transaction)
    crew_id = member_crew_id(user)
    if not crew_id:
        raise HTTPException(status_code=400, detail="No crew.")
    crew_ref = service.firebase_service.db.collection("crews").document(crew_id)
    crew_snapshot = crew_ref.get(transaction=transaction)
    if not crew_snapshot.exists:
        raise HTTPException(status_code=404, detail="Crew not found.")
    crew = crew_snapshot.to_dict() or {}
    day = kst_today(current).isoformat()
    if crew_has_cheer(crew, day):
        return _wallet_result(
            user,
            "already_active",
            "Cheer flag is already up for this crew today.",
        )

    inventory_ref = user_ref.collection("shopInventory").document(CREW_CHEER_FLAG_ITEM_ID)
    quantity = _quantity(inventory_ref, transaction)
    if quantity < 1:
        raise HTTPException(status_code=400, detail="No item to use.")

    transaction.set(inventory_ref, {"quantity": quantity - 1}, merge=True)
    transaction.update(
        crew_ref,
        {
            "cheerFlag": {
                "dayKey": day,
                "buyerUid": uid,
                "requestId": request_id,
                "shareBonusPercent": CHEER_SHARE_PERCENT,
            },
            "updatedAt": SERVER_TIMESTAMP,
        },
    )
    transaction.set(
        ledger_ref,
        {
            "uid": uid,
            "type": "shop_item_use",
            "itemId": CREW_CHEER_FLAG_ITEM_ID,
            "requestId": request_id,
            "quantityAmount": -1,
            "crewId": crew_id,
            "dayKey": day,
            "shareBonusPercent": CHEER_SHARE_PERCENT,
            "createdAt": SERVER_TIMESTAMP,
        },
    )
    return _wallet_result(user, "used", "Crew cheer flag is up for today.")


def _own_pace(service, transaction, uid: str, activity_id: str | None) -> float | None:
    text = (activity_id or "").strip()
    if not text:
        return None
    try:
        _, pace = _verified_pace(service, transaction, uid, text)
    except HTTPException:
        return None
    return pace


def _friend_pace(service, transaction, friend_uid: str, activity_id: str | None):
    text = (activity_id or "").strip()
    if not text:
        raise HTTPException(status_code=400, detail="Friend recorded run is required.")
    return _verified_pace(service, transaction, friend_uid, text)


def _verified_pace(service, transaction, owner_uid: str, activity_id: str):
    if "/" in activity_id or len(activity_id) > 128:
        raise HTTPException(status_code=400, detail="Friend recorded run is required.")
    ref = service.firebase_service.db.collection("activities").document(activity_id)
    snapshot = ref.get(transaction=transaction)
    if not snapshot.exists:
        raise HTTPException(status_code=404, detail="Recorded run not found.")
    activity = snapshot.to_dict() or {}
    if activity.get("userId") != owner_uid:
        raise HTTPException(
            status_code=403,
            detail="Recorded run belongs to another runner.",
        )
    if activity.get("jenaVerified") is not True:
        raise HTTPException(status_code=400, detail="Recorded run is not verified.")
    pace = _pace_or_none(activity.get("averagePaceSecondsPerKm"))
    if pace is None:
        raise HTTPException(status_code=400, detail="Recorded run has no pace.")
    return ref.id, pace


def _pace_or_none(raw: object) -> float | None:
    if isinstance(raw, bool) or not isinstance(raw, (int, float)):
        return None
    pace = float(raw)
    if pace <= 0:
        return None
    return pace


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
