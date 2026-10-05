"""Crew founding and challenge-room create debit SHARE and append a ledger row."""

from types import SimpleNamespace

from fastapi import HTTPException
import pytest

from app.services.secured_action_service import (
    SecuredActionService,
    _commit_create_room_tx,
    _commit_crew_found_tx,
)
from test_redeem_referral import _MemoryDb, _MemoryTxn


def _service(db: _MemoryDb) -> SecuredActionService:
    return SecuredActionService(firebase_service=SimpleNamespace(db=db))


def test_found_crew_debits_30000_share_and_keeps_other_balances() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {
        "wallet": {
            "shareBalance": 1_000_000,
            "diamondBalance": 1_000_000,
            "valueTokenBalance": 1_000_000,
        }
    }
    service = _service(db)
    user_ref = db.collection("users").document("u1")
    crew_ref = db.collection("crews").document("crew1")

    result = _commit_crew_found_tx.to_wrap(
        _MemoryTxn(),
        service,
        "u1",
        "우리크루",
        "share",
        "req-crew-01",
        user_ref,
        crew_ref,
    )

    assert result.share_balance == 970_000
    assert result.diamond_balance == 1_000_000
    assert db.store["users/u1"]["wallet"]["valueTokenBalance"] == 1_000_000
    assert db.store["users/u1"]["ownedCrewId"] == "crew1"
    assert db.store["crews/crew1"]["shareCost"] == 30000
    assert db.store["crews/crew1"]["diaCost"] == 0
    ledger = [
        row for path, row in db.store.items() if path.startswith("walletTransactions/")
    ]
    assert ledger[0]["type"] == "crew_create"
    assert ledger[0]["shareAmount"] == -30000


def test_create_room_uses_server_fee_for_3km() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {
        "wallet": {
            "shareBalance": 1_000_000,
            "diamondBalance": 1_000_000,
            "valueTokenBalance": 1_000_000,
        }
    }
    service = _service(db)
    user_ref = db.collection("users").document("u1")
    room_ref = db.collection("tournaments").document("room1")

    result = _commit_create_room_tx.to_wrap(
        _MemoryTxn(), service, "u1", "아침 3km", 3, user_ref, room_ref
    )

    assert result.entry_fee_share == 600_000
    assert result.tournament_id == "room1"
    assert result.share_balance == 400_000
    assert result.diamond_balance == 1_000_000
    assert db.store["tournaments/room1"]["entryFeeShare"] == 600_000
    assert db.store["tournaments/room1"]["userCreated"] is True
    ledger = [
        row for path, row in db.store.items() if path.startswith("walletTransactions/")
    ]
    assert ledger[0]["type"] == "challenge_room_create"
    assert ledger[0]["shareAmount"] == -600_000


def test_short_share_creates_nothing() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {"wallet": {"shareBalance": 10}}
    service = _service(db)
    user_ref = db.collection("users").document("u1")
    with pytest.raises(HTTPException):
        _commit_crew_found_tx.to_wrap(
            _MemoryTxn(),
            service,
            "u1",
            "우리크루",
            "share",
            "req-crew-short",
            user_ref,
            db.collection("crews").document("crew1"),
        )
    assert "crews/crew1" not in db.store
    assert not any(path.startswith("walletTransactions/") for path in db.store)
