"""Cash refund debit and its negative ledger row share one transaction."""

from types import SimpleNamespace

from app.models.secured_actions import RefundRequest
from app.services.secured_action_service import SecuredActionService, _commit_refund_tx
from test_redeem_referral import _MemoryDb, _MemoryTxn


def _refund(db: _MemoryDb, service: SecuredActionService, amount: int):
    user_ref = db.collection("users").document("u1")
    request = RefundRequest(share_amount=amount)
    return _commit_refund_tx.to_wrap(
        _MemoryTxn(),
        service,
        "u1",
        request,
        user_ref,
    )


def test_refund_appends_negative_share_row() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {"wallet": {"shareBalance": 500}}
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))

    result = _refund(db, service, 120)

    assert result.status == "refund_requested"
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 380
    first = [
        row
        for path, row in db.store.items()
        if path.startswith("walletTransactions/")
    ]
    assert len(first) == 1
    assert first[0]["type"] == "cash_refund_requested"
    assert first[0]["shareAmount"] == -120

    _refund(db, service, 120)
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 260
    paths = [path for path in db.store if path.startswith("walletTransactions/")]
    assert len(paths) == 2
    assert len(set(paths)) == 2
