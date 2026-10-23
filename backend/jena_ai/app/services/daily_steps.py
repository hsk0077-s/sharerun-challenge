"""Per-day step totals the phone reports, written by the server.

The phone sends its day total. The server decides what is stored, so a phone
cannot write a number directly. Streak marks on the same document are left
alone. These totals are backup and history; walking SHARE is still minted only
by the harvest action.

Rules, matching what the app used to enforce on itself:
- the day is today (KST) or one of the last 35 days, never the future;
- 1..30,000 steps; past days only go up;
- with a Health reading, steps more than 2,000 above it are refused, and a
  stored total that is more than 2,000 above Health may be lowered to match.
"""

from datetime import datetime, timedelta, timezone

from fastapi import HTTPException
from google.cloud import firestore
from google.cloud.firestore_v1 import SERVER_TIMESTAMP

MAX_DAILY_STEPS = 30_000
HEALTH_LEAD_MAX = 2_000
LOOKBACK_DAYS = 35
STRIDE_METERS = 0.75
SOURCES = {"health_connect", "sensor"}
_KST = timezone(timedelta(hours=9))


def _today_kst(now: datetime | None) -> datetime:
    return (now or datetime.now(timezone.utc)).astimezone(_KST)


def _parse_day(day_key: str, now: datetime | None):
    try:
        day = datetime.strptime(day_key, "%Y-%m-%d").date()
    except (TypeError, ValueError) as error:
        raise HTTPException(status_code=400, detail="Invalid day.") from error
    today = _today_kst(now).date()
    if day > today or (today - day).days > LOOKBACK_DAYS:
        raise HTTPException(status_code=400, detail="Invalid day.")
    return day, day == today


def merged_steps(previous: int, incoming: int, is_today: bool, health: int | None) -> int | None:
    """The total to store, or None to leave the stored one as it is."""
    if incoming <= 0:
        return None
    if not is_today:
        return incoming if incoming > previous else None
    if health is not None:
        if incoming > health + HEALTH_LEAD_MAX:
            return None
        if previous > health + HEALTH_LEAD_MAX:
            return incoming if incoming != previous else None
    return incoming if incoming > previous else None


def apply_daily_steps(
    transaction,
    ref,
    *,
    steps: int,
    source: str,
    last_health: int | None,
    is_today: bool,
) -> dict:
    snap = ref.get(transaction=transaction)
    data = (snap.to_dict() or {}) if snap.exists else {}
    previous = data.get("steps") if isinstance(data.get("steps"), int) else 0
    health = last_health if last_health and last_health > 0 else None
    stored = merged_steps(previous, steps, is_today, health)
    if stored is None:
        return {"status": "unchanged", "steps": previous}
    payload = {
        "steps": stored,
        "km": round(stored * STRIDE_METERS / 1000.0, 3),
        "source": source if source in SOURCES else "sensor",
        "updatedAt": SERVER_TIMESTAMP,
    }
    if health is not None:
        payload["lastHealth"] = min(health, MAX_DAILY_STEPS)
    transaction.set(ref, payload, merge=True)
    return {"status": "saved", "steps": stored}


@firestore.transactional
def _commit(transaction, ref, **kwargs) -> dict:
    return apply_daily_steps(transaction, ref, **kwargs)


def record_daily_steps(
    db,
    uid: str,
    day_key: str,
    steps: int,
    source: str,
    last_health: int | None = None,
    now: datetime | None = None,
) -> dict:
    if not 1 <= steps <= MAX_DAILY_STEPS:
        raise HTTPException(status_code=400, detail="Invalid steps.")
    _, is_today = _parse_day(day_key, now)
    ref = db.collection("users").document(uid).collection("daily_metrics").document(day_key)
    return _commit(
        db.transaction(),
        ref,
        steps=steps,
        source=source,
        last_health=last_health,
        is_today=is_today,
    )
