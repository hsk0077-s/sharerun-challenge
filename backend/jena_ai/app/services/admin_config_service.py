from datetime import date, datetime
from typing import Any

from app.models.admin_api import ConfigDocument, ConfigListResult
from app.services.admin_audit_service import admin_audit_service
from app.services.firebase_service import FirebaseService

# 운영자가 눈으로 확인할 설정 문서. 고치는 화면이 아니라 보는 화면이다.
# 값을 바꾸는 일은 계속 서버 배포·Firestore 콘솔로 한다.
CONFIG_DOCUMENT_IDS: tuple[tuple[str, str], ...] = (
    ("item_prices", "아이템 가격"),
    ("referral_trial", "추천인 체험·보상"),
    ("promotion", "프로모션"),
    ("company_donation", "회사 기부"),
    ("funding_goal", "기부 펀딩 목표"),
    ("company_tournament", "회사 대회"),
)


def _plain(value: Any) -> Any:
    """JSON으로 내보낼 수 있는 값으로 바꾼다 (Firestore 시간 등)."""
    if isinstance(value, dict):
        return {str(k): _plain(v) for k, v in value.items()}
    if isinstance(value, (list, tuple)):
        return [_plain(v) for v in value]
    if isinstance(value, (datetime, date)):
        return value.isoformat()
    if value is None or isinstance(value, (bool, int, float, str)):
        return value
    return str(value)


class AdminConfigService:
    def __init__(self, firebase_service: FirebaseService | None = None) -> None:
        self.firebase_service = firebase_service

    def read_all(self, *, actor_uid: str, actor_email: str | None) -> ConfigListResult:
        db = (self.firebase_service or FirebaseService()).db
        documents: list[ConfigDocument] = []
        for doc_id, title in CONFIG_DOCUMENT_IDS:
            snap = db.collection("config").document(doc_id).get()
            exists = bool(getattr(snap, "exists", False))
            data = (snap.to_dict() or {}) if exists else {}
            documents.append(
                ConfigDocument(id=doc_id, title=title, exists=exists, data=_plain(data))
            )
        admin_audit_service.write(
            uid=actor_uid,
            email=actor_email,
            action="config_view",
            target_uid=None,
            reason="read config documents",
        )
        return ConfigListResult(documents=documents)


admin_config_service = AdminConfigService()
