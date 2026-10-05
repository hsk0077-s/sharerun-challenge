import math
from dataclasses import dataclass
from datetime import datetime

from app.constants.economy_constants import SRV_TOKENS_PER_KM
from app.constants.jena_validation_constants import (
    BIKE_GYRO_STABILITY_THRESHOLD,
    BIKE_MIN_HEART_RATE_BPM,
    GPS_MAX_SEGMENT_KMH,
    GPS_MIN_SEGMENT_M,
    KICKBOARD_MAX_CADENCE_SPM,
    KICKBOARD_MAX_HEART_RATE_BPM,
    KICKBOARD_PACE_NO_HR_SECONDS_PER_KM,
    KICKBOARD_PACE_SECONDS_PER_KM,
    STRIDE_MAX_M,
    STRIDE_MIN_M,
    VERIFIED_CADENCE_MAX_SPM,
    VERIFIED_CADENCE_MIN_SPM,
    VERIFIED_MIN_DISTANCE_KM,
    VERIFIED_MIN_HEART_RATE_BPM,
    VERIFIED_MIN_HR_VARIANCE,
)
from app.models.validation_request import ValidationRequest
from app.models.validation_result import ValidationResult


@dataclass(frozen=True)
class RunValidationPolicy:
    """Room-specific gates. Free runs use the 1.0km floor and optional HR."""

    min_distance_km: float = VERIFIED_MIN_DISTANCE_KM
    requires_heart_rate: bool = False


def policy_for_room(
    *,
    has_room: bool,
    target_distance_km: float = 0,
    tier_min_distance_km: float = 0,
    requires_heart_rate: bool = False,
) -> RunValidationPolicy:
    """Min distance is the room target, else the prize-tier distance, else 1km.

    User rooms pass ``requires_heart_rate=False``. A prize tier passes the
    config flag. Missing heart-rate samples are not a deposit forfeiture.
    """
    if not has_room:
        return RunValidationPolicy(VERIFIED_MIN_DISTANCE_KM, False)
    distance = target_distance_km if target_distance_km > 0 else tier_min_distance_km
    if distance < VERIFIED_MIN_DISTANCE_KM:
        distance = VERIFIED_MIN_DISTANCE_KM
    return RunValidationPolicy(distance, requires_heart_rate)


class RunningValidationService:
    """Jena AI 3-stage filter: kickboard → bicycle → verified run."""

    def validate(
        self,
        request: ValidationRequest,
        policy: RunValidationPolicy | None = None,
        *,
        total_steps: int | None = None,
        gps_route: list | None = None,
    ) -> ValidationResult:
        policy = policy or RunValidationPolicy()
        pace_seconds_per_km = request.duration_seconds / request.distance_km
        heart_rate_samples = len(request.heart_rates)
        average_hr = self._average(request.heart_rates)
        average_cadence = self._average(request.cadence_spm)
        hr_variance = self._variance(request.heart_rates)
        steps = self._steps(request, total_steps)
        distance_m = request.distance_km * 1000.0

        # Stage A — kickboard. Missing HR is not treated as HR <= 80.
        if heart_rate_samples > 0 and self._looks_like_kickboard(
            pace_seconds_per_km=pace_seconds_per_km,
            average_hr=average_hr,
            average_cadence=average_cadence,
        ):
            return self._rejected(
                decision="rejected_kickboard",
                reason_code="kickboard",
                reason=(
                    "3분/km급 페이스인데 심박 80BPM 이하·케이던스 0에 수렴 — "
                    "킥보드/탑승 의심. 예치금 몰수."
                ),
                forfeit_deposit=True,
            )
        if heart_rate_samples == 0 and self._kickboard_without_hr(
            pace_seconds_per_km=pace_seconds_per_km,
            average_cadence=average_cadence,
            distance_m=distance_m,
            steps=steps,
        ):
            return self._rejected(
                decision="rejected_kickboard",
                reason_code="kickboard",
                reason=(
                    "심박이 없고 페이스가 빠른데 걸음이 거의 없습니다 — "
                    "킥보드/탑승 의심. 예치금 몰수."
                ),
                forfeit_deposit=True,
            )

        # Stage B — bicycle. HR is part of the rule, so a missing watch
        # cannot satisfy it.
        if heart_rate_samples > 0 and self._looks_like_bike(
            average_hr=average_hr,
            gyro_stability_score=request.gyro_stability_score,
        ):
            return self._rejected(
                decision="rejected_bike",
                reason_code="bike",
                reason=(
                    "속도·심박은 상승했으나 자이로(팔 스윙) 신호가 고정 — "
                    "자전거 탑승 의심."
                ),
                forfeit_deposit=True,
            )

        if policy.requires_heart_rate and heart_rate_samples == 0:
            return self._rejected(
                decision="rejected_unknown",
                reason_code="heart_rate_required",
                reason="이 레이스는 심박 데이터가 있어야 완주로 인정됩니다.",
                forfeit_deposit=False,
            )

        if request.distance_km + 1e-9 < policy.min_distance_km:
            return self._rejected(
                decision="rejected_unknown",
                reason_code="distance_too_short",
                reason="검증 최소 거리에 못 미칩니다.",
                forfeit_deposit=False,
            )

        if not (
            VERIFIED_CADENCE_MIN_SPM
            <= average_cadence
            <= VERIFIED_CADENCE_MAX_SPM
        ):
            return self._rejected(
                decision="rejected_unknown",
                reason_code="cadence_out_of_range",
                reason="러닝 케이던스(120~210 SPM) 범위를 벗어났습니다.",
                forfeit_deposit=False,
            )

        if heart_rate_samples > 0:
            if average_hr < VERIFIED_MIN_HEART_RATE_BPM:
                return self._rejected(
                    decision="rejected_unknown",
                    reason_code="heart_rate_low",
                    reason="평균 심박이 러닝 기준보다 낮습니다.",
                    forfeit_deposit=False,
                )
            if heart_rate_samples >= 3 and hr_variance < VERIFIED_MIN_HR_VARIANCE:
                return self._rejected(
                    decision="rejected_unknown",
                    reason_code="heart_rate_flat",
                    reason="심박 곡선이 평평합니다.",
                    forfeit_deposit=False,
                )
        else:
            phone = self._phone_only_failure(distance_m, steps, gps_route)
            if phone is not None:
                return phone

        if heart_rate_samples > 0:
            reason = "러닝 케이던스(120~210 SPM)와 심박 곡선을 확인했습니다."
        else:
            reason = "심박 없이 케이던스·보폭·GPS 속도로 확인했습니다."
        return ValidationResult(
            verified=True,
            decision="verified",
            reason=reason,
            reason_code="verified",
            value_token_reward=int(request.distance_km * SRV_TOKENS_PER_KM),
            forfeit_deposit=False,
        )

    def _phone_only_failure(
        self,
        distance_m: float,
        steps: int,
        gps_route: list | None,
    ) -> ValidationResult | None:
        if steps <= 0:
            return self._rejected(
                decision="rejected_unknown",
                reason_code="stride_out_of_range",
                reason="걸음 수가 없어 보폭을 확인할 수 없습니다.",
                forfeit_deposit=False,
            )
        # Claimed distance and the GPS path. The longer one is the stride.
        distance_m = max(distance_m, self._route_distance_m(gps_route))
        stride = distance_m / steps
        if not (STRIDE_MIN_M <= stride <= STRIDE_MAX_M):
            return self._rejected(
                decision="rejected_unknown",
                reason_code="stride_out_of_range",
                reason="거리와 걸음 수의 보폭이 러닝 범위를 벗어났습니다.",
                forfeit_deposit=False,
            )
        if self._vehicle_like_speed(gps_route):
            return self._rejected(
                decision="rejected_unknown",
                reason_code="vehicle_speed",
                reason="GPS 구간 속도가 차량 이동에 가깝습니다.",
                forfeit_deposit=False,
            )
        return None

    def _rejected(
        self,
        *,
        decision: str,
        reason_code: str,
        reason: str,
        forfeit_deposit: bool,
    ) -> ValidationResult:
        return ValidationResult(
            verified=False,
            decision=decision,
            reason=reason,
            reason_code=reason_code,
            value_token_reward=0,
            forfeit_deposit=forfeit_deposit,
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

    def _kickboard_without_hr(
        self,
        *,
        pace_seconds_per_km: float,
        average_cadence: float,
        distance_m: float,
        steps: int,
    ) -> bool:
        if pace_seconds_per_km > KICKBOARD_PACE_NO_HR_SECONDS_PER_KM:
            return False
        if average_cadence <= KICKBOARD_MAX_CADENCE_SPM:
            return True
        if steps > 0 and (distance_m / steps) > STRIDE_MAX_M:
            return True
        return False

    def _looks_like_bike(
        self,
        average_hr: float,
        gyro_stability_score: float,
    ) -> bool:
        return (
            average_hr >= BIKE_MIN_HEART_RATE_BPM
            and gyro_stability_score >= BIKE_GYRO_STABILITY_THRESHOLD
        )

    def _steps(self, request: ValidationRequest, total_steps: int | None) -> int:
        if total_steps is not None:
            return max(0, int(total_steps))
        if not request.cadence_spm or request.duration_seconds <= 0:
            return 0
        average = sum(request.cadence_spm) / len(request.cadence_spm)
        return int(average * request.duration_seconds / 60)

    def _route_distance_m(self, gps_route: list | None) -> float:
        points = [_route_sample(point) for point in (gps_route or [])]
        points = [point for point in points if point is not None]
        total = 0.0
        for earlier, later in zip(points, points[1:]):
            total += _haversine_m(earlier[0], earlier[1], later[0], later[1])
        return total

    def _vehicle_like_speed(self, gps_route: list | None) -> bool:
        points = [_route_sample(point) for point in (gps_route or [])]
        points = [point for point in points if point is not None]
        if len(points) < 2:
            return False
        previous = points[0]
        for point in points[1:]:
            meters = _haversine_m(previous[0], previous[1], point[0], point[1])
            if meters < GPS_MIN_SEGMENT_M:
                previous = point
                continue
            started = previous[2]
            ended = point[2]
            if started is None or ended is None:
                previous = point
                continue
            elapsed = (ended - started).total_seconds()
            if elapsed <= 0 or (meters / elapsed) * 3.6 > GPS_MAX_SEGMENT_KMH:
                return True
            previous = point
        return False

    def _average(self, values: list[int]) -> float:
        if not values:
            return 0
        return sum(values) / len(values)

    def _variance(self, values: list[int]) -> float:
        if len(values) < 2:
            return float("inf")
        mean = self._average(values)
        return sum((value - mean) ** 2 for value in values) / len(values)


def _route_sample(point) -> tuple[float, float, datetime | None] | None:
    if isinstance(point, dict):
        lat = point.get("latitude")
        lng = point.get("longitude")
        raw_time = point.get("recordedAt") or point.get("recorded_at")
    else:
        lat = getattr(point, "latitude", None)
        lng = getattr(point, "longitude", None)
        raw_time = getattr(point, "recordedAt", None) or getattr(
            point, "recorded_at", None
        )
    if not isinstance(lat, (int, float)) or not isinstance(lng, (int, float)):
        return None
    return float(lat), float(lng), _parse_time(raw_time)


def _parse_time(raw) -> datetime | None:
    if isinstance(raw, datetime):
        return raw
    if not isinstance(raw, str) or not raw.strip():
        return None
    text = raw.strip().replace("Z", "+00:00")
    try:
        return datetime.fromisoformat(text)
    except ValueError:
        return None


def _haversine_m(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    radius = 6_371_000.0
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    d_phi = math.radians(lat2 - lat1)
    d_lam = math.radians(lon2 - lon1)
    a = (
        math.sin(d_phi / 2) ** 2
        + math.cos(phi1) * math.cos(phi2) * math.sin(d_lam / 2) ** 2
    )
    return 2 * radius * math.asin(min(1.0, math.sqrt(a)))
