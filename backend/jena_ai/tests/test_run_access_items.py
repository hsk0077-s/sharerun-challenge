"""코치 원포인트권 and 추가 참가권: config price, one charge, real effect."""

from datetime import datetime, timedelta, timezone
from types import SimpleNamespace

from fastapi import HTTPException
import pytest

from app.models.secured_actions import JoinTournamentRequest
from app.services.item_price_config import resolve_item_prices
from app.services.run_access_items import use_coach_one_point
from app.services.secured_action_service import (
    SecuredActionService,
    _commit_join_tx,
    _commit_run_access_purchase_tx,
)
from test_redeem_referral import _MemoryDb, _MemoryTxn

NOW = datetime(2026, 10, 4, 1, 0, tzinfo=timezone.utc)
COACH = "coach_one_point_ticket"
ENTRY = "extra_entry_ticket"
PACK = "extra_entry_ticket_3pack"


def _service(db: _MemoryDb) -> SecuredActionService:
    return SecuredActionService(firebase_service=SimpleNamespace(db=db))


def _wallet(diamond: int = 40, free: int = 5, paid: int = 35) -> dict:
    return {
        "tier": 1,
        "wallet": {
            "diamondBalance": diamond,
            "freeDiamondBalance": free,
            "paidDiamondBalance": paid,
            "shareBalance": 1000,
            "valueTokenBalance": 4,
        },
    }


def _buy(db: _MemoryDb, item_id: str, request_id: str):
    service = _service(db)
    user_ref = db.collection("users").document("u1")
    return _commit_run_access_purchase_tx.to_wrap(
        _MemoryTxn(),
        service,
        "u1",
        item_id,
        request_id,
        user_ref,
    )


def _use_coach(db: _MemoryDb, request_id: str, now: datetime = NOW):
    service = _service(db)
    user_ref = db.collection("users").document("u1")
    return use_coach_one_point(
        service, _MemoryTxn(), "u1", request_id, user_ref, now=now
    )


def _join(db: _MemoryDb, tournament_id: str, *, use_extra_entry: bool):
    service = _service(db)
    user_ref = db.collection("users").document("u1")
    tournament_ref = db.collection("tournaments").document(tournament_id)
    participant_ref = tournament_ref.collection("participants").document("u1")
    request = JoinTournamentRequest(
        tournament_id=tournament_id,
        use_extra_entry=use_extra_entry,
    )
    return _commit_join_tx.to_wrap(
        _MemoryTxn(),
        service,
        "u1",
        request,
        user_ref,
        tournament_ref,
        participant_ref,
    )


def _ledger(db: _MemoryDb) -> list[dict]:
    return [
        row
        for path, row in db.store.items()
        if path.startswith("walletTransactions/")
    ]


def _room(**extra: object) -> dict:
    room = {
        "status": "recruiting",
        "requiredTier": 1,
        "entryFeeShare": 200,
        "diamondDepositRequired": 0,
        "participantCount": 0,
        "maxParticipants": 10,
    }
    room.update(extra)
    return room


def test_prices_default_and_a_bad_override_keeps_the_code_price() -> None:
    assert resolve_item_prices(None)[COACH] == 5
    assert resolve_item_prices(None)[ENTRY] == 10
    assert resolve_item_prices(None)[PACK] == 25
    overridden = resolve_item_prices({COACH: 7, ENTRY: 0, PACK: "25"})
    assert overridden[COACH] == 7
    assert overridden[ENTRY] == 10
    assert overridden[PACK] == 25


def test_catalog_uses_the_config_price() -> None:
    db = _MemoryDb()
    db.store["config/item_prices"] = {COACH: 7, PACK: 20}
    prices = {row["id"]: row["diamondCost"] for row in _service(db).shop_catalog()}
    assert prices[COACH] == 7
    assert prices[ENTRY] == 10
    assert prices[PACK] == 20
    assert prices["battle_run_pass"] == 120


def test_coach_purchase_spends_free_dia_first_and_replay_is_free() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet(diamond=22, free=2, paid=20)

    result = _buy(db, COACH, "req-coach-01")

    assert result.status == "purchased"
    assert result.diamond_balance == 17
    wallet = db.store["users/u1"]["wallet"]
    assert wallet["freeDiamondBalance"] == 0
    assert wallet["paidDiamondBalance"] == 17
    assert db.store[f"users/u1/shopInventory/{COACH}"]["quantity"] == 1
    row = _ledger(db)[0]
    assert row["type"] == "shop_purchase"
    assert row["diamondAmount"] == -5
    assert row["diamondFreeAmount"] == -2
    assert row["diamondPaidAmount"] == -3
    assert row["itemId"] == COACH

    again = _buy(db, COACH, "req-coach-01")
    assert again.status == "already_purchased"
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 17
    assert len(_ledger(db)) == 1


def test_pack_grants_three_tickets_for_25_and_replay_does_not_grant_again() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet(diamond=30, free=10, paid=20)

    result = _buy(db, PACK, "req-pack-0001")

    assert result.status == "purchased"
    assert result.diamond_balance == 5
    assert db.store[f"users/u1/shopInventory/{ENTRY}"]["quantity"] == 3
    assert f"users/u1/shopInventory/{PACK}" not in db.store
    row = _ledger(db)[0]
    assert row["itemId"] == PACK
    assert row["inventoryItemId"] == ENTRY
    assert row["quantityAmount"] == 3
    assert row["diamondAmount"] == -25
    assert row["diamondFreeAmount"] == -10
    assert row["diamondPaidAmount"] == -15

    _buy(db, PACK, "req-pack-0001")
    assert db.store[f"users/u1/shopInventory/{ENTRY}"]["quantity"] == 3
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 5


def test_short_dia_or_request_id_writes_nothing() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet(diamond=4, free=4, paid=0)
    with pytest.raises(HTTPException) as short:
        _buy(db, COACH, "req-coach-01")
    assert short.value.detail == "Insufficient Diamond balance."
    assert _ledger(db) == []
    assert f"users/u1/shopInventory/{COACH}" not in db.store

    db.store["users/u1"] = _wallet()
    with pytest.raises(HTTPException) as bad_id:
        _buy(db, ENTRY, "short")
    assert bad_id.value.detail == "request_id is required."
    assert _ledger(db) == []


def test_coach_use_unlocks_one_run_per_day_and_replay_does_not_spend_again() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet()
    db.store[f"users/u1/shopInventory/{COACH}"] = {"quantity": 2}

    used = _use_coach(db, "run-00000001")
    assert used.status == "used"
    assert db.store[f"users/u1/shopInventory/{COACH}"]["quantity"] == 1
    assert db.store["users/u1"]["coachOnePointRun"]["requestId"] == "run-00000001"
    assert db.store["users/u1"]["coachOnePointUseDay"]["count"] == 1
    assert _ledger(db)[0]["type"] == "shop_item_use"
    assert _ledger(db)[0]["quantityAmount"] == -1

    again = _use_coach(db, "run-00000001")
    assert again.status == "already_used"
    assert db.store[f"users/u1/shopInventory/{COACH}"]["quantity"] == 1
    assert len(_ledger(db)) == 1

    with pytest.raises(HTTPException) as capped:
        _use_coach(db, "run-00000002")
    assert capped.value.detail == "Coach one-point daily use cap is 1."
    assert db.store[f"users/u1/shopInventory/{COACH}"]["quantity"] == 1

    tomorrow = _use_coach(db, "run-00000003", now=NOW + timedelta(days=1))
    assert tomorrow.status == "used"
    assert db.store[f"users/u1/shopInventory/{COACH}"]["quantity"] == 0
    assert db.store["users/u1"]["coachOnePointUseDay"]["count"] == 1


def test_coach_plus_subscriber_does_not_spend_a_ticket() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet()
    db.store["users/u1"]["coachPlus"] = {
        "productId": "coach_plus_monthly",
        "activeUntil": "2026-12-01T00:00:00+00:00",
    }
    db.store[f"users/u1/shopInventory/{COACH}"] = {"quantity": 1}

    result = _use_coach(db, "run-subscriber")

    assert result.status == "subscriber"
    assert db.store[f"users/u1/shopInventory/{COACH}"]["quantity"] == 1
    assert _ledger(db) == []


def test_extra_entry_opens_a_full_room_and_replay_does_not_spend_again() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet()
    db.store[f"users/u1/shopInventory/{ENTRY}"] = {"quantity": 2}
    db.store["tournaments/full"] = _room(participantCount=10, maxParticipants=10)

    result = _join(db, "full", use_extra_entry=True)

    assert result.status == "joined"
    assert result.share_balance == 800
    assert db.store[f"users/u1/shopInventory/{ENTRY}"]["quantity"] == 1
    assert db.store["users/u1"]["extraEntryUseDay"]["count"] == 1
    assert db.store["tournaments/full/participants/u1"]["extraEntryTicket"] is True
    assert db.store["tournaments/full"]["participantCount"] == 11
    kinds = {row["type"] for row in _ledger(db)}
    assert kinds == {"tournament_entry", "shop_item_use"}
    entry = next(row for row in _ledger(db) if row["type"] == "tournament_entry")
    assert entry["shareAmount"] == -200
    assert entry["extraEntryItemId"] == ENTRY

    again = _join(db, "full", use_extra_entry=True)
    assert again.status == "already_joined"
    assert db.store[f"users/u1/shopInventory/{ENTRY}"]["quantity"] == 1
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 800
    assert len(_ledger(db)) == 2


def test_open_room_does_not_spend_a_ticket_even_if_offered() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet()
    db.store[f"users/u1/shopInventory/{ENTRY}"] = {"quantity": 1}
    db.store["tournaments/open"] = _room()

    result = _join(db, "open", use_extra_entry=True)

    assert result.status == "joined"
    assert db.store[f"users/u1/shopInventory/{ENTRY}"]["quantity"] == 1
    assert "extraEntryUseDay" not in db.store["users/u1"]
    assert [row["type"] for row in _ledger(db)] == ["tournament_entry"]


def test_full_room_with_no_ticket_in_inventory_does_not_join() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet()
    db.store["tournaments/full"] = _room(participantCount=10, maxParticipants=10)
    with pytest.raises(HTTPException) as raised:
        _join(db, "full", use_extra_entry=True)
    assert raised.value.detail == "No extra entry ticket."
    assert "tournaments/full/participants/u1" not in db.store
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 1000


def test_full_room_without_a_ticket_stays_full() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet()
    db.store["tournaments/full"] = _room(participantCount=10, maxParticipants=10)
    with pytest.raises(HTTPException) as raised:
        _join(db, "full", use_extra_entry=False)
    assert raised.value.status_code == 409
    assert "tournaments/full/participants/u1" not in db.store


def test_closed_room_opens_with_a_ticket_and_a_cancelled_room_does_not() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet()
    db.store[f"users/u1/shopInventory/{ENTRY}"] = {"quantity": 1}
    db.store["tournaments/live"] = _room(status="active", participantCount=1)

    opened = _join(db, "live", use_extra_entry=True)
    assert opened.status == "joined"
    assert db.store[f"users/u1/shopInventory/{ENTRY}"]["quantity"] == 0

    db.store[f"users/u1/shopInventory/{ENTRY}"] = {"quantity": 1}
    db.store["tournaments/dead"] = _room(status="cancelled")
    with pytest.raises(HTTPException) as cancelled:
        _join(db, "dead", use_extra_entry=True)
    assert cancelled.value.detail == "Tournament is not recruiting."
    assert db.store[f"users/u1/shopInventory/{ENTRY}"]["quantity"] == 1
    assert "tournaments/dead/participants/u1" not in db.store


def test_two_uses_per_day_then_the_cap_rejects_without_spending() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet()
    db.store[f"users/u1/shopInventory/{ENTRY}"] = {"quantity": 3}
    db.store["tournaments/a"] = _room(participantCount=2, maxParticipants=2)
    db.store["tournaments/b"] = _room(status="closed", participantCount=0)
    db.store["tournaments/c"] = _room(participantCount=5, maxParticipants=5)

    assert _join(db, "a", use_extra_entry=True).status == "joined"
    assert _join(db, "b", use_extra_entry=True).status == "joined"
    with pytest.raises(HTTPException) as capped:
        _join(db, "c", use_extra_entry=True)
    assert capped.value.detail == "Extra entry daily use cap is 2."
    assert db.store[f"users/u1/shopInventory/{ENTRY}"]["quantity"] == 1
    assert "tournaments/c/participants/u1" not in db.store
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 600


def test_prize_race_rejects_the_ticket_and_does_not_join() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet()
    db.store[f"users/u1/shopInventory/{ENTRY}"] = {"quantity": 1}
    db.store["tournaments/prize"] = _room(prizeTier="beginner", participantCount=10)

    with pytest.raises(HTTPException) as raised:
        _join(db, "prize", use_extra_entry=True)

    assert raised.value.detail == "Prize races accept only SHARE or free tickets."
    assert db.store[f"users/u1/shopInventory/{ENTRY}"]["quantity"] == 1
    assert "tournaments/prize/participants/u1" not in db.store
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 1000
    assert _ledger(db) == []


def test_direct_use_of_an_extra_entry_ticket_is_rejected() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet()
    db.store[f"users/u1/shopInventory/{ENTRY}"] = {"quantity": 1}
    service = _service(db)
    with pytest.raises(HTTPException) as raised:
        service.use_shop_item("u1", ENTRY, request_id="req-use-entry")
    assert raised.value.detail == "Extra entry ticket is spent by joining a race."
    assert db.store[f"users/u1/shopInventory/{ENTRY}"]["quantity"] == 1
