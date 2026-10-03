"""Signup VALUE credit and its ledger row share one transaction."""

from types import SimpleNamespace

from app.services.secured_action_service import (
    SecuredActionService,
    _commit_signup_reward_tx,
)
from test_redeem_referral import _MemoryDb, _MemoryTxn


def _claim(db: _MemoryDb, service: SecuredActionService):
    user_ref = db.collection("users").document("u1")
    return _commit_signup_reward_tx.to_wrap(_MemoryTxn(), service, "u1", user_ref)


def test_signup_appends_positive_value_row_once() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {
        "economy": {},
        "wallet": {"valueTokenBalance": 5},
    }
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))

    result = _claim(db, service)

    assert result.status == "claimed"
    assert db.store["users/u1"]["wallet"]["valueTokenBalance"] == 105
    assert db.store["users/u1"]["economy"]["signupRewardClaimed"] is True
    ledger = [
        row
        for path, row in db.store.items()
        if path.startswith("walletTransactions/")
    ]
    assert len(ledger) == 1
    assert ledger[0]["type"] == "onboarding_signup_reward"
    assert ledger[0]["valueAmount"] == 100

    again = _claim(db, service)
    assert again.status == "already_claimed"
    assert db.store["users/u1"]["wallet"]["valueTokenBalance"] == 105
    assert (
        sum(1 for path in db.store if path.startswith("walletTransactions/"))
        == 1
    )
