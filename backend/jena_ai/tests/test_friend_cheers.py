"""Friend cheers: friend run records, fixed cheers, inbox and mute settings."""

from datetime import datetime, timedelta, timezone
from types import SimpleNamespace
from unittest.mock import patch

import pytest
from fastapi import HTTPException

from app.models.secured_actions import ValidateRunRequest
from app.models.validation_result import ValidationResult
from app.routers import secured_action_router as router
from app.services import friend_cheers as fc
from app.services import friends
from app.services.secured_action_service import SecuredActionService
from test_redeem_referral import (
    _MemoryCollection,
    _MemoryDb,
    _MemoryQuery,
    _MemoryTxn,
    _child_snapshots,
)

NOW = datetime(2026, 11, 20, 3, 0, tzinfo=timezone.utc)  # 12:00 KST
WALLET = {"shareBalance": 120, "diaBalance": 7}


class _OrderedQuery:
    def __init__(self, store, name, field, descending):
        self._args = (store, name)
        self._field = field
        self._descending = descending
        self._limit = None

    def limit(self, count):
        self._limit = count
        return self

    def get(self, transaction=None):
        snaps = _child_snapshots(*self._args)
        snaps.sort(
            key=lambda s: s.to_dict().get(self._field), reverse=self._descending
        )
        return snaps[: self._limit] if self._limit is not None else snaps


@pytest.fixture(autouse=True)
def _fake_firestore(monkeypatch) -> None:
    # The shared in-memory DB has no order_by; add the one thing these tests need.
    monkeypatch.setattr(
        _MemoryCollection,
        "order_by",
        lambda self, field, direction=None: _OrderedQuery(
            self._store, self._name, field, direction is not None
        ),
        raising=False,
    )
    monkeypatch.setattr(
        fc,
        "_send_tx",
        lambda txn, db, uid, friend, act, reaction, now: fc.send_in_txn(
            txn, db, uid, friend, act, reaction, now
        ),
    )
    # The purge job streams a query; the shared fake only has get().
    monkeypatch.setattr(_MemoryQuery, "stream", lambda self: iter(self.get()), raising=False)
    monkeypatch.setattr(
        _MemoryCollection, "stream", lambda self: iter(self.get()), raising=False
    )
    # The real helper asks Firestore for a document-id range; the fake scans keys.
    monkeypatch.setattr(
        fc,
        "_ids_with_prefix",
        lambda db, collection, prefix: [
            key.split("/", 1)[1]
            for key in db.store
            if key.startswith(f"{collection}/")
            and key.count("/") == 1
            and key.split("/", 1)[1].startswith(prefix)
        ],
    )
    monkeypatch.setattr(
        fc,
        "_settings_tx",
        lambda txn, db, uid, mute_all, friend, muted, now: fc.update_settings_in_txn(
            txn, db, uid, mute_all, friend, muted, now
        ),
    )


def _db(*uids: str) -> _MemoryDb:
    db = _MemoryDb()
    for uid in uids:
        db.store[f"users/{uid}"] = {
            "nickname": f"nick-{uid}",
            "wallet": dict(WALLET),
            "lastRoute": [[37.1, 127.1]],
        }
    return db


def _befriend(db: _MemoryDb, a: str, b: str) -> None:
    db.store[f"users/{a}/friends/{b}"] = {"createdAt": NOW}
    db.store[f"users/{b}/friends/{a}"] = {"createdAt": NOW}


def _run(db: _MemoryDb, uid: str, activity: str, days_ago: int = 0, hours: int = 0):
    at = NOW - timedelta(days=days_ago, hours=hours)
    fc.record_friend_run(db, uid, activity, 5.2, 1800, now=at)


def _send(db, uid="me", friend="f1", activity="r1", reaction="clap", now=NOW):
    return fc.send_in_txn(_MemoryTxn(), db, uid, friend, activity, reaction, now)


def _error(call) -> tuple[int, str]:
    with pytest.raises(HTTPException) as caught:
        call()
    return caught.value.status_code, caught.value.detail


def _setup() -> _MemoryDb:
    db = _db("me", "f1", "f2", "stranger")
    _befriend(db, "me", "f1")
    _befriend(db, "me", "f2")
    return db


# --- record_friend_run ---------------------------------------------------


def test_record_writes_only_the_minimum() -> None:
    db = _db("me")
    _run(db, "me", "r1")

    doc = db.store["users/me/friendRuns/r1"]
    assert set(doc) == {"distanceKm", "durationSeconds", "kstDate", "createdAt"}
    assert doc["kstDate"] == "2026-11-20"
    assert doc["distanceKm"] == 5.2
    assert doc["durationSeconds"] == 1800


def test_same_activity_twice_is_one_document() -> None:
    db = _db("me")
    _run(db, "me", "r1")
    _run(db, "me", "r1")

    assert [k for k in db.store if "/friendRuns/" in k] == ["users/me/friendRuns/r1"]


def test_unsafe_activity_id_writes_nothing() -> None:
    db = _db("me")
    fc.record_friend_run(db, "me", "a/b", 5, 100, now=NOW)
    fc.record_friend_run(db, "me", "  ", 5, 100, now=NOW)

    assert [k for k in db.store if "friendRuns" in k] == []


def _validate(monkeypatch, db, verified: bool, record=None):
    result = ValidationResult(
        verified=verified,
        decision="verified" if verified else "rejected",
        reason="",
        value_token_reward=0,
    )
    fake_service = SimpleNamespace(
        validate_run=lambda uid, request: result,
        firebase_service=SimpleNamespace(db=db),
    )
    monkeypatch.setattr(router, "service", fake_service)
    monkeypatch.setattr(router.run_times, "check_run_times", lambda *a, **k: None)
    if record is not None:
        monkeypatch.setattr(router.friend_cheers, "record_friend_run", record)
    request = ValidateRunRequest(
        activity_id="act1",
        distance_km=5.0,
        duration_seconds=1500,
        gyro_stability_score=0.9,
    )
    http = SimpleNamespace(state=SimpleNamespace())
    return result, router.validate_run(request, http, uid="me")


def test_router_records_a_verified_run(monkeypatch) -> None:
    db = _db("me")
    result, answer = _validate(monkeypatch, db, verified=True)

    assert answer is result
    assert "users/me/friendRuns/act1" in db.store


def test_router_records_nothing_for_an_unverified_run(monkeypatch) -> None:
    db = _db("me")
    result, answer = _validate(monkeypatch, db, verified=False)

    assert answer is result
    assert [k for k in db.store if "friendRuns" in k] == []


def test_record_failure_never_changes_the_validation_answer(monkeypatch) -> None:
    def boom(*args, **kwargs):
        raise RuntimeError("firestore down")

    db = _db("me")
    result, answer = _validate(monkeypatch, db, verified=True, record=boom)

    assert answer is result
    assert answer.verified is True


# --- friends/runs --------------------------------------------------------


def test_runs_show_only_friends_with_my_reaction() -> None:
    db = _setup()
    _run(db, "f1", "r1")
    _run(db, "stranger", "rs")
    _run(db, "me", "mine")
    _send(db, friend="f1", activity="r1", reaction="fire")

    runs = fc.list_friend_runs(db, "me", now=NOW).runs

    assert [(r.activity_id, r.friend_uid) for r in runs] == [("r1", "f1")]
    assert runs[0].nickname == "nick-f1"
    assert runs[0].distance_km == 5.2
    assert runs[0].duration_seconds == 1800
    assert runs[0].kst_date == "2026-11-20"
    assert runs[0].my_reaction == "fire"


def test_runs_have_no_route_or_start_time() -> None:
    db = _setup()
    _run(db, "f1", "r1")

    dumped = fc.list_friend_runs(db, "me", now=NOW).runs[0].model_dump()

    assert set(dumped) == {
        "activity_id",
        "friend_uid",
        "nickname",
        "distance_km",
        "duration_seconds",
        "kst_date",
        "my_reaction",
    }


def test_runs_without_a_cheer_have_null_reaction() -> None:
    db = _setup()
    _run(db, "f1", "r1")

    assert fc.list_friend_runs(db, "me", now=NOW).runs[0].my_reaction is None


def test_runs_older_than_seven_kst_days_are_left_out() -> None:
    db = _setup()
    _run(db, "f1", "old", days_ago=8)
    _run(db, "f1", "edge", days_ago=6)
    _run(db, "f1", "new", days_ago=1)

    ids = [r.activity_id for r in fc.list_friend_runs(db, "me", now=NOW).runs]

    assert ids == ["new", "edge"]


def test_runs_are_newest_first_and_three_per_friend() -> None:
    db = _setup()
    for index in range(5):
        _run(db, "f1", f"a{index}", hours=index)

    ids = [r.activity_id for r in fc.list_friend_runs(db, "me", now=NOW).runs]

    assert ids == ["a0", "a1", "a2"]


def test_runs_stop_at_fifty() -> None:
    db = _db("me")
    for index in range(30):
        friend = f"f{index}"
        db.store[f"users/{friend}"] = {"nickname": friend}
        _befriend(db, "me", friend)
        for run in range(3):
            _run(db, friend, f"{friend}-{run}", hours=run)

    assert len(fc.list_friend_runs(db, "me", now=NOW).runs) == 50


def test_runs_skip_blocked_and_deleted_friends() -> None:
    db = _db("me", "i-blocked", "blocked-me", "gone", "ok")
    for uid in ("i-blocked", "blocked-me", "gone", "ok"):
        _befriend(db, "me", uid)
        _run(db, uid, f"r-{uid}")
    db.store["users/me/blocks/i-blocked"] = {"createdAt": NOW}
    db.store["users/blocked-me/blocks/me"] = {"createdAt": NOW}
    db.store["users/gone"]["accountStatus"] = "deleted"

    runs = fc.list_friend_runs(db, "me", now=NOW).runs

    assert [r.friend_uid for r in runs] == ["ok"]


# --- cheers/send ---------------------------------------------------------


def test_send_writes_four_documents() -> None:
    db = _setup()
    _run(db, "f1", "r1")

    assert _send(db).status == "sent"

    assert db.store["friendCheers/r1_me"] == {
        "fromUid": "me",
        "toUid": "f1",
        "activityId": "r1",
        "reaction": "clap",
        "createdAt": NOW,
    }
    assert "friendCheerPairDays/me_f1_20261120" in db.store
    assert db.store["friendCheerDays/me_20261120"]["count"] == 1
    assert db.store["users/f1/cheersInbox/r1_me"]["reaction"] == "clap"
    assert db.store["users/f1/cheersInbox/r1_me"]["fromUid"] == "me"


def test_send_changes_no_wallet_or_ledger() -> None:
    db = _setup()
    _run(db, "f1", "r1")
    before = {k: v for k, v in db.store.items() if k.startswith("users/")}

    _send(db)

    for key, value in before.items():
        if "cheersInbox" in key:
            continue
        assert db.store[key] == value, key
    new = set(db.store) - set(before)
    assert new == {
        "friendCheers/r1_me",
        "friendCheerPairDays/me_f1_20261120",
        "friendCheerDays/me_20261120",
        "users/f1/cheersInbox/r1_me",
    }


@pytest.mark.parametrize("reaction", ["", "love", "CLAP", "hello there"])
def test_send_rejects_other_reactions(reaction) -> None:
    db = _setup()
    _run(db, "f1", "r1")

    assert _error(lambda: _send(db, reaction=reaction)) == (400, "invalid_reaction")
    assert not [k for k in db.store if "Cheer" in k or "cheer" in k]


@pytest.mark.parametrize("reaction", sorted(fc.REACTIONS))
def test_send_accepts_each_fixed_reaction(reaction) -> None:
    db = _setup()
    _run(db, "f1", "r1")

    assert _send(db, reaction=reaction).status == "sent"


def test_send_to_myself_is_self() -> None:
    db = _setup()
    _run(db, "me", "r1")

    assert _error(lambda: _send(db, friend="me")) == (400, "self")


def test_send_to_a_non_friend_is_not_found() -> None:
    db = _setup()
    _run(db, "stranger", "r1")

    assert _error(lambda: _send(db, friend="stranger")) == (404, "not_found")


def test_send_when_blocked_either_way_is_not_found() -> None:
    db = _setup()
    _run(db, "f1", "r1")
    _run(db, "f2", "r2")
    db.store["users/me/blocks/f1"] = {"createdAt": NOW}
    db.store["users/f2/blocks/me"] = {"createdAt": NOW}

    assert _error(lambda: _send(db, friend="f1", activity="r1")) == (404, "not_found")
    assert _error(lambda: _send(db, friend="f2", activity="r2")) == (404, "not_found")


def test_blocked_and_missing_run_look_the_same() -> None:
    db = _setup()
    _run(db, "f1", "r1")
    db.store["users/f1/blocks/me"] = {"createdAt": NOW}

    blocked = _error(lambda: _send(db, friend="f1", activity="r1"))
    missing = _error(lambda: _send(db, friend="f2", activity="nope"))

    assert blocked == missing == (404, "not_found")


def test_send_for_a_missing_run_is_not_found() -> None:
    db = _setup()

    assert _error(lambda: _send(db, activity="nope")) == (404, "not_found")


def test_send_for_someone_elses_run_is_not_found() -> None:
    db = _setup()
    _run(db, "f2", "r2")

    assert _error(lambda: _send(db, friend="f1", activity="r2")) == (404, "not_found")


def test_send_for_an_old_run_is_not_found() -> None:
    db = _setup()
    _run(db, "f1", "old", days_ago=8)

    assert _error(lambda: _send(db, activity="old")) == (404, "not_found")


def test_same_run_twice_is_already_cheered() -> None:
    db = _setup()
    _run(db, "f1", "r1")
    _send(db)

    assert _error(lambda: _send(db)) == (409, "already_cheered")


def test_same_friend_twice_in_a_day_is_friend_daily_limit() -> None:
    db = _setup()
    _run(db, "f1", "r1")
    _run(db, "f1", "r2", hours=1)
    _send(db, activity="r1")

    assert _error(lambda: _send(db, activity="r2")) == (429, "friend_daily_limit")


def test_the_next_kst_day_allows_the_same_friend_again() -> None:
    db = _setup()
    _run(db, "f1", "r1")
    _run(db, "f1", "r2", hours=1)
    _send(db, activity="r1")

    tomorrow = NOW + timedelta(days=1)

    assert _send(db, activity="r2", now=tomorrow).status == "sent"
    assert db.store["friendCheerDays/me_20261121"]["count"] == 1


def test_the_twenty_first_cheer_in_a_day_is_refused() -> None:
    db = _db("me")
    for index in range(21):
        friend = f"f{index}"
        db.store[f"users/{friend}"] = {"nickname": friend}
        _befriend(db, "me", friend)
        _run(db, friend, f"r{index}")
    for index in range(20):
        _send(db, friend=f"f{index}", activity=f"r{index}")

    assert _error(lambda: _send(db, friend="f20", activity="r20")) == (
        429,
        "daily_limit",
    )
    assert db.store["friendCheerDays/me_20261120"]["count"] == 20
    assert "friendCheers/r20_me" not in db.store


def test_a_muted_receiver_still_gets_sent_and_the_cheer_is_stored() -> None:
    db = _setup()
    _run(db, "f1", "r1")
    db.store["cheerSettings/f1"] = {"muteAll": True, "mutedFriends": ["me"]}

    assert _send(db).status == "sent"
    assert "users/f1/cheersInbox/r1_me" in db.store


# --- inbox ---------------------------------------------------------------


def _inbox_doc(db, to, sender, activity, at, reaction="heart"):
    db.store[f"users/{to}/cheersInbox/{activity}_{sender}"] = {
        "fromUid": sender,
        "activityId": activity,
        "reaction": reaction,
        "createdAt": at,
    }


def test_inbox_is_newest_first_with_nicknames() -> None:
    db = _setup()
    _inbox_doc(db, "me", "f1", "a", NOW - timedelta(hours=3))
    _inbox_doc(db, "me", "f2", "b", NOW - timedelta(hours=1), reaction="fire")

    inbox = fc.list_inbox(db, "me", now=NOW)

    assert [(c.from_uid, c.nickname, c.reaction) for c in inbox.cheers] == [
        ("f2", "nick-f2", "fire"),
        ("f1", "nick-f1", "heart"),
    ]
    assert inbox.cheers[0].activity_id == "b"
    assert inbox.cheers[0].created_at is not None


def test_inbox_keeps_only_the_last_thirty_days_and_fifty_rows() -> None:
    db = _setup()
    _inbox_doc(db, "me", "f1", "old", NOW - timedelta(days=31))
    _inbox_doc(db, "me", "f1", "ok", NOW - timedelta(days=29))

    assert [c.activity_id for c in fc.list_inbox(db, "me", now=NOW).cheers] == ["ok"]

    for index in range(60):
        _inbox_doc(db, "me", "f2", f"n{index}", NOW - timedelta(minutes=index))
    assert len(fc.list_inbox(db, "me", now=NOW).cheers) == 50


def test_inbox_hides_removed_blocked_and_deleted_senders() -> None:
    db = _db("me", "ok", "removed", "i-blocked", "blocked-me", "gone")
    for uid in ("ok", "i-blocked", "blocked-me", "gone"):
        _befriend(db, "me", uid)
    db.store["users/me/blocks/i-blocked"] = {"createdAt": NOW}
    db.store["users/blocked-me/blocks/me"] = {"createdAt": NOW}
    db.store["users/gone"]["accountStatus"] = "deleted"
    for uid in ("ok", "removed", "i-blocked", "blocked-me", "gone"):
        _inbox_doc(db, "me", uid, f"a-{uid}", NOW - timedelta(hours=1))

    inbox = fc.list_inbox(db, "me", now=NOW)

    assert [c.from_uid for c in inbox.cheers] == ["ok"]
    assert inbox.unread_count == 1


def test_unread_counts_after_seen_and_seen_resets_it() -> None:
    db = _setup()
    _inbox_doc(db, "me", "f1", "a", NOW - timedelta(hours=5))
    _inbox_doc(db, "me", "f2", "b", NOW - timedelta(hours=1))

    assert fc.list_inbox(db, "me", now=NOW).unread_count == 2

    assert fc.mark_seen(db, "me", now=NOW - timedelta(hours=2)).status == "ok"
    assert fc.list_inbox(db, "me", now=NOW).unread_count == 1

    fc.mark_seen(db, "me", now=NOW)
    inbox = fc.list_inbox(db, "me", now=NOW)
    assert inbox.unread_count == 0
    assert len(inbox.cheers) == 2


# --- settings ------------------------------------------------------------


def _set(db, mute_all=None, friend=None, muted=None):
    return fc.update_settings_in_txn(_MemoryTxn(), db, "me", mute_all, friend, muted, NOW)


def test_settings_default_to_off() -> None:
    db = _setup()

    settings = fc.get_settings(db, "me")

    assert settings.mute_all is False
    assert settings.muted_friends == []


def test_mute_all_turns_on_and_off() -> None:
    db = _setup()

    assert _set(db, mute_all=True).mute_all is True
    assert fc.get_settings(db, "me").mute_all is True
    assert _set(db, mute_all=False).mute_all is False
    assert fc.get_settings(db, "me").mute_all is False


def test_one_friend_can_be_muted_and_unmuted() -> None:
    db = _setup()

    assert _set(db, friend="f1", muted=True).muted_friends == ["f1"]
    assert _set(db, friend="f1", muted=True).muted_friends == ["f1"]
    assert _set(db, friend="f2", muted=True).muted_friends == ["f1", "f2"]
    assert _set(db, friend="f1", muted=False).muted_friends == ["f2"]
    assert fc.get_settings(db, "me").muted_friends == ["f2"]


def test_changing_one_thing_keeps_the_other() -> None:
    db = _setup()
    _set(db, mute_all=True)

    result = _set(db, friend="f1", muted=True)

    assert result.mute_all is True
    assert result.muted_friends == ["f1"]


def test_muting_a_non_friend_is_invalid() -> None:
    db = _setup()

    assert _error(lambda: _set(db, friend="stranger", muted=True)) == (400, "invalid")
    assert "cheerSettings/me" not in db.store


def test_an_empty_or_half_request_is_invalid() -> None:
    db = _setup()

    assert _error(lambda: _set(db)) == (400, "invalid")
    assert _error(lambda: _set(db, friend="f1")) == (400, "invalid")
    assert _error(lambda: _set(db, muted=True)) == (400, "invalid")


def test_at_most_fifty_muted_friends() -> None:
    db = _db("me")
    for index in range(51):
        friend = f"f{index}"
        db.store[f"users/{friend}"] = {"nickname": friend}
        _befriend(db, "me", friend)
    for index in range(50):
        _set(db, friend=f"f{index}", muted=True)

    assert _error(lambda: _set(db, friend="f50", muted=True)) == (400, "invalid")
    assert len(fc.get_settings(db, "me").muted_friends) == 50


# --- friends.py is unchanged in behaviour ---------------------------------


def test_friend_list_still_shows_nickname_only() -> None:
    db = _setup()
    _run(db, "f1", "r1")

    rows = friends.list_friends(db, "me").friends

    assert {tuple(sorted(r.model_dump())) for r in rows} == {
        ("created_at", "nickname", "uid")
    }


# --- delete_account ------------------------------------------------------


def test_delete_account_removes_the_new_documents_only() -> None:
    db = _setup()
    _run(db, "me", "r1")
    _run(db, "f1", "r2")
    _inbox_doc(db, "me", "f1", "r0", NOW)
    _inbox_doc(db, "f1", "me", "r2", NOW)
    db.store["cheerSettings/me"] = {"muteAll": True}
    db.store["cheerSettings/f1"] = {"muteAll": True}
    db.store["friendCheers/r2_me"] = {"fromUid": "me"}
    db.store["users/me/watchDevices/d1"] = {"name": "watch"}

    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))
    with patch(
        "app.services.secured_action_service.firebase_auth.delete_user"
    ), patch("app.services.secured_action_service.identities.forget_account"):
        result = service.delete_account("me")

    assert result.status == "deleted"
    assert "users/me/friendRuns/r1" not in db.store
    assert "users/me/cheersInbox/r0_f1" not in db.store
    assert "cheerSettings/me" not in db.store
    assert "users/me/watchDevices/d1" not in db.store
    # Other people's data and the user's own profile document stay.
    assert "users/f1/friendRuns/r2" in db.store
    assert "users/f1/cheersInbox/r2_me" in db.store
    assert "cheerSettings/f1" in db.store
    assert db.store["users/me"]["accountStatus"] == "deleted"
    # Cheers this person sent are removed with the account (see purge_friend_data).
    assert "friendCheers/r2_me" not in db.store


def test_cheer_routes_are_registered() -> None:
    paths = {
        (method, route.path)
        for route in router.router.routes
        for method in getattr(route, "methods", set())
    }

    for expected in [
        ("GET", "/actions/friends/runs"),
        ("POST", "/actions/cheers/send"),
        ("GET", "/actions/cheers/inbox"),
        ("POST", "/actions/cheers/inbox/seen"),
        ("GET", "/actions/cheers/settings"),
        ("POST", "/actions/cheers/settings"),
    ]:
        assert expected in paths


# --- purge_friend_data: everything about a deleted account ----------------


def _purge_setup() -> _MemoryDb:
    db = _db("me", "f1", "f2", "other")
    _befriend(db, "me", "f1")
    _befriend(db, "me", "f2")
    _befriend(db, "f1", "other")
    db.store["users/me/blocks/other"] = {"createdAt": NOW}
    db.store["users/other/blocks/me"] = {"createdAt": NOW}
    _run(db, "me", "r-me")
    _run(db, "f1", "r-f1")
    _run(db, "other", "r-other")
    _send(db, uid="me", friend="f1", activity="r-f1")  # me -> f1
    _send(db, uid="f1", friend="me", activity="r-me")  # f1 -> me
    _send(db, uid="f1", friend="other", activity="r-other")  # unrelated
    db.store["cheerSettings/f1"] = {"muteAll": False, "mutedFriends": ["me", "f2"]}
    db.store["friendInvites/tok-me"] = {"fromUid": "me", "usedBy": "f2"}
    db.store["friendInvites/tok-f1"] = {"fromUid": "f1", "usedBy": "me"}
    db.store["friendInvites/tok-other"] = {"fromUid": "other", "usedBy": None}
    db.store["friendInviteDays/me_20261120"] = {"count": 2}
    db.store["friendInviteDays/f1_20261120"] = {"count": 1}
    return db


def test_purge_removes_the_friend_link_on_both_sides() -> None:
    db = _purge_setup()

    fc.purge_friend_data(db, "me")

    assert "users/f1/friends/me" not in db.store
    assert "users/f2/friends/me" not in db.store
    assert not [k for k in db.store if k.startswith("users/me/friends/")]
    # Links between other people are untouched.
    assert "users/f1/friends/other" in db.store
    assert "users/other/friends/f1" in db.store


def test_purge_removes_the_deleted_person_from_other_muted_lists() -> None:
    db = _purge_setup()

    fc.purge_friend_data(db, "me")

    assert db.store["cheerSettings/f1"]["mutedFriends"] == ["f2"]
    assert "cheerSettings/me" not in db.store


def test_purge_removes_cheers_sent_and_received_and_inbox_copies() -> None:
    db = _purge_setup()
    assert "friendCheers/r-f1_me" in db.store
    assert "friendCheers/r-me_f1" in db.store

    counts = fc.purge_friend_data(db, "me")

    assert "friendCheers/r-f1_me" not in db.store
    assert "friendCheers/r-me_f1" not in db.store
    # The copy of what me sent sits in f1's inbox.
    assert "users/f1/cheersInbox/r-f1_me" not in db.store
    assert not [k for k in db.store if k.startswith("users/me/cheersInbox/")]
    assert counts["cheers"] == 2
    # Unrelated cheers stay.
    assert "friendCheers/r-other_f1" in db.store
    assert "users/other/cheersInbox/r-other_f1" in db.store


def test_purge_removes_own_blocks_friend_runs_and_settings() -> None:
    db = _purge_setup()

    fc.purge_friend_data(db, "me")

    assert "users/me/blocks/other" not in db.store
    assert "users/me/friendRuns/r-me" not in db.store
    # What other people recorded about their own side is theirs.
    assert "users/other/friendRuns/r-other" in db.store
    assert "users/other/blocks/me" in db.store


def test_purge_removes_invites_and_blanks_the_name_on_used_ones() -> None:
    db = _purge_setup()

    counts = fc.purge_friend_data(db, "me")

    assert "friendInvites/tok-me" not in db.store
    assert counts["invites"] == 1
    # An invite someone else made and me used stays used, without naming me.
    assert db.store["friendInvites/tok-f1"] == {"fromUid": "f1", "usedBy": "deleted"}
    assert db.store["friendInvites/tok-other"] == {"fromUid": "other", "usedBy": None}


def test_purge_removes_the_per_day_counters_named_after_the_person() -> None:
    db = _purge_setup()

    fc.purge_friend_data(db, "me")

    assert "friendInviteDays/me_20261120" not in db.store
    assert "friendCheerDays/me_20261120" not in db.store
    assert not [k for k in db.store if k.startswith("friendCheerPairDays/me_")]
    assert "friendInviteDays/f1_20261120" in db.store
    assert "friendCheerDays/f1_20261120" in db.store


def test_purge_twice_changes_nothing_more() -> None:
    db = _purge_setup()
    fc.purge_friend_data(db, "me")
    after = {k: dict(v) for k, v in db.store.items()}

    counts = fc.purge_friend_data(db, "me")

    assert db.store == after
    assert counts == {"friends": 0, "cheers": 0, "invites": 0, "counters": 0}


def test_purge_leaves_the_deleted_persons_wallet_and_profile_to_the_caller() -> None:
    db = _purge_setup()
    before = dict(db.store["users/me"])

    fc.purge_friend_data(db, "me")

    assert db.store["users/me"] == before
    assert not [k for k in db.store if "walletTransactions" in k]


def test_delete_account_cleans_the_other_sides_too() -> None:
    db = _purge_setup()
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))

    with patch(
        "app.services.secured_action_service.firebase_auth.delete_user"
    ), patch("app.services.secured_action_service.identities.forget_account"):
        service.delete_account("me")

    assert "users/f1/friends/me" not in db.store
    assert "friendCheers/r-f1_me" not in db.store
    assert "friendInvites/tok-me" not in db.store
    assert db.store["users/me"]["accountStatus"] == "deleted"
    # Friends who stayed still see each other.
    assert "users/f1/friends/other" in db.store


def test_the_daily_purge_runs_the_same_cleanup() -> None:
    from app.services.ops_service import OpsService

    db = _purge_setup()
    db.store["users/me"]["accountStatus"] = "deleted"
    service = OpsService(firebase_service=SimpleNamespace(db=db))

    with patch("app.services.ops_service.send_tournament_topic_notification"):
        result = service.purge_user_data("me")

    assert result.status == "purged"
    assert "users/f1/friends/me" not in db.store
    assert "friendCheers/r-f1_me" not in db.store
    assert "friendInvites/tok-me" not in db.store


def test_a_failed_friend_cleanup_does_not_stop_the_account_deletion() -> None:
    db = _purge_setup()
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))

    with patch(
        "app.services.secured_action_service.firebase_auth.delete_user"
    ) as delete_user, patch(
        "app.services.secured_action_service.identities.forget_account"
    ) as forget, patch(
        "app.services.secured_action_service.friend_cheers.purge_friend_data",
        side_effect=RuntimeError("firestore down"),
    ):
        result = service.delete_account("me")

    assert result.status == "deleted"
    delete_user.assert_called_once_with("me")
    forget.assert_called_once()
    assert db.store["users/me"]["accountStatus"] == "deleted"
