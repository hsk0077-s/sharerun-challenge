"""Prepared (not wired) Apple token revocation: local key, stubbed HTTP, no network."""

from __future__ import annotations

import logging

import jwt
import pytest
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import ec

from app.services import apple_revoke

TOKEN = "refresh-token-value-123"


@pytest.fixture(scope="module")
def key_pair():
    private = ec.generate_private_key(ec.SECP256R1())
    pem = private.private_bytes(
        serialization.Encoding.PEM,
        serialization.PrivateFormat.PKCS8,
        serialization.NoEncryption(),
    ).decode()
    return pem, private.public_key()


def _env(pem: str) -> dict[str, str]:
    return {
        "APPLE_CLIENT_ID": "com.sharerun.shareRunChallenge",
        "APPLE_TEAM_ID": "TEAM123456",
        "APPLE_KEY_ID": "KEY1234567",
        "APPLE_PRIVATE_KEY": pem,
    }


def test_not_configured_when_any_setting_is_missing(key_pair) -> None:
    pem, _ = key_pair
    assert apple_revoke.is_configured(_env(pem)) is True
    for name in apple_revoke.REQUIRED_SETTINGS:
        env = _env(pem)
        env[name] = "  "
        assert apple_revoke.is_configured(env) is False, name
        del env[name]
        assert apple_revoke.is_configured(env) is False, name


def test_unconfigured_never_calls_apple(key_pair) -> None:
    calls = []
    assert apple_revoke.revoke_token(TOKEN, environ={}, post=lambda *a: calls.append(a) or 200) is False
    assert calls == []


def test_client_secret_is_a_short_es256_jwt_for_our_app(key_pair) -> None:
    pem, public = key_pair
    secret = apple_revoke.build_client_secret(_env(pem), now=1_000_000)
    header = jwt.get_unverified_header(secret)
    assert header["alg"] == "ES256"
    assert header["kid"] == "KEY1234567"
    claims = jwt.decode(
        secret,
        public,
        algorithms=["ES256"],
        audience=apple_revoke.APPLE_AUDIENCE,
        options={"verify_exp": False, "verify_iat": False},
    )
    assert claims["iss"] == "TEAM123456"
    assert claims["sub"] == "com.sharerun.shareRunChallenge"
    assert claims["exp"] - claims["iat"] == apple_revoke.CLIENT_SECRET_LIFETIME_SECONDS


def test_private_key_with_escaped_newlines_still_works(key_pair) -> None:
    pem, public = key_pair
    env = _env(pem.replace("\n", "\\n"))
    secret = apple_revoke.build_client_secret(env, now=1_000_000)
    jwt.decode(secret, public, algorithms=["ES256"], audience=apple_revoke.APPLE_AUDIENCE,
               options={"verify_exp": False, "verify_iat": False})


def test_revoke_posts_the_expected_form_and_reports_success(key_pair) -> None:
    pem, _ = key_pair
    seen = {}

    def post(url, data, timeout):
        seen.update(url=url, data=dict(data), timeout=timeout)
        return 200

    assert apple_revoke.revoke_token(TOKEN, environ=_env(pem), post=post) is True
    assert seen["url"] == apple_revoke.APPLE_REVOKE_URL
    assert set(seen["data"]) == {"client_id", "client_secret", "token", "token_type_hint"}
    assert seen["data"]["token"] == TOKEN
    assert seen["data"]["token_type_hint"] == "refresh_token"
    assert seen["data"]["client_id"] == "com.sharerun.shareRunChallenge"


@pytest.mark.parametrize("status", [400, 401, 500])
def test_non_200_is_a_failure(key_pair, status) -> None:
    pem, _ = key_pair
    assert apple_revoke.revoke_token(TOKEN, environ=_env(pem), post=lambda *a: status) is False


def test_network_error_is_a_failure_not_an_exception(key_pair) -> None:
    pem, _ = key_pair

    def boom(*args):
        raise OSError("connection reset")

    assert apple_revoke.revoke_token(TOKEN, environ=_env(pem), post=boom) is False


def test_bad_key_material_is_a_failure_not_an_exception() -> None:
    env = _env("not a key")
    assert apple_revoke.revoke_token(TOKEN, environ=env, post=lambda *a: 200) is False


def test_nothing_secret_reaches_the_logs(key_pair, caplog) -> None:
    pem, _ = key_pair
    captured = {}

    def post(url, data, timeout):
        captured.update(data)
        return 400

    with caplog.at_level(logging.DEBUG):
        apple_revoke.revoke_token(TOKEN, environ=_env(pem), post=post)
        apple_revoke.revoke_token(TOKEN, environ=_env("not a key"), post=lambda *a: 200)
    text = "\n".join(record.getMessage() for record in caplog.records)
    assert TOKEN not in text
    assert captured["client_secret"] not in text
    assert "BEGIN" not in text
    assert "KEY1234567" not in text and "TEAM123456" not in text


def test_client_secret_lifetime_is_within_apples_documented_limit(key_pair) -> None:
    pem, public = key_pair
    secret = apple_revoke.build_client_secret(_env(pem), now=1_700_000_000)
    claims = jwt.decode(secret, public, algorithms=["ES256"], audience="https://appleid.apple.com",
                        options={"verify_exp": False})
    assert 0 < claims["exp"] - claims["iat"] <= apple_revoke.MAX_CLIENT_SECRET_LIFETIME_SECONDS
    assert claims["iss"] == "TEAM123456" and claims["sub"] == "com.sharerun.shareRunChallenge"


def test_client_id_is_never_the_team_id(key_pair) -> None:
    pem, _ = key_pair
    seen = {}
    apple_revoke.revoke_token(TOKEN, environ=_env(pem), post=lambda u, d, t: seen.update(d) or 200)
    assert seen["client_id"] != "TEAM123456"


@pytest.mark.parametrize("hint", ["access_token", "refresh_token"])
def test_both_documented_hints_are_sent(key_pair, hint) -> None:
    pem, _ = key_pair
    seen = {}
    ok = apple_revoke.revoke_token(TOKEN, token_type_hint=hint, environ=_env(pem),
                                   post=lambda u, d, t: seen.update(d) or 200)
    assert ok and seen["token_type_hint"] == hint


def test_undocumented_hint_is_refused_without_calling_apple(key_pair) -> None:
    pem, _ = key_pair
    calls = []
    assert apple_revoke.revoke_token(TOKEN, token_type_hint="id_token", environ=_env(pem),
                                     post=lambda *a: calls.append(a) or 200) is False
    assert calls == []
