"""Web3 VALUE transfer is disabled. It must not debit or write a ledger row."""

from types import SimpleNamespace

from app.models.secured_actions import Web3TransferRequest
from app.services.secured_action_service import SecuredActionService
from test_redeem_referral import _MemoryDb

_ADDRESS = "0x" + "ab" * 20


def test_web3_transfer_does_not_debit_value() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {"wallet": {"valueTokenBalance": 40}}
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))
    request = Web3TransferRequest(
        destination_address=_ADDRESS,
        amount_srv=15,
        transfer_channel="external_wallet",
    )

    result = service.transfer_value_to_web3("u1", request)

    assert result.accepted is False
    assert result.status == "coming_soon"
    assert result.reason == "준비 중"
    assert db.store["users/u1"]["wallet"]["valueTokenBalance"] == 40
    assert not any(path.startswith("walletTransactions/") for path in db.store)

    service.transfer_value_to_web3("u1", request)
    assert db.store["users/u1"]["wallet"]["valueTokenBalance"] == 40
    assert not any(path.startswith("walletTransactions/") for path in db.store)
