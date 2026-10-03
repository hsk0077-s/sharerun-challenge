"""Web3 VALUE transfer and its negative ledger row share one transaction."""

from types import SimpleNamespace

from app.models.secured_actions import Web3TransferRequest
from app.services.secured_action_service import (
    SecuredActionService,
    _commit_web3_transfer_tx,
)
from test_redeem_referral import _MemoryDb, _MemoryTxn

_ADDRESS = "0x" + "ab" * 20


def _transfer(db: _MemoryDb, service: SecuredActionService, amount: int):
    user_ref = db.collection("users").document("u1")
    request = Web3TransferRequest(
        destination_address=_ADDRESS,
        amount_srv=amount,
        transfer_channel="external_wallet",
    )
    return _commit_web3_transfer_tx.to_wrap(
        _MemoryTxn(),
        service,
        "u1",
        request,
        user_ref,
    )


def test_web3_transfer_appends_negative_value_row() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {"wallet": {"valueTokenBalance": 40}}
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))

    result = _transfer(db, service, 15)

    assert result.status == "transferred"
    assert db.store["users/u1"]["wallet"]["valueTokenBalance"] == 25
    ledger = [
        (path, row)
        for path, row in db.store.items()
        if path.startswith("walletTransactions/")
    ]
    assert len(ledger) == 1
    assert ledger[0][1]["type"] == "web3_transfer"
    assert ledger[0][1]["valueAmount"] == -15
    assert ledger[0][1]["destinationAddress"] == _ADDRESS

    _transfer(db, service, 10)
    assert db.store["users/u1"]["wallet"]["valueTokenBalance"] == 15
    paths = [path for path in db.store if path.startswith("walletTransactions/")]
    assert len(paths) == 2
    assert len(set(paths)) == 2
