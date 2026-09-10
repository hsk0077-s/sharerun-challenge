from fastapi import APIRouter, Depends

from app.models.secured_actions import (
    ApplyReferralRequest,
    CollectDiamondBoxRequest,
    HarvestPedometerRequest,
    JoinTournamentRequest,
    RefundRequest,
    SecuredActionResult,
    SettleTournamentFailureRequest,
    ShopPurchaseRequest,
    ValidateRunRequest,
    Web3TransferRequest,
    WinnerRewardRequest,
)
from app.models.validation_result import ValidationResult
from app.services.auth_service import require_uid
from app.services.secured_action_service import SecuredActionService

router = APIRouter(prefix="/actions", tags=["secured-actions"])
service = SecuredActionService()


@router.post("/runs/validate", response_model=ValidationResult)
def validate_run(
    request: ValidateRunRequest,
    uid: str = Depends(require_uid),
) -> ValidationResult:
    return service.validate_run(uid=uid, request=request)


@router.post("/tournaments/join", response_model=SecuredActionResult)
def join_tournament(
    request: JoinTournamentRequest,
    uid: str = Depends(require_uid),
) -> SecuredActionResult:
    return service.join_tournament(uid=uid, request=request)


@router.post("/tournaments/settle-failure", response_model=SecuredActionResult)
def settle_tournament_failure(
    request: SettleTournamentFailureRequest,
    uid: str = Depends(require_uid),
) -> SecuredActionResult:
    return service.settle_tournament_failure(uid=uid, request=request)


@router.post("/diamond-boxes/collect", response_model=SecuredActionResult)
def collect_diamond_box(
    request: CollectDiamondBoxRequest,
    uid: str = Depends(require_uid),
) -> SecuredActionResult:
    return service.collect_diamond_box(uid=uid, request=request)


@router.post("/wallet/refund", response_model=SecuredActionResult)
def request_refund(
    request: RefundRequest,
    uid: str = Depends(require_uid),
) -> SecuredActionResult:
    return service.request_refund(uid=uid, request=request)


@router.post("/pedometer/harvest", response_model=SecuredActionResult)
def harvest_pedometer_share(
    request: HarvestPedometerRequest,
    uid: str = Depends(require_uid),
) -> SecuredActionResult:
    return service.harvest_pedometer_share(uid=uid, request=request)


@router.post("/debug/test-grant-1m", response_model=SecuredActionResult)
def grant_debug_test_wallet(
    uid: str = Depends(require_uid),
) -> SecuredActionResult:
    return service.grant_debug_test_wallet(uid=uid)


@router.post("/account/delete", response_model=SecuredActionResult)
def delete_account(uid: str = Depends(require_uid)) -> SecuredActionResult:
    return service.delete_account(uid=uid)


@router.post("/rewards/winner", response_model=SecuredActionResult)
def apply_winner_reward(
    request: WinnerRewardRequest,
    uid: str = Depends(require_uid),
) -> SecuredActionResult:
    return service.apply_winner_reward(uid=uid, request=request)


@router.post("/onboarding/claim-signup", response_model=SecuredActionResult)
def claim_signup_reward(uid: str = Depends(require_uid)) -> SecuredActionResult:
    return service.claim_signup_reward(uid=uid)


@router.post("/referrals/apply", response_model=SecuredActionResult)
def apply_referral_code(
    request: ApplyReferralRequest,
    uid: str = Depends(require_uid),
) -> SecuredActionResult:
    return service.apply_referral_code(uid=uid, referral_code=request.referral_code)


@router.post("/shop/purchase", response_model=SecuredActionResult)
def purchase_shop_item(
    request: ShopPurchaseRequest,
    uid: str = Depends(require_uid),
) -> SecuredActionResult:
    return service.purchase_shop_item(uid=uid, item_id=request.item_id)


@router.post("/web3/transfer", response_model=SecuredActionResult)
def transfer_value_to_web3(
    request: Web3TransferRequest,
    uid: str = Depends(require_uid),
) -> SecuredActionResult:
    return service.transfer_value_to_web3(uid=uid, request=request)
