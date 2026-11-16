"""Costume skins v1: sports outfits (animal / character / set) and traditional costumes."""

from types import SimpleNamespace

from fastapi import HTTPException
import pytest

from app.services import accessories as acc
from app.services.accessory_catalog import ACCESSORIES
from test_redeem_referral import _MemoryDb, _MemoryTxn

SPORTS = ("W1", "W2", "W3", "W4", "W5", "W6")
COSTUMES = ("T1", "T2", "T3", "T4")


def _db(gender: str | None = None, diamonds: int = 1000) -> _MemoryDb:
    db = _MemoryDb()
    user = {
        "gradeRank": 0,
        "wallet": {
            "shareBalance": 0,
            "diamondBalance": diamonds,
            "freeDiamondBalance": 0,
            "paidDiamondBalance": diamonds,
        },
    }
    if gender is not None:
        user["gender"] = gender
    db.store["users/u1"] = user
    return db


def _service(db):
    return SimpleNamespace(firebase_service=SimpleNamespace(db=db))


def _buy(db, item_id, request_id="req-costume-01"):
    return acc.purchase(_service(db), _MemoryTxn(), "u1", item_id, request_id, db.collection("users").document("u1"))


def _equip(db, slot, item_id):
    return acc.equip(_service(db), _MemoryTxn(), "u1", slot, item_id, db.collection("users").document("u1"))


def _owned(db, item_id) -> bool:
    row = db.store.get(f"users/u1/shopInventory/{item_id}")
    return bool(row and row.get("quantity") == 1)


def _loadout(db) -> dict:
    return db.store.get("users/u1/shopInventory/accessory_loadout", {}).get("slots", {})


# ---- the agreed prices, pinned ----

def test_agreed_prices_are_fixed() -> None:
    price = {i["id"]: i["price"] for i in ACCESSORIES}
    for sport in SPORTS:
        assert price[sport + "A"] == 60  # sportswear for the animal
        assert price[sport + "C"] == 60  # sportswear for the character
        assert price[sport + "B"] == 90  # animal + character set
    for costume in COSTUMES:
        assert price[costume + "M"] == 120
        assert price[costume + "F"] == 120
        assert price[costume + "S"] == 200  # male + female set
    assert price["S008"] == 180 == acc.ANIMAL_SKIN_PRICE_DIA  # whole-animal skin unchanged
    assert acc.COURT_COSTUME_PRICE_DIA == {"single": 250, "pair": 420}
    assert all(i["currency"] == "dia" for i in ACCESSORIES if i["id"][0] in "WT")


def test_court_costumes_are_not_in_the_catalog_yet() -> None:
    assert not [i for i in ACCESSORIES if i["id"].startswith(("C", "R"))]
    assert len(ACCESSORIES) == 76


def test_sets_are_cheaper_than_their_parts_and_point_at_real_items() -> None:
    by_id = {i["id"]: i for i in ACCESSORIES}
    bundles = [i for i in ACCESSORIES if i["bundle"]]
    assert len(bundles) == 10  # 6 sports sets + 4 costume pairs
    for bundle in bundles:
        parts = [by_id[p] for p in bundle["bundle"]]
        assert len(parts) == 2 and not any(p["bundle"] for p in parts)
        assert bundle["price"] < sum(p["price"] for p in parts)


def test_targets_genders_and_names_of_the_new_items() -> None:
    by_id = {i["id"]: i for i in ACCESSORIES}
    for sport in SPORTS:
        assert (by_id[sport + "A"]["target"], by_id[sport + "A"]["slot"]) == ("animal", "outfit")
        assert (by_id[sport + "C"]["target"], by_id[sport + "C"]["gender"]) == ("character", "unisex")
        assert by_id[sport + "B"]["target"] == "both"
        assert by_id[sport + "A"]["parts"]
    for costume in COSTUMES:
        assert by_id[costume + "M"]["gender"] == "male" and by_id[costume + "F"]["gender"] == "female"
        assert all(by_id[costume + s]["target"] == "character" for s in "MFS")
        assert all(by_id[costume + s]["slot"] == "costume" for s in "MFS")
    # the old animal hanbok stays an animal skin
    assert by_id["S008"]["slot"] == "skin" and by_id["S008"]["target"] == "animal"


# ---- buying ----

def test_buying_a_set_opens_every_version_and_charges_once() -> None:
    db = _db()
    result = _buy(db, "T1S")
    assert result.status == "purchased" and result.diamond_balance == 800
    assert _owned(db, "T1M") and _owned(db, "T1F")
    assert not _owned(db, "T1S")  # the set itself is not an item
    assert db.store["users/u1/shopInventory/T1M"]["fromBundle"] == "T1S"
    ledgers = [k for k in db.store if k.startswith("walletTransactions/accessory_buy_")]
    assert len(ledgers) == 1 and db.store[ledgers[0]]["diamondAmount"] == -200


def test_sports_set_opens_the_animal_and_the_character_version() -> None:
    db = _db()
    assert _buy(db, "W3B").diamond_balance == 910
    assert _owned(db, "W3A") and _owned(db, "W3C")


def test_one_costume_version_opens_only_that_version() -> None:
    db = _db()
    assert _buy(db, "T2F").diamond_balance == 880
    assert _owned(db, "T2F") and not _owned(db, "T2M")


def test_set_is_refused_when_a_part_is_already_owned_and_nothing_is_charged() -> None:
    db = _db()
    _buy(db, "T1M", "req-costume-01")
    with pytest.raises(HTTPException) as error:
        _buy(db, "T1S", "req-costume-02")
    assert error.value.status_code == 400
    assert db.store["users/u1"]["wallet"]["diamondBalance"] == 880
    assert not _owned(db, "T1F")


def test_buying_the_same_thing_twice_is_refused() -> None:
    db = _db()
    _buy(db, "W1A", "req-costume-01")
    with pytest.raises(HTTPException) as error:
        _buy(db, "W1A", "req-costume-02")
    assert error.value.status_code == 400


def test_not_enough_diamonds_buys_nothing() -> None:
    db = _db(diamonds=199)
    with pytest.raises(HTTPException):
        _buy(db, "T3S")
    assert not _owned(db, "T3M") and not _owned(db, "T3F")


# ---- wearing ----

def test_animal_outfit_goes_in_the_outfit_slot_and_replaces_loose_clothes() -> None:
    db = _db()
    _buy(db, "W1A", "req-costume-01")
    db.store["users/u1/shopInventory/P058"] = {"quantity": 1, "category": "accessory"}
    _equip(db, "top", "P058")
    _equip(db, "outfit", "W1A")
    assert _loadout(db) == {"outfit": "W1A"}
    _equip(db, "top", "P058")  # loose clothes take the outfit off again
    assert _loadout(db) == {"top": "P058"}


def test_outfit_keeps_hand_eyes_back_and_head_items() -> None:
    db = _db()
    _buy(db, "W2A")
    for item in ("P004", "P031"):
        db.store[f"users/u1/shopInventory/{item}"] = {"quantity": 1, "category": "accessory"}
    _equip(db, "head", "P004")
    _equip(db, "hand", "P031")
    _equip(db, "outfit", "W2A")
    assert _loadout(db) == {"head": "P004", "hand": "P031", "outfit": "W2A"}


def test_a_set_cannot_be_worn() -> None:
    db = _db()
    _buy(db, "W1B")
    for slot in ("outfit", "costume"):
        with pytest.raises(HTTPException):
            _equip(db, slot, "W1B")


def test_an_animal_item_cannot_go_in_the_costume_slot_and_a_costume_not_on_the_animal() -> None:
    db = _db()
    _buy(db, "W1A", "req-costume-01")
    _buy(db, "W1C", "req-costume-02")
    with pytest.raises(HTTPException):
        _equip(db, "costume", "W1A")  # animal outfit: wrong slot
    with pytest.raises(HTTPException):
        _equip(db, "outfit", "W1C")  # character costume: wrong slot


def test_unowned_costume_cannot_be_worn() -> None:
    db = _db()
    with pytest.raises(HTTPException) as error:
        _equip(db, "costume", "T1M")
    assert error.value.status_code == 400


def test_gender_version_must_match_the_profile_gender() -> None:
    db = _db(gender="male")
    _buy(db, "T4S")  # owns both
    _equip(db, "costume", "T4M")
    assert _loadout(db)["costume"] == "T4M"
    with pytest.raises(HTTPException) as error:
        _equip(db, "costume", "T4F")
    assert error.value.status_code == 400 and "other gender" in error.value.detail


def test_missing_gender_counts_as_male_like_the_app() -> None:
    db = _db(gender=None)
    _buy(db, "T2S")
    _equip(db, "costume", "T2M")
    with pytest.raises(HTTPException):
        _equip(db, "costume", "T2F")


def test_unisex_sports_costume_fits_both_genders() -> None:
    for gender in ("male", "female"):
        db = _db(gender=gender)
        _buy(db, "W5C")
        _equip(db, "costume", "W5C")
        assert _loadout(db)["costume"] == "W5C"


def test_changing_gender_keeps_what_was_bought() -> None:
    db = _db(gender="female")
    _buy(db, "T3S")
    _equip(db, "costume", "T3F")
    db.store["users/u1"]["gender"] = "male"  # the profile gender changes
    assert _owned(db, "T3M") and _owned(db, "T3F")  # both versions stay in the inventory
    with pytest.raises(HTTPException):
        _equip(db, "costume", "T3F")  # the female version cannot be put on now
    _equip(db, "costume", "T3M")
    assert _loadout(db)["costume"] == "T3M"
    db.store["users/u1"]["gender"] = "female"
    _equip(db, "costume", "T3F")
    assert _loadout(db)["costume"] == "T3F"


def test_taking_the_costume_off() -> None:
    db = _db(gender="female")
    _buy(db, "T1F")
    _equip(db, "costume", "T1F")
    _equip(db, "costume", "")
    assert "costume" not in _loadout(db)
