from pydantic import BaseModel


class BepRefundResult(BaseModel):
    accepted: bool
    tournament_id: str
    refunded_participants: int
    refunded_share_total: int
    status: str
    reason: str


class ActivateTournamentResult(BaseModel):
    accepted: bool
    tournament_id: str
    participant_count: int
    status: str
    reason: str


class PurgeUserResult(BaseModel):
    accepted: bool
    uid: str
    deleted_activities: int
    deleted_diamond_collections: int
    status: str
    reason: str


class PurgeDeletedAccountsResult(BaseModel):
    accepted: bool
    processed_users: int
    purged_users: list[str]
    status: str
    reason: str
