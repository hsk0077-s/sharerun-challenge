from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.models.ops_result import (
    ActivateTournamentResult,
    BepRefundResult,
    CreatePrizeRaceResult,
    CreateRankedTournamentResult,
    GradeBackfillResult,
    PrizeSettlementResult,
    PurgeDeletedAccountsResult,
    PurgeUserResult,
)
from app.services import crew_ranking
from app.services.ops_auth_service import require_ops_admin
from app.services.ops_service import OpsService

router = APIRouter(prefix="/ops", tags=["operations"])
service = OpsService()


class CreatePrizeRaceRequest(BaseModel):
    tier: str
    edition: int


class CreateRankedTournamentRequest(BaseModel):
    kind: str
    title: str
    target_distance_km: float
    tier_animal: int | None = None
    entry_fee_share: int = 0
    max_participants: int = 1000


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


@router.post(
    "/prize-races/{tournament_id}",
    response_model=CreatePrizeRaceResult,
)
def create_company_prize_race(
    tournament_id: str,
    request: CreatePrizeRaceRequest,
    _: None = Depends(require_ops_admin),
) -> CreatePrizeRaceResult:
    return service.create_company_prize_race(
        tournament_id=tournament_id,
        tier=request.tier,
        edition=request.edition,
    )


@router.post(
    "/ranked-tournaments/{tournament_id}",
    response_model=CreateRankedTournamentResult,
)
def create_ranked_tournament(
    tournament_id: str,
    request: CreateRankedTournamentRequest,
    _: None = Depends(require_ops_admin),
) -> CreateRankedTournamentResult:
    made = service.create_ranked_tournament(
        tournament_id,
        kind=request.kind,
        title=request.title,
        target_distance_km=request.target_distance_km,
        tier_animal=request.tier_animal,
        entry_fee_share=request.entry_fee_share,
        max_participants=request.max_participants,
    )
    return CreateRankedTournamentResult(
        accepted=True,
        tournament_id=made["tournamentId"],
        status=made["status"],
    )


@router.post(
    "/tournaments/{tournament_id}/settle",
    response_model=PrizeSettlementResult,
)
def settle_company_tournament(
    tournament_id: str,
    _: None = Depends(require_ops_admin),
) -> PrizeSettlementResult:
    return service.settle_company_tournament(tournament_id=tournament_id)


@router.post("/crews/ranking/{month}/finalize")
def finalize_crew_ranking(month: str, _: None = Depends(require_ops_admin)) -> dict:
    """Close a finished month (YYYY-MM) now instead of waiting for the next ranking read."""
    if len(month) != 7 or month[4] != "-" or not (month[:4] + month[5:]).isdigit():
        raise HTTPException(status_code=400, detail="Month must look like 2026-09.")
    return crew_ranking.finalize_month(service.firebase_service.db, month)


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


@router.post("/grades/backfill", response_model=GradeBackfillResult)
def backfill_grades(
    dry_run: bool = True,
    _: None = Depends(require_ops_admin),
) -> GradeBackfillResult:
    return service.backfill_grades(dry_run=dry_run)
