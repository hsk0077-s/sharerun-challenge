from types import SimpleNamespace

from app.services.privacy_settings import (
    apply_ai_learning,
    read_settings,
    settings_view,
)
from test_redeem_referral import _MemoryDb, _MemoryTxn


def _db() -> _MemoryDb:
    return _MemoryDb()


def _logs(db: _MemoryDb) -> list[dict]:
    return [v for k, v in db.store.items() if k.startswith("privacySettingLog/")]


def test_default_is_off() -> None:
    assert settings_view(None) == {"ai_learning": False}
    assert settings_view({"aiLearning": "yes"}) == {"ai_learning": False}
    assert read_settings(_db(), "u1") == {"ai_learning": False}


def test_turning_on_saves_and_logs_once() -> None:
    db = _db()
    assert apply_ai_learning(_MemoryTxn(), db, "u1", True) == {"ai_learning": True}
    assert db.store["privacySettings/u1"]["aiLearning"] is True
    assert read_settings(db, "u1") == {"ai_learning": True}
    assert len(_logs(db)) == 1
    assert _logs(db)[0]["before"] is False and _logs(db)[0]["after"] is True


def test_same_value_again_adds_no_log_row() -> None:
    db = _db()
    apply_ai_learning(_MemoryTxn(), db, "u1", True)
    apply_ai_learning(_MemoryTxn(), db, "u1", True)
    apply_ai_learning(_MemoryTxn(), db, "u1", False)
    apply_ai_learning(_MemoryTxn(), db, "u1", False)
    logs = _logs(db)
    assert [row["after"] for row in logs] == [True, False]


def test_each_account_is_separate() -> None:
    db = _db()
    apply_ai_learning(_MemoryTxn(), db, "u1", True)
    assert read_settings(db, "u2") == {"ai_learning": False}
