"""What pace_too_fast and the pace floor do with a slow GPS kilometre.

``pace_too_fast`` is not a validation reason. Validation uses
``implausible_pace`` under 150 sec/km and ``vehicle_speed`` over 25 km/h.
A 1km trace drawn slower than that still verifies and can become a grade
sample. Beginner entry and a beginner prize finish then look at the pace
number, not at the shape of the trace.
"""

from datetime import datetime, timedelta, timezone

from app.models.validation_request import ValidationRequest
from app.services.company_tournament_settlement import (
    beginner_signal_hold,
    gps_spacing_uniform,
    gps_trace_sparse,
    prize_finish_fields,
)
from app.services.grade_assignment import (
    beginner_entry_block,
    counts_for_grade,
    note_pace_sample,
    run_pace_sec_per_km,
)
from app.services.running_validation_service import RunningValidationService

_START = datetime(2026, 10, 5, tzinfo=timezone.utc)


def _slow_kilometre(seconds: int = 900) -> list[dict]:
    """About 1km north, split into 100m steps. 900s is roughly 4 km/h."""
    points = []
    for index in range(11):
        moment = _START + timedelta(seconds=seconds * index / 10)
        points.append(
            {
                "latitude": 37.5 + (index * 100.0 / 111_320.0),
                "longitude": 127.0,
                "recordedAt": moment.isoformat(),
            }
        )
    return points


def _request(**overrides) -> ValidationRequest:
    fields = {
        "activity_id": "drawn",
        "user_id": "runner",
        "distance_km": 1.0,
        "duration_seconds": 900,
        "heart_rates": [120, 140, 160],
        "cadence_spm": [160, 164, 158],
        "gyro_stability_score": 0.4,
    }
    fields.update(overrides)
    return ValidationRequest(**fields)


def _user(samples: list[int], rank: int = 1) -> dict:
    return {
        "gradeRank": rank,
        "gradeCode": "turtle_bronze",
        "gradeSource": "signup_floor",
        "economy": {
            "paceSamples": [
                {"day": f"d{index}", "activityId": f"a{index}", "paceSec": pace}
                for index, pace in enumerate(samples)
            ]
        },
    }


def _finish(duration: int, distance: float = 1.0, **signals) -> dict | None:
    return prize_finish_fields(
        {"prizeTier": "beginner", "targetDistanceKm": 1, "status": "active"},
        {"uid": "runner", "status": "joined"},
        distance_km=distance,
        duration_seconds=duration,
        activity_id="finish",
        **signals,
    )


def test_a_slowly_drawn_kilometre_is_a_grade_sample() -> None:
    service = RunningValidationService()
    route = _slow_kilometre(900)
    verified = service.validate(_request(), gps_route=route)
    assert verified.reason_code == "verified"
    pace = run_pace_sec_per_km(1.0, 900)
    assert pace == 900
    assert counts_for_grade(1.0) is True
    samples, added = note_pace_sample([], activity_id="drawn", day_key="2026-10-05", pace_sec=pace)
    assert added is True
    assert samples[0]["paceSec"] == 900
    assert beginner_entry_block(_user([900])) is None
    # Pace alone still pays. The drawing is the even gaps, not the 900s.
    assert _finish(900)["verifiedFinish"] is True
    assert gps_spacing_uniform(route) is True
    drawn = _finish(
        900,
        heart_rates=[120, 140, 160],
        cadence_spm=[160, 164, 158],
        total_steps=1400,
        gps_route=route,
    )
    assert drawn["prizeHeld"] is True
    assert drawn["prizeHoldReason"] == "uniform_gps"
    assert drawn["verifiedFinish"] is False


def test_heart_rate_does_not_excuse_a_vehicle_segment() -> None:
    service = RunningValidationService()
    started = "2026-10-05T00:00:00+00:00"
    ended = "2026-10-05T00:00:30+00:00"
    fast = [
        {"latitude": 37.50, "longitude": 127.00, "recordedAt": started},
        {"latitude": 37.50, "longitude": 127.02, "recordedAt": ended},
    ]
    with_pulse = service.validate(
        _request(distance_km=1.2, duration_seconds=420),
        gps_route=fast,
    )
    without_pulse = service.validate(
        _request(distance_km=1.2, duration_seconds=420, heart_rates=[]),
        total_steps=1_000,
        gps_route=fast,
    )
    assert with_pulse.reason_code == "vehicle_speed"
    assert without_pulse.reason_code == "vehicle_speed"
    assert counts_for_grade(1.2) is True
    # The run never verifies, so it does not become a pace sample.
    assert with_pulse.verified is False


def test_pace_band_from_150_to_450() -> None:
    service = RunningValidationService()
    too_fast = service.validate(_request(duration_seconds=149))
    assert too_fast.reason_code == "implausible_pace"
    assert too_fast.verified is False
    assert beginner_entry_block(_user([])) is None

    at_floor = service.validate(_request(duration_seconds=150))
    assert at_floor.reason_code == "verified"
    assert run_pace_sec_per_km(1.0, 150) == 150
    assert beginner_entry_block(_user([150])) == "pace_too_fast"
    assert _finish(150)["prizeHeld"] is True
    assert _finish(150)["prizeHoldReason"] == "pace_too_fast"

    inside = service.validate(_request(duration_seconds=449))
    assert inside.reason_code == "verified"
    assert beginner_entry_block(_user([300, 449])) == "pace_too_fast"
    held = _finish(449)
    assert held["prizeHeld"] is True
    assert held["verifiedFinish"] is False

    at_turtle = service.validate(_request(duration_seconds=450))
    assert at_turtle.reason_code == "verified"
    assert beginner_entry_block(_user([450])) is None
    legal = _finish(450)
    assert legal["verifiedFinish"] is True
    assert "prizeHeld" not in legal

    # Faster than 150 and slower than 450 can be stored. The entry looks at
    # the median only. One slow day among fast days does not hide the median.
    assert beginner_entry_block(_user([200, 900, 220])) == "pace_too_fast"
    assert beginner_entry_block(_user([900, 800, 450])) is None


def test_a_beginner_prize_holds_when_the_run_has_no_companion_signal() -> None:
    bare = _finish(
        900,
        heart_rates=[],
        cadence_spm=[],
        total_steps=0,
        gps_route=[],
    )
    assert bare["prizeHeld"] is True
    assert bare["prizeHoldReason"] == "missing_run_signal"
    # A real slow run keeps steps or cadence, and the gaps are not even.
    uneven = [
        {"latitude": 37.50, "longitude": 127.00, "recordedAt": "2026-10-05T00:00:00+00:00"},
        {"latitude": 37.501, "longitude": 127.0004, "recordedAt": "2026-10-05T00:01:10+00:00"},
        {"latitude": 37.503, "longitude": 127.001, "recordedAt": "2026-10-05T00:03:40+00:00"},
        {"latitude": 37.504, "longitude": 127.002, "recordedAt": "2026-10-05T00:04:05+00:00"},
        {"latitude": 37.508, "longitude": 127.001, "recordedAt": "2026-10-05T00:08:20+00:00"},
        {"latitude": 37.509, "longitude": 127.004, "recordedAt": "2026-10-05T00:15:00+00:00"},
    ]
    assert gps_spacing_uniform(uneven) is False
    # Six fixes over fifteen minutes is a drawing, even with a cadence list.
    assert gps_trace_sparse(uneven, 900) is True
    drawn = _finish(900, cadence_spm=[150, 162, 158], gps_route=uneven)
    assert drawn["prizeHeld"] is True
    assert drawn["prizeHoldReason"] == "sparse_gps"
    # Same drawing with a step total is still too few fixes.
    with_steps = _finish(
        900,
        cadence_spm=[150, 162, 158],
        total_steps=2200,
        gps_route=uneven,
    )
    assert with_steps["prizeHoldReason"] == "sparse_gps"


def _dense_irregular(count: int = 40) -> list[dict]:
    """About 1km with uneven gaps. Dense enough to be a live trace."""
    points = []
    elapsed = 0
    for index in range(count):
        gap = 8 + (index % 5) * 7
        elapsed += gap
        points.append(
            {
                "latitude": 37.5 + (index * 25.0) / 111_320.0,
                "longitude": 127.0 + ((index % 3) * 8.0) / 88_300.0,
                "recordedAt": (_START + timedelta(seconds=elapsed)).isoformat(),
            }
        )
    return points


def test_dense_irregular_gps_with_an_implausible_step_count_now_holds() -> None:
    """The gap pattern alone used to be enough to pay this: dense, uneven
    timestamps, a step total. The position still advances by almost the
    same step every fix no matter how the gap was nudged, and 2,200 steps
    for 1km is well under half a metre a stride. Neither signal alone
    blocks (see the two false-positive cases below); together they do.
    """
    route = _dense_irregular()
    assert gps_spacing_uniform(route) is False
    assert gps_trace_sparse(route, 900) is False
    held = _finish(
        900,
        cadence_spm=[150, 162, 158],
        total_steps=2200,
        gps_route=route,
    )
    assert held["prizeHeld"] is True
    assert held["prizeHoldReason"] == "gps_stride_mismatch"
    assert held["verifiedFinish"] is False
    unbacked = _finish(
        900,
        cadence_spm=[150, 162, 158],
        total_steps=0,
        gps_route=route,
    )
    assert unbacked["prizeHeld"] is True
    assert unbacked["prizeHoldReason"] == "cadence_unbacked"
    # An empty pace list still opens the door. Closing it would block the
    # first real race, and one slow drawing reopens it.
    assert beginner_entry_block(_user([])) is None


def test_dense_irregular_gps_with_a_plausible_step_count_still_pays() -> None:
    """False positive guard: the same gap-nudged trace, but the step count
    is an ordinary stride for the distance (1,300/km). The geometric
    signal alone is not enough to hold the prize.
    """
    route = _dense_irregular()
    paid = _finish(
        900,
        cadence_spm=[150, 162, 158],
        total_steps=1300,
        gps_route=route,
    )
    assert paid["verifiedFinish"] is True
    assert "prizeHeld" not in paid


def _dense_genuinely_variable(count: int = 40) -> list[dict]:
    """About 1km, both the gaps and the stride length vary -- a real
    phone trace, not a position that was advanced by a fixed step."""
    points = []
    elapsed = 0.0
    for index in range(count):
        time_gap = 8 + (index % 5) * 7
        elapsed += time_gap
        stride = 15.0 + (index % 7) * 6.0
        points.append(
            {
                "latitude": 37.5 + (index * stride) / 111_320.0,
                "longitude": 127.0,
                "recordedAt": (_START + timedelta(seconds=elapsed)).isoformat(),
            }
        )
    return points


def test_dense_genuinely_variable_gps_with_a_suspicious_step_count_still_pays() -> None:
    """False positive guard: the step count alone is the same implausible
    2,200/km, but the GPS stride length itself varies a normal amount, so
    the geometric half of the signal does not fire.
    """
    route = _dense_genuinely_variable()
    assert gps_spacing_uniform(route) is False
    paid = _finish(
        900,
        cadence_spm=[150, 162, 158],
        total_steps=2200,
        gps_route=route,
    )
    assert paid["verifiedFinish"] is True
    assert "prizeHeld" not in paid
