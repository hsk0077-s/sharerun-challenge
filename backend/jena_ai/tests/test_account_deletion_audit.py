"""Account deletion audit: what delete_account and the later purge remove, and what stays.

Runs on an in-memory Firestore stand-in with TEST data only. Nothing here touches a real
project. The "stays" assertions document today's behaviour (see docs/account-deletion-audit.md);
they are not a statement that staying is correct — several need an owner decision.
"""

from __future__ import annotations

from unittest.mock import MagicMock, patch

import pytest
from fastapi import HTTPException
from google.cloud import firestore

from app.services import identities
from app.services.ops_service import OpsService
from app.services.secured_action_service import SecuredActionService

DELETE = firestore.DELETE_FIELD


class _Snap:
    def __init__(self, db, path):
        self.id = path.rsplit("/", 1)[-1]
        self._db, self._path = db, path
        self.exists = path in db.docs
        self.reference = _Doc(db, path)

    def to_dict(self):
        return dict(self._db.docs[self._path]) if self.exists else None


class _Doc:
    def __init__(self, db, path):
        self.db, self.path = db, path
        self.id = path.rsplit("/", 1)[-1]

    def get(self):
        return _Snap(self.db, self.path)

    def set(self, data, merge=False):
        self.db.maybe_fail("set", self.path)
        row = self.db.docs.get(self.path, {}) if merge else {}
        row = dict(row)
        for key, value in data.items():
            if value is DELETE:
                row.pop(key, None)
            elif isinstance(value, dict) and isinstance(row.get(key), dict) and merge:
                row[key] = {**row[key], **value}
            else:
                row[key] = value
        self.db.docs[self.path] = row

    def delete(self):
        self.db.maybe_fail("delete", self.path)
        self.db.docs.pop(self.path, None)

    def collection(self, name):
        return _Coll(self.db, f"{self.path}/{name}")


class _Coll:
    def __init__(self, db, path, filters=(), max_rows=None):
        self.db, self.path, self.filters, self.max_rows = db, path, tuple(filters), max_rows

    def document(self, doc_id=None):
        return _Doc(self.db, f"{self.path}/{doc_id or 'auto'}")

    def where(self, field, op, value):
        assert op == "=="
        return _Coll(self.db, self.path, self.filters + ((field, value),), self.max_rows)

    def limit(self, count):
        return _Coll(self.db, self.path, self.filters, count)

    def get(self):
        depth = self.path.count("/") + 1
        rows = [
            _Snap(self.db, p)
            for p, row in list(self.db.docs.items())
            if p.startswith(self.path + "/")
            and p.count("/") + 1 == depth + 1
            and all(row.get(f) == v for f, v in self.filters)
        ]
        return rows[: self.max_rows] if self.max_rows else rows

    stream = get


class FakeDb:
    def __init__(self):
        self.docs: dict[str, dict] = {}
        self.fail_on: tuple[str, str] | None = None
        self.fail_times = 0

    def collection(self, name):
        return _Coll(self, name)

    def maybe_fail(self, op, path):
        if self.fail_on and self.fail_on[0] == op and self.fail_on[1] in path and self.fail_times > 0:
            self.fail_times -= 1
            raise RuntimeError("injected failure")

    def under(self, prefix):
        return sorted(p for p in self.docs if p.startswith(prefix))


UID = "uid-test-1"
OTHER = "uid-test-2"


def _seed(db: FakeDb, uid: str = UID) -> None:
    db.docs.update(
        {
            f"users/{uid}": {
                "uid": uid, "accountStatus": "active", "nickname": "달팽이", "email": "t@example.test",
                "gender": "f", "fcmToken": "tok", "connectedDeviceType": "phone",
                "wallet": {"shareBalance": 5, "diamondBalance": 7, "valueTokenBalance": 1, "totalDonationValue": 2},
            },
            f"users/{uid}/watchDevices/w1": {"x": 1},
            f"users/{uid}/daily_metrics/2026-11-01": {"steps": 10, "model": "SM-test"},
            f"users/{uid}/notifications/n1": {"t": 1},
            f"users/{uid}/retentionPushes/r1": {"t": 1},
            f"users/{uid}/loginDevices/d1": {"model": "SM-test"},
            f"users/{uid}/collectedDiamondBoxes/b1": {"t": 1},
            f"users/{uid}/prizeTickets/p1": {"t": 1},
            f"users/{uid}/companyPrizeRace/state": {"t": 1},
            f"users/{uid}/shopInventory/cpr": {"n": 1},
            f"activities/a1": {"userId": uid, "distanceKm": 3},
            f"activities/a2": {"userId": OTHER, "distanceKm": 5},
            f"walletTransactions/t1": {"uid": uid, "amount": 5},
            f"playPurchases/o1": {"uid": uid, "orderId": "GPA.test"},
            f"crews/c1/members/{uid}": {"role": "member"},
            f"reports/{uid}_run_a1": {"uid": uid},
            identities.IDENTITIES + "/kakao:123": {"uid": uid, "provider": "kakao"},
            identities.IDENTITIES + "/apple:abc": {"uid": uid, "provider": "apple"},
        }
    )
    db.docs[f"users/{OTHER}"] = {"uid": OTHER, "accountStatus": "active", "nickname": "other"}


def _delete(db: FakeDb, uid: str = UID, auth=None):
    service = SecuredActionService(firebase_service=MagicMock())
    service.firebase_service.db = db
    with patch("app.services.secured_action_service.firebase_auth.delete_user", auth or MagicMock()) as mock:
        result = service.delete_account(uid)
    return result, mock


def _ops(db: FakeDb) -> OpsService:
    service = OpsService(firebase_service=MagicMock())
    service.firebase_service.db = db
    return service


@pytest.fixture()
def db():
    fake = FakeDb()
    _seed(fake)
    return fake


# ---------- stage 1: POST /actions/account/delete ----------

def test_delete_now_removes_login_push_watch_wallet_and_identity_links(db) -> None:
    result, auth = _delete(db)
    assert result.status == "deleted"
    auth.assert_called_once_with(UID)
    user = db.docs[f"users/{UID}"]
    assert user["accountStatus"] == "deleted" and "fcmToken" not in user
    assert user["wallet"] == {"shareBalance": 0, "diamondBalance": 0, "valueTokenBalance": 0, "totalDonationValue": 0}
    assert db.under(f"users/{UID}/watchDevices") == []
    assert not [p for p in db.docs if p.startswith(identities.IDENTITIES) and db.docs[p].get("uid") == UID]
    # reward tombstone hashes are written for the two identities
    assert len(db.under(identities.REWARD_TOMBSTONES)) == 2


def test_delete_leaves_these_until_the_purge_or_forever(db) -> None:
    """Documents today's behaviour. See docs/account-deletion-audit.md for who decides."""
    _delete(db)
    user = db.docs[f"users/{UID}"]
    assert user["nickname"] == "달팽이" and user["email"] == "t@example.test"  # until purge
    assert "activities/a1" in db.docs  # until purge
    assert "walletTransactions/t1" in db.docs and "playPurchases/o1" in db.docs  # ledgers
    assert f"crews/c1/members/{UID}" in db.docs  # delete_account never leaves the crew
    assert f"reports/{UID}_run_a1" in db.docs
    assert "users/uid-test-1/prizeTickets/p1" in db.docs  # not in the purge list either


def test_delete_does_not_touch_other_users(db) -> None:
    _delete(db)
    assert db.docs[f"users/{OTHER}"]["accountStatus"] == "active"
    assert "activities/a2" in db.docs


def test_delete_unknown_user_is_404(db) -> None:
    with pytest.raises(HTTPException) as error:
        _delete(db, uid="nobody")
    assert error.value.status_code == 404


def test_delete_can_be_repeated_after_an_auth_failure(db) -> None:
    """Firestore is anonymized first; if Firebase Auth fails the call errors and a retry finishes."""
    failing = MagicMock(side_effect=RuntimeError("auth down"))
    with pytest.raises(RuntimeError):
        _delete(db, auth=failing)
    # half done: profile anonymized, identity links still there
    assert db.docs[f"users/{UID}"]["accountStatus"] == "deleted"
    assert any(p.startswith(identities.IDENTITIES) for p in db.docs)
    result, _ = _delete(db)
    assert result.status == "deleted"
    assert not [p for p in db.docs if p.startswith(identities.IDENTITIES) and db.docs[p].get("uid") == UID]


def test_delete_twice_is_harmless(db) -> None:
    _delete(db)
    result, _ = _delete(db)
    assert result.status == "deleted"
    assert db.docs[f"users/{UID}"]["accountStatus"] == "deleted"


# ---------- stage 2: POST /ops/users/purge-deleted ----------

def test_purge_refuses_an_account_that_was_not_deleted(db) -> None:
    with pytest.raises(HTTPException) as error:
        _ops(db).purge_user_data(UID)
    assert error.value.status_code == 400


def test_purge_removes_personal_records_and_keeps_ledgers(db) -> None:
    _delete(db)
    result = _ops(db).purge_user_data(UID)
    assert result.status == "purged" and result.deleted_activities == 1
    user = db.docs[f"users/{UID}"]
    assert user["accountStatus"] == "purged"
    for gone in ("nickname", "email", "gender", "connectedDeviceType", "fcmToken"):
        assert gone not in user
    assert "activities/a1" not in db.docs and "activities/a2" in db.docs
    for prefix in ("daily_metrics", "notifications", "retentionPushes", "loginDevices", "collectedDiamondBoxes", "watchDevices"):
        assert db.under(f"users/{UID}/{prefix}") == []
    # kept on purpose (ledgers) or not covered by the purge today
    assert "walletTransactions/t1" in db.docs and "playPurchases/o1" in db.docs
    assert f"crews/c1/members/{UID}" in db.docs
    assert "users/uid-test-1/prizeTickets/p1" in db.docs
    assert "users/uid-test-1/shopInventory/cpr" in db.docs
    assert f"reports/{UID}_run_a1" in db.docs


def test_purge_twice_is_refused_not_repeated(db) -> None:
    """The "already_purged" branch in purge_user_data is unreachable: status is "purged" by then."""
    _delete(db)
    _ops(db).purge_user_data(UID)
    with pytest.raises(HTTPException) as error:
        _ops(db).purge_user_data(UID)
    assert error.value.status_code == 400


def test_purge_failure_midway_leaves_it_retryable_and_not_marked_purged(db) -> None:
    _delete(db)
    db.fail_on, db.fail_times = ("delete", "activities/a1"), 1
    with pytest.raises(RuntimeError):
        _ops(db).purge_user_data(UID)
    assert db.docs[f"users/{UID}"]["accountStatus"] == "deleted"  # not marked purged
    assert _ops(db).purge_user_data(UID).status == "purged"  # retry finishes
    assert "activities/a1" not in db.docs


def test_batch_continues_past_one_failing_account(db) -> None:
    db.docs["users/uid-test-3"] = {"uid": "uid-test-3", "accountStatus": "active", "nickname": "third"}
    db.docs["activities/a3"] = {"userId": "uid-test-3"}
    _delete(db, UID)
    _delete(db, "uid-test-3")
    db.fail_on, db.fail_times = ("delete", "activities/a1"), 1_000  # the first user's activity can never be deleted
    result = _ops(db).purge_deleted_accounts()
    assert result.status == "completed"
    statuses = {uid: db.docs[f"users/{uid}"]["accountStatus"] for uid in (UID, "uid-test-3")}
    assert statuses["uid-test-3"] == "purged" and statuses[UID] == "deleted"
