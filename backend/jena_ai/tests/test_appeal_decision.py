"""An admin decides an appeal. Approval settles the run once, like a verified one."""

from datetime import datetime, timezone
from types import SimpleNamespace

import pytest
from fastapi import HTTPException

from app.services import appeals, secured_action_service
from app.services.secured_action_service import SecuredActionService
from test_redeem_referral import _MemoryDb, _MemoryTxn

NOW = datetime(2026, 10, 14, 3, 0, tzinfo=timezone.utc)
RUN_DAY = datetime(2026, 10, 12, 1, 0, tzinfo=timezone.utc)
APPEAL = "appeal-act-1"
ROUTE = [{"lat": 37.5, "lng": 127.0}, {"lat": 37.51, "lng": 127.01}]


class _Db(_MemoryDb):
    def batch(self):
        txn = _MemoryTxn()

        class _Batch:
            def set(self, ref, data, merge=False):
                txn.set(ref, data, merge=merge)

            def delete(self, ref):
                txn.delete(ref)

            def commit(self):
                return None

        return _Batch()


def _service(db: _Db) -> SecuredActionService:
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))
    service._auth_account_created_at = lambda uid: None
    return service


@pytest.fixture(autouse=True)
def _memory_transaction(monkeypatch):
    """The real wrapper needs a Firestore transaction. Run the body on the memory one."""

    def commit(
        _txn, service, uid, request, result, activity_ref, user_ref, appeal,
        account_created_at=None, now=None,
    ):
        return service._persist_validation_tx(
            _MemoryTxn(), uid, request, result, activity_ref, user_ref,
            account_created_at=account_created_at, now=now, appeal=appeal,
        )

    monkeypatch.setattr(secured_action_service, "_commit_appeal_approval_tx", commit)


def _seed(db: _Db, status: str = "under_review") -> None:
    db.store["users/u1"] = {
        "nickname": "달림이",
        "wallet": {"shareBalance": 5, "diamondBalance": 1, "valueTokenBalance": 0},
    }
    db.store["activities/act-1"] = {
        "userId": "u1",
        "distanceKm": 5.0,
        "durationSeconds": 1800,
        "gyroStabilityScore": 0.8,
        "gpsRoute": ROUTE,
        "jenaVerified": False,
        "jenaDecision": "rejected_unknown",
        "jenaReason": "케이던스가 범위 밖입니다.",
        "validationFinalized": True,
        "depositForfeited": False,
        "completedAt": RUN_DAY,
        "appealStatus": status,
        "appealId": APPEAL,
        "locked": True,
    }
    db.store[f"appeals/{APPEAL}"] = {
        "appealId": APPEAL,
        "userId": "u1",
        "activityId": "act-1",
        "status": status,
    }
    db.store[f"appealProofs/{APPEAL}"] = {
        "userId": "u1",
        "contentType": "image/jpeg",
        "bytes": b"\xff\xd8\xffphoto",
    }


def _donations(db: _Db) -> list[str]:
    return [path for path in db.store if path.startswith("donationLedger/")]


def test_approval_settles_the_run_once_and_keeps_its_day() -> None:
    db = _Db()
    _seed(db)
    service = _service(db)

    outcome = service.approve_appeal(APPEAL, actor_uid="admin1", note="영상 확인", now=NOW)

    assert outcome == {"status": "approved", "appeal_id": APPEAL}
    run = db.store["activities/act-1"]
    assert run["jenaVerified"] is True
    assert run["jenaDecision"] == "verified"
    assert run["appealStatus"] == "approved"
    assert run["locked"] is False
    assert run["completedAt"] == RUN_DAY
    assert run["gpsRoute"] == ROUTE
    assert run["appealPriorDecision"] == "rejected_unknown"
    assert run["donationCounted"] is True
    assert run["companyDonationWon"] == 500
    assert _donations(db) == ["donationLedger/verified_run_act-1"]
    assert db.store["donationLedger/verified_run_act-1"]["companyWon"] == 500
    assert db.store["donationMonthTotals/2026-10"]["totalWon"] == 500
    appeal = db.store[f"appeals/{APPEAL}"]
    assert appeal["status"] == "approved"
    assert appeal["decidedBy"] == "admin1"
    assert appeal["adminNote"] == "영상 확인"
    assert f"appealProofs/{APPEAL}" not in db.store

    wallet = db.store["users/u1"]["wallet"]
    value_after = wallet["valueTokenBalance"]
    share_after = wallet["shareBalance"]

    again = service.approve_appeal(APPEAL, actor_uid="admin2", now=NOW)
    assert again["already"] is True
    assert _donations(db) == ["donationLedger/verified_run_act-1"]
    assert db.store["donationMonthTotals/2026-10"]["totalWon"] == 500
    assert db.store["users/u1"]["wallet"]["valueTokenBalance"] == value_after
    assert db.store["users/u1"]["wallet"]["shareBalance"] == share_after


def test_rejection_keeps_the_run_unaccepted_and_deletes_the_proof() -> None:
    db = _Db()
    _seed(db)

    outcome = appeals.reject_appeal(db, APPEAL, actor_uid="admin1", note="증빙 부족")

    assert outcome == {"status": "rejected", "appeal_id": APPEAL}
    run = db.store["activities/act-1"]
    assert run["jenaVerified"] is False
    assert run["appealStatus"] == "rejected"
    assert run["locked"] is False
    assert _donations(db) == []
    appeal = db.store[f"appeals/{APPEAL}"]
    assert appeal["status"] == "rejected"
    assert appeal["decidedBy"] == "admin1"
    assert appeal["adminNote"] == "증빙 부족"
    assert f"appealProofs/{APPEAL}" not in db.store

    assert appeals.reject_appeal(db, APPEAL, actor_uid="admin2")["already"] is True


def test_a_decided_appeal_cannot_be_flipped() -> None:
    db = _Db()
    _seed(db)
    appeals.reject_appeal(db, APPEAL, actor_uid="admin1")
    with pytest.raises(HTTPException) as raised:
        _service(db).approve_appeal(APPEAL, actor_uid="admin1", now=NOW)
    assert raised.value.status_code == 409
    assert db.store["activities/act-1"]["jenaVerified"] is False
    assert _donations(db) == []

    db2 = _Db()
    _seed(db2)
    _service(db2).approve_appeal(APPEAL, actor_uid="admin1", now=NOW)
    with pytest.raises(HTTPException) as raised:
        appeals.reject_appeal(db2, APPEAL, actor_uid="admin1")
    assert raised.value.status_code == 409
    assert db2.store["activities/act-1"]["appealStatus"] == "approved"


def test_unknown_appeal_is_not_found() -> None:
    db = _Db()
    with pytest.raises(HTTPException) as raised:
        _service(db).approve_appeal("appeal-none", actor_uid="admin1", now=NOW)
    assert raised.value.status_code == 404
    with pytest.raises(HTTPException) as raised:
        appeals.reject_appeal(db, "appeal-none", actor_uid="admin1")
    assert raised.value.status_code == 404


def test_proof_is_readable_until_the_decision_then_gone() -> None:
    db = _Db()
    _seed(db)
    data, content_type = appeals.get_proof(db, APPEAL)
    assert data == b"\xff\xd8\xffphoto"
    assert content_type == "image/jpeg"

    appeals.reject_appeal(db, APPEAL, actor_uid="admin1")
    with pytest.raises(HTTPException) as raised:
        appeals.get_proof(db, APPEAL)
    assert raised.value.status_code == 404


def test_admin_routes_need_an_admin_token() -> None:
    from fastapi.testclient import TestClient

    from app.main import app

    client = TestClient(app)
    assert client.get(f"/admin/appeals/{APPEAL}/proof").status_code == 401
    response = client.post(
        f"/admin/appeals/{APPEAL}/decision", json={"decision": "approved"}
    )
    assert response.status_code == 401
