"""Monthly crew ranking: average verified distance per member, finalized at month end."""

from datetime import datetime, timezone

import pytest

from app.services import crew_ranking as cr
from test_redeem_referral import _MemoryDb
from test_verified_run_donation import NOW, _persist, _seed


def _seed_crew(db: _MemoryDb, members: int = 6) -> None:
    _seed(db)
    db.store["users/u1"]["crewId"] = "c1"
    db.store["crews/c1"] = {
        "name": "새벽러너",
        "ownerUid": "u1",
        "emblem": "moon:lime",
        "memberCount": members,
        "totalDistanceKm": 10.0,
        "totalDonationWon": 500,
    }


# ---- counting runs ---------------------------------------------------------------------
def test_a_verified_run_counts_for_the_crew_total_and_the_month_once() -> None:
    db = _MemoryDb()
    _seed_crew(db)

    _persist(db, "act-1", 3)
    assert db.store["crews/c1"]["totalDistanceKm"] == pytest.approx(13.0)
    assert db.store["crewMonthly/2026-10/crews/c1"]["distanceKm"] == pytest.approx(3.0)
    assert "crews/c1/runs/act-1" in db.store

    _persist(db, "act-1", 3)  # the same run submitted again
    assert db.store["crews/c1"]["totalDistanceKm"] == pytest.approx(13.0)
    assert db.store["crewMonthly/2026-10/crews/c1"]["distanceKm"] == pytest.approx(3.0)

    _persist(db, "act-2", 2)
    assert db.store["crewMonthly/2026-10/crews/c1"]["distanceKm"] == pytest.approx(5.0)


def test_an_unverified_run_adds_nothing() -> None:
    db = _MemoryDb()
    _seed_crew(db)
    _persist(db, "act-bad", 3, verified=False, reason="no")
    assert db.store["crews/c1"]["totalDistanceKm"] == pytest.approx(10.0)
    assert "crewMonthly/2026-10/crews/c1" not in db.store


def test_the_crew_keeps_climbing_after_the_company_donation_cap_is_full() -> None:
    db = _MemoryDb()
    _seed_crew(db)
    db.store["config/company_donation"] = {"monthlyCapWon": 1_000}
    db.store["donationMonthTotals/2026-10"] = {"totalWon": 1_000}

    outcome = _persist(db, "act-after-cap", 4)

    assert outcome.donation_counted is False
    assert db.store["crews/c1"]["totalDistanceKm"] == pytest.approx(14.0)
    assert db.store["crewMonthly/2026-10/crews/c1"]["distanceKm"] == pytest.approx(4.0)
    # The donation total only follows real donations.
    assert db.store["crews/c1"]["totalDonationWon"] == 500


def test_a_run_by_someone_without_a_crew_touches_no_crew() -> None:
    db = _MemoryDb()
    _seed(db)
    _persist(db, "act-solo", 3)
    assert not [p for p in db.store if p.startswith("crewMonthly/")]


# ---- ranking ---------------------------------------------------------------------------
def _row(crew_id, km, members, when=None):
    return {"crew_id": crew_id, "name": crew_id, "emblem": "", "distance_km": km,
            "member_count": members, "updated_at": when}


def test_the_average_per_member_decides_not_the_big_total() -> None:
    ranked = cr.rank_crews([_row("big", 100, 50), _row("small", 40, 5), _row("mid", 90, 10)])
    assert [r["crew_id"] for r in ranked] == ["mid", "small", "big"]
    assert [r["rank"] for r in ranked] == [1, 2, 3]
    assert ranked[0]["average_km"] == pytest.approx(9.0)


def test_a_crew_under_the_minimum_is_not_ranked() -> None:
    assert [r["crew_id"] for r in cr.rank_crews([_row("duo", 500, 2), _row("ok", 5, 5)])] == ["ok"]
    assert cr.rank_crews([_row("duo", 500, 2)]) == []
    assert [r["crew_id"] for r in cr.rank_crews([_row("duo", 500, 2)], minimum=2)] == ["duo"]


def test_a_crew_with_no_distance_is_not_ranked() -> None:
    assert cr.rank_crews([_row("idle", 0, 10)]) == []


def test_ties_go_to_more_distance_then_to_who_got_there_first() -> None:
    early = datetime(2026, 10, 3, tzinfo=timezone.utc)
    late = datetime(2026, 10, 9, tzinfo=timezone.utc)
    ranked = cr.rank_crews(
        [_row("a", 50, 10, late), _row("b", 100, 20, late), _row("c", 100, 20, early)]
    )
    # All three average 5.0 km. b and c have more distance than a, and c got there before b.
    assert [r["crew_id"] for r in ranked] == ["c", "b", "a"]


def test_ranking_borders_follow_the_best_rank() -> None:
    assert cr.ranking_borders(1) == ["ranking-1", "ranking-2", "ranking-3"]
    assert cr.ranking_borders(10) == ["ranking-1", "ranking-2"]
    assert cr.ranking_borders(100) == ["ranking-1"]
    assert cr.ranking_borders(101) == []
    assert cr.ranking_borders(0) == []


# ---- month end -------------------------------------------------------------------------
def _month(db, month, crews):
    for crew_id, (km, members) in crews.items():
        db.store[f"crewMonthly/{month}/crews/{crew_id}"] = {"distanceKm": km}
        db.store.setdefault(
            f"crews/{crew_id}",
            {"name": crew_id, "emblem": "moon:lime", "memberCount": members},
        )


def test_finalizing_saves_each_crews_best_rank_and_borders_once() -> None:
    db = _MemoryDb()
    _month(db, "2026-09", {"a": (80, 8), "b": (60, 10), "tiny": (99, 2)})

    out = cr.finalize_month(db, "2026-09")

    assert (out["status"], out["ranked"]) == ("finalized", 2)
    assert db.store["crews/a"]["bestMonthlyRank"] == 1
    assert db.store["crews/b"]["bestMonthlyRank"] == 2
    assert db.store["crews/a"]["unlockedBorders"] == ["ranking-1", "ranking-2", "ranking-3"]
    assert db.store["crews/b"]["unlockedBorders"] == ["ranking-1", "ranking-2"]
    assert "bestMonthlyRank" not in db.store["crews/tiny"]
    assert db.store["crewMonthly/2026-09"]["finalized"] is True
    assert db.store["crewMonthly/2026-09"]["ranking"][0]["crew_id"] == "a"

    assert cr.finalize_month(db, "2026-09")["status"] == "already_finalized"


def test_a_worse_month_never_lowers_the_best_rank_or_removes_a_border() -> None:
    db = _MemoryDb()
    _month(db, "2026-09", {"a": (80, 8), "b": (60, 10)})
    cr.finalize_month(db, "2026-09")
    _month(db, "2026-10", {"a": (10, 8), "b": (90, 10)})

    cr.finalize_month(db, "2026-10")

    assert db.store["crews/a"]["bestMonthlyRank"] == 1  # was 1, is now 2: stays 1
    assert db.store["crews/b"]["bestMonthlyRank"] == 1  # was 2, is now 1: improves
    assert "ranking-3" in db.store["crews/a"]["unlockedBorders"]


def test_the_summary_shows_the_top_and_where_my_crew_stands() -> None:
    db = _MemoryDb()
    now = datetime(2026, 10, 20, 3, tzinfo=timezone.utc)
    _month(db, "2026-10", {"a": (80, 8), "b": (60, 10), "mine": (30, 6)})

    out = cr.summary(db, "mine", now)

    assert out["month"] == "2026-10"
    assert [t["crew_id"] for t in out["top"]] == ["a", "b", "mine"]
    assert out["mine"]["rank"] == 3 and out["mine"]["average_km"] == pytest.approx(5.0)
    assert out["my_eligible"] is True and out["min_members"] == 5
    # Asking for the ranking closes the month before it.
    assert db.store.get("crewMonthly/2026-09", {}).get("finalized") is True


def test_a_crew_under_the_minimum_sees_why_it_is_not_listed() -> None:
    db = _MemoryDb()
    now = datetime(2026, 10, 20, 3, tzinfo=timezone.utc)
    _month(db, "2026-10", {"duo": (50, 2), "a": (80, 8)})

    out = cr.summary(db, "duo", now)

    assert out["mine"] is None
    assert out["my_eligible"] is False
    assert out["my_member_count"] == 2
    assert out["my_distance_km"] == pytest.approx(50.0)
