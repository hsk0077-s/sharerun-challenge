"""SHARE referral payouts: redeem, 5th verified run, cap, idempotency."""

from types import SimpleNamespace

import pytest
from fastapi import HTTPException

from app.models.secured_actions import ValidateRunRequest
from app.models.validation_result import ValidationResult
from app.services.secured_action_service import (
    SecuredActionService,
    _commit_validation_tx,
)
from test_redeem_referral import _MemoryDb, _MemoryTxn, _NOW


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


def _seed_pair(db: _MemoryDb, *, trial_run_count: int, payout_count: int = 0) -> None:
    db.store["users/u2"] = {
        "tier": 1,
        "economy": {
            "trialRunCount": trial_run_count,
            "referredBy": "u1",
            "referralCode": "KEEP",
        },
        "wallet": _wallet(40),
    }
    db.store["users/u1"] = {
        "economy": {"referralPayoutCount": payout_count, "referralCode": "AB23CD45"},
        "wallet": _wallet(20, dia=1, value=2),
    }
    db.store["referralCodes/AB23CD45"] = {"uid": "u1"}


def _verified(activity_id: str, *, verified: bool = True) -> tuple:
    request = ValidateRunRequest(
        activity_id=activity_id,
        distance_km=0.05,
        duration_seconds=30,
        gyro_stability_score=0.5,
    )
    result = ValidationResult(
        verified=verified,
        decision="verified" if verified else "rejected_unknown",
        reason="ok",
        value_token_reward=0,
        forfeit_deposit=False,
    )
    return request, result


def _persist(service: SecuredActionService, uid: str, activity_id: str, **kwargs):
    request, result = _verified(activity_id, **kwargs)
    db = service.firebase_service.db
    return service._persist_validation_tx(
        _MemoryTxn(),
        uid,
        request,
        result,
        db.collection("activities").document(activity_id),
        db.collection("users").document(uid),
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
    assert _share(db, "u2") == 1_040
    assert _share(db, "u1") == 20
    assert _value(db, "u2") == 7
    assert db.store["referralPayouts/u2_redeem"]["amount"] == 1_000
    receipt = db.store["users/u2/wallet_transactions/referral_u2_redeem"]
    assert receipt["title"] == "초대 코드 등록"
    assert receipt["amount"] == 1_000
    assert receipt["assetType"] == "SHARE"
    assert db.store["walletTransactions/referral_u2_u2_redeem"]["type"] == (
        "referral_redeem"
    )

    with pytest.raises(HTTPException) as again:
        _redeem(service, "u2", "AB23CD45")
    assert again.value.detail == "already"
    assert _share(db, "u2") == 1_040

    economy = db.store["users/u2"]["economy"]
    economy.pop("referredBy", None)
    _redeem(service, "u2", "AB23CD45")
    assert _share(db, "u2") == 1_040

    with pytest.raises(HTTPException) as own:
        _redeem(service, "u1", "AB23CD45")
    assert own.value.detail == "self"
    assert _share(db, "u1") == 20

    with pytest.raises(HTTPException) as missing:
        _redeem(service, "u2", "NOSUCH1")
    assert missing.value.detail == "invalid"
    assert _share(db, "u2") == 1_040
    assert not any(path.startswith("referralPayouts/u1_") for path in db.store)


def test_fifth_verified_run_pays_referee_and_referrer_once() -> None:
    db = _MemoryDb()
    _seed_pair(db, trial_run_count=3)
    service = _service(db)

    _persist(service, "u2", "run-4")
    assert db.store["users/u2"]["economy"]["trialRunCount"] == 4
    assert _share(db, "u2") == 40
    assert _share(db, "u1") == 20
    assert _value(db, "u2") == 7
    assert not any(path.startswith("referralPayouts/") for path in db.store)

    _persist(service, "u2", "run-5")
    assert db.store["users/u2"]["economy"]["trialRunCount"] == 5
    assert db.store["users/u2"]["economy"]["trialMilestoneRewardClaimed"] is True
    assert _share(db, "u2") == 5_040
    assert _share(db, "u1") == 3_020
    assert _value(db, "u2") == 507
    assert _value(db, "u1") == 2
    assert db.store["users/u2"]["wallet"]["diamondBalance"] == 3
    assert _payout_count(db, "u1") == 1
    assert db.store["referralPayouts/u2_trial_referee"]["amount"] == 5_000
    assert db.store["referralPayouts/u2_trial_referrer"]["amount"] == 3_000
    referee_receipt = db.store[
        "users/u2/wallet_transactions/referral_u2_trial_referee"
    ]
    referrer_receipt = db.store[
        "users/u1/wallet_transactions/referral_u2_trial_referrer"
    ]
    assert referee_receipt["title"] == "체험 런 5회 완료"
    assert referee_receipt["amount"] == 5_000
    assert referrer_receipt["title"] == "친구 체험 런 5회"
    assert referrer_receipt["amount"] == 3_000

    _persist(service, "u2", "run-5")
    _persist(service, "u2", "run-6")
    assert _share(db, "u2") == 5_040
    assert _share(db, "u1") == 3_020
    assert _payout_count(db, "u1") == 1
    assert _value(db, "u2") == 507


def test_unverified_run_does_not_pay() -> None:
    db = _MemoryDb()
    _seed_pair(db, trial_run_count=4)
    _persist(_service(db), "u2", "run-x", verified=False)
    assert db.store["users/u2"]["economy"]["trialRunCount"] == 4
    assert _share(db, "u2") == 40
    assert _share(db, "u1") == 20


def test_eleventh_referral_pays_referrer_nothing() -> None:
    db = _MemoryDb()
    _seed_pair(db, trial_run_count=4, payout_count=10)
    _persist(_service(db), "u2", "run-5")
    assert _share(db, "u2") == 5_040
    assert _share(db, "u1") == 20
    assert _payout_count(db, "u1") == 10
    assert db.store["referralPayouts/u2_trial_referrer"]["amount"] == 0
    assert "users/u1/wallet_transactions/referral_u2_trial_referrer" not in db.store

    _persist(_service(db), "u2", "run-5")
    assert _share(db, "u2") == 5_040
    assert _share(db, "u1") == 20


def test_legacy_referred_by_uid_does_not_pay_srv_or_share() -> None:
    db = _MemoryDb()
    db.store["users/u2"] = {
        "tier": 1,
        "economy": {"trialRunCount": 4, "referredByUid": "u1"},
        "wallet": _wallet(40),
    }
    db.store["users/u1"] = {
        "economy": {"referralPayoutCount": 0},
        "wallet": _wallet(20, dia=1, value=2),
    }
    _persist(_service(db), "u2", "run-5")
    assert _share(db, "u2") == 40
    assert _share(db, "u1") == 20
    assert _value(db, "u2") == 507
    assert _value(db, "u1") == 2
    assert _payout_count(db, "u1") == 0
    assert not any(path.startswith("referralPayouts/") for path in db.store)


def test_redeem_after_five_runs_pays_all_once() -> None:
    db = _MemoryDb()
    db.store["users/u2"] = {
        "economy": {
            "trialRunCount": 5,
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
    assert _share(db, "u2") == 6_040
    assert _share(db, "u1") == 3_020
    assert _payout_count(db, "u1") == 10
    assert _value(db, "u2") == 7

    _persist(service, "u2", "run-6")
    assert _share(db, "u2") == 6_040
    assert _share(db, "u1") == 3_020
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
        "transaction", "u2", "request", "result", "activity", "user"
    )
