"""Device and app integrity checks (Play Integrity on Android).

Record-only for now: the server decodes the verdict, keeps it, and never
blocks anyone. After one or two weeks of data the team decides what to block.

`integrityChallenges/{uid}` holds one pending single-use nonce (5 minutes).
`integrityChecks/{uid}` holds the latest verdict.
`integrityLog` is append-only: one row per check, never edited.
The platform is stored on every row so an iOS check can use the same tables.
"""

import secrets
from datetime import datetime, timedelta, timezone
from typing import Callable

from fastapi import HTTPException
from google.cloud.firestore_v1 import SERVER_TIMESTAMP

PACKAGE_NAME = "com.sharerun.share_run_challenge"
NONCE_TTL = timedelta(minutes=5)
TOKEN_MAX_AGE = timedelta(minutes=10)
MAX_TOKEN_CHARS = 20_000
CHALLENGES = "integrityChallenges"
CHECKS = "integrityChecks"
LOG = "integrityLog"


def issue_nonce(db, uid: str, now: datetime | None = None) -> str:
    now = now or datetime.now(timezone.utc)
    nonce = secrets.token_urlsafe(32).rstrip("=")
    db.collection(CHALLENGES).document(uid).set(
        {"uid": uid, "nonce": nonce, "expiresAt": now + NONCE_TTL}
    )
    return nonce


def decode_with_google(token: str) -> dict:
    """Ask Google to decode the token. Uses the service's own credentials."""
    import google.auth
    from google.auth.transport.requests import AuthorizedSession

    credentials, _ = google.auth.default(
        scopes=["https://www.googleapis.com/auth/playintegrity"]
    )
    response = AuthorizedSession(credentials).post(
        f"https://playintegrity.googleapis.com/v1/{PACKAGE_NAME}:decodeIntegrityToken",
        json={"integrity_token": token},
        timeout=10,
    )
    if response.status_code != 200:
        raise RuntimeError(f"decode_http_{response.status_code}")
    return response.json().get("tokenPayloadExternal") or {}


def _list(value: object) -> list[str]:
    if isinstance(value, list):
        return [str(item)[:60] for item in value[:10]]
    return []


def summarize(payload: dict) -> dict:
    """Only the verdict fields. No device identifiers are kept."""
    return {
        "device": _list(
            (payload.get("deviceIntegrity") or {}).get("deviceRecognitionVerdict")
        ),
        "app": str(
            (payload.get("appIntegrity") or {}).get("appRecognitionVerdict") or ""
        )[:60],
        "licensing": str(
            (payload.get("accountDetails") or {}).get("appLicensingVerdict") or ""
        )[:60],
    }


def _problem(payload: dict, nonce: str, now: datetime) -> str:
    details = payload.get("requestDetails") or {}
    if details.get("requestPackageName") != PACKAGE_NAME:
        return "package_mismatch"
    if details.get("nonce") != nonce:
        return "nonce_mismatch"
    try:
        issued = datetime.fromtimestamp(
            int(details.get("timestampMillis")) / 1000, tz=timezone.utc
        )
    except (TypeError, ValueError):
        return "no_timestamp"
    if now - issued > TOKEN_MAX_AGE:
        return "token_too_old"
    return ""


def record_check(
    db,
    uid: str,
    token: str,
    *,
    decode: Callable[[str], dict] = decode_with_google,
    now: datetime | None = None,
) -> dict:
    """Records one check. A bad or unreadable verdict is recorded, not refused."""
    now = now or datetime.now(timezone.utc)
    if not token or len(token) > MAX_TOKEN_CHARS:
        raise HTTPException(status_code=400, detail="invalid_integrity_token")

    ref = db.collection(CHALLENGES).document(uid)
    snap = ref.get()
    pending = snap.to_dict() if snap.exists else None
    expires = (pending or {}).get("expiresAt")
    if not pending or not isinstance(expires, datetime) or now > (
        expires if expires.tzinfo else expires.replace(tzinfo=timezone.utc)
    ):
        raise HTTPException(status_code=400, detail="integrity_challenge_expired")
    ref.delete()  # single use

    row: dict = {"uid": uid, "platform": "android", "checkedAt": SERVER_TIMESTAMP}
    try:
        payload = decode(token)
        problem = _problem(payload, str(pending.get("nonce") or ""), now)
        row.update(summarize(payload) if not problem else {"problem": problem})
    except Exception as error:  # record the failure; never block the app
        row["problem"] = f"decode_failed:{str(error)[:60]}"

    db.collection(CHECKS).document(uid).set(row)
    db.collection(LOG).document().set(row)
    return {"recorded": "problem" not in row}
