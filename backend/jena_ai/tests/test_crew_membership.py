"""Joining, leaving and listing crews."""

from types import SimpleNamespace

from fastapi import HTTPException
from google.cloud import firestore
import pytest

from app.services import crew_membership as cm
from test_redeem_referral import _MemoryDb, _MemoryTxn


@pytest.fixture(autouse=True)
def _plain_transactions(monkeypatch):
    monkeypatch.setattr(cm, "_run", lambda fn, tx, *args: fn.to_wrap(tx, *args))


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
    names = [c["name"] for c in cm.list_crews(db, "")["crews"]]
    assert names == ["한강크루", "새벽러너"]  # biggest first
    only = cm.list_crews(db, " 새벽 ")["crews"]
    assert [c["id"] for c in only] == ["c1"]
    assert set(only[0]) == {"id", "name", "emblem", "member_count", "max_members", "is_full", "total_distance_km", "join_mode",
                           "name_changes", "rename_cost_dia", "rejected"}


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
    assert cm.my_crew(db, "nobody") == {"crew": None, "role": "none", "members": [], "pending_requests": 0}


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



# ---- approval crews ----------------------------------------------------------------
def _decide(db, leader, target, approve):
    return cm._decide_tx.to_wrap(
        _MemoryTxn(),
        db.collection("crews").document("c1"),
        db.collection("users").document(target),
        target,
        approve,
    )


def test_approval_crew_takes_a_request_not_a_member() -> None:
    db = _MemoryDb()
    _seed(db)
    cm.set_join_mode(db, "u1", "approval")
    assert cm.list_crews(db)["crews"][0]["join_mode"] in {"approval", "open"}
    assert _join(db, "u2", "c1")["status"] == "requested"
    assert "crews/c1/members/u2" not in db.store
    assert db.store["users/u2"]["pendingCrewId"] == "c1"
    assert _join(db, "u2", "c1")["status"] == "already_requested"
    assert cm.list_crews(db, "", "u2")["pending_crew_id"] == "c1"
    assert cm.my_crew(db, "u1")["pending_requests"] == 1
    assert [r["nickname"] for r in cm.list_requests(db, "u1")["requests"]] == ["러너2"]


def test_a_second_request_to_another_crew_is_refused() -> None:
    db = _MemoryDb()
    _seed(db)
    db.store["crews/c2"]["joinMode"] = "approval"
    cm.set_join_mode(db, "u1", "approval")
    _join(db, "u2", "c1")
    with pytest.raises(HTTPException) as caught:
        _join(db, "u2", "c2")
    assert caught.value.status_code == 409


def test_approving_makes_the_member_and_rejecting_does_not() -> None:
    db = _MemoryDb()
    _seed(db)
    cm.set_join_mode(db, "u1", "approval")
    _join(db, "u2", "c1")
    assert _decide(db, "u1", "u2", True)["status"] == "approved"
    assert db.store["users/u2"]["crewId"] == "c1"
    assert db.store["crews/c1"]["memberCount"] == 2
    assert "crews/c1/joinRequests/u2" not in db.store

    db.store["users/u4"] = {"nickname": "러너4"}
    _join(db, "u4", "c1")
    assert _decide(db, "u1", "u4", False)["status"] == "rejected"
    assert "crewId" not in db.store["users/u4"]
    assert db.store["crews/c1"]["memberCount"] == 2


def test_a_plain_member_cannot_decide_and_the_user_can_cancel() -> None:
    db = _MemoryDb()
    _seed(db)
    cm.set_join_mode(db, "u1", "approval")
    _join(db, "u2", "c1")
    with pytest.raises(HTTPException) as caught:
        cm.list_requests(db, "u2")
    assert caught.value.status_code == 403
    assert cm.cancel_request(db, "u2")["status"] == "cancelled"
    assert "crews/c1/joinRequests/u2" not in db.store
    with pytest.raises(HTTPException):
        cm.cancel_request(db, "u2")


def test_only_the_leader_changes_the_join_mode() -> None:
    db = _MemoryDb()
    _seed(db)
    _join(db, "u2", "c1")
    cm.set_role(db, "u1", "u2", "sub")
    with pytest.raises(HTTPException) as caught:
        cm.set_join_mode(db, "u2", "approval")
    assert caught.value.status_code == 403
    with pytest.raises(HTTPException):
        cm.set_join_mode(db, "u1", "closed")


# ---- kick, hand over, disband ---------------------------------------------------------
def test_leader_and_sub_leader_remove_members_with_limits() -> None:
    db = _MemoryDb()
    _seed(db)
    for uid in ("u2", "u4", "u5"):
        db.store[f"users/{uid}"] = {"nickname": uid}
        _join(db, uid, "c1")
    cm.set_role(db, "u1", "u2", "sub")
    cm.set_role(db, "u1", "u5", "sub")
    assert cm.kick(db, "u2", "u4")["status"] == "removed"  # sub removes a member
    assert "crewId" in db.store["users/u4"] and db.store["users/u4"]["crewId"] is firestore.DELETE_FIELD
    with pytest.raises(HTTPException) as caught:
        cm.kick(db, "u2", "u5")  # a sub cannot remove a sub
    assert caught.value.status_code == 403
    with pytest.raises(HTTPException):
        cm.kick(db, "u2", "u1")  # nobody removes the leader
    assert cm.kick(db, "u1", "u5")["status"] == "removed"  # the leader removes a sub
    assert db.store["crews/c1"]["subLeaderUids"] == ["u2"]
    assert db.store["crews/c1"]["memberCount"] == 2
    with pytest.raises(HTTPException) as caught:
        cm.kick(db, "u4", "u2")  # a removed person manages nothing
    assert caught.value.status_code == 403


def test_handing_the_crew_over_lets_the_old_leader_leave_like_anyone() -> None:
    db = _MemoryDb()
    _seed(db)
    _join(db, "u2", "c1")
    assert cm.transfer(db, "u1", "u2")["new_leader"] == "u2"
    assert db.store["crews/c1"]["ownerUid"] == "u2"
    assert db.store["users/u2"]["ownedCrewId"] == "c1"
    assert db.store["users/u1"]["crewId"] == "c1"
    assert cm.my_crew(db, "u1")["role"] == "sub"
    assert cm.my_crew(db, "u2")["role"] == "leader"
    with pytest.raises(HTTPException):
        cm.transfer(db, "u1", "u2")  # no longer the leader
    cm.set_role(db, "u2", "u1", "member")
    assert _leave(db, "u1")["status"] == "left"


def test_transfer_needs_a_member_target() -> None:
    db = _MemoryDb()
    _seed(db)
    with pytest.raises(HTTPException) as caught:
        cm.transfer(db, "u1", "stranger")
    assert caught.value.status_code == 404


def test_disbanding_releases_everyone_the_leader_included() -> None:
    db = _MemoryDb()
    _seed(db)
    cm.set_join_mode(db, "u1", "approval")
    db.store["users/u4"] = {"nickname": "u4"}
    db.store["crews/c1/members/u2"] = {"uid": "u2"}
    db.store["users/u2"] = {"nickname": "러너2", "crewId": "c1"}
    _join(db, "u4", "c1")  # a pending request
    result = cm.disband(db, "u1")
    assert result["status"] == "disbanded"
    assert not [p for p in db.store if p.startswith("crews/c1")]
    for uid in ("u1", "u2"):
        user = db.store[f"users/{uid}"]
        assert user.get("crewId") is firestore.DELETE_FIELD or "crewId" not in user
        assert user.get("ownedCrewId") is firestore.DELETE_FIELD or "ownedCrewId" not in user
    assert db.store["users/u4"]["pendingCrewId"] is firestore.DELETE_FIELD
    assert cm.my_crew(db, "u1")["crew"] is None


def test_only_the_leader_can_disband() -> None:
    db = _MemoryDb()
    _seed(db)
    _join(db, "u2", "c1")
    cm.set_role(db, "u1", "u2", "sub")
    with pytest.raises(HTTPException) as caught:
        cm.disband(db, "u2")
    assert caught.value.status_code == 403
    assert "crews/c1" in db.store


@pytest.mark.parametrize("name", ["", " ", "가", "가" * 21])
def test_crew_names_must_be_two_to_twenty_characters(name: str) -> None:
    from app.services.secured_action_service import SecuredActionService, _commit_crew_found_tx

    db = _MemoryDb()
    db.store["users/u9"] = {"wallet": {"shareBalance": 100_000}}
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))
    with pytest.raises(HTTPException) as caught:
        _commit_crew_found_tx.to_wrap(
            _MemoryTxn(), service, "u9", name, "share", "req-name-0001",
            db.collection("users").document("u9"), db.collection("crews").document("n1"),
        )
    assert caught.value.status_code == 400
    assert "crews/n1" not in db.store


# ---- rename and rejection ---------------------------------------------------------------
def _rename(db, uid, name, request_id="req-name-0001"):
    service = SimpleNamespace(firebase_service=SimpleNamespace(db=db))
    return cm.rename(service, uid, name, request_id)


def _seed_rich(db):
    _seed(db)
    db.store["users/u1"]["wallet"] = {"diamondBalance": 500, "freeDiamondBalance": 100, "paidDiamondBalance": 400}


def test_the_first_rename_is_free_and_the_next_costs_300_dia() -> None:
    db = _MemoryDb()
    _seed_rich(db)
    first = _rename(db, "u1", "한강 새벽러너")
    assert (first["status"], first["charged_dia"]) == ("renamed", 0)
    assert db.store["crews/c1"]["name"] == "한강 새벽러너" and db.store["crews/c1"]["nameChanges"] == 1
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 500
    assert cm.list_crews(db, "", "u1")["crews"][-1]["rename_cost_dia"] in {0, 300}

    second = _rename(db, "u1", "서울 밤 러너", "req-name-0002")
    assert (second["status"], second["charged_dia"], second["diamond_balance"]) == ("renamed", 300, 200)
    wallet = db.store["users/u1"]["wallet"]
    assert (wallet["freeDiamondBalance"], wallet["paidDiamondBalance"]) == (0, 200)  # bonus first
    assert db.store["crews/c1"]["nameChanges"] == 2
    ledger = [v for k, v in db.store.items() if k.startswith("walletTransactions/crew_rename_")]
    assert sorted(l["diamondAmount"] for l in ledger) == [-300, 0]


def test_the_same_rename_request_charges_once() -> None:
    db = _MemoryDb()
    _seed_rich(db)
    _rename(db, "u1", "첫 이름")
    _rename(db, "u1", "둘째 이름", "req-name-0002")
    again = _rename(db, "u1", "셋째 이름", "req-name-0002")
    assert again["status"] == "already_renamed"
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 200
    assert db.store["crews/c1"]["name"] == "둘째 이름"


def test_rename_needs_the_diamonds_and_a_valid_new_name() -> None:
    db = _MemoryDb()
    _seed(db)
    db.store["users/u1"]["wallet"] = {"diamondBalance": 100}
    db.store["crews/c1"]["nameChanges"] = 1
    with pytest.raises(HTTPException) as caught:
        _rename(db, "u1", "새 이름")
    assert caught.value.status_code == 400
    assert db.store["crews/c1"]["name"] == "새벽러너"
    for bad in ("", "가", "가" * 21, "새벽러너"):
        with pytest.raises(HTTPException):
            _rename(db, "u1", bad, "req-name-0009")


def test_only_the_leader_renames() -> None:
    db = _MemoryDb()
    _seed_rich(db)
    _join(db, "u2", "c1")
    cm.set_role(db, "u1", "u2", "sub")
    with pytest.raises(HTTPException) as caught:
        _rename(db, "u2", "부크루장의 이름")
    assert caught.value.status_code == 403
    assert db.store["crews/c1"]["name"] == "새벽러너"


def test_someone_turned_down_cannot_ask_again_or_join_after_a_mode_change() -> None:
    db = _MemoryDb()
    _seed(db)
    cm.set_join_mode(db, "u1", "approval")
    _join(db, "u2", "c1")
    _decide(db, "u1", "u2", False)
    assert "crews/c1/rejected/u2" in db.store
    with pytest.raises(HTTPException) as caught:
        _join(db, "u2", "c1")
    assert caught.value.status_code == 403
    cm.set_join_mode(db, "u1", "open")
    with pytest.raises(HTTPException) as caught:
        _join(db, "u2", "c1")
    assert caught.value.status_code == 403
    assert "crewId" not in db.store["users/u2"]
    row = next(c for c in cm.list_crews(db, "", "u2")["crews"] if c["id"] == "c1")
    assert row["rejected"] is True
    other = next(c for c in cm.list_crews(db, "", "u3")["crews"] if c["id"] == "c1")
    assert other["rejected"] is False


def test_other_crews_and_other_people_are_not_affected_by_a_rejection() -> None:
    db = _MemoryDb()
    _seed(db)
    db.store["users/u4"] = {"nickname": "u4"}
    cm.set_join_mode(db, "u1", "approval")
    _join(db, "u2", "c1")
    _decide(db, "u1", "u2", False)
    assert _join(db, "u2", "c2")["status"] == "joined"  # another crew
    _join(db, "u4", "c1")
    assert _decide(db, "u1", "u4", True)["status"] == "approved"  # someone else


def test_disbanding_clears_the_rejection_list_too() -> None:
    db = _MemoryDb()
    _seed(db)
    cm.set_join_mode(db, "u1", "approval")
    _join(db, "u2", "c1")
    _decide(db, "u1", "u2", False)
    cm.disband(db, "u1")
    assert not [p for p in db.store if p.startswith("crews/c1")]


# ---- expand ------------------------------------------------------------------------------
def _expand(db, uid, request_id="req-expand-01"):
    service = SimpleNamespace(firebase_service=SimpleNamespace(db=db))
    return cm.expand(service, uid, request_id)


def _rich(db, dia=10_000):
    _seed_rich(db)
    db.store["users/u1"]["wallet"] = {"diamondBalance": dia, "freeDiamondBalance": 0, "paidDiamondBalance": dia}


def test_the_base_limit_is_50_and_the_first_step_adds_50_for_300_dia() -> None:
    db = _MemoryDb()
    _rich(db, 500)
    row = lambda: next(c for c in cm.list_crews(db, "", "u1")["crews"] if c["id"] == "c1")
    assert row()["max_members"] == 50
    assert cm.my_crew(db, "u1")["crew"]["expand"] == {"add": 50, "cost_dia": 300, "state": "ok"}

    done = _expand(db, "u1")
    assert (done["status"], done["added"], done["charged_dia"], done["max_members"], done["diamond_balance"]) == ("expanded", 50, 300, 100, 200)
    assert row()["max_members"] == 100
    ledger = [v for k, v in db.store.items() if k.startswith("walletTransactions/crew_expand_")]
    assert len(ledger) == 1 and ledger[0]["diamondAmount"] == -300 and ledger[0]["addedSeats"] == 50


def test_up_to_300_seats_the_step_is_always_50_for_300_dia() -> None:
    db = _MemoryDb()
    _rich(db)
    caps = []
    for n in range(5):
        caps.append(_expand(db, "u1", f"req-expand-{n:02d}")["max_members"])
    assert caps == [100, 150, 200, 250, 300]
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 10_000 - 5 * 300


def test_past_300_the_crew_must_be_full_then_100_seats_cost_500_dia_up_to_500() -> None:
    db = _MemoryDb()
    _rich(db)
    db.store["crews/c1"]["memberCapBonus"] = 250  # 300 seats
    db.store["crews/c1"]["memberCount"] = 299
    assert cm.my_crew(db, "u1")["crew"]["expand"] == {"add": 100, "cost_dia": 500, "state": "needs_full"}
    with pytest.raises(HTTPException) as caught:
        _expand(db, "u1")
    assert caught.value.status_code == 409
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 10_000

    db.store["crews/c1"]["memberCount"] = 300
    first = _expand(db, "u1", "req-expand-10")
    assert (first["added"], first["charged_dia"], first["max_members"]) == (100, 500, 400)
    db.store["crews/c1"]["memberCount"] = 400
    second = _expand(db, "u1", "req-expand-11")
    assert (second["added"], second["charged_dia"], second["max_members"]) == (100, 500, 500)


def test_past_500_the_crew_must_be_full_then_one_step_of_500_costs_1000_and_1000_is_the_end() -> None:
    db = _MemoryDb()
    _rich(db)
    db.store["crews/c1"]["memberCapBonus"] = 450  # 500 seats
    db.store["crews/c1"]["memberCount"] = 499
    with pytest.raises(HTTPException) as caught:
        _expand(db, "u1")
    assert caught.value.status_code == 409

    db.store["crews/c1"]["memberCount"] = 500
    last = _expand(db, "u1", "req-expand-20")
    assert (last["added"], last["charged_dia"], last["max_members"]) == (500, 1000, 1000)
    assert cm.my_crew(db, "u1")["crew"]["expand"]["state"] == "max"
    db.store["crews/c1"]["memberCount"] = 1000
    with pytest.raises(HTTPException) as caught:
        _expand(db, "u1", "req-expand-21")
    assert caught.value.status_code == 409
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 10_000 - 1000


def test_the_same_expand_request_charges_once() -> None:
    db = _MemoryDb()
    _rich(db)
    _expand(db, "u1")
    again = _expand(db, "u1")
    assert again["status"] == "already_expanded"
    assert db.store["crews/c1"]["memberCapBonus"] == 50
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 9_700


def test_expand_needs_the_diamonds_and_the_leader() -> None:
    db = _MemoryDb()
    _seed(db)
    db.store["users/u1"]["wallet"] = {"diamondBalance": 299, "freeDiamondBalance": 0, "paidDiamondBalance": 299}
    with pytest.raises(HTTPException) as caught:
        _expand(db, "u1")
    assert caught.value.status_code == 400
    assert "memberCapBonus" not in db.store["crews/c1"]

    _seed_rich(db)
    _join(db, "u2", "c1")
    cm.set_role(db, "u1", "u2", "sub")
    with pytest.raises(HTTPException) as caught:
        _expand(db, "u2", "req-expand-03")
    assert caught.value.status_code == 403


# ---- gift ---------------------------------------------------------------------------------
def _gift(db, uid, target="", request_id="req-gift-0001"):
    service = SimpleNamespace(firebase_service=SimpleNamespace(db=db))
    return cm.gift(service, uid, target, request_id)


def _seed_gift(db):
    _seed_rich(db)
    db.store["users/u1"]["wallet"] = {"diamondBalance": 500, "freeDiamondBalance": 0, "paidDiamondBalance": 500}
    _join(db, "u2", "c1")


def _qty(db, uid, item):
    return db.store.get(f"users/{uid}/shopInventory/{item}", {}).get("quantity", 0)


def test_gift_to_one_member_puts_both_items_in_their_inventory_and_charges_30() -> None:
    db = _MemoryDb()
    _seed_gift(db)
    done = _gift(db, "u1", "u2")
    assert (done["status"], done["recipients"], done["charged_dia"], done["diamond_balance"]) == ("gifted", 1, 30, 470)
    assert _qty(db, "u2", "record_cpr_ticket") == 1
    assert _qty(db, "u2", "record_safe_guard") == 1
    assert _qty(db, "u1", "record_cpr_ticket") == 0
    ledger = [v for k, v in db.store.items() if k.startswith("walletTransactions/crew_gift_")]
    assert len(ledger) == 1 and ledger[0]["diamondAmount"] == -30 and ledger[0]["recipientCount"] == 1


def test_gift_to_everyone_charges_per_member_and_skips_the_leader() -> None:
    db = _MemoryDb()
    _seed_gift(db)
    db.store["users/u4"] = {"nickname": "러너4"}
    _join(db, "u4", "c1")
    done = _gift(db, "u1")
    assert (done["recipients"], done["charged_dia"], done["diamond_balance"]) == (2, 60, 440)
    for uid in ("u2", "u4"):
        assert _qty(db, uid, "record_cpr_ticket") == 1
    assert _qty(db, "u1", "record_safe_guard") == 0


def test_gift_adds_to_what_the_member_already_has_and_repeats_charge_once() -> None:
    db = _MemoryDb()
    _seed_gift(db)
    db.store["users/u2/shopInventory/record_cpr_ticket"] = {"quantity": 2}
    _gift(db, "u1", "u2")
    assert _qty(db, "u2", "record_cpr_ticket") == 3
    again = _gift(db, "u1", "u2")
    assert again["status"] == "already_gifted"
    assert _qty(db, "u2", "record_cpr_ticket") == 3
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 470


def test_gift_needs_diamonds_a_real_member_and_the_leader() -> None:
    db = _MemoryDb()
    _seed_gift(db)
    db.store["users/u1"]["wallet"] = {"diamondBalance": 29, "freeDiamondBalance": 0, "paidDiamondBalance": 29}
    with pytest.raises(HTTPException) as caught:
        _gift(db, "u1", "u2")
    assert caught.value.status_code == 400
    assert _qty(db, "u2", "record_cpr_ticket") == 0

    db.store["users/u1"]["wallet"] = {"diamondBalance": 500, "freeDiamondBalance": 0, "paidDiamondBalance": 500}
    for target in ("u3", "u1"):
        with pytest.raises(HTTPException) as caught:
            _gift(db, "u1", target, "req-gift-0002")
        assert caught.value.status_code == 404

    cm.set_role(db, "u1", "u2", "sub")
    with pytest.raises(HTTPException) as caught:
        _gift(db, "u2", "", "req-gift-0003")
    assert caught.value.status_code == 403
