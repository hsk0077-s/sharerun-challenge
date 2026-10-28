"""Monthly ceiling stays backward compatible, then slides when asked."""

from app.services.donation_cap import (
    clip_daily_donation,
    resolve_monthly_cap_won,
)


def test_monthly_cap_alone_is_unchanged() -> None:
    assert resolve_monthly_cap_won(None) == 1_000_000
    assert resolve_monthly_cap_won({"monthlyCapWon": 1_000}) == 1_000
    assert resolve_monthly_cap_won({"monthlyCapWon": -5}) == 1_000_000


def test_sliding_cap_uses_base_revenue_and_the_hard_ceiling() -> None:
    assert resolve_monthly_cap_won({"baseCapWon": 300_000}) == 300_000
    assert (
        resolve_monthly_cap_won(
            {"baseCapWon": 300_000, "priorMonthNetRevenueWon": 2_000_000}
        )
        == 400_000
    )
    assert (
        resolve_monthly_cap_won(
            {
                "monthlyCapWon": 500_000,
                "baseCapWon": 300_000,
                "priorMonthNetRevenueWon": 10_000_000,
                "sponsorAttributedWon": 100_000,
            }
        )
        == 500_000
    )


def test_one_runner_stops_at_ten_kilometres() -> None:
    won, km = clip_daily_donation(12.5, 1250, 0, 0)
    assert won == 1_000
    assert km == 10
    later, later_km = clip_daily_donation(12.5, 1250, 2.4, 240)
    assert later == 760
    assert later_km < 8
    assert clip_daily_donation(5, 500, 10, 1000) == (0, 0.0)
