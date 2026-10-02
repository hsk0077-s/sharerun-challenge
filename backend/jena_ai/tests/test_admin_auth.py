from unittest.mock import MagicMock

import pytest
from fastapi.testclient import TestClient
from firebase_admin import firestore

from app.main import app
from app.services.admin_audit_service import AdminAuditService, admin_audit_service
from app.services.admin_auth_service import admin_auth_service

client = TestClient(app)
AUTH = {"Authorization": "Bearer test-token"}


@pytest.fixture(autouse=True)
def reset_admin_services():
    admin_auth_service._verify_token = None
    admin_auth_service._admin_doc_exists = None
    admin_audit_service.firebase_service = None
    yield
    admin_auth_service._verify_token = None
    admin_auth_service._admin_doc_exists = None
    admin_audit_service.firebase_service = None


def _token(decoded: dict, *, doc_exists: bool = False) -> None:
    admin_auth_service._verify_token = lambda _token: decoded
    admin_auth_service._admin_doc_exists = lambda _uid: doc_exists


def test_whoami_missing_token_is_401() -> None:
    response = client.get("/admin/whoami")

    assert response.status_code == 401


def test_whoami_invalid_token_is_401() -> None:
    def reject(_token: str) -> dict:
        raise ValueError("bad token")

    admin_auth_service._verify_token = reject

    response = client.get("/admin/whoami", headers=AUTH)

    assert response.status_code == 401


def test_whoami_token_without_uid_is_401() -> None:
    _token({"email": "admin@share-run-challenge.app"})

    response = client.get("/admin/whoami", headers=AUTH)

    assert response.status_code == 401


def test_whoami_non_admin_is_403() -> None:
    _token({"uid": "runner", "email": "runner@example.com", "admin": False})

    response = client.get("/admin/whoami", headers=AUTH)

    assert response.status_code == 403
    assert response.json()["detail"] == "Admin access required."


@pytest.mark.parametrize(
    "email",
    ["admin@share-run-challenge.app", "ops@share-run-challenge.app"],
)
def test_whoami_allowlisted_email(email: str) -> None:
    _token({"uid": "allow-1", "email": email})

    response = client.get("/admin/whoami", headers=AUTH)

    assert response.status_code == 200
    assert response.json() == {"uid": "allow-1", "email": email, "admin": True}


def test_whoami_custom_claim() -> None:
    def doc_must_not_be_read(_uid: str) -> bool:
        raise AssertionError("admins doc should not be read when claim is set")

    admin_auth_service._verify_token = lambda _token: {
        "uid": "claim-1",
        "email": "other@example.com",
        "admin": True,
    }
    admin_auth_service._admin_doc_exists = doc_must_not_be_read

    response = client.get("/admin/whoami", headers=AUTH)

    assert response.status_code == 200
    assert response.json()["uid"] == "claim-1"
    assert response.json()["admin"] is True


def test_whoami_admins_document() -> None:
    _token({"uid": "doc-1", "email": "other@example.com"}, doc_exists=True)

    response = client.get("/admin/whoami", headers=AUTH)

    assert response.status_code == 200
    assert response.json()["uid"] == "doc-1"


def test_whoami_does_not_write_audit_log() -> None:
    db = MagicMock()
    admin_audit_service.firebase_service = MagicMock(db=db)
    _token(
        {
            "uid": "allow-1",
            "email": "admin@share-run-challenge.app",
            "admin": True,
        }
    )

    response = client.get("/admin/whoami", headers=AUTH)

    assert response.status_code == 200
    db.collection.assert_not_called()


def test_ping_missing_token_is_401() -> None:
    response = client.post("/admin/audit/ping")

    assert response.status_code == 401


def test_ping_non_admin_is_403() -> None:
    _token({"uid": "runner", "email": "runner@example.com"})

    response = client.post("/admin/audit/ping", headers=AUTH)

    assert response.status_code == 403


def test_ping_writes_audit_log_and_does_not_touch_users() -> None:
    ref = MagicMock()
    ref.id = "log-1"
    logs = MagicMock()
    logs.document.return_value = ref
    db = MagicMock()

    def collection(name: str):
        if name != "adminAuditLogs":
            raise AssertionError(f"unexpected collection {name}")
        return logs

    db.collection.side_effect = collection
    admin_audit_service.firebase_service = MagicMock(db=db)
    _token(
        {
            "uid": "allow-1",
            "email": "admin@share-run-challenge.app",
        }
    )

    response = client.post(
        "/admin/audit/ping",
        headers=AUTH,
        json={"reason": "check"},
    )

    assert response.status_code == 200
    assert response.json()["accepted"] is True
    assert response.json()["log_id"] == "log-1"
    assert response.json()["action"] == "audit_ping"
    payload = ref.set.call_args.args[0]
    assert payload["uid"] == "allow-1"
    assert payload["email"] == "admin@share-run-challenge.app"
    assert payload["action"] == "audit_ping"
    assert payload["targetUid"] is None
    assert payload["before"] is None
    assert payload["after"] is None
    assert payload["reason"] == "check"
    assert payload["createdAt"] is firestore.SERVER_TIMESTAMP


def test_audit_writer_stores_who_when_target_and_before_after() -> None:
    ref = MagicMock()
    ref.id = "log-9"
    logs = MagicMock()
    logs.document.return_value = ref
    db = MagicMock()
    db.collection.return_value = logs
    service = AdminAuditService(firebase_service=MagicMock(db=db))

    log_id = service.write(
        uid="allow-1",
        email="ops@share-run-challenge.app",
        action="audit_ping",
        target_uid="runner-2",
        before={"marker": "before"},
        after={"marker": "after"},
        reason="shape",
    )

    assert log_id == "log-9"
    db.collection.assert_called_once_with("adminAuditLogs")
    payload = ref.set.call_args.args[0]
    assert payload["uid"] == "allow-1"
    assert payload["email"] == "ops@share-run-challenge.app"
    assert payload["createdAt"] is firestore.SERVER_TIMESTAMP
    assert payload["action"] == "audit_ping"
    assert payload["targetUid"] == "runner-2"
    assert payload["before"] == {"marker": "before"}
    assert payload["after"] == {"marker": "after"}
    assert payload["reason"] == "shape"
    assert "wallet" not in payload
