"""A watch's sign-in token works only for the two upload routes."""

import pytest
from fastapi import Depends, FastAPI, HTTPException
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


def _watch_with(monkeypatch, *, token_gen, account_gen) -> TestClient:
    claims = {"provider": "watch"}
    if token_gen is not None:
        claims["wgen"] = token_gen
    _sign_in_as(monkeypatch, claims)
    monkeypatch.setattr(auth_module, "_current_watch_generation", lambda _uid: account_gen)
    return _app()


def test_a_watch_signed_in_before_a_disconnect_is_refused(monkeypatch) -> None:
    client = _watch_with(monkeypatch, token_gen=0, account_gen=1)
    response = client.post("/actions/daily-steps", headers=HEADERS)
    assert response.status_code == 401
    assert response.json()["detail"] == "watch_revoked"


def test_a_watch_signed_in_after_a_disconnect_works(monkeypatch) -> None:
    client = _watch_with(monkeypatch, token_gen=1, account_gen=1)
    assert client.post("/actions/daily-steps", headers=HEADERS).status_code == 200


def test_a_watch_paired_before_generations_existed_works_until_a_disconnect(monkeypatch) -> None:
    assert (
        _watch_with(monkeypatch, token_gen=None, account_gen=0)
        .post("/actions/daily-steps", headers=HEADERS)
        .status_code
        == 200
    )
    assert (
        _watch_with(monkeypatch, token_gen=None, account_gen=1)
        .post("/actions/daily-steps", headers=HEADERS)
        .status_code
        == 401
    )


def test_a_phone_token_is_not_checked_against_the_watch_generation(monkeypatch) -> None:
    _sign_in_as(monkeypatch, {"provider": "google"})
    monkeypatch.setattr(
        auth_module,
        "_current_watch_generation",
        lambda _uid: (_ for _ in ()).throw(AssertionError("not for phones")),
    )
    assert _app().post("/actions/shop/buy", headers=HEADERS).status_code == 200


def test_a_watch_cannot_disconnect_watches(monkeypatch) -> None:
    app = FastAPI()
    app.post("/actions/watch-pairing/revoke")(lambda uid=Depends(require_uid): {"uid": uid})
    _sign_in_as(monkeypatch, {"provider": "watch"})
    response = TestClient(app).post("/actions/watch-pairing/revoke", headers=HEADERS)
    assert response.status_code == 403


def _real_app(monkeypatch, claims: dict):
    from app.main import app
    from app.routers import secured_action_router

    _sign_in_as(monkeypatch, claims)
    monkeypatch.setattr(auth_module, "_current_watch_generation", lambda _uid: 0)
    def reached_the_service(uid, request):
        raise HTTPException(status_code=418, detail="reached")

    monkeypatch.setattr(secured_action_router.service, "validate_run", reached_the_service)
    return TestClient(app)


def _body(**extra) -> dict:
    return {
        "activity_id": "a1",
        "distance_km": 3,
        "duration_seconds": 1000,
        "gyro_stability_score": 0.5,
        **extra,
    }


def test_a_watch_run_must_carry_its_times(monkeypatch) -> None:
    client = _real_app(monkeypatch, {"provider": "watch", "wgen": 0})
    response = client.post("/actions/runs/validate", json=_body(), headers=HEADERS)
    assert response.status_code == 400
    assert response.json()["detail"] == "run_time_required"


def test_a_watch_run_with_impossible_times_is_refused(monkeypatch) -> None:
    client = _real_app(monkeypatch, {"provider": "watch", "wgen": 0})
    response = client.post(
        "/actions/runs/validate",
        json=_body(started_at="2030-01-01T00:00:00Z", ended_at="2030-01-01T00:20:00Z"),
        headers=HEADERS,
    )
    assert response.status_code == 400
    assert response.json()["detail"] == "run_in_future"


def test_a_phone_run_does_not_need_times(monkeypatch) -> None:
    client = _real_app(monkeypatch, {"provider": "google"})
    response = client.post("/actions/runs/validate", json=_body(), headers=HEADERS)
    assert response.status_code == 418  # got past the time check to the service
