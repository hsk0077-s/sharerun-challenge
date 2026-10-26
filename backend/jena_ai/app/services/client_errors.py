"""Errors the app could not handle, sent by the phone so they can be read in the server log.

Each report becomes one ERROR line in the Cloud Run log (kept 30 days by default).
Nothing is stored in Firestore. The account is logged as a short one-way hash, not as
the uid, and tokens or long secrets that may sit in an error message are masked.
"""

import hashlib
import logging
import re
import time

from fastapi import HTTPException

from app.services import rate_limit

logger = logging.getLogger("client_error")

_MESSAGE_MAX = 500
_STACK_MAX = 4000
_FIELD_MAX = 60

_SECRETS = (
    (re.compile(r"(?i)bearer\s+[A-Za-z0-9._~+/=-]+"), "Bearer [masked]"),
    (
        re.compile(r"(?i)((?:access_token|id_token|refresh_token|token|key|secret|code)=)[^&\s\"']+"),
        r"\1[masked]",
    ),
    # Long unbroken runs look like tokens (JWTs, API keys, purchase tokens).
    (re.compile(r"[A-Za-z0-9_\-./+=]{40,}"), "[masked]"),
)
_CONTROL = re.compile(r"[\x00-\x08\x0b-\x1f\x7f]")


def clean(text: str, limit: int) -> str:
    out = _CONTROL.sub("", text or "")
    for pattern, replacement in _SECRETS:
        out = pattern.sub(replacement, out)
    return out[:limit]


def who(uid: str) -> str:
    return hashlib.sha256(uid.encode()).hexdigest()[:12]


def record(uid: str, *, message: str, stack: str, fatal: bool, app_version: str, platform: str) -> dict:
    if not rate_limit.CLIENT_ERROR_BY_UID.allow(uid, time.monotonic()):
        raise HTTPException(status_code=429, detail="too_many_reports")
    logger.error(
        "client_error who=%s fatal=%s app=%s platform=%s message=%s stack=%s",
        who(uid),
        bool(fatal),
        clean(app_version, _FIELD_MAX),
        clean(platform, _FIELD_MAX),
        clean(message, _MESSAGE_MAX).replace("\n", " | "),
        clean(stack, _STACK_MAX).replace("\n", " | "),
    )
    return {"accepted": True}
