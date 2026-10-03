"""SHARE → DIA is one atomic ledger row with the report's locks."""

from datetime import datetime, timedelta, timezone
from types import SimpleNamespace

import pytest
from fastapi import HTTPException

from app.services.economy_service import EconomyService
from app.services.secured_action_service import (
    SecuredActionService,
    _commit_share_to_dia_tx,
)
from test_redeem_referral import _MemoryDb, _MemoryTxn


def _service(db: _MemoryDb) -> SecuredActionService:
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))
    service._auth_account_created_at = (
        lambda uid: datetime.now(timezone.utc) - timedelta(days=30)
    )
    service._ensure_email_verified = lambda uid: None
    return service


def _user(**wallet):
    return {
        "economy": {"lastVerifiedRunWeek": EconomyService().kst_week_key()},
        "wallet": {"diamondBalance": 0, "valueTokenBalance": 3, **wallet},
    }


def _exchange(db, service, dia: int):
    user_ref = db.collection("users").document("u1")
    return _commit_share_to_dia_tx.to_wrap(
        _MemoryTxn(), service, "u1", dia, user_ref
    )


def test_exchange_is_one_row_and_credits_free_dia() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _user(shareBalance=5_000)
    service = _service(db)

    result = _exchange(db, service, 10)

    assert result.status == "exchanged"
    assert result.remaining_dia == 10
    wallet = db.store["users/u1"]["wallet"]
    assert wallet["shareBalance"] == 3_800
    assert wallet["freeShareBalance"] == 3_800
    assert wallet["diamondBalance"] == 10
    assert wallet["freeDiamondBalance"] == 10
    assert wallet["paidDiamondBalance"] == 0
    assert wallet["valueTokenBalance"] == 3
    ledger = [
        row
        for path, row in db.store.items()
        if path.startswith("walletTransactions/")
    ]
    assert len(ledger) == 1
    assert ledger[0]["type"] == "share_to_dia"
    assert ledger[0]["shareAmount"] == -1_200
    assert ledger[0]["diamondAmount"] == 10
    assert ledger[0]["diamondFreeAmount"] == 10


def test_weekly_cap_blocks_the_third_unit() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _user(shareBalance=10_000)
    service = _service(db)

    _exchange(db, service, 10)
    _exchange(db, service, 10)
    with pytest.raises(HTTPException) as exc:
        _exchange(db, service, 10)
    assert "한도" in exc.value.detail
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 20


def test_signup_lock_and_referral_share_are_not_exchangeable() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _user(shareBalance=5_000)
    service = _service(db)
    service._auth_account_created_at = (
        lambda uid: datetime.now(timezone.utc) - timedelta(days=2)
    )
    with pytest.raises(HTTPException) as fresh:
        _exchange(db, service, 10)
    assert "7일" in fresh.value.detail
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 5_000

    service._auth_account_created_at = (
        lambda uid: datetime.now(timezone.utc) - timedelta(days=30)
    )
    unlock = (datetime.now(timezone.utc) + timedelta(days=30)).isoformat()
    db.store["users/u1"]["wallet"] = {
        "shareBalance": 2_000,
        "freeShareBalance": 2_000,
        "paidShareBalance": 0,
        "lockedReferralShare": 2_000,
        "referralShareLocks": [{"amount": 2_000, "unlockAt": unlock}],
        "diamondBalance": 0,
        "valueTokenBalance": 3,
    }
    with pytest.raises(HTTPException) as locked:
        _exchange(db, service, 10)
    assert "30일" in locked.value.detail
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 0
