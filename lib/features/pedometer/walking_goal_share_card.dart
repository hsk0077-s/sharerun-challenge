import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/remaining_surface.dart';
import '../onboarding/src_onboarding_controller.dart';
import '../profile/widgets/tier_circle_badge.dart';
import '../run_result/run_finish_share_card.dart';

/// Image card for the Walking Challenge "오늘의 목표 달성" brag.
///
/// 4:5 (1080×1350) so KakaoTalk chat rooms do not crop it. It reuses the run
/// finish card's palette, atmosphere, tier circles and brand lockup; only the
/// record block differs. Everything on it is already on the phone: the step
/// count the walking screen computed, the goal, the date and the tier.
class WalkingGoalShareCard extends StatelessWidget {
  const WalkingGoalShareCard({
    required this.steps,
    required this.goalSteps,
    required this.date,
    this.style = RunFinishCardTheme.mint,
    this.badges,
    this.square = false,
    super.key,
  });

  static const canvasWidth = 1080.0;

  /// 4:5, for KakaoTalk chat rooms and the system sheet.
  static const canvasHeight = 1350.0;

  /// 1:1, for the KakaoTalk feed card image.
  static const squareHeight = 1080.0;

  static const headlineKey = Key('walking-goal-card-headline');
  static const stepsKey = Key('walking-goal-card-steps');
  static const goalKey = Key('walking-goal-card-goal');
  static const dateKey = Key('walking-goal-card-date');
  static const badgesKey = Key('walking-goal-card-badges');

  static String get headline => RemainingSurface.trNow(
        'pedometer.walking_challenge_share.body.12',
        '오늘의 목표 달성!',
      );
  static String get stepsLabel => RemainingSurface.trNow(
        'profile.retention_widgets.body.2',
        '오늘 걸음',
      );
  static String get stepsUnit => RemainingSurface.trNow(
        'solo_pedometer.body.9',
        '걸음',
      );
  static String goalLine(int goalSteps) => RemainingSurface.trNow(
        'pedometer.walking_goal_share_card.goal',
        '목표 ${commaSteps(goalSteps)}걸음',
        {'goal': commaSteps(goalSteps)},
      );

  /// `12,345`. The card never shows a negative count.
  static String commaSteps(int value) {
    final digits = math.max(0, value).toString();
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
      out.write(digits[i]);
    }
    return out.toString();
  }

  final int steps;
  final int goalSteps;
  final DateTime date;
  final RunFinishCardTheme style;

  /// 동물 티어·천사 등급 원. null이거나 비어 있으면 그리지 않는다.
  final RunFinishTierBadges? badges;

  /// 1080×1080 instead of 1080×1350. Same content, tighter spacing.
  final bool square;

  @override
  Widget build(BuildContext context) {
    final palette = RunFinishCardPalette.of(style);
    final media = MediaQuery.maybeOf(context) ?? const MediaQueryData();
    final hasBadges = badges != null && !badges!.isEmpty;
    return DefaultTextStyle(
      style: const TextStyle(
        decoration: TextDecoration.none,
        fontFamily: RunFinishShareCard.fontFamily,
      ),
      child: MediaQuery(
        data: media.copyWith(textScaler: TextScaler.noScaling),
        child: SizedBox(
          width: canvasWidth,
          height: square ? squareHeight : canvasHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF07110E),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: palette.background,
                stops: const [0.0, 0.48, 1.0],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: RunFinishAtmospherePainter(palette)),
                CustomPaint(painter: RunFinishTrackFieldPainter(palette.decor)),
                CustomPaint(painter: _ConfettiPainter(palette)),
                Padding(
                  padding: EdgeInsets.fromLTRB(76, square ? 64 : 84, 76, square ? 60 : 76),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          headline,
                          key: headlineKey,
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: RunFinishShareCard.fontFamily,
                            fontSize: 88,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                            letterSpacing: -2,
                            color: palette.hero,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: palette.unit,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Flexible(
                                  child: Text(
                                    runFinishDateLabel(date),
                                    key: dateKey,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: RunFinishShareCard.fontFamily,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w600,
                                      color: palette.muted,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (hasBadges) ...[
                            const SizedBox(width: 24),
                            RunFinishTierBadgeRow(
                              key: badgesKey,
                              badges: badges!,
                              palette: palette,
                            ),
                          ],
                        ],
                      ),
                      const Spacer(),
                      Text(
                        stepsLabel,
                        style: TextStyle(
                          fontFamily: RunFinishShareCard.fontFamily,
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          color: palette.muted,
                          height: 1.3,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              commaSteps(steps),
                              key: stepsKey,
                              style: TextStyle(
                                fontFamily: RunFinishShareCard.fontFamily,
                                fontSize: square ? 200 : 232,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -7,
                                color: palette.hero,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 22),
                              child: Text(
                                stepsUnit,
                                style: TextStyle(
                                  fontFamily: RunFinishShareCard.fontFamily,
                                  fontSize: 64,
                                  fontWeight: FontWeight.w700,
                                  color: palette.unit,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: palette.chip,
                          borderRadius: BorderRadius.circular(60),
                          border: Border.all(
                            color: palette.unit.withValues(alpha: 0.7),
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 34, vertical: 16),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomPaint(
                                size: const Size(44, 44),
                                painter: _CheckPainter(
                                  ring: palette.unit,
                                  tick: palette.chip,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                goalLine(goalSteps),
                                key: goalKey,
                                style: TextStyle(
                                  fontFamily: RunFinishShareCard.fontFamily,
                                  fontSize: 38,
                                  fontWeight: FontWeight.w800,
                                  color: palette.hero,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      RunFinishBrandLockup(palette: palette),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A filled circle with a tick. Drawn by hand so the shared image does not
/// depend on the icon font being available.
class _CheckPainter extends CustomPainter {
  const _CheckPainter({required this.ring, required this.tick});

  final Color ring;
  final Color tick;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawCircle(c, size.width / 2, Paint()..color = ring);
    final path = Path()
      ..moveTo(size.width * 0.27, size.height * 0.52)
      ..lineTo(size.width * 0.43, size.height * 0.68)
      ..lineTo(size.width * 0.74, size.height * 0.34);
    canvas.drawPath(
      path,
      Paint()
        ..color = tick
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.11
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _CheckPainter oldDelegate) =>
      oldDelegate.ring != ring || oldDelegate.tick != tick;
}

/// Fixed confetti, so the golden and the shared image are always the same.
class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter(this.palette);

  final RunFinishCardPalette palette;

  // x, y (fractions), size, turns, color index.
  static const _bits = <List<double>>[
    [0.08, 0.30, 22, 0.1, 0],
    [0.18, 0.42, 16, 0.6, 1],
    [0.30, 0.22, 20, 0.3, 2],
    [0.47, 0.30, 14, 0.8, 0],
    [0.62, 0.26, 24, 0.2, 1],
    [0.74, 0.40, 18, 0.7, 2],
    [0.88, 0.33, 22, 0.4, 0],
    [0.93, 0.56, 16, 0.9, 1],
    [0.06, 0.62, 18, 0.5, 2],
    [0.14, 0.72, 14, 0.2, 0],
    [0.86, 0.74, 20, 0.6, 2],
    [0.70, 0.64, 14, 0.1, 1],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [palette.unit, palette.glow, palette.hero];
    for (final bit in _bits) {
      final paint = Paint()
        ..color =
            colors[bit[4].toInt() % colors.length].withValues(alpha: 0.75);
      canvas.save();
      canvas.translate(size.width * bit[0], size.height * bit[1]);
      canvas.rotate(bit[3] * math.pi * 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: bit[2], height: bit[2] * 0.5),
          const Radius.circular(4),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.palette != palette;
}

/// Tier circles for the goal card, same rules as the run finish poster: a
/// circle is left out while the user has no animal tier (snail) or no angel
/// tier yet (pre-angel).
RunFinishTierBadges walkingGoalBadges(
  BuildContext context, {
  required UserTier tier,
  required AngelTier angel,
}) {
  return RunFinishTierBadges(
    animalImage: tier.isSnail ? null : tier.avatarAssetPath,
    animalLabel:
        tier.isSnail ? null : tier.animalName(Localizations.localeOf(context)),
    angelImage: angel == AngelTier.preAngel ? null : angel.avatarAssetPath,
    angelLabel:
        angel == AngelTier.preAngel ? null : angel.circleLabelFor(context),
    angelEmoji: angel.emoji,
  );
}
