from collections.abc import Callable

from fastapi import HTTPException, status
from firebase_admin import auth

from app.services.firebase_service import FirebaseService

# Keep in sync with firestore.rules isAdmin() email allowlist.
ADMIN_EMAILS = frozenset(
    {
        "admin@share-run-challenge.app",
        "ops@share-run-challenge.app",
    }
)


class AdminAuthService:
    def __init__(
        self,
        *,
        verify_token: Callable[[str], dict] | None = None,
        admin_doc_exists: Callable[[str], bool] | None = None,
    ) -> None:
        self._verify_token = verify_token
        self._admin_doc_exists = admin_doc_exists

    def require_admin(self, authorization: str | None) -> dict:
        decoded = self._decode(authorization)
        if not self.is_admin(decoded):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Admin access required.",
            )
        return decoded

    def is_admin(self, decoded: dict) -> bool:
        if decoded.get("admin") is True:
            return True
        email = decoded.get("email")
        if email in ADMIN_EMAILS:
            return True
        uid = decoded.get("uid")
        if not isinstance(uid, str) or not uid:
            return False
        return self._has_admin_doc(uid)

    def _decode(self, authorization: str | None) -> dict:
        if not authorization or not authorization.startswith("Bearer "):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Missing Firebase ID token.",
            )
        token = authorization.removeprefix("Bearer ").strip()
        if not token:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Missing Firebase ID token.",
            )
        try:
            decoded = self._verify(token)
        except HTTPException:
            raise
        except Exception as error:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid Firebase ID token.",
            ) from error
        if not isinstance(decoded, dict) or not decoded.get("uid"):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Firebase token did not include uid.",
            )
        return decoded

    def _verify(self, token: str) -> dict:
        if self._verify_token is not None:
            return self._verify_token(token)
        FirebaseService()
        return auth.verify_id_token(token)

    def _has_admin_doc(self, uid: str) -> bool:
        if self._admin_doc_exists is not None:
            return self._admin_doc_exists(uid)
        snapshot = (
            FirebaseService().db.collection("admins").document(uid).get()
        )
        return bool(snapshot.exists)


admin_auth_service = AdminAuthService()
