"""Start and end times a client reports for a run.

The server cannot prove a phone's or a watch's clock, but it can refuse times that
cannot be true: in the future, older than a week, ending before they start, or
shorter than the running time the same request claims. A watch records runs while
it is offline and uploads them later, so its uploads must carry both times.
"""

from datetime import datetime, timedelta, timezone

from fastapi import HTTPException

MAX_AGE = timedelta(days=7)
FUTURE_SLACK = timedelta(minutes=5)
DURATION_SLACK_SECONDS = 60
MAX_SPAN = timedelta(hours=12)


def _bad(code: str) -> HTTPException:
    return HTTPException(status_code=400, detail=code)


def _parse(value: str) -> datetime:
    try:
        parsed = datetime.fromisoformat(value.strip().replace("Z", "+00:00"))
    except ValueError as error:
        raise _bad("invalid_run_time") from error
    return parsed if parsed.tzinfo else parsed.replace(tzinfo=timezone.utc)


def check_run_times(
    started_at: str | None,
    ended_at: str | None,
    duration_seconds: int,
    *,
    required: bool,
    now: datetime | None = None,
) -> None:
    """Raises 400 for a time that cannot be true. Does nothing when absent and optional."""
    if started_at is None and ended_at is None:
        if required:
            raise _bad("run_time_required")
        return
    if started_at is None or ended_at is None:
        raise _bad("invalid_run_time")
    current = now or datetime.now(timezone.utc)
    start, end = _parse(started_at), _parse(ended_at)
    if end <= start:
        raise _bad("invalid_run_time")
    if end > current + FUTURE_SLACK:
        raise _bad("run_in_future")
    if end < current - MAX_AGE:
        raise _bad("run_too_old")
    span = end - start
    if span > MAX_SPAN:
        raise _bad("invalid_run_time")
    # Running time cannot be longer than the time between start and end.
    if duration_seconds > span.total_seconds() + DURATION_SLACK_SECONDS:
        raise _bad("invalid_run_time")
