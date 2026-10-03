from datetime import datetime, timezone
from types import SimpleNamespace

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.services.admin_audit_service import admin_audit_service
from app.services.admin_auth_service import admin_auth_service
from app.services.admin_wallet_ledger_service import admin_wallet_ledger_service

client = TestClient(app)
AUTH = {"Authorization": "Bearer test-token"}


class MemorySnap:
    def __init__(self, doc_id: str, data: dict | None) -> None:
        self.id = doc_id
        self.exists = data is not None
        self._data = data

    def to_dict(self) -> dict | None:
        return None if self._data is None else dict(self._data)


class MemoryDoc:
    def __init__(self, db: "MemoryDb", path: str) -> None:
        self.db = db
        self.path = path
        self.id = path.rsplit("/", 1)[-1]

    def get(self) -> MemorySnap:
        self.db.reads += 1
        return MemorySnap(self.id, self.db.docs.get(self.path))

    def set(self, data: dict) -> None:
        self.db.writes.append(self.path)
        self.db.docs[self.path] = dict(data)


class MemoryQuery:
    def __init__(self, db: "MemoryDb", path: str) -> None:
        self.db = db
        self.path = path
        self._limit: int | None = None
        self._where: list[tuple[str, str]] = []

    def where(self, field: str, op: str, value: str) -> "MemoryQuery":
        assert op == "=="
        self._where.append((field, value))
        return self

    def order_by(self, *_args, **_kwargs) -> "MemoryQuery":
        return self

    def limit(self, count: int) -> "MemoryQuery":
        self._limit = count
        return self

    def stream(self) -> list[MemorySnap]:
        self.db.reads += 1
        prefix = f"{self.path}/"
        rows: list[tuple[str, dict]] = []
        for path, data in self.db.docs.items():
            if not path.startswith(prefix):
                continue
            doc_id = path[len(prefix) :]
            if "/" in doc_id:
                continue
            if any(data.get(field) != expected for field, expected in self._where):
                continue
            rows.append((doc_id, data))

        def sort_key(item: tuple[str, dict]):
            created = item[1].get("createdAt")
            if isinstance(created, datetime):
                return created
            return datetime.min.replace(tzinfo=timezone.utc)

        rows.sort(key=sort_key, reverse=True)
        if self._limit is not None:
            rows = rows[: self._limit]
        return [MemorySnap(doc_id, data) for doc_id, data in rows]


class MemoryCollection:
    def __init__(self, db: "MemoryDb", path: str) -> None:
        self.db = db
        self.path = path

    def document(self, doc_id: str | None = None) -> MemoryDoc:
        if not doc_id:
            self.db.seq += 1
            doc_id = f"auto-{self.db.seq}"
        return MemoryDoc(self.db, f"{self.path}/{doc_id}")

    def where(self, *args, **kwargs) -> MemoryQuery:
        return MemoryQuery(self.db, self.path).where(*args, **kwargs)


class MemoryDb:
    def __init__(self, docs: dict[str, dict]) -> None:
        self.docs = dict(docs)
        self.reads = 0
        self.writes: list[str] = []
        self.seq = 0

    def collection(self, name: str) -> MemoryCollection:
        self.reads += 1
        return MemoryCollection(self, name)


@pytest.fixture(autouse=True)
def reset_admin():
    admin_auth_service._verify_token = None
    admin_auth_service._admin_doc_exists = None
    admin_wallet_ledger_service.firebase_service = None
    admin_audit_service.firebase_service = None
    yield
    admin_auth_service._verify_token = None
    admin_auth_service._admin_doc_exists = None
    admin_wallet_ledger_service.firebase_service = None
    admin_audit_service.firebase_service = None


def _admin() -> None:
    admin_auth_service._verify_token = lambda _token: {
        "uid": "admin-1",
        "email": "admin@share-run-challenge.app",
    }
    admin_auth_service._admin_doc_exists = lambda _uid: False


def _bind(docs: dict[str, dict]) -> MemoryDb:
    db = MemoryDb(docs)
    bound = SimpleNamespace(db=db)
    admin_wallet_ledger_service.firebase_service = bound
    admin_audit_service.firebase_service = bound
    return db


def test_wallet_ledger_missing_token_is_401() -> None:
    db = _bind({})

    response = client.get("/admin/wallet-ledger", params={"uid": "u1"})

    assert response.status_code == 401
    assert db.reads == 0
    assert db.writes == []


def test_wallet_ledger_non_admin_is_403() -> None:
    admin_auth_service._verify_token = lambda _token: {
        "uid": "runner",
        "email": "runner@example.com",
    }
    admin_auth_service._admin_doc_exists = lambda _uid: False
    db = _bind({})

    response = client.get("/admin/wallet-ledger", headers=AUTH, params={"uid": "u1"})

    assert response.status_code == 403
    assert db.reads == 0
    assert db.writes == []


def test_wallet_ledger_sums_seed_gap_and_audit() -> None:
    _admin()
    created = datetime(2026, 10, 2, 15, 0, tzinfo=timezone.utc)
    db = _bind(
        {
            "users/u1": {
                "nickname": "러너",
                "email": "runner@example.com",
                "wallet": {
                    "shareBalance": 150,
                    "diamondBalance": 3,
                    "valueTokenBalance": 1_000_000,
                },
            },
            "walletTransactions/topup": {
                "uid": "u1",
                "type": "share_top_up",
                "shareAmount": 100,
                "paymentIntentId": "pi-1",
                "createdAt": datetime(2026, 10, 1, 1, 0, tzinfo=timezone.utc),
            },
            "walletTransactions/join": {
                "uid": "u1",
                "type": "tournament_entry",
                "shareAmount": 50,
                "diamondAmount": -5,
                "tournamentId": "room-1",
                "createdAt": created,
            },
            "walletTransactions/sponsor": {
                "uid": "u1",
                "type": "sponsor_payment_verified",
                "shareAmount": 0,
                "tournamentId": "room-9",
                "createdAt": datetime(2026, 10, 2, 1, 0, tzinfo=timezone.utc),
            },
            "walletTransactions/other": {
                "uid": "someone-else",
                "type": "share_top_up",
                "shareAmount": 999,
                "createdAt": created,
            },
        }
    )

    response = client.get("/admin/wallet-ledger", headers=AUTH, params={"uid": "u1"})

    assert response.status_code == 200
    body = response.json()
    assert body["uid"] == "u1"
    assert body["nickname"] == "러너"
    assert body["email"] == "runner@example.com"
    assert body["truncated"] is False
    by_currency = {row["currency"]: row for row in body["currencies"]}
    assert by_currency["SHARE"] == {
        "currency": "SHARE",
        "balance": 150,
        "ledgerSum": 150,
        "mismatch": False,
        "seedGap": False,
    }
    assert by_currency["DIA"]["balance"] == 3
    assert by_currency["DIA"]["ledgerSum"] == -5
    assert by_currency["DIA"]["mismatch"] is True
    assert by_currency["DIA"]["seedGap"] is False
    assert by_currency["VALUE"]["balance"] == 1_000_000
    assert by_currency["VALUE"]["ledgerSum"] == 0
    assert by_currency["VALUE"]["mismatch"] is True
    assert by_currency["VALUE"]["seedGap"] is True
    join = [
        row
        for row in body["entries"]
        if row["id"] == "join" and row["currency"] == "SHARE"
    ]
    assert join[0]["amount"] == 50
    assert join[0]["timeKst"] == "2026-10-03 00:00:00"
    assert join[0]["relatedId"] == "room-1"
    assert any(row["id"] == "join" and row["currency"] == "DIA" for row in body["entries"])
    assert any(
        row["id"] == "sponsor" and row["amount"] == 0 and row["currency"] == "SHARE"
        for row in body["entries"]
    )
    assert all(row["id"] != "other" for row in body["entries"])
    assert db.writes == ["adminAuditLogs/auto-1"]
    log = db.docs["adminAuditLogs/auto-1"]
    assert log["action"] == "wallet_ledger_lookup"
    assert log["uid"] == "admin-1"
    assert log["targetUid"] == "u1"
    assert log["reason"] == "read wallet ledger"
    assert not any(path.startswith("users/") or path.startswith("walletTransactions/") for path in db.writes)


def test_wallet_ledger_missing_user_is_404_and_audited() -> None:
    _admin()
    db = _bind({})

    response = client.get("/admin/wallet-ledger", headers=AUTH, params={"uid": "missing"})

    assert response.status_code == 404
    assert db.writes == ["adminAuditLogs/auto-1"]
    assert db.docs["adminAuditLogs/auto-1"]["reason"] == "user not found"
    assert db.docs["adminAuditLogs/auto-1"]["targetUid"] == "missing"
