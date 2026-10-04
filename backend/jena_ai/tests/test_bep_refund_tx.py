"""BEP refunds credit SHARE inside one transaction, once per participant."""

from types import SimpleNamespace
from unittest.mock import patch

import pytest
from fastapi import HTTPException

from app.services.ops_service import (
    OpsService,
    _commit_bep_refund_tx,
    bep_refund_ledger_id,
)
from test_redeem_referral import _MemoryDb, _MemoryTxn


def _seed(db: _MemoryDb) -> None:
    db.store["tournaments/t1"] = {
        "status": "recruiting",
        "participantCount": 1,
        "minParticipantsBep": 50,
    }
    db.store["tournaments/t1/participants/u1"] = {
        "uid": "u1",
        "status": "joined",
        "entryFeeShare": 200,
    }
    db.store["users/u1"] = {
        "wallet": {
            "shareBalance": 100,
            "freeShareBalance": 100,
            "paidShareBalance": 0,
        }
    }


def test_bep_refund_credits_once_inside_the_transaction() -> None:
    db = _MemoryDb()
    _seed(db)
    service = OpsService(firebase_service=SimpleNamespace(db=db))

    count, total = _commit_bep_refund_tx.to_wrap(_MemoryTxn(), service, "t1")

    assert count == 1
    assert total == 200
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 300
    assert db.store["tournaments/t1"]["status"] == "cancelled_bep_not_met"
    assert db.store["tournaments/t1/participants/u1"]["refundStatus"] == "refunded"
    ledger_id = bep_refund_ledger_id("t1", "u1")
    ledger = db.store[f"walletTransactions/{ledger_id}"]
    assert ledger["type"] == "bep_refund"
    assert ledger["shareAmount"] == 200

    again_count, again_total = _commit_bep_refund_tx.to_wrap(
        _MemoryTxn(), service, "t1"
    )
    assert again_count == 0
    assert again_total == 0
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 300
    assert (
        sum(1 for path in db.store if path.startswith("walletTransactions/")) == 1
    )


def test_bep_refund_rejects_when_minimum_is_met() -> None:
    db = _MemoryDb()
    _seed(db)
    db.store["tournaments/t1"]["participantCount"] = 50
    service = OpsService(firebase_service=SimpleNamespace(db=db))

    with pytest.raises(HTTPException) as exc_info:
        _commit_bep_refund_tx.to_wrap(_MemoryTxn(), service, "t1")

    assert exc_info.value.status_code == 400
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 100
    assert not any(path.startswith("walletTransactions/") for path in db.store)


@patch("app.services.ops_service.send_tournament_topic_notification")
def test_cancel_bep_calls_module_transaction(mock_notify) -> None:
    db = _MemoryDb()
    service = OpsService(firebase_service=SimpleNamespace(db=db))
    seen: dict = {}

    def fake(transaction, service_arg, tournament_id):
        seen["service"] = service_arg
        seen["tournament_id"] = tournament_id
        return 2, 40

    with patch("app.services.ops_service._commit_bep_refund_tx", fake):
        result = service.cancel_bep_and_refund("t1")

    assert result.refunded_participants == 2
    assert result.refunded_share_total == 40
    assert seen["service"] is service
    assert seen["tournament_id"] == "t1"
    mock_notify.assert_called_once()
