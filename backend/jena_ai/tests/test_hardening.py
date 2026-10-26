import pytest
from fastapi.testclient import TestClient
from starlette.requests import Request

from app.routers.identity_router import _client
from app.services.ops_auth_service import require_ops_admin


def _request(headers: dict[str, str], host: str = "10.0.0.1") -> Request:
    return Request(
        {
            "type": "http",
            "headers": [(k.lower().encode(), v.encode()) for k, v in headers.items()],
            "client": (host, 1234),
        }
    )


def test_client_address_is_the_last_forwarded_entry() -> None:
    # A caller can put anything first; Cloud Run appends the real address last.
    request = _request({"x-forwarded-for": "1.2.3.4, 5.6.7.8, 203.0.113.9"})
    assert _client(request) == "203.0.113.9"


def test_a_spoofed_first_entry_does_not_change_the_address() -> None:
    a = _request({"x-forwarded-for": "9.9.9.9, 203.0.113.9"})
    b = _request({"x-forwarded-for": "8.8.8.8, 203.0.113.9"})
    assert _client(a) == _client(b) == "203.0.113.9"


def test_client_address_falls_back_to_the_socket() -> None:
    assert _client(_request({})) == "10.0.0.1"
    assert _client(_request({"x-forwarded-for": " "})) == "10.0.0.1"


def test_ops_secret_must_match(monkeypatch: pytest.MonkeyPatch) -> None:
    from fastapi import HTTPException

    monkeypatch.setenv("OPS_ADMIN_SECRET", "s3cret")
    require_ops_admin("s3cret")
    for bad in (None, "", "s3cre", "s3cret!"):
        with pytest.raises(HTTPException) as caught:
            require_ops_admin(bad)
        assert caught.value.status_code == 401


def test_validate_run_without_login_is_gone_and_docs_are_hidden() -> None:
    from app import config
    from app.main import app

    client = TestClient(app)
    assert client.post("/validate-run", json={}).status_code == 404
    if not config.is_local_dev_mode():
        assert client.get("/docs").status_code == 404
        assert client.get("/openapi.json").status_code == 404
