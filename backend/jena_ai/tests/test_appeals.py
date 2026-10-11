import base64
from datetime import datetime, timedelta, timezone

import pytest
from fastapi import HTTPException

from app.services.appeals import MAX_PROOF_BYTES, submit_appeal

NOW = datetime(2026, 10, 11, 12, 0, tzinfo=timezone.utc)
JPEG = b"\xff\xd8\xff\xe0" + b"0" * 100


def _b64(data: bytes = JPEG) -> str:
    return base64.b64encode(data).decode()


class _Snap:
    def __init__(self, data):
        self._data = data
        self.exists = data is not None

    def to_dict(self):
        return dict(self._data) if self._data is not None else None


class _Doc:
    def __init__(self, store, id_):
        self.store, self.id = store, id_

    def get(self):
        return _Snap(self.store.get(self.id))

    def set(self, data, merge=False):
        if merge:
            self.store.setdefault(self.id, {}).update(data)
        else:
            self.store[self.id] = dict(data)


class _Db:
    def __init__(self, activity=None):
        self.stores = {
            "activities": {"a1": activity} if activity is not None else {},
            "users": {"u1": {"nickname": "달리는\n사람"}},
            "appeals": {},
            "appealProofs": {},
        }

    def collection(self, name):
        stores = self.stores

        class C:
            def document(self, id_):
                return _Doc(stores[name], id_)

        return C()


def _run(**over):
    base = {
        "userId": "u1",
        "jenaVerified": False,
        "jenaDecision": "rejected_unknown",
        "jenaReason": "케이던스 범위를 벗어났습니다.",
        "distanceKm": 3.2,
        "completedAt": NOW - timedelta(days=1),
    }
    base.update(over)
    return base


def _submit(db, **over):
    kwargs = dict(
        activity_id="a1",
        reason_category="GPS 오류",
        reason_detail="터널 구간이었어요",
        proof_base64=_b64(),
        now=NOW,
    )
    kwargs.update(over)
    return submit_appeal(db, "u1", **kwargs)


def test_rejected_run_creates_appeal_proof_and_lock() -> None:
    db = _Db(_run())
    assert _submit(db) == {"status": "under_review", "appeal_id": "appeal-a1"}
    appeal = db.stores["appeals"]["appeal-a1"]
    assert appeal["userId"] == "u1" and appeal["status"] == "under_review"
    assert appeal["userNickname"] == "달리는 사람"
    assert appeal["purgeAt"] == NOW + timedelta(days=14)
    assert db.stores["appealProofs"]["appeal-a1"]["bytes"] == JPEG
    run = db.stores["activities"]["a1"]
    assert run["appealStatus"] == "under_review" and run["locked"] is True


def test_sending_twice_changes_nothing() -> None:
    db = _Db(_run())
    _submit(db)
    first = dict(db.stores["appeals"]["appeal-a1"])
    assert _submit(db)["status"] == "under_review"
    assert db.stores["appeals"]["appeal-a1"] == first


@pytest.mark.parametrize(
    "run, code",
    [
        (_run(userId="someone-else"), 404),
        (_run(jenaVerified=True, jenaDecision="verified"), 400),
        (_run(completedAt=NOW - timedelta(days=15)), 400),
        (_run(appealStatus="approved", appealId="appeal-a1"), 409),
    ],
)
def test_runs_that_cannot_be_appealed(run, code) -> None:
    db = _Db(run)
    with pytest.raises(HTTPException) as caught:
        _submit(db)
    assert caught.value.status_code == code
    assert db.stores["appeals"] == {} and db.stores["appealProofs"] == {}


def test_missing_run_is_not_found() -> None:
    with pytest.raises(HTTPException) as caught:
        _submit(_Db())
    assert caught.value.status_code == 404


@pytest.mark.parametrize(
    "proof, code",
    [
        ("%%%not base64%%%", 400),
        (_b64(b"plain text, not an image"), 400),
        (_b64(JPEG + b"0" * MAX_PROOF_BYTES), 413),
    ],
)
def test_bad_photo_is_refused_before_anything_is_written(proof, code) -> None:
    db = _Db(_run())
    with pytest.raises(HTTPException) as caught:
        _submit(db, proof_base64=proof)
    assert caught.value.status_code == code
    assert db.stores["appeals"] == {}
    assert "appealStatus" not in db.stores["activities"]["a1"]
