"""Referral twin-phone check. A shared crew run is not enough on its own.

A GPS pair is a twin when three signals match: start times within three
minutes, the same cadence/distance signature, and at least half of the
compared route points within 40 metres. A phone run that sends no route
used to pass that check, because overlap of an empty route is zero. That
pair is a twin when the starts are within one minute and a supporting
signal matches: the same device id, or the same signature. The run itself
still counts. Missing times do not match, so older rows are left alone.
"""

from datetime import datetime, timedelta
import hashlib
import math

TWIN_WINDOW_SECONDS = 180
# Near-identical start for a run that has no GPS route. Wider than a few
# seconds so two phones that begin together still meet, tighter than the
# three-minute GPS window.
BARE_WINDOW_SECONDS = 60
TWIN_ROUTE_METERS = 40.0
TWIN_ROUTE_FRACTION = 0.5
TWIN_REASON = "twin_run"
# Payout is held because the referrer has no run to compare yet.
# It is not a twin. A later referee run reopens it once a run exists.
REFERRER_RUN_ABSENT = "referrer_run_absent"


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


def _started(run: dict) -> datetime | None:
    return _time(run.get("startedAt") or run.get("started_at"))


def _device_id(run: dict) -> str:
    for key in ("deviceId", "device_id"):
        value = run.get(key)
        if isinstance(value, str) and value.strip():
            return value.strip()
    return ""


def _route_points(run: dict) -> list[tuple[float, float]]:
    return _points(run.get("gpsRoute") or run.get("gps_route"))


def _has_route(run: dict) -> bool:
    return len(_route_points(run)) >= 2


def describe_run(
    *,
    distance_km: float,
    duration_seconds: int,
    cadence_spm: list[int] | None,
    gps_route: list,
    started_at: str | None,
    device_id: str,
    now: datetime | None = None,
) -> dict:
    """The fields the payout check compares. A missing start is estimated."""
    started = started_at.strip() if isinstance(started_at, str) else ""
    if not started and now is not None:
        moment = now if now.tzinfo else now.replace(tzinfo=datetime.now().astimezone().tzinfo)
        started = (moment - timedelta(seconds=int(duration_seconds))).isoformat()
    return {
        "startedAt": started,
        "runSignature": run_signature(
            distance_km=distance_km,
            duration_seconds=duration_seconds,
            cadence_spm=cadence_spm,
        ),
        "gpsRoute": [point for point in gps_route if isinstance(point, dict)],
        "deviceId": device_id.strip() if isinstance(device_id, str) else "",
    }


def is_twin_run(left: dict, right: dict) -> bool:
    """True when time, signature, and route all say these are one outing."""
    started = _started(left)
    other = _started(right)
    if started is None or other is None:
        return False
    if abs((started - other).total_seconds()) > TWIN_WINDOW_SECONDS:
        return False
    left_sig = left.get("runSignature")
    right_sig = right.get("runSignature")
    if not isinstance(left_sig, str) or not left_sig or left_sig != right_sig:
        return False
    return _overlap(_route_points(left), _route_points(right)) >= TWIN_ROUTE_FRACTION


def bare_phone_twin(left: dict, right: dict) -> bool:
    """True when a missing route would otherwise skip ``is_twin_run``.

    Both sides already having a route stay on ``is_twin_run``. Here the
    starts must be near-identical, and either the device id or the signature
    must match.
    """
    if _has_route(left) and _has_route(right):
        return False
    started = _started(left)
    other = _started(right)
    if started is None or other is None:
        return False
    if abs((started - other).total_seconds()) > BARE_WINDOW_SECONDS:
        return False
    left_device = _device_id(left)
    right_device = _device_id(right)
    if left_device and left_device == right_device:
        return True
    left_sig = left.get("runSignature")
    right_sig = right.get("runSignature")
    return isinstance(left_sig, str) and bool(left_sig) and left_sig == right_sig


def referral_twin_reason(left: dict, right: dict) -> str | None:
    """``twin_run`` when a referral payout for this pair should be held."""
    if is_twin_run(left, right) or bare_phone_twin(left, right):
        return TWIN_REASON
    return None
