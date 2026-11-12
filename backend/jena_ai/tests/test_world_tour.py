"""World Tour: a verified run links to one mission once; the passport follows."""

import pytest
from fastapi import HTTPException

from app.services import world_tour as wt
from test_redeem_referral import _MemoryDb, _MemoryTxn


def _db_with_runs(**runs: dict) -> _MemoryDb:
    db = _MemoryDb()
    for activity_id, fields in runs.items():
        base = {
            "userId": "u1",
            "distanceKm": 1.0,
            "validationFinalized": True,
            "jenaVerified": True,
        }
        base.update(fields)
        db.store[f"activities/{activity_id}"] = base
    return db


def _attach(db: _MemoryDb, mission: str, activity: str, uid: str = "u1"):
    return wt.attach_in_txn(_MemoryTxn(), db, uid, mission, activity)


def _code(call) -> tuple[int, str]:
    with pytest.raises(HTTPException) as error:
        call()
    return error.value.status_code, error.value.detail


def test_a_verified_run_adds_its_whole_distance_to_the_chosen_mission() -> None:
    db = _db_with_runs(a1={"distanceKm": 2.5})

    result = _attach(db, "japan_fuji", "a1")

    assert result.counted_km == pytest.approx(2.5)
    assert result.progress_km == pytest.approx(2.5)
    assert result.target_km == 3.0
    assert result.state == "active"
    assert result.stamp_id is None
    assert result.already_attached is False
    assert db.store["users/u1/worldTour/japan_fuji"]["progressKm"] == pytest.approx(2.5)
    guard = db.store["users/u1/worldTourRuns/a1"]
    assert guard["missionId"] == "japan_fuji"
    assert guard["countedKm"] == pytest.approx(2.5)


def test_the_daily_cap_distance_is_not_used() -> None:
    db = _db_with_runs(a1={"distanceKm": 4.0, "dailyCountedKm": 0.5})
    assert _attach(db, "japan_fuji", "a1").counted_km == pytest.approx(4.0)


def test_the_same_run_twice_adds_nothing_the_second_time() -> None:
    db = _db_with_runs(a1={"distanceKm": 1.5})
    first = _attach(db, "india_taj", "a1")
    again = _attach(db, "india_taj", "a1")

    assert first.already_attached is False
    assert again.already_attached is True
    assert again.progress_km == pytest.approx(1.5)
    assert again.counted_km == pytest.approx(1.5)
    assert db.store["users/u1/worldTour/india_taj"]["progressKm"] == pytest.approx(1.5)


def test_the_same_run_cannot_feed_a_second_mission() -> None:
    db = _db_with_runs(a1={"distanceKm": 1.5})
    _attach(db, "india_taj", "a1")

    assert _code(lambda: _attach(db, "japan_fuji", "a1")) == (409, "run_already_linked")
    assert "users/u1/worldTour/japan_fuji" not in db.store


def test_an_unverified_run_is_refused_and_nothing_is_written() -> None:
    db = _db_with_runs(a1={"jenaVerified": False})
    assert _code(lambda: _attach(db, "france_eiffel", "a1")) == (422, "run_not_verified")
    assert "users/u1/worldTourRuns/a1" not in db.store
    assert "users/u1/worldTour/france_eiffel" not in db.store


def test_a_run_whose_validation_is_not_finished_is_refused() -> None:
    db = _db_with_runs(a1={"validationFinalized": False})
    assert _code(lambda: _attach(db, "france_eiffel", "a1")) == (409, "run_not_finalized")
    assert "users/u1/worldTourRuns/a1" not in db.store


def test_someone_elses_run_is_refused() -> None:
    db = _db_with_runs(a1={"userId": "u2"})
    assert _code(lambda: _attach(db, "france_eiffel", "a1")) == (403, "activity_not_yours")
    assert not [p for p in db.store if p.startswith("users/u1/")]


def test_a_missing_run_or_mission_is_not_found() -> None:
    db = _db_with_runs(a1={})
    assert _code(lambda: _attach(db, "france_eiffel", "nope")) == (404, "activity_not_found")
    assert _code(lambda: _attach(db, "atlantis", "a1")) == (404, "mission_not_found")


def test_reaching_the_target_completes_the_mission_with_a_stamp() -> None:
    db = _db_with_runs(a1={"distanceKm": 1.2}, a2={"distanceKm": 1.0})

    first = _attach(db, "india_taj", "a1")
    assert first.state == "active"
    assert first.newly_completed is False

    last = _attach(db, "india_taj", "a2")
    assert last.state == "completed"
    assert last.newly_completed is True
    assert last.stamp_id == "stamp-india_taj"
    row = db.store["users/u1/worldTour/india_taj"]
    assert row["state"] == "completed"
    assert row["stampId"] == "stamp-india_taj"
    assert row["completedAt"] is not None


def test_one_long_run_can_finish_a_short_mission() -> None:
    db = _db_with_runs(a1={"distanceKm": 1.0})
    result = _attach(db, "france_eiffel", "a1")
    assert result.state == "completed"
    assert result.stamp_id == "stamp-france_eiffel"


def test_a_finished_mission_refuses_a_new_run_and_keeps_its_stamp() -> None:
    db = _db_with_runs(a1={"distanceKm": 1.0}, a2={"distanceKm": 3.0})
    _attach(db, "france_eiffel", "a1")

    assert _code(lambda: _attach(db, "france_eiffel", "a2")) == (409, "mission_completed")
    assert "users/u1/worldTourRuns/a2" not in db.store
    assert db.store["users/u1/worldTour/france_eiffel"]["progressKm"] == pytest.approx(1.0)


def test_repeating_the_finishing_call_still_answers_with_the_stamp() -> None:
    db = _db_with_runs(a1={"distanceKm": 1.0})
    _attach(db, "france_eiffel", "a1")
    again = _attach(db, "france_eiffel", "a1")
    assert again.already_attached is True
    assert again.state == "completed"
    assert again.stamp_id == "stamp-france_eiffel"
    assert again.newly_completed is False


def test_attaching_never_touches_the_run_or_the_wallet() -> None:
    db = _db_with_runs(a1={"distanceKm": 3.0})
    db.store["users/u1"] = {"wallet": {"shareBalance": 7}}
    before_activity = dict(db.store["activities/a1"])

    _attach(db, "japan_fuji", "a1")

    assert db.store["activities/a1"] == before_activity
    assert db.store["users/u1"] == {"wallet": {"shareBalance": 7}}
    assert not [p for p in db.store if p.startswith("walletTransactions")]


def test_the_seed_has_the_five_open_missions() -> None:
    assert [(m["missionId"], m["targetKm"]) for m in wt.MISSION_SEED] == [
        ("france_eiffel", 1.0),
        ("india_taj", 2.0),
        ("japan_fuji", 3.0),
        ("egypt_pyramids", 5.0),
        ("usa_liberty", 3.0),
    ]
    assert all(m["active"] is True for m in wt.MISSION_SEED)


def test_read_me_lists_missions_with_progress_and_the_passport() -> None:
    db = _db_with_runs(a1={"distanceKm": 1.0}, a2={"distanceKm": 1.5})
    _attach(db, "france_eiffel", "a1")
    _attach(db, "japan_fuji", "a2")

    me = wt.read_me(db, "u1")

    assert [m.mission_id for m in me.missions] == [
        "france_eiffel",
        "india_taj",
        "japan_fuji",
        "egypt_pyramids",
        "usa_liberty",
    ]
    by_id = {m.mission_id: m for m in me.missions}
    assert by_id["france_eiffel"].state == "completed"
    assert by_id["japan_fuji"].progress_km == pytest.approx(1.5)
    assert by_id["india_taj"].progress_km == 0
    assert [s.mission_id for s in me.passport] == ["france_eiffel"]
    assert (me.completed_count, me.total_count) == (1, 5)


def test_read_me_for_a_new_user_shows_all_open_and_an_empty_passport() -> None:
    me = wt.read_me(_MemoryDb(), "new")
    assert me.total_count == 5
    assert me.completed_count == 0
    assert me.passport == []
    assert all(m.state == "active" and m.progress_km == 0 for m in me.missions)


def test_another_users_progress_is_not_shown() -> None:
    db = _db_with_runs(a1={"distanceKm": 1.0})
    _attach(db, "france_eiffel", "a1")
    assert wt.read_me(db, "u2").completed_count == 0


def test_seeding_writes_the_catalog_and_read_me_uses_it() -> None:
    db = _MemoryDb()
    assert wt.seed_missions(db) == 5
    assert db.store["worldTourMissions/japan_fuji"]["targetKm"] == 3.0
    db.store["worldTourMissions/usa_liberty"]["active"] = False
    ids = [m.mission_id for m in wt.read_me(db, "u1").missions]
    assert "usa_liberty" not in ids
    assert len(ids) == 4
