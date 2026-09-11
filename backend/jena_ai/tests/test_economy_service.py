from datetime import datetime, timezone

from app.services.economy_service import EconomyService


def test_compute_mining_reward_within_daily_cap() -> None:
    allowance = EconomyService().compute_mining_reward(
        distance_km=3.0,
        daily_earned_km=0.0,
        daily_earned_tokens=0,
    )

    assert allowance.reward_tokens == 30
    assert allowance.counted_km == 3.0
    assert allowance.daily_cap_reached is False


def test_compute_mining_reward_hits_daily_token_cap() -> None:
    allowance = EconomyService().compute_mining_reward(
        distance_km=3.0,
        daily_earned_km=2.0,
        daily_earned_tokens=40,
    )

    assert allowance.reward_tokens == 10
    assert allowance.counted_km == 1.0


def test_compute_mining_reward_returns_zero_when_cap_exhausted() -> None:
    allowance = EconomyService().compute_mining_reward(
        distance_km=3.0,
        daily_earned_km=5.0,
        daily_earned_tokens=50,
    )

    assert allowance.reward_tokens == 0
    assert allowance.counted_km == 0.0
    assert allowance.daily_cap_reached is True


def test_trial_milestone_reached_at_five_runs() -> None:
    service = EconomyService()
    assert service.trial_milestone_reached(4) is False
    assert service.trial_milestone_reached(5) is True


def test_kst_today_key_rolls_at_utc_plus_9_midnight() -> None:
    service = EconomyService()
    just_before = datetime(2026, 9, 8, 14, 59, tzinfo=timezone.utc)
    at_midnight = datetime(2026, 9, 8, 15, 0, tzinfo=timezone.utc)
    assert service.kst_today_key(just_before) == "2026-09-08"
    assert service.kst_today_key(at_midnight) == "2026-09-09"


def test_normalize_daily_mining_resets_on_new_kst_day() -> None:
    service = EconomyService()
    previous = {
        "dateKey": "2026-09-08",
        "earnedKm": 3.0,
        "earnedSrvTokens": 30,
    }
    reset = service.normalize_daily_mining(previous, "2026-09-09")
    assert reset == {
        "dateKey": "2026-09-09",
        "earnedKm": 0.0,
        "earnedSrvTokens": 0,
    }
    same_day = service.normalize_daily_mining(previous, "2026-09-08")
    assert same_day["earnedKm"] == 3.0
    assert same_day["earnedSrvTokens"] == 30


def test_normalize_pedometer_harvest_resets_on_new_kst_day() -> None:
    service = EconomyService()
    previous = {
        "dateKey": "2026-09-08",
        "claimedSteps": 4000,
        "harvestedShare": 40,
    }
    reset = service.normalize_pedometer_harvest(previous, "2026-09-09")
    assert reset == {
        "dateKey": "2026-09-09",
        "claimedSteps": 0,
        "harvestedShare": 0,
    }
    same_day = service.normalize_pedometer_harvest(previous, "2026-09-08")
    assert same_day["claimedSteps"] == 4000
    assert same_day["harvestedShare"] == 40


def test_pedometer_harvest_share_is_one_per_hundred_steps_with_daily_cap() -> None:
    service = EconomyService()
    assert (
        service.pedometer_harvest_share(
            claimed_steps=150,
            prev_claimed_steps=0,
            harvested_share=0,
        )
        == 1
    )
    assert (
        service.pedometer_harvest_share(
            claimed_steps=250,
            prev_claimed_steps=150,
            harvested_share=1,
        )
        == 1
    )
    assert (
        service.pedometer_harvest_share(
            claimed_steps=7000,
            prev_claimed_steps=0,
            harvested_share=0,
        )
        == 60
    )
    assert (
        service.pedometer_harvest_share(
            claimed_steps=1000,
            prev_claimed_steps=0,
            harvested_share=55,
        )
        == 5
    )
    assert (
        service.pedometer_harvest_share(
            claimed_steps=200,
            prev_claimed_steps=150,
            harvested_share=1,
        )
        == 0
    )
    assert (
        service.pedometer_harvest_share(
            claimed_steps=2918,
            prev_claimed_steps=0,
            harvested_share=0,
        )
        == 29
    )
    assert (
        service.pedometer_harvest_share(
            claimed_steps=2918,
            prev_claimed_steps=2918,
            harvested_share=29,
        )
        == 0
    )
