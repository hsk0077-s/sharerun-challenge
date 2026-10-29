"""Twin-phone referral gate. Time, signature, and route must all match."""

from datetime import datetime, timedelta, timezone

from app.services.twin_run import (
    bare_phone_twin,
    copy_review_detail,
    is_twin_run,
    offset_route_twin,
    referral_twin_reason,
    run_signature,
    same_device_delayed_copy,
    same_device_shifted_route,
)

NOW = datetime(2026, 10, 6, 1, 0, tzinfo=timezone.utc)
ROUTE = [
    {"latitude": 37.5, "longitude": 127.0},
    {"latitude": 37.501, "longitude": 127.001},
    {"latitude": 37.502, "longitude": 127.002},
]


def _run(**extra) -> dict:
    cadence = [170] * 20
    base = {
        "startedAt": NOW.isoformat(),
        "runSignature": run_signature(
            distance_km=1.2, duration_seconds=400, cadence_spm=cadence
        ),
        "gpsRoute": ROUTE,
    }
    base.update(extra)
    return base


def test_same_outing_on_two_phones_is_a_twin() -> None:
    assert is_twin_run(_run(), _run(startedAt=(NOW + timedelta(seconds=40)).isoformat()))


def test_a_later_start_or_a_different_signature_is_not() -> None:
    assert not is_twin_run(_run(), _run(startedAt=(NOW + timedelta(minutes=10)).isoformat()))
    other = _run()
    other["runSignature"] = "different-signature"
    assert not is_twin_run(_run(), other)


def test_matching_time_and_signature_without_a_shared_route_is_not() -> None:
    far = [
        {"latitude": 35.1, "longitude": 129.0},
        {"latitude": 35.12, "longitude": 129.02},
        {"latitude": 35.14, "longitude": 129.04},
    ]
    assert not is_twin_run(_run(), _run(gpsRoute=far))


def test_missing_start_time_does_not_match_old_rows() -> None:
    bare = _run()
    del bare["startedAt"]
    assert not is_twin_run(_run(), bare)


def test_a_phone_run_without_gps_is_a_twin_on_device_or_signature() -> None:
    left = _run(gpsRoute=[], deviceId="phone-a")
    same_phone = _run(
        gpsRoute=[],
        deviceId="phone-a",
        runSignature="other",
        startedAt=(NOW + timedelta(seconds=20)).isoformat(),
    )
    assert bare_phone_twin(left, same_phone)
    assert referral_twin_reason(left, same_phone) == "twin_run"

    same_signature = _run(
        gpsRoute=[],
        deviceId="phone-b",
        startedAt=(NOW + timedelta(seconds=30)).isoformat(),
    )
    assert bare_phone_twin(left, same_signature)

    different = _run(
        gpsRoute=[],
        deviceId="phone-b",
        runSignature="other",
        startedAt=(NOW + timedelta(seconds=20)).isoformat(),
    )
    assert not bare_phone_twin(left, different)
    assert referral_twin_reason(left, different) is None


def test_two_routes_that_do_not_overlap_stay_on_the_gps_check() -> None:
    far = [
        {"latitude": 35.1, "longitude": 129.0},
        {"latitude": 35.12, "longitude": 129.02},
        {"latitude": 35.14, "longitude": 129.04},
    ]
    left = _run(deviceId="phone-a")
    right = _run(
        deviceId="phone-b",
        gpsRoute=far,
        runSignature="other",
        startedAt=(NOW + timedelta(seconds=20)).isoformat(),
    )
    assert not bare_phone_twin(left, right)
    assert not is_twin_run(left, right)
    assert not same_device_shifted_route(left, right)
    assert referral_twin_reason(left, right) is None


def test_same_device_with_a_shifted_route_is_still_a_twin() -> None:
    far = [
        {"latitude": 35.1, "longitude": 129.0},
        {"latitude": 35.12, "longitude": 129.02},
        {"latitude": 35.14, "longitude": 129.04},
    ]
    left = _run(deviceId="phone-a")
    right = _run(
        deviceId="phone-a",
        gpsRoute=far,
        runSignature="other",
        startedAt=(NOW + timedelta(seconds=20)).isoformat(),
    )
    assert not is_twin_run(left, right)
    assert not bare_phone_twin(left, right)
    assert same_device_shifted_route(left, right)
    assert referral_twin_reason(left, right) == "twin_run"
    later = _run(
        deviceId="phone-a",
        gpsRoute=far,
        startedAt=(NOW + timedelta(minutes=4)).isoformat(),
    )
    assert not same_device_shifted_route(left, later)
    # Same signature inside thirty minutes is still one handset.
    assert same_device_delayed_copy(left, later)
    assert referral_twin_reason(left, later) == "twin_run"


def _loop(shift_m: float = 0.0) -> list[dict]:
    """A square about 200m on a side. ``shift_m`` slides it east."""
    corners = [
        (0.0, 0.0),
        (200.0, 0.0),
        (200.0, 200.0),
        (0.0, 200.0),
        (0.0, 0.0),
    ]
    points = []
    for left, right in zip(corners, corners[1:]):
        for step in range(8):
            blend = step / 8
            north = left[0] + (right[0] - left[0]) * blend
            east = left[1] + (right[1] - left[1]) * blend + shift_m
            points.append(
                {
                    "latitude": 37.5 + north / 111_320.0,
                    "longitude": 127.0 + east / 88_300.0,
                }
            )
    return points


def test_a_shifted_loop_on_two_phones_is_a_twin_when_the_signature_matches() -> None:
    left = _run(deviceId="phone-a", gpsRoute=_loop())
    right = _run(
        deviceId="phone-b",
        gpsRoute=_loop(150.0),
        startedAt=(NOW + timedelta(seconds=40)).isoformat(),
    )
    assert not is_twin_run(left, right)
    assert offset_route_twin(left, right)
    assert referral_twin_reason(left, right) == "twin_run"


def test_a_straight_slide_or_a_far_slide_is_not_an_offset_twin() -> None:
    left = _run(deviceId="phone-a", gpsRoute=[_north(i, 10.0) for i in range(40)])
    straight = _run(
        deviceId="phone-b",
        gpsRoute=[
            {
                "latitude": 37.5 + (index * 10.0) / 111_320.0,
                "longitude": 127.0 + 150.0 / 88_300.0,
            }
            for index in range(40)
        ],
        startedAt=(NOW + timedelta(seconds=20)).isoformat(),
    )
    assert not offset_route_twin(left, straight)
    assert referral_twin_reason(left, straight) is None
    assert copy_review_detail(left, straight) == "straight_slide"

    loop = _run(deviceId="phone-a", gpsRoute=_loop())
    far = _run(
        deviceId="phone-b",
        gpsRoute=_loop(5_000.0),
        startedAt=(NOW + timedelta(seconds=20)).isoformat(),
    )
    assert not offset_route_twin(loop, far)
    assert copy_review_detail(loop, far) == "far_slide"
    changed = _run(
        deviceId="phone-b",
        gpsRoute=_loop(150.0),
        runSignature="other",
        startedAt=(NOW + timedelta(seconds=20)).isoformat(),
    )
    assert not offset_route_twin(loop, changed)
    assert referral_twin_reason(loop, changed) is None


def test_same_phone_delayed_past_three_minutes_holds_only_inside_thirty() -> None:
    left = _run(deviceId="phone-a", gpsRoute=_loop())
    delayed = _run(
        deviceId="phone-a",
        gpsRoute=_loop(400.0),
        startedAt=(NOW + timedelta(seconds=181)).isoformat(),
    )
    assert not same_device_shifted_route(left, delayed)
    assert same_device_delayed_copy(left, delayed)
    assert referral_twin_reason(left, delayed) == "twin_run"
    too_late = _run(
        deviceId="phone-a",
        gpsRoute=_loop(400.0),
        startedAt=(NOW + timedelta(minutes=31)).isoformat(),
    )
    assert not same_device_delayed_copy(left, too_late)
    assert referral_twin_reason(left, too_late) is None
    assert copy_review_detail(left, too_late) is None
    changed_late = _run(
        deviceId="phone-a",
        gpsRoute=_loop(400.0),
        runSignature="other-signature",
        startedAt=(NOW + timedelta(minutes=31)).isoformat(),
    )
    assert referral_twin_reason(left, changed_late) is None
    assert copy_review_detail(left, changed_late) == "late_signature"
    other_workout = _run(
        deviceId="phone-a",
        gpsRoute=[_north(i, 25.0) for i in range(30)],
        runSignature="other",
        startedAt=(NOW + timedelta(seconds=181)).isoformat(),
    )
    assert not same_device_delayed_copy(left, other_workout)
    assert referral_twin_reason(left, other_workout) is None
    assert copy_review_detail(left, other_workout) is None


def _north(index: int, step_m: float, shift_m: float = 0.0) -> dict:
    return {
        "latitude": 37.5 + ((index * step_m) + shift_m) / 111_320.0,
        "longitude": 127.0,
    }


def test_a_long_route_still_matches_when_samples_are_out_of_phase() -> None:
    """Subsampling both traces used to miss a point that sat inside 40m."""
    left = _run(gpsRoute=[_north(i, 10.0) for i in range(200)])
    right = _run(
        gpsRoute=[_north(i, 10.0, shift_m=50.0) for i in range(200)],
        startedAt=(NOW + timedelta(seconds=30)).isoformat(),
    )
    assert is_twin_run(left, right)
