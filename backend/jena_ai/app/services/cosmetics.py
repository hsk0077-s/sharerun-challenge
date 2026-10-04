"""Cosmetic shop: runner avatars, shoe skins, and share-card frames.

The catalog lives in ``config/cosmetics_catalog``. A missing doc or a bad
field keeps the code default, same rule as ``config/item_prices``. Prices
can change without an app update. Purchase spends free DIA first, then
paid, so prize DIA can buy these. The ledger document id is the request,
so a retry does not charge twice. One copy each. Equip is stored on the
account and does not change rankings or records.
"""

import re

from fastapi import HTTPException
from google.cloud.firestore_v1 import SERVER_TIMESTAMP

from app.models.secured_actions import SecuredActionResult
from app.services.streak_protection import require_request_id
from app.services.wallet_funding import move_currency

COSMETICS_CONFIG_ID = "cosmetics_catalog"
CURRENT_SEASON = "season_1"
LOADOUT_ID = "cosmetic_loadout"
MIN_PRICE = 30
MAX_PRICE = 200
MAX_LIMITED_PRICE = 300
RUNNER_AVATAR = "runner_avatar"
SHOE_SKIN = "shoe_skin"
SHARE_FRAME = "share_frame"
CATEGORIES = (RUNNER_AVATAR, SHOE_SKIN, SHARE_FRAME)
ALREADY_OWNED = "Cosmetic already owned."
NOT_ON_SALE = "Season item is not on sale."
NOT_OWNED = "Cosmetic is not owned."
NOT_SPENT = "Cosmetic item is not spent."
_ACCENTS = frozenset({"", "dark", "blue", "pink", "yellow", "mint"})
_ITEM_ID = re.compile(r"^[a-z][a-z0-9_]{2,39}$")
_SEASON = re.compile(r"^[a-z0-9_]{1,32}$")
_ASSET = re.compile(r"^assets/images/[A-Za-z0-9_./-]+$")
_HEX = re.compile(r"^#[0-9A-Fa-f]{6}$")

_CHARACTERS = "assets/images/characters"
DEFAULT_ITEMS = (
    {
        "id": "avatar_snail",
        "name": "달팽이 러너",
        "category": RUNNER_AVATAR,
        "price": 30,
        "limited": False,
        "season": "",
        "asset": f"{_CHARACTERS}/chibi_snail_smiling.png",
        "accent": "",
    },
    {
        "id": "avatar_rabbit",
        "name": "토끼 러너",
        "category": RUNNER_AVATAR,
        "price": 80,
        "limited": False,
        "season": "",
        "asset": f"{_CHARACTERS}/chibi_rabbit_pure.png",
        "accent": "",
    },
    {
        "id": "avatar_cheetah",
        "name": "치타 러너",
        "category": RUNNER_AVATAR,
        "price": 150,
        "limited": False,
        "season": "",
        "asset": f"{_CHARACTERS}/chibi_cheetah_pure.png",
        "accent": "",
    },
    {
        "id": "avatar_season_wolf",
        "name": "시즌 1 늑대 러너",
        "category": RUNNER_AVATAR,
        "price": 280,
        "limited": True,
        "season": CURRENT_SEASON,
        "asset": f"{_CHARACTERS}/chibi_wolf_pure.png",
        "accent": "",
    },
    {
        "id": "shoe_mint",
        "name": "민트 러닝화",
        "category": SHOE_SKIN,
        "price": 40,
        "limited": False,
        "season": "",
        "asset": "",
        "accent": "#1E6A58",
    },
    {
        "id": "shoe_blue",
        "name": "블루 러닝화",
        "category": SHOE_SKIN,
        "price": 70,
        "limited": False,
        "season": "",
        "asset": "",
        "accent": "#1A56C4",
    },
    {
        "id": "shoe_pink",
        "name": "핑크 러닝화",
        "category": SHOE_SKIN,
        "price": 120,
        "limited": False,
        "season": "",
        "asset": "",
        "accent": "#F2A0C0",
    },
    {
        "id": "shoe_season_gold",
        "name": "시즌 1 골드 러닝화",
        "category": SHOE_SKIN,
        "price": 300,
        "limited": True,
        "season": CURRENT_SEASON,
        "asset": "",
        "accent": "#FFC857",
    },
    {
        "id": "frame_blue",
        "name": "블루 결과 프레임",
        "category": SHARE_FRAME,
        "price": 50,
        "limited": False,
        "season": "",
        "asset": "",
        "accent": "blue",
    },
    {
        "id": "frame_pink",
        "name": "핑크 결과 프레임",
        "category": SHARE_FRAME,
        "price": 90,
        "limited": False,
        "season": "",
        "asset": "",
        "accent": "pink",
    },
    {
        "id": "frame_mint",
        "name": "민트 결과 프레임",
        "category": SHARE_FRAME,
        "price": 140,
        "limited": False,
        "season": "",
        "asset": "",
        "accent": "mint",
    },
    {
        "id": "frame_season_gold",
        "name": "시즌 1 골드 프레임",
        "category": SHARE_FRAME,
        "price": 260,
        "limited": True,
        "season": CURRENT_SEASON,
        "asset": "",
        "accent": "yellow",
    },
)
_DEFAULTS = {row["id"]: row for row in DEFAULT_ITEMS}


def resolve_cosmetics_catalog(raw: dict | None) -> dict:
    """Merge a Firestore doc over the code defaults."""
    by_id = {item_id: dict(row) for item_id, row in _DEFAULTS.items()}
    season = CURRENT_SEASON
    if isinstance(raw, dict):
        season = _season(raw.get("season")) or CURRENT_SEASON
        rows = raw.get("items")
        if isinstance(rows, dict):
            for item_id, row in rows.items():
                if item_id in by_id:
                    by_id[item_id] = _merge(by_id[item_id], row)
                    continue
                extra = _extra(item_id, row)
                if extra is not None:
                    by_id[item_id] = extra
    items = [by_id[row["id"]] for row in DEFAULT_ITEMS]
    extras = sorted(item_id for item_id in by_id if item_id not in _DEFAULTS)
    items.extend(by_id[item_id] for item_id in extras)
    return {"season": season, "items": items}


def read_cosmetics_catalog(db, transaction=None) -> dict:
    """Load ``config/cosmetics_catalog``. A read failure keeps the defaults."""
    try:
        snapshot = (
            db.collection("config")
            .document(COSMETICS_CONFIG_ID)
            .get(transaction=transaction)
        )
        raw = snapshot.to_dict() if snapshot.exists else None
    except Exception:
        raw = None
    return resolve_cosmetics_catalog(raw)


def is_cosmetic_item(db, item_id: str) -> bool:
    return any(row["id"] == item_id for row in read_cosmetics_catalog(db)["items"])


def purchase_cosmetic(
    service,
    transaction,
    uid: str,
    item_id: str,
    request_id: str,
    user_ref,
) -> SecuredActionResult:
    request_id = require_request_id(request_id)
    catalog = read_cosmetics_catalog(service.firebase_service.db, transaction)
    item = _find(catalog, item_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Shop item not found.")
    if item["limited"] and item["season"] != catalog["season"]:
        raise HTTPException(status_code=400, detail=NOT_ON_SALE)

    ledger_ref = _ledger(service, f"shop_buy_{uid}_{item_id}_{request_id}")
    if ledger_ref.get(transaction=transaction).exists:
        user = _user(user_ref, transaction)
        return _result(user, "already_purchased", "Purchase already recorded.")

    user = _user(user_ref, transaction)
    inventory_ref = user_ref.collection("shopInventory").document(item_id)
    if _quantity(inventory_ref, transaction) >= 1:
        raise HTTPException(status_code=400, detail=ALREADY_OWNED)

    wallet = user.get("wallet")
    if not isinstance(wallet, dict):
        wallet = {}
        user["wallet"] = wallet
    cost = int(item["price"])
    moved = move_currency(wallet, diamond=-cost)
    transaction.update(
        user_ref,
        {**moved["updates"], "updatedAt": SERVER_TIMESTAMP},
    )
    transaction.set(
        inventory_ref,
        {
            "itemId": item_id,
            "title": item["name"],
            "quantity": 1,
            "category": item["category"],
            "season": item["season"],
            "limited": item["limited"],
            "asset": item["asset"],
            "accent": item["accent"],
            "purchasedAt": SERVER_TIMESTAMP,
        },
    )
    transaction.set(
        ledger_ref,
        {
            "uid": uid,
            "type": "shop_purchase",
            "diamondAmount": -cost,
            "itemId": item_id,
            "category": item["category"],
            "seasonId": catalog["season"],
            "requestId": request_id,
            "createdAt": SERVER_TIMESTAMP,
            **moved["ledger"],
        },
    )
    return _result(user, "purchased", f"Purchased {item['name']}.")


def equip_cosmetic(
    service,
    transaction,
    uid: str,
    item_id: str,
    request_id: str,
    user_ref,
    equip: bool,
) -> SecuredActionResult:
    request_id = require_request_id(request_id)
    catalog = read_cosmetics_catalog(service.firebase_service.db, transaction)
    item = _find(catalog, item_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Shop item not found.")

    ledger_ref = _ledger(service, f"cosmetic_equip_{uid}_{request_id}")
    user = _user(user_ref, transaction)
    if ledger_ref.get(transaction=transaction).exists:
        return _result(user, "already_equipped", "Equip already recorded.")

    inventory_ref = user_ref.collection("shopInventory").document(item_id)
    if equip and _quantity(inventory_ref, transaction) < 1:
        raise HTTPException(status_code=400, detail=NOT_OWNED)

    loadout_ref = user_ref.collection("shopInventory").document(LOADOUT_ID)
    snapshot = loadout_ref.get(transaction=transaction)
    current = snapshot.to_dict() if snapshot.exists else None
    slots = _slots(current)
    category = item["category"]
    if equip:
        slots[category] = {
            "id": item_id,
            "name": item["name"],
            "asset": item["asset"],
            "accent": item["accent"],
        }
    elif slots[category].get("id") == item_id:
        slots[category] = _empty_slot()

    transaction.set(
        loadout_ref,
        {
            "itemId": LOADOUT_ID,
            "quantity": 0,
            "slots": slots,
        },
        merge=True,
    )
    transaction.set(
        ledger_ref,
        {
            "uid": uid,
            "type": "cosmetic_equip",
            "diamondAmount": 0,
            "itemId": item_id,
            "category": category,
            "equipped": equip,
            "requestId": request_id,
            "createdAt": SERVER_TIMESTAMP,
        },
    )
    status = "equipped" if equip else "unequipped"
    return _result(user, status, f"{status} {item['name']}.")


def _find(catalog: dict, item_id: str) -> dict | None:
    for row in catalog["items"]:
        if row["id"] == item_id:
            return row
    return None


def _merge(base: dict, row: object) -> dict:
    merged = dict(base)
    if not isinstance(row, dict):
        return merged
    category = row.get("category")
    if category in CATEGORIES:
        merged["category"] = category
    if isinstance(row.get("limited"), bool):
        merged["limited"] = row["limited"]
    season = _season(row.get("season"), allow_empty=True)
    if season is not None and "season" in row:
        merged["season"] = season
    name = _name(row.get("name"))
    if name is not None:
        merged["name"] = name
    asset = _asset(row.get("asset"))
    if asset is not None and "asset" in row:
        merged["asset"] = asset
    accent = _accent(row.get("accent"))
    if accent is not None and "accent" in row:
        merged["accent"] = accent
    price = _price(row.get("price"), limited=bool(merged["limited"]))
    merged["price"] = int(base["price"]) if price is None else price
    if merged["limited"] and not merged["season"]:
        merged["limited"] = bool(base["limited"])
        merged["season"] = base["season"]
    if _price(merged["price"], limited=bool(merged["limited"])) is None:
        merged["price"] = int(base["price"])
        merged["limited"] = bool(base["limited"])
        merged["season"] = base["season"]
    return merged


def _extra(item_id: object, row: object) -> dict | None:
    if not isinstance(item_id, str) or _ITEM_ID.fullmatch(item_id) is None:
        return None
    if not isinstance(row, dict):
        return None
    category = row.get("category")
    if category not in CATEGORIES:
        return None
    limited = row.get("limited")
    if not isinstance(limited, bool):
        return None
    season = _season(row.get("season"), allow_empty=not limited)
    if season is None or (limited and not season):
        return None
    name = _name(row.get("name"))
    price = _price(row.get("price"), limited=limited)
    if name is None or price is None:
        return None
    asset = _asset(row.get("asset")) if "asset" in row else ""
    accent = _accent(row.get("accent")) if "accent" in row else ""
    if asset is None or accent is None:
        return None
    return {
        "id": item_id,
        "name": name,
        "category": category,
        "price": price,
        "limited": limited,
        "season": season,
        "asset": asset,
        "accent": accent,
    }


def _price(value: object, *, limited: bool) -> int | None:
    if isinstance(value, bool):
        return None
    if isinstance(value, int):
        number = value
    elif isinstance(value, float) and value.is_integer():
        number = int(value)
    else:
        return None
    ceiling = MAX_LIMITED_PRICE if limited else MAX_PRICE
    if number < MIN_PRICE or number > ceiling:
        return None
    return number


def _name(value: object) -> str | None:
    if not isinstance(value, str):
        return None
    text = value.strip()
    if not text or len(text) > 40 or any(ord(ch) < 32 for ch in text):
        return None
    return text


def _season(value: object, allow_empty: bool = False) -> str | None:
    if value is None and allow_empty:
        return ""
    if not isinstance(value, str):
        return None
    text = value.strip()
    if not text and allow_empty:
        return ""
    if _SEASON.fullmatch(text) is None:
        return None
    return text


def _asset(value: object) -> str | None:
    if value is None:
        return ""
    if not isinstance(value, str):
        return None
    text = value.strip()
    if not text:
        return ""
    if ".." in text or _ASSET.fullmatch(text) is None:
        return None
    return text


def _accent(value: object) -> str | None:
    if value is None:
        return ""
    if not isinstance(value, str):
        return None
    text = value.strip()
    if text in _ACCENTS or _HEX.fullmatch(text):
        return text
    return None


def _slots(doc: dict | None) -> dict:
    raw = doc.get("slots") if isinstance(doc, dict) else None
    slots = {}
    for category in CATEGORIES:
        row = raw.get(category) if isinstance(raw, dict) else None
        if not isinstance(row, dict):
            slots[category] = _empty_slot()
            continue
        item_id = row.get("id")
        slots[category] = {
            "id": item_id if isinstance(item_id, str) else "",
            "name": row.get("name") if isinstance(row.get("name"), str) else "",
            "asset": row.get("asset") if isinstance(row.get("asset"), str) else "",
            "accent": row.get("accent") if isinstance(row.get("accent"), str) else "",
        }
    return slots


def _empty_slot() -> dict:
    return {"id": "", "name": "", "asset": "", "accent": ""}


def _quantity(ref, transaction) -> int:
    snapshot = ref.get(transaction=transaction)
    if not snapshot.exists:
        return 0
    quantity = (snapshot.to_dict() or {}).get("quantity") or 0
    if isinstance(quantity, bool) or not isinstance(quantity, int):
        return 0
    return quantity


def _user(user_ref, transaction) -> dict:
    snapshot = user_ref.get(transaction=transaction)
    if not snapshot.exists:
        raise HTTPException(status_code=404, detail="User not found.")
    return snapshot.to_dict() or {}


def _ledger(service, doc_id: str):
    return service.firebase_service.db.collection("walletTransactions").document(doc_id)


def _balances(wallet: dict) -> tuple[int, int, int]:
    return (
        int(wallet.get("shareBalance") or 0),
        int(wallet.get("diamondBalance") or 0),
        int(wallet.get("valueTokenBalance") or 0),
    )


def _result(user: dict, status: str, reason: str) -> SecuredActionResult:
    share, diamonds, value = _balances(user.get("wallet") or {})
    return SecuredActionResult(
        accepted=True,
        status=status,
        reason=reason,
        share_balance=share,
        diamond_balance=diamonds,
        value_token_balance=value,
    )
