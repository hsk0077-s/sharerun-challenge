from types import SimpleNamespace

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.routers import secured_action_router
from app.services import profile_language
from app.services.auth_service import require_uid
from test_redeem_referral import _MemoryDb



def _db(user: dict | None = None) -> _MemoryDb:
    db = _MemoryDb()
    if user is not None:
        db.store["users/u1"] = user
    return db


def test_saves_language_and_country_on_an_existing_user() -> None:
    db = _db({"nickname": "runner"})

    result = profile_language.record_language(db, "u1", "ja", "JP")

    assert result == {"status": "saved", "language": "ja"}
    user = db.store["users/u1"]
    assert user["language"] == "ja"
    assert user["countryCode"] == "JP"
    assert user["nickname"] == "runner"


def test_does_not_create_a_user_that_does_not_exist() -> None:
    db = _db()

    assert profile_language.record_language(db, "u1", "ko", "KR") == {
        "status": "no_user"
    }
    assert "users/u1" not in db.store


def test_same_values_are_not_written_again() -> None:
    db = _db({"language": "ko", "countryCode": "KR"})

    assert profile_language.record_language(db, "u1", "ko", "KR")["status"] == "unchanged"
    assert profile_language.record_language(db, "u1", "ko", None)["status"] == "unchanged"


def test_a_new_language_replaces_the_old_one() -> None:
    db = _db({"language": "ko", "countryCode": "KR"})

    assert profile_language.record_language(db, "u1", "vi", "VN")["status"] == "saved"
    assert db.store["users/u1"]["language"] == "vi"
    assert db.store["users/u1"]["countryCode"] == "VN"


def test_country_is_left_alone_when_the_phone_has_none() -> None:
    db = _db({"language": "ko", "countryCode": "KR"})

    profile_language.record_language(db, "u1", "en", None)

    assert db.store["users/u1"]["language"] == "en"
    assert db.store["users/u1"]["countryCode"] == "KR"


@pytest.fixture
def client(monkeypatch):
    db = _db({"nickname": "runner"})
    monkeypatch.setattr(
        secured_action_router,
        "service",
        SimpleNamespace(firebase_service=SimpleNamespace(db=db)),
    )
    app.dependency_overrides[require_uid] = lambda: "u1"
    yield TestClient(app), db
    app.dependency_overrides.clear()


def test_route_saves_a_shipped_language(client) -> None:
    http, db = client

    response = http.post(
        "/actions/profile/language", json={"language": "th", "country_code": "TH"}
    )

    assert response.status_code == 200
    assert response.json()["status"] == "saved"
    assert db.store["users/u1"]["language"] == "th"


@pytest.mark.parametrize(
    "body",
    [
        {"language": "ru"},
        {"language": "ko", "country_code": "kr"},
        {"language": "ko", "country_code": "KOR"},
        {},
    ],
)
def test_route_refuses_unknown_languages_and_bad_countries(client, body) -> None:
    http, db = client

    assert http.post("/actions/profile/language", json=body).status_code == 422
    assert "language" not in db.store["users/u1"]


def test_every_shipped_language_is_accepted() -> None:
    assert set(profile_language.SUPPORTED_LANGUAGES) == {
        "ko", "en", "ja", "zh", "es", "pt", "de", "fr", "vi", "th", "id",
    }
