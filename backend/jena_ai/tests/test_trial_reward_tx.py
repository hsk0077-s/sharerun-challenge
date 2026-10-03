"""Trial completion SHARE credit and its ledger row share one transaction."""

from types import SimpleNamespace

from app.services.secured_action_service import (
    SecuredActionService,
    _commit_trial_reward_tx,
)
from test_redeem_referral import _MemoryDb, _MemoryTxn


def _claim(service: SecuredActionService):
    user_ref = service.firebase_service.db.collection("users").document("u1")
    return _commit_trial_reward_tx.to_wrap(_MemoryTxn(), service, "u1", user_ref)


def test_trial_credits_500_share_once_per_account() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {
        "economy": {"signupRewardClaimed": True},
        "wallet": {
            "shareBalance": 1_000_000,
            "diamondBalance": 1_000_000,
        },
    }
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))

    result = _claim(service)

    assert result.status == "claimed"
    assert result.share_credited == 500
    assert result.share_balance == 1_000_500
    assert result.diamond_balance == 1_000_000
    user = db.store["users/u1"]
    assert user["wallet"]["shareBalance"] == 1_000_500
    assert user["wallet"]["diamondBalance"] == 1_000_000
    assert user["economy"]["trialMilestoneRewardClaimed"] is True
    assert user["economy"]["signupRewardClaimed"] is True
    ledger = [
        row
        for path, row in db.store.items()
        if path.startswith("walletTransactions/")
    ]
    assert len(ledger) == 1
    assert ledger[0]["type"] == "trial_completion_reward"
    assert ledger[0]["shareAmount"] == 500

    again = _claim(service)
    assert again.status == "already_claimed"
    assert again.share_balance == 1_000_500
    assert user["wallet"]["shareBalance"] == 1_000_500
    assert (
        sum(1 for path in db.store if path.startswith("walletTransactions/"))
        == 1
    )
