"""What pace_too_fast and the pace floor do with a slow GPS kilometre.

``pace_too_fast`` is not a validation reason. Validation uses
``implausible_pace`` under 150 sec/km and ``vehicle_speed`` over 25 km/h.
A 1km trace drawn slower than that still verifies and can become a grade
sample. Beginner entry and a beginner prize finish then look at the pace
number, not at the shape of the trace.
"""

from datetime import datetime, timedelta, timezone

from app.models.validation_request import ValidationRequest
from app.services.company_tournament_settlement import prize_finish_fields
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


def _finish(duration: int, distance: float = 1.0) -> dict | None:
    return prize_finish_fields(
        {"prizeTier": "beginner", "targetDistanceKm": 1, "status": "active"},
        {"uid": "runner", "status": "joined"},
        distance_km=distance,
        duration_seconds=duration,
        activity_id="finish",
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
    assert _finish(900)["verifiedFinish"] is True


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
