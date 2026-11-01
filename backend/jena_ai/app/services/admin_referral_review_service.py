from datetime import datetime, timezone

from fastapi import HTTPException, status

from app.models.admin_api import (
    ReferralReviewDecisionResult,
    ReferralReviewListResult,
    ReferralReviewRow,
)
from app.services.firebase_service import FirebaseService
from app.services.secured_action_service import SecuredActionService

STATUSES = ("pending", "rejected", "released")
DEFAULT_LIMIT = 100
MAX_LIMIT = 200


class AdminReferralReviewService:
    """The copy-review queue: referral SHARE held for seven days.

    A pending review pays out by itself once ``releaseAt`` passes. An admin can
    reject it (keep the hold), reopen a rejection, or pay it right away.
    """

    def __init__(self, firebase_service: FirebaseService | None = None) -> None:
        self.firebase_service = firebase_service

    def _db(self):
        return (self.firebase_service or FirebaseService()).db

    def _actions(self) -> SecuredActionService:
        return SecuredActionService(firebase_service=self.firebase_service)

    def list_reviews(
        self, *, review_status: str = "pending", limit: int = DEFAULT_LIMIT
    ) -> ReferralReviewListResult:
        if review_status not in STATUSES:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid status."
            )
        size = max(1, min(int(limit), MAX_LIMIT))
        docs = (
            self._db()
            .collection("referralReviews")
            .where("status", "==", review_status)
            .limit(size)
            .get()
        )
        rows = [_row(doc.id, doc.to_dict() or {}) for doc in docs]
        # Soonest release first; reviews with no date go last.
        rows.sort(key=lambda row: (row.releaseAt is None, row.releaseAt or ""))
        return ReferralReviewListResult(reviews=rows)

    def decide(
        self, review_id: str, decision: str, *, actor_uid: str, note: str
    ) -> ReferralReviewDecisionResult:
        actions = self._actions()
        if decision == "release":
            outcome = actions.settle_copy_review(
                review_id, datetime.now(timezone.utc), due_only=False
            )
        elif decision == "reject":
            outcome = actions.reject_copy_review(
                review_id, actor_uid=actor_uid, note=note
            )
        else:
            outcome = actions.reopen_copy_review(
                review_id, actor_uid=actor_uid, note=note
            )
        expected = {"release": "released", "reject": "rejected", "reopen": "pending"}
        if outcome == "not_found":
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Review not found."
            )
        if outcome != expected[decision]:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Cannot {decision} a review that is {outcome}.",
            )
        return ReferralReviewDecisionResult(id=review_id, status=outcome)


def _row(review_id: str, data: dict) -> ReferralReviewRow:
    amount = data.get("amount")
    return ReferralReviewRow(
        id=review_id,
        status=str(data.get("status") or ""),
        reason=_text(data.get("reason")),
        detail=_text(data.get("detail")),
        amount=amount if isinstance(amount, int) and not isinstance(amount, bool) else 0,
        payeeUid=_text(data.get("payeeUid")),
        refereeUid=_text(data.get("refereeUid")),
        payoutType=_text(data.get("payoutType")),
        releaseAt=_iso(data.get("releaseAt")),
        createdAt=_iso(data.get("createdAt")),
        reviewedBy=_text(data.get("reviewedBy")),
        reviewNote=_text(data.get("reviewNote")),
    )


def _text(value: object) -> str | None:
    return value if isinstance(value, str) and value else None


def _iso(value: object) -> str | None:
    if isinstance(value, str):
        return value or None
    to_dt = getattr(value, "isoformat", None)
    if callable(to_dt):
        try:
            return to_dt()
        except (TypeError, ValueError):
            return None
    return None


admin_referral_review_service = AdminReferralReviewService()
