"""Inputs a client controls cannot buy rewards: NaN, impossible runs, fake streaks."""

from datetime import datetime, timedelta, timezone
from types import SimpleNamespace

import pytest
from fastapi import HTTPException
from pydantic import ValidationError

from app.models.secured_actions import (
    CollectDiamondBoxRequest,
    SettleTournamentFailureRequest,
    ValidateRunRequest,
)
from app.models.validation_request import ValidationRequest
from app.services.running_validation_service import RunningValidationService
from app.services.secured_action_service import (
    SecuredActionService,
    _commit_settle_failure_tx,
    _commit_streak_bonus_tx,
)
from test_redeem_referral import _MemoryDb, _MemoryTxn

_KST = timezone(timedelta(hours=9))


def _service(db: _MemoryDb) -> SecuredActionService:
    return SecuredActionService(firebase_service=SimpleNamespace(db=db))


@pytest.mark.parametrize("bad", [float("nan"), float("inf"), 91.0])
def test_diamond_box_refuses_nan_and_out_of_range_latitude(bad: float) -> None:
    with pytest.raises(ValidationError):
        CollectDiamondBoxRequest(box_id="b1", latitude=bad, longitude=0)


def test_diamond_box_id_cannot_hold_a_path() -> None:
    with pytest.raises(ValidationError):
        CollectDiamondBoxRequest(box_id="a/b", latitude=0, longitude=0)


def test_run_request_refuses_infinite_distance_and_path_like_id() -> None:
    base = dict(
        activity_id="activity-1",
        distance_km=3.0,
        duration_seconds=1800,
        gyro_stability_score=0.3,
    )
    ValidateRunRequest(**base)
    with pytest.raises(ValidationError):
        ValidateRunRequest(**{**base, "distance_km": float("inf")})
    with pytest.raises(ValidationError):
        ValidateRunRequest(**{**base, "activity_id": "x/y"})
    with pytest.raises(ValidationError):
        ValidateRunRequest(**{**base, "duration_seconds": 10**9})


def test_settle_failure_refuses_nan() -> None:
    with pytest.raises(ValidationError):
        SettleTournamentFailureRequest(
            tournament_id="t1", distance_achieved_km=float("nan")
        )


@pytest.mark.parametrize(
    "distance_km,duration",
    [(999, 1), (42, 60), (101, 101 * 400)],
)
def test_impossible_runs_are_not_verified(distance_km: float, duration: int) -> None:
    request = ValidationRequest(
        activity_id="a1",
        user_id="u1",
        distance_km=distance_km,
        duration_seconds=duration,
        heart_rates=[],
        cadence_spm=[160] * 10,
        gyro_stability_score=0.2,
    )
    result = RunningValidationService().validate(request, total_steps=10_000_000)
    assert result.verified is False
    assert result.reason_code == "implausible_pace"
    assert result.forfeit_deposit is False


def _claim(db: _MemoryDb, age_days: int | None):
    user_ref = db.collection("users").document("u1")
    return _commit_streak_bonus_tx.to_wrap(
        _MemoryTxn(), _service(db), "u1", user_ref, age_days
    )


def test_streak_cannot_be_longer_than_the_account_is_old() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {"wallet": {"diamondBalance": 0, "shareBalance": 0}}
    end = datetime.now(_KST).date()
    for offset in range(400):  # a client wrote 400 fake days
        day = (end - timedelta(days=offset)).isoformat()
        db.store[f"users/u1/daily_metrics/{day}"] = {"steps": 1}

    result = _claim(db, 2)
    assert result.status == "not_eligible"
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 0

    result = _claim(db, 15)
    assert result.status == "claimed"
    assert db.store["users/u1"]["streakBonusMilestone"] == 14
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 20


def _settle(db: _MemoryDb):
    user_ref = db.collection("users").document("u1")
    tournament_ref = db.collection("tournaments").document("t1")
    participant_ref = tournament_ref.collection("participants").document("u1")
    return _commit_settle_failure_tx.to_wrap(
        _MemoryTxn(),
        _service(db),
        "u1",
        SettleTournamentFailureRequest(tournament_id="t1", distance_achieved_km=1),
        user_ref,
        tournament_ref,
        participant_ref,
    )


def test_a_forfeited_deposit_is_not_refunded_by_settle_failure() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {"wallet": {"diamondBalance": 0}}
    db.store["tournaments/t1"] = {"targetDistanceKm": 5}
    db.store["tournaments/t1/participants/u1"] = {
        "diamondDeposit": 10,
        "status": "forfeited_fraud",
        "depositForfeited": True,
    }
    with pytest.raises(HTTPException) as error:
        _settle(db)
    assert error.value.status_code == 409
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 0
