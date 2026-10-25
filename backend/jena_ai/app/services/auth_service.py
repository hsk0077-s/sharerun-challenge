import time

from fastapi import Header, HTTPException, Request, status
from firebase_admin import auth

from app.services.firebase_service import FirebaseService


# A watch signs in with a custom token that carries `provider: "watch"`. The watch only
# uploads runs and step totals, so that token is accepted on those two routes and nowhere
# else. A lost or copied watch then cannot spend currency, change the profile or delete
# the account.
WATCH_PROVIDER = "watch"
WATCH_ALLOWED_PATHS = frozenset({"/actions/runs/validate", "/actions/daily-steps"})

_CHECK_SECONDS = 30.0
_valid_after: dict[str, tuple[float, int]] = {}
_watch_generation: dict[str, tuple[float, int]] = {}


def forget_watch_generation(uid: str) -> None:
    _watch_generation.pop(uid, None)


def _current_watch_generation(uid: str) -> int:
    """Bumped by "disconnect all watches". Cached briefly, like the sign-out check."""
    now = time.monotonic()
    cached = _watch_generation.get(uid)
    if cached and now - cached[0] < _CHECK_SECONDS:
        return cached[1]
    snap = FirebaseService().db.collection("users").document(uid).get()
    data = (snap.to_dict() or {}) if snap.exists else {}
    raw = data.get("watchGeneration")
    value = raw if isinstance(raw, int) and not isinstance(raw, bool) else 0
    _watch_generation[uid] = (now, value)
    return value


def forget_sign_out_cache(uid: str) -> None:
    _valid_after.pop(uid, None)


def _tokens_valid_after(uid: str) -> int:
    """Seconds; tokens issued before this were signed out. Cached briefly."""
    now = time.monotonic()
    cached = _valid_after.get(uid)
    if cached and now - cached[0] < _CHECK_SECONDS:
        return cached[1]
    # firebase_admin returns milliseconds; token `iat` is in seconds.
    value = int(auth.get_user(uid).tokens_valid_after_timestamp or 0) // 1000
    _valid_after[uid] = (now, value)
    return value


class AuthService:
    def verify_bearer_decoded(self, authorization: str | None, path: str | None = None) -> dict:
        if not authorization or not authorization.startswith("Bearer "):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Missing Firebase ID token.",
            )

        token = authorization.removeprefix("Bearer ").strip()
        try:
            FirebaseService()
            decoded = auth.verify_id_token(token)
        except Exception as error:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid Firebase ID token.",
            ) from error

        uid = decoded.get("uid")
        if not uid:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Firebase token did not include uid.",
            )

        if decoded.get("provider") == WATCH_PROVIDER:
            if path not in WATCH_ALLOWED_PATHS:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="watch_scope",
                )
            # "Disconnect all watches" raises the account's generation, so every
            # watch signed in before it stops working without signing the phone out.
            claimed = decoded.get("wgen")
            claimed = claimed if isinstance(claimed, int) and not isinstance(claimed, bool) else 0
            try:
                current = _current_watch_generation(uid)
            except Exception:
                current = claimed
            if claimed != current:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="watch_revoked",
                )

        # A sign-out on all devices must stop the server from accepting tokens
        # issued before it. If the check itself fails, the request is allowed.
        try:
            signed_out = int(decoded.get("iat") or 0) < _tokens_valid_after(uid)
        except Exception:
            signed_out = False
        if signed_out:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Signed out.",
            )

        return decoded

    def verify_bearer_token(self, authorization: str | None, path: str | None = None) -> str:
        return str(self.verify_bearer_decoded(authorization, path)["uid"])


auth_service = AuthService()


def require_uid(request: Request, authorization: str | None = Header(default=None)) -> str:
    decoded = auth_service.verify_bearer_decoded(authorization, request.url.path)
    # Run checks that only apply to a watch read this.
    request.state.is_watch = decoded.get("provider") == WATCH_PROVIDER
    return str(decoded["uid"])
