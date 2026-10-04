"""Referral apply and mercy settlement run inside a module transaction."""

from types import SimpleNamespace

from app.models.secured_actions import SettleTournamentFailureRequest
from app.services.secured_action_service import (
    SecuredActionResult,
    SecuredActionService,
    _commit_apply_referral_tx,
    _commit_settle_failure_tx,
)
from test_redeem_referral import _MemoryDb, _MemoryTxn


def _service(db: _MemoryDb) -> SecuredActionService:
    return SecuredActionService(firebase_service=SimpleNamespace(db=db))


def test_handlers_are_module_transactions_not_decorated_methods() -> None:
    assert not hasattr(SecuredActionService._apply_referral_code_tx, "to_wrap")
    assert not hasattr(SecuredActionService._settle_tournament_failure_tx, "to_wrap")
    assert hasattr(_commit_apply_referral_tx, "to_wrap")
    assert hasattr(_commit_settle_failure_tx, "to_wrap")


def test_apply_referral_calls_module_wrapper(monkeypatch) -> None:
    db = _MemoryDb()
    service = _service(db)
    seen: dict = {}

    def fake(transaction, service_arg, uid, code, user_ref):
        seen["service"] = service_arg
        seen["uid"] = uid
        seen["code"] = code
        return SecuredActionResult(accepted=True, status="applied", reason="ok")

    monkeypatch.setattr(
        "app.services.secured_action_service._commit_apply_referral_tx",
        fake,
    )

    result = service.apply_referral_code("u2", " ab12 ")

    assert result.status == "applied"
    assert seen["service"] is service
    assert seen["uid"] == "u2"
    assert seen["code"] == "AB12"


def test_apply_referral_saves_referrer_once() -> None:
    db = _MemoryDb()
    db.store["users/u2"] = {"economy": {"trialRunCount": 1}, "wallet": {}}
    db.store["users/u1"] = {"economy": {"referralCode": "AB12"}}
    service = _service(db)
    user_ref = db.collection("users").document("u2")

    result = _commit_apply_referral_tx.to_wrap(
        _MemoryTxn(), service, "u2", "AB12", user_ref
    )

    assert result.status == "applied"
    assert db.store["users/u2"]["economy"]["referredByUid"] == "u1"
    assert db.store["users/u2"]["economy"]["trialRunCount"] == 1

    again = _commit_apply_referral_tx.to_wrap(
        _MemoryTxn(), service, "u2", "AB12", user_ref
    )
    assert again.status == "already_applied"


def test_settle_failure_calls_module_wrapper(monkeypatch) -> None:
    db = _MemoryDb()
    service = _service(db)
    seen: dict = {}

    def fake(transaction, service_arg, uid, request, user_ref, tournament_ref, participant_ref):
        seen["service"] = service_arg
        seen["uid"] = uid
        seen["tournament"] = request.tournament_id
        return SecuredActionResult(accepted=True, status="mercy_settled", reason="ok")

    monkeypatch.setattr(
        "app.services.secured_action_service._commit_settle_failure_tx",
        fake,
    )
    request = SettleTournamentFailureRequest(
        tournament_id="room1", distance_achieved_km=1
    )

    result = service.settle_tournament_failure("u1", request)

    assert result.status == "mercy_settled"
    assert seen["service"] is service
    assert seen["uid"] == "u1"
    assert seen["tournament"] == "room1"


def test_settle_failure_returns_partial_deposit() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {"wallet": {"diamondBalance": 4}}
    db.store["tournaments/room1"] = {"targetDistanceKm": 10}
    db.store["tournaments/room1/participants/u1"] = {
        "diamondDeposit": 10,
        "selectedCharity": "UNICEF",
    }
    service = _service(db)
    request = SettleTournamentFailureRequest(
        tournament_id="room1", distance_achieved_km=6
    )
    user_ref = db.collection("users").document("u1")
    tournament_ref = db.collection("tournaments").document("room1")
    participant_ref = tournament_ref.collection("participants").document("u1")

    result = _commit_settle_failure_tx.to_wrap(
        _MemoryTxn(),
        service,
        "u1",
        request,
        user_ref,
        tournament_ref,
        participant_ref,
    )

    assert result.status == "mercy_settled"
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 10
    assert db.store["tournaments/room1/participants/u1"]["mercySettled"] is True
    ledger = [
        row
        for path, row in db.store.items()
        if path.startswith("walletTransactions/")
    ]
    assert len(ledger) == 1
    assert ledger[0]["type"] == "mercy_rule_donation"
