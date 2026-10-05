"""Referral trial counting: distance, one KST day, window, device block."""

from datetime import datetime, timedelta, timezone

from app.services.referral_trial_config import (
    advance_trial_count,
    milestones_due,
    resolve_referral_trial_config,
)

_DAY = datetime(2026, 10, 1, 3, tzinfo=timezone.utc)


def test_defaults_ignore_a_watch_requirement() -> None:
    config = resolve_referral_trial_config({"watch_required": True, "runs_required": 3})
    assert config["watch_required"] is False
    assert config["runs_required"] == 3
    assert config["referee_milestones"] == [
        {"run": 1, "share": 10_000},
        {"run": 3, "share": 40_000},
    ]


def test_one_counted_run_per_kst_day_and_three_distinct_days() -> None:
    config = resolve_referral_trial_config(None)
    economy: dict = {}
    count, days, counted = advance_trial_count(
        economy,
        distance_m=1100,
        now=_DAY,
        signup_at=_DAY,
        config=config,
        device_blocked=False,
    )
    assert (count, counted) == (1, True)
    economy = {"trialRunCount": count, "trialCountedDays": days}
    count, days, counted = advance_trial_count(
        economy,
        distance_m=1100,
        now=_DAY + timedelta(hours=3),
        signup_at=_DAY,
        config=config,
        device_blocked=False,
    )
    assert counted is False
    assert count == 1
    count, days, counted = advance_trial_count(
        {"trialRunCount": count, "trialCountedDays": days},
        distance_m=1000,
        now=_DAY + timedelta(days=1),
        signup_at=_DAY,
        config=config,
        device_blocked=False,
    )
    assert counted is True and count == 2
    count, days, counted = advance_trial_count(
        {"trialRunCount": count, "trialCountedDays": days},
        distance_m=1500,
        now=_DAY + timedelta(days=2),
        signup_at=_DAY,
        config=config,
        device_blocked=False,
    )
    assert count == 3 and len(set(days)) == 3
    assert milestones_due(count, config) == [
        {"run": 1, "share": 10_000},
        {"run": 3, "share": 40_000},
    ]


def test_short_late_and_blocked_runs_do_not_count() -> None:
    config = resolve_referral_trial_config(None)
    short = advance_trial_count(
        {},
        distance_m=999,
        now=_DAY,
        signup_at=_DAY,
        config=config,
        device_blocked=False,
    )
    assert short[2] is False
    late = advance_trial_count(
        {},
        distance_m=1100,
        now=_DAY + timedelta(days=14, seconds=1),
        signup_at=_DAY,
        config=config,
        device_blocked=False,
    )
    assert late[2] is False
    blocked = advance_trial_count(
        {},
        distance_m=1100,
        now=_DAY,
        signup_at=_DAY,
        config=config,
        device_blocked=True,
    )
    assert blocked[2] is False


def test_legacy_count_is_kept() -> None:
    config = resolve_referral_trial_config(None)
    count, days, counted = advance_trial_count(
        {"trialRunCount": 2},
        distance_m=1100,
        now=_DAY,
        signup_at=_DAY,
        config=config,
        device_blocked=False,
    )
    assert counted is True
    assert count == 3
    assert days[:2] == ["legacy-0", "legacy-1"]
