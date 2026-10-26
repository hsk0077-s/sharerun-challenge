from datetime import datetime, timedelta, timezone

import pytest
from fastapi import HTTPException

from app.services.run_times import check_run_times

NOW = datetime(2026, 10, 25, 12, 0, tzinfo=timezone.utc)


def _iso(delta: timedelta) -> str:
    return (NOW + delta).isoformat()


def _check(start, end, duration=1800, required=True):
    check_run_times(start, end, duration, required=required, now=NOW)


def test_a_normal_run_passes() -> None:
    _check(_iso(-timedelta(hours=2)), _iso(-timedelta(hours=1, minutes=25)), 1800)


def test_a_phone_may_leave_the_times_out_but_a_watch_may_not() -> None:
    _check(None, None, required=False)
    with pytest.raises(HTTPException) as caught:
        _check(None, None, required=True)
    assert caught.value.detail == "run_time_required"


@pytest.mark.parametrize(
    ("start", "end", "code"),
    [
        (-timedelta(hours=1), timedelta(minutes=20), "run_in_future"),
        (-timedelta(days=9), -timedelta(days=8, hours=23), "run_too_old"),
        (-timedelta(hours=1), -timedelta(hours=2), "invalid_run_time"),
        (-timedelta(hours=30), -timedelta(hours=1), "invalid_run_time"),
    ],
)
def test_times_that_cannot_be_true_are_refused(start, end, code) -> None:
    with pytest.raises(HTTPException) as caught:
        _check(_iso(start), _iso(end), 600)
    assert caught.value.status_code == 400
    assert caught.value.detail == code


def test_running_time_longer_than_the_span_is_refused() -> None:
    with pytest.raises(HTTPException):
        _check(_iso(-timedelta(hours=2)), _iso(-timedelta(hours=1, minutes=50)), 1800)


def test_unreadable_or_half_given_times_are_refused() -> None:
    for start, end in (("nope", _iso(-timedelta(hours=1))), (_iso(-timedelta(hours=1)), None)):
        with pytest.raises(HTTPException) as caught:
            _check(start, end, 60, required=False)
        assert caught.value.detail == "invalid_run_time"


def test_a_z_suffix_and_a_clock_a_few_minutes_ahead_are_accepted() -> None:
    start = (NOW - timedelta(minutes=40)).strftime("%Y-%m-%dT%H:%M:%SZ")
    end = (NOW + timedelta(minutes=3)).strftime("%Y-%m-%dT%H:%M:%SZ")
    _check(start, end, 2400)
