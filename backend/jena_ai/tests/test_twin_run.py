"""Twin-phone referral gate. Time, signature, and route must all match."""

from datetime import datetime, timedelta, timezone

from app.services.twin_run import (
    bare_phone_twin,
    is_twin_run,
    referral_twin_reason,
    run_signature,
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
