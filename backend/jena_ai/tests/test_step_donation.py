"""Step donation: a KST day with 6,000+ steps makes the company donate 50 won, once."""

from datetime import datetime, timedelta, timezone
from types import SimpleNamespace

from app.models.secured_actions import HarvestPedometerRequest
from app.services import donation_cap as cap
from app.services.secured_action_service import (
    SecuredActionService,
    _commit_harvest_tx,
)
from test_redeem_referral import _MemoryDb, _MemoryTxn
from test_verified_run_donation import NOW as RUN_NOW
from test_verified_run_donation import _persist

NOW = datetime(2026, 11, 20, 3, 0, tzinfo=timezone.utc)  # 12:00 KST, 2026-11-20
DAY = "2026-11-20"
LEDGER = "donationLedger/step_goal_u1_20261120"
TOTALS = "donationMonthTotals/2026-11"


def _db(**user_fields) -> _MemoryDb:
    db = _MemoryDb()
    db.store["users/u1"] = {
        "wallet": {"shareBalance": 0, "diamondBalance": 0, "valueTokenBalance": 0},
        **user_fields,
    }
    return db


def _harvest(db: _MemoryDb, steps: int, now: datetime = NOW):
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))
    user_ref = db.collection("users").document("u1")
    return _commit_harvest_tx.to_wrap(
        _MemoryTxn(), service, "u1", HarvestPedometerRequest(claimed_steps=steps), user_ref, now
    )


def _step_rows(db: _MemoryDb) -> list[str]:
    return [p for p in db.store if p.startswith("donationLedger/step_goal_")]


def test_the_rule_in_numbers() -> None:
    assert cap.STEP_DONATION_THRESHOLD_STEPS == 6000
    assert cap.STEP_DONATION_KRW == 50
    assert cap.step_donation_requested_won(5999) == 0
    assert cap.step_donation_requested_won(6000) == 50
    assert cap.step_donation_requested_won(50_000) == 50
    assert cap.step_goal_doc_id("u1", "2026-11-20") == "step_goal_u1_20261120"


def test_5999_steps_donate_nothing() -> None:
    db = _db()

    _harvest(db, 5999)

    assert _step_rows(db) == []
    assert TOTALS not in db.store
    assert "donationDaily" not in db.store["users/u1"]


def test_6000_steps_donate_50_won_and_nothing_else_moves() -> None:
    db = _db()

    result = _harvest(db, 6000)

    row = db.store[LEDGER]
    assert row["type"] == "step_goal_donation"
    assert row["uid"] == "u1"
    assert row["companyWon"] == 50
    assert row["receiptIssued"] is False
    assert row["monthKey"] == "2026-11"
    assert row["date"] == DAY
    assert row["steps"] == 6000
    assert "capped" not in row
    assert db.store[TOTALS]["totalWon"] == 50
    assert db.store[TOTALS]["stepWon"] == 50
    assert db.store[TOTALS]["capWon"] == 1_000_000
    # What the walk earns is unchanged: 600 SHARE for 6,000 steps, wallet untouched otherwise.
    assert result.share_credited == 600
    wallet = db.store["users/u1"]["wallet"]
    assert wallet["shareBalance"] == 600
    assert wallet["diamondBalance"] == 0
    assert wallet["valueTokenBalance"] == 0
    assert not [p for p in db.store if p.startswith("walletTransactions/") and
                db.store[p].get("type") == "step_goal_donation"]


def test_step_won_is_kept_apart_from_run_won_in_donation_daily() -> None:
    db = _db()

    _harvest(db, 6000)

    assert db.store["users/u1"]["donationDaily"] == {
        "day": DAY,
        "countedKm": 0.0,
        "countedWon": 50,
        "stepWon": 50,
    }


def test_the_same_day_twice_donates_once() -> None:
    db = _db()

    _harvest(db, 6000)
    _harvest(db, 6000)  # same watermark: nothing new
    _harvest(db, 9000, NOW + timedelta(hours=2))  # more steps later the same day

    assert _step_rows(db) == [LEDGER]
    assert db.store[TOTALS]["totalWon"] == 50
    assert db.store[TOTALS]["stepWon"] == 50
    assert db.store["users/u1"]["donationDaily"]["countedWon"] == 50


def test_crossing_the_goal_in_two_calls_donates_once() -> None:
    db = _db()

    _harvest(db, 3000)
    assert _step_rows(db) == []
    _harvest(db, 6500, NOW + timedelta(hours=1))

    assert _step_rows(db) == [LEDGER]
    assert db.store[TOTALS]["totalWon"] == 50


def test_the_next_kst_day_donates_again() -> None:
    db = _db()
    _harvest(db, 6000)

    _harvest(db, 6000, NOW + timedelta(days=1))

    assert sorted(_step_rows(db)) == [
        "donationLedger/step_goal_u1_20261120",
        "donationLedger/step_goal_u1_20261121",
    ]
    assert db.store[TOTALS]["totalWon"] == 100
    assert db.store["users/u1"]["donationDaily"]["day"] == "2026-11-21"
    assert db.store["users/u1"]["donationDaily"]["stepWon"] == 50


def test_a_full_day_room_of_1000_won_leaves_no_step_donation() -> None:
    db = _db(donationDaily={"day": DAY, "countedKm": 10.0, "countedWon": 1000})

    _harvest(db, 6000)

    assert _step_rows(db) == []
    assert TOTALS not in db.store
    assert db.store["users/u1"]["donationDaily"]["countedWon"] == 1000


def test_only_what_fits_in_the_day_room_is_recorded() -> None:
    db = _db(donationDaily={"day": DAY, "countedKm": 9.8, "countedWon": 980})

    _harvest(db, 6000)

    row = db.store[LEDGER]
    assert row["companyWon"] == 20
    assert row["requestedWon"] == 50
    assert row["capped"] is True
    assert db.store["users/u1"]["donationDaily"]["countedWon"] == 1000
    assert db.store["users/u1"]["donationDaily"]["stepWon"] == 20


def test_a_run_donation_from_yesterday_does_not_use_todays_room() -> None:
    db = _db(donationDaily={"day": "2026-11-19", "countedKm": 10.0, "countedWon": 1000})

    _harvest(db, 6000)

    assert db.store[LEDGER]["companyWon"] == 50
    assert db.store["users/u1"]["donationDaily"]["countedWon"] == 50


def test_the_monthly_cap_stops_the_step_donation() -> None:
    db = _db()
    db.store[TOTALS] = {"monthKey": "2026-11", "totalWon": 1_000_000, "capWon": 1_000_000}

    _harvest(db, 6000)

    assert _step_rows(db) == []
    assert db.store[TOTALS]["totalWon"] == 1_000_000
    assert "donationDaily" not in db.store["users/u1"]


def test_only_what_is_left_under_the_monthly_cap_is_recorded() -> None:
    db = _db()
    db.store[TOTALS] = {"monthKey": "2026-11", "totalWon": 999_980, "capWon": 1_000_000}

    _harvest(db, 6000)

    assert db.store[LEDGER]["companyWon"] == 20
    assert db.store[LEDGER]["capped"] is True
    assert db.store[TOTALS]["totalWon"] == 1_000_000


def test_the_cap_in_config_is_used_not_a_fixed_number() -> None:
    db = _db()
    db.store["config/company_donation"] = {"monthlyCapWon": 30}

    _harvest(db, 6000)

    assert db.store[LEDGER]["companyWon"] == 30
    assert db.store[TOTALS]["capWon"] == 30


def test_the_hourly_step_cap_still_limits_a_spoofed_claim() -> None:
    db = _db()

    _harvest(db, 999_999)

    # 12,000 steps are accepted in one hour. One day still means one 50 won gift.
    assert db.store["users/u1"]["pedometerHarvest"]["claimedSteps"] == 12_000
    assert _step_rows(db) == [LEDGER]
    assert db.store[TOTALS]["totalWon"] == 50


def test_a_run_the_same_day_keeps_the_step_won_and_the_room() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {
        "nickname": "달림이",
        "wallet": {"shareBalance": 0, "diamondBalance": 0, "valueTokenBalance": 0},
        "donationDaily": {"day": "2026-10-07", "countedKm": 0.0, "countedWon": 50, "stepWon": 50},
    }

    _persist(db, "act-1", 1.0)

    daily = db.store["users/u1"]["donationDaily"]
    assert daily["countedWon"] == 150
    assert daily["stepWon"] == 50
    assert daily["countedKm"] == 1.0
