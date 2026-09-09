from pydantic import BaseModel, Field


class ValidationRequest(BaseModel):
    activity_id: str
    user_id: str
    distance_km: float = Field(gt=0)
    duration_seconds: int = Field(gt=0)
    heart_rates: list[int] = Field(default_factory=list)
    cadence_spm: list[int] = Field(default_factory=list)
    gyro_stability_score: float = Field(ge=0, le=1)
