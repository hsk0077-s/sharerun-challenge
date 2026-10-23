"""Sign-in with Google, Kakao or Naver that ends in one Firebase account.

The phone sends a provider token. The server checks it, maps the provider user
id to one Firebase account (`authIdentities`) and hands back a Firebase custom
token. Ledger, wallet and profile stay on that uid.

A new provider identity is attached automatically only when the provider gives
a verified e-mail and exactly one live account already has that same verified
e-mail. Anything else (missing e-mail, unverified e-mail, two accounts, a
deleted or purging account, or this provider already linked on the match) does
not merge and does not create an account. The phone must ask the person, then
either sign in with the original method and link, or create an account on
purpose.

Verified e-mail rules:
- Google: the ID token e-mail is verified when `email_verified` is true.
- Kakao: `kakao_account.is_email_valid` and `is_email_verified` must both be
  true. One flag, or a missing e-mail, is not enough.
- Naver: `/v1/nid/me` has no verified flag. Naver will not finish sign-up until
  the member authenticates an e-mail, and `response.email` is that registered
  address (omitted when the person declines the e-mail scope). A non-empty
  e-mail on a `resultcode` 00 profile is therefore treated as verified. A
  missing or blank e-mail is not a match. This is weaker than Kakao's two
  flags, so absence always means "do not merge".

`authIdentities/{provider}:{providerUserId}` holds `{uid, provider, ...}`.
`authIdentityLog` is the append-only audit ledger: one row per login, link,
auto-link, refusal or unlink. Rows hold a short hash of the provider id and,
for an auto-link, a short hash of the e-mail. Never a token or a raw address.
`authVerifiedEmails/{sha256}` lists uids that have presented that verified
address, so a second account with the same address blocks a later auto-link.
"""

import hashlib
import json
import os
import urllib.error
import urllib.request
from collections import defaultdict, deque
from collections.abc import Callable
from dataclasses import dataclass

from fastapi import HTTPException
from firebase_admin import auth as firebase_auth
from google.api_core.exceptions import AlreadyExists
from google.cloud.firestore_v1 import SERVER_TIMESTAMP

IDENTITIES = "authIdentities"
LOG = "authIdentityLog"
VERIFIED_EMAILS = "authVerifiedEmails"
USERS = "users"
PROVIDERS = ("kakao", "naver", "google")
KAKAO_TOKEN_INFO_URL = "https://kapi.kakao.com/v1/user/access_token_info"
KAKAO_USER_ME_URL = "https://kapi.kakao.com/v2/user/me"
NAVER_PROFILE_URL = "https://openapi.naver.com/v1/nid/me"
_DEAD_ACCOUNT = frozenset({"deleted", "purged", "purging"})

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


class AmbiguousVerifiedEmail(Exception):
    """The lookup can see more than one account for this address."""


class _EmailLookupError(Exception):
    """The lookup failed, so a merge would be a guess."""


@dataclass(frozen=True)
class ProviderIdentity:
    user_id: str
    verified_email: str | None = None


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


def _normalize_email(value) -> str | None:
    if not isinstance(value, str):
        return None
    email = value.strip().lower()
    if "@" not in email or email.startswith("@") or email.endswith("@"):
        return None
    local, _, domain = email.partition("@")
    if not local or "." not in domain:
        return None
    return email


def _as_identity(raw) -> ProviderIdentity:
    if isinstance(raw, ProviderIdentity):
        return raw
    return ProviderIdentity(user_id=str(raw))


def _read_json(url: str, token: str) -> dict:
    request = urllib.request.Request(
        url, headers={"Authorization": f"Bearer {token}"}
    )
    try:
        with urllib.request.urlopen(request, timeout=5) as response:
            payload = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as error:
        if error.code in (400, 401, 403):
            raise HTTPException(status_code=401, detail="invalid_provider_token")
        raise HTTPException(status_code=502, detail="provider_unreachable")
    except (urllib.error.URLError, TimeoutError, ValueError):
        raise HTTPException(status_code=502, detail="provider_unreachable")
    if not isinstance(payload, dict):
        raise HTTPException(status_code=502, detail="provider_unreachable")
    return payload


def _kakao_verified_email(account) -> str | None:
    """Trust the address only when Kakao says it is both valid and verified."""
    if not isinstance(account, dict):
        return None
    if account.get("is_email_valid") is not True:
        return None
    if account.get("is_email_verified") is not True:
        return None
    return _normalize_email(account.get("email"))


def verify_kakao_token(token: str) -> ProviderIdentity:
    """Kakao user id, plus the e-mail when both verification flags are true."""
    expected = kakao_app_id()
    if not expected:
        raise HTTPException(status_code=503, detail="kakao_not_configured")
    info = _read_json(KAKAO_TOKEN_INFO_URL, token)
    app_id = info.get("app_id", info.get("appId"))
    user_id = info.get("id")
    if user_id is None:
        raise HTTPException(status_code=401, detail="invalid_provider_token")
    if str(app_id) != expected:
        raise HTTPException(status_code=401, detail="provider_token_for_other_app")

    # The token-info endpoint has no e-mail. A failure here means we do not
    # know whether the address is verified, so we must not merge. The user id
    # from the token is still enough to open an account that is already linked.
    email = None
    try:
        me = _read_json(KAKAO_USER_ME_URL, token)
        email = _kakao_verified_email(me.get("kakao_account"))
    except HTTPException:
        email = None
    return ProviderIdentity(str(user_id), email)


def verify_naver_token(token: str) -> ProviderIdentity:
    """Naver user id, plus the profile e-mail when Naver returned one.

    Unlike Kakao, Naver gives the server no way to tell which app the token was
    issued to, so only the user id is checked. Sign-up through this provider is
    a product decision made with that in mind.

    Naver does not send an e-mail-verified flag. Membership cannot be completed
    until the e-mail is authenticated, and `response.email` on a successful
    profile is that registered address. It is omitted when the person does not
    agree to the e-mail scope. A present address is treated as verified; a
    missing one is not used to merge.
    """
    info = _read_json(NAVER_PROFILE_URL, token)
    if str(info.get("resultcode")) != "00":
        raise HTTPException(status_code=401, detail="invalid_provider_token")
    profile = info.get("response") or {}
    if not isinstance(profile, dict):
        raise HTTPException(status_code=401, detail="invalid_provider_token")
    user_id = profile.get("id")
    if not user_id:
        raise HTTPException(status_code=401, detail="invalid_provider_token")
    return ProviderIdentity(str(user_id), _normalize_email(profile.get("email")))


def _google_claims(token: str, audience: str | None) -> dict:
    from google.auth.transport import requests as google_requests
    from google.oauth2 import id_token

    info = id_token.verify_oauth2_token(
        token, google_requests.Request(), audience
    )
    if not isinstance(info, dict):
        raise ValueError("not a dict")
    return info


def verify_google_id_token(token: str) -> ProviderIdentity:
    """Google subject, plus the e-mail when Google marked it verified.

    Google accounts present `email_verified: true`. An explicit false, or a
    missing address, is not a match.

    `GOOGLE_WEB_CLIENT_ID` (the same web client id the app uses) checks the
    token audience. If it is unset the signature and expiry are still checked,
    so a deploy is not blocked, but another client's token would also pass.
    """
    audience = os.getenv("GOOGLE_WEB_CLIENT_ID", "").strip()
    try:
        info = _google_claims(token, audience or None)
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=401, detail="invalid_provider_token")
    subject = info.get("sub")
    if not subject:
        raise HTTPException(status_code=401, detail="invalid_provider_token")
    email = None
    if info.get("email_verified") is True:
        email = _normalize_email(info.get("email"))
    return ProviderIdentity(str(subject), email)


VERIFIERS: dict[str, Callable[[str], ProviderIdentity]] = {
    "kakao": verify_kakao_token,
    "naver": verify_naver_token,
    "google": verify_google_id_token,
}


def _doc_id(provider: str, provider_user_id: str) -> str:
    return f"{provider}:{provider_user_id}"


def _email_doc(email: str) -> str:
    return hashlib.sha256(email.encode()).hexdigest()


def _log(
    db,
    uid: str,
    provider: str,
    provider_user_id: str,
    action: str,
    email: str | None = None,
) -> None:
    digest = hashlib.sha256(f"{provider}:{provider_user_id}".encode()).hexdigest()[:16]
    row = {
        "uid": uid,
        "provider": provider,
        "idHash": digest,
        "action": action,
        "at": SERVER_TIMESTAMP,
    }
    if email:
        row["emailHash"] = hashlib.sha256(email.encode()).hexdigest()[:16]
    db.collection(LOG).document().set(row)


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


def _profile_allows_link(db, uid: str) -> bool:
    """Deleted and purging profiles are not accounts we can join."""
    snap = db.collection(USERS).document(uid).get()
    if not snap.exists:
        return True
    status = str((snap.to_dict() or {}).get("accountStatus") or "")
    return status not in _DEAD_ACCOUNT


def _user_matches_verified_email(user, email: str) -> bool:
    if _normalize_email(getattr(user, "email", None)) != email:
        return False
    return getattr(user, "email_verified", False) is True


def _auth_users_for_email(fb_auth, email: str) -> list:
    lister = getattr(fb_auth, "list_users_by_email", None)
    if callable(lister):
        try:
            return list(lister(email))
        except AmbiguousVerifiedEmail:
            raise
        except Exception as error:
            raise _EmailLookupError(str(error)) from error
    getter = getattr(fb_auth, "get_user_by_email", None)
    if not callable(getter):
        raise _EmailLookupError("no email lookup")
    try:
        return [getter(email)]
    except AmbiguousVerifiedEmail:
        raise
    except Exception as error:
        not_found = getattr(fb_auth, "UserNotFoundError", ())
        if isinstance(error, not_found):
            return []
        raise _EmailLookupError(str(error)) from error


def _uid_matches(db, fb_auth, uid: str, email: str) -> bool:
    if not uid or not _profile_allows_link(db, uid):
        return False
    try:
        user = fb_auth.get_user(uid)
    except Exception as error:
        not_found = getattr(fb_auth, "UserNotFoundError", ())
        if isinstance(error, not_found):
            return False
        raise _EmailLookupError(str(error)) from error
    return _user_matches_verified_email(user, email)


def _verified_account_uids(db, fb_auth, email: str) -> list[str]:
    """Live uids whose Firebase e-mail is this address and is verified.

    More than one uid means the caller must not merge. Firebase's
    `get_user_by_email` returns a single user, so a lookup that can see two
    raises `AmbiguousVerifiedEmail`, and `authVerifiedEmails` plus the users
    collection add any other verified uid we already know about.
    """
    found: set[str] = set()
    try:
        auth_users = _auth_users_for_email(fb_auth, email)
    except AmbiguousVerifiedEmail:
        return ["__ambiguous_a__", "__ambiguous_b__"]
    for user in auth_users:
        uid = str(getattr(user, "uid", "") or "")
        if _user_matches_verified_email(user, email) and _profile_allows_link(db, uid):
            found.add(uid)

    snap = db.collection(VERIFIED_EMAILS).document(_email_doc(email)).get()
    if snap.exists:
        for raw in (snap.to_dict() or {}).get("uids") or []:
            uid = str(raw)
            if _uid_matches(db, fb_auth, uid, email):
                found.add(uid)

    for row in db.collection(USERS).where("email", "==", email).limit(10).get():
        if _uid_matches(db, fb_auth, str(row.id), email):
            found.add(str(row.id))
    return sorted(found)


def _login_target_alive(db, fb_auth, uid: str) -> bool:
    try:
        fb_auth.get_user(uid)
    except Exception as error:
        not_found = getattr(fb_auth, "UserNotFoundError", ())
        if isinstance(error, not_found):
            return False
        raise
    return _profile_allows_link(db, uid)


def _custom_token(fb_auth, uid: str, provider: str, created: bool) -> dict:
    try:
        custom = fb_auth.create_custom_token(uid, {"provider": provider})
    except Exception as error:
        raise HTTPException(status_code=500, detail="custom_token_unavailable") from error
    text = custom.decode("utf-8") if isinstance(custom, bytes) else str(custom)
    return {"custom_token": text, "new_account": created}


def _choice() -> dict:
    return {"needs_account_choice": True, "new_account": False}


def _stamp_verified_email(fb_auth, uid: str, email: str) -> None:
    """Record the verified address on the Firebase user when it is free.

    Later sign-in with another provider finds this account by that address.
    A different address already on the user is left alone.
    """
    try:
        user = fb_auth.get_user(uid)
    except Exception:
        return
    current = _normalize_email(getattr(user, "email", None))
    if current == email and getattr(user, "email_verified", False) is True:
        return
    if current and current != email:
        return
    updater = getattr(fb_auth, "update_user", None)
    if not callable(updater):
        return
    try:
        updater(uid, email=email, email_verified=True)
    except Exception:
        return


def _remember_verified_email(db, uid: str, email: str) -> None:
    ref = db.collection(VERIFIED_EMAILS).document(_email_doc(email))
    snap = ref.get()
    uids = []
    if snap.exists:
        uids = [str(item) for item in ((snap.to_dict() or {}).get("uids") or [])]
    if uid not in uids:
        uids.append(uid)
    ref.set({"uids": uids}, merge=True)


def _identity_row(uid: str, provider: str, *, linked_by: str | None = None) -> dict:
    row = {
        "uid": uid,
        "provider": provider,
        "linkedAt": SERVER_TIMESTAMP,
        "lastLoginAt": SERVER_TIMESTAMP,
    }
    if linked_by:
        row["linkedBy"] = linked_by
    return row


def _open_existing(db, fb_auth, ref, uid: str, provider: str, provider_user_id: str) -> dict:
    ref.set({"lastLoginAt": SERVER_TIMESTAMP}, merge=True)
    _log(db, uid, provider, provider_user_id, "login")
    return _custom_token(fb_auth, uid, provider, False)


def _auto_link(
    db,
    fb_auth,
    ref,
    provider: str,
    provider_user_id: str,
    target: str,
    email: str,
) -> dict:
    try:
        ref.create(_identity_row(target, provider, linked_by="verified_email"))
    except AlreadyExists:
        uid = str((ref.get().to_dict() or {}).get("uid") or "")
        if uid and _login_target_alive(db, fb_auth, uid):
            return _open_existing(db, fb_auth, ref, uid, provider, provider_user_id)
        raise HTTPException(status_code=409, detail="try_again")
    _stamp_verified_email(fb_auth, target, email)
    _remember_verified_email(db, target, email)
    _log(db, target, provider, provider_user_id, "auto_link", email=email)
    return _custom_token(fb_auth, target, provider, False)


def login(
    db,
    provider: str,
    token: str,
    *,
    verify: Callable[[str], ProviderIdentity | str] | None = None,
    fb_auth=firebase_auth,
    create_account: bool = False,
) -> dict:
    """Returns a custom token for the one account, or asks the phone to choose.

    `create_account` is the explicit "새 계정 만들기" path. It is ignored when
    one safe verified-e-mail match exists: that match is linked instead, so a
    second account is not created for the same person.
    """
    _check_provider(provider)
    identity = _as_identity((verify or VERIFIERS[provider])(token))
    provider_user_id = identity.user_id.strip()
    if not provider_user_id:
        raise HTTPException(status_code=401, detail="invalid_provider_token")
    email = _normalize_email(identity.verified_email)
    ref = db.collection(IDENTITIES).document(_doc_id(provider, provider_user_id))

    snap = ref.get()
    if snap.exists:
        uid = str((snap.to_dict() or {}).get("uid") or "")
        # Already linked, including linked to someone else: that uid wins.
        # Do not move the identity onto an e-mail match.
        if uid and _login_target_alive(db, fb_auth, uid):
            return _open_existing(db, fb_auth, ref, uid, provider, provider_user_id)
        ref.delete()

    if email:
        try:
            matches = _verified_account_uids(db, fb_auth, email)
        except _EmailLookupError as error:
            raise HTTPException(
                status_code=503, detail="email_lookup_unavailable"
            ) from error
        if len(matches) == 1:
            target = matches[0]
            # This account already has a different identity for the provider.
            # Linking would drop that one, so ask the person instead.
            if _mapping_for(db, target, provider) is None:
                return _auto_link(
                    db, fb_auth, ref, provider, provider_user_id, target, email
                )

    if not create_account:
        return _choice()

    created_user = _create_firebase_user(fb_auth, email)
    uid = created_user.uid
    try:
        ref.create(_identity_row(uid, provider))
        created = True
    except AlreadyExists:
        fb_auth.delete_user(uid)
        uid = str((ref.get().to_dict() or {}).get("uid") or "")
        if not uid:
            raise HTTPException(status_code=409, detail="try_again")
        created = False
    if created and email:
        _stamp_verified_email(fb_auth, uid, email)
        _remember_verified_email(db, uid, email)
    _log(db, uid, provider, provider_user_id, "login_new" if created else "login")
    return _custom_token(fb_auth, uid, provider, created)


def _create_firebase_user(fb_auth, email: str | None):
    if not email:
        return fb_auth.create_user()
    try:
        return fb_auth.create_user(email=email, email_verified=True)
    except Exception:
        # The address is already taken and there was no single safe match
        # (the caller decided to create anyway). Keep the new account, without
        # claiming an address that belongs to more than one person.
        return fb_auth.create_user()


def link(
    db,
    uid: str,
    provider: str,
    token: str,
    *,
    verify: Callable[[str], ProviderIdentity | str] | None = None,
) -> dict:
    """Attaches this provider identity to the signed-in account."""
    _check_provider(provider)
    provider_user_id = _as_identity((verify or VERIFIERS[provider])(token)).user_id.strip()
    if not provider_user_id:
        raise HTTPException(status_code=401, detail="invalid_provider_token")
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
        ref.create(_identity_row(uid, provider))
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
