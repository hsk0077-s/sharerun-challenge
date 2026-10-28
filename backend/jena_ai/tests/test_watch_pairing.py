from datetime import datetime, timedelta, timezone

import pytest
from fastapi import HTTPException

from app.models.secured_actions import RunDeviceInfo, ValidateRunRequest
from app.services import watch_pairing
from app.services.secured_action_service import SecuredActionService
from test_identities import _FbAuth
from test_redeem_referral import _MemoryDb

NOW = datetime(2026, 10, 24, 12, 0, tzinfo=timezone.utc)


@pytest.fixture(autouse=True)
def _plain_transactions(monkeypatch):
    # The in-memory db has no real transaction; run the wrapped body directly.
    monkeypatch.setattr(
        watch_pairing,
        "_run",
        lambda tx_func, transaction, *args: tx_func.to_wrap(transaction, *args),
    )


def _db_with_user(uid="u1", nickname="달림이"):
    db = _MemoryDb()
    fb = _FbAuth()
    fb.add(uid)
    db.store[f"users/{uid}"] = {"nickname": nickname}
    return db, fb


def test_issue_code_is_six_digits_and_lasts_five_minutes() -> None:
    db, _ = _db_with_user()
    out = watch_pairing.issue_code(db, "u1", now=NOW)
    assert len(out["code"]) == 6 and out["code"].isdigit()
    assert out["expires_in"] == 300
    row = db.store[f"watchPairingCodes/{out['code']}"]
    assert row["uid"] == "u1" and row["used"] is False
    assert row["expiresAt"] == NOW + timedelta(seconds=300)


def test_a_live_code_is_not_handed_out_twice(monkeypatch) -> None:
    db, _ = _db_with_user()
    first = watch_pairing.issue_code(db, "u1", now=NOW)["code"]
    codes = iter([first, "123456"])
    monkeypatch.setattr(watch_pairing, "_new_code", lambda: next(codes))
    second = watch_pairing.issue_code(db, "u2", now=NOW)["code"]
    assert second == "123456"
    assert db.store[f"watchPairingCodes/{first}"]["uid"] == "u1"


def test_an_expired_code_can_be_reused_for_a_new_person(monkeypatch) -> None:
    db, _ = _db_with_user()
    first = watch_pairing.issue_code(db, "u1", now=NOW)["code"]
    monkeypatch.setattr(watch_pairing, "_new_code", lambda: first)
    later = NOW + timedelta(seconds=301)
    assert watch_pairing.issue_code(db, "u2", now=later)["code"] == first
    assert db.store[f"watchPairingCodes/{first}"]["uid"] == "u2"


def test_pair_returns_the_account_and_burns_the_code() -> None:
    db, fb = _db_with_user()
    code = watch_pairing.issue_code(db, "u1", now=NOW)["code"]
    out = watch_pairing.pair(db, code, fb_auth=fb, now=NOW + timedelta(seconds=30))
    assert out["uid"] == "u1" and out["nickname"] == "달림이"
    assert out["custom_token"] == "custom-for-u1"
    assert out["device_id"]  # the server names a watch that did not bring an id
    assert db.store[f"watchPairingCodes/{code}"]["used"] is True

    with pytest.raises(HTTPException) as again:
        watch_pairing.pair(db, code, fb_auth=fb, now=NOW + timedelta(seconds=31))
    assert again.value.status_code == 400
    assert again.value.detail == "invalid_code"


def test_pair_refuses_expired_unknown_and_malformed_codes() -> None:
    db, fb = _db_with_user()
    code = watch_pairing.issue_code(db, "u1", now=NOW)["code"]
    for bad, when in (
        (code, NOW + timedelta(seconds=300)),
        ("000000" if code != "000000" else "000001", NOW),
        ("12345", NOW),
        ("abcdef", NOW),
    ):
        with pytest.raises(HTTPException) as caught:
            watch_pairing.pair(db, bad, fb_auth=fb, now=when)
        assert caught.value.detail == "invalid_code"
    assert db.store[f"watchPairingCodes/{code}"]["used"] is False


def test_pair_refuses_a_deleted_account() -> None:
    db, fb = _db_with_user()
    code = watch_pairing.issue_code(db, "u1", now=NOW)["code"]
    db.store["users/u1"]["accountStatus"] = "deleted"
    with pytest.raises(HTTPException) as caught:
        watch_pairing.pair(db, code, fb_auth=fb, now=NOW)
    assert caught.value.detail == "invalid_code"


def test_routes_are_wired() -> None:
    from fastapi.testclient import TestClient

    from app.main import app

    client = TestClient(app)
    assert client.post("/actions/watch-pairing/code").status_code == 401
    assert client.post("/auth/watch-pair", json={"code": "12"}).status_code == 422
    assert client.post("/auth/watch-pair", json={"code": "abcdef"}).status_code == 422


def _run_request(**overrides) -> ValidateRunRequest:
    data = {
        "activity_id": "a1",
        "distance_km": 5.0,
        "duration_seconds": 1800,
        "gyro_stability_score": 0.5,
        "total_steps": 5400,
        "device_info": RunDeviceInfo(watch_used=True),
    }
    data.update(overrides)
    return ValidateRunRequest(**data)


def test_watch_run_derives_cadence_from_total_steps() -> None:
    # 5400 steps over 30 minutes is 180 steps per minute.
    assert SecuredActionService._cadence_series(_run_request()) == [180]


def test_cadence_is_left_alone_when_the_phone_sent_one_or_no_watch_was_used() -> None:
    sent = _run_request(cadence_spm=[150, 160])
    assert SecuredActionService._cadence_series(sent) == [150, 160]
    phone = _run_request(device_info=RunDeviceInfo(watch_used=False))
    assert SecuredActionService._cadence_series(phone) == []
    assert SecuredActionService._cadence_series(_run_request(device_info=None)) == []
    assert SecuredActionService._cadence_series(_run_request(total_steps=None)) == []


class _RecordingAuth(_FbAuth):
    def create_custom_token(self, uid, claims=None):
        self.claims = claims
        return super().create_custom_token(uid, claims)


def test_the_watch_token_carries_the_account_generation() -> None:
    db, _ = _db_with_user()
    fb = _RecordingAuth()
    fb.add("u1")
    db.store["users/u1"]["watchGeneration"] = 3
    code = watch_pairing.issue_code(db, "u1", now=NOW)["code"]
    watch_pairing.pair(db, code, fb_auth=fb, now=NOW)
    assert fb.claims["provider"] == "watch" and fb.claims["wgen"] == 3
    assert fb.claims["wdev"]


def test_disconnecting_all_watches_raises_the_generation() -> None:
    db, _ = _db_with_user()
    assert watch_pairing.revoke_all(db, "u1") == {"revoked": True, "generation": 1}
    assert watch_pairing.revoke_all(db, "u1")["generation"] == 2
    assert db.store["users/u1"]["watchGeneration"] == 2
    assert db.store["users/u1"]["nickname"] == "달림이"


def _pair(db, fb, device_id, label="", n=0):
    code = watch_pairing.issue_code(db, "u1", now=NOW)["code"]
    return watch_pairing.pair(
        db, code, device_id=device_id, device_label=label, fb_auth=fb, now=NOW + timedelta(seconds=n)
    )


def test_a_watch_keeps_its_id_and_pairing_again_uses_no_new_slot() -> None:
    db, fb = _db_with_user()
    first = _pair(db, fb, "watch-aaaaaaaa", "내 갤럭시 워치")
    again = _pair(db, fb, "watch-aaaaaaaa", "내 갤럭시 워치", 5)
    assert first["device_id"] == again["device_id"] == "watch-aaaaaaaa"
    assert watch_pairing.list_devices(db, "u1") == {
        "devices": [{"id": "watch-aaaaaaaa", "label": "내 갤럭시 워치"}],
        "max": 1,
    }


def test_pairing_a_new_watch_disconnects_the_previous_one() -> None:
    db, fb = _db_with_user()
    _pair(db, fb, "watch-0aaaaaaa", "갤럭시 워치")
    out = _pair(db, fb, "watch-newaaaaa", "다른 워치", n=9)
    assert out["device_id"] == "watch-newaaaaa"
    assert watch_pairing.list_devices(db, "u1")["devices"] == [
        {"id": "watch-newaaaaa", "label": "다른 워치"}
    ]
    assert db.store["users/u1/watchDevices/watch-0aaaaaaa"]["revoked"] is True


def test_removing_the_watch_empties_the_list_and_unknown_ids_are_404() -> None:
    db, fb = _db_with_user()
    _pair(db, fb, "watch-2aaaaaaa")
    assert watch_pairing.revoke_device(db, "u1", "watch-2aaaaaaa")["revoked"] is True
    assert watch_pairing.list_devices(db, "u1")["devices"] == []
    with pytest.raises(HTTPException) as caught:
        watch_pairing.revoke_device(db, "u1", "nope-nope-nope")
    assert caught.value.status_code == 404


def test_a_malformed_device_id_is_replaced_by_a_server_id() -> None:
    db, fb = _db_with_user()
    out = _pair(db, fb, "bad id/with slash")
    assert "/" not in out["device_id"] and len(out["device_id"]) >= 8

def test_re_pairing_a_revoked_watch_clears_the_revocation_cache() -> None:
    from app.services import auth_service

    db, fb = _db_with_user()
    _pair(db, fb, "watch-repaired")
    watch_pairing.revoke_device(db, "u1", "watch-repaired")
    auth_service._watch_device[("u1", "watch-repaired")] = (999999999.0, False)
    _pair(db, fb, "watch-repaired", n=5)
    assert ("u1", "watch-repaired") not in auth_service._watch_device

