"""Revoke a person's Sign in with Apple grant when they delete their account.

Apple asks apps that offer Sign in with Apple to revoke the user's tokens when
the account is deleted. Nothing about Apple is stored: when an iPhone user
whose account has Apple linked deletes the account, the app asks Apple for a
fresh one-time `authorization_code` and sends it with the delete request. Here
the code is exchanged for a token and that token is revoked straight away.

Configuration (all server-side, never in the app):
    APPLE_TEAM_ID       Apple developer team id (10 characters)
    APPLE_KEY_ID        id of the "Sign in with Apple" key (10 characters)
    APPLE_PRIVATE_KEY   contents of that key's .p8 file (PEM; "\\n" escapes ok)
    APPLE_CLIENT_ID     the app's bundle id (also used to check token audience)

If any value is missing, or Apple is unreachable, the account is still deleted;
the result says why the revoke was skipped. Secrets are never logged.
"""

from __future__ import annotations

import json
import logging
import os
import time
import urllib.error
import urllib.parse
import urllib.request
from collections.abc import Callable

APPLE_AUDIENCE = "https://appleid.apple.com"
TOKEN_URL = "https://appleid.apple.com/auth/token"
REVOKE_URL = "https://appleid.apple.com/auth/revoke"
CLIENT_SECRET_SECONDS = 300

_log = logging.getLogger(__name__)

Post = Callable[[str, dict[str, str]], tuple[int, dict]]


def _config() -> dict[str, str] | None:
    values = {
        "team_id": os.getenv("APPLE_TEAM_ID", "").strip(),
        "key_id": os.getenv("APPLE_KEY_ID", "").strip(),
        "private_key": os.getenv("APPLE_PRIVATE_KEY", "").replace("\\n", "\n").strip(),
        "client_id": os.getenv("APPLE_CLIENT_ID", "").strip(),
    }
    return values if all(values.values()) else None


def client_secret(config: dict[str, str], now: float | None = None) -> str:
    """Short-lived ES256 JWT Apple accepts as the client secret."""
    import jwt

    issued = int(now if now is not None else time.time())
    return jwt.encode(
        {
            "iss": config["team_id"],
            "iat": issued,
            "exp": issued + CLIENT_SECRET_SECONDS,
            "aud": APPLE_AUDIENCE,
            "sub": config["client_id"],
        },
        config["private_key"],
        algorithm="ES256",
        headers={"kid": config["key_id"]},
    )


def _post(url: str, form: dict[str, str]) -> tuple[int, dict]:
    request = urllib.request.Request(
        url,
        data=urllib.parse.urlencode(form).encode(),
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=8) as response:
            body = response.read()
            status = response.status
    except urllib.error.HTTPError as error:
        body = error.read()
        status = error.code
    try:
        parsed = json.loads(body) if body else {}
    except ValueError:
        parsed = {}
    return status, parsed if isinstance(parsed, dict) else {}


def revoke_with_code(
    authorization_code: str | None,
    *,
    post: Post = _post,
    config: dict[str, str] | None = None,
    now: float | None = None,
) -> str:
    """Exchange the one-time code and revoke the token. Never raises.

    Returns one of: "revoked", "no_code", "not_configured", "exchange_failed",
    "revoke_failed".
    """
    code = (authorization_code or "").strip()
    if not code:
        return "no_code"
    settings = config if config is not None else _config()
    if settings is None:
        _log.warning("Apple revoke skipped: Sign in with Apple key is not configured.")
        return "not_configured"
    try:
        secret = client_secret(settings, now)
        status, token = post(
            TOKEN_URL,
            {
                "client_id": settings["client_id"],
                "client_secret": secret,
                "code": code,
                "grant_type": "authorization_code",
            },
        )
        refresh = token.get("refresh_token")
        access = token.get("access_token")
        if status != 200 or not (refresh or access):
            _log.warning("Apple revoke: code exchange failed (HTTP %s, %s).", status, token.get("error"))
            return "exchange_failed"
        status, _ = post(
            REVOKE_URL,
            {
                "client_id": settings["client_id"],
                "client_secret": secret,
                "token": str(refresh or access),
                "token_type_hint": "refresh_token" if refresh else "access_token",
            },
        )
        if status != 200:
            _log.warning("Apple revoke: revoke call failed (HTTP %s).", status)
            return "revoke_failed"
        return "revoked"
    except Exception:  # noqa: BLE001 - deletion must not fail because of Apple
        _log.exception("Apple revoke failed unexpectedly.")
        return "revoke_failed"
