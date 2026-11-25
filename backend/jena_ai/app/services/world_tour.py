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

# The 13 missions. All are open from the start. Title is Korean for admin and
# logs; the app shows its own translated name for each landmark. The landmarkId
# must match the app's landmark id (lib/features/world_tour/world_tour_landmarks.dart).
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
        "missionId": "uk_big_ben",
        "title": "영국 런던 빅벤",
        "countryCode": "GB",
        "landmarkId": "big_ben",
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
    {
        "missionId": "korea_gwanghwamun",
        "title": "한국 서울 광화문",
        "countryCode": "KR",
        "landmarkId": "gwanghwamun",
        "targetKm": 2.0,
        "order": 6,
        "active": True,
    },
    {
        "missionId": "taiwan_taroko",
        "title": "대만 타이루거 협곡",
        "countryCode": "TW",
        "landmarkId": "taroko_gorge",
        "targetKm": 3.0,
        "order": 7,
        "active": True,
    },
    {
        "missionId": "spain_alhambra",
        "title": "스페인 알람브라 궁전",
        "countryCode": "ES",
        "landmarkId": "alhambra",
        "targetKm": 3.0,
        "order": 8,
        "active": True,
    },
    {
        "missionId": "brazil_iguazu",
        "title": "브라질 이구아수 폭포",
        "countryCode": "BR",
        "landmarkId": "iguazu_falls",
        "targetKm": 5.0,
        "order": 9,
        "active": True,
    },
    {
        "missionId": "germany_neuschwanstein",
        "title": "독일 노이슈반슈타인 성",
        "countryCode": "DE",
        "landmarkId": "neuschwanstein",
        "targetKm": 3.0,
        "order": 10,
        "active": True,
    },
    {
        "missionId": "vietnam_halong",
        "title": "베트남 하롱베이",
        "countryCode": "VN",
        "landmarkId": "ha_long_bay",
        "targetKm": 3.0,
        "order": 11,
        "active": True,
    },
    {
        "missionId": "thailand_ayutthaya",
        "title": "태국 아유타야 유적",
        "countryCode": "TH",
        "landmarkId": "ayutthaya",
        "targetKm": 2.0,
        "order": 12,
        "active": True,
    },
    {
        "missionId": "indonesia_bali",
        "title": "인도네시아 발리 계단식 논",
        "countryCode": "ID",
        "landmarkId": "bali_rice_terraces",
        "targetKm": 3.0,
        "order": 13,
        "active": True,
    },
)
_SEED_BY_ID = {row["missionId"]: row for row in MISSION_SEED}

# Missions that were renamed. Progress saved under the old id keeps counting
# under the new one. The Pyramids mission became Big Ben (same distance, same
# place in the list); an old app may still send the old id.
LEGACY_MISSION_ALIASES: dict[str, str] = {"egypt_pyramids": "uk_big_ben"}


def canonical_mission_id(mission_id: str) -> str:
    return LEGACY_MISSION_ALIASES.get(mission_id, mission_id)


def _legacy_ids_for(mission_id: str) -> list[str]:
    return [old for old, new in LEGACY_MISSION_ALIASES.items() if new == mission_id]


def stamp_id_for(mission_id: str) -> str:
    return f"stamp-{mission_id}"


def seed_missions(db) -> int:
    """Write the catalog docs. Safe to run again; it only sets the seed missions."""
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
    mission_id = canonical_mission_id(mission_id)
    activity_ref = db.collection("activities").document(activity_id)
    user_ref = db.collection(USERS).document(uid)
    guard_ref = user_ref.collection(RUNS).document(activity_id)
    progress_ref = user_ref.collection(PROGRESS).document(mission_id)
    mission_ref = db.collection(MISSIONS).document(mission_id)

    activity_snap = activity_ref.get(transaction=transaction)
    guard_snap = guard_ref.get(transaction=transaction)
    progress_snap = progress_ref.get(transaction=transaction)
    mission_snap = mission_ref.get(transaction=transaction)
    legacy_snaps = [
        user_ref.collection(PROGRESS).document(old).get(transaction=transaction)
        for old in _legacy_ids_for(mission_id)
    ]

    mission = _catalog_row(
        (mission_snap.to_dict() or {}) if mission_snap.exists else None, mission_id
    )
    if mission is None or mission.get("active") is False:
        raise _http(status.HTTP_404_NOT_FOUND, "mission_not_found")
    target_km = _positive_km(mission.get("targetKm"))
    if target_km <= 0:
        raise _http(status.HTTP_404_NOT_FOUND, "mission_not_found")

    progress = (progress_snap.to_dict() or {}) if progress_snap.exists else {}
    if not progress_snap.exists:
        # Take over what was saved under the old mission id. The old document
        # is left as it is.
        for legacy in legacy_snaps:
            if legacy.exists:
                progress = legacy.to_dict() or {}
                break

    # A run that is already linked answers the same every time.
    if guard_snap.exists:
        guard = guard_snap.to_dict() or {}
        if canonical_mission_id(str(guard.get("missionId") or "")) == mission_id:
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
        if data.get("active") is False or snap.id in LEGACY_MISSION_ALIASES:
            continue
        catalog[snap.id] = data
    if not catalog:
        catalog = {key: dict(row) for key, row in _SEED_BY_ID.items()}

    progress: dict[str, dict] = {}
    for snap in db.collection(USERS).document(uid).collection(PROGRESS).get():
        progress[snap.id] = snap.to_dict() or {}
    for old, new in LEGACY_MISSION_ALIASES.items():
        if new not in progress and old in progress:
            progress[new] = progress[old]

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
