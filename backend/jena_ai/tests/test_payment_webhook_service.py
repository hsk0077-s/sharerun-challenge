import hashlib
import hmac

import pytest
from fastapi import HTTPException

from app.models.payment_webhook import PaymentWebhookRequest
from app.services.payment_webhook_service import PaymentWebhookService


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


def test_amount_policy_accepts_supported_share_top_up_amount() -> None:
    PaymentWebhookService()._ensure_supported_amount("share_top_up", 10_000)


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


def test_already_processed_payment_returns_idempotent_result() -> None:
    result = PaymentWebhookService()._already_processed_result("intent-test")

    assert result.accepted is True
    assert result.payment_intent_id == "intent-test"
    assert result.status == "credited"
    assert result.reason == "Payment intent was already processed."
