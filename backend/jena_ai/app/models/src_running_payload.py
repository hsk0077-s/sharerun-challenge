"""SRC standard running payload schema for Jena AI (src.running.v1)."""

from pydantic import BaseModel, Field


class SrcGpsPoint(BaseModel):
    latitude: float
    longitude: float
    recorded_at: str


class SrcRunningSession(BaseModel):
    started_at: str | None = None
    ended_at: str | None = None
    distance_km: float = Field(gt=0)
    duration_seconds: int = Field(gt=0)


class SrcRunningBiometrics(BaseModel):
    """EPHEMERAL — heart-rate/cadence arrays must not be persisted to Firestore."""

    heart_rate_bpm_series: list[int] = Field(default_factory=list)
    cadence_spm_series: list[int] = Field(default_factory=list)
    ephemeral: bool = True


class SrcRunningDevice(BaseModel):
    watch_type: str = "none"
    gyro_stability_score: float = Field(ge=0, le=1)
    integration_track: str = "os_health_direct"


class SrcRunningPayload(BaseModel):
    schema_version: str = "src.running.v1"
    activity_id: str
    user_id: str
    session: SrcRunningSession
    gps_track: list[SrcGpsPoint] = Field(default_factory=list)
    biometrics: SrcRunningBiometrics
    device: SrcRunningDevice
