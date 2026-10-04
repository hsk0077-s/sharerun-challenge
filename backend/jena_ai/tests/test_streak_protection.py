"""심폐소생권 and 세이프가드: config price, one charge per request id, real streak effect."""

from datetime import datetime, timezone
from types import SimpleNamespace
from unittest.mock import MagicMock

from fastapi import HTTPException
import pytest

from app.services.item_price_config import resolve_item_prices
from app.services.secured_action_service import SecuredActionService, _day_has_activity
from app.services.streak_protection import (
    grant_coach_plus_cpr,
    purchase_streak_item,
    use_streak_item,
)
from test_redeem_referral import _MemoryDb, _MemoryTxn

# 2026-10-04 10:00 KST.
NOW = datetime(2026, 10, 4, 1, 0, tzinfo=timezone.utc)
CPR = "record_cpr_ticket"
GUARD = "record_safe_guard"


def _service(db: _MemoryDb) -> SecuredActionService:
    return SecuredActionService(firebase_service=SimpleNamespace(db=db))


def _wallet(diamond: int = 30, free: int = 5, paid: int = 25) -> dict:
    return {
        "wallet": {
            "diamondBalance": diamond,
            "freeDiamondBalance": free,
            "paidDiamondBalance": paid,
            "shareBalance": 10,
            "valueTokenBalance": 4,
        }
    }


def _buy(db: _MemoryDb, item_id: str, request_id: str, now: datetime = NOW):
    service = _service(db)
    user_ref = db.collection("users").document("u1")
    return purchase_streak_item(
        service, _MemoryTxn(), "u1", item_id, request_id, user_ref, now=now
    )


def _use(db: _MemoryDb, item_id: str, request_id: str, now: datetime = NOW):
    service = _service(db)
    user_ref = db.collection("users").document("u1")
    return use_streak_item(
        service, _MemoryTxn(), "u1", item_id, request_id, user_ref, now=now
    )


def _ledger(db: _MemoryDb) -> list[dict]:
    return [
        row
        for path, row in db.store.items()
        if path.startswith("walletTransactions/")
    ]


def test_invalid_price_fields_keep_defaults() -> None:
    prices = resolve_item_prices(
        {
            CPR: 0,
            GUARD: True,
            "ghost_pace_match": 1,
        }
    )
    assert prices == {
        CPR: 12,
        GUARD: 8,
        "coach_one_point_ticket": 5,
        "extra_entry_ticket": 10,
        "extra_entry_ticket_3pack": 25,
        "friend_ghost_pace": 5,
        "friend_ghost_pace_10pack": 40,
        "crew_cheer_flag": 15,
        "crew_create_dia": 50,
        "crew_create_share": 30000,
    }

    overridden = resolve_item_prices({CPR: 20, GUARD: "8"})
    assert overridden[CPR] == 20
    assert overridden[GUARD] == 8


def test_catalog_uses_firestore_price_for_streak_items_only() -> None:
    db = _MemoryDb()
    db.store["config/item_prices"] = {CPR: 20, GUARD: -3, "battle_run_pass": 1}
    prices = {
        row["id"]: row["diamondCost"] for row in _service(db).shop_catalog()
    }
    assert prices[CPR] == 20
    assert prices[GUARD] == 8
    assert prices["battle_run_pass"] == 120


def test_purchase_spends_free_dia_first_and_replay_does_not_charge_again() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet()

    result = _buy(db, CPR, "req-cpr-0001")

    assert result.status == "purchased"
    assert result.diamond_balance == 18
    assert result.share_balance == 10
    assert result.value_token_balance == 4
    wallet = db.store["users/u1"]["wallet"]
    assert wallet["diamondBalance"] == 18
    assert wallet["freeDiamondBalance"] == 0
    assert wallet["paidDiamondBalance"] == 18
    assert db.store[f"users/u1/shopInventory/{CPR}"]["quantity"] == 1
    rows = _ledger(db)
    assert len(rows) == 1
    assert rows[0]["type"] == "shop_purchase"
    assert rows[0]["diamondAmount"] == -12
    assert rows[0]["diamondFreeAmount"] == -5
    assert rows[0]["diamondPaidAmount"] == -7
    assert rows[0]["requestId"] == "req-cpr-0001"

    again = _buy(db, CPR, "req-cpr-0001")
    assert again.status == "already_purchased"
    assert again.diamond_balance == 18
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 18
    assert db.store[f"users/u1/shopInventory/{CPR}"]["quantity"] == 1
    assert len(_ledger(db)) == 1

    second = _buy(db, CPR, "req-cpr-0002")
    assert second.status == "purchased"
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 6
    assert db.store[f"users/u1/shopInventory/{CPR}"]["quantity"] == 2
    assert len(_ledger(db)) == 2


def test_purchase_uses_config_price_and_rejects_a_short_request_id() -> None:
    db = _MemoryDb()
    db.store["config/item_prices"] = {CPR: 15}
    db.store["users/u1"] = _wallet(diamond=15, free=15, paid=0)

    result = _buy(db, CPR, "req-price-01")

    assert result.diamond_balance == 0
    assert _ledger(db)[0]["diamondAmount"] == -15
    with pytest.raises(HTTPException) as raised:
        _buy(db, CPR, "short")
    assert raised.value.status_code == 400
    assert raised.value.detail == "request_id is required."


def test_insufficient_dia_writes_nothing() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet(diamond=11, free=11, paid=0)

    with pytest.raises(HTTPException) as raised:
        _buy(db, CPR, "req-cpr-0001")

    assert raised.value.detail == "Insufficient Diamond balance."
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 11
    assert not any(path.startswith("walletTransactions/") for path in db.store)
    assert f"users/u1/shopInventory/{CPR}" not in db.store


def test_safeguard_hold_cap_is_two() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet()
    db.store[f"users/u1/shopInventory/{GUARD}"] = {"quantity": 2}

    with pytest.raises(HTTPException) as raised:
        _buy(db, GUARD, "req-guard-01")

    assert raised.value.detail == "Safeguard hold cap is 2."
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 30
    assert db.store[f"users/u1/shopInventory/{GUARD}"]["quantity"] == 2
    assert _ledger(db) == []


def test_buying_a_safeguard_covers_one_missed_day_once() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet()
    db.store["users/u1/daily_metrics/2026-10-02"] = {"km": 1.2}

    result = _buy(db, GUARD, "req-guard-01")

    assert result.status == "purchased"
    assert result.diamond_balance == 22
    assert db.store[f"users/u1/shopInventory/{GUARD}"]["quantity"] == 0
    covered = db.store["users/u1/daily_metrics/2026-10-03"]
    assert covered["streakCovered"] == "safeguard"
    assert "km" not in covered
    rows = _ledger(db)
    assert {row["type"] for row in rows} == {"shop_purchase", "shop_item_use"}
    assert sum(row.get("diamondAmount", 0) for row in rows) == -8

    again = _buy(db, GUARD, "req-guard-01")
    assert again.status == "already_purchased"
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 22
    assert db.store[f"users/u1/shopInventory/{GUARD}"]["quantity"] == 0
    assert len(_ledger(db)) == 2


def test_cpr_restores_the_gap_inside_72_hours_and_replay_does_not_use_another() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet(diamond=0, free=0, paid=0)
    db.store[f"users/u1/shopInventory/{CPR}"] = {"quantity": 2}
    db.store["users/u1/daily_metrics/2026-10-01"] = {"km": 2}

    result = _use(db, CPR, "req-use-cpr1")

    assert result.status == "used"
    assert db.store[f"users/u1/shopInventory/{CPR}"]["quantity"] == 1
    assert db.store["users/u1/daily_metrics/2026-10-02"]["streakCovered"] == "cpr"
    assert db.store["users/u1/daily_metrics/2026-10-03"]["streakCovered"] == "cpr"
    assert db.store["users/u1/daily_metrics/2026-10-01"]["km"] == 2
    assert db.store["users/u1"]["cprUseMonth"] == {"monthKey": "2026-10", "count": 1}
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 0
    rows = _ledger(db)
    assert len(rows) == 1
    assert rows[0]["type"] == "shop_item_use"
    assert rows[0]["quantityAmount"] == -1
    assert rows[0]["coveredDays"] == ["2026-10-02", "2026-10-03"]

    again = _use(db, CPR, "req-use-cpr1")
    assert again.status == "already_used"
    assert db.store[f"users/u1/shopInventory/{CPR}"]["quantity"] == 1
    assert db.store["users/u1"]["cprUseMonth"]["count"] == 1
    assert len(_ledger(db)) == 1

    with pytest.raises(HTTPException) as raised:
        _use(db, CPR, "req-use-cpr2")
    assert raised.value.detail == "Streak is not broken."
    assert db.store[f"users/u1/shopInventory/{CPR}"]["quantity"] == 1


def test_cpr_rejects_a_live_streak_and_a_break_older_than_72_hours() -> None:
    live = _MemoryDb()
    live.store["users/u1"] = {"wallet": {"diamondBalance": 0}}
    live.store[f"users/u1/shopInventory/{CPR}"] = {"quantity": 1}
    live.store["users/u1/daily_metrics/2026-10-03"] = {"steps": 100}

    with pytest.raises(HTTPException) as alive:
        _use(live, CPR, "req-use-live")
    assert alive.value.detail == "Streak is not broken."
    assert live.store[f"users/u1/shopInventory/{CPR}"]["quantity"] == 1
    assert _ledger(live) == []

    old = _MemoryDb()
    old.store["users/u1"] = {"wallet": {"diamondBalance": 0}}
    old.store[f"users/u1/shopInventory/{CPR}"] = {"quantity": 1}
    old.store["users/u1/daily_metrics/2026-09-28"] = {"km": 1}

    with pytest.raises(HTTPException) as window:
        _use(old, CPR, "req-use-old1")
    assert window.value.detail == "Streak break is outside 72 hours."
    assert old.store[f"users/u1/shopInventory/{CPR}"]["quantity"] == 1
    assert "users/u1/daily_metrics/2026-09-29" not in old.store


def test_cpr_use_cap_is_two_per_month() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {
        "wallet": {"diamondBalance": 0},
        "cprUseMonth": {"monthKey": "2026-10", "count": 2},
    }
    db.store[f"users/u1/shopInventory/{CPR}"] = {"quantity": 1}
    db.store["users/u1/daily_metrics/2026-10-02"] = {"km": 1}

    with pytest.raises(HTTPException) as raised:
        _use(db, CPR, "req-use-cap1")

    assert raised.value.detail == "CPR monthly use cap is 2."
    assert db.store[f"users/u1/shopInventory/{CPR}"]["quantity"] == 1
    assert _ledger(db) == []


def test_coach_plus_grant_is_one_ticket_per_month_and_can_be_used() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {
        "wallet": {"diamondBalance": 0},
        "coachPlus": {"productId": "coach_plus_monthly", "activeUntil": "2026-12-01T00:00:00+00:00"},
    }
    service = _service(db)
    user_ref = db.collection("users").document("u1")
    grant_coach_plus_cpr(service, _MemoryTxn(), "u1", user_ref, now=NOW)
    grant_coach_plus_cpr(service, _MemoryTxn(), "u1", user_ref, now=NOW)

    assert db.store[f"users/u1/shopInventory/{CPR}"]["quantity"] == 1
    assert db.store["users/u1"]["cprFreeGrantMonth"] == "2026-10"
    rows = _ledger(db)
    assert len(rows) == 1
    assert rows[0]["type"] == "cpr_coach_plus_grant"
    assert rows[0]["quantityAmount"] == 1
    assert rows[0]["diamondAmount"] == 0
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 0

    db.store["users/u1/daily_metrics/2026-10-02"] = {"km": 1}
    used = _use(db, CPR, "req-free-cpr")
    assert used.status == "used"
    assert db.store[f"users/u1/shopInventory/{CPR}"]["quantity"] == 0
    assert db.store["users/u1/daily_metrics/2026-10-03"]["streakCovered"] == "cpr"


def test_expired_coach_plus_does_not_grant() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {
        "wallet": {"diamondBalance": 0},
        "coachPlus": {"activeUntil": "2026-09-01T00:00:00+00:00"},
    }
    service = _service(db)
    grant_coach_plus_cpr(
        service,
        _MemoryTxn(),
        "u1",
        db.collection("users").document("u1"),
        now=NOW,
    )
    assert f"users/u1/shopInventory/{CPR}" not in db.store
    assert _ledger(db) == []


def test_safeguard_use_covers_only_a_single_miss_and_replays() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {"wallet": {"diamondBalance": 0}}
    db.store[f"users/u1/shopInventory/{GUARD}"] = {"quantity": 2}
    db.store["users/u1/daily_metrics/2026-10-02"] = {"steps": 50}

    result = _use(db, GUARD, "req-guard-use")

    assert result.status == "used"
    assert db.store[f"users/u1/shopInventory/{GUARD}"]["quantity"] == 1
    assert db.store["users/u1/daily_metrics/2026-10-03"]["streakCovered"] == "safeguard"
    again = _use(db, GUARD, "req-guard-use")
    assert again.status == "already_used"
    assert db.store[f"users/u1/shopInventory/{GUARD}"]["quantity"] == 1

    wide = _MemoryDb()
    wide.store["users/u1"] = {"wallet": {"diamondBalance": 0}}
    wide.store[f"users/u1/shopInventory/{GUARD}"] = {"quantity": 1}
    wide.store["users/u1/daily_metrics/2026-10-01"] = {"km": 1}
    with pytest.raises(HTTPException) as raised:
        _use(wide, GUARD, "req-guard-wide")
    assert raised.value.detail == "No missed day to protect."
    assert wide.store[f"users/u1/shopInventory/{GUARD}"]["quantity"] == 1


def test_automatic_safeguard_does_not_error_when_nothing_is_held() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {"wallet": {"diamondBalance": 0}}
    db.store["users/u1/daily_metrics/2026-10-02"] = {"km": 1}

    quiet = _use(db, GUARD, "safeguard-auto-2026-10-04")

    assert quiet.status == "no_item"
    assert _ledger(db) == []
    db.store[f"users/u1/shopInventory/{GUARD}"] = {"quantity": 1}
    applied = _use(db, GUARD, "safeguard-auto-2026-10-04")
    assert applied.status == "used"
    assert db.store[f"users/u1/shopInventory/{GUARD}"]["quantity"] == 0


def test_covered_day_counts_as_streak_activity() -> None:
    snapshot = MagicMock()
    snapshot.exists = True
    snapshot.to_dict.return_value = {"streakCovered": "cpr"}
    assert _day_has_activity(snapshot) is True
    empty = MagicMock()
    empty.exists = True
    empty.to_dict.return_value = {"steps": 0, "km": 0}
    assert _day_has_activity(empty) is False
