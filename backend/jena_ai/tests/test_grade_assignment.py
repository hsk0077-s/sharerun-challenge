"""Grade is set once, by the server, from the median of three 1km runs."""

from datetime import datetime, timedelta, timezone
from types import SimpleNamespace

from app.models.secured_actions import ValidateRunRequest
from app.models.validation_result import ValidationResult
from app.services.grade_assignment import (
    advance_grade_runs,
    assignment_from_runs,
    grade_for_pace,
    median_pace,
)
from app.services.secured_action_service import SecuredActionService
from test_redeem_referral import _MemoryDb, _MemoryTxn

DAY1 = datetime(2026, 10, 6, 1, 0, tzinfo=timezone.utc)


def test_pace_table_matches_the_app_ladder() -> None:
    cases = {
        0: ("cheetah_master", 25),
        199: ("cheetah_master", 25),
        200: ("cheetah_diamond", 24),
        239: ("cheetah_bronze", 21),
        240: ("gazelle_master", 20),
        299: ("gazelle_bronze", 16),
        300: ("wolf_master", 15),
        323: ("wolf_diamond", 14),
        324: ("wolf_gold", 13),
        359: ("wolf_bronze", 11),
        360: ("rabbit_master", 10),
        449: ("rabbit_bronze", 6),
        450: ("turtle_master", 5),
        540: ("turtle_silver", 2),
        900: ("turtle_bronze", 1),
    }
    for pace, expected in cases.items():
        assert grade_for_pace(pace) == expected, pace


def test_median_of_three_ignores_one_fast_or_slow_run() -> None:
    assert median_pace([600, 330, 340]) == 340
    assert median_pace([200, 700, 330]) == 330


def test_runs_count_once_per_day_and_once_per_activity() -> None:
    runs, counted = advance_grade_runs(None, activity_id="a1", day_key="2026-10-06", pace_sec=330)
    assert counted and len(runs) == 1
    same_day, counted = advance_grade_runs(runs, activity_id="a2", day_key="2026-10-06", pace_sec=300)
    assert not counted and same_day == runs
    replay, counted = advance_grade_runs(runs, activity_id="a1", day_key="2026-10-07", pace_sec=330)
    assert not counted and replay == runs
    assert assignment_from_runs(runs) is None


def _service(db: _MemoryDb) -> SecuredActionService:
    return SecuredActionService(firebase_service=SimpleNamespace(db=db))


def _persist(
    db: _MemoryDb,
    activity_id: str,
    day: int,
    *,
    distance_km: float = 1.0,
    seconds: int = 330,
    verified: bool = True,
) -> None:
    service = _service(db)
    request = ValidateRunRequest(
        activity_id=activity_id,
        distance_km=distance_km,
        duration_seconds=seconds,
        gyro_stability_score=0.9,
    )
    result = ValidationResult(
        verified=verified,
        decision="verified" if verified else "rejected_unknown",
        reason="ok",
        value_token_reward=0,
        forfeit_deposit=False,
    )
    service._persist_validation_tx(
        _MemoryTxn(),
        "u1",
        request,
        result,
        db.collection("activities").document(activity_id),
        db.collection("users").document("u1"),
        now=DAY1 + timedelta(days=day),
    )


def _seed(db: _MemoryDb, **extra) -> None:
    db.store["users/u1"] = {
        "nickname": "달림이",
        "wallet": {"shareBalance": 0, "diamondBalance": 0, "valueTokenBalance": 0},
        **extra,
    }


def _user(db: _MemoryDb) -> dict:
    return db.store["users/u1"]


def test_third_distinct_day_run_sets_the_grade_from_the_median_once() -> None:
    db = _MemoryDb()
    _seed(db)

    _persist(db, "a1", 0, seconds=600)
    _persist(db, "a2", 1, seconds=330)
    assert "gradeRank" not in _user(db)
    _persist(db, "a3", 2, seconds=340)

    user = _user(db)
    assert user["gradeCode"] == "wolf_silver"
    assert user["gradeRank"] == 12
    record = db.store["gradeAssignments/u1"]
    assert record["type"] == "initial_grade"
    assert record["medianPaceSec"] == 340
    assert [row["activityId"] for row in record["runs"]] == ["a1", "a2", "a3"]

    _persist(db, "a3", 2, seconds=340)
    _persist(db, "a4", 3, seconds=200)
    assert _user(db)["gradeRank"] == 12
    assert db.store["gradeAssignments/u1"] == record


def test_same_day_second_run_counts_as_one() -> None:
    db = _MemoryDb()
    _seed(db)

    _persist(db, "a1", 0)
    _persist(db, "a2", 0)
    _persist(db, "a3", 1)

    assert "gradeRank" not in _user(db)
    assert len(_user(db)["economy"]["gradeRuns"]) == 2


def test_short_or_unverified_runs_do_not_count() -> None:
    db = _MemoryDb()
    _seed(db)

    _persist(db, "short", 0, distance_km=0.9, seconds=300)
    _persist(db, "bad", 1, verified=False)

    assert "economy" not in _user(db) or "gradeRuns" not in _user(db)["economy"]


def test_a_user_who_already_has_a_grade_keeps_it() -> None:
    db = _MemoryDb()
    _seed(db, gradeCode="rabbit_gold", gradeRank=8)

    for index in range(4):
        _persist(db, f"a{index}", index, seconds=200)

    assert _user(db)["gradeRank"] == 8
    assert "gradeAssignments/u1" not in db.store


def _activity(db: _MemoryDb, activity_id: str, day: int, seconds: int, **extra) -> None:
    db.store[f"activities/{activity_id}"] = {
        "userId": "u1",
        "jenaVerified": True,
        "distanceKm": 1.0,
        "durationSeconds": seconds,
        "completedAt": (DAY1 + timedelta(days=day)).isoformat(),
        **extra,
    }


def test_backfill_dry_run_writes_nothing_then_real_run_is_repeatable() -> None:
    from app.services.grade_assignment import backfill_grades

    db = _MemoryDb()
    _seed(db)
    _activity(db, "old1", 0, 340)
    _activity(db, "old2", 1, 330)
    _activity(db, "old3", 2, 350)
    _activity(db, "late", 9, 200)
    _activity(db, "same-day", 1, 100)
    _activity(db, "short", 3, 250, distanceKm=0.5)
    db.store["users/u2"] = {"wallet": {}}
    _activity(db, "other", 0, 300, userId="u2")

    preview = backfill_grades(db, dry_run=True)
    assert preview["planned"] == 1 and preview["written"] == 0
    assert preview["grades"][0]["uid"] == "u1"
    assert preview["grades"][0]["gradeCode"] == "wolf_silver"
    assert "gradeRank" not in _user(db)
    assert "gradeAssignments/u1" not in db.store

    done = backfill_grades(db, dry_run=False)
    assert done["written"] == 1
    assert _user(db)["gradeRank"] == 12
    assert db.store["gradeAssignments/u1"]["source"] == "backfill"
    assert "gradeRank" not in db.store["users/u2"]

    again = backfill_grades(db, dry_run=False)
    assert again["written"] == 0 and again["planned"] == 0
