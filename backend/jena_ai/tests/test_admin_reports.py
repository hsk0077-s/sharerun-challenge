from datetime import datetime, timezone

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.routers import admin_router
from app.services.admin_auth_service import admin_auth_service

client = TestClient(app)
AUTH = {"Authorization": "Bearer test-token"}


class _Snap:
    def __init__(self, doc_id, data):
        self.id = doc_id
        self.exists = data is not None
        self._data = data

    def to_dict(self):
        return None if self._data is None else dict(self._data)


class _Doc:
    def __init__(self, store, doc_id):
        self.store, self.id = store, doc_id

    def get(self):
        return _Snap(self.id, self.store.get(self.id))

    def update(self, fields):
        self.store[self.id].update(fields)


class _Query:
    def __init__(self, store, flt=None, cap=None):
        self.store, self.flt, self.cap = store, flt, cap

    def where(self, field, _op, value):
        return _Query(self.store, (field, value), self.cap)

    def limit(self, n):
        return _Query(self.store, self.flt, n)

    def get(self):
        rows = [
            _Snap(k, v)
            for k, v in self.store.items()
            if self.flt is None or v.get(self.flt[0]) == self.flt[1]
        ]
        return rows[: self.cap] if self.cap else rows


class _Db:
    def __init__(self, reports):
        self.reports = reports

    def collection(self, name):
        assert name == "reports"
        store = self.reports

        class C(_Query):
            def document(self, doc_id):
                return _Doc(store, doc_id)

        return C(store)


@pytest.fixture(autouse=True)
def _admin(monkeypatch):
    admin_auth_service._verify_token = lambda _t: {
        "uid": "admin-1",
        "admin": True,
    }
    admin_auth_service._admin_doc_exists = lambda _u: False
    yield
    admin_auth_service._verify_token = None
    admin_auth_service._admin_doc_exists = None


def _report(status="open", day=1):
    return {
        "targetType": "crew",
        "targetId": "c1",
        "targetName": "이름",
        "reason": "spam",
        "status": status,
        "reporterUid": "u1",
        "createdAt": datetime(2026, 10, day, tzinfo=timezone.utc),
    }


def test_reports_need_an_admin() -> None:
    admin_auth_service._verify_token = lambda _t: {"uid": "runner", "email": "r@example.com"}
    assert client.get("/admin/reports", headers=AUTH).status_code == 403
    assert client.get("/admin/reports").status_code == 401


def test_open_reports_are_listed_oldest_first(monkeypatch) -> None:
    db = _Db({"b": _report(day=3), "a": _report(day=2), "c": _report("resolved")})
    monkeypatch.setattr(admin_router, "FirebaseService", lambda: type("F", (), {"db": db})())

    body = client.get("/admin/reports", headers=AUTH).json()

    assert [row["id"] for row in body["reports"]] == ["a", "b"]


def test_changing_status_is_written_to_the_audit_log(monkeypatch) -> None:
    db = _Db({"a": _report()})
    monkeypatch.setattr(admin_router, "FirebaseService", lambda: type("F", (), {"db": db})())
    audit: list[dict] = []
    monkeypatch.setattr(
        admin_router.admin_audit_service, "write", lambda **kw: audit.append(kw) or "log1"
    )

    response = client.post(
        "/admin/reports/a/status", headers=AUTH, json={"status": "resolved", "note": "이름 변경됨"}
    )

    assert response.status_code == 200
    assert db.reports["a"]["status"] == "resolved"
    assert db.reports["a"]["reviewedBy"] == "admin-1"
    assert audit[0]["action"] == "report_status"
    assert audit[0]["before"] == {"status": "open"}
    assert audit[0]["after"] == {"status": "resolved"}


def test_unknown_report_and_bad_status_are_refused(monkeypatch) -> None:
    db = _Db({"a": _report()})
    monkeypatch.setattr(admin_router, "FirebaseService", lambda: type("F", (), {"db": db})())

    assert (
        client.post("/admin/reports/zz/status", headers=AUTH, json={"status": "resolved"}).status_code
        == 404
    )
    assert (
        client.post("/admin/reports/a/status", headers=AUTH, json={"status": "open"}).status_code
        == 422
    )
    assert client.get("/admin/reports?status=bogus", headers=AUTH).status_code == 400
