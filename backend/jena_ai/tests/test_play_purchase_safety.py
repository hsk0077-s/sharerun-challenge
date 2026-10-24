"""Product and subscription checks refuse test purchases and tokens bound to another account."""

import pytest
from fastapi import HTTPException

from app.services import play_billing


class _Response:
    def __init__(self, body: dict) -> None:
        self.status_code = 200
        self._body = body

    def json(self) -> dict:
        return self._body


class _Session:
    def __init__(self, body: dict) -> None:
        self._body = body

    def get(self, url: str, timeout: int = 0) -> _Response:
        return _Response(self._body)


def _use(monkeypatch, body: dict) -> None:
    session = _Session(body)
    monkeypatch.setattr(play_billing, "_authorized_session", lambda: (session, "com.example.app"))
    monkeypatch.delenv("GOOGLE_PLAY_ALLOW_TEST_PURCHASES", raising=False)


def test_a_test_purchase_is_refused_by_default(monkeypatch) -> None:
    _use(monkeypatch, {"purchaseState": 0, "purchaseType": 0})
    with pytest.raises(HTTPException):
        play_billing.verify_play_product_purchase("dia_pack_1", "tok")


def test_a_test_purchase_passes_when_the_gate_is_on(monkeypatch) -> None:
    _use(monkeypatch, {"purchaseState": 0, "purchaseType": 0})
    monkeypatch.setenv("GOOGLE_PLAY_ALLOW_TEST_PURCHASES", "true")
    assert play_billing.verify_play_product_purchase("dia_pack_1", "tok")["purchaseType"] == 0


@pytest.mark.parametrize("extra", [{}, {"purchaseType": 1}, {"purchaseType": 2}])
def test_real_purchases_never_need_the_gate(monkeypatch, extra) -> None:
    _use(monkeypatch, {"purchaseState": 0, **extra})
    assert play_billing.verify_play_product_purchase("dia_pack_1", "tok")


def test_a_token_bound_to_another_account_is_refused(monkeypatch) -> None:
    _use(monkeypatch, {"purchaseState": 0, "obfuscatedExternalAccountId": play_billing.account_binding_id("owner")})
    with pytest.raises(HTTPException):
        play_billing.verify_play_product_purchase("dia_pack_1", "tok", "thief")


def test_a_token_bound_to_the_caller_passes(monkeypatch) -> None:
    _use(monkeypatch, {"purchaseState": 0, "obfuscatedExternalAccountId": play_billing.account_binding_id("owner")})
    assert play_billing.verify_play_product_purchase("dia_pack_1", "tok", "owner")


def test_an_unbound_token_still_passes_for_older_app_builds(monkeypatch) -> None:
    _use(monkeypatch, {"purchaseState": 0})
    assert play_billing.verify_play_product_purchase("dia_pack_1", "tok", "anyone")


def _subscription(**extra) -> dict:
    from datetime import datetime, timedelta, timezone

    expiry = (datetime.now(timezone.utc) + timedelta(days=20)).strftime("%Y-%m-%dT%H:%M:%S.%fZ")
    return {
        "subscriptionState": "SUBSCRIPTION_STATE_ACTIVE",
        "latestOrderId": "GPA.1234",
        "lineItems": [{"productId": "coach_plus_monthly", "expiryTime": expiry}],
        **extra,
    }


def test_a_test_subscription_is_refused_by_default(monkeypatch) -> None:
    _use(monkeypatch, _subscription(testPurchase={}))
    with pytest.raises(HTTPException):
        play_billing.verify_play_subscription("coach_plus_monthly", "t")


def test_a_subscription_bound_to_another_account_is_refused(monkeypatch) -> None:
    ids = {"obfuscatedExternalAccountId": play_billing.account_binding_id("owner")}
    _use(monkeypatch, _subscription(externalAccountIdentifiers=ids))
    with pytest.raises(HTTPException):
        play_billing.verify_play_subscription("coach_plus_monthly", "t", "thief")
    assert play_billing.verify_play_subscription("coach_plus_monthly", "t", "owner")
