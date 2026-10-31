"""Monthly cap on company donations. ``config/company_donation`` overrides it.

The cap is one KST calendar month of ``donationLedger`` won. The running total
lives in ``donationMonthTotals/{YYYY-MM}`` and is changed in the same
transaction that appends the ledger row. A run that crosses the cap records
only the won that is left. A bad config field keeps the default.
"""

DONATION_MONTH_TOTALS = "donationMonthTotals"
COMPANY_DONATION_CONFIG_ID = "company_donation"
DEFAULT_MONTHLY_CAP_WON = 1_000_000
DEFAULT_BASE_CAP_WON = 300_000
DAILY_USER_DONATION_CAP_KM = 10.0
DAILY_USER_DONATION_CAP_WON = 1_000
CAP_REACHED = "cap_reached"
DAILY_CAP_REACHED = "daily_donation_cap"
_SLIDING_KEYS = ("baseCapWon", "priorMonthNetRevenueWon", "sponsorAttributedWon")
CURRENT_MONTH_NET_REVENUE_KEY = "currentMonthNetRevenueWon"


def _nonneg(value: object) -> int | None:
    if isinstance(value, bool) or not isinstance(value, (int, float)) or value < 0:
        return None
    return int(value)


def resolve_monthly_cap_won(raw: dict | None) -> int:
    """Hard ceiling for one KST month.

    A doc that only sets ``monthlyCapWon`` keeps that number, so older tests
    and configs stay put. Sliding applies when a base, prior-month net
    revenue, or sponsor amount is present:

    ``min(monthlyCapWon, max(baseCapWon, prior * 0.2 + sponsor))``.

    When ``currentMonthNetRevenueWon`` is present and a non-negative number,
    the result is cut again: ``min(that cap, currentMonthNetRevenueWon)``.
    A missing or unreadable value leaves the cap above unchanged. The 300,000
    floor is not re-applied after this cut, so a weaker month can sit under it.
    A current-month figure above the hard ceiling does not raise the cap.
    """
    if not isinstance(raw, dict):
        return DEFAULT_MONTHLY_CAP_WON
    if "monthlyCapWon" in raw:
        hard = _nonneg(raw.get("monthlyCapWon"))
        if hard is None:
            return DEFAULT_MONTHLY_CAP_WON
    else:
        hard = DEFAULT_MONTHLY_CAP_WON
    if not any(key in raw for key in _SLIDING_KEYS):
        cap = hard
    else:
        base = _nonneg(raw.get("baseCapWon")) if "baseCapWon" in raw else DEFAULT_BASE_CAP_WON
        if base is None:
            base = DEFAULT_BASE_CAP_WON
        prior = _nonneg(raw.get("priorMonthNetRevenueWon")) or 0
        sponsor = _nonneg(raw.get("sponsorAttributedWon")) or 0
        cap = min(hard, max(base, int(prior * 0.2) + sponsor))
    return _clip_current_month(raw, cap)


def _clip_current_month(raw: dict, cap: int) -> int:
    if CURRENT_MONTH_NET_REVENUE_KEY not in raw:
        return cap
    current = _nonneg(raw.get(CURRENT_MONTH_NET_REVENUE_KEY))
    if current is None:
        return cap
    return min(cap, current)


def daily_donation_used(user: dict | None, day_key: str) -> tuple[float, int]:
    """Km and won already counted for this user on ``day_key``."""
    raw = user.get("donationDaily") if isinstance(user, dict) else None
    if not isinstance(raw, dict) or raw.get("day") != day_key:
        return 0.0, 0
    km = raw.get("countedKm")
    won = raw.get("countedWon")
    used_km = float(km) if isinstance(km, (int, float)) and not isinstance(km, bool) else 0.0
    used_won = int(won) if isinstance(won, (int, float)) and not isinstance(won, bool) else 0
    return max(0.0, used_km), max(0, used_won)


def clip_daily_donation(
    distance_km: float,
    full_won: int,
    used_km: float,
    used_won: int,
) -> tuple[int, float]:
    """Won and km that still fit in today's 10km / 1,000 won room.

    The rest of the run stays on the activity. It does not enter the ledger.
    """
    remain_km = max(0.0, DAILY_USER_DONATION_CAP_KM - used_km)
    remain_won = max(0, DAILY_USER_DONATION_CAP_WON - used_won)
    if distance_km <= 0 or full_won <= 0 or remain_km <= 0 or remain_won <= 0:
        return 0, 0.0
    counted_km = min(distance_km, remain_km)
    proportional = int(round(full_won * (counted_km / distance_km)))
    won = min(proportional, remain_won)
    if won <= 0:
        return 0, 0.0
    if proportional > won and proportional > 0:
        counted_km = counted_km * (won / proportional)
    return won, counted_km


def read_monthly_cap_won(db, transaction=None) -> int:
    try:
        snapshot = (
            db.collection("config")
            .document(COMPANY_DONATION_CONFIG_ID)
            .get(transaction=transaction)
        )
        raw = snapshot.to_dict() if snapshot.exists else None
    except Exception:
        raw = None
    return resolve_monthly_cap_won(raw)


def month_total_won(data: dict | None) -> int:
    value = data.get("totalWon") if isinstance(data, dict) else None
    if isinstance(value, bool) or not isinstance(value, (int, float)) or value < 0:
        return 0
    return int(value)


def won_within_cap(requested: int, month_total: int, cap: int) -> int:
    """Won that still fits under the cap this month."""
    return max(0, min(int(requested), int(cap) - int(month_total)))
