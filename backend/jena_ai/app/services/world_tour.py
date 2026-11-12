"""World Tour: verified run distance becomes progress on a virtual trip.

This sits on top of the run pipeline and only READS a finished activity:
``activities/{id}`` with ``userId == uid``, ``validationFinalized`` and
``jenaVerified`` all true. It never changes the run, the validation, any
reward or any wallet. The reward is a stamp in the passport, nothing else.

Collections (the client may only read its own; every write is server-side):
    worldTourMissions/{missionId}          catalog (code constants if not seeded)
    users/{uid}/worldTour/{missionId}      state, progressKm, completedAt, stampId
    users/{uid}/worldTourRuns/{activityId} guard doc: one run links to one mission

``attach`` is one transaction. The guard doc is read first, so a repeat call
for the same run returns the stored answer and adds nothing. This follows the
guard-doc pattern of ``crew_ranking`` (read the guard, then write the guard in
the same transaction); that file is not touched.
"""

from __future__ import annotations

from datetime import datetime
from typing import Any

from fastapi import HTTPException, status
from google.cloud import firestore
from google.cloud.firestore_v1 import SERVER_TIMESTAMP

from app.models.world_tour import (
    WorldTourAttachResult,
    WorldTourMe,
    WorldTourMissionView,
    WorldTourStampView,
)

MISSIONS = "worldTourMissions"
USERS = "users"
PROGRESS = "worldTour"
RUNS = "worldTourRuns"

# The first five missions. All are open from the start. Title is Korean for
# admin and logs; the app shows its own translated name for each landmark.
MISSION_SEED: tuple[dict[str, Any], ...] = (
    {
        "missionId": "france_eiffel",
        "title": "프랑스 에펠탑",
        "countryCode": "FR",
        "landmarkId": "eiffel_tower",
        "targetKm": 1.0,
        "order": 1,
        "active": True,
    },
    {
        "missionId": "india_taj",
        "title": "인도 타지마할",
        "countryCode": "IN",
        "landmarkId": "taj_mahal",
        "targetKm": 2.0,
        "order": 2,
        "active": True,
    },
    {
        "missionId": "japan_fuji",
        "title": "일본 후지산",
        "countryCode": "JP",
        "landmarkId": "mount_fuji",
        "targetKm": 3.0,
        "order": 3,
        "active": True,
    },
    {
        "missionId": "egypt_pyramids",
        "title": "이집트 피라미드",
        "countryCode": "EG",
        "landmarkId": "pyramids",
        "targetKm": 5.0,
        "order": 4,
        "active": True,
    },
    {
        "missionId": "usa_liberty",
        "title": "미국 자유의 여신상",
        "countryCode": "US",
        "landmarkId": "statue_of_liberty",
        "targetKm": 3.0,
        "order": 5,
        "active": True,
    },
)
_SEED_BY_ID = {row["missionId"]: row for row in MISSION_SEED}


def stamp_id_for(mission_id: str) -> str:
    return f"stamp-{mission_id}"


def seed_missions(db) -> int:
    """Write the catalog docs. Safe to run again; it only sets these five."""
    for row in MISSION_SEED:
        db.collection(MISSIONS).document(row["missionId"]).set(dict(row), merge=True)
    return len(MISSION_SEED)


def _http(code: int, detail: str) -> HTTPException:
    return HTTPException(status_code=code, detail=detail)


def _catalog_row(snapshot_data: dict | None, mission_id: str) -> dict | None:
    """The stored doc when it exists, else the code constant."""
    if snapshot_data is not None:
        return snapshot_data
    return _SEED_BY_ID.get(mission_id)


def _positive_km(value: Any) -> float:
    try:
        km = float(value)
    except (TypeError, ValueError):
        return 0.0
    if km != km or km in (float("inf"), float("-inf")) or km <= 0:
        return 0.0
    return km


def _iso(value: Any) -> str | None:
    if isinstance(value, datetime):
        return value.isoformat()
    if isinstance(value, str) and value:
        return value
    return None


def _result(
    mission_id: str,
    activity_id: str,
    counted_km: float,
    progress: dict,
    target_km: float,
    *,
    already: bool,
    newly: bool,
) -> WorldTourAttachResult:
    stamp = progress.get("stampId")
    return WorldTourAttachResult(
        mission_id=mission_id,
        activity_id=activity_id,
        counted_km=counted_km,
        progress_km=float(progress.get("progressKm") or 0.0),
        target_km=target_km,
        state=str(progress.get("state") or "active"),
        stamp_id=stamp if isinstance(stamp, str) and stamp else None,
        already_attached=already,
        newly_completed=newly,
    )


def attach_in_txn(
    transaction,
    db,
    uid: str,
    mission_id: str,
    activity_id: str,
) -> WorldTourAttachResult:
    """Link one verified run to one mission. Every read happens before a write."""
    activity_ref = db.collection("activities").document(activity_id)
    user_ref = db.collection(USERS).document(uid)
    guard_ref = user_ref.collection(RUNS).document(activity_id)
    progress_ref = user_ref.collection(PROGRESS).document(mission_id)
    mission_ref = db.collection(MISSIONS).document(mission_id)

    activity_snap = activity_ref.get(transaction=transaction)
    guard_snap = guard_ref.get(transaction=transaction)
    progress_snap = progress_ref.get(transaction=transaction)
    mission_snap = mission_ref.get(transaction=transaction)

    mission = _catalog_row(
        (mission_snap.to_dict() or {}) if mission_snap.exists else None, mission_id
    )
    if mission is None or mission.get("active") is False:
        raise _http(status.HTTP_404_NOT_FOUND, "mission_not_found")
    target_km = _positive_km(mission.get("targetKm"))
    if target_km <= 0:
        raise _http(status.HTTP_404_NOT_FOUND, "mission_not_found")

    progress = (progress_snap.to_dict() or {}) if progress_snap.exists else {}

    # A run that is already linked answers the same every time.
    if guard_snap.exists:
        guard = guard_snap.to_dict() or {}
        if guard.get("missionId") == mission_id:
            return _result(
                mission_id,
                activity_id,
                float(guard.get("countedKm") or 0.0),
                progress,
                target_km,
                already=True,
                newly=False,
            )
        raise _http(status.HTTP_409_CONFLICT, "run_already_linked")

    if not activity_snap.exists:
        raise _http(status.HTTP_404_NOT_FOUND, "activity_not_found")
    activity = activity_snap.to_dict() or {}
    if activity.get("userId") != uid:
        raise _http(status.HTTP_403_FORBIDDEN, "activity_not_yours")
    if activity.get("validationFinalized") is not True:
        raise _http(status.HTTP_409_CONFLICT, "run_not_finalized")
    if activity.get("jenaVerified") is not True:
        raise _http(422, "run_not_verified")
    counted_km = _positive_km(activity.get("distanceKm"))
    if counted_km <= 0:
        raise _http(422, "run_not_verified")

    if progress.get("state") == "completed":
        raise _http(status.HTTP_409_CONFLICT, "mission_completed")

    progress_km = round(float(progress.get("progressKm") or 0.0) + counted_km, 4)
    finished = progress_km + 1e-9 >= target_km
    stamp = stamp_id_for(mission_id) if finished else None

    transaction.set(
        progress_ref,
        {
            "missionId": mission_id,
            "state": "completed" if finished else "active",
            "progressKm": progress_km,
            "stampId": stamp,
            "completedAt": SERVER_TIMESTAMP if finished else None,
            "updatedAt": SERVER_TIMESTAMP,
        },
        merge=True,
    )
    transaction.set(
        guard_ref,
        {
            "missionId": mission_id,
            "countedKm": counted_km,
            "linkedAt": SERVER_TIMESTAMP,
        },
    )
    return _result(
        mission_id,
        activity_id,
        counted_km,
        {"progressKm": progress_km, "state": "completed" if finished else "active", "stampId": stamp},
        target_km,
        already=False,
        newly=finished,
    )


@firestore.transactional
def _attach_tx(transaction, db, uid: str, mission_id: str, activity_id: str):
    # Module-level so the first argument is the Transaction.
    return attach_in_txn(transaction, db, uid, mission_id, activity_id)


def attach(db, uid: str, mission_id: str, activity_id: str) -> WorldTourAttachResult:
    return _attach_tx(db.transaction(), db, uid, mission_id, activity_id)


def read_me(db, uid: str) -> WorldTourMe:
    """The catalog with this user's progress, and the passport."""
    catalog: dict[str, dict] = {}
    for snap in db.collection(MISSIONS).get():
        data = snap.to_dict() or {}
        if data.get("active") is False:
            continue
        catalog[snap.id] = data
    if not catalog:
        catalog = {key: dict(row) for key, row in _SEED_BY_ID.items()}

    progress: dict[str, dict] = {}
    for snap in db.collection(USERS).document(uid).collection(PROGRESS).get():
        progress[snap.id] = snap.to_dict() or {}

    missions: list[WorldTourMissionView] = []
    for mission_id, row in catalog.items():
        target = _positive_km(row.get("targetKm"))
        if target <= 0:
            continue
        mine = progress.get(mission_id, {})
        completed = mine.get("state") == "completed"
        missions.append(
            WorldTourMissionView(
                mission_id=mission_id,
                title=str(row.get("title") or mission_id),
                country_code=str(row.get("countryCode") or ""),
                landmark_id=str(row.get("landmarkId") or ""),
                target_km=target,
                order=int(row.get("order") or 0),
                progress_km=float(mine.get("progressKm") or 0.0),
                state="completed" if completed else "active",
                stamp_id=mine.get("stampId") if completed else None,
                completed_at=_iso(mine.get("completedAt")) if completed else None,
            )
        )
    missions.sort(key=lambda view: (view.order, view.mission_id))
    passport = [
        WorldTourStampView(
            mission_id=view.mission_id,
            stamp_id=view.stamp_id or stamp_id_for(view.mission_id),
            country_code=view.country_code,
            landmark_id=view.landmark_id,
            completed_at=view.completed_at,
        )
        for view in missions
        if view.state == "completed"
    ]
    return WorldTourMe(
        missions=missions,
        passport=passport,
        completed_count=len(passport),
        total_count=len(missions),
    )
