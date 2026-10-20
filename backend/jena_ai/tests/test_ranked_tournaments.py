"""Tier and free tournaments: entry rules, challenge ticket use, finish, settle."""

from datetime import datetime, timedelta, timezone

from fastapi import HTTPException
import pytest

from app.services.ranked_tournaments import (
    entry_decision,
    open_ranked_tournament,
    ranked_finish_fields,
    settle_ranked_tournament,
)
from test_join_tournament_tx import _join
from test_redeem_referral import _MemoryDb

NOW = datetime(2026, 10, 14, 3, 0, tzinfo=timezone.utc)


def _user(grade_rank: int | None, **extra) -> dict:
    user = {
        "tier": 1,
        "wallet": {"shareBalance": 5_000, "diamondBalance": 0, "valueTokenBalance": 0},
    }
    if grade_rank is not None:
        user["gradeRank"] = grade_rank
    user.update(extra)
    return user


def _tier_room(animal: int, **extra) -> dict:
    room = {
        "status": "recruiting",
        "kind": "tier",
        "tierAnimal": animal,
        "requiredTier": 1,
        "entryFeeShare": 100,
        "participantCount": 0,
        "targetDistanceKm": 5,
    }
    room.update(extra)
    return room


def test_decision_table() -> None:
    wolf = _user(12)  # wolf silver
    assert entry_decision(wolf, _tier_room(3))["allowed"]
    assert not entry_decision(wolf, _tier_room(3))["needsTicket"]
    up = entry_decision(wolf, _tier_room(4))
    assert up["allowed"] and up["needsTicket"]
    assert entry_decision(wolf, _tier_room(2))["reason"] == "too_low"
    assert entry_decision(wolf, _tier_room(5))["reason"] == "too_high"
    assert entry_decision(_user(None), _tier_room(1))["reason"] == "ungraded"
    free = {"kind": "free"}
    assert entry_decision(wolf, free)["allowed"]
    assert entry_decision(_user(None), free)["reason"] == "ungraded"


def test_same_animal_joins_without_a_ticket() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _user(12)
    db.store["tournaments/t1"] = _tier_room(3)
    assert _join(db, "u1", "t1").status == "joined"
    assert "challengedUp" not in db.store["tournaments/t1/participants/u1"]
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 4_900


def test_lower_and_far_tournaments_are_refused() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _user(12)
    db.store["tournaments/low"] = _tier_room(2)
    db.store["tournaments/far"] = _tier_room(5)
    for room in ("low", "far"):
        with pytest.raises(HTTPException) as caught:
            _join(db, "u1", room)
        assert caught.value.status_code == 403
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 5_000


def test_snail_cannot_join() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _user(None)
    db.store["tournaments/t1"] = _tier_room(1)
    with pytest.raises(HTTPException) as caught:
        _join(db, "u1", "t1")
    assert caught.value.status_code == 403


def test_one_step_up_spends_a_ticket_and_marks_the_runner() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _user(12)
    db.store["users/u1/shopInventory/challenge_ticket"] = {"quantity": 1}
    db.store["tournaments/t1"] = _tier_room(4)
    assert _join(db, "u1", "t1").status == "joined"
    assert db.store["users/u1/shopInventory/challenge_ticket"]["quantity"] == 0
    assert db.store["tournaments/t1/participants/u1"]["challengedUp"] is True
    assert "walletTransactions/shop_use_u1_challenge_ticket_t1" in db.store


def test_one_step_up_without_a_ticket_is_refused_and_charges_nothing() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _user(12)
    db.store["tournaments/t1"] = _tier_room(4)
    with pytest.raises(HTTPException) as caught:
        _join(db, "u1", "t1")
    assert caught.value.status_code == 400
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 5_000


def test_ticket_works_once_a_week() -> None:
    db = _MemoryDb()
    from app.services.promotion_points import week_key
    db.store["users/u1"] = _user(
        12, challengeTicketUse={"weekKey": week_key(datetime.now(timezone.utc)), "count": 1}
    )
    db.store["users/u1/shopInventory/challenge_ticket"] = {"quantity": 3}
    db.store["tournaments/t1"] = _tier_room(4)
    with pytest.raises(HTTPException) as caught:
        _join(db, "u1", "t1")
    assert caught.value.status_code == 400
    assert db.store["users/u1/shopInventory/challenge_ticket"]["quantity"] == 3


def test_finish_fields_only_for_ranked_and_keep_the_best_time() -> None:
    room = _tier_room(3)
    first = ranked_finish_fields(
        room, {}, distance_km=5.0, duration_seconds=1500, activity_id="a1"
    )
    assert first["verifiedFinish"] is True and first["durationSeconds"] == 1500
    slower = ranked_finish_fields(
        room, {"verifiedFinish": True, "durationSeconds": 1500},
        distance_km=5.0, duration_seconds=1600, activity_id="a2",
    )
    assert slower is None
    short = ranked_finish_fields(
        room, {}, distance_km=4.0, duration_seconds=1000, activity_id="a3"
    )
    assert short is None
    assert ranked_finish_fields(
        {"kind": "other"}, {}, distance_km=5, duration_seconds=1, activity_id="a"
    ) is None
    assert ranked_finish_fields(
        {**room, "rankedSettled": True}, {}, distance_km=5,
        duration_seconds=1, activity_id="a",
    ) is None


def _settle_setup(db: _MemoryDb, count: int, kind: str = "tier") -> None:
    room = _tier_room(1) if kind == "tier" else {"kind": "free", "targetDistanceKm": 3}
    db.store["tournaments/race"] = {**room, "status": "active"}
    for index in range(count):
        uid = f"u{index:02d}"
        db.store[f"users/{uid}"] = {
            "gradeRank": 2,
            "authCreatedAt": (NOW - timedelta(days=90)).isoformat(),
        }
        db.store[f"tournaments/race/participants/{uid}"] = {
            "uid": uid,
            "verifiedFinish": True,
            "durationSeconds": 1000 + index,
            **({"challengedUp": True} if index == 1 else {}),
        }


def test_settle_gives_points_once_and_locks_the_race() -> None:
    db = _MemoryDb()
    _settle_setup(db, 10)
    first = settle_ranked_tournament(db, "race", now=NOW)
    assert first.status == "settled" and first.finisher_count == 10
    assert db.store["promotionLedger/race__u00"]["points"] == 40  # 40 x 1.0 x 1.0
    assert db.store["promotionLedger/race__u01"]["points"] == 30  # 25 x 1.0 x 1.2
    assert db.store["tournaments/race"]["rankedSettled"] is True
    again = settle_ranked_tournament(db, "race", now=NOW)
    assert again.status == "already_settled"


def test_free_tournament_needs_ten_finishers() -> None:
    db = _MemoryDb()
    _settle_setup(db, 9, kind="free")
    settle_ranked_tournament(db, "race", now=NOW)
    assert db.store["promotionLedger/race__u00"]["points"] == 0


def test_settle_refuses_other_tournaments() -> None:
    db = _MemoryDb()
    db.store["tournaments/p"] = {"status": "active", "prizeTier": "mid"}
    with pytest.raises(HTTPException) as caught:
        settle_ranked_tournament(db, "p", now=NOW)
    assert caught.value.status_code == 400


def test_open_is_idempotent_and_validates() -> None:
    db = _MemoryDb()
    made = open_ranked_tournament(
        db, "t9", kind="tier", title="늑대 5km", target_distance_km=5, tier_animal=3,
        entry_fee_share=100,
    )
    assert made["status"] == "created"
    assert db.store["tournaments/t9"]["tierAnimal"] == 3
    same = open_ranked_tournament(
        db, "t9", kind="tier", title="늑대 5km", target_distance_km=5, tier_animal=3,
        entry_fee_share=100,
    )
    assert same["status"] == "already_created"
    with pytest.raises(HTTPException) as caught:
        open_ranked_tournament(
            db, "t9", kind="tier", title="다른", target_distance_km=5, tier_animal=3
        )
    assert caught.value.status_code == 409
    with pytest.raises(HTTPException):
        open_ranked_tournament(db, "t8", kind="tier", title="x", target_distance_km=5)


# ---- HTTP level: routes, auth, and request plumbing -------------------------
from types import SimpleNamespace

from fastapi.testclient import TestClient

from app.main import app
from app.routers import ops_router, secured_action_router
from app.services.auth_service import require_uid
from app.services.ops_service import OpsService


def test_ops_routes_create_then_settle_a_ranked_tournament(monkeypatch) -> None:
    monkeypatch.setenv("OPS_ADMIN_SECRET", "ops-secret")
    db = _MemoryDb()
    original = ops_router.service
    ops_router.service = OpsService(firebase_service=SimpleNamespace(db=db))
    headers = {"x-ops-admin-secret": "ops-secret"}
    body = {"kind": "tier", "title": "늑대 5km", "target_distance_km": 5, "tier_animal": 3}
    try:
        client = TestClient(app)
        denied = client.post("/ops/ranked-tournaments/r1", json=body, headers={"x-ops-admin-secret": "x"})
        made = client.post("/ops/ranked-tournaments/r1", json=body, headers=headers)
        again = client.post("/ops/ranked-tournaments/r1", json=body, headers=headers)
        bad = client.post(
            "/ops/ranked-tournaments/r2",
            json={**body, "tier_animal": 9},
            headers=headers,
        )
        early = client.post("/ops/tournaments/r1/settle", headers=headers)
        db.store["tournaments/r1"]["status"] = "active"
        for i in range(5):
            uid = f"u{i}"
            db.store[f"users/{uid}"] = {"gradeRank": 12}
            db.store[f"tournaments/r1/participants/{uid}"] = {
                "verifiedFinish": True, "durationSeconds": 1000 + i,
            }
        settled = client.post("/ops/tournaments/r1/settle", headers=headers)
        twice = client.post("/ops/tournaments/r1/settle", headers=headers)
    finally:
        ops_router.service = original

    assert denied.status_code == 401
    assert made.status_code == 200 and made.json()["status"] == "created"
    assert again.json()["status"] == "already_created"
    assert bad.status_code == 400
    assert early.status_code == 400
    assert settled.status_code == 200 and settled.json()["status"] == "settled"
    assert settled.json()["finisher_count"] == 5
    assert twice.json()["status"] == "already_settled"
    assert db.store["promotionLedger/r1__u0"]["points"] == 24  # 40 x 0.6 x 1.0


def test_shop_purchase_route_passes_pay_with(monkeypatch) -> None:
    seen = {}

    def fake(uid, item_id, request_id=None, pay_with=None):
        seen.update(uid=uid, item_id=item_id, request_id=request_id, pay_with=pay_with)
        return {"accepted": True, "status": "purchased", "reason": "ok"}

    original = secured_action_router.service
    secured_action_router.service = SimpleNamespace(purchase_shop_item=fake)
    app.dependency_overrides[require_uid] = lambda: "u1"
    try:
        response = TestClient(app).post(
            "/actions/shop/purchase",
            json={"item_id": "challenge_ticket", "request_id": "r1", "pay_with": "dia"},
        )
    finally:
        secured_action_router.service = original
        app.dependency_overrides.clear()
    assert response.status_code == 200, response.text
    assert seen == {
        "uid": "u1", "item_id": "challenge_ticket", "request_id": "r1", "pay_with": "dia"
    }
