"""Friend ghost, crew cheer, and crew creation: config price, one charge, real effect."""

from datetime import datetime, timezone
from types import SimpleNamespace

from fastapi import HTTPException
import pytest

from app.models.secured_actions import ValidateRunRequest
from app.models.validation_result import ValidationResult
from app.services.item_price_config import resolve_item_prices
from app.services.secured_action_service import (
    SecuredActionService,
    _commit_crew_cheer_use_tx,
    _commit_crew_found_tx,
    _commit_friend_ghost_use_tx,
    _commit_social_purchase_tx,
)
from test_redeem_referral import _MemoryDb, _MemoryTxn

NOW = datetime(2026, 10, 4, 3, 0, tzinfo=timezone.utc)
GHOST = "friend_ghost_pace"
PACK = "friend_ghost_pace_10pack"
FLAG = "crew_cheer_flag"


def _service(db: _MemoryDb) -> SecuredActionService:
    return SecuredActionService(firebase_service=SimpleNamespace(db=db))


def _wallet(diamond: int = 50, free: int = 5, paid: int = 45, share: int = 100_000) -> dict:
    return {
        "tier": 1,
        "ownedCrewId": "crew1",
        "wallet": {
            "diamondBalance": diamond,
            "freeDiamondBalance": free,
            "paidDiamondBalance": paid,
            "shareBalance": share,
            "freeShareBalance": share,
            "paidShareBalance": 0,
            "valueTokenBalance": 4,
        },
    }


def _buy(db: _MemoryDb, item_id: str, request_id: str):
    service = _service(db)
    user_ref = db.collection("users").document("u1")
    return _commit_social_purchase_tx.to_wrap(
        _MemoryTxn(), service, "u1", item_id, request_id, user_ref
    )


def _use_ghost(db: _MemoryDb, request_id: str, friend_uid: str | None, activity_id: str | None):
    service = _service(db)
    user_ref = db.collection("users").document("u1")
    return _commit_friend_ghost_use_tx.to_wrap(
        _MemoryTxn(),
        service,
        "u1",
        request_id,
        friend_uid,
        activity_id,
        user_ref,
    )


def _use_flag(db: _MemoryDb, request_id: str, now: datetime = NOW):
    service = _service(db)
    user_ref = db.collection("users").document("u1")
    return _commit_crew_cheer_use_tx.to_wrap(
        _MemoryTxn(), service, "u1", request_id, user_ref, now=now
    )


def _ledger(db: _MemoryDb) -> list[dict]:
    return [
        row
        for path, row in db.store.items()
        if path.startswith("walletTransactions/")
    ]


def test_prices_default_and_a_bad_override_keeps_the_code_price() -> None:
    assert resolve_item_prices(None)[GHOST] == 5
    assert resolve_item_prices(None)[PACK] == 40
    assert resolve_item_prices(None)[FLAG] == 15
    assert resolve_item_prices(None)["crew_create_dia"] == 50
    assert resolve_item_prices(None)["crew_create_share"] == 30000
    overridden = resolve_item_prices({GHOST: 0, PACK: "40", FLAG: 9, "crew_create_share": 1})
    assert overridden[GHOST] == 5
    assert overridden[PACK] == 40
    assert overridden[FLAG] == 9
    assert overridden["crew_create_share"] == 1


def test_catalog_uses_the_config_price() -> None:
    db = _MemoryDb()
    db.store["config/item_prices"] = {GHOST: 7, PACK: 30, FLAG: 11}
    prices = {row["id"]: row["diamondCost"] for row in _service(db).shop_catalog()}
    assert prices[GHOST] == 7
    assert prices[PACK] == 30
    assert prices[FLAG] == 11
    assert prices["ghost_pace_match"] == 8
    assert prices["battle_run_pass"] == 120


def test_ghost_purchase_spends_free_dia_first_and_replay_is_free() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet(diamond=22, free=2, paid=20)

    result = _buy(db, GHOST, "req-ghost-01")

    assert result.status == "purchased"
    assert result.diamond_balance == 17
    wallet = db.store["users/u1"]["wallet"]
    assert wallet["freeDiamondBalance"] == 0
    assert wallet["paidDiamondBalance"] == 17
    assert wallet["shareBalance"] == 100_000
    assert db.store[f"users/u1/shopInventory/{GHOST}"]["quantity"] == 1
    row = _ledger(db)[0]
    assert row["type"] == "shop_purchase"
    assert row["diamondAmount"] == -5
    assert row["diamondFreeAmount"] == -2
    assert row["diamondPaidAmount"] == -3
    assert row["itemId"] == GHOST

    again = _buy(db, GHOST, "req-ghost-01")
    assert again.status == "already_purchased"
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 17
    assert len(_ledger(db)) == 1


def test_pack_grants_ten_uses_for_40_and_replay_does_not_grant_again() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet()

    result = _buy(db, PACK, "req-pack-01")

    assert result.diamond_balance == 10
    assert db.store[f"users/u1/shopInventory/{GHOST}"]["quantity"] == 10
    assert f"users/u1/shopInventory/{PACK}" not in db.store
    assert _ledger(db)[0]["quantityAmount"] == 10
    assert _ledger(db)[0]["diamondAmount"] == -40

    _buy(db, PACK, "req-pack-01")
    assert db.store[f"users/u1/shopInventory/{GHOST}"]["quantity"] == 10
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 10
    assert len(_ledger(db)) == 1


def test_short_dia_buys_nothing() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet(diamond=4, free=4, paid=0)
    with pytest.raises(HTTPException):
        _buy(db, FLAG, "req-flag-short")
    assert not _ledger(db)
    assert "users/u1/shopInventory/crew_cheer_flag" not in db.store


def test_friend_ghost_uses_the_friend_pace_and_replay_is_free() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet()
    db.store[f"users/u1/shopInventory/{GHOST}"] = {"quantity": 2}
    db.store["activities/run-friend"] = {
        "userId": "friend",
        "jenaVerified": True,
        "averagePaceSecondsPerKm": 280,
        "distanceKm": 5,
    }
    kept = dict(db.store["activities/run-friend"])

    result = _use_ghost(db, "req-use-01", "friend", "run-friend")

    assert result.status == "used"
    assert result.pace_sec_per_km == 280
    assert db.store[f"users/u1/shopInventory/{GHOST}"]["quantity"] == 1
    assert db.store["users/u1"]["friendGhostRun"]["paceSecPerKm"] == 280
    assert db.store["users/u1"]["friendGhostRun"]["friendUid"] == "friend"
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 50
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 100_000
    assert db.store["activities/run-friend"] == kept
    assert not any(path.startswith("crewRankings/") for path in db.store)
    row = _ledger(db)[0]
    assert row["type"] == "shop_item_use"
    assert row["quantityAmount"] == -1
    assert "diamondAmount" not in row
    assert "shareAmount" not in row

    again = _use_ghost(db, "req-use-01", "friend", "run-friend")
    assert again.status == "already_used"
    assert again.pace_sec_per_km == 280
    assert db.store[f"users/u1/shopInventory/{GHOST}"]["quantity"] == 1
    assert len(_ledger(db)) == 1


def test_own_best_does_not_spend_a_ticket_or_write_a_ledger_row() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet()
    db.store[f"users/u1/shopInventory/{GHOST}"] = {"quantity": 2}
    db.store["activities/mine"] = {
        "userId": "u1",
        "jenaVerified": True,
        "averagePaceSecondsPerKm": 300,
    }

    result = _use_ghost(db, "req-own-01", "u1", "mine")

    assert result.status == "own_best"
    assert result.pace_sec_per_km == 300
    assert db.store[f"users/u1/shopInventory/{GHOST}"]["quantity"] == 2
    assert "friendGhostRun" not in db.store["users/u1"]
    assert not _ledger(db)
    assert db.store["activities/mine"]["averagePaceSecondsPerKm"] == 300


def test_unverified_friend_run_does_not_spend_the_ticket() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet()
    db.store[f"users/u1/shopInventory/{GHOST}"] = {"quantity": 1}
    db.store["activities/pending"] = {
        "userId": "friend",
        "jenaVerified": False,
        "averagePaceSecondsPerKm": 280,
    }
    with pytest.raises(HTTPException) as raised:
        _use_ghost(db, "req-bad-01", "friend", "pending")
    assert raised.value.status_code == 400
    assert db.store[f"users/u1/shopInventory/{GHOST}"]["quantity"] == 1
    assert not _ledger(db)


def test_cheer_flag_is_once_per_crew_per_day_and_replay_is_free() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet()
    db.store["crews/crew1"] = {"name": "나이트", "totalValue": 9, "memberCount": 3}
    db.store[f"users/u1/shopInventory/{FLAG}"] = {"quantity": 2}

    result = _use_flag(db, "req-flag-01")

    assert result.status == "used"
    assert db.store[f"users/u1/shopInventory/{FLAG}"]["quantity"] == 1
    assert db.store["crews/crew1"]["cheerFlag"]["dayKey"] == "2026-10-04"
    assert db.store["crews/crew1"]["cheerFlag"]["shareBonusPercent"] == 10
    assert db.store["crews/crew1"]["totalValue"] == 9
    assert db.store["crews/crew1"]["memberCount"] == 3
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 50
    assert not any(path.startswith("crewRankings/") for path in db.store)
    assert _ledger(db)[0]["type"] == "shop_item_use"
    assert _ledger(db)[0]["itemId"] == FLAG

    again = _use_flag(db, "req-flag-01")
    assert again.status == "already_used"
    assert db.store[f"users/u1/shopInventory/{FLAG}"]["quantity"] == 1
    assert len(_ledger(db)) == 1

    second = _use_flag(db, "req-flag-02")
    assert second.status == "already_active"
    assert db.store[f"users/u1/shopInventory/{FLAG}"]["quantity"] == 1
    assert len(_ledger(db)) == 1


def test_cheer_without_a_crew_spends_nothing() -> None:
    db = _MemoryDb()
    user = _wallet()
    user.pop("ownedCrewId")
    db.store["users/u1"] = user
    db.store[f"users/u1/shopInventory/{FLAG}"] = {"quantity": 1}
    with pytest.raises(HTTPException) as raised:
        _use_flag(db, "req-flag-nocrew")
    assert raised.value.detail == "No crew."
    assert db.store[f"users/u1/shopInventory/{FLAG}"]["quantity"] == 1
    assert not _ledger(db)


def _persist_race(db: _MemoryDb, activity_id: str = "act1"):
    service = _service(db)
    request = ValidateRunRequest(
        activity_id=activity_id,
        distance_km=1,
        duration_seconds=300,
        gyro_stability_score=0.9,
        tournament_id="race",
    )
    result = ValidationResult(
        verified=True,
        decision="verified",
        reason="ok",
        value_token_reward=10,
        forfeit_deposit=False,
    )
    return service._persist_validation_tx(
        _MemoryTxn(),
        "u1",
        request,
        result,
        db.collection("activities").document(activity_id),
        db.collection("users").document("u1"),
    )


def test_cheer_adds_ten_percent_share_and_leaves_value_dia_and_pace() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet(share=500)
    day = _service(db)._economy_service.kst_today_key()
    db.store["crews/crew1"] = {
        "totalValue": 12,
        "memberCount": 4,
        "cheerFlag": {"dayKey": day, "shareBonusPercent": 10},
    }
    db.store["tournaments/race"] = {"shareReward": 200, "title": "3km"}

    outcome = _persist_race(db)

    assert outcome.value_token_reward == 10
    wallet = db.store["users/u1"]["wallet"]
    assert wallet["shareBalance"] == 520
    assert wallet["diamondBalance"] == 50
    assert wallet["valueTokenBalance"] == 14
    activity = db.store["activities/act1"]
    assert activity["valueTokenReward"] == 10
    assert activity["averagePaceSecondsPerKm"] == 300
    assert "rank" not in activity
    assert db.store["crews/crew1"]["totalValue"] == 12
    assert db.store["crews/crew1"]["memberCount"] == 4
    assert not any(path.startswith("crewRankings/") for path in db.store)
    cheer = db.store["walletTransactions/crew_cheer_act1"]
    assert cheer["type"] == "crew_cheer_share"
    assert cheer["shareAmount"] == 20
    assert cheer["baseShare"] == 200
    assert "diamondAmount" not in cheer
    assert "valueAmount" not in cheer

    _persist_race(db)
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 520


def test_cheer_does_not_pay_when_the_race_has_no_share_reward() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet(share=500)
    day = _service(db)._economy_service.kst_today_key()
    db.store["crews/crew1"] = {"cheerFlag": {"dayKey": day}}
    db.store["tournaments/race"] = {"title": "3km"}

    _persist_race(db, "act-empty")

    assert db.store["users/u1"]["wallet"]["shareBalance"] == 500
    assert "walletTransactions/crew_cheer_act-empty" not in db.store
    assert db.store["activities/act-empty"]["valueTokenReward"] == 10


def test_cheer_does_not_pay_share_without_the_flag() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet(share=500)
    db.store["crews/crew1"] = {"totalValue": 1}
    db.store["tournaments/race"] = {"shareReward": 200}

    _persist_race(db, "act-plain")

    assert db.store["users/u1"]["wallet"]["shareBalance"] == 500
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 50
    assert "walletTransactions/crew_cheer_act-plain" not in db.store


def test_crew_create_dia_spends_free_first_and_replay_creates_nothing_else() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet(diamond=80, free=20, paid=60, share=40_000)
    service = _service(db)
    user_ref = db.collection("users").document("u1")

    result = _commit_crew_found_tx.to_wrap(
        _MemoryTxn(),
        service,
        "u1",
        "우리크루",
        "dia",
        "req-dia-01",
        user_ref,
        db.collection("crews").document("crew-dia"),
    )

    assert result.status == "created"
    assert result.diamond_balance == 30
    assert result.share_balance == 40_000
    assert result.value_token_balance == 4
    wallet = db.store["users/u1"]["wallet"]
    assert wallet["freeDiamondBalance"] == 0
    assert wallet["paidDiamondBalance"] == 30
    crew = next(row for path, row in db.store.items() if path.startswith("crews/"))
    assert crew["diaCost"] == 50
    assert crew["shareCost"] == 0
    assert crew["payWith"] == "dia"
    assert crew["memberCount"] == 1
    row = _ledger(db)[0]
    assert row["type"] == "crew_create"
    assert row["diamondAmount"] == -50
    assert row["diamondFreeAmount"] == -20
    assert row["diamondPaidAmount"] == -30
    assert "shareAmount" not in row

    again = _commit_crew_found_tx.to_wrap(
        _MemoryTxn(),
        service,
        "u1",
        "우리크루",
        "share",
        "req-dia-01",
        user_ref,
        db.collection("crews").document("crew-other"),
    )
    assert again.status == "already_created"
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 30
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 40_000
    assert len([path for path in db.store if path.startswith("crews/")]) == 1
    assert len(_ledger(db)) == 1


def test_crew_create_uses_the_config_share_price() -> None:
    db = _MemoryDb()
    db.store["config/item_prices"] = {"crew_create_share": 1000}
    db.store["users/u1"] = _wallet(share=5000)
    service = _service(db)
    result = _commit_crew_found_tx.to_wrap(
        _MemoryTxn(),
        service,
        "u1",
        "싼크루",
        "share",
        "req-share-cfg",
        db.collection("users").document("u1"),
        db.collection("crews").document("crew-cfg"),
    )
    assert result.share_balance == 4000
    assert _ledger(db)[0]["shareAmount"] == -1000
