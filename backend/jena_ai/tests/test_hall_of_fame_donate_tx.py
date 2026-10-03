"""Hall of Fame 500 VALUE donation and its ledger row share one transaction."""

from types import SimpleNamespace

from fastapi import HTTPException
import pytest

from app.services.secured_action_service import (
    SecuredActionService,
    _commit_hall_of_fame_donate_tx,
)
from test_redeem_referral import _MemoryDb, _MemoryTxn


def _donate(db: _MemoryDb, service: SecuredActionService):
    user_ref = db.collection("users").document("u1")
    return _commit_hall_of_fame_donate_tx.to_wrap(
        _MemoryTxn(),
        service,
        "u1",
        user_ref,
    )


def test_hall_of_fame_donate_appends_negative_value_row() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {
        "wallet": {"valueTokenBalance": 1000, "totalDonationValue": 20}
    }
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))

    result = _donate(db, service)

    assert result.status == "donated"
    assert result.value_token_balance == 500
    wallet = db.store["users/u1"]["wallet"]
    assert wallet["valueTokenBalance"] == 500
    assert wallet["totalDonationValue"] == 520
    ledger = [
        row
        for path, row in db.store.items()
        if path.startswith("walletTransactions/")
    ]
    assert len(ledger) == 1
    assert ledger[0]["type"] == "hall_of_fame_donation"
    assert ledger[0]["valueAmount"] == -500


def test_hall_of_fame_donate_rejects_insufficient_value() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {"wallet": {"valueTokenBalance": 100}}
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))

    with pytest.raises(HTTPException) as exc:
        _donate(db, service)

    assert exc.value.status_code == 400
    assert db.store["users/u1"]["wallet"]["valueTokenBalance"] == 100
    assert not any(path.startswith("walletTransactions/") for path in db.store)
