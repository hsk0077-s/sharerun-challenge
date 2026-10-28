"""Referral twin-phone check. A shared crew run is not enough on its own.

A referral payout is blocked only when three signals match: start times
within three minutes, the same cadence/distance signature, and at least
half of the compared route points within 40 metres. The run itself still
counts. Missing times or signatures do not match, so older rows are left
alone.
"""

from datetime import datetime
import hashlib
import math

TWIN_WINDOW_SECONDS = 180
TWIN_ROUTE_METERS = 40.0
TWIN_ROUTE_FRACTION = 0.5
TWIN_REASON = "twin_run"


def run_signature(
    *,
    distance_km: float,
    duration_seconds: int,
    cadence_spm: list[int] | None,
) -> str:
    """Short hash of distance, duration, and ten cadence buckets."""
    series = [int(v) for v in (cadence_spm or []) if isinstance(v, int)]
    buckets: list[int] = []
    if series:
        size = max(1, len(series) // 10)
        for index in range(0, len(series), size):
            chunk = series[index:index + size]
            buckets.append(int(round(sum(chunk) / len(chunk))))
            if len(buckets) >= 10:
                break
    payload = f"{round(float(distance_km), 2):.2f}|{int(duration_seconds)}|{buckets}"
    return hashlib.sha256(payload.encode()).hexdigest()[:16]


def _time(value: object) -> datetime | None:
    if isinstance(value, datetime):
        return value if value.tzinfo else value.replace(tzinfo=datetime.now().astimezone().tzinfo)
    if isinstance(value, str) and value:
        try:
            parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
        except ValueError:
            return None
        return parsed
    return None


def _points(route: object) -> list[tuple[float, float]]:
    if not isinstance(route, list):
        return []
    out = []
    for point in route:
        if not isinstance(point, dict):
            continue
        lat = point.get("latitude", point.get("lat"))
        lng = point.get("longitude", point.get("lng"))
        if isinstance(lat, (int, float)) and isinstance(lng, (int, float)):
            if isinstance(lat, bool) or isinstance(lng, bool):
                continue
            out.append((float(lat), float(lng)))
    return out


def _meters(a: tuple[float, float], b: tuple[float, float]) -> float:
    lat1, lon1 = math.radians(a[0]), math.radians(a[1])
    lat2, lon2 = math.radians(b[0]), math.radians(b[1])
    h = (
        math.sin((lat2 - lat1) / 2) ** 2
        + math.cos(lat1) * math.cos(lat2) * math.sin((lon2 - lon1) / 2) ** 2
    )
    return 2 * 6371000.0 * math.asin(math.sqrt(h))


def _overlap(left: list[tuple[float, float]], right: list[tuple[float, float]]) -> float:
    if len(left) < 2 or len(right) < 2:
        return 0.0
    sample = left[:: max(1, len(left) // 20)]
    hits = 0
    for point in sample:
        if any(_meters(point, other) <= TWIN_ROUTE_METERS for other in right[:: max(1, len(right) // 20)]):
            hits += 1
    return hits / len(sample)


def is_twin_run(left: dict, right: dict) -> bool:
    """True when time, signature, and route all say these are one outing."""
    started = _time(left.get("startedAt") or left.get("started_at"))
    other = _time(right.get("startedAt") or right.get("started_at"))
    if started is None or other is None:
        return False
    if abs((started - other).total_seconds()) > TWIN_WINDOW_SECONDS:
        return False
    left_sig = left.get("runSignature")
    right_sig = right.get("runSignature")
    if not isinstance(left_sig, str) or not left_sig or left_sig != right_sig:
        return False
    return _overlap(_points(left.get("gpsRoute") or left.get("gps_route")), _points(right.get("gpsRoute") or right.get("gps_route"))) >= TWIN_ROUTE_FRACTION
