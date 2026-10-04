"""휴식일 지정권 and 기부 매칭권. VALUE is spent, never converted."""

from datetime import datetime, timedelta, timezone
from types import SimpleNamespace

from fastapi import HTTPException
import pytest

from app.services.economy_service import EconomyService
from app.services.item_price_config import resolve_item_prices
from app.services.secured_action_service import SecuredActionService, _commit_streak_bonus_tx
from app.services.streak_protection import use_streak_item
from app.services.value_items import apply_donation_match, purchase_value_item, use_value_item
from test_redeem_referral import _MemoryDb, _MemoryTxn

# 2026-10-04 10:00 KST (Sunday). Week starts 2026-09-28.
NOW = datetime(2026, 10, 4, 1, 0, tzinfo=timezone.utc)
NEXT_WEEK = datetime(2026, 10, 5, 1, 0, tzinfo=timezone.utc)
REST = "rest_day_ticket"
MATCH = "donation_match"
CPR = "record_cpr_ticket"
GUARD = "record_safe_guard"


def _service(db: _MemoryDb) -> SecuredActionService:
    return SecuredActionService(firebase_service=SimpleNamespace(db=db))


def _user(value: int = 200, **extra) -> dict:
    return {
        "nickname": "러너상",
        "wallet": {
            "shareBalance": 10,
            "diamondBalance": 4,
            "valueTokenBalance": value,
        },
        **extra,
    }


def _buy(db: _MemoryDb, item_id: str, request_id: str, uid: str = "u1", now: datetime = NOW):
    service = _service(db)
    return purchase_value_item(
        service,
        _MemoryTxn(),
        uid,
        item_id,
        request_id,
        db.collection("users").document(uid),
        now=now,
    )


def _use_rest(db: _MemoryDb, request_id: str, rest_day: str | None = None, now: datetime = NOW):
    service = _service(db)
    return use_value_item(
        service,
        _MemoryTxn(),
        "u1",
        REST,
        request_id,
        db.collection("users").document("u1"),
        rest_day=rest_day,
        now=now,
    )


def _match(db: _MemoryDb, request_id: str, uid: str = "u1", now: datetime = NOW):
    service = _service(db)
    return apply_donation_match(
        service,
        _MemoryTxn(),
        uid,
        request_id,
        db.collection("users").document(uid),
        now=now,
    )


def _wallet_rows(db: _MemoryDb) -> list[dict]:
    return [row for path, row in db.store.items() if path.startswith("walletTransactions/")]


def _donations(db: _MemoryDb) -> list[tuple[str, dict]]:
    return [
        (path, row)
        for path, row in db.store.items()
        if path.startswith("donationLedger/")
    ]


def test_prices_and_caps_keep_defaults() -> None:
    prices = resolve_item_prices(None)
    assert prices[REST] == 50
    assert prices["rest_day_free_per_week"] == 1
    assert prices[MATCH] == 100
    assert prices["donation_match_won"] == 1000
    assert prices["donation_match_user_monthly"] == 1
    assert prices["donation_match_company_cap_won"] == 500_000

    overridden = resolve_item_prices(
        {
            REST: 0,
            MATCH: 80,
            "donation_match_won": True,
            "donation_match_company_cap_won": 2_000,
            "donation_match_sponsor": "나이키",
        }
    )
    assert overridden[REST] == 50
    assert overridden[MATCH] == 80
    assert overridden["donation_match_won"] == 1_000
    assert overridden["donation_match_company_cap_won"] == 2_000


def test_catalog_prices_value_not_dia() -> None:
    db = _MemoryDb()
    db.store["config/item_prices"] = {REST: 40, MATCH: 90, "donation_match_won": 1500}
    rows = {row["id"]: row for row in _service(db).shop_catalog()}
    assert rows[REST]["diamondCost"] == 0
    assert rows[REST]["shareCost"] == 0
    assert rows[REST]["valueCost"] == 40
    assert rows[MATCH]["valueCost"] == 90
    assert rows[MATCH]["diamondCost"] == 0


def test_free_rest_day_is_weekly_and_not_stockpiled() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _user()

    used = _use_rest(db, "req-rest-free1")

    assert used.status == "used"
    assert used.value_token_balance == 200
    assert db.store["users/u1"]["wallet"]["valueTokenBalance"] == 200
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 10
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 4
    assert "users/u1/shopInventory/rest_day_ticket" not in db.store
    assert db.store["users/u1"]["restDayFreeWeek"] == {
        "weekKey": "2026-09-28",
        "count": 1,
    }
    paused = db.store["users/u1/daily_metrics/2026-10-04"]
    assert paused["streakPaused"] == "rest"
    assert "streakCovered" not in paused
    assert _wallet_rows(db)[0]["valueAmount"] == 0
    assert _wallet_rows(db)[0]["freeWeek"] is True

    again = _use_rest(db, "req-rest-free1")
    assert again.status == "already_used"
    assert db.store["users/u1"]["restDayFreeWeek"]["count"] == 1

    with pytest.raises(HTTPException) as raised:
        _use_rest(db, "req-rest-free2", rest_day="2026-10-03")
    assert raised.value.detail == "No item to use."
    assert "users/u1/daily_metrics/2026-10-03" not in db.store
    assert db.store["users/u1"]["wallet"]["valueTokenBalance"] == 200

    nxt = _use_rest(db, "req-rest-next", now=NEXT_WEEK)
    assert nxt.status == "used"
    assert db.store["users/u1"]["restDayFreeWeek"]["weekKey"] == "2026-10-05"
    assert db.store["users/u1"]["restDayFreeWeek"]["count"] == 1
    assert "users/u1/shopInventory/rest_day_ticket" not in db.store
    assert db.store["users/u1/daily_metrics/2026-10-05"]["streakPaused"] == "rest"


def test_extra_rest_day_costs_value_once_and_pauses_without_covering() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _user(value=50)
    db.store["users/u1"]["restDayFreeWeek"] = {"weekKey": "2026-09-28", "count": 1}
    db.store["config/item_prices"] = {REST: 40}

    bought = _buy(db, REST, "req-rest-buy1")

    assert bought.status == "purchased"
    assert bought.value_token_balance == 10
    assert bought.share_balance == 10
    assert bought.diamond_balance == 4
    assert db.store["users/u1/shopInventory/rest_day_ticket"]["quantity"] == 1
    row = _wallet_rows(db)[0]
    assert row["type"] == "shop_purchase"
    assert row["valueAmount"] == -40
    assert "shareAmount" not in row
    assert "diamondAmount" not in row

    replay = _buy(db, REST, "req-rest-buy1")
    assert replay.status == "already_purchased"
    assert db.store["users/u1"]["wallet"]["valueTokenBalance"] == 10
    assert db.store["users/u1/shopInventory/rest_day_ticket"]["quantity"] == 1

    used = _use_rest(db, "req-rest-paid", rest_day="2026-10-03")
    assert used.status == "used"
    assert db.store["users/u1/shopInventory/rest_day_ticket"]["quantity"] == 0
    assert db.store["users/u1"]["wallet"]["valueTokenBalance"] == 10
    assert db.store["users/u1/daily_metrics/2026-10-03"]["streakPaused"] == "rest"
    assert "streakCovered" not in db.store["users/u1/daily_metrics/2026-10-03"]


def test_rest_day_rejects_a_run_or_a_cover_without_spending() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _user()
    db.store["users/u1/daily_metrics/2026-10-04"] = {"km": 1.2, "streakCovered": "cpr"}

    with pytest.raises(HTTPException) as raised:
        _use_rest(db, "req-rest-run")
    assert raised.value.detail == "That day already counts."
    assert db.store["users/u1"]["wallet"]["valueTokenBalance"] == 200
    assert "restDayFreeWeek" not in db.store["users/u1"]
    assert db.store["users/u1/daily_metrics/2026-10-04"]["streakCovered"] == "cpr"
    assert "streakPaused" not in db.store["users/u1/daily_metrics/2026-10-04"]
    assert _wallet_rows(db) == []

    with pytest.raises(HTTPException) as old:
        _use_rest(db, "req-rest-old", rest_day="2026-10-01")
    assert old.value.detail == "Rest day must be today or yesterday."


def test_rest_day_does_not_double_protect_with_cpr_or_safeguard() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _user(value=0)
    db.store["users/u1/shopInventory/record_cpr_ticket"] = {"quantity": 1}
    db.store["users/u1/shopInventory/record_safe_guard"] = {"quantity": 1}
    db.store["users/u1/daily_metrics/2026-10-01"] = {"km": 2}
    db.store["users/u1/daily_metrics/2026-10-03"] = {"streakPaused": "rest"}
    service = _service(db)
    user_ref = db.collection("users").document("u1")

    with pytest.raises(HTTPException) as guard:
        use_streak_item(service, _MemoryTxn(), "u1", GUARD, "req-guard-rest", user_ref, now=NOW)
    assert guard.value.detail == "No missed day to protect."
    assert "streakCovered" not in db.store["users/u1/daily_metrics/2026-10-03"]
    assert db.store["users/u1/shopInventory/record_safe_guard"]["quantity"] == 1

    restored = use_streak_item(
        service, _MemoryTxn(), "u1", CPR, "req-cpr-rest", user_ref, now=NOW
    )
    assert restored.status == "used"
    assert db.store["users/u1/daily_metrics/2026-10-02"]["streakCovered"] == "cpr"
    assert db.store["users/u1/daily_metrics/2026-10-03"]["streakPaused"] == "rest"
    assert "streakCovered" not in db.store["users/u1/daily_metrics/2026-10-03"]


def test_safeguard_still_covers_one_miss_after_a_rest_pause() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {"wallet": {"diamondBalance": 0}}
    db.store["users/u1/shopInventory/record_safe_guard"] = {"quantity": 1}
    db.store["users/u1/daily_metrics/2026-10-01"] = {"km": 1}
    db.store["users/u1/daily_metrics/2026-10-02"] = {"streakPaused": "rest"}
    service = _service(db)

    used = use_streak_item(
        service,
        _MemoryTxn(),
        "u1",
        GUARD,
        "req-guard-after-rest",
        db.collection("users").document("u1"),
        now=NOW,
    )

    assert used.status == "used"
    assert db.store["users/u1/daily_metrics/2026-10-03"]["streakCovered"] == "safeguard"
    assert db.store["users/u1/daily_metrics/2026-10-02"]["streakPaused"] == "rest"
    assert "streakCovered" not in db.store["users/u1/daily_metrics/2026-10-02"]


def test_paused_day_is_not_a_run_and_does_not_break_the_streak(monkeypatch) -> None:
    monkeypatch.setattr(EconomyService, "kst_today_key", lambda self, now=None: "2026-10-04")
    db = _MemoryDb()
    db.store["users/u1"] = _user(value=0)
    for offset in (0, 2, 3, 4, 5, 6):
        day = (datetime(2026, 10, 4) - timedelta(days=offset)).date().isoformat()
        db.store[f"users/u1/daily_metrics/{day}"] = {"km": 1}
    db.store["users/u1/daily_metrics/2026-10-03"] = {"streakPaused": "rest"}
    service = _service(db)

    assert service._walk_streak_days(_MemoryTxn(), "u1") == 6

    db.store["users/u1/daily_metrics/2026-09-27"] = {"steps": 100}
    assert service._walk_streak_days(_MemoryTxn(), "u1") == 7


def test_streak_bonus_skips_a_rest_day_instead_of_counting_it(monkeypatch) -> None:
    monkeypatch.setattr(EconomyService, "kst_today_key", lambda self, now=None: "2026-10-04")
    monkeypatch.setattr(EconomyService, "kst_week_key", lambda self, now=None: "2026-09-28")
    db = _MemoryDb()
    db.store["users/u1"] = {"wallet": {"diamondBalance": 1, "shareBalance": 3}}
    for offset in (0, 2, 3, 4, 5, 6):
        day = (datetime(2026, 10, 4) - timedelta(days=offset)).date().isoformat()
        db.store[f"users/u1/daily_metrics/{day}"] = {"km": 1}
    db.store["users/u1/daily_metrics/2026-10-03"] = {"streakPaused": "rest"}
    service = _service(db)

    short = _commit_streak_bonus_tx.to_wrap(
        _MemoryTxn(), service, "u1", db.collection("users").document("u1")
    )
    assert short.status == "not_eligible"
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 1

    db.store["users/u1/daily_metrics/2026-09-27"] = {"km": 1}
    claimed = _commit_streak_bonus_tx.to_wrap(
        _MemoryTxn(), service, "u1", db.collection("users").document("u1")
    )
    assert claimed.status == "claimed"
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 11


def test_insufficient_value_writes_nothing() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _user(value=49)

    with pytest.raises(HTTPException) as raised:
        _buy(db, REST, "req-rest-poor")
    assert raised.value.detail == "Insufficient Value balance."
    assert db.store["users/u1"]["wallet"]["valueTokenBalance"] == 49
    assert _wallet_rows(db) == []
    assert "users/u1/shopInventory/rest_day_ticket" not in db.store


def test_donation_match_records_company_won_and_the_user() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _user(value=100)
    db.store["config/item_prices"] = {
        MATCH: 80,
        "donation_match_won": 1000,
        "donation_match_sponsor": "SRC",
    }

    result = _match(db, "req-match-0001")

    assert result.status == "matched"
    assert result.value_token_balance == 20
    assert result.share_balance == 10
    assert result.diamond_balance == 4
    user = db.store["users/u1"]
    assert user["wallet"]["valueTokenBalance"] == 20
    assert user["wallet"]["shareBalance"] == 10
    assert "totalDonationValue" not in user["wallet"]
    assert user["donationMatchMonth"] == {"monthKey": "2026-10", "count": 1}
    wallet = _wallet_rows(db)[0]
    assert wallet["type"] == "donation_match"
    assert wallet["valueAmount"] == -80
    assert wallet["companyWon"] == 1000
    assert wallet["sponsorName"] == "SRC"
    assert wallet["contributorName"] == "러너상"
    assert wallet["receiptIssued"] is False
    assert "shareAmount" not in wallet
    path, donation = _donations(db)[0]
    assert path == "donationLedger/donation_match_u1_req-match-0001"
    assert donation["sponsorName"] == "SRC"
    assert donation["contributorName"] == "러너상"
    assert donation["companyWon"] == 1000
    assert donation["donationTarget"] == "UNICEF"
    assert donation["valueAmount"] == -80
    assert donation["receiptIssued"] is False
    assert db.store["donationPools/2026-10"]["totalWon"] == 1000

    replay = _match(db, "req-match-0001")
    assert replay.status == "already_matched"
    assert db.store["users/u1"]["wallet"]["valueTokenBalance"] == 20
    assert db.store["donationPools/2026-10"]["totalWon"] == 1000
    assert len(_donations(db)) == 1
    assert len(_wallet_rows(db)) == 1


def test_donation_match_user_cap_rejects_without_debit() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _user(
        value=500,
        donationMatchMonth={"monthKey": "2026-10", "count": 1},
    )

    with pytest.raises(HTTPException) as raised:
        _match(db, "req-match-0002")
    assert raised.value.detail == "Donation match monthly cap reached."
    assert db.store["users/u1"]["wallet"]["valueTokenBalance"] == 500
    assert _wallet_rows(db) == []
    assert _donations(db) == []
    assert "donationPools/2026-10" not in db.store


def test_donation_match_company_cap_rejects_without_debit() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _user(value=100)
    db.store["users/u2"] = _user(value=100)
    db.store["config/item_prices"] = {"donation_match_company_cap_won": 1000}
    db.store["donationPools/2026-10"] = {"totalWon": 1000, "sponsorName": "SRC"}

    with pytest.raises(HTTPException) as raised:
        _match(db, "req-match-cap", uid="u2")
    assert raised.value.detail == "Donation match company cap reached."
    assert db.store["users/u2"]["wallet"]["valueTokenBalance"] == 100
    assert db.store["donationPools/2026-10"]["totalWon"] == 1000
    assert _wallet_rows(db) == []
    assert _donations(db) == []


def test_donation_match_stops_at_the_company_cap() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _user(value=100)
    db.store["users/u2"] = _user(value=100)
    db.store["config/item_prices"] = {"donation_match_company_cap_won": 1000}

    first = _match(db, "req-match-a")
    assert first.status == "matched"
    assert db.store["donationPools/2026-10"]["totalWon"] == 1000

    with pytest.raises(HTTPException) as raised:
        _match(db, "req-match-b", uid="u2")
    assert raised.value.detail == "Donation match company cap reached."
    assert db.store["users/u2"]["wallet"]["valueTokenBalance"] == 100
    assert db.store["donationPools/2026-10"]["totalWon"] == 1000


def test_generic_shop_path_does_not_sell_value_items() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _user()
    service = _service(db)
    user_ref = db.collection("users").document("u1")

    with pytest.raises(HTTPException) as bought:
        service._purchase_shop_item_tx(_MemoryTxn(), "u1", REST, user_ref)
    assert bought.value.detail == "request_id is required."

    with pytest.raises(HTTPException) as used:
        service._use_shop_item_tx(_MemoryTxn(), "u1", MATCH, user_ref)
    assert used.value.detail == "request_id is required."
    assert db.store["users/u1"]["wallet"]["valueTokenBalance"] == 200
    assert _wallet_rows(db) == []