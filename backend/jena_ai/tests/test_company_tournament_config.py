"""Company prize-race config defaults, Firestore overlay, and read route."""

from types import SimpleNamespace

from fastapi.testclient import TestClient

from app.constants.economy_constants import SRV_TOKENS_PER_KM
from app.main import app
from app.routers import secured_action_router
from app.services.auth_service import require_uid
from app.services.company_tournament_config import resolve_company_tournament_config
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

    beginner = config["tiers"]["beginner"]
    assert beginner["labelKo"] == "초급"
    assert beginner["distanceLabel"] == "1-3km"
    assert beginner["entryShare"] == 600
    assert beginner["freeTicketCost"] == 1
    assert beginner["minEntrants"] == 30
    assert beginner["targetEntrants"] == 100
    assert beginner["maxEntrants"] == 500
    assert beginner["top10PercentShare"] == 1_000
    assert beginner["prizeDiaByRank"] == {"1": 1_000, "2": 500, "3": 300}

    mid = config["tiers"]["mid"]
    assert mid["entryShare"] == 1_800
    assert mid["freeTicketCost"] == 1
    assert mid["prizeDiaByRank"]["4"] == 500
    assert mid["prizeDiaByRank"]["6"] == 200
    assert mid["top10PercentShare"] == 2_000
    assert (mid["minEntrants"], mid["targetEntrants"], mid["maxEntrants"]) == (
        50,
        200,
        1_000,
    )

    advanced = config["tiers"]["advanced"]
    assert advanced["entryShare"] == 3_000
    assert advanced["freeTicketCost"] == 2
    assert advanced["prizeDiaByRank"]["1"] == 5_000
    assert advanced["prizeDiaByRank"]["10"] == 400
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
    assert final["top10PercentShare"] == 10_000
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
    assert config["tiers"]["mid"]["entryShare"] == 1_800


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
    assert body["tiers"]["beginner"]["entryShare"] == 600
    assert body["prizesFundedByEntryFees"] is False
