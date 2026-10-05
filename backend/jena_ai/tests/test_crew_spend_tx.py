"""Crew manager spends debit the server price and append one ledger row."""

from types import SimpleNamespace

from fastapi import HTTPException
import pytest

from app.services.secured_action_service import SecuredActionService, _commit_crew_spend_tx
from test_redeem_referral import _MemoryDb, _MemoryTxn


def _spend(db: _MemoryDb, action: str):
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))
    user_ref = db.collection("users").document("u1")
    return _commit_crew_spend_tx.to_wrap(
        _MemoryTxn(), service, "u1", action, user_ref
    )


def _wallet():
    return {
        "shareBalance": 1_000_000,
        "diamondBalance": 1_000_000,
        "valueTokenBalance": 1_000_000,
    }


def test_profile_pass_and_expand_debit_dia() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {"wallet": _wallet()}

    profile = _spend(db, "profile")
    assert profile.diamond_balance == 999_900
    passed = _spend(db, "pass")
    assert passed.diamond_balance == 999_850
    expanded = _spend(db, "expand")
    assert expanded.diamond_balance == 999_550
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 1_000_000
    assert db.store["users/u1"]["wallet"]["valueTokenBalance"] == 1_000_000

    types = [
        row["type"]
        for path, row in db.store.items()
        if path.startswith("walletTransactions/")
    ]
    assert types == [
        "crew_profile_change",
        "crew_challenge_pass",
        "crew_member_expand",
    ]


def test_deposit_debits_share_only() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {"wallet": _wallet()}

    result = _spend(db, "deposit")

    assert result.share_balance == 900_000
    assert result.diamond_balance == 1_000_000
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 1_000_000
    ledger = [
        row
        for path, row in db.store.items()
        if path.startswith("walletTransactions/")
    ]
    assert ledger[0]["type"] == "crew_deposit"
    assert ledger[0]["shareAmount"] == -100_000


def test_unknown_action_and_short_balance_write_no_ledger() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {"wallet": {"diamondBalance": 10, "shareBalance": 10}}
    with pytest.raises(HTTPException) as unknown:
        _spend(db, "nope")
    assert unknown.value.status_code == 404
    with pytest.raises(HTTPException) as short:
        _spend(db, "profile")
    assert short.value.status_code == 400
    assert not any(path.startswith("walletTransactions/") for path in db.store)
