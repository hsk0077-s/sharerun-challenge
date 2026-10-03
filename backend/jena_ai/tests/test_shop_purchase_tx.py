"""Shop DIA debit and its negative ledger row share one transaction."""

from types import SimpleNamespace

from app.services.secured_action_service import SecuredActionService, _commit_shop_tx
from test_redeem_referral import _MemoryDb, _MemoryTxn


def _buy(db: _MemoryDb, service: SecuredActionService):
    user_ref = db.collection("users").document("u1")
    return _commit_shop_tx.to_wrap(
        _MemoryTxn(),
        service,
        "u1",
        "record_cpr_ticket",
        user_ref,
    )


def test_shop_purchase_appends_negative_diamond_row() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {"wallet": {"diamondBalance": 10}}
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))

    result = _buy(db, service)

    assert result.status == "purchased"
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 7
    assert db.store["users/u1/shopInventory/record_cpr_ticket"]["quantity"] == 1
    ledger = [
        row
        for path, row in db.store.items()
        if path.startswith("walletTransactions/")
    ]
    assert len(ledger) == 1
    assert ledger[0]["type"] == "shop_purchase"
    assert ledger[0]["diamondAmount"] == -3
    assert ledger[0]["itemId"] == "record_cpr_ticket"

    again = _buy(db, service)
    assert again.status == "purchased"
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 4
    assert db.store["users/u1/shopInventory/record_cpr_ticket"]["quantity"] == 2
    ledger_paths = [
        path for path in db.store if path.startswith("walletTransactions/")
    ]
    assert len(ledger_paths) == 2
    assert len(set(ledger_paths)) == 2
