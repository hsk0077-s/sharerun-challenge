import time

from fastapi import APIRouter, Depends, Header, HTTPException, Request, status

from app.config import debug_test_grant_enabled
from app.models.secured_actions import (
    AppealRequest,
    IntegrityReportRequest,
    AiLearningRequest,
    LoginDeviceRequest,
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
    SignupFreeTicketResult,
    SettleTournamentFailureRequest,
    CoachPlusActivateRequest,
    CreateChallengeRoomRequest,
    CreateChallengeRoomResult,
    CrewEmblemPurchaseRequest,
    AccessoryEquipRequest,
    CrewDecideRequest,
    CrewRenameRequest,
    DailyStepsRequest,
    ReportRequest,
    DiaRefundRequest,
    CrewJoinModeRequest,
    CrewJoinRequest,
    CrewTargetRequest,
    CrewRoleRequest,
    CrewEmblemRequest,
    CrewEmblemStatus,
    CrewFoundRequest,
    CrewExpandRequest,
    CrewGiftRequest,
    CosmeticCatalogItem,
    CosmeticCatalogView,
    CosmeticEquipRequest,
    ShopCatalogItem,
    ShopCatalogView,
    ShopPurchaseRequest,
    ValidateRunRequest,
    DiaPackGrantRequest,
    PersonalSponsorRequest,
    PersonalSponsorResult,
    ShareToDiaRequest,
    ShareToDiaView,
    Web3TransferRequest,
    WinnerRewardRequest,
)
from app.models.validation_result import ValidationResult
from app.services.admin_auth_service import admin_auth_service
from app.services.auth_service import require_uid
from app.services import appeals, daily_steps, integrity, login_devices, privacy_settings, reports
from app.services.notification_service import send_new_device_alert
from app.services.auth_service import forget_sign_out_cache
from app.services import crew_membership, crew_ranking, dia_refund, funding_goal, sponsorship_records
from app.services import rate_limit, run_times, watch_pairing
from app.services.secured_action_service import SecuredActionService

router = APIRouter(prefix="/actions", tags=["secured-actions"])
service = SecuredActionService()


@router.post("/runs/validate", response_model=ValidationResult)
def validate_run(
    request: ValidateRunRequest,
    http_request: Request,
    uid: str = Depends(require_uid),
) -> ValidationResult:
    run_times.check_run_times(
        request.started_at,
        request.ended_at,
        request.duration_seconds,
        required=bool(getattr(http_request.state, "is_watch", False)),
    )
    return service.validate_run(uid=uid, request=request)


@router.post("/tournaments/join", response_model=SecuredActionResult)
def join_tournament(
    request: JoinTournamentRequest,
    uid: str = Depends(require_uid),
) -> SecuredActionResult:
    return service.join_tournament(uid=uid, request=request)


@router.get("/company-tournament/config")
def company_tournament_config(uid: str = Depends(require_uid)) -> dict:
    return service.get_company_tournament_config(uid)


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


@router.post("/wallet/signup-ticket", response_model=SignupFreeTicketResult)
def ensure_signup_free_ticket(uid: str = Depends(require_uid)) -> SignupFreeTicketResult:
    """One first-race ticket per account. A repeat call does not grant another."""
    return service.ensure_signup_free_ticket(uid=uid)


@router.post("/wallet/refund", response_model=SecuredActionResult)
def request_refund(
    request: RefundRequest,
    uid: str = Depends(require_uid),
) -> SecuredActionResult:
    return service.request_refund(uid=uid, request=request)


@router.get("/crew/ranking")
def crew_ranking_summary(uid: str = Depends(require_uid)) -> dict:
    """This month's crew ranking and where the caller's crew stands."""
    db = service.firebase_service.db
    user = db.collection("users").document(uid).get()
    crew_id = crew_membership.member_crew_id(user.to_dict() or {}) if user.exists else ""
    return crew_ranking.summary(db, crew_id)


@router.get("/funding/summary")
def funding_summary(uid: str = Depends(require_uid)) -> dict:
    """This month's company donation against the current goal. Same numbers for everyone."""
    return funding_goal.summary(service.firebase_service.db)


@router.get("/sponsorship/summary")
def sponsorship_summary(uid: str = Depends(require_uid)) -> dict:
    """Public totals of donation sponsorship (amounts held back until enough sponsors)."""
    return sponsorship_records.summary(service.firebase_service.db, uid)


@router.get("/sponsorship/mine")
def sponsorship_mine(uid: str = Depends(require_uid)) -> dict:
    """The caller's own sponsorship entries. Nobody else's."""
    return sponsorship_records.mine(service.firebase_service.db, uid)


@router.get("/wallet/dia-purchases")
def dia_purchases(uid: str = Depends(require_uid)) -> dict:
    """DIA pack purchases inside the refund period, each with what a refund would pay."""
    return {
        "refund_days": dia_refund.refund_days(),
        "purchases": dia_refund.list_refundable(service.firebase_service.db, uid),
    }


@router.post("/wallet/dia-refund")
def dia_refund_request(request: DiaRefundRequest, uid: str = Depends(require_uid)) -> dict:
    """Cash refund of the unused paid DIA of one pack bought in the last 7 days."""
    return dia_refund.request_refund(service, uid, request.purchase_id)


@router.post("/pedometer/harvest", response_model=SecuredActionResult)
def harvest_pedometer_share(
    request: HarvestPedometerRequest,
    uid: str = Depends(require_uid),
) -> SecuredActionResult:
    return service.harvest_pedometer_share(uid=uid, request=request)


@router.post("/debug/test-grant-1m", response_model=SecuredActionResult)
def grant_debug_test_wallet(
    request: DebugTestGrantRequest = DebugTestGrantRequest(),
    authorization: str | None = Header(default=None),
) -> SecuredActionResult:
    # Off by default. A baked client secret is not enough. Existing balances
    # are left as they are; this returns before any wallet write.
    if not debug_test_grant_enabled():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Not found.",
        )
    actor = admin_auth_service.require_admin(authorization)
    return service.grant_debug_test_wallet(
        uid=str(actor["uid"]),
        request=request,
        admin_authorized=True,
    )


@router.post("/account/delete", response_model=SecuredActionResult)
def delete_account(uid: str = Depends(require_uid)) -> SecuredActionResult:
    return service.delete_account(uid=uid)


@router.post("/rewards/winner", response_model=SecuredActionResult)
def apply_winner_reward(
    request: WinnerRewardRequest,
    uid: str = Depends(require_uid),
) -> SecuredActionResult:
    return service.apply_winner_reward(uid=uid, request=request)


@router.post("/onboarding/confirm-age14", response_model=SecuredActionResult)
def confirm_age_over_14(uid: str = Depends(require_uid)) -> SecuredActionResult:
    return service.confirm_age_over_14(uid=uid)


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
    return service.activate_coach_plus(
        uid=uid,
        product_id=request.product_id,
        purchase_token=request.purchase_token,
    )


@router.post("/shop/purchase", response_model=SecuredActionResult)
def purchase_shop_item(
    request: ShopPurchaseRequest,
    uid: str = Depends(require_uid),
) -> SecuredActionResult:
    return service.purchase_shop_item(
        uid=uid,
        item_id=request.item_id,
        request_id=request.request_id,
        pay_with=request.pay_with,
    )


@router.post("/crew/emblem", response_model=SecuredActionResult)
def change_crew_emblem(
    request: CrewEmblemRequest,
    uid: str = Depends(require_uid),
) -> SecuredActionResult:
    return service.change_crew_emblem(uid=uid, emblem=request.emblem)


@router.get("/crew/list")
def list_crews(query: str = "", uid: str = Depends(require_uid)) -> dict:
    return crew_membership.list_crews(service.firebase_service.db, query[:40], uid)


@router.get("/crew/mine")
def my_crew(uid: str = Depends(require_uid)) -> dict:
    return crew_membership.my_crew(service.firebase_service.db, uid)


@router.post("/crew/join")
def join_crew(request: CrewJoinRequest, uid: str = Depends(require_uid)) -> dict:
    return crew_membership.join(service.firebase_service.db, uid, request.crew_id)


@router.post("/crew/leave")
def leave_crew(uid: str = Depends(require_uid)) -> dict:
    return crew_membership.leave(service.firebase_service.db, uid)


@router.post("/crew/join-mode")
def set_crew_join_mode(request: CrewJoinModeRequest, uid: str = Depends(require_uid)) -> dict:
    return crew_membership.set_join_mode(service.firebase_service.db, uid, request.mode)


@router.get("/crew/requests")
def crew_join_requests(uid: str = Depends(require_uid)) -> dict:
    return crew_membership.list_requests(service.firebase_service.db, uid)


@router.post("/crew/requests/decide")
def decide_crew_request(request: CrewDecideRequest, uid: str = Depends(require_uid)) -> dict:
    return crew_membership.decide_request(
        service.firebase_service.db, uid, request.uid, request.approve
    )


@router.post("/crew/requests/cancel")
def cancel_crew_request(uid: str = Depends(require_uid)) -> dict:
    return crew_membership.cancel_request(service.firebase_service.db, uid)


@router.post("/crew/kick")
def kick_crew_member(request: CrewTargetRequest, uid: str = Depends(require_uid)) -> dict:
    return crew_membership.kick(service.firebase_service.db, uid, request.uid)


@router.post("/crew/transfer")
def transfer_crew(request: CrewTargetRequest, uid: str = Depends(require_uid)) -> dict:
    return crew_membership.transfer(service.firebase_service.db, uid, request.uid)


@router.post("/reports")
def submit_report(request: ReportRequest, uid: str = Depends(require_uid)) -> dict:
    return reports.submit_report(
        service.firebase_service.db,
        uid,
        request.target_type,
        request.target_id,
        request.reason,
        request.detail,
    )


@router.get("/watch-pairing/devices")
def watch_pairing_devices(uid: str = Depends(require_uid)) -> dict:
    return watch_pairing.list_devices(service.firebase_service.db, uid)


@router.post("/watch-pairing/devices/{device_id}/revoke")
def watch_pairing_revoke_device(device_id: str, uid: str = Depends(require_uid)) -> dict:
    return watch_pairing.revoke_device(service.firebase_service.db, uid, device_id)


@router.post("/watch-pairing/revoke")
def watch_pairing_revoke(uid: str = Depends(require_uid)) -> dict:
    """Disconnect every watch of this account (a watch token cannot call this)."""
    return watch_pairing.revoke_all(service.firebase_service.db, uid)


@router.post("/watch-pairing/code")
def watch_pairing_code(uid: str = Depends(require_uid)) -> dict:
    if not rate_limit.WATCH_CODE_BY_UID.allow(uid, time.monotonic()):
        raise HTTPException(status_code=429, detail="too_many_attempts")
    return watch_pairing.issue_code(service.firebase_service.db, uid)


@router.post("/daily-steps")
def record_daily_steps(request: DailyStepsRequest, uid: str = Depends(require_uid)) -> dict:
    return daily_steps.record_daily_steps(
        service.firebase_service.db,
        uid,
        request.day_key,
        request.steps,
        request.source,
        request.last_health,
    )


@router.post("/crew/disband")
def disband_crew(uid: str = Depends(require_uid)) -> dict:
    return crew_membership.disband(service.firebase_service.db, uid)


@router.post("/crew/rename")
def rename_crew(request: CrewRenameRequest, uid: str = Depends(require_uid)) -> dict:
    return crew_membership.rename(service, uid, request.name, request.request_id)


@router.post("/crew/expand")
def expand_crew(request: CrewExpandRequest, uid: str = Depends(require_uid)) -> dict:
    return crew_membership.expand(service, uid, request.request_id)


@router.post("/crew/gift")
def gift_crew_items(request: CrewGiftRequest, uid: str = Depends(require_uid)) -> dict:
    return crew_membership.gift(service, uid, request.target_uid, request.request_id)


@router.post("/crew/role")
def set_crew_role(request: CrewRoleRequest, uid: str = Depends(require_uid)) -> dict:
    return crew_membership.set_role(service.firebase_service.db, uid, request.uid, request.role)


@router.get("/crew/emblem/status", response_model=CrewEmblemStatus)
def crew_emblem_status(uid: str = Depends(require_uid)) -> CrewEmblemStatus:
    return CrewEmblemStatus(**service.crew_emblem_status(uid=uid))


@router.post("/crew/emblem/purchase", response_model=SecuredActionResult)
def purchase_crew_paid_emblem(
    request: CrewEmblemPurchaseRequest,
    uid: str = Depends(require_uid),
) -> SecuredActionResult:
    return service.purchase_crew_paid_emblem(
        uid=uid, emblem_id=request.emblem_id, request_id=request.request_id
    )


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
    return service.found_crew(
        uid=uid,
        name=request.name,
        pay_with=request.pay_with,
        request_id=request.request_id,
        emblem=request.emblem,
    )


@router.post("/tournaments/create-room", response_model=CreateChallengeRoomResult)
def create_challenge_room(
    request: CreateChallengeRoomRequest,
    uid: str = Depends(require_uid),
) -> CreateChallengeRoomResult:
    return service.create_challenge_room(
        uid=uid, title=request.title, distance_km=request.distance_km
    )


@router.post("/shop/cosmetics", response_model=CosmeticCatalogView)
def cosmetics_catalog(uid: str = Depends(require_uid)) -> CosmeticCatalogView:
    catalog = service.cosmetics_catalog()
    return CosmeticCatalogView(
        season=catalog["season"],
        items=[
            CosmeticCatalogItem(
                id=row["id"],
                name=row["name"],
                category=row["category"],
                price=row["price"],
                limited=row["limited"],
                season=row["season"],
                asset=row["asset"],
                accent=row["accent"],
            )
            for row in catalog["items"]
        ],
    )


@router.post("/shop/cosmetics/equip", response_model=SecuredActionResult)
def equip_cosmetic_item(
    request: CosmeticEquipRequest,
    uid: str = Depends(require_uid),
) -> SecuredActionResult:
    return service.equip_cosmetic_item(
        uid=uid,
        item_id=request.item_id,
        request_id=request.request_id,
        equip=request.equip,
    )


@router.post("/shop/accessories/equip", response_model=SecuredActionResult)
def equip_accessory(
    request: AccessoryEquipRequest,
    uid: str = Depends(require_uid),
) -> SecuredActionResult:
    return service.equip_accessory(uid=uid, slot=request.slot, item_id=request.item_id)


@router.post("/shop/catalog", response_model=ShopCatalogView)
def shop_catalog(uid: str = Depends(require_uid)) -> ShopCatalogView:
    service.ensure_coach_plus_cpr(uid)
    return ShopCatalogView(
        items=[
            ShopCatalogItem(
                id=row["id"],
                title=row["title"],
                diamond_cost=row["diamondCost"],
                share_cost=int(row.get("shareCost") or 0),
                value_cost=int(row.get("valueCost") or 0),
            )
            for row in service.shop_catalog()
        ]
    )


@router.post("/shop/use", response_model=SecuredActionResult)
def use_shop_item(
    request: ShopPurchaseRequest,
    uid: str = Depends(require_uid),
) -> SecuredActionResult:
    return service.use_shop_item(
        uid=uid,
        item_id=request.item_id,
        request_id=request.request_id,
        friend_uid=request.friend_uid,
        activity_id=request.activity_id,
        rest_day=request.rest_day,
    )


@router.post("/web3/transfer", response_model=SecuredActionResult)
def transfer_value_to_web3(
    request: Web3TransferRequest,
    uid: str = Depends(require_uid),
) -> SecuredActionResult:
    return service.transfer_value_to_web3(uid=uid, request=request)


@router.post("/hall-of-fame/donate", response_model=SecuredActionResult)
def donate_hall_of_fame(uid: str = Depends(require_uid)) -> SecuredActionResult:
    return service.donate_hall_of_fame(uid=uid)


@router.post("/sponsorship/donate", response_model=PersonalSponsorResult)
def donate_personal_sponsor(
    request: PersonalSponsorRequest,
    uid: str = Depends(require_uid),
) -> PersonalSponsorResult:
    return service.donate_personal_sponsor(
        uid=uid,
        request_id=request.request_id,
        purpose=request.purpose,
    )


@router.post("/wallet/share-to-dia/quote", response_model=ShareToDiaView)
def quote_share_to_dia(uid: str = Depends(require_uid)) -> ShareToDiaView:
    return service.quote_share_to_dia(uid=uid)


@router.post("/wallet/share-to-dia", response_model=ShareToDiaView)
def exchange_share_to_dia(
    request: ShareToDiaRequest,
    uid: str = Depends(require_uid),
) -> ShareToDiaView:
    return service.exchange_share_to_dia(uid=uid, dia_amount=request.dia_amount)


@router.post("/wallet/dia-pack/grant", response_model=SecuredActionResult)
def grant_dia_pack(
    request: DiaPackGrantRequest,
    uid: str = Depends(require_uid),
) -> SecuredActionResult:
    return service.grant_dia_pack(
        uid=uid,
        product_id=request.product_id,
        purchase_token=request.purchase_token,
    )


@router.get("/privacy/settings")
def get_privacy_settings(uid: str = Depends(require_uid)) -> dict:
    return privacy_settings.read_settings(service.firebase_service.db, uid)


@router.post("/privacy/ai-learning")
def set_ai_learning(
    request: AiLearningRequest,
    uid: str = Depends(require_uid),
) -> dict:
    return privacy_settings.set_ai_learning(
        service.firebase_service.db, uid, request.enabled
    )


@router.post("/security/devices/register")
def register_login_device(
    request: LoginDeviceRequest,
    uid: str = Depends(require_uid),
) -> dict:
    device_id = login_devices.clean_device_id(request.device_id)
    if device_id is None:
        raise HTTPException(status_code=400, detail="invalid_device_id")
    login_devices.register_device(
        service.firebase_service.db,
        uid,
        device_id,
        model=request.model,
        os_version=request.os_version,
        app_version=request.app_version,
        fcm_token=request.fcm_token,
        notify=send_new_device_alert,
    )
    return {"status": "ok"}


@router.get("/security/devices")
def list_login_devices(
    device_id: str | None = None,
    uid: str = Depends(require_uid),
) -> dict:
    return {
        "devices": login_devices.list_devices(
            service.firebase_service.db,
            uid,
            login_devices.clean_device_id(device_id),
        )
    }


@router.post("/security/sign-out-everywhere")
def sign_out_everywhere(uid: str = Depends(require_uid)) -> dict:
    from firebase_admin import auth as firebase_auth

    login_devices.sign_out_everywhere(
        service.firebase_service.db, uid, firebase_auth.revoke_refresh_tokens
    )
    forget_sign_out_cache(uid)
    return {"status": "signed_out"}


@router.post("/appeals")
def submit_appeal(
    request: AppealRequest,
    uid: str = Depends(require_uid),
) -> dict:
    return appeals.submit_appeal(
        service.firebase_service.db,
        uid,
        activity_id=request.activity_id,
        reason_category=request.reason_category,
        reason_detail=request.reason_detail,
        proof_base64=request.proof_base64,
    )


@router.get("/integrity/nonce")
def integrity_nonce(uid: str = Depends(require_uid)) -> dict:
    return {"nonce": integrity.issue_nonce(service.firebase_service.db, uid)}


@router.post("/integrity/report")
def integrity_report(
    request: IntegrityReportRequest,
    uid: str = Depends(require_uid),
) -> dict:
    # Record-only: the result never changes what this account can do.
    return integrity.record_check(service.firebase_service.db, uid, request.token)
