"""Real donation payments: one record per KST month, written by an admin.

``donationExecutions/{YYYY-MM}`` holds what was actually sent: the amount, the
date, who received it, the proof image path (a file in Storage) and a note.
Only this module writes it (Admin SDK); every signed-in user may read it, so
the app can show the proof.

Saving a record also marks the month's ``donationLedger`` rows with
``receiptIssued = True``. Nothing here touches a wallet, a balance, the monthly
cap or a person's day room.
"""

from __future__ import annotations

import re
from datetime import date, datetime, timezone

from fastapi import HTTPException, status
from google.cloud.firestore_v1 import SERVER_TIMESTAMP

EXECUTIONS = "donationExecutions"
DONATION_LEDGER = "donationLedger"
MAX_AMOUNT_WON = 1_000_000_000
MAX_NOTE_CHARS = 500
MAX_PARTNER_CHARS = 100
_BATCH = 400  # Firestore allows 500 writes in one batch
_MONTH_RE = re.compile(r"^\d{4}-(0[1-9]|1[0-2])$")
_FILE_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]{0,119}$")


def _bad(detail: str) -> HTTPException:
    return HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=detail)


def receipt_path_ok(month: str, path: str) -> bool:
    """Proof images live in ``donation-receipts/{YYYY-MM}/{file}`` and nowhere else."""
    prefix = f"donation-receipts/{month}/"
    return path.startswith(prefix) and bool(_FILE_RE.match(path[len(prefix) :]))


def _as_datetime(value: str | date | datetime) -> datetime:
    if isinstance(value, datetime):
        return value if value.tzinfo else value.replace(tzinfo=timezone.utc)
    if isinstance(value, date):
        return datetime(value.year, value.month, value.day, tzinfo=timezone.utc)
    try:
        parsed = datetime.fromisoformat(str(value))
    except ValueError as error:
        raise _bad("invalid_executed_at") from error
    return parsed if parsed.tzinfo else parsed.replace(tzinfo=timezone.utc)


def _mark_ledger_rows(db, month: str) -> int:
    """receiptIssued -> True on every ledger row of ``month``. Safe to run twice."""
    rows = list(db.collection(DONATION_LEDGER).where("monthKey", "==", month).get())
    pending = [row.reference for row in rows if (row.to_dict() or {}).get("receiptIssued") is not True]
    for start in range(0, len(pending), _BATCH):
        batch = db.batch()
        for ref in pending[start : start + _BATCH]:
            batch.update(ref, {"receiptIssued": True})
        batch.commit()
    return len(pending)


def record_execution(
    db,
    *,
    month: str,
    amount_won: int,
    executed_at: str | date | datetime,
    partner_name: str,
    receipt_image_path: str,
    note: str,
    created_by: str,
) -> dict:
    month = (month or "").strip()
    if not _MONTH_RE.match(month):
        raise _bad("invalid_month")
    if isinstance(amount_won, bool) or not isinstance(amount_won, int) or not 0 < amount_won <= MAX_AMOUNT_WON:
        raise _bad("invalid_amount")
    partner = (partner_name or "").strip()
    if not partner or len(partner) > MAX_PARTNER_CHARS:
        raise _bad("invalid_partner")
    path = (receipt_image_path or "").strip()
    if not receipt_path_ok(month, path):
        raise _bad("invalid_receipt_path")
    note = (note or "").strip()
    if len(note) > MAX_NOTE_CHARS:
        raise _bad("note_too_long")
    executed = _as_datetime(executed_at)
    if not created_by:
        raise _bad("invalid_actor")

    ref = db.collection(EXECUTIONS).document(month)
    existing = ref.get()
    fields = {
        "month": month,
        "amountWon": amount_won,
        "executedAt": executed,
        "partnerName": partner,
        "receiptImagePath": path,
        "note": note,
        "createdBy": created_by,
        "updatedAt": SERVER_TIMESTAMP,
    }
    if not existing.exists:
        fields["createdAt"] = SERVER_TIMESTAMP
    ref.set(fields, merge=True)
    marked = _mark_ledger_rows(db, month)
    return {
        "month": month,
        "amount_won": amount_won,
        "replaced": bool(existing.exists),
        "ledger_rows_marked": marked,
    }
