"""Sponsorship (개인 후원) records: a public summary and each sponsor's own list.

Sponsorship is donated in the company's name and the company only relays it. Everyone may
see the totals; only the sponsor sees their own entries.

* Totals live in ``sponsorTotals/donation`` (all time) and ``sponsorTotals/donation_YYYY-MM``.
  Clients cannot read them. ``summary`` hands them out and holds the money amounts back until
  at least ``SPONSOR_SUMMARY_MIN`` (default 5) people have sponsored, so a lone sponsor's
  amount is never public by accident.
* Only the ``donation`` purpose counts here; the ``prize`` purpose funds prizes.
"""

from __future__ import annotations

import os
from datetime import datetime, timedelta, timezone

from google.cloud.firestore_v1 import Increment

TOTALS = "sponsorTotals"
DONATION_TYPE = "personal_sponsor_donation"
PRIZE_TYPE = "personal_sponsor_prize"
DEFAULT_MIN_SPONSORS = 5
LIST_LIMIT = 100
_KST = timezone(timedelta(hours=9))


def min_sponsors() -> int:
    raw = os.environ.get("SPONSOR_SUMMARY_MIN", "").strip()
    try:
        return max(1, int(raw)) if raw else DEFAULT_MIN_SPONSORS
    except ValueError:
        return DEFAULT_MIN_SPONSORS


def month_key(now: datetime | None = None) -> str:
    return (now or datetime.now(_KST)).astimezone(_KST).strftime("%Y-%m")


def refs(db, now: datetime | None = None):
    return (
        db.collection(TOTALS).document("donation"),
        db.collection(TOTALS).document(f"donation_{month_key(now)}"),
    )


def read_totals(transaction, all_ref, month_ref) -> None:
    """Read both docs first (a transaction reads before it writes)."""
    all_ref.get(transaction=transaction)
    month_ref.get(transaction=transaction)


def record_donation(transaction, all_ref, month_ref, *, won: int, first_time: bool) -> None:
    """Add one donation sponsorship to the public totals."""
    transaction.set(
        all_ref,
        {
            "totalWon": Increment(won),
            "count": Increment(1),
            **({"sponsorCount": Increment(1)} if first_time else {}),
        },
        merge=True,
    )
    transaction.set(
        month_ref,
        {"totalWon": Increment(won), "count": Increment(1)},
        merge=True,
    )


def _num(doc: dict | None, key: str) -> int:
    value = (doc or {}).get(key)
    return int(value) if isinstance(value, (int, float)) and not isinstance(value, bool) else 0


def summary(db, uid: str) -> dict:
    all_ref, month_ref = refs(db)
    all_snapshot = all_ref.get()
    month_snapshot = month_ref.get()
    all_doc = all_snapshot.to_dict() if all_snapshot.exists else {}
    month_doc = month_snapshot.to_dict() if month_snapshot.exists else {}
    sponsors = _num(all_doc, "sponsorCount")
    show_money = sponsors >= min_sponsors()
    return {
        "sponsor_count": sponsors,
        "show_amounts": show_money,
        "min_sponsors": min_sponsors(),
        "total_won": _num(all_doc, "totalWon") if show_money else None,
        "month_won": _num(month_doc, "totalWon") if show_money else None,
        "month_count": _num(month_doc, "count") if show_money else None,
    }


def mine(db, uid: str) -> dict:
    """The caller's own sponsorship entries, newest first."""
    rows = []
    for tx_type, purpose in ((DONATION_TYPE, "donation"), (PRIZE_TYPE, "prize")):
        query = db.collection("walletTransactions").where("uid", "==", uid).where("type", "==", tx_type)
        for snapshot in query.get():
            row = snapshot.to_dict() or {}
            created = row.get("createdAt")
            share = abs(int(row.get("shareAmount") or 0))
            rows.append(
                {
                    "purpose": purpose,
                    "share": share,
                    "won": share,  # 1 SHARE counts as 1 won (config: personal_sponsor_won_per_share)
                    "angel_tier_code": str(row.get("angelTierCode") or ""),
                    "created_at": created.isoformat() if isinstance(created, datetime) else "",
                }
            )
    rows.sort(key=lambda r: r["created_at"], reverse=True)
    donation = [r for r in rows if r["purpose"] == "donation"]
    return {
        "entries": rows[:LIST_LIMIT],
        "donation_count": len(donation),
        "donation_won": sum(r["won"] for r in donation),
    }
