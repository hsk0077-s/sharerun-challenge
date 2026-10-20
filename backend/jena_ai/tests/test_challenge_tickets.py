"""Challenge ticket: earned SHARE or free DIA only, charged once."""

from datetime import datetime, timedelta, timezone
from types import SimpleNamespace

from fastapi import HTTPException
import pytest

from app.services.secured_action_service import (
    SecuredActionService,
    _commit_challenge_ticket_tx,
)
from test_redeem_referral import _MemoryDb, _MemoryTxn


def _service(db: _MemoryDb) -> SecuredActionService:
    return SecuredActionService(firebase_service=SimpleNamespace(db=db))


def _user(**wallet) -> dict:
    base = {
        "shareBalance": 3_000,
        "freeShareBalance": 3_000,
        "paidShareBalance": 0,
        "diamondBalance": 5,
        "freeDiamondBalance": 5,
        "paidDiamondBalance": 0,
        "valueTokenBalance": 0,
    }
    base.update(wallet)
    return {"wallet": base}


def _buy(db: _MemoryDb, pay_with: str | None, request_id: str = "r1"):
    service = _service(db)
    user_ref = db.collection("users").document("u1")
    return _commit_challenge_ticket_tx.to_wrap(
        _MemoryTxn(), service, "u1", pay_with, request_id, user_ref
    )


def _held(db: _MemoryDb) -> int:
    row = db.store.get("users/u1/shopInventory/challenge_ticket") or {}
    return row.get("quantity", 0)


def test_buys_with_earned_share() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _user()
    result = _buy(db, "share")
    assert result.status == "purchased" and result.share_balance == 1_800
    assert _held(db) == 1
    ledger = db.store["walletTransactions/shop_buy_u1_challenge_ticket_r1"]
    assert ledger["shareAmount"] == -1_200 and ledger["payWith"] == "share"


def test_buys_with_one_free_dia() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _user()
    result = _buy(db, "dia")
    assert result.diamond_balance == 4 and _held(db) == 1


def test_retry_with_same_request_id_charges_once() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _user()
    _buy(db, "share")
    again = _buy(db, "share")
    assert again.status == "already_purchased"
    assert _held(db) == 1
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 1_800


def test_paid_dia_cannot_pay() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _user(
        diamondBalance=50, freeDiamondBalance=0, paidDiamondBalance=50
    )
    with pytest.raises(HTTPException) as caught:
        _buy(db, "dia")
    assert caught.value.status_code == 400
    assert _held(db) == 0
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 50


def test_paid_share_cannot_pay() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _user(
        shareBalance=5_000, freeShareBalance=500, paidShareBalance=4_500
    )
    with pytest.raises(HTTPException):
        _buy(db, "share")
    assert _held(db) == 0


def test_locked_referral_share_cannot_pay() -> None:
    db = _MemoryDb()
    later = (datetime.now(timezone.utc) + timedelta(days=10)).isoformat()
    db.store["users/u1"] = _user(
        shareBalance=1_500,
        freeShareBalance=1_500,
        lockedReferralShare=1_000,
        referralShareLocks=[{"amount": 1_000, "unlockAt": later}],
    )
    with pytest.raises(HTTPException):
        _buy(db, "share")
    assert _held(db) == 0


def test_must_choose_a_currency() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _user()
    with pytest.raises(HTTPException) as caught:
        _buy(db, None)
    assert caught.value.status_code == 400
