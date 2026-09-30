from copy import deepcopy
from types import SimpleNamespace
from unittest.mock import MagicMock

import pytest
from fastapi import HTTPException

from app.services.secured_action_service import (
    InviteCodeCollision,
    SecuredActionService,
    _commit_invite_code_tx,
)


class _MemoryDoc:
    def __init__(self, store: dict, path: str) -> None:
        self._store = store
        self.path = path

    def get(self, transaction=None):
        data = self._store.get(self.path)
        snapshot = MagicMock()
        snapshot.exists = data is not None
        snapshot.to_dict.return_value = None if data is None else deepcopy(data)
        return snapshot


class _MemoryCollection:
    def __init__(self, store: dict, name: str) -> None:
        self._store = store
        self._name = name

    def document(self, doc_id: str) -> _MemoryDoc:
        return _MemoryDoc(self._store, f"{self._name}/{doc_id}")


class _MemoryTxn:
    def set(self, ref: _MemoryDoc, data: dict) -> None:
        ref._store[ref.path] = deepcopy(data)

    def update(self, ref: _MemoryDoc, data: dict) -> None:
        current = ref._store[ref.path]
        for key, value in data.items():
            if "." not in key:
                current[key] = value
                continue
            parent, child = key.split(".", 1)
            nested = dict(current.get(parent) or {})
            nested[child] = value
            current[parent] = nested


class _MemoryDb:
    def __init__(self) -> None:
        self.store: dict[str, dict] = {}

    def collection(self, name: str) -> _MemoryCollection:
        return _MemoryCollection(self.store, name)

    def transaction(self) -> _MemoryTxn:
        return _MemoryTxn()


def _service(db: _MemoryDb) -> SecuredActionService:
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))

    def commit(transaction, uid, user_ref, code):
        return service._allocate_invite_code(transaction, uid, user_ref, code)

    service._commit_invite_code = commit
    return service


def test_get_or_create_is_idempotent_and_retries_collisions() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {"economy": {"signupRewardClaimed": True}}
    db.store["users/u2"] = {"economy": {"trialRunCount": 1}}
    service = _service(db)
    codes = iter(["AB23CD45", "AB23CD45", "K7MNPQ23", "UNUSED99"])
    service._economy_service.generate_invite_code = lambda: next(codes)

    first = service.get_or_create_invite_code("u1")
    second = service.get_or_create_invite_code("u2")
    again = service.get_or_create_invite_code("u1")

    assert first.referral_code == "AB23CD45"
    assert again.referral_code == "AB23CD45"
    assert second.referral_code == "K7MNPQ23"
    assert db.store["referralCodes/AB23CD45"]["uid"] == "u1"
    assert db.store["referralCodes/K7MNPQ23"]["uid"] == "u2"
    assert "referralCodes/UNUSED99" not in db.store
    assert db.store["users/u1"]["economy"]["signupRewardClaimed"] is True
    assert db.store["users/u2"]["economy"]["trialRunCount"] == 1
    assert db.store["users/u2"]["economy"]["referralCode"] == "K7MNPQ23"


def test_existing_code_is_indexed_and_not_replaced() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {
        "economy": {"referralCode": "deadbeef", "referralPayoutCount": 2}
    }
    service = _service(db)
    service._economy_service.generate_invite_code = lambda: "AB23CD45"

    result = service.get_or_create_invite_code("u1")

    assert result.referral_code == "deadbeef"
    assert db.store["referralCodes/deadbeef"]["uid"] == "u1"
    assert "referralCodes/AB23CD45" not in db.store
    assert db.store["users/u1"]["economy"]["referralCode"] == "deadbeef"
    assert db.store["users/u1"]["economy"]["referralPayoutCount"] == 2

    db.store["referralCodes/deadbeef"]["createdAt"] = "kept"
    again = service.get_or_create_invite_code("u1")
    assert again.referral_code == "deadbeef"
    assert db.store["referralCodes/deadbeef"] == {"uid": "u1", "createdAt": "kept"}


def test_collided_existing_code_is_replaced() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {
        "economy": {"referralCode": "deadbeef", "referralPayoutCount": 2}
    }
    db.store["referralCodes/deadbeef"] = {"uid": "u2", "createdAt": "theirs"}
    service = _service(db)
    service._economy_service.generate_invite_code = lambda: "AB23CD45"

    result = service.get_or_create_invite_code("u1")

    assert result.referral_code == "AB23CD45"
    assert db.store["users/u1"]["economy"]["referralCode"] == "AB23CD45"
    assert db.store["users/u1"]["economy"]["referralPayoutCount"] == 2
    assert db.store["referralCodes/deadbeef"] == {"uid": "u2", "createdAt": "theirs"}
    assert db.store["referralCodes/AB23CD45"]["uid"] == "u1"


def test_owned_index_doc_is_reused_without_rewriting_it() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {"economy": {}}
    db.store["referralCodes/AB23CD45"] = {"uid": "u1", "createdAt": "kept"}
    service = _service(db)

    issued = service._allocate_invite_code(
        _MemoryTxn(),
        "u1",
        db.collection("users").document("u1"),
        "AB23CD45",
    )

    assert issued == "AB23CD45"
    assert db.store["referralCodes/AB23CD45"]["createdAt"] == "kept"
    assert db.store["users/u1"]["economy"]["referralCode"] == "AB23CD45"


def test_missing_user_is_not_retried() -> None:
    db = _MemoryDb()
    service = _service(db)
    calls = {"n": 0}
    allocate = service._allocate_invite_code

    def counting(transaction, uid, user_ref, code):
        calls["n"] += 1
        return allocate(transaction, uid, user_ref, code)

    service._commit_invite_code = counting

    with pytest.raises(HTTPException) as exc_info:
        service.get_or_create_invite_code("missing")

    assert exc_info.value.status_code == 404
    assert calls["n"] == 1


def test_repeated_collisions_fail_without_writing() -> None:
    service = SecuredActionService(firebase_service=MagicMock())
    service._economy_service.generate_invite_code = lambda: "AB23CD45"

    def collide(transaction, uid, user_ref, code):
        raise InviteCodeCollision()

    service._commit_invite_code = collide

    with pytest.raises(HTTPException) as exc_info:
        service.get_or_create_invite_code("u1")

    assert exc_info.value.status_code == 503
    assert service.firebase_service.db.transaction.call_count == (
        SecuredActionService._INVITE_CODE_ATTEMPTS
    )


def test_transaction_wrapper_passes_transaction_before_service() -> None:
    service = MagicMock()
    service._allocate_invite_code.return_value = "AB23CD45"

    issued = _commit_invite_code_tx.to_wrap(
        "transaction", service, "u1", "user-ref", "AB23CD45"
    )

    assert issued == "AB23CD45"
    service._allocate_invite_code.assert_called_once_with(
        "transaction", "u1", "user-ref", "AB23CD45"
    )
