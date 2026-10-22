"""Play subscription checks: only a paid-up subscription to the asked product counts."""

from datetime import datetime, timedelta, timezone

import pytest
from fastapi import HTTPException

from app.services import play_billing


class _Response:
    def __init__(self, status_code: int, body: dict | None = None) -> None:
        self.status_code = status_code
        self._body = body or {}

    def json(self) -> dict:
        return self._body


class _Session:
    def __init__(self, response: _Response) -> None:
        self._response = response
        self.urls: list[str] = []

    def get(self, url: str, timeout: int = 0) -> _Response:
        self.urls.append(url)
        return self._response


def _expiry(days: int) -> str:
    moment = datetime.now(timezone.utc) + timedelta(days=days)
    return moment.strftime("%Y-%m-%dT%H:%M:%S.%fZ")


def _use(monkeypatch, response: _Response) -> _Session:
    session = _Session(response)
    monkeypatch.setattr(play_billing, "_authorized_session", lambda: (session, "com.example.app"))
    return session


def _body(state: str = "SUBSCRIPTION_STATE_ACTIVE", product: str = "coach_plus_monthly", days: int = 20):
    return {
        "subscriptionState": state,
        "latestOrderId": "GPA.1234",
        "lineItems": [{"productId": product, "expiryTime": _expiry(days)}],
    }


def test_an_active_subscription_returns_the_play_expiry(monkeypatch) -> None:
    session = _use(monkeypatch, _Response(200, _body()))

    verified = play_billing.verify_play_subscription("coach_plus_monthly", "tok/en")

    assert verified["orderId"] == "GPA.1234"
    assert verified["expiresAt"] > datetime.now(timezone.utc) + timedelta(days=19)
    assert "/purchases/subscriptionsv2/tokens/tok%2Fen" in session.urls[0]
    assert "/applications/com.example.app/" in session.urls[0]


@pytest.mark.parametrize(
    "state",
    ["SUBSCRIPTION_STATE_ACTIVE", "SUBSCRIPTION_STATE_CANCELED", "SUBSCRIPTION_STATE_IN_GRACE_PERIOD"],
)
def test_states_that_still_pay_for_access_are_accepted(monkeypatch, state) -> None:
    _use(monkeypatch, _Response(200, _body(state=state)))
    assert play_billing.verify_play_subscription("coach_plus_monthly", "t")["state"] == state


@pytest.mark.parametrize(
    "state",
    [
        "SUBSCRIPTION_STATE_ON_HOLD",
        "SUBSCRIPTION_STATE_PAUSED",
        "SUBSCRIPTION_STATE_EXPIRED",
        "SUBSCRIPTION_STATE_PENDING",
        "",
    ],
)
def test_states_that_do_not_pay_for_access_are_rejected(monkeypatch, state) -> None:
    _use(monkeypatch, _Response(200, _body(state=state)))
    with pytest.raises(HTTPException) as raised:
        play_billing.verify_play_subscription("coach_plus_monthly", "t")
    assert raised.value.status_code == 400


def test_a_token_for_another_product_is_rejected(monkeypatch) -> None:
    _use(monkeypatch, _Response(200, _body(product="coach_plus_yearly")))
    with pytest.raises(HTTPException) as raised:
        play_billing.verify_play_subscription("coach_plus_monthly", "t")
    assert raised.value.status_code == 400


def test_an_expired_subscription_is_rejected(monkeypatch) -> None:
    _use(monkeypatch, _Response(200, _body(days=-1)))
    with pytest.raises(HTTPException) as raised:
        play_billing.verify_play_subscription("coach_plus_monthly", "t")
    assert raised.value.status_code == 400


def test_a_missing_or_unreadable_expiry_is_rejected(monkeypatch) -> None:
    body = _body()
    body["lineItems"][0]["expiryTime"] = "not-a-date"
    _use(monkeypatch, _Response(200, body))
    with pytest.raises(HTTPException):
        play_billing.verify_play_subscription("coach_plus_monthly", "t")


def test_play_saying_no_is_a_rejection(monkeypatch) -> None:
    _use(monkeypatch, _Response(404))
    with pytest.raises(HTTPException) as raised:
        play_billing.verify_play_subscription("coach_plus_monthly", "t")
    assert raised.value.status_code == 400


def test_not_configured_is_503(monkeypatch) -> None:
    monkeypatch.delenv("GOOGLE_PLAY_PACKAGE_NAME", raising=False)
    monkeypatch.delenv("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON", raising=False)
    with pytest.raises(HTTPException) as raised:
        play_billing.verify_play_subscription("coach_plus_monthly", "t")
    assert raised.value.status_code == 503
