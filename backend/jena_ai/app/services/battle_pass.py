"""배틀런 패스 and 패스+.

Prices come from ``config/item_prices``. Both charge paid DIA only. Free,
bonus, and prize DIA stay put. The ledger document id is the request, so
a retry does not charge twice. One pass per season: 패스+ after a pass
charges the price difference.

Rewards are cosmetic frames, skins, and badges on the season inventory
doc. They do not pay DIA or SHARE and they do not change rankings or
records.
"""

from fastapi import HTTPException
from google.cloud.firestore_v1 import SERVER_TIMESTAMP

from app.models.secured_actions import SecuredActionResult
from app.services.item_price_config import (
    BATTLE_PASS_ITEM_ID,
    BATTLE_PASS_ITEM_IDS,
    BATTLE_PASS_PLUS_ITEM_ID,
    read_item_prices,
)
from app.services.streak_protection import require_request_id
from app.services.wallet_funding import move_currency, resolved_buckets

SEASON_ID = "season_1"
ALREADY_OWNED = "Battle pass already owned for this season."
NOT_SPENT = "Battle pass is not spent."
PAID_SHORT = "Insufficient paid Diamond balance."
UPGRADE_INVALID = "Pass upgrade price is invalid."

# Cosmetic only. No amounts, no currency, no rank.
PASS_REWARDS = (
    {"id": "season1_frame", "kind": "frame", "title": "시즌 1 프레임"},
    {"id": "season1_badge", "kind": "badge", "title": "시즌 1 배지"},
)
PLUS_REWARDS = (
    {"id": "season1_plus_frame", "kind": "frame", "title": "시즌 1 플러스 프레임"},
    {"id": "season1_skin", "kind": "skin", "title": "시즌 1 스킨"},
    {"id": "season1_plus_badge", "kind": "badge", "title": "시즌 1 플러스 배지"},
)


def reward_rows(tier: str) -> list[dict]:
    source = PASS_REWARDS if tier == "pass" else (*PASS_REWARDS, *PLUS_REWARDS)
    return [
        {"id": row["id"], "kind": row["kind"], "title": row["title"]}
        for row in source
    ]


def owned_tier(doc: dict | None) -> str:
    """``pass`` or ``plus`` for this season. A legacy quantity is a pass."""
    if not isinstance(doc, dict):
        return ""
    season = doc.get("seasonId")
    if isinstance(season, str) and season and season != SEASON_ID:
        return ""
    tier = doc.get("tier")
    if tier in ("pass", "plus"):
        return tier
    quantity = doc.get("quantity") or 0
    if isinstance(quantity, bool) or not isinstance(quantity, int):
        return ""
    if quantity >= 1:
        return "pass"
    return ""


def purchase_battle_pass(
    service,
    transaction,
    uid: str,
    item_id: str,
    request_id: str,
    user_ref,
) -> SecuredActionResult:
    request_id = require_request_id(request_id)
    if item_id not in BATTLE_PASS_ITEM_IDS:
        raise HTTPException(status_code=404, detail="Shop item not found.")
    prices = read_item_prices(service.firebase_service.db, transaction)
    catalog = service.SHOP_CATALOG.get(item_id)
    if catalog is None or item_id not in prices:
        raise HTTPException(status_code=404, detail="Shop item not found.")
    pass_cost = int(prices[BATTLE_PASS_ITEM_ID])
    plus_cost = int(prices[BATTLE_PASS_PLUS_ITEM_ID])

    ledger_ref = service.firebase_service.db.collection("walletTransactions").document(
        f"battle_pass_{uid}_{request_id}"
    )
    if ledger_ref.get(transaction=transaction).exists:
        user = _user(user_ref, transaction)
        return _wallet_result(user, "already_purchased", "Purchase already recorded.")

    user = _user(user_ref, transaction)
    inventory_ref = user_ref.collection("shopInventory").document(BATTLE_PASS_ITEM_ID)
    snapshot = inventory_ref.get(transaction=transaction)
    owned = owned_tier(snapshot.to_dict() if snapshot.exists else None)
    tier, cost = _quote(item_id, owned, pass_cost, plus_cost)

    wallet = user.get("wallet") or {}
    paid = int(resolved_buckets(wallet)["paid_diamond"])
    if paid < cost:
        raise HTTPException(status_code=400, detail=PAID_SHORT)
    moved = move_currency(wallet, diamond=-cost, paid_only=True)
    rewards = reward_rows(tier)
    transaction.update(
        user_ref,
        {**moved["updates"], "updatedAt": SERVER_TIMESTAMP},
    )
    transaction.set(
        inventory_ref,
        {
            "itemId": BATTLE_PASS_ITEM_ID,
            "title": service.SHOP_CATALOG[BATTLE_PASS_ITEM_ID]["title"],
            "quantity": 1,
            "seasonId": SEASON_ID,
            "tier": tier,
            "rewards": rewards,
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
            "seasonId": SEASON_ID,
            "tier": tier,
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


def _quote(item_id: str, owned: str, pass_cost: int, plus_cost: int) -> tuple[str, int]:
    if item_id == BATTLE_PASS_ITEM_ID:
        if owned:
            raise HTTPException(status_code=400, detail=ALREADY_OWNED)
        return "pass", pass_cost
    if owned == "plus":
        raise HTTPException(status_code=400, detail=ALREADY_OWNED)
    if owned == "pass":
        gap = plus_cost - pass_cost
        if gap < 1:
            raise HTTPException(status_code=400, detail=UPGRADE_INVALID)
        return "plus", gap
    return "plus", plus_cost


def _user(user_ref, transaction) -> dict:
    snapshot = user_ref.get(transaction=transaction)
    if not snapshot.exists:
        raise HTTPException(status_code=404, detail="User not found.")
    return snapshot.to_dict() or {}


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
