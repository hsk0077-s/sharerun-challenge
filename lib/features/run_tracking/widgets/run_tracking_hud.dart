import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../l10n/remaining_surface.dart';
import '../models/run_telemetry.dart';
import '../run_live_pace.dart';

/// Distance, elapsed time, and pace for a run that is underway.
///
/// Gyro stability is intentionally not drawn. The session still records it
/// and the finish path still sends it.
class RunTrackingHud extends StatelessWidget {
  const RunTrackingHud({required this.telemetry, super.key});

  final RunTelemetry telemetry;

  static const distanceKey = Key('run-live-distance');
  static const elapsedKey = Key('run-live-elapsed');
  static const paceCurrentKey = Key('run-live-pace-current');
  static const paceAverageKey = Key('run-live-pace-average');

  @override
  Widget build(BuildContext context) {
    final distance = telemetry.distanceKm.toStringAsFixed(2);
    final elapsed = formatRunClock(telemetry.durationSeconds);
    final current = RunLivePace.currentLabel(telemetry.routePoints);
    final average = RunLivePace.averageLabel(
      distanceKm: telemetry.distanceKm,
      durationSeconds: telemetry.durationSeconds,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final wide = constraints.maxWidth >= 340 && scale <= 1.3;
        final height =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 280.0;
        final distanceSize = (height * (wide ? 0.42 : 0.28)).clamp(44.0, 108.0);
        final statSize = (height * (wide ? 0.22 : 0.16)).clamp(22.0, 48.0);
        final labelSize = (statSize * 0.42).clamp(11.0, 16.0);

        final distanceStat = _Stat(
          label: RemainingSurface.tr(
            context,
            'run_tracking.stat.distance',
            '거리',
          ),
          value: distance,
          unit: 'km',
          valueKey: distanceKey,
          valueSize: distanceSize,
          labelSize: labelSize,
          valueColor: AppColors.nightLime,
        );
        final timeStat = _Stat(
          label: RemainingSurface.tr(context, 'run_tracking.stat.time', '시간'),
          value: elapsed,
          valueKey: elapsedKey,
          valueSize: statSize,
          labelSize: labelSize,
          valueColor: AppColors.nightInk,
        );
        final currentStat = _Stat(
          label: RemainingSurface.tr(
            context,
            'run_tracking.stat.pace_current',
            '현재 페이스',
          ),
          value: current,
          valueKey: paceCurrentKey,
          valueSize: statSize,
          labelSize: labelSize,
          valueColor: AppColors.nightInk,
        );
        final averageStat = _Stat(
          label: RemainingSurface.tr(
            context,
            'run_tracking.stat.pace_average',
            '평균 페이스',
          ),
          value: average,
          valueKey: paceAverageKey,
          valueSize: statSize,
          labelSize: labelSize,
          valueColor: AppColors.nightInk,
        );

        final block = wide
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  distanceStat,
                  SizedBox(height: height * 0.04),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: timeStat),
                      Expanded(child: currentStat),
                      Expanded(child: averageStat),
                    ],
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  distanceStat,
                  SizedBox(height: height * 0.03),
                  timeStat,
                  SizedBox(height: height * 0.02),
                  currentStat,
                  SizedBox(height: height * 0.02),
                  averageStat,
                ],
              );

        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: SizedBox(
            width: _finiteWidth(constraints.maxWidth),
            child: block,
          ),
        );
      },
    );
  }
}

double _finiteWidth(double width) => width.isFinite && width > 0 ? width : 280;

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.valueKey,
    required this.valueSize,
    required this.labelSize,
    required this.valueColor,
    this.unit,
  });

  final String label;
  final String value;
  final Key valueKey;
  final double valueSize;
  final double labelSize;
  final Color valueColor;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final valueStyle = TextStyle(
      fontFamily: AppTextStyles.fontFamily,
      color: valueColor,
      fontSize: valueSize,
      fontWeight: FontWeight.w900,
      height: 1,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final unitText = unit;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: AppColors.nightMuted,
            fontSize: labelSize,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: unitText == null
              ? Text(value, key: valueKey, maxLines: 1, style: valueStyle)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(value, key: valueKey, maxLines: 1, style: valueStyle),
                    const SizedBox(width: 6),
                    Text(
                      unitText,
                      maxLines: 1,
                      style: valueStyle.copyWith(
                        color: AppColors.nightMuted,
                        fontSize: valueSize * 0.38,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Heart rate and cadence, only for readings that exist.
class RunTrackingVitals extends StatelessWidget {
  const RunTrackingVitals({required this.telemetry, super.key});

  final RunTelemetry telemetry;

  static const vitalsKey = Key('run-live-vitals');

  @override
  Widget build(BuildContext context) {
    final hr = telemetry.currentHeartRate;
    final spm = telemetry.currentCadenceSpm;
    final hasHr = hr != null && hr > 0;
    final hasSpm = spm != null && spm > 0;
    if (!hasHr && !hasSpm) return const SizedBox.shrink();

    final String text;
    if (hasHr && hasSpm) {
      text = RemainingSurface.tr(
        context,
        'run_tracking.telemetry',
        '심박 \$hr BPM / 케이던스 \$spm SPM',
        {'hr': hr, 'spm': spm},
      );
    } else if (hasHr) {
      text = RemainingSurface.tr(
        context,
        'run_tracking.heart_rate',
        '심박 \$hr BPM',
        {'hr': hr},
      );
    } else {
      text = RemainingSurface.tr(
        context,
        'run_tracking.cadence',
        '케이던스 \$spm SPM',
        {'spm': spm},
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Text(
          text,
          key: vitalsKey,
          maxLines: 1,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: AppColors.nightMuted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
