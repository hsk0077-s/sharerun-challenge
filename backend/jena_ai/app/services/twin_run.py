"""Referral twin-phone check. A shared crew run is not enough on its own.

A GPS pair is a twin when three signals match: start times within three
minutes, the same cadence/distance signature, and at least half of the
compared route points within 40 metres. The other route is not thinned
before that distance check: thinning both sides can hide the points that
actually sat within 40 metres, so one road looks like two. A phone run
that sends no route used to pass the overlap check, because overlap of an
empty route is zero. That pair is a twin when the starts are within one
minute and a supporting signal matches: the same device id, or the same
signature. Once both sides send a route, a shifted track used to skip the
device check as well. The same device inside the three-minute window is
still one outing. Waiting just past that window on the same device, with
the same workout numbers or a slid copy of the route, is still one outing
up to thirty minutes. Two handsets with the same workout numbers and a
route slid past 40m are one outing inside the three-minute window,
however far the slide moved it — the kilometre count of a shift is not
the signal, the exact signature plus the congruent shape is. A route that
turns only needs a 25m/85% positional match after the slide, because the
turning shape is already distinctive. A straight route is not distinctive
by shape — too many real kilometres look like that — so a straight slide
needs a 15m/95% match, close to GPS noise, before it counts as the same
copy rather than two people on two nearby straight streets. The run
itself still counts. Missing times do not match, so older rows are left
alone.
"""

from datetime import datetime, timedelta
import hashlib
import math
import statistics

TWIN_WINDOW_SECONDS = 180
# Near-identical start for a run that has no GPS route. Wider than a few
# seconds so two phones that begin together still meet, tighter than the
# three-minute GPS window.
BARE_WINDOW_SECONDS = 60
TWIN_ROUTE_METERS = 40.0
TWIN_ROUTE_FRACTION = 0.5
# Same handset, start delayed just past the three-minute window. Thirty
# minutes catches a few minutes of waiting. A later start is left alone.
SAME_DEVICE_DELAY_SECONDS = 30 * 60
# A copied track shifted sideways. Under 40m is already the overlap check.
# There is no upper bound: the kilometre count of the shift is not the
# signal. Two phones an exact signature (0.01km / 1s / ten cadence
# buckets) and a congruent translated shape apart inside the three-minute
# window is already the evidence, however far the copy was moved. A larger
# shift does not make that coincidence more plausible, so it is not given
# a pass.
OFFSET_MIN_METERS = 40.0
OFFSET_RESIDUAL_METERS = 25.0
OFFSET_FRACTION = 0.85
OFFSET_MIN_TURN_DEGREES = 25.0
OFFSET_SAMPLES = 12
# A turning route is unique by shape, so a 25m residual on 85% of the
# samples is already strong evidence of a copy. A straight route is common
# shape-wise (any street looks like it), so a straight slide needs a much
# tighter positional match before it counts as the same copy rather than
# two people on two nearby straight roads. 15m/95% is close to GPS noise,
# which a real independent phone trace on a parallel street would not hit.
STRAIGHT_OFFSET_RESIDUAL_METERS = 15.0
STRAIGHT_OFFSET_FRACTION = 0.95
TWIN_REASON = "twin_run"
# Payout is held because the referrer has no run to compare yet.
# It is not a twin. A later referee run reopens it once a run exists.
REFERRER_RUN_ABSENT = "referrer_run_absent"
# Neither account has a device id to compare. A later referee run reopens
# it once either side has one. It is not a twin.
DEVICE_ID_ABSENT = "device_id_absent"
# The referee and referrer accounts share a device id somewhere in their
# history — not just inside the GPS twin window. Waiting out the window or
# changing the workout numbers does not clear this; the device overlap is
# a fact about the two accounts, not about one run. Stays held like
# ``twin_run``; nothing reopens it automatically.
SHARED_DEVICE_HISTORY = "shared_device_history"


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
    # Keep every point on the other route. Sampling both sides drops the
    # neighbours that were inside 40 metres when the traces are long.
    hits = 0
    for point in sample:
        if any(_meters(point, other) <= TWIN_ROUTE_METERS for other in right):
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


def same_device_shifted_route(left: dict, right: dict) -> bool:
    """True when both routes exist but the handset is the same.

    ``bare_phone_twin`` returns false once both sides have a route, so a
    shifted track used to hide the device id. The same device inside the
    GPS window is one outing even when the tracks do not overlap.
    """
    if not (_has_route(left) and _has_route(right)):
        return False
    started = _started(left)
    other = _started(right)
    if started is None or other is None:
        return False
    if abs((started - other).total_seconds()) > TWIN_WINDOW_SECONDS:
        return False
    left_device = _device_id(left)
    right_device = _device_id(right)
    return bool(left_device) and left_device == right_device


def _resample(points: list[tuple[float, float]], count: int) -> list[tuple[float, float]]:
    if len(points) < 2:
        return []
    last = len(points) - 1
    out = []
    for index in range(count):
        at = round(index * last / (count - 1))
        out.append(points[at])
    return out


def _bearing(a: tuple[float, float], b: tuple[float, float]) -> float | None:
    if _meters(a, b) < 5.0:
        return None
    lat1, lon1 = math.radians(a[0]), math.radians(a[1])
    lat2, lon2 = math.radians(b[0]), math.radians(b[1])
    dlon = lon2 - lon1
    x = math.sin(dlon) * math.cos(lat2)
    y = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dlon)
    return math.degrees(math.atan2(x, y)) % 360.0


def _max_turn_degrees(points: list[tuple[float, float]]) -> float:
    """Largest heading change. A straight kilometre stays near zero."""
    headings = []
    for left, right in zip(points, points[1:]):
        heading = _bearing(left, right)
        if heading is not None:
            headings.append(heading)
    if len(headings) < 2:
        return 0.0
    largest = 0.0
    previous = headings[0]
    for heading in headings[1:]:
        delta = abs(heading - previous)
        if delta > 180.0:
            delta = 360.0 - delta
        if delta > largest:
            largest = delta
        previous = heading
    return largest


def translated_route_copy(left: dict, right: dict) -> bool:
    """True when one route is the other, slid sideways by one fixed offset.

    The shift has to be past the 40m overlap rule. There is no upper bound
    on the shift: how many kilometres the copy was moved is not the
    signal, so it is not checked. A route that turns is a distinctive
    enough shape that a 25m/85% positional match
    after the slide is already a copy. A straight route is not distinctive
    by shape (any straight street matches), so the same slide only counts
    as a copy when the positional match is much tighter (15m/95%) — close
    to GPS noise, not the spacing of two different people on two different
    straight streets.
    """
    left_points = _route_points(left)
    right_points = _route_points(right)
    if len(left_points) < 6 or len(right_points) < 6:
        return False
    left_sample = _resample(left_points, OFFSET_SAMPLES)
    right_sample = _resample(right_points, OFFSET_SAMPLES)
    if len(left_sample) != OFFSET_SAMPLES or len(right_sample) != OFFSET_SAMPLES:
        return False
    dlat = statistics.median(
        right_sample[index][0] - left_sample[index][0] for index in range(OFFSET_SAMPLES)
    )
    dlng = statistics.median(
        right_sample[index][1] - left_sample[index][1] for index in range(OFFSET_SAMPLES)
    )
    shift = _meters(left_sample[0], (left_sample[0][0] + dlat, left_sample[0][1] + dlng))
    if shift <= OFFSET_MIN_METERS:
        return False
    turning = (
        _max_turn_degrees(left_sample) >= OFFSET_MIN_TURN_DEGREES
        or _max_turn_degrees(right_sample) >= OFFSET_MIN_TURN_DEGREES
    )
    residual_limit = OFFSET_RESIDUAL_METERS if turning else STRAIGHT_OFFSET_RESIDUAL_METERS
    required_fraction = OFFSET_FRACTION if turning else STRAIGHT_OFFSET_FRACTION
    close = 0
    for point, other in zip(left_sample, right_sample):
        moved = (point[0] + dlat, point[1] + dlng)
        if _meters(moved, other) <= residual_limit:
            close += 1
    return close / OFFSET_SAMPLES >= required_fraction


def _signature_match(left: dict, right: dict) -> bool:
    left_sig = left.get("runSignature")
    right_sig = right.get("runSignature")
    return isinstance(left_sig, str) and bool(left_sig) and left_sig == right_sig


def _start_gap_seconds(left: dict, right: dict) -> float | None:
    started = _started(left)
    other = _started(right)
    if started is None or other is None:
        return None
    return abs((started - other).total_seconds())


def offset_route_twin(left: dict, right: dict) -> bool:
    """Different handsets, same workout numbers, route copied and slid.

    Same handset is ``same_device_shifted_route`` or
    ``same_device_delayed_copy``. A slide under 40m, or a different
    signature, stays out. A straight slide still needs the tighter
    positional match in ``translated_route_copy`` to count. There is no
    upper bound on how far the slide moved.
    """
    left_device = _device_id(left)
    right_device = _device_id(right)
    if left_device and left_device == right_device:
        return False
    gap = _start_gap_seconds(left, right)
    if gap is None or gap > TWIN_WINDOW_SECONDS:
        return False
    if not _signature_match(left, right):
        return False
    return translated_route_copy(left, right)


def same_device_delayed_copy(left: dict, right: dict) -> bool:
    """Same handset, start later than three minutes and within thirty.

    The three-minute window is ``same_device_shifted_route``. Waiting three
    minutes and one second used to skip it. The workout numbers have to
    match, or the route has to be a slid copy (turning or straight, each
    against its own positional bar). A different workout on a shared phone
    is not this.
    """
    left_device = _device_id(left)
    right_device = _device_id(right)
    if not left_device or left_device != right_device:
        return False
    gap = _start_gap_seconds(left, right)
    if gap is None or gap <= TWIN_WINDOW_SECONDS or gap > SAME_DEVICE_DELAY_SECONDS:
        return False
    if _signature_match(left, right):
        return True
    return translated_route_copy(left, right)


def referral_twin_reason(left: dict, right: dict) -> str | None:
    """``twin_run`` when a referral payout for this pair should be held."""
    if (
        is_twin_run(left, right)
        or bare_phone_twin(left, right)
        or same_device_shifted_route(left, right)
        or offset_route_twin(left, right)
        or same_device_delayed_copy(left, right)
    ):
        return TWIN_REASON
    return None
