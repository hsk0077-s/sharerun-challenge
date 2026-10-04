"""Shop DIA debit and its negative ledger row share one transaction."""

from types import SimpleNamespace

from fastapi import HTTPException
import pytest

from app.services.secured_action_service import SecuredActionService, _commit_shop_tx
from test_redeem_referral import _MemoryDb, _MemoryTxn


def _buy(db: _MemoryDb, service: SecuredActionService):
    user_ref = db.collection("users").document("u1")
    return _commit_shop_tx.to_wrap(
        _MemoryTxn(),
        service,
        "u1",
        "ghost_pace_match",
        user_ref,
    )


def test_catalog_prices_streak_items_from_config_and_keeps_battle_pass() -> None:
    db = _MemoryDb()
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))
    prices = {row["id"]: row["diamondCost"] for row in service.shop_catalog()}
    assert prices["record_cpr_ticket"] == 12
    assert prices["record_safe_guard"] == 8
    assert prices["battle_run_pass"] == 120


def test_generic_shop_purchase_does_not_sell_battle_pass() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {"wallet": {"diamondBalance": 200}}
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))
    user_ref = db.collection("users").document("u1")
    with pytest.raises(HTTPException) as exc:
        _commit_shop_tx.to_wrap(
            _MemoryTxn(),
            service,
            "u1",
            "battle_run_pass",
            user_ref,
        )
    assert exc.value.detail == "request_id is required."
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 200
    assert not any(path.startswith("walletTransactions/") for path in db.store)


def test_shop_purchase_appends_negative_diamond_row() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {"wallet": {"diamondBalance": 20}}
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))

    result = _buy(db, service)

    assert result.status == "purchased"
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 12
    assert db.store["users/u1/shopInventory/ghost_pace_match"]["quantity"] == 1
    ledger = [
        row
        for path, row in db.store.items()
        if path.startswith("walletTransactions/")
    ]
    assert len(ledger) == 1
    assert ledger[0]["type"] == "shop_purchase"
    assert ledger[0]["diamondAmount"] == -8
    assert ledger[0]["itemId"] == "ghost_pace_match"

    again = _buy(db, service)
    assert again.status == "purchased"
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 4
    assert db.store["users/u1/shopInventory/ghost_pace_match"]["quantity"] == 2
    ledger_paths = [
        path for path in db.store if path.startswith("walletTransactions/")
    ]
    assert len(ledger_paths) == 2
    assert len(set(ledger_paths)) == 2
