"""A watch's sign-in token works only for the two upload routes."""

import pytest
from fastapi import Depends, FastAPI
from fastapi.testclient import TestClient

from app.services import auth_service as auth_module
from app.services.auth_service import require_uid


def _app() -> TestClient:
    app = FastAPI()
    for path in ("/actions/runs/validate", "/actions/daily-steps", "/actions/shop/buy"):
        app.post(path)(lambda uid=Depends(require_uid): {"uid": uid})
    return TestClient(app)


def _sign_in_as(monkeypatch, claims: dict) -> None:
    decoded = {"uid": "u1", "iat": 100, **claims}
    monkeypatch.setattr(auth_module, "FirebaseService", lambda: None)
    monkeypatch.setattr(auth_module.auth, "verify_id_token", lambda _token: decoded)
    monkeypatch.setattr(auth_module, "_tokens_valid_after", lambda _uid: 0)


HEADERS = {"Authorization": "Bearer token"}


@pytest.mark.parametrize("path", ["/actions/runs/validate", "/actions/daily-steps"])
def test_a_watch_may_upload_runs_and_steps(monkeypatch, path) -> None:
    _sign_in_as(monkeypatch, {"provider": "watch"})
    response = _app().post(path, headers=HEADERS)
    assert response.status_code == 200
    assert response.json() == {"uid": "u1"}


def test_a_watch_may_not_touch_anything_else(monkeypatch) -> None:
    _sign_in_as(monkeypatch, {"provider": "watch"})
    response = _app().post("/actions/shop/buy", headers=HEADERS)
    assert response.status_code == 403
    assert response.json()["detail"] == "watch_scope"


@pytest.mark.parametrize("claims", [{}, {"provider": "kakao"}, {"provider": "google"}])
def test_phone_sign_ins_are_not_limited(monkeypatch, claims) -> None:
    _sign_in_as(monkeypatch, claims)
    assert _app().post("/actions/shop/buy", headers=HEADERS).status_code == 200


def test_a_direct_call_without_a_path_refuses_a_watch_token(monkeypatch) -> None:
    _sign_in_as(monkeypatch, {"provider": "watch"})
    with pytest.raises(Exception) as caught:
        auth_module.auth_service.verify_bearer_token("Bearer token")
    assert getattr(caught.value, "status_code", None) == 403
