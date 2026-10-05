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


def _ledger(db: _MemoryDb) -> dict:
    return next(
        row for path, row in db.store.items() if path.startswith("walletTransactions/")
    )


def _prize_user(share: int = 10000, tickets: int = 0, **extra: object) -> dict:
    user = {
        "tier": 1,
        "wallet": {
            "shareBalance": share,
            "freeShareBalance": share,
            "paidShareBalance": 0,
            "diamondBalance": 50,
            "paidDiamondBalance": 50,
            "freeDiamondBalance": 0,
            "valueTokenBalance": 7,
            "freeTicketBalance": tickets,
        },
    }
    user.update(extra)
    return user


def _prize_room(tier: str, **extra: object) -> dict:
    room = {
        "status": "recruiting",
        "prizeTier": tier,
        "entryFeeShare": 99999,
        "diamondDepositRequired": 12,
        "maxParticipants": 9999,
        "participantCount": 0,
        "requiredTier": 1,
    }
    room.update(extra)
    return room


def test_prize_race_debits_config_share_not_the_room_fee() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _prize_user()
    db.store["tournaments/race"] = _prize_room("beginner")

    result = _join(db, "u1", "race")

    assert result.status == "joined"
    assert result.share_credited == -600
    assert result.diamond_balance == 50
    wallet = db.store["users/u1"]["wallet"]
    assert wallet["shareBalance"] == 9400
    assert wallet["diamondBalance"] == 50
    assert wallet["paidDiamondBalance"] == 50
    assert wallet["valueTokenBalance"] == 7
    participant = db.store["tournaments/race/participants/u1"]
    assert participant["entryFeeShare"] == 600
    assert participant["entryMethod"] == "share"
    assert participant["diamondDeposit"] == 0
    assert participant["prizeTier"] == "beginner"
    ledger = _ledger(db)
    assert ledger["type"] == "tournament_entry"
    assert ledger["shareAmount"] == -600
    assert ledger["diamondAmount"] == 0
    assert ledger["ticketAmount"] == 0
    assert ledger["entryMethod"] == "share"
    assert db.store["tournaments/race"]["entryFeeShare"] == 99999

    again = _join(db, "u1", "race")
    assert again.status == "already_joined"
    assert wallet["shareBalance"] == 9400
    assert (
        sum(1 for path in db.store if path.startswith("walletTransactions/")) == 1
    )


def test_prize_race_firestore_override_replaces_the_share_fee() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _prize_user()
    db.store["tournaments/race"] = _prize_room("mid")
    db.store["config/company_tournament"] = {
        "tiers": {"mid": {"entryShare": 111}},
    }

    result = _join(db, "u1", "race")

    assert result.share_credited == -111
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 9889
    assert _ledger(db)["shareAmount"] == -111


def test_prize_race_free_ticket_debits_tickets_not_share() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _prize_user(tickets=2)
    db.store["tournaments/race"] = _prize_room("advanced")
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))
    request = JoinTournamentRequest(
        tournament_id="race",
        diamond_deposit=0,
        entry_method="ticket",
    )
    result = _commit_join_tx.to_wrap(
        _MemoryTxn(),
        service,
        "u1",
        request,
        db.collection("users").document("u1"),
        db.collection("tournaments").document("race"),
        db.collection("tournaments").document("race").collection("participants").document("u1"),
    )

    assert result.status == "joined_ticket"
    assert result.share_credited == 0
    wallet = db.store["users/u1"]["wallet"]
    assert wallet["shareBalance"] == 10000
    assert wallet["freeTicketBalance"] == 0
    assert wallet["diamondBalance"] == 50
    ledger = _ledger(db)
    assert ledger["ticketAmount"] == -2
    assert ledger["shareAmount"] == 0
    assert ledger["entryMethod"] == "ticket"
    assert db.store["tournaments/race/participants/u1"]["entryFeeShare"] == 0

    again = _commit_join_tx.to_wrap(
        _MemoryTxn(),
        service,
        "u1",
        request,
        db.collection("users").document("u1"),
        db.collection("tournaments").document("race"),
        db.collection("tournaments").document("race").collection("participants").document("u1"),
    )
    assert again.status == "already_joined"
    assert wallet["freeTicketBalance"] == 0


def test_prize_race_zero_fee_final_writes_a_ledger_row() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _prize_user(share=0, seasonQualified=True)
    db.store["tournaments/finals"] = _prize_room("final")

    result = _join(db, "u1", "finals")

    assert result.status == "joined_free"
    assert result.accepted is True
    assert result.share_credited == 0
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 0
    ledger = _ledger(db)
    assert ledger["type"] == "tournament_entry"
    assert ledger["shareAmount"] == 0
    assert ledger["ticketAmount"] == 0
    assert ledger["entryMethod"] == "free"
    assert ledger["diamondAmount"] == 0
    assert db.store["tournaments/finals/participants/u1"]["status"] == "joined"

    again = _join(db, "u1", "finals")
    assert again.status == "already_joined"
    assert sum(1 for path in db.store if path.startswith("walletTransactions/")) == 1


def test_prize_race_final_requires_season_qualification() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _prize_user()
    db.store["tournaments/finals"] = _prize_room("final")

    with pytest.raises(HTTPException) as blocked:
        _join(db, "u1", "finals")
    assert blocked.value.status_code == 403
    assert "tournaments/finals/participants/u1" not in db.store
    assert not any(path.startswith("walletTransactions/") for path in db.store)


def test_prize_race_rejects_dia_and_unknown_tier() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _prize_user()
    db.store["tournaments/race"] = _prize_room("beginner")
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))
    user_ref = db.collection("users").document("u1")
    tournament_ref = db.collection("tournaments").document("race")
    participant_ref = tournament_ref.collection("participants").document("u1")
    paid = JoinTournamentRequest(tournament_id="race", diamond_deposit=1)
    with pytest.raises(HTTPException) as dia:
        _commit_join_tx.to_wrap(
            _MemoryTxn(),
            service,
            "u1",
            paid,
            user_ref,
            tournament_ref,
            participant_ref,
        )
    assert dia.value.status_code == 400
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 50
    assert not any(path.startswith("walletTransactions/") for path in db.store)

    db.store["tournaments/race"]["prizeTier"] = "legend"
    with pytest.raises(HTTPException) as unknown:
        _join(db, "u1", "race")
    assert unknown.value.status_code == 400
    assert "tournaments/race/participants/u1" not in db.store


def test_prize_race_enforces_config_max_entrants() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _prize_user()
    db.store["tournaments/race"] = _prize_room("beginner", participantCount=500)

    with pytest.raises(HTTPException) as full:
        _join(db, "u1", "race")
    assert full.value.status_code == 409
    assert not any(path.startswith("walletTransactions/") for path in db.store)

    db.store["tournaments/race"]["participantCount"] = 499
    result = _join(db, "u1", "race")
    assert result.status == "joined"


def test_prize_race_insufficient_share_writes_nothing() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _prize_user(share=599)
    db.store["tournaments/race"] = _prize_room("beginner")

    with pytest.raises(HTTPException) as broke:
        _join(db, "u1", "race")

    assert broke.value.status_code == 400
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 599
    assert "tournaments/race/participants/u1" not in db.store
    assert not any(path.startswith("walletTransactions/") for path in db.store)


def test_prize_race_ticket_shortfall_does_not_touch_share() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _prize_user(tickets=0)
    db.store["tournaments/race"] = _prize_room("half")
    request = JoinTournamentRequest(
        tournament_id="race",
        diamond_deposit=0,
        entry_method="ticket",
    )
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))
    with pytest.raises(HTTPException) as short:
        _commit_join_tx.to_wrap(
            _MemoryTxn(),
            service,
            "u1",
            request,
            db.collection("users").document("u1"),
            db.collection("tournaments").document("race"),
            db.collection("tournaments").document("race").collection("participants").document("u1"),
        )
    assert short.value.status_code == 400
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 10000
    assert "tournaments/race/participants/u1" not in db.store


def test_room_without_prize_tier_ignores_company_config() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _prize_user(share=1000)
    db.store["tournaments/t1"] = {
        "status": "recruiting",
        "requiredTier": 1,
        "entryFeeShare": 200,
        "diamondDepositRequired": 0,
        "participantCount": 0,
    }
    db.store["config/company_tournament"] = {
        "tiers": {"beginner": {"entryShare": 1}},
    }

    result = _join(db, "u1", "t1")

    assert result.status == "joined"
    assert result.share_credited == -200
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 800


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


@pytest.mark.parametrize(
    ("tier", "share_fee", "ticket_fee"),
    [
        ("beginner", 600, 1),
        ("mid", 1_800, 1),
        ("advanced", 3_000, 2),
        ("half", 4_200, 3),
    ],
)
def test_prize_tiers_charge_config_share_or_tickets(
    tier: str,
    share_fee: int,
    ticket_fee: int,
) -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _prize_user(share=10_000)
    db.store["tournaments/race"] = _prize_room(tier, entryFeeShare=99999)

    share_join = _join(db, "u1", "race")

    assert share_join.share_credited == -share_fee
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 10_000 - share_fee
    assert db.store["tournaments/race"]["entryFeeShare"] == 99999
    assert _ledger(db)["shareAmount"] == -share_fee
    assert _ledger(db)["ticketAmount"] == 0

    ticket_db = _MemoryDb()
    ticket_db.store["users/u1"] = _prize_user(share=10_000, tickets=ticket_fee)
    ticket_db.store["tournaments/race"] = _prize_room(tier, entryFeeShare=99999)
    service = SecuredActionService(firebase_service=SimpleNamespace(db=ticket_db))
    request = JoinTournamentRequest(
        tournament_id="race",
        diamond_deposit=0,
        entry_method="ticket",
    )
    ticket_join = _commit_join_tx.to_wrap(
        _MemoryTxn(),
        service,
        "u1",
        request,
        ticket_db.collection("users").document("u1"),
        ticket_db.collection("tournaments").document("race"),
        ticket_db.collection("tournaments")
        .document("race")
        .collection("participants")
        .document("u1"),
    )
    assert ticket_join.status == "joined_ticket"
    assert ticket_join.share_credited == 0
    assert ticket_db.store["users/u1"]["wallet"]["shareBalance"] == 10_000
    assert ticket_db.store["users/u1"]["wallet"]["freeTicketBalance"] == 0
    assert _ledger(ticket_db)["ticketAmount"] == -ticket_fee
    assert _ledger(ticket_db)["shareAmount"] == 0


def test_final_rejects_tickets_and_stays_free_for_qualified_users() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _prize_user(share=0, tickets=3, seasonQualified=True)
    db.store["tournaments/finals"] = _prize_room("final", entryFeeShare=99999)
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))
    request = JoinTournamentRequest(
        tournament_id="finals",
        diamond_deposit=0,
        entry_method="ticket",
    )
    with pytest.raises(HTTPException) as rejected:
        _commit_join_tx.to_wrap(
            _MemoryTxn(),
            service,
            "u1",
            request,
            db.collection("users").document("u1"),
            db.collection("tournaments").document("finals"),
            db.collection("tournaments")
            .document("finals")
            .collection("participants")
            .document("u1"),
        )
    assert rejected.value.status_code == 400
    assert db.store["users/u1"]["wallet"]["freeTicketBalance"] == 3
    assert "tournaments/finals/participants/u1" not in db.store
