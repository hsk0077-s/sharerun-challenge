"""Funding card numbers: this month's company donation against a growing goal.

The money is the company's own won in ``donationMonthTotals/{YYYY-MM}`` (verified runs and
donation-match tickets). VALUE is not converted into won, so nothing here reads a user's
VALUE. The goal moves up through ``stages`` as each one is reached; ``config/funding_goal``
may replace the stages. The monthly cap is the same one that stops the donation itself
(``config/company_donation``), so the card can never promise more than the company will pay.
Everyone sees the same totals and nothing about a single person.
"""

from __future__ import annotations

from datetime import datetime, timedelta, timezone

from app.services.donation_cap import (
    DONATION_MONTH_TOTALS,
    month_total_won,
    read_monthly_cap_won,
)

FUNDING_GOAL_CONFIG_ID = "funding_goal"
DEFAULT_STAGES = (100_000, 300_000, 500_000, 1_000_000)
_KST = timezone(timedelta(hours=9))


def month_key(now: datetime | None = None) -> str:
    return (now or datetime.now(_KST)).astimezone(_KST).strftime("%Y-%m")


def resolve_stages(raw: dict | None) -> tuple[int, ...]:
    """Positive, strictly rising whole won. A bad config keeps the default."""
    value = raw.get("stages") if isinstance(raw, dict) else None
    if not isinstance(value, list) or not value:
        return DEFAULT_STAGES
    stages: list[int] = []
    for item in value:
        if isinstance(item, bool) or not isinstance(item, (int, float)) or item <= 0:
            return DEFAULT_STAGES
        won = int(item)
        if stages and won <= stages[-1]:
            return DEFAULT_STAGES
        stages.append(won)
    return tuple(stages)


def stages_through_cap(stages: tuple[int, ...], cap_won: int) -> tuple[int, ...]:
    """Goals the card may show. The last one is the monthly cap.

    A stage list that stops at 300,000 left ``goal_won`` at 0 while the
    company was still paying up to the real cap. Stages above the cap are
    dropped so the card does not promise more than the company will pay.
    """
    if cap_won <= 0:
        return stages
    below = tuple(stage for stage in stages if stage < cap_won)
    return (*below, cap_won)


def progress(total_won: int, stages: tuple[int, ...], cap_won: int) -> dict:
    """The goal the month is working toward and how far along it is.

    ``goal_won`` is 0 once every stage is reached. ``stage`` counts from 1.
    """
    reached = [s for s in stages if total_won >= s]
    next_goal = next((s for s in stages if total_won < s), 0)
    return {
        "total_won": int(total_won),
        "goal_won": next_goal,
        "stage": min(len(reached) + 1, len(stages)),
        "stage_count": len(stages),
        "stages_reached": len(reached),
        "cap_won": int(cap_won),
        "cap_reached": cap_won > 0 and total_won >= cap_won,
    }


def summary(db, now: datetime | None = None) -> dict:
    month = month_key(now)
    try:
        totals = db.collection(DONATION_MONTH_TOTALS).document(month).get()
        total = month_total_won(totals.to_dict() if totals.exists else None)
    except Exception:
        total = 0
    try:
        config = db.collection("config").document(FUNDING_GOAL_CONFIG_ID).get()
        stages = resolve_stages(config.to_dict() if config.exists else None)
    except Exception:
        stages = DEFAULT_STAGES
    cap_won = read_monthly_cap_won(db)
    return {"month": month, **progress(total, stages_through_cap(stages, cap_won), cap_won)}
