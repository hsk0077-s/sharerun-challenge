from fastapi import APIRouter, Depends

from app.models.secured_actions import (
    ApplyReferralRequest,
    CollectDiamondBoxRequest,
    DebugTestGrantRequest,
    HarvestPedometerRequest,
    InviteCodeResult,
    NicknameChangeRequest,
    JoinTournamentRequest,
    RedeemReferralRequest,
    RedeemReferralResult,
    RefundRequest,
    SecuredActionResult,
    SettleTournamentFailureRequest,
    CoachPlusActivateRequest,
    CreateChallengeRoomRequest,
    CreateChallengeRoomResult,
    CrewFoundRequest,
    CrewSpendRequest,
    ShopPurchaseRequest,
    ValidateRunRequest,
    ShareToDiaRequest,
    ShareToDiaView,
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
    request: DebugTestGrantRequest = DebugTestGrantRequest(),
    uid: str = Depends(require_uid),
) -> SecuredActionResult:
    return service.grant_debug_test_wallet(uid=uid, request=request)


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


@router.post("/rewards/streak", response_model=SecuredActionResult)
def claim_streak_bonus(uid: str = Depends(require_uid)) -> SecuredActionResult:
    return service.claim_streak_bonus(uid=uid)


@router.post("/onboarding/claim-trial", response_model=SecuredActionResult)
def claim_trial_reward(uid: str = Depends(require_uid)) -> SecuredActionResult:
    return service.claim_trial_reward(uid=uid)


@router.post("/referrals/apply", response_model=SecuredActionResult)
def apply_referral_code(
    request: ApplyReferralRequest,
    uid: str = Depends(require_uid),
) -> SecuredActionResult:
    return service.apply_referral_code(uid=uid, referral_code=request.referral_code)


@router.post("/referrals/code", response_model=InviteCodeResult)
def get_or_create_invite_code(uid: str = Depends(require_uid)) -> InviteCodeResult:
    return service.get_or_create_invite_code(uid=uid)


@router.post("/referrals/redeem", response_model=RedeemReferralResult)
def redeem_referral_code(
    request: RedeemReferralRequest,
    uid: str = Depends(require_uid),
) -> RedeemReferralResult:
    return service.redeem_referral_code(uid=uid, code=request.code)


@router.post("/coach-plus/activate", response_model=SecuredActionResult)
def activate_coach_plus(
    request: CoachPlusActivateRequest,
    uid: str = Depends(require_uid),
) -> SecuredActionResult:
    return service.activate_coach_plus(uid=uid, product_id=request.product_id)


@router.post("/shop/purchase", response_model=SecuredActionResult)
def purchase_shop_item(
    request: ShopPurchaseRequest,
    uid: str = Depends(require_uid),
) -> SecuredActionResult:
    return service.purchase_shop_item(uid=uid, item_id=request.item_id)


@router.post("/shop/crew-gift", response_model=SecuredActionResult)
def grant_crew_items(uid: str = Depends(require_uid)) -> SecuredActionResult:
    return service.grant_crew_items(uid=uid)


@router.post("/crew/spend", response_model=SecuredActionResult)
def spend_crew_action(
    request: CrewSpendRequest,
    uid: str = Depends(require_uid),
) -> SecuredActionResult:
    return service.spend_crew_action(uid=uid, action=request.action)


@router.post("/profile/nickname", response_model=SecuredActionResult)
def change_nickname(
    request: NicknameChangeRequest,
    uid: str = Depends(require_uid),
) -> SecuredActionResult:
    return service.change_nickname(uid=uid, nickname=request.nickname)


@router.post("/crew/found", response_model=SecuredActionResult)
def found_crew(
    request: CrewFoundRequest,
    uid: str = Depends(require_uid),
) -> SecuredActionResult:
    return service.found_crew(uid=uid, name=request.name)


@router.post("/tournaments/create-room", response_model=CreateChallengeRoomResult)
def create_challenge_room(
    request: CreateChallengeRoomRequest,
    uid: str = Depends(require_uid),
) -> CreateChallengeRoomResult:
    return service.create_challenge_room(
        uid=uid, title=request.title, distance_km=request.distance_km
    )


@router.post("/shop/use", response_model=SecuredActionResult)
def use_shop_item(
    request: ShopPurchaseRequest,
    uid: str = Depends(require_uid),
) -> SecuredActionResult:
    return service.use_shop_item(uid=uid, item_id=request.item_id)


@router.post("/web3/transfer", response_model=SecuredActionResult)
def transfer_value_to_web3(
    request: Web3TransferRequest,
    uid: str = Depends(require_uid),
) -> SecuredActionResult:
    return service.transfer_value_to_web3(uid=uid, request=request)


@router.post("/hall-of-fame/donate", response_model=SecuredActionResult)
def donate_hall_of_fame(uid: str = Depends(require_uid)) -> SecuredActionResult:
    return service.donate_hall_of_fame(uid=uid)


@router.post("/wallet/share-to-dia/quote", response_model=ShareToDiaView)
def quote_share_to_dia(uid: str = Depends(require_uid)) -> ShareToDiaView:
    return service.quote_share_to_dia(uid=uid)


@router.post("/wallet/share-to-dia", response_model=ShareToDiaView)
def exchange_share_to_dia(
    request: ShareToDiaRequest,
    uid: str = Depends(require_uid),
) -> ShareToDiaView:
    return service.exchange_share_to_dia(uid=uid, dia_amount=request.dia_amount)
