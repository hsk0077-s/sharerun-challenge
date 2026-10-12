"""Sign-in with Kakao or Naver that ends in a normal Firebase account.

The phone sends the Kakao access token. The server asks Kakao whether it is
valid and was issued to this app, then maps the Kakao user id to one Firebase
account (`authIdentities`) and hands back a Firebase custom token. So Google,
Kakao and later providers all give the same kind of account, and one person
can reach one account through several providers.

`authIdentities/{provider}:{providerUserId}` holds `{uid, provider, ...}`.
`authIdentityLog` is append-only: one row per login, link, refusal or unlink.
Rows hold a short hash of the provider id, never a token.

No automatic merge by e-mail: Kakao e-mails can be unverified. A provider is
attached to an account only by that signed-in account asking for it.
"""

import hashlib
import json
import os
import urllib.error
import urllib.request
from collections import defaultdict, deque
from datetime import datetime, timezone
from typing import Callable

from fastapi import HTTPException
from firebase_admin import auth as firebase_auth
from google.api_core.exceptions import AlreadyExists
from google.cloud.firestore_v1 import SERVER_TIMESTAMP

IDENTITIES = "authIdentities"
LOG = "authIdentityLog"
PROVIDERS = ("kakao", "naver")
KAKAO_TOKEN_INFO_URL = "https://kapi.kakao.com/v1/user/access_token_info"
NAVER_PROFILE_URL = "https://openapi.naver.com/v1/nid/me"

_FIREBASE_PROVIDER_NAMES = {
    "google.com": "google",
    "apple.com": "apple",
    "password": "email",
}

# Per server instance, in memory. It slows a script that guesses tokens; it is
# not a promise, and a restart clears it.
_LOGIN_WINDOW_SECONDS = 600
_LOGIN_MAX_ATTEMPTS = 30
_attempts: dict[str, deque] = defaultdict(deque)


def allow_login_attempt(client: str, now: float) -> bool:
    queue = _attempts[client or "unknown"]
    while queue and now - queue[0] > _LOGIN_WINDOW_SECONDS:
        queue.popleft()
    if len(queue) >= _LOGIN_MAX_ATTEMPTS:
        return False
    queue.append(now)
    return True


def kakao_app_id() -> str:
    return os.getenv("KAKAO_APP_ID", "").strip()


def verify_kakao_token(token: str) -> str:
    """Returns the Kakao user id if the token is valid and made for this app."""
    expected = kakao_app_id()
    if not expected:
        raise HTTPException(status_code=503, detail="kakao_not_configured")
    request = urllib.request.Request(
        KAKAO_TOKEN_INFO_URL, headers={"Authorization": f"Bearer {token}"}
    )
    try:
        with urllib.request.urlopen(request, timeout=5) as response:
            info = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as error:
        if error.code in (400, 401):
            raise HTTPException(status_code=401, detail="invalid_provider_token")
        raise HTTPException(status_code=502, detail="provider_unreachable")
    except (urllib.error.URLError, TimeoutError, ValueError):
        raise HTTPException(status_code=502, detail="provider_unreachable")

    app_id = info.get("app_id", info.get("appId"))
    user_id = info.get("id")
    if user_id is None:
        raise HTTPException(status_code=401, detail="invalid_provider_token")
    if str(app_id) != expected:
        raise HTTPException(status_code=401, detail="provider_token_for_other_app")
    return str(user_id)


def verify_naver_token(token: str) -> str:
    """Returns the Naver user id if the token is valid.

    Unlike Kakao, Naver gives the server no way to tell which app the token was
    issued to, so only the user id is checked. Sign-up through this provider is
    a product decision made with that in mind.
    """
    request = urllib.request.Request(
        NAVER_PROFILE_URL, headers={"Authorization": f"Bearer {token}"}
    )
    try:
        with urllib.request.urlopen(request, timeout=5) as response:
            info = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as error:
        if error.code in (400, 401, 403):
            raise HTTPException(status_code=401, detail="invalid_provider_token")
        raise HTTPException(status_code=502, detail="provider_unreachable")
    except (urllib.error.URLError, TimeoutError, ValueError):
        raise HTTPException(status_code=502, detail="provider_unreachable")

    if str(info.get("resultcode")) != "00":
        raise HTTPException(status_code=401, detail="invalid_provider_token")
    user_id = (info.get("response") or {}).get("id")
    if not user_id:
        raise HTTPException(status_code=401, detail="invalid_provider_token")
    return str(user_id)


VERIFIERS: dict[str, Callable[[str], str]] = {
    "kakao": verify_kakao_token,
    "naver": verify_naver_token,
}


def _doc_id(provider: str, provider_user_id: str) -> str:
    return f"{provider}:{provider_user_id}"


def _log(db, uid: str, provider: str, provider_user_id: str, action: str) -> None:
    digest = hashlib.sha256(f"{provider}:{provider_user_id}".encode()).hexdigest()[:16]
    db.collection(LOG).document().set(
        {
            "uid": uid,
            "provider": provider,
            "idHash": digest,
            "action": action,
            "at": SERVER_TIMESTAMP,
        }
    )


def _check_provider(provider: str) -> None:
    if provider not in PROVIDERS:
        raise HTTPException(status_code=400, detail="unknown_provider")


def _mapping_for(db, uid: str, provider: str):
    rows = (
        db.collection(IDENTITIES)
        .where("uid", "==", uid)
        .where("provider", "==", provider)
        .limit(1)
        .get()
    )
    return rows[0] if rows else None


def login(
    db,
    provider: str,
    token: str,
    *,
    verify: Callable[[str], str] | None = None,
    fb_auth=firebase_auth,
) -> dict:
    """Finds or creates the account for this provider identity, gives a custom token."""
    _check_provider(provider)
    provider_user_id = (verify or VERIFIERS[provider])(token)
    ref = db.collection(IDENTITIES).document(_doc_id(provider, provider_user_id))

    uid, created = "", False
    snap = ref.get()
    if snap.exists:
        uid = str((snap.to_dict() or {}).get("uid") or "")
        try:
            fb_auth.get_user(uid)
        except fb_auth.UserNotFoundError:
            ref.delete()  # the account was deleted; start a fresh one
            uid = ""
    if not uid:
        uid = fb_auth.create_user().uid
        try:
            ref.create(
                {
                    "uid": uid,
                    "provider": provider,
                    "linkedAt": SERVER_TIMESTAMP,
                    "lastLoginAt": SERVER_TIMESTAMP,
                }
            )
            created = True
        except AlreadyExists:
            # Two first logins at once: keep the winner, drop our extra user.
            fb_auth.delete_user(uid)
            uid = str((ref.get().to_dict() or {}).get("uid") or "")
            if not uid:
                raise HTTPException(status_code=409, detail="try_again")
    else:
        ref.set({"lastLoginAt": SERVER_TIMESTAMP}, merge=True)

    try:
        custom = fb_auth.create_custom_token(uid, {"provider": provider})
    except Exception as error:
        raise HTTPException(status_code=500, detail="custom_token_unavailable") from error
    _log(db, uid, provider, provider_user_id, "login_new" if created else "login")
    text = custom.decode("utf-8") if isinstance(custom, bytes) else str(custom)
    return {"custom_token": text, "new_account": created}


def link(
    db,
    uid: str,
    provider: str,
    token: str,
    *,
    verify: Callable[[str], str] | None = None,
) -> dict:
    """Attaches this provider identity to the signed-in account."""
    _check_provider(provider)
    provider_user_id = (verify or VERIFIERS[provider])(token)
    ref = db.collection(IDENTITIES).document(_doc_id(provider, provider_user_id))

    def owner() -> str:
        snap = ref.get()
        return str((snap.to_dict() or {}).get("uid") or "") if snap.exists else ""

    current = owner()
    if current == uid:
        return {"linked": True, "already": True}
    if current:
        _log(db, uid, provider, provider_user_id, "link_refused")
        raise HTTPException(status_code=409, detail="identity_belongs_to_another_account")
    if _mapping_for(db, uid, provider) is not None:
        _log(db, uid, provider, provider_user_id, "link_refused")
        raise HTTPException(status_code=409, detail="provider_already_linked")
    try:
        ref.create(
            {
                "uid": uid,
                "provider": provider,
                "linkedAt": SERVER_TIMESTAMP,
                "lastLoginAt": SERVER_TIMESTAMP,
            }
        )
    except AlreadyExists:
        if owner() == uid:
            return {"linked": True, "already": True}
        _log(db, uid, provider, provider_user_id, "link_refused")
        raise HTTPException(status_code=409, detail="identity_belongs_to_another_account")
    _log(db, uid, provider, provider_user_id, "link")
    return {"linked": True, "already": False}


def _other_methods(db, uid: str, provider: str, fb_auth) -> int:
    count = len(fb_auth.get_user(uid).provider_data or [])
    for other in PROVIDERS:
        if other != provider and _mapping_for(db, uid, other) is not None:
            count += 1
    return count


def unlink(db, uid: str, provider: str, *, fb_auth=firebase_auth) -> dict:
    """Detaches a provider. The last way to sign in cannot be removed."""
    _check_provider(provider)
    row = _mapping_for(db, uid, provider)
    if row is None:
        raise HTTPException(status_code=404, detail="not_linked")
    if _other_methods(db, uid, provider, fb_auth) < 1:
        raise HTTPException(status_code=409, detail="last_login_method")
    provider_user_id = row.id.split(":", 1)[1] if ":" in row.id else ""
    row.reference.delete()
    _log(db, uid, provider, provider_user_id, "unlink")
    return {"unlinked": True}


def list_providers(db, uid: str, *, fb_auth=firebase_auth) -> dict:
    names: list[str] = []
    for info in fb_auth.get_user(uid).provider_data or []:
        name = _FIREBASE_PROVIDER_NAMES.get(info.provider_id)
        if name and name not in names:
            names.append(name)
    for provider in PROVIDERS:
        if _mapping_for(db, uid, provider) is not None and provider not in names:
            names.append(provider)
    return {"providers": names}


def forget_account(db, uid: str) -> None:
    """Called when an account is deleted, so the provider id can sign up again."""
    for row in db.collection(IDENTITIES).where("uid", "==", uid).get():
        row.reference.delete()
