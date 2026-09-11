from math import asin, cos, radians, sin, sqrt

from fastapi import HTTPException, status
from firebase_admin import auth as firebase_auth
from google.cloud import firestore
from google.cloud.firestore_v1 import SERVER_TIMESTAMP

from app.models.secured_actions import (
    CollectDiamondBoxRequest,
    DebugTestGrantRequest,
    HarvestPedometerRequest,
    JoinTournamentRequest,
    RefundRequest,
    SecuredActionResult,
    SettleTournamentFailureRequest,
    ValidateRunRequest,
    Web3TransferRequest,
    WinnerRewardRequest,
)
from app.services.firebase_service import FirebaseService
from app.constants.economy_constants import (
    TEST_WALLET_GRANT_AMOUNT,
    TEST_WALLET_GRANT_DEBUG_CLIENT_SECRET,
    TEST_WALLET_GRANT_ELIGIBLE_FLAG,
    TEST_WALLET_GRANT_FLAG,
)
from app.models.validation_request import ValidationRequest
from app.models.validation_result import ValidationResult
from app.services.economy_service import EconomyService
from app.services.mercy_rule_service import MercyRuleService
from app.services.running_validation_service import RunningValidationService


class SecuredActionService:
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
        return self._persist_validation_tx(
            transaction, uid, request, result, activity_ref, user_ref
        )

    def claim_signup_reward(self, uid: str) -> SecuredActionResult:
        transaction = self.firebase_service.db.transaction()
        user_ref = self.firebase_service.db.collection("users").document(uid)
        return self._claim_signup_reward_tx(transaction, uid, user_ref)

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

    def purchase_shop_item(
        self,
        uid: str,
        item_id: str,
    ) -> SecuredActionResult:
        transaction = self.firebase_service.db.transaction()
        user_ref = self.firebase_service.db.collection("users").document(uid)
        return self._purchase_shop_item_tx(transaction, uid, item_id, user_ref)

    def transfer_value_to_web3(
        self,
        uid: str,
        request: Web3TransferRequest,
    ) -> SecuredActionResult:
        transaction = self.firebase_service.db.transaction()
        user_ref = self.firebase_service.db.collection("users").document(uid)
        return self._transfer_value_to_web3_tx(transaction, uid, request, user_ref)

    @firestore.transactional
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
                referred_by = economy.get("referredByUid")
                if referred_by:
                    self._pay_referral_reward_tx(
                        transaction,
                        invitee_uid=uid,
                        referrer_uid=referred_by,
                    )

        if economy_updates:
            user_updates["economy"] = {**economy, **economy_updates}

        if len(user_updates) > 1:
            transaction.update(user_ref, user_updates)

        if result.forfeit_deposit:
            self._forfeit_active_deposit_tx(transaction, uid, user_ref, activity_ref.id)

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
            "diamondCost": 3,
        },
        "record_safe_guard": {
            "title": "기록 마감 세이프 가드",
            "diamondCost": 5,
        },
        "ghost_pace_match": {
            "title": "고스트 페이스 매칭",
            "diamondCost": 8,
        },
        "battle_run_pass": {
            "title": "배틀런 챌린지 패스",
            "diamondCost": 15,
        },
    }

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

    @firestore.transactional
    def _transfer_value_to_web3_tx(
        self,
        transaction,
        uid: str,
        request: Web3TransferRequest,
        user_ref,
    ) -> SecuredActionResult:
        user_snapshot = user_ref.get(transaction=transaction)
        if not user_snapshot.exists:
            raise HTTPException(status_code=404, detail="User not found.")

        self._debit_value_tx(
            transaction,
            uid=uid,
            user_ref=user_ref,
            amount=request.amount_srv,
            tx_type="web3_transfer",
            extra_fields={
                "destinationAddress": request.destination_address,
                "transferChannel": request.transfer_channel,
            },
        )
        channel_label = (
            "외부 지갑"
            if request.transfer_channel == "external_wallet"
            else "DEX"
        )
        return SecuredActionResult(
            accepted=True,
            status="transferred",
            reason=(
                f"{request.amount_srv} SRV가 {channel_label} "
                f"({request.destination_address[:10]}...)로 전송되었습니다. "
                "앱 내 현금 환전은 제공하지 않습니다."
            ),
        )

    @firestore.transactional
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
        transaction.update(
            user_ref,
            {
                "economy": {
                    **economy,
                    "signupRewardClaimed": True,
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
            reason="Referral code saved. Referrer reward pays after 5 trial runs.",
        )

    def _pay_referral_reward_tx(
        self,
        transaction,
        *,
        invitee_uid: str,
        referrer_uid: str,
    ) -> None:
        if not referrer_uid or referrer_uid == invitee_uid:
            return

        referrer_ref = self.firebase_service.db.collection("users").document(referrer_uid)
        referrer_snapshot = referrer_ref.get(transaction=transaction)
        if not referrer_snapshot.exists:
            return

        referrer = referrer_snapshot.to_dict() or {}
        referrer_economy = referrer.get("economy") or {}
        if not self._economy_service.can_pay_referrer(referrer_economy):
            return

        reward = self._economy_service.referral_reward_amount()
        self._credit_value_tx(
            transaction,
            uid=referrer_uid,
            user_ref=referrer_ref,
            amount=reward,
            tx_type="referral_reward",
            extra_fields={"inviteeUid": invitee_uid},
        )
        transaction.update(
            referrer_ref,
            {
                "economy.referralPayoutCount": firestore.Increment(1),
                "updatedAt": SERVER_TIMESTAMP,
            },
        )

    @firestore.transactional
    def _purchase_shop_item_tx(
        self,
        transaction,
        uid: str,
        item_id: str,
        user_ref,
    ) -> SecuredActionResult:
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

        inventory_ref = user_ref.collection("shopInventory").document(item_id)
        inventory_snapshot = inventory_ref.get(transaction=transaction)
        current_qty = 0
        if inventory_snapshot.exists:
            current_qty = int((inventory_snapshot.to_dict() or {}).get("quantity") or 0)

        tx_ref = self.firebase_service.db.collection("walletTransactions").document()
        transaction.update(
            user_ref,
            {
                "wallet.diamondBalance": diamond_balance - cost,
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
                "diamondAmount": cost,
                "itemId": item_id,
                "createdAt": SERVER_TIMESTAMP,
            },
        )
        return SecuredActionResult(
            accepted=True,
            status="purchased",
            reason=f"Purchased {catalog_item['title']}.",
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

    def join_tournament(
        self,
        uid: str,
        request: JoinTournamentRequest,
    ) -> SecuredActionResult:
        self._ensure_email_verified(uid)
        transaction = self.firebase_service.db.transaction()
        tournament_ref = self.firebase_service.db.collection("tournaments").document(
            request.tournament_id
        )
        user_ref = self.firebase_service.db.collection("users").document(uid)
        participant_ref = tournament_ref.collection("participants").document(uid)
        return self._join_tournament_tx(
            transaction, uid, request, user_ref, tournament_ref, participant_ref
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

    @firestore.transactional
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

        if not user_snapshot.exists or not tournament_snapshot.exists:
            raise HTTPException(status_code=404, detail="User or tournament not found.")

        user = user_snapshot.to_dict() or {}
        tournament = tournament_snapshot.to_dict() or {}
        share, diamonds, value = self._wallet_balances(user)
        if participant_snapshot.exists:
            return self._already_joined_result(
                share_balance=share,
                diamond_balance=diamonds,
                value_token_balance=value,
            )

        user_tier = int(user.get("tier") or 1)
        required_tier = int(tournament.get("requiredTier") or 1)
        entry_fee = int(tournament.get("entryFeeShare") or 0)
        required_deposit = int(tournament.get("diamondDepositRequired") or 0)
        diamond_deposit = request.diamond_deposit or required_deposit
        selected_charity = request.selected_charity or "UNICEF"

        if tournament.get("status", "recruiting") != "recruiting":
            raise HTTPException(status_code=400, detail="Tournament is not recruiting.")
        if required_tier < user_tier:
            raise HTTPException(status_code=403, detail="Lower-tier room is locked.")
        if self._tournament_is_full(tournament):
            raise HTTPException(status_code=409, detail="Tournament is full.")
        if share < entry_fee:
            raise HTTPException(status_code=400, detail="Insufficient Share balance.")
        if diamond_deposit > 0 and diamonds < diamond_deposit:
            raise HTTPException(status_code=400, detail="Insufficient Diamond deposit.")

        user_updates = {
            "wallet.shareBalance": share - entry_fee,
            "updatedAt": SERVER_TIMESTAMP,
        }
        if diamond_deposit > 0:
            user_updates["wallet.diamondBalance"] = diamonds - diamond_deposit

        tx_ref = self.firebase_service.db.collection("walletTransactions").document()
        transaction.update(user_ref, user_updates)
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
            },
        )
        transaction.set(
            tx_ref,
            {
                "uid": uid,
                "tournamentId": tournament_ref.id,
                "type": "tournament_entry",
                "shareAmount": entry_fee,
                "diamondAmount": diamond_deposit,
                "charityTarget": selected_charity if diamond_deposit > 0 else None,
                "createdAt": SERVER_TIMESTAMP,
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
        if settlement.returned_diamonds > 0:
            user_updates["wallet.diamondBalance"] = firestore.Increment(
                settlement.returned_diamonds
            )
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
        return self._collect_diamond_box_tx(
            transaction, uid, request, user_ref, box_ref, collected_ref
        )

    @firestore.transactional
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
        tx_ref = self.firebase_service.db.collection("walletTransactions").document()
        transaction.update(
            user_ref,
            {
                "wallet.diamondBalance": firestore.Increment(reward),
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
        return self._harvest_pedometer_share_tx(
            transaction, uid, request, user_ref
        )

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

    @firestore.transactional
    def _harvest_pedometer_share_tx(
        self,
        transaction,
        uid: str,
        request: HarvestPedometerRequest,
        user_ref,
    ) -> SecuredActionResult:
        user_snapshot = user_ref.get(transaction=transaction)
        if not user_snapshot.exists:
            raise HTTPException(status_code=404, detail="User not found.")

        user = user_snapshot.to_dict() or {}
        current_share, current_dia, current_value = self._wallet_balances(user)
        today = self._economy_service.kst_today_key()
        harvest = self._economy_service.normalize_pedometer_harvest(
            user.get("pedometerHarvest"),
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

        share = self._economy_service.pedometer_harvest_share(
            claimed_steps=claimed,
            prev_claimed_steps=prev_claimed,
            harvested_share=harvested,
        )
        new_share = current_share + share
        # Dotted SHARE field only — never replace the wallet map (DIA/VALUE).
        updates = {
            "pedometerHarvest.dateKey": today,
            "pedometerHarvest.claimedSteps": claimed,
            "pedometerHarvest.harvestedShare": harvested + share,
            "updatedAt": SERVER_TIMESTAMP,
        }
        if share > 0:
            updates["wallet.shareBalance"] = new_share
            tx_ref = self.firebase_service.db.collection(
                "walletTransactions"
            ).document()
            transaction.set(
                tx_ref,
                {
                    "uid": uid,
                    "type": "pedometer_harvest",
                    "shareAmount": share,
                    "claimedSteps": claimed,
                    "createdAt": SERVER_TIMESTAMP,
                },
            )
        transaction.update(user_ref, updates)
        if share <= 0:
            return self._harvest_result(
                status="daily_cap_reached",
                reason="Walking challenge daily SHARE cap reached.",
                share_credited=0,
                share_balance=current_share,
                diamond_balance=current_dia,
                value_token_balance=current_value,
            )
        return self._harvest_result(
            status="harvested",
            reason=f"{share} SHARE credited from walking challenge.",
            share_credited=share,
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
    ) -> SecuredActionResult:
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
        request: DebugTestGrantRequest,
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
        if not self.is_test_grant_authorized(
            uid,
            user,
            request.grant_secret,
            debug_client=request.debug_client,
        ):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not eligible for debug test grant.",
            )

        amount = TEST_WALLET_GRANT_AMOUNT
        # Dotted fields only — keep wallet.totalDonationValue intact.
        transaction.update(
            user_ref,
            {
                "wallet.shareBalance": amount,
                "wallet.diamondBalance": amount,
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
        return self._request_refund_tx(transaction, uid, request, user_ref)

    @firestore.transactional
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

        tx_ref = self.firebase_service.db.collection("walletTransactions").document()
        transaction.update(
            user_ref,
            {
                "wallet.shareBalance": share - request.share_amount,
                "updatedAt": SERVER_TIMESTAMP,
            },
        )
        transaction.set(
            tx_ref,
            {
                "uid": uid,
                "type": "cash_refund_requested",
                "shareAmount": request.share_amount,
                "createdAt": SERVER_TIMESTAMP,
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
        return self._apply_winner_reward_tx(
            transaction, uid, request, user_ref, activity_ref
        )

    @firestore.transactional
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
                "valueAmount": reward,
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
