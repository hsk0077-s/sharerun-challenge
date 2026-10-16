"""Promotion points: scoring, medal steps, gates, and the idempotent ledger."""

from datetime import datetime, timedelta, timezone

from app.services.promotion_points import (
    DEFAULT_CONFIG,
    PROMOTION_LEDGER,
    apply_award,
    award_tournament_results,
    points_for_result,
    rank_to_grade,
    resolve_config,
)
from test_redeem_referral import _MemoryDb

NOW = datetime(2026, 10, 14, 3, 0, tzinfo=timezone.utc)
CFG = resolve_config(None)


def _points(**kwargs) -> int:
    base = {"rank": 1, "finishers": 10, "tournament_class": "tier"}
    base.update(kwargs)
    return points_for_result(CFG, **base)


def test_rule_sheet_example_two_wins_of_ten_runners_make_100() -> None:
    assert _points(rank=2) * 4 == 100


def test_field_under_five_gives_nothing() -> None:
    assert _points(finishers=4) == 0


def test_headcount_and_class_multipliers() -> None:
    assert _points(finishers=5) == 24  # 40 x 0.6
    assert _points(finishers=30) == 60  # 40 x 1.5
    assert _points(finishers=100) == 100  # 40 x 2.5
    assert _points(tournament_class="company") == 60
    assert _points(tournament_class="final", finishers=10) == 100


def test_free_needs_ten_finishers_and_halves() -> None:
    assert _points(tournament_class="free", finishers=9) == 0
    assert _points(tournament_class="free", finishers=10) == 20


def test_challenged_up_bonus_and_new_account_win_halves() -> None:
    assert _points(challenged_up=True) == 48
    assert _points(account_age_days=3) == 20
    assert _points(rank=2, account_age_days=3) == 25


def test_other_finishers_and_top_quarter() -> None:
    assert _points(rank=2, finishers=40) == int(25 * 1.5)
    assert _points(rank=9, finishers=40) == int(10 * 1.5)  # top 25 percent
    assert _points(rank=9, finishers=10) == 3


def test_rank_to_grade_matches_server_codes() -> None:
    assert rank_to_grade(1) == ("turtle_bronze", 1)
    assert rank_to_grade(5) == ("turtle_master", 5)
    assert rank_to_grade(6) == ("beagle_bronze", 6)
    assert rank_to_grade(25) == ("cheetah_master", 25)


def test_medal_step_moves_one_rank_and_keeps_the_remainder() -> None:
    out = apply_award(
        CFG, grade_rank=2, state={"points": 15}, points=30,
        counts_tournament=True, first_place_instant=False,
        best_recent_pace_sec=None, now=NOW,
    )
    assert out["promoted"] and out["gradeRank"] == 3
    assert out["points"] == 25  # 45 - one 20 step; one step per award


def test_not_enough_points_changes_nothing_but_banks() -> None:
    out = apply_award(
        CFG, grade_rank=2, state={}, points=10, counts_tournament=True,
        first_place_instant=False, best_recent_pace_sec=None, now=NOW,
    )
    assert not out["promoted"] and out["points"] == 10 and out["tournaments"] == 1


def test_one_promotion_per_week() -> None:
    state = {"points": 40, "lastPromotedAt": (NOW - timedelta(days=2)).isoformat()}
    out = apply_award(
        CFG, grade_rank=2, state=state, points=0, counts_tournament=False,
        first_place_instant=False, best_recent_pace_sec=None, now=NOW,
    )
    assert not out["promoted"] and out["blocked"] == "cooldown"
    later = apply_award(
        CFG, grade_rank=2, state=state, points=0, counts_tournament=False,
        first_place_instant=False, best_recent_pace_sec=None,
        now=NOW + timedelta(days=6),
    )
    assert later["promoted"]


def test_crossing_to_next_animal_needs_tournaments() -> None:
    out = apply_award(
        CFG, grade_rank=5, state={"points": 20, "tournaments": 1}, points=0,
        counts_tournament=False, first_place_instant=False,
        best_recent_pace_sec=None, now=NOW,
    )
    assert not out["promoted"] and out["blocked"] == "tournaments"
    ready = apply_award(
        CFG, grade_rank=5, state={"points": 20, "tournaments": 3}, points=0,
        counts_tournament=False, first_place_instant=False,
        best_recent_pace_sec=None, now=NOW,
    )
    assert ready["promoted"] and ready["gradeRank"] == 6 and ready["tournaments"] == 0


def test_wolf_gate_needs_a_recent_fast_run() -> None:
    state = {"points": 30, "tournaments": 5}
    slow = apply_award(
        CFG, grade_rank=10, state=state, points=0, counts_tournament=False,
        first_place_instant=False, best_recent_pace_sec=None, now=NOW,
    )
    assert slow["blocked"] == "tournaments" or slow["blocked"] == "pace"
    state = {"points": 40, "tournaments": 6}
    no_run = apply_award(
        CFG, grade_rank=10, state=state, points=0, counts_tournament=False,
        first_place_instant=False, best_recent_pace_sec=None, now=NOW,
    )
    assert no_run["blocked"] == "pace"
    fast = apply_award(
        CFG, grade_rank=10, state=state, points=0, counts_tournament=False,
        first_place_instant=False, best_recent_pace_sec=299, now=NOW,
    )
    assert fast["promoted"] and fast["gradeRank"] == 11


def test_zebra_to_cheetah_waits_for_the_season_rule() -> None:
    out = apply_award(
        CFG, grade_rank=20, state={"points": 60, "tournaments": 8}, points=0,
        counts_tournament=False, first_place_instant=False,
        best_recent_pace_sec=200, now=NOW,
    )
    assert not out["promoted"] and out["blocked"] == "season"


def test_instant_win_for_turtle_goes_to_beagle_bronze() -> None:
    out = apply_award(
        CFG, grade_rank=4, state={}, points=40, counts_tournament=True,
        first_place_instant=True, best_recent_pace_sec=None, now=NOW,
    )
    assert out["instant"] and out["gradeRank"] == 6 and out["points"] == 0


def test_no_instant_win_for_wolf_and_above() -> None:
    out = apply_award(
        CFG, grade_rank=11, state={}, points=40, counts_tournament=True,
        first_place_instant=True, best_recent_pace_sec=None, now=NOW,
    )
    assert not out["instant"]


def test_bad_config_edit_keeps_defaults() -> None:
    raw = {"rankPoints": {"1": "lots"}, "freeWeeklyCap": 50, "promotionCooldownDays": -1}
    cfg = resolve_config(raw)
    assert cfg["rankPoints"] == DEFAULT_CONFIG["rankPoints"]
    assert cfg["freeWeeklyCap"] == 50
    assert cfg["promotionCooldownDays"] == DEFAULT_CONFIG["promotionCooldownDays"]


def _seed(db: _MemoryDb, uid: str, rank: int, **extra) -> None:
    user = {"gradeRank": rank, "gradeCode": "x", "authCreatedAt": (NOW - timedelta(days=90)).isoformat()}
    user.update(extra)
    db.store[f"users/{uid}"] = user


def test_award_writes_ledger_once_and_updates_the_grade() -> None:
    db = _MemoryDb()
    for uid in ("a", "b", "c", "d", "e"):
        _seed(db, uid, 2)
    results = [{"uid": uid, "rank": i} for i, uid in enumerate("abcde", start=1)]
    first = award_tournament_results(
        db, tournament_id="t1", tournament_class="company", results=results, now=NOW
    )
    assert first["awarded"] == 5 and first["skipped"] == 0
    assert f"{PROMOTION_LEDGER}/t1__a" in db.store
    winner = db.store["users/a"]
    assert winner["promotion"]["points"] >= 0
    assert winner["promotion"]["step"] == 20  # turtle medal step
    again = award_tournament_results(
        db, tournament_id="t1", tournament_class="company", results=results, now=NOW
    )
    assert again["awarded"] == 0 and again["skipped"] == 5
    assert db.store["users/a"] == winner


def test_snail_without_grade_is_skipped() -> None:
    db = _MemoryDb()
    db.store["users/s"] = {"authCreatedAt": NOW.isoformat()}
    out = award_tournament_results(
        db, tournament_id="t2", tournament_class="tier",
        results=[{"uid": "s", "rank": 1}], now=NOW,
    )
    assert out["awarded"] == 0 and out["skipped"] == 1
    assert f"{PROMOTION_LEDGER}/t2__s" not in db.store


def test_free_weekly_cap_limits_points() -> None:
    db = _MemoryDb()
    _seed(db, "a", 2)
    db.store[f"{PROMOTION_LEDGER}/old__a"] = {
        "uid": "a", "weekKey": "2026-W42", "tournamentClass": "free", "points": 25,
    }
    results = [{"uid": "a", "rank": 1}] + [{"uid": f"x{i}", "rank": i + 2} for i in range(9)]
    out = award_tournament_results(
        db, tournament_id="free1", tournament_class="free", results=results, now=NOW
    )
    assert db.store[f"{PROMOTION_LEDGER}/free1__a"]["points"] == 5
    assert out["awarded"] == 1
