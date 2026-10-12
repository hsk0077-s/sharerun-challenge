import time

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field

from app.services import identities
from app.services.auth_service import require_uid
from app.services.firebase_service import FirebaseService

router = APIRouter(prefix="/auth", tags=["identities"])


class ProviderTokenRequest(BaseModel):
    access_token: str = Field(min_length=10, max_length=4000)


def _db():
    return FirebaseService().db


def _client(request: Request) -> str:
    forwarded = request.headers.get("x-forwarded-for", "")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.client.host if request.client else ""


@router.post("/kakao/login")
def kakao_login(body: ProviderTokenRequest, request: Request) -> dict:
    # No Firebase token yet: this is how a phone gets one.
    if not identities.allow_login_attempt(_client(request), time.monotonic()):
        raise HTTPException(status_code=429, detail="too_many_attempts")
    return identities.login(_db(), "kakao", body.access_token)


@router.post("/kakao/link")
def kakao_link(body: ProviderTokenRequest, uid: str = Depends(require_uid)) -> dict:
    return identities.link(_db(), uid, "kakao", body.access_token)


@router.post("/kakao/unlink")
def kakao_unlink(uid: str = Depends(require_uid)) -> dict:
    return identities.unlink(_db(), uid, "kakao")


@router.get("/identities")
def list_identities(uid: str = Depends(require_uid)) -> dict:
    return identities.list_providers(_db(), uid)
