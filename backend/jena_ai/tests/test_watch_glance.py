"""The watch glance is a read of tour, goals, race, crew and diamonds."""

from copy import deepcopy
from datetime import datetime, timezone

from app.services import watch_glance
from test_redeem_referral import _MemoryDb

NOW = datetime(2026, 10, 28, 1, 0, tzinfo=timezone.utc)  # Wednesday, KST morning


def _db() -> _MemoryDb:
    db = _MemoryDb()
    db.store["users/u1"] = {
        "gradeCode": "wolf_bronze",
        "crewId": "crew1",
        "wallet": {"diamondBalance": 12, "shareBalance": 40},
    }
    db.store["users/u1/daily_metrics/2026-10-28"] = {"km": 1.5, "steps": 2000}
    db.store["users/u1/daily_metrics/2026-10-26"] = {"km": 2.0}
    db.store["users/u1/worldTour/france_eiffel"] = {"state": "active", "progressKm": 0.4}
    db.store["crews/crew1"] = {"name": "새벽", "memberCount": 5}
    db.store["crewMonthly/2026-10/crews/crew1"] = {"distanceKm": 20.0}
    db.store["crews/crew1/runs/a1"] = {
        "distanceKm": 3.5,
        "createdAt": NOW,
        "uid": "u1",
    }
    db.store["crews/crew1/runs/old"] = {
        "distanceKm": 9.0,
        "createdAt": datetime(2026, 10, 20, 1, 0, tzinfo=timezone.utc),
        "uid": "u1",
    }
    db.store["tournaments/race"] = {
        "title": "한강 5km",
        "status": "active",
        "participantCount": 2,
    }
    db.store["tournaments/race/participants/u1"] = {
        "uid": "u1",
        "status": "joined",
        "verifiedFinish": True,
        "durationSeconds": 1500,
        "joinedAt": NOW,
    }
    db.store["tournaments/race/participants/u2"] = {
        "uid": "u2",
        "status": "joined",
        "verifiedFinish": True,
        "durationSeconds": 1400,
    }
    db.store["tournaments/closed/participants/u1"] = {
        "uid": "u1",
        "status": "joined",
        "verifiedFinish": True,
        "durationSeconds": 1000,
    }
    db.store["tournaments/closed"] = {"title": "지난 대회", "status": "finished"}
    return db


def test_glance_reads_the_four_faces_and_writes_nothing() -> None:
    db = _db()
    before = deepcopy(db.store)
    board = watch_glance.build(db, "u1", now=NOW)
    assert db.store == before

    assert board["tier_code"] == "wolf"
    assert board["diamond_balance"] == 12
    tour = board["world_tour"]
    assert tour["landmark_id"] == "eiffel_tower"
    assert tour["country_code"] == "FR"
    assert tour["remaining_km"] == 0.6
    assert tour["completed_count"] == 0
    assert tour["total_count"] == 13
    assert tour["all_done"] is False
    assert board["goals"] == {
        "today_km": 1.5,
        "today_target_km": 7.0,
        "week_km": 3.5,
        "week_target_km": 49.0,
    }
    assert board["race"] == {
        "tournament_id": "race",
        "name": "한강 5km",
        "rank": 2,
        "field": 2,
    }
    assert board["crew"] == {
        "name": "새벽",
        "week_km": 3.5,
        "rank": 1,
        "rank_period": "month",
    }


def test_missing_crew_race_and_grade_are_empty_not_invented() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {}
    board = watch_glance.build(db, "u1", now=NOW)
    assert board["tier_code"] == "snail"
    assert board["diamond_balance"] == 0
    assert board["race"] is None
    assert board["crew"] is None
    assert board["goals"]["today_km"] == 0
    assert board["goals"]["today_target_km"] == 3.0
    assert board["goals"]["week_target_km"] == 21.0
    assert board["world_tour"]["landmark_id"] == "eiffel_tower"
    assert board["world_tour"]["remaining_km"] == 1.0


def test_steps_fill_today_when_the_day_has_no_km() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {"gradeCode": "turtle_bronze"}
    db.store["users/u1/daily_metrics/2026-10-28"] = {"steps": 4000}
    board = watch_glance.build(db, "u1", now=NOW)
    assert board["goals"]["today_km"] == 3.0
    assert board["goals"]["today_target_km"] == 5.0


def test_a_joined_race_without_a_finish_has_no_rank() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {}
    db.store["tournaments/open"] = {"title": "모집", "status": "recruiting", "participantCount": 1}
    db.store["tournaments/open/participants/u1"] = {"uid": "u1", "status": "joined"}
    board = watch_glance.build(db, "u1", now=NOW)
    assert board["race"]["tournament_id"] == "open"
    assert board["race"]["rank"] is None


def test_request_accepts_the_watch_device_id_and_does_not_require_it() -> None:
    assert watch_glance.WatchGlanceRequest().device_id is None
    assert watch_glance.WatchGlanceRequest(device_id="watch-abc").device_id == "watch-abc"
