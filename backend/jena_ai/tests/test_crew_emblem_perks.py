"""Unlock borders, paid emblems, sub-leaders and the change cooldown."""

from datetime import datetime, timedelta, timezone
from types import SimpleNamespace

from fastapi import HTTPException
import pytest

from app.services import crew_emblem_perks as perks
from app.services.crew_emblem import normalize_crew_emblem
from app.services.secured_action_service import (
    SecuredActionService,
    _commit_crew_paid_emblem_tx,
)
from test_redeem_referral import _MemoryDb, _MemoryTxn

V2 = "shield:g_wolf:rays:navy:white"


def _service(db) -> SecuredActionService:
    return SecuredActionService(firebase_service=SimpleNamespace(db=db))


def _seed(db, crew: dict | None = None, uid: str = "u1", user: dict | None = None):
    db.store[f"users/{uid}"] = user or {
        "ownedCrewId": "crew1",
        "wallet": {"shareBalance": 10, "diamondBalance": 100, "valueTokenBalance": 0},
    }
    db.store["crews/crew1"] = {"name": "c", "ownerUid": "u1", "emblem": "moon:lime", **(crew or {})}


@pytest.fixture(autouse=True)
def _env(monkeypatch):
    monkeypatch.delenv("CREW_EMBLEM_COOLDOWN_DAYS", raising=False)
    monkeypatch.delenv("CREW_EMBLEM_PAID_SALE", raising=False)


# ---- borders ----------------------------------------------------------------
def test_borders_follow_the_recorded_crew_stats() -> None:
    assert perks.earned_borders({}) == set()
    crew = {
        "totalDistanceKm": 5_000,
        "totalDonationWon": 99_999,
        "memberCount": 30,
        "bestMonthlyRank": 10,
    }
    assert perks.earned_borders(crew) == {
        "distance-1", "distance-2", "members-1", "members-2", "ranking-1", "ranking-2",
    }
    assert "ranking-3" not in perks.earned_borders({"bestMonthlyRank": 2})
    assert "ranking-3" in perks.earned_borders({"bestMonthlyRank": 1})


def test_a_border_once_recorded_stays_even_if_the_stat_drops() -> None:
    assert perks.earned_borders({"memberCount": 3, "unlockedBorders": ["members-2"]}) == {"members-2"}


def test_normalize_accepts_a_border_part_and_paid_ids() -> None:
    assert normalize_crew_emblem(f"{V2}:distance-2") == f"{V2}:distance-2"
    assert normalize_crew_emblem("paid:moon-wolf") == "paid:moon-wolf"
    for bad in (f"{V2}:distance-9", f"{V2}:gold", "paid:nope", "paid:"):
        with pytest.raises(HTTPException):
            normalize_crew_emblem(bad)


def test_cannot_wear_a_border_the_crew_has_not_earned() -> None:
    db = _MemoryDb()
    _seed(db, {"memberCount": 12})
    with pytest.raises(HTTPException) as caught:
        _service(db).change_crew_emblem("u1", f"{V2}:distance-1")
    assert caught.value.status_code == 403
    assert db.store["crews/crew1"]["emblem"] == "moon:lime"


def test_earned_border_is_stored_and_recorded() -> None:
    db = _MemoryDb()
    _seed(db, {"memberCount": 12})
    _service(db).change_crew_emblem("u1", f"{V2}:members-1")
    assert db.store["crews/crew1"]["emblem"] == f"{V2}:members-1"
    assert db.store["crews/crew1"]["unlockedBorders"] == ["members-1"]


# ---- cooldown and who may change --------------------------------------------
def test_second_change_inside_the_cooldown_is_refused() -> None:
    db = _MemoryDb()
    _seed(db, {"emblemChangedAt": datetime.now(timezone.utc) - timedelta(days=2)})
    with pytest.raises(HTTPException) as caught:
        _service(db).change_crew_emblem("u1", V2)
    assert caught.value.status_code == 429


def test_change_after_the_cooldown_is_allowed() -> None:
    db = _MemoryDb()
    _seed(db, {"emblemChangedAt": datetime.now(timezone.utc) - timedelta(days=8)})
    assert _service(db).change_crew_emblem("u1", V2).status == "updated"


def test_cooldown_days_can_be_set_to_zero_for_testing(monkeypatch) -> None:
    monkeypatch.setenv("CREW_EMBLEM_COOLDOWN_DAYS", "0")
    db = _MemoryDb()
    _seed(db, {"emblemChangedAt": datetime.now(timezone.utc)})
    assert _service(db).change_crew_emblem("u1", V2).status == "updated"


def test_a_sub_leader_may_change_but_a_plain_member_may_not() -> None:
    db = _MemoryDb()
    _seed(db, {"subLeaderUids": ["u2"]})
    db.store["users/u2"] = {"crewId": "crew1", "wallet": {}}
    db.store["users/u3"] = {"crewId": "crew1", "wallet": {}}
    assert _service(db).change_crew_emblem("u2", V2).status == "updated"
    with pytest.raises(HTTPException) as caught:
        _service(db).change_crew_emblem("u3", "shield:g_star:none:navy:lime")
    assert caught.value.status_code == 404


# ---- paid ---------------------------------------------------------------------
def test_paid_emblem_needs_ownership() -> None:
    db = _MemoryDb()
    _seed(db)
    with pytest.raises(HTTPException) as caught:
        _service(db).change_crew_emblem("u1", "paid:moon-wolf")
    assert caught.value.status_code == 403
    db.store["crews/crew1"]["paidEmblems"] = ["moon-wolf"]
    assert _service(db).change_crew_emblem("u1", "paid:moon-wolf").status == "updated"


def test_paid_sale_is_off_until_switched_on() -> None:
    db = _MemoryDb()
    _seed(db)
    with pytest.raises(HTTPException) as caught:
        _service(db).purchase_crew_paid_emblem("u1", "moon-wolf", "req-paid-0001")
    assert caught.value.status_code == 403
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 100


def test_buying_charges_diamonds_once_and_the_crew_keeps_it(monkeypatch) -> None:
    monkeypatch.setenv("CREW_EMBLEM_PAID_SALE", "on")
    db = _MemoryDb()
    _seed(db)
    service = _service(db)
    user_ref = db.collection("users").document("u1")
    crew_ref = db.collection("crews").document("crew1")

    def buy():
        return _commit_crew_paid_emblem_tx.to_wrap(
            _MemoryTxn(), service, "u1", "glow-heart", 50, "req-paid-0001", user_ref, crew_ref
        )

    assert buy().status == "bought"
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 50
    assert db.store["crews/crew1"]["paidEmblems"] == ["glow-heart"]
    again = buy()
    assert again.status == "already_bought"
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 50


def test_not_enough_diamonds_buys_nothing(monkeypatch) -> None:
    monkeypatch.setenv("CREW_EMBLEM_PAID_SALE", "on")
    db = _MemoryDb()
    _seed(db, user={"ownedCrewId": "crew1", "wallet": {"diamondBalance": 10}})
    service = _service(db)
    with pytest.raises(HTTPException):
        _commit_crew_paid_emblem_tx.to_wrap(
            _MemoryTxn(), service, "u1", "moon-wolf", 40, "req-paid-0002",
            db.collection("users").document("u1"), db.collection("crews").document("crew1"),
        )
    assert "paidEmblems" not in db.store["crews/crew1"]


def test_status_lists_progress_and_sale_state() -> None:
    db = _MemoryDb()
    _seed(db, {"memberCount": 12, "totalDistanceKm": 40.5})
    status = _service(db).crew_emblem_status("u1")
    assert status["earned_borders"] == ["members-1"]
    assert status["progress"]["distance"] == 40.5
    assert status["paid_sale_enabled"] is False
    assert status["paid_prices"]["glow-heart"] == 50
