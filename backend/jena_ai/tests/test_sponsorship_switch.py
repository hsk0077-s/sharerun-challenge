"""POST /actions/sponsorship/donate is closed unless SPONSORSHIP_ENABLED is on."""

from types import SimpleNamespace

from fastapi import HTTPException
import pytest

from app.config import sponsorship_enabled
from app.services.secured_action_service import SecuredActionService
from test_redeem_referral import _MemoryDb


def _service(db: _MemoryDb) -> SecuredActionService:
    return SecuredActionService(firebase_service=SimpleNamespace(db=db))


def _user() -> dict:
    return {
        "wallet": {
            "shareBalance": 80_000,
            "freeShareBalance": 30_000,
            "paidShareBalance": 50_000,
            "diamondBalance": 9,
            "valueTokenBalance": 4,
        }
    }


def test_default_is_off(monkeypatch) -> None:
    monkeypatch.delenv("SPONSORSHIP_ENABLED", raising=False)
    assert sponsorship_enabled() is False


def test_off_rejects_and_changes_nothing(monkeypatch) -> None:
    monkeypatch.delenv("SPONSORSHIP_ENABLED", raising=False)
    db = _MemoryDb()
    db.store["users/u1"] = _user()
    before = {k: dict(v) if isinstance(v, dict) else v for k, v in db.store.items()}

    with pytest.raises(HTTPException) as err:
        _service(db).donate_personal_sponsor("u1", "req-1", "donation")

    assert err.value.status_code == 403
    assert err.value.detail == {"code": "sponsorship_disabled"}
    assert db.store == before
    assert not [p for p in db.store if p.startswith("walletTransactions/")]


def test_on_runs_the_existing_path(monkeypatch) -> None:
    monkeypatch.setenv("SPONSORSHIP_ENABLED", "true")
    called = {}

    def fake_commit(transaction, service, uid, request_id, purpose, user_ref):
        called["args"] = (uid, request_id, purpose)
        return "ok"

    import app.services.secured_action_service as mod

    monkeypatch.setattr(mod, "_commit_personal_sponsor_tx", fake_commit)
    db = _MemoryDb()
    db.transaction = lambda: object()
    result = _service(db).donate_personal_sponsor("u1", "req-1", "donation")
    assert result == "ok"
    assert called["args"] == ("u1", "req-1", "donation")
