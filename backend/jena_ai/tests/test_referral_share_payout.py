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
    assert _share(db, "u2") == 1_040
    assert _share(db, "u1") == 20
    assert db.store["referralPayouts/u2_trial_referee_1"]["amount"] == 1_000
    assert "referralPayouts/u2_trial_referrer" not in db.store

    _persist(service, "u2", "run-1b", now=_DAY1_LATER, signup_at=_DAY1)
    assert db.store["users/u2"]["economy"]["trialRunCount"] == 1
    assert _share(db, "u2") == 1_040

    _persist(service, "u2", "run-2", now=_DAY2, signup_at=_DAY1)
    assert db.store["users/u2"]["economy"]["trialRunCount"] == 2
    assert _share(db, "u2") == 1_040
    assert _share(db, "u1") == 20

    _persist(service, "u2", "run-3", now=_DAY3, signup_at=_DAY1)
    economy = db.store["users/u2"]["economy"]
    assert economy["trialRunCount"] == 3
    assert economy.get("trialMilestoneRewardClaimed") is not True
    assert economy.get("firstTierGranted") is not True
    assert len(set(economy["trialCountedDays"])) == 3
    assert _share(db, "u2") == 5_040
    assert _share(db, "u1") == 20
    assert _value(db, "u2") == 7
    assert _value(db, "u1") == 2
    assert db.store["users/u2"]["wallet"]["diamondBalance"] == 3
    assert _payout_count(db, "u1") == 1
    assert db.store["referralPayouts/u2_trial_referee"]["amount"] == 4_000
    referrer = db.store["referralPayouts/u2_trial_referrer"]
    assert referrer["amount"] == 3_000
    assert referrer["status"] == "pending"
    assert db.store["users/u1"]["economy"]["referrerHolds"]["u2"]["status"] == (
        "pending"
    )
    receipt = db.store["users/u2/wallet_transactions/referral_u2_trial_referee"]
    assert receipt["title"] == "체험 런 3회 완료"
    assert receipt["amount"] == 4_000
    hold = db.store["walletTransactions/trial_referrer_hold_u1_u2"]
    assert hold["shareAmount"] == 0
    assert hold["amount"] == 3_000

    _persist(service, "u2", "run-3")
    _persist(service, "u2", "run-4", now=_DAY3 + timedelta(days=1), signup_at=_DAY1)
    assert _share(db, "u2") == 5_040
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
    assert _share(db, "u1") == 3_020
    assert _value(db, "u1") == 2
    released = db.store["walletTransactions/trial_referrer_release_u1_u2"]
    assert released["type"] == "referral_trial_referrer"
    assert released["shareAmount"] == 3_000
    assert db.store["users/u1"]["economy"]["referrerHolds"]["u2"]["status"] == (
        "released"
    )

    service._release_referrer_holds_tx(_MemoryTxn(), "u1", release_at)
    assert _share(db, "u1") == 3_020

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
    assert _share(shared, "u2") == 5_040
    assert _share(shared, "u1") == 20
    assert shared.store["referralPayouts/u2_trial_referrer"]["amount"] == 0
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
    assert _share(db, "u2") == 5_040
    assert _share(db, "u1") == 20
    assert _payout_count(db, "u1") == 10
    assert db.store["referralPayouts/u2_trial_referrer"]["amount"] == 0
    assert "walletTransactions/trial_referrer_hold_u1_u2" not in db.store

    _persist(_service(db), "u2", "run-3")
    assert _share(db, "u2") == 5_040
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
        "economy": {"referralPayoutCount": 9},
        "wallet": _wallet(20, dia=1, value=2),
    }
    db.store["referralCodes/AB23CD45"] = {"uid": "u1"}
    service = _service(db)

    _redeem(service, "u2", "AB23CD45")
    assert _share(db, "u2") == 15_040
    assert _share(db, "u1") == 20
    assert _payout_count(db, "u1") == 10
    assert _value(db, "u2") == 7
    assert db.store["referralPayouts/u2_trial_referrer"]["status"] == "pending"

    _persist(service, "u2", "run-6", now=_DAY3, signup_at=_DAY1)
    assert _share(db, "u2") == 15_040
    assert _share(db, "u1") == 20
    assert _payout_count(db, "u1") == 10


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
