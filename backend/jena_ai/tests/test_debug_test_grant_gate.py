"""Debug 1M grant stays closed unless an env flag and an admin token are both set."""

from unittest.mock import MagicMock

import pytest
from fastapi import HTTPException
from fastapi.testclient import TestClient

from app.main import app
from app.models.secured_actions import SecuredActionResult
from app.services.admin_auth_service import admin_auth_service
from app.services.secured_action_service import SecuredActionService

client = TestClient(app)
AUTH = {"Authorization": "Bearer test-token"}
BAKED = {
    "debug_client": True,
    "grant_secret": "sharerun-debug-test-grant-1m",
}


@pytest.fixture(autouse=True)
def reset_admin_auth():
    admin_auth_service._verify_token = None
    admin_auth_service._admin_doc_exists = None
    yield
    admin_auth_service._verify_token = None
    admin_auth_service._admin_doc_exists = None


def test_grant_service_does_not_touch_wallet_when_flag_is_off(monkeypatch) -> None:
    monkeypatch.delenv("DEBUG_TEST_GRANT_ENABLED", raising=False)
    firebase = MagicMock()
    service = SecuredActionService(firebase_service=firebase)

    with pytest.raises(HTTPException) as exc:
        service.grant_debug_test_wallet("uid-1", admin_authorized=True)

    assert exc.value.status_code == 404
    firebase.db.transaction.assert_not_called()


def test_grant_service_rejects_non_admin_without_a_wallet_write(monkeypatch) -> None:
    monkeypatch.setenv("DEBUG_TEST_GRANT_ENABLED", "true")
    firebase = MagicMock()
    service = SecuredActionService(firebase_service=firebase)

    with pytest.raises(HTTPException) as exc:
        service.grant_debug_test_wallet("uid-1", admin_authorized=False)

    assert exc.value.status_code == 403
    firebase.db.transaction.assert_not_called()


def test_endpoint_is_404_by_default_even_with_baked_client_secret(monkeypatch) -> None:
    monkeypatch.delenv("DEBUG_TEST_GRANT_ENABLED", raising=False)

    response = client.post("/actions/debug/test-grant-1m", headers=AUTH, json=BAKED)

    assert response.status_code == 404


def test_endpoint_flag_without_admin_is_403(monkeypatch) -> None:
    monkeypatch.setenv("DEBUG_TEST_GRANT_ENABLED", "true")
    admin_auth_service._verify_token = lambda _token: {
        "uid": "runner",
        "email": "runner@example.com",
        "admin": False,
    }
    admin_auth_service._admin_doc_exists = lambda _uid: False

    response = client.post("/actions/debug/test-grant-1m", headers=AUTH, json=BAKED)

    assert response.status_code == 403


def test_endpoint_admin_and_flag_reaches_grant_without_using_the_secret(
    monkeypatch,
) -> None:
    monkeypatch.setenv("DEBUG_TEST_GRANT_ENABLED", "true")
    admin_auth_service._verify_token = lambda _token: {
        "uid": "admin-1",
        "email": "admin@share-run-challenge.app",
        "admin": True,
    }
    seen: dict[str, object] = {}

    def fake_grant(uid, request=None, *, admin_authorized=False):
        seen["uid"] = uid
        seen["admin_authorized"] = admin_authorized
        seen["secret"] = "" if request is None else request.grant_secret
        return SecuredActionResult(
            accepted=True,
            status="already_granted",
            reason="Debug 1M test grant was already applied.",
            share_credited=0,
            share_balance=1_000_000,
            diamond_balance=1_000_000,
            value_token_balance=1_000_000,
        )

    monkeypatch.setattr(
        "app.routers.secured_action_router.service.grant_debug_test_wallet",
        fake_grant,
    )

    response = client.post("/actions/debug/test-grant-1m", headers=AUTH, json=BAKED)

    assert response.status_code == 200
    assert response.json()["status"] == "already_granted"
    assert response.json()["share_balance"] == 1_000_000
    assert seen == {
        "uid": "admin-1",
        "admin_authorized": True,
        "secret": "sharerun-debug-test-grant-1m",
    }
