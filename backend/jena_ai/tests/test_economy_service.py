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
