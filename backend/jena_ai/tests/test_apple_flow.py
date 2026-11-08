"""Apple code exchange and nonce check: local key, stubbed HTTP, no network."""

from __future__ import annotations

import logging

import jwt
import pytest
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import ec

from app.services import apple_flow

CODE = "single-use-code-abc"


@pytest.fixture(scope="module")
def env():
    private = ec.generate_private_key(ec.SECP256R1())
    pem = private.private_bytes(
        serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8, serialization.NoEncryption()
    ).decode()
    return {
        "APPLE_CLIENT_ID": "com.example.test",
        "APPLE_TEAM_ID": "TEAMTEST12",
        "APPLE_KEY_ID": "KEYTEST123",
        "APPLE_PRIVATE_KEY": pem,
    }


def test_exchange_posts_the_documented_form_and_returns_the_tokens(env) -> None:
    seen = {}

    def post(url, data, timeout):
        seen.update(url=url, data=dict(data))
        return 200, {"access_token": "a", "refresh_token": "r", "id_token": "i", "expires_in": 3600}

    result = apple_flow.exchange_authorization_code(CODE, environ=env, post=post)
    assert result["refresh_token"] == "r"
    assert seen["url"] == "https://appleid.apple.com/auth/token"
    assert set(seen["data"]) == {"client_id", "client_secret", "code", "grant_type"}
    assert seen["data"]["grant_type"] == "authorization_code" and seen["data"]["code"] == CODE
    assert seen["data"]["client_id"] == "com.example.test" and "TEAMTEST12" != seen["data"]["client_id"]
    claims = jwt.decode(seen["data"]["client_secret"], options={"verify_signature": False})
    assert claims["sub"] == "com.example.test" and claims["iss"] == "TEAMTEST12"


def test_unconfigured_or_empty_code_never_calls_apple(env) -> None:
    calls = []
    post = lambda *a: calls.append(a) or (200, {"refresh_token": "r"})  # noqa: E731
    assert apple_flow.exchange_authorization_code(CODE, environ={}, post=post) is None
    assert apple_flow.exchange_authorization_code("", environ=env, post=post) is None
    assert calls == []


@pytest.mark.parametrize("status,payload", [(400, {"error": "invalid_grant"}), (200, {}), (200, {"access_token": "a"})])
def test_refusals_and_tokenless_answers_are_failures(env, status, payload) -> None:
    assert apple_flow.exchange_authorization_code(CODE, environ=env, post=lambda *a: (status, payload)) is None


def test_network_error_is_a_failure_not_an_exception(env) -> None:
    def boom(*a):
        raise OSError("down")

    assert apple_flow.exchange_authorization_code(CODE, environ=env, post=boom) is None


def test_logs_hold_no_code_secret_or_token(env, caplog) -> None:
    caplog.set_level(logging.DEBUG)
    apple_flow.exchange_authorization_code(CODE, environ=env, post=lambda *a: (400, {"refresh_token": "SECRET-R"}))
    apple_flow.exchange_authorization_code(CODE, environ=env, post=lambda *a: (_ for _ in ()).throw(OSError(CODE)))
    text = caplog.text
    assert CODE not in text and "SECRET-R" not in text and "BEGIN PRIVATE" not in text


def test_nonce_matches_only_the_hash_of_the_raw_value() -> None:
    raw = "raw-nonce-123"
    assert apple_flow.nonce_matches(apple_flow.hash_nonce(raw), raw)
    assert not apple_flow.nonce_matches(raw, raw)  # the raw value itself is not accepted
    assert not apple_flow.nonce_matches(apple_flow.hash_nonce("other"), raw)


@pytest.mark.parametrize("claim", [None, "", 5])
def test_missing_nonce_claim_is_rejected_when_one_was_expected(claim) -> None:
    assert not apple_flow.nonce_matches(claim, "raw")


def test_no_expected_nonce_never_matches() -> None:
    assert not apple_flow.nonce_matches(apple_flow.hash_nonce(""), "")
