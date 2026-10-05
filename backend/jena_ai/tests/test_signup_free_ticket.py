"""One first-race ticket, granted once and recorded on the ledger."""

from types import SimpleNamespace

import pytest
from fastapi import HTTPException

from app.models.secured_actions import JoinTournamentRequest
from app.services.secured_action_service import (
    SecuredActionService,
    _commit_join_tx,
    _commit_signup_free_ticket_tx,
)
from test_join_tournament_tx import _prize_room, _prize_user
from test_redeem_referral import _MemoryDb, _MemoryTxn


def _ensure(db: _MemoryDb, uid: str = "u1"):
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))
    user_ref = db.collection("users").document(uid)
    return _commit_signup_free_ticket_tx.to_wrap(_MemoryTxn(), service, uid, user_ref)


def _ticket_rows(db: _MemoryDb) -> list[str]:
    return [path for path in db.store if path.startswith("walletTransactions/")]


def test_existing_account_receives_one_ticket_on_the_lazy_grant() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {
        "economy": {"signupRewardClaimed": True},
        "wallet": {"shareBalance": 40, "freeTicketBalance": 0, "valueTokenBalance": 5},
    }

    first = _ensure(db)

    assert first.status == "granted"
    assert first.free_ticket_balance == 1
    wallet = db.store["users/u1"]["wallet"]
    assert wallet["freeTicketBalance"] == 1
    assert wallet["shareBalance"] == 40
    assert wallet["valueTokenBalance"] == 5
    assert db.store["users/u1"]["economy"]["signupRewardClaimed"] is True
    assert db.store["users/u1"]["economy"]["signupFreeTicketGranted"] is True
    row = db.store["walletTransactions/signup_free_ticket_u1"]
    assert row["type"] == "signup_free_ticket"
    assert row["ticketAmount"] == 1
    assert row["uid"] == "u1"

    again = _ensure(db)

    assert again.status == "already_granted"
    assert again.free_ticket_balance == 1
    assert wallet["freeTicketBalance"] == 1
    assert _ticket_rows(db) == ["walletTransactions/signup_free_ticket_u1"]


def test_spent_ticket_is_not_granted_again() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {
        "economy": {"signupFreeTicketGranted": True},
        "wallet": {"freeTicketBalance": 0, "shareBalance": 10},
    }

    result = _ensure(db)

    assert result.status == "already_granted"
    assert result.free_ticket_balance == 0
    assert db.store["users/u1"]["wallet"]["freeTicketBalance"] == 0
    assert _ticket_rows(db) == []


def test_ledger_row_blocks_a_second_grant_and_sets_the_flag() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {
        "economy": {"referralCode": "KEEP"},
        "wallet": {"freeTicketBalance": 4},
    }
    db.store["walletTransactions/signup_free_ticket_u1"] = {
        "uid": "u1",
        "type": "signup_free_ticket",
        "ticketAmount": 1,
    }

    result = _ensure(db)

    assert result.status == "already_granted"
    assert result.free_ticket_balance == 4
    assert db.store["users/u1"]["wallet"]["freeTicketBalance"] == 4
    assert db.store["users/u1"]["economy"]["signupFreeTicketGranted"] is True
    assert db.store["users/u1"]["economy"]["referralCode"] == "KEEP"
    assert db.store["walletTransactions/signup_free_ticket_u1"]["ticketAmount"] == 1


def test_missing_user_does_not_write_a_ticket() -> None:
    db = _MemoryDb()

    with pytest.raises(HTTPException) as missing:
        _ensure(db)

    assert missing.value.status_code == 404
    assert db.store == {}


def test_lazy_grant_then_beginner_ticket_join_spends_that_one_ticket() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _prize_user(share=900, tickets=0)
    db.store["tournaments/race"] = _prize_room("beginner", entryFeeShare=99999)

    granted = _ensure(db)
    assert granted.free_ticket_balance == 1

    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))
    request = JoinTournamentRequest(
        tournament_id="race",
        diamond_deposit=0,
        entry_method="ticket",
    )
    joined = _commit_join_tx.to_wrap(
        _MemoryTxn(),
        service,
        "u1",
        request,
        db.collection("users").document("u1"),
        db.collection("tournaments").document("race"),
        db.collection("tournaments").document("race").collection("participants").document("u1"),
    )

    assert joined.status == "joined_ticket"
    assert joined.share_credited == 0
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 900
    assert db.store["users/u1"]["wallet"]["freeTicketBalance"] == 0
    assert db.store["tournaments/race"]["entryFeeShare"] == 99999
    entry = next(
        row
        for path, row in db.store.items()
        if path.startswith("walletTransactions/") and row.get("type") == "tournament_entry"
    )
    assert entry["ticketAmount"] == -1
    assert entry["shareAmount"] == 0
    assert entry["entryMethod"] == "ticket"

    repeat = _ensure(db)
    assert repeat.status == "already_granted"
    assert db.store["users/u1"]["wallet"]["freeTicketBalance"] == 0
    assert (
        sum(1 for path in db.store if "signup_free_ticket_" in path)
        == 1
    )
