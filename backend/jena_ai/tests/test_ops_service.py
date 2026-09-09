from unittest.mock import MagicMock, patch

import pytest
from fastapi import HTTPException

from app.services.ops_service import OpsService


def test_purge_user_data_requires_deleted_status() -> None:
    service = OpsService(firebase_service=MagicMock())
    user_ref = MagicMock()
    user_snapshot = MagicMock()
    user_snapshot.exists = True
    user_snapshot.to_dict.return_value = {"accountStatus": "active"}
    user_ref.get.return_value = user_snapshot
    service.firebase_service.db.collection.return_value.document.return_value = user_ref

    with pytest.raises(HTTPException) as exc_info:
        service.purge_user_data("uid-test")

    assert exc_info.value.status_code == 400
    assert exc_info.value.detail == "Only deleted accounts can be purged."


def test_purge_user_data_deletes_activities_and_marks_purged() -> None:
    service = OpsService(firebase_service=MagicMock())
    db = service.firebase_service.db

    user_ref = MagicMock()
    user_snapshot = MagicMock()
    user_snapshot.exists = True
    user_snapshot.to_dict.return_value = {"accountStatus": "deleted"}
    user_ref.get.return_value = user_snapshot

    activity_snapshot = MagicMock()
    activities_query = MagicMock()
    activities_query.stream.return_value = [activity_snapshot]
    diamond_snapshot = MagicMock()
    diamond_collection = MagicMock()
    diamond_collection.stream.return_value = [diamond_snapshot]
    user_ref.collection.return_value = diamond_collection

    def collection_side_effect(name: str):
        if name == "users":
            users = MagicMock()
            users.document.return_value = user_ref
            return users
        if name == "activities":
            activities = MagicMock()
            activities.where.return_value = activities_query
            return activities
        raise AssertionError(f"Unexpected collection: {name}")

    db.collection.side_effect = collection_side_effect

    with patch(
        "app.services.ops_service.send_tournament_topic_notification"
    ):
        result = service.purge_user_data("uid-test")

    assert result.accepted is True
    assert result.status == "purged"
    assert result.deleted_activities == 1
    assert result.deleted_diamond_collections == 1
    activity_snapshot.reference.delete.assert_called_once()
    diamond_snapshot.reference.delete.assert_called_once()
    user_ref.set.assert_called_once()


def _tournament_service(
    *,
    exists: bool = True,
    tournament: dict | None = None,
) -> tuple[OpsService, MagicMock]:
    service = OpsService(firebase_service=MagicMock())
    tournament_ref = MagicMock()
    tournament_snapshot = MagicMock()
    tournament_snapshot.exists = exists
    tournament_snapshot.to_dict.return_value = tournament or {}
    tournament_ref.get.return_value = tournament_snapshot
    service.firebase_service.db.collection.return_value.document.return_value = (
        tournament_ref
    )
    return service, tournament_ref


@patch("app.services.ops_service.send_tournament_topic_notification")
def test_activate_tournament_sets_active_when_bep_met(
    mock_notify: MagicMock,
) -> None:
    service, tournament_ref = _tournament_service(
        tournament={
            "title": "Spring Run",
            "status": "recruiting",
            "participantCount": 10,
            "minParticipantsBep": 8,
        }
    )

    result = service.activate_tournament("tour-1")

    assert result.accepted is True
    assert result.status == "active"
    tournament_ref.update.assert_called_once()
    mock_notify.assert_called_once()


def test_activate_tournament_rejects_when_bep_not_met() -> None:
    service, _ = _tournament_service(
        tournament={
            "status": "recruiting",
            "participantCount": 3,
            "minParticipantsBep": 8,
        }
    )

    with pytest.raises(HTTPException) as exc_info:
        service.activate_tournament("tour-1")

    assert exc_info.value.status_code == 400
    assert exc_info.value.detail == "BEP has not been met; tournament cannot be activated."


@patch("app.services.ops_service.send_tournament_topic_notification")
def test_activate_tournament_is_idempotent_when_already_active(
    mock_notify: MagicMock,
) -> None:
    service, tournament_ref = _tournament_service(
        tournament={
            "status": "active",
            "participantCount": 10,
            "minParticipantsBep": 8,
        }
    )

    result = service.activate_tournament("tour-1")

    assert result.status == "active"
    assert result.reason == "Tournament was already active."
    tournament_ref.update.assert_not_called()
    mock_notify.assert_not_called()


def test_purge_deleted_accounts_skips_already_purged() -> None:
    service = OpsService(firebase_service=MagicMock())
    db = service.firebase_service.db

    purged_user = MagicMock()
    purged_user.id = "uid-purged"
    purged_user.to_dict.return_value = {
        "accountStatus": "deleted",
        "accountPurgedAt": "2026-01-01T00:00:00Z",
    }

    pending_user = MagicMock()
    pending_user.id = "uid-pending"
    pending_user.to_dict.return_value = {"accountStatus": "deleted"}

    users_query = MagicMock()
    users_query.where.return_value.limit.return_value.stream.return_value = [
        purged_user,
        pending_user,
    ]
    db.collection.return_value = users_query

    with patch.object(service, "purge_user_data") as purge_user_data:
        purge_user_data.return_value = MagicMock(accepted=True, status="purged")
        result = service.purge_deleted_accounts()

    purge_user_data.assert_called_once_with("uid-pending")
    assert result.processed_users == 1
    assert result.purged_users == ["uid-pending"]

