from datetime import datetime, timezone
from types import SimpleNamespace

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.services.admin_audit_service import admin_audit_service
from app.services.admin_auth_service import admin_auth_service
from app.services.admin_config_service import admin_config_service

client = TestClient(app)
AUTH = {"Authorization": "Bearer test-token"}


class _Snap:
    def __init__(self, data):
        self.exists = data is not None
        self._data = data

    def to_dict(self):
        return None if self._data is None else dict(self._data)


class _Db:
    def __init__(self, docs):
        self.docs = docs
        self.reads = []

    def collection(self, name):
        assert name == "config"
        return SimpleNamespace(document=lambda doc_id: self._doc(doc_id))

    def _doc(self, doc_id):
        self.reads.append(doc_id)
        return SimpleNamespace(get=lambda: _Snap(self.docs.get(doc_id)))


@pytest.fixture(autouse=True)
def _wire(monkeypatch):
    audits = []
    monkeypatch.setattr(
        admin_auth_service,
        "require_admin",
        lambda authorization: {"uid": "admin1", "email": "a@x.com"},
    )
    monkeypatch.setattr(admin_audit_service, "write", lambda **kw: audits.append(kw))
    yield audits
    admin_config_service.firebase_service = None


def test_lists_known_config_documents_and_marks_missing_ones(_wire) -> None:
    db = _Db(
        {
            "item_prices": {"rest_day": 200, "updatedAt": datetime(2026, 11, 1, tzinfo=timezone.utc)},
            "referral_trial": {"enabled": True},
        }
    )
    admin_config_service.firebase_service = SimpleNamespace(db=db)

    response = client.get("/admin/config", headers=AUTH)

    assert response.status_code == 200
    docs = {d["id"]: d for d in response.json()["documents"]}
    assert docs["item_prices"]["exists"] is True
    assert docs["item_prices"]["data"]["rest_day"] == 200
    assert docs["item_prices"]["data"]["updatedAt"].startswith("2026-11-01")
    assert docs["referral_trial"]["data"] == {"enabled": True}
    assert docs["promotion"]["exists"] is False
    assert docs["promotion"]["data"] == {}
    assert _wire[0]["action"] == "config_view"


def test_requires_admin(monkeypatch) -> None:
    from fastapi import HTTPException

    def deny(authorization):
        raise HTTPException(status_code=403, detail="no")

    monkeypatch.setattr(admin_auth_service, "require_admin", deny)

    assert client.get("/admin/config", headers=AUTH).status_code == 403
