"""DIA pack grants require a verified Play token and split paid vs bonus DIA."""

from types import SimpleNamespace

import pytest
from fastapi import HTTPException

from app.services.secured_action_service import (
    SecuredActionService,
    _commit_dia_pack_tx,
)
from test_redeem_referral import _MemoryDb, _MemoryTxn


def _service(db: _MemoryDb) -> SecuredActionService:
    return SecuredActionService(firebase_service=SimpleNamespace(db=db))


def _grant(db: _MemoryDb, pack: dict, token_hash: str = "hash1"):
    service = _service(db)
    user_ref = db.collection("users").document("u1")
    purchase_ref = db.collection("playPurchases").document(token_hash)
    return _commit_dia_pack_tx.to_wrap(
        _MemoryTxn(),
        service,
        "u1",
        pack,
        user_ref,
        purchase_ref,
    )


def test_grant_rejects_when_play_verification_is_not_configured() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {"wallet": {"diamondBalance": 1, "shareBalance": 7}}
    service = _service(db)
    with pytest.raises(HTTPException) as raised:
        service.grant_dia_pack("u1", "dia_pack_60", "token-not-verified")
    assert raised.value.status_code == 503
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 1
    assert not any(key.startswith("walletTransactions/") for key in db.store)


def test_verified_pack_records_paid_base_and_free_bonus_once() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {
        "wallet": {"diamondBalance": 0, "shareBalance": 4, "valueTokenBalance": 9}
    }
    pack = {
        "productId": "dia_pack_130",
        "priceKrw": 12000,
        "baseDia": 120,
        "bonusDia": 10,
    }
    first = _grant(db, pack)
    assert first.status == "granted"
    assert first.diamond_balance == 130
    wallet = db.store["users/u1"]["wallet"]
    assert wallet["diamondBalance"] == 130
    assert wallet["paidDiamondBalance"] == 120
    assert wallet["freeDiamondBalance"] == 10
    assert wallet["shareBalance"] == 4
    assert wallet["valueTokenBalance"] == 9
    rows = [row for key, row in db.store.items() if key.startswith("walletTransactions/")]
    assert len(rows) == 1
    assert rows[0]["type"] == "dia_pack_purchase"
    assert rows[0]["diamondAmount"] == 130
    assert rows[0]["diamondPaidAmount"] == 120
    assert rows[0]["diamondFreeAmount"] == 10

    again = _grant(db, pack)
    assert again.status == "already_granted"
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 130
    rows = [row for key, row in db.store.items() if key.startswith("walletTransactions/")]
    assert len(rows) == 1


def test_unknown_pack_writes_nothing() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {"wallet": {"diamondBalance": 3}}
    service = _service(db)
    with pytest.raises(HTTPException) as raised:
        service.grant_dia_pack("u1", "dia_pack_missing", "token-unknown-pack")
    assert raised.value.status_code == 400
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 3


def test_grant_verifies_token_before_the_ledger(monkeypatch) -> None:
    seen: dict = {}

    def verify(product_id, purchase_token):
        seen["verified"] = (product_id, purchase_token)

    def commit(transaction, service_arg, uid, pack, user_ref, purchase_ref):
        seen["product"] = pack["productId"]
        seen["purchase"] = purchase_ref.id
        return SimpleNamespace(status="granted")

    monkeypatch.setattr(
        "app.services.secured_action_service.verify_play_product_purchase",
        verify,
    )
    monkeypatch.setattr(
        "app.services.secured_action_service.consume_play_product_purchase",
        lambda product_id, purchase_token: seen.setdefault("consumed", product_id),
    )
    monkeypatch.setattr(
        "app.services.secured_action_service._commit_dia_pack_tx",
        commit,
    )
    db = _MemoryDb()
    service = _service(db)
    service.grant_dia_pack("u1", "dia_pack_12", "token-for-helper")
    assert seen["verified"] == ("dia_pack_12", "token-for-helper")
    assert seen["product"] == "dia_pack_12"
    assert seen["consumed"] == "dia_pack_12"
    assert len(seen["purchase"]) == 64
