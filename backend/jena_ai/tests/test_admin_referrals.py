from types import SimpleNamespace

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.services.admin_auth_service import admin_auth_service
from app.services.admin_referral_service import admin_referral_service

client = TestClient(app)
AUTH = {"Authorization": "Bearer test-token"}


class MemorySnap:
    def __init__(self, doc_id: str, data: dict | None) -> None:
        self.id = doc_id
        self.exists = data is not None
        self._data = data

    def to_dict(self) -> dict | None:
        return None if self._data is None else dict(self._data)


class MemoryDoc:
    def __init__(self, db: "MemoryDb", path: str) -> None:
        self.db = db
        self.path = path
        self.id = path.rsplit("/", 1)[-1]

    def get(self) -> MemorySnap:
        return MemorySnap(self.id, self.db.docs.get(self.path))


class MemoryQuery:
    def __init__(self, db: "MemoryDb", name: str) -> None:
        self.db = db
        self.name = name
        self._limit: int | None = None
        self._cursor: str | None = None

    def order_by(self, *_args, **_kwargs) -> "MemoryQuery":
        return self

    def limit(self, count: int) -> "MemoryQuery":
        self._limit = count
        return self

    def start_after(self, values) -> "MemoryQuery":
        ref = values[0]
        self._cursor = ref.id
        return self

    def stream(self) -> list[MemorySnap]:
        prefix = f"{self.name}/"
        ids = sorted(
            path[len(prefix) :]
            for path in self.db.docs
            if path.startswith(prefix) and "/" not in path[len(prefix) :]
        )
        if self._cursor is not None:
            ids = [doc_id for doc_id in ids if doc_id > self._cursor]
        if self._limit is not None:
            ids = ids[: self._limit]
        return [MemorySnap(doc_id, self.db.docs[f"{self.name}/{doc_id}"]) for doc_id in ids]


class MemoryCollection:
    def __init__(self, db: "MemoryDb", name: str) -> None:
        self.db = db
        self.name = name

    def document(self, doc_id: str) -> MemoryDoc:
        return MemoryDoc(self.db, f"{self.name}/{doc_id}")

    def order_by(self, *args, **kwargs) -> MemoryQuery:
        return MemoryQuery(self.db, self.name).order_by(*args, **kwargs)


class MemoryDb:
    def __init__(self, docs: dict[str, dict]) -> None:
        self.docs = docs
        self.reads = 0

    def collection(self, name: str) -> MemoryCollection:
        self.reads += 1
        return MemoryCollection(self, name)

    def get_all(self, refs) -> list[MemorySnap]:
        self.reads += 1
        return [ref.get() for ref in refs]


@pytest.fixture(autouse=True)
def reset_admin() -> None:
    admin_auth_service._verify_token = None
    admin_auth_service._admin_doc_exists = None
    admin_referral_service.firebase_service = None
    yield
    admin_auth_service._verify_token = None
    admin_auth_service._admin_doc_exists = None
    admin_referral_service.firebase_service = None


def _admin() -> None:
    admin_auth_service._verify_token = lambda _token: {
        "uid": "admin-1",
        "email": "admin@share-run-challenge.app",
    }
    admin_auth_service._admin_doc_exists = lambda _uid: False


def _bind(docs: dict[str, dict]) -> MemoryDb:
    db = MemoryDb(docs)
    admin_referral_service.firebase_service = SimpleNamespace(db=db)
    return db


def test_referrals_missing_token_is_401() -> None:
    db = _bind({})

    response = client.get("/admin/referrals")

    assert response.status_code == 401
    assert db.reads == 0


def test_referrals_non_admin_is_403() -> None:
    admin_auth_service._verify_token = lambda _token: {
        "uid": "runner",
        "email": "runner@example.com",
    }
    admin_auth_service._admin_doc_exists = lambda _uid: False
    db = _bind({})

    response = client.get("/admin/referrals", headers=AUTH)

    assert response.status_code == 403
    assert db.reads == 0


def test_referrals_shape_and_payout_markers() -> None:
    _admin()
    db = _bind(
        {
            "users/b": {
                "economy": {
                    "referralCode": "AB23CD45",
                    "referredBy": "a",
                    "trialRunCount": 2,
                    "referralPayoutCount": 1,
                }
            },
            "users/c": {
                "economy": {
                    "referredByUid": "b",
                    "trialRunCount": 5,
                    "referralPayoutCount": 10,
                }
            },
            "referralPayouts/b_redeem": {
                "amount": 1000,
                "createdAt": "2024-05-01T00:00:00+00:00",
                "payeeUid": "b",
            },
            "referralPayouts/b_trial_referee": {
                "amount": 5000,
                "createdAt": "2024-05-02T00:00:00+00:00",
                "payeeUid": "b",
            },
            "referralPayouts/b_trial_referrer": {
                "amount": 3000,
                "createdAt": "2024-05-03T00:00:00+00:00",
                "payeeUid": "a",
            },
        }
    )

    response = client.get("/admin/referrals", headers=AUTH)

    assert response.status_code == 200
    body = response.json()
    assert body["limit"] == 40
    assert body["nextCursor"] is None
    by_uid = {row["uid"]: row for row in body["users"]}
    assert by_uid["b"]["referralCode"] == "AB23CD45"
    assert by_uid["b"]["referredBy"] == "a"
    assert by_uid["b"]["referredByUid"] is None
    assert by_uid["b"]["trialRunCount"] == 2
    assert by_uid["b"]["trialRunsRequired"] == 3
    assert by_uid["b"]["referralPayoutCount"] == 1
    assert by_uid["b"]["referralPayoutMax"] == 10
    assert by_uid["b"]["payouts"]["redeem"] == {
        "amount": 1000,
        "createdAt": "2024-05-01T00:00:00+00:00",
        "payeeUid": "b",
    }
    assert by_uid["b"]["payouts"]["trial_referee"]["amount"] == 5000
    assert by_uid["b"]["payouts"]["trial_referrer"]["amount"] == 3000
    assert by_uid["c"]["referralCode"] is None
    assert by_uid["c"]["referredBy"] is None
    assert by_uid["c"]["referredByUid"] == "b"
    assert by_uid["c"]["payouts"] == {
        "redeem": None,
        "trial_referee": None,
        "trial_referrer": None,
    }
    assert db.reads > 0


def test_referrals_paginates_by_user_id() -> None:
    _admin()
    _bind(
        {
            "users/a": {"economy": {}},
            "users/b": {"economy": {"referralCode": "CODE"}},
            "users/c": {"economy": {}},
        }
    )

    first = client.get("/admin/referrals?limit=2", headers=AUTH)
    assert first.status_code == 200
    page = first.json()
    assert [row["uid"] for row in page["users"]] == ["a", "b"]
    assert page["nextCursor"] == "b"

    second = client.get(
        "/admin/referrals",
        headers=AUTH,
        params={"limit": 2, "cursor": page["nextCursor"]},
    )
    assert second.status_code == 200
    assert [row["uid"] for row in second.json()["users"]] == ["c"]
    assert second.json()["nextCursor"] is None
