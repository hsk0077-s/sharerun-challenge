"""Prices and caps Jena reads from ``config/item_prices``.

Jena reads the doc for the shop catalog and when one of these items is
bought. Missing or invalid fields keep the code default, so a bad edit
cannot make an item free. Numbers can change without an app update and
without another Cloud Run deploy after this code is live.

DIA, SHARE, and VALUE prices share this doc. The item decides the
currency. Cap keys are not shop items.
"""

ITEM_PRICES_CONFIG_ID = "item_prices"
CPR_ITEM_ID = "record_cpr_ticket"
SAFEGUARD_ITEM_ID = "record_safe_guard"
COACH_ONE_POINT_ITEM_ID = "coach_one_point_ticket"
EXTRA_ENTRY_ITEM_ID = "extra_entry_ticket"
EXTRA_ENTRY_PACK_ITEM_ID = "extra_entry_ticket_3pack"
FRIEND_GHOST_ITEM_ID = "friend_ghost_pace"
FRIEND_GHOST_PACK_ITEM_ID = "friend_ghost_pace_10pack"
CREW_CHEER_FLAG_ITEM_ID = "crew_cheer_flag"
CREW_CREATE_DIA_ID = "crew_create_dia"
CREW_CREATE_SHARE_ID = "crew_create_share"
BATTLE_PASS_ITEM_ID = "battle_run_pass"
BATTLE_PASS_PLUS_ITEM_ID = "battle_run_pass_plus"
BOOST_RUN_ITEM_ID = "boost_run"
STEP_INCUBATOR_ITEM_ID = "step_incubator"
REST_DAY_TICKET_ID = "rest_day_ticket"
REST_DAY_FREE_PER_WEEK_ID = "rest_day_free_per_week"
DONATION_MATCH_ID = "donation_match"
DONATION_MATCH_WON_ID = "donation_match_won"
DONATION_MATCH_USER_MONTHLY_ID = "donation_match_user_monthly"
DONATION_MATCH_COMPANY_CAP_ID = "donation_match_company_cap_won"
BATTLE_PASS_ITEM_IDS = frozenset({BATTLE_PASS_ITEM_ID, BATTLE_PASS_PLUS_ITEM_ID})
SHARE_ACTIVITY_ITEM_IDS = frozenset({BOOST_RUN_ITEM_ID, STEP_INCUBATOR_ITEM_ID})
VALUE_ITEM_IDS = frozenset({REST_DAY_TICKET_ID, DONATION_MATCH_ID})
STREAK_ITEM_IDS = frozenset({CPR_ITEM_ID, SAFEGUARD_ITEM_ID})
RUN_ACCESS_ITEM_IDS = frozenset(
    {COACH_ONE_POINT_ITEM_ID, EXTRA_ENTRY_ITEM_ID, EXTRA_ENTRY_PACK_ITEM_ID}
)
SOCIAL_ITEM_IDS = frozenset(
    {FRIEND_GHOST_ITEM_ID, FRIEND_GHOST_PACK_ITEM_ID, CREW_CHEER_FLAG_ITEM_ID}
)

# Code defaults. A missing doc or a bad field keeps these.
_DEFAULTS = {
    CPR_ITEM_ID: 12,
    SAFEGUARD_ITEM_ID: 8,
    COACH_ONE_POINT_ITEM_ID: 5,
    EXTRA_ENTRY_ITEM_ID: 10,
    EXTRA_ENTRY_PACK_ITEM_ID: 25,
    FRIEND_GHOST_ITEM_ID: 5,
    FRIEND_GHOST_PACK_ITEM_ID: 40,
    CREW_CHEER_FLAG_ITEM_ID: 15,
    CREW_CREATE_DIA_ID: 50,
    CREW_CREATE_SHARE_ID: 30_000,
    BATTLE_PASS_ITEM_ID: 120,
    BATTLE_PASS_PLUS_ITEM_ID: 200,
    BOOST_RUN_ITEM_ID: 120,
    STEP_INCUBATOR_ITEM_ID: 1_200,
    REST_DAY_TICKET_ID: 50,
    REST_DAY_FREE_PER_WEEK_ID: 1,
    DONATION_MATCH_ID: 100,
    DONATION_MATCH_WON_ID: 1_000,
    DONATION_MATCH_USER_MONTHLY_ID: 1,
    DONATION_MATCH_COMPANY_CAP_ID: 500_000,
}


def resolve_item_prices(raw: dict | None) -> dict[str, int]:
    """Merge a Firestore doc over the code defaults."""
    resolved = dict(_DEFAULTS)
    if not isinstance(raw, dict):
        return resolved
    for item_id in _DEFAULTS:
        if item_id not in raw:
            continue
        number = _positive_int(raw.get(item_id))
        if number is None:
            continue
        resolved[item_id] = number
    return resolved


def read_item_prices(db, transaction=None) -> dict[str, int]:
    """Load ``config/item_prices``. A read failure keeps the code defaults."""
    try:
        snapshot = (
            db.collection("config")
            .document(ITEM_PRICES_CONFIG_ID)
            .get(transaction=transaction)
        )
        raw = snapshot.to_dict() if snapshot.exists else None
    except Exception:
        raw = None
    return resolve_item_prices(raw)


def _positive_int(value: object) -> int | None:
    if isinstance(value, bool):
        return None
    if isinstance(value, int):
        number = value
    elif isinstance(value, float) and value.is_integer():
        number = int(value)
    else:
        return None
    if number < 1:
        return None
    return number
