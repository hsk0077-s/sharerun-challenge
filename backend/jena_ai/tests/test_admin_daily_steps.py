from datetime import datetime, timezone
from types import SimpleNamespace

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.services.admin_auth_service import admin_auth_service
from app.services.admin_daily_steps_service import admin_daily_steps_service

client = TestClient(app)
AUTH = {"Authorization": "Bearer test-token"}


class MemorySnap:
    def __init__(self, doc_id: str, path: str, data: dict) -> None:
        self.id = doc_id
        self.reference = SimpleNamespace(path=path, id=doc_id)
        self.exists = True
        self._data = data

    def to_dict(self) -> dict:
        return dict(self._data)


class MemoryDoc:
    def __init__(self, db: "MemoryDb", path: str) -> None:
        self.db = db
        self.path = path
        self.id = path.rsplit("/", 1)[-1]

    def collection(self, name: str) -> "MemoryCollection":
        self.db.reads += 1
        return MemoryCollection(self.db, f"{self.path}/{name}")


class MemoryRange:
    def __init__(self, db: "MemoryDb", parent: str) -> None:
        self.db = db
        self.parent = parent
        self._start: str | None = None
        self._end: str | None = None

    def order_by(self, *_args, **_kwargs) -> "MemoryRange":
        return self

    def start_at(self, values) -> "MemoryRange":
        self._start = values[0].id
        return self

    def end_at(self, values) -> "MemoryRange":
        self._end = values[0].id
        return self

    def stream(self) -> list[MemorySnap]:
        prefix = f"{self.parent}/"
        rows: list[tuple[str, str, dict]] = []
        for path, data in self.db.docs.items():
            if not path.startswith(prefix):
                continue
            doc_id = path[len(prefix) :]
            if "/" in doc_id:
                continue
            if self._start and doc_id < self._start:
                continue
            if self._end and doc_id > self._end:
                continue
            rows.append((doc_id, path, data))
        rows.sort()
        return [MemorySnap(doc_id, path, data) for doc_id, path, data in rows]


class MemoryCollection:
    def __init__(self, db: "MemoryDb", path: str) -> None:
        self.db = db
        self.path = path

    def document(self, doc_id: str) -> MemoryDoc:
        return MemoryDoc(self.db, f"{self.path}/{doc_id}")

    def order_by(self, *args, **kwargs) -> MemoryRange:
        return MemoryRange(self.db, self.path).order_by(*args, **kwargs)


class MemoryGroup:
    def __init__(self, db: "MemoryDb", name: str) -> None:
        self.db = db
        self.name = name
        self._limit: int | None = None

    def order_by(self, *_args, **_kwargs) -> "MemoryGroup":
        return self

    def limit(self, count: int) -> "MemoryGroup":
        self._limit = count
        return self

    def stream(self) -> list[MemorySnap]:
        rows: list[tuple[str, str, dict]] = []
        for path, data in self.db.docs.items():
            parts = path.split("/")
            if self.name not in parts:
                continue
            index = parts.index(self.name)
            if index + 1 != len(parts) - 1:
                continue
            rows.append((path, parts[-1], data))
        rows.sort()
        if self._limit is not None:
            rows = rows[: self._limit]
        return [MemorySnap(doc_id, path, data) for path, doc_id, data in rows]


class MemoryDb:
    def __init__(self, docs: dict[str, dict]) -> None:
        self.docs = docs
        self.reads = 0

    def collection(self, name: str) -> MemoryCollection:
        self.reads += 1
        return MemoryCollection(self, name)

    def collection_group(self, name: str) -> MemoryGroup:
        self.reads += 1
        return MemoryGroup(self, name)


@pytest.fixture(autouse=True)
def reset_admin():
    admin_auth_service._verify_token = None
    admin_auth_service._admin_doc_exists = None
    admin_daily_steps_service.firebase_service = None
    yield
    admin_auth_service._verify_token = None
    admin_auth_service._admin_doc_exists = None
    admin_daily_steps_service.firebase_service = None


def _admin() -> None:
    admin_auth_service._verify_token = lambda _token: {
        "uid": "admin-1",
        "email": "admin@share-run-challenge.app",
    }
    admin_auth_service._admin_doc_exists = lambda _uid: False


def _bind(docs: dict[str, dict]) -> MemoryDb:
    db = MemoryDb(docs)
    admin_daily_steps_service.firebase_service = SimpleNamespace(db=db)
    return db


def _sample() -> dict[str, dict]:
    return {
        "users/u1/daily_metrics/2026-10-01": {
            "steps": 29000,
            "source": "health_connect",
            "lastHealth": 1000,
            "updatedAt": "2026-10-01T01:00:00+00:00",
        },
        "users/u1/daily_metrics/2026-10-02": {
            "steps": 4200,
            "source": "sensor",
            "lastHealth": 2000,
            "updatedAt": "2026-10-02T01:00:00+00:00",
        },
        "users/u1/daily_metrics/2026-10-03": {
            "steps": 4000,
            "source": "sensor",
            "lastHealth": 2000,
            "updatedAt": "2026-10-03T01:00:00+00:00",
        },
        "users/u2/daily_metrics/2026-10-02": {
            "steps": 1000,
            "source": "sensor",
            "updatedAt": "2026-10-02T02:00:00+00:00",
        },
        "users/u1/daily_metrics/2026-01-01": {
            "steps": 30000,
            "source": "sensor",
            "lastHealth": 1,
            "updatedAt": "2026-01-01T00:00:00+00:00",
        },
    }


def test_daily_steps_missing_token_is_401() -> None:
    db = _bind(_sample())

    response = client.get("/admin/daily-steps")

    assert response.status_code == 401
    assert db.reads == 0


def test_daily_steps_non_admin_is_403() -> None:
    admin_auth_service._verify_token = lambda _token: {
        "uid": "runner",
        "email": "runner@example.com",
    }
    admin_auth_service._admin_doc_exists = lambda _uid: False
    db = _bind(_sample())

    response = client.get("/admin/daily-steps", headers=AUTH)

    assert response.status_code == 403
    assert db.reads == 0


def test_daily_steps_shape_anomalies_and_range() -> None:
    _admin()
    _bind(_sample())

    response = client.get(
        "/admin/daily-steps",
        headers=AUTH,
        params={"from": "2026-10-01", "to": "2026-10-03"},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["start"] == "2026-10-01"
    assert body["end"] == "2026-10-03"
    assert body["uid"] is None
    assert body["truncated"] is False
    by_key = {(row["uid"], row["day"]): row for row in body["rows"]}
    assert ("u1", "2026-01-01") not in by_key
    high = by_key[("u1", "2026-10-01")]
    assert high["steps"] == 29000
    assert high["source"] == "health_connect"
    assert high["lastHealth"] == 1000
    assert high["updatedAt"] == "2026-10-01T01:00:00+00:00"
    assert high["anomaly"] is True
    lead = by_key[("u1", "2026-10-02")]
    assert lead["steps"] == 4200
    assert lead["anomaly"] is True
    equal_lead = by_key[("u1", "2026-10-03")]
    assert equal_lead["steps"] == 4000
    assert equal_lead["anomaly"] is False
    missing_health = by_key[("u2", "2026-10-02")]
    assert missing_health["lastHealth"] is None
    assert missing_health["anomaly"] is False


def test_daily_steps_uid_filter() -> None:
    _admin()
    _bind(_sample())

    response = client.get(
        "/admin/daily-steps",
        headers=AUTH,
        params={"uid": "u1", "from": "2026-10-01", "to": "2026-10-03"},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["uid"] == "u1"
    assert {row["uid"] for row in body["rows"]} == {"u1"}
    assert [row["day"] for row in body["rows"]] == [
        "2026-10-03",
        "2026-10-02",
        "2026-10-01",
    ]


def test_default_window_is_last_14_kst_days() -> None:
    _bind({})
    result = admin_daily_steps_service.list_steps(
        now=datetime(2026, 10, 2, 15, 0, tzinfo=timezone.utc)
    )

    assert result.start == "2026-09-20"
    assert result.end == "2026-10-03"
