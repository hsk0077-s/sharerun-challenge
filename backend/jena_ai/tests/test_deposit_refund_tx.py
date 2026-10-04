"""Diamond deposit refunds return paid DIA to the paid bucket."""

from types import SimpleNamespace

from app.models.secured_actions import (
    JoinTournamentRequest,
    SettleTournamentFailureRequest,
)
from app.services.secured_action_service import (
    SecuredActionService,
    _commit_join_tx,
    _commit_settle_failure_tx,
)
from test_redeem_referral import _MemoryDb, _MemoryTxn


def _service(db: _MemoryDb) -> SecuredActionService:
    return SecuredActionService(firebase_service=SimpleNamespace(db=db))


def test_join_records_the_paid_and_free_deposit_split() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {
        "tier": 1,
        "wallet": {
            "shareBalance": 1000,
            "diamondBalance": 10,
            "freeDiamondBalance": 4,
            "paidDiamondBalance": 6,
        },
    }
    db.store["tournaments/t1"] = {
        "status": "recruiting",
        "requiredTier": 1,
        "entryFeeShare": 0,
        "diamondDepositRequired": 10,
        "participantCount": 0,
    }
    service = _service(db)
    user_ref = db.collection("users").document("u1")
    tournament_ref = db.collection("tournaments").document("t1")
    participant_ref = tournament_ref.collection("participants").document("u1")

    _commit_join_tx.to_wrap(
        _MemoryTxn(),
        service,
        "u1",
        JoinTournamentRequest(tournament_id="t1", diamond_deposit=10),
        user_ref,
        tournament_ref,
        participant_ref,
    )

    participant = db.store["tournaments/t1/participants/u1"]
    assert participant["diamondPaidDeposit"] == 6
    assert participant["diamondFreeDeposit"] == 4
    ledger = next(
        row for path, row in db.store.items() if path.startswith("walletTransactions/")
    )
    assert ledger["diamondAmount"] == -10
    assert ledger["shareAmount"] == 0
    wallet = db.store["users/u1"]["wallet"]
    assert wallet["paidDiamondBalance"] == 0
    assert wallet["freeDiamondBalance"] == 0


def test_mercy_refund_keeps_paid_dia_paid() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {
        "wallet": {
            "diamondBalance": 0,
            "freeDiamondBalance": 0,
            "paidDiamondBalance": 0,
        }
    }
    db.store["tournaments/room1"] = {"targetDistanceKm": 10}
    db.store["tournaments/room1/participants/u1"] = {
        "diamondDeposit": 10,
        "diamondPaidDeposit": 6,
        "diamondFreeDeposit": 4,
        "selectedCharity": "UNICEF",
    }
    service = _service(db)
    request = SettleTournamentFailureRequest(
        tournament_id="room1", distance_achieved_km=6
    )

    result = _commit_settle_failure_tx.to_wrap(
        _MemoryTxn(),
        service,
        "u1",
        request,
        db.collection("users").document("u1"),
        db.collection("tournaments").document("room1"),
        db.collection("tournaments").document("room1")
        .collection("participants")
        .document("u1"),
    )

    # 60% back. Paid is returned before free, so the 6 paid DIA stay paid.
    assert result.status == "mercy_settled"
    wallet = db.store["users/u1"]["wallet"]
    assert wallet["diamondBalance"] == 6
    assert wallet["paidDiamondBalance"] == 6
    assert wallet["freeDiamondBalance"] == 0
    ledger = next(
        row for path, row in db.store.items() if path.startswith("walletTransactions/")
    )
    assert ledger["diamondPaidAmount"] == 6
    assert ledger["diamondFreeAmount"] == 0
    assert ledger["diamondAmount"] == 6
    assert ledger["forfeitedDiamondAmount"] == 4


def test_forfeited_deposit_is_not_a_positive_ledger_credit() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {
        "wallet": {"diamondBalance": 90, "totalDonationValue": 1}
    }
    db.store["tournaments/room1/participants/u1"] = {
        "uid": "u1",
        "status": "joined",
        "diamondDeposit": 10,
        "selectedCharity": "UNICEF",
    }
    service = _service(db)

    service._forfeit_active_deposit_tx(
        _MemoryTxn(),
        "u1",
        db.collection("users").document("u1"),
        "act1",
    )

    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 90
    assert db.store["users/u1"]["wallet"]["totalDonationValue"] == 11
    ledger = next(
        row for path, row in db.store.items() if path.startswith("walletTransactions/")
    )
    assert ledger["type"] == "deposit_forfeiture_fraud"
    assert ledger["diamondAmount"] == 0
    assert ledger["forfeitedDiamondAmount"] == 10
