"""Sponsorship totals everyone sees, and the list only the sponsor sees."""

from datetime import datetime, timezone
from types import SimpleNamespace

from google.cloud.firestore_v1.transforms import Increment

from app.services import sponsorship_records as rec
from app.services.personal_sponsor import donate_personal_sponsor
from app.services.secured_action_service import SecuredActionService
from test_redeem_referral import _MemoryDb, _MemoryTxn


def _db(**user_extra) -> _MemoryDb:
    db = _MemoryDb()
    db.store["users/u1"] = {
        "wallet": {"shareBalance": 80_000, "freeShareBalance": 80_000, "diamondBalance": 0},
        **user_extra,
    }
    return db


def _donate(db, request_id="req-sp-0001", purpose="donation"):
    service = SecuredActionService(firebase_service=SimpleNamespace(db=db))
    return donate_personal_sponsor(
        service, _MemoryTxn(), "u1", request_id, purpose, db.collection("users").document("u1")
    )


def _totals(db):
    return {p: d for p, d in db.store.items() if p.startswith("sponsorTotals/")}


def test_a_donation_sponsorship_adds_to_the_public_totals() -> None:
    db = _db()
    _donate(db)
    totals = _totals(db)
    assert len(totals) == 2
    all_doc = totals["sponsorTotals/donation"]
    assert all_doc["totalWon"] == 50_000 and all_doc["count"] == 1
    assert all_doc["sponsorCount"] == 1
    month_doc = next(d for p, d in totals.items() if p != "sponsorTotals/donation")
    assert month_doc["totalWon"] == 50_000 and "sponsorCount" not in month_doc
    assert db.store["users/u1"]["personalDonationSponsored"] is True


def test_a_returning_sponsor_is_counted_as_one_person() -> None:
    db = _db(personalDonationSponsored=True)
    _donate(db)
    assert "sponsorCount" not in _totals(db)["sponsorTotals/donation"]
    assert _totals(db)["sponsorTotals/donation"]["count"] == 1


def test_a_prize_sponsorship_is_not_a_donation_total() -> None:
    db = _db()
    _donate(db, purpose="prize")
    assert _totals(db) == {}
    assert "personalDonationSponsored" not in db.store["users/u1"]


def test_the_same_request_does_not_count_twice() -> None:
    db = _db()
    _donate(db)
    before = dict(_totals(db))
    _donate(db)
    assert _totals(db) == before


def test_amounts_stay_hidden_until_enough_people_have_sponsored(monkeypatch) -> None:
    monkeypatch.delenv("SPONSOR_SUMMARY_MIN", raising=False)
    db = _MemoryDb()
    all_ref, month_ref = rec.refs(db)
    db.store[all_ref.path] = {"totalWon": 200_000, "count": 4, "sponsorCount": 4}
    hidden = rec.summary(db, "anyone")
    assert hidden == {
        "sponsor_count": 4, "show_amounts": False, "min_sponsors": 5,
        "total_won": None, "month_won": None, "month_count": None,
    }
    db.store[all_ref.path] = {"totalWon": 300_000, "count": 6, "sponsorCount": 5}
    db.store[month_ref.path] = {"totalWon": 100_000, "count": 2}
    shown = rec.summary(db, "anyone")
    assert (shown["show_amounts"], shown["total_won"], shown["month_won"], shown["month_count"]) == (True, 300_000, 100_000, 2)


def test_the_threshold_can_be_changed(monkeypatch) -> None:
    monkeypatch.setenv("SPONSOR_SUMMARY_MIN", "1")
    db = _MemoryDb()
    all_ref, _ = rec.refs(db)
    db.store[all_ref.path] = {"totalWon": 50_000, "count": 1, "sponsorCount": 1}
    assert rec.summary(db, "x")["total_won"] == 50_000


def test_nothing_sponsored_yet_is_an_honest_empty_summary() -> None:
    summary = rec.summary(_MemoryDb(), "x")
    assert summary["sponsor_count"] == 0 and summary["total_won"] is None


def test_my_list_has_only_my_entries_newest_first() -> None:
    db = _MemoryDb()
    t = lambda d: datetime(2026, 10, d, tzinfo=timezone.utc)
    db.store["walletTransactions/a"] = {"uid": "u1", "type": "personal_sponsor_donation", "shareAmount": -50_000, "angelTierCode": "guardian", "createdAt": t(1)}
    db.store["walletTransactions/b"] = {"uid": "u1", "type": "personal_sponsor_prize", "shareAmount": -50_000, "angelTierCode": "guardian", "createdAt": t(3)}
    db.store["walletTransactions/c"] = {"uid": "u2", "type": "personal_sponsor_donation", "shareAmount": -50_000, "createdAt": t(2)}
    db.store["walletTransactions/d"] = {"uid": "u1", "type": "shop_purchase", "diamondAmount": -40, "createdAt": t(4)}
    mine = rec.mine(db, "u1")
    assert [e["purpose"] for e in mine["entries"]] == ["prize", "donation"]
    assert mine["donation_count"] == 1 and mine["donation_won"] == 50_000
    other = rec.mine(db, "u2")
    assert len(other["entries"]) == 1 and other["entries"][0]["share"] == 50_000
    assert rec.mine(db, "u3")["entries"] == []
