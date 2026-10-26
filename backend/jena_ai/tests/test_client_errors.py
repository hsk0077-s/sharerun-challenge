import logging

import pytest
from fastapi import HTTPException
from fastapi.testclient import TestClient

from app.main import app
from app.services import client_errors, rate_limit
from app.services.auth_service import require_uid


@pytest.fixture(autouse=True)
def _reset():
    rate_limit.CLIENT_ERROR_BY_UID.clear()
    app.dependency_overrides[require_uid] = lambda: "uid-secret-123"
    yield
    app.dependency_overrides.clear()
    rate_limit.CLIENT_ERROR_BY_UID.clear()


def test_a_report_becomes_one_log_line_without_the_uid(caplog) -> None:
    with caplog.at_level(logging.ERROR, logger="client_error"):
        response = TestClient(app).post(
            "/actions/diagnostics/client-error",
            json={
                "message": "Bad state: nope",
                "stack": "#0 main (a.dart:1)\n#1 run (b.dart:2)",
                "fatal": True,
                "app_version": "1.0.0+7",
                "platform": "android",
            },
        )
    assert response.status_code == 200
    assert response.json() == {"accepted": True}
    lines = [r.getMessage() for r in caplog.records if r.name == "client_error"]
    assert len(lines) == 1
    line = lines[0]
    assert "Bad state: nope" in line and "fatal=True" in line and "app=1.0.0+7" in line
    assert "uid-secret-123" not in line
    assert client_errors.who("uid-secret-123") in line
    assert "\n" not in line


def test_tokens_in_a_message_are_masked() -> None:
    text = (
        "GET https://x/api?access_token=abc123def&x=1 failed, "
        "Authorization: Bearer eyJhbGciOi.payload.sig "
        "purchase " + "A" * 80
    )
    cleaned = client_errors.clean(text, 500)
    assert "abc123def" not in cleaned
    assert "eyJhbGciOi" not in cleaned
    assert "A" * 40 not in cleaned
    assert "access_token=[masked]" in cleaned


def test_long_text_is_cut_and_control_characters_removed() -> None:
    assert len(client_errors.clean(" ".join(["word"] * 3000), 500)) == 500
    assert client_errors.clean("a\x00b\x1fc", 50) == "abc"


def test_reports_are_rate_limited_per_account() -> None:
    client = TestClient(app)
    body = {"message": "m"}
    for _ in range(20):
        assert client.post("/actions/diagnostics/client-error", json=body).status_code == 200
    blocked = client.post("/actions/diagnostics/client-error", json=body)
    assert blocked.status_code == 429
    assert blocked.json()["detail"] == "too_many_reports"


def test_a_report_needs_a_login() -> None:
    app.dependency_overrides.clear()
    response = TestClient(app).post("/actions/diagnostics/client-error", json={"message": "m"})
    assert response.status_code == 401


def test_oversized_bodies_are_refused() -> None:
    response = TestClient(app).post(
        "/actions/diagnostics/client-error", json={"message": "x" * 5000}
    )
    assert response.status_code == 422
