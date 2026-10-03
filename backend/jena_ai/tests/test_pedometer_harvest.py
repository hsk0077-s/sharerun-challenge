"""Walking SHARE pickup credits wallet.shareBalance once per claimed watermark."""

from types import SimpleNamespace

from app.models.secured_actions import HarvestPedometerRequest
from app.services.secured_action_service import (
    SecuredActionService,
    _commit_harvest_tx,
)
from test_redeem_referral import _MemoryDb, _MemoryTxn


def test_harvest_credits_fifty_share_once() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {
        "wallet": {
            "shareBalance": 10,
            "diamondBalance": 2,
            "valueTokenBalance": 3,
        }
    }
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))
    user_ref = db.collection("users").document("u1")
    request = HarvestPedometerRequest(claimed_steps=5000)

    first = _commit_harvest_tx.to_wrap(
        _MemoryTxn(), service, "u1", request, user_ref
    )
    assert first.status == "harvested"
    assert first.share_credited == 50
    assert first.share_balance == 60
    wallet = db.store["users/u1"]["wallet"]
    assert wallet["shareBalance"] == 60
    assert wallet["diamondBalance"] == 2
    assert wallet["valueTokenBalance"] == 3

    again = _commit_harvest_tx.to_wrap(
        _MemoryTxn(), service, "u1", request, user_ref
    )
    assert again.status == "already_harvested"
    assert again.share_credited == 0
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 60


def test_harvest_entry_uses_module_transaction(monkeypatch) -> None:
    db = _MemoryDb()
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))
    seen: dict = {}

    def fake(transaction, service_arg, uid, request, user_ref):
        seen["uid"] = uid
        seen["steps"] = request.claimed_steps
        return "ok"

    monkeypatch.setattr(
        "app.services.secured_action_service._commit_harvest_tx",
        fake,
    )
    result = service.harvest_pedometer_share(
        "u1",
        HarvestPedometerRequest(claimed_steps=5000),
    )
    assert result == "ok"
    assert seen == {"uid": "u1", "steps": 5000}
