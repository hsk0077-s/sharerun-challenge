"""Personal sponsor donation (angel / 개인 후원).

The phone does not write donation totals or SHARE. One transaction debits
SHARE (free first, then paid), appends one ``walletTransactions`` row, and
stores the new angel totals. The price is
``config/item_prices.personal_sponsor_share`` (default 50,000). One SHARE
counts as ``personal_sponsor_won_per_share`` won (default 1). A repeated
``request_id`` does not charge again.

Angel thresholds match the Flutter ``AngelTierX.resolve`` ladder.
"""

from fastapi import HTTPException
from google.cloud.firestore_v1 import SERVER_TIMESTAMP

from app.models.secured_actions import PersonalSponsorResult
from app.services.item_price_config import (
    PERSONAL_SPONSOR_SHARE_ID,
    PERSONAL_SPONSOR_WON_PER_SHARE_ID,
    read_item_prices,
)
from app.services.streak_protection import require_request_id
from app.services.wallet_funding import move_currency

_PURPOSES = {
    "donation": "personal_sponsor_donation",
    "prize": "personal_sponsor_prize",
}
# (min count, min won, code). First match wins. Count 0 stays pre-angel.
_TIER_LADDER = (
    (100, 5_000_000, "seraphim"),
    (50, 1_000_000, "cherubim"),
    (20, 300_000, "archangel"),
    (5, 50_000, "guardian"),
)


def donate_personal_sponsor(
    service,
    transaction,
    uid: str,
    request_id: str,
    purpose: str,
    user_ref,
) -> PersonalSponsorResult:
    request_id = require_request_id(request_id)
    tx_type = _PURPOSES.get(purpose)
    if tx_type is None:
        raise HTTPException(status_code=400, detail="Invalid sponsor purpose.")

    prices = read_item_prices(service.firebase_service.db, transaction)
    share_cost = int(prices[PERSONAL_SPONSOR_SHARE_ID])
    won_per_share = int(prices[PERSONAL_SPONSOR_WON_PER_SHARE_ID])
    ledger_ref = service.firebase_service.db.collection("walletTransactions").document(
        f"personal_sponsor_{uid}_{request_id}"
    )
    existing = ledger_ref.get(transaction=transaction)
    user_snapshot = user_ref.get(transaction=transaction)
    if not user_snapshot.exists:
        raise HTTPException(status_code=404, detail="User not found.")
    user = user_snapshot.to_dict() or {}
    wallet = dict(user.get("wallet") or {})
    if existing.exists:
        row = existing.to_dict() or {}
        return _result(
            user,
            wallet,
            status="already_sponsored",
            reason="Personal sponsor donation already recorded.",
            share_spent=abs(int(row.get("shareAmount") or 0)),
        )

    moved = move_currency(wallet, share=-share_cost)
    count = max(0, int(user.get("donationCount") or 0)) + 1
    amount = max(0, int(user.get("cumulativeDonationAmount") or 0)) + (
        share_cost * won_per_share
    )
    tier = angel_tier_code(count, amount)
    transaction.update(
        user_ref,
        {
            **moved["updates"],
            "donationCount": count,
            "cumulativeDonationAmount": amount,
            "isSponsored": True,
            "angelTierCode": tier,
            "updatedAt": SERVER_TIMESTAMP,
        },
    )
    transaction.set(
        ledger_ref,
        {
            "uid": uid,
            "type": tx_type,
            "purpose": purpose,
            "requestId": request_id,
            "shareAmount": -share_cost,
            "donationCount": count,
            "cumulativeDonationAmount": amount,
            "angelTierCode": tier,
            "createdAt": SERVER_TIMESTAMP,
            **moved["ledger"],
        },
    )
    confirmed = {
        **user,
        "donationCount": count,
        "cumulativeDonationAmount": amount,
        "isSponsored": True,
        "angelTierCode": tier,
    }
    return _result(
        confirmed,
        wallet,
        status="sponsored",
        reason="Personal sponsor donation recorded.",
        share_spent=share_cost,
    )


def angel_tier_code(donation_count: int, cumulative_won: int) -> str:
    count = donation_count if donation_count > 0 else 0
    amount = cumulative_won if cumulative_won > 0 else 0
    if count == 0:
        return "pre_angel"
    for min_count, min_won, code in _TIER_LADDER:
        if count >= min_count or amount >= min_won:
            return code
    return "cupid"


def _result(
    user: dict,
    wallet: dict,
    *,
    status: str,
    reason: str,
    share_spent: int,
) -> PersonalSponsorResult:
    count = int(user.get("donationCount") or 0)
    amount = int(user.get("cumulativeDonationAmount") or 0)
    tier = user.get("angelTierCode") or angel_tier_code(count, amount)
    return PersonalSponsorResult(
        accepted=True,
        status=status,
        reason=reason,
        share_spent=share_spent,
        donation_count=count,
        cumulative_donation_amount=amount,
        angel_tier_code=str(tier),
        is_sponsored=user.get("isSponsored") is True,
        share_balance=int(wallet.get("shareBalance") or 0),
        diamond_balance=int(wallet.get("diamondBalance") or 0),
        value_token_balance=int(wallet.get("valueTokenBalance") or 0),
    )
