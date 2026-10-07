from app.models.secured_actions import RunDeviceInfo, ValidateRunRequest
from app.models.validation_result import ValidationResult, with_reason_code
from app.services.run_device_info import device_info_document


def test_device_info_stores_only_diagnostics() -> None:
    parsed = RunDeviceInfo.model_validate(
        {
            "model": "SM-N970F\nnote",
            "os_version": "Android 12",
            "app_version": "1.0.0+12",
            "watch_used": False,
            "heart_rate_used": True,
            "email": "runner@example.com",
            "serial": "secret",
        }
    )
    stored = device_info_document(parsed)

    assert stored == {
        "model": "SM-N970F note",
        "osVersion": "Android 12",
        "appVersion": "1.0.0+12",
        "watchUsed": False,
        "heartRateUsed": True,
    }
    assert set(stored) == {
        "model",
        "osVersion",
        "appVersion",
        "watchUsed",
        "heartRateUsed",
    }


def test_missing_device_info_is_not_stored() -> None:
    request = ValidateRunRequest(
        activity_id="activity-1",
        distance_km=1.2,
        duration_seconds=400,
        gyro_stability_score=0.4,
    )
    assert request.device_info is None
    assert device_info_document(request.device_info) is None


def test_long_fields_are_clipped_instead_of_rejecting_the_run() -> None:
    stored = device_info_document(
        RunDeviceInfo(model="M" * 200, os_version="Android 12", app_version="1")
    )
    assert stored is not None
    assert len(stored["model"]) == 80


def test_missing_reason_code_is_filled_only_when_absent() -> None:
    filled = with_reason_code(
        ValidationResult(
            verified=False,
            decision="rejected_kickboard",
            reason="old record",
            value_token_reward=0,
        )
    )
    kept = with_reason_code(
        ValidationResult(
            verified=False,
            decision="rejected_unknown",
            reason="short",
            reason_code="distance_too_short",
            value_token_reward=0,
        )
    )
    unknown = with_reason_code(
        ValidationResult(
            verified=False,
            decision="rejected_unknown",
            reason="검증 최소 거리에 못 미칩니다.",
            value_token_reward=0,
        )
    )

    assert filled.reason_code == "kickboard"
    assert kept.reason_code == "distance_too_short"
    assert unknown.reason_code == ""
