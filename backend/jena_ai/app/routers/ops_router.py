from fastapi import APIRouter, Depends

from app.models.ops_result import (
    ActivateTournamentResult,
    BepRefundResult,
    PurgeDeletedAccountsResult,
    PurgeUserResult,
)
from app.services.ops_auth_service import require_ops_admin
from app.services.ops_service import OpsService

router = APIRouter(prefix="/ops", tags=["operations"])
service = OpsService()


@router.post(
    "/tournaments/{tournament_id}/cancel-bep-refund",
    response_model=BepRefundResult,
)
def cancel_bep_and_refund(
    tournament_id: str,
    _: None = Depends(require_ops_admin),
) -> BepRefundResult:
    return service.cancel_bep_and_refund(tournament_id=tournament_id)


@router.post(
    "/tournaments/{tournament_id}/activate",
    response_model=ActivateTournamentResult,
)
def activate_tournament(
    tournament_id: str,
    _: None = Depends(require_ops_admin),
) -> ActivateTournamentResult:
    return service.activate_tournament(tournament_id=tournament_id)


@router.post("/users/{uid}/purge-data", response_model=PurgeUserResult)
def purge_user_data(
    uid: str,
    _: None = Depends(require_ops_admin),
) -> PurgeUserResult:
    return service.purge_user_data(uid=uid)


@router.post("/users/purge-deleted", response_model=PurgeDeletedAccountsResult)
def purge_deleted_accounts(
    _: None = Depends(require_ops_admin),
) -> PurgeDeletedAccountsResult:
    return service.purge_deleted_accounts()
