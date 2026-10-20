"""Monthly crew ranking: average verified distance per crew member.

* Every verified run of a crew member adds its distance to ``crews/{id}`` (all-time) and to
  ``crewMonthly/{YYYY-MM}/crews/{id}`` (that KST month). A guard doc ``crews/{id}/runs/{activity}``
  makes one run count once, however often it is submitted. None of this depends on the company
  donation cap: a crew keeps climbing after the cap is full.
* Rank value = month distance / member count. A crew under ``MIN_MEMBERS`` members is not ranked,
  so a lone runner cannot top the list. Ties: more month distance first, then who reached it first.
* The month is finalized once it is over (on the first ranking read after it, or by ops). Each ranked
  crew keeps its best rank ever on the crew doc (``bestMonthlyRank``) and the ranking borders it
  earned (``unlockedBorders``). Neither goes away.
"""

from __future__ import annotations

import os
from datetime import datetime, timedelta, timezone

from google.cloud.firestore_v1 import SERVER_TIMESTAMP, Increment

from app.services.crew_emblem_perks import BORDER_THRESHOLDS

MONTHLY = "crewMonthly"
DEFAULT_MIN_MEMBERS = 5
TOP_LIMIT = 10
_KST = timezone(timedelta(hours=9))


def min_members() -> int:
    raw = os.environ.get("CREW_RANK_MIN_MEMBERS", "").strip()
    try:
        return max(1, int(raw)) if raw else DEFAULT_MIN_MEMBERS
    except ValueError:
        return DEFAULT_MIN_MEMBERS


def month_key(now: datetime | None = None) -> str:
    return (now or datetime.now(_KST)).astimezone(_KST).strftime("%Y-%m")


def previous_month_key(now: datetime | None = None) -> str:
    first = (now or datetime.now(_KST)).astimezone(_KST).replace(day=1)
    return (first - timedelta(days=1)).strftime("%Y-%m")


def _num(value: object) -> float:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        return 0.0
    return float(value)


def _when(value: object) -> float:
    """Sort key for 'who got there first'. Missing times sort last."""
    if isinstance(value, datetime):
        if value.tzinfo is None:
            value = value.replace(tzinfo=timezone.utc)
        return value.timestamp()
    return float("inf")


# ---- one run ---------------------------------------------------------------------------
def run_guard_ref(db, crew_id: str, activity_id: str):
    return db.collection("crews").document(crew_id).collection("runs").document(activity_id)


def read_run_guard(transaction, db, crew_id: str, activity_id: str) -> bool:
    """True when this run was already counted. Read it before any write of the transaction."""
    return run_guard_ref(db, crew_id, activity_id).get(transaction=transaction).exists


def record_run(
    transaction,
    db,
    *,
    crew_id: str,
    activity_id: str,
    uid: str,
    distance_km: float,
    now: datetime | None = None,
) -> None:
    """Count one verified run for the crew: all-time, this month, and the guard doc."""
    month = month_key(now)
    km = float(distance_km)
    transaction.update(
        db.collection("crews").document(crew_id),
        {"totalDistanceKm": Increment(km)},
    )
    transaction.set(
        db.collection(MONTHLY).document(month).collection("crews").document(crew_id),
        {"distanceKm": Increment(km), "runs": Increment(1), "updatedAt": SERVER_TIMESTAMP},
        merge=True,
    )
    transaction.set(
        run_guard_ref(db, crew_id, activity_id),
        {"uid": uid, "month": month, "distanceKm": km, "createdAt": SERVER_TIMESTAMP},
    )


# ---- ranking ---------------------------------------------------------------------------
def rank_crews(rows: list[dict], minimum: int | None = None) -> list[dict]:
    """Ranked crews, best first. ``rows``: crew_id, distance_km, member_count, updated_at."""
    floor = min_members() if minimum is None else minimum
    eligible = [
        {
            **row,
            "average_km": row["distance_km"] / row["member_count"],
        }
        for row in rows
        if row["member_count"] >= floor and row["distance_km"] > 0
    ]
    eligible.sort(
        key=lambda r: (-r["average_km"], -r["distance_km"], _when(r.get("updated_at")), r["crew_id"])
    )
    for position, row in enumerate(eligible, start=1):
        row["rank"] = position
    return eligible


def load_rows(db, month: str) -> list[dict]:
    rows = []
    for snapshot in db.collection(MONTHLY).document(month).collection("crews").get():
        data = snapshot.to_dict() or {}
        crew_snapshot = db.collection("crews").document(snapshot.id).get()
        if not crew_snapshot.exists:
            continue
        crew = crew_snapshot.to_dict() or {}
        rows.append(
            {
                "crew_id": snapshot.id,
                "name": str(crew.get("name") or ""),
                "emblem": str(crew.get("emblem") or ""),
                "distance_km": _num(data.get("distanceKm")),
                "member_count": int(_num(crew.get("memberCount"))),
                "updated_at": data.get("updatedAt"),
            }
        )
    return rows


def _public(row: dict) -> dict:
    return {
        "rank": row["rank"],
        "crew_id": row["crew_id"],
        "name": row["name"],
        "emblem": row["emblem"],
        "average_km": round(row["average_km"], 2),
        "distance_km": round(row["distance_km"], 2),
        "member_count": row["member_count"],
    }


def ranking_borders(rank: int) -> list[str]:
    """Ranking borders a best rank reaches (bronze/silver/gold = top 100 / 10 / 1)."""
    return [
        f"ranking-{tier}"
        for tier, limit in enumerate(BORDER_THRESHOLDS["ranking"], start=1)
        if 0 < rank <= limit
    ]


# ---- month end -------------------------------------------------------------------------
def finalize_month(db, month: str) -> dict:
    """Close a finished month: store its ranking, raise each crew's best rank and borders."""
    month_ref = db.collection(MONTHLY).document(month)
    existing = month_ref.get()
    if existing.exists and (existing.to_dict() or {}).get("finalized") is True:
        return {"month": month, "status": "already_finalized"}
    ranked = rank_crews(load_rows(db, month))
    for row in ranked:
        crew_ref = db.collection("crews").document(row["crew_id"])
        crew_snapshot = crew_ref.get()
        crew = crew_snapshot.to_dict() or {}
        best = crew.get("bestMonthlyRank")
        best = int(best) if isinstance(best, (int, float)) and not isinstance(best, bool) and best > 0 else 0
        new_best = row["rank"] if best == 0 else min(best, row["rank"])
        recorded = crew.get("unlockedBorders")
        borders = sorted(
            {b for b in (recorded if isinstance(recorded, list) else []) if isinstance(b, str)}
            | set(ranking_borders(new_best))
        )
        crew_ref.set(
            {"bestMonthlyRank": new_best, "unlockedBorders": borders, "updatedAt": SERVER_TIMESTAMP},
            merge=True,
        )
    month_ref.set(
        {
            "finalized": True,
            "finalizedAt": SERVER_TIMESTAMP,
            "rankedCrews": len(ranked),
            "ranking": [_public(r) for r in ranked[:TOP_LIMIT]],
        },
        merge=True,
    )
    return {"month": month, "status": "finalized", "ranked": len(ranked)}


def ensure_previous_month_finalized(db, now: datetime | None = None) -> None:
    try:
        finalize_month(db, previous_month_key(now))
    except Exception:
        # Reading the ranking must still work; the next read tries again.
        pass


def summary(db, crew_id: str, now: datetime | None = None) -> dict:
    """This month's live ranking: the top crews and where the caller's crew stands."""
    ensure_previous_month_finalized(db, now)
    month = month_key(now)
    rows = load_rows(db, month)
    ranked = rank_crews(rows)
    mine = next((r for r in ranked if r["crew_id"] == crew_id), None)
    own = next((r for r in rows if r["crew_id"] == crew_id), None)
    floor = min_members()
    crew_snapshot = db.collection("crews").document(crew_id).get() if crew_id else None
    crew = (crew_snapshot.to_dict() or {}) if crew_snapshot is not None and crew_snapshot.exists else {}
    members = int(_num(crew.get("memberCount")))
    best = crew.get("bestMonthlyRank")
    return {
        "month": month,
        "min_members": floor,
        "ranked_crews": len(ranked),
        "top": [_public(r) for r in ranked[:TOP_LIMIT]],
        "mine": None if mine is None else _public(mine),
        "my_distance_km": round(own["distance_km"], 2) if own else 0.0,
        "my_member_count": members,
        "my_eligible": members >= floor,
        "best_rank": int(best) if isinstance(best, (int, float)) and not isinstance(best, bool) and best > 0 else 0,
    }
