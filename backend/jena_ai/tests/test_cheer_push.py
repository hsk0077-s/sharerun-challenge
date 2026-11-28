"""Once-a-day bundled friend cheer push."""

from datetime import datetime, timedelta, timezone
from types import SimpleNamespace

import pytest
from fastapi.testclient import TestClient
from google.cloud import firestore

from app.main import app
from app.routers import ops_router
from app.services import cheer_push as cp
from app.services import friend_cheers as fc
from app.services.ops_service import OpsService
from test_redeem_referral import _MemoryDb

NOON = datetime(2026, 11, 20, 3, 0, tzinfo=timezone.utc)  # 12:00 KST
EVENING = datetime(2026, 11, 20, 10, 30, tzinfo=timezone.utc)  # 19:30 KST


class _Invalid(Exception):
    pass


@pytest.fixture(autouse=True)
def _fake_firestore(monkeypatch) -> None:
    # The shared fake has no range query and no create(); stand in for both.
    def receivers(db, since):
        return {
            str(data.get("toUid"))
            for key, data in db.store.items()
            if key.startswith("friendCheers/") and data["createdAt"] >= since
        }

    def claim(db, uid, ymd, data):
        key = f"{cp.PUSH_DAYS}/{uid}_{ymd}"
        if key in db.store:
            return False
        db.store[key] = dict(data)
        return True

    monkeypatch.setattr(cp, "recent_receivers", receivers)
    monkeypatch.setattr(cp, "claim_day", claim)
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


def _db(*uids: str) -> _MemoryDb:
    db = _MemoryDb()
    for uid in uids:
        db.store[f"users/{uid}"] = {"nickname": f"nick-{uid}"}
        db.store[f"users/{uid}/loginDevices/dev-{uid}"] = {"fcmToken": f"tok-{uid}"}
    return db


def _befriend(db, a: str, b: str) -> None:
    db.store[f"users/{a}/friends/{b}"] = {"createdAt": NOON}
    db.store[f"users/{b}/friends/{a}"] = {"createdAt": NOON}


def _cheer(db, sender: str, to: str, activity: str, at: datetime) -> None:
    db.store[f"friendCheers/{activity}_{sender}"] = {
        "fromUid": sender,
        "toUid": to,
        "activityId": activity,
        "reaction": "clap",
        "createdAt": at,
    }
    db.store[f"users/{to}/cheersInbox/{activity}_{sender}"] = {
        "fromUid": sender,
        "activityId": activity,
        "reaction": "clap",
        "createdAt": at,
    }


def _setup() -> _MemoryDb:
    db = _db("me", "f1", "f2", "f3")
    for friend in ("f1", "f2", "f3"):
        _befriend(db, "me", friend)
    at = EVENING - timedelta(hours=3)
    _cheer(db, "f1", "me", "r1", at)
    _cheer(db, "f1", "me", "r2", at)  # same friend twice counts once
    _cheer(db, "f2", "me", "r1", at)
    _cheer(db, "f3", "me", "r1", at)
    return db


def _run(db, now=EVENING, fail=None):
    sent: list[tuple[str, str, str, dict]] = []

    def send(token, title, body, data):
        if fail and token in fail:
            raise _Invalid(token)
        sent.append((token, title, body, data))

    result = cp.send_daily_cheer_pushes(
        db, send, lambda error: isinstance(error, _Invalid), now=now
    )
    return result, sent


# --- who gets a push, and the count -------------------------------------


def test_one_push_counts_distinct_friends_and_names_nobody() -> None:
    db = _setup()
    result, sent = _run(db)

    assert result["sent"] == 1
    assert len(sent) == 1
    token, title, body, data = sent[0]
    assert token == "tok-me"
    assert title == "응원이 도착했어요"
    assert body == "친구 3명이 응원을 보냈어요"
    assert data == {"type": "friend_cheers", "route": "/friends/cheers"}
    for nick in ("nick-f1", "nick-f2", "nick-f3"):
        assert nick not in title + body
    assert db.store["cheerPushDays/me_20261120"]["friendCount"] == 3
    assert db.store["cheerSettings/me"]["pushedAt"] == EVENING


def test_seen_cheers_are_not_counted() -> None:
    db = _setup()
    db.store["cheerSettings/me"] = {"seenAt": EVENING - timedelta(hours=1)}
    result, sent = _run(db)
    assert sent == []
    assert result["sent"] == 0


def test_cheers_already_announced_are_not_announced_again() -> None:
    db = _setup()
    _run(db)
    # Next day, nothing new arrived.
    result, sent = _run(db, now=EVENING + timedelta(days=1))
    assert sent == []
    # A new cheer the next day is announced, counting only the new one.
    _cheer(db, "f2", "me", "r9", EVENING + timedelta(days=1, hours=-1))
    result, sent = _run(db, now=EVENING + timedelta(days=1))
    assert [s[2] for s in sent] == ["친구 1명이 응원을 보냈어요"]


def test_language_follows_the_profile_and_falls_back_to_korean() -> None:
    db = _setup()
    db.store["users/me"]["language"] = "ja"
    _, sent = _run(db)
    assert sent[0][1:3] == ("応援が届きました", "友だち3人が応援してくれました")

    assert cp.copy_for("zh", 2) == ("收到加油了", "有 2 位朋友為你加油")
    assert cp.copy_for("pt", 1) == ("Você recebeu torcida", "1 amigo torceu por você")
    assert cp.copy_for(None, 2)[0] == "응원이 도착했어요"
    assert cp.copy_for("xx", 2)[1] == "친구 2명이 응원을 보냈어요"


def test_every_shipped_language_has_text() -> None:
    for code in ("ko", "en", "ja", "zh-TW", "es", "pt-BR", "de", "fr", "vi", "th", "id"):
        title, body = cp.copy_for(code, 3)
        assert title and "3" in body, code


# --- once a day, quiet hours ---------------------------------------------


def test_second_call_the_same_day_sends_nothing() -> None:
    db = _setup()
    _run(db)
    _cheer(db, "f2", "me", "r8", EVENING + timedelta(minutes=5))
    result, sent = _run(db, now=EVENING + timedelta(minutes=10))
    assert sent == []
    assert result["sent"] == 0


@pytest.mark.parametrize(
    "kst_hour, quiet",
    [(7, True), (8, False), (12, False), (20, False), (21, True), (23, True), (0, True)],
)
def test_quiet_hours_send_nothing(kst_hour: int, quiet: bool) -> None:
    db = _setup()
    now = datetime(2026, 11, 20, kst_hour, 0, tzinfo=timezone.utc) - timedelta(hours=9)
    # Cheers just before "now" so they are new at any hour.
    for key, data in list(db.store.items()):
        if "createdAt" in data and ("cheersInbox" in key or key.startswith("friendCheers/")):
            data["createdAt"] = now - timedelta(minutes=30)
    result, sent = _run(db, now=now)
    assert result["quiet_hours"] is quiet
    assert (len(sent) == 0) is quiet
    if quiet:
        assert result["sent"] == 0
        assert not any(k.startswith("cheerPushDays/") for k in db.store)


# --- mute and blocks -------------------------------------------------------


def test_mute_all_sends_nothing() -> None:
    db = _setup()
    db.store["cheerSettings/me"] = {"muteAll": True}
    result, sent = _run(db)
    assert sent == []
    assert result["skipped"] == 1


def test_muted_friends_are_left_out_of_the_count() -> None:
    db = _setup()
    db.store["cheerSettings/me"] = {"mutedFriends": ["f1", "f2"]}
    _, sent = _run(db)
    assert sent[0][2] == "친구 1명이 응원을 보냈어요"

    db = _setup()
    db.store["cheerSettings/me"] = {"mutedFriends": ["f1", "f2", "f3"]}
    _, sent = _run(db)
    assert sent == []


def test_blocks_either_way_are_left_out() -> None:
    db = _setup()
    db.store["users/me/blocks/f1"] = {"createdAt": NOON}
    db.store["users/f2/blocks/me"] = {"createdAt": NOON}
    _, sent = _run(db)
    assert sent[0][2] == "친구 1명이 응원을 보냈어요"


def test_a_cheer_from_someone_who_is_not_a_friend_is_not_counted() -> None:
    db = _setup()
    db.store["users/stranger"] = {"nickname": "x"}
    _cheer(db, "stranger", "me", "r1", EVENING - timedelta(hours=1))
    _, sent = _run(db)
    assert sent[0][2] == "친구 3명이 응원을 보냈어요"


# --- tokens ------------------------------------------------------------------


def test_an_invalid_token_is_removed_and_others_still_get_theirs() -> None:
    db = _setup()
    db.store["users/me/loginDevices/dev-old"] = {"fcmToken": "tok-old"}
    db.store["users/f1/cheersInbox/rx_f2"] = {
        "fromUid": "f2",
        "activityId": "rx",
        "reaction": "fire",
        "createdAt": EVENING - timedelta(hours=1),
    }
    db.store["friendCheers/rx_f2"] = {
        "fromUid": "f2",
        "toUid": "f1",
        "activityId": "rx",
        "createdAt": EVENING - timedelta(hours=1),
    }
    _befriend(db, "f1", "f2")
    result, sent = _run(db, fail={"tok-old"})

    assert sorted(s[0] for s in sent) == ["tok-f1", "tok-me"]
    assert result["tokens_removed"] == 1
    assert db.store["users/me/loginDevices/dev-old"]["fcmToken"] is firestore.DELETE_FIELD
    assert result["sent"] == 2


def test_one_person_failing_does_not_stop_the_others(monkeypatch) -> None:
    db = _setup()
    _cheer(db, "me", "f1", "rz", EVENING - timedelta(hours=1))
    original = cp.unseen_friend_count

    def flaky(db_, uid, current):
        if uid == "f1":
            raise RuntimeError("boom")
        return original(db_, uid, current)

    monkeypatch.setattr(cp, "unseen_friend_count", flaky)
    result, sent = _run(db)
    assert result["failed"] == 1
    assert [s[0] for s in sent] == ["tok-me"]


def test_no_token_means_no_record_so_a_later_device_can_still_get_it() -> None:
    db = _setup()
    del db.store["users/me/loginDevices/dev-me"]
    result, sent = _run(db)
    assert sent == []
    assert "cheerPushDays/me_20261120" not in db.store


# --- account deletion --------------------------------------------------------


def test_account_deletion_removes_push_records() -> None:
    db = _setup()
    _run(db)
    db.store["cheerPushDays/me_20261119"] = {"uid": "me"}
    db.store["cheerPushDays/meow_20261120"] = {"uid": "meow"}
    fc.purge_friend_data(db, "me")
    assert not any(k.startswith("cheerPushDays/me_") for k in db.store)
    assert "cheerPushDays/meow_20261120" in db.store


# --- endpoint ----------------------------------------------------------------


def test_endpoint_needs_the_ops_secret(monkeypatch) -> None:
    monkeypatch.setenv("OPS_ADMIN_SECRET", "ops-secret")
    db = _setup()
    calls: list[str] = []
    monkeypatch.setattr(
        "app.services.notification_service.send_data_push",
        lambda token, title, body, data: calls.append(token),
    )
    original = ops_router.service
    ops_router.service = OpsService(firebase_service=SimpleNamespace(db=db))
    try:
        client = TestClient(app)
        missing = client.post("/ops/friend-cheers/daily-push")
        wrong = client.post(
            "/ops/friend-cheers/daily-push", headers={"x-ops-admin-secret": "nope"}
        )
        allowed = client.post(
            "/ops/friend-cheers/daily-push",
            headers={"x-ops-admin-secret": "ops-secret"},
        )
    finally:
        ops_router.service = original

    # Same guard as every other /ops route: no or wrong secret is refused.
    assert missing.status_code == 401
    assert wrong.status_code == 401
    assert allowed.status_code == 200
    assert set(allowed.json()) == {
        "quiet_hours",
        "candidates",
        "sent",
        "skipped",
        "failed",
        "tokens_removed",
    }


def test_invalid_token_check_matches_firebase_errors() -> None:
    from firebase_admin import messaging

    from app.services.notification_service import is_invalid_token_error

    assert is_invalid_token_error(messaging.UnregisteredError("gone"))
    assert is_invalid_token_error(messaging.SenderIdMismatchError("other app"))
    assert not is_invalid_token_error(RuntimeError("network"))
