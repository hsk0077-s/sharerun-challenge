from datetime import date, datetime, timedelta, timezone
from math import asin, cos, radians, sin, sqrt
import re

from fastapi import HTTPException, status
from firebase_admin import auth as firebase_auth
from google.cloud import firestore
from google.cloud.firestore_v1 import SERVER_TIMESTAMP

from app.models.secured_actions import (
    CollectDiamondBoxRequest,
    DebugTestGrantRequest,
    HarvestPedometerRequest,
    InviteCodeResult,
    JoinTournamentRequest,
    PersonalSponsorResult,
    RedeemReferralResult,
    RefundRequest,
    ShareToDiaView,
    CreateChallengeRoomResult,
    SecuredActionResult,
    SignupFreeTicketResult,
    SettleTournamentFailureRequest,
    ValidateRunRequest,
    Web3TransferRequest,
    WinnerRewardRequest,
)
from app.services.firebase_service import FirebaseService
from app.constants.economy_constants import (
    HALL_OF_FAME_DONATE_VALUE,
    PEDOMETER_HOURLY_STEP_CAP,
    REFERRAL_REDEEM_SHARE,
    REFERRAL_SHARE_LOCK_DAYS,
    REFERRAL_TRIAL_REFEREE_SHARE,
    REFERRAL_TRIAL_REFERRER_SHARE,
    SHARE_PER_DIA,
    SHARE_TO_DIA_SIGNUP_LOCK_DAYS,
    SHARE_TO_DIA_UNIT,
    SHARE_TO_DIA_WEEKLY_CAP,
    STREAK_BONUS_DIA,
    TEST_WALLET_GRANT_AMOUNT,
    TEST_WALLET_GRANT_DEBUG_CLIENT_SECRET,
    TEST_WALLET_GRANT_ELIGIBLE_FLAG,
    TEST_WALLET_GRANT_FLAG,
    TRIAL_COMPLETION_REWARD_SRV,
)
from app.models.validation_request import ValidationRequest
from app.models.validation_result import ValidationResult
from app.services.economy_service import EconomyService
from app.services.mercy_rule_service import MercyRuleService
from app.services.play_billing import (
    consume_play_product_purchase,
    dia_pack_by_id,
    purchase_token_hash,
    verify_play_product_purchase,
)
from app.services.company_tournament_config import (
    COMPANY_TOURNAMENT_CONFIG_ID,
    prize_tier_id,
    resolve_company_tournament_config,
)
from app.services.company_tournament_settlement import prize_finish_fields
from app.services.battle_pass import NOT_SPENT, purchase_battle_pass
from app.services.cosmetics import (
    NOT_SPENT as COSMETIC_NOT_SPENT,
    equip_cosmetic,
    is_cosmetic_item,
    purchase_cosmetic,
    read_cosmetics_catalog,
)
from app.services.item_price_config import (
    BATTLE_PASS_ITEM_IDS,
    COACH_ONE_POINT_ITEM_ID,
    CREW_CHEER_FLAG_ITEM_ID,
    CREW_CREATE_DIA_ID,
    CREW_CREATE_SHARE_ID,
    EXTRA_ENTRY_ITEM_ID,
    FRIEND_GHOST_ITEM_ID,
    FRIEND_GHOST_PACK_ITEM_ID,
    RUN_ACCESS_ITEM_IDS,
    SHARE_ACTIVITY_ITEM_IDS,
    SOCIAL_ITEM_IDS,
    STREAK_ITEM_IDS,
    VALUE_ITEM_IDS,
    read_item_prices,
)
from app.services.run_access_items import (
    consume_extra_entry_ticket,
    extra_entry_opens_closed,
    purchase_run_access_item,
    use_coach_one_point,
)
from app.services.social_items import (
    cheer_bonus_share,
    crew_has_cheer,
    member_crew_id,
    positive_share_reward,
    purchase_social_item,
    use_crew_cheer,
    use_friend_ghost,
)
from app.services.streak_protection import (
    CPR_ITEM_ID,
    grant_coach_plus_cpr,
    is_rest_pause,
    maybe_grant_coach_plus_cpr,
    metric_qualifies,
    purchase_streak_item,
    require_request_id,
    use_streak_item,
)
from app.services.personal_sponsor import donate_personal_sponsor as _donate_personal_sponsor
from app.services.value_items import purchase_value_item, use_value_item
from app.services.wallet_funding import (
    assign_free_balances,
    exchange_spendable,
    move_currency,
)
from app.services.running_validation_service import RunningValidationService
from app.services.share_activity_items import (
    plan_activity_share,
    purchase_share_activity_item,
    use_share_activity_item,
)


_NICKNAME_PATTERN = re.compile(r"^[가-힣a-zA-Z0-9]{2,12}$")

_COACH_PLUS_DAYS = {
    "coach_plus_monthly": 32,
    "coach_plus_yearly": 370,
}

# Client detail copy has no Firestore doc. First join writes these defaults.
# Beginner prize/donation are the shown "3만 원"; intermediate, "50만 원".
_BEGINNER_BUILTIN_ROOM = {
    "title": "1km 초보 챌린지",
    "targetDistanceKm": 1.0,
    "entryFeeShare": 30000,
    "status": "recruiting",
    "maxParticipants": 200,
    "minParticipantsBep": 100,
    "winnerRewardValue": 30000,
    "donationValue": 30000,
    "requiredTier": 1,
}
_INTERMEDIATE_BUILTIN_ROOM = {
    "title": "3km 중급 챌린지 (골드 방)",
    "targetDistanceKm": 3.0,
    "entryFeeShare": 60000,
    "status": "recruiting",
    "maxParticipants": 400,
    "minParticipantsBep": 100,
    "winnerRewardValue": 500000,
    "donationValue": 500000,
    "requiredTier": 1,
}
_BUILTIN_ROOMS = {
    "beginner-1km-room": _BEGINNER_BUILTIN_ROOM,
    "beginner-1km-room-01": _BEGINNER_BUILTIN_ROOM,
    "intermediate-3km-room": _INTERMEDIATE_BUILTIN_ROOM,
    "demo-intermediate-3km": _INTERMEDIATE_BUILTIN_ROOM,
    "crew-challenge-room": _INTERMEDIATE_BUILTIN_ROOM,
}
# PR #64: the beginner lobby stays open to every tier.
_OPEN_TIER_ROOM_IDS = frozenset({"beginner-1km-room", "beginner-1km-room-01"})


# One first-race ticket. The ledger id is the idempotency key.
SIGNUP_FREE_TICKET_COUNT = 1


def signup_free_ticket_id(uid: str) -> str:
    return f"signup_free_ticket_{uid}"


class InviteCodeCollision(Exception):
    """`referralCodes/{code}` is already owned by a different user."""


class SecuredActionService:
    _INVITE_CODE_ATTEMPTS = 8
    _REFERRAL_REDEEM_WINDOW = timedelta(days=7)

    def __init__(self, firebase_service: FirebaseService | None = None) -> None:
        self._firebase_service = firebase_service
        self._running_validation_service = RunningValidationService()
        self._economy_service = EconomyService()
        self._mercy_rule_service = MercyRuleService()

    def validate_run(
        self,
        uid: str,
        request: ValidateRunRequest,
    ) -> ValidationResult:
        validation_request = ValidationRequest(
            activity_id=request.activity_id,
            user_id=uid,
            distance_km=request.distance_km,
            duration_seconds=request.duration_seconds,
            heart_rates=request.heart_rates,
            cadence_spm=request.cadence_spm,
            gyro_stability_score=request.gyro_stability_score,
        )
        result = self._running_validation_service.validate(validation_request)

        transaction = self.firebase_service.db.transaction()
        activity_ref = self.firebase_service.db.collection("activities").document(
            request.activity_id
        )
        user_ref = self.firebase_service.db.collection("users").document(uid)
        # Module wrapper: a method decorator does not bind `self`, so the
        # transaction body never ran. Same shape as referral redeem.
        return _commit_validation_tx(
            transaction, self, uid, request, result, activity_ref, user_ref
        )

    def claim_signup_reward(self, uid: str) -> SecuredActionResult:
        transaction = self.firebase_service.db.transaction()
        user_ref = self.firebase_service.db.collection("users").document(uid)
        return _commit_signup_reward_tx(transaction, self, uid, user_ref)

    def ensure_signup_free_ticket(self, uid: str) -> SignupFreeTicketResult:
        """Grant the one signup ticket if this account has never received it."""
        transaction = self.firebase_service.db.transaction()
        user_ref = self.firebase_service.db.collection("users").document(uid)
        return _commit_signup_free_ticket_tx(transaction, self, uid, user_ref)

    def claim_streak_bonus(self, uid: str) -> SecuredActionResult:
        transaction = self.firebase_service.db.transaction()
        user_ref = self.firebase_service.db.collection("users").document(uid)
        return _commit_streak_bonus_tx(transaction, self, uid, user_ref)

    def claim_trial_reward(self, uid: str) -> SecuredActionResult:
        transaction = self.firebase_service.db.transaction()
        user_ref = self.firebase_service.db.collection("users").document(uid)
        return _commit_trial_reward_tx(transaction, self, uid, user_ref)

    def apply_referral_code(
        self,
        uid: str,
        referral_code: str,
    ) -> SecuredActionResult:
        transaction = self.firebase_service.db.transaction()
        user_ref = self.firebase_service.db.collection("users").document(uid)
        return self._apply_referral_code_tx(
            transaction, uid, referral_code.strip().upper(), user_ref
        )

    def get_or_create_invite_code(self, uid: str) -> InviteCodeResult:
        user_ref = self.firebase_service.db.collection("users").document(uid)
        for _ in range(self._INVITE_CODE_ATTEMPTS):
            code = self._economy_service.generate_invite_code()
            transaction = self.firebase_service.db.transaction()
            try:
                issued = self._commit_invite_code(transaction, uid, user_ref, code)
            except InviteCodeCollision:
                continue
            return InviteCodeResult(referral_code=issued)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Could not allocate a unique invite code.",
        )

    def redeem_referral_code(self, uid: str, code: str) -> RedeemReferralResult:
        # Records who invited this user and credits SHARE. Does not credit SRV.
        normalized = self._normalize_referral_code(code)
        if normalized is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="invalid",
            )
        created_at = self._auth_account_created_at(uid)
        user_ref = self.firebase_service.db.collection("users").document(uid)
        transaction = self.firebase_service.db.transaction()
        return self._commit_redeem_referral(
            transaction, uid, user_ref, normalized, created_at
        )

    def _commit_redeem_referral(
        self,
        transaction,
        uid: str,
        user_ref,
        code: str,
        created_at: datetime | None,
    ) -> RedeemReferralResult:
        return _commit_redeem_referral_tx(
            transaction, self, uid, user_ref, code, created_at
        )

    @staticmethod
    def _normalize_referral_code(code: str | None) -> str | None:
        normalized = (code or "").strip().upper()
        if not normalized or len(normalized) > 32 or not normalized.isalnum():
            return None
        return normalized

    def _auth_account_created_at(self, uid: str) -> datetime | None:
        # Auth creation time is not client-writable. users.createdAt is
        # allowed on client create, so it is not the 7-day clock.
        try:
            auth_user = firebase_auth.get_user(uid)
        except firebase_auth.UserNotFoundError as error:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found.",
            ) from error
        metadata = getattr(auth_user, "user_metadata", None)
        millis = getattr(metadata, "creation_timestamp", None) if metadata else None
        if not millis:
            return None
        return datetime.fromtimestamp(int(millis) / 1000, tz=timezone.utc)

    def _apply_redeem_referral(
        self,
        transaction,
        uid: str,
        user_ref,
        code: str,
        created_at: datetime | None,
        now: datetime | None = None,
    ) -> RedeemReferralResult:
        normalized = self._normalize_referral_code(code)
        if normalized is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="invalid",
            )

        user_snapshot = user_ref.get(transaction=transaction)
        if not user_snapshot.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found.",
            )

        code_ref = self.firebase_service.db.collection("referralCodes").document(
            normalized
        )
        code_snapshot = code_ref.get(transaction=transaction)
        if not code_snapshot.exists:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="invalid",
            )
        owner = (code_snapshot.to_dict() or {}).get("uid")
        if not isinstance(owner, str) or not owner.strip():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="invalid",
            )
        if owner == uid:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="self",
            )

        user = user_snapshot.to_dict() or {}
        economy = user.get("economy") or {}
        referred_by = economy.get("referredBy")
        if isinstance(referred_by, str) and referred_by.strip():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="already",
            )

        current = now or datetime.now(timezone.utc)
        if created_at is not None:
            created = created_at
            if created.tzinfo is None:
                created = created.replace(tzinfo=timezone.utc)
            if current.tzinfo is None:
                current = current.replace(tzinfo=timezone.utc)
            if current - created > self._REFERRAL_REDEEM_WINDOW:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="expired",
                )

        trial_complete = bool(economy.get("trialMilestoneRewardClaimed")) or (
            self._economy_service.trial_milestone_reached(
                int(economy.get("trialRunCount") or 0)
            )
        )
        payouts = self._plan_redeem_referral_payouts(
            transaction,
            referee_uid=uid,
            referee_ref=user_ref,
            referrer_uid=owner,
            include_trial=trial_complete,
        )
        transaction.update(
            user_ref,
            {
                "economy.referredBy": owner,
                "economy.referredByCode": normalized,
                "economy.referredAt": SERVER_TIMESTAMP,
                "updatedAt": SERVER_TIMESTAMP,
            },
        )
        transaction.set(
            code_ref.collection("referrals").document(uid),
            {"createdAt": SERVER_TIMESTAMP},
        )
        transaction.update(code_ref, {"redeemCount": firestore.Increment(1)})
        self._write_referral_payouts(transaction, payouts)
        return RedeemReferralResult(referred_by=owner, code=normalized)

    def _commit_invite_code(self, transaction, uid: str, user_ref, code: str) -> str:
        return _commit_invite_code_tx(transaction, self, uid, user_ref, code)

    def purchase_shop_item(
        self,
        uid: str,
        item_id: str,
        request_id: str | None = None,
    ) -> SecuredActionResult:
        transaction = self.firebase_service.db.transaction()
        user_ref = self.firebase_service.db.collection("users").document(uid)
        if item_id in STREAK_ITEM_IDS:
            return _commit_streak_purchase_tx(
                transaction,
                self,
                uid,
                item_id,
                require_request_id(request_id),
                user_ref,
            )
        if item_id in RUN_ACCESS_ITEM_IDS:
            return _commit_run_access_purchase_tx(
                transaction,
                self,
                uid,
                item_id,
                require_request_id(request_id),
                user_ref,
            )
        if item_id in SOCIAL_ITEM_IDS:
            return _commit_social_purchase_tx(
                transaction,
                self,
                uid,
                item_id,
                require_request_id(request_id),
                user_ref,
            )
        if item_id in BATTLE_PASS_ITEM_IDS:
            return _commit_battle_pass_purchase_tx(
                transaction,
                self,
                uid,
                item_id,
                require_request_id(request_id),
                user_ref,
            )
        if item_id in SHARE_ACTIVITY_ITEM_IDS:
            return _commit_share_activity_purchase_tx(
                transaction,
                self,
                uid,
                item_id,
                require_request_id(request_id),
                user_ref,
            )
        if item_id in VALUE_ITEM_IDS:
            return _commit_value_purchase_tx(
                transaction,
                self,
                uid,
                item_id,
                require_request_id(request_id),
                user_ref,
            )
        if item_id not in self.SHOP_CATALOG and is_cosmetic_item(
            self.firebase_service.db, item_id
        ):
            return _commit_cosmetic_purchase_tx(
                transaction,
                self,
                uid,
                item_id,
                require_request_id(request_id),
                user_ref,
            )
        return _commit_shop_tx(transaction, self, uid, item_id, user_ref)

    def cosmetics_catalog(self) -> dict:
        return read_cosmetics_catalog(self.firebase_service.db)

    def equip_cosmetic_item(
        self,
        uid: str,
        item_id: str,
        request_id: str,
        equip: bool,
    ) -> SecuredActionResult:
        transaction = self.firebase_service.db.transaction()
        user_ref = self.firebase_service.db.collection("users").document(uid)
        return _commit_cosmetic_equip_tx(
            transaction,
            self,
            uid,
            item_id,
            require_request_id(request_id),
            user_ref,
            equip,
        )

    def ensure_coach_plus_cpr(self, uid: str) -> None:
        maybe_grant_coach_plus_cpr(self, uid)

    def commit_cpr_grant(self, transaction, uid: str, user_ref) -> None:
        _commit_cpr_grant_tx(transaction, self, uid, user_ref)

    def grant_crew_items(self, uid: str) -> SecuredActionResult:
        transaction = self.firebase_service.db.transaction()
        user_ref = self.firebase_service.db.collection("users").document(uid)
        return _commit_crew_gift_tx(transaction, self, uid, user_ref)

    def spend_crew_action(self, uid: str, action: str) -> SecuredActionResult:
        transaction = self.firebase_service.db.transaction()
        user_ref = self.firebase_service.db.collection("users").document(uid)
        return _commit_crew_spend_tx(transaction, self, uid, action, user_ref)

    def change_nickname(self, uid: str, nickname: str) -> SecuredActionResult:
        compact = re.sub(r"\s+", "", nickname.strip())
        if _NICKNAME_PATTERN.fullmatch(compact) is None:
            raise HTTPException(status_code=400, detail="Invalid nickname.")
        transaction = self.firebase_service.db.transaction()
        user_ref = self.firebase_service.db.collection("users").document(uid)
        return _commit_nickname_tx(transaction, self, uid, compact, user_ref)

    def found_crew(
        self,
        uid: str,
        name: str,
        pay_with: str,
        request_id: str,
    ) -> SecuredActionResult:
        if pay_with not in {"share", "dia"}:
            raise HTTPException(status_code=400, detail="Invalid crew payment.")
        transaction = self.firebase_service.db.transaction()
        user_ref = self.firebase_service.db.collection("users").document(uid)
        crew_ref = self.firebase_service.db.collection("crews").document()
        return _commit_crew_found_tx(
            transaction,
            self,
            uid,
            name,
            pay_with,
            require_request_id(request_id),
            user_ref,
            crew_ref,
        )

    def create_challenge_room(
        self, uid: str, title: str, distance_km: int
    ) -> CreateChallengeRoomResult:
        transaction = self.firebase_service.db.transaction()
        user_ref = self.firebase_service.db.collection("users").document(uid)
        room_ref = self.firebase_service.db.collection("tournaments").document()
        return _commit_create_room_tx(
            transaction, self, uid, title, distance_km, user_ref, room_ref
        )

    def use_shop_item(
        self,
        uid: str,
        item_id: str,
        request_id: str | None = None,
        friend_uid: str | None = None,
        activity_id: str | None = None,
        rest_day: str | None = None,
    ) -> SecuredActionResult:
        if item_id == CPR_ITEM_ID:
            self.ensure_coach_plus_cpr(uid)
        if item_id in BATTLE_PASS_ITEM_IDS:
            raise HTTPException(status_code=400, detail=NOT_SPENT)
        transaction = self.firebase_service.db.transaction()
        user_ref = self.firebase_service.db.collection("users").document(uid)
        if item_id in STREAK_ITEM_IDS:
            return _commit_streak_use_tx(
                transaction,
                self,
                uid,
                item_id,
                require_request_id(request_id),
                user_ref,
            )
        if item_id == COACH_ONE_POINT_ITEM_ID:
            return _commit_coach_one_point_use_tx(
                transaction,
                self,
                uid,
                require_request_id(request_id),
                user_ref,
            )
        if item_id in RUN_ACCESS_ITEM_IDS:
            raise HTTPException(
                status_code=400,
                detail="Extra entry ticket is spent by joining a race.",
            )
        if item_id == FRIEND_GHOST_ITEM_ID:
            return _commit_friend_ghost_use_tx(
                transaction,
                self,
                uid,
                require_request_id(request_id),
                friend_uid,
                activity_id,
                user_ref,
            )
        if item_id == CREW_CHEER_FLAG_ITEM_ID:
            return _commit_crew_cheer_use_tx(
                transaction,
                self,
                uid,
                require_request_id(request_id),
                user_ref,
            )
        if item_id == FRIEND_GHOST_PACK_ITEM_ID:
            raise HTTPException(
                status_code=400,
                detail="Friend ghost pack is spent as single uses.",
            )
        if item_id in SHARE_ACTIVITY_ITEM_IDS:
            return _commit_share_activity_use_tx(
                transaction,
                self,
                uid,
                item_id,
                require_request_id(request_id),
                user_ref,
            )
        if item_id in VALUE_ITEM_IDS:
            return _commit_value_use_tx(
                transaction,
                self,
                uid,
                item_id,
                require_request_id(request_id),
                user_ref,
                rest_day,
            )
        return _commit_use_shop_tx(transaction, self, uid, item_id, user_ref)

    def transfer_value_to_web3(
        self,
        uid: str,
        request: Web3TransferRequest,
    ) -> SecuredActionResult:
        # On-chain transfer is not live. Do not open a transaction or debit VALUE.
        del uid, request
        return SecuredActionResult(
            accepted=False,
            status="coming_soon",
            reason="준비 중",
        )

    def quote_share_to_dia(self, uid: str) -> ShareToDiaView:
        user_ref = self.firebase_service.db.collection("users").document(uid)
        snapshot = user_ref.get()
        if not snapshot.exists:
            raise HTTPException(status_code=404, detail="User not found.")
        return self._share_to_dia_view(uid, snapshot.to_dict() or {})

    def exchange_share_to_dia(self, uid: str, dia_amount: int) -> ShareToDiaView:
        transaction = self.firebase_service.db.transaction()
        user_ref = self.firebase_service.db.collection("users").document(uid)
        return _commit_share_to_dia_tx(
            transaction, self, uid, dia_amount, user_ref
        )

    def grant_dia_pack(
        self,
        uid: str,
        product_id: str,
        purchase_token: str,
    ) -> SecuredActionResult:
        pack = dia_pack_by_id(product_id)
        if pack is None:
            raise HTTPException(status_code=400, detail="Unknown DIA pack.")
        verify_play_product_purchase(product_id, purchase_token)
        token_hash = purchase_token_hash(purchase_token)
        transaction = self.firebase_service.db.transaction()
        user_ref = self.firebase_service.db.collection("users").document(uid)
        purchase_ref = self.firebase_service.db.collection("playPurchases").document(
            token_hash
        )
        result = _commit_dia_pack_tx(
            transaction,
            self,
            uid,
            pack,
            user_ref,
            purchase_ref,
        )
        if result.status in {"granted", "already_granted"}:
            consume_play_product_purchase(product_id, purchase_token)
        return result

    def donate_hall_of_fame(self, uid: str) -> SecuredActionResult:
        transaction = self.firebase_service.db.transaction()
        user_ref = self.firebase_service.db.collection("users").document(uid)
        return _commit_hall_of_fame_donate_tx(transaction, self, uid, user_ref)

    def donate_personal_sponsor(
        self,
        uid: str,
        request_id: str,
        purpose: str,
    ) -> PersonalSponsorResult:
        transaction = self.firebase_service.db.transaction()
        user_ref = self.firebase_service.db.collection("users").document(uid)
        return _commit_personal_sponsor_tx(
            transaction,
            self,
            uid,
            request_id,
            purpose,
            user_ref,
        )

    def activate_coach_plus(self, uid: str, product_id: str) -> SecuredActionResult:
        if product_id not in _COACH_PLUS_DAYS:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Unknown Coach+ product.",
            )
        transaction = self.firebase_service.db.transaction()
        user_ref = self.firebase_service.db.collection("users").document(uid)
        return _commit_coach_plus_tx(transaction, self, product_id, user_ref)

    def _activate_coach_plus_tx(
        self,
        transaction,
        product_id: str,
        user_ref,
    ) -> SecuredActionResult:
        user_snapshot = user_ref.get(transaction=transaction)
        if not user_snapshot.exists:
            raise HTTPException(status_code=404, detail="User not found.")
        until = datetime.now(timezone.utc) + timedelta(
            days=_COACH_PLUS_DAYS[product_id]
        )
        transaction.update(
            user_ref,
            {
                "coachPlus": {
                    "productId": product_id,
                    "activeUntil": until.isoformat(),
                },
                "updatedAt": SERVER_TIMESTAMP,
            },
        )
        return SecuredActionResult(
            accepted=True,
            status="coach_plus_active",
            reason="Coach+ entitlement saved. Wallet was not changed.",
        )

    def _persist_validation_tx(
        self,
        transaction,
        uid: str,
        request: ValidateRunRequest,
        result: ValidationResult,
        activity_ref,
        user_ref,
    ) -> ValidationResult:
        activity_snapshot = activity_ref.get(transaction=transaction)
        if activity_snapshot.exists:
            activity = activity_snapshot.to_dict() or {}
            if activity.get("userId") != uid:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Activity belongs to another user.",
                )
            if activity.get("validationFinalized") is True:
                return self._validation_result_from_activity(activity)

        user_snapshot = user_ref.get(transaction=transaction)
        user = user_snapshot.to_dict() or {} if user_snapshot.exists else {}
        economy = user.get("economy") or {}
        today = self._economy_service.kst_today_key()
        daily_mining = self._economy_service.normalize_daily_mining(
            user.get("dailyMining"), today
        )

        reward_tokens = 0
        counted_km = 0.0
        daily_cap_applied = False
        trial_run_count = int(economy.get("trialRunCount") or 0)
        trial_milestone_reached = bool(economy.get("trialMilestoneRewardClaimed"))

        if result.verified:
            allowance = self._economy_service.compute_mining_reward(
                distance_km=request.distance_km,
                daily_earned_km=float(daily_mining.get("earnedKm") or 0),
                daily_earned_tokens=int(daily_mining.get("earnedSrvTokens") or 0),
            )
            reward_tokens = allowance.reward_tokens
            counted_km = allowance.counted_km
            daily_cap_applied = (
                allowance.daily_cap_reached
                or counted_km < request.distance_km
                or reward_tokens < result.value_token_reward
            )

            if self._economy_service.should_count_trial_run(economy):
                trial_run_count = self._economy_service.next_trial_run_count(economy)

        # Reads before the activity write. 5th verified run is the trial trigger.
        referral_payouts: list[dict] = []
        referred_by = economy.get("referredBy")
        if (
            result.verified
            and self._economy_service.should_count_trial_run(economy)
            and self._economy_service.trial_milestone_reached(trial_run_count)
            and isinstance(referred_by, str)
            and referred_by.strip()
            and referred_by != uid
        ):
            referral_payouts = self._plan_trial_referral_payouts(
                transaction,
                referee_uid=uid,
                referee_ref=user_ref,
                referrer_uid=referred_by,
            )

        crew_id = member_crew_id(user) if user_snapshot.exists else ""
        cheer_crew = None
        if crew_id:
            crew_snapshot = (
                self.firebase_service.db.collection("crews")
                .document(crew_id)
                .get(transaction=transaction)
            )
            if crew_snapshot.exists:
                cheer_crew = crew_snapshot.to_dict() or {}
        tournament_id = (request.tournament_id or "").strip()
        race_share = 0
        prize_finish = None
        participant_ref = None
        if tournament_id and "/" not in tournament_id:
            tournament_ref = self.firebase_service.db.collection("tournaments").document(
                tournament_id
            )
            tournament_snapshot = tournament_ref.get(transaction=transaction)
            if tournament_snapshot.exists:
                tournament_doc = tournament_snapshot.to_dict() or {}
                race_share = positive_share_reward(tournament_doc.get("shareReward"))
                if result.verified and prize_tier_id(tournament_doc) is not None:
                    participant_ref = tournament_ref.collection("participants").document(
                        uid
                    )
                    participant_snapshot = participant_ref.get(transaction=transaction)
                    if participant_snapshot.exists:
                        prize_finish = prize_finish_fields(
                            tournament_doc,
                            participant_snapshot.to_dict() or {},
                            distance_km=request.distance_km,
                            duration_seconds=request.duration_seconds,
                            activity_id=activity_ref.id,
                        )
        cheer_ledger_ref = self.firebase_service.db.collection(
            "walletTransactions"
        ).document(f"crew_cheer_{activity_ref.id}")
        cheer_already = cheer_ledger_ref.get(transaction=transaction).exists

        route = [
            point.model_dump() if hasattr(point, "model_dump") else point.dict()
            for point in request.gps_route
        ]
        average_pace = (
            None
            if request.distance_km <= 0
            else request.duration_seconds / request.distance_km
        )

        transaction.set(
            activity_ref,
            {
                "userId": uid,
                "distanceKm": request.distance_km,
                "durationSeconds": request.duration_seconds,
                "averagePaceSecondsPerKm": average_pace,
                "gyroStabilityScore": request.gyro_stability_score,
                "gpsRoute": route,
                "jenaVerified": result.verified,
                "jenaDecision": result.decision,
                "jenaReason": result.reason,
                "valueTokenReward": reward_tokens,
                "dailyCapApplied": daily_cap_applied,
                "dailyCountedKm": counted_km,
                "validationFinalized": True,
                "effortValueMinted": bool(result.verified and reward_tokens > 0),
                "depositForfeited": bool(result.forfeit_deposit),
                "sensitiveArraysStored": False,
                "completedAt": SERVER_TIMESTAMP,
                "updatedAt": SERVER_TIMESTAMP,
            },
            merge=True,
        )

        user_updates: dict = {"updatedAt": SERVER_TIMESTAMP}
        economy_updates: dict = {}

        if result.verified and reward_tokens > 0:
            self._credit_value_tx(
                transaction,
                uid=uid,
                user_ref=user_ref,
                amount=reward_tokens,
                tx_type="effort_value_mint",
                extra_fields={"activityId": activity_ref.id},
            )
            daily_mining = {
                "dateKey": today,
                "earnedKm": float(daily_mining.get("earnedKm") or 0) + counted_km,
                "earnedSrvTokens": int(daily_mining.get("earnedSrvTokens") or 0)
                + reward_tokens,
            }
            user_updates["dailyMining"] = daily_mining

        if result.verified and self._economy_service.should_count_trial_run(economy):
            economy_updates["trialRunCount"] = trial_run_count
            if self._economy_service.trial_milestone_reached(trial_run_count):
                trial_milestone_reached = True
                economy_updates["trialMilestoneRewardClaimed"] = True
                economy_updates["firstTierGranted"] = True
                self._credit_value_tx(
                    transaction,
                    uid=uid,
                    user_ref=user_ref,
                    amount=self._economy_service.trial_completion_reward_amount(),
                    tx_type="trial_milestone_reward",
                )
                user_updates["tier"] = max(int(user.get("tier") or 1), 1)
                if referral_payouts:
                    self._write_referral_payouts(transaction, referral_payouts)

        if result.verified:
            economy_updates["lastVerifiedRunWeek"] = self._economy_service.kst_week_key()

        if economy_updates:
            user_updates["economy"] = {**economy, **economy_updates}

        if len(user_updates) > 1:
            transaction.update(user_ref, user_updates)

        if result.forfeit_deposit:
            self._forfeit_active_deposit_tx(transaction, uid, user_ref, activity_ref.id)

        cheer_bonus = 0
        if (
            result.verified
            and user_snapshot.exists
            and not cheer_already
            and crew_has_cheer(cheer_crew, today)
        ):
            cheer_bonus = cheer_bonus_share(race_share)
        if cheer_bonus > 0:
            wallet = user.get("wallet") or {}
            moved = move_currency(wallet, share=cheer_bonus)
            transaction.update(
                user_ref,
                {**moved["updates"], "updatedAt": SERVER_TIMESTAMP},
            )
            transaction.set(
                cheer_ledger_ref,
                {
                    "uid": uid,
                    "type": "crew_cheer_share",
                    "shareAmount": cheer_bonus,
                    "baseShare": race_share,
                    "bonusPercent": 10,
                    "crewId": crew_id,
                    "tournamentId": tournament_id,
                    "activityId": activity_ref.id,
                    "createdAt": SERVER_TIMESTAMP,
                    **moved["ledger"],
                },
            )

        if prize_finish is not None and participant_ref is not None:
            transaction.update(
                participant_ref,
                {**prize_finish, "updatedAt": SERVER_TIMESTAMP},
            )

        return ValidationResult(
            verified=result.verified,
            decision=result.decision,
            reason=result.reason,
            value_token_reward=reward_tokens,
            daily_cap_applied=daily_cap_applied,
            trial_run_count=trial_run_count if result.verified else None,
            trial_milestone_reached=trial_milestone_reached,
        )

    SHOP_CATALOG: dict[str, dict] = {
        "record_cpr_ticket": {
            "title": "기록 심폐소생권",
            "diamondCost": 12,
        },
        "record_safe_guard": {
            "title": "기록 마감 세이프 가드",
            "diamondCost": 8,
        },
        "coach_one_point_ticket": {
            "title": "코치 원포인트권",
            "diamondCost": 5,
        },
        "extra_entry_ticket": {
            "title": "추가 참가권",
            "diamondCost": 10,
        },
        "extra_entry_ticket_3pack": {
            "title": "추가 참가권 3장",
            "diamondCost": 25,
        },
        "friend_ghost_pace": {
            "title": "친구 고스트 페이스",
            "diamondCost": 5,
        },
        "friend_ghost_pace_10pack": {
            "title": "친구 고스트 10회",
            "diamondCost": 40,
        },
        "crew_cheer_flag": {
            "title": "크루 응원 깃발",
            "diamondCost": 15,
        },
        "ghost_pace_match": {
            "title": "고스트 페이스 매칭",
            "diamondCost": 8,
        },
        "battle_run_pass": {
            "title": "배틀런 챌린지 패스",
            "diamondCost": 120,
        },
        "battle_run_pass_plus": {
            "title": "배틀런 패스+",
            "diamondCost": 200,
        },
        "boost_run": {
            "title": "부스트 런",
            "diamondCost": 0,
        },
        "step_incubator": {
            "title": "만보기 부화기",
            "diamondCost": 0,
        },
        "rest_day_ticket": {
            "title": "휴식일 지정권",
            "diamondCost": 0,
        },
        "donation_match": {
            "title": "기부 매칭권",
            "diamondCost": 0,
        },
    }

    def shop_catalog(self) -> list[dict]:
        prices = read_item_prices(self.firebase_service.db)
        rows = []
        for item_id, item in self.SHOP_CATALOG.items():
            if item_id in SHARE_ACTIVITY_ITEM_IDS:
                rows.append(
                    {
                        "id": item_id,
                        "title": item["title"],
                        "diamondCost": 0,
                        "shareCost": int(prices[item_id]),
                        "valueCost": 0,
                    }
                )
                continue
            if item_id in VALUE_ITEM_IDS:
                rows.append(
                    {
                        "id": item_id,
                        "title": item["title"],
                        "diamondCost": 0,
                        "shareCost": 0,
                        "valueCost": int(prices[item_id]),
                    }
                )
                continue
            rows.append(
                {
                    "id": item_id,
                    "title": item["title"],
                    "diamondCost": int(prices.get(item_id, item["diamondCost"])),
                    "shareCost": 0,
                    "valueCost": 0,
                }
            )
        return rows

    # Crew prices live here. The client does not send an amount.
    CREW_GIFT_DIA = 30
    CREW_SPENDS = {
        "profile": ("diamond", 100, "crew_profile_change"),
        "pass": ("diamond", 50, "crew_challenge_pass"),
        "expand": ("diamond", 300, "crew_member_expand"),
        "deposit": ("share", 10000, "crew_deposit"),
    }
    NICKNAME_CHANGE_DIA = 100
    CREW_GIFT_ITEMS = (
        ("record_cpr_ticket", "기록 심폐소생권"),
        ("record_safe_guard", "기록 마감 세이프 가드"),
    )

    def _credit_value_tx(
        self,
        transaction,
        *,
        uid: str,
        user_ref,
        amount: int,
        tx_type: str,
        extra_fields: dict | None = None,
    ) -> None:
        if amount <= 0:
            return
        tx_ref = self.firebase_service.db.collection("walletTransactions").document()
        transaction.update(
            user_ref,
            {
                "wallet.valueTokenBalance": firestore.Increment(amount),
                "updatedAt": SERVER_TIMESTAMP,
            },
        )
        payload = {
            "uid": uid,
            "type": tx_type,
            "valueAmount": amount,
            "createdAt": SERVER_TIMESTAMP,
        }
        if extra_fields:
            payload.update(extra_fields)
        transaction.set(tx_ref, payload)

    def _debit_value_tx(
        self,
        transaction,
        *,
        uid: str,
        user_ref,
        amount: int,
        tx_type: str,
        extra_fields: dict | None = None,
    ) -> None:
        if amount <= 0:
            return
        user_snapshot = user_ref.get(transaction=transaction)
        user = user_snapshot.to_dict() or {}
        wallet = user.get("wallet") or {}
        balance = int(wallet.get("valueTokenBalance") or 0)
        if balance < amount:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Insufficient SRV (Value Token) balance.",
            )
        tx_ref = self.firebase_service.db.collection("walletTransactions").document()
        transaction.update(
            user_ref,
            {
                "wallet.valueTokenBalance": balance - amount,
                "updatedAt": SERVER_TIMESTAMP,
            },
        )
        payload = {
            "uid": uid,
            "type": tx_type,
            "valueAmount": -amount,
            "createdAt": SERVER_TIMESTAMP,
        }
        if extra_fields:
            payload.update(extra_fields)
        transaction.set(tx_ref, payload)

    def _forfeit_active_deposit_tx(
        self,
        transaction,
        uid: str,
        user_ref,
        activity_id: str,
    ) -> None:
        query = (
            self.firebase_service.db.collection_group("participants")
            .where("uid", "==", uid)
            .where("status", "==", "joined")
        )
        participant_snapshots = list(transaction.get(query))
        total_forfeited = 0
        charity = "UNICEF"

        for snapshot in participant_snapshots:
            if not snapshot.exists:
                continue
            participant = snapshot.to_dict() or {}
            if participant.get("depositForfeited"):
                continue
            deposit = int(participant.get("diamondDeposit") or 0)
            if deposit <= 0:
                continue
            charity = participant.get("selectedCharity") or charity
            total_forfeited += deposit
            transaction.update(
                snapshot.reference,
                {
                    "status": "forfeited_fraud",
                    "depositForfeited": True,
                    "forfeitedAt": SERVER_TIMESTAMP,
                    "forfeitActivityId": activity_id,
                },
            )

        if total_forfeited <= 0:
            return

        user_snapshot = user_ref.get(transaction=transaction)
        user = user_snapshot.to_dict() or {}
        wallet = user.get("wallet") or {}
        donation = int(wallet.get("totalDonationValue") or 0)
        transaction.update(
            user_ref,
            {
                "wallet.totalDonationValue": donation + total_forfeited,
                "updatedAt": SERVER_TIMESTAMP,
            },
        )
        tx_ref = self.firebase_service.db.collection("walletTransactions").document()
        transaction.set(
            tx_ref,
            {
                "uid": uid,
                "type": "deposit_forfeiture_fraud",
                "diamondAmount": total_forfeited,
                "charityTarget": charity,
                "activityId": activity_id,
                "createdAt": SERVER_TIMESTAMP,
            },
        )

    def _share_to_dia_view(
        self,
        uid: str,
        user: dict,
        *,
        dia_amount: int | None = None,
        now: datetime | None = None,
    ) -> ShareToDiaView:
        current = now or datetime.now(timezone.utc)
        share, diamonds, value = self._wallet_balances(user)
        wallet = user.get("wallet") or {}
        spendable, locked = exchange_spendable(wallet, current)
        week = self._economy_service.kst_week_key(current)
        used = (
            int(user.get("shareToDiaWeekDia") or 0)
            if user.get("shareToDiaWeekKey") == week
            else 0
        )
        remaining = max(0, SHARE_TO_DIA_WEEKLY_CAP - used)
        reason = self._share_to_dia_lock_reason(
            uid,
            user,
            spendable=spendable,
            locked_share=locked,
            remaining=remaining,
            dia_amount=dia_amount,
            now=current,
        )
        return ShareToDiaView(
            accepted=reason is None,
            status="quote" if dia_amount is None else "blocked",
            reason=reason or "SHARE를 DIA로 교환할 수 있습니다.",
            rate_share_per_dia=SHARE_PER_DIA,
            unit_dia=SHARE_TO_DIA_UNIT,
            weekly_cap_dia=SHARE_TO_DIA_WEEKLY_CAP,
            remaining_dia=remaining,
            spendable_share=spendable,
            locked_share=locked,
            lock_reason=reason,
            share_balance=share,
            diamond_balance=diamonds,
            value_token_balance=value,
        )

    def _share_to_dia_lock_reason(
        self,
        uid: str,
        user: dict,
        *,
        spendable: int,
        locked_share: int,
        remaining: int,
        dia_amount: int | None,
        now: datetime,
    ) -> str | None:
        created = self._auth_account_created_at(uid)
        if created is None or now - created < timedelta(
            days=SHARE_TO_DIA_SIGNUP_LOCK_DAYS
        ):
            return "가입 후 7일이 지나야 교환할 수 있습니다."
        try:
            self._ensure_email_verified(uid)
        except HTTPException:
            return "이메일 인증이 필요합니다."
        economy = user.get("economy") or {}
        if economy.get("lastVerifiedRunWeek") != self._economy_service.kst_week_key(
            now
        ):
            return "이번 주 검증 러닝 1회 후 교환할 수 있습니다."
        if remaining <= 0:
            return "이번 주 교환 한도 20 DIA를 모두 사용했습니다."
        if dia_amount is None:
            unit_cost = SHARE_PER_DIA * SHARE_TO_DIA_UNIT
            if spendable < unit_cost and locked_share > 0:
                return "추천 보상 SHARE는 받은 날부터 30일 동안 교환할 수 없습니다."
            if spendable < unit_cost:
                return "교환 가능한 SHARE가 부족합니다."
            return None
        if dia_amount % SHARE_TO_DIA_UNIT != 0:
            return "DIA는 10개 단위로 교환합니다."
        if dia_amount > remaining:
            return "이번 주 교환 한도를 초과했습니다."
        cost = dia_amount * SHARE_PER_DIA
        if spendable < cost and locked_share > 0 and spendable + locked_share >= cost:
            return "추천 보상 SHARE는 받은 날부터 30일 동안 교환할 수 없습니다."
        if spendable < cost:
            return "교환 가능한 SHARE가 부족합니다."
        return None

    def _exchange_share_to_dia_tx(
        self,
        transaction,
        uid: str,
        dia_amount: int,
        user_ref,
    ) -> ShareToDiaView:
        # DIA is not transferable between accounts. This only converts SHARE.
        snapshot = user_ref.get(transaction=transaction)
        if not snapshot.exists:
            raise HTTPException(status_code=404, detail="User not found.")
        user = snapshot.to_dict() or {}
        now = datetime.now(timezone.utc)
        view = self._share_to_dia_view(uid, user, dia_amount=dia_amount, now=now)
        if view.lock_reason:
            raise HTTPException(status_code=400, detail=view.lock_reason)
        wallet = user.get("wallet") or {}
        cost = dia_amount * SHARE_PER_DIA
        moved = move_currency(
            wallet,
            share=-cost,
            diamond=dia_amount,
            for_exchange=True,
            now=now,
        )
        week = self._economy_service.kst_week_key(now)
        used = view.weekly_cap_dia - view.remaining_dia
        tx_ref = self.firebase_service.db.collection("walletTransactions").document()
        transaction.update(
            user_ref,
            {
                **moved["updates"],
                "shareToDiaWeekKey": week,
                "shareToDiaWeekDia": used + dia_amount,
                "updatedAt": SERVER_TIMESTAMP,
            },
        )
        transaction.set(
            tx_ref,
            {
                "uid": uid,
                "type": "share_to_dia",
                "shareAmount": -cost,
                "diamondAmount": dia_amount,
                "weekKey": week,
                "createdAt": SERVER_TIMESTAMP,
                **moved["ledger"],
            },
        )
        share, diamonds, value = self._wallet_balances({"wallet": wallet})
        return ShareToDiaView(
            accepted=True,
            status="exchanged",
            reason=f"{cost} SHARE를 {dia_amount} DIA로 교환했습니다.",
            rate_share_per_dia=SHARE_PER_DIA,
            unit_dia=SHARE_TO_DIA_UNIT,
            weekly_cap_dia=SHARE_TO_DIA_WEEKLY_CAP,
            remaining_dia=view.remaining_dia - dia_amount,
            spendable_share=max(0, view.spendable_share - cost),
            locked_share=view.locked_share,
            lock_reason=None,
            share_balance=share,
            diamond_balance=diamonds,
            value_token_balance=value,
        )

    def _grant_dia_pack_tx(
        self,
        transaction,
        uid: str,
        pack: dict,
        user_ref,
        purchase_ref,
    ) -> SecuredActionResult:
        existing = purchase_ref.get(transaction=transaction)
        if existing.exists:
            prior = existing.to_dict() or {}
            if prior.get("uid") != uid:
                raise HTTPException(status_code=409, detail="Purchase token already used.")
            user_snapshot = user_ref.get(transaction=transaction)
            user = user_snapshot.to_dict() or {} if user_snapshot.exists else {}
            share, diamonds, value = self._wallet_balances(user)
            return SecuredActionResult(
                accepted=True,
                status="already_granted",
                reason="DIA pack purchase was already recorded.",
                share_balance=share,
                diamond_balance=diamonds,
                value_token_balance=value,
            )
        user_snapshot = user_ref.get(transaction=transaction)
        if not user_snapshot.exists:
            raise HTTPException(status_code=404, detail="User not found.")
        user = user_snapshot.to_dict() or {}
        wallet = user.get("wallet") or {}
        base = int(pack["baseDia"])
        bonus = int(pack["bonusDia"])
        updates: dict = {"updatedAt": SERVER_TIMESTAMP}
        ledger: dict = {}
        if base:
            paid = move_currency(wallet, diamond=base, paid_credit=True)
            updates.update(paid["updates"])
            ledger.update(paid["ledger"])
        if bonus:
            free = move_currency(wallet, diamond=bonus)
            updates.update(free["updates"])
            ledger["diamondFreeAmount"] = free["ledger"].get("diamondFreeAmount", bonus)
            ledger["diamondPaidAmount"] = ledger.get("diamondPaidAmount", 0)
        share, diamonds, value = self._wallet_balances({"wallet": wallet})
        total = base + bonus
        tx_ref = self.firebase_service.db.collection("walletTransactions").document()
        transaction.update(user_ref, updates)
        transaction.set(
            tx_ref,
            {
                "uid": uid,
                "type": "dia_pack_purchase",
                "productId": pack["productId"],
                "priceKrw": pack["priceKrw"],
                "diamondAmount": total,
                "createdAt": SERVER_TIMESTAMP,
                **ledger,
            },
        )
        transaction.set(
            purchase_ref,
            {
                "uid": uid,
                "productId": pack["productId"],
                "diamondAmount": total,
                "createdAt": SERVER_TIMESTAMP,
            },
        )
        return SecuredActionResult(
            accepted=True,
            status="granted",
            reason=f"{total} DIA granted from {pack['productId']}.",
            diamond_balance=diamonds,
            share_balance=share,
            value_token_balance=value,
        )

    def _donate_hall_of_fame_tx(
        self,
        transaction,
        uid: str,
        user_ref,
    ) -> SecuredActionResult:
        user_snapshot = user_ref.get(transaction=transaction)
        if not user_snapshot.exists:
            raise HTTPException(status_code=404, detail="User not found.")
        user = user_snapshot.to_dict() or {}
        share, diamonds, value = self._wallet_balances(user)
        amount = HALL_OF_FAME_DONATE_VALUE
        self._debit_value_tx(
            transaction,
            uid=uid,
            user_ref=user_ref,
            amount=amount,
            tx_type="hall_of_fame_donation",
        )
        donation = int((user.get("wallet") or {}).get("totalDonationValue") or 0)
        transaction.update(
            user_ref,
            {
                "wallet.totalDonationValue": donation + amount,
                "updatedAt": SERVER_TIMESTAMP,
            },
        )
        return SecuredActionResult(
            accepted=True,
            status="donated",
            reason=f"{amount} VALUE donated to the Hall of Fame.",
            share_balance=share,
            diamond_balance=diamonds,
            value_token_balance=value - amount,
        )

    def _claim_signup_reward_tx(self, transaction, uid: str, user_ref) -> SecuredActionResult:
        user_snapshot = user_ref.get(transaction=transaction)
        if not user_snapshot.exists:
            raise HTTPException(status_code=404, detail="User not found.")

        user = user_snapshot.to_dict() or {}
        economy = user.get("economy") or {}
        if economy.get("signupRewardClaimed") is True:
            return SecuredActionResult(
                accepted=True,
                status="already_claimed",
                reason="Signup reward was already claimed.",
            )

        referral_code = economy.get("referralCode") or self._economy_service.generate_referral_code(
            uid
        )
        reward = self._economy_service.signup_reward_amount()
        self._credit_value_tx(
            transaction,
            uid=uid,
            user_ref=user_ref,
            amount=reward,
            tx_type="onboarding_signup_reward",
        )
        self._grant_signup_free_ticket(transaction, uid, user, user_ref)
        transaction.update(
            user_ref,
            {
                "economy": {
                    **economy,
                    "signupRewardClaimed": True,
                    "signupFreeTicketGranted": True,
                    "referralCode": referral_code,
                    "referralPayoutCount": int(economy.get("referralPayoutCount") or 0),
                    "trialRunCount": int(economy.get("trialRunCount") or 0),
                    "trialMilestoneRewardClaimed": bool(
                        economy.get("trialMilestoneRewardClaimed")
                    ),
                },
                "updatedAt": SERVER_TIMESTAMP,
            },
        )
        return SecuredActionResult(
            accepted=True,
            status="claimed",
            reason=f"Signup reward of {reward} SRV credited.",
        )

    def _grant_signup_free_ticket_tx(
        self,
        transaction,
        uid: str,
        user_ref,
    ) -> SignupFreeTicketResult:
        user_snapshot = user_ref.get(transaction=transaction)
        if not user_snapshot.exists:
            raise HTTPException(status_code=404, detail="User not found.")
        user = user_snapshot.to_dict() or {}
        balance, status_name = self._grant_signup_free_ticket(
            transaction, uid, user, user_ref
        )
        return SignupFreeTicketResult(
            accepted=True,
            status=status_name,
            free_ticket_balance=balance,
        )

    def _grant_signup_free_ticket(
        self,
        transaction,
        uid: str,
        user: dict,
        user_ref,
    ) -> tuple[int, str]:
        """Credit one ticket unless the flag or the ledger row already exists."""
        economy = user.get("economy") or {}
        owned = int((user.get("wallet") or {}).get("freeTicketBalance") or 0)
        ledger_ref = self.firebase_service.db.collection("walletTransactions").document(
            signup_free_ticket_id(uid)
        )
        ledger_exists = ledger_ref.get(transaction=transaction).exists
        flagged = economy.get("signupFreeTicketGranted") is True
        if flagged or ledger_exists:
            if not flagged:
                transaction.update(
                    user_ref,
                    {
                        "economy": {**economy, "signupFreeTicketGranted": True},
                        "updatedAt": SERVER_TIMESTAMP,
                    },
                )
            return owned, "already_granted"
        transaction.update(
            user_ref,
            {
                "wallet.freeTicketBalance": owned + SIGNUP_FREE_TICKET_COUNT,
                "economy": {**economy, "signupFreeTicketGranted": True},
                "updatedAt": SERVER_TIMESTAMP,
            },
        )
        transaction.set(
            ledger_ref,
            {
                "uid": uid,
                "type": "signup_free_ticket",
                "ticketAmount": SIGNUP_FREE_TICKET_COUNT,
                "createdAt": SERVER_TIMESTAMP,
            },
        )
        return owned + SIGNUP_FREE_TICKET_COUNT, "granted"

    def _claim_streak_bonus_tx(self, transaction, uid: str, user_ref) -> SecuredActionResult:
        user_snapshot = user_ref.get(transaction=transaction)
        if not user_snapshot.exists:
            raise HTTPException(status_code=404, detail="User not found.")

        user = user_snapshot.to_dict() or {}
        share, diamonds, value = self._wallet_balances(user)
        week = self._economy_service.kst_week_key()
        if (user.get("streakBonusWeekKey") or "") == week:
            return self._harvest_result(
                status="already_claimed",
                reason="Streak diamond reward was already claimed this week.",
                share_credited=0,
                share_balance=share,
                diamond_balance=diamonds,
                value_token_balance=value,
            )

        streak_days = self._walk_streak_days(transaction, uid)
        if streak_days <= 0 or streak_days % _STREAK_BONUS_DAYS != 0:
            return self._harvest_result(
                status="not_eligible",
                reason="Streak bonus needs 7 consecutive account days.",
                share_credited=0,
                share_balance=share,
                diamond_balance=diamonds,
                value_token_balance=value,
            )

        reward = STREAK_BONUS_DIA
        wallet = user.get("wallet") or {}
        moved = move_currency(wallet, diamond=reward)
        tx_ref = self.firebase_service.db.collection("walletTransactions").document()
        transaction.update(
            user_ref,
            {
                **moved["updates"],
                "streakBonusWeekKey": week,
                "updatedAt": SERVER_TIMESTAMP,
            },
        )
        transaction.set(
            tx_ref,
            {
                "uid": uid,
                "type": "streak_bonus",
                "diamondAmount": reward,
                "weekKey": week,
                "createdAt": SERVER_TIMESTAMP,
                **moved["ledger"],
            },
        )
        return self._harvest_result(
            status="claimed",
            reason=f"Streak bonus of {reward} DIA credited.",
            share_credited=0,
            share_balance=share,
            diamond_balance=diamonds + reward,
            value_token_balance=value,
        )

    def _claim_trial_reward_tx(self, transaction, uid: str, user_ref) -> SecuredActionResult:
        user_snapshot = user_ref.get(transaction=transaction)
        if not user_snapshot.exists:
            raise HTTPException(status_code=404, detail="User not found.")

        user = user_snapshot.to_dict() or {}
        economy = user.get("economy") or {}
        share, diamonds, value = self._wallet_balances(user)
        if economy.get("trialMilestoneRewardClaimed") is True:
            return self._harvest_result(
                status="already_claimed",
                reason="Trial completion reward was already claimed.",
                share_credited=0,
                share_balance=share,
                diamond_balance=diamonds,
                value_token_balance=value,
            )

        reward = TRIAL_COMPLETION_REWARD_SRV
        wallet = user.get("wallet") or {}
        moved = move_currency(wallet, share=reward)
        tx_ref = self.firebase_service.db.collection("walletTransactions").document()
        transaction.update(
            user_ref,
            {
                **moved["updates"],
                "economy.trialMilestoneRewardClaimed": True,
                "updatedAt": SERVER_TIMESTAMP,
            },
        )
        transaction.set(
            tx_ref,
            {
                "uid": uid,
                "type": "trial_completion_reward",
                "shareAmount": reward,
                "createdAt": SERVER_TIMESTAMP,
                **moved["ledger"],
            },
        )
        return self._harvest_result(
            status="claimed",
            reason=f"Trial completion reward of {reward} SHARE credited.",
            share_credited=reward,
            share_balance=share + reward,
            diamond_balance=diamonds,
            value_token_balance=value,
        )

    @firestore.transactional
    def _apply_referral_code_tx(
        self,
        transaction,
        uid: str,
        referral_code: str,
        user_ref,
    ) -> SecuredActionResult:
        if not referral_code:
            raise HTTPException(status_code=400, detail="Referral code is required.")

        user_snapshot = user_ref.get(transaction=transaction)
        if not user_snapshot.exists:
            raise HTTPException(status_code=404, detail="User not found.")

        user = user_snapshot.to_dict() or {}
        economy = user.get("economy") or {}
        if economy.get("referredByUid"):
            return SecuredActionResult(
                accepted=True,
                status="already_applied",
                reason="Referral code was already applied.",
            )
        if economy.get("trialMilestoneRewardClaimed"):
            raise HTTPException(
                status_code=400,
                detail="Referral code can only be applied before trial completion.",
            )
        if economy.get("referralCode") == referral_code:
            raise HTTPException(status_code=400, detail="Cannot use your own referral code.")

        referrer_query = (
            self.firebase_service.db.collection("users")
            .where("economy.referralCode", "==", referral_code)
            .limit(1)
        )
        referrer_docs = list(
            referrer_query.get(transaction=transaction)
        )
        if not referrer_docs:
            raise HTTPException(status_code=404, detail="Referral code not found.")

        referrer_doc = referrer_docs[0]
        if referrer_doc.id == uid:
            raise HTTPException(status_code=400, detail="Cannot use your own referral code.")

        transaction.update(
            user_ref,
            {
                "economy": {
                    **economy,
                    "referredByUid": referrer_doc.id,
                },
                "updatedAt": SERVER_TIMESTAMP,
            },
        )
        return SecuredActionResult(
            accepted=True,
            status="applied",
            reason="Referral code saved.",
        )

    def _allocate_invite_code(self, transaction, uid: str, user_ref, code: str) -> str:
        user_snapshot = user_ref.get(transaction=transaction)
        if not user_snapshot.exists:
            raise HTTPException(status_code=404, detail="User not found.")

        user = user_snapshot.to_dict() or {}
        existing = self._stored_invite_code(user)
        if existing:
            existing_ref = self.firebase_service.db.collection("referralCodes").document(
                existing
            )
            existing_snapshot = existing_ref.get(transaction=transaction)
            if not existing_snapshot.exists:
                transaction.set(
                    existing_ref,
                    {"uid": uid, "createdAt": SERVER_TIMESTAMP},
                )
                return existing
            owner = (existing_snapshot.to_dict() or {}).get("uid")
            if owner == uid:
                return existing

        code_ref = self.firebase_service.db.collection("referralCodes").document(code)
        code_snapshot = code_ref.get(transaction=transaction)
        if code_snapshot.exists:
            owner = (code_snapshot.to_dict() or {}).get("uid")
            if owner != uid:
                raise InviteCodeCollision()
        else:
            transaction.set(
                code_ref,
                {"uid": uid, "createdAt": SERVER_TIMESTAMP},
            )
        transaction.update(
            user_ref,
            {
                "economy.referralCode": code,
                "updatedAt": SERVER_TIMESTAMP,
            },
        )
        return code

    @staticmethod
    def _stored_invite_code(user: dict) -> str | None:
        economy = user.get("economy") or {}
        code = economy.get("referralCode")
        if not isinstance(code, str):
            return None
        stripped = code.strip()
        return stripped or None

    _REFERRAL_SHARE_TITLES = {
        "redeem": "초대 코드 등록",
        "trial_referee": "체험 런 5회 완료",
        "trial_referrer": "친구 체험 런 5회",
    }

    def _referral_payout_ref(self, referee_uid: str, payout_type: str):
        return self.firebase_service.db.collection("referralPayouts").document(
            f"{referee_uid}_{payout_type}"
        )

    def _plan_redeem_referral_payouts(
        self,
        transaction,
        *,
        referee_uid: str,
        referee_ref,
        referrer_uid: str,
        include_trial: bool,
    ) -> list[dict]:
        payouts: list[dict] = []
        redeem = self._payout_if_unpaid(
            transaction,
            referee_uid=referee_uid,
            payout_type="redeem",
            payee_uid=referee_uid,
            payee_ref=referee_ref,
            amount=REFERRAL_REDEEM_SHARE,
        )
        if redeem is not None:
            payouts.append(redeem)
        if include_trial:
            payouts.extend(
                self._plan_trial_referral_payouts(
                    transaction,
                    referee_uid=referee_uid,
                    referee_ref=referee_ref,
                    referrer_uid=referrer_uid,
                )
            )
        return payouts

    def _plan_trial_referral_payouts(
        self,
        transaction,
        *,
        referee_uid: str,
        referee_ref,
        referrer_uid: str,
    ) -> list[dict]:
        payouts: list[dict] = []
        referee = self._payout_if_unpaid(
            transaction,
            referee_uid=referee_uid,
            payout_type="trial_referee",
            payee_uid=referee_uid,
            payee_ref=referee_ref,
            amount=REFERRAL_TRIAL_REFEREE_SHARE,
        )
        if referee is not None:
            payouts.append(referee)

        marker_ref = self._referral_payout_ref(referee_uid, "trial_referrer")
        if marker_ref.get(transaction=transaction).exists:
            return payouts

        referrer_ref = self.firebase_service.db.collection("users").document(
            referrer_uid
        )
        referrer_snapshot = referrer_ref.get(transaction=transaction)
        amount = 0
        bump = False
        if referrer_snapshot.exists:
            referrer_economy = (referrer_snapshot.to_dict() or {}).get("economy") or {}
            if self._economy_service.can_pay_referrer(referrer_economy):
                amount = REFERRAL_TRIAL_REFERRER_SHARE
                bump = True
        payouts.append(
            {
                "referee_uid": referee_uid,
                "type": "trial_referrer",
                "payee_uid": referrer_uid,
                "payee_ref": referrer_ref,
                "amount": amount,
                "title": self._REFERRAL_SHARE_TITLES["trial_referrer"],
                "marker_ref": marker_ref,
                "bump_referrer_count": bump,
            }
        )
        return payouts

    def _payout_if_unpaid(
        self,
        transaction,
        *,
        referee_uid: str,
        payout_type: str,
        payee_uid: str,
        payee_ref,
        amount: int,
    ) -> dict | None:
        marker_ref = self._referral_payout_ref(referee_uid, payout_type)
        if marker_ref.get(transaction=transaction).exists:
            return None
        return {
            "referee_uid": referee_uid,
            "type": payout_type,
            "payee_uid": payee_uid,
            "payee_ref": payee_ref,
            "amount": amount,
            "title": self._REFERRAL_SHARE_TITLES[payout_type],
            "marker_ref": marker_ref,
            "bump_referrer_count": False,
        }

    def _write_referral_payouts(self, transaction, payouts: list[dict]) -> None:
        for payout in payouts:
            transaction.set(
                payout["marker_ref"],
                {
                    "refereeUid": payout["referee_uid"],
                    "payeeUid": payout["payee_uid"],
                    "type": payout["type"],
                    "amount": payout["amount"],
                    "createdAt": SERVER_TIMESTAMP,
                },
            )
            if payout["amount"] <= 0:
                continue
            payee_snapshot = payout["payee_ref"].get(transaction=transaction)
            payee_wallet = (payee_snapshot.to_dict() or {}).get("wallet") or {}
            unlock_at = datetime.now(timezone.utc) + timedelta(
                days=REFERRAL_SHARE_LOCK_DAYS
            )
            moved = move_currency(
                payee_wallet,
                share=payout["amount"],
                lock_until=unlock_at,
            )
            payout["ledger"] = moved["ledger"]
            transaction.update(
                payout["payee_ref"],
                {
                    **moved["updates"],
                    "updatedAt": SERVER_TIMESTAMP,
                },
            )
            if payout["bump_referrer_count"]:
                transaction.update(
                    payout["payee_ref"],
                    {
                        "economy.referralPayoutCount": firestore.Increment(1),
                        "updatedAt": SERVER_TIMESTAMP,
                    },
                )
            self._write_share_receipt(transaction, payout)

    def _write_share_receipt(self, transaction, payout: dict) -> None:
        referee_uid = payout["referee_uid"]
        payee_uid = payout["payee_uid"]
        payout_type = payout["type"]
        receipt_id = f"referral_{referee_uid}_{payout_type}"
        transaction.set(
            payout["payee_ref"].collection("wallet_transactions").document(receipt_id),
            {
                "id": receipt_id,
                "uid": payee_uid,
                "title": payout["title"],
                "amount": payout["amount"],
                "assetType": "SHARE",
                "timestamp": SERVER_TIMESTAMP,
            },
        )
        transaction.set(
            self.firebase_service.db.collection("walletTransactions").document(
                f"referral_{payee_uid}_{referee_uid}_{payout_type}"
            ),
            {
                "uid": payee_uid,
                "type": f"referral_{payout_type}",
                "shareAmount": payout["amount"],
                "createdAt": SERVER_TIMESTAMP,
                **(payout.get("ledger") or {}),
            },
        )

    def _purchase_shop_item_tx(
        self,
        transaction,
        uid: str,
        item_id: str,
        user_ref,
    ) -> SecuredActionResult:
        if item_id in STREAK_ITEM_IDS or item_id in RUN_ACCESS_ITEM_IDS or item_id in SOCIAL_ITEM_IDS or item_id in BATTLE_PASS_ITEM_IDS or item_id in SHARE_ACTIVITY_ITEM_IDS or item_id in VALUE_ITEM_IDS:
            raise HTTPException(status_code=400, detail="request_id is required.")
        catalog_item = self.SHOP_CATALOG.get(item_id)
        if catalog_item is None:
            raise HTTPException(status_code=404, detail="Shop item not found.")

        user_snapshot = user_ref.get(transaction=transaction)
        if not user_snapshot.exists:
            raise HTTPException(status_code=404, detail="User not found.")

        user = user_snapshot.to_dict() or {}
        wallet = user.get("wallet") or {}
        diamond_balance = int(wallet.get("diamondBalance") or 0)
        cost = int(catalog_item["diamondCost"])
        if diamond_balance < cost:
            raise HTTPException(status_code=400, detail="Insufficient Diamond balance.")
        moved = move_currency(wallet, diamond=-cost)

        inventory_ref = user_ref.collection("shopInventory").document(item_id)
        inventory_snapshot = inventory_ref.get(transaction=transaction)
        current_qty = 0
        if inventory_snapshot.exists:
            current_qty = int((inventory_snapshot.to_dict() or {}).get("quantity") or 0)

        tx_ref = self.firebase_service.db.collection("walletTransactions").document()
        transaction.update(
            user_ref,
            {
                **moved["updates"],
                "updatedAt": SERVER_TIMESTAMP,
            },
        )
        transaction.set(
            inventory_ref,
            {
                "itemId": item_id,
                "title": catalog_item["title"],
                "quantity": current_qty + 1,
                "purchasedAt": SERVER_TIMESTAMP,
            },
            merge=True,
        )
        transaction.set(
            tx_ref,
            {
                "uid": uid,
                "type": "shop_purchase",
                "diamondAmount": -cost,
                "itemId": item_id,
                "createdAt": SERVER_TIMESTAMP,
                **moved["ledger"],
            },
        )
        return SecuredActionResult(
            accepted=True,
            status="purchased",
            reason=f"Purchased {catalog_item['title']}.",
            share_balance=_wallet_int(wallet, "shareBalance"),
            diamond_balance=diamond_balance - cost,
            value_token_balance=_wallet_int(wallet, "valueTokenBalance"),
        )

    def _grant_crew_items_tx(
        self,
        transaction,
        uid: str,
        user_ref,
    ) -> SecuredActionResult:
        user_snapshot = user_ref.get(transaction=transaction)
        if not user_snapshot.exists:
            raise HTTPException(status_code=404, detail="User not found.")
        user = user_snapshot.to_dict() or {}
        wallet = user.get("wallet") or {}
        diamond_balance = int(wallet.get("diamondBalance") or 0)
        cost = self.CREW_GIFT_DIA
        if diamond_balance < cost:
            raise HTTPException(status_code=400, detail="Insufficient Diamond balance.")
        moved = move_currency(wallet, diamond=-cost)
        transaction.update(
            user_ref,
            {
                **moved["updates"],
                "updatedAt": SERVER_TIMESTAMP,
            },
        )
        granted = []
        for item_id, title in self.CREW_GIFT_ITEMS:
            inventory_ref = user_ref.collection("shopInventory").document(item_id)
            inventory_snapshot = inventory_ref.get(transaction=transaction)
            current_qty = 0
            if inventory_snapshot.exists:
                current_qty = int(
                    (inventory_snapshot.to_dict() or {}).get("quantity") or 0
                )
            transaction.set(
                inventory_ref,
                {
                    "itemId": item_id,
                    "title": title,
                    "quantity": current_qty + 1,
                    "purchasedAt": SERVER_TIMESTAMP,
                },
                merge=True,
            )
            granted.append(item_id)
        tx_ref = self.firebase_service.db.collection("walletTransactions").document()
        transaction.set(
            tx_ref,
            {
                "uid": uid,
                "type": "crew_item_gift",
                "diamondAmount": -cost,
                "itemIds": granted,
                "createdAt": SERVER_TIMESTAMP,
                **moved["ledger"],
            },
        )
        return SecuredActionResult(
            accepted=True,
            status="granted",
            reason="Crew items granted.",
            share_balance=_wallet_int(wallet, "shareBalance"),
            diamond_balance=diamond_balance - cost,
            value_token_balance=_wallet_int(wallet, "valueTokenBalance"),
        )

    def _spend_crew_action_tx(
        self,
        transaction,
        uid: str,
        action: str,
        user_ref,
    ) -> SecuredActionResult:
        spec = self.CREW_SPENDS.get(action)
        if spec is None:
            raise HTTPException(status_code=404, detail="Unknown crew action.")
        asset, cost, tx_type = spec
        user_snapshot = user_ref.get(transaction=transaction)
        if not user_snapshot.exists:
            raise HTTPException(status_code=404, detail="User not found.")
        user = user_snapshot.to_dict() or {}
        wallet = user.get("wallet") or {}
        if asset == "diamond":
            balance = int(wallet.get("diamondBalance") or 0)
            amount_key = "diamondAmount"
            if balance < cost:
                raise HTTPException(
                    status_code=400, detail="Insufficient Diamond balance."
                )
            moved = move_currency(wallet, diamond=-cost)
        else:
            balance = int(wallet.get("shareBalance") or 0)
            amount_key = "shareAmount"
            if balance < cost:
                raise HTTPException(
                    status_code=400, detail="Insufficient Share balance."
                )
            moved = move_currency(wallet, share=-cost)
        transaction.update(
            user_ref,
            {**moved["updates"], "updatedAt": SERVER_TIMESTAMP},
        )
        tx_ref = self.firebase_service.db.collection("walletTransactions").document()
        transaction.set(
            tx_ref,
            {
                "uid": uid,
                "type": tx_type,
                amount_key: -cost,
                "createdAt": SERVER_TIMESTAMP,
                **moved["ledger"],
            },
        )
        return SecuredActionResult(
            accepted=True,
            status="spent",
            reason=f"Crew {action} spent.",
            share_balance=(
                balance - cost if asset == "share" else _wallet_int(wallet, "shareBalance")
            ),
            diamond_balance=(
                balance - cost
                if asset == "diamond"
                else _wallet_int(wallet, "diamondBalance")
            ),
            value_token_balance=_wallet_int(wallet, "valueTokenBalance"),
        )

    def _change_nickname_tx(
        self,
        transaction,
        uid: str,
        nickname: str,
        user_ref,
    ) -> SecuredActionResult:
        user_snapshot = user_ref.get(transaction=transaction)
        if not user_snapshot.exists:
            raise HTTPException(status_code=404, detail="User not found.")
        wallet = (user_snapshot.to_dict() or {}).get("wallet") or {}
        diamond = int(wallet.get("diamondBalance") or 0)
        cost = self.NICKNAME_CHANGE_DIA
        if diamond < cost:
            raise HTTPException(status_code=400, detail="Insufficient Diamond balance.")
        moved = move_currency(wallet, diamond=-cost)
        transaction.update(
            user_ref,
            {
                **moved["updates"],
                "nickname": nickname,
                "nicknameUpdatedAt": SERVER_TIMESTAMP,
                "updatedAt": SERVER_TIMESTAMP,
            },
        )
        tx_ref = self.firebase_service.db.collection("walletTransactions").document()
        transaction.set(
            tx_ref,
            {
                "uid": uid,
                "type": "nickname_change",
                "diamondAmount": -cost,
                "createdAt": SERVER_TIMESTAMP,
                **moved["ledger"],
            },
        )
        return SecuredActionResult(
            accepted=True,
            status="renamed",
            reason="Nickname updated.",
            share_balance=_wallet_int(wallet, "shareBalance"),
            diamond_balance=diamond - cost,
            value_token_balance=_wallet_int(wallet, "valueTokenBalance"),
        )

    def _found_crew_tx(
        self,
        transaction,
        uid: str,
        name: str,
        pay_with: str,
        request_id: str,
        user_ref,
        crew_ref,
    ) -> SecuredActionResult:
        trimmed = name.strip()
        if not trimmed or len(trimmed) > 80:
            raise HTTPException(status_code=400, detail="Invalid crew name.")
        prices = read_item_prices(self.firebase_service.db, transaction)
        dia_cost = int(prices[CREW_CREATE_DIA_ID])
        share_cost = int(prices[CREW_CREATE_SHARE_ID])
        ledger_ref = self.firebase_service.db.collection("walletTransactions").document(
            f"crew_create_{uid}_{request_id}"
        )
        if ledger_ref.get(transaction=transaction).exists:
            user_snapshot = user_ref.get(transaction=transaction)
            wallet = (user_snapshot.to_dict() or {}).get("wallet") or {}
            return SecuredActionResult(
                accepted=True,
                status="already_created",
                reason="Crew creation already recorded.",
                share_balance=_wallet_int(wallet, "shareBalance"),
                diamond_balance=_wallet_int(wallet, "diamondBalance"),
                value_token_balance=_wallet_int(wallet, "valueTokenBalance"),
            )
        user_snapshot = user_ref.get(transaction=transaction)
        if not user_snapshot.exists:
            raise HTTPException(status_code=404, detail="User not found.")
        wallet = (user_snapshot.to_dict() or {}).get("wallet") or {}
        share = int(wallet.get("shareBalance") or 0)
        diamonds = int(wallet.get("diamondBalance") or 0)
        if pay_with == "dia":
            if diamonds < dia_cost:
                raise HTTPException(
                    status_code=400, detail="Insufficient Diamond balance."
                )
            moved = move_currency(wallet, diamond=-dia_cost)
            amount_key = "diamondAmount"
            cost = dia_cost
            share_charged = 0
            dia_charged = dia_cost
        else:
            if share < share_cost:
                raise HTTPException(status_code=400, detail="Insufficient Share balance.")
            moved = move_currency(wallet, share=-share_cost)
            amount_key = "shareAmount"
            cost = share_cost
            share_charged = share_cost
            dia_charged = 0
        transaction.update(
            user_ref,
            {
                **moved["updates"],
                "ownedCrewId": crew_ref.id,
                "updatedAt": SERVER_TIMESTAMP,
            },
        )
        transaction.set(
            crew_ref,
            {
                "name": trimmed,
                "ownerUid": uid,
                "totalValue": 0,
                "memberCount": 1,
                "payWith": pay_with,
                "shareCost": share_charged,
                "diaCost": dia_charged,
                "createdAt": SERVER_TIMESTAMP,
            },
        )
        transaction.set(
            ledger_ref,
            {
                "uid": uid,
                "type": "crew_create",
                amount_key: -cost,
                "payWith": pay_with,
                "crewId": crew_ref.id,
                "requestId": request_id,
                "createdAt": SERVER_TIMESTAMP,
                **moved["ledger"],
            },
        )
        return SecuredActionResult(
            accepted=True,
            status="created",
            reason="Crew created.",
            share_balance=share - share_charged,
            diamond_balance=diamonds - dia_charged,
            value_token_balance=_wallet_int(wallet, "valueTokenBalance"),
        )

    def _create_challenge_room_tx(
        self,
        transaction,
        uid: str,
        title: str,
        distance_km: int,
        user_ref,
        room_ref,
    ) -> CreateChallengeRoomResult:
        trimmed = title.strip()
        if not trimmed or len(trimmed) > 80:
            raise HTTPException(status_code=400, detail="Invalid room title.")
        fee = _challenge_entry_fee(distance_km)
        user_snapshot = user_ref.get(transaction=transaction)
        if not user_snapshot.exists:
            raise HTTPException(status_code=404, detail="User not found.")
        wallet = (user_snapshot.to_dict() or {}).get("wallet") or {}
        share = int(wallet.get("shareBalance") or 0)
        if share < fee:
            raise HTTPException(status_code=400, detail="Insufficient Share balance.")
        moved = move_currency(wallet, share=-fee)
        bep = _challenge_bep(distance_km)
        capacity = min(400, max(20, bep * 2))
        transaction.update(
            user_ref,
            {**moved["updates"], "updatedAt": SERVER_TIMESTAMP},
        )
        transaction.set(
            room_ref,
            {
                "title": trimmed,
                "targetDistanceKm": float(distance_km),
                "entryFeeShare": fee,
                "winnerRewardValue": int(fee * 0.4),
                "donationValue": int(fee * 0.2),
                "minParticipantsBep": bep,
                "maxParticipants": capacity,
                "participantCount": 1,
                "requiredTier": 1,
                "status": "recruiting",
                "sponsorName": "UNICEF",
                "sponsorBillboardMessages": [],
                "createdByUid": uid,
                "userCreated": True,
                "createdAt": SERVER_TIMESTAMP,
            },
        )
        tx_ref = self.firebase_service.db.collection("walletTransactions").document()
        transaction.set(
            tx_ref,
            {
                "uid": uid,
                "type": "challenge_room_create",
                "shareAmount": -fee,
                "tournamentId": room_ref.id,
                "createdAt": SERVER_TIMESTAMP,
                **moved["ledger"],
            },
        )
        return CreateChallengeRoomResult(
            accepted=True,
            status="created",
            reason="Challenge room created.",
            share_balance=share - fee,
            diamond_balance=_wallet_int(wallet, "diamondBalance"),
            value_token_balance=_wallet_int(wallet, "valueTokenBalance"),
            tournament_id=room_ref.id,
            entry_fee_share=fee,
        )

    def _use_shop_item_tx(
        self,
        transaction,
        uid: str,
        item_id: str,
        user_ref,
    ) -> SecuredActionResult:
        if item_id in BATTLE_PASS_ITEM_IDS:
            raise HTTPException(status_code=400, detail=NOT_SPENT)
        if item_id in STREAK_ITEM_IDS or item_id in RUN_ACCESS_ITEM_IDS or item_id in SOCIAL_ITEM_IDS or item_id in SHARE_ACTIVITY_ITEM_IDS or item_id in VALUE_ITEM_IDS:
            raise HTTPException(status_code=400, detail="request_id is required.")
        if item_id not in self.SHOP_CATALOG:
            if is_cosmetic_item(self.firebase_service.db, item_id):
                raise HTTPException(status_code=400, detail=COSMETIC_NOT_SPENT)
            raise HTTPException(status_code=404, detail="Shop item not found.")
        inventory_ref = user_ref.collection("shopInventory").document(item_id)
        inventory_snapshot = inventory_ref.get(transaction=transaction)
        current_qty = 0
        if inventory_snapshot.exists:
            current_qty = int((inventory_snapshot.to_dict() or {}).get("quantity") or 0)
        if current_qty < 1:
            raise HTTPException(status_code=400, detail="No item to use.")
        transaction.set(
            inventory_ref,
            {"quantity": current_qty - 1},
            merge=True,
        )
        tx_ref = self.firebase_service.db.collection("walletTransactions").document()
        transaction.set(
            tx_ref,
            {
                "uid": uid,
                "type": "shop_item_use",
                "itemId": item_id,
                "quantityAmount": -1,
                "createdAt": SERVER_TIMESTAMP,
            },
        )
        return SecuredActionResult(
            accepted=True,
            status="used",
            reason="Item used.",
        )

    def _validation_result_from_activity(self, activity: dict) -> ValidationResult:
        return ValidationResult(
            verified=bool(activity.get("jenaVerified")),
            decision=activity.get("jenaDecision") or "rejected_unknown",
            reason=activity.get("jenaReason") or "Validation already finalized.",
            value_token_reward=int(activity.get("valueTokenReward") or 0),
            daily_cap_applied=bool(activity.get("dailyCapApplied")),
            trial_run_count=activity.get("trialRunCount"),
            trial_milestone_reached=bool(activity.get("trialMilestoneReached")),
            forfeit_deposit=bool(activity.get("depositForfeited")),
        )

    def get_company_tournament_config(self) -> dict:
        snapshot = (
            self.firebase_service.db.collection("config")
            .document(COMPANY_TOURNAMENT_CONFIG_ID)
            .get()
        )
        raw = snapshot.to_dict() if snapshot.exists else None
        return resolve_company_tournament_config(raw)

    def join_tournament(
        self,
        uid: str,
        request: JoinTournamentRequest,
    ) -> SecuredActionResult:
        self._ensure_email_verified(uid)
        # Existing accounts receive the one signup ticket before the fee check.
        self.ensure_signup_free_ticket(uid)
        transaction = self.firebase_service.db.transaction()
        tournament_ref = self.firebase_service.db.collection("tournaments").document(
            request.tournament_id
        )
        user_ref = self.firebase_service.db.collection("users").document(uid)
        participant_ref = tournament_ref.collection("participants").document(uid)
        # Module wrapper: a method decorator does not bind `self`.
        return _commit_join_tx(
            transaction, self, uid, request, user_ref, tournament_ref, participant_ref
        )

    def settle_tournament_failure(
        self,
        uid: str,
        request: SettleTournamentFailureRequest,
    ) -> SecuredActionResult:
        transaction = self.firebase_service.db.transaction()
        tournament_ref = self.firebase_service.db.collection("tournaments").document(
            request.tournament_id
        )
        user_ref = self.firebase_service.db.collection("users").document(uid)
        participant_ref = tournament_ref.collection("participants").document(uid)
        return self._settle_tournament_failure_tx(
            transaction,
            uid,
            request,
            user_ref,
            tournament_ref,
            participant_ref,
        )

    def _join_tournament_tx(
        self,
        transaction,
        uid: str,
        request: JoinTournamentRequest,
        user_ref,
        tournament_ref,
        participant_ref,
    ) -> SecuredActionResult:
        user_snapshot = user_ref.get(transaction=transaction)
        tournament_snapshot = tournament_ref.get(transaction=transaction)
        participant_snapshot = participant_ref.get(transaction=transaction)

        builtin = (
            None
            if tournament_snapshot.exists
            else _BUILTIN_ROOMS.get(tournament_ref.id)
        )
        if not user_snapshot.exists or (
            not tournament_snapshot.exists and builtin is None
        ):
            raise HTTPException(status_code=404, detail="User or tournament not found.")

        user = user_snapshot.to_dict() or {}
        tournament = (
            dict(builtin) if builtin is not None else (tournament_snapshot.to_dict() or {})
        )
        share, diamonds, value = self._wallet_balances(user)
        if participant_snapshot.exists:
            return self._already_joined_result(
                share_balance=share,
                diamond_balance=diamonds,
                value_token_balance=value,
            )

        tier_id = prize_tier_id(tournament)
        if request.use_extra_entry and tier_id is not None:
            raise HTTPException(
                status_code=400,
                detail="Prize races accept only SHARE or free tickets.",
            )
        if tier_id is not None:
            if tier_id == "":
                raise HTTPException(status_code=400, detail="Unknown prize tier.")
            config_snapshot = (
                self.firebase_service.db.collection("config")
                .document(COMPANY_TOURNAMENT_CONFIG_ID)
                .get(transaction=transaction)
            )
            raw = config_snapshot.to_dict() if config_snapshot.exists else None
            return self._join_prize_race_tx(
                transaction,
                uid,
                request,
                user,
                tournament,
                tier_id,
                resolve_company_tournament_config(raw),
                user_ref,
                tournament_ref,
                participant_ref,
                builtin is not None,
                share,
                diamonds,
                value,
            )

        user_tier = int(user.get("tier") or 1)
        required_tier = int(tournament.get("requiredTier") or 1)
        entry_fee = int(tournament.get("entryFeeShare") or 0)
        required_deposit = int(tournament.get("diamondDepositRequired") or 0)
        diamond_deposit = request.diamond_deposit or required_deposit
        selected_charity = request.selected_charity or "UNICEF"

        needs_ticket = False
        if tournament.get("status", "recruiting") != "recruiting":
            if request.use_extra_entry and extra_entry_opens_closed(
                tournament.get("status")
            ):
                needs_ticket = True
            else:
                raise HTTPException(
                    status_code=400, detail="Tournament is not recruiting."
                )
        if required_tier < user_tier and tournament_ref.id not in _OPEN_TIER_ROOM_IDS:
            raise HTTPException(status_code=403, detail="Lower-tier room is locked.")
        if self._tournament_is_full(tournament):
            if request.use_extra_entry:
                needs_ticket = True
            else:
                raise HTTPException(status_code=409, detail="Tournament is full.")
        if share < entry_fee:
            raise HTTPException(status_code=400, detail="Insufficient Share balance.")
        if diamond_deposit > 0 and diamonds < diamond_deposit:
            raise HTTPException(status_code=400, detail="Insufficient Diamond deposit.")
        if needs_ticket:
            consume_extra_entry_ticket(
                self, transaction, uid, user_ref, tournament_ref.id
            )

        wallet = user.get("wallet") or {}
        moved = move_currency(
            wallet,
            share=-entry_fee,
            diamond=-diamond_deposit if diamond_deposit > 0 else 0,
        )
        user_updates = {
            **moved["updates"],
            "updatedAt": SERVER_TIMESTAMP,
        }

        tx_ref = self.firebase_service.db.collection("walletTransactions").document()
        transaction.update(user_ref, user_updates)
        if builtin is not None:
            transaction.set(
                tournament_ref,
                {**tournament, "participantCount": 1, "updatedAt": SERVER_TIMESTAMP},
            )
        else:
            transaction.update(
                tournament_ref,
                {
                    "participantCount": firestore.Increment(1),
                    "updatedAt": SERVER_TIMESTAMP,
                },
            )
        transaction.set(
            participant_ref,
            {
                "uid": uid,
                "entryFeeShare": entry_fee,
                "diamondDeposit": diamond_deposit,
                "selectedCharity": selected_charity,
                "joinedAt": SERVER_TIMESTAMP,
                "status": "joined",
                **({"extraEntryTicket": True} if needs_ticket else {}),
            },
        )
        transaction.set(
            tx_ref,
            {
                "uid": uid,
                "tournamentId": tournament_ref.id,
                "type": "tournament_entry",
                "shareAmount": -entry_fee,
                "diamondAmount": -diamond_deposit,
                "charityTarget": selected_charity if diamond_deposit > 0 else None,
                "createdAt": SERVER_TIMESTAMP,
                **({"extraEntryItemId": EXTRA_ENTRY_ITEM_ID} if needs_ticket else {}),
                **moved["ledger"],
            },
        )
        new_share = share - entry_fee
        new_diamonds = diamonds - diamond_deposit if diamond_deposit > 0 else diamonds
        return SecuredActionResult(
            accepted=True,
            status="joined",
            reason="Tournament joined with Share and Diamond deposit.",
            share_credited=-entry_fee,
            share_balance=new_share,
            diamond_balance=new_diamonds,
            value_token_balance=value,
        )

    def _join_prize_race_tx(
        self,
        transaction,
        uid: str,
        request: JoinTournamentRequest,
        user: dict,
        tournament: dict,
        tier_id: str,
        config: dict,
        user_ref,
        tournament_ref,
        participant_ref,
        builtin: bool,
        share: int,
        diamonds: int,
        value: int,
    ) -> SecuredActionResult:
        """Admission for a company prize race. Fee comes from config, not the room doc."""
        tier = config["tiers"].get(tier_id)
        if tier is None:
            raise HTTPException(status_code=400, detail="Unknown prize tier.")
        if tournament.get("status", "recruiting") != "recruiting":
            raise HTTPException(status_code=400, detail="Tournament is not recruiting.")
        if self._tournament_is_full(
            {**tournament, "maxParticipants": int(tier["maxEntrants"])}
        ):
            raise HTTPException(status_code=409, detail="Tournament is full.")
        if (request.diamond_deposit or 0) > 0:
            raise HTTPException(
                status_code=400,
                detail="Prize race entry does not accept DIA.",
            )
        if tier["requiresSeasonQualification"] and user.get("seasonQualified") is not True:
            raise HTTPException(
                status_code=403,
                detail="Season qualification is required.",
            )

        wallet = user.get("wallet") or {}
        share_fee = 0
        ticket_fee = 0
        moved: dict = {"updates": {}, "ledger": {}}
        if request.entry_method == "ticket":
            ticket_fee = int(tier["freeTicketCost"])
            if ticket_fee <= 0:
                raise HTTPException(
                    status_code=400,
                    detail="This tier does not accept free tickets.",
                )
            owned = int(wallet.get("freeTicketBalance") or 0)
            if owned < ticket_fee:
                raise HTTPException(status_code=400, detail="Insufficient free tickets.")
            transaction.update(
                user_ref,
                {
                    "wallet.freeTicketBalance": owned - ticket_fee,
                    "updatedAt": SERVER_TIMESTAMP,
                },
            )
            entry_method = "ticket"
            result_status = "joined_ticket"
            reason = "Tournament joined with free tickets."
            new_share = share
        else:
            share_fee = int(tier["entryShare"])
            if share_fee > 0:
                if share < share_fee:
                    raise HTTPException(
                        status_code=400,
                        detail="Insufficient Share balance.",
                    )
                moved = move_currency(wallet, share=-share_fee)
                transaction.update(
                    user_ref,
                    {**moved["updates"], "updatedAt": SERVER_TIMESTAMP},
                )
                entry_method = "share"
                result_status = "joined"
                reason = "Tournament joined with Share."
                new_share = share - share_fee
            else:
                entry_method = "free"
                result_status = "joined_free"
                reason = "Tournament joined with no entry fee."
                new_share = share

        if builtin:
            transaction.set(
                tournament_ref,
                {**tournament, "participantCount": 1, "updatedAt": SERVER_TIMESTAMP},
            )
        else:
            transaction.update(
                tournament_ref,
                {
                    "participantCount": firestore.Increment(1),
                    "updatedAt": SERVER_TIMESTAMP,
                },
            )
        transaction.set(
            participant_ref,
            {
                "uid": uid,
                "entryFeeShare": share_fee,
                "ticketAmount": ticket_fee,
                "entryMethod": entry_method,
                "prizeTier": tier_id,
                "diamondDeposit": 0,
                "selectedCharity": request.selected_charity or "UNICEF",
                "joinedAt": SERVER_TIMESTAMP,
                "status": "joined",
            },
        )
        transaction.set(
            self.firebase_service.db.collection("walletTransactions").document(),
            {
                "uid": uid,
                "tournamentId": tournament_ref.id,
                "type": "tournament_entry",
                "shareAmount": -share_fee,
                "diamondAmount": 0,
                "ticketAmount": -ticket_fee,
                "entryMethod": entry_method,
                "prizeTier": tier_id,
                "createdAt": SERVER_TIMESTAMP,
                **moved["ledger"],
            },
        )
        return SecuredActionResult(
            accepted=True,
            status=result_status,
            reason=reason,
            share_credited=-share_fee,
            share_balance=new_share,
            diamond_balance=diamonds,
            value_token_balance=value,
        )

    @firestore.transactional
    def _settle_tournament_failure_tx(
        self,
        transaction,
        uid: str,
        request: SettleTournamentFailureRequest,
        user_ref,
        tournament_ref,
        participant_ref,
    ) -> SecuredActionResult:
        user_snapshot = user_ref.get(transaction=transaction)
        tournament_snapshot = tournament_ref.get(transaction=transaction)
        participant_snapshot = participant_ref.get(transaction=transaction)

        if not user_snapshot.exists or not tournament_snapshot.exists:
            raise HTTPException(status_code=404, detail="User or tournament not found.")
        if not participant_snapshot.exists:
            raise HTTPException(status_code=404, detail="Tournament participation not found.")

        participant = participant_snapshot.to_dict() or {}
        if participant.get("mercySettled") is True:
            return SecuredActionResult(
                accepted=True,
                status="already_settled",
                reason="Mercy settlement was already processed.",
            )

        tournament = tournament_snapshot.to_dict() or {}
        target_distance = float(tournament.get("targetDistanceKm") or 0)
        diamond_deposit = int(participant.get("diamondDeposit") or 0)
        charity_target = participant.get("selectedCharity") or "UNICEF"

        settlement = self._mercy_rule_service.compute_settlement(
            diamond_deposit=diamond_deposit,
            target_distance_km=target_distance,
            distance_achieved_km=request.distance_achieved_km,
            charity_target=charity_target,
        )

        if settlement.achievement_rate >= 1.0:
            raise HTTPException(
                status_code=400,
                detail="Mission completed. Mercy settlement is not required.",
            )

        user_updates: dict = {"updatedAt": SERVER_TIMESTAMP}
        returned_ledger: dict = {}
        if settlement.returned_diamonds > 0:
            wallet = (user_snapshot.to_dict() or {}).get("wallet") or {}
            moved = move_currency(wallet, diamond=settlement.returned_diamonds)
            user_updates.update(moved["updates"])
            returned_ledger = moved["ledger"]
        if settlement.forfeited_diamonds > 0:
            user_updates["wallet.totalDonationValue"] = firestore.Increment(
                settlement.forfeited_diamonds
            )

        if len(user_updates) > 1:
            transaction.update(user_ref, user_updates)

        tx_ref = self.firebase_service.db.collection("walletTransactions").document()
        transaction.set(
            tx_ref,
            {
                "uid": uid,
                "tournamentId": tournament_ref.id,
                "type": "mercy_rule_donation",
                "diamondAmount": settlement.forfeited_diamonds,
                "returnedDiamondAmount": settlement.returned_diamonds,
                **returned_ledger,
                "achievementRate": settlement.achievement_rate,
                "donationTarget": settlement.charity_target,
                "createdAt": SERVER_TIMESTAMP,
            },
        )
        transaction.update(
            participant_ref,
            {
                "status": "failed_mercy_settled",
                "mercySettled": True,
                "achievementRate": settlement.achievement_rate,
                "forfeitedDiamonds": settlement.forfeited_diamonds,
                "returnedDiamonds": settlement.returned_diamonds,
                "settledAt": SERVER_TIMESTAMP,
            },
        )
        return SecuredActionResult(
            accepted=True,
            status="mercy_settled",
            reason=(
                f"Mercy rule applied: {settlement.returned_diamonds} Diamond returned, "
                f"{settlement.forfeited_diamonds} donated to {settlement.charity_target}."
            ),
        )

    def collect_diamond_box(
        self,
        uid: str,
        request: CollectDiamondBoxRequest,
    ) -> SecuredActionResult:
        transaction = self.firebase_service.db.transaction()
        user_ref = self.firebase_service.db.collection("users").document(uid)
        box_ref = self.firebase_service.db.collection("diamondBoxes").document(
            request.box_id
        )
        collected_ref = user_ref.collection("collectedDiamondBoxes").document(
            request.box_id
        )
        return _commit_diamond_box_tx(
            transaction, self, uid, request, user_ref, box_ref, collected_ref
        )

    def _collect_diamond_box_tx(
        self,
        transaction,
        uid: str,
        request: CollectDiamondBoxRequest,
        user_ref,
        box_ref,
        collected_ref,
    ) -> SecuredActionResult:
        box_snapshot = box_ref.get(transaction=transaction)
        collected_snapshot = collected_ref.get(transaction=transaction)
        if not box_snapshot.exists:
            raise HTTPException(status_code=404, detail="Diamond box not found.")
        if collected_snapshot.exists:
            return self._already_collected_result()

        box = box_snapshot.to_dict() or {}
        if box.get("active") is not True:
            raise HTTPException(status_code=400, detail="Diamond box is inactive.")

        distance = self._distance_meters(
            request.latitude,
            request.longitude,
            float(box.get("latitude") or 0),
            float(box.get("longitude") or 0),
        )
        if distance > 80:
            raise HTTPException(status_code=403, detail="Move closer to collect.")

        reward = int(box.get("rewardDiamond") or 1)
        user_snapshot = user_ref.get(transaction=transaction)
        wallet = (user_snapshot.to_dict() or {}).get("wallet") or {}
        moved = move_currency(wallet, diamond=reward)
        tx_ref = self.firebase_service.db.collection("walletTransactions").document()
        transaction.update(
            user_ref,
            {
                **moved["updates"],
                "updatedAt": SERVER_TIMESTAMP,
            },
        )
        transaction.set(
            collected_ref,
            {
                "boxId": box_ref.id,
                "rewardDiamond": reward,
                "collectedAt": SERVER_TIMESTAMP,
            },
        )
        transaction.set(
            tx_ref,
            {
                "uid": uid,
                "boxId": box_ref.id,
                "type": "diamond_box_collect",
                "diamondAmount": reward,
                "createdAt": SERVER_TIMESTAMP,
                **moved["ledger"],
            },
        )
        return SecuredActionResult(
            accepted=True,
            status="collected",
            reason="Diamond box collected.",
        )

    def harvest_pedometer_share(
        self,
        uid: str,
        request: HarvestPedometerRequest,
    ) -> SecuredActionResult:
        transaction = self.firebase_service.db.transaction()
        user_ref = self.firebase_service.db.collection("users").document(uid)
        # Module wrapper: a method decorator does not bind `self`, so this
        # transaction never ran and the wallet was not credited.
        return _commit_harvest_tx(transaction, self, uid, request, user_ref)

    def _walk_streak_days(self, transaction, uid: str) -> int:
        """Consecutive qualifying daily_metrics days, ending today or yesterday."""
        today = date.fromisoformat(self._economy_service.kst_today_key())
        parent = (
            self.firebase_service.db.collection("users")
            .document(uid)
            .collection("daily_metrics")
        )
        start = today
        today_snap = parent.document(today.isoformat()).get(transaction=transaction)
        if not _day_has_activity(today_snap):
            start = today - timedelta(days=1)
        count = 0
        day = start
        for _ in range(_STREAK_LOOKBACK_DAYS):
            snap = parent.document(day.isoformat()).get(transaction=transaction)
            if _day_has_activity(snap):
                count += 1
            elif _day_is_rest(snap):
                pass
            else:
                break
            day -= timedelta(days=1)
        return count

    @staticmethod
    def _wallet_balances(user: dict) -> tuple[int, int, int]:
        wallet = user.get("wallet") or {}
        return (
            int(wallet.get("shareBalance") or 0),
            int(wallet.get("diamondBalance") or 0),
            int(wallet.get("valueTokenBalance") or 0),
        )

    def _harvest_result(
        self,
        *,
        status: str,
        reason: str,
        share_credited: int,
        share_balance: int,
        diamond_balance: int,
        value_token_balance: int,
    ) -> SecuredActionResult:
        return SecuredActionResult(
            accepted=True,
            status=status,
            reason=reason,
            share_credited=share_credited,
            share_balance=share_balance,
            diamond_balance=diamond_balance,
            value_token_balance=value_token_balance,
        )

    def _harvest_pedometer_share_tx(
        self,
        transaction,
        uid: str,
        request: HarvestPedometerRequest,
        user_ref,
        now: datetime | None = None,
    ) -> SecuredActionResult:
        user_snapshot = user_ref.get(transaction=transaction)
        if not user_snapshot.exists:
            raise HTTPException(status_code=404, detail="User not found.")

        user = user_snapshot.to_dict() or {}
        current_share, current_dia, current_value = self._wallet_balances(user)
        current = now or datetime.now(timezone.utc)
        today = self._economy_service.kst_today_key(current)
        hour_key = self._economy_service.kst_hour_key(current)
        raw_harvest = user.get("pedometerHarvest") or {}
        harvest = self._economy_service.normalize_pedometer_harvest(
            raw_harvest,
            today,
        )
        prev_claimed = int(harvest["claimedSteps"])
        harvested = int(harvest["harvestedShare"])
        claimed = int(request.claimed_steps)
        if claimed <= prev_claimed:
            return self._harvest_result(
                status="already_harvested",
                reason="Pedometer harvest watermark already applied.",
                share_credited=0,
                share_balance=current_share,
                diamond_balance=current_dia,
                value_token_balance=current_value,
            )

        same_hour = (
            raw_harvest.get("dateKey") == today
            and raw_harvest.get("hourKey") == hour_key
        )
        hour_steps = int(raw_harvest.get("hourSteps") or 0) if same_hour else 0
        accepted_delta = min(
            claimed - prev_claimed,
            max(0, PEDOMETER_HOURLY_STEP_CAP - hour_steps),
        )
        if accepted_delta <= 0:
            return self._harvest_result(
                status="hourly_cap_reached",
                reason="Walking challenge hourly step cap reached.",
                share_credited=0,
                share_balance=current_share,
                diamond_balance=current_dia,
                value_token_balance=current_value,
            )
        accepted_claimed = prev_claimed + accepted_delta
        share = self._economy_service.pedometer_harvest_share(
            claimed_steps=accepted_claimed,
            prev_claimed_steps=prev_claimed,
            harvested_share=harvested,
        )
        wallet = user.get("wallet") or {}
        effect = plan_activity_share(
            self,
            transaction,
            user,
            user_ref,
            base_share=share,
            accepted_steps=accepted_delta,
            now=current,
        )
        credit = share + effect.extra_share
        moved = (
            move_currency(wallet, share=credit)
            if credit > 0
            else {"updates": {}, "ledger": {}}
        )
        hatch_moved = (
            move_currency(wallet, share=effect.hatch_share)
            if effect.hatch_share > 0
            else {"updates": {}, "ledger": {}}
        )
        new_share = int(wallet.get("shareBalance") or current_share)
        # Dotted SHARE fields only — never replace the wallet map (DIA/VALUE).
        updates = {
            "pedometerHarvest.dateKey": today,
            "pedometerHarvest.claimedSteps": accepted_claimed,
            "pedometerHarvest.harvestedShare": harvested + share,
            "pedometerHarvest.hourKey": hour_key,
            "pedometerHarvest.hourSteps": hour_steps + accepted_delta,
            "updatedAt": SERVER_TIMESTAMP,
            **moved["updates"],
            **hatch_moved["updates"],
        }
        if effect.boost_state is not None:
            updates["boostRun"] = effect.boost_state
        if effect.incubator_state is not None:
            updates["stepIncubator"] = effect.incubator_state
        if credit > 0:
            tx_ref = self.firebase_service.db.collection(
                "walletTransactions"
            ).document()
            transaction.set(
                tx_ref,
                {
                    "uid": uid,
                    "type": "pedometer_harvest",
                    "shareAmount": credit,
                    "boostShare": effect.extra_share,
                    "claimedSteps": claimed,
                    "createdAt": SERVER_TIMESTAMP,
                    **moved["ledger"],
                },
            )
        if effect.hatch_fields is not None:
            transaction.set(
                self.firebase_service.db.collection("walletTransactions").document(
                    effect.hatch_doc_id
                ),
                {
                    **effect.hatch_fields,
                    "createdAt": SERVER_TIMESTAMP,
                    **hatch_moved["ledger"],
                },
            )
        if effect.cosmetic_fields is not None:
            transaction.set(
                user_ref.collection("shopInventory").document(effect.cosmetic_id),
                effect.cosmetic_fields,
            )
        transaction.update(user_ref, updates)
        granted = credit + effect.hatch_share
        if share <= 0:
            return self._harvest_result(
                status="daily_cap_reached",
                reason="Walking challenge daily SHARE cap reached.",
                share_credited=granted,
                share_balance=new_share,
                diamond_balance=current_dia,
                value_token_balance=current_value,
            )
        return self._harvest_result(
            status="harvested",
            reason=f"{credit} SHARE credited from walking challenge.",
            share_credited=granted,
            share_balance=new_share,
            diamond_balance=current_dia,
            value_token_balance=current_value,
        )

    @staticmethod
    def _test_grant_already_applied(user: dict) -> bool:
        return user.get(TEST_WALLET_GRANT_FLAG) is True

    @staticmethod
    def _test_grant_needs_reapply(user: dict) -> bool:
        """Flag set but balances still 0 — grant never landed; allow one retry."""
        if not SecuredActionService._test_grant_already_applied(user):
            return False
        share, dia, value = SecuredActionService._wallet_balances(user)
        return share <= 0 and dia <= 0 and value <= 0

    @staticmethod
    def is_test_grant_authorized(
        uid: str,
        user: dict,
        grant_secret: str = "",
        *,
        debug_client: bool = False,
        allowlist: frozenset[str] | None = None,
        expected_secret: str | None = None,
        debug_client_secret: str | None = None,
    ) -> bool:
        from app.config import test_wallet_grant_secret, test_wallet_grant_uids

        allowed = allowlist if allowlist is not None else test_wallet_grant_uids()
        if uid and uid in allowed:
            return True
        if user.get(TEST_WALLET_GRANT_ELIGIBLE_FLAG) is True:
            return True
        baked = (
            debug_client_secret
            if debug_client_secret is not None
            else TEST_WALLET_GRANT_DEBUG_CLIENT_SECRET
        )
        if debug_client and baked and grant_secret == baked:
            return True
        expected = (
            expected_secret
            if expected_secret is not None
            else test_wallet_grant_secret()
        )
        return bool(expected) and grant_secret == expected

    def grant_debug_test_wallet(
        self,
        uid: str,
        request: DebugTestGrantRequest | None = None,
        *,
        admin_authorized: bool = False,
    ) -> SecuredActionResult:
        from app.config import debug_test_grant_enabled

        if not debug_test_grant_enabled():
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Not found.",
            )
        if not admin_authorized:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Admin access required.",
            )
        transaction = self.firebase_service.db.transaction()
        user_ref = self.firebase_service.db.collection("users").document(uid)
        return self._grant_debug_test_wallet_tx(
            transaction, uid, request or DebugTestGrantRequest(), user_ref
        )

    @firestore.transactional
    def _grant_debug_test_wallet_tx(
        self,
        transaction,
        uid: str,
        _request: DebugTestGrantRequest,
        user_ref,
    ) -> SecuredActionResult:
        user_snapshot = user_ref.get(transaction=transaction)
        if not user_snapshot.exists:
            raise HTTPException(status_code=404, detail="User not found.")

        user = user_snapshot.to_dict() or {}
        current_share, current_dia, current_value = self._wallet_balances(user)
        if self._test_grant_already_applied(
            user
        ) and not self._test_grant_needs_reapply(user):
            # Never reset existing test balances on relaunch.
            return self._harvest_result(
                status="already_granted",
                reason="Debug 1M test grant was already applied.",
                share_credited=0,
                share_balance=current_share,
                diamond_balance=current_dia,
                value_token_balance=current_value,
            )

        amount = TEST_WALLET_GRANT_AMOUNT
        wallet = user.get("wallet") or {}
        moved = assign_free_balances(wallet, share=amount, diamond=amount)
        # Dotted fields only — keep wallet.totalDonationValue intact.
        transaction.update(
            user_ref,
            {
                **moved["updates"],
                "wallet.valueTokenBalance": amount,
                TEST_WALLET_GRANT_FLAG: True,
                "updatedAt": SERVER_TIMESTAMP,
            },
        )
        tx_ref = self.firebase_service.db.collection(
            "walletTransactions"
        ).document()
        transaction.set(
            tx_ref,
            {
                "uid": uid,
                "type": "debug_test_grant_1m",
                "shareAmount": amount,
                "diamondAmount": amount,
                "valueAmount": amount,
                "createdAt": SERVER_TIMESTAMP,
                **moved["ledger"],
            },
        )
        return self._harvest_result(
            status="granted",
            reason=(
                f"Debug test grant set SHARE/DIA/VALUE to {amount}."
            ),
            share_credited=amount,
            share_balance=amount,
            diamond_balance=amount,
            value_token_balance=amount,
        )

    def request_refund(self, uid: str, request: RefundRequest) -> SecuredActionResult:
        transaction = self.firebase_service.db.transaction()
        user_ref = self.firebase_service.db.collection("users").document(uid)
        return _commit_refund_tx(transaction, self, uid, request, user_ref)

    def _request_refund_tx(
        self,
        transaction,
        uid: str,
        request: RefundRequest,
        user_ref,
    ) -> SecuredActionResult:
        user_snapshot = user_ref.get(transaction=transaction)
        if not user_snapshot.exists:
            raise HTTPException(status_code=404, detail="User not found.")
        wallet = (user_snapshot.to_dict() or {}).get("wallet") or {}
        share = int(wallet.get("shareBalance") or 0)
        if share < request.share_amount:
            raise HTTPException(status_code=400, detail="Refund exceeds Share balance.")
        # Paid first so a cash refund returns unused paid SHARE before free.
        moved = move_currency(wallet, share=-request.share_amount, paid_first=True)

        tx_ref = self.firebase_service.db.collection("walletTransactions").document()
        transaction.update(
            user_ref,
            {
                **moved["updates"],
                "updatedAt": SERVER_TIMESTAMP,
            },
        )
        transaction.set(
            tx_ref,
            {
                "uid": uid,
                "type": "cash_refund_requested",
                "shareAmount": -request.share_amount,
                "createdAt": SERVER_TIMESTAMP,
                **moved["ledger"],
            },
        )
        return SecuredActionResult(
            accepted=True,
            status="refund_requested",
            reason="Cash refund request recorded.",
        )

    def delete_account(self, uid: str) -> SecuredActionResult:
        db = self.firebase_service.db
        user_ref = db.collection("users").document(uid)
        user_snapshot = user_ref.get()
        if not user_snapshot.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found.",
            )

        user_ref.set(
            {
                "uid": uid,
                "accountStatus": "deleted",
                "pushNotificationsEnabled": False,
                "fcmToken": firestore.DELETE_FIELD,
                "wallet": {
                    "shareBalance": 0,
                    "diamondBalance": 0,
                    "valueTokenBalance": 0,
                    "totalDonationValue": 0,
                },
                "updatedAt": SERVER_TIMESTAMP,
                "accountDeletedAt": SERVER_TIMESTAMP,
            },
            merge=True,
        )

        try:
            firebase_auth.delete_user(uid)
        except firebase_auth.UserNotFoundError:
            pass

        return SecuredActionResult(
            accepted=True,
            status="deleted",
            reason="Account deleted and profile anonymized.",
        )

    def apply_winner_reward(
        self,
        uid: str,
        request: WinnerRewardRequest,
    ) -> SecuredActionResult:
        transaction = self.firebase_service.db.transaction()
        user_ref = self.firebase_service.db.collection("users").document(uid)
        activity_ref = self.firebase_service.db.collection("activities").document(
            request.activity_id
        )
        return _commit_winner_tx(
            transaction, self, uid, request, user_ref, activity_ref
        )

    def _apply_winner_reward_tx(
        self,
        transaction,
        uid: str,
        request: WinnerRewardRequest,
        user_ref,
        activity_ref,
    ) -> SecuredActionResult:
        user_snapshot = user_ref.get(transaction=transaction)
        activity_snapshot = activity_ref.get(transaction=transaction)
        if not user_snapshot.exists or not activity_snapshot.exists:
            raise HTTPException(status_code=404, detail="User or activity not found.")

        activity = activity_snapshot.to_dict() or {}
        if activity.get("userId") != uid or activity.get("jenaVerified") is not True:
            raise HTTPException(status_code=403, detail="Verified own activity required.")
        if activity.get("rewardClaimed") is True:
            return self._already_reward_processed_result()

        reward = int(activity.get("valueTokenReward") or 0)
        if reward <= 0:
            raise HTTPException(status_code=400, detail="No reward available.")

        donation = self._donation_amount(reward, request.action)
        retained = reward - donation
        wallet = (user_snapshot.to_dict() or {}).get("wallet") or {}
        current_value = int(wallet.get("valueTokenBalance") or 0)
        if donation > current_value:
            raise HTTPException(status_code=400, detail="Insufficient Value to donate.")

        tx_ref = self.firebase_service.db.collection("walletTransactions").document()
        update_user = {"updatedAt": SERVER_TIMESTAMP}
        if donation > 0:
            update_user["wallet.valueTokenBalance"] = current_value - donation
            update_user["wallet.totalDonationValue"] = firestore.Increment(donation)

        transaction.update(user_ref, update_user)
        transaction.update(
            activity_ref,
            {
                "rewardClaimed": True,
                "rewardAction": request.action,
                "rewardClaimedValue": retained,
                "rewardDonatedValue": donation,
                "rewardProcessedAt": SERVER_TIMESTAMP,
                "updatedAt": SERVER_TIMESTAMP,
            },
        )
        transaction.set(
            tx_ref,
            {
                "uid": uid,
                "activityId": activity_ref.id,
                "type": request.action,
                "valueAmount": -donation,
                "claimedValue": retained,
                "donatedValue": donation,
                "donationTarget": "UNICEF" if donation > 0 else None,
                "createdAt": SERVER_TIMESTAMP,
            },
        )
        return SecuredActionResult(
            accepted=True,
            status="reward_processed",
            reason="Winner reward processed.",
        )

    def _donation_amount(self, reward: int, action: str) -> int:
        if action == "winner_reward_donate_half":
            return reward // 2
        if action == "winner_reward_donate_all":
            return reward
        return 0

    def _already_joined_result(
        self,
        share_balance: int | None = None,
        diamond_balance: int | None = None,
        value_token_balance: int | None = None,
    ) -> SecuredActionResult:
        return SecuredActionResult(
            accepted=True,
            status="already_joined",
            reason="Tournament was already joined.",
            share_credited=0,
            share_balance=share_balance,
            diamond_balance=diamond_balance,
            value_token_balance=value_token_balance,
        )

    def _already_collected_result(self) -> SecuredActionResult:
        return SecuredActionResult(
            accepted=True,
            status="collected",
            reason="Diamond box was already collected.",
        )

    def _already_reward_processed_result(self) -> SecuredActionResult:
        return SecuredActionResult(
            accepted=True,
            status="reward_processed",
            reason="Winner reward was already processed.",
        )

    def _tournament_is_full(self, tournament: dict) -> bool:
        max_participants = int(tournament.get("maxParticipants") or 0)
        if max_participants <= 0:
            return False
        participant_count = int(tournament.get("participantCount") or 0)
        return participant_count >= max_participants

    def _ensure_email_verified(self, uid: str) -> None:
        try:
            auth_user = firebase_auth.get_user(uid)
        except firebase_auth.UserNotFoundError as error:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found.",
            ) from error

        if not auth_user.email:
            return

        provider_ids = {provider.provider_id for provider in auth_user.provider_data}
        if "password" in provider_ids and not auth_user.email_verified:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Email verification is required.",
            )

    def _distance_meters(
        self,
        lat1: float,
        lng1: float,
        lat2: float,
        lng2: float,
    ) -> float:
        radius_m = 6371000
        d_lat = radians(lat2 - lat1)
        d_lng = radians(lng2 - lng1)
        a = (
            sin(d_lat / 2) ** 2
            + cos(radians(lat1)) * cos(radians(lat2)) * sin(d_lng / 2) ** 2
        )
        return 2 * radius_m * asin(sqrt(a))

    @property
    def firebase_service(self) -> FirebaseService:
        if self._firebase_service is None:
            self._firebase_service = FirebaseService()
        return self._firebase_service


@firestore.transactional
def _commit_invite_code_tx(transaction, service, uid: str, user_ref, code: str) -> str:
    # Module-level so the first argument is the Transaction. Decorating a
    # method puts `self` first, which this helper rejects.
    return service._allocate_invite_code(transaction, uid, user_ref, code)


@firestore.transactional
def _commit_validation_tx(
    transaction,
    service,
    uid: str,
    request: ValidateRunRequest,
    result: ValidationResult,
    activity_ref,
    user_ref,
) -> ValidationResult:
    return service._persist_validation_tx(
        transaction, uid, request, result, activity_ref, user_ref
    )


@firestore.transactional
def _commit_harvest_tx(
    transaction,
    service,
    uid: str,
    request: HarvestPedometerRequest,
    user_ref,
    now: datetime | None = None,
) -> SecuredActionResult:
    return service._harvest_pedometer_share_tx(
        transaction, uid, request, user_ref, now
    )


@firestore.transactional
def _commit_shop_tx(
    transaction,
    service,
    uid: str,
    item_id: str,
    user_ref,
) -> SecuredActionResult:
    return service._purchase_shop_item_tx(transaction, uid, item_id, user_ref)


@firestore.transactional
def _commit_join_tx(
    transaction,
    service,
    uid: str,
    request: JoinTournamentRequest,
    user_ref,
    tournament_ref,
    participant_ref,
) -> SecuredActionResult:
    return service._join_tournament_tx(
        transaction, uid, request, user_ref, tournament_ref, participant_ref
    )


@firestore.transactional
def _commit_winner_tx(
    transaction,
    service,
    uid: str,
    request: WinnerRewardRequest,
    user_ref,
    activity_ref,
) -> SecuredActionResult:
    return service._apply_winner_reward_tx(
        transaction, uid, request, user_ref, activity_ref
    )


@firestore.transactional
def _commit_diamond_box_tx(
    transaction,
    service,
    uid: str,
    request: CollectDiamondBoxRequest,
    user_ref,
    box_ref,
    collected_ref,
) -> SecuredActionResult:
    return service._collect_diamond_box_tx(
        transaction, uid, request, user_ref, box_ref, collected_ref
    )


@firestore.transactional
def _commit_signup_reward_tx(
    transaction,
    service,
    uid: str,
    user_ref,
) -> SecuredActionResult:
    return service._claim_signup_reward_tx(transaction, uid, user_ref)


@firestore.transactional
def _commit_signup_free_ticket_tx(
    transaction,
    service,
    uid: str,
    user_ref,
) -> SignupFreeTicketResult:
    return service._grant_signup_free_ticket_tx(transaction, uid, user_ref)


@firestore.transactional
def _commit_refund_tx(
    transaction,
    service,
    uid: str,
    request: RefundRequest,
    user_ref,
) -> SecuredActionResult:
    return service._request_refund_tx(transaction, uid, request, user_ref)


@firestore.transactional
def _commit_share_to_dia_tx(
    transaction,
    service,
    uid: str,
    dia_amount: int,
    user_ref,
) -> ShareToDiaView:
    return service._exchange_share_to_dia_tx(
        transaction, uid, dia_amount, user_ref
    )


@firestore.transactional
def _commit_dia_pack_tx(
    transaction,
    service,
    uid: str,
    pack: dict,
    user_ref,
    purchase_ref,
) -> SecuredActionResult:
    return service._grant_dia_pack_tx(
        transaction, uid, pack, user_ref, purchase_ref
    )


@firestore.transactional
def _commit_hall_of_fame_donate_tx(
    transaction,
    service,
    uid: str,
    user_ref,
) -> SecuredActionResult:
    return service._donate_hall_of_fame_tx(transaction, uid, user_ref)


@firestore.transactional
def _commit_personal_sponsor_tx(
    transaction,
    service,
    uid: str,
    request_id: str,
    purpose: str,
    user_ref,
) -> PersonalSponsorResult:
    return _donate_personal_sponsor(
        service, transaction, uid, request_id, purpose, user_ref
    )


@firestore.transactional
def _commit_coach_plus_tx(
    transaction,
    service,
    product_id: str,
    user_ref,
) -> SecuredActionResult:
    return service._activate_coach_plus_tx(transaction, product_id, user_ref)


@firestore.transactional
def _commit_streak_bonus_tx(
    transaction,
    service,
    uid: str,
    user_ref,
) -> SecuredActionResult:
    return service._claim_streak_bonus_tx(transaction, uid, user_ref)


@firestore.transactional
def _commit_trial_reward_tx(
    transaction,
    service,
    uid: str,
    user_ref,
) -> SecuredActionResult:
    return service._claim_trial_reward_tx(transaction, uid, user_ref)


def _challenge_entry_fee(km: int) -> int:
    if km == 1:
        return 30000
    if km == 3:
        return 60000
    if km == 5:
        return 70000
    if km == 10:
        return 100000
    if km > 10:
        return 100000 + ((km - 10) // 5) * 50000
    return 30000


def _challenge_bep(km: int) -> int:
    return {1: 50, 3: 100, 5: 150, 10: 200}.get(km, 250)


_STREAK_BONUS_DAYS = 7
_STREAK_LOOKBACK_DAYS = 400


def _day_has_activity(snapshot) -> bool:
    if not snapshot.exists:
        return False
    return metric_qualifies(snapshot.to_dict() or {})


def _day_is_rest(snapshot) -> bool:
    if not snapshot.exists:
        return False
    return is_rest_pause(snapshot.to_dict() or {})


def _wallet_int(wallet: dict, key: str) -> int | None:
    raw = wallet.get(key)
    if raw is None:
        return None
    return int(raw)


@firestore.transactional
def _commit_streak_purchase_tx(
    transaction,
    service,
    uid: str,
    item_id: str,
    request_id: str,
    user_ref,
) -> SecuredActionResult:
    return purchase_streak_item(
        service, transaction, uid, item_id, request_id, user_ref
    )


@firestore.transactional
def _commit_run_access_purchase_tx(
    transaction,
    service,
    uid: str,
    item_id: str,
    request_id: str,
    user_ref,
) -> SecuredActionResult:
    return purchase_run_access_item(
        service, transaction, uid, item_id, request_id, user_ref
    )


@firestore.transactional
def _commit_coach_one_point_use_tx(
    transaction,
    service,
    uid: str,
    request_id: str,
    user_ref,
) -> SecuredActionResult:
    return use_coach_one_point(service, transaction, uid, request_id, user_ref)


@firestore.transactional
def _commit_streak_use_tx(
    transaction,
    service,
    uid: str,
    item_id: str,
    request_id: str,
    user_ref,
) -> SecuredActionResult:
    return use_streak_item(service, transaction, uid, item_id, request_id, user_ref)


@firestore.transactional
def _commit_value_purchase_tx(
    transaction,
    service,
    uid: str,
    item_id: str,
    request_id: str,
    user_ref,
) -> SecuredActionResult:
    return purchase_value_item(
        service, transaction, uid, item_id, request_id, user_ref
    )


@firestore.transactional
def _commit_value_use_tx(
    transaction,
    service,
    uid: str,
    item_id: str,
    request_id: str,
    user_ref,
    rest_day: str | None,
) -> SecuredActionResult:
    return use_value_item(
        service, transaction, uid, item_id, request_id, user_ref, rest_day
    )


@firestore.transactional
def _commit_cpr_grant_tx(transaction, service, uid: str, user_ref) -> None:
    grant_coach_plus_cpr(service, transaction, uid, user_ref)


@firestore.transactional
def _commit_use_shop_tx(
    transaction,
    service,
    uid: str,
    item_id: str,
    user_ref,
) -> SecuredActionResult:
    return service._use_shop_item_tx(transaction, uid, item_id, user_ref)


@firestore.transactional
def _commit_nickname_tx(
    transaction,
    service,
    uid: str,
    nickname: str,
    user_ref,
) -> SecuredActionResult:
    return service._change_nickname_tx(transaction, uid, nickname, user_ref)


@firestore.transactional
def _commit_cosmetic_purchase_tx(
    transaction,
    service,
    uid: str,
    item_id: str,
    request_id: str,
    user_ref,
) -> SecuredActionResult:
    return purchase_cosmetic(
        service, transaction, uid, item_id, request_id, user_ref
    )


@firestore.transactional
def _commit_cosmetic_equip_tx(
    transaction,
    service,
    uid: str,
    item_id: str,
    request_id: str,
    user_ref,
    equip: bool,
) -> SecuredActionResult:
    return equip_cosmetic(
        service, transaction, uid, item_id, request_id, user_ref, equip
    )


@firestore.transactional
def _commit_battle_pass_purchase_tx(
    transaction,
    service,
    uid: str,
    item_id: str,
    request_id: str,
    user_ref,
) -> SecuredActionResult:
    return purchase_battle_pass(
        service, transaction, uid, item_id, request_id, user_ref
    )


@firestore.transactional
def _commit_social_purchase_tx(
    transaction,
    service,
    uid: str,
    item_id: str,
    request_id: str,
    user_ref,
) -> SecuredActionResult:
    return purchase_social_item(
        service, transaction, uid, item_id, request_id, user_ref
    )


@firestore.transactional
def _commit_share_activity_purchase_tx(
    transaction,
    service,
    uid: str,
    item_id: str,
    request_id: str,
    user_ref,
) -> SecuredActionResult:
    return purchase_share_activity_item(
        service, transaction, uid, item_id, request_id, user_ref
    )


@firestore.transactional
def _commit_share_activity_use_tx(
    transaction,
    service,
    uid: str,
    item_id: str,
    request_id: str,
    user_ref,
    now: datetime | None = None,
) -> SecuredActionResult:
    return use_share_activity_item(
        service, transaction, uid, item_id, request_id, user_ref, now
    )


@firestore.transactional
def _commit_friend_ghost_use_tx(
    transaction,
    service,
    uid: str,
    request_id: str,
    friend_uid: str | None,
    activity_id: str | None,
    user_ref,
) -> SecuredActionResult:
    return use_friend_ghost(
        service,
        transaction,
        uid,
        request_id,
        friend_uid,
        activity_id,
        user_ref,
    )


@firestore.transactional
def _commit_crew_cheer_use_tx(
    transaction,
    service,
    uid: str,
    request_id: str,
    user_ref,
    now=None,
) -> SecuredActionResult:
    return use_crew_cheer(service, transaction, uid, request_id, user_ref, now=now)


@firestore.transactional
def _commit_crew_found_tx(
    transaction,
    service,
    uid: str,
    name: str,
    pay_with: str,
    request_id: str,
    user_ref,
    crew_ref,
) -> SecuredActionResult:
    return service._found_crew_tx(
        transaction, uid, name, pay_with, request_id, user_ref, crew_ref
    )


@firestore.transactional
def _commit_create_room_tx(
    transaction,
    service,
    uid: str,
    title: str,
    distance_km: int,
    user_ref,
    room_ref,
) -> CreateChallengeRoomResult:
    return service._create_challenge_room_tx(
        transaction, uid, title, distance_km, user_ref, room_ref
    )


@firestore.transactional
def _commit_crew_spend_tx(
    transaction,
    service,
    uid: str,
    action: str,
    user_ref,
) -> SecuredActionResult:
    return service._spend_crew_action_tx(transaction, uid, action, user_ref)


@firestore.transactional
def _commit_crew_gift_tx(
    transaction,
    service,
    uid: str,
    user_ref,
) -> SecuredActionResult:
    return service._grant_crew_items_tx(transaction, uid, user_ref)


@firestore.transactional
def _commit_redeem_referral_tx(
    transaction,
    service,
    uid: str,
    user_ref,
    code: str,
    created_at: datetime | None,
) -> RedeemReferralResult:
    return service._apply_redeem_referral(
        transaction, uid, user_ref, code, created_at
    )
