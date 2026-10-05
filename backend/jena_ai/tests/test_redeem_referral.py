from copy import deepcopy
from datetime import datetime, timedelta, timezone
from types import SimpleNamespace
from unittest.mock import MagicMock, patch

import pytest
from fastapi import HTTPException
from google.cloud.firestore_v1 import SERVER_TIMESTAMP
from google.cloud.firestore_v1.transforms import Increment

from app.services.secured_action_service import (
    SecuredActionService,
    _commit_redeem_referral_tx,
)


class _MemoryDoc:
    def __init__(self, store: dict, path: str) -> None:
        self._store = store
        self.path = path

    @property
    def id(self) -> str:
        return self.path.rsplit("/", 1)[-1]

    def get(self, transaction=None):
        data = self._store.get(self.path)
        snapshot = MagicMock()
        snapshot.exists = data is not None
        snapshot.to_dict.return_value = None if data is None else deepcopy(data)
        return snapshot

    def collection(self, name: str) -> "_MemoryCollection":
        return _MemoryCollection(self._store, f"{self.path}/{name}")


class _MemoryCollection:
    def __init__(self, store: dict, name: str) -> None:
        self._store = store
        self._name = name

    def document(self, doc_id: str | None = None) -> _MemoryDoc:
        if not doc_id:
            doc_id = f"auto{len(self._store)}"
        return _MemoryDoc(self._store, f"{self._name}/{doc_id}")

    def where(self, field: str, op: str, value):
        return _MemoryQuery(self._store, self._name, [(field, op, value)])

    def get(self, transaction=None):
        return _child_snapshots(self._store, self._name)


class _MemoryQuery:
    def __init__(
        self,
        store: dict,
        name: str,
        filters: list | None = None,
        group: bool = False,
    ) -> None:
        self._store = store
        self._name = name
        self._filters = list(filters or [])
        self._group = group
        self._limit = None

    def where(self, field: str, op: str, value) -> "_MemoryQuery":
        return _MemoryQuery(
            self._store,
            self._name,
            [*self._filters, (field, op, value)],
            group=self._group,
        )

    def limit(self, count: int) -> "_MemoryQuery":
        self._limit = count
        return self

    def get(self, transaction=None):
        snapshots = (
            _group_snapshots(self._store, self._name)
            if self._group
            else _child_snapshots(self._store, self._name)
        )
        matched = [
            snapshot
            for snapshot in snapshots
            if _matches(snapshot.to_dict(), self._filters)
        ]
        if self._limit is not None:
            return matched[: self._limit]
        return matched


def _matches(data: dict, filters: list) -> bool:
    for field, op, value in filters:
        current = data
        for part in field.split("."):
            if not isinstance(current, dict) or part not in current:
                current = None
                break
            current = current[part]
        if op != "==" or current != value:
            return False
    return True


def _group_snapshots(store: dict, name: str) -> list:
    token = f"/{name}/"
    snapshots = []
    for path, data in store.items():
        marked = f"/{path}"
        if token not in marked:
            continue
        tail = marked.split(token, 1)[1]
        if "/" in tail:
            continue
        snapshot = MagicMock()
        snapshot.id = tail
        snapshot.exists = True
        snapshot.to_dict.return_value = deepcopy(data)
        snapshot.reference = _MemoryDoc(store, path)
        snapshots.append(snapshot)
    return snapshots


def _child_snapshots(store: dict, name: str) -> list:
    prefix = f"{name}/"
    depth = name.count("/") + 1
    snapshots = []
    for path, data in store.items():
        if not path.startswith(prefix) or path.count("/") != depth:
            continue
        snapshot = MagicMock()
        snapshot.id = path.rsplit("/", 1)[-1]
        snapshot.exists = True
        snapshot.to_dict.return_value = deepcopy(data)
        snapshot.reference = _MemoryDoc(store, path)
        snapshots.append(snapshot)
    return snapshots


class _MemoryTxn:
    def set(self, ref: _MemoryDoc, data: dict, merge: bool = False) -> None:
        if merge and ref.path in ref._store:
            current = ref._store[ref.path]
            current.update(deepcopy(data))
            return
        ref._store[ref.path] = deepcopy(data)

    def update(self, ref: _MemoryDoc, data: dict) -> None:
        current = ref._store[ref.path]
        for key, value in data.items():
            if isinstance(value, Increment):
                _assign_increment(current, key, value.value)
                continue
            if "." not in key:
                current[key] = value
                continue
            parent, child = key.split(".", 1)
            nested = dict(current.get(parent) or {})
            nested[child] = value
            current[parent] = nested

    def get(self, ref_or_query):
        return ref_or_query.get(transaction=self)


def _assign_increment(current: dict, key: str, amount) -> None:
    if "." not in key:
        current[key] = (current.get(key) or 0) + amount
        return
    parent, child = key.split(".", 1)
    nested = dict(current.get(parent) or {})
    nested[child] = (nested.get(child) or 0) + amount
    current[parent] = nested


class _MemoryDb:
    def __init__(self) -> None:
        self.store: dict[str, dict] = {}

    def collection(self, name: str) -> _MemoryCollection:
        return _MemoryCollection(self.store, name)

    def collection_group(self, name: str) -> _MemoryQuery:
        return _MemoryQuery(self.store, name, group=True)

    def transaction(self) -> _MemoryTxn:
        return _MemoryTxn()


def _service(db: _MemoryDb) -> SecuredActionService:
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))
    service._auth_account_created_at = lambda uid: _NOW

    def commit(transaction, uid, user_ref, code, created_at):
        return service._apply_redeem_referral(
            transaction, uid, user_ref, code, created_at, now=_NOW
        )

    service._commit_redeem_referral = commit
    return service


_NOW = datetime(2026, 10, 1, tzinfo=timezone.utc)


def _redeem(service: SecuredActionService, uid: str, code: str, created_at):
    user_ref = service.firebase_service.db.collection("users").document(uid)
    return service._apply_redeem_referral(
        _MemoryTxn(),
        uid,
        user_ref,
        code,
        created_at,
        now=_NOW,
    )


def test_redeem_pays_referee_1000_share_once() -> None:
    db = _MemoryDb()
    db.store["users/u2"] = {
        "economy": {"referralCode": "KEEP", "referralPayoutCount": 1},
        "wallet": {"shareBalance": 40},
    }
    db.store["referralCodes/AB23CD45"] = {"uid": "u1", "createdAt": "kept"}
    service = _service(db)

    result = service.redeem_referral_code("u2", " ab23cd45 ")

    assert result.referred_by == "u1"
    assert result.code == "AB23CD45"
    economy = db.store["users/u2"]["economy"]
    assert economy["referredBy"] == "u1"
    assert economy["referredByCode"] == "AB23CD45"
    assert economy["referredAt"] is SERVER_TIMESTAMP
    assert economy["referralCode"] == "KEEP"
    assert economy["referralPayoutCount"] == 1
    assert "referredByUid" not in economy
    assert db.store["users/u2"]["wallet"]["shareBalance"] == 10_040
    marker = db.store["referralPayouts/u2_redeem"]
    assert marker["amount"] == 10_000
    assert marker["payeeUid"] == "u2"
    assert db.store["users/u2/wallet_transactions/referral_u2_redeem"]["amount"] == 10_000
    assert db.store["walletTransactions/referral_u2_u2_redeem"]["shareAmount"] == 10_000
    with pytest.raises(HTTPException) as again:
        service.redeem_referral_code("u2", "AB23CD45")
    assert again.value.detail == "already"
    assert db.store["users/u2"]["wallet"]["shareBalance"] == 10_040
    assert db.store["referralCodes/AB23CD45"]["uid"] == "u1"
    assert db.store["referralCodes/AB23CD45"]["createdAt"] == "kept"
    assert db.store["referralCodes/AB23CD45"]["redeemCount"] == 1
    assert db.store["referralCodes/AB23CD45/referrals/u2"] == {
        "createdAt": SERVER_TIMESTAMP
    }


def test_redeem_increments_existing_count() -> None:
    db = _MemoryDb()
    db.store["users/u2"] = {"economy": {}}
    db.store["referralCodes/AB23CD45"] = {"uid": "u1", "redeemCount": 3}
    created = _NOW - timedelta(days=7)

    result = _redeem(_service(db), "u2", "AB23CD45", created)

    assert result.code == "AB23CD45"
    assert db.store["referralCodes/AB23CD45"]["redeemCount"] == 4


def test_missing_code_is_invalid_and_writes_nothing() -> None:
    db = _MemoryDb()
    db.store["users/u2"] = {"economy": {"referralPayoutCount": 1}}
    service = _service(db)

    with pytest.raises(HTTPException) as exc_info:
        _redeem(service, "u2", "NOSUCH1", _NOW)

    assert exc_info.value.status_code == 400
    assert exc_info.value.detail == "invalid"
    assert db.store["users/u2"]["economy"] == {"referralPayoutCount": 1}
    assert len(db.store) == 1


def test_code_without_owner_is_invalid() -> None:
    db = _MemoryDb()
    db.store["users/u2"] = {"economy": {}}
    db.store["referralCodes/AB23CD45"] = {"createdAt": "kept"}

    with pytest.raises(HTTPException) as exc_info:
        _redeem(_service(db), "u2", "AB23CD45", _NOW)

    assert exc_info.value.detail == "invalid"
    assert "redeemCount" not in db.store["referralCodes/AB23CD45"]


def test_own_code_is_rejected() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {"economy": {}}
    db.store["referralCodes/AB23CD45"] = {"uid": "u1"}

    with pytest.raises(HTTPException) as exc_info:
        _redeem(_service(db), "u1", "AB23CD45", _NOW)

    assert exc_info.value.detail == "self"
    assert "referredBy" not in db.store["users/u1"]["economy"]


def test_second_redeem_is_already() -> None:
    db = _MemoryDb()
    db.store["users/u2"] = {"economy": {"referredBy": "u1", "referralCode": "KEEP"}}
    db.store["referralCodes/K7MNPQ23"] = {"uid": "u3"}

    with pytest.raises(HTTPException) as exc_info:
        _redeem(_service(db), "u2", "K7MNPQ23", _NOW)

    assert exc_info.value.detail == "already"
    assert db.store["users/u2"]["economy"]["referralCode"] == "KEEP"
    assert "redeemCount" not in db.store["referralCodes/K7MNPQ23"]


def test_account_older_than_seven_days_is_expired() -> None:
    db = _MemoryDb()
    db.store["users/u2"] = {"economy": {}}
    db.store["referralCodes/AB23CD45"] = {"uid": "u1"}
    created = _NOW - timedelta(days=7, seconds=1)

    with pytest.raises(HTTPException) as exc_info:
        _redeem(_service(db), "u2", "AB23CD45", created)

    assert exc_info.value.detail == "expired"
    assert "referredBy" not in db.store["users/u2"]["economy"]


def test_missing_auth_timestamp_is_not_expired() -> None:
    db = _MemoryDb()
    db.store["users/u2"] = {"economy": {}}
    db.store["referralCodes/AB23CD45"] = {"uid": "u1"}

    result = _redeem(_service(db), "u2", "AB23CD45", None)

    assert result.referred_by == "u1"


def test_missing_user_document_is_not_found() -> None:
    db = _MemoryDb()
    db.store["referralCodes/AB23CD45"] = {"uid": "u1"}

    with pytest.raises(HTTPException) as exc_info:
        _redeem(_service(db), "u2", "AB23CD45", _NOW)

    assert exc_info.value.status_code == 404
    assert "referralCodes/AB23CD45/referrals/u2" not in db.store


def test_blank_or_unsafe_code_is_invalid_before_auth() -> None:
    service = SecuredActionService(firebase_service=MagicMock())

    for code in ("   ", "ab/cd", "x" * 33):
        with pytest.raises(HTTPException) as exc_info:
            service.redeem_referral_code("u1", code)
        assert exc_info.value.detail == "invalid"

    service.firebase_service.db.collection.assert_not_called()


@patch("app.services.secured_action_service.firebase_auth.get_user")
def test_auth_creation_timestamp_is_the_age_clock(mock_get_user: MagicMock) -> None:
    mock_get_user.return_value = SimpleNamespace(
        user_metadata=SimpleNamespace(creation_timestamp=1_700_000_000_000)
    )
    service = SecuredActionService(firebase_service=MagicMock())

    created = service._auth_account_created_at("u1")

    assert created == datetime.fromtimestamp(1_700_000_000, tz=timezone.utc)


@patch("app.services.secured_action_service.firebase_auth.get_user")
def test_missing_auth_user_is_not_found(mock_get_user: MagicMock) -> None:
    from firebase_admin import auth as firebase_auth

    mock_get_user.side_effect = firebase_auth.UserNotFoundError("missing")
    service = SecuredActionService(firebase_service=MagicMock())

    with pytest.raises(HTTPException) as exc_info:
        service._auth_account_created_at("missing")

    assert exc_info.value.status_code == 404
    assert exc_info.value.detail == "User not found."


def test_transaction_wrapper_passes_transaction_before_service() -> None:
    service = MagicMock()
    service._apply_redeem_referral.return_value = "ok"

    issued = _commit_redeem_referral_tx.to_wrap(
        "transaction", service, "u2", "user-ref", "AB23CD45", None
    )

    assert issued == "ok"
    service._apply_redeem_referral.assert_called_once_with(
        "transaction", "u2", "user-ref", "AB23CD45", None
    )
