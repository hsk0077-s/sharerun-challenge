"""Accessories and skins: buy with DIA or SHARE, then wear.

The list lives in ``accessory_catalog`` (made from the app's list). Rules:
* ``tierReward`` items and items marked not ``ready`` are not for sale.
* A tier-locked skin needs that animal's tier (or higher) on the server's ``gradeRank``.
* DIA spends bonus first, SHARE spends the free part first (``move_currency`` default).
* Owned items sit in ``users/{uid}/shopInventory/{id}`` (category ``accessory``); what is
  worn sits in ``shopInventory/accessory_loadout`` as ``slots: {slot: id}``.
"""

from __future__ import annotations

from fastapi import HTTPException
from google.cloud.firestore_v1 import SERVER_TIMESTAMP

from app.models.secured_actions import SecuredActionResult
from app.services.accessory_catalog import ACCESSORIES
from app.services.streak_protection import require_request_id
from app.services.wallet_funding import move_currency

CATEGORY = "accessory"
LOADOUT_ID = "accessory_loadout"
SLOTS = frozenset({"back", "bottom", "top", "feet", "hand", "eyes", "head", "skin"})
# 0 = snail (no grade yet), then turtle .. cheetah, the order of the app's tier ladder.
_ANIMAL_RANK = {"turtle": 1, "beagle": 2, "wolf": 3, "zebra": 4, "cheetah": 5}

_BY_ID = {item["id"]: item for item in ACCESSORIES}


def find(item_id: str) -> dict | None:
    return _BY_ID.get(item_id)


def is_accessory(item_id: str) -> bool:
    return item_id in _BY_ID


def for_sale(item: dict) -> bool:
    return (
        item["ready"]
        and item["rarity"] != "tierReward"
        and item["currency"] in {"dia", "share"}
        and isinstance(item["price"], int)
        and item["price"] > 0
    )


def animal_rank(user: dict) -> int:
    """0 for a snail (not graded yet), else 1 (turtle) .. 5 (cheetah) from ``gradeRank``."""
    raw = user.get("gradeRank")
    if isinstance(raw, bool) or not isinstance(raw, (int, float)) or raw <= 0:
        return 0
    return min(5, (int(raw) - 1) // 5 + 1)


def _balances(wallet: dict) -> tuple[int, int, int]:
    return (
        int(wallet.get("shareBalance") or 0),
        int(wallet.get("diamondBalance") or 0),
        int(wallet.get("valueTokenBalance") or 0),
    )


def _result(wallet: dict, status: str, reason: str) -> SecuredActionResult:
    share, diamonds, value = _balances(wallet)
    return SecuredActionResult(
        accepted=True,
        status=status,
        reason=reason,
        share_balance=share,
        diamond_balance=diamonds,
        value_token_balance=value,
    )


def purchase(service, transaction, uid: str, item_id: str, request_id: str, user_ref) -> SecuredActionResult:
    request_id = require_request_id(request_id)
    item = find(item_id)
    if item is None or not for_sale(item):
        raise HTTPException(status_code=404, detail="Shop item not found.")
    ledger_ref = service.firebase_service.db.collection("walletTransactions").document(
        f"accessory_buy_{uid}_{item_id}_{request_id}"
    )
    user_snapshot = user_ref.get(transaction=transaction)
    if not user_snapshot.exists:
        raise HTTPException(status_code=404, detail="User not found.")
    user = user_snapshot.to_dict() or {}
    wallet = user.get("wallet") if isinstance(user.get("wallet"), dict) else {}
    if ledger_ref.get(transaction=transaction).exists:
        return _result(wallet, "already_purchased", "Purchase already recorded.")
    inventory_ref = user_ref.collection("shopInventory").document(item_id)
    owned = inventory_ref.get(transaction=transaction)
    if owned.exists and int((owned.to_dict() or {}).get("quantity") or 0) >= 1:
        raise HTTPException(status_code=400, detail="Item already owned.")
    lock = item["tier_lock"]
    if lock is not None and animal_rank(user) < _ANIMAL_RANK[lock]:
        raise HTTPException(status_code=403, detail="This item needs a higher tier.")
    price = int(item["price"])
    if item["currency"] == "dia":
        moved = move_currency(wallet, diamond=-price)
        ledger_amount = {"diamondAmount": -price}
    else:
        moved = move_currency(wallet, share=-price)
        ledger_amount = {"shareAmount": -price}
    transaction.update(user_ref, {**moved["updates"], "updatedAt": SERVER_TIMESTAMP})
    transaction.set(
        inventory_ref,
        {
            "itemId": item_id,
            "quantity": 1,
            "category": CATEGORY,
            "slot": item["slot"],
            "purchasedAt": SERVER_TIMESTAMP,
        },
    )
    transaction.set(
        ledger_ref,
        {
            "uid": uid,
            "type": "accessory_purchase",
            "itemId": item_id,
            "requestId": request_id,
            "createdAt": SERVER_TIMESTAMP,
            **ledger_amount,
            **moved["ledger"],
        },
    )
    return _result(wallet, "purchased", f"Purchased {item_id}.")


def equip(service, transaction, uid: str, slot: str, item_id: str, user_ref) -> SecuredActionResult:
    """Wear ``item_id`` in ``slot``, or take the slot off when ``item_id`` is empty."""
    if slot not in SLOTS:
        raise HTTPException(status_code=400, detail="Unknown slot.")
    user_snapshot = user_ref.get(transaction=transaction)
    if not user_snapshot.exists:
        raise HTTPException(status_code=404, detail="User not found.")
    user = user_snapshot.to_dict() or {}
    wallet = user.get("wallet") if isinstance(user.get("wallet"), dict) else {}
    loadout_ref = user_ref.collection("shopInventory").document(LOADOUT_ID)
    snapshot = loadout_ref.get(transaction=transaction)
    slots = dict(((snapshot.to_dict() or {}).get("slots") or {})) if snapshot.exists else {}
    if item_id:
        item = find(item_id)
        if item is None or item["slot"] != slot:
            raise HTTPException(status_code=400, detail="That item does not go in this slot.")
        inventory = user_ref.collection("shopInventory").document(item_id).get(transaction=transaction)
        owned = inventory.exists and int((inventory.to_dict() or {}).get("quantity") or 0) >= 1
        # A tier-reward item (the laurel) is given by the tier, not bought: allow it by tier.
        if not owned and not (item["rarity"] == "tierReward" and _reward_unlocked(user, item)):
            raise HTTPException(status_code=400, detail="You do not own this item.")
        slots[slot] = item_id
    else:
        slots.pop(slot, None)
    transaction.set(
        loadout_ref,
        {"itemId": LOADOUT_ID, "quantity": 0, "slots": slots},
        merge=False,
    )
    return _result(wallet, "equipped" if item_id else "unequipped", f"{slot} updated.")


def _reward_unlocked(user: dict, item: dict) -> bool:
    return animal_rank(user) >= 1
