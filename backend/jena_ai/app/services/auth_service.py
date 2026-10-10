import time

from fastapi import Header, HTTPException, status
from firebase_admin import auth

from app.services.firebase_service import FirebaseService


_CHECK_SECONDS = 30.0
_valid_after: dict[str, tuple[float, int]] = {}


def forget_sign_out_cache(uid: str) -> None:
    _valid_after.pop(uid, None)


def _tokens_valid_after(uid: str) -> int:
    """Seconds; tokens issued before this were signed out. Cached briefly."""
    now = time.monotonic()
    cached = _valid_after.get(uid)
    if cached and now - cached[0] < _CHECK_SECONDS:
        return cached[1]
    value = int(auth.get_user(uid).tokens_valid_after_timestamp or 0)
    _valid_after[uid] = (now, value)
    return value


class AuthService:
    def verify_bearer_token(self, authorization: str | None) -> str:
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

        return uid


auth_service = AuthService()


def require_uid(authorization: str | None = Header(default=None)) -> str:
    return auth_service.verify_bearer_token(authorization)
