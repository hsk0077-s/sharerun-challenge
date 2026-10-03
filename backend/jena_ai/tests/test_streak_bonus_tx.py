"""Weekly streak DIA credit and its ledger row share one transaction."""

from types import SimpleNamespace

from app.services.economy_service import EconomyService
from app.services.secured_action_service import (
    SecuredActionService,
    _commit_streak_bonus_tx,
)
from test_redeem_referral import _MemoryDb, _MemoryTxn


def _claim(service: SecuredActionService):
    user_ref = service.firebase_service.db.collection("users").document("u1")
    return _commit_streak_bonus_tx.to_wrap(_MemoryTxn(), service, "u1", user_ref)


def test_streak_credits_ten_dia_once_per_week(monkeypatch) -> None:
    monkeypatch.setattr(
        EconomyService,
        "kst_week_key",
        lambda self, now=None: "2026-09-28",
    )
    db = _MemoryDb()
    db.store["users/u1"] = {
        "wallet": {"diamondBalance": 4, "shareBalance": 1_000_000},
    }
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))

    result = _claim(service)

    assert result.status == "claimed"
    assert result.diamond_balance == 14
    assert result.share_balance == 1_000_000
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 14
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 1_000_000
    assert db.store["users/u1"]["streakBonusWeekKey"] == "2026-09-28"
    ledger = [
        row
        for path, row in db.store.items()
        if path.startswith("walletTransactions/")
    ]
    assert len(ledger) == 1
    assert ledger[0]["type"] == "streak_bonus"
    assert ledger[0]["diamondAmount"] == 10
    assert ledger[0]["weekKey"] == "2026-09-28"

    again = _claim(service)
    assert again.status == "already_claimed"
    assert again.diamond_balance == 14
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 14
    assert (
        sum(1 for path in db.store if path.startswith("walletTransactions/"))
        == 1
    )

    monkeypatch.setattr(
        EconomyService,
        "kst_week_key",
        lambda self, now=None: "2026-10-05",
    )
    next_week = _claim(service)
    assert next_week.status == "claimed"
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 24
    assert db.store["users/u1"]["streakBonusWeekKey"] == "2026-10-05"
    assert (
        sum(1 for path in db.store if path.startswith("walletTransactions/"))
        == 2
    )
