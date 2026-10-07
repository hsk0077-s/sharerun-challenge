"""A verified run appends one company donation. Wallets are not debited."""

from datetime import datetime, timezone
from types import SimpleNamespace

from app.models.secured_actions import ValidateRunRequest
from app.models.validation_result import ValidationResult
from app.services.secured_action_service import (
    SecuredActionService,
    verified_run_donation_won,
)
from test_redeem_referral import _MemoryDb, _MemoryTxn

NOW = datetime(2026, 10, 6, 15, 0, tzinfo=timezone.utc)


def _service(db: _MemoryDb) -> SecuredActionService:
    return SecuredActionService(firebase_service=SimpleNamespace(db=db))


def _seed(db: _MemoryDb) -> None:
    db.store["users/u1"] = {
        "nickname": "달림이",
        "wallet": {
            "shareBalance": 40,
            "diamondBalance": 7,
            "valueTokenBalance": 3,
        },
    }


def _persist(
    db: _MemoryDb,
    activity_id: str,
    distance_km: float,
    *,
    verified: bool = True,
    reason: str = "ok",
) -> ValidationResult:
    service = _service(db)
    request = ValidateRunRequest(
        activity_id=activity_id,
        distance_km=distance_km,
        duration_seconds=600,
        gyro_stability_score=0.9,
    )
    result = ValidationResult(
        verified=verified,
        decision="verified" if verified else "rejected_unknown",
        reason=reason,
        value_token_reward=0,
        forfeit_deposit=False,
    )
    return service._persist_validation_tx(
        _MemoryTxn(),
        "u1",
        request,
        result,
        db.collection("activities").document(activity_id),
        db.collection("users").document("u1"),
        now=NOW,
    )


def _donations(db: _MemoryDb) -> list[tuple[str, dict]]:
    return [
        (path, row)
        for path, row in db.store.items()
        if path.startswith("donationLedger/")
    ]


def test_won_is_100_per_km_with_no_cap() -> None:
    assert verified_run_donation_won(1) == 100
    assert verified_run_donation_won(2.4) == 240
    assert verified_run_donation_won(12.5) == 1250
    assert verified_run_donation_won(0.004) == 0


def test_verified_run_appends_company_won_and_leaves_the_wallet() -> None:
    db = _MemoryDb()
    _seed(db)

    outcome = _persist(db, "act-1", 2.4)

    assert outcome.donation_counted is True
    assert outcome.company_donation_won == 240
    assert outcome.donation_reason == ""
    wallet = db.store["users/u1"]["wallet"]
    assert wallet["shareBalance"] == 40
    assert wallet["diamondBalance"] == 7
    assert wallet["valueTokenBalance"] >= 3
    assert "companyWon" not in wallet
    rows = _donations(db)
    assert len(rows) == 1
    path, row = rows[0]
    assert path == "donationLedger/verified_run_act-1"
    assert row["type"] == "verified_run_donation"
    assert row["companyWon"] == 240
    assert row["krwPerKm"] == 100
    assert row["sponsorName"] == "SRC"
    assert row["contributorName"] == "달림이"
    assert row["receiptIssued"] is False
    assert row["monthKey"] == "2026-10"
    assert row["uid"] == "u1"
    assert "valueAmount" not in row
    assert db.store["activities/act-1"]["donationCounted"] is True
    assert db.store["activities/act-1"]["companyDonationWon"] == 240
    assert not any(
        path.startswith("walletTransactions/")
        and isinstance(row, dict)
        and row.get("type") == "verified_run_donation"
        for path, row in db.store.items()
    )

    value_after = wallet["valueTokenBalance"]
    again = _persist(db, "act-1", 2.4)
    assert again.company_donation_won == 240
    assert again.donation_counted is True
    assert len(_donations(db)) == 1
    assert db.store["users/u1"]["wallet"]["valueTokenBalance"] == value_after
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 40

    second = _persist(db, "act-2", 12.5)
    assert second.company_donation_won == 1250
    assert len(_donations(db)) == 2
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 40
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 7


def test_unverified_run_records_no_donation() -> None:
    db = _MemoryDb()
    _seed(db)
    reason = "케이던스가 범위 밖입니다."

    outcome = _persist(db, "act-no", 3, verified=False, reason=reason)

    assert outcome.verified is False
    assert outcome.donation_counted is False
    assert outcome.company_donation_won == 0
    assert outcome.donation_reason == reason
    assert _donations(db) == []
    wallet = db.store["users/u1"]["wallet"]
    assert wallet == {
        "shareBalance": 40,
        "diamondBalance": 7,
        "valueTokenBalance": 3,
    }
    assert db.store["activities/act-no"]["donationCounted"] is False
    assert db.store["activities/act-no"]["companyDonationWon"] == 0

    replay = _persist(db, "act-no", 3, verified=False, reason=reason)
    assert replay.donation_counted is False
    assert replay.donation_reason == reason
    assert _donations(db) == []
