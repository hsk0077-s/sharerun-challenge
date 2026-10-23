from datetime import datetime, timezone

import pytest
from fastapi import HTTPException

from app.services import daily_steps
from test_redeem_referral import _MemoryDb, _MemoryTxn

NOW = datetime(2026, 10, 24, 3, 0, tzinfo=timezone.utc)  # 12:00 KST, 2026-10-24
PATH = "users/u1/daily_metrics/{}"


def _ref(db, day):
    return db.collection("users").document("u1").collection("daily_metrics").document(day)


def _run(db, day, steps, *, health=None, source="sensor"):
    _, is_today = daily_steps._parse_day(day, NOW)
    return daily_steps.apply_daily_steps(
        _MemoryTxn(),
        _ref(db, day),
        steps=steps,
        source=source,
        last_health=health,
        is_today=is_today,
    )


def test_a_new_day_is_saved_with_server_km() -> None:
    db = _MemoryDb()
    assert _run(db, "2026-10-24", 4000)["status"] == "saved"
    row = db.store[PATH.format("2026-10-24")]
    assert row["steps"] == 4000 and row["km"] == 3.0 and row["source"] == "sensor"


def test_totals_only_go_up() -> None:
    db = _MemoryDb()
    _run(db, "2026-10-24", 4000)
    assert _run(db, "2026-10-24", 3000)["status"] == "unchanged"
    assert _run(db, "2026-10-24", 5000)["steps"] == 5000
    _run(db, "2026-10-20", 9000)
    assert _run(db, "2026-10-20", 100)["status"] == "unchanged"


def test_streak_marks_are_kept() -> None:
    db = _MemoryDb()
    db.store[PATH.format("2026-10-23")] = {"steps": 100, "streakCovered": True}
    _run(db, "2026-10-23", 8000)
    assert db.store[PATH.format("2026-10-23")]["streakCovered"] is True


def test_steps_far_above_health_are_refused_and_a_bad_total_can_heal() -> None:
    db = _MemoryDb()
    assert _run(db, "2026-10-24", 20000, health=5000)["status"] == "unchanged"
    db.store[PATH.format("2026-10-24")] = {"steps": 25000}
    assert _run(db, "2026-10-24", 6000, health=5000)["steps"] == 6000


@pytest.mark.parametrize("day", ["2026-10-25", "2026-09-01", "garbage"])
def test_days_outside_the_window_are_refused(day: str) -> None:
    with pytest.raises(HTTPException) as caught:
        daily_steps.record_daily_steps(_MemoryDb(), "u1", day, 100, "sensor", None, now=NOW)
    assert caught.value.status_code == 400


def test_step_range_is_enforced() -> None:
    for bad in (0, 30001):
        with pytest.raises(HTTPException):
            daily_steps.record_daily_steps(_MemoryDb(), "u1", "2026-10-24", bad, "sensor", None, now=NOW)
