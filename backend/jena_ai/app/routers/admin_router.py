from fastapi import APIRouter, Depends, Header, Query, Response

from app.models.admin_api import (
    AppealDecisionRequest,
    AuditPingRequest,
    AuditPingResult,
    DailyStepsResult,
    ReferralListResult,
    ReportStatusRequest,
    UserDetailResult,
    WalletAnomalyListResult,
    WalletLedgerResult,
    WhoAmIResult,
)
from app.services import appeals, reports
from app.services.admin_audit_service import admin_audit_service
from app.services.admin_auth_service import admin_auth_service
from app.services.admin_daily_steps_service import admin_daily_steps_service
from app.services.admin_referral_service import admin_referral_service
from app.services.admin_user_detail_service import admin_user_detail_service
from app.services.admin_wallet_anomaly_service import admin_wallet_anomaly_service
from app.services.admin_wallet_ledger_service import admin_wallet_ledger_service
from app.services.firebase_service import FirebaseService
from app.services.secured_action_service import SecuredActionService


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


def _actor_email(actor: dict) -> str | None:
    email = actor.get("email")
    return email if isinstance(email, str) else None


@router.get("/user-detail", response_model=UserDetailResult)
def get_user_detail(
    uid: str,
    actor: dict = Depends(require_admin_user),
) -> UserDetailResult:
    """Profile, login providers, reward block and crew for CS lookups."""
    return admin_user_detail_service.lookup(
        uid=uid,
        actor_uid=str(actor["uid"]),
        actor_email=_actor_email(actor),
    )


@router.get("/appeals/{appeal_id}/proof")
def get_appeal_proof(
    appeal_id: str,
    actor: dict = Depends(require_admin_user),
) -> Response:
    """The proof photo for one appeal. Every look is written to the audit log."""
    data, content_type = appeals.get_proof(FirebaseService().db, appeal_id)
    admin_audit_service.write(
        uid=str(actor["uid"]),
        email=_actor_email(actor),
        action="appeal_proof_view",
        target_uid=None,
        reason=appeal_id,
    )
    return Response(
        content=data,
        media_type=content_type,
        headers={"Cache-Control": "no-store"},
    )


@router.post("/appeals/{appeal_id}/decision")
def decide_appeal(
    appeal_id: str,
    body: AppealDecisionRequest,
    actor: dict = Depends(require_admin_user),
) -> dict:
    """Approve (settle the run like a verified one) or reject an appeal."""
    actions = SecuredActionService()
    if body.decision == "approved":
        outcome = actions.approve_appeal(
            appeal_id, actor_uid=str(actor["uid"]), note=body.note
        )
    else:
        outcome = appeals.reject_appeal(
            actions.firebase_service.db,
            appeal_id,
            actor_uid=str(actor["uid"]),
            note=body.note,
        )
    admin_audit_service.write(
        uid=str(actor["uid"]),
        email=_actor_email(actor),
        action=f"appeal_{body.decision}",
        target_uid=None,
        before={"status": "under_review"},
        after={"status": outcome.get("status")},
        reason=f"{appeal_id}: {body.note[:120]}",
    )
    return outcome


@router.get("/reports")
def list_reports(
    status: str = "open",
    limit: int = Query(default=50, ge=1, le=100),
    _actor: dict = Depends(require_admin_user),
) -> dict:
    """Player reports of names, oldest first."""
    return {"reports": reports.list_reports(FirebaseService().db, status, limit)}


@router.post("/reports/{report_id}/status")
def set_report_status(
    report_id: str,
    body: ReportStatusRequest,
    actor: dict = Depends(require_admin_user),
) -> dict:
    """Marks a report reviewed, resolved or dismissed. Every change is audited."""
    outcome = reports.set_report_status(
        FirebaseService().db,
        report_id,
        body.status,
        str(actor["uid"]),
        body.note,
    )
    admin_audit_service.write(
        uid=str(actor["uid"]),
        email=_actor_email(actor),
        action="report_status",
        target_uid=None,
        before={"status": outcome["before"]},
        after={"status": outcome["status"]},
        reason=f"{report_id}: {body.note[:120]}",
    )
    return {"id": report_id, "status": outcome["status"]}
