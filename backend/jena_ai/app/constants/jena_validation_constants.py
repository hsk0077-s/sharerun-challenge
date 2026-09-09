"""Jena AI 3-stage abuse detection thresholds."""

# Situation A — kickboard: 3 min/km pace, low HR, near-zero cadence
KICKBOARD_PACE_SECONDS_PER_KM = 180  # 3:00 / km
KICKBOARD_MAX_HEART_RATE_BPM = 80
KICKBOARD_MAX_CADENCE_SPM = 20

# Situation B — bicycle: elevated HR but fixed arm-swing gyro signal
BIKE_MIN_HEART_RATE_BPM = 110
BIKE_GYRO_STABILITY_THRESHOLD = 0.92

# Situation C — verified outdoor run
VERIFIED_MIN_DISTANCE_KM = 3.0
VERIFIED_MIN_HEART_RATE_BPM = 100
VERIFIED_CADENCE_MIN_SPM = 150
VERIFIED_CADENCE_MAX_SPM = 180
VERIFIED_MIN_HR_VARIANCE = 8.0  # natural curve vs flat line
