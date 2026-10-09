from fastapi import HTTPException, status
from google.cloud import firestore
from google.cloud.firestore_v1 import SERVER_TIMESTAMP
import logging

from app.models.ops_result import (
    ActivateTournamentResult,
    BepRefundResult,
    CreatePrizeRaceResult,
    GradeBackfillResult,
    PrizeSettlementResult,
    PurgeDeletedAccountsResult,
    PurgeUserResult,
)
from app.services.company_tournament_settlement import (
    create_company_prize_race as open_company_prize_race,
    settle_company_prize_race,
)
from app.services.firebase_service import FirebaseService
from app.services.grade_assignment import backfill_grades
from app.services.notification_service import send_tournament_topic_notification
from app.services.wallet_funding import move_currency

logger = logging.getLogger(__name__)


class OpsService:
    def __init__(self, firebase_service: FirebaseService | None = None) -> None:
        self._firebase_service = firebase_service

    def cancel_bep_and_refund(self, tournament_id: str) -> BepRefundResult:
        transaction = self.firebase_service.db.transaction()
        refunded_count, refunded_total = _commit_bep_refund_tx(
            transaction, self, tournament_id
        )

        self._try_send_tournament_notification(
            tournament_id,
            title="SRC Tournament Update",
            body="BEP 미달로 대회가 취소되었고 Share 환불이 처리되었습니다.",
        )

        return BepRefundResult(
            accepted=True,
            tournament_id=tournament_id,
            refunded_participants=refunded_count,
            refunded_share_total=refunded_total,
            status="cancelled_bep_not_met",
            reason="Tournament cancelled because BEP was not met; Share refunded without fee.",
        )

    def backfill_grades(self, dry_run: bool = True) -> GradeBackfillResult:
        return GradeBackfillResult(
            **backfill_grades(self.firebase_service.db, dry_run=dry_run)
        )

    def activate_tournament(self, tournament_id: str) -> ActivateTournamentResult:
        db = self.firebase_service.db
        tournament_ref = db.collection("tournaments").document(tournament_id)
        tournament_snapshot = tournament_ref.get()

        if not tournament_snapshot.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Tournament does not exist.",
            )

        tournament = tournament_snapshot.to_dict() or {}
        participant_count = int(tournament.get("participantCount") or 0)
        min_participants_bep = int(tournament.get("minParticipantsBep") or 0)
        current_status = tournament.get("status", "recruiting")

        if current_status == "active":
            return ActivateTournamentResult(
                accepted=True,
                tournament_id=tournament_id,
                participant_count=participant_count,
                status="active",
                reason="Tournament was already active.",
            )

        if current_status != "recruiting":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Only recruiting tournaments can be activated.",
            )

        if participant_count < min_participants_bep:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="BEP has not been met; tournament cannot be activated.",
            )

        tournament_ref.update(
            {
                "status": "active",
                "activatedAt": SERVER_TIMESTAMP,
                "updatedAt": SERVER_TIMESTAMP,
            }
        )

        title = tournament.get("title") or "SRC Tournament"
        self._try_send_tournament_notification(
            tournament_id,
            title="SRC Tournament Started",
            body=f'"{title}" 대회가 시작되었습니다. 러닝을 시작해 보세요!',
        )

        return ActivateTournamentResult(
            accepted=True,
            tournament_id=tournament_id,
            participant_count=participant_count,
            status="active",
            reason="Tournament activated and participants notified.",
        )

    def create_company_prize_race(
        self, tournament_id: str, tier: str, edition: int
    ) -> CreatePrizeRaceResult:
        return open_company_prize_race(
            self.firebase_service.db, tournament_id, tier, edition
        )

    def settle_company_tournament(self, tournament_id: str) -> PrizeSettlementResult:
        return settle_company_prize_race(self.firebase_service.db, tournament_id)

    def purge_user_data(self, uid: str) -> PurgeUserResult:
        db = self.firebase_service.db
        user_ref = db.collection("users").document(uid)
        user_snapshot = user_ref.get()
        if not user_snapshot.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found.",
            )

        user = user_snapshot.to_dict() or {}
        if user.get("accountStatus") != "deleted":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Only deleted accounts can be purged.",
            )
        if user.get("accountPurgedAt") is not None:
            return PurgeUserResult(
                accepted=True,
                uid=uid,
                deleted_activities=0,
                deleted_diamond_collections=0,
                status="already_purged",
                reason="User data was already purged.",
            )

        deleted_activities = 0
        for activity_snapshot in (
            db.collection("activities").where("userId", "==", uid).stream()
        ):
            activity_snapshot.reference.delete()
            deleted_activities += 1

        deleted_collections = 0
        for box_snapshot in user_ref.collection("collectedDiamondBoxes").stream():
            box_snapshot.reference.delete()
            deleted_collections += 1

        user_ref.set(
            {
                "uid": uid,
                "accountStatus": "purged",
                "pushNotificationsEnabled": False,
                "fcmToken": firestore.DELETE_FIELD,
                "sensitiveDataConsent": False,
                "watchType": "none",
                "accountPurgedAt": SERVER_TIMESTAMP,
                "updatedAt": SERVER_TIMESTAMP,
            },
            merge=True,
        )

        return PurgeUserResult(
            accepted=True,
            uid=uid,
            deleted_activities=deleted_activities,
            deleted_diamond_collections=deleted_collections,
            status="purged",
            reason="Deleted account data purged from Firestore.",
        )

    def purge_deleted_accounts(self, limit: int = 50) -> PurgeDeletedAccountsResult:
        db = self.firebase_service.db
        snapshots = (
            db.collection("users")
            .where("accountStatus", "==", "deleted")
            .limit(limit)
            .stream()
        )

        purged_users: list[str] = []
        for user_snapshot in snapshots:
            user = user_snapshot.to_dict() or {}
            if user.get("accountPurgedAt") is not None:
                continue
            result = self.purge_user_data(user_snapshot.id)
            if result.accepted:
                purged_users.append(user_snapshot.id)

        return PurgeDeletedAccountsResult(
            accepted=True,
            processed_users=len(purged_users),
            purged_users=purged_users,
            status="completed",
            reason="Deleted accounts purge batch completed.",
        )

    def _try_send_tournament_notification(
        self,
        tournament_id: str,
        *,
        title: str,
        body: str,
    ) -> None:
        try:
            send_tournament_topic_notification(
                tournament_id,
                title=title,
                body=body,
            )
        except Exception:
            logger.exception(
                "Failed to send tournament topic notification for %s",
                tournament_id,
            )

    @property
    def firebase_service(self) -> FirebaseService:
        if self._firebase_service is None:
            self._firebase_service = FirebaseService()
        return self._firebase_service


def bep_refund_ledger_id(tournament_id: str, uid: str) -> str:
    return f"bep_refund_{tournament_id}_{uid}"


@firestore.transactional
def _commit_bep_refund_tx(transaction, service: OpsService, tournament_id: str):
    db = service.firebase_service.db
    tournament_ref = db.collection("tournaments").document(tournament_id)
    tournament_snapshot = tournament_ref.get(transaction=transaction)
    if not tournament_snapshot.exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Tournament does not exist.",
        )

    tournament = tournament_snapshot.to_dict() or {}
    participant_count = int(tournament.get("participantCount") or 0)
    min_participants_bep = int(tournament.get("minParticipantsBep") or 0)
    current_status = tournament.get("status", "recruiting")
    if participant_count >= min_participants_bep:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="BEP has been met; tournament cannot be cancelled.",
        )
    if current_status not in {"recruiting", "cancelled_bep_not_met"}:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only recruiting or already-BEP-cancelled tournaments can be refunded.",
        )

    participants = list(
        transaction.get(tournament_ref.collection("participants"))
    )
    plans = []
    for participant_snapshot in participants:
        participant = participant_snapshot.to_dict() or {}
        if participant.get("refundStatus") == "refunded":
            continue
        if participant.get("status") not in {"joined", "refundable"}:
            continue
        uid = participant.get("uid") or participant_snapshot.id
        entry_fee = int(participant.get("entryFeeShare") or 0)
        if entry_fee <= 0:
            continue
        user_ref = db.collection("users").document(uid)
        ledger_ref = db.collection("walletTransactions").document(
            bep_refund_ledger_id(tournament_id, uid)
        )
        user_snapshot = user_ref.get(transaction=transaction)
        if ledger_ref.get(transaction=transaction).exists:
            continue
        if not user_snapshot.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found.",
            )
        wallet = (user_snapshot.to_dict() or {}).get("wallet") or {}
        plans.append(
            (user_ref, ledger_ref, participant_snapshot.reference, entry_fee, wallet, uid)
        )

    transaction.update(
        tournament_ref,
        {
            "status": "cancelled_bep_not_met",
            "cancelledReason": "bep_not_met",
            "updatedAt": SERVER_TIMESTAMP,
        },
    )
    refunded_count = 0
    refunded_total = 0
    for user_ref, ledger_ref, participant_ref, entry_fee, wallet, uid in plans:
        moved = move_currency(wallet, share=entry_fee)
        transaction.update(
            user_ref,
            {**moved["updates"], "updatedAt": SERVER_TIMESTAMP},
        )
        transaction.update(
            participant_ref,
            {
                "refundStatus": "refunded",
                "refundedShare": entry_fee,
                "refundedAt": SERVER_TIMESTAMP,
                "status": "refunded",
            },
        )
        transaction.set(
            ledger_ref,
            {
                "uid": uid,
                "tournamentId": tournament_id,
                "type": "bep_refund",
                "shareAmount": entry_fee,
                "fee": 0,
                "createdAt": SERVER_TIMESTAMP,
                **moved["ledger"],
            },
        )
        refunded_count += 1
        refunded_total += entry_fee
    return refunded_count, refunded_total
