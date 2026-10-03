from fastapi import APIRouter, Depends, Header, Query

from app.models.admin_api import (
    AuditPingRequest,
    AuditPingResult,
    DailyStepsResult,
    ReferralListResult,
    WalletAnomalyListResult,
    WalletLedgerResult,
    WhoAmIResult,
)
from app.services.admin_audit_service import admin_audit_service
from app.services.admin_auth_service import admin_auth_service
from app.services.admin_daily_steps_service import admin_daily_steps_service
from app.services.admin_referral_service import admin_referral_service
from app.services.admin_wallet_anomaly_service import admin_wallet_anomaly_service
from app.services.admin_wallet_ledger_service import admin_wallet_ledger_service


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


@router.get("/referrals", response_model=ReferralListResult)
def list_referrals(
    limit: int = Query(default=40, ge=1, le=80),
    cursor: str | None = None,
    _actor: dict = Depends(require_admin_user),
) -> ReferralListResult:
    return admin_referral_service.list_referrals(limit=limit, cursor=cursor)


@router.get("/daily-steps", response_model=DailyStepsResult)
def list_daily_steps(
    uid: str | None = None,
    start: str | None = Query(default=None, alias="from"),
    end: str | None = Query(default=None, alias="to"),
    _actor: dict = Depends(require_admin_user),
) -> DailyStepsResult:
    return admin_daily_steps_service.list_steps(uid=uid, start=start, end=end)


@router.get("/wallet-anomalies", response_model=WalletAnomalyListResult)
def list_wallet_anomalies(
    uid: str | None = None,
    limit: int = Query(default=20, ge=1, le=40),
    cursor: str | None = None,
    _actor: dict = Depends(require_admin_user),
) -> WalletAnomalyListResult:
    return admin_wallet_anomaly_service.list_anomalies(
        uid=uid,
        limit=limit,
        cursor=cursor,
    )


@router.get("/wallet-ledger", response_model=WalletLedgerResult)
def get_wallet_ledger(
    uid: str,
    actor: dict = Depends(require_admin_user),
) -> WalletLedgerResult:
    email = actor.get("email")
    return admin_wallet_ledger_service.lookup(
        uid=uid,
        actor_uid=str(actor["uid"]),
        actor_email=email if isinstance(email, str) else None,
    )
