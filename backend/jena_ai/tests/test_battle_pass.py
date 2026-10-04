"""배틀런 패스 charges paid DIA once per season and grants cosmetics."""

from types import SimpleNamespace

from fastapi import HTTPException
import pytest

from app.services.battle_pass import (
    ALREADY_OWNED,
    NOT_SPENT,
    PAID_SHORT,
    PLUS_REWARDS,
    PASS_REWARDS,
    reward_rows,
)
from app.services.item_price_config import resolve_item_prices
from app.services.secured_action_service import (
    SecuredActionService,
    _commit_battle_pass_purchase_tx,
    _commit_shop_tx,
    _commit_use_shop_tx,
)
from test_redeem_referral import _MemoryDb, _MemoryTxn

PASS = "battle_run_pass"
PLUS = "battle_run_pass_plus"


def _service(db: _MemoryDb) -> SecuredActionService:
    return SecuredActionService(firebase_service=SimpleNamespace(db=db))


def _wallet(diamond: int = 500, free: int = 300, paid: int = 200, share: int = 40_000) -> dict:
    return {
        "wallet": {
            "diamondBalance": diamond,
            "freeDiamondBalance": free,
            "paidDiamondBalance": paid,
            "shareBalance": share,
            "freeShareBalance": share,
            "paidShareBalance": 0,
            "valueTokenBalance": 9,
        }
    }


def _buy(db: _MemoryDb, item_id: str, request_id: str):
    service = _service(db)
    user_ref = db.collection("users").document("u1")
    return _commit_battle_pass_purchase_tx.to_wrap(
        _MemoryTxn(), service, "u1", item_id, request_id, user_ref
    )


def _ledger(db: _MemoryDb) -> list[dict]:
    return [
        row
        for path, row in db.store.items()
        if path.startswith("walletTransactions/")
    ]


def _pass_doc(db: _MemoryDb) -> dict:
    return db.store[f"users/u1/shopInventory/{PASS}"]


def test_prices_default_and_a_bad_override_keeps_the_code_price() -> None:
    assert resolve_item_prices(None)[PASS] == 120
    assert resolve_item_prices(None)[PLUS] == 200
    overridden = resolve_item_prices({PASS: 0, PLUS: True})
    assert overridden[PASS] == 120
    assert overridden[PLUS] == 200
    applied = resolve_item_prices({PASS: 90, PLUS: 180})
    assert applied[PASS] == 90
    assert applied[PLUS] == 180


def test_catalog_uses_the_config_price() -> None:
    db = _MemoryDb()
    db.store["config/item_prices"] = {PASS: 90, PLUS: 160}
    prices = {row["id"]: row["diamondCost"] for row in _service(db).shop_catalog()}
    assert prices[PASS] == 90
    assert prices[PLUS] == 160


def test_pass_spends_paid_dia_only_and_replay_is_free() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet()

    result = _buy(db, PASS, "req-pass-01")

    assert result.status == "purchased"
    assert result.diamond_balance == 380
    assert result.share_balance == 40_000
    assert result.value_token_balance == 9
    wallet = db.store["users/u1"]["wallet"]
    assert wallet["freeDiamondBalance"] == 300
    assert wallet["paidDiamondBalance"] == 80
    doc = _pass_doc(db)
    assert doc["quantity"] == 1
    assert doc["seasonId"] == "season_1"
    assert doc["tier"] == "pass"
    assert doc["rewards"] == reward_rows("pass")
    row = _ledger(db)[0]
    assert row["type"] == "shop_purchase"
    assert row["diamondAmount"] == -120
    assert row["diamondFreeAmount"] == 0
    assert row["diamondPaidAmount"] == -120
    assert row["itemId"] == PASS
    assert row["tier"] == "pass"

    again = _buy(db, PASS, "req-pass-01")
    assert again.status == "already_purchased"
    assert wallet["paidDiamondBalance"] == 80
    assert len(_ledger(db)) == 1
    assert _pass_doc(db)["tier"] == "pass"


def test_free_dia_cannot_buy_even_when_it_covers_the_price() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet(diamond=500, free=500, paid=0)
    with pytest.raises(HTTPException) as exc:
        _buy(db, PASS, "req-pass-free")
    assert exc.value.detail == PAID_SHORT
    wallet = db.store["users/u1"]["wallet"]
    assert wallet["diamondBalance"] == 500
    assert wallet["freeDiamondBalance"] == 500
    assert wallet["paidDiamondBalance"] == 0
    assert not _ledger(db)
    assert f"users/u1/shopInventory/{PASS}" not in db.store


def test_paid_shortfall_rejects_when_free_would_make_up_the_rest() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet(diamond=400, free=300, paid=100)
    with pytest.raises(HTTPException) as exc:
        _buy(db, PLUS, "req-plus-short")
    assert exc.value.detail == PAID_SHORT
    assert db.store["users/u1"]["wallet"]["paidDiamondBalance"] == 100
    assert not _ledger(db)


def test_a_second_request_cannot_buy_the_same_season_again() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet()
    _buy(db, PASS, "req-pass-01")
    with pytest.raises(HTTPException) as exc:
        _buy(db, PASS, "req-pass-02")
    assert exc.value.detail == ALREADY_OWNED
    assert db.store["users/u1"]["wallet"]["paidDiamondBalance"] == 80
    assert len(_ledger(db)) == 1


def test_plus_grants_extra_cosmetics_and_upgrade_charges_the_difference() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet(diamond=400, free=0, paid=400)

    direct = _MemoryDb()
    direct.store["users/u1"] = _wallet(diamond=400, free=0, paid=400)
    bought = _buy(direct, PLUS, "req-plus-01")
    assert bought.diamond_balance == 200
    assert _pass_doc(direct)["tier"] == "plus"
    assert _pass_doc(direct)["rewards"] == reward_rows("plus")
    assert _ledger(direct)[0]["diamondAmount"] == -200
    assert _ledger(direct)[0]["diamondPaidAmount"] == -200
    assert _ledger(direct)[0]["diamondFreeAmount"] == 0

    _buy(db, PASS, "req-pass-01")
    upgraded = _buy(db, PLUS, "req-plus-02")
    assert upgraded.status == "purchased"
    assert db.store["users/u1"]["wallet"]["paidDiamondBalance"] == 200
    assert db.store["users/u1"]["wallet"]["freeDiamondBalance"] == 0
    assert _pass_doc(db)["tier"] == "plus"
    assert _pass_doc(db)["quantity"] == 1
    assert _pass_doc(db)["rewards"] == reward_rows("plus")
    amounts = [row["diamondAmount"] for row in _ledger(db)]
    assert amounts == [-120, -80]

    with pytest.raises(HTTPException) as exc:
        _buy(db, PLUS, "req-plus-03")
    assert exc.value.detail == ALREADY_OWNED
    with pytest.raises(HTTPException) as again:
        _buy(db, PASS, "req-pass-03")
    assert again.value.detail == ALREADY_OWNED
    assert db.store["users/u1"]["wallet"]["paidDiamondBalance"] == 200
    assert len(_ledger(db)) == 2


def test_config_prices_change_the_upgrade_gap() -> None:
    db = _MemoryDb()
    db.store["config/item_prices"] = {PASS: 100, PLUS: 150}
    db.store["users/u1"] = _wallet(diamond=300, free=0, paid=300)
    _buy(db, PASS, "req-pass-cfg")
    _buy(db, PLUS, "req-plus-cfg")
    assert [row["diamondAmount"] for row in _ledger(db)] == [-100, -50]
    assert db.store["users/u1"]["wallet"]["paidDiamondBalance"] == 150


def test_legacy_quantity_upgrades_for_the_difference() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet(diamond=100, free=0, paid=100)
    db.store[f"users/u1/shopInventory/{PASS}"] = {"quantity": 1}
    result = _buy(db, PLUS, "req-legacy-01")
    assert result.diamond_balance == 20
    assert _pass_doc(db)["tier"] == "plus"
    assert _ledger(db)[0]["diamondAmount"] == -80


def test_rewards_are_cosmetic_only() -> None:
    rows = reward_rows("plus")
    ids = [row["id"] for row in rows]
    assert [row["id"] for row in PASS_REWARDS] == ids[:2]
    assert [row["id"] for row in PLUS_REWARDS] == ids[2:]
    assert {row["kind"] for row in rows} <= {"frame", "skin", "badge"}
    for row in rows:
        assert set(row) == {"id", "kind", "title"}


def test_generic_shop_path_cannot_sell_or_spend_the_pass() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet()
    service = _service(db)
    user_ref = db.collection("users").document("u1")
    with pytest.raises(HTTPException) as exc:
        _commit_shop_tx.to_wrap(_MemoryTxn(), service, "u1", PASS, user_ref)
    assert exc.value.detail == "request_id is required."
    assert not _ledger(db)

    db.store[f"users/u1/shopInventory/{PASS}"] = {
        "quantity": 1,
        "tier": "pass",
        "seasonId": "season_1",
    }
    with pytest.raises(HTTPException) as used:
        _commit_use_shop_tx.to_wrap(_MemoryTxn(), service, "u1", PASS, user_ref)
    assert used.value.detail == NOT_SPENT
    assert db.store[f"users/u1/shopInventory/{PASS}"]["quantity"] == 1


def test_unsplit_balance_counts_as_free_and_cannot_buy() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = {"wallet": {"diamondBalance": 500, "shareBalance": 10}}
    with pytest.raises(HTTPException) as exc:
        _buy(db, PASS, "req-unsplit")
    assert exc.value.detail == PAID_SHORT
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 500
    assert not _ledger(db)
