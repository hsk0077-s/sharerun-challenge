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


def test_trial_requires_five_verified_runs() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {
        "economy": {"signupRewardClaimed": True, "trialRunCount": 4},
        "wallet": {
            "shareBalance": 1_000_000,
            "diamondBalance": 1_000_000,
        },
    }
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))

    early = _claim(service)

    assert early.status == "not_eligible"
    assert early.share_balance == 1_000_000
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 1_000_000
    assert "trialMilestoneRewardClaimed" not in db.store["users/u1"]["economy"]
    assert not any(path.startswith("walletTransactions/") for path in db.store)

    db.store["users/u1"]["economy"]["trialRunCount"] = 5
    result = _claim(service)

    assert result.status == "claimed"
    assert result.share_credited == 5_000
    assert result.share_balance == 1_005_000
    assert result.diamond_balance == 1_000_000
    user = db.store["users/u1"]
    assert user["wallet"]["shareBalance"] == 1_005_000
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
    assert ledger[0]["shareAmount"] == 5_000

    again = _claim(service)
    assert again.status == "already_claimed"
    assert again.share_balance == 1_005_000
    assert user["wallet"]["shareBalance"] == 1_005_000
    assert (
        sum(1 for path in db.store if path.startswith("walletTransactions/"))
        == 1
    )
