from firebase_admin import firestore

from app.services.firebase_service import FirebaseService


class AdminAuditService:
    """Writes adminAuditLogs. Does not read or change wallet balances."""

    def __init__(self, firebase_service: FirebaseService | None = None) -> None:
        self.firebase_service = firebase_service

    def write(
        self,
        *,
        uid: str,
        email: str | None,
        action: str,
        target_uid: str | None = None,
        before: dict | None = None,
        after: dict | None = None,
        reason: str | None = None,
    ) -> str:
        service = self.firebase_service or FirebaseService()
        ref = service.db.collection("adminAuditLogs").document()
        ref.set(
            {
                "uid": uid,
                "email": email,
                "createdAt": firestore.SERVER_TIMESTAMP,
                "action": action,
                "targetUid": target_uid,
                "before": before,
                "after": after,
                "reason": reason,
            }
        )
        return ref.id


admin_audit_service = AdminAuditService()
