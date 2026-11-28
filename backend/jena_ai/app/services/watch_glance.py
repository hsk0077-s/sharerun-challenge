"""Read-only board for the standalone watch.

One call fills the world-tour, challenge, crew and diamond faces. It never
writes, spends, or ranks anyone into a new table. The account is the bearer
token's uid. A ``device_id`` in the body is the same id the watch sends on a
run upload; it does not choose whose data is read (the token's ``wdev`` claim
is what marks the watch as still paired).
"""

from __future__ import annotations

from datetime import datetime, timedelta, timezone

from pydantic import BaseModel, Field

from app.services import world_tour
from app.services.crew_ranking import load_rows, month_key, rank_crews
from app.services.grade_assignment import tier_animal
from app.services.identities import _user_profile
from app.services.social_items import member_crew_id

_KST = timezone(timedelta(hours=9))
_STRIDE_KM = 0.75 / 1000.0

# Same daily walking targets the phone uses for each animal (snail = not rated).
_DAILY_TARGET_KM = {
    "snail": 3.0,
    "turtle": 5.0,
    "beagle": 7.0,
    "wolf": 7.0,
    "zebra": 10.0,
    "cheetah": 10.0,
}

_OPEN_RACE = {"recruiting", "active"}


class WatchGlanceRequest(BaseModel):
    device_id: str | None = Field(default=None, max_length=128)


def _round_km(value: float) -> float:
    if value != value or value in (float("inf"), float("-inf")) or value < 0:
        return 0.0
    return round(value, 3)


def _km_of(data: dict) -> float:
    raw = data.get("km")
    if isinstance(raw, (int, float)) and not isinstance(raw, bool) and raw >= 0:
        return float(raw)
    steps = data.get("steps")
    if isinstance(steps, int) and not isinstance(steps, bool) and steps > 0:
        return steps * _STRIDE_KM
    return 0.0


def _kst(now: datetime | None) -> datetime:
    return (now or datetime.now(timezone.utc)).astimezone(_KST)


def _week_dates(now: datetime | None) -> list:
    current = _kst(now).date()
    monday = current - timedelta(days=current.weekday())
    return [monday + timedelta(days=i) for i in range(7)]


def _utc(value: object) -> datetime | None:
    if not isinstance(value, datetime):
        return None
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc)


def _diamond(profile: dict) -> int:
    wallet = profile.get("wallet")
    raw = wallet.get("diamondBalance") if isinstance(wallet, dict) else 0
    if isinstance(raw, bool) or not isinstance(raw, (int, float)):
        return 0
    return max(0, int(raw))


def _goals(db, uid: str, animal: str, now: datetime | None) -> dict:
    target = _DAILY_TARGET_KM.get(animal, _DAILY_TARGET_KM["snail"])
    days = _week_dates(now)
    today_key = _kst(now).date().isoformat()
    metrics = db.collection("users").document(uid).collection("daily_metrics")
    week = 0.0
    today = 0.0
    for day in days:
        key = day.isoformat()
        snap = metrics.document(key).get()
        km = _km_of(snap.to_dict() or {}) if snap.exists else 0.0
        week += km
        if key == today_key:
            today = km
    return {
        "today_km": _round_km(today),
        "today_target_km": target,
        "week_km": _round_km(week),
        "week_target_km": round(target * 7, 3),
    }


def _world(db, uid: str) -> dict | None:
    board = world_tour.read_me(db, uid)
    if not board.missions:
        return None
    current = next((row for row in board.missions if row.state != "completed"), None)
    all_done = current is None
    shown = board.missions[-1] if current is None else current
    remaining = 0.0 if all_done else max(0.0, shown.target_km - shown.progress_km)
    return {
        "landmark_id": shown.landmark_id,
        "country_code": shown.country_code,
        "title": shown.title,
        "progress_km": _round_km(shown.progress_km),
        "target_km": _round_km(shown.target_km),
        "remaining_km": _round_km(remaining),
        "completed_count": board.completed_count,
        "total_count": board.total_count,
        "all_done": all_done,
    }


def _tournament_id(snap) -> str | None:
    ref = getattr(snap, "reference", None)
    path = getattr(ref, "path", "") if ref is not None else ""
    parts = [part for part in str(path).split("/") if part]
    if "tournaments" not in parts:
        return None
    index = parts.index("tournaments")
    if index + 1 >= len(parts) or index + 2 >= len(parts):
        return None
    if parts[index + 2] != "participants":
        return None
    return parts[index + 1]


def _finish_rank(db, tournament_id: str, uid: str) -> int | None:
    rows = []
    parent = db.collection("tournaments").document(tournament_id).collection("participants")
    for snap in parent.get():
        data = snap.to_dict() or {}
        if data.get("verifiedFinish") is not True:
            continue
        duration = data.get("durationSeconds")
        if isinstance(duration, bool) or not isinstance(duration, (int, float)) or duration <= 0:
            continue
        rows.append((float(duration), snap.id))
    rows.sort()
    for index, (_, participant_id) in enumerate(rows, start=1):
        if participant_id == uid:
            return index
    return None


def _race(db, uid: str) -> dict | None:
    try:
        snaps = db.collection_group("participants").where("uid", "==", uid).get()
    except Exception:
        return None
    chosen = None
    for snap in snaps:
        data = snap.to_dict() or {}
        status = data.get("status")
        if status not in (None, "joined"):
            continue
        tournament_id = _tournament_id(snap)
        if not tournament_id:
            continue
        tournament_snap = db.collection("tournaments").document(tournament_id).get()
        if not tournament_snap.exists:
            continue
        tournament = tournament_snap.to_dict() or {}
        race_status = tournament.get("status") or "recruiting"
        if race_status not in _OPEN_RACE:
            continue
        rank = None
        if data.get("verifiedFinish") is True:
            rank = _finish_rank(db, tournament_id, uid)
        title = tournament.get("title") or tournament.get("name") or ""
        field = tournament.get("participantCount")
        if isinstance(field, bool) or not isinstance(field, (int, float)) or field < 0:
            field = 0
        row = {
            "tournament_id": tournament_id,
            "name": str(title),
            "rank": rank,
            "field": int(field),
            "_active": race_status == "active",
            "_joined": _utc(data.get("joinedAt")) or datetime.min.replace(tzinfo=timezone.utc),
        }
        if chosen is None:
            chosen = row
            continue
        if row["_active"] != chosen["_active"]:
            if row["_active"]:
                chosen = row
            continue
        if row["_joined"] > chosen["_joined"]:
            chosen = row
    if chosen is None:
        return None
    return {
        "tournament_id": chosen["tournament_id"],
        "name": chosen["name"],
        "rank": chosen["rank"],
        "field": chosen["field"],
    }


def _crew_week_km(db, crew_id: str, now: datetime | None) -> float:
    days = _week_dates(now)
    start = datetime(days[0].year, days[0].month, days[0].day, tzinfo=_KST).astimezone(timezone.utc)
    end = start + timedelta(days=7)
    total = 0.0
    runs = db.collection("crews").document(crew_id).collection("runs")
    for snap in runs.get():
        data = snap.to_dict() or {}
        when = _utc(data.get("createdAt"))
        if when is None or when < start or when >= end:
            continue
        distance = data.get("distanceKm")
        if isinstance(distance, bool) or not isinstance(distance, (int, float)) or distance <= 0:
            continue
        total += float(distance)
    return _round_km(total)


def _crew_month_rank(db, crew_id: str, now: datetime | None) -> int | None:
    try:
        ranked = rank_crews(load_rows(db, month_key(now)))
    except Exception:
        return None
    mine = next((row for row in ranked if row.get("crew_id") == crew_id), None)
    if mine is None:
        return None
    rank = mine.get("rank")
    if isinstance(rank, bool) or not isinstance(rank, int) or rank < 1:
        return None
    return rank


def _crew(db, profile: dict, now: datetime | None) -> dict | None:
    crew_id = member_crew_id(profile)
    if not crew_id:
        return None
    snap = db.collection("crews").document(crew_id).get()
    if not snap.exists:
        return None
    data = snap.to_dict() or {}
    return {
        "name": str(data.get("name") or ""),
        "week_km": _crew_week_km(db, crew_id, now),
        "rank": _crew_month_rank(db, crew_id, now),
        # The live crew board is monthly. Week distance is this crew's runs only.
        "rank_period": "month",
    }


def build(db, uid: str, now: datetime | None = None) -> dict:
    """The four watch faces. Reads only."""
    profile = _user_profile(db, uid) or {}
    animal = tier_animal(profile.get("gradeCode"), profile.get("gradeRank")) or "snail"
    return {
        "tier_code": animal,
        "diamond_balance": _diamond(profile),
        "world_tour": _world(db, uid),
        "goals": _goals(db, uid, animal, now),
        "race": _race(db, uid),
        "crew": _crew(db, profile, now),
    }
