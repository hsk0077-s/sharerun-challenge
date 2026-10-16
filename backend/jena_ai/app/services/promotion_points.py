"""Promotion points: tournament results move a runner up the 25-step grade.

Rules come from the confirmed tier rule sheet (2026-10-15). Every number is a
default here and can be overridden by the Firestore doc ``config/promotion``;
a missing or invalid field keeps the default.

* One tournament result gives ``rank points x headcount multiplier x class
  multiplier``. Fewer than 5 finishers give nothing.
* Points collect on ``users/{uid}.promotion.points``. One medal step is the
  animal's threshold divided by five. Crossing to the next animal also needs a
  minimum number of tournaments in the current animal and, from the wolf up,
  a recent verified run at the next animal's pace.
* One step per award and one promotion per 7 days. There is no demotion here.
* A win in an official race can promote at once (turtle with 10 finishers,
  maltese with 30). Wolf and above are not covered yet.
* The ledger doc ``promotionLedger/{tournamentId}__{uid}`` is written once, so
  settling again never pays twice. Points have no cash or DIA value.
"""

from copy import deepcopy
from datetime import datetime, timedelta, timezone
import logging

from google.cloud.firestore_v1 import SERVER_TIMESTAMP

from app.services.grade_assignment import (
    counts_for_grade,
    run_pace_sec_per_km,
)
from app.services.referral_trial_config import kst_day_key

logger = logging.getLogger(__name__)

PROMOTION_CONFIG_ID = "promotion"
PROMOTION_LEDGER = "promotionLedger"

ANIMALS = ("turtle", "maltese", "wolf", "horse", "cheetah")
MEDALS = ("bronze", "silver", "gold", "diamond", "master")

DEFAULT_CONFIG: dict = {
    # rank 1, 2, 3, top 25 percent, any other finish
    "rankPoints": {"1": 40, "2": 25, "3": 18, "top25": 10, "finish": 3},
    # (minimum finishers, multiplier). Below the first row gives no points.
    "headcountMultipliers": [[5, 0.6], [10, 1.0], [30, 1.5], [100, 2.5]],
    "classMultipliers": {
        "free": 0.5,
        "tier": 1.0,
        "company": 1.5,
        "sponsor": 2.5,
        "final": 2.5,
    },
    "challengeRankBonus": 1.2,
    # per animal: points to leave the animal, min tournaments, pace gate (sec/km)
    "animals": {
        "turtle": {"threshold": 100, "minTournaments": 3, "paceGateSec": 0},
        "maltese": {"threshold": 150, "minTournaments": 5, "paceGateSec": 359},
        "wolf": {"threshold": 200, "minTournaments": 6, "paceGateSec": 299},
        "horse": {"threshold": 300, "minTournaments": 8, "paceGateSec": 239},
        "cheetah": {"threshold": 300, "minTournaments": 0, "paceGateSec": 0},
    },
    "paceGateDays": 30,
    "freeMinFinishers": 10,
    "freeWeeklyCap": 30,
    "newAccountDays": 14,
    "newAccountWinFactor": 0.5,
    "promotionCooldownDays": 7,
    # instant promotion: animal -> minimum finishers; official races only
    "instantWin": {"turtle": 10, "maltese": 30},
    "instantWinClasses": ["company", "sponsor", "final"],
}


def resolve_config(raw: object) -> dict:
    """Defaults, overridden field by field when the stored value has the same
    shape. A bad edit keeps the default for that field only."""
    config = deepcopy(DEFAULT_CONFIG)
    if not isinstance(raw, dict):
        return config
    for key, default in DEFAULT_CONFIG.items():
        if key not in raw:
            continue
        value = raw[key]
        if _same_shape(default, value):
            config[key] = deepcopy(value)
    return config


def _same_shape(default: object, value: object) -> bool:
    if isinstance(default, bool):
        return isinstance(value, bool)
    if isinstance(default, (int, float)):
        return (
            isinstance(value, (int, float))
            and not isinstance(value, bool)
            and value >= 0
        )
    if isinstance(default, str):
        return isinstance(value, str)
    if isinstance(default, list):
        if not isinstance(value, list) or not value:
            return False
        if isinstance(default[0], list):
            return all(
                isinstance(row, list)
                and len(row) == 2
                and all(
                    isinstance(item, (int, float)) and not isinstance(item, bool)
                    for item in row
                )
                for row in value
            )
        return all(isinstance(item, str) for item in value)
    if isinstance(default, dict):
        if not isinstance(value, dict) or set(value) != set(default):
            return False
        return all(_same_shape(default[key], value[key]) for key in default)
    return False


def rank_to_grade(rank: int) -> tuple[str, int]:
    """``(gradeCode, gradeRank)`` for a 1..25 rank, bronze first in each animal."""
    clamped = max(1, min(25, int(rank)))
    animal = ANIMALS[(clamped - 1) // 5]
    medal = MEDALS[(clamped - 1) % 5]
    return f"{animal}_{medal}", clamped


def animal_of_rank(rank: int) -> str:
    return ANIMALS[(max(1, min(25, int(rank))) - 1) // 5]


def medal_step(config: dict, animal: str) -> int:
    threshold = int(config["animals"][animal]["threshold"])
    return max(1, threshold // 5)


def headcount_multiplier(config: dict, finishers: int) -> float:
    multiplier = 0.0
    for minimum, value in config["headcountMultipliers"]:
        if finishers >= minimum:
            multiplier = float(value)
    return multiplier


def base_rank_points(config: dict, rank: int, finishers: int) -> int:
    table = config["rankPoints"]
    if rank == 1:
        return int(table["1"])
    if rank == 2:
        return int(table["2"])
    if rank == 3:
        return int(table["3"])
    if finishers > 0 and rank <= max(1, (finishers * 25) // 100):
        return int(table["top25"])
    return int(table["finish"])


def points_for_result(
    config: dict,
    *,
    rank: int,
    finishers: int,
    tournament_class: str,
    account_age_days: float | None = None,
    challenged_up: bool = False,
) -> int:
    """Whole points for one result. Zero when the field is too small."""
    if tournament_class == "free" and finishers < int(config["freeMinFinishers"]):
        return 0
    spread = headcount_multiplier(config, finishers)
    if spread <= 0:
        return 0
    class_multiplier = float(config["classMultipliers"].get(tournament_class, 0))
    if class_multiplier <= 0:
        return 0
    value = base_rank_points(config, rank, finishers) * spread * class_multiplier
    if challenged_up:
        value *= float(config["challengeRankBonus"])
    if (
        rank == 1
        and account_age_days is not None
        and account_age_days < int(config["newAccountDays"])
    ):
        value *= float(config["newAccountWinFactor"])
    return int(value)


def _as_int(value: object, default: int = 0) -> int:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        return default
    return int(value)


def _as_time(value: object) -> datetime | None:
    if isinstance(value, datetime):
        return value if value.tzinfo else value.replace(tzinfo=timezone.utc)
    if isinstance(value, str):
        try:
            parsed = datetime.fromisoformat(value)
        except ValueError:
            return None
        return parsed if parsed.tzinfo else parsed.replace(tzinfo=timezone.utc)
    return None


def apply_award(
    config: dict,
    *,
    grade_rank: int,
    state: dict | None,
    points: int,
    counts_tournament: bool,
    first_place_instant: bool,
    best_recent_pace_sec: int | None,
    now: datetime,
) -> dict:
    """Pure step: new state after one result.

    Returns ``{"gradeRank", "points", "tournaments", "promoted", "instant",
    "lastPromotedAt", "blocked"}``. ``blocked`` names what held a promotion
    back (``cooldown``, ``tournaments``, ``pace``) so the app can say so.
    """
    state = state if isinstance(state, dict) else {}
    rank = max(1, min(25, int(grade_rank)))
    banked = max(0, _as_int(state.get("points")))
    tournaments = max(0, _as_int(state.get("tournaments")))
    last_promoted = _as_time(state.get("lastPromotedAt"))
    cooldown = timedelta(days=int(config["promotionCooldownDays"]))
    cooling = last_promoted is not None and now - last_promoted < cooldown

    if counts_tournament:
        tournaments += 1
    banked += max(0, int(points))

    outcome = {
        "gradeRank": rank,
        "points": banked,
        "tournaments": tournaments,
        "promoted": False,
        "instant": False,
        "lastPromotedAt": state.get("lastPromotedAt"),
        "blocked": None,
    }
    animal = animal_of_rank(rank)

    if first_place_instant and rank < 25 and animal in config["instantWin"]:
        if cooling:
            outcome["blocked"] = "cooldown"
        else:
            rank = (rank - 1) // 5 * 5 + 6
            outcome.update(
                {
                    "gradeRank": rank,
                    "points": 0,
                    "tournaments": 0,
                    "promoted": True,
                    "instant": True,
                    "lastPromotedAt": now.isoformat(),
                }
            )
            return outcome

    if rank >= 25:
        return outcome
    step = medal_step(config, animal)
    if banked < step:
        return outcome
    if cooling:
        outcome["blocked"] = "cooldown"
        return outcome

    crossing = rank % 5 == 0
    if crossing:
        rule = config["animals"][animal]
        if tournaments < int(rule["minTournaments"]):
            outcome["blocked"] = "tournaments"
            return outcome
        gate = int(rule["paceGateSec"])
        if animal == "horse":
            # Season top 10 percent is not tracked yet, so a horse stays put
            # until that rule exists. A cheetah placement by pace still works.
            outcome["blocked"] = "season"
            return outcome
        if gate > 0 and (best_recent_pace_sec is None or best_recent_pace_sec > gate):
            outcome["blocked"] = "pace"
            return outcome

    banked -= step
    rank += 1
    outcome.update(
        {
            "gradeRank": rank,
            "points": banked,
            "promoted": True,
            "lastPromotedAt": now.isoformat(),
        }
    )
    if crossing:
        outcome["tournaments"] = 0
    return outcome


def week_key(now: datetime) -> str:
    year, week, _ = datetime.fromisoformat(kst_day_key(now)).isocalendar()
    return f"{year}-W{week:02d}"


def ledger_id(tournament_id: str, uid: str) -> str:
    return f"{tournament_id}__{uid}"


def best_recent_pace(db, uid: str, now: datetime, days: int) -> int | None:
    """Fastest verified 1km+ run pace in the last ``days``, or ``None``."""
    since = now - timedelta(days=days)
    best: int | None = None
    for row in (
        db.collection("activities")
        .where("userId", "==", uid)
        .where("jenaVerified", "==", True)
        .get()
    ):
        data = row.to_dict() or {}
        finished = _as_time(data.get("completedAt"))
        distance = data.get("distanceKm")
        duration = data.get("durationSeconds")
        if finished is None or finished < since:
            continue
        if isinstance(distance, bool) or isinstance(duration, bool):
            continue
        if not isinstance(distance, (int, float)) or not isinstance(duration, (int, float)):
            continue
        if not counts_for_grade(float(distance)):
            continue
        pace = run_pace_sec_per_km(float(distance), float(duration))
        if pace is not None and (best is None or pace < best):
            best = pace
    return best


def _free_points_this_week(db, uid: str, week: str) -> int:
    total = 0
    for row in (
        db.collection(PROMOTION_LEDGER)
        .where("uid", "==", uid)
        .where("weekKey", "==", week)
        .get()
    ):
        data = row.to_dict() or {}
        if data.get("tournamentClass") == "free":
            total += max(0, _as_int(data.get("points")))
    return total


def load_config(db) -> dict:
    snapshot = db.collection("config").document(PROMOTION_CONFIG_ID).get()
    raw = snapshot.to_dict() if snapshot.exists else None
    return resolve_config(raw)


def award_tournament_results(
    db,
    *,
    tournament_id: str,
    tournament_class: str,
    results: list[dict],
    now: datetime | None = None,
    config: dict | None = None,
) -> dict:
    """Give promotion points for one settled tournament.

    ``results`` rows: ``{"uid", "rank", "challengedUp": bool}`` for verified
    finishers, in finish order. Runners without a grade (snails) are skipped.
    Safe to call again: a runner who already has a ledger doc is skipped.
    """
    current = now or datetime.now(timezone.utc)
    rules = config or load_config(db)
    finishers = len(results)
    week = week_key(current)
    summary = {
        "awarded": 0,
        "skipped": 0,
        "promoted": 0,
        "points": 0,
    }
    for row in results:
        uid = str(row["uid"])
        ledger_ref = db.collection(PROMOTION_LEDGER).document(
            ledger_id(tournament_id, uid)
        )
        if ledger_ref.get().exists:
            summary["skipped"] += 1
            continue
        user_ref = db.collection("users").document(uid)
        snapshot = user_ref.get()
        user = snapshot.to_dict() if snapshot.exists else None
        grade_rank = _as_int((user or {}).get("gradeRank"))
        if not user or grade_rank <= 0:
            summary["skipped"] += 1
            continue

        created = _as_time(user.get("authCreatedAt"))
        age_days = (current - created).total_seconds() / 86400 if created else None
        rank = int(row["rank"])
        points = points_for_result(
            rules,
            rank=rank,
            finishers=finishers,
            tournament_class=tournament_class,
            account_age_days=age_days,
            challenged_up=bool(row.get("challengedUp")),
        )
        if tournament_class == "free" and points > 0:
            room = int(rules["freeWeeklyCap"]) - _free_points_this_week(db, uid, week)
            points = max(0, min(points, room))

        state = user.get("promotion") if isinstance(user.get("promotion"), dict) else {}
        counts = headcount_multiplier(rules, finishers) > 0
        instant = (
            rank == 1
            and tournament_class in rules["instantWinClasses"]
            and finishers >= int(rules["instantWin"].get(animal_of_rank(grade_rank), 10**9))
        )
        pace = None
        step_needed = apply_award(
            rules,
            grade_rank=grade_rank,
            state=state,
            points=points,
            counts_tournament=counts,
            first_place_instant=False,
            best_recent_pace_sec=None,
            now=current,
        )
        if step_needed["blocked"] == "pace":
            pace = best_recent_pace(
                db, uid, current, int(rules["paceGateDays"])
            )
        result = apply_award(
            rules,
            grade_rank=grade_rank,
            state=state,
            points=points,
            counts_tournament=counts,
            first_place_instant=instant,
            best_recent_pace_sec=pace,
            now=current,
        )

        ledger = {
            "uid": uid,
            "tournamentId": tournament_id,
            "tournamentClass": tournament_class,
            "rank": rank,
            "finishers": finishers,
            "points": points,
            "weekKey": week,
            "fromGradeRank": grade_rank,
            "toGradeRank": result["gradeRank"],
            "promoted": result["promoted"],
            "instant": result["instant"],
            "blocked": result["blocked"],
            "createdAt": SERVER_TIMESTAMP,
        }
        ledger_ref.set(ledger)
        update: dict = {
            "promotion": {
                "points": result["points"],
                "tournaments": result["tournaments"],
                "lastPromotedAt": result["lastPromotedAt"],
                "blocked": result["blocked"],
            }
        }
        if result["promoted"]:
            code, new_rank = rank_to_grade(result["gradeRank"])
            update["gradeCode"] = code
            update["gradeRank"] = new_rank
            summary["promoted"] += 1
        user_ref.set(update, merge=True)
        summary["awarded"] += 1
        summary["points"] += points
    return summary
