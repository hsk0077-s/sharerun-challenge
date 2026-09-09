from fastapi import Header, HTTPException, status
from firebase_admin import auth

from app.services.firebase_service import FirebaseService


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

        return uid


auth_service = AuthService()


def require_uid(authorization: str | None = Header(default=None)) -> str:
    return auth_service.verify_bearer_token(authorization)
