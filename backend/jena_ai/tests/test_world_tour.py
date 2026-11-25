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


def test_the_seed_has_the_thirteen_open_missions() -> None:
    assert [(m["missionId"], m["targetKm"]) for m in wt.MISSION_SEED] == [
        ("france_eiffel", 1.0),
        ("india_taj", 2.0),
        ("japan_fuji", 3.0),
        ("uk_big_ben", 5.0),
        ("usa_liberty", 3.0),
        ("korea_gwanghwamun", 2.0),
        ("taiwan_taroko", 3.0),
        ("spain_alhambra", 3.0),
        ("brazil_iguazu", 5.0),
        ("germany_neuschwanstein", 3.0),
        ("vietnam_halong", 3.0),
        ("thailand_ayutthaya", 2.0),
        ("indonesia_bali", 3.0),
    ]
    assert [m["order"] for m in wt.MISSION_SEED] == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
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
        "uk_big_ben",
        "usa_liberty",
        "korea_gwanghwamun",
        "taiwan_taroko",
        "spain_alhambra",
        "brazil_iguazu",
        "germany_neuschwanstein",
        "vietnam_halong",
        "thailand_ayutthaya",
        "indonesia_bali",
    ]
    by_id = {m.mission_id: m for m in me.missions}
    assert by_id["france_eiffel"].state == "completed"
    assert by_id["japan_fuji"].progress_km == pytest.approx(1.5)
    assert by_id["india_taj"].progress_km == 0
    assert [s.mission_id for s in me.passport] == ["france_eiffel"]
    assert (me.completed_count, me.total_count) == (1, 13)


def test_read_me_for_a_new_user_shows_all_open_and_an_empty_passport() -> None:
    me = wt.read_me(_MemoryDb(), "new")
    assert me.total_count == 13
    assert me.completed_count == 0
    assert me.passport == []
    assert all(m.state == "active" and m.progress_km == 0 for m in me.missions)


def test_another_users_progress_is_not_shown() -> None:
    db = _db_with_runs(a1={"distanceKm": 1.0})
    _attach(db, "france_eiffel", "a1")
    assert wt.read_me(db, "u2").completed_count == 0


def test_seeding_writes_the_catalog_and_read_me_uses_it() -> None:
    db = _MemoryDb()
    assert wt.seed_missions(db) == 13
    assert db.store["worldTourMissions/japan_fuji"]["targetKm"] == 3.0
    db.store["worldTourMissions/usa_liberty"]["active"] = False
    ids = [m.mission_id for m in wt.read_me(db, "u1").missions]
    assert "usa_liberty" not in ids
    assert len(ids) == 12


# --- Pyramids became Big Ben: old progress and the old id keep working -------


def _legacy_db(**runs: dict) -> _MemoryDb:
    db = _db_with_runs(**runs)
    db.store["users/u1/worldTour/egypt_pyramids"] = {
        "missionId": "egypt_pyramids",
        "state": "active",
        "progressKm": 2.0,
        "stampId": None,
        "completedAt": None,
    }
    return db


def test_the_app_and_server_agree_on_the_big_ben_ids() -> None:
    row = {m["missionId"]: m for m in wt.MISSION_SEED}["uk_big_ben"]

    assert row["landmarkId"] == "big_ben"
    assert row["countryCode"] == "GB"
    assert row["targetKm"] == 5.0
    assert row["order"] == 4
    assert "egypt_pyramids" not in {m["missionId"] for m in wt.MISSION_SEED}
    assert "pyramids" not in {m["landmarkId"] for m in wt.MISSION_SEED}


def test_the_new_landmarks_have_unique_ids() -> None:
    assert len({m["missionId"] for m in wt.MISSION_SEED}) == 13
    assert len({m["landmarkId"] for m in wt.MISSION_SEED}) == 13


def test_read_me_shows_old_pyramids_progress_on_big_ben() -> None:
    db = _legacy_db()

    me = wt.read_me(db, "u1")

    by_id = {m.mission_id: m for m in me.missions}
    assert "egypt_pyramids" not in by_id
    assert by_id["uk_big_ben"].progress_km == pytest.approx(2.0)
    assert by_id["uk_big_ben"].landmark_id == "big_ben"
    assert by_id["uk_big_ben"].state == "active"


def test_a_finished_pyramids_stamp_shows_as_big_ben_with_its_saved_stamp_id() -> None:
    db = _legacy_db()
    db.store["users/u1/worldTour/egypt_pyramids"].update(
        {"state": "completed", "progressKm": 5.0, "stampId": "stamp-egypt_pyramids"}
    )

    me = wt.read_me(db, "u1")

    assert [s.mission_id for s in me.passport] == ["uk_big_ben"]
    assert me.passport[0].landmark_id == "big_ben"
    assert me.passport[0].stamp_id == "stamp-egypt_pyramids"
    assert me.completed_count == 1


def test_new_big_ben_progress_wins_over_the_old_document() -> None:
    db = _legacy_db()
    db.store["users/u1/worldTour/uk_big_ben"] = {
        "missionId": "uk_big_ben",
        "state": "active",
        "progressKm": 4.0,
    }

    by_id = {m.mission_id: m for m in wt.read_me(db, "u1").missions}

    assert by_id["uk_big_ben"].progress_km == pytest.approx(4.0)


def test_an_old_catalog_document_is_not_listed() -> None:
    db = _MemoryDb()
    wt.seed_missions(db)
    db.store["worldTourMissions/egypt_pyramids"] = {
        "missionId": "egypt_pyramids",
        "title": "이집트 피라미드",
        "countryCode": "EG",
        "landmarkId": "pyramids",
        "targetKm": 5.0,
        "order": 4,
        "active": True,
    }

    ids = [m.mission_id for m in wt.read_me(db, "u1").missions]

    assert "egypt_pyramids" not in ids
    assert ids.count("uk_big_ben") == 1
    assert len(ids) == 13


def test_attaching_with_the_old_id_continues_the_old_progress() -> None:
    db = _legacy_db(a1={"distanceKm": 1.5})

    result = _attach(db, "egypt_pyramids", "a1")

    assert result.mission_id == "uk_big_ben"
    assert result.progress_km == pytest.approx(3.5)
    assert db.store["users/u1/worldTour/uk_big_ben"]["progressKm"] == pytest.approx(3.5)
    assert db.store["users/u1/worldTourRuns/a1"]["missionId"] == "uk_big_ben"
    # The old document is left alone.
    assert db.store["users/u1/worldTour/egypt_pyramids"]["progressKm"] == 2.0


def test_attaching_with_the_new_id_also_continues_the_old_progress() -> None:
    db = _legacy_db(a1={"distanceKm": 3.0})

    result = _attach(db, "uk_big_ben", "a1")

    assert result.progress_km == pytest.approx(5.0)
    assert result.state == "completed"
    assert result.stamp_id == "stamp-uk_big_ben"
    assert result.newly_completed is True


def test_attaching_the_same_run_again_adds_nothing() -> None:
    db = _legacy_db(a1={"distanceKm": 1.5})
    first = _attach(db, "egypt_pyramids", "a1")
    again = _attach(db, "egypt_pyramids", "a1")
    again_new = _attach(db, "uk_big_ben", "a1")

    assert first.already_attached is False
    assert again.already_attached is True
    assert again_new.already_attached is True
    assert again.progress_km == pytest.approx(3.5)
    assert db.store["users/u1/worldTour/uk_big_ben"]["progressKm"] == pytest.approx(3.5)


def test_a_run_linked_under_the_old_id_is_not_a_conflict_for_big_ben() -> None:
    db = _legacy_db(a1={"distanceKm": 1.0})
    db.store["users/u1/worldTourRuns/a1"] = {
        "missionId": "egypt_pyramids",
        "countedKm": 1.0,
    }

    result = _attach(db, "uk_big_ben", "a1")

    assert result.already_attached is True
    assert result.counted_km == pytest.approx(1.0)
    assert result.mission_id == "uk_big_ben"


def test_a_run_linked_to_another_mission_still_conflicts_with_the_old_id() -> None:
    db = _legacy_db(a1={"distanceKm": 1.0})
    _attach(db, "india_taj", "a1")

    assert _code(lambda: _attach(db, "egypt_pyramids", "a1")) == (409, "run_already_linked")


def test_a_finished_old_mission_refuses_more_runs() -> None:
    db = _legacy_db(a1={"distanceKm": 1.0})
    db.store["users/u1/worldTour/egypt_pyramids"].update(
        {"state": "completed", "progressKm": 5.0, "stampId": "stamp-egypt_pyramids"}
    )

    assert _code(lambda: _attach(db, "egypt_pyramids", "a1")) == (409, "mission_completed")


def test_big_ben_works_for_a_user_with_no_old_progress() -> None:
    db = _db_with_runs(a1={"distanceKm": 5.0})

    result = _attach(db, "uk_big_ben", "a1")

    assert result.state == "completed"
    assert result.stamp_id == "stamp-uk_big_ben"


def test_each_new_landmark_mission_can_be_attached() -> None:
    for mission in wt.MISSION_SEED[5:]:
        db = _db_with_runs(a1={"distanceKm": mission["targetKm"]})

        result = _attach(db, mission["missionId"], "a1")

        assert result.state == "completed", mission["missionId"]
        assert result.stamp_id == f"stamp-{mission['missionId']}"


# --- the one-time migration script ------------------------------------------

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "migrate_pyramids",
    Path(__file__).resolve().parents[1]
    / "scripts"
    / "migrate_world_tour_pyramids_to_big_ben.py",
)
migrate = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(migrate)


def _migration_db() -> _MemoryDb:
    db = _MemoryDb()
    db.store["users/u1/worldTour/egypt_pyramids"] = {
        "missionId": "egypt_pyramids",
        "state": "completed",
        "progressKm": 5.0,
        "stampId": "stamp-egypt_pyramids",
        "completedAt": "2026-11-01T00:00:00",
    }
    db.store["users/u2/worldTour/egypt_pyramids"] = {"state": "active", "progressKm": 1.0}
    db.store["users/u2/worldTour/uk_big_ben"] = {"state": "active", "progressKm": 2.5}
    db.store["users/u3/worldTour/japan_fuji"] = {"state": "active", "progressKm": 1.0}
    db.store["worldTourMissions/egypt_pyramids"] = {"active": True, "landmarkId": "pyramids"}
    return db


def test_the_migration_dry_run_writes_nothing() -> None:
    db = _migration_db()
    before = {k: dict(v) for k, v in db.store.items()}

    planned = migrate.plan(db)

    assert [uid for uid, _ in planned["copy"]] == ["u1"]
    assert planned["skipped_existing"] == ["u2"]
    assert planned["deactivate_old_catalog"] is True
    assert db.store == before


def test_the_migration_apply_copies_seeds_and_deactivates() -> None:
    db = _migration_db()

    migrate.apply(db, migrate.plan(db))

    copied = db.store["users/u1/worldTour/uk_big_ben"]
    assert copied["progressKm"] == 5.0
    assert copied["state"] == "completed"
    assert copied["stampId"] == "stamp-egypt_pyramids"
    assert copied["missionId"] == "uk_big_ben"
    assert db.store["users/u1/worldTour/egypt_pyramids"]["progressKm"] == 5.0
    assert db.store["users/u2/worldTour/uk_big_ben"]["progressKm"] == 2.5
    assert db.store["worldTourMissions/egypt_pyramids"]["active"] is False
    assert db.store["worldTourMissions/uk_big_ben"]["landmarkId"] == "big_ben"
    assert "users/u3/worldTour/uk_big_ben" not in db.store


def test_running_the_migration_twice_changes_nothing_more() -> None:
    db = _migration_db()
    migrate.apply(db, migrate.plan(db))
    after_first = {k: dict(v) for k, v in db.store.items()}

    again = migrate.plan(db)
    migrate.apply(db, again)

    assert again["copy"] == []
    assert db.store == after_first
