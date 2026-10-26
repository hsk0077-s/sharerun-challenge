"""Pair a Wear OS watch with an account using a 6-digit code.

A watch has no keyboard worth using, so the signed-in phone asks for a code
and the person types it on the watch. The code lives five minutes, works once,
and is stored as `watchPairingCodes/{code}` with `{uid, expiresAt, used}`. The
watch trades it for a Firebase custom token and signs in as the same uid, so
run validation and daily steps go through the normal bearer-token routes.

Only the server reads or writes these documents (`firestore.rules` denies all
client access). Codes are short, so the pair call is rate limited per client.
"""

import secrets
from datetime import datetime, timedelta, timezone

from fastapi import HTTPException
from firebase_admin import auth as firebase_auth
from google.cloud import firestore
from google.cloud.firestore_v1 import SERVER_TIMESTAMP

from app.services import identities

COLLECTION = "watchPairingCodes"
CODE_LENGTH = 6
CODE_TTL_SECONDS = 300
_ISSUE_TRIES = 8


def _run(tx_func, transaction, *args):
    """Run a transactional function. Tests swap this for the plain wrapped function."""
    return tx_func(transaction, *args)


def _new_code() -> str:
    return f"{secrets.randbelow(10**CODE_LENGTH):0{CODE_LENGTH}d}"


def _as_utc(value) -> datetime | None:
    if not isinstance(value, datetime):
        return None
    return value if value.tzinfo else value.replace(tzinfo=timezone.utc)


def _is_live(row: dict | None, now: datetime) -> bool:
    if not isinstance(row, dict) or row.get("used") is not False:
        return False
    expires = _as_utc(row.get("expiresAt"))
    return expires is not None and expires > now


@firestore.transactional
def _issue_tx(transaction, ref, uid: str, now: datetime) -> bool:
    snap = ref.get(transaction=transaction)
    if snap.exists and _is_live(snap.to_dict(), now):
        return False  # another person holds this code right now
    transaction.set(
        ref,
        {
            "uid": uid,
            "expiresAt": now + timedelta(seconds=CODE_TTL_SECONDS),
            "used": False,
            "createdAt": SERVER_TIMESTAMP,
        },
    )
    return True


@firestore.transactional
def _consume_tx(transaction, ref, now: datetime) -> str | None:
    snap = ref.get(transaction=transaction)
    row = snap.to_dict() if snap.exists else None
    if not _is_live(row, now):
        return None
    transaction.update(ref, {"used": True, "usedAt": SERVER_TIMESTAMP})
    return str(row.get("uid") or "") or None


def issue_code(db, uid: str, *, now: datetime | None = None) -> dict:
    now = now or datetime.now(timezone.utc)
    for _ in range(_ISSUE_TRIES):
        code = _new_code()
        ref = db.collection(COLLECTION).document(code)
        if _run(_issue_tx, db.transaction(), ref, uid, now):
            return {"code": code, "expires_in": CODE_TTL_SECONDS}
    raise HTTPException(status_code=503, detail="try_again")


def _generation(db, uid: str) -> int:
    snap = db.collection("users").document(uid).get()
    raw = (snap.to_dict() or {}).get("watchGeneration") if snap.exists else 0
    return raw if isinstance(raw, int) and not isinstance(raw, bool) else 0


def revoke_all(db, uid: str) -> dict:
    """Disconnect every watch of this account. The phone stays signed in.

    A watch's sign-in token carries the generation it was issued under. Raising the
    account's generation makes the server refuse all of them (`watch_revoked`).
    """
    from app.services import auth_service

    ref = db.collection("users").document(uid)
    nxt = _generation(db, uid) + 1
    ref.set({"watchGeneration": nxt}, merge=True)
    auth_service.forget_watch_generation(uid)
    return {"revoked": True, "generation": nxt}


def pair(db, code: str, *, fb_auth=firebase_auth, now: datetime | None = None) -> dict:
    now = now or datetime.now(timezone.utc)
    code = (code or "").strip()
    if len(code) != CODE_LENGTH or not code.isdigit():
        raise HTTPException(status_code=400, detail="invalid_code")
    ref = db.collection(COLLECTION).document(code)
    uid = _run(_consume_tx, db.transaction(), ref, now)
    if not uid:
        raise HTTPException(status_code=400, detail="invalid_code")
    try:
        alive = identities._login_target_alive(db, fb_auth, uid)
    except Exception as error:
        raise HTTPException(status_code=503, detail="try_again") from error
    if not alive:
        raise HTTPException(status_code=400, detail="invalid_code")
    claims = {"provider": "watch", "wgen": _generation(db, uid)}
    try:
        custom = fb_auth.create_custom_token(uid, claims)
    except Exception as error:
        raise HTTPException(status_code=500, detail="custom_token_unavailable") from error
    token = custom.decode("utf-8") if isinstance(custom, bytes) else str(custom)
    nickname = identities._nickname(identities._user_profile(db, uid))
    return {"uid": uid, "nickname": nickname, "custom_token": token}
