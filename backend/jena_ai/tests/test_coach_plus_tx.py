"""Coach+ is an account flag. It does not move SHARE, DIA, or VALUE."""

from datetime import datetime
from types import SimpleNamespace

import pytest
from fastapi import HTTPException

from app.services.secured_action_service import (
    SecuredActionService,
    _commit_coach_plus_tx,
)
from test_redeem_referral import _MemoryDb, _MemoryTxn


def test_coach_plus_writes_entitlement_without_a_ledger_row() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {
        "wallet": {
            "shareBalance": 1000,
            "diamondBalance": 8,
            "valueTokenBalance": 3,
        }
    }
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))
    user_ref = db.collection("users").document("u1")

    result = _commit_coach_plus_tx.to_wrap(
        _MemoryTxn(),
        service,
        "coach_plus_monthly",
        user_ref,
    )

    assert result.status == "coach_plus_active"
    wallet = db.store["users/u1"]["wallet"]
    assert wallet == {
        "shareBalance": 1000,
        "diamondBalance": 8,
        "valueTokenBalance": 3,
    }
    entitlement = db.store["users/u1"]["coachPlus"]
    assert entitlement["productId"] == "coach_plus_monthly"
    until = datetime.fromisoformat(entitlement["activeUntil"])
    assert until > datetime.now(until.tzinfo)
    assert not any(path.startswith("walletTransactions/") for path in db.store)


def test_unknown_coach_plus_product_writes_nothing() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {"wallet": {"shareBalance": 4}}
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))

    with pytest.raises(HTTPException) as exc_info:
        service.activate_coach_plus("u1", "share_pack")

    assert exc_info.value.status_code == 400
    assert "coachPlus" not in db.store["users/u1"]
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 4
