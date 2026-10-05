from app.models.validation_request import ValidationRequest

from app.services.running_validation_service import (
    RunningValidationService,
    policy_for_room,
)





def _request(

    *,

    distance_km: float = 3.0,

    duration_seconds: int = 1_800,

    heart_rates: list[int] | None = None,

    cadence_spm: list[int] | None = None,

    gyro_stability_score: float = 0.3,

) -> ValidationRequest:

    return ValidationRequest(

        activity_id="activity-test",

        user_id="user-test",

        distance_km=distance_km,

        duration_seconds=duration_seconds,

        heart_rates=[130, 142, 150] if heart_rates is None else heart_rates,

        cadence_spm=[158, 164, 170] if cadence_spm is None else cadence_spm,

        gyro_stability_score=gyro_stability_score,

    )





def test_rejects_kickboard_like_activity() -> None:

    result = RunningValidationService().validate(

        _request(

            duration_seconds=480,

            heart_rates=[72, 76, 78],

            cadence_spm=[0, 4, 6],

        )

    )



    assert result.verified is False

    assert result.decision == "rejected_kickboard"

    assert result.value_token_reward == 0

    assert result.forfeit_deposit is True





def test_rejects_bike_like_activity() -> None:

    result = RunningValidationService().validate(

        _request(

            heart_rates=[124, 132, 140],

            cadence_spm=[70, 74, 78],

            gyro_stability_score=0.96,

        )

    )



    assert result.verified is False

    assert result.decision == "rejected_bike"

    assert result.value_token_reward == 0

    assert result.forfeit_deposit is True





def test_verifies_normal_run_and_rewards_value_token() -> None:

    result = RunningValidationService().validate(

        _request(

            distance_km=3.2,

            duration_seconds=1_680,

            heart_rates=[122, 148, 158],

            cadence_spm=[152, 164, 176],

            gyro_stability_score=0.42,

        )

    )



    assert result.verified is True

    assert result.decision == "verified"

    assert result.value_token_reward == 32

    assert result.forfeit_deposit is False





def test_rejects_flat_heart_rate_curve_despite_cadence() -> None:

    result = RunningValidationService().validate(

        _request(

            distance_km=3.5,

            duration_seconds=1_800,

            heart_rates=[140, 140, 140],

            cadence_spm=[160, 165, 170],

            gyro_stability_score=0.35,

        )

    )



    assert result.verified is False

    assert result.decision == "rejected_unknown"


def test_phone_only_six_minute_pace_verifies_without_heart_rate() -> None:
    """3.0 km at 6:00/km, pedometer cadence, no watch."""
    result = RunningValidationService().validate(
        ValidationRequest(
            activity_id="activity-phone",
            user_id="user-phone",
            distance_km=3.0,
            duration_seconds=1_080,
            heart_rates=[],
            cadence_spm=[160],
            gyro_stability_score=0.45,
        )
    )

    assert result.verified is True
    assert result.decision == "verified"
    assert result.value_token_reward == 30
    assert result.forfeit_deposit is False


def test_six_minute_pace_without_steps_is_not_a_kickboard() -> None:
    result = RunningValidationService().validate(
        ValidationRequest(
            activity_id="activity-phone-empty",
            user_id="user-phone",
            distance_km=3.0,
            duration_seconds=1_080,
            heart_rates=[],
            cadence_spm=[],
            gyro_stability_score=0.45,
        )
    )

    assert result.verified is False
    assert result.decision == "rejected_unknown"
    assert result.forfeit_deposit is False


def test_free_run_floor_is_one_kilometer() -> None:
    service = RunningValidationService()
    verified = service.validate(
        _request(distance_km=1.0, duration_seconds=420, heart_rates=[], cadence_spm=[150])
    )
    short = service.validate(
        _request(distance_km=0.9, duration_seconds=400, heart_rates=[], cadence_spm=[150])
    )

    assert verified.verified is True
    assert verified.reason_code == "verified"
    assert verified.value_token_reward == 10
    assert short.verified is False
    assert short.reason_code == "distance_too_short"
    assert short.forfeit_deposit is False


def test_room_distance_replaces_the_old_three_kilometer_floor() -> None:
    policy = policy_for_room(has_room=True, target_distance_km=3.0)
    result = RunningValidationService().validate(
        _request(distance_km=2.9, duration_seconds=1_200),
        policy,
    )

    assert policy.min_distance_km == 3.0
    assert result.reason_code == "distance_too_short"
    assert result.forfeit_deposit is False


def test_cadence_band_is_120_to_210() -> None:
    service = RunningValidationService()
    low = service.validate(_request(cadence_spm=[119, 119, 119]))
    high = service.validate(_request(cadence_spm=[211, 211, 211]))
    edges = service.validate(_request(cadence_spm=[120, 210]))

    assert low.reason_code == "cadence_out_of_range"
    assert high.reason_code == "cadence_out_of_range"
    assert edges.verified is True


def test_heart_rate_required_rejects_without_forfeiture() -> None:
    result = RunningValidationService().validate(
        _request(distance_km=10.0, duration_seconds=3_600, heart_rates=[], cadence_spm=[160]),
        policy_for_room(
            has_room=True,
            tier_min_distance_km=10.0,
            requires_heart_rate=True,
        ),
    )

    assert result.verified is False
    assert result.reason_code == "heart_rate_required"
    assert result.forfeit_deposit is False


def test_phone_only_rejects_long_stride_and_vehicle_speed() -> None:
    service = RunningValidationService()
    stride = service.validate(
        _request(distance_km=1.0, duration_seconds=420, heart_rates=[], cadence_spm=[160]),
        total_steps=200,
    )
    started = "2026-10-05T00:00:00+00:00"
    ended = "2026-10-05T00:00:30+00:00"
    vehicle = service.validate(
        _request(distance_km=1.2, duration_seconds=420, heart_rates=[], cadence_spm=[160]),
        total_steps=1_200,
        gps_route=[
            {"latitude": 37.50, "longitude": 127.00, "recordedAt": started},
            {"latitude": 37.50, "longitude": 127.02, "recordedAt": ended},
        ],
    )

    assert stride.reason_code == "stride_out_of_range"
    assert stride.forfeit_deposit is False
    assert vehicle.reason_code == "vehicle_speed"
    assert vehicle.forfeit_deposit is False


def test_missing_heart_rate_does_not_count_as_a_kickboard_or_bike() -> None:
    service = RunningValidationService()
    running = service.validate(
        _request(
            distance_km=1.0,
            duration_seconds=420,
            heart_rates=[],
            cadence_spm=[160],
            gyro_stability_score=0.98,
        )
    )
    kickboard = service.validate(
        _request(
            distance_km=1.0,
            duration_seconds=200,
            heart_rates=[],
            cadence_spm=[4, 6],
            gyro_stability_score=0.2,
        )
    )

    assert running.verified is True
    assert running.decision == "verified"
    assert kickboard.decision == "rejected_kickboard"
    assert kickboard.reason_code == "kickboard"
    assert kickboard.forfeit_deposit is True


def test_user_room_and_prize_tier_policies() -> None:
    user_room = policy_for_room(has_room=True, target_distance_km=2.0)
    beginner = policy_for_room(
        has_room=True,
        tier_min_distance_km=1.0,
        requires_heart_rate=False,
    )
    advanced = policy_for_room(
        has_room=True,
        tier_min_distance_km=10.0,
        requires_heart_rate=True,
    )
    free = policy_for_room(has_room=False)

    assert user_room.min_distance_km == 2.0
    assert user_room.requires_heart_rate is False
    assert beginner.min_distance_km == 1.0
    assert beginner.requires_heart_rate is False
    assert advanced.min_distance_km == 10.0
    assert advanced.requires_heart_rate is True
    assert free.min_distance_km == 1.0
    assert free.requires_heart_rate is False


def test_validation_policy_reads_room_distance_and_prize_tier() -> None:
    from types import SimpleNamespace

    from app.services.secured_action_service import SecuredActionService
    from test_redeem_referral import _MemoryDb

    db = _MemoryDb()
    db.store["tournaments/room"] = {"targetDistanceKm": 2}
    db.store["tournaments/race"] = {"prizeTier": "advanced", "targetDistanceKm": 0}
    db.store["tournaments/beginner"] = {"prizeTier": "beginner", "targetDistanceKm": 0}
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))

    user_room = service._validation_policy("room")
    advanced = service._validation_policy("race")
    beginner = service._validation_policy("beginner")
    free = service._validation_policy(None)

    assert user_room.min_distance_km == 2.0
    assert user_room.requires_heart_rate is False
    assert advanced.min_distance_km == 10.0
    assert advanced.requires_heart_rate is True
    assert beginner.min_distance_km == 1.0
    assert beginner.requires_heart_rate is False
    assert free.min_distance_km == 1.0
    assert free.requires_heart_rate is False

