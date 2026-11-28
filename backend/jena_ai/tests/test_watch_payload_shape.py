"""The Apple Watch upload body is checked against ValidateRunRequest without Xcode.

swiftc is not required. The test reads the Swift source the watch target
compiles and fails if a field name, unit, or daily-steps source drifts from
the server models.
"""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
WATCH_DIR = ROOT / "ios" / "ShareRunWatch Watch App"
IOS_QUEUE = WATCH_DIR / "WatchSyncQueue.swift"
IOS_FLUSH_GATE = WATCH_DIR / "WatchFlushGate.swift"
PBXPROJ = ROOT / "ios" / "Runner.xcodeproj" / "project.pbxproj"

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


def test_watch_target_sends_times_and_a_legal_steps_source() -> None:
    # Was a check on the old, unbuilt watchos_app/ copy. Now it checks the
    # files the Xcode watch target really compiles.
    project = PBXPROJ.read_text(encoding="utf-8")
    for name in ("WatchSyncQueue.swift", "WatchFlushGate.swift"):
        assert f"/* {name} in Sources */" in project, name
    source = IOS_QUEUE.read_text(encoding="utf-8")
    for key in ("started_at", "ended_at", "pace_samples", "gps_route"):
        assert key in source, key
    assert '"source": "watch"' not in source
    assert '"source": "sensor"' in source


def test_overlapping_flush_is_rejected_until_the_first_ends() -> None:
    # Replaces watchos_app/ShareRunWatchTests/WatchFlushGateTests.swift, an
    # XCTest no target ever ran: second begin is refused until end.
    gate = IOS_FLUSH_GATE.read_text(encoding="utf-8")
    assert "if flushing { return false }" in gate
    assert "flushing = true" in gate
    assert "mutating func end() {\n        flushing = false" in gate.replace("\r\n", "\n")
    queue = IOS_QUEUE.read_text(encoding="utf-8").replace("\r\n", "\n")
    flush = queue[queue.index("func flush(using account: WatchAccountManager)") :]
    begin = flush.index("guard tryBeginFlush() else { return }")
    assert begin < flush.index('path: "/actions/runs/validate"')
    assert "endFlush()" in flush[begin : flush.index("for run in runs")]
