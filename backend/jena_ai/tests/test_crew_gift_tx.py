"""Crew gift debits DIA and appends both inventory docs plus one ledger row."""

from types import SimpleNamespace

from fastapi import HTTPException
import pytest

from app.services.secured_action_service import SecuredActionService, _commit_crew_gift_tx
from test_redeem_referral import _MemoryDb, _MemoryTxn


def _gift(db: _MemoryDb):
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))
    user_ref = db.collection("users").document("u1")
    return _commit_crew_gift_tx.to_wrap(_MemoryTxn(), service, "u1", user_ref)


def test_crew_gift_debits_30_and_grants_both_items() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {
        "wallet": {
            "shareBalance": 1000000,
            "diamondBalance": 1000000,
            "valueTokenBalance": 1000000,
        }
    }

    result = _gift(db)

    assert result.status == "granted"
    assert result.diamond_balance == 999970
    assert result.share_balance == 1000000
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 999970
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 1000000
    assert db.store["users/u1/shopInventory/record_cpr_ticket"]["quantity"] == 1
    assert db.store["users/u1/shopInventory/record_safe_guard"]["quantity"] == 1
    ledger = [
        row
        for path, row in db.store.items()
        if path.startswith("walletTransactions/")
    ]
    assert len(ledger) == 1
    assert ledger[0]["type"] == "crew_item_gift"
    assert ledger[0]["diamondAmount"] == -30
    assert ledger[0]["itemIds"] == ["record_cpr_ticket", "record_safe_guard"]


def test_crew_gift_rejects_when_dia_is_short() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {"wallet": {"diamondBalance": 10}}
    with pytest.raises(HTTPException) as raised:
        _gift(db)
    assert raised.value.status_code == 400
    assert "walletTransactions/" not in "".join(db.store)
