"""Sign in with Apple: authorization-code exchange and nonce check. PREPARED, NOT WIRED, NOT DEPLOYED.

See docs/ios-apple-auth.md for the whole flow. Nothing here calls Apple unless a caller
passes real settings, and nothing in the app or routers calls it yet.

Token endpoint (Apple "Generate and validate tokens", read 2026-11-08):
  POST https://appleid.apple.com/auth/token, form fields client_id, client_secret, code,
  grant_type=authorization_code (redirect_uri only if the authorization request had one).
  The code is single-use and valid for five minutes. Success returns access_token,
  token_type, expires_in, refresh_token, id_token.

Nonce (Apple "Verifying a user": "Verify the nonce for the authentication"): Apple does not say
how the nonce is formed. This project's design: the server issues a random raw nonce, the app
sends sha256-hex(raw) to Apple, and the identity token's `nonce` claim must equal
sha256-hex(raw). Whether Apple puts the value into the token unchanged is 미확인 until a real
device test.
"""

from __future__ import annotations

import hashlib
import hmac
import json
import logging
import urllib.parse
import urllib.request
from collections.abc import Callable, Mapping

from app.services.apple_revoke import build_client_secret, is_configured

_logger = logging.getLogger(__name__)

APPLE_TOKEN_URL = "https://appleid.apple.com/auth/token"

PostJson = Callable[[str, Mapping[str, str], float], tuple[int, dict]]


def hash_nonce(raw_nonce: str) -> str:
    return hashlib.sha256(raw_nonce.encode("utf-8")).hexdigest()


def nonce_matches(claim: object, raw_nonce: str) -> bool:
    """True only when a nonce was expected, the token carries one and it matches."""
    if not raw_nonce or not isinstance(claim, str) or not claim:
        return False
    return hmac.compare_digest(claim, hash_nonce(raw_nonce))


def _default_post_json(url: str, data: Mapping[str, str], timeout: float) -> tuple[int, dict]:
    body = urllib.parse.urlencode(dict(data)).encode()
    request = urllib.request.Request(
        url, data=body, method="POST", headers={"Content-Type": "application/x-www-form-urlencoded"}
    )
    with urllib.request.urlopen(request, timeout=timeout) as response:  # noqa: S310
        return int(response.status), json.loads(response.read().decode("utf-8") or "{}")


def exchange_authorization_code(
    code: str,
    *,
    environ: Mapping[str, str] | None = None,
    post: PostJson | None = None,
    now: float | None = None,
    timeout: float = 8.0,
) -> dict | None:
    """Apple's token response (contains a refresh_token), or None on any failure.

    Never raises and never logs the code, the client secret or the returned tokens.
    The caller decides whether the refresh token may be stored (see the doc)."""
    import os

    env = os.environ if environ is None else environ
    if not code or not is_configured(env):
        return None
    try:
        status, payload = (post or _default_post_json)(
            APPLE_TOKEN_URL,
            {
                "client_id": str(env["APPLE_CLIENT_ID"]).strip(),
                "client_secret": build_client_secret(env, now),
                "code": code,
                "grant_type": "authorization_code",
            },
            timeout,
        )
    except Exception as error:
        _logger.warning("Apple code exchange failed (%s)", type(error).__name__)
        return None
    if status != 200 or not isinstance(payload, dict) or not payload.get("refresh_token"):
        _logger.warning("Apple code exchange refused (HTTP %s)", status)
        return None
    return payload
