from datetime import datetime, timedelta, timezone
from types import SimpleNamespace

import pytest
from fastapi import HTTPException
from fastapi.testclient import TestClient

from app.main import app
from app.routers import admin_router
from app.services.admin_auth_service import admin_auth_service
from app.services.admin_referral_review_service import AdminReferralReviewService
from app.services.secured_action_service import SecuredActionService
from test_redeem_referral import _MemoryDb

client = TestClient(app)
AUTH = {"Authorization": "Bearer test-token"}
_NOW = datetime(2026, 10, 10, 3, tzinfo=timezone.utc)
_DUE = (_NOW - timedelta(days=1)).isoformat()
_LATER = (_NOW + timedelta(days=3)).isoformat()


@pytest.fixture(autouse=True)
def _memory_transactions(monkeypatch):
    """The memory db has no real transactions: run the in-transaction bodies directly."""
    monkeypatch.setattr(
        SecuredActionService,
        "_commit_settle_copy_review",
        lambda self, tx, review_id, now, due_only: self._settle_copy_review_in_txn(
            tx, review_id, now, due_only
        ),
    )
    monkeypatch.setattr(
        SecuredActionService,
        "_commit_set_copy_review_status",
        lambda self, tx, review_id, expect, new, actor, note: self._set_copy_review_status_in_txn(
            tx, review_id, expect, new, actor, note
        ),
    )


def _db(*, release_at: str = _DUE, status: str = "pending") -> _MemoryDb:
    db = _MemoryDb()
    db.store["users/u1"] = {"wallet": {"shareBalance": 20}}
    db.store["referralPayouts/u1_u2_trial_referrer"] = {"status": "held"}
    db.store["referralReviews/r1"] = {
        "status": status,
        "reason": "copy_review",
        "detail": "straight_slide",
        "amount": 30_000,
        "payeeUid": "u1",
        "refereeUid": "u2",
        "payoutType": "trial_referrer",
        "markerId": "u1_u2_trial_referrer",
        "releaseAt": release_at,
    }
    return db


def _share(db: _MemoryDb) -> int:
    return int(db.store["users/u1"]["wallet"]["shareBalance"])


def _service(db: _MemoryDb) -> AdminReferralReviewService:
    return AdminReferralReviewService(firebase_service=SimpleNamespace(db=db))


def _actions(db: _MemoryDb) -> SecuredActionService:
    return SecuredActionService(firebase_service=SimpleNamespace(db=db))


def test_due_review_pays_once_even_if_the_sweep_runs_twice() -> None:
    db = _db()
    actions = _actions(db)

    assert actions.release_due_copy_reviews(_NOW) == 1
    assert actions.release_due_copy_reviews(_NOW) == 0

    assert _share(db) == 20 + 30_000
    assert db.store["referralReviews/r1"]["status"] == "released"
    assert db.store["referralPayouts/u1_u2_trial_referrer"]["status"] == "released"


def test_a_review_that_is_not_due_is_not_paid() -> None:
    db = _db(release_at=_LATER)

    assert _actions(db).release_due_copy_reviews(_NOW) == 0

    assert _share(db) == 20
    assert db.store["referralReviews/r1"]["status"] == "pending"


def test_reject_keeps_the_hold_and_the_sweep_skips_it() -> None:
    db = _db()
    service = _service(db)

    result = service.decide("r1", "reject", actor_uid="admin1", note="same person")

    assert result.status == "rejected"
    review = db.store["referralReviews/r1"]
    assert review["reviewedBy"] == "admin1"
    assert review["reviewNote"] == "same person"
    assert _actions(db).release_due_copy_reviews(_NOW) == 0
    assert _share(db) == 20


def test_reopen_puts_a_rejection_back_in_the_queue() -> None:
    db = _db(status="rejected")
    service = _service(db)

    assert service.decide("r1", "reopen", actor_uid="admin1", note="").status == "pending"
    assert _actions(db).release_due_copy_reviews(_NOW) == 1
    assert _share(db) == 20 + 30_000


def test_release_now_pays_before_the_date_and_only_once() -> None:
    db = _db(release_at=_LATER)
    service = _service(db)

    result = service.decide("r1", "release", actor_uid="admin1", note="ok")

    assert result.status == "released"
    assert _share(db) == 20 + 30_000
    with pytest.raises(HTTPException) as again:
        service.decide("r1", "release", actor_uid="admin1", note="")
    assert again.value.status_code == 409
    assert _share(db) == 20 + 30_000


def test_decisions_on_the_wrong_status_or_a_missing_review_are_refused() -> None:
    db = _db(status="released")
    service = _service(db)

    with pytest.raises(HTTPException) as reject:
        service.decide("r1", "reject", actor_uid="a", note="")
    assert reject.value.status_code == 409
    with pytest.raises(HTTPException) as missing:
        service.decide("nope", "release", actor_uid="a", note="")
    assert missing.value.status_code == 404
    assert _share(db) == 20


def test_a_review_without_a_user_is_not_paid() -> None:
    db = _db()
    del db.store["users/u1"]

    assert _actions(db).release_due_copy_reviews(_NOW) == 0
    assert db.store["referralReviews/r1"]["status"] == "pending"


def test_list_shows_soonest_release_first() -> None:
    db = _db(release_at=_LATER)
    db.store["referralReviews/r0"] = dict(db.store["referralReviews/r1"], releaseAt=_DUE)

    rows = _service(db).list_reviews(review_status="pending").reviews

    assert [row.id for row in rows] == ["r0", "r1"]
    assert rows[0].amount == 30_000 and rows[0].payeeUid == "u1"
    with pytest.raises(HTTPException):
        _service(db).list_reviews(review_status="nonsense")


def _as_admin(monkeypatch, db: _MemoryDb) -> list[dict]:
    monkeypatch.setattr(
        admin_auth_service,
        "require_admin",
        lambda _header: {"uid": "admin1", "email": "a@example.com"},
    )
    monkeypatch.setattr(admin_router, "admin_referral_review_service", _service(db))
    logs: list[dict] = []
    monkeypatch.setattr(
        admin_router.admin_audit_service,
        "write",
        lambda **kwargs: logs.append(kwargs) or "log1",
    )
    return logs


def test_admin_api_lists_and_decides_with_an_audit_log(monkeypatch) -> None:
    db = _db()
    logs = _as_admin(monkeypatch, db)

    listed = client.get("/admin/referral-reviews", headers=AUTH)
    assert listed.status_code == 200
    assert listed.json()["reviews"][0]["id"] == "r1"

    decided = client.post(
        "/admin/referral-reviews/r1/decision",
        headers=AUTH,
        json={"decision": "reject", "note": "twin"},
    )
    assert decided.status_code == 200
    assert decided.json() == {"id": "r1", "status": "rejected"}
    assert logs[0]["action"] == "referral_review_reject"
    assert "r1" in logs[0]["reason"]

    conflict = client.post(
        "/admin/referral-reviews/r1/decision",
        headers=AUTH,
        json={"decision": "reject", "note": ""},
    )
    assert conflict.status_code == 409


def test_admin_api_needs_an_admin() -> None:
    assert client.get("/admin/referral-reviews").status_code in (401, 403)
    assert (
        client.post(
            "/admin/referral-reviews/r1/decision", json={"decision": "release"}
        ).status_code
        in (401, 403, 422)
    )


def test_ops_release_route_needs_the_ops_secret(monkeypatch) -> None:
    monkeypatch.setenv("OPS_ADMIN_SECRET", "ops-secret")

    assert client.post("/ops/referral-reviews/release-due").status_code == 401
    wrong = client.post(
        "/ops/referral-reviews/release-due", headers={"X-Ops-Admin-Secret": "nope"}
    )
    assert wrong.status_code == 401


def test_ops_release_route_pays_what_is_due(monkeypatch) -> None:
    from app.routers import ops_router

    db = _db()
    monkeypatch.setenv("OPS_ADMIN_SECRET", "ops-secret")
    monkeypatch.setattr(
        ops_router, "service", SimpleNamespace(firebase_service=SimpleNamespace(db=db))
    )

    first = client.post(
        "/ops/referral-reviews/release-due", headers={"X-Ops-Admin-Secret": "ops-secret"}
    )
    again = client.post(
        "/ops/referral-reviews/release-due", headers={"X-Ops-Admin-Secret": "ops-secret"}
    )

    assert first.status_code == 200 and first.json()["released"] == 1
    assert again.json()["released"] == 0
    assert _share(db) == 20 + 30_000
