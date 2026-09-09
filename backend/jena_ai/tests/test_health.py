from fastapi.testclient import TestClient

from app.main import app


def test_health_returns_ok() -> None:
    client = TestClient(app)

    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_health_ready_returns_503_when_env_missing(monkeypatch) -> None:
    monkeypatch.delenv("PG_WEBHOOK_SECRET", raising=False)
    monkeypatch.delenv("OPS_ADMIN_SECRET", raising=False)
    monkeypatch.delenv("LOCAL_DEV_MODE", raising=False)
    client = TestClient(app)

    response = client.get("/health/ready")

    assert response.status_code == 503
    assert response.json()["detail"]["status"] == "not_ready"
    assert "PG_WEBHOOK_SECRET" in response.json()["detail"]["missing_env"]
    assert "OPS_ADMIN_SECRET" in response.json()["detail"]["missing_env"]


def test_health_ready_returns_ready_when_env_present(monkeypatch) -> None:
    monkeypatch.setenv("PG_WEBHOOK_SECRET", "test-secret")
    monkeypatch.setenv("OPS_ADMIN_SECRET", "test-ops-secret")
    monkeypatch.delenv("LOCAL_DEV_MODE", raising=False)
    client = TestClient(app)

    response = client.get("/health/ready")

    assert response.status_code == 200
    assert response.json() == {"status": "ready"}
