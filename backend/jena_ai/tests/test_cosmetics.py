"""Cosmetics charge free DIA first, once, and do not touch rankings."""

from types import SimpleNamespace

from fastapi import HTTPException
import pytest

from app.services.cosmetics import (
    FREE_ITEM,
    NO_LONGER_SOLD,
    ALREADY_OWNED,
    CURRENT_SEASON,
    LOADOUT_ID,
    MAX_LIMITED_PRICE,
    MAX_PRICE,
    MIN_PRICE,
    NOT_ON_SALE,
    NOT_OWNED,
    NOT_SPENT,
    resolve_cosmetics_catalog,
)
from app.services.secured_action_service import (
    SecuredActionService,
    _commit_cosmetic_equip_tx,
    _commit_cosmetic_purchase_tx,
    _commit_shop_tx,
    _commit_use_shop_tx,
)
from test_redeem_referral import _MemoryDb, _MemoryTxn

AVATAR = "avatar_snail"
WOLF = "avatar_season_wolf"
SEASON_SHOE = "shoe_season_gold"
SHOE = "shoe_mint"
FRAME = "frame_blue"


def _service(db: _MemoryDb) -> SecuredActionService:
    return SecuredActionService(firebase_service=SimpleNamespace(db=db))


def _wallet(free: int = 100, paid: int = 50) -> dict:
    return {
        "rankScore": 9,
        "wallet": {
            "diamondBalance": free + paid,
            "freeDiamondBalance": free,
            "paidDiamondBalance": paid,
            "shareBalance": 4000,
            "freeShareBalance": 4000,
            "paidShareBalance": 0,
            "valueTokenBalance": 7,
        },
    }


def _buy(db: _MemoryDb, item_id: str, request_id: str):
    service = _service(db)
    user_ref = db.collection("users").document("u1")
    return _commit_cosmetic_purchase_tx.to_wrap(
        _MemoryTxn(), service, "u1", item_id, request_id, user_ref
    )


def _equip(db: _MemoryDb, item_id: str, request_id: str, equip: bool = True):
    service = _service(db)
    user_ref = db.collection("users").document("u1")
    return _commit_cosmetic_equip_tx.to_wrap(
        _MemoryTxn(), service, "u1", item_id, request_id, user_ref, equip
    )


def _ledger(db: _MemoryDb) -> list[dict]:
    return [
        row
        for path, row in db.store.items()
        if path.startswith("walletTransactions/")
    ]


def test_defaults_cover_three_categories_and_a_bad_price_stays_default() -> None:
    catalog = resolve_cosmetics_catalog(None)
    assert catalog["season"] == CURRENT_SEASON
    by_category: dict[str, list] = {}
    for row in catalog["items"]:
        by_category.setdefault(row["category"], []).append(row)
        ceiling = MAX_LIMITED_PRICE if row["limited"] else MAX_PRICE
        assert MIN_PRICE <= row["price"] <= ceiling
        assert row["name"]
    assert len(by_category["runner_avatar"]) == 4
    assert len(by_category["shoe_skin"]) == 4
    assert len(by_category["share_frame"]) == 4
    assert resolve_cosmetics_catalog(None)["items"][0]["price"] == 30

    overridden = resolve_cosmetics_catalog(
        {
            "season": "NOPE",
            "items": {
                AVATAR: {"price": 10, "name": ""},
                WOLF: {"price": 250},
                "bonus_frame": {
                    "name": "보너스 프레임",
                    "category": "share_frame",
                    "price": 180,
                    "limited": False,
                    "season": "",
                    "accent": "mint",
                },
                "gacha_box": {
                    "name": "랜덤 상자",
                    "category": "share_frame",
                    "price": 5,
                    "limited": False,
                    "season": "",
                },
            },
        }
    )
    prices = {row["id"]: row for row in overridden["items"]}
    assert overridden["season"] == CURRENT_SEASON
    assert prices[AVATAR]["price"] == 30
    assert prices[AVATAR]["name"] == "달팽이 러너"
    assert prices[WOLF]["price"] == 250
    assert prices[WOLF]["limited"] is True
    assert prices["bonus_frame"]["name"] == "보너스 프레임"
    assert "gacha_box" not in prices


def test_catalog_endpoint_uses_the_config_doc() -> None:
    db = _MemoryDb()
    db.store["config/cosmetics_catalog"] = {
        "items": {AVATAR: {"price": 45, "name": "느린 달팽이"}}
    }
    catalog = _service(db).cosmetics_catalog()
    row = next(item for item in catalog["items"] if item["id"] == AVATAR)
    assert row["price"] == 45
    assert row["name"] == "느린 달팽이"


def test_purchase_spends_free_dia_first_and_replay_does_not_charge() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet()

    result = _buy(db, SHOE, "req-shoe01")

    assert result.status == "purchased"
    assert result.diamond_balance == 110
    assert result.share_balance == 4000
    assert result.value_token_balance == 7
    wallet = db.store["users/u1"]["wallet"]
    assert wallet["freeDiamondBalance"] == 60
    assert wallet["paidDiamondBalance"] == 50
    owned = db.store[f"users/u1/shopInventory/{SHOE}"]
    assert owned["quantity"] == 1
    assert owned["category"] == "shoe_skin"
    assert owned["title"] == "민트 러닝화"
    row = _ledger(db)[0]
    assert row["type"] == "shop_purchase"
    assert row["diamondAmount"] == -40
    assert row["diamondFreeAmount"] == -40
    assert row["diamondPaidAmount"] == 0
    assert row["itemId"] == SHOE
    assert db.store["users/u1"]["rankScore"] == 9
    assert not any(
        path.startswith(("activities/", "dailyMetrics/", "tournaments/", "rankings/"))
        for path in db.store
    )

    again = _buy(db, SHOE, "req-shoe01")
    assert again.status == "already_purchased"
    assert wallet["diamondBalance"] == 110
    assert len(_ledger(db)) == 1
    assert owned["quantity"] == 1


def test_second_request_does_not_sell_another_copy() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet()
    _buy(db, SHOE, "req-shoe01")
    with pytest.raises(HTTPException) as exc:
        _buy(db, SHOE, "req-shoe02")
    assert exc.value.detail == ALREADY_OWNED
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 110
    assert len(_ledger(db)) == 1


def test_spend_uses_free_dia_then_paid() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet(free=20, paid=50)
    result = _buy(db, SHOE, "req-split01")
    assert result.status == "purchased"
    wallet = db.store["users/u1"]["wallet"]
    assert wallet["freeDiamondBalance"] == 0
    assert wallet["paidDiamondBalance"] == 30
    assert wallet["diamondBalance"] == 30
    row = _ledger(db)[0]
    assert row["diamondFreeAmount"] == -20
    assert row["diamondPaidAmount"] == -20


def test_free_dia_alone_can_buy_and_a_short_balance_does_not() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet(free=40, paid=0)
    result = _buy(db, SHOE, "req-shoe01")
    assert result.status == "purchased"
    assert db.store["users/u1"]["wallet"]["freeDiamondBalance"] == 0
    assert db.store["users/u1"]["wallet"]["paidDiamondBalance"] == 0

    short = _MemoryDb()
    short.store["users/u1"] = _wallet(free=10, paid=10)
    with pytest.raises(HTTPException) as exc:
        _buy(short, SHOE, "req-shoe02")
    assert exc.value.detail == "Insufficient Diamond balance."
    assert short.store["users/u1"]["wallet"]["diamondBalance"] == 20
    assert f"users/u1/shopInventory/{SHOE}" not in short.store


def test_season_item_follows_the_config_season() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet(free=400, paid=0)
    bought = _buy(db, SEASON_SHOE, "req-gold001")
    assert bought.status == "purchased"
    assert db.store["users/u1"]["wallet"]["freeDiamondBalance"] == 100

    closed = _MemoryDb()
    closed.store["users/u1"] = _wallet(free=400, paid=0)
    closed.store["config/cosmetics_catalog"] = {"season": "season_2"}
    with pytest.raises(HTTPException) as exc:
        _buy(closed, SEASON_SHOE, "req-gold002")
    assert exc.value.detail == NOT_ON_SALE
    assert closed.store["users/u1"]["wallet"]["diamondBalance"] == 400


def test_equip_and_unequip_are_server_side_and_free() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet()
    _buy(db, FRAME, "req-frame01")
    equipped = _equip(db, FRAME, "req-equip01")
    assert equipped.status == "equipped"
    slot = db.store[f"users/u1/shopInventory/{LOADOUT_ID}"]["slots"]["share_frame"]
    assert slot["id"] == FRAME
    assert slot["accent"] == "blue"
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 100
    equip_rows = [row for row in _ledger(db) if row["type"] == "cosmetic_equip"]
    assert equip_rows[0]["diamondAmount"] == 0
    assert equip_rows[0]["equipped"] is True

    again = _equip(db, FRAME, "req-equip01")
    assert again.status == "already_equipped"
    assert len([row for row in _ledger(db) if row["type"] == "cosmetic_equip"]) == 1

    _buy(db, "frame_pink", "req-frame02")
    swapped = _equip(db, "frame_pink", "req-equip03")
    assert swapped.status == "equipped"
    assert (
        db.store[f"users/u1/shopInventory/{LOADOUT_ID}"]["slots"]["share_frame"]["id"]
        == "frame_pink"
    )
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 10

    left = _equip(db, FRAME, "req-equip02", equip=False)
    assert left.status == "unequipped"
    assert (
        db.store[f"users/u1/shopInventory/{LOADOUT_ID}"]["slots"]["share_frame"]["id"]
        == "frame_pink"
    )
    cleared = _equip(db, "frame_pink", "req-equip04", equip=False)
    assert cleared.status == "unequipped"
    assert (
        db.store[f"users/u1/shopInventory/{LOADOUT_ID}"]["slots"]["share_frame"]["id"]
        == ""
    )
    assert db.store["users/u1"]["rankScore"] == 9


def test_equip_requires_ownership_and_use_does_not_consume() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet()
    with pytest.raises(HTTPException) as missing:
        _equip(db, SHOE, "req-equip03")
    assert missing.value.detail == NOT_OWNED
    assert f"users/u1/shopInventory/{LOADOUT_ID}" not in db.store

    _buy(db, SHOE, "req-shoe01")
    service = _service(db)
    user_ref = db.collection("users").document("u1")
    with pytest.raises(HTTPException) as used:
        _commit_use_shop_tx.to_wrap(_MemoryTxn(), service, "u1", SHOE, user_ref)
    assert used.value.detail == NOT_SPENT
    assert db.store[f"users/u1/shopInventory/{SHOE}"]["quantity"] == 1


def test_generic_shop_purchase_does_not_sell_a_cosmetic() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet()
    service = _service(db)
    user_ref = db.collection("users").document("u1")
    with pytest.raises(HTTPException) as exc:
        _commit_shop_tx.to_wrap(_MemoryTxn(), service, "u1", AVATAR, user_ref)
    assert exc.value.status_code == 404
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 150
    assert not any(path.startswith("walletTransactions/") for path in db.store)


def test_short_request_id_is_rejected() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet()
    with pytest.raises(HTTPException) as exc:
        _buy(db, AVATAR, "short")
    assert exc.value.detail == "request_id is required."
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 150


def test_animal_avatars_are_no_longer_sold_but_owners_keep_them() -> None:
    for animal in ("avatar_rabbit", "avatar_cheetah", WOLF):
        db = _MemoryDb()
        db.store["users/u1"] = _wallet(free=400, paid=0)
        with pytest.raises(HTTPException) as exc:
            _buy(db, animal, "req-animal1")
        assert exc.value.detail == NO_LONGER_SOLD
        assert db.store["users/u1"]["wallet"]["diamondBalance"] == 400
        assert not any(path.startswith("walletTransactions/") for path in db.store)

    owner = _MemoryDb()
    owner.store["users/u1"] = _wallet()
    owner.store["users/u1/shopInventory/avatar_rabbit"] = {
        "itemId": "avatar_rabbit",
        "quantity": 1,
        "category": "runner_avatar",
    }
    equipped = _equip(owner, "avatar_rabbit", "req-equip10")
    assert equipped.status == "equipped"
    slot = owner.store[f"users/u1/shopInventory/{LOADOUT_ID}"]["slots"]["runner_avatar"]
    assert slot["id"] == "avatar_rabbit"


def test_the_snail_is_free_for_everyone_and_cannot_be_bought() -> None:
    db = _MemoryDb()
    db.store["users/u1"] = _wallet()
    with pytest.raises(HTTPException) as exc:
        _buy(db, AVATAR, "req-snail01")
    assert exc.value.detail == FREE_ITEM

    equipped = _equip(db, AVATAR, "req-equip20")
    assert equipped.status == "equipped"
    slot = db.store[f"users/u1/shopInventory/{LOADOUT_ID}"]["slots"]["runner_avatar"]
    assert slot["id"] == AVATAR
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 150
    assert f"users/u1/shopInventory/{AVATAR}" not in db.store

    left = _equip(db, AVATAR, "req-equip21", equip=False)
    assert left.status == "unequipped"


def test_a_config_doc_cannot_put_a_retired_animal_back_on_sale() -> None:
    catalog = resolve_cosmetics_catalog(
        {"items": {"avatar_rabbit": {"price": 50, "retired": False}}}
    )
    row = next(item for item in catalog["items"] if item["id"] == "avatar_rabbit")
    assert row["retired"] is True
    snail = next(item for item in catalog["items"] if item["id"] == AVATAR)
    assert snail["free"] is True
