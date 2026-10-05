"""Company prize-race config defaults, Firestore overlay, and read route."""

from datetime import datetime, timedelta, timezone
from types import SimpleNamespace

from fastapi.testclient import TestClient

from app.constants.economy_constants import SRV_TOKENS_PER_KM
from app.main import app
from app.routers import secured_action_router
from app.services.auth_service import require_uid
from app.services.company_tournament_config import (
    prize_claim_reason,
    resolve_company_tournament_config,
    ticket_reward_for_rank,
    ticket_reward_label,
    ticket_seat_cap,
)
from app.services.secured_action_service import SecuredActionService
from test_redeem_referral import _MemoryDb


def test_defaults_match_the_prize_race_decision() -> None:
    config = resolve_company_tournament_config(None)

    assert config["source"] == "defaults"
    assert config["id"] == "company_tournament"
    assert config["prizesFundedByEntryFees"] is False
    assert config["entryFeeRole"] == "admission_only"
    assert config["diaKrw"] == 100
    assert config["companyDonationKrwPerKm"] == 100
    assert config["monthlyCompanyPrizeCapDia"] == 120_000
    assert config["finisherValueRule"] == "existing_srv_per_km"
    assert config["finisherValueTokensPerKm"] == SRV_TOKENS_PER_KM
    assert config["topPercent"] == 10
    assert config["topPercentExcludesPrizeRanks"] is True
    assert config["requireIdentityVerification"] is False
    assert config["beginnerFreeEntryCount"] == 2
    assert config["weeklyEntriesPerTier"] == 1
    assert config["prizeClaimMinAccountAgeDays"] == 14
    assert config["prizeClaimMinVerifiedRuns"] == 3
    assert config["prizeClaimVerifiedRunWindowDays"] == 14
    assert config["finalFrequency"] == "season"
    assert config["finalCountsTowardMonthlyCap"] is False

    beginner = config["tiers"]["beginner"]
    assert beginner["labelKo"] == "초급"
    assert beginner["distanceLabel"] == "1-3km"
    assert beginner["entryShare"] == 300
    assert beginner["freeTicketCost"] == 1
    assert beginner["minEntrants"] == 30
    assert beginner["targetEntrants"] == 100
    assert beginner["maxEntrants"] == 500
    assert beginner["top10PercentShare"] == 10_000
    assert beginner["prizeDiaByRank"] == {"1": 1_000, "2": 500, "3": 300}

    mid = config["tiers"]["mid"]
    assert mid["entryShare"] == 1_200
    assert mid["freeTicketCost"] == 1
    assert mid["prizeDiaByRank"]["4"] == 500
    assert mid["prizeDiaByRank"]["6"] == 100
    assert mid["top10PercentShare"] == 20_000
    assert (mid["minEntrants"], mid["targetEntrants"], mid["maxEntrants"]) == (
        50,
        200,
        1_000,
    )

    advanced = config["tiers"]["advanced"]
    assert advanced["entryShare"] == 2_400
    assert advanced["freeTicketCost"] == 2
    assert advanced["prizeDiaByRank"]["1"] == 5_000
    assert advanced["prizeDiaByRank"]["10"] == 200
    assert advanced["targetEntrants"] == 250

    half = config["tiers"]["half"]
    assert half["labelKo"] == "하프"
    assert half["entryShare"] == 4_200
    assert half["freeTicketCost"] == 3
    assert half["prizeDiaByRank"]["1"] == 10_000
    assert (half["minEntrants"], half["targetEntrants"], half["maxEntrants"]) == (
        50,
        150,
        500,
    )

    final = config["tiers"]["final"]
    assert final["entryShare"] == 0
    assert final["freeTicketCost"] == 0
    assert final["requiresSeasonQualification"] is True
    assert final["prizeDiaByRank"]["1"] == 30_000
    assert final["prizeDiaByRank"]["6"] == 3_000
    assert final["top10PercentShare"] == 100_000
    assert (final["minEntrants"], final["targetEntrants"], final["maxEntrants"]) == (
        64,
        96,
        128,
    )


def test_firestore_overlay_keeps_invalid_fields_on_defaults() -> None:
    config = resolve_company_tournament_config(
        {
            "prizesFundedByEntryFees": True,
            "entryFeeRole": "prize_pool",
            "companyDonationKrwPerKm": -5,
            "monthlyCompanyPrizeCapDia": True,
            "tiers": {
                "beginner": {
                    "entryShare": 50,
                    "freeTicketCost": "9",
                    "maxEntrants": 10,
                    "prizeDiaByRank": {"1": 9, "nope": 4},
                },
                "extra": {"entryShare": 1},
            },
        }
    )

    assert config["source"] == "firestore"
    assert config["prizesFundedByEntryFees"] is False
    assert config["entryFeeRole"] == "admission_only"
    assert config["companyDonationKrwPerKm"] == 100
    assert config["monthlyCompanyPrizeCapDia"] == 120_000
    beginner = config["tiers"]["beginner"]
    assert beginner["entryShare"] == 50
    assert beginner["freeTicketCost"] == 1
    # max 10 is below the default min 30, so the entrant triple stays default.
    assert beginner["maxEntrants"] == 500
    assert beginner["prizeDiaByRank"]["1"] == 9
    assert "nope" not in beginner["prizeDiaByRank"]
    assert "2" not in beginner["prizeDiaByRank"]
    assert "extra" not in config["tiers"]
    assert config["tiers"]["mid"]["entryShare"] == 1_200


def test_overlay_of_entry_limits_and_claim_thresholds() -> None:
    config = resolve_company_tournament_config(
        {
            "requireIdentityVerification": True,
            "beginnerFreeEntryCount": 4,
            "weeklyEntriesPerTier": 2,
            "prizeClaimMinAccountAgeDays": 10,
            "prizeClaimMinVerifiedRuns": 5,
            "prizeClaimVerifiedRunWindowDays": 7,
        }
    )
    assert config["requireIdentityVerification"] is True
    assert config["beginnerFreeEntryCount"] == 4
    assert config["weeklyEntriesPerTier"] == 2
    assert config["prizeClaimMinAccountAgeDays"] == 10
    assert config["prizeClaimMinVerifiedRuns"] == 5
    assert config["prizeClaimVerifiedRunWindowDays"] == 7

    kept = resolve_company_tournament_config(
        {
            "requireIdentityVerification": "yes",
            "beginnerFreeEntryCount": -1,
            "weeklyEntriesPerTier": 0,
            "prizeClaimMinAccountAgeDays": True,
            "prizeClaimMinVerifiedRuns": "3",
            "prizeClaimVerifiedRunWindowDays": 0,
        }
    )
    assert kept["requireIdentityVerification"] is False
    assert kept["beginnerFreeEntryCount"] == 2
    assert kept["weeklyEntriesPerTier"] == 1
    assert kept["prizeClaimMinAccountAgeDays"] == 14
    assert kept["prizeClaimMinVerifiedRuns"] == 3
    assert kept["prizeClaimVerifiedRunWindowDays"] == 14


def test_claim_thresholds_are_14_days_and_3_runs() -> None:
    config = resolve_company_tournament_config(None)
    now = datetime(2026, 10, 4, 3, tzinfo=timezone.utc)
    old = now - timedelta(days=14)
    young = now - timedelta(days=13)

    assert (
        prize_claim_reason(
            identity_verified=True,
            created_at=old,
            verified_runs=3,
            config=config,
            now=now,
        )
        is None
    )
    assert (
        prize_claim_reason(
            identity_verified=True,
            created_at=young,
            verified_runs=3,
            config=config,
            now=now,
        )
        == "account_too_new"
    )
    assert (
        prize_claim_reason(
            identity_verified=True,
            created_at=old - timedelta(seconds=1),
            verified_runs=3,
            config=config,
            now=now,
        )
        is None
    )
    assert (
        prize_claim_reason(
            identity_verified=True,
            created_at=now - timedelta(days=14) + timedelta(seconds=1),
            verified_runs=3,
            config=config,
            now=now,
        )
        == "account_too_new"
    )
    assert (
        prize_claim_reason(
            identity_verified=True,
            created_at=old,
            verified_runs=2,
            config=config,
            now=now,
        )
        == "not_enough_verified_runs"
    )
    assert (
        prize_claim_reason(
            identity_verified=False,
            created_at=old,
            verified_runs=3,
            config=config,
            now=now,
        )
        is None
    )
    assert (
        prize_claim_reason(
            identity_verified=False,
            created_at=young,
            verified_runs=3,
            config=config,
            now=now,
        )
        == "account_too_new"
    )
    locked = resolve_company_tournament_config({"requireIdentityVerification": True})
    assert (
        prize_claim_reason(
            identity_verified=False,
            created_at=old,
            verified_runs=3,
            config=locked,
            now=now,
        )
        == "not_identity_verified"
    )
    assert (
        prize_claim_reason(
            identity_verified=True,
            created_at=old,
            verified_runs=3,
            config=locked,
            now=now,
        )
        is None
    )


def test_read_route_returns_merged_config() -> None:
    db = _MemoryDb()
    db.store["config/company_tournament"] = {
        "tiers": {"half": {"entryShare": 10}},
    }
    original = secured_action_router.service
    secured_action_router.service = SecuredActionService(
        firebase_service=SimpleNamespace(db=db)
    )
    app.dependency_overrides[require_uid] = lambda: "u1"
    try:
        response = TestClient(app).get("/actions/company-tournament/config")
    finally:
        app.dependency_overrides.clear()
        secured_action_router.service = original

    assert response.status_code == 200
    body = response.json()
    assert body["source"] == "firestore"
    assert body["tiers"]["half"]["entryShare"] == 10
    assert body["tiers"]["beginner"]["entryShare"] == 300
    assert body["prizesFundedByEntryFees"] is False
    assert body["beginnerFreeEntryCount"] == 2
    assert body["requireIdentityVerification"] is False
    assert body["viewer"]["beginnerFreeEntryEligible"] is True
    assert body["viewer"]["freeEntryLabelKo"] == "첫 2회 무료"
    assert body["viewer"]["prizeIneligibleReason"] == "account_too_new"
    assert "일주일에 1번" in body["viewer"]["weeklyLimitLabelKo"]
    assert body["viewer"]["tierTickets"] == []
    assert body["finalFrequency"] == "season"
    assert body["finalCountsTowardMonthlyCap"] is False


def test_rank_6_to_10_dia_defaults_are_halved() -> None:
    config = resolve_company_tournament_config(None)
    mid = config["tiers"]["mid"]["prizeDiaByRank"]
    advanced = config["tiers"]["advanced"]["prizeDiaByRank"]
    half = config["tiers"]["half"]["prizeDiaByRank"]

    assert mid["5"] == 500
    assert mid["6"] == 100
    assert mid["10"] == 100
    assert advanced["5"] == 800
    assert advanced["6"] == 200
    assert advanced["10"] == 200
    assert half["5"] == 1_500
    assert half["6"] == 400
    assert half["10"] == 400
    assert config["tiers"]["beginner"]["prizeDiaByRank"] == {
        "1": 1_000,
        "2": 500,
        "3": 300,
    }
    assert config["tiers"]["final"]["prizeDiaByRank"]["1"] == 30_000
    assert config["tiers"]["final"]["prizeDiaByRank"]["10"] == 3_000
    assert config["tiers"]["mid"]["advertisedPrizeDia"] == 7_000
    assert config["tiers"]["advanced"]["advertisedPrizeDia"] == 11_600
    assert config["tiers"]["half"]["advertisedPrizeDia"] == 23_000
    assert config["tiers"]["beginner"]["advertisedPrizeDia"] == 1_800
    assert config["tiers"]["final"]["advertisedPrizeDia"] == 80_000
    assert "원" not in ticket_reward_label(config, "mid")


def test_ticket_mapping_and_seat_caps_come_from_config() -> None:
    config = resolve_company_tournament_config(None)

    assert ticket_reward_for_rank(config["tiers"]["beginner"], 3)["targetTier"] == "mid"
    assert ticket_reward_for_rank(config["tiers"]["beginner"], 4) is None
    assert ticket_reward_for_rank(config["tiers"]["mid"], 10)["targetTier"] == "advanced"
    assert ticket_reward_for_rank(config["tiers"]["advanced"], 1)["targetTier"] == "half"
    assert ticket_reward_for_rank(config["tiers"]["half"], 3)["targetTier"] == "final"
    assert ticket_reward_for_rank(config["tiers"]["half"], 4)["targetTier"] == "half"
    assert ticket_reward_for_rank(config["tiers"]["final"], 1) is None
    assert config["ticketValidEditions"] == 2
    assert config["ticketSeatPercent"] == 20
    assert config["finalDirectTicketSeatPercent"] == 15
    assert config["beginnerDiaPrizeLimitPerSeason"] == 2
    assert ticket_seat_cap(config, "mid", config["tiers"]["mid"]) == 200
    assert ticket_seat_cap(config, "final", config["tiers"]["final"]) == 19

    overlaid = resolve_company_tournament_config(
        {
            "ticketSeatPercent": 10,
            "finalDirectTicketSeatPercent": 15,
            "ticketValidEditions": 0,
            "beginnerDiaPrizeLimitPerSeason": "2",
        }
    )
    assert overlaid["ticketSeatPercent"] == 10
    assert overlaid["finalDirectTicketSeatPercent"] == 15
    assert overlaid["ticketValidEditions"] == 2
    assert overlaid["beginnerDiaPrizeLimitPerSeason"] == 2


def test_final_frequency_keeps_season_when_the_value_is_invalid() -> None:
    opened = resolve_company_tournament_config(
        {"finalFrequency": "Unlimited", "finalCountsTowardMonthlyCap": True}
    )
    assert opened["finalFrequency"] == "unlimited"
    assert opened["finalCountsTowardMonthlyCap"] is True

    kept = resolve_company_tournament_config(
        {"finalFrequency": "monthly", "finalCountsTowardMonthlyCap": "no"}
    )
    assert kept["finalFrequency"] == "season"
    assert kept["finalCountsTowardMonthlyCap"] is False
