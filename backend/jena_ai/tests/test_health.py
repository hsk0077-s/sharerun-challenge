from fastapi.testclient import TestClient

from app.main import app


def test_health_returns_ok() -> None:
    client = TestClient(app)

    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_health_ready_returns_503_when_env_missing(monkeypatch) -> None:
    monkeypatch.setenv("PAYMENTS_ENABLED", "true")
    monkeypatch.delenv("PG_WEBHOOK_SECRET", raising=False)
    monkeypatch.delenv("OPS_ADMIN_SECRET", raising=False)
    monkeypatch.delenv("LOCAL_DEV_MODE", raising=False)
    client = TestClient(app)

    response = client.get("/health/ready")

    assert response.status_code == 503
    assert response.json()["detail"]["status"] == "not_ready"
    assert "PG_WEBHOOK_SECRET" in response.json()["detail"]["missing_env"]
    assert "OPS_ADMIN_SECRET" in response.json()["detail"]["missing_env"]


def test_ready_without_pg_secret_when_payments_are_off(monkeypatch, caplog) -> None:
    monkeypatch.delenv("PAYMENTS_ENABLED", raising=False)
    monkeypatch.delenv("PG_WEBHOOK_SECRET", raising=False)
    monkeypatch.setenv("OPS_ADMIN_SECRET", "test-ops-secret")
    monkeypatch.delenv("LOCAL_DEV_MODE", raising=False)
    monkeypatch.setattr("app.main._warned_no_pg_secret", False)
    client = TestClient(app)

    with caplog.at_level("WARNING"):
        response = client.get("/health/ready")
        client.get("/health/ready")

    assert response.status_code == 200
    assert response.json() == {"status": "ready", "warnings": ["PG_WEBHOOK_SECRET"]}
    # One warning, not one per health check.
    assert sum("PG_WEBHOOK_SECRET" in r.message for r in caplog.records) == 1


def test_ops_secret_is_still_required_when_payments_are_off(monkeypatch) -> None:
    monkeypatch.delenv("PAYMENTS_ENABLED", raising=False)
    monkeypatch.delenv("PG_WEBHOOK_SECRET", raising=False)
    monkeypatch.delenv("OPS_ADMIN_SECRET", raising=False)
    monkeypatch.delenv("LOCAL_DEV_MODE", raising=False)
    client = TestClient(app)

    response = client.get("/health/ready")

    assert response.status_code == 503
    assert response.json()["detail"]["missing_env"] == ["OPS_ADMIN_SECRET"]


def test_pg_secret_is_required_again_when_payments_turn_on(monkeypatch) -> None:
    monkeypatch.setenv("PAYMENTS_ENABLED", "1")
    monkeypatch.delenv("PG_WEBHOOK_SECRET", raising=False)
    monkeypatch.setenv("OPS_ADMIN_SECRET", "test-ops-secret")
    monkeypatch.delenv("LOCAL_DEV_MODE", raising=False)
    client = TestClient(app)

    response = client.get("/health/ready")

    assert response.status_code == 503
    assert response.json()["detail"]["missing_env"] == ["PG_WEBHOOK_SECRET"]


def test_health_ready_returns_ready_when_env_present(monkeypatch) -> None:
    monkeypatch.setenv("PAYMENTS_ENABLED", "true")
    monkeypatch.setenv("PG_WEBHOOK_SECRET", "test-secret")
    monkeypatch.setenv("OPS_ADMIN_SECRET", "test-ops-secret")
    monkeypatch.delenv("LOCAL_DEV_MODE", raising=False)
    client = TestClient(app)

    response = client.get("/health/ready")

    assert response.status_code == 200
    assert response.json() == {"status": "ready"}
