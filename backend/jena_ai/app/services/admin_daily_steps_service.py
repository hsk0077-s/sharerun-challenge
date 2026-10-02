import re
from datetime import date, datetime, timedelta, timezone

from fastapi import HTTPException, status
from google.cloud.firestore_v1.field_path import FieldPath

from app.models.admin_api import DailyStepRow, DailyStepsResult
from app.services.firebase_service import FirebaseService

# Collection-group order is by document id only, so no composite index.
SCAN_CAP = 800
RETURN_CAP = 200
MAX_SPAN_DAYS = 62
ANOMALY_STEPS = 29_000
SENSOR_LEAD = 2_000
_DAY = re.compile(r"^\d{4}-\d{2}-\d{2}$")
_KST = timezone(timedelta(hours=9))


class AdminDailyStepsService:
    """Reads users/{uid}/daily_metrics. Does not write step counts."""

    def __init__(self, firebase_service: FirebaseService | None = None) -> None:
        self.firebase_service = firebase_service

    def list_steps(
        self,
        *,
        uid: str | None = None,
        start: str | None = None,
        end: str | None = None,
        now: datetime | None = None,
    ) -> DailyStepsResult:
        owner = _uid(uid)
        start_day, end_day = _range(start, end, now)
        db = self._db()
        if owner:
            snaps = self._for_user(db, owner, start_day, end_day)
            truncated = False
        else:
            snaps, truncated = self._group(db)
        rows: list[DailyStepRow] = []
        for snap in snaps:
            row = _row(snap, owner)
            if row is None:
                continue
            if row.day < start_day.isoformat() or row.day > end_day.isoformat():
                continue
            rows.append(row)
        rows.sort(key=lambda row: row.uid)
        rows.sort(key=lambda row: row.day, reverse=True)
        if len(rows) > RETURN_CAP:
            rows = rows[:RETURN_CAP]
            truncated = True
        return DailyStepsResult(
            start=start_day.isoformat(),
            end=end_day.isoformat(),
            uid=owner,
            truncated=truncated,
            rows=rows,
        )

    def _db(self):
        service = self.firebase_service or FirebaseService()
        return service.db

    def _for_user(self, db, uid: str, start_day: date, end_day: date):
        parent = db.collection("users").document(uid).collection("daily_metrics")
        query = (
            parent.order_by(FieldPath.document_id())
            .start_at([parent.document(start_day.isoformat())])
            .end_at([parent.document(end_day.isoformat())])
        )
        return list(query.stream())

    def _group(self, db) -> tuple[list, bool]:
        query = (
            db.collection_group("daily_metrics")
            .order_by(FieldPath.document_id())
            .limit(SCAN_CAP)
        )
        snaps = list(query.stream())
        return snaps, len(snaps) >= SCAN_CAP


def _range(
    start: str | None,
    end: str | None,
    now: datetime | None,
) -> tuple[date, date]:
    today = _kst_today(now)
    if start is None and end is None:
        return today - timedelta(days=13), today
    if start is None or end is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Provide both from and to.",
        )
    start_day = _day(start)
    end_day = _day(end)
    if end_day < start_day or (end_day - start_day).days > MAX_SPAN_DAYS - 1:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid date range.",
        )
    return start_day, end_day


def _kst_today(now: datetime | None) -> date:
    current = now or datetime.now(timezone.utc)
    if current.tzinfo is None:
        current = current.replace(tzinfo=timezone.utc)
    return current.astimezone(_KST).date()


def _day(value: str) -> date:
    text = value.strip()
    if not _DAY.fullmatch(text):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid date.",
        )
    try:
        return date.fromisoformat(text)
    except ValueError as error:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid date.",
        ) from error


def _uid(uid: str | None) -> str | None:
    if uid is None:
        return None
    text = uid.strip()
    if not text:
        return None
    if "/" in text or len(text) > 128:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid uid.",
        )
    return text


def _row(snap, only_uid: str | None) -> DailyStepRow | None:
    path = getattr(getattr(snap, "reference", None), "path", "") or ""
    parts = path.split("/")
    if "daily_metrics" not in parts:
        return None
    index = parts.index("daily_metrics")
    if index < 1 or index + 1 >= len(parts):
        return None
    uid = parts[index - 1]
    day = parts[index + 1]
    if only_uid and uid != only_uid:
        return None
    if not _DAY.fullmatch(day):
        return None
    data = snap.to_dict() or {}
    steps = _count(data.get("steps"))
    source = _text(data.get("source"))
    health = _health(data.get("lastHealth"))
    return DailyStepRow(
        uid=uid,
        day=day,
        steps=steps,
        source=source,
        lastHealth=health,
        updatedAt=_iso(data.get("updatedAt")),
        anomaly=_anomaly(steps, source, health),
    )


def _anomaly(steps: int, source: str | None, last_health: int | None) -> bool:
    if steps >= ANOMALY_STEPS:
        return True
    return (
        source == "sensor"
        and last_health is not None
        and steps > last_health + SENSOR_LEAD
    )


def _text(value: object) -> str | None:
    if not isinstance(value, str):
        return None
    text = value.strip()
    return text or None


def _count(value: object) -> int:
    if isinstance(value, bool):
        return 0
    if isinstance(value, int):
        return value
    if isinstance(value, float) and value.is_integer():
        return int(value)
    return 0


def _health(value: object) -> int | None:
    count = _count(value)
    if count <= 0:
        return None
    return count


def _iso(value: object) -> str | None:
    if isinstance(value, str):
        text = value.strip()
        return text or None
    isoformat = getattr(value, "isoformat", None)
    if callable(isoformat):
        return str(isoformat())
    return None


admin_daily_steps_service = AdminDailyStepsService()
