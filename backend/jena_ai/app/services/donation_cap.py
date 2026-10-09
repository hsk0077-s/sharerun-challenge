"""Monthly cap on company donations. ``config/company_donation`` overrides it.

The cap is one KST calendar month of ``donationLedger`` won. The running total
lives in ``donationMonthTotals/{YYYY-MM}`` and is changed in the same
transaction that appends the ledger row. A run that crosses the cap records
only the won that is left. A bad config field keeps the default.
"""

DONATION_MONTH_TOTALS = "donationMonthTotals"
COMPANY_DONATION_CONFIG_ID = "company_donation"
DEFAULT_MONTHLY_CAP_WON = 1_000_000
CAP_REACHED = "cap_reached"


def resolve_monthly_cap_won(raw: dict | None) -> int:
    value = raw.get("monthlyCapWon") if isinstance(raw, dict) else None
    if isinstance(value, bool) or not isinstance(value, (int, float)) or value < 0:
        return DEFAULT_MONTHLY_CAP_WON
    return int(value)


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
