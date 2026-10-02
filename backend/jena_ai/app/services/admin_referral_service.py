from fastapi import HTTPException, status
from google.cloud.firestore_v1.field_path import FieldPath

from app.constants.economy_constants import MAX_REFERRAL_PAYOUTS, TRIAL_RUNS_REQUIRED
from app.models.admin_api import (
    ReferralListResult,
    ReferralPayoutMarker,
    ReferralPayouts,
    ReferralUserRow,
)
from app.services.firebase_service import FirebaseService

PAYOUT_TYPES = ("redeem", "trial_referee", "trial_referrer")
DEFAULT_LIMIT = 40
MAX_LIMIT = 80


class AdminReferralService:
    """Reads referral fields. Does not write users, codes, or payouts."""

    def __init__(self, firebase_service: FirebaseService | None = None) -> None:
        self.firebase_service = firebase_service

    def list_referrals(
        self,
        *,
        limit: int = DEFAULT_LIMIT,
        cursor: str | None = None,
    ) -> ReferralListResult:
        page_size = _page_size(limit)
        start = _cursor(cursor)
        db = self._db()
        query = (
            db.collection("users")
            .order_by(FieldPath.document_id())
            .limit(page_size + 1)
        )
        if start:
            query = query.start_after([db.collection("users").document(start)])
        docs = list(query.stream())
        has_more = len(docs) > page_size
        page = docs[:page_size]
        payouts = self._load_payouts(db, [doc.id for doc in page])
        rows = [_row(doc.id, doc.to_dict() or {}, payouts) for doc in page]
        next_cursor = page[-1].id if has_more and page else None
        return ReferralListResult(
            users=rows,
            nextCursor=next_cursor,
            limit=page_size,
        )

    def _db(self):
        service = self.firebase_service or FirebaseService()
        return service.db

    def _load_payouts(self, db, uids: list[str]) -> dict[str, dict]:
        if not uids:
            return {}
        refs = [
            db.collection("referralPayouts").document(f"{uid}_{kind}")
            for uid in uids
            for kind in PAYOUT_TYPES
        ]
        found: dict[str, dict] = {}
        for snap in db.get_all(refs):
            if not getattr(snap, "exists", False):
                continue
            data = snap.to_dict() or {}
            found[snap.id] = data
        return found


def _page_size(limit: int) -> int:
    if limit < 1:
        return DEFAULT_LIMIT
    return min(limit, MAX_LIMIT)


def _cursor(cursor: str | None) -> str | None:
    if cursor is None:
        return None
    text = cursor.strip()
    if not text:
        return None
    if "/" in text or len(text) > 128:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid cursor.",
        )
    return text


def _row(uid: str, user: dict, payouts: dict[str, dict]) -> ReferralUserRow:
    economy = user.get("economy") if isinstance(user.get("economy"), dict) else {}
    markers = {}
    for kind in PAYOUT_TYPES:
        data = payouts.get(f"{uid}_{kind}")
        markers[kind] = None if data is None else _marker(data)
    return ReferralUserRow(
        uid=uid,
        referralCode=_text(economy.get("referralCode")),
        referredBy=_text(economy.get("referredBy")),
        referredByUid=_text(economy.get("referredByUid")),
        trialRunCount=_count(economy.get("trialRunCount")),
        trialRunsRequired=TRIAL_RUNS_REQUIRED,
        referralPayoutCount=_count(economy.get("referralPayoutCount")),
        referralPayoutMax=MAX_REFERRAL_PAYOUTS,
        payouts=ReferralPayouts(**markers),
    )


def _marker(data: dict) -> ReferralPayoutMarker:
    return ReferralPayoutMarker(
        amount=_count(data.get("amount")),
        createdAt=_iso(data.get("createdAt")),
        payeeUid=_text(data.get("payeeUid")),
    )


def _text(value: object) -> str | None:
    if not isinstance(value, str):
        return None
    text = value.strip()
    return text or None


def _count(value: object) -> int:
    if isinstance(value, bool):
        return 0
    if isinstance(value, int):
        return value
    if isinstance(value, float) and value.is_integer():
        return int(value)
    return 0


def _iso(value: object) -> str | None:
    if isinstance(value, str):
        text = value.strip()
        return text or None
    isoformat = getattr(value, "isoformat", None)
    if callable(isoformat):
        return str(isoformat())
    return None


admin_referral_service = AdminReferralService()
