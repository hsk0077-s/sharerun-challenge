"""Buying and wearing accessories and skins."""

from pathlib import Path
from types import SimpleNamespace
import importlib.util

from fastapi import HTTPException
import pytest

from app.services import accessories as acc
from app.services.accessory_catalog import ACCESSORIES
from test_redeem_referral import _MemoryDb, _MemoryTxn


def _db(user: dict | None = None) -> _MemoryDb:
    db = _MemoryDb()
    db.store["users/u1"] = user or {
        "gradeRank": 0,
        "wallet": {"shareBalance": 1000, "diamondBalance": 500, "freeDiamondBalance": 100, "paidDiamondBalance": 400},
    }
    return db


def _buy(db, item_id, request_id="req-acc-0001"):
    service = SimpleNamespace(firebase_service=SimpleNamespace(db=db))
    return acc.purchase(service, _MemoryTxn(), "u1", item_id, request_id, db.collection("users").document("u1"))


def _equip(db, slot, item_id):
    service = SimpleNamespace(firebase_service=SimpleNamespace(db=db))
    return acc.equip(service, _MemoryTxn(), "u1", slot, item_id, db.collection("users").document("u1"))


def test_the_server_list_matches_the_apps_list() -> None:
    root = Path(__file__).resolve().parents[3]
    spec = importlib.util.spec_from_file_location("gen", root / "tool/gen_accessory_catalog.py")
    gen = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(gen)
    parsed = gen.parse((root / "lib/features/accessories/accessory_catalog.dart").read_text(encoding="utf-8"))
    assert parsed == list(ACCESSORIES), "run: python3 tool/gen_accessory_catalog.py"


def test_what_is_for_sale() -> None:
    sale = [i for i in ACCESSORIES if acc.for_sale(i)]
    assert len(sale) == 44  # 46 less the tier-reward laurel and the unfinished angel wings
    assert sum(1 for i in sale if i["currency"] == "dia") == 34
    assert sum(1 for i in sale if i["currency"] == "share") == 10
    assert not acc.for_sale(acc.find("P047"))


def test_dia_purchase_takes_bonus_first_and_marks_ownership() -> None:
    db = _db()
    result = _buy(db, "P004")  # 40 DIA
    assert result.status == "purchased" and result.diamond_balance == 460
    wallet = db.store["users/u1"]["wallet"]
    assert (wallet["freeDiamondBalance"], wallet["paidDiamondBalance"]) == (60, 400)
    inventory = db.store["users/u1/shopInventory/P004"]
    assert inventory["quantity"] == 1 and inventory["category"] == "accessory" and inventory["slot"] == "head"


def test_share_items_cost_share_not_dia() -> None:
    db = _db()
    assert _buy(db, "P001").share_balance == 600  # 400 SHARE
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 500


def test_the_same_request_charges_once_and_an_owned_item_is_refused() -> None:
    db = _db()
    _buy(db, "P004")
    assert _buy(db, "P004").status == "already_purchased"
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 460
    with pytest.raises(HTTPException) as caught:
        _buy(db, "P004", "req-acc-0002")
    assert caught.value.status_code == 400


def test_not_enough_money_buys_nothing() -> None:
    db = _db({"wallet": {"shareBalance": 0, "diamondBalance": 10}})
    with pytest.raises(HTTPException):
        _buy(db, "P004")
    assert "users/u1/shopInventory/P004" not in db.store


def test_the_tier_reward_and_unfinished_items_are_not_sold() -> None:
    db = _db()
    for item_id in ("P015", "P047", "NOPE"):
        with pytest.raises(HTTPException) as caught:
            _buy(db, item_id)
        assert caught.value.status_code == 404


def test_a_master_skin_needs_its_tier() -> None:
    wolf_skin = acc.find("S003")
    assert wolf_skin["tier_lock"] == "wolf" and wolf_skin["price"] == 250
    db = _db({"gradeRank": 7, "wallet": {"diamondBalance": 1000, "paidDiamondBalance": 1000}})  # beagle
    with pytest.raises(HTTPException) as caught:
        _buy(db, "S003")
    assert caught.value.status_code == 403
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 1000
    db = _db({"gradeRank": 11, "wallet": {"diamondBalance": 1000, "paidDiamondBalance": 1000}})  # wolf bronze
    assert _buy(db, "S003").status == "purchased"
    db = _db({"gradeRank": 0, "wallet": {"diamondBalance": 1000}})  # snail
    with pytest.raises(HTTPException):
        _buy(db, "S001")


def test_animal_rank_follows_the_grade_table() -> None:
    assert acc.animal_rank({}) == 0
    assert [acc.animal_rank({"gradeRank": r}) for r in (1, 5, 6, 10, 11, 16, 21, 25)] == [1, 1, 2, 2, 3, 4, 5, 5]


def test_wearing_needs_ownership_and_the_right_slot() -> None:
    db = _db()
    with pytest.raises(HTTPException):
        _equip(db, "head", "P004")  # not owned
    _buy(db, "P004")
    with pytest.raises(HTTPException) as caught:
        _equip(db, "eyes", "P004")  # a head item
    assert caught.value.status_code == 400
    assert _equip(db, "head", "P004").status == "equipped"
    assert db.store["users/u1/shopInventory/accessory_loadout"]["slots"] == {"head": "P004"}
    assert _equip(db, "head", "").status == "unequipped"
    assert db.store["users/u1/shopInventory/accessory_loadout"]["slots"] == {}
    with pytest.raises(HTTPException):
        _equip(db, "tail", "")


def test_the_laurel_can_be_worn_once_graded_without_buying() -> None:
    db = _db({"gradeRank": 1, "wallet": {}})
    assert _equip(db, "head", "P015").status == "equipped"
    db = _db({"gradeRank": 0, "wallet": {}})
    with pytest.raises(HTTPException):
        _equip(db, "head", "P015")
