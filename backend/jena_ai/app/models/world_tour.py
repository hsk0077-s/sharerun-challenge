"""World Tour request and response models."""

from pydantic import BaseModel, Field


class WorldTourAttachRequest(BaseModel):
    mission_id: str = Field(min_length=1, max_length=64, pattern=r"^[A-Za-z0-9_-]+$")
    activity_id: str = Field(min_length=1, max_length=128, pattern=r"^[^/]+$")


class WorldTourAttachResult(BaseModel):
    mission_id: str
    activity_id: str
    # The run's whole verified distance. The daily mining cap is not applied.
    counted_km: float
    progress_km: float
    target_km: float
    state: str  # "active" | "completed"
    stamp_id: str | None = None
    # True when this run was already linked and the stored answer is returned.
    already_attached: bool = False
    # True only on the call that finished the mission.
    newly_completed: bool = False


class WorldTourMissionView(BaseModel):
    mission_id: str
    title: str
    country_code: str
    landmark_id: str
    target_km: float
    order: int
    progress_km: float = 0.0
    state: str = "active"  # "active" | "completed"
    stamp_id: str | None = None
    completed_at: str | None = None


class WorldTourStampView(BaseModel):
    mission_id: str
    stamp_id: str
    country_code: str
    landmark_id: str
    completed_at: str | None = None


class WorldTourMe(BaseModel):
    missions: list[WorldTourMissionView]
    passport: list[WorldTourStampView]
    completed_count: int
    total_count: int
