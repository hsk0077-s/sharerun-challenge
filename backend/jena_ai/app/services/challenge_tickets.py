"""Challenge ticket: the right to enter one tier tournament a step above.

Bought with earned SHARE or one free DIA. Cash-bought (paid) DIA and referral
SHARE that is still locked can never pay for it, so money cannot buy a way up.
The spend and the inventory change commit together; the same ``request_id``
on a retry returns the first result and never charges twice. Entering a
tournament with the ticket is a separate step.
"""

from fastapi import HTTPException
from google.cloud.firestore_v1 import SERVER_TIMESTAMP

from app.models.secured_actions import SecuredActionResult
from app.services.item_price_config import (
    CHALLENGE_TICKET_DIA_ID,
    CHALLENGE_TICKET_ITEM_ID,
    CHALLENGE_TICKET_SHARE_ID,
    read_item_prices,
)
from app.services.share_activity_items import (
    _balances,
    _exists,
    _ledger_ref,
    _quantity,
    _user,
    _wallet_result,
)
from app.services.wallet_funding import move_currency

CHALLENGE_TICKET_TITLE = "도전 입장권"
PAY_WITH_SHARE = "share"
PAY_WITH_DIA = "dia"


def purchase_challenge_ticket(
    service,
    transaction,
    uid: str,
    pay_with: str | None,
    request_id: str,
    user_ref,
) -> SecuredActionResult:
    method = (pay_with or "").strip().lower()
    if method not in {PAY_WITH_SHARE, PAY_WITH_DIA}:
        raise HTTPException(status_code=400, detail="Choose SHARE or free DIA.")
    prices = read_item_prices(service.firebase_service.db, transaction)
    ledger_ref = _ledger_ref(
        service, f"shop_buy_{uid}_{CHALLENGE_TICKET_ITEM_ID}_{request_id}"
    )
    user = _user(user_ref, transaction)
    if _exists(ledger_ref, transaction):
        return _wallet_result(user, "already_purchased", "Purchase already recorded.")

    wallet = user.get("wallet")
    if not isinstance(wallet, dict):
        wallet = {}
        user["wallet"] = wallet
    if method == PAY_WITH_SHARE:
        cost = int(prices[CHALLENGE_TICKET_SHARE_ID])
        moved = move_currency(wallet, share=-cost, free_only=True, for_exchange=True)
        amounts = {"shareAmount": -cost}
    else:
        cost = int(prices[CHALLENGE_TICKET_DIA_ID])
        moved = move_currency(wallet, diamond=-cost, free_only=True)
        amounts = {"diamondAmount": -cost}

    inventory_ref = user_ref.collection("shopInventory").document(
        CHALLENGE_TICKET_ITEM_ID
    )
    held = _quantity(inventory_ref, transaction) + 1
    transaction.update(
        user_ref,
        {**moved["updates"], "updatedAt": SERVER_TIMESTAMP},
    )
    transaction.set(
        inventory_ref,
        {
            "itemId": CHALLENGE_TICKET_ITEM_ID,
            "title": CHALLENGE_TICKET_TITLE,
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
            "itemId": CHALLENGE_TICKET_ITEM_ID,
            "payWith": method,
            "quantityAmount": 1,
            "requestId": request_id,
            "createdAt": SERVER_TIMESTAMP,
            **amounts,
            **moved["ledger"],
        },
    )
    share, diamonds, value = _balances(wallet)
    return SecuredActionResult(
        accepted=True,
        status="purchased",
        reason=f"Purchased {CHALLENGE_TICKET_TITLE}.",
        share_balance=share,
        diamond_balance=diamonds,
        value_token_balance=value,
    )
