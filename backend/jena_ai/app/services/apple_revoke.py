"""Sign in with Apple token revocation. PREPARED, NOT WIRED, NOT DEPLOYED.

Apple's account-deletion guidance (App Review Guideline 5.1.1(v) reference page):
"Apps that support Sign in with Apple should use the Sign in with Apple REST API to
revoke user tokens." and "Use server-to-server notification endpoints to process
changes for Sign in with Apple accounts."

Why this is not called from `delete_account` yet (see docs/ios-readiness.md, section 3):
- The app sends only Apple's identity token at sign-in (`obtainAppleIdToken`), so the
  server never holds a refresh/access token that could be revoked. Getting one means
  the app also sending the one-time authorization code and the server exchanging it
  with Apple, then storing the result. That is a product and privacy decision (the
  guideline also says an app "may not store credentials or tokens to social networks
  off of the device"), so it is left to the owner.
- It needs credentials only Apple can issue (Services/bundle id, Team ID, Key ID and a
  private key). Nothing here reads or stores them anywhere except the process
  environment, and nothing logs them.

What it does when the pieces exist: build the short-lived `client_secret` (an ES256 JWT
signed with the Apple key) and post the revoke request. The request shape below (URL,
parameter names, JWT claims) is written from memory of Apple's REST API documentation:
**the official pages' body text could not be read when this was written (the 5.1.1(v)
guideline reference page could), so these must be checked against Apple's current
"Revoke tokens" and "Generate and validate tokens" pages before this is ever switched on.**
"""

from __future__ import annotations

import logging
import os
import time
import urllib.parse
import urllib.request
from collections.abc import Callable, Mapping

_logger = logging.getLogger(__name__)

APPLE_AUDIENCE = "https://appleid.apple.com"
# UNCONFIRMED against Apple's page text. Verify before use.
APPLE_REVOKE_URL = "https://appleid.apple.com/auth/revoke"
REQUIRED_SETTINGS = ("APPLE_CLIENT_ID", "APPLE_TEAM_ID", "APPLE_KEY_ID", "APPLE_PRIVATE_KEY")
CLIENT_SECRET_LIFETIME_SECONDS = 300

Post = Callable[[str, Mapping[str, str], float], int]


def is_configured(environ: Mapping[str, str] | None = None) -> bool:
    env = os.environ if environ is None else environ
    return all(str(env.get(name, "")).strip() for name in REQUIRED_SETTINGS)


def build_client_secret(environ: Mapping[str, str] | None = None, now: float | None = None) -> str:
    """Short-lived ES256 JWT that proves the server owns the Apple key."""
    import jwt

    env = os.environ if environ is None else environ
    if not is_configured(env):
        raise RuntimeError("apple_revoke_not_configured")
    issued = int(time.time() if now is None else now)
    private_key = str(env["APPLE_PRIVATE_KEY"]).replace("\\n", "\n")
    return jwt.encode(
        {
            "iss": str(env["APPLE_TEAM_ID"]).strip(),
            "iat": issued,
            "exp": issued + CLIENT_SECRET_LIFETIME_SECONDS,
            "aud": APPLE_AUDIENCE,
            "sub": str(env["APPLE_CLIENT_ID"]).strip(),
        },
        private_key,
        algorithm="ES256",
        headers={"kid": str(env["APPLE_KEY_ID"]).strip()},
    )


def _default_post(url: str, data: Mapping[str, str], timeout: float) -> int:
    body = urllib.parse.urlencode(dict(data)).encode()
    request = urllib.request.Request(
        url,
        data=body,
        method="POST",
        headers={"Content-Type": "application/x-www-form-urlencoded"},
    )
    with urllib.request.urlopen(request, timeout=timeout) as response:  # noqa: S310
        return int(response.status)


def revoke_token(
    token: str,
    *,
    token_type_hint: str = "refresh_token",
    environ: Mapping[str, str] | None = None,
    post: Post | None = None,
    now: float | None = None,
    timeout: float = 8.0,
) -> bool:
    """True when Apple accepted the revoke request (HTTP 200). Never raises, never
    logs the token, the client secret or the key. Returns False when not configured."""
    env = os.environ if environ is None else environ
    if not token or not is_configured(env):
        return False
    try:
        secret = build_client_secret(env, now)
        status = (post or _default_post)(
            APPLE_REVOKE_URL,
            {
                "client_id": str(env["APPLE_CLIENT_ID"]).strip(),
                "client_secret": secret,
                "token": token,
                "token_type_hint": token_type_hint,
            },
            timeout,
        )
    except Exception as error:  # network, key format, anything
        _logger.warning("Apple token revoke failed (%s)", type(error).__name__)
        return False
    if status != 200:
        _logger.warning("Apple token revoke refused (HTTP %s)", status)
        return False
    return True
