"""Using an item decrements quantity and appends a usage row."""

from types import SimpleNamespace

from fastapi import HTTPException
import pytest

from app.services.secured_action_service import SecuredActionService, _commit_use_shop_tx
from test_redeem_referral import _MemoryDb, _MemoryTxn


def _use(db: _MemoryDb, item_id: str = "record_cpr_ticket"):
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))
    user_ref = db.collection("users").document("u1")
    return _commit_use_shop_tx.to_wrap(
        _MemoryTxn(),
        service,
        "u1",
        item_id,
        user_ref,
    )


def test_use_decrements_quantity_and_appends_usage_row() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {"wallet": {"diamondBalance": 1000000}}
    db.store["users/u1/shopInventory/record_cpr_ticket"] = {"quantity": 2}

    result = _use(db)

    assert result.status == "used"
    assert db.store["users/u1/shopInventory/record_cpr_ticket"]["quantity"] == 1
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 1000000
    ledger = [
        row
        for path, row in db.store.items()
        if path.startswith("walletTransactions/")
    ]
    assert len(ledger) == 1
    assert ledger[0]["type"] == "shop_item_use"
    assert ledger[0]["itemId"] == "record_cpr_ticket"
    assert ledger[0]["quantityAmount"] == -1

    _use(db)
    assert db.store["users/u1/shopInventory/record_cpr_ticket"]["quantity"] == 0
    with pytest.raises(HTTPException) as raised:
        _use(db)
    assert raised.value.status_code == 400
    ledger_paths = [
        path for path in db.store if path.startswith("walletTransactions/")
    ]
    assert len(ledger_paths) == 2
