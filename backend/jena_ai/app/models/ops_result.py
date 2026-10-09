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


class CreatePrizeRaceResult(BaseModel):
    accepted: bool
    tournament_id: str
    tier: str
    edition: int
    season_id: str | None = None
    status: str
    reason: str


class PrizeSettlementResult(BaseModel):
    accepted: bool
    tournament_id: str
    status: str
    finisher_count: int
    paid_dia: int
    held_dia: int
    share_paid: int
    value_paid: int
    donation_krw: int
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


class GradeBackfillItem(BaseModel):
    uid: str
    gradeCode: str
    gradeRank: int
    medianPaceSec: int


class GradeBackfillResult(BaseModel):
    dry_run: bool
    scanned: int
    skipped: int
    planned: int
    written: int
    grades: list[GradeBackfillItem]
