from fastapi import HTTPException, status

from app.models.admin_api import UserDetailCrew, UserDetailResult
from app.services.admin_audit_service import admin_audit_service
from app.services.firebase_service import FirebaseService


class AdminUserDetailService:
    """Reads one user's profile, login providers, reward block and crew."""

    def __init__(self, firebase_service: FirebaseService | None = None) -> None:
        self.firebase_service = firebase_service

    def lookup(
        self,
        *,
        uid: str,
        actor_uid: str,
        actor_email: str | None,
    ) -> UserDetailResult:
        owner = _uid(uid)
        db = (self.firebase_service or FirebaseService()).db
        snap = db.collection("users").document(owner).get()
        if not getattr(snap, "exists", False):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found.",
            )
        user = snap.to_dict() or {}
        block = db.collection("rewardBlocks").document(owner).get()
        blocked = bool(getattr(block, "exists", False))
        block_data = (block.to_dict() or {}) if blocked else {}
        admin_audit_service.write(
            uid=actor_uid,
            email=actor_email,
            action="user_detail_lookup",
            target_uid=owner,
            reason="read user detail",
        )
        return UserDetailResult(
            uid=owner,
            nickname=_text(user.get("nickname")),
            email=_text(user.get("email")),
            country=_country(user),
            providers=self._providers(db, owner),
            rewardBlocked=blocked,
            rewardBlockReason=_text(block_data.get("reason")),
            rewardBlockedAt=_iso(block_data.get("createdAt")),
            crew=self._crew(db, user),
        )

    def _providers(self, db, uid: str) -> list[str]:
        names: set[str] = set()
        for row in db.collection("authIdentities").where("uid", "==", uid).get():
            data = row.to_dict() or {}
            provider = _text(data.get("provider"))
            if provider is None and ":" in str(row.id):
                provider = str(row.id).split(":", 1)[0] or None
            if provider:
                names.add(provider)
        return sorted(names)

    def _crew(self, db, user: dict) -> UserDetailCrew | None:
        crew_id = _text(user.get("crewId")) or _text(user.get("ownedCrewId"))
        if crew_id is None or "/" in crew_id:
            return None
        name = _text(user.get("crewName"))
        if name is None:
            crew = db.collection("crews").document(crew_id).get()
            if getattr(crew, "exists", False):
                name = _text((crew.to_dict() or {}).get("name"))
        return UserDetailCrew(id=crew_id, name=name)


def _uid(uid: str) -> str:
    text = uid.strip()
    if not text or "/" in text or len(text) > 128:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid uid.",
        )
    return text


def _text(value: object) -> str | None:
    if not isinstance(value, str):
        return None
    text = value.strip()
    return text or None


def _country(user: dict) -> str | None:
    for key in ("countryCode", "country", "locale"):
        text = _text(user.get(key))
        if text:
            return text
    return None


def _iso(value: object) -> str | None:
    if isinstance(value, str):
        return _text(value)
    isoformat = getattr(value, "isoformat", None)
    if callable(isoformat):
        return str(isoformat())
    return None


admin_user_detail_service = AdminUserDetailService()
