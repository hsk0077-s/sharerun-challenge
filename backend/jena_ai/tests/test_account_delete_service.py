from unittest.mock import MagicMock, patch

from app.services.secured_action_service import SecuredActionService


def test_delete_account_anonymizes_profile_and_deletes_auth_user() -> None:
    service = SecuredActionService(firebase_service=MagicMock())
    user_ref = MagicMock()
    user_snapshot = MagicMock()
    user_snapshot.exists = True
    user_ref.get.return_value = user_snapshot
    service.firebase_service.db.collection.return_value.document.return_value = user_ref

    with patch(
        "app.services.secured_action_service.firebase_auth.delete_user"
    ) as delete_user:
        result = service.delete_account("user-test")

    assert result.accepted is True
    assert result.status == "deleted"
    user_ref.set.assert_called_once()
    delete_user.assert_called_once_with("user-test")
