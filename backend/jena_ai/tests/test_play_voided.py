"""Orders Google Play refunded or charged back are undone here, once, without going below zero."""

from datetime import datetime, timedelta, timezone

import pytest
from fastapi import HTTPException

from app.services import play_billing, play_voided_service
from app.services.play_billing import purchase_token_hash
from app.services.play_voided_service import (
    _void_coach_tx,
    _void_dia_tx,
    process_voided_purchases,
)
from test_redeem_referral import _MemoryDb, _MemoryTxn

NOW = datetime(2026, 11, 10, 12, 0, tzinfo=timezone.utc)
TOKEN = "token-dia-1"
HASH = purchase_token_hash(TOKEN)


@pytest.fixture(autouse=True)
def _in_memory_transactions(monkeypatch):
    """The in-memory database has no real transaction, so run the commit bodies directly."""
    monkeypatch.setattr(play_voided_service, "_void_dia_tx", lambda *a: _void_dia_tx.to_wrap(*a))
    monkeypatch.setattr(play_voided_service, "_void_coach_tx", lambda *a: _void_coach_tx.to_wrap(*a))


def _db(paid: int = 120, free: int = 10, refund_status: str | None = None) -> _MemoryDb:
    db = _MemoryDb()
    db.transaction = lambda: _MemoryTxn()
    db.store["users/u1"] = {
        "wallet": {
            "diamondBalance": paid + free,
            "paidDiamondBalance": paid,
            "freeDiamondBalance": free,
            "shareBalance": 5,
        }
    }
    purchase = {
        "uid": "u1",
        "productId": "dia_pack_130",
        "baseDia": 120,
        "bonusDia": 10,
        "priceKrw": 12000,
        "orderId": "GPA.1",
    }
    if refund_status:
        purchase["refundStatus"] = refund_status
    db.store[f"playPurchases/{HASH}"] = purchase
    return db


def _rows(*tokens: str, source: int = 0):
    return [{"purchaseToken": t, "voidedSource": source, "voidedReason": 0} for t in tokens]


def _serve(monkeypatch, rows, calls: list | None = None):
    def fake(start_ms: int, end_ms: int):
        if calls is not None:
            calls.append((start_ms, end_ms))
        return rows

    monkeypatch.setattr(play_voided_service, "list_voided_purchases", fake)


def _wallet(db):
    return db.store["users/u1"]["wallet"]


def _ledger(db):
    return [row for key, row in db.store.items() if key.startswith("walletTransactions/")]


def test_a_refunded_pack_takes_back_its_paid_dia_and_the_bonus(monkeypatch) -> None:
    db = _db()
    _serve(monkeypatch, _rows(TOKEN))

    summary = process_voided_purchases(db, now=NOW)

    assert summary["dia_taken_back"] == 1
    assert summary["shortfall_dia"] == 0
    wallet = _wallet(db)
    assert wallet["paidDiamondBalance"] == 0
    assert wallet["freeDiamondBalance"] == 0
    assert wallet["diamondBalance"] == 0
    assert wallet["shareBalance"] == 5
    purchase = db.store[f"playPurchases/{HASH}"]
    assert purchase["refundStatus"] == "voided"
    assert purchase["clawbackPaidDia"] == 120
    assert purchase["clawbackBonusDia"] == 10
    rows = _ledger(db)
    assert len(rows) == 1 and rows[0]["type"] == "play_void_clawback"
    assert rows[0]["diamondAmount"] == -130


def test_paid_dia_already_spent_is_written_down_as_a_shortfall(monkeypatch) -> None:
    db = _db(paid=70, free=0)  # 50 of the 120 paid DIA were already spent
    _serve(monkeypatch, _rows(TOKEN))

    summary = process_voided_purchases(db, now=NOW)

    assert summary["shortfall_dia"] == 50
    wallet = _wallet(db)
    assert wallet["paidDiamondBalance"] == 0
    assert wallet["diamondBalance"] == 0  # never below zero
    assert db.store["users/u1"]["refundShortfallDia"] == 50
    assert db.store[f"playPurchases/{HASH}"]["shortfallDia"] == 50


def test_a_purchase_the_in_app_refund_already_settled_takes_nothing_more(monkeypatch) -> None:
    db = _db(paid=0, free=0, refund_status="refunded")
    db.store["users/u1"]["wallet"]["diamondBalance"] = 40  # unrelated DIA stays
    _serve(monkeypatch, _rows(TOKEN, source=1))

    summary = process_voided_purchases(db, now=NOW)

    assert summary["already_handled"] == 1
    assert summary["dia_taken_back"] == 0
    assert _wallet(db)["diamondBalance"] == 40
    assert _ledger(db) == []
    assert "voidedAt" in db.store[f"playPurchases/{HASH}"]


def test_running_again_does_not_take_back_twice(monkeypatch) -> None:
    db = _db()
    _serve(monkeypatch, _rows(TOKEN))
    process_voided_purchases(db, now=NOW)
    db.store["users/u1"]["wallet"]["paidDiamondBalance"] = 100  # bought more later
    db.store["users/u1"]["wallet"]["diamondBalance"] = 100

    summary = process_voided_purchases(db, now=NOW + timedelta(hours=1))

    assert summary["already_handled"] == 1
    assert summary["dia_taken_back"] == 0
    assert _wallet(db)["paidDiamondBalance"] == 100
    assert len(_ledger(db)) == 1


def test_coach_plus_ends_when_the_voided_order_is_the_one_it_runs_on(monkeypatch) -> None:
    db = _MemoryDb()
    db.transaction = lambda: _MemoryTxn()
    sub_hash = purchase_token_hash("sub-token")
    db.store["users/u1"] = {
        "coachPlus": {
            "productId": "coach_plus_monthly",
            "activeUntil": "2030-01-01T00:00:00+00:00",
            "tokenHash": sub_hash,
        }
    }
    db.store[f"playSubscriptions/{sub_hash}"] = {"uid": "u1", "productId": "coach_plus_monthly"}
    _serve(monkeypatch, _rows("sub-token"))

    summary = process_voided_purchases(db, now=NOW)

    assert summary["coach_plus_ended"] == 1
    coach = db.store["users/u1"]["coachPlus"]
    assert datetime.fromisoformat(coach["activeUntil"]) == NOW
    assert coach["productId"] == "coach_plus_monthly"
    assert "voidedAt" in db.store[f"playSubscriptions/{sub_hash}"]


def test_coach_plus_running_on_another_paid_order_is_left_alone(monkeypatch) -> None:
    db = _MemoryDb()
    db.transaction = lambda: _MemoryTxn()
    voided_hash = purchase_token_hash("monthly-token")
    db.store["users/u1"] = {
        "coachPlus": {
            "productId": "coach_plus_yearly",
            "activeUntil": "2031-01-01T00:00:00+00:00",
            "tokenHash": "some-other-order",
        }
    }
    db.store[f"playSubscriptions/{voided_hash}"] = {"uid": "u1", "productId": "coach_plus_monthly"}
    _serve(monkeypatch, _rows("monthly-token"))

    process_voided_purchases(db, now=NOW)

    assert db.store["users/u1"]["coachPlus"]["activeUntil"] == "2031-01-01T00:00:00+00:00"
    assert "voidedAt" in db.store[f"playSubscriptions/{voided_hash}"]


def test_an_order_we_never_recorded_is_counted_and_ignored(monkeypatch) -> None:
    db = _db()
    _serve(monkeypatch, _rows("someone-elses-token", ""))

    summary = process_voided_purchases(db, now=NOW)

    assert summary["unknown"] == 2
    assert _wallet(db)["paidDiamondBalance"] == 120


def test_first_run_looks_back_a_week_and_later_runs_start_at_the_saved_point(monkeypatch) -> None:
    db = _db()
    calls: list = []
    _serve(monkeypatch, [], calls)

    process_voided_purchases(db, now=NOW)
    first_start, first_end = calls[0]
    assert datetime.fromtimestamp(first_start / 1000, timezone.utc) == NOW - timedelta(days=7)
    assert first_end == int(NOW.timestamp() * 1000)
    assert db.store["opsState/playVoided"]["lastEndMillis"] == first_end

    later = NOW + timedelta(days=2)
    process_voided_purchases(db, now=later)
    start = datetime.fromtimestamp(calls[1][0] / 1000, timezone.utc)
    assert start == NOW - timedelta(days=1)  # saved point minus one day of overlap


def test_the_window_never_reaches_further_back_than_play_remembers(monkeypatch) -> None:
    db = _db()
    db.store["opsState/playVoided"] = {"lastEndMillis": int((NOW - timedelta(days=90)).timestamp() * 1000)}
    calls: list = []
    _serve(monkeypatch, [], calls)

    process_voided_purchases(db, now=NOW)

    start = datetime.fromtimestamp(calls[0][0] / 1000, timezone.utc)
    assert start == NOW - timedelta(days=29)


def test_a_failed_row_keeps_the_saved_point_so_it_is_read_again(monkeypatch) -> None:
    db = _db()
    _serve(monkeypatch, _rows(TOKEN))

    def boom(*args):
        raise RuntimeError("firestore hiccup")

    monkeypatch.setattr(play_voided_service, "_void_dia_tx", boom)

    summary = process_voided_purchases(db, now=NOW)

    assert summary["failed"] == 1
    assert "opsState/playVoided" not in db.store
    assert _wallet(db)["paidDiamondBalance"] == 120


class _Page:
    def __init__(self, body: dict, status_code: int = 200) -> None:
        self._body = body
        self.status_code = status_code

    def json(self) -> dict:
        return self._body


class _PagedSession:
    def __init__(self, pages: list[_Page]) -> None:
        self._pages = list(pages)
        self.calls: list[tuple[str, dict]] = []

    def get(self, url: str, params: dict | None = None, timeout: int = 0) -> _Page:
        self.calls.append((url, dict(params or {})))
        return self._pages.pop(0)


def test_list_voided_purchases_reads_every_page_and_asks_for_subscriptions_too(monkeypatch) -> None:
    session = _PagedSession(
        [
            _Page({"voidedPurchases": [{"purchaseToken": "a"}], "tokenPagination": {"nextPageToken": "p2"}}),
            _Page({"voidedPurchases": [{"purchaseToken": "b"}]}),
        ]
    )
    monkeypatch.setattr(play_billing, "_authorized_session", lambda: (session, "com.example.app"))

    rows = play_billing.list_voided_purchases(1000, 2000)

    assert [r["purchaseToken"] for r in rows] == ["a", "b"]
    first_url, first_params = session.calls[0]
    assert "/applications/com.example.app/purchases/voidedpurchases" in first_url
    assert first_params["startTime"] == "1000" and first_params["endTime"] == "2000"
    assert first_params["type"] == "1"
    assert "token" not in first_params
    assert session.calls[1][1]["token"] == "p2"


def test_list_voided_purchases_failure_is_an_error_not_an_empty_list(monkeypatch) -> None:
    session = _PagedSession([_Page({}, status_code=403)])
    monkeypatch.setattr(play_billing, "_authorized_session", lambda: (session, "com.example.app"))

    with pytest.raises(HTTPException) as raised:
        play_billing.list_voided_purchases(1, 2)

    assert raised.value.status_code == 502


def test_without_play_configuration_the_job_fails_loudly(monkeypatch) -> None:
    monkeypatch.delenv("GOOGLE_PLAY_PACKAGE_NAME", raising=False)
    monkeypatch.delenv("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON", raising=False)
    db = _db()

    with pytest.raises(HTTPException) as raised:
        process_voided_purchases(db, now=NOW)

    assert raised.value.status_code == 503
    assert "opsState/playVoided" not in db.store
