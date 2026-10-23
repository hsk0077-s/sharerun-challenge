from pydantic import BaseModel, Field


class ValidationRequest(BaseModel):
    activity_id: str = Field(max_length=128)
    user_id: str = Field(max_length=128)
    distance_km: float = Field(gt=0, le=1000, allow_inf_nan=False)
    duration_seconds: int = Field(gt=0, le=172800)
    heart_rates: list[int] = Field(default_factory=list, max_length=50000)
    cadence_spm: list[int] = Field(default_factory=list, max_length=50000)
    gyro_stability_score: float = Field(ge=0, le=1, allow_inf_nan=False)
