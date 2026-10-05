"""Referral trial runs. ``config/referral_trial`` overrides these defaults.

A verified run of at least 1km counts once per KST day. Three distinct days
inside 14 days of signup pay the referee 10,000 then 40,000 SHARE. The
referrer is owed 30,000 SHARE after that, held 7 days. A watch does not add
SHARE. Bad Firestore fields keep the defaults.
"""

from datetime import datetime, timedelta, timezone

REFERRAL_TRIAL_CONFIG_ID = "referral_trial"

_DEFAULTS = {
    "runs_required": 3,
    "min_distance_m": 1000,
    "max_counted_per_day": 1,
    "distinct_days_required": 3,
    "day_boundary_tz": "Asia/Seoul",
    "completion_window_days": 14,
    "referee_milestones": (
        {"run": 1, "share": 10_000},
        {"run": 3, "share": 40_000},
    ),
    "referrer_reward": 30_000,
    "referrer_payout_hold_days": 7,
    "referrer_max_referrals": 10,
    "referrer_lock_days": 30,
    "watch_required": False,
}

_KST = timezone(timedelta(hours=9))


def resolve_referral_trial_config(raw: dict | None) -> dict:
    resolved = {
        "runs_required": _DEFAULTS["runs_required"],
        "min_distance_m": _DEFAULTS["min_distance_m"],
        "max_counted_per_day": _DEFAULTS["max_counted_per_day"],
        "distinct_days_required": _DEFAULTS["distinct_days_required"],
        "day_boundary_tz": _DEFAULTS["day_boundary_tz"],
        "completion_window_days": _DEFAULTS["completion_window_days"],
        "referee_milestones": [dict(row) for row in _DEFAULTS["referee_milestones"]],
        "referrer_reward": _DEFAULTS["referrer_reward"],
        "referrer_payout_hold_days": _DEFAULTS["referrer_payout_hold_days"],
        "referrer_max_referrals": _DEFAULTS["referrer_max_referrals"],
        "referrer_lock_days": _DEFAULTS["referrer_lock_days"],
        "watch_required": False,
    }
    if not isinstance(raw, dict):
        return resolved
    _overlay_int(resolved, raw, "runs_required", minimum=1)
    _overlay_int(resolved, raw, "min_distance_m", minimum=1)
    _overlay_int(resolved, raw, "max_counted_per_day", minimum=1)
    _overlay_int(resolved, raw, "distinct_days_required", minimum=1)
    _overlay_int(resolved, raw, "completion_window_days", minimum=1)
    _overlay_int(resolved, raw, "referrer_reward", minimum=0)
    _overlay_int(resolved, raw, "referrer_payout_hold_days", minimum=0)
    _overlay_int(resolved, raw, "referrer_max_referrals", minimum=0)
    _overlay_int(resolved, raw, "referrer_lock_days", minimum=0)
    tz = raw.get("day_boundary_tz")
    if tz == "Asia/Seoul":
        resolved["day_boundary_tz"] = tz
    if raw.get("watch_required") is False:
        resolved["watch_required"] = False
    milestones = _milestones(raw.get("referee_milestones"))
    if milestones:
        resolved["referee_milestones"] = milestones
    return resolved


def read_referral_trial_config(db, transaction=None) -> dict:
    try:
        snapshot = (
            db.collection("config")
            .document(REFERRAL_TRIAL_CONFIG_ID)
            .get(transaction=transaction)
        )
        raw = snapshot.to_dict() if snapshot.exists else None
    except Exception:
        raw = None
    return resolve_referral_trial_config(raw)


def kst_day_key(now: datetime) -> str:
    current = now if now.tzinfo else now.replace(tzinfo=timezone.utc)
    return current.astimezone(_KST).date().isoformat()


def counted_days(economy: dict) -> list[str]:
    raw = economy.get("trialCountedDays")
    if not isinstance(raw, list):
        return []
    return [day for day in raw if isinstance(day, str) and day]


def progress_count(economy: dict) -> int:
    days = counted_days(economy)
    if days:
        return len(days)
    return int(economy.get("trialRunCount") or 0)


def distinct_day_count(economy: dict, count: int) -> int:
    days = counted_days(economy)
    if days:
        return len(set(days))
    return count


def within_completion_window(
    signup_at: datetime | None,
    now: datetime,
    window_days: int,
) -> bool:
    if signup_at is None:
        return True
    started = signup_at if signup_at.tzinfo else signup_at.replace(tzinfo=timezone.utc)
    current = now if now.tzinfo else now.replace(tzinfo=timezone.utc)
    return current <= started + timedelta(days=window_days)


def advance_trial_count(
    economy: dict,
    *,
    distance_m: float,
    now: datetime,
    signup_at: datetime | None,
    config: dict,
    device_blocked: bool,
) -> tuple[int, list[str], bool]:
    """Return ``(count, days, counted_this_run)``.

    ``days`` includes one entry per counted run. A legacy count with no day
    list is kept and extended, not reset.
    """
    days = counted_days(economy)
    count = progress_count(economy)
    if device_blocked or economy.get("trialMilestoneRewardClaimed") is True:
        return count, days, False
    if distance_m + 1e-6 < int(config["min_distance_m"]):
        return count, days, False
    if not within_completion_window(
        signup_at, now, int(config["completion_window_days"])
    ):
        return count, days, False
    if count >= int(config["runs_required"]):
        return count, days, False
    today = kst_day_key(now)
    if days.count(today) >= int(config["max_counted_per_day"]):
        return count, days, False
    if not days and count > 0:
        days = [f"legacy-{index}" for index in range(count)]
    return count + 1, [*days, today], True


def milestones_due(count: int, config: dict) -> list[dict]:
    due = []
    for row in config["referee_milestones"]:
        if count >= int(row["run"]) and int(row["share"]) > 0:
            due.append({"run": int(row["run"]), "share": int(row["share"])})
    return due


def referrer_due(count: int, distinct_days: int, config: dict) -> bool:
    return (
        count >= int(config["runs_required"])
        and distinct_days >= int(config["distinct_days_required"])
        and int(config["referrer_reward"]) > 0
    )


def _milestones(raw: object) -> list[dict] | None:
    if not isinstance(raw, list) or not raw:
        return None
    cleaned = []
    for row in raw:
        if not isinstance(row, dict):
            return None
        run = _int(row.get("run"))
        share = _int(row.get("share"))
        if run is None or share is None or run < 1 or share < 1:
            return None
        cleaned.append({"run": run, "share": share})
    cleaned.sort(key=lambda item: item["run"])
    return cleaned


def _overlay_int(base: dict, raw: dict, key: str, *, minimum: int) -> None:
    if key not in raw:
        return
    number = _int(raw.get(key))
    if number is None or number < minimum:
        return
    base[key] = number


def _int(value: object) -> int | None:
    if isinstance(value, bool) or not isinstance(value, int):
        return None
    return value
