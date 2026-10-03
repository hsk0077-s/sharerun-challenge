"""Tournament entry debits SHARE in the same transaction as its ledger row."""

from types import SimpleNamespace

from app.models.secured_actions import JoinTournamentRequest
from app.services.secured_action_service import SecuredActionService, _commit_join_tx
from test_redeem_referral import _MemoryDb, _MemoryTxn


def test_join_writes_negative_ledger_with_the_debit() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {
        "tier": 1,
        "wallet": {"shareBalance": 1000, "diamondBalance": 8, "valueTokenBalance": 3},
    }
    db.store["tournaments/t1"] = {
        "status": "recruiting",
        "requiredTier": 1,
        "entryFeeShare": 200,
        "diamondDepositRequired": 0,
        "participantCount": 0,
    }
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))
    user_ref = db.collection("users").document("u1")
    tournament_ref = db.collection("tournaments").document("t1")
    participant_ref = tournament_ref.collection("participants").document("u1")
    request = JoinTournamentRequest(tournament_id="t1", diamond_deposit=0)

    result = _commit_join_tx.to_wrap(
        _MemoryTxn(),
        service,
        "u1",
        request,
        user_ref,
        tournament_ref,
        participant_ref,
    )

    assert result.status == "joined"
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 800
    ledger = next(
        row for path, row in db.store.items() if path.startswith("walletTransactions/")
    )
    assert ledger["type"] == "tournament_entry"
    assert ledger["shareAmount"] == -200
    assert ledger["diamondAmount"] == 0

    again = _commit_join_tx.to_wrap(
        _MemoryTxn(),
        service,
        "u1",
        request,
        user_ref,
        tournament_ref,
        participant_ref,
    )
    assert again.status == "already_joined"
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 800
    assert (
        sum(
            1
            for path in db.store
            if path.startswith("walletTransactions/")
        )
        == 1
    )
