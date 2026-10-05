"""Jena AI 3-stage abuse detection thresholds.

Distances, cadence, stride, and GPS speed live here so a later config
overlay can replace them without hunting through the filter.
"""

# Situation A — kickboard: fast pace, low HR, near-zero cadence.
KICKBOARD_PACE_SECONDS_PER_KM = 180  # 3:00 / km
# Phone-only: missing HR must not count as "HR <= 80". A fast pace plus
# almost no steps (or a stride no runner has) is the kickboard signal.
KICKBOARD_PACE_NO_HR_SECONDS_PER_KM = 240  # 4:00 / km
KICKBOARD_MAX_HEART_RATE_BPM = 80
KICKBOARD_MAX_CADENCE_SPM = 20

# Situation B — bicycle: elevated HR but fixed arm-swing gyro signal.
BIKE_MIN_HEART_RATE_BPM = 110
BIKE_GYRO_STABILITY_THRESHOLD = 0.92

# Situation C — verified outdoor run.
# Free runs and the floor under every room distance. A room uses its own
# target when that target is higher.
VERIFIED_MIN_DISTANCE_KM = 1.0
VERIFIED_MIN_HEART_RATE_BPM = 100
VERIFIED_CADENCE_MIN_SPM = 120
VERIFIED_CADENCE_MAX_SPM = 210
VERIFIED_MIN_HR_VARIANCE = 8.0  # natural curve vs flat line

# Phone-only, when the watch sent no heart-rate samples.
# Stride = distance / steps. Kickboards and bikes barely step, so the
# stride becomes much longer than a run.
STRIDE_MIN_M = 0.4
STRIDE_MAX_M = 1.8
# Vehicle-like segment. Sub-50m spikes are GPS jitter, not a car.
GPS_MAX_SEGMENT_KMH = 25.0
GPS_MIN_SEGMENT_M = 50.0
