"""Company prize-race settlement: bonus DIA, SHARE, VALUE, cap, km donation."""

from copy import deepcopy
from datetime import datetime, timedelta, timezone
import logging
from types import SimpleNamespace

from fastapi import HTTPException
from fastapi.testclient import TestClient
import pytest

from app.main import app
from app.models.secured_actions import ValidateRunRequest
from app.models.validation_result import ValidationResult
from app.routers import ops_router
from app.services.company_tournament_config import resolve_company_tournament_config
from app.services.company_tournament_settlement import (
    plan_payouts,
    settle_company_prize_race,
)
from app.services.ops_service import OpsService
from app.services.secured_action_service import SecuredActionService
from test_redeem_referral import _MemoryDb, _MemoryTxn

NOW = datetime(2026, 10, 4, 3, 0, tzinfo=timezone.utc)


def _wallet() -> dict:
    return {
        "identityVerified": True,
        "authCreatedAt": (NOW - timedelta(days=30)).isoformat(),
        "wallet": {
            "shareBalance": 10,
            "freeShareBalance": 4,
            "paidShareBalance": 6,
            "diamondBalance": 60,
            "freeDiamondBalance": 10,
            "paidDiamondBalance": 50,
            "valueTokenBalance": 5,
        }
    }


def _settle(db: _MemoryDb, tournament_id: str = "race"):
    return settle_company_prize_race(db, tournament_id, now=NOW)


def _seed_finishers(db: _MemoryDb, tournament_id: str, rows: list[tuple[str, dict]], **race):
    tournament = {
        "status": "active",
        "prizeTier": "beginner",
        "targetDistanceKm": 1,
    }
    tournament.update(race)
    db.store[f"tournaments/{tournament_id}"] = tournament
    for uid, participant in rows:
        db.store[f"tournaments/{tournament_id}/participants/{uid}"] = participant
        db.store.setdefault(f"users/{uid}", _wallet())
        for index in range(3):
            db.store.setdefault(
                f"activities/{uid}-verified-{index}",
                {
                    "userId": uid,
                    "jenaVerified": True,
                    "completedAt": (NOW - timedelta(days=1)).isoformat(),
                },
            )


def _finisher(uid: str, duration: int, *, distance: float = 3, entry_fee: int = 0) -> dict:
    return {
        "uid": uid,
        "status": "joined",
        "verifiedFinish": True,
        "distanceKm": distance,
        "durationSeconds": duration,
        "entryFeeShare": entry_fee,
    }


def _wallet_rows(db: _MemoryDb) -> list[dict]:
    return [
        row
        for path, row in db.store.items()
        if path.startswith("walletTransactions/")
    ]


def test_plan_pays_config_ranks_then_share_below_them() -> None:
    config = resolve_company_tournament_config(None)
    finishers = [
        {"uid": f"u{index:02d}", "distance_km": 5, "duration_seconds": index}
        for index in range(1, 13)
    ]

    payouts = plan_payouts(config, "mid", finishers)

    assert [payout.uid for payout in payouts] == [f"u{index:02d}" for index in range(1, 13)]
    assert payouts[0].dia_requested == 3_000
    assert payouts[0].share == 0
    assert payouts[9].dia_requested == 200
    assert payouts[10].dia_requested == 0
    assert payouts[10].share == 20_000
    assert payouts[11].share == 0
    assert {payout.value for payout in payouts} == {50}
    assert {payout.donation_krw for payout in payouts} == {500}


def test_equal_times_rank_by_uid() -> None:
    config = resolve_company_tournament_config(None)
    payouts = plan_payouts(
        config,
        "beginner",
        [
            {"uid": "m", "distance_km": 1, "duration_seconds": 100},
            {"uid": "a", "distance_km": 1, "duration_seconds": 100},
        ],
    )

    assert [payout.uid for payout in payouts] == ["a", "m"]
    assert [payout.dia_requested for payout in payouts] == [1_000, 500]
    assert [payout.share for payout in payouts] == [0, 0]


def test_settlement_pays_bonus_dia_share_value_and_km_donation_once() -> None:
    db = _MemoryDb()
    rows = []
    for index in range(1, 11):
        uid = f"u{index:02d}"
        rows.append(
            (
                uid,
                _finisher(uid, index * 100, entry_fee=50_000 if index == 1 else 7),
            )
        )
    rows.append(("dnf", _finisher("dnf", 50, distance=0.4, entry_fee=9_999)))
    rows.append(
        (
            "joined",
            {"uid": "joined", "status": "joined", "entryFeeShare": 600, "distanceKm": 3},
        )
    )
    _seed_finishers(db, "race", rows)

    result = _settle(db)

    assert result.status == "settled"
    assert result.finisher_count == 10
    assert result.paid_dia == 1_800
    assert result.held_dia == 0
    assert result.share_paid == 10_000
    assert result.value_paid == 300
    assert result.donation_krw == 3_000
    assert result.paid_dia != sum(
        int(row.get("entryFeeShare") or 0)
        for _, row in rows
    )
    race = db.store["tournaments/race"]
    assert race["status"] == "finished"
    assert race["prizeSettled"] is True
    assert race["prizeSettlement"]["fundedByEntryFees"] is False

    winner = db.store["users/u01"]["wallet"]
    assert winner["diamondBalance"] == 1_060
    assert winner["freeDiamondBalance"] == 1_010
    assert winner["paidDiamondBalance"] == 50
    assert winner["shareBalance"] == 10
    assert winner["valueTokenBalance"] == 35
    assert "totalDonationValue" not in winner
    dia = db.store["walletTransactions/tournament_prize_race_u01"]
    assert dia["type"] == "tournament_prize_dia"
    assert dia["diamondAmount"] == 1_000
    assert dia["diamondFreeAmount"] == 1_000
    assert dia["diamondPaidAmount"] == 0
    assert dia["bonusDia"] is True
    assert dia["fundedByEntryFees"] is False
    assert dia["prizeStatus"] == "paid"
    assert "walletTransactions/tournament_share_race_u01" not in db.store

    share_user = db.store["users/u04"]["wallet"]
    assert share_user["shareBalance"] == 10_010
    assert share_user["freeShareBalance"] == 10_004
    assert share_user["paidShareBalance"] == 6
    assert share_user["diamondBalance"] == 60
    share = db.store["walletTransactions/tournament_share_race_u04"]
    assert share["type"] == "tournament_top_percent_share"
    assert share["shareAmount"] == 10_000
    assert share["fundedByEntryFees"] is False
    assert db.store["tournaments/race/participants/u04"]["finishRank"] == 4

    plain = db.store["users/u10"]["wallet"]
    assert plain["shareBalance"] == 10
    assert plain["diamondBalance"] == 60
    assert plain["valueTokenBalance"] == 35
    assert db.store["walletTransactions/tournament_value_race_u10"]["valueAmount"] == 30
    assert "walletTransactions/tournament_prize_race_u10" not in db.store

    assert db.store["users/dnf"]["wallet"]["diamondBalance"] == 60
    assert db.store["users/joined"]["wallet"] == _wallet()["wallet"]
    assert "donationLedger/tournament_km_race_dnf" not in db.store
    assert "donationLedger/tournament_km_race_joined" not in db.store
    donation = db.store["donationLedger/tournament_km_race_u01"]
    assert donation["type"] == "tournament_km_donation"
    assert donation["companyWon"] == 300
    assert donation["krwPerKm"] == 100
    assert donation["receiptIssued"] is False
    assert db.store["companyDonationPools/2026-10"]["totalKrw"] == 3_000
    assert db.store["companyPrizePools/2026-10"]["paidDia"] == 1_800
    assert len(_wallet_rows(db)) == 14

    balances = deepcopy(db.store["users/u01"]["wallet"])
    pool = db.store["companyPrizePools/2026-10"]["paidDia"]
    again = _settle(db)
    assert again.status == "already_settled"
    assert again.paid_dia == 1_800
    assert db.store["users/u01"]["wallet"] == balances
    assert db.store["companyPrizePools/2026-10"]["paidDia"] == pool
    assert db.store["companyDonationPools/2026-10"]["totalKrw"] == 3_000
    assert len(_wallet_rows(db)) == 14

    db.store["tournaments/race"]["prizeSettled"] = False
    db.store["tournaments/race"].pop("prizeSettlement")
    retry = _settle(db)
    assert retry.status == "settled"
    assert db.store["users/u01"]["wallet"] == balances
    assert db.store["companyPrizePools/2026-10"]["paidDia"] == pool
    assert len(_wallet_rows(db)) == 14


def test_monthly_cap_holds_the_overflow_and_logs_it(caplog: pytest.LogCaptureFixture) -> None:
    db = _MemoryDb()
    db.store["config/company_tournament"] = {"monthlyCompanyPrizeCapDia": 1_000}
    _seed_finishers(
        db,
        "race",
        [
            ("u1", _finisher("u1", 10)),
            ("u2", _finisher("u2", 20)),
        ],
    )

    with caplog.at_level(logging.WARNING):
        result = _settle(db)

    assert result.paid_dia == 1_000
    assert result.held_dia == 500
    assert "monthly_company_prize_cap" in caplog.text
    assert "u2" in caplog.text
    assert db.store["users/u1"]["wallet"]["freeDiamondBalance"] == 1_010
    assert db.store["users/u2"]["wallet"]["diamondBalance"] == 60
    held = db.store["walletTransactions/tournament_prize_race_u2"]
    assert held["prizeStatus"] == "held"
    assert held["diamondAmount"] == 0
    assert held["requestedDia"] == 500
    assert held["heldDia"] == 500
    assert held["capReason"] == "monthly_company_prize_cap"
    assert held["diamondFreeAmount"] == 0
    assert db.store["users/u2"]["wallet"]["valueTokenBalance"] == 35
    assert db.store["donationLedger/tournament_km_race_u2"]["companyWon"] == 300
    assert db.store["companyPrizePools/2026-10"]["paidDia"] == 1_000


def test_later_race_is_capped_by_dia_already_reserved_this_month() -> None:
    db = _MemoryDb()
    db.store["config/company_tournament"] = {"monthlyCompanyPrizeCapDia": 1_200}
    _seed_finishers(db, "first", [("u1", _finisher("u1", 10))])
    _seed_finishers(db, "second", [("u2", _finisher("u2", 10))])

    first = _settle(db, "first")
    second = _settle(db, "second")

    assert first.paid_dia == 1_000
    assert second.paid_dia == 200
    assert second.held_dia == 800
    assert second.reason.startswith("Settled.")
    capped = db.store["walletTransactions/tournament_prize_second_u2"]
    assert capped["prizeStatus"] == "capped"
    assert capped["diamondAmount"] == 200
    assert capped["heldDia"] == 800
    assert capped["capReason"] == "monthly_company_prize_cap"
    assert db.store["users/u2"]["wallet"]["freeDiamondBalance"] == 210
    assert db.store["users/u2"]["wallet"]["paidDiamondBalance"] == 50
    assert db.store["companyPrizePools/2026-10"]["paidDia"] == 1_200

    replay = _settle(db, "first")
    assert replay.status == "already_settled"
    assert db.store["companyPrizePools/2026-10"]["paidDia"] == 1_200
    assert db.store["users/u2"]["wallet"]["diamondBalance"] == 260


def test_settle_rejects_races_that_are_not_ready() -> None:
    missing = _MemoryDb()
    with pytest.raises(HTTPException) as exc_info:
        _settle(missing)
    assert exc_info.value.status_code == 404

    recruiting = _MemoryDb()
    _seed_finishers(recruiting, "race", [("u1", _finisher("u1", 10))], status="recruiting")
    with pytest.raises(HTTPException) as exc_info:
        _settle(recruiting)
    assert exc_info.value.status_code == 400
    assert recruiting.store["users/u1"]["wallet"]["diamondBalance"] == 60

    plain = _MemoryDb()
    _seed_finishers(plain, "race", [("u1", _finisher("u1", 10))], prizeTier=None)
    del plain.store["tournaments/race"]["prizeTier"]
    with pytest.raises(HTTPException) as exc_info:
        _settle(plain)
    assert exc_info.value.detail == "Not a company prize race."

    unknown = _MemoryDb()
    _seed_finishers(unknown, "race", [("u1", _finisher("u1", 10))], prizeTier="legend")
    with pytest.raises(HTTPException) as exc_info:
        _settle(unknown)
    assert exc_info.value.detail == "Unknown prize tier."


def test_missing_finisher_account_does_not_mark_the_race_settled() -> None:
    db = _MemoryDb()
    _seed_finishers(db, "race", [("ghost", _finisher("ghost", 10))])
    del db.store["users/ghost"]

    with pytest.raises(HTTPException) as exc_info:
        _settle(db)

    assert exc_info.value.status_code == 409
    assert db.store["tournaments/race"].get("prizeSettled") is not True
    assert _wallet_rows(db) == []


def test_finished_race_with_no_verified_finishers_settles_empty() -> None:
    db = _MemoryDb()
    _seed_finishers(
        db,
        "race",
        [("u1", {"uid": "u1", "status": "joined"})],
        status="finished",
    )

    result = _settle(db)

    assert result.status == "settled"
    assert result.finisher_count == 0
    assert result.paid_dia == 0
    assert result.donation_krw == 0
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 60
    assert _wallet_rows(db) == []
    assert db.store["companyDonationPools/2026-10"]["totalKrw"] == 0


def test_settle_route_uses_the_ops_secret(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("OPS_ADMIN_SECRET", "ops-secret")
    db = _MemoryDb()
    _seed_finishers(db, "race", [("u1", _finisher("u1", 10))], status="finished")
    original = ops_router.service
    ops_router.service = OpsService(firebase_service=SimpleNamespace(db=db))
    try:
        client = TestClient(app)
        denied = client.post(
            "/ops/tournaments/race/settle",
            headers={"x-ops-admin-secret": "nope"},
        )
        allowed = client.post(
            "/ops/tournaments/race/settle",
            headers={"x-ops-admin-secret": "ops-secret"},
        )
    finally:
        ops_router.service = original

    assert denied.status_code == 401
    assert allowed.status_code == 200
    assert allowed.json()["paid_dia"] == 1000
    assert allowed.json()["status"] == "settled"
    assert db.store["users/u1"]["wallet"]["freeDiamondBalance"] == 1_010


def test_verified_prize_finish_keeps_the_faster_time() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet()
    db.store["tournaments/race"] = {
        "prizeTier": "beginner",
        "targetDistanceKm": 1,
        "status": "active",
    }
    db.store["tournaments/race/participants/u1"] = {"uid": "u1", "status": "joined"}
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))

    def persist(activity_id: str, distance: float, duration: int, *, verified: bool = True) -> None:
        request = ValidateRunRequest(
            activity_id=activity_id,
            distance_km=distance,
            duration_seconds=duration,
            gyro_stability_score=0.9,
            tournament_id="race",
        )
        result = ValidationResult(
            verified=verified,
            decision="verified" if verified else "rejected",
            reason="ok",
            value_token_reward=10 if verified else 0,
            forfeit_deposit=False,
        )
        service._persist_validation_tx(
            _MemoryTxn(),
            "u1",
            request,
            result,
            db.collection("activities").document(activity_id),
            db.collection("users").document("u1"),
        )

    persist("slow", 2, 500)
    assert db.store["tournaments/race/participants/u1"]["durationSeconds"] == 500
    persist("slower", 2, 700)
    assert db.store["tournaments/race/participants/u1"]["durationSeconds"] == 500
    assert db.store["tournaments/race/participants/u1"]["finishActivityId"] == "slow"
    persist("short", 0.5, 100)
    assert db.store["tournaments/race/participants/u1"]["distanceKm"] == 2
    persist("fast", 2, 400)
    assert db.store["tournaments/race/participants/u1"]["durationSeconds"] == 400
    assert db.store["tournaments/race/participants/u1"]["verifiedFinish"] is True
    persist("cheat", 2, 50, verified=False)
    assert db.store["tournaments/race/participants/u1"]["durationSeconds"] == 400

    db.store["tournaments/race"]["prizeSettled"] = True
    persist("late", 2, 10)
    assert db.store["tournaments/race/participants/u1"]["durationSeconds"] == 400

    other = _MemoryDb()
    other.store["users/u1"] = _wallet()
    other.store["tournaments/plain"] = {"status": "active", "targetDistanceKm": 1}
    other.store["tournaments/plain/participants/u1"] = {"uid": "u1", "status": "joined"}
    request = ValidateRunRequest(
        activity_id="plain",
        distance_km=2,
        duration_seconds=300,
        gyro_stability_score=0.9,
        tournament_id="plain",
    )
    SecuredActionService(firebase_service=SimpleNamespace(db=other))._persist_validation_tx(
        _MemoryTxn(),
        "u1",
        request,
        ValidationResult(
            verified=True,
            decision="verified",
            reason="ok",
            value_token_reward=10,
            forfeit_deposit=False,
        ),
        other.collection("activities").document("plain"),
        other.collection("users").document("u1"),
    )
    assert "verifiedFinish" not in other.store["tournaments/plain/participants/u1"]


def _claim_race(days: int, runs: int, *, identity: bool = True):
    db = _MemoryDb()
    _seed_finishers(
        db,
        "race",
        [("u1", _finisher("u1", 10)), ("u2", _finisher("u2", 20))],
    )
    db.store["users/u1"]["authCreatedAt"] = (NOW - timedelta(days=days)).isoformat()
    db.store["users/u1"]["identityVerified"] = identity
    for index in range(runs, 3):
        del db.store[f"activities/u1-verified-{index}"]
    return db


def test_thirteen_day_account_keeps_rank_and_receives_no_dia() -> None:
    young = _claim_race(13, 3)
    old = _claim_race(14, 3)

    blocked = _settle(young)
    allowed = _settle(old)

    assert blocked.paid_dia == 500
    assert young.store["tournaments/race/participants/u1"]["finishRank"] == 1
    assert young.store["tournaments/race/participants/u1"]["prizeDiaPaid"] == 0
    assert (
        young.store["tournaments/race/participants/u1"]["prizeIneligibleReason"]
        == "account_too_new"
    )
    assert young.store["users/u1"]["wallet"]["diamondBalance"] == 60
    assert "walletTransactions/tournament_prize_race_u1" not in young.store
    assert young.store["users/u2"]["wallet"]["diamondBalance"] == 560
    assert young.store["walletTransactions/tournament_prize_race_u2"]["diamondAmount"] == 500
    assert young.store["companyPrizePools/2026-10"]["paidDia"] == 500
    assert young.store["walletTransactions/tournament_value_race_u1"]["valueAmount"] == 30

    assert allowed.paid_dia == 1_500
    assert old.store["users/u1"]["wallet"]["diamondBalance"] == 1_060
    assert old.store["tournaments/race/participants/u1"].get("prizeIneligibleReason") is None


def test_two_verified_runs_block_dia_and_three_do_not() -> None:
    short = _claim_race(30, 2)
    enough = _claim_race(30, 3)

    blocked = _settle(short)
    allowed = _settle(enough)

    assert blocked.paid_dia == 500
    assert (
        short.store["tournaments/race/participants/u1"]["prizeIneligibleReason"]
        == "not_enough_verified_runs"
    )
    assert short.store["users/u1"]["wallet"]["diamondBalance"] == 60
    assert "walletTransactions/tournament_prize_race_u1" not in short.store
    assert short.store["users/u2"]["wallet"]["freeDiamondBalance"] == 510
    assert allowed.paid_dia == 1_500


def test_unverified_identity_is_not_paid_and_resettle_does_not_double_pay() -> None:
    db = _claim_race(30, 3, identity=False)
    first = _settle(db)
    second_balance = db.store["users/u2"]["wallet"]["diamondBalance"]
    first_balance = db.store["users/u1"]["wallet"]["diamondBalance"]
    pool = db.store["companyPrizePools/2026-10"]["paidDia"]

    assert first.paid_dia == 500
    assert (
        db.store["tournaments/race/participants/u1"]["prizeIneligibleReason"]
        == "not_identity_verified"
    )
    assert first_balance == 60
    assert "walletTransactions/tournament_prize_race_u1" not in db.store

    db.store["tournaments/race"]["prizeSettled"] = False
    db.store["tournaments/race"].pop("prizeSettlement")
    again = _settle(db)

    assert again.paid_dia == 500
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == first_balance
    assert db.store["users/u2"]["wallet"]["diamondBalance"] == second_balance
    assert db.store["companyPrizePools/2026-10"]["paidDia"] == pool
    assert "walletTransactions/tournament_prize_race_u1" not in db.store
