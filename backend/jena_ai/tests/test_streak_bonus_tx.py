"""Streak DIA is paid once per 7-day milestone, including a jumped count."""

from datetime import datetime, timedelta, timezone
from types import SimpleNamespace

from app.services.secured_action_service import (
    SecuredActionService,
    _commit_streak_bonus_tx,
)
from test_redeem_referral import _MemoryDb, _MemoryTxn

_KST = timezone(timedelta(hours=9))


def _claim(service: SecuredActionService):
    user_ref = service.firebase_service.db.collection("users").document("u1")
    return _commit_streak_bonus_tx.to_wrap(_MemoryTxn(), service, "u1", user_ref)


def _seed_days(db: _MemoryDb, days: int) -> None:
    end = datetime.now(_KST).date()
    for offset in range(days):
        day = (end - timedelta(days=offset)).isoformat()
        steps = 0 if offset == 0 else 100
        km = 1.2 if offset == 0 else 0
        db.store[f"users/u1/daily_metrics/{day}"] = {"steps": steps, "km": km}


def test_streak_pays_each_seven_day_milestone_once() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {
        "wallet": {"diamondBalance": 4, "shareBalance": 1_000_000},
    }
    _seed_days(db, 8)
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))

    result = _claim(service)

    assert result.status == "claimed"
    assert result.diamond_balance == 14
    assert result.share_balance == 1_000_000
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 14
    assert db.store["users/u1"]["streakBonusMilestone"] == 7
    ledger = [
        row
        for path, row in db.store.items()
        if path.startswith("walletTransactions/")
    ]
    assert len(ledger) == 1
    assert ledger[0]["type"] == "streak_bonus"
    assert ledger[0]["diamondAmount"] == 10
    assert ledger[0]["streakDays"] == 7

    again = _claim(service)
    assert again.status == "already_claimed"
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 14
    assert (
        sum(1 for path in db.store if path.startswith("walletTransactions/"))
        == 1
    )

    _seed_days(db, 14)
    next_milestone = _claim(service)
    assert next_milestone.status == "claimed"
    assert next_milestone.diamond_balance == 24
    assert db.store["users/u1"]["streakBonusMilestone"] == 14
    assert (
        sum(1 for path in db.store if path.startswith("walletTransactions/"))
        == 2
    )


def test_jumped_streak_pays_every_crossed_milestone_once() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {"wallet": {"diamondBalance": 0, "shareBalance": 1}}
    _seed_days(db, 15)
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))

    result = _claim(service)

    assert result.status == "claimed"
    assert result.diamond_balance == 20
    assert db.store["users/u1"]["streakBonusMilestone"] == 14
    ledger = [
        row
        for path, row in db.store.items()
        if path.startswith("walletTransactions/")
    ]
    assert ledger[0]["diamondAmount"] == 20

    again = _claim(service)
    assert again.status == "already_claimed"
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 20


def test_short_streak_writes_no_ledger() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {
        "wallet": {"diamondBalance": 4, "shareBalance": 1_000_000},
    }
    _seed_days(db, 6)
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))

    result = _claim(service)

    assert result.status == "not_eligible"
    assert result.diamond_balance == 4
    assert result.share_balance == 1_000_000
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 4
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 1_000_000
    assert "streakBonusMilestone" not in db.store["users/u1"]
    assert not any(path.startswith("walletTransactions/") for path in db.store)
