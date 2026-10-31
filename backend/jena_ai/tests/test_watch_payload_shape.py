"""The Apple Watch upload body is checked against ValidateRunRequest without Xcode.

swiftc is not required. The test reads the Swift source the watch target
compiles and fails if a field name, unit, or daily-steps source drifts from
the server models.
"""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
IOS_QUEUE = ROOT / "ios" / "ShareRunWatch Watch App" / "WatchSyncQueue.swift"
STALE_QUEUE = ROOT / "watchos_app" / "ShareRunWatch" / "WatchSyncQueue.swift"

VALIDATE_KEYS = (
    "activity_id",
    "distance_km",
    "duration_seconds",
    "heart_rates",
    "cadence_spm",
    "gyro_stability_score",
    "gps_route",
    "pace_samples",
    "started_at",
    "ended_at",
    "total_steps",
    "device_info",
    "watch_used",
    "heart_rate_used",
    "latitude",
    "longitude",
    "recordedAt",
    "secondsPerKm",
)


def test_ios_watch_validate_body_uses_server_field_names() -> None:
    source = IOS_QUEUE.read_text(encoding="utf-8")
    for key in VALIDATE_KEYS:
        assert key in source, key
    assert '"source": "watch"' not in source
    assert '"source": "sensor"' in source
    assert "min(7200" in source
    assert "min(30_000" in source


def test_stale_watchos_tree_also_sends_times_and_a_legal_steps_source() -> None:
    source = STALE_QUEUE.read_text(encoding="utf-8")
    for key in ("started_at", "ended_at", "pace_samples", "gps_route"):
        assert key in source, key
    assert '"source": "watch"' not in source
    assert '"source": "sensor"' in source
