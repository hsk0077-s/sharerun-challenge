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


def test_wallet_balances_read_nested_map_without_defaulting_other_assets() -> None:
    share, dia, value = SecuredActionService._wallet_balances(
        {
            "wallet": {
                "shareBalance": 12,
                "diamondBalance": 3,
                "valueTokenBalance": 5000,
            }
        }
    )
    assert (share, dia, value) == (12, 3, 5000)


def test_harvest_result_returns_share_snapshot_and_preserves_dia_value() -> None:
    result = SecuredActionService()._harvest_result(
        status="harvested",
        reason="51 SHARE credited from walking challenge.",
        share_credited=51,
        share_balance=51,
        diamond_balance=0,
        value_token_balance=5000,
    )
    dumped = result.model_dump()
    assert dumped["share_credited"] == 51
    assert dumped["share_balance"] == 51
    assert dumped["diamond_balance"] == 0
    assert dumped["value_token_balance"] == 5000
    assert dumped["status"] == "harvested"


def test_debug_test_wallet_grant_amount_is_one_million() -> None:
    from app.constants.economy_constants import TEST_WALLET_GRANT_AMOUNT

    assert TEST_WALLET_GRANT_AMOUNT == 1_000_000


def test_debug_test_wallet_grant_flag_is_one_shot() -> None:
    assert SecuredActionService._test_grant_already_applied(
        {"testGrant1mDone": True}
    )
    assert not SecuredActionService._test_grant_already_applied({})
    assert not SecuredActionService._test_grant_already_applied(
        {"testGrant1mDone": False}
    )


def test_debug_test_wallet_grant_reapplies_when_flag_set_but_balances_zero() -> None:
    assert SecuredActionService._test_grant_needs_reapply(
        {"testGrant1mDone": True, "wallet": {}}
    )
    assert not SecuredActionService._test_grant_needs_reapply(
        {
            "testGrant1mDone": True,
            "wallet": {
                "shareBalance": 1_000_000,
                "diamondBalance": 1_000_000,
                "valueTokenBalance": 1_000_000,
            },
        }
    )
    assert not SecuredActionService._test_grant_needs_reapply({})


def test_debug_test_grant_request_defaults_are_safe_for_release() -> None:
    from app.models.secured_actions import DebugTestGrantRequest

    request = DebugTestGrantRequest()
    assert request.debug_client is False
    assert request.grant_secret == ""


def test_debug_test_wallet_grant_is_denied_without_allowlist_or_flag() -> None:
    assert not SecuredActionService.is_test_grant_authorized(
        "some-other-uid",
        {},
        "",
        allowlist=frozenset(),
        expected_secret="",
    )


def test_debug_test_wallet_grant_allows_allowlisted_uid() -> None:
    assert SecuredActionService.is_test_grant_authorized(
        "owner-uid",
        {},
        "",
        allowlist=frozenset({"owner-uid"}),
        expected_secret="",
    )


def test_debug_test_wallet_grant_allows_admin_eligible_flag() -> None:
    assert SecuredActionService.is_test_grant_authorized(
        "random-uid",
        {"testGrant1mEligible": True},
        "",
        allowlist=frozenset(),
        expected_secret="",
    )
    assert not SecuredActionService.is_test_grant_authorized(
        "random-uid",
        {"testGrant1mEligible": False},
        "",
        allowlist=frozenset(),
        expected_secret="",
    )


def test_debug_test_wallet_grant_allows_matching_secret_only() -> None:
    assert SecuredActionService.is_test_grant_authorized(
        "random-uid",
        {},
        "private-debug-secret",
        allowlist=frozenset(),
        expected_secret="private-debug-secret",
    )
    assert not SecuredActionService.is_test_grant_authorized(
        "random-uid",
        {},
        "wrong",
        allowlist=frozenset(),
        expected_secret="private-debug-secret",
    )
    assert not SecuredActionService.is_test_grant_authorized(
        "random-uid",
        {},
        "private-debug-secret",
        allowlist=frozenset(),
        expected_secret="",
    )


def test_debug_test_wallet_grant_allows_debug_client_baked_secret() -> None:
    from app.constants.economy_constants import (
        TEST_WALLET_GRANT_DEBUG_CLIENT_SECRET,
    )

    assert TEST_WALLET_GRANT_DEBUG_CLIENT_SECRET == "sharerun-debug-test-grant-1m"
    assert SecuredActionService.is_test_grant_authorized(
        "any-uid",
        {},
        TEST_WALLET_GRANT_DEBUG_CLIENT_SECRET,
        debug_client=True,
        allowlist=frozenset(),
        expected_secret="",
    )
    # Release/profile never send debug_client; baked secret alone is not enough.
    assert not SecuredActionService.is_test_grant_authorized(
        "any-uid",
        {},
        TEST_WALLET_GRANT_DEBUG_CLIENT_SECRET,
        debug_client=False,
        allowlist=frozenset(),
        expected_secret="",
    )
    assert not SecuredActionService.is_test_grant_authorized(
        "any-uid",
        {},
        "wrong",
        debug_client=True,
        allowlist=frozenset(),
        expected_secret="",
    )
    assert not SecuredActionService.is_test_grant_authorized(
        "play-store-uid",
        {},
        "",
        debug_client=False,
        allowlist=frozenset(),
        expected_secret="",
    )


def test_debug_test_wallet_grant_result_sets_all_three_assets() -> None:
    result = SecuredActionService()._harvest_result(
        status="granted",
        reason="Debug test grant set SHARE/DIA/VALUE to 1000000.",
        share_credited=1_000_000,
        share_balance=1_000_000,
        diamond_balance=1_000_000,
        value_token_balance=1_000_000,
    )
    dumped = result.model_dump()
    assert dumped["status"] == "granted"
    assert dumped["share_balance"] == 1_000_000
    assert dumped["diamond_balance"] == 1_000_000
    assert dumped["value_token_balance"] == 1_000_000
