"""Coach+ is an account flag backed by a Play subscription. It never moves SHARE, DIA or VALUE."""

from datetime import datetime, timedelta, timezone
from types import SimpleNamespace

import pytest
from fastapi import HTTPException

from app.services.secured_action_service import (
    SecuredActionService,
    _commit_coach_plus_tx,
)
from test_redeem_referral import _MemoryDb, _MemoryTxn

TOKEN = "play-subscription-token-1"


def _service(db: _MemoryDb) -> SecuredActionService:
    return SecuredActionService(firebase_service=SimpleNamespace(db=db))


def _activate(
    db: _MemoryDb,
    *,
    uid: str = "u1",
    product_id: str = "coach_plus_monthly",
    token_hash: str = "hash1",
    until: datetime | None = None,
    order_id: str | None = "GPA.1",
):
    until = until or datetime.now(timezone.utc) + timedelta(days=30)
    return _commit_coach_plus_tx.to_wrap(
        _MemoryTxn(),
        _service(db),
        uid,
        product_id,
        db.collection("users").document(uid),
        db.collection("playSubscriptions").document(token_hash),
        token_hash,
        until,
        order_id,
    )


def test_coach_plus_writes_entitlement_without_a_ledger_row() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {
        "wallet": {
            "shareBalance": 1000,
            "diamondBalance": 8,
            "valueTokenBalance": 3,
        }
    }
    until = datetime(2030, 1, 1, tzinfo=timezone.utc)

    result = _activate(db, until=until)

    assert result.status == "coach_plus_active"
    assert db.store["users/u1"]["wallet"] == {
        "shareBalance": 1000,
        "diamondBalance": 8,
        "valueTokenBalance": 3,
    }
    entitlement = db.store["users/u1"]["coachPlus"]
    assert entitlement["productId"] == "coach_plus_monthly"
    # The expiry is the one Play reported, not "now plus a fixed number of days".
    assert datetime.fromisoformat(entitlement["activeUntil"]) == until
    assert entitlement["tokenHash"] == "hash1"
    assert not any(path.startswith("walletTransactions/") for path in db.store)


def test_subscription_record_keeps_who_owns_the_token() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {"wallet": {}}
    _activate(db, order_id="GPA.42")

    record = db.store["playSubscriptions/hash1"]
    assert record["uid"] == "u1"
    assert record["productId"] == "coach_plus_monthly"
    assert record["orderId"] == "GPA.42"


def test_a_token_used_by_another_account_is_rejected_and_writes_nothing() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {"wallet": {}}
    db.store["users/u2"] = {"wallet": {}}
    _activate(db, uid="u1")

    with pytest.raises(HTTPException) as raised:
        _activate(db, uid="u2")

    assert raised.value.status_code == 409
    assert "coachPlus" not in db.store["users/u2"]
    assert db.store["playSubscriptions/hash1"]["uid"] == "u1"


def test_the_same_account_can_renew_and_the_expiry_moves_forward() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {"wallet": {}}
    first = datetime(2030, 1, 1, tzinfo=timezone.utc)
    later = datetime(2030, 2, 1, tzinfo=timezone.utc)
    _activate(db, until=first)
    _activate(db, until=later)

    until = datetime.fromisoformat(db.store["users/u1"]["coachPlus"]["activeUntil"])
    assert until == later


def test_a_second_subscription_never_shortens_access_already_paid_for() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {"wallet": {}}
    yearly_end = datetime(2031, 1, 1, tzinfo=timezone.utc)
    monthly_end = datetime(2030, 2, 1, tzinfo=timezone.utc)
    _activate(db, product_id="coach_plus_yearly", token_hash="year", until=yearly_end)
    _activate(db, product_id="coach_plus_monthly", token_hash="month", until=monthly_end)

    entitlement = db.store["users/u1"]["coachPlus"]
    assert entitlement["productId"] == "coach_plus_yearly"
    assert datetime.fromisoformat(entitlement["activeUntil"]) == yearly_end
    assert db.store["playSubscriptions/month"]["uid"] == "u1"


def test_missing_user_writes_nothing() -> None:
    db = _MemoryDb()
    with pytest.raises(HTTPException) as raised:
        _activate(db)
    assert raised.value.status_code == 404
    assert "playSubscriptions/hash1" not in db.store


def test_unknown_coach_plus_product_writes_nothing() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {"wallet": {"shareBalance": 4}}

    with pytest.raises(HTTPException) as exc_info:
        _service(db).activate_coach_plus("u1", "share_pack", TOKEN)

    assert exc_info.value.status_code == 400
    assert "coachPlus" not in db.store["users/u1"]
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 4


def test_without_play_verification_nothing_is_granted(monkeypatch) -> None:
    monkeypatch.delenv("GOOGLE_PLAY_PACKAGE_NAME", raising=False)
    monkeypatch.delenv("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON", raising=False)
    db = _MemoryDb()
    db.store["users/u1"] = {"wallet": {}}

    with pytest.raises(HTTPException) as raised:
        _service(db).activate_coach_plus("u1", "coach_plus_monthly", TOKEN)

    assert raised.value.status_code == 503
    assert "coachPlus" not in db.store["users/u1"]
    assert "playSubscriptions" not in "".join(db.store)


def test_a_verified_token_grants_the_expiry_play_reported(monkeypatch) -> None:
    until = datetime(2030, 5, 5, tzinfo=timezone.utc)
    monkeypatch.setattr(
        "app.services.secured_action_service.verify_play_subscription",
        lambda product_id, token, uid=None: {"orderId": "GPA.7", "expiresAt": until, "state": "x"},
    )
    db = _MemoryDb()
    db.store["users/u1"] = {"wallet": {}}
    service = _service(db)
    # The in-memory database has no real transaction, so run the commit body directly.
    service.firebase_service.db.transaction = lambda: _MemoryTxn()
    monkeypatch.setattr(
        "app.services.secured_action_service._commit_coach_plus_tx",
        lambda *args: _commit_coach_plus_tx.to_wrap(*args),
    )

    result = service.activate_coach_plus("u1", "coach_plus_yearly", TOKEN)

    assert result.status == "coach_plus_active"
    entitlement = db.store["users/u1"]["coachPlus"]
    assert entitlement["productId"] == "coach_plus_yearly"
    assert datetime.fromisoformat(entitlement["activeUntil"]) == until
