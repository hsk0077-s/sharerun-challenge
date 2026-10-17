"""Crew emblem extras: unlock borders, paid illustrations, change rules.

* Unlock borders (4 kinds x bronze/silver/gold) are earned from crew stats the server
  keeps on the crew doc. They cannot be bought.
* Paid illustrations (4) are bought with DIA by the crew leader and then owned by the crew.
  Sale stays off until ``CREW_EMBLEM_PAID_SALE`` is ``on`` (the art is still a sample).
* The leader or a sub-leader may change the emblem; the server enforces a cooldown.
"""

from __future__ import annotations

import os
from datetime import datetime, timedelta, timezone

BORDER_KINDS = ("distance", "donation", "members", "ranking")
BORDER_TIERS = (1, 2, 3)
BORDER_IDS = frozenset(f"{k}-{t}" for k in BORDER_KINDS for t in BORDER_TIERS)

# Spec values (all provisional): distance km, donation won, members, best monthly rank.
BORDER_THRESHOLDS: dict[str, tuple[int, int, int]] = {
    "distance": (1_000, 5_000, 20_000),
    "donation": (100_000, 500_000, 2_000_000),
    "members": (10, 30, 50),
    "ranking": (100, 10, 1),  # rank must be this or better
}

PAID_EMBLEM_PRICES_DIA: dict[str, int] = {
    "sunrise-cheetah": 40,
    "moon-wolf": 40,
    "ocean-turtle": 40,
    "glow-heart": 50,
}

DEFAULT_COOLDOWN_DAYS = 7


def cooldown_days() -> int:
    raw = os.environ.get("CREW_EMBLEM_COOLDOWN_DAYS", "")
    try:
        return max(0, int(raw)) if raw.strip() else DEFAULT_COOLDOWN_DAYS
    except ValueError:
        return DEFAULT_COOLDOWN_DAYS


def paid_sale_enabled() -> bool:
    return os.environ.get("CREW_EMBLEM_PAID_SALE", "").strip().lower() == "on"


def _num(value: object) -> float:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        return 0.0
    return float(value)


def stats(crew: dict) -> dict[str, float]:
    rank = crew.get("bestMonthlyRank")
    return {
        "distance": _num(crew.get("totalDistanceKm")),
        "donation": _num(crew.get("totalDonationWon")),
        "members": _num(crew.get("memberCount")),
        # 0 means "never ranked".
        "ranking": _num(rank) if isinstance(rank, (int, float)) and rank > 0 else 0.0,
    }


def earned_borders(crew: dict) -> set[str]:
    """Borders the crew's recorded stats reach now, plus any recorded earlier."""
    now = stats(crew)
    out: set[str] = set()
    for kind, limits in BORDER_THRESHOLDS.items():
        for tier, limit in enumerate(limits, start=1):
            if kind == "ranking":
                reached = 0 < now[kind] <= limit
            else:
                reached = now[kind] >= limit
            if reached:
                out.add(f"{kind}-{tier}")
    recorded = crew.get("unlockedBorders")
    if isinstance(recorded, list):
        out |= {b for b in recorded if isinstance(b, str) and b in BORDER_IDS}
    return out


def owned_paid(crew: dict) -> set[str]:
    owned = crew.get("paidEmblems")
    if not isinstance(owned, list):
        return set()
    return {p for p in owned if isinstance(p, str) and p in PAID_EMBLEM_PRICES_DIA}


def can_manage(uid: str, crew: dict) -> bool:
    if crew.get("ownerUid") == uid:
        return True
    subs = crew.get("subLeaderUids")
    return isinstance(subs, list) and uid in subs


def cooldown_remaining_seconds(crew: dict, now: datetime | None = None) -> int:
    days = cooldown_days()
    changed = crew.get("emblemChangedAt")
    if days <= 0 or not isinstance(changed, datetime):
        return 0
    if changed.tzinfo is None:
        changed = changed.replace(tzinfo=timezone.utc)
    now = now or datetime.now(timezone.utc)
    left = changed + timedelta(days=days) - now
    return max(0, int(left.total_seconds()))
