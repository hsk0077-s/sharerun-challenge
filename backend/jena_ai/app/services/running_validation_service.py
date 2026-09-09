from app.constants.economy_constants import SRV_TOKENS_PER_KM
from app.constants.jena_validation_constants import (
    BIKE_GYRO_STABILITY_THRESHOLD,
    BIKE_MIN_HEART_RATE_BPM,
    KICKBOARD_MAX_CADENCE_SPM,
    KICKBOARD_MAX_HEART_RATE_BPM,
    KICKBOARD_PACE_SECONDS_PER_KM,
    VERIFIED_CADENCE_MAX_SPM,
    VERIFIED_CADENCE_MIN_SPM,
    VERIFIED_MIN_DISTANCE_KM,
    VERIFIED_MIN_HEART_RATE_BPM,
    VERIFIED_MIN_HR_VARIANCE,
)
from app.models.validation_request import ValidationRequest
from app.models.validation_result import ValidationResult


class RunningValidationService:
    """Jena AI 3-stage filter: kickboard → bicycle → verified run."""

    def validate(self, request: ValidationRequest) -> ValidationResult:
        pace_seconds_per_km = request.duration_seconds / request.distance_km
        average_hr = self._average(request.heart_rates)
        average_cadence = self._average(request.cadence_spm)
        hr_variance = self._variance(request.heart_rates)

        # Stage A — kickboard (fast pace, flat HR, zero cadence) → deposit forfeiture
        if self._looks_like_kickboard(
            pace_seconds_per_km=pace_seconds_per_km,
            average_hr=average_hr,
            average_cadence=average_cadence,
        ):
            return ValidationResult(
                verified=False,
                decision="rejected_kickboard",
                reason=(
                    "3분/km급 페이스인데 심박 80BPM 이하·케이던스 0에 수렴 — "
                    "킥보드/탑승 의심. 예치금 몰수."
                ),
                value_token_reward=0,
                forfeit_deposit=True,
            )

        # Stage B — bicycle (HR up, gyro/arm-swing fixed)
        if self._looks_like_bike(
            average_hr=average_hr,
            gyro_stability_score=request.gyro_stability_score,
        ):
            return ValidationResult(
                verified=False,
                decision="rejected_bike",
                reason=(
                    "속도·심박은 상승했으나 자이로(팔 스윙) 신호가 고정 — "
                    "자전거 탑승 의심."
                ),
                value_token_reward=0,
                forfeit_deposit=True,
            )

        # Stage C — natural running curve + cadence band → Value mint
        if self._looks_like_verified_run(
            average_hr=average_hr,
            average_cadence=average_cadence,
            distance_km=request.distance_km,
            hr_variance=hr_variance,
            heart_rate_samples=len(request.heart_rates),
        ):
            return ValidationResult(
                verified=True,
                decision="verified",
                reason=(
                    "페이스 변동에 따른 자연스러운 심박 곡선과 "
                    "러닝 케이던스(150~180 SPM) 확인."
                ),
                value_token_reward=int(request.distance_km * SRV_TOKENS_PER_KM),
                forfeit_deposit=False,
            )

        return ValidationResult(
            verified=False,
            decision="rejected_unknown",
            reason="검증 가능한 러닝 생체 신호가 부족합니다.",
            value_token_reward=0,
            forfeit_deposit=False,
        )

    def _looks_like_kickboard(
        self,
        pace_seconds_per_km: float,
        average_hr: float,
        average_cadence: float,
    ) -> bool:
        return (
            pace_seconds_per_km <= KICKBOARD_PACE_SECONDS_PER_KM
            and average_hr <= KICKBOARD_MAX_HEART_RATE_BPM
            and average_cadence <= KICKBOARD_MAX_CADENCE_SPM
        )

    def _looks_like_bike(
        self,
        average_hr: float,
        gyro_stability_score: float,
    ) -> bool:
        return (
            average_hr >= BIKE_MIN_HEART_RATE_BPM
            and gyro_stability_score >= BIKE_GYRO_STABILITY_THRESHOLD
        )

    def _looks_like_verified_run(
        self,
        average_hr: float,
        average_cadence: float,
        distance_km: float,
        hr_variance: float,
        heart_rate_samples: int,
    ) -> bool:
        if distance_km < VERIFIED_MIN_DISTANCE_KM:
            return False
        if average_hr < VERIFIED_MIN_HEART_RATE_BPM:
            return False
        if not (VERIFIED_CADENCE_MIN_SPM <= average_cadence <= VERIFIED_CADENCE_MAX_SPM):
            return False
        if heart_rate_samples >= 3 and hr_variance < VERIFIED_MIN_HR_VARIANCE:
            return False
        return True

    def _average(self, values: list[int]) -> float:
        if not values:
            return 0
        return sum(values) / len(values)

    def _variance(self, values: list[int]) -> float:
        if len(values) < 2:
            return float("inf")
        mean = self._average(values)
        return sum((value - mean) ** 2 for value in values) / len(values)
