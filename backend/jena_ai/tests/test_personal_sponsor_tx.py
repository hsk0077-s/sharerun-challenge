"""Personal sponsor SHARE debit, angel totals, and one ledger row."""

from types import SimpleNamespace

from fastapi import HTTPException
import pytest

from app.services.item_price_config import resolve_item_prices
from app.services.personal_sponsor import angel_tier_code, donate_personal_sponsor
from app.services.secured_action_service import SecuredActionService
from test_redeem_referral import _MemoryDb, _MemoryTxn


def _service(db: _MemoryDb) -> SecuredActionService:
    return SecuredActionService(firebase_service=SimpleNamespace(db=db))


def _donate(
    db: _MemoryDb,
    request_id: str = "req-sponsor-1",
    purpose: str = "donation",
    uid: str = "u1",
):
    service = _service(db)
    return donate_personal_sponsor(
        service,
        _MemoryTxn(),
        uid,
        request_id,
        purpose,
        db.collection("users").document(uid),
    )


def _user(**wallet) -> dict:
    base = {
        "shareBalance": 80_000,
        "freeShareBalance": 30_000,
        "paidShareBalance": 50_000,
        "diamondBalance": 9,
        "valueTokenBalance": 4,
    }
    base.update(wallet)
    return {"wallet": base}


def _ledger(db: _MemoryDb) -> list[tuple[str, dict]]:
    return [
        (path, row)
        for path, row in db.store.items()
        if path.startswith("walletTransactions/")
    ]


def test_default_price_is_50000_share() -> None:
    prices = resolve_item_prices(None)
    assert prices["personal_sponsor_share"] == 50_000
    assert prices["personal_sponsor_won_per_share"] == 1
    kept = resolve_item_prices(
        {"personal_sponsor_share": 0, "personal_sponsor_won_per_share": "1"}
    )
    assert kept["personal_sponsor_share"] == 50_000
    assert kept["personal_sponsor_won_per_share"] == 1


def test_sponsor_debits_free_share_first_and_sets_guardian() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _user()

    result = _donate(db)

    assert result.status == "sponsored"
    assert result.share_spent == 50_000
    assert result.share_balance == 30_000
    assert result.diamond_balance == 9
    assert result.value_token_balance == 4
    assert result.donation_count == 1
    assert result.cumulative_donation_amount == 50_000
    assert result.angel_tier_code == "guardian"
    assert result.is_sponsored is True
    user = db.store["users/u1"]
    wallet = user["wallet"]
    assert wallet["shareBalance"] == 30_000
    assert wallet["freeShareBalance"] == 0
    assert wallet["paidShareBalance"] == 30_000
    assert wallet["diamondBalance"] == 9
    assert wallet["valueTokenBalance"] == 4
    assert user["donationCount"] == 1
    assert user["cumulativeDonationAmount"] == 50_000
    assert user["isSponsored"] is True
    assert user["angelTierCode"] == "guardian"
    rows = _ledger(db)
    assert len(rows) == 1
    assert rows[0][0] == "walletTransactions/personal_sponsor_u1_req-sponsor-1"
    row = rows[0][1]
    assert row["type"] == "personal_sponsor_donation"
    assert row["shareAmount"] == -50_000
    assert row["shareFreeAmount"] == -30_000
    assert row["sharePaidAmount"] == -20_000
    assert row["uid"] == "u1"
    assert "valueAmount" not in row
    assert "diamondAmount" not in row


def test_same_request_id_does_not_charge_twice() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _user()

    first = _donate(db)
    second = _donate(db)

    assert first.status == "sponsored"
    assert second.status == "already_sponsored"
    assert second.share_balance == 30_000
    assert second.donation_count == 1
    assert second.share_spent == 50_000
    assert db.store["users/u1"]["wallet"]["shareBalance"] == 30_000
    assert db.store["users/u1"]["donationCount"] == 1
    assert len(_ledger(db)) == 1


def test_insufficient_share_writes_nothing() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _user(
        shareBalance=49_999,
        freeShareBalance=49_999,
        paidShareBalance=0,
        diamondBalance=1_000_000,
    )

    with pytest.raises(HTTPException) as raised:
        _donate(db)

    assert raised.value.status_code == 400
    assert raised.value.detail == "Insufficient Share balance."
    wallet = db.store["users/u1"]["wallet"]
    assert wallet["shareBalance"] == 49_999
    assert wallet["diamondBalance"] == 1_000_000
    assert "donationCount" not in db.store["users/u1"]
    assert _ledger(db) == []


def test_config_price_and_won_rate_override_the_client_amount() -> None:
    db = _MemoryDb()
    db.store["config/item_prices"] = {
        "personal_sponsor_share": 1_000,
        "personal_sponsor_won_per_share": 50,
    }
    db.store["users/u1"] = _user(shareBalance=1_000, freeShareBalance=1_000, paidShareBalance=0)

    result = _donate(db, purpose="prize")

    assert result.share_spent == 1_000
    assert result.share_balance == 0
    assert result.cumulative_donation_amount == 50_000
    assert result.angel_tier_code == "guardian"
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 9
    row = _ledger(db)[0][1]
    assert row["type"] == "personal_sponsor_prize"
    assert row["shareAmount"] == -1_000
    assert row["purpose"] == "prize"


def test_missing_user_does_not_open_a_ledger_row() -> None:
    db = _MemoryDb()

    with pytest.raises(HTTPException) as raised:
        _donate(db)

    assert raised.value.status_code == 404
    assert _ledger(db) == []


def test_angel_ladder_matches_the_client() -> None:
    assert angel_tier_code(0, 9_999_999) == "pre_angel"
    assert angel_tier_code(1, 0) == "cupid"
    assert angel_tier_code(4, 50_000) == "guardian"
    assert angel_tier_code(20, 0) == "archangel"
    assert angel_tier_code(1, 1_000_000) == "cherubim"
    assert angel_tier_code(100, 0) == "seraphim"
