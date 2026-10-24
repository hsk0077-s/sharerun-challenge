from types import SimpleNamespace

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.services.admin_audit_service import admin_audit_service
from app.services.admin_auth_service import admin_auth_service
from app.services.admin_user_detail_service import admin_user_detail_service

client = TestClient(app)
AUTH = {"Authorization": "Bearer test-token"}


class Snap:
    def __init__(self, doc_id: str, data: dict | None) -> None:
        self.id = doc_id
        self.exists = data is not None
        self._data = data

    def to_dict(self) -> dict | None:
        return None if self._data is None else dict(self._data)


class Doc:
    def __init__(self, db: "Db", path: str) -> None:
        self.db = db
        self.path = path

    def get(self) -> Snap:
        self.db.reads += 1
        return Snap(self.path.rsplit("/", 1)[-1], self.db.docs.get(self.path))


class Query:
    def __init__(self, db: "Db", name: str, uid: str) -> None:
        self.db = db
        self.name = name
        self.uid = uid

    def get(self) -> list[Snap]:
        prefix = f"{self.name}/"
        return [
            Snap(path[len(prefix) :], data)
            for path, data in self.db.docs.items()
            if path.startswith(prefix) and data.get("uid") == self.uid
        ]


class Collection:
    def __init__(self, db: "Db", name: str) -> None:
        self.db = db
        self.name = name

    def document(self, doc_id: str) -> Doc:
        return Doc(self.db, f"{self.name}/{doc_id}")

    def where(self, field: str, _op: str, value: str) -> Query:
        assert field == "uid"
        return Query(self.db, self.name, value)


class Db:
    def __init__(self, docs: dict[str, dict]) -> None:
        self.docs = docs
        self.reads = 0

    def collection(self, name: str) -> Collection:
        return Collection(self, name)


@pytest.fixture(autouse=True)
def reset(monkeypatch):
    admin_auth_service._verify_token = None
    admin_auth_service._admin_doc_exists = None
    admin_user_detail_service.firebase_service = None
    audits: list[dict] = []
    monkeypatch.setattr(
        admin_audit_service, "write", lambda **kwargs: audits.append(kwargs) or "log-1"
    )
    yield audits
    admin_auth_service._verify_token = None
    admin_auth_service._admin_doc_exists = None
    admin_user_detail_service.firebase_service = None


def _admin() -> None:
    admin_auth_service._verify_token = lambda _token: {
        "uid": "admin-1",
        "email": "admin@share-run-challenge.app",
        "email_verified": True,
    }
    admin_auth_service._admin_doc_exists = lambda _uid: False


def _bind(docs: dict[str, dict]) -> Db:
    db = Db(docs)
    admin_user_detail_service.firebase_service = SimpleNamespace(db=db)
    return db


def test_missing_token_is_401() -> None:
    db = _bind({})

    assert client.get("/admin/user-detail", params={"uid": "u1"}).status_code == 401
    assert db.reads == 0


def test_non_admin_is_403() -> None:
    admin_auth_service._verify_token = lambda _token: {"uid": "r", "email": "r@example.com"}
    admin_auth_service._admin_doc_exists = lambda _uid: False
    db = _bind({})

    response = client.get("/admin/user-detail", headers=AUTH, params={"uid": "u1"})

    assert response.status_code == 403
    assert db.reads == 0


def test_full_detail(reset) -> None:
    _admin()
    _bind(
        {
            "users/u1": {
                "nickname": "runner",
                "email": "u1@example.com",
                "countryCode": "KR",
                "locale": "en_US",
                "crewId": "c1",
            },
            "crews/c1": {"name": "dawn-crew"},
            "authIdentities/kakao:aaa": {"uid": "u1", "provider": "kakao"},
            "authIdentities/google:bbb": {"uid": "u1", "provider": "google"},
            "authIdentities/naver:ccc": {"uid": "u2", "provider": "naver"},
            "rewardBlocks/u1": {
                "reason": "returning_identity",
                "createdAt": "2026-10-01T00:00:00+00:00",
            },
        }
    )

    response = client.get("/admin/user-detail", headers=AUTH, params={"uid": "u1"})

    assert response.status_code == 200
    assert response.json() == {
        "uid": "u1",
        "nickname": "runner",
        "email": "u1@example.com",
        "country": "KR",
        "providers": ["google", "kakao"],
        "rewardBlocked": True,
        "rewardBlockReason": "returning_identity",
        "rewardBlockedAt": "2026-10-01T00:00:00+00:00",
        "crew": {"id": "c1", "name": "dawn-crew"},
    }
    assert reset[0]["action"] == "user_detail_lookup"
    assert reset[0]["target_uid"] == "u1"


def test_locale_is_the_last_country_fallback_and_crew_name_is_used() -> None:
    _admin()
    _bind({"users/u1": {"nickname": "runner", "locale": "ja_JP", "crewId": "c9", "crewName": "named"}})

    body = client.get("/admin/user-detail", headers=AUTH, params={"uid": "u1"}).json()

    assert body["country"] == "ja_JP"
    assert body["providers"] == []
    assert body["rewardBlocked"] is False
    assert body["rewardBlockReason"] is None
    assert body["crew"] == {"id": "c9", "name": "named"}


def test_no_country_no_crew() -> None:
    _admin()
    _bind({"users/u1": {"nickname": "runner"}})

    body = client.get("/admin/user-detail", headers=AUTH, params={"uid": "u1"}).json()

    assert body["country"] is None
    assert body["crew"] is None


def test_unknown_user_is_404_and_bad_uid_is_400() -> None:
    _admin()
    _bind({})

    assert client.get("/admin/user-detail", headers=AUTH, params={"uid": "nope"}).status_code == 404
    assert client.get("/admin/user-detail", headers=AUTH, params={"uid": "a/b"}).status_code == 400
