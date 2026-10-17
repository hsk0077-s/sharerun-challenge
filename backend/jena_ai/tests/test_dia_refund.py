"""Cash refund of a DIA pack: unused paid part, within 7 days, once."""

from datetime import datetime, timedelta, timezone
from types import SimpleNamespace

from fastapi import HTTPException
import pytest

from app.services import dia_refund
from test_redeem_referral import _MemoryDb, _MemoryTxn

NOW = datetime.now(timezone.utc)


def _wallet(paid: int, free: int) -> dict:
    return {
        "diamondBalance": paid + free,
        "paidDiamondBalance": paid,
        "freeDiamondBalance": free,
        "shareBalance": 0,
    }


def _purchase(product="dia_pack_130", days_ago=1, **extra) -> dict:
    return {"uid": "u1", "productId": product, "createdAt": NOW - timedelta(days=days_ago), **extra}


def _seed(db, wallet, purchase):
    db.store["users/u1"] = {"wallet": wallet}
    db.store["playPurchases/p1"] = purchase
    return db


def _refund(db):
    service = SimpleNamespace(firebase_service=SimpleNamespace(db=db))
    return dia_refund._refund_tx.to_wrap(
        _MemoryTxn(),
        db,
        "u1",
        db.collection("users").document("u1"),
        db.collection("playPurchases").document("p1"),
        db.collection("refundRequests").document("p1"),
    )


def test_untouched_pack_refunds_everything_and_takes_the_bonus_back() -> None:
    # 130 pack: 120 paid + 10 bonus, price 12,000 KRW.
    quote = dia_refund.compute(_purchase(), _wallet(paid=120, free=10), NOW)
    assert quote == {
        "eligible": True, "reason": "", "paid_dia": 120, "bonus_revoked": 10,
        "bonus_spent": 0, "refund_krw": 12_000,
    }


def test_spent_paid_dia_is_not_refunded() -> None:
    quote = dia_refund.compute(_purchase(), _wallet(paid=70, free=10), NOW)
    assert quote["paid_dia"] == 70
    # bonus comes back in proportion: round(10 * 70 / 120) = 6
    assert quote["bonus_revoked"] == 6
    assert quote["refund_krw"] == 7_000


def test_a_spent_bonus_is_taken_off_the_refund_at_100_krw() -> None:
    quote = dia_refund.compute(_purchase(), _wallet(paid=120, free=4), NOW)
    assert (quote["bonus_revoked"], quote["bonus_spent"]) == (4, 6)
    assert quote["refund_krw"] == (120 - 6) * 100


def test_after_seven_days_or_with_nothing_left_there_is_no_refund() -> None:
    assert dia_refund.compute(_purchase(days_ago=8), _wallet(120, 10), NOW)["reason"] == "period_over"
    assert dia_refund.compute(_purchase(), _wallet(0, 130), NOW)["reason"] == "nothing_left"
    assert dia_refund.compute(_purchase(refundStatus="requested"), _wallet(120, 10), NOW)["reason"] == "already_refunded"


def test_refund_debits_the_wallet_once_and_records_the_request() -> None:
    db = _seed(_MemoryDb(), _wallet(120, 15), _purchase())
    result = _refund(db)
    assert result["status"] == "refund_requested"
    assert result["refund_krw"] == 12_000
    wallet = db.store["users/u1"]["wallet"]
    assert wallet["paidDiamondBalance"] == 0
    assert wallet["freeDiamondBalance"] == 5  # 15 - the 10 bonus that came with the pack
    assert db.store["playPurchases/p1"]["refundStatus"] == "requested"
    assert db.store["refundRequests/p1"]["refundKrw"] == 12_000
    with pytest.raises(HTTPException) as caught:
        _refund(db)
    assert caught.value.status_code == 409
    assert db.store["users/u1"]["wallet"]["paidDiamondBalance"] == 0


def test_someone_elses_purchase_cannot_be_refunded() -> None:
    db = _seed(_MemoryDb(), _wallet(120, 10), {**_purchase(), "uid": "other"})
    with pytest.raises(HTTPException) as caught:
        _refund(db)
    assert caught.value.status_code == 404
    assert db.store["users/u1"]["wallet"]["paidDiamondBalance"] == 120


def test_old_purchase_docs_without_base_and_bonus_use_the_pack_table() -> None:
    # dia_pack_60 is 59 paid + 1 bonus.
    quote = dia_refund.compute(_purchase("dia_pack_60"), _wallet(59, 1), NOW)
    assert (quote["paid_dia"], quote["bonus_revoked"], quote["refund_krw"]) == (59, 1, 5_900)


def test_list_shows_only_purchases_in_the_period_with_a_preview() -> None:
    db = _seed(_MemoryDb(), _wallet(120, 10), _purchase())
    db.store["playPurchases/p2"] = _purchase(days_ago=30)
    rows = dia_refund.list_refundable(db, "u1")
    assert [r["purchase_id"] for r in rows] == ["p1"]
    assert rows[0]["refund_krw"] == 12_000 and rows[0]["eligible"] is True


def test_request_marks_refunded_when_google_play_pays_back(monkeypatch) -> None:
    db = _seed(_MemoryDb(), _wallet(120, 10), _purchase(orderId="GPA.1"))
    service = SimpleNamespace(firebase_service=SimpleNamespace(db=db))
    original = dia_refund._refund_tx
    monkeypatch.setattr(dia_refund, "_refund_tx", lambda tx, *a: original.to_wrap(tx, *a))
    monkeypatch.setattr("app.services.play_billing.refund_play_order", lambda order_id: True)
    result = dia_refund.request_refund(service, "u1", "p1")
    assert result["status"] == "refunded" and result["play_refunded"] is True
    assert db.store["playPurchases/p1"]["refundStatus"] == "refunded"


def test_without_play_credentials_the_request_waits_for_an_operator(monkeypatch) -> None:
    db = _seed(_MemoryDb(), _wallet(120, 10), _purchase(orderId="GPA.1"))
    service = SimpleNamespace(firebase_service=SimpleNamespace(db=db))
    original = dia_refund._refund_tx
    monkeypatch.setattr(dia_refund, "_refund_tx", lambda tx, *a: original.to_wrap(tx, *a))
    monkeypatch.setattr("app.services.play_billing.refund_play_order", lambda order_id: False)
    result = dia_refund.request_refund(service, "u1", "p1")
    assert result["status"] == "refund_requested" and result["play_refunded"] is False
    assert db.store["refundRequests/p1"]["status"] == "requested"
