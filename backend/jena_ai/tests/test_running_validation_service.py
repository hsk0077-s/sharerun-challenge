from app.models.validation_request import ValidationRequest

from app.services.running_validation_service import RunningValidationService





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

        heart_rates=heart_rates or [130, 142, 150],

        cadence_spm=cadence_spm or [158, 164, 170],

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

