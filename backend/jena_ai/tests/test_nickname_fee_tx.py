"""Nickname change debits 100 DIA and stores the name in one transaction."""

from types import SimpleNamespace

from fastapi import HTTPException
import pytest

from app.services.secured_action_service import SecuredActionService, _commit_nickname_tx
from test_redeem_referral import _MemoryDb, _MemoryTxn


def _rename(db: _MemoryDb, nickname: str):
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))
    user_ref = db.collection("users").document("u1")
    return _commit_nickname_tx.to_wrap(
        _MemoryTxn(), service, "u1", nickname, user_ref
    )


def test_nickname_change_debits_100_and_keeps_share() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {
        "wallet": {
            "shareBalance": 1_000_000,
            "diamondBalance": 1_000_000,
            "valueTokenBalance": 1_000_000,
        }
    }

    result = _rename(db, "새이름")

    assert result.diamond_balance == 999_900
    assert result.share_balance == 1_000_000
    assert db.store["users/u1"]["nickname"] == "새이름"
    assert db.store["users/u1"]["wallet"]["valueTokenBalance"] == 1_000_000
    ledger = [
        row for path, row in db.store.items() if path.startswith("walletTransactions/")
    ]
    assert ledger[0]["type"] == "nickname_change"
    assert ledger[0]["diamondAmount"] == -100


def test_short_dia_does_not_rename() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {"wallet": {"diamondBalance": 10}, "nickname": "기존"}
    with pytest.raises(HTTPException) as raised:
        _rename(db, "새이름")
    assert raised.value.status_code == 400
    assert db.store["users/u1"]["nickname"] == "기존"
    assert not any(path.startswith("walletTransactions/") for path in db.store)
