from unittest.mock import MagicMock, patch

import pytest
from fastapi import HTTPException

from app.services.secured_action_service import SecuredActionService


def test_validation_result_from_finalized_activity() -> None:
    result = SecuredActionService()._validation_result_from_activity(
        {
            "jenaVerified": True,
            "jenaDecision": "verified",
            "jenaReason": "Already verified.",
            "valueTokenReward": 500,
        }
    )

    assert result.verified is True
    assert result.decision == "verified"
    assert result.reason == "Already verified."
    assert result.value_token_reward == 500


def test_already_joined_returns_idempotent_success() -> None:
    result = SecuredActionService()._already_joined_result()

    assert result.accepted is True
    assert result.status == "joined"
    assert result.reason == "Tournament was already joined."


def test_already_collected_returns_idempotent_success() -> None:
    result = SecuredActionService()._already_collected_result()

    assert result.accepted is True
    assert result.status == "collected"
    assert result.reason == "Diamond box was already collected."


def test_already_reward_processed_returns_idempotent_success() -> None:
    result = SecuredActionService()._already_reward_processed_result()

    assert result.accepted is True
    assert result.status == "reward_processed"
    assert result.reason == "Winner reward was already processed."


def test_tournament_without_max_participants_is_not_full() -> None:
    assert SecuredActionService()._tournament_is_full(
        {"participantCount": 10}
    ) is False


def test_tournament_below_max_participants_is_not_full() -> None:
    assert SecuredActionService()._tournament_is_full(
        {"participantCount": 9, "maxParticipants": 10}
    ) is False


def test_tournament_at_max_participants_is_full() -> None:
    assert SecuredActionService()._tournament_is_full(
        {"participantCount": 10, "maxParticipants": 10}
    ) is True


from unittest.mock import MagicMock, patch

import pytest
from fastapi import HTTPException


@patch("app.services.secured_action_service.firebase_auth.get_user")
def test_ensure_email_verified_skips_when_no_email(mock_get_user: MagicMock) -> None:
    user = MagicMock()
    user.email = None
    mock_get_user.return_value = user

    SecuredActionService()._ensure_email_verified("uid-test")

    mock_get_user.assert_called_once_with("uid-test")


@patch("app.services.secured_action_service.firebase_auth.get_user")
def test_ensure_email_verified_raises_for_unverified_password(
    mock_get_user: MagicMock,
) -> None:
    user = MagicMock()
    user.email = "runner@example.com"
    user.email_verified = False
    provider = MagicMock()
    provider.provider_id = "password"
    user.provider_data = [provider]
    mock_get_user.return_value = user

    with pytest.raises(HTTPException) as exc_info:
        SecuredActionService()._ensure_email_verified("uid-test")

    assert exc_info.value.status_code == 403
    assert exc_info.value.detail == "Email verification is required."
