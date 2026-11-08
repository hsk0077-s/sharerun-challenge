"""Apple identity token audience: real RS256 tokens, no mocks of the signature check.

An Apple-issued identity token is signed by Apple for ONE app (`aud` = that app's
bundle id). Any app on the App Store can obtain a validly signed Apple token for
any of its own users, so a server that does not check `aud` accepts tokens minted
for other apps. These tests build real signed tokens with a local key and swap only
Apple's public-key lookup, so the audience logic in `identities` runs for real.
"""

from __future__ import annotations

import logging
import time

import jwt
import pytest
from cryptography.hazmat.primitives.asymmetric import rsa
from fastapi import HTTPException

from app.services import identities

OUR_BUNDLE_ID = "com.sharerun.shareRunChallenge"
OTHER_APP = "com.someone.else"


@pytest.fixture(scope="module")
def apple_key():
    return rsa.generate_private_key(public_exponent=65537, key_size=2048)


@pytest.fixture(autouse=True)
def fake_apple_keys(monkeypatch, apple_key):
    class _SigningKey:
        key = apple_key.public_key()

    class _Jwks:
        def get_signing_key_from_jwt(self, token):
            return _SigningKey()

    monkeypatch.setattr(identities, "_apple_jwks", _Jwks())


def _token(apple_key, *, aud: str, sub: str = "apple-sub-1", **extra) -> str:
    now = int(time.time())
    claims = {
        "iss": identities.APPLE_ISSUER,
        "aud": aud,
        "sub": sub,
        "iat": now,
        "exp": now + 600,
        "email": "Person@Example.com",
        "email_verified": "true",
        **extra,
    }
    return jwt.encode(claims, apple_key, algorithm="RS256", headers={"kid": "test"})


def test_configured_audience_accepts_our_app(monkeypatch, apple_key) -> None:
    monkeypatch.setenv("APPLE_CLIENT_ID", OUR_BUNDLE_ID)
    identity = identities.verify_apple_id_token(_token(apple_key, aud=OUR_BUNDLE_ID))
    assert identity.user_id == "apple-sub-1"
    assert identity.verified_email == "person@example.com"


def test_configured_audience_rejects_another_app(monkeypatch, apple_key) -> None:
    monkeypatch.setenv("APPLE_CLIENT_ID", OUR_BUNDLE_ID)
    with pytest.raises(HTTPException) as caught:
        identities.verify_apple_id_token(_token(apple_key, aud=OTHER_APP))
    assert caught.value.status_code == 401
    assert caught.value.detail == "invalid_provider_token"


@pytest.mark.parametrize("value", [None, "", "   "])
def test_missing_audience_setting_refuses_apple_tokens(monkeypatch, apple_key, value) -> None:
    """A token that is correctly signed by Apple for ANOTHER app must not log in
    when the server has no APPLE_CLIENT_ID. Before the fix this returned an
    identity because the audience check was skipped."""
    if value is None:
        monkeypatch.delenv("APPLE_CLIENT_ID", raising=False)
    else:
        monkeypatch.setenv("APPLE_CLIENT_ID", value)
    for aud in (OTHER_APP, OUR_BUNDLE_ID):
        with pytest.raises(HTTPException) as caught:
            identities.verify_apple_id_token(_token(apple_key, aud=aud))
        assert caught.value.status_code == 503
        assert caught.value.detail == "apple_login_not_configured"


def test_missing_setting_does_not_touch_the_firebase_apple_path(monkeypatch) -> None:
    """Android signs in with Apple through Firebase; that token is checked by
    Firebase (project audience), not by APPLE_CLIENT_ID."""
    monkeypatch.delenv("APPLE_CLIENT_ID", raising=False)
    monkeypatch.setattr(identities, "_unverified_issuer", lambda token: "https://securetoken.google.com/p")
    monkeypatch.setattr(
        identities,
        "_firebase_claims",
        lambda token: {
            "email": "a@b.com",
            "email_verified": True,
            "firebase": {"sign_in_provider": "apple.com", "identities": {"apple.com": ["fb-sub"]}},
        },
    )
    assert identities.verify_apple_id_token("t" * 20).user_id == "fb-sub"


def test_missing_setting_does_not_touch_other_providers(monkeypatch) -> None:
    monkeypatch.delenv("APPLE_CLIENT_ID", raising=False)
    assert set(identities.VERIFIERS) == {"kakao", "naver", "google", "apple"}
    for provider in ("kakao", "naver", "google"):
        assert identities.VERIFIERS[provider] is not identities.verify_apple_id_token
    assert identities.VERIFIERS["apple"] is identities.verify_apple_id_token


def test_refusal_logs_no_token_or_key_material(monkeypatch, apple_key, caplog) -> None:
    monkeypatch.delenv("APPLE_CLIENT_ID", raising=False)
    token = _token(apple_key, aud=OTHER_APP)
    with caplog.at_level(logging.DEBUG):
        with pytest.raises(HTTPException):
            identities.verify_apple_id_token(token)
    text = "\n".join(record.getMessage() for record in caplog.records)
    assert token not in text
    assert token.split(".")[1] not in text  # payload
    assert "apple-sub-1" not in text
    assert "BEGIN" not in text
    assert "APPLE_CLIENT_ID" in text  # the operator learns WHAT to set, not any value
