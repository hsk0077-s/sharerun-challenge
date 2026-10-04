from types import SimpleNamespace

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.services.admin_auth_service import admin_auth_service
from app.services.admin_wallet_anomaly_service import admin_wallet_anomaly_service

client = TestClient(app)
AUTH = {"Authorization": "Bearer test-token"}
GRANT = 1_000_000


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

    def collection(self, name: str) -> "MemoryCollection":
        self.db.reads += 1
        return MemoryCollection(self.db, f"{self.path}/{name}")


class MemoryQuery:
    def __init__(self, db: "MemoryDb", path: str) -> None:
        self.db = db
        self.path = path
        self._limit: int | None = None
        self._cursor: str | None = None
        self._where: list[tuple[str, str]] = []

    def order_by(self, *_args, **_kwargs) -> "MemoryQuery":
        return self

    def limit(self, count: int) -> "MemoryQuery":
        self._limit = count
        return self

    def start_after(self, values) -> "MemoryQuery":
        self._cursor = values[0].id
        return self

    def where(self, field: str, op: str, value: str) -> "MemoryQuery":
        assert op == "=="
        self._where.append((field, value))
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
            if self._cursor is not None and doc_id <= self._cursor:
                continue
            if any(data.get(field) != expected for field, expected in self._where):
                continue
            rows.append((doc_id, data))
        rows.sort()
        if self._limit is not None:
            rows = rows[: self._limit]
        return [MemorySnap(doc_id, data) for doc_id, data in rows]


class MemoryCollection:
    def __init__(self, db: "MemoryDb", path: str) -> None:
        self.db = db
        self.path = path

    def document(self, doc_id: str) -> MemoryDoc:
        return MemoryDoc(self.db, f"{self.path}/{doc_id}")

    def order_by(self, *args, **kwargs) -> MemoryQuery:
        return MemoryQuery(self.db, self.path).order_by(*args, **kwargs)

    def where(self, *args, **kwargs) -> MemoryQuery:
        return MemoryQuery(self.db, self.path).where(*args, **kwargs)

    def limit(self, count: int) -> MemoryQuery:
        return MemoryQuery(self.db, self.path).limit(count)


class MemoryDb:
    def __init__(self, docs: dict[str, dict]) -> None:
        self.docs = docs
        self.reads = 0

    def collection(self, name: str) -> MemoryCollection:
        self.reads += 1
        return MemoryCollection(self, name)


@pytest.fixture(autouse=True)
def reset_admin():
    admin_auth_service._verify_token = None
    admin_auth_service._admin_doc_exists = None
    admin_wallet_anomaly_service.firebase_service = None
    yield
    admin_auth_service._verify_token = None
    admin_auth_service._admin_doc_exists = None
    admin_wallet_anomaly_service.firebase_service = None


def _admin() -> None:
    admin_auth_service._verify_token = lambda _token: {
        "uid": "admin-1",
        "email": "admin@share-run-challenge.app",
    }
    admin_auth_service._admin_doc_exists = lambda _uid: False


def _bind(docs: dict[str, dict]) -> MemoryDb:
    db = MemoryDb(docs)
    admin_wallet_anomaly_service.firebase_service = SimpleNamespace(db=db)
    return db


def _reasons(body: dict) -> set[tuple[str, str]]:
    return {(row["uid"], row["reason"]) for row in body["rows"]}


def test_wallet_anomalies_missing_token_is_401() -> None:
    db = _bind({})

    response = client.get("/admin/wallet-anomalies")

    assert response.status_code == 401
    assert db.reads == 0


def test_wallet_anomalies_non_admin_is_403() -> None:
    admin_auth_service._verify_token = lambda _token: {
        "uid": "runner",
        "email": "runner@example.com",
    }
    admin_auth_service._admin_doc_exists = lambda _uid: False
    db = _bind({})

    response = client.get("/admin/wallet-anomalies", headers=AUTH)

    assert response.status_code == 403
    assert db.reads == 0


def test_wallet_anomalies_flags_grant_receipt_and_payment() -> None:
    _admin()
    _bind(
        {
            "users/clean": {
                "wallet": {
                    "shareBalance": 1000,
                    "diamondBalance": 0,
                    "valueTokenBalance": 0,
                }
            },
            "users/clean/wallet_transactions/referral_clean_redeem": {
                "uid": "clean",
                "title": "초대 코드 등록",
                "amount": 1000,
                "assetType": "SHARE",
            },
            "walletTransactions/referral_clean": {
                "uid": "clean",
                "type": "referral_redeem",
                "shareAmount": 1000,
            },
            "users/grant": {
                "testGrant1mDone": True,
                "wallet": {
                    "shareBalance": 10,
                    "diamondBalance": 10,
                    "valueTokenBalance": 10,
                },
            },
            "walletTransactions/grant-ledger": {
                "uid": "grant",
                "type": "debug_test_grant_1m",
                "shareAmount": GRANT,
                "diamondAmount": GRANT,
                "valueAmount": GRANT,
            },
            "users/balances": {
                "wallet": {
                    "shareBalance": GRANT,
                    "diamondBalance": GRANT,
                    "valueTokenBalance": GRANT,
                }
            },
            "users/fake": {
                "wallet": {"shareBalance": 10000, "diamondBalance": 0, "valueTokenBalance": 0}
            },
            "users/fake/wallet_transactions/tx-fake": {
                "title": "SHARE 충전",
                "amount": 99999,
                "assetType": "SHARE",
            },
            "users/fake/wallet_transactions/tx-real": {
                "title": "SHARE 충전",
                "amount": 10000,
                "assetType": "SHARE",
            },
            "users/fake/wallet_transactions/tx-dia": {
                "title": "상점",
                "amount": -500,
                "assetType": "DIA",
            },
            "walletTransactions/fake-share": {
                "uid": "fake",
                "type": "share_top_up",
                "shareAmount": 10000,
            },
            "users/paid": {"wallet": {"shareBalance": 10000}},
            "users/paid/wallet_transactions/tx-paid": {
                "amount": 10000,
                "assetType": "SHARE",
            },
            "paymentIntents/paid-1": {
                "uid": "paid",
                "type": "share_top_up",
                "amountKrw": 10000,
                "status": "credited",
            },
            "users/mismatch": {"wallet": {"shareBalance": 0}},
            "paymentIntents/bad-1": {
                "uid": "mismatch",
                "type": "share_top_up",
                "amountKrw": 10000,
                "pgAmount": 5000,
                "status": "amount_mismatch",
            },
            "users/debt": {
                "wallet": {
                    "shareBalance": -20,
                    "diamondBalance": 0,
                    "valueTokenBalance": 1,
                }
            },
        }
    )

    response = client.get("/admin/wallet-anomalies", headers=AUTH, params={"limit": 40})

    assert response.status_code == 200
    body = response.json()
    reasons = _reasons(body)
    assert ("clean", "unmatched_receipt") not in reasons
    assert ("clean", "debug_test_grant_1m") not in reasons
    assert ("grant", "debug_test_grant_1m") in reasons
    assert ("balances", "debug_test_grant_1m") in reasons
    grant = next(row for row in body["rows"] if row["uid"] == "grant")
    assert "testGrant1mDone" in grant["detail"]
    assert "원장 type=debug_test_grant_1m" in grant["detail"]
    balances = next(row for row in body["rows"] if row["uid"] == "balances")
    assert "shareBalance=1000000" in balances["detail"]
    assert not any(row["uid"] == "fake" for row in body["rows"])
    assert ("paid", "unmatched_receipt") not in reasons
    assert ("mismatch", "payment_amount_mismatch") in reasons
    debt = next(row for row in body["rows"] if row["uid"] == "debt")
    assert debt["reason"] == "negative_balance"
    assert debt["shareBalance"] == -20


def test_wallet_anomalies_uid_filter_and_cursor() -> None:
    _admin()
    _bind(
        {
            "users/a": {"wallet": {"shareBalance": 1}},
            "users/b": {"testGrant1mDone": True, "wallet": {"shareBalance": 1}},
        }
    )

    filtered = client.get(
        "/admin/wallet-anomalies",
        headers=AUTH,
        params={"uid": "b"},
    )
    assert filtered.status_code == 200
    body = filtered.json()
    assert body["nextCursor"] is None
    assert [row["uid"] for row in body["rows"]] == ["b"]

    first = client.get(
        "/admin/wallet-anomalies",
        headers=AUTH,
        params={"limit": 1},
    )
    assert first.status_code == 200
    page = first.json()
    assert page["rows"] == []
    assert page["nextCursor"] == "a"

    second = client.get(
        "/admin/wallet-anomalies",
        headers=AUTH,
        params={"limit": 1, "cursor": page["nextCursor"]},
    )
    assert second.status_code == 200
    assert [row["reason"] for row in second.json()["rows"]] == ["debug_test_grant_1m"]
