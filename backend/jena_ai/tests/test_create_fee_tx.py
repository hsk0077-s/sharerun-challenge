"""Crew founding and challenge-room create debit SHARE and append a ledger row."""

from types import SimpleNamespace

from fastapi import HTTPException
import pytest

from app.models.secured_actions import JoinTournamentRequest
from app.services.secured_action_service import (
    SecuredActionService,
    _challenge_entry_fee,
    _commit_create_room_tx,
    _commit_crew_found_tx,
    _commit_join_tx,
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

    assert result.entry_fee_share == 1_200
    assert result.tournament_id == "room1"
    assert result.share_balance == 998_800
    assert result.diamond_balance == 1_000_000
    assert db.store["tournaments/room1"]["entryFeeShare"] == 1_200
    assert db.store["tournaments/room1"]["winnerRewardValue"] == 0
    assert db.store["tournaments/room1"]["donationValue"] == 0
    assert db.store["tournaments/room1"]["userCreated"] is True
    ledger = [
        row for path, row in db.store.items() if path.startswith("walletTransactions/")
    ]
    assert ledger[0]["type"] == "challenge_room_create"
    assert ledger[0]["shareAmount"] == -1_200
    assert db.store["tournaments/room1/participants/u1"]["status"] == "joined"
    assert db.store["tournaments/room1/participants/u1"]["entryFeeShare"] == 1_200

    joined = _commit_join_tx.to_wrap(
        _MemoryTxn(),
        service,
        "u1",
        JoinTournamentRequest(tournament_id="room1"),
        user_ref,
        room_ref,
        room_ref.collection("participants").document("u1"),
    )
    assert joined.status == "already_joined"
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 998_800
    assert (
        sum(1 for path in db.store if path.startswith("walletTransactions/")) == 1
    )


def test_creator_join_without_a_participant_doc_does_not_charge_again() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {
        "tier": 1,
        "wallet": {"shareBalance": 400_000, "diamondBalance": 0, "valueTokenBalance": 0},
    }
    db.store["tournaments/room1"] = {
        "status": "recruiting",
        "userCreated": True,
        "createdByUid": "u1",
        "entryFeeShare": 600_000,
        "participantCount": 1,
        "requiredTier": 1,
    }
    service = _service(db)
    user_ref = db.collection("users").document("u1")
    room_ref = db.collection("tournaments").document("room1")

    result = _commit_join_tx.to_wrap(
        _MemoryTxn(),
        service,
        "u1",
        JoinTournamentRequest(tournament_id="room1"),
        user_ref,
        room_ref,
        room_ref.collection("participants").document("u1"),
    )

    assert result.status == "already_joined"
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 400_000
    assert db.store["tournaments/room1"]["participantCount"] == 1
    assert db.store["tournaments/room1/participants/u1"]["status"] == "joined"
    assert not any(path.startswith("walletTransactions/") for path in db.store)


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


def test_user_room_fee_schedule() -> None:
    assert _challenge_entry_fee(1) == 600
    assert _challenge_entry_fee(3) == 1_200
    assert _challenge_entry_fee(5) == 1_800
    assert _challenge_entry_fee(10) == 3_000
    assert _challenge_entry_fee(15) == 3_600
    assert _challenge_entry_fee(20) == 4_200
    assert _challenge_entry_fee(0) == 600
