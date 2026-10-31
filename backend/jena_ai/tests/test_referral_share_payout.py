"""SHARE referral payouts: redeem, 3 counted trial days, hold, cap."""

from datetime import datetime, timedelta, timezone
from types import SimpleNamespace

import pytest
from fastapi import HTTPException

from app.models.secured_actions import ValidateRunRequest
from app.models.validation_result import ValidationResult
from app.services.economy_service import EconomyService
from app.services.secured_action_service import (
    SecuredActionService,
    _commit_validation_tx,
)
from app.services.twin_run import run_signature
from test_redeem_referral import _MemoryDb, _MemoryTxn, _NOW

_DAY1 = datetime(2026, 10, 1, 3, tzinfo=timezone.utc)
_DAY1_LATER = datetime(2026, 10, 1, 6, tzinfo=timezone.utc)
_DAY2 = datetime(2026, 10, 2, 3, tzinfo=timezone.utc)
_DAY3 = datetime(2026, 10, 3, 3, tzinfo=timezone.utc)


def _service(db: _MemoryDb) -> SecuredActionService:
    return SecuredActionService(firebase_service=SimpleNamespace(db=db))


def _share(db: _MemoryDb, uid: str) -> int:
    user = db.store.get(f"users/{uid}") or {}
    return int((user.get("wallet") or {}).get("shareBalance") or 0)


def _value(db: _MemoryDb, uid: str) -> int:
    user = db.store.get(f"users/{uid}") or {}
    return int((user.get("wallet") or {}).get("valueTokenBalance") or 0)


def _payout_count(db: _MemoryDb, uid: str) -> int:
    user = db.store.get(f"users/{uid}") or {}
    return int((user.get("economy") or {}).get("referralPayoutCount") or 0)


def _wallet(share: int, dia: int = 3, value: int = 7) -> dict:
    return {
        "shareBalance": share,
        "diamondBalance": dia,
        "valueTokenBalance": value,
    }


def _seed_pair(
    db: _MemoryDb,
    *,
    trial_run_count: int,
    payout_count: int = 0,
    referrer_device: str = "",
    referrer_has_run: bool = True,
    referrer_run_device: str = "referrer-phone",
) -> None:
    mining = {
        "dateKey": EconomyService().kst_today_key(),
        "earnedKm": 5.0,
        "earnedSrvTokens": 50,
    }
    db.store["users/u2"] = {
        "tier": 1,
        "economy": {
            "trialRunCount": trial_run_count,
            "referredBy": "u1",
            "referralCode": "KEEP",
        },
        "dailyMining": mining,
        "wallet": _wallet(40),
    }
    referrer_economy = {
        "referralPayoutCount": payout_count,
        "referralCode": "AB23CD45",
    }
    if referrer_device:
        referrer_economy["trialDeviceId"] = referrer_device
    if referrer_has_run:
        # An older outing, far from the referee's clock, so it is not a twin.
        # Without this, the first referee payout is held.
        latest_run = {
            "activityId": "referrer-older",
            "startedAt": "2026-09-01T00:00:00+00:00",
            "runSignature": "not-the-referee",
            "gpsRoute": [
                {"latitude": 35.0, "longitude": 129.0},
                {"latitude": 35.01, "longitude": 129.01},
            ],
        }
        if referrer_run_device:
            latest_run["deviceId"] = referrer_run_device
        referrer_economy["latestRun"] = latest_run
    db.store["users/u1"] = {
        "economy": referrer_economy,
        "wallet": _wallet(20, dia=1, value=2),
    }
    db.store["referralCodes/AB23CD45"] = {"uid": "u1"}


def _verified(
    activity_id: str,
    *,
    verified: bool = True,
    distance_km: float = 1.1,
    device_id: str | None = None,
) -> tuple:
    request = ValidateRunRequest(
        activity_id=activity_id,
        distance_km=distance_km,
        duration_seconds=400,
        gyro_stability_score=0.5,
        device_id=device_id,
    )
    result = ValidationResult(
        verified=verified,
        decision="verified" if verified else "rejected_unknown",
        reason="ok",
        value_token_reward=0,
        forfeit_deposit=False,
    )
    return request, result


def _persist(
    service: SecuredActionService,
    uid: str,
    activity_id: str,
    *,
    now: datetime | None = None,
    signup_at: datetime | None = None,
    **kwargs,
):
    request, result = _verified(activity_id, **kwargs)
    db = service.firebase_service.db
    return service._persist_validation_tx(
        _MemoryTxn(),
        uid,
        request,
        result,
        db.collection("activities").document(activity_id),
        db.collection("users").document(uid),
        account_created_at=signup_at,
        now=now,
    )


def _redeem(service: SecuredActionService, uid: str, code: str):
    db = service.firebase_service.db
    return service._apply_redeem_referral(
        _MemoryTxn(),
        uid,
        db.collection("users").document(uid),
        code,
        _NOW,
        now=_NOW,
    )


def test_redeem_pays_1000_once_and_rejects_repeat_self_and_invalid() -> None:
    db = _MemoryDb()
    db.store["users/u2"] = {"economy": {}, "wallet": _wallet(40)}
    db.store["users/u1"] = {"economy": {}, "wallet": _wallet(20, dia=1, value=2)}
    db.store["referralCodes/AB23CD45"] = {"uid": "u1"}
    service = _service(db)

    result = _redeem(service, "u2", "ab23cd45")

    assert result.referred_by == "u1"
    assert _share(db, "u2") == 10_040
    assert _share(db, "u1") == 20
    assert _value(db, "u2") == 7
    assert db.store["referralPayouts/u2_redeem"]["amount"] == 10_000
    receipt = db.store["users/u2/wallet_transactions/referral_u2_redeem"]
    assert receipt["title"] == "초대 코드 등록"
    assert receipt["amount"] == 10_000
    assert receipt["assetType"] == "SHARE"
    assert db.store["walletTransactions/referral_u2_u2_redeem"]["type"] == (
        "referral_redeem"
    )

    with pytest.raises(HTTPException) as again:
        _redeem(service, "u2", "AB23CD45")
    assert again.value.detail == "already"
    assert _share(db, "u2") == 10_040

    economy = db.store["users/u2"]["economy"]
    economy.pop("referredBy", None)
    _redeem(service, "u2", "AB23CD45")
    assert _share(db, "u2") == 10_040

    with pytest.raises(HTTPException) as own:
        _redeem(service, "u1", "AB23CD45")
    assert own.value.detail == "self"
    assert _share(db, "u1") == 20

    with pytest.raises(HTTPException) as missing:
        _redeem(service, "u2", "NOSUCH1")
    assert missing.value.detail == "invalid"
    assert _share(db, "u2") == 10_040
    assert not any(path.startswith("referralPayouts/u1_") for path in db.store)


def test_three_distinct_days_pay_referee_and_hold_referrer() -> None:
    db = _MemoryDb()
    _seed_pair(db, trial_run_count=0)
    service = _service(db)

    _persist(service, "u2", "short", distance_km=0.9, now=_DAY1, signup_at=_DAY1)
    assert db.store["users/u2"]["economy"]["trialRunCount"] == 0
    assert _share(db, "u2") == 40

    _persist(service, "u2", "run-1", now=_DAY1, signup_at=_DAY1)
    assert db.store["users/u2"]["economy"]["trialRunCount"] == 1
    assert _share(db, "u2") == 10_040
    assert _share(db, "u1") == 20
    assert db.store["referralPayouts/u2_trial_referee_1"]["amount"] == 10_000
    assert "referralPayouts/u2_trial_referrer" not in db.store

    _persist(service, "u2", "run-1b", now=_DAY1_LATER, signup_at=_DAY1)
    assert db.store["users/u2"]["economy"]["trialRunCount"] == 1
    assert _share(db, "u2") == 10_040

    _persist(service, "u2", "run-2", now=_DAY2, signup_at=_DAY1)
    assert db.store["users/u2"]["economy"]["trialRunCount"] == 2
    assert _share(db, "u2") == 10_040
    assert _share(db, "u1") == 20

    _persist(service, "u2", "run-3", now=_DAY3, signup_at=_DAY1)
    economy = db.store["users/u2"]["economy"]
    assert economy["trialRunCount"] == 3
    assert economy.get("trialMilestoneRewardClaimed") is not True
    assert economy.get("firstTierGranted") is not True
    assert len(set(economy["trialCountedDays"])) == 3
    assert _share(db, "u2") == 50_040
    assert _share(db, "u1") == 20
    assert _value(db, "u2") == 7
    assert _value(db, "u1") == 2
    assert db.store["users/u2"]["wallet"]["diamondBalance"] == 3
    assert _payout_count(db, "u1") == 1
    assert db.store["referralPayouts/u2_trial_referee"]["amount"] == 40_000
    referrer = db.store["referralPayouts/u2_trial_referrer"]
    assert referrer["amount"] == 30_000
    assert referrer["status"] == "pending"
    assert db.store["users/u1"]["economy"]["referrerHolds"]["u2"]["status"] == (
        "pending"
    )
    receipt = db.store["users/u2/wallet_transactions/referral_u2_trial_referee"]
    assert receipt["title"] == "체험 런 3회 완료"
    assert receipt["amount"] == 40_000
    hold = db.store["walletTransactions/trial_referrer_hold_u1_u2"]
    assert hold["shareAmount"] == 0
    assert hold["amount"] == 30_000

    _persist(service, "u2", "run-3")
    _persist(service, "u2", "run-4", now=_DAY3 + timedelta(days=1), signup_at=_DAY1)
    assert _share(db, "u2") == 50_040
    assert _share(db, "u1") == 20
    assert _payout_count(db, "u1") == 1
    assert _value(db, "u2") == 7


def test_referrer_hold_releases_once_and_clawback_pays_nothing() -> None:
    db = _MemoryDb()
    _seed_pair(db, trial_run_count=2)
    service = _service(db)
    _persist(service, "u2", "run-3", now=_DAY3, signup_at=_DAY1)
    assert _share(db, "u1") == 20

    service._release_referrer_holds_tx(_MemoryTxn(), "u1", _DAY3)
    assert _share(db, "u1") == 20

    release_at = _DAY3 + timedelta(days=7, seconds=1)
    service._release_referrer_holds_tx(_MemoryTxn(), "u1", release_at)
    assert _share(db, "u1") == 30_020
    assert _value(db, "u1") == 2
    released = db.store["walletTransactions/trial_referrer_release_u1_u2"]
    assert released["type"] == "referral_trial_referrer"
    assert released["shareAmount"] == 30_000
    assert db.store["users/u1"]["economy"]["referrerHolds"]["u2"]["status"] == (
        "released"
    )

    service._release_referrer_holds_tx(_MemoryTxn(), "u1", release_at)
    assert _share(db, "u1") == 30_020

    flagged = _MemoryDb()
    _seed_pair(flagged, trial_run_count=2)
    flagged_service = _service(flagged)
    _persist(flagged_service, "u2", "run-3", now=_DAY3, signup_at=_DAY1)
    flagged.store["referralPayouts/u2_trial_referrer"]["clawback"] = True
    flagged_service._release_referrer_holds_tx(_MemoryTxn(), "u1", release_at)
    assert _share(flagged, "u1") == 20
    assert flagged.store["users/u1"]["economy"]["referrerHolds"]["u2"]["status"] == (
        "clawed_back"
    )
    clawback = flagged.store["walletTransactions/trial_referrer_clawback_u1_u2"]
    assert clawback["shareAmount"] == 0


def test_run_outside_signup_window_does_not_count() -> None:
    db = _MemoryDb()
    _seed_pair(db, trial_run_count=0)
    late = _DAY1 + timedelta(days=15)
    _persist(_service(db), "u2", "late", now=late, signup_at=_DAY1)
    assert db.store["users/u2"]["economy"]["trialRunCount"] == 0
    assert _share(db, "u2") == 40


def test_same_device_blocks_a_second_trial_and_referrer_reward() -> None:
    db = _MemoryDb()
    _seed_pair(db, trial_run_count=0)
    service = _service(db)
    _persist(service, "u2", "run-1", now=_DAY1, signup_at=_DAY1, device_id="phone-a")
    assert db.store["trialDevices/phone-a"]["uid"] == "u2"

    db.store["users/u3"] = {
        "economy": {"referredBy": "u1"},
        "dailyMining": db.store["users/u2"]["dailyMining"],
        "wallet": _wallet(40),
    }
    _persist(
        service,
        "u3",
        "other",
        now=_DAY2,
        signup_at=_DAY1,
        device_id="phone-a",
    )
    assert db.store["users/u3"]["economy"].get("trialRunCount", 0) == 0
    assert _share(db, "u3") == 40

    # Running on the referrer's own registered phone is a device/account
    # relationship, not a one-run time window: it is held the same way
    # ``shared_device_history`` holds a past overlap, with no 30-minute
    # expiry and no need for the workout numbers to match.
    shared = _MemoryDb()
    _seed_pair(shared, trial_run_count=2, referrer_device="phone-b")
    _persist(
        _service(shared),
        "u2",
        "run-3",
        now=_DAY3,
        signup_at=_DAY1,
        device_id="phone-b",
    )
    assert _share(shared, "u2") == 40
    assert _share(shared, "u1") == 20
    referee = shared.store["referralPayouts/u2_trial_referee"]
    assert referee["reason"] == "shared_device_history"
    assert referee["amount"] == 40_000
    assert shared.store["referralPayouts/u2_trial_referrer"]["amount"] == 0
    assert shared.store["referralPayouts/u2_trial_referrer"]["reason"] == (
        "shared_device_history"
    )
    assert "walletTransactions/trial_referrer_hold_u1_u2" not in shared.store
    assert _payout_count(shared, "u1") == 0


def test_unverified_run_does_not_pay() -> None:
    db = _MemoryDb()
    _seed_pair(db, trial_run_count=2)
    _persist(_service(db), "u2", "run-x", verified=False, now=_DAY3, signup_at=_DAY1)
    assert db.store["users/u2"]["economy"]["trialRunCount"] == 2
    assert _share(db, "u2") == 40
    assert _share(db, "u1") == 20


def test_eleventh_referral_pays_referrer_nothing() -> None:
    db = _MemoryDb()
    _seed_pair(db, trial_run_count=2, payout_count=10)
    _persist(_service(db), "u2", "run-3", now=_DAY3, signup_at=_DAY1)
    assert _share(db, "u2") == 50_040
    assert _share(db, "u1") == 20
    assert _payout_count(db, "u1") == 10
    assert db.store["referralPayouts/u2_trial_referrer"]["amount"] == 0
    assert "walletTransactions/trial_referrer_hold_u1_u2" not in db.store

    _persist(_service(db), "u2", "run-3")
    assert _share(db, "u2") == 50_040
    assert _share(db, "u1") == 20


def test_legacy_referred_by_uid_does_not_pay_the_referrer() -> None:
    db = _MemoryDb()
    db.store["users/u2"] = {
        "tier": 1,
        "economy": {"trialRunCount": 2, "referredByUid": "u1"},
        "dailyMining": {
            "dateKey": EconomyService().kst_today_key(),
            "earnedKm": 5.0,
            "earnedSrvTokens": 50,
        },
        "wallet": _wallet(40),
    }
    db.store["users/u1"] = {
        "economy": {"referralPayoutCount": 0},
        "wallet": _wallet(20, dia=1, value=2),
    }
    _persist(_service(db), "u2", "run-3", now=_DAY3, signup_at=_DAY1)
    assert db.store["users/u2"]["economy"]["trialRunCount"] == 3
    assert _share(db, "u2") == 40
    assert _share(db, "u1") == 20
    assert _value(db, "u2") == 7
    assert _payout_count(db, "u1") == 0
    assert not any(path.startswith("referralPayouts/") for path in db.store)


def test_redeem_after_three_runs_pays_milestones_and_holds_referrer() -> None:
    db = _MemoryDb()
    db.store["users/u2"] = {
        "economy": {
            "trialRunCount": 3,
            "trialCountedDays": ["2026-10-01", "2026-10-02", "2026-10-03"],
            "trialMilestoneRewardClaimed": True,
        },
        "wallet": _wallet(40),
    }
    db.store["users/u1"] = {
        "economy": {
            "referralPayoutCount": 9,
            "latestRun": {
                "activityId": "referrer-older",
                "startedAt": "2026-09-01T00:00:00+00:00",
                "runSignature": "not-the-referee",
                "deviceId": "referrer-phone",
            },
        },
        "wallet": _wallet(20, dia=1, value=2),
    }
    db.store["referralCodes/AB23CD45"] = {"uid": "u1"}
    service = _service(db)

    _redeem(service, "u2", "AB23CD45")
    assert _share(db, "u2") == 60_040
    assert _share(db, "u1") == 20
    assert _payout_count(db, "u1") == 10
    assert _value(db, "u2") == 7
    assert db.store["referralPayouts/u2_trial_referrer"]["status"] == "pending"

    _persist(service, "u2", "run-6", now=_DAY3, signup_at=_DAY1)
    assert _share(db, "u2") == 60_040
    assert _share(db, "u1") == 20
    assert _payout_count(db, "u1") == 10


def _route(stamp: str) -> list[dict]:
    return [
        {"latitude": 37.5, "longitude": 127.0, "recordedAt": stamp},
        {"latitude": 37.501, "longitude": 127.001, "recordedAt": stamp},
        {"latitude": 37.502, "longitude": 127.002, "recordedAt": stamp},
    ]


def test_a_twin_outing_holds_referee_and_referrer_share() -> None:
    db = _MemoryDb()
    _seed_pair(db, trial_run_count=2)
    cadence = [170] * 20
    signature = run_signature(
        distance_km=1.1, duration_seconds=400, cadence_spm=cadence
    )
    db.store["activities/referrer-outing"] = {
        "userId": "u1",
        "jenaVerified": True,
        "startedAt": _DAY3.isoformat(),
        "runSignature": signature,
        "gpsRoute": _route("t"),
        "deviceId": "phone-r",
    }
    service = _service(db)
    request = ValidateRunRequest(
        activity_id="run-3",
        distance_km=1.1,
        duration_seconds=400,
        gyro_stability_score=0.5,
        cadence_spm=cadence,
        gps_route=_route("t2"),
        started_at=(_DAY3 + timedelta(seconds=40)).isoformat(),
        device_id="phone-e",
    )
    result = ValidationResult(
        verified=True,
        decision="verified",
        reason="ok",
        value_token_reward=0,
        forfeit_deposit=False,
    )
    service._persist_validation_tx(
        _MemoryTxn(),
        "u2",
        request,
        result,
        db.collection("activities").document("run-3"),
        db.collection("users").document("u2"),
        account_created_at=_DAY1,
        now=_DAY3,
    )

    assert _share(db, "u2") == 40
    assert _share(db, "u1") == 20
    assert _payout_count(db, "u1") == 0
    for payout_type, amount in (("trial_referee_1", 10_000), ("trial_referee", 40_000)):
        marker = db.store[f"referralPayouts/u2_{payout_type}"]
        assert marker["status"] == "held"
        assert marker["reason"] == "twin_run"
        assert marker["amount"] == amount
    referrer = db.store["referralPayouts/u2_trial_referrer"]
    assert referrer["status"] == "held"
    assert referrer["reason"] == "twin_run"
    assert referrer["amount"] == 30_000
    assert "users/u1" not in {
        path.split("/")[1]
        for path, row in db.store.items()
        if path.startswith("walletTransactions/referral_")
        and isinstance(row, dict)
        and row.get("shareAmount", 0) > 0
    }


def test_a_phone_run_without_gps_is_held_when_the_signature_matches() -> None:
    db = _MemoryDb()
    _seed_pair(db, trial_run_count=2)
    cadence = [160] * 12
    signature = run_signature(
        distance_km=1.1, duration_seconds=400, cadence_spm=cadence
    )
    db.store["users/u1"]["economy"]["latestRun"] = {
        "activityId": "old",
        "startedAt": _DAY3.isoformat(),
        "runSignature": signature,
        "deviceId": "phone-r",
    }
    service = _service(db)
    request = ValidateRunRequest(
        activity_id="run-3",
        distance_km=1.1,
        duration_seconds=400,
        gyro_stability_score=0.5,
        cadence_spm=cadence,
        started_at=(_DAY3 + timedelta(seconds=25)).isoformat(),
        device_id="phone-e",
    )
    service._persist_validation_tx(
        _MemoryTxn(),
        "u2",
        request,
        ValidationResult(
            verified=True,
            decision="verified",
            reason="ok",
            value_token_reward=0,
            forfeit_deposit=False,
        ),
        db.collection("activities").document("run-3"),
        db.collection("users").document("u2"),
        account_created_at=_DAY1,
        now=_DAY3,
    )
    assert _share(db, "u2") == 40
    assert db.store["referralPayouts/u2_trial_referee"]["reason"] == "twin_run"
    assert db.store["referralPayouts/u2_trial_referrer"]["status"] == "held"


def test_missing_trial_device_id_still_blocks_a_known_phone() -> None:
    db = _MemoryDb()
    _seed_pair(db, trial_run_count=2)
    db.store["users/u1/loginDevices/phone-a"] = {"deviceId": "phone-a"}
    _persist(
        _service(db),
        "u2",
        "run-3",
        now=_DAY3,
        signup_at=_DAY1,
        device_id="phone-a",
    )
    # A login-device match is the referrer's known phone too, so the
    # referee's milestone is held alongside the referrer's zeroed amount.
    assert _share(db, "u2") == 40
    assert _share(db, "u1") == 20
    referee = db.store["referralPayouts/u2_trial_referee"]
    assert referee["reason"] == "shared_device_history"
    referrer = db.store["referralPayouts/u2_trial_referrer"]
    assert referrer["amount"] == 0
    assert referrer["reason"] == "shared_device_history"
    assert _payout_count(db, "u1") == 0
    assert "trialDeviceId" not in db.store["users/u1"]["economy"]


def test_no_device_on_either_side_holds_until_one_appears() -> None:
    db = _MemoryDb()
    _seed_pair(db, trial_run_count=0, referrer_run_device="")
    service = _service(db)
    _persist(service, "u2", "run-1", now=_DAY1, signup_at=_DAY1)
    assert _share(db, "u2") == 40
    assert _share(db, "u1") == 20
    marker = db.store["referralPayouts/u2_trial_referee_1"]
    assert marker["status"] == "held"
    assert marker["reason"] == "device_id_absent"
    assert marker["amount"] == 10_000

    _persist(
        service,
        "u2",
        "run-2",
        now=_DAY2,
        signup_at=_DAY1,
        device_id="watch-abc12345",
    )
    assert _share(db, "u2") == 10_040
    assert db.store["referralPayouts/u2_trial_referee_1"].get("status") != "held"


def test_a_watch_device_id_is_not_treated_as_missing() -> None:
    db = _MemoryDb()
    _seed_pair(db, trial_run_count=0, referrer_run_device="")
    _persist(
        _service(db),
        "u2",
        "run-1",
        now=_DAY1,
        signup_at=_DAY1,
        device_id="watch-abc12345",
    )
    assert _share(db, "u2") == 10_040
    marker = db.store["referralPayouts/u2_trial_referee_1"]
    assert marker.get("status") != "held"
    assert marker["amount"] == 10_000


def test_same_device_shifted_gps_holds_the_referral() -> None:
    db = _MemoryDb()
    _seed_pair(db, trial_run_count=2)
    cadence = [170] * 20
    signature = run_signature(
        distance_km=1.1, duration_seconds=400, cadence_spm=cadence
    )
    far = [
        {"latitude": 35.1, "longitude": 129.0, "recordedAt": "t"},
        {"latitude": 35.12, "longitude": 129.02, "recordedAt": "t"},
        {"latitude": 35.14, "longitude": 129.04, "recordedAt": "t"},
    ]
    db.store["activities/referrer-outing"] = {
        "userId": "u1",
        "jenaVerified": True,
        "startedAt": _DAY3.isoformat(),
        "runSignature": signature,
        "gpsRoute": _route("t"),
        "deviceId": "phone-same",
    }
    service = _service(db)
    request = ValidateRunRequest(
        activity_id="run-3",
        distance_km=1.1,
        duration_seconds=400,
        gyro_stability_score=0.5,
        cadence_spm=cadence,
        gps_route=far,
        started_at=(_DAY3 + timedelta(seconds=40)).isoformat(),
        device_id="phone-same",
    )
    service._persist_validation_tx(
        _MemoryTxn(),
        "u2",
        request,
        ValidationResult(
            verified=True,
            decision="verified",
            reason="ok",
            value_token_reward=0,
            forfeit_deposit=False,
        ),
        db.collection("activities").document("run-3"),
        db.collection("users").document("u2"),
        account_created_at=_DAY1,
        now=_DAY3,
    )
    assert _share(db, "u2") == 40
    assert db.store["referralPayouts/u2_trial_referee"]["reason"] == "twin_run"
    assert db.store["referralPayouts/u2_trial_referee"]["amount"] == 40_000
    # Same phone still zeros the referrer. The new part is the referee hold.
    referrer = db.store["referralPayouts/u2_trial_referrer"]
    assert referrer["status"] == "held"
    assert referrer["reason"] == "twin_run"
    assert referrer["amount"] == 0


def test_no_referrer_run_holds_the_referee_until_a_later_run() -> None:
    db = _MemoryDb()
    _seed_pair(db, trial_run_count=0, referrer_has_run=False)
    service = _service(db)
    _persist(service, "u2", "run-1", now=_DAY1, signup_at=_DAY1)
    assert _share(db, "u2") == 40
    assert _share(db, "u1") == 20
    marker = db.store["referralPayouts/u2_trial_referee_1"]
    assert marker["status"] == "held"
    assert marker["reason"] == "referrer_run_absent"
    assert marker["amount"] == 10_000

    _persist(service, "u2", "run-2", now=_DAY2, signup_at=_DAY1)
    assert _share(db, "u2") == 40
    assert db.store["referralPayouts/u2_trial_referee_1"]["reason"] == (
        "referrer_run_absent"
    )

    db.store["users/u1"]["economy"]["latestRun"] = {
        "activityId": "referrer-later",
        "startedAt": "2026-09-20T00:00:00+00:00",
        "runSignature": "still-not-the-referee",
        "deviceId": "referrer-phone",
        "gpsRoute": [
            {"latitude": 35.0, "longitude": 129.0},
            {"latitude": 35.02, "longitude": 129.02},
        ],
    }
    _persist(service, "u2", "run-3", now=_DAY3, signup_at=_DAY1)
    assert _share(db, "u2") == 50_040
    assert db.store["referralPayouts/u2_trial_referee_1"].get("status") != "held"
    assert db.store["referralPayouts/u2_trial_referee"]["amount"] == 40_000
    referrer = db.store["referralPayouts/u2_trial_referrer"]
    assert referrer["status"] == "pending"
    assert referrer["amount"] == 30_000
    assert _share(db, "u1") == 20


def test_a_device_shared_in_past_history_holds_the_referral_without_a_gps_twin() -> None:
    """The run being judged uses a new device, so the GPS twin check and the
    single-device ``_same_referrer_phone`` check both miss it. An older
    referee run on a device the referrer's account has also used is still a
    fact about the two accounts, so the milestone and the referrer reward
    are held as ``shared_device_history`` instead of paid.
    """
    db = _MemoryDb()
    _seed_pair(db, trial_run_count=2, referrer_device="shared-phone")
    db.store["activities/u2-old"] = {
        "userId": "u2",
        "jenaVerified": True,
        "startedAt": "2026-09-15T00:00:00+00:00",
        "deviceId": "shared-phone",
    }
    _persist(
        _service(db),
        "u2",
        "run-3",
        now=_DAY3,
        signup_at=_DAY1,
        device_id="phone-new",
    )
    assert _share(db, "u2") == 40
    referee = db.store["referralPayouts/u2_trial_referee"]
    assert referee["reason"] == "shared_device_history"
    assert referee["amount"] == 40_000
    referrer = db.store["referralPayouts/u2_trial_referrer"]
    assert referrer["status"] == "held"
    assert referrer["reason"] == "shared_device_history"
    assert referrer["amount"] == 30_000


def _square(shift_m: float = 0.0) -> list[dict]:
    corners = [(0.0, 0.0), (200.0, 0.0), (200.0, 200.0), (0.0, 200.0), (0.0, 0.0)]
    points = []
    for left, right in zip(corners, corners[1:]):
        for step in range(8):
            blend = step / 8
            north = left[0] + (right[0] - left[0]) * blend
            east = left[1] + (right[1] - left[1]) * blend + shift_m
            points.append(
                {
                    "latitude": 37.5 + north / 111_320.0,
                    "longitude": 127.0 + east / 88_300.0,
                    "recordedAt": "t",
                }
            )
    return points


def _finish_referral(db, *, device_id: str, route: list[dict], started: datetime, cadence: list[int]):
    service = _service(db)
    request = ValidateRunRequest(
        activity_id="run-3",
        distance_km=1.1,
        duration_seconds=400,
        gyro_stability_score=0.5,
        cadence_spm=cadence,
        gps_route=route,
        started_at=started.isoformat(),
        device_id=device_id,
    )
    service._persist_validation_tx(
        _MemoryTxn(),
        "u2",
        request,
        ValidationResult(
            verified=True,
            decision="verified",
            reason="ok",
            value_token_reward=0,
            forfeit_deposit=False,
        ),
        db.collection("activities").document("run-3"),
        db.collection("users").document("u2"),
        account_created_at=_DAY1,
        now=_DAY3,
    )


def test_offset_loop_on_two_phones_holds_referee_and_referrer() -> None:
    """Different devices, same signature, route slid 150m. 40,000 + 30,000 stay held.

    The 10,000 first milestone uses the same ``twin_run`` reason when that
    run is the copy. This call is the third day, so the new row is 40,000.
    """
    db = _MemoryDb()
    _seed_pair(db, trial_run_count=2, referrer_run_device="phone-r")
    cadence = [170] * 20
    signature = run_signature(distance_km=1.1, duration_seconds=400, cadence_spm=cadence)
    db.store["activities/referrer-outing"] = {
        "userId": "u1",
        "jenaVerified": True,
        "startedAt": _DAY3.isoformat(),
        "runSignature": signature,
        "gpsRoute": _square(),
        "deviceId": "phone-r",
    }
    _finish_referral(
        db,
        device_id="phone-b",
        route=_square(150.0),
        started=_DAY3 + timedelta(seconds=40),
        cadence=cadence,
    )
    assert _share(db, "u2") == 40
    assert _share(db, "u1") == 20
    referee = db.store["referralPayouts/u2_trial_referee"]
    assert referee["reason"] == "twin_run"
    assert referee["amount"] == 40_000
    referrer = db.store["referralPayouts/u2_trial_referrer"]
    assert referrer["status"] == "held"
    assert referrer["reason"] == "twin_run"
    assert referrer["amount"] == 30_000


def test_same_phone_start_delayed_181s_holds_the_referee() -> None:
    """3 min 1 s later on one phone. Referrer was already 0. Referee 40,000 is held."""
    db = _MemoryDb()
    _seed_pair(db, trial_run_count=2, referrer_run_device="phone-same")
    cadence = [170] * 20
    signature = run_signature(distance_km=1.1, duration_seconds=400, cadence_spm=cadence)
    db.store["activities/referrer-outing"] = {
        "userId": "u1",
        "jenaVerified": True,
        "startedAt": _DAY3.isoformat(),
        "runSignature": signature,
        "gpsRoute": _square(),
        "deviceId": "phone-same",
    }
    _finish_referral(
        db,
        device_id="phone-same",
        route=_square(400.0),
        started=_DAY3 + timedelta(seconds=181),
        cadence=cadence,
    )
    assert _share(db, "u2") == 40
    referee = db.store["referralPayouts/u2_trial_referee"]
    assert referee["reason"] == "twin_run"
    assert referee["amount"] == 40_000
    referrer = db.store["referralPayouts/u2_trial_referrer"]
    assert referrer["amount"] == 0
    assert referrer["reason"] == "twin_run"


def test_same_phone_31_minutes_later_with_a_changed_signature_still_holds_the_referee() -> None:
    """Past the old 30-minute GPS window, with different workout numbers
    and a route that is not a translated copy of the referrer's, the GPS
    checks miss this pair entirely. The phone is still the referrer's own,
    so the device relationship (not a time window) holds the referee's
    milestone too, the same way ``shared_device_history`` holds a past
    overlap.
    """
    db = _MemoryDb()
    _seed_pair(db, trial_run_count=2, referrer_run_device="phone-same")
    cadence = [170] * 20
    signature = run_signature(distance_km=1.1, duration_seconds=400, cadence_spm=cadence)
    db.store["activities/referrer-outing"] = {
        "userId": "u1",
        "jenaVerified": True,
        "startedAt": _DAY3.isoformat(),
        "runSignature": signature,
        "gpsRoute": _square(),
        "deviceId": "phone-same",
    }
    _finish_referral(
        db,
        device_id="phone-same",
        route=[
            {"latitude": 37.6, "longitude": 127.3, "recordedAt": "t"},
            {"latitude": 37.601, "longitude": 127.301, "recordedAt": "t"},
        ],
        started=_DAY3 + timedelta(minutes=31),
        cadence=[150] * 20,
    )
    assert _share(db, "u2") == 40
    referee = db.store["referralPayouts/u2_trial_referee"]
    assert referee["reason"] == "shared_device_history"
    assert referee["amount"] == 40_000
    referrer = db.store["referralPayouts/u2_trial_referrer"]
    assert referrer["amount"] == 0
    assert referrer["reason"] == "shared_device_history"


def test_same_road_different_device_and_day_pays_in_full() -> None:
    """A real false-positive guard: the referee runs the same street the
    referrer ran weeks earlier, on a different phone, at a different pace.
    Neither the GPS-twin check (time window) nor the device-relationship
    check should hold this pair.
    """
    db = _MemoryDb()
    _seed_pair(db, trial_run_count=2, referrer_run_device="phone-r")
    db.store["activities/referrer-outing"] = {
        "userId": "u1",
        "jenaVerified": True,
        "startedAt": "2026-08-01T00:00:00+00:00",
        "runSignature": "a-completely-different-pace",
        "gpsRoute": _square(),
        "deviceId": "phone-r",
    }
    _finish_referral(
        db,
        device_id="phone-e",
        route=_square(),
        started=_DAY3,
        cadence=[190] * 20,
    )
    assert _share(db, "u2") == 50_040
    assert _share(db, "u1") == 20
    assert db.store["referralPayouts/u2_trial_referee"].get("status") != "held"
    referrer = db.store["referralPayouts/u2_trial_referrer"]
    assert referrer["status"] == "pending"
    assert referrer["amount"] == 30_000


def test_validation_wrapper_passes_transaction_before_service() -> None:
    from unittest.mock import MagicMock

    service = MagicMock()
    service._persist_validation_tx.return_value = "ok"
    issued = _commit_validation_tx.to_wrap(
        "transaction",
        service,
        "u2",
        "request",
        "result",
        "activity",
        "user",
    )
    assert issued == "ok"
    service._persist_validation_tx.assert_called_once_with(
        "transaction",
        "u2",
        "request",
        "result",
        "activity",
        "user",
        account_created_at=None,
        now=None,
    )
