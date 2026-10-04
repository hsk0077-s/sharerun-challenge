"""부스트 런 and 만보기 부화기: SHARE price, one charge, server-side effect."""

from datetime import datetime, timedelta, timezone
from types import SimpleNamespace

from fastapi import HTTPException
import pytest

from app.models.secured_actions import HarvestPedometerRequest, ValidateRunRequest
from app.models.validation_result import ValidationResult
from app.services.item_price_config import resolve_item_prices
from app.services.secured_action_service import (
    SecuredActionService,
    _commit_harvest_tx,
    _commit_share_activity_purchase_tx,
    _commit_share_activity_use_tx,
    _commit_shop_tx,
    _commit_use_shop_tx,
)
from app.services.share_activity_items import (
    BOOST_EXTRA_DAILY_CAP,
    HATCH_COSMETIC_ID,
    HATCH_FALLBACK_SHARE,
    INCUBATOR_STEP_GOAL,
)
from test_redeem_referral import _MemoryDb, _MemoryTxn

NOW = datetime(2026, 10, 4, 3, 0, tzinfo=timezone.utc)
BOOST = "boost_run"
INCUBATOR = "step_incubator"


def _service(db: _MemoryDb) -> SecuredActionService:
    return SecuredActionService(firebase_service=SimpleNamespace(db=db))


def _wallet(
    share: int = 5_000,
    diamond: int = 9,
    value: int = 4,
    free_share: int | None = None,
    paid_share: int = 0,
) -> dict:
    free = share if free_share is None else free_share
    return {
        "wallet": {
            "shareBalance": share,
            "freeShareBalance": free,
            "paidShareBalance": paid_share,
            "diamondBalance": diamond,
            "valueTokenBalance": value,
            "totalDonationValue": 7,
        }
    }


def _buy(db: _MemoryDb, item_id: str, request_id: str):
    service = _service(db)
    user_ref = db.collection("users").document("u1")
    return _commit_share_activity_purchase_tx.to_wrap(
        _MemoryTxn(), service, "u1", item_id, request_id, user_ref
    )


def _use(db: _MemoryDb, item_id: str, request_id: str, now: datetime = NOW):
    service = _service(db)
    user_ref = db.collection("users").document("u1")
    return _commit_share_activity_use_tx.to_wrap(
        _MemoryTxn(), service, "u1", item_id, request_id, user_ref, now
    )


def _harvest(db: _MemoryDb, steps: int, now: datetime = NOW):
    service = _service(db)
    user_ref = db.collection("users").document("u1")
    return _commit_harvest_tx.to_wrap(
        _MemoryTxn(),
        service,
        "u1",
        HarvestPedometerRequest(claimed_steps=steps),
        user_ref,
        now,
    )


def _ledger(db: _MemoryDb) -> list[dict]:
    return [
        row
        for path, row in db.store.items()
        if path.startswith("walletTransactions/")
    ]


def test_prices_default_and_a_bad_override_keeps_the_code_price() -> None:
    assert resolve_item_prices(None)[BOOST] == 120
    assert resolve_item_prices(None)[INCUBATOR] == 1_200
    overridden = resolve_item_prices({BOOST: 0, INCUBATOR: "1200", "nope": 1})
    assert overridden[BOOST] == 120
    assert overridden[INCUBATOR] == 1_200
    assert "nope" not in overridden
    applied = resolve_item_prices({BOOST: 90, INCUBATOR: 1_000})
    assert applied[BOOST] == 90
    assert applied[INCUBATOR] == 1_000


def test_catalog_share_price_is_not_a_diamond_price() -> None:
    db = _MemoryDb()
    db.store["config/item_prices"] = {BOOST: 90, INCUBATOR: 1_000}
    rows = {row["id"]: row for row in _service(db).shop_catalog()}
    assert rows[BOOST]["shareCost"] == 90
    assert rows[BOOST]["diamondCost"] == 0
    assert rows[INCUBATOR]["shareCost"] == 1_000
    assert rows[INCUBATOR]["diamondCost"] == 0
    assert rows["record_cpr_ticket"]["diamondCost"] == 12
    assert rows["record_cpr_ticket"]["shareCost"] == 0
    assert rows["battle_run_pass"]["diamondCost"] == 120


def test_purchase_spends_share_once_and_leaves_dia_and_value() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet(share=200, free_share=50, paid_share=150)

    result = _buy(db, BOOST, "req-boost-01")

    assert result.status == "purchased"
    assert result.share_balance == 80
    assert result.diamond_balance == 9
    assert result.value_token_balance == 4
    wallet = db.store["users/u1"]["wallet"]
    assert wallet["shareBalance"] == 80
    assert wallet["freeShareBalance"] == 0
    assert wallet["paidShareBalance"] == 80
    assert wallet["diamondBalance"] == 9
    assert wallet["valueTokenBalance"] == 4
    assert wallet["totalDonationValue"] == 7
    assert db.store[f"users/u1/shopInventory/{BOOST}"]["quantity"] == 1
    row = _ledger(db)[0]
    assert row["type"] == "shop_purchase"
    assert row["shareAmount"] == -120
    assert row["shareFreeAmount"] == -50
    assert row["sharePaidAmount"] == -70
    assert "diamondAmount" not in row
    assert "valueAmount" not in row

    again = _buy(db, BOOST, "req-boost-01")
    assert again.status == "already_purchased"
    assert again.share_balance == 80
    assert db.store[f"users/u1/shopInventory/{BOOST}"]["quantity"] == 1
    assert len(_ledger(db)) == 1


def test_config_price_is_what_the_purchase_charges() -> None:
    db = _MemoryDb()
    db.store["config/item_prices"] = {INCUBATOR: 1_000}
    db.store["users/u1"] = _wallet(share=1_000)
    result = _buy(db, INCUBATOR, "req-inc-price")
    assert result.status == "purchased"
    assert result.share_balance == 0
    assert _ledger(db)[0]["shareAmount"] == -1_000


def test_insufficient_share_writes_nothing() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet(share=100)
    with pytest.raises(HTTPException) as exc:
        _buy(db, BOOST, "req-boost-poor")
    assert exc.value.detail == "Insufficient Share balance."
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 100
    assert f"users/u1/shopInventory/{BOOST}" not in db.store
    assert _ledger(db) == []


def test_generic_shop_path_cannot_mint_share_items() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet()
    service = _service(db)
    user_ref = db.collection("users").document("u1")
    with pytest.raises(HTTPException) as bought:
        _commit_shop_tx.to_wrap(_MemoryTxn(), service, "u1", BOOST, user_ref)
    assert bought.value.detail == "request_id is required."
    with pytest.raises(HTTPException) as used:
        _commit_use_shop_tx.to_wrap(_MemoryTxn(), service, "u1", INCUBATOR, user_ref)
    assert used.value.detail == "request_id is required."
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 5_000
    assert _ledger(db) == []


def test_boost_doubles_harvest_share_inside_the_window_only() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet(share=500)
    db.store[f"users/u1/shopInventory/{BOOST}"] = {"quantity": 1}

    used = _use(db, BOOST, "req-boost-use", NOW)
    assert used.status == "used"
    assert db.store[f"users/u1/shopInventory/{BOOST}"]["quantity"] == 0
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 500
    assert db.store["users/u1"]["boostRun"]["useDayKey"] == "2026-10-04"

    inside = _harvest(db, 1_000, NOW + timedelta(minutes=14))
    assert inside.status == "harvested"
    assert inside.share_credited == 200
    assert inside.diamond_balance == 9
    assert inside.value_token_balance == 4
    wallet = db.store["users/u1"]["wallet"]
    assert wallet["shareBalance"] == 700
    assert wallet["diamondBalance"] == 9
    assert wallet["valueTokenBalance"] == 4
    assert wallet["totalDonationValue"] == 7
    harvest = db.store["users/u1"]["pedometerHarvest"]
    assert harvest["harvestedShare"] == 100
    assert harvest["claimedSteps"] == 1_000
    assert db.store["users/u1"]["boostRun"]["extraShare"] == 100
    harvest_row = next(row for row in _ledger(db) if row["type"] == "pedometer_harvest")
    assert harvest_row["shareAmount"] == 200
    assert harvest_row["boostShare"] == 100
    assert "diamondAmount" not in harvest_row
    assert "valueAmount" not in harvest_row
    assert not any(path.startswith("activities/") for path in db.store)

    outside = _harvest(db, 2_000, NOW + timedelta(minutes=15))
    assert outside.share_credited == 100
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 800
    assert db.store["users/u1"]["pedometerHarvest"]["harvestedShare"] == 200
    assert db.store["users/u1"]["boostRun"]["extraShare"] == 100


def test_boost_is_once_per_kst_day_and_the_replay_does_not_consume() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet()
    db.store[f"users/u1/shopInventory/{BOOST}"] = {"quantity": 2}

    assert _use(db, BOOST, "req-boost-day", NOW).status == "used"
    again = _use(db, BOOST, "req-boost-day", NOW + timedelta(minutes=1))
    assert again.status == "already_used"
    assert db.store[f"users/u1/shopInventory/{BOOST}"]["quantity"] == 1

    with pytest.raises(HTTPException) as capped:
        _use(db, BOOST, "req-boost-day2", NOW + timedelta(hours=1))
    assert capped.value.detail == "Boost run already used today."
    assert db.store[f"users/u1/shopInventory/{BOOST}"]["quantity"] == 1

    nxt = _use(db, BOOST, "req-boost-next", NOW + timedelta(hours=16))
    assert nxt.status == "used"
    assert db.store["users/u1"]["boostRun"]["useDayKey"] == "2026-10-05"
    assert db.store[f"users/u1/shopInventory/{BOOST}"]["quantity"] == 0


def test_boost_extra_stops_at_the_daily_ceiling() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet(share=10)
    db.store["users/u1"]["boostRun"] = {
        "useDayKey": "2026-10-04",
        "expiresAt": (NOW + timedelta(minutes=10)).isoformat(),
        "extraDayKey": "2026-10-04",
        "extraShare": BOOST_EXTRA_DAILY_CAP - 10,
    }

    first = _harvest(db, 2_000, NOW)
    assert first.share_credited == 210
    assert db.store["users/u1"]["boostRun"]["extraShare"] == BOOST_EXTRA_DAILY_CAP
    assert db.store["users/u1"]["pedometerHarvest"]["harvestedShare"] == 200

    second = _harvest(db, 3_000, NOW + timedelta(minutes=1))
    assert second.share_credited == 100
    assert db.store["users/u1"]["boostRun"]["extraShare"] == BOOST_EXTRA_DAILY_CAP
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 320


def test_boost_does_not_change_a_verified_run_or_race_share() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {
        **_wallet(share=500),
        "crewId": "crew1",
        "boostRun": {
            "useDayKey": "2026-10-04",
            "expiresAt": (datetime.now(timezone.utc) + timedelta(minutes=10)).isoformat(),
            "extraDayKey": "2026-10-04",
            "extraShare": 0,
        },
    }
    db.store["crews/crew1"] = {"totalValue": 12, "cheerFlag": {"dayKey": _service(db)._economy_service.kst_today_key()}}
    db.store["tournaments/race"] = {"shareReward": 200}
    service = _service(db)
    request = ValidateRunRequest(
        activity_id="act1",
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
    outcome = service._persist_validation_tx(
        _MemoryTxn(),
        "u1",
        request,
        result,
        db.collection("activities").document("act1"),
        db.collection("users").document("u1"),
    )

    assert outcome.value_token_reward == 10
    wallet = db.store["users/u1"]["wallet"]
    assert wallet["shareBalance"] == 520
    assert wallet["diamondBalance"] == 9
    assert wallet["valueTokenBalance"] == 14
    assert wallet["totalDonationValue"] == 7
    activity = db.store["activities/act1"]
    assert activity["valueTokenReward"] == 10
    assert activity["averagePaceSecondsPerKm"] == 300
    assert "boostShare" not in activity
    assert "rank" not in activity
    assert db.store["crews/crew1"]["totalValue"] == 12
    cheer = db.store["walletTransactions/crew_cheer_act1"]
    assert cheer["shareAmount"] == 20
    assert cheer["type"] == "crew_cheer_share"


def test_incubator_hatches_one_fixed_cosmetic_from_capped_steps() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet(share=2_000)
    db.store[f"users/u1/shopInventory/{INCUBATOR}"] = {"quantity": 2}
    assert _use(db, INCUBATOR, "req-egg-01", NOW).status == "used"
    assert db.store["users/u1"]["stepIncubator"]["steps"] == 0

    _harvest(db, 5_000, NOW)
    assert db.store["users/u1"]["stepIncubator"]["steps"] == 5_000

    capped = _harvest(db, 999_999, NOW + timedelta(hours=1))
    assert capped.share_credited == 100
    assert db.store["users/u1"]["stepIncubator"]["steps"] == 17_000
    assert db.store["users/u1"]["pedometerHarvest"]["claimedSteps"] == 17_000

    blocked = _harvest(db, 999_999, NOW + timedelta(hours=1))
    assert blocked.status == "hourly_cap_reached"
    assert blocked.share_credited == 0
    assert db.store["users/u1"]["stepIncubator"]["steps"] == 17_000

    _harvest(db, 29_000, NOW + timedelta(hours=2))
    assert db.store["users/u1"]["stepIncubator"]["status"] == "active"
    assert db.store["users/u1"]["stepIncubator"]["steps"] == 29_000

    _harvest(db, 41_000, NOW + timedelta(hours=3))
    state = db.store["users/u1"]["stepIncubator"]
    assert state["status"] == "hatched"
    assert state["steps"] == 41_000
    assert state["steps"] >= INCUBATOR_STEP_GOAL
    assert state["rewardItemId"] == HATCH_COSMETIC_ID
    assert state["rewardShare"] == 0
    cosmetic = db.store[f"users/u1/shopInventory/{HATCH_COSMETIC_ID}"]
    assert cosmetic["quantity"] == 1
    assert cosmetic["category"] == "shoe_skin"
    assert cosmetic["title"] == "민트 러닝화"
    hatch = db.store["walletTransactions/step_incubator_u1_req-egg-01"]
    assert hatch["type"] == "step_incubator_hatch"
    assert hatch["rewardItemId"] == HATCH_COSMETIC_ID
    assert "shareAmount" not in hatch
    assert "diamondAmount" not in hatch
    assert "valueAmount" not in hatch
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 9
    assert db.store["users/u1"]["wallet"]["valueTokenBalance"] == 4
    assert db.store["users/u1"]["wallet"]["totalDonationValue"] == 7

    _harvest(db, 53_000, NOW + timedelta(hours=4))
    assert db.store[f"users/u1/shopInventory/{HATCH_COSMETIC_ID}"]["quantity"] == 1
    assert len([row for row in _ledger(db) if row["type"] == "step_incubator_hatch"]) == 1

    started = _use(db, INCUBATOR, "req-egg-02", NOW + timedelta(days=1))
    assert started.status == "used"
    assert db.store["users/u1"]["stepIncubator"]["status"] == "active"
    assert db.store["users/u1"]["stepIncubator"]["steps"] == 0
    assert db.store[f"users/u1/shopInventory/{INCUBATOR}"]["quantity"] == 0
    replay = _use(db, INCUBATOR, "req-egg-02", NOW + timedelta(days=1, minutes=1))
    assert replay.status == "already_used"
    assert db.store[f"users/u1/shopInventory/{INCUBATOR}"]["quantity"] == 0

    with pytest.raises(HTTPException) as busy:
        _use(db, INCUBATOR, "req-egg-03", NOW + timedelta(days=1, hours=1))
    assert busy.value.detail == "An incubator is already active."
    assert db.store[f"users/u1/shopInventory/{INCUBATOR}"]["quantity"] == 0


def test_steps_before_activation_do_not_count() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet()
    _harvest(db, 4_000, NOW)
    assert "stepIncubator" not in db.store["users/u1"]
    db.store[f"users/u1/shopInventory/{INCUBATOR}"] = {"quantity": 1}
    _use(db, INCUBATOR, "req-egg-late", NOW + timedelta(minutes=5))
    _harvest(db, 6_000, NOW + timedelta(minutes=6))
    assert db.store["users/u1"]["stepIncubator"]["steps"] == 2_000


def test_owned_cosmetic_hatches_fixed_share_and_never_dia() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet(share=100)
    db.store["users/u1"]["stepIncubator"] = {
        "status": "active",
        "steps": INCUBATOR_STEP_GOAL - 1_000,
        "requestId": "req-owned",
    }
    db.store[f"users/u1/shopInventory/{HATCH_COSMETIC_ID}"] = {
        "quantity": 1,
        "category": "shoe_skin",
    }

    result = _harvest(db, 12_000, NOW)
    assert result.share_credited == 600 + HATCH_FALLBACK_SHARE
    assert result.diamond_balance == 9
    assert result.value_token_balance == 4
    wallet = db.store["users/u1"]["wallet"]
    assert wallet["shareBalance"] == 100 + 600 + HATCH_FALLBACK_SHARE
    assert wallet["diamondBalance"] == 9
    assert wallet["valueTokenBalance"] == 4
    assert db.store[f"users/u1/shopInventory/{HATCH_COSMETIC_ID}"]["quantity"] == 1
    hatch = db.store["walletTransactions/step_incubator_u1_req-owned"]
    assert hatch["shareAmount"] == HATCH_FALLBACK_SHARE
    assert "diamondAmount" not in hatch
    assert "valueAmount" not in hatch
    assert db.store["users/u1"]["stepIncubator"]["rewardItemId"] == ""
