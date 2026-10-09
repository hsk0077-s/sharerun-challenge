"""Runner grade, set once by the server from three verified 1km runs.

A verified run of at least 1km on a new KST day counts. The third counted run
sets the grade from the median pace of the three. The grade lives in
``gradeCode`` / ``gradeRank`` on the user doc, apart from the room ``tier``
number, so room locks do not change. Nothing here demotes a grade.
"""

from datetime import datetime, timezone

from google.cloud.firestore_v1 import SERVER_TIMESTAMP

from app.services.referral_trial_config import kst_day_key

GRADE_RUNS_REQUIRED = 3
GRADE_MIN_DISTANCE_KM = 1.0
GRADE_ASSIGNMENTS = "gradeAssignments"

_MEDALS = ("master", "diamond", "gold", "silver", "bronze")

# (slowest pace is the first group). Each row: animal, rank base, lowest pace
# of the group in sec/km, and the slowest pace that still earns master, diamond,
# gold and silver. Anything slower in the group is bronze.
_GROUPS = (
    ("turtle", 0, 450, (479, 509, 539, 569)),
    ("rabbit", 5, 360, (377, 395, 413, 431)),
    ("wolf", 10, 300, (311, 323, 335, 347)),
    ("gazelle", 15, 240, (251, 263, 275, 287)),
    ("cheetah", 20, 0, (199, 209, 219, 229)),
)


def grade_for_pace(pace_sec_per_km: int | float) -> tuple[str, int]:
    """``(gradeCode, gradeRank)`` for a pace. Same table the app used."""
    pace = max(0, int(pace_sec_per_km))
    for animal, base, lowest, bounds in _GROUPS:
        if pace < lowest:
            continue
        for index, bound in enumerate(bounds):
            if pace <= bound:
                return f"{animal}_{_MEDALS[index]}", base + 5 - index
        return f"{animal}_bronze", base + 1
    return "cheetah_master", 25


def median_pace(paces: list[int]) -> int:
    ordered = sorted(int(pace) for pace in paces)
    return ordered[len(ordered) // 2]


def run_pace_sec_per_km(distance_km: float, duration_seconds: float) -> int | None:
    if distance_km <= 0 or duration_seconds <= 0:
        return None
    return int(round(duration_seconds / distance_km))


def counts_for_grade(distance_km: float) -> bool:
    return distance_km + 1e-9 >= GRADE_MIN_DISTANCE_KM


def advance_grade_runs(
    runs: object,
    *,
    activity_id: str,
    day_key: str,
    pace_sec: int,
) -> tuple[list[dict], bool]:
    """Add one run. Returns ``(runs, counted)``. One run per day, no repeats."""
    current = [
        dict(row)
        for row in (runs if isinstance(runs, list) else [])
        if isinstance(row, dict)
    ]
    if len(current) >= GRADE_RUNS_REQUIRED:
        return current, False
    if any(
        row.get("activityId") == activity_id or row.get("day") == day_key
        for row in current
    ):
        return current, False
    current.append({"day": day_key, "activityId": activity_id, "paceSec": int(pace_sec)})
    return current, True


def assignment_from_runs(runs: list[dict]) -> dict | None:
    """The grade for a full set of runs, or ``None`` while runs are missing."""
    if len(runs) < GRADE_RUNS_REQUIRED:
        return None
    basis = runs[:GRADE_RUNS_REQUIRED]
    pace = median_pace([int(row["paceSec"]) for row in basis])
    code, rank = grade_for_pace(pace)
    return {
        "gradeCode": code,
        "gradeRank": rank,
        "medianPaceSec": pace,
        "runs": basis,
    }


def assignment_document(uid: str, assignment: dict, *, source: str, server_time) -> dict:
    """Append-only record. The doc id is the uid, so a grade is written once."""
    return {
        "uid": uid,
        "type": "initial_grade",
        "source": source,
        "gradeCode": assignment["gradeCode"],
        "gradeRank": assignment["gradeRank"],
        "medianPaceSec": assignment["medianPaceSec"],
        "runs": assignment["runs"],
        "createdAt": server_time,
    }



def _completed_at(value: object) -> datetime | None:
    if isinstance(value, datetime):
        return value if value.tzinfo else value.replace(tzinfo=timezone.utc)
    if isinstance(value, str):
        try:
            parsed = datetime.fromisoformat(value)
        except ValueError:
            return None
        return parsed if parsed.tzinfo else parsed.replace(tzinfo=timezone.utc)
    return None


def runs_from_activities(activities: list[dict]) -> list[dict]:
    """First three verified 1km runs on different KST days, oldest first.

    The oldest runs are used so a backfill cannot place anyone above the grade
    the live rule would have given them. Nothing demotes a grade later.
    """
    candidates = []
    for index, activity in enumerate(activities):
        if activity.get("jenaVerified") is not True:
            continue
        distance = activity.get("distanceKm")
        duration = activity.get("durationSeconds")
        if isinstance(distance, bool) or isinstance(duration, bool):
            continue
        if not isinstance(distance, (int, float)) or not isinstance(duration, (int, float)):
            continue
        if not counts_for_grade(float(distance)):
            continue
        pace = run_pace_sec_per_km(float(distance), float(duration))
        finished = _completed_at(activity.get("completedAt"))
        if pace is None or finished is None:
            continue
        candidates.append((finished, index, str(activity.get("activityId") or index), pace))
    candidates.sort(key=lambda row: (row[0], row[1]))
    runs: list[dict] = []
    for finished, _, activity_id, pace in candidates:
        runs, _ = advance_grade_runs(
            runs, activity_id=activity_id, day_key=kst_day_key(finished), pace_sec=pace
        )
        if len(runs) >= GRADE_RUNS_REQUIRED:
            break
    return runs


def backfill_grades(db, *, dry_run: bool) -> dict:
    """Give a grade to users who already have three qualifying runs.

    ``dry_run`` reads and plans only. A user who has a grade, or an assignment
    record, is skipped, so running it twice changes nothing.
    """
    scanned = 0
    skipped = 0
    planned: list[dict] = []
    for snapshot in db.collection("users").get():
        scanned += 1
        uid = snapshot.id
        user = snapshot.to_dict() or {}
        rank = user.get("gradeRank")
        if isinstance(rank, int) and not isinstance(rank, bool) and rank > 0:
            skipped += 1
            continue
        activities = []
        for row in (
            db.collection("activities")
            .where("userId", "==", uid)
            .where("jenaVerified", "==", True)
            .get()
        ):
            data = row.to_dict() or {}
            data["activityId"] = row.id
            activities.append(data)
        assigned = assignment_from_runs(runs_from_activities(activities))
        if assigned is None:
            skipped += 1
            continue
        planned.append({"uid": uid, **assigned})
    written = 0
    if not dry_run:
        for item in planned:
            uid = item["uid"]
            record_ref = db.collection(GRADE_ASSIGNMENTS).document(uid)
            if record_ref.get().exists:
                continue
            record_ref.set(
                assignment_document(uid, item, source="backfill", server_time=SERVER_TIMESTAMP)
            )
            db.collection("users").document(uid).set(
                {
                    "gradeCode": item["gradeCode"],
                    "gradeRank": item["gradeRank"],
                    "gradeAssignedAt": SERVER_TIMESTAMP,
                    "economy": {"gradeRuns": item["runs"]},
                },
                merge=True,
            )
            written += 1
    return {
        "dry_run": dry_run,
        "scanned": scanned,
        "skipped": skipped,
        "planned": len(planned),
        "written": written,
        "grades": [
            {
                "uid": item["uid"],
                "gradeCode": item["gradeCode"],
                "gradeRank": item["gradeRank"],
                "medianPaceSec": item["medianPaceSec"],
            }
            for item in planned
        ],
    }
