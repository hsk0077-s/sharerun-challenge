"""Friend connections: one-time invite tokens, accept, list, remove, block."""

import re
from datetime import datetime, timedelta, timezone

import pytest
from fastapi import HTTPException

from app.services import friends
from test_redeem_referral import _MemoryDb, _MemoryTxn

NOW = datetime(2026, 11, 20, 3, 0, tzinfo=timezone.utc)  # 12:00 KST
WALLET = {"shareBalance": 120, "diaBalance": 7}


def _db(*uids: str) -> _MemoryDb:
    db = _MemoryDb()
    for uid in uids:
        db.store[f"users/{uid}"] = {
            "nickname": f"nick-{uid}",
            "gender": "female",
            "wallet": dict(WALLET),
            # These must never reach the friend list.
            "lastRoute": [[37.1, 127.1]],
            "lastRunStartedAt": "2026-11-20T01:00:00",
        }
    return db


def _invite(db: _MemoryDb, uid: str = "a", now: datetime = NOW):
    return friends.invite_in_txn(_MemoryTxn(), db, uid, now)


def _accept(db: _MemoryDb, uid: str, token: str, now: datetime = NOW):
    return friends.accept_in_txn(_MemoryTxn(), db, uid, token, now)


def _error(call) -> tuple[int, str]:
    with pytest.raises(HTTPException) as caught:
        call()
    return caught.value.status_code, caught.value.detail


def _friend_docs(db: _MemoryDb) -> set[str]:
    return {key for key in db.store if "/friends/" in key}


@pytest.fixture(autouse=True)
def _in_memory_transactions(monkeypatch) -> None:
    # The real wrappers need a Firestore transaction; here the same logic runs
    # on the in-memory one.
    monkeypatch.setattr(
        friends,
        "_block_tx",
        lambda txn, db, uid, target, now: friends.block_in_txn(txn, db, uid, target, now),
    )
    monkeypatch.setattr(
        friends,
        "_remove_tx",
        lambda txn, db, uid, target: friends.remove_in_txn(txn, db, uid, target),
    )


# --- invite -------------------------------------------------------------


def test_invite_token_is_long_random_and_url_safe() -> None:
    db = _db("a")

    first = _invite(db)
    second = _invite(db)

    assert re.fullmatch(r"[A-Za-z0-9_-]{32}", first.token)  # 192 bits
    assert first.token != second.token
    assert first.qr_payload == f"sharerun-friend:{first.token}"


def test_invite_lives_24_hours_and_is_unused() -> None:
    db = _db("a")

    result = _invite(db)

    saved = db.store[f"friendInvites/{result.token}"]
    assert saved["fromUid"] == "a"
    assert saved["expiresAt"] == NOW + timedelta(hours=24)
    assert saved["usedBy"] is None and saved["usedAt"] is None
    assert result.expires_at == (NOW + timedelta(hours=24)).isoformat()


def test_the_21st_invite_in_a_kst_day_is_refused_then_allowed_next_day() -> None:
    db = _db("a")
    for _ in range(20):
        _invite(db)

    assert _error(lambda: _invite(db)) == (429, "Friend invite limit reached.")
    assert db.store["friendInviteDays/a_20261120"]["count"] == 20

    # 15:00 UTC on the 20th is 00:00 KST on the 21st.
    next_day = datetime(2026, 11, 20, 15, 0, tzinfo=timezone.utc)
    assert _invite(db, now=next_day).token
    assert db.store["friendInviteDays/a_20261121"]["count"] == 1


# --- accept -------------------------------------------------------------


def test_accept_writes_both_friend_docs_and_marks_the_token_used() -> None:
    db = _db("a", "b")
    token = _invite(db).token

    result = _accept(db, "b", token)

    assert (result.status, result.friend_uid) == ("added", "a")
    assert "users/b/friends/a" in db.store and "users/a/friends/b" in db.store
    used = db.store[f"friendInvites/{token}"]
    assert used["usedBy"] == "b" and used["usedAt"] == NOW


@pytest.mark.parametrize("token", ["", "short", "has/slash" + "x" * 30, "!" * 32])
def test_a_badly_formed_token_is_invalid(token: str) -> None:
    db = _db("a", "b")

    assert _error(lambda: _accept(db, "b", token)) == (400, "invalid")


def test_an_unknown_token_is_invalid() -> None:
    db = _db("a", "b")

    assert _error(lambda: _accept(db, "b", "x" * 32)) == (400, "invalid")


def test_an_expired_token_is_refused() -> None:
    db = _db("a", "b")
    token = _invite(db).token

    later = NOW + timedelta(hours=24, seconds=1)
    assert _error(lambda: _accept(db, "b", token, later)) == (410, "expired")
    assert not _friend_docs(db)


def test_another_person_cannot_reuse_a_used_token() -> None:
    db = _db("a", "b", "c")
    token = _invite(db).token
    _accept(db, "b", token)

    assert _error(lambda: _accept(db, "c", token)) == (410, "used")
    assert "users/c/friends/a" not in db.store


def test_the_same_person_accepting_again_gets_the_same_answer_and_writes_nothing() -> None:
    db = _db("a", "b")
    token = _invite(db).token
    first = _accept(db, "b", token)
    before = {key: dict(value) for key, value in db.store.items()}

    again = _accept(db, "b", token, NOW + timedelta(hours=1))

    assert again == first
    assert db.store == before


def test_your_own_token_is_refused() -> None:
    db = _db("a")
    token = _invite(db).token

    assert _error(lambda: _accept(db, "a", token)) == (400, "self")


def test_already_friends_answers_ok_and_marks_the_token_used() -> None:
    db = _db("a", "b")
    _accept(db, "b", _invite(db).token)
    friend_doc = dict(db.store["users/a/friends/b"])
    second = _invite(db).token

    result = _accept(db, "b", second, NOW + timedelta(minutes=5))

    assert (result.status, result.friend_uid) == ("already_friends", "a")
    assert db.store[f"friendInvites/{second}"]["usedBy"] == "b"
    assert db.store["users/a/friends/b"] == friend_doc


def _fill_friends(db: _MemoryDb, uid: str, count: int) -> None:
    for number in range(count):
        db.store[f"users/{uid}/friends/f{number}"] = {"createdAt": NOW}


def test_the_accepting_person_cannot_pass_50_friends() -> None:
    db = _db("a", "b")
    _fill_friends(db, "b", friends.MAX_FRIENDS)
    token = _invite(db).token

    assert _error(lambda: _accept(db, "b", token)) == (409, "friend_limit")
    assert "users/a/friends/b" not in db.store
    assert db.store[f"friendInvites/{token}"]["usedBy"] is None


def test_the_inviting_person_cannot_pass_50_friends() -> None:
    db = _db("a", "b")
    _fill_friends(db, "a", friends.MAX_FRIENDS)
    token = _invite(db).token

    assert _error(lambda: _accept(db, "b", token)) == (409, "friend_limit")
    assert "users/b/friends/a" not in db.store


def test_49_friends_still_has_room_for_one_more() -> None:
    db = _db("a", "b")
    _fill_friends(db, "b", friends.MAX_FRIENDS - 1)

    assert _accept(db, "b", _invite(db).token).status == "added"


def test_a_block_by_the_accepting_person_looks_like_a_missing_token() -> None:
    db = _db("a", "b")
    token = _invite(db).token
    friends.block(db, "b", "a", now=NOW)

    assert _error(lambda: _accept(db, "b", token)) == (400, "invalid")
    assert _error(lambda: _accept(db, "b", "x" * 32)) == (400, "invalid")


def test_a_block_by_the_inviting_person_looks_like_a_missing_token() -> None:
    db = _db("a", "b")
    token = _invite(db).token
    friends.block(db, "a", "b", now=NOW)

    assert _error(lambda: _accept(db, "b", token)) == (400, "invalid")
    assert not _friend_docs(db)


def test_accepting_gives_no_reward_and_leaves_the_wallet_alone() -> None:
    db = _db("a", "b")
    before = {uid: dict(db.store[f"users/{uid}"]) for uid in ("a", "b")}

    _accept(db, "b", _invite(db).token)

    for uid in ("a", "b"):
        assert db.store[f"users/{uid}"] == before[uid]
        assert db.store[f"users/{uid}"]["wallet"] == WALLET
    touched = {key.split("/")[0] for key in db.store}
    assert touched <= {"users", "friendInvites", "friendInviteDays"}


# --- list ---------------------------------------------------------------


def test_the_list_has_only_uid_nickname_and_date() -> None:
    db = _db("a", "b", "c")
    _accept(db, "b", _invite(db, "a").token)
    _accept(db, "c", _invite(db, "a").token, NOW + timedelta(minutes=1))

    listed = friends.list_friends(db, "a")

    assert [row.uid for row in listed.friends] == ["b", "c"]
    assert [row.nickname for row in listed.friends] == ["nick-b", "nick-c"]
    dumped = listed.model_dump()
    for row in dumped["friends"]:
        assert set(row) == {"uid", "nickname", "created_at"}
    text = str(dumped)
    for forbidden in ("lastRoute", "lastRunStartedAt", "37.1", "gender", "wallet"):
        assert forbidden not in text


def test_a_friend_without_a_nickname_shows_an_empty_string() -> None:
    db = _db("a")
    db.store["users/a/friends/ghost"] = {"createdAt": NOW}

    assert friends.list_friends(db, "a").friends[0].nickname == ""


def test_the_list_of_someone_with_no_friends_is_empty() -> None:
    assert friends.list_friends(_db("a"), "a").friends == []


# --- remove -------------------------------------------------------------


def test_remove_deletes_both_sides_and_tells_no_one() -> None:
    db = _db("a", "b")
    _accept(db, "b", _invite(db).token)

    assert friends.remove(db, "a", "b").status == "removed"
    assert not _friend_docs(db)
    assert not [key for key in db.store if "notif" in key.lower()]


def test_remove_of_a_non_friend_is_not_an_error() -> None:
    db = _db("a", "b")

    assert friends.remove(db, "a", "b").status == "not_friends"


def test_remove_works_from_either_side() -> None:
    db = _db("a", "b")
    _accept(db, "b", _invite(db).token)

    assert friends.remove(db, "b", "a").status == "removed"
    assert not _friend_docs(db)


# --- block --------------------------------------------------------------


def test_block_deletes_both_friend_docs_and_saves_the_block() -> None:
    db = _db("a", "b")
    _accept(db, "b", _invite(db).token)

    result = friends.block(db, "a", "b", now=NOW)

    assert result.status == "blocked"
    assert not _friend_docs(db)
    assert db.store["users/a/blocks/b"] == {"createdAt": NOW}
    assert "users/b/blocks/a" not in db.store


def test_block_twice_gives_the_same_result_and_keeps_the_first_date() -> None:
    db = _db("a", "b")
    friends.block(db, "a", "b", now=NOW)

    again = friends.block(db, "a", "b", now=NOW + timedelta(days=1))

    assert again.status == "blocked"
    assert db.store["users/a/blocks/b"]["createdAt"] == NOW


def test_blocking_yourself_is_refused() -> None:
    db = _db("a")

    assert _error(lambda: friends.block(db, "a", "a")) == (400, "self")
    assert "users/a/blocks/a" not in db.store


def test_block_with_a_reason_adds_one_report() -> None:
    db = _db("a", "b")

    friends.block(db, "a", "b", report_reason="spam", now=NOW)

    reports = {k: v for k, v in db.store.items() if k.startswith("reports/")}
    assert list(reports) == ["reports/a_user_b"]
    assert reports["reports/a_user_b"]["reason"] == "spam"
    assert reports["reports/a_user_b"]["targetId"] == "b"


def test_block_goes_on_when_the_person_was_already_reported() -> None:
    db = _db("a", "b")
    friends.block(db, "a", "b", report_reason="spam", now=NOW)
    db.store.pop("users/a/blocks/b")

    result = friends.block(db, "a", "b", report_reason="hate", now=NOW)

    assert result.status == "blocked"
    assert "users/a/blocks/b" in db.store
    assert db.store["reports/a_user_b"]["reason"] == "spam"


def test_a_bad_report_reason_refuses_before_anything_is_written() -> None:
    db = _db("a", "b")
    _accept(db, "b", _invite(db).token)

    assert _error(lambda: friends.block(db, "a", "b", report_reason="nope")) == (
        400,
        "invalid_report_reason",
    )
    assert "users/a/blocks/b" not in db.store
    assert "users/a/friends/b" in db.store


def test_block_without_a_reason_files_no_report() -> None:
    db = _db("a", "b")

    friends.block(db, "a", "b", now=NOW)

    assert not [k for k in db.store if k.startswith("reports/")]


# --- routes -------------------------------------------------------------


def test_the_five_friend_routes_are_registered() -> None:
    from app.main import app

    schema = app.openapi()["paths"]
    paths = {
        (method.upper(), path) for path, item in schema.items() for method in item
    }
    assert ("POST", "/actions/friends/invite") in paths
    assert ("POST", "/actions/friends/accept") in paths
    assert ("GET", "/actions/friends/list") in paths
    assert ("POST", "/actions/friends/remove") in paths
    assert ("POST", "/actions/friends/block") in paths


def test_the_friend_routes_need_a_signed_in_user() -> None:
    from fastapi.testclient import TestClient

    from app.main import app

    client = TestClient(app)
    assert client.post("/actions/friends/invite").status_code == 401
    assert client.get("/actions/friends/list").status_code == 401
