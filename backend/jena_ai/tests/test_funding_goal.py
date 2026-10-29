"""The funding card: the goal rises as each stage is reached, and the cap is the real one."""

from datetime import datetime, timezone

from app.services import funding_goal as fg
from test_redeem_referral import _MemoryDb


def test_the_goal_is_the_first_stage_not_yet_reached() -> None:
    stages = (100_000, 300_000)
    first = fg.progress(0, stages, 1_000_000)
    assert (first["goal_won"], first["stage"], first["stages_reached"]) == (100_000, 1, 0)
    mid = fg.progress(99_999, stages, 1_000_000)
    assert mid["goal_won"] == 100_000
    second = fg.progress(100_000, stages, 1_000_000)
    assert (second["goal_won"], second["stage"], second["stages_reached"]) == (300_000, 2, 1)


def test_every_stage_reached_leaves_no_goal() -> None:
    done = fg.progress(300_000, (100_000, 300_000), 1_000_000)
    assert (done["goal_won"], done["stage"], done["stages_reached"], done["stage_count"]) == (0, 2, 2, 2)


def test_the_cap_flag_follows_the_month_total() -> None:
    assert fg.progress(999_999, fg.DEFAULT_STAGES, 1_000_000)["cap_reached"] is False
    assert fg.progress(1_000_000, fg.DEFAULT_STAGES, 1_000_000)["cap_reached"] is True
    assert fg.progress(5, fg.DEFAULT_STAGES, 0)["cap_reached"] is False


def test_a_bad_stage_list_keeps_the_default() -> None:
    assert fg.resolve_stages({"stages": [100, 100]}) == fg.DEFAULT_STAGES
    assert fg.resolve_stages({"stages": [0, 10]}) == fg.DEFAULT_STAGES
    assert fg.resolve_stages({"stages": "x"}) == fg.DEFAULT_STAGES
    assert fg.resolve_stages(None) == fg.DEFAULT_STAGES
    assert fg.resolve_stages({"stages": [50_000, 200_000, 1_000_000]}) == (50_000, 200_000, 1_000_000)


def test_the_summary_reads_this_months_totals_and_the_configured_stages() -> None:
    db = _MemoryDb()
    db.store["donationMonthTotals/2026-10"] = {"totalWon": 120_000}
    db.store["donationMonthTotals/2026-09"] = {"totalWon": 999_000}
    db.store["config/company_donation"] = {"monthlyCapWon": 500_000}
    out = fg.summary(db, datetime(2026, 10, 20, 3, tzinfo=timezone.utc))
    assert out["month"] == "2026-10"
    assert (out["total_won"], out["goal_won"], out["cap_won"]) == (120_000, 300_000, 500_000)
    assert set(out) == {"month", "total_won", "goal_won", "stage", "stage_count", "stages_reached", "cap_won", "cap_reached"}


def test_the_card_still_has_a_goal_after_the_old_last_stage() -> None:
    db = _MemoryDb()
    db.store["donationMonthTotals/2026-10"] = {"totalWon": 300_000}
    out = fg.summary(db, datetime(2026, 10, 20, 3, tzinfo=timezone.utc))
    assert out["goal_won"] == 1_000_000
    assert out["cap_won"] == 1_000_000
    assert out["cap_reached"] is False
    assert out["stage_count"] == 3

    db.store["donationMonthTotals/2026-10"] = {"totalWon": 1_000_000}
    done = fg.summary(db, datetime(2026, 10, 20, 3, tzinfo=timezone.utc))
    assert done["goal_won"] == 0
    assert done["cap_reached"] is True


def test_a_stage_above_the_cap_is_replaced_by_the_cap() -> None:
    db = _MemoryDb()
    db.store["donationMonthTotals/2026-10"] = {"totalWon": 300_000}
    db.store["config/funding_goal"] = {"stages": [100_000, 300_000, 2_000_000]}
    db.store["config/company_donation"] = {"monthlyCapWon": 500_000}
    out = fg.summary(db, datetime(2026, 10, 20, 3, tzinfo=timezone.utc))
    assert (out["goal_won"], out["cap_won"]) == (500_000, 500_000)


def test_without_any_data_the_card_starts_at_the_first_goal() -> None:
    out = fg.summary(_MemoryDb(), datetime(2026, 10, 1, tzinfo=timezone.utc))
    assert (out["total_won"], out["goal_won"], out["cap_won"]) == (0, 100_000, 1_000_000)
