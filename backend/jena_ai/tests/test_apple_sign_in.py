"""Sign in with Apple on the iPhone: nonce check and revoke on account delete."""

import hashlib
from unittest.mock import MagicMock, patch

import jwt
import pytest
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import ec
from fastapi import HTTPException

from app.routers import identity_router
from app.services import apple_revoke, identities
from app.services.secured_action_service import SecuredActionService

RAW_NONCE = "raw-nonce-from-the-phone"
HASHED = hashlib.sha256(RAW_NONCE.encode()).hexdigest()


def _apple_token(monkeypatch, claims: dict) -> None:
    monkeypatch.setattr(identities, "_unverified_issuer", lambda token: identities.APPLE_ISSUER)
    monkeypatch.setattr(identities, "_apple_claims", lambda token, audience: dict(claims))
    monkeypatch.delenv("APPLE_CLIENT_ID", raising=False)


# --- nonce ------------------------------------------------------------------


def test_matching_nonce_is_accepted(monkeypatch) -> None:
    _apple_token(monkeypatch, {"sub": "s1", "nonce": HASHED})
    assert identities.verify_apple_id_token("t" * 20, RAW_NONCE).user_id == "s1"


@pytest.mark.parametrize("sent", [None, "", "another-nonce"])
def test_a_token_with_a_nonce_needs_the_matching_raw_nonce(monkeypatch, sent) -> None:
    _apple_token(monkeypatch, {"sub": "s1", "nonce": HASHED})
    with pytest.raises(HTTPException) as caught:
        identities.verify_apple_id_token("t" * 20, sent)
    assert caught.value.status_code == 401


def test_a_token_without_a_nonce_still_works_but_not_with_one_sent(monkeypatch) -> None:
    _apple_token(monkeypatch, {"sub": "s1"})
    assert identities.verify_apple_id_token("t" * 20).user_id == "s1"
    with pytest.raises(HTTPException):
        identities.verify_apple_id_token("t" * 20, RAW_NONCE)


def test_hide_my_email_relay_address_is_kept_as_the_verified_email(monkeypatch) -> None:
    _apple_token(
        monkeypatch,
        {
            "sub": "s1",
            "nonce": HASHED,
            "email": "Abc123@privaterelay.appleid.com",
            "email_verified": "true",
            "is_private_email": "true",
        },
    )
    identity = identities.verify_apple_id_token("t" * 20, RAW_NONCE)
    assert identity.verified_email == "abc123@privaterelay.appleid.com"


def test_no_email_at_all_still_signs_in(monkeypatch) -> None:
    # Later Apple sign-ins carry no name, and may carry no e-mail.
    _apple_token(monkeypatch, {"sub": "s1", "nonce": HASHED})
    identity = identities.verify_apple_id_token("t" * 20, RAW_NONCE)
    assert identity == identities.ProviderIdentity("s1", None)


def test_the_router_passes_the_nonce_to_login_and_link(monkeypatch) -> None:
    seen = []

    def fake_login(db, provider, token, *, verify, create_account=False):
        seen.append(("login", provider, verify(token).user_id, create_account))
        return {"custom_token": "c", "new_account": False}

    def fake_link(db, uid, provider, token, *, verify):
        seen.append(("link", provider, verify(token).user_id))
        return {"linked": True}

    _apple_token(monkeypatch, {"sub": "s1", "nonce": HASHED})
    monkeypatch.setattr(identity_router, "_db", lambda: None)
    monkeypatch.setattr(identity_router.identities, "login", fake_login)
    monkeypatch.setattr(identity_router.identities, "link", fake_link)
    monkeypatch.setattr(identity_router.identities, "allow_login_attempt", lambda *a: True)
    monkeypatch.setattr(identity_router, "_throttle_link", lambda *a: None)
    request = MagicMock()
    body = identity_router.AppleTokenRequest(id_token="t" * 20, nonce=RAW_NONCE, create_account=True)
    identity_router.apple_login(body, request)
    identity_router.apple_link(body, request, uid="u1")
    assert seen == [("login", "apple", "s1", True), ("link", "apple", "s1")]

    wrong = identity_router.AppleTokenRequest(id_token="t" * 20, nonce="nope")
    with pytest.raises(HTTPException):
        identity_router.apple_login(wrong, request)


# --- revoke -----------------------------------------------------------------


def _config() -> dict[str, str]:
    key = ec.generate_private_key(ec.SECP256R1())
    pem = key.private_bytes(
        serialization.Encoding.PEM,
        serialization.PrivateFormat.PKCS8,
        serialization.NoEncryption(),
    ).decode()
    return {
        "team_id": "TEAM123456",
        "key_id": "KEY1234567",
        "private_key": pem,
        "client_id": "com.sharerun.shareRunChallenge",
        "_public": key.public_key(),
    }


def test_client_secret_is_a_short_es256_token_for_apple() -> None:
    config = _config()
    secret = apple_revoke.client_secret(config, now=1_000_000)
    header = jwt.get_unverified_header(secret)
    assert header == {"alg": "ES256", "kid": "KEY1234567", "typ": "JWT"}
    claims = jwt.decode(
        secret,
        config["_public"],
        algorithms=["ES256"],
        audience="https://appleid.apple.com",
        options={"verify_exp": False},
    )
    assert claims["iss"] == "TEAM123456"
    assert claims["sub"] == "com.sharerun.shareRunChallenge"
    assert claims["exp"] - claims["iat"] <= 300


def test_revoke_exchanges_the_code_then_revokes_the_refresh_token() -> None:
    calls = []

    def post(url, form):
        calls.append((url, dict(form)))
        if url == apple_revoke.TOKEN_URL:
            return 200, {"refresh_token": "r-token", "access_token": "a-token"}
        return 200, {}

    assert apple_revoke.revoke_with_code("code-1", post=post, config=_config()) == "revoked"
    token_url, token_form = calls[0]
    assert token_url == apple_revoke.TOKEN_URL
    assert token_form["grant_type"] == "authorization_code"
    assert token_form["code"] == "code-1"
    assert token_form["client_id"] == "com.sharerun.shareRunChallenge"
    revoke_url, revoke_form = calls[1]
    assert revoke_url == apple_revoke.REVOKE_URL
    assert revoke_form["token"] == "r-token"
    assert revoke_form["token_type_hint"] == "refresh_token"


@pytest.mark.parametrize(
    "code, config, responses, outcome",
    [
        ("", "set", [], "no_code"),
        ("c", None, [], "not_configured"),
        ("c", "set", [(400, {"error": "invalid_grant"})], "exchange_failed"),
        ("c", "set", [(200, {"refresh_token": "r"}), (500, {})], "revoke_failed"),
    ],
)
def test_revoke_never_raises(monkeypatch, code, config, responses, outcome) -> None:
    for name in ("APPLE_TEAM_ID", "APPLE_KEY_ID", "APPLE_PRIVATE_KEY", "APPLE_CLIENT_ID"):
        monkeypatch.delenv(name, raising=False)
    queue = list(responses)
    result = apple_revoke.revoke_with_code(
        code,
        post=lambda url, form: queue.pop(0),
        config=_config() if config == "set" else None,
    )
    assert result == outcome


def test_account_delete_revokes_only_when_the_phone_sent_a_code() -> None:
    service = SecuredActionService(firebase_service=MagicMock())
    user_ref = MagicMock()
    user_ref.get.return_value.exists = True
    service.firebase_service.db.collection.return_value.document.return_value = user_ref

    with patch("app.services.secured_action_service.firebase_auth.delete_user"), patch(
        "app.services.secured_action_service.apple_revoke.revoke_with_code",
        return_value="revoked",
    ) as revoke:
        service.delete_account("u1")
        revoke.assert_not_called()
        result = service.delete_account("u1", apple_authorization_code="code-9")
    revoke.assert_called_once_with("code-9")
    assert result.status == "deleted"


def test_account_delete_still_succeeds_when_apple_fails() -> None:
    service = SecuredActionService(firebase_service=MagicMock())
    user_ref = MagicMock()
    user_ref.get.return_value.exists = True
    service.firebase_service.db.collection.return_value.document.return_value = user_ref
    with patch("app.services.secured_action_service.firebase_auth.delete_user"), patch(
        "app.services.apple_revoke._post", side_effect=OSError("down")
    ), patch.dict(
        "os.environ",
        {
            "APPLE_TEAM_ID": "TEAM123456",
            "APPLE_KEY_ID": "KEY1234567",
            "APPLE_PRIVATE_KEY": _config()["private_key"],
            "APPLE_CLIENT_ID": "com.sharerun.shareRunChallenge",
        },
    ):
        result = service.delete_account("u1", apple_authorization_code="code-9")
    assert result.accepted is True
    assert result.status == "deleted"


def test_delete_endpoint_takes_the_old_empty_body_and_the_new_code(monkeypatch) -> None:
    from fastapi.testclient import TestClient

    from app.main import app
    from app.routers import secured_action_router
    from app.services.auth_service import require_uid

    seen = []

    def fake_delete(uid, apple_authorization_code=None):
        seen.append((uid, apple_authorization_code))
        return secured_action_router.SecuredActionResult(
            accepted=True, status="deleted", reason="ok"
        )

    monkeypatch.setattr(secured_action_router.service, "delete_account", fake_delete)
    app.dependency_overrides[require_uid] = lambda: "u-1"
    try:
        client = TestClient(app)
        assert client.post("/actions/account/delete", json={}).status_code == 200
        assert client.post("/actions/account/delete").status_code == 200
        assert (
            client.post(
                "/actions/account/delete",
                json={"apple_authorization_code": "code-7"},
            ).status_code
            == 200
        )
    finally:
        app.dependency_overrides.clear()
    assert seen == [("u-1", None), ("u-1", None), ("u-1", "code-7")]
