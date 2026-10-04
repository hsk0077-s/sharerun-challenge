import hashlib
import hmac
import logging
from types import SimpleNamespace

import pytest
from fastapi import HTTPException

from app.models.payment_webhook import PaymentWebhookRequest
from app.services.payment_webhook_service import PaymentWebhookService
from test_redeem_referral import _MemoryDb, _MemoryTxn


def _request(signature: str, currency: str = "KRW") -> PaymentWebhookRequest:
    return PaymentWebhookRequest(
        payment_intent_id="intent-test",
        pg_transaction_id="pg-test",
        status="paid",
        amount=10_000,
        currency=currency,
        signature=signature,
    )


def test_signature_payload_matches_pg_contract() -> None:
    service = PaymentWebhookService()
    request = _request(signature="placeholder")

    assert service._signature_payload(request) == "intent-test.pg-test.10000.paid"


def test_handle_webhook_uses_module_transaction(monkeypatch) -> None:
    class _Db:
        def transaction(self):
            return object()

        def collection(self, name):
            return self

        def document(self, doc_id=None):
            return object()

    service = PaymentWebhookService(
        firebase_service=type("FS", (), {"db": _Db()})()
    )
    service.webhook_secret = "dev-secret"
    signature = hmac.new(
        b"dev-secret",
        b"intent-test.pg-test.10000.paid",
        hashlib.sha256,
    ).hexdigest()
    seen: dict = {}

    def fake(transaction, service_arg, intent_ref, request):
        seen["intent"] = request.payment_intent_id
        seen["service"] = service_arg
        return "ok"

    monkeypatch.setattr(
        "app.services.payment_webhook_service._commit_webhook_tx",
        fake,
    )
    assert service.handle_webhook(_request(signature=signature)) == "ok"
    assert seen["intent"] == "intent-test"
    assert seen["service"] is service


def test_signature_validation_accepts_matching_hmac() -> None:
    service = PaymentWebhookService()
    service.webhook_secret = "dev-secret"
    signature = hmac.new(
        b"dev-secret",
        b"intent-test.pg-test.10000.paid",
        hashlib.sha256,
    ).hexdigest()

    assert service._signature_is_valid(_request(signature=signature)) is True


def test_signature_validation_rejects_mismatched_hmac() -> None:
    service = PaymentWebhookService()
    service.webhook_secret = "dev-secret"

    assert service._signature_is_valid(_request(signature="bad-signature")) is False


def test_currency_validation_accepts_krw_case_insensitively() -> None:
    service = PaymentWebhookService()

    service._ensure_supported_currency(_request(signature="placeholder", currency="krw"))


def test_currency_validation_rejects_non_krw() -> None:
    service = PaymentWebhookService()

    with pytest.raises(HTTPException) as exc_info:
        service._ensure_supported_currency(
            _request(signature="placeholder", currency="USD")
        )

    assert exc_info.value.status_code == 400
    assert exc_info.value.detail == "Only KRW payment webhooks are supported."


def test_sponsor_uid_from_intent_accepts_matching_owner() -> None:
    service = PaymentWebhookService()

    assert service._sponsor_uid_from_intent(
        {"uid": "user-test", "sponsorId": "user-test"}
    ) == "user-test"


def test_sponsor_uid_from_intent_rejects_missing_owner() -> None:
    service = PaymentWebhookService()

    with pytest.raises(HTTPException) as exc_info:
        service._sponsor_uid_from_intent({"sponsorId": "user-test"})

    assert exc_info.value.status_code == 400
    assert exc_info.value.detail == "Sponsor payment intent has invalid owner identity."


def test_sponsor_uid_from_intent_rejects_mismatched_owner() -> None:
    service = PaymentWebhookService()

    with pytest.raises(HTTPException) as exc_info:
        service._sponsor_uid_from_intent(
            {"uid": "user-test", "sponsorId": "other-user"}
        )

    assert exc_info.value.status_code == 400
    assert exc_info.value.detail == "Sponsor payment intent has invalid owner identity."


def test_share_top_up_uid_from_intent_accepts_valid_owner() -> None:
    service = PaymentWebhookService()

    assert service._share_top_up_uid_from_intent({"uid": "user-test"}) == "user-test"


def test_share_top_up_uid_from_intent_rejects_missing_owner() -> None:
    service = PaymentWebhookService()

    with pytest.raises(HTTPException) as exc_info:
        service._share_top_up_uid_from_intent({})

    assert exc_info.value.status_code == 400
    assert exc_info.value.detail == "Share top-up intent has invalid owner identity."


def test_share_top_up_uid_from_intent_rejects_conflicting_sponsor_id() -> None:
    service = PaymentWebhookService()

    with pytest.raises(HTTPException) as exc_info:
        service._share_top_up_uid_from_intent(
            {"uid": "user-test", "sponsorId": "other-user"}
        )

    assert exc_info.value.status_code == 400
    assert exc_info.value.detail == "Share top-up intent has invalid owner identity."


def test_amount_policy_rejects_share_top_up_amount() -> None:
    with pytest.raises(HTTPException) as exc_info:
        PaymentWebhookService()._ensure_supported_amount("share_top_up", 10_000)

    assert exc_info.value.status_code == 400
    assert exc_info.value.detail == "Payment intent amount is not supported."


def test_amount_policy_accepts_supported_sponsor_amounts() -> None:
    service = PaymentWebhookService()

    for amount in [1_000, 3_000, 5_000]:
        service._ensure_supported_amount("sponsor_payment", amount)


def test_amount_policy_rejects_unsupported_share_top_up_amount() -> None:
    with pytest.raises(HTTPException) as exc_info:
        PaymentWebhookService()._ensure_supported_amount("share_top_up", 20_000)

    assert exc_info.value.status_code == 400
    assert exc_info.value.detail == "Payment intent amount is not supported."


def test_amount_policy_rejects_unsupported_sponsor_amount() -> None:
    with pytest.raises(HTTPException) as exc_info:
        PaymentWebhookService()._ensure_supported_amount("sponsor_payment", 2_000)

    assert exc_info.value.status_code == 400
    assert exc_info.value.detail == "Payment intent amount is not supported."


def _paid_request(
    intent_id: str,
    amount: int,
    *,
    status: str = "paid",
) -> PaymentWebhookRequest:
    return PaymentWebhookRequest(
        payment_intent_id=intent_id,
        pg_transaction_id="pg-test",
        status=status,
        amount=amount,
        currency="KRW",
        signature="unused",
    )


def test_share_top_up_rejects_without_crediting_share(caplog) -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {
        "wallet": {
            "shareBalance": 5,
            "paidShareBalance": 0,
            "freeShareBalance": 5,
        }
    }
    db.store["paymentIntents/intent-share"] = {
        "uid": "u1",
        "type": "share_top_up",
        "amountKrw": 10_000,
        "status": "created",
    }
    service = PaymentWebhookService(firebase_service=SimpleNamespace(db=db))
    intent_ref = db.collection("paymentIntents").document("intent-share")
    request = _paid_request("intent-share", 10_000)

    with caplog.at_level(logging.WARNING):
        result = service._apply_webhook_in_transaction(
            _MemoryTxn(), intent_ref, request
        )

    assert result.accepted is False
    assert result.status == "rejected"
    assert result.reason == "SHARE is not sold for money."
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 5
    assert db.store["paymentIntents/intent-share"]["status"] == "rejected"
    assert db.store["paymentIntents/intent-share"]["rejectReason"] == "share_not_for_sale"
    assert not any(path.startswith("walletTransactions/") for path in db.store)
    assert "share_top_up" in caplog.text
    assert "intent-share" in caplog.text

    again = service._apply_webhook_in_transaction(_MemoryTxn(), intent_ref, request)
    assert again.accepted is False
    assert again.status == "rejected"
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 5
    assert not any(path.startswith("walletTransactions/") for path in db.store)


def test_sponsor_payment_still_applies_without_selling_share() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {"wallet": {"shareBalance": 5}}
    db.store["tournaments/race"] = {"sponsorPrizeSupportShare": 1_000}
    db.store["paymentIntents/intent-sponsor"] = {
        "uid": "u1",
        "sponsorId": "u1",
        "type": "sponsor_payment",
        "tournamentId": "race",
        "option": "direct_prize_support",
        "amountShare": 3_000,
        "status": "created",
    }
    service = PaymentWebhookService(firebase_service=SimpleNamespace(db=db))
    intent_ref = db.collection("paymentIntents").document("intent-sponsor")

    result = service._apply_webhook_in_transaction(
        _MemoryTxn(),
        intent_ref,
        _paid_request("intent-sponsor", 3_000),
    )

    assert result.accepted is True
    assert result.status == "credited"
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 5
    assert db.store["tournaments/race"]["sponsorPrizeSupportShare"] == 4_000
    ledger = [
        row for path, row in db.store.items() if path.startswith("walletTransactions/")
    ]
    assert ledger[0]["type"] == "sponsor_payment_verified"
    assert ledger[0]["shareAmount"] == 0
    assert ledger[0]["sponsorAmount"] == 3_000


def test_already_processed_payment_returns_idempotent_result() -> None:
    result = PaymentWebhookService()._already_processed_result("intent-test")

    assert result.accepted is True
    assert result.payment_intent_id == "intent-test"
    assert result.status == "credited"
    assert result.reason == "Payment intent was already processed."
