import time

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field

from app.services import identities, rate_limit
from app.services.auth_service import require_uid
from app.services.firebase_service import FirebaseService

router = APIRouter(prefix="/auth", tags=["identities"])


class ProviderTokenRequest(BaseModel):
    access_token: str = Field(min_length=10, max_length=4000)
    # 확인된 이메일로 기존 계정을 찾지 못했을 때만, 사람이 새 계정을 고른 뒤에 true.
    create_account: bool = False


class GoogleTokenRequest(BaseModel):
    id_token: str = Field(min_length=10, max_length=4000)
    create_account: bool = False


def _db():
    return FirebaseService().db


def _client(request: Request) -> str:
    forwarded = request.headers.get("x-forwarded-for", "")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.client.host if request.client else ""


def _throttle(
    request: Request,
    uid: str,
    by_uid: rate_limit.WindowLimiter,
    by_ip: rate_limit.WindowLimiter,
) -> None:
    """Link, unlink and preview are for a person choosing, not for a script."""
    now = time.monotonic()
    if not by_uid.allow(uid, now) or not by_ip.allow(_client(request), now):
        raise HTTPException(status_code=429, detail="too_many_attempts")


def _throttle_link(request: Request, uid: str) -> None:
    _throttle(request, uid, rate_limit.LINK_BY_UID, rate_limit.LINK_BY_IP)


@router.post("/kakao/login")
def kakao_login(body: ProviderTokenRequest, request: Request) -> dict:
    # No Firebase token yet: this is how a phone gets one.
    if not identities.allow_login_attempt(_client(request), time.monotonic()):
        raise HTTPException(status_code=429, detail="too_many_attempts")
    return identities.login(
        _db(), "kakao", body.access_token, create_account=body.create_account
    )


@router.post("/kakao/link")
def kakao_link(
    body: ProviderTokenRequest, request: Request, uid: str = Depends(require_uid)
) -> dict:
    _throttle_link(request, uid)
    return identities.link(_db(), uid, "kakao", body.access_token)


@router.post("/kakao/unlink")
def kakao_unlink(request: Request, uid: str = Depends(require_uid)) -> dict:
    _throttle_link(request, uid)
    return identities.unlink(_db(), uid, "kakao")


@router.post("/naver/login")
def naver_login(body: ProviderTokenRequest, request: Request) -> dict:
    if not identities.allow_login_attempt(_client(request), time.monotonic()):
        raise HTTPException(status_code=429, detail="too_many_attempts")
    return identities.login(
        _db(), "naver", body.access_token, create_account=body.create_account
    )


@router.post("/naver/link")
def naver_link(
    body: ProviderTokenRequest, request: Request, uid: str = Depends(require_uid)
) -> dict:
    _throttle_link(request, uid)
    return identities.link(_db(), uid, "naver", body.access_token)


@router.post("/naver/unlink")
def naver_unlink(request: Request, uid: str = Depends(require_uid)) -> dict:
    _throttle_link(request, uid)
    return identities.unlink(_db(), uid, "naver")


@router.post("/google/login")
def google_login(body: GoogleTokenRequest, request: Request) -> dict:
    # 구글도 같은 서버 계정으로 들어오게 한다. 전화가 Firebase에 먼저
    # 새 사용자를 만들지 않고, 여기로 받은 맞춤 토큰으로 로그인한다.
    if not identities.allow_login_attempt(_client(request), time.monotonic()):
        raise HTTPException(status_code=429, detail="too_many_attempts")
    return identities.login(
        _db(), "google", body.id_token, create_account=body.create_account
    )


@router.post("/google/link")
def google_link(
    body: GoogleTokenRequest, request: Request, uid: str = Depends(require_uid)
) -> dict:
    _throttle_link(request, uid)
    return identities.link(_db(), uid, "google", body.id_token)


@router.post("/google/unlink")
def google_unlink(request: Request, uid: str = Depends(require_uid)) -> dict:
    _throttle_link(request, uid)
    return identities.unlink(_db(), uid, "google")


@router.get("/link-preview")
def link_preview(request: Request, uid: str = Depends(require_uid)) -> dict:
    """Nickname and SHARE of the signed-in account, before a link is confirmed."""
    _throttle(request, uid, rate_limit.PREVIEW_BY_UID, rate_limit.PREVIEW_BY_IP)
    return identities.link_preview(_db(), uid)


@router.get("/identities")
def list_identities(uid: str = Depends(require_uid)) -> dict:
    return identities.list_providers(_db(), uid)
