"""Crew emblem: stored with the crew, only from the fixed list."""

from types import SimpleNamespace

from fastapi import HTTPException
from fastapi.testclient import TestClient
import pytest

from app.main import app
from app.routers import secured_action_router
from app.services.auth_service import require_uid
from app.services.crew_emblem import DEFAULT_CREW_EMBLEM, normalize_crew_emblem
from app.services.secured_action_service import (
    SecuredActionService,
    _commit_crew_found_tx,
)
from test_redeem_referral import _MemoryDb, _MemoryTxn


def _found(db: _MemoryDb, emblem: str | None):
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))
    user_ref = db.collection("users").document("u1")
    crew_ref = db.collection("crews").document("crew1")
    return _commit_crew_found_tx.to_wrap(
        _MemoryTxn(), service, "u1", "우리크루", "share", "req-crew-01",
        user_ref, crew_ref, normalize_crew_emblem(emblem),
    )


def _seed(db: _MemoryDb) -> None:
    db.store["users/u1"] = {
        "wallet": {"shareBalance": 100_000, "diamondBalance": 0, "valueTokenBalance": 0}
    }


def test_chosen_emblem_is_stored_on_the_crew() -> None:
    db = _MemoryDb()
    _seed(db)
    _found(db, "rocket:sky")
    assert db.store["crews/crew1"]["emblem"] == "rocket:sky"


def test_missing_emblem_gets_the_default() -> None:
    db = _MemoryDb()
    _seed(db)
    _found(db, None)
    assert db.store["crews/crew1"]["emblem"] == DEFAULT_CREW_EMBLEM
    assert normalize_crew_emblem("  ") == DEFAULT_CREW_EMBLEM


@pytest.mark.parametrize(
    "bad", ["moon", "moon:red", "dragon:lime", "moon:lime:x", "<script>:lime", ":"]
)
def test_unknown_emblem_is_refused_and_nothing_is_charged(bad: str) -> None:
    db = _MemoryDb()
    _seed(db)
    with pytest.raises(HTTPException) as caught:
        _found(db, bad)
    assert caught.value.status_code == 400
    assert "crews/crew1" not in db.store
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 100_000


def test_route_passes_the_emblem_through() -> None:
    seen = {}

    def fake(uid, name, pay_with, request_id, emblem=None):
        seen.update(uid=uid, name=name, emblem=emblem)
        return {"accepted": True, "status": "created", "reason": "ok"}

    original = secured_action_router.service
    secured_action_router.service = SimpleNamespace(found_crew=fake)
    app.dependency_overrides[require_uid] = lambda: "u1"
    try:
        response = TestClient(app).post(
            "/actions/crew/found",
            json={"name": "우리크루", "pay_with": "dia",
                  "request_id": "req-crew-0001", "emblem": "star:gold"},
        )
    finally:
        secured_action_router.service = original
        app.dependency_overrides.clear()
    assert response.status_code == 200, response.text
    assert seen == {"uid": "u1", "name": "우리크루", "emblem": "star:gold"}


# ---- changing the emblem later --------------------------------------------
def _owner_service(db: _MemoryDb) -> SecuredActionService:
    return SecuredActionService(firebase_service=SimpleNamespace(db=db))


def test_owner_can_change_the_emblem_for_free() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {
        "ownedCrewId": "crew1",
        "wallet": {"shareBalance": 500, "diamondBalance": 7, "valueTokenBalance": 0},
    }
    db.store["crews/crew1"] = {"name": "우리크루", "ownerUid": "u1", "emblem": "moon:lime"}
    result = _owner_service(db).change_crew_emblem("u1", "bike:violet")
    assert result.status == "updated"
    assert db.store["crews/crew1"]["emblem"] == "bike:violet"
    assert db.store["crews/crew1"]["name"] == "우리크루"
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 500
    assert result.diamond_balance == 7
    assert not [p for p in db.store if p.startswith("walletTransactions/")]


def test_new_shapes_are_accepted() -> None:
    for shape in ("walk", "bee", "bunny", "spark", "globe", "skate"):
        assert normalize_crew_emblem(f"{shape}:gold") == f"{shape}:gold"


def test_someone_without_a_crew_cannot_change_an_emblem() -> None:
    db = _MemoryDb()
    db.store["users/u2"] = {"wallet": {}}
    with pytest.raises(HTTPException) as caught:
        _owner_service(db).change_crew_emblem("u2", "moon:lime")
    assert caught.value.status_code == 404


def test_cannot_change_a_crew_owned_by_someone_else() -> None:
    db = _MemoryDb()
    db.store["users/u3"] = {"ownedCrewId": "crew9", "wallet": {}}
    db.store["crews/crew9"] = {"ownerUid": "someone-else", "emblem": "moon:lime"}
    with pytest.raises(HTTPException):
        _owner_service(db).change_crew_emblem("u3", "star:gold")
    assert db.store["crews/crew9"]["emblem"] == "moon:lime"


def test_bad_emblem_is_refused_before_anything_is_read() -> None:
    db = _MemoryDb()
    with pytest.raises(HTTPException) as caught:
        _owner_service(db).change_crew_emblem("u1", "dragon:red")
    assert caught.value.status_code == 400


def test_emblem_route() -> None:
    seen = {}

    def fake(uid, emblem):
        seen.update(uid=uid, emblem=emblem)
        return {"accepted": True, "status": "updated", "reason": "ok"}

    original = secured_action_router.service
    secured_action_router.service = SimpleNamespace(change_crew_emblem=fake)
    app.dependency_overrides[require_uid] = lambda: "u1"
    try:
        response = TestClient(app).post("/actions/crew/emblem", json={"emblem": "sun:sky"})
    finally:
        secured_action_router.service = original
        app.dependency_overrides.clear()
    assert response.status_code == 200, response.text
    assert seen == {"uid": "u1", "emblem": "sun:sky"}
