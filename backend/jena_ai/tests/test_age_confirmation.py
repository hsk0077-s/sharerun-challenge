from unittest.mock import MagicMock

import pytest
from fastapi import HTTPException

from app.services.secured_action_service import SecuredActionService


def _service(exists: bool, data: dict | None = None):
    service = SecuredActionService(firebase_service=MagicMock())
    user_ref = MagicMock()
    snapshot = MagicMock()
    snapshot.exists = exists
    snapshot.to_dict.return_value = data or {}
    user_ref.get.return_value = snapshot
    service.firebase_service.db.collection.return_value.document.return_value = user_ref
    return service, user_ref


def test_confirm_age_records_the_time_once() -> None:
    service, user_ref = _service(True, {"uid": "u1"})

    result = service.confirm_age_over_14("u1")

    assert result.accepted is True
    assert result.status == "confirmed"
    written = user_ref.update.call_args.args[0]
    assert "ageOver14ConfirmedAt" in written


def test_confirm_age_keeps_the_first_time() -> None:
    service, user_ref = _service(True, {"ageOver14ConfirmedAt": "earlier"})

    result = service.confirm_age_over_14("u1")

    assert result.status == "already_confirmed"
    user_ref.update.assert_not_called()


def test_confirm_age_needs_an_existing_user() -> None:
    service, user_ref = _service(False)

    with pytest.raises(HTTPException) as exc_info:
        service.confirm_age_over_14("u1")

    assert exc_info.value.status_code == 404
    user_ref.update.assert_not_called()
