"""Tournament entry debits SHARE in the same transaction as its ledger row."""

from types import SimpleNamespace

import pytest
from fastapi import HTTPException

from app.models.secured_actions import JoinTournamentRequest
from app.services.secured_action_service import SecuredActionService, _commit_join_tx
from test_redeem_referral import _MemoryDb, _MemoryTxn


def _join(db: _MemoryDb, uid: str, tournament_id: str):
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))
    user_ref = db.collection("users").document(uid)
    tournament_ref = db.collection("tournaments").document(tournament_id)
    participant_ref = tournament_ref.collection("participants").document(uid)
    request = JoinTournamentRequest(tournament_id=tournament_id, diamond_deposit=0)
    return _commit_join_tx.to_wrap(
        _MemoryTxn(),
        service,
        uid,
        request,
        user_ref,
        tournament_ref,
        participant_ref,
    )


def test_join_writes_negative_ledger_with_the_debit() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {
        "tier": 1,
        "wallet": {"shareBalance": 1000, "diamondBalance": 8, "valueTokenBalance": 3},
    }
    db.store["tournaments/t1"] = {
        "status": "recruiting",
        "requiredTier": 1,
        "entryFeeShare": 200,
        "diamondDepositRequired": 0,
        "participantCount": 0,
    }
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))
    user_ref = db.collection("users").document("u1")
    tournament_ref = db.collection("tournaments").document("t1")
    participant_ref = tournament_ref.collection("participants").document("u1")
    request = JoinTournamentRequest(tournament_id="t1", diamond_deposit=0)

    result = _commit_join_tx.to_wrap(
        _MemoryTxn(),
        service,
        "u1",
        request,
        user_ref,
        tournament_ref,
        participant_ref,
    )

    assert result.status == "joined"
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 800
    ledger = next(
        row for path, row in db.store.items() if path.startswith("walletTransactions/")
    )
    assert ledger["type"] == "tournament_entry"
    assert ledger["shareAmount"] == -200
    assert ledger["diamondAmount"] == 0

    again = _commit_join_tx.to_wrap(
        _MemoryTxn(),
        service,
        "u1",
        request,
        user_ref,
        tournament_ref,
        participant_ref,
    )
    assert again.status == "already_joined"
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 800
    assert (
        sum(
            1
            for path in db.store
            if path.startswith("walletTransactions/")
        )
        == 1
    )


def test_missing_builtin_room_is_created_and_debited() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {
        "tier": 5,
        "wallet": {"shareBalance": 100000, "diamondBalance": 0, "valueTokenBalance": 0},
    }

    result = _join(db, "u1", "beginner-1km-room")

    room = db.store["tournaments/beginner-1km-room"]
    assert result.status == "joined"
    assert result.share_credited == -30000
    assert room["title"] == "1km 초보 챌린지"
    assert room["targetDistanceKm"] == 1.0
    assert room["entryFeeShare"] == 30000
    assert room["status"] == "recruiting"
    assert room["maxParticipants"] == 200
    assert room["minParticipantsBep"] == 100
    assert room["winnerRewardValue"] == 30000
    assert room["donationValue"] == 30000
    assert room["participantCount"] == 1
    assert "Increment" not in repr(room["participantCount"])
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 70000
    ledger = next(
        row for path, row in db.store.items() if path.startswith("walletTransactions/")
    )
    assert ledger["type"] == "tournament_entry"
    assert ledger["shareAmount"] == -30000
    assert ledger["tournamentId"] == "beginner-1km-room"

    again = _join(db, "u1", "beginner-1km-room")
    assert again.status == "already_joined"
    assert room["participantCount"] == 1
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 70000


def test_builtin_intermediate_keeps_tier_lock_and_fallback_ids() -> None:
    db = _MemoryDb()
    db.store["users/gold"] = {
        "tier": 3,
        "wallet": {"shareBalance": 200000, "diamondBalance": 0, "valueTokenBalance": 0},
    }
    with pytest.raises(HTTPException) as locked:
        _join(db, "gold", "intermediate-3km-room")
    assert locked.value.status_code == 403
    assert "tournaments/intermediate-3km-room" not in db.store

    db.store["users/rookie"] = {
        "tier": 1,
        "wallet": {"shareBalance": 200000, "diamondBalance": 0, "valueTokenBalance": 0},
    }
    for tournament_id in (
        "intermediate-3km-room",
        "demo-intermediate-3km",
        "crew-challenge-room",
    ):
        created = _join(db, "rookie", tournament_id)
        room = db.store[f"tournaments/{tournament_id}"]
        assert created.status == "joined"
        assert room["entryFeeShare"] == 60000
        assert room["maxParticipants"] == 400
        assert room["minParticipantsBep"] == 100
        assert room["winnerRewardValue"] == 500000
        assert room["participantCount"] == 1

    assert db.store["users/rookie"]["wallet"]["shareBalance"] == 20000


def test_unknown_missing_tournament_stays_404() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {
        "tier": 1,
        "wallet": {"shareBalance": 100000, "diamondBalance": 0, "valueTokenBalance": 0},
    }
    with pytest.raises(HTTPException) as missing:
        _join(db, "u1", "not-a-room")
    assert missing.value.status_code == 404
    assert missing.value.detail == "User or tournament not found."
    assert "tournaments/not-a-room" not in db.store
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 100000
