from fastapi import APIRouter, Depends, Header

from app.models.admin_api import AuditPingRequest, AuditPingResult, WhoAmIResult
from app.services.admin_audit_service import admin_audit_service
from app.services.admin_auth_service import admin_auth_service


router = APIRouter(prefix="/admin", tags=["admin"])


def require_admin_user(
    authorization: str | None = Header(default=None),
) -> dict:
    return admin_auth_service.require_admin(authorization)


@router.get("/whoami", response_model=WhoAmIResult)
def whoami(actor: dict = Depends(require_admin_user)) -> WhoAmIResult:
    email = actor.get("email")
    return WhoAmIResult(
        uid=str(actor["uid"]),
        email=email if isinstance(email, str) else None,
        admin=True,
    )


@router.post("/audit/ping", response_model=AuditPingResult)
def audit_ping(
    actor: dict = Depends(require_admin_user),
    body: AuditPingRequest | None = None,
) -> AuditPingResult:
    email = actor.get("email")
    log_id = admin_audit_service.write(
        uid=str(actor["uid"]),
        email=email if isinstance(email, str) else None,
        action="audit_ping",
        target_uid=None,
        before=None,
        after=None,
        reason=(body.reason if body and body.reason else "ping"),
    )
    return AuditPingResult(accepted=True, log_id=log_id, action="audit_ping")
