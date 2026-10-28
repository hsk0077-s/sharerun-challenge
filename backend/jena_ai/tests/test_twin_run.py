"""Twin-phone referral gate. Time, signature, and route must all match."""

from datetime import datetime, timedelta, timezone

from app.services.twin_run import is_twin_run, run_signature

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
