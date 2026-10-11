from datetime import datetime, timedelta, timezone

import pytest
from fastapi import HTTPException

from app.services.integrity import PACKAGE_NAME, issue_nonce, record_check

NOW = datetime(2026, 10, 11, 12, 0, tzinfo=timezone.utc)


class _Snap:
    def __init__(self, data):
        self._data, self.exists = data, data is not None

    def to_dict(self):
        return dict(self._data) if self._data is not None else None


class _Doc:
    def __init__(self, store, id_):
        self.store, self.id = store, id_

    def get(self):
        return _Snap(self.store.get(self.id))

    def set(self, data, merge=False):
        self.store[self.id] = dict(data)

    def delete(self):
        self.store.pop(self.id, None)


class _Db:
    def __init__(self):
        self.stores = {"integrityChallenges": {}, "integrityChecks": {}, "integrityLog": {}}

    def collection(self, name):
        stores = self.stores

        class C:
            def document(self, id_=None):
                return _Doc(stores[name], id_ or f"auto{len(stores[name])}")

        return C()


def _payload(nonce, **over):
    base = {
        "requestDetails": {
            "requestPackageName": PACKAGE_NAME,
            "nonce": nonce,
            "timestampMillis": str(int(NOW.timestamp() * 1000)),
        },
        "deviceIntegrity": {"deviceRecognitionVerdict": ["MEETS_DEVICE_INTEGRITY"]},
        "appIntegrity": {"appRecognitionVerdict": "UNRECOGNIZED_VERSION"},
        "accountDetails": {"appLicensingVerdict": "UNEVALUATED"},
    }
    base.update(over)
    return base


def test_good_verdict_is_recorded_without_identifiers() -> None:
    db = _Db()
    nonce = issue_nonce(db, "u1", NOW)
    out = record_check(db, "u1", "tok", decode=lambda t: _payload(nonce), now=NOW)
    assert out == {"recorded": True}
    row = db.stores["integrityChecks"]["u1"]
    assert row["device"] == ["MEETS_DEVICE_INTEGRITY"]
    assert row["app"] == "UNRECOGNIZED_VERSION"
    assert "nonce" not in row and "token" not in row
    assert len(db.stores["integrityLog"]) == 1


def test_nonce_is_single_use() -> None:
    db = _Db()
    nonce = issue_nonce(db, "u1", NOW)
    record_check(db, "u1", "tok", decode=lambda t: _payload(nonce), now=NOW)
    with pytest.raises(HTTPException) as caught:
        record_check(db, "u1", "tok", decode=lambda t: _payload(nonce), now=NOW)
    assert caught.value.status_code == 400


def test_expired_nonce_is_refused() -> None:
    db = _Db()
    nonce = issue_nonce(db, "u1", NOW)
    with pytest.raises(HTTPException):
        record_check(
            db, "u1", "tok", decode=lambda t: _payload(nonce),
            now=NOW + timedelta(minutes=6),
        )
    assert db.stores["integrityLog"] == {}


@pytest.mark.parametrize(
    "mutate, problem",
    [
        (lambda n: _payload("other"), "nonce_mismatch"),
        (lambda n: _payload(n, requestDetails={"requestPackageName": "x.y", "nonce": n}), "package_mismatch"),
        (lambda n: _payload(n, requestDetails={"requestPackageName": PACKAGE_NAME, "nonce": n, "timestampMillis": "1000"}), "token_too_old"),
    ],
)
def test_bad_token_contents_are_recorded_as_a_problem_not_a_verdict(mutate, problem) -> None:
    db = _Db()
    nonce = issue_nonce(db, "u1", NOW)
    out = record_check(db, "u1", "tok", decode=lambda t: mutate(nonce), now=NOW)
    assert out == {"recorded": False}
    row = db.stores["integrityChecks"]["u1"]
    assert row["problem"] == problem and "device" not in row


def test_decode_failure_never_raises() -> None:
    db = _Db()
    issue_nonce(db, "u1", NOW)

    def boom(_):
        raise RuntimeError("decode_http_403")

    out = record_check(db, "u1", "tok", decode=boom, now=NOW)
    assert out == {"recorded": False}
    assert db.stores["integrityChecks"]["u1"]["problem"].startswith("decode_failed")


def test_missing_token_is_refused() -> None:
    with pytest.raises(HTTPException):
        record_check(_Db(), "u1", "")
