import hashlib
import hmac
import os

from fastapi import HTTPException, status
from google.cloud import firestore
from google.cloud.firestore_v1 import SERVER_TIMESTAMP

from app.models.payment_webhook import PaymentWebhookRequest, PaymentWebhookResult
from app.services.firebase_service import FirebaseService

SHARE_TOP_UP_AMOUNTS_KRW = {10000}
SPONSOR_PAYMENT_AMOUNTS_SHARE = {1000, 3000, 5000}


class PaymentWebhookService:
    def __init__(self, firebase_service: FirebaseService | None = None) -> None:
        self._firebase_service = firebase_service
        self.webhook_secret = os.getenv("PG_WEBHOOK_SECRET", "")

    def handle_webhook(self, request: PaymentWebhookRequest) -> PaymentWebhookResult:
        if not self.webhook_secret:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="PG_WEBHOOK_SECRET is not configured.",
            )

        self._ensure_supported_currency(request)

        if not self._signature_is_valid(request):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid PG webhook signature.",
            )

        db = self.firebase_service.db
        intent_ref = db.collection("paymentIntents").document(
            request.payment_intent_id
        )
        transaction = db.transaction()
        return self._apply_webhook_in_transaction(transaction, intent_ref, request)

    @firestore.transactional
    def _apply_webhook_in_transaction(
        self,
        transaction,
        intent_ref,
        request: PaymentWebhookRequest,
    ) -> PaymentWebhookResult:
        intent_snapshot = intent_ref.get(transaction=transaction)
        if not intent_snapshot.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Payment intent does not exist.",
            )

        intent = intent_snapshot.to_dict() or {}
        expected_amount = intent.get("amountKrw") or intent.get("amountShare")
        current_status = intent.get("status")

        if current_status == "credited":
            return self._already_processed_result(request.payment_intent_id)

        if expected_amount != request.amount:
            transaction.update(
                intent_ref,
                {
                    "status": "amount_mismatch",
                    "pgTransactionId": request.pg_transaction_id,
                    "pgAmount": request.amount,
                    "updatedAt": SERVER_TIMESTAMP,
                }
            )
            return PaymentWebhookResult(
                accepted=False,
                payment_intent_id=request.payment_intent_id,
                status="amount_mismatch",
                reason="Payment amount does not match intent amount.",
            )

        if request.status != "paid":
            mapped_status = f"pg_{request.status}"
            transaction.update(
                intent_ref,
                {
                    "status": mapped_status,
                    "pgTransactionId": request.pg_transaction_id,
                    "updatedAt": SERVER_TIMESTAMP,
                }
            )
            return PaymentWebhookResult(
                accepted=True,
                payment_intent_id=request.payment_intent_id,
                status=mapped_status,
                reason="PG reported a non-paid terminal status.",
            )

        intent_type = intent.get("type")
        self._ensure_supported_amount(intent_type, expected_amount)

        if intent_type == "share_top_up":
            return self._credit_share_top_up(
                transaction=transaction,
                intent_ref=intent_ref,
                intent=intent,
                request=request,
            )

        if intent_type == "sponsor_payment":
            return self._apply_sponsor_payment(
                transaction=transaction,
                intent_ref=intent_ref,
                intent=intent,
                request=request,
            )

        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unsupported payment intent type: {intent_type}",
        )

    def _credit_share_top_up(
        self,
        transaction,
        intent_ref,
        intent: dict,
        request: PaymentWebhookRequest,
    ) -> PaymentWebhookResult:
        uid = self._share_top_up_uid_from_intent(intent)

        user_ref = self.firebase_service.db.collection("users").document(uid)
        user_snapshot = user_ref.get(transaction=transaction)
        if not user_snapshot.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User document does not exist.",
            )

        wallet = (user_snapshot.to_dict() or {}).get("wallet") or {}
        current_share = int(wallet.get("shareBalance") or 0)
        share_amount = request.amount
        tx_ref = self.firebase_service.db.collection("walletTransactions").document()

        transaction.update(
            user_ref,
            {
                "wallet.shareBalance": current_share + share_amount,
                "updatedAt": SERVER_TIMESTAMP,
            },
        )
        transaction.set(
            tx_ref,
            {
                "uid": uid,
                "paymentIntentId": request.payment_intent_id,
                "pgTransactionId": request.pg_transaction_id,
                "type": "share_top_up",
                "shareAmount": share_amount,
                "createdAt": SERVER_TIMESTAMP,
            },
        )
        transaction.update(
            intent_ref,
            {
                "status": "credited",
                "pgTransactionId": request.pg_transaction_id,
                "verifiedAmount": request.amount,
                "verifiedCurrency": request.currency,
                "serverVerifiedAt": SERVER_TIMESTAMP,
                "creditedAt": SERVER_TIMESTAMP,
                "updatedAt": SERVER_TIMESTAMP,
            },
        )

        return PaymentWebhookResult(
            accepted=True,
            payment_intent_id=request.payment_intent_id,
            status="credited",
            reason="Share top-up verified and credited.",
        )

    def _apply_sponsor_payment(
        self,
        transaction,
        intent_ref,
        intent: dict,
        request: PaymentWebhookRequest,
    ) -> PaymentWebhookResult:
        tournament_id = intent.get("tournamentId")
        option = intent.get("option")
        sponsor_uid = self._sponsor_uid_from_intent(intent)
        if not tournament_id or not option:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Sponsor payment intent is missing tournament data.",
            )

        tournament_ref = self.firebase_service.db.collection("tournaments").document(
            tournament_id
        )
        tournament_snapshot = tournament_ref.get(transaction=transaction)
        if not tournament_snapshot.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Tournament document does not exist.",
            )

        tournament = tournament_snapshot.to_dict() or {}
        tx_ref = self.firebase_service.db.collection("walletTransactions").document()

        direct_support = int(tournament.get("sponsorPrizeSupportShare") or 0)
        donation_support = int(tournament.get("sponsorDonationSupportShare") or 0)
        update_payload = {
            "updatedAt": SERVER_TIMESTAMP,
        }

        if option == "direct_prize_support":
            update_payload["sponsorPrizeSupportShare"] = direct_support + request.amount
        elif option == "winner_named_unicef_donation":
            update_payload["sponsorDonationSupportShare"] = (
                donation_support + request.amount
            )
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Unsupported sponsor option: {option}",
            )

        transaction.update(tournament_ref, update_payload)
        transaction.set(
            tx_ref,
            {
                "uid": sponsor_uid,
                "paymentIntentId": request.payment_intent_id,
                "pgTransactionId": request.pg_transaction_id,
                "sponsorId": sponsor_uid,
                "tournamentId": tournament_id,
                "type": "sponsor_payment_verified",
                "option": option,
                "shareAmount": request.amount,
                "createdAt": SERVER_TIMESTAMP,
            },
        )
        transaction.update(
            intent_ref,
            {
                "status": "credited",
                "pgTransactionId": request.pg_transaction_id,
                "verifiedAmount": request.amount,
                "verifiedCurrency": request.currency,
                "serverVerifiedAt": SERVER_TIMESTAMP,
                "creditedAt": SERVER_TIMESTAMP,
                "updatedAt": SERVER_TIMESTAMP,
            },
        )

        return PaymentWebhookResult(
            accepted=True,
            payment_intent_id=request.payment_intent_id,
            status="credited",
            reason="Sponsor payment verified and applied.",
        )

    def _signature_is_valid(self, request: PaymentWebhookRequest) -> bool:
        expected = hmac.new(
            self.webhook_secret.encode("utf-8"),
            self._signature_payload(request).encode("utf-8"),
            hashlib.sha256,
        ).hexdigest()

        return hmac.compare_digest(expected, request.signature)

    def _ensure_supported_currency(self, request: PaymentWebhookRequest) -> None:
        if request.currency.upper() != "KRW":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Only KRW payment webhooks are supported.",
            )

    def _ensure_supported_amount(self, intent_type: str | None, amount: int) -> None:
        if intent_type == "share_top_up" and amount in SHARE_TOP_UP_AMOUNTS_KRW:
            return
        if intent_type == "sponsor_payment" and amount in SPONSOR_PAYMENT_AMOUNTS_SHARE:
            return
        if intent_type not in {"share_top_up", "sponsor_payment"}:
            return
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Payment intent amount is not supported.",
        )

    def _sponsor_uid_from_intent(self, intent: dict) -> str:
        uid = intent.get("uid")
        sponsor_id = intent.get("sponsorId")
        if not uid or sponsor_id != uid:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Sponsor payment intent has invalid owner identity.",
            )
        return str(uid)

    def _share_top_up_uid_from_intent(self, intent: dict) -> str:
        uid = intent.get("uid")
        sponsor_id = intent.get("sponsorId")
        if not uid or (sponsor_id is not None and sponsor_id != uid):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Share top-up intent has invalid owner identity.",
            )
        return str(uid)

    def _signature_payload(self, request: PaymentWebhookRequest) -> str:
        return (
            f"{request.payment_intent_id}."
            f"{request.pg_transaction_id}."
            f"{request.amount}."
            f"{request.status}"
        )

    def _already_processed_result(self, payment_intent_id: str) -> PaymentWebhookResult:
        return PaymentWebhookResult(
            accepted=True,
            payment_intent_id=payment_intent_id,
            status="credited",
            reason="Payment intent was already processed.",
        )

    @property
    def firebase_service(self) -> FirebaseService:
        if self._firebase_service is None:
            self._firebase_service = FirebaseService()
        return self._firebase_service
