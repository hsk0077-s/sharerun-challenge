import pytest
from fastapi import HTTPException
from firebase_admin import auth

from app.services import auth_service as auth_module
from app.services.login_devices import (
    clean_device_id,
    list_devices,
    register_device,
    sign_out_everywhere,
)


class _Snap:
    def __init__(self, id_, data):
        self.id = id_
        self._data = data

    def to_dict(self):
        return dict(self._data)


class _Docs:
    def __init__(self, store):
        self.store = store

    def document(self, doc_id=None):
        return _Doc(self.store, doc_id or f"auto{len(self.store)}")

    def get(self):
        return [_Snap(k, v) for k, v in list(self.store.items())]


class _Doc:
    def __init__(self, store, id_):
        self.store, self.id = store, id_

    def get(self):
        class S:
            exists = self.id in self.store

        return S()

    def set(self, data, merge=False):
        self.store.setdefault(self.id, {}).update(data) if merge else self.store.__setitem__(self.id, dict(data))

    def delete(self):
        self.store.pop(self.id, None)


class _Db:
    def __init__(self):
        self.devices: dict = {}
        self.log: dict = {}

    def collection(self, name):
        db = self
        if name == "securityLog":
            return _Docs(self.log)

        class Users:
            def document(self, uid):
                class U:
                    def collection(self, sub):
                        return _Docs(db.devices)

                return U()

        return Users()


def test_device_id_must_look_like_an_install_id() -> None:
    assert clean_device_id("a" * 32) == "a" * 32
    assert clean_device_id("short") is None
    assert clean_device_id("has space in it!!") is None
    assert clean_device_id(None) is None


def test_register_is_idempotent_and_keeps_first_seen() -> None:
    db = _Db()
    register_device(db, "u1", "d" * 16, model="SM-N970", os_version="Android 12", app_version="1.0+1")
    first = db.devices["d" * 16]["firstSeenAt"]
    register_device(db, "u1", "d" * 16, model="SM-N970", os_version="Android 12", app_version="1.0+2")
    assert len(db.devices) == 1
    assert db.devices["d" * 16]["appVersion"] == "1.0+2"
    assert db.devices["d" * 16]["firstSeenAt"] is first


def test_list_marks_current_and_shows_no_location() -> None:
    db = _Db()
    register_device(db, "u1", "a" * 16, model="A", os_version="x", app_version="1")
    register_device(db, "u1", "b" * 16, model="B", os_version="x", app_version="1")
    rows = list_devices(db, "u1", "b" * 16)
    assert {r["device_id"]: r["current"] for r in rows} == {"a" * 16: False, "b" * 16: True}
    assert all("fcmToken" not in r and "fcm_token" not in r for r in rows)


def test_sign_out_revokes_clears_list_and_logs_once() -> None:
    db = _Db()
    register_device(db, "u1", "a" * 16, model="A", os_version="x", app_version="1")
    revoked = []
    sign_out_everywhere(db, "u1", revoked.append)
    assert revoked == ["u1"]
    assert db.devices == {}
    assert [row["type"] for row in db.log.values()] == ["sign_out_everywhere"]


def test_server_rejects_tokens_issued_before_the_sign_out(monkeypatch) -> None:
    auth_module._valid_after.clear()
    monkeypatch.setattr(auth_module, "FirebaseService", lambda: None)
    monkeypatch.setattr(auth, "verify_id_token", lambda token: {"uid": "u1", "iat": 100})

    class User:
        tokens_valid_after_timestamp = 200_000  # milliseconds, as firebase_admin returns

    monkeypatch.setattr(auth, "get_user", lambda uid: User())
    with pytest.raises(HTTPException) as caught:
        auth_module.auth_service.verify_bearer_token("Bearer t")
    assert caught.value.status_code == 401

    auth_module._valid_after.clear()
    monkeypatch.setattr(auth, "verify_id_token", lambda token: {"uid": "u1", "iat": 300})
    assert auth_module.auth_service.verify_bearer_token("Bearer t") == "u1"


def test_a_normal_recent_login_is_never_rejected(monkeypatch) -> None:
    """Real shape: validSince in ms from account creation, iat in seconds now."""
    auth_module._valid_after.clear()
    monkeypatch.setattr(auth_module, "FirebaseService", lambda: None)
    monkeypatch.setattr(
        auth, "verify_id_token", lambda token: {"uid": "u1", "iat": 1_760_000_000}
    )

    class User:
        tokens_valid_after_timestamp = 1_750_000_000_000

    monkeypatch.setattr(auth, "get_user", lambda uid: User())
    assert auth_module.auth_service.verify_bearer_token("Bearer t") == "u1"


def test_a_failing_check_does_not_lock_everyone_out(monkeypatch) -> None:
    auth_module._valid_after.clear()
    monkeypatch.setattr(auth_module, "FirebaseService", lambda: None)
    monkeypatch.setattr(auth, "verify_id_token", lambda token: {"uid": "u1", "iat": 1})

    def boom(uid):
        raise RuntimeError("down")

    monkeypatch.setattr(auth, "get_user", boom)
    assert auth_module.auth_service.verify_bearer_token("Bearer t") == "u1"


def test_new_device_alerts_the_other_devices_once() -> None:
    db = _Db()
    sent = []
    notify = lambda tokens, model: sent.append((tokens, model))  # noqa: E731
    register_device(db, "u1", "a" * 16, model="Old", os_version="x", app_version="1", fcm_token="tok-old", notify=notify)
    assert sent == []  # the first device has nobody to tell
    assert register_device(db, "u1", "b" * 16, model="New", os_version="x", app_version="1", fcm_token="tok-new", notify=notify) is True
    assert sent == [(["tok-old"], "New")]  # the new device is not told about itself
    assert register_device(db, "u1", "b" * 16, model="New", os_version="x", app_version="1", fcm_token="tok-new", notify=notify) is False
    assert len(sent) == 1  # opening the app again is not a new login


def test_a_failing_alert_never_blocks_registration() -> None:
    db = _Db()
    register_device(db, "u1", "a" * 16, model="Old", os_version="x", app_version="1", fcm_token="tok-old")

    def boom(tokens, model):
        raise RuntimeError("push down")

    register_device(db, "u1", "b" * 16, model="New", os_version="x", app_version="1", notify=boom)
    assert "b" * 16 in db.devices


def test_devices_without_a_push_token_are_skipped() -> None:
    db = _Db()
    sent = []
    register_device(db, "u1", "a" * 16, model="Old", os_version="x", app_version="1")
    register_device(db, "u1", "b" * 16, model="New", os_version="x", app_version="1", notify=lambda t, m: sent.append(t))
    assert sent == []
