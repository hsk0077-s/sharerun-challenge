"""Winner claim debits only the donation, with a matching ledger row."""

from types import SimpleNamespace

from app.models.secured_actions import WinnerRewardRequest
from app.services.secured_action_service import (
    SecuredActionService,
    _commit_winner_tx,
)
from test_redeem_referral import _MemoryDb, _MemoryTxn


def _claim(db: _MemoryDb, service: SecuredActionService, action: str):
    user_ref = db.collection("users").document("u1")
    activity_ref = db.collection("activities").document("a1")
    request = WinnerRewardRequest(activity_id="a1", action=action)
    return _commit_winner_tx.to_wrap(
        _MemoryTxn(),
        service,
        "u1",
        request,
        user_ref,
        activity_ref,
    )


def _seed(db: _MemoryDb, balance: int = 100) -> None:
    db.store["users/u1"] = {
        "wallet": {"valueTokenBalance": balance, "totalDonationValue": 0},
    }
    db.store["activities/a1"] = {
        "userId": "u1",
        "jenaVerified": True,
        "valueTokenReward": 100,
        "rewardClaimed": False,
    }


def _ledger(db: _MemoryDb) -> list[dict]:
    return [
        row
        for path, row in db.store.items()
        if path.startswith("walletTransactions/")
    ]


def test_donate_half_writes_negative_value_row() -> None:
    db = _MemoryDb()
    _seed(db)
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))

    result = _claim(db, service, "winner_reward_donate_half")

    assert result.status == "reward_processed"
    assert db.store["users/u1"]["wallet"]["valueTokenBalance"] == 50
    ledger = _ledger(db)
    assert len(ledger) == 1
    assert ledger[0]["valueAmount"] == -50
    assert ledger[0]["donatedValue"] == 50

    again = _claim(db, service, "winner_reward_donate_half")
    assert again.status == "reward_processed"
    assert again.reason == "Winner reward was already processed."
    assert db.store["users/u1"]["wallet"]["valueTokenBalance"] == 50
    assert len(_ledger(db)) == 1


def test_claim_all_writes_zero_because_validation_already_credited() -> None:
    db = _MemoryDb()
    _seed(db, balance=100)
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))

    result = _claim(db, service, "winner_reward_claim_all")

    assert result.status == "reward_processed"
    assert db.store["users/u1"]["wallet"]["valueTokenBalance"] == 100
    ledger = _ledger(db)
    assert len(ledger) == 1
    assert ledger[0]["valueAmount"] == 0
