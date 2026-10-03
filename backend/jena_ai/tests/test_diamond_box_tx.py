"""Diamond box credit and its positive ledger row share one transaction."""

from types import SimpleNamespace

from app.models.secured_actions import CollectDiamondBoxRequest
from app.services.secured_action_service import (
    SecuredActionService,
    _commit_diamond_box_tx,
)
from test_redeem_referral import _MemoryDb, _MemoryTxn


def _collect(db: _MemoryDb, service: SecuredActionService):
    user_ref = db.collection("users").document("u1")
    box_ref = db.collection("diamondBoxes").document("box1")
    collected_ref = user_ref.collection("collectedDiamondBoxes").document("box1")
    request = CollectDiamondBoxRequest(box_id="box1", latitude=0, longitude=0)
    return _commit_diamond_box_tx.to_wrap(
        _MemoryTxn(),
        service,
        "u1",
        request,
        user_ref,
        box_ref,
        collected_ref,
    )


def test_collect_appends_positive_diamond_row_once() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {"wallet": {"diamondBalance": 2}}
    db.store["diamondBoxes/box1"] = {
        "active": True,
        "latitude": 0,
        "longitude": 0,
        "rewardDiamond": 4,
    }
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))

    result = _collect(db, service)

    assert result.status == "collected"
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 6
    ledger = [
        row
        for path, row in db.store.items()
        if path.startswith("walletTransactions/")
    ]
    assert len(ledger) == 1
    assert ledger[0]["type"] == "diamond_box_collect"
    assert ledger[0]["diamondAmount"] == 4

    again = _collect(db, service)
    assert again.reason == "Diamond box was already collected."
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 6
    assert (
        sum(1 for path in db.store if path.startswith("walletTransactions/"))
        == 1
    )
