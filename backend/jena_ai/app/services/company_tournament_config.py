"""Company prize-race settings.

One Firestore doc, ``config/company_tournament``, overrides these defaults.
Jena reads it on join and on ``GET /actions/company-tournament/config``.
Missing or invalid fields keep the code default, so a bad edit cannot
zero a fee or drop a tier. Numbers can change without an app update and
without another Cloud Run deploy after this code is live.

Entry fees are admission only. This module does not pay prizes.
Entry SHARE is already the 10x scale and is not multiplied again.
top10PercentShare is the 10x reward. Prize DIA is unchanged.
"""

from copy import deepcopy
from datetime import datetime, timedelta, timezone

from app.constants.economy_constants import SRV_TOKENS_PER_KM

COMPANY_TOURNAMENT_CONFIG_ID = "company_tournament"

# Pinned. A doc edit cannot turn entry fees into prize funding.
_PRIZES_FUNDED_BY_ENTRY_FEES = False
_ENTRY_FEE_ROLE = "admission_only"


def _rank_prizes(*bands: tuple[int, int, int]) -> dict[str, int]:
    prizes: dict[str, int] = {}
    for start, end, dia in bands:
        for rank in range(start, end + 1):
            prizes[str(rank)] = dia
    return prizes


def _tier(
    *,
    label_ko: str,
    distance_label: str,
    entry_share: int,
    free_ticket_cost: int,
    min_entrants: int,
    target_entrants: int,
    max_entrants: int,
    top10_percent_share: int,
    prize_dia_by_rank: dict[str, int],
    requires_season_qualification: bool = False,
) -> dict:
    return {
        "labelKo": label_ko,
        "distanceLabel": distance_label,
        "entryShare": entry_share,
        "freeTicketCost": free_ticket_cost,
        "requiresSeasonQualification": requires_season_qualification,
        "minEntrants": min_entrants,
        "targetEntrants": target_entrants,
        "maxEntrants": max_entrants,
        "top10PercentShare": top10_percent_share,
        "prizeDiaByRank": prize_dia_by_rank,
    }


_DEFAULT_TIERS = {
    "beginner": _tier(
        label_ko="초급",
        distance_label="1-3km",
        entry_share=300,
        free_ticket_cost=1,
        min_entrants=30,
        target_entrants=100,
        max_entrants=500,
        top10_percent_share=10_000,
        prize_dia_by_rank=_rank_prizes((1, 1, 1_000), (2, 2, 500), (3, 3, 300)),
    ),
    "mid": _tier(
        label_ko="중급",
        distance_label="5km",
        entry_share=1_200,
        free_ticket_cost=1,
        min_entrants=50,
        target_entrants=200,
        max_entrants=1_000,
        top10_percent_share=20_000,
        prize_dia_by_rank=_rank_prizes(
            (1, 1, 3_000),
            (2, 2, 1_500),
            (3, 3, 1_000),
            (4, 5, 500),
            (6, 10, 200),
        ),
    ),
    "advanced": _tier(
        label_ko="상급",
        distance_label="10km",
        entry_share=2_400,
        free_ticket_cost=2,
        min_entrants=50,
        target_entrants=250,
        max_entrants=1_000,
        top10_percent_share=30_000,
        prize_dia_by_rank=_rank_prizes(
            (1, 1, 5_000),
            (2, 2, 2_500),
            (3, 3, 1_500),
            (4, 5, 800),
            (6, 10, 400),
        ),
    ),
    "half": _tier(
        label_ko="하프",
        distance_label="하프",
        entry_share=4_200,
        free_ticket_cost=3,
        min_entrants=50,
        target_entrants=150,
        max_entrants=500,
        top10_percent_share=50_000,
        prize_dia_by_rank=_rank_prizes(
            (1, 1, 10_000),
            (2, 2, 5_000),
            (3, 3, 3_000),
            (4, 5, 1_500),
            (6, 10, 800),
        ),
    ),
    "final": _tier(
        label_ko="파이널",
        distance_label="파이널",
        entry_share=0,
        free_ticket_cost=0,
        min_entrants=64,
        target_entrants=96,
        max_entrants=128,
        top10_percent_share=100_000,
        prize_dia_by_rank=_rank_prizes(
            (1, 1, 30_000),
            (2, 2, 15_000),
            (3, 3, 10_000),
            (4, 5, 5_000),
            (6, 10, 3_000),
        ),
        requires_season_qualification=True,
    ),
}

_DEFAULTS = {
    "id": COMPANY_TOURNAMENT_CONFIG_ID,
    "diaKrw": 100,
    "companyDonationKrwPerKm": 100,
    "monthlyCompanyPrizeCapDia": 120_000,
    # Finishers still get VALUE from the existing per-km rule. Not settled here.
    "finisherValueRule": "existing_srv_per_km",
    "finisherValueTokensPerKm": SRV_TOKENS_PER_KM,
    "topPercent": 10,
    "topPercentExcludesPrizeRanks": True,
    # First N 초급 joins are free. Identity is checked only when this is true.
    # Nothing sets identityVerified yet, so the flag stays false until 본인인증 exists.
    "requireIdentityVerification": False,
    "beginnerFreeEntryCount": 2,
    "weeklyEntriesPerTier": 1,
    "prizeClaimMinAccountAgeDays": 14,
    "prizeClaimMinVerifiedRuns": 3,
    "prizeClaimVerifiedRunWindowDays": 14,
    "tiers": _DEFAULT_TIERS,
}

# Server-owned user field. Clients cannot write it. Missing means not eligible.
IDENTITY_VERIFIED_FIELD = "identityVerified"
FREE_ENTRY_TIER = "beginner"


def resolve_company_tournament_config(raw: dict | None) -> dict:
    """Merge a Firestore doc over the code defaults."""
    resolved = deepcopy(_DEFAULTS)
    resolved["source"] = "defaults"
    resolved["prizesFundedByEntryFees"] = _PRIZES_FUNDED_BY_ENTRY_FEES
    resolved["entryFeeRole"] = _ENTRY_FEE_ROLE
    if not isinstance(raw, dict):
        return resolved

    resolved["source"] = "firestore"
    _overlay_int(resolved, raw, "diaKrw", minimum=1)
    _overlay_int(resolved, raw, "companyDonationKrwPerKm", minimum=0)
    _overlay_int(resolved, raw, "monthlyCompanyPrizeCapDia", minimum=0)
    _overlay_int(resolved, raw, "finisherValueTokensPerKm", minimum=0)
    _overlay_int(resolved, raw, "topPercent", minimum=1, maximum=100)
    _overlay_bool(resolved, raw, "requireIdentityVerification")
    _overlay_int(resolved, raw, "beginnerFreeEntryCount", minimum=0)
    _overlay_int(resolved, raw, "weeklyEntriesPerTier", minimum=1)
    _overlay_int(resolved, raw, "prizeClaimMinAccountAgeDays", minimum=0)
    _overlay_int(resolved, raw, "prizeClaimMinVerifiedRuns", minimum=0)
    _overlay_int(resolved, raw, "prizeClaimVerifiedRunWindowDays", minimum=1)
    rule = raw.get("finisherValueRule")
    if isinstance(rule, str) and rule.strip() and len(rule.strip()) <= 64:
        resolved["finisherValueRule"] = rule.strip()

    incoming_tiers = raw.get("tiers")
    if isinstance(incoming_tiers, dict):
        for tier_id, base in resolved["tiers"].items():
            incoming = incoming_tiers.get(tier_id)
            if isinstance(incoming, dict):
                _overlay_tier(base, incoming)

    resolved["prizesFundedByEntryFees"] = _PRIZES_FUNDED_BY_ENTRY_FEES
    resolved["entryFeeRole"] = _ENTRY_FEE_ROLE
    resolved["topPercentExcludesPrizeRanks"] = True
    return resolved


def prize_tier_id(tournament: dict) -> str | None:
    """Return a prize-race tier id, or None when this is not a prize race."""
    if "prizeTier" not in tournament:
        return None
    raw = tournament.get("prizeTier")
    if raw is None or raw == "":
        return None
    if not isinstance(raw, str):
        return ""
    return raw.strip().lower()


def _overlay_tier(base: dict, incoming: dict) -> None:
    _overlay_int(base, incoming, "entryShare", minimum=0)
    _overlay_int(base, incoming, "freeTicketCost", minimum=0)
    _overlay_int(base, incoming, "top10PercentShare", minimum=0)
    _overlay_label(base, incoming, "labelKo")
    _overlay_label(base, incoming, "distanceLabel")
    qualified = incoming.get("requiresSeasonQualification")
    if isinstance(qualified, bool):
        base["requiresSeasonQualification"] = qualified
    _overlay_entrants(base, incoming)
    prizes = incoming.get("prizeDiaByRank")
    if isinstance(prizes, dict):
        cleaned: dict[str, int] = {}
        for rank, amount in prizes.items():
            key = _rank_key(rank)
            dia = _nonneg_int(amount)
            if key is not None and dia is not None:
                cleaned[key] = dia
        if cleaned:
            base["prizeDiaByRank"] = cleaned


def _overlay_entrants(base: dict, incoming: dict) -> None:
    min_entrants = _picked_int(base, incoming, "minEntrants")
    target = _picked_int(base, incoming, "targetEntrants")
    maximum = _picked_int(base, incoming, "maxEntrants")
    if min_entrants is None or target is None or maximum is None:
        return
    if 1 <= min_entrants <= target <= maximum:
        base["minEntrants"] = min_entrants
        base["targetEntrants"] = target
        base["maxEntrants"] = maximum


def _picked_int(base: dict, incoming: dict, key: str) -> int | None:
    if key not in incoming:
        return base[key]
    return _nonneg_int(incoming.get(key))


def _overlay_bool(base: dict, incoming: dict, key: str) -> None:
    if key not in incoming:
        return
    value = incoming.get(key)
    if isinstance(value, bool):
        base[key] = value


def _overlay_int(
    base: dict,
    incoming: dict,
    key: str,
    *,
    minimum: int,
    maximum: int | None = None,
) -> None:
    if key not in incoming:
        return
    number = _nonneg_int(incoming.get(key))
    if number is None or number < minimum:
        return
    if maximum is not None and number > maximum:
        return
    base[key] = number


def _overlay_label(base: dict, incoming: dict, key: str) -> None:
    if key not in incoming:
        return
    value = incoming.get(key)
    if not isinstance(value, str):
        return
    text = value.strip()
    if text and len(text) <= 40:
        base[key] = text


def _rank_key(value: object) -> str | None:
    if isinstance(value, str) and value.isdigit():
        number = int(value)
    else:
        number = _nonneg_int(value)
    if number is None or number < 1 or number > 100:
        return None
    return str(number)


def identity_check_passed(config: dict, identity_verified: bool) -> bool:
    """False only when the config flag is on and the account is not verified."""
    if config.get("requireIdentityVerification") is not True:
        return True
    return identity_verified is True


def prize_claim_reason(
    *,
    identity_verified: bool,
    created_at: datetime | None,
    verified_runs: int,
    config: dict,
    now: datetime,
) -> str | None:
    """Why this account cannot be paid DIA. None means the claim is allowed."""
    if not identity_check_passed(config, identity_verified):
        return "not_identity_verified"
    if not account_age_reached(
        created_at, now, int(config["prizeClaimMinAccountAgeDays"])
    ):
        return "account_too_new"
    if verified_runs < int(config["prizeClaimMinVerifiedRuns"]):
        return "not_enough_verified_runs"
    return None


def account_age_reached(created_at: datetime | None, now: datetime, min_days: int) -> bool:
    created = _as_utc(created_at)
    current = _as_utc(now)
    if created is None or current is None:
        return False
    return current - created >= timedelta(days=min_days)


def count_verified_runs(rows: list[dict], now: datetime, window_days: int) -> int:
    current = _as_utc(now)
    if current is None:
        return 0
    cutoff = current - timedelta(days=window_days)
    count = 0
    for row in rows:
        if row.get("jenaVerified") is not True:
            continue
        stamp = parse_time(row.get("completedAt"))
        if stamp is None:
            stamp = parse_time(row.get("createdAt"))
        if stamp is not None and stamp >= cutoff:
            count += 1
    return count


def verified_runs_in_window(db, uid: str, now: datetime, window_days: int) -> int:
    snaps = db.collection("activities").where("userId", "==", uid).get()
    rows = [snap.to_dict() or {} for snap in snaps]
    return count_verified_runs(rows, now, window_days)


def resolve_account_created_at(user: dict, uid: str) -> datetime | None:
    """Auth creation time. ``users.createdAt`` is client-writable and ignored."""
    live = _auth_created_at(uid)
    if live is not None:
        return live
    return parse_time(user.get("authCreatedAt"))


def free_entry_label_ko(count: int) -> str:
    if count == 2:
        return "첫 2회 무료"
    return f"첫 {count}회 무료"


def weekly_limit_label_ko(limit: int) -> str:
    return f"같은 등급은 일주일에 {limit}번만 참가할 수 있어요."


def prize_ineligible_reason_ko(reason: str | None, config: dict) -> str | None:
    age = int(config["prizeClaimMinAccountAgeDays"])
    runs = int(config["prizeClaimMinVerifiedRuns"])
    window = int(config["prizeClaimVerifiedRunWindowDays"])
    labels = {
        "not_identity_verified": "본인인증된 계정이 아니라 다이아 상금을 받을 수 없어요.",
        "account_too_new": f"가입 {age}일이 지나야 다이아 상금을 받을 수 있어요.",
        "not_enough_verified_runs": (
            f"최근 {window}일 안에 인증된 달리기가 {runs}회 이상이어야 "
            "다이아 상금을 받을 수 있어요."
        ),
    }
    return labels.get(reason or "")


def build_prize_viewer(
    *,
    user: dict,
    created_at: datetime | None,
    verified_runs: int,
    free_used: int,
    config: dict,
    now: datetime,
) -> dict:
    identity = user.get(IDENTITY_VERIFIED_FIELD) is True
    identity_ok = identity_check_passed(config, identity)
    allowance = int(config["beginnerFreeEntryCount"])
    remaining = max(0, allowance - max(0, free_used)) if identity_ok else 0
    free_ok = identity_ok and remaining > 0 and allowance > 0
    reason = prize_claim_reason(
        identity_verified=identity,
        created_at=created_at,
        verified_runs=verified_runs,
        config=config,
        now=now,
    )
    return {
        "beginnerFreeEntryEligible": free_ok,
        "beginnerFreeEntriesRemaining": remaining,
        "freeEntryLabelKo": free_entry_label_ko(allowance) if free_ok else None,
        "weeklyEntriesPerTier": int(config["weeklyEntriesPerTier"]),
        "weeklyLimitLabelKo": weekly_limit_label_ko(int(config["weeklyEntriesPerTier"])),
        "prizeClaimEligible": reason is None,
        "prizeIneligibleReason": reason,
        "prizeIneligibleReasonKo": prize_ineligible_reason_ko(reason, config),
    }


def parse_time(value: object) -> datetime | None:
    if isinstance(value, datetime):
        return _as_utc(value)
    if isinstance(value, str):
        text = value.strip()
        if not text:
            return None
        try:
            parsed = datetime.fromisoformat(text.replace("Z", "+00:00"))
        except ValueError:
            return None
        return _as_utc(parsed)
    return None


def _as_utc(value: datetime | None) -> datetime | None:
    if value is None:
        return None
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc)


def _auth_created_at(uid: str) -> datetime | None:
    try:
        import firebase_admin
        from firebase_admin import auth as firebase_auth

        firebase_admin.get_app()
        auth_user = firebase_auth.get_user(uid)
    except Exception:
        return None
    metadata = getattr(auth_user, "user_metadata", None)
    millis = getattr(metadata, "creation_timestamp", None) if metadata else None
    if not millis:
        return None
    return datetime.fromtimestamp(int(millis) / 1000, tz=timezone.utc)


def _nonneg_int(value: object) -> int | None:
    if isinstance(value, bool):
        return None
    if isinstance(value, int):
        number = value
    elif isinstance(value, float) and value.is_integer():
        number = int(value)
    else:
        return None
    if number < 0:
        return None
    return number
