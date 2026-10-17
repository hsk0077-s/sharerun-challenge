"""Joining, leaving and listing crews."""

from types import SimpleNamespace

from fastapi import HTTPException
from google.cloud import firestore
import pytest

from app.services import crew_membership as cm
from test_redeem_referral import _MemoryDb, _MemoryTxn


def _seed(db: _MemoryDb) -> None:
    db.store["users/u1"] = {"ownedCrewId": "c1", "nickname": "대장"}
    db.store["users/u2"] = {"nickname": "러너2"}
    db.store["users/u3"] = {"nickname": "러너3", "crewId": "c2"}
    db.store["crews/c1"] = {"name": "새벽러너", "ownerUid": "u1", "emblem": "moon:lime", "memberCount": 1, "totalDistanceKm": 12}
    db.store["crews/c1/members/u1"] = {"uid": "u1"}
    db.store["crews/c2"] = {"name": "한강크루", "ownerUid": "x", "emblem": "moon:lime", "memberCount": 5}


def _join(db, uid, crew_id):
    return cm._join_tx.to_wrap(
        _MemoryTxn(), db, uid, db.collection("users").document(uid), db.collection("crews").document(crew_id)
    )


def _leave(db, uid):
    return cm._leave_tx.to_wrap(_MemoryTxn(), db, uid, db.collection("users").document(uid))


def test_list_filters_by_name_and_hides_nothing_private() -> None:
    db = _MemoryDb()
    _seed(db)
    names = [c["name"] for c in cm.list_crews(db, "")]
    assert names == ["한강크루", "새벽러너"]  # biggest first
    only = cm.list_crews(db, " 새벽 ")
    assert [c["id"] for c in only] == ["c1"]
    assert set(only[0]) == {"id", "name", "emblem", "member_count", "max_members", "is_full", "total_distance_km"}


def test_join_adds_the_member_and_counts_once() -> None:
    db = _MemoryDb()
    _seed(db)
    assert _join(db, "u2", "c1")["status"] == "joined"
    assert db.store["users/u2"]["crewId"] == "c1"
    assert db.store["crews/c1"]["memberCount"] == 2
    assert "crews/c1/members/u2" in db.store
    assert _join(db, "u2", "c1")["status"] == "already_member"
    assert db.store["crews/c1"]["memberCount"] == 2


def test_cannot_join_a_second_crew_or_a_missing_or_full_one(monkeypatch) -> None:
    db = _MemoryDb()
    _seed(db)
    with pytest.raises(HTTPException) as caught:
        _join(db, "u3", "c1")
    assert caught.value.status_code == 409
    with pytest.raises(HTTPException) as caught:
        _join(db, "u2", "nope")
    assert caught.value.status_code == 404
    monkeypatch.setenv("CREW_MAX_MEMBERS", "1")
    with pytest.raises(HTTPException) as caught:
        _join(db, "u2", "c1")
    assert caught.value.status_code == 409
    assert "crewId" not in db.store["users/u2"]


def test_leave_removes_the_member_and_the_sub_leader_seat() -> None:
    db = _MemoryDb()
    _seed(db)
    _join(db, "u2", "c1")
    db.store["crews/c1"]["subLeaderUids"] = ["u2"]
    assert _leave(db, "u2")["status"] == "left"
    assert "crews/c1/members/u2" not in db.store
    assert db.store["crews/c1"]["memberCount"] == 1
    assert db.store["crews/c1"]["subLeaderUids"] == []
    assert db.store["users/u2"]["crewId"] is firestore.DELETE_FIELD


def test_the_leader_cannot_leave_and_a_loner_has_nothing_to_leave() -> None:
    db = _MemoryDb()
    _seed(db)
    with pytest.raises(HTTPException) as caught:
        _leave(db, "u1")
    assert caught.value.status_code == 400
    with pytest.raises(HTTPException) as caught:
        _leave(db, "u2")
    assert caught.value.status_code == 404


def test_my_crew_shows_role_and_members() -> None:
    db = _MemoryDb()
    _seed(db)
    _join(db, "u2", "c1")
    mine = cm.my_crew(db, "u2")
    assert mine["role"] == "member"
    assert mine["crew"]["id"] == "c1"
    assert [(m["nickname"], m["role"]) for m in mine["members"]] == [("대장", "leader"), ("러너2", "member")]
    assert cm.my_crew(db, "nobody") == {"crew": None, "role": "none", "members": []}


def test_leader_sets_a_sub_leader_who_can_then_change_the_emblem() -> None:
    from app.services.secured_action_service import SecuredActionService

    db = _MemoryDb()
    _seed(db)
    _join(db, "u2", "c1")
    assert cm.set_role(db, "u1", "u2", "sub")["role"] == "sub"
    assert db.store["crews/c1"]["subLeaderUids"] == ["u2"]
    assert cm.my_crew(db, "u2")["role"] == "sub"
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))
    assert service.change_crew_emblem("u2", "shield:g_wolf:rays:navy:white").status == "updated"
    cm.set_role(db, "u1", "u2", "member")
    assert db.store["crews/c1"]["subLeaderUids"] == []


def test_only_the_leader_appoints_and_only_members_are_appointed() -> None:
    db = _MemoryDb()
    _seed(db)
    _join(db, "u2", "c1")
    with pytest.raises(HTTPException) as caught:
        cm.set_role(db, "u2", "u2", "sub")
    assert caught.value.status_code == 403
    with pytest.raises(HTTPException) as caught:
        cm.set_role(db, "u1", "stranger", "sub")
    assert caught.value.status_code == 404
    with pytest.raises(HTTPException):
        cm.set_role(db, "u1", "u2", "boss")


def test_a_new_member_counts_toward_the_members_border() -> None:
    from app.services import crew_emblem_perks as perks

    db = _MemoryDb()
    _seed(db)
    db.store["crews/c1"]["memberCount"] = 9
    _join(db, "u2", "c1")
    assert "members-1" in perks.earned_borders(db.store["crews/c1"])


def test_someone_already_in_a_crew_cannot_found_another() -> None:
    from app.services.secured_action_service import _commit_crew_found_tx

    db = _MemoryDb()
    _seed(db)
    db.store["users/u3"]["wallet"] = {"shareBalance": 100_000, "diamondBalance": 0}
    from app.services.secured_action_service import SecuredActionService

    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))
    with pytest.raises(HTTPException) as caught:
        _commit_crew_found_tx.to_wrap(
            _MemoryTxn(), service, "u3", "새크루", "share", "req-found-001",
            db.collection("users").document("u3"), db.collection("crews").document("new1"),
        )
    assert caught.value.status_code == 409
    assert "crews/new1" not in db.store
