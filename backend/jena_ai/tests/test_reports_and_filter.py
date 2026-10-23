"""Names other players see are filtered on the server, and players can report them."""

from types import SimpleNamespace

import pytest
from fastapi import HTTPException

from app.services import content_filter, crew_membership, reports
from app.services.secured_action_service import SecuredActionService
from test_redeem_referral import _MemoryDb


@pytest.mark.parametrize(
    "text",
    ["씨발크루", "씨 발", "S.H.I.T", "f u c k", "ＦＵＣＫ러너", "개새끼들"],
)
def test_banned_words_are_found_through_spacing_and_width(text: str) -> None:
    assert content_filter.contains_banned_word(text)


@pytest.mark.parametrize("text", ["인천 논현 러너", "Morning Runners", "달리는곰", "쉐어런123"])
def test_ordinary_names_pass(text: str) -> None:
    assert not content_filter.contains_banned_word(text)


def test_control_characters_are_found() -> None:
    assert content_filter.has_control_characters("크루​이름")
    assert content_filter.has_control_characters("크루\n이름")
    assert not content_filter.has_control_characters("크루 이름 🏃")


def _service(db: _MemoryDb) -> SecuredActionService:
    return SecuredActionService(firebase_service=SimpleNamespace(db=db))


def test_nickname_with_a_banned_word_is_refused() -> None:
    service = _service(_MemoryDb())
    with pytest.raises(HTTPException) as error:
        service.change_nickname("u1", "씨발러너")
    assert error.value.status_code == 400
    assert error.value.detail == "Inappropriate nickname."


def test_crew_rename_refuses_a_banned_word() -> None:
    service = _service(_MemoryDb())
    with pytest.raises(HTTPException) as error:
        crew_membership.rename(service, "u1", "병신 크루", "request-0001")
    assert error.value.detail == "Inappropriate crew name."


def test_found_crew_refuses_a_banned_word() -> None:
    db = _MemoryDb()
    service = _service(db)
    with pytest.raises(HTTPException) as error:
        service._found_crew_tx(
            SimpleNamespace(),
            "u1",
            "fuck crew",
            "share",
            "request-0001",
            db.collection("users").document("u1"),
            db.collection("crews").document("c1"),
        )
    assert error.value.detail == "Inappropriate crew name."


def _db_with_targets() -> _MemoryDb:
    db = _MemoryDb()
    db.store["crews/c1"] = {"name": "문제 크루"}
    db.store["users/bad"] = {"nickname": "문제닉"}
    return db


def test_report_is_stored_once_per_reporter_and_target() -> None:
    db = _db_with_targets()

    first = reports.submit_report(db, "u1", "crew", "c1", "offensive_name", "  욕설  ")
    again = reports.submit_report(db, "u1", "crew", "c1", "spam")

    assert first == {"status": "reported"}
    assert again == {"status": "already_reported"}
    rows = [row for path, row in db.store.items() if path.startswith("reports/")]
    assert len(rows) == 1
    assert rows[0]["reporterUid"] == "u1"
    assert rows[0]["targetName"] == "문제 크루"
    assert rows[0]["reason"] == "offensive_name"
    assert rows[0]["detail"] == "욕설"
    assert rows[0]["status"] == "open"


def test_report_of_a_user_keeps_the_nickname() -> None:
    db = _db_with_targets()
    reports.submit_report(db, "u1", "user", "bad", "hate")
    row = db.store["reports/u1_user_bad"]
    assert row["targetName"] == "문제닉"


@pytest.mark.parametrize(
    "target_type,target_id,reason,status",
    [
        ("crew", "c1", "nonsense", 400),
        ("team", "c1", "spam", 400),
        ("crew", "a/b", "spam", 400),
        ("user", "u1", "spam", 400),
        ("crew", "missing", "spam", 404),
    ],
)
def test_bad_reports_are_refused(target_type, target_id, reason, status) -> None:
    db = _db_with_targets()
    with pytest.raises(HTTPException) as error:
        reports.submit_report(db, "u1", target_type, target_id, reason)
    assert error.value.status_code == status
