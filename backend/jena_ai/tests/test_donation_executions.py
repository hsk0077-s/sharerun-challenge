"""Donation execution records: what was really sent, saved by an admin."""

import pytest
from fastapi import HTTPException
from fastapi.testclient import TestClient

from app.main import app
from app.routers import admin_router
from app.services import donation_executions as de
from app.services.admin_auth_service import admin_auth_service
from test_redeem_referral import _MemoryDb


class _Batch:
    def __init__(self, db):
        self.db, self.ops = db, []

    def update(self, ref, fields):
        self.ops.append((ref, fields))

    def commit(self):
        for ref, fields in self.ops:
            ref._store[ref.path].update(fields)


@pytest.fixture(autouse=True)
def _batches(monkeypatch):
    monkeypatch.setattr(_MemoryDb, "batch", lambda self: _Batch(self), raising=False)


def _db() -> _MemoryDb:
    db = _MemoryDb()
    db.store["donationLedger/verified_run_a"] = {"monthKey": "2026-11", "companyWon": 100, "receiptIssued": False, "uid": "u1"}
    db.store["donationLedger/step_goal_u1_20261120"] = {"monthKey": "2026-11", "companyWon": 50, "receiptIssued": False, "uid": "u1"}
    db.store["donationLedger/donation_match_u1_r"] = {"monthKey": "2026-11", "companyWon": 1000, "receiptIssued": False, "uid": "u1"}
    db.store["donationLedger/verified_run_old"] = {"monthKey": "2026-10", "companyWon": 100, "receiptIssued": False, "uid": "u1"}
    return db


def _save(db, **over):
    args = dict(
        month="2026-11",
        amount_won=1150,
        executed_at="2026-12-03",
        partner_name="테스트 기부처",
        receipt_image_path="donation-receipts/2026-11/receipt-1.jpg",
        note="12월 3일 송금",
        created_by="admin1",
    )
    args.update(over)
    return de.record_execution(db, **args)


def _error(**over) -> str:
    with pytest.raises(HTTPException) as caught:
        _save(_db(), **over)
    assert caught.value.status_code == 400
    return caught.value.detail


def test_saving_writes_the_month_record() -> None:
    db = _db()

    out = _save(db)

    doc = db.store["donationExecutions/2026-11"]
    assert doc["month"] == "2026-11"
    assert doc["amountWon"] == 1150
    assert doc["partnerName"] == "테스트 기부처"
    assert doc["receiptImagePath"] == "donation-receipts/2026-11/receipt-1.jpg"
    assert doc["note"] == "12월 3일 송금"
    assert doc["createdBy"] == "admin1"
    assert doc["executedAt"].isoformat().startswith("2026-12-03")
    assert out == {"month": "2026-11", "amount_won": 1150, "replaced": False, "ledger_rows_marked": 3}


def test_saving_marks_only_that_months_ledger_rows() -> None:
    db = _db()

    _save(db)

    for key in ("verified_run_a", "step_goal_u1_20261120", "donation_match_u1_r"):
        assert db.store[f"donationLedger/{key}"]["receiptIssued"] is True
    assert db.store["donationLedger/verified_run_old"]["receiptIssued"] is False


def test_saving_again_replaces_the_record_and_marks_nothing_twice() -> None:
    db = _db()
    _save(db)

    out = _save(db, amount_won=1200, note="정정")

    assert out["replaced"] is True
    assert out["ledger_rows_marked"] == 0
    assert db.store["donationExecutions/2026-11"]["amountWon"] == 1200
    assert db.store["donationExecutions/2026-11"]["note"] == "정정"


def test_a_save_touches_no_wallet_total_or_cap() -> None:
    db = _db()
    db.store["donationMonthTotals/2026-11"] = {"totalWon": 1150, "capWon": 1_000_000}
    db.store["users/u1"] = {"wallet": {"shareBalance": 5}, "donationDaily": {"day": "2026-11-20", "countedWon": 50}}
    before = {k: dict(v) for k, v in db.store.items() if k.startswith(("donationMonthTotals", "users"))}

    _save(db)

    after = {k: dict(v) for k, v in db.store.items() if k.startswith(("donationMonthTotals", "users"))}
    assert after == before


@pytest.mark.parametrize(
    "over,detail",
    [
        ({"month": "2026-13"}, "invalid_month"),
        ({"month": "26-11"}, "invalid_month"),
        ({"amount_won": 0}, "invalid_amount"),
        ({"amount_won": -5}, "invalid_amount"),
        ({"amount_won": True}, "invalid_amount"),
        ({"partner_name": "  "}, "invalid_partner"),
        ({"partner_name": "x" * 101}, "invalid_partner"),
        ({"receipt_image_path": "other/2026-11/a.jpg"}, "invalid_receipt_path"),
        ({"receipt_image_path": "donation-receipts/2026-10/a.jpg"}, "invalid_receipt_path"),
        ({"receipt_image_path": "donation-receipts/2026-11/../x.jpg"}, "invalid_receipt_path"),
        ({"receipt_image_path": "donation-receipts/2026-11/"}, "invalid_receipt_path"),
        ({"note": "n" * 501}, "note_too_long"),
        ({"executed_at": "yesterday"}, "invalid_executed_at"),
        ({"created_by": ""}, "invalid_actor"),
    ],
)
def test_bad_input_is_refused_and_nothing_is_written(over, detail) -> None:
    db = _db()
    with pytest.raises(HTTPException) as caught:
        _save(db, **over)

    assert caught.value.status_code == 400
    assert caught.value.detail == detail
    assert "donationExecutions/2026-11" not in db.store
    assert db.store["donationLedger/verified_run_a"]["receiptIssued"] is False


def test_more_rows_than_one_batch_are_all_marked() -> None:
    db = _MemoryDb()
    for index in range(1000):
        db.store[f"donationLedger/row{index}"] = {"monthKey": "2026-11", "receiptIssued": False}

    out = _save(db)

    assert out["ledger_rows_marked"] == 1000
    assert all(v["receiptIssued"] is True for k, v in db.store.items() if k.startswith("donationLedger/"))


# --- the admin route ---------------------------------------------------------

client = TestClient(app)
BODY = {
    "month": "2026-11",
    "amount_won": 1150,
    "executed_at": "2026-12-03",
    "partner_name": "테스트 기부처",
    "receipt_image_path": "donation-receipts/2026-11/receipt-1.jpg",
    "note": "",
}


def test_the_route_needs_an_admin(monkeypatch) -> None:
    assert client.post("/admin/donation-executions", json=BODY).status_code == 401

    monkeypatch.setattr(admin_auth_service, "require_admin", lambda authorization: (_ for _ in ()).throw(
        HTTPException(status_code=403, detail="Admin access required.")))
    assert client.post("/admin/donation-executions", json=BODY, headers={"Authorization": "Bearer x"}).status_code == 403


def test_the_route_saves_and_audits(monkeypatch) -> None:
    db = _db()
    audits: list[dict] = []
    monkeypatch.setattr(admin_auth_service, "require_admin", lambda authorization: {"uid": "admin1", "email": "a@b.c"})
    monkeypatch.setattr(admin_router, "FirebaseService", lambda: type("F", (), {"db": db})())
    monkeypatch.setattr(admin_router.admin_audit_service, "write", lambda **kw: audits.append(kw) or "log1")

    response = client.post("/admin/donation-executions", json=BODY, headers={"Authorization": "Bearer x"})

    assert response.status_code == 200
    assert response.json() == {"month": "2026-11", "amount_won": 1150, "replaced": False, "ledger_rows_marked": 3}
    assert db.store["donationExecutions/2026-11"]["createdBy"] == "admin1"
    assert audits[0]["action"] == "donation_execution"
    assert audits[0]["after"]["amountWon"] == 1150


def test_the_route_rejects_a_bad_month(monkeypatch) -> None:
    monkeypatch.setattr(admin_auth_service, "require_admin", lambda authorization: {"uid": "admin1"})

    response = client.post(
        "/admin/donation-executions",
        json={**BODY, "month": "2026-13"},
        headers={"Authorization": "Bearer x"},
    )

    assert response.status_code == 422
