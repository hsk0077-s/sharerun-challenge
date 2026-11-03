import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/remaining_surface.dart';
import '../onboarding/src_onboarding_controller.dart';
import '../profile/widgets/tier_circle_badge.dart';
import '../run_result/run_finish_share_card.dart';

/// Image card for the Walking Challenge "오늘의 목표 달성" brag.
///
/// Design A: deep navy fading to teal, lime light beams and confetti, the
/// logo top left, a ribbon with the headline, the big step count in the
/// middle and the tier animal in a glowing ring at the bottom.
///
/// Two sizes, same content: 4:5 (1080×1350) for chat rooms and the system
/// sheet, 1:1 (1080×1080) for the KakaoTalk feed card. It reuses the run
/// finish card's palette type, atmosphere, track lines, tier circle and brand
/// lockup. Everything on it is already on the phone: the step count the
/// walking screen computed, the goal, the date, the tier and, when the server
/// has confirmed them, today's SHARE and the streak.
class WalkingGoalShareCard extends StatelessWidget {
  const WalkingGoalShareCard({
    required this.steps,
    required this.goalSteps,
    required this.date,
    this.badges,
    this.shareToday,
    this.streakDays,
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
  static const animalKey = Key('walking-goal-card-animal');
  static const shareKey = Key('walking-goal-card-share');
  static const streakKey = Key('walking-goal-card-streak');
  static const taglineKey = Key('walking-goal-card-tagline');

  /// Streaks shorter than this are not worth showing ("1 day" is not a streak).
  static const minStreakShown = 2;

  static String get headline => RemainingSurface.trNow(
        'pedometer.walking_goal_share_card.headline',
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
  static String get tagline => RemainingSurface.trNow(
        'pedometer.walking_goal_share_card.tagline',
        '나도 걸으면 리워드와 기부가 쌓여요',
      );
  static String goalLine(int goalSteps) => RemainingSurface.trNow(
        'pedometer.walking_goal_share_card.goal',
        '목표 ${commaSteps(goalSteps)}걸음',
        {'goal': commaSteps(goalSteps)},
      );
  static String streakLine(int days) => RemainingSurface.trNow(
        'pedometer.walking_goal_share_card.streak',
        '$days일 연속',
        {'days': days},
      );

  /// Korean text may otherwise break in the middle of a word ("쌓/여요").
  /// A word joiner (zero width) between the letters of a word keeps each word
  /// whole; lines still break at spaces.
  static String keepWordsTogether(String text) {
    return text
        .split(' ')
        .map((word) => word.runes.map(String.fromCharCode).join('\u2060'))
        .join(' ');
  }

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

  /// Navy to teal, lime light. Same fields as the run finish themes.
  static const palette = RunFinishCardPalette(
    background: [Color(0xFF06142E), Color(0xFF0A4A63), Color(0xFF0E8A8A)],
    glow: Color(0xFFB6F23A),
    glowAlpha: 0.30,
    hero: Color(0xFFFFFFFF),
    unit: Color(0xFFC8F560),
    muted: Color(0xD6FFFFFF),
    stat: Color(0xFFFFFFFF),
    route: Color(0xFFC8F560),
    hairline: Color(0x38FFFFFF),
    decor: Color(0xFF8FE3E0),
    chip: Color(0xFF0B2E4A),
    icon: Color(0xFFC8F560),
    iconPlate: Color(0xFF12506A),
    badge: Color(0xFFC8F560),
    badgeInk: Color(0xFF06142E),
  );

  final int steps;
  final int goalSteps;
  final DateTime date;

  /// 동물 티어·천사 등급 원. 동물이 없으면(null) 그리지 않는다.
  final RunFinishTierBadges? badges;

  /// 오늘 모은 SHARE. 서버가 확정한 값만 넘긴다. null이나 0이면 그리지 않는다.
  final int? shareToday;

  /// 연속 달성 일수. [minStreakShown]보다 짧으면 그리지 않는다.
  final int? streakDays;

  /// 1080×1080 instead of 1080×1350. Same content, tighter spacing.
  final bool square;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.maybeOf(context) ?? const MediaQueryData();
    final showShare = shareToday != null && shareToday! > 0;
    final showStreak = streakDays != null && streakDays! >= minStreakShown;
    final hasAnimal = badges != null && badges!.hasAnimal;
    final hasAngel = badges != null && badges!.hasAngel;
    final animalSize = square ? 210.0 : 290.0;
    final heroFont = square ? 190.0 : 244.0;
    final goalSize = square ? 198.0 : 206.0;
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
              color: const Color(0xFF06142E),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: palette.background,
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: RunFinishAtmospherePainter(palette)),
                CustomPaint(painter: RunFinishTrackFieldPainter(palette.decor)),
                const CustomPaint(painter: _BeamPainter()),
                const CustomPaint(painter: _ConfettiPainter()),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      76, square ? 56 : 76, 76, square ? 52 : 72),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const RunFinishBrandLockup(
                            palette: palette,
                            showHairline: false,
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Text(
                              runFinishDateLabel(date),
                              key: dateKey,
                              maxLines: 1,
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: RunFinishShareCard.fontFamily,
                                fontSize: 30,
                                fontWeight: FontWeight.w600,
                                color: Color(0xD6FFFFFF),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: square ? 20 : 30),
                      _Ribbon(text: headline, compact: square),
                      const Spacer(),
                      Text(
                        stepsLabel,
                        style: const TextStyle(
                          fontFamily: RunFinishShareCard.fontFamily,
                          fontSize: 38,
                          fontWeight: FontWeight.w700,
                          color: Color(0xD6FFFFFF),
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
                                fontSize: heroFont,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -7,
                                color: palette.hero,
                                height: 1.1,
                                shadows: const [
                                  Shadow(
                                    color: Color(0x66B6F23A),
                                    blurRadius: 40,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Text(
                                stepsUnit,
                                style: TextStyle(
                                  fontFamily: RunFinishShareCard.fontFamily,
                                  fontSize: 60,
                                  fontWeight: FontWeight.w700,
                                  color: palette.unit,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: square ? 14 : 22),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _GoalCircle(
                            text: goalLine(goalSteps),
                            size: goalSize,
                          ),
                          const SizedBox(width: 28),
                          Expanded(
                            child: Wrap(
                              spacing: 14,
                              runSpacing: 14,
                              children: [
                                if (showShare)
                                  _Chip(
                                    key: shareKey,
                                    text: '+${commaSteps(shareToday!)} SHARE',
                                    leading: const _Dot(),
                                  ),
                                if (showStreak)
                                  _Chip(
                                    key: streakKey,
                                    text: streakLine(streakDays!),
                                    leading: const CustomPaint(
                                      size: Size(34, 40),
                                      painter: _FlamePainter(),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (hasAnimal)
                            _TierHero(
                              key: animalKey,
                              image: badges!.animalImage!,
                              label: badges!.animalLabel!,
                              size: animalSize,
                              angel: hasAngel
                                  ? RunFinishTierBadges(
                                      angelImage: badges!.angelImage,
                                      angelLabel: badges!.angelLabel,
                                      angelEmoji: badges!.angelEmoji,
                                    )
                                  : null,
                            ),
                          if (hasAnimal) SizedBox(width: hasAngel ? 66 : 36),
                          Expanded(
                            child: Text(
                              keepWordsTogether(tagline),
                              key: taglineKey,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: RunFinishShareCard.fontFamily,
                                fontSize: square ? 40 : 46,
                                fontWeight: FontWeight.w800,
                                height: 1.3,
                                color: palette.hero,
                              ),
                            ),
                          ),
                        ],
                      ),
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

/// Headline on a ribbon with notched ends.
class _Ribbon extends StatelessWidget {
  const _Ribbon({required this.text, required this.compact});

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _RibbonPainter(),
      child: Padding(
        padding:
            EdgeInsets.symmetric(horizontal: 56, vertical: compact ? 14 : 20),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            key: WalkingGoalShareCard.headlineKey,
            maxLines: 1,
            style: TextStyle(
              fontFamily: RunFinishShareCard.fontFamily,
              fontSize: compact ? 70 : 82,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
              height: 1.2,
              color: const Color(0xFF06142E),
            ),
          ),
        ),
      ),
    );
  }
}

class _RibbonPainter extends CustomPainter {
  const _RibbonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final notch = size.height * 0.28;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width - notch, size.height / 2)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..lineTo(notch, size.height / 2)
      ..close();
    canvas.drawShadow(path, const Color(0x99000000), 12, false);
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFD9FF7A), Color(0xFFB6F23A)],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _RibbonPainter oldDelegate) => false;
}

/// A ring with the goal inside: the goal was reached, so the ring is closed.
class _GoalCircle extends StatelessWidget {
  const _GoalCircle({required this.text, required this.size});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size < 200 ? 14 : 20),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: WalkingGoalShareCard.palette.chip,
        border: Border.all(color: WalkingGoalShareCard.palette.unit, width: 8),
        boxShadow: const [
          BoxShadow(color: Color(0x55B6F23A), blurRadius: 36, spreadRadius: 2),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomPaint(
            size: const Size(40, 40),
            painter: _CheckPainter(
              ring: WalkingGoalShareCard.palette.unit,
              tick: WalkingGoalShareCard.palette.chip,
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              WalkingGoalShareCard.keepWordsTogether(text),
              key: WalkingGoalShareCard.goalKey,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: RunFinishShareCard.fontFamily,
                fontSize: size < 200 ? 24 : 30,
                fontWeight: FontWeight.w800,
                color: WalkingGoalShareCard.palette.hero,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({super.key, required this.text, required this.leading});

  final String text;
  final Widget leading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: WalkingGoalShareCard.palette.chip,
        borderRadius: BorderRadius.circular(60),
        border: Border.all(
          color: WalkingGoalShareCard.palette.unit.withValues(alpha: 0.7),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            leading,
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                fontFamily: RunFinishShareCard.fontFamily,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: WalkingGoalShareCard.palette.hero,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: WalkingGoalShareCard.palette.unit,
      ),
    );
  }
}

/// The tier animal, large, in a glowing ring. The angel tier, when there is
/// one, sits on its lower right as a small circle (same widget the run finish
/// card uses). A user with no tier yet gets the default character.
class _TierHero extends StatelessWidget {
  const _TierHero({
    super.key,
    required this.image,
    required this.label,
    required this.size,
    this.angel,
  });

  final String image;
  final String label;
  final double size;
  final RunFinishTierBadges? angel;

  @override
  Widget build(BuildContext context) {
    final palette = WalkingGoalShareCard.palette;
    return SizedBox(
      width: size + 20,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: size,
                height: size,
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const SweepGradient(
                    colors: [
                      Color(0xFFD9FF7A),
                      Color(0xFF3FD0C9),
                      Color(0xFFB6F23A),
                      Color(0xFFD9FF7A),
                    ],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x88B6F23A),
                      blurRadius: 60,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: ClipOval(
                    child: Transform.scale(
                      scale: 1.2,
                      child: Image.asset(
                        image,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: RunFinishShareCard.fontFamily,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: palette.hero,
                  height: 1.2,
                ),
              ),
            ],
          ),
          if (angel != null && !angel!.isEmpty)
            Positioned(
              right: -34,
              top: size * 0.50,
              child: Transform.scale(
                scale: 0.62,
                alignment: Alignment.topRight,
                child: RunFinishTierBadgeRow(
                  key: WalkingGoalShareCard.badgesKey,
                  badges: angel!,
                  palette: palette,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Soft lime beams fanning out from the top left corner.
class _BeamPainter extends CustomPainter {
  const _BeamPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const lime = Color(0xFFB6F23A);
    final beams = <List<double>>[
      // angle (deg from the x axis), spread (deg), alpha
      [28, 7, 0.16],
      [44, 5, 0.12],
      [60, 9, 0.10],
      [14, 4, 0.10],
    ];
    final origin = Offset(size.width * 0.12, -size.height * 0.04);
    final reach = size.height * 1.4;
    for (final beam in beams) {
      final a1 = (beam[0] - beam[1] / 2) * math.pi / 180;
      final a2 = (beam[0] + beam[1] / 2) * math.pi / 180;
      final path = Path()
        ..moveTo(origin.dx, origin.dy)
        ..lineTo(
            origin.dx + reach * math.cos(a1), origin.dy + reach * math.sin(a1))
        ..lineTo(
            origin.dx + reach * math.cos(a2), origin.dy + reach * math.sin(a2))
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              lime.withValues(alpha: beam[2]),
              lime.withValues(alpha: 0),
            ],
          ).createShader(Offset.zero & size),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BeamPainter oldDelegate) => false;
}

/// Fixed confetti, so the golden and the shared image are always the same.
class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter();

  // x, y (fractions), size, turns, color index.
  static const _bits = <List<double>>[
    [0.50, 0.20, 22, 0.1, 0],
    [0.62, 0.26, 16, 0.6, 1],
    [0.72, 0.16, 20, 0.3, 2],
    [0.84, 0.30, 14, 0.8, 0],
    [0.92, 0.20, 24, 0.2, 1],
    [0.56, 0.38, 18, 0.7, 2],
    [0.08, 0.34, 22, 0.4, 0],
    [0.94, 0.46, 16, 0.9, 1],
    [0.05, 0.50, 18, 0.5, 2],
    [0.46, 0.46, 14, 0.2, 0],
    [0.90, 0.62, 20, 0.6, 2],
    [0.40, 0.14, 14, 0.1, 1],
    [0.78, 0.40, 12, 0.35, 0],
    [0.30, 0.30, 12, 0.75, 1],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const colors = [Color(0xFFC8F560), Color(0xFF3FD0C9), Color(0xFFFFFFFF)];
    for (final bit in _bits) {
      final paint = Paint()
        ..color =
            colors[bit[4].toInt() % colors.length].withValues(alpha: 0.85);
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
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => false;
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

/// A small flame for the streak chip. Drawn, not an emoji, so it looks the
/// same on every phone and in the golden.
class _FlamePainter extends CustomPainter {
  const _FlamePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final outer = Path()
      ..moveTo(w * 0.50, 0)
      ..cubicTo(w * 0.62, h * 0.22, w * 0.98, h * 0.36, w * 0.92, h * 0.68)
      ..cubicTo(w * 0.88, h * 0.90, w * 0.68, h, w * 0.50, h)
      ..cubicTo(w * 0.30, h, w * 0.08, h * 0.88, w * 0.08, h * 0.64)
      ..cubicTo(w * 0.08, h * 0.46, w * 0.22, h * 0.40, w * 0.28, h * 0.22)
      ..cubicTo(w * 0.40, h * 0.30, w * 0.44, h * 0.16, w * 0.50, 0)
      ..close();
    canvas.drawPath(outer, Paint()..color = const Color(0xFFFFA630));
    final inner = Path()
      ..moveTo(w * 0.50, h * 0.46)
      ..cubicTo(w * 0.60, h * 0.60, w * 0.74, h * 0.66, w * 0.68, h * 0.82)
      ..cubicTo(w * 0.62, h * 0.96, w * 0.38, h * 0.96, w * 0.32, h * 0.82)
      ..cubicTo(w * 0.28, h * 0.68, w * 0.44, h * 0.62, w * 0.50, h * 0.46)
      ..close();
    canvas.drawPath(inner, Paint()..color = const Color(0xFFFFE066));
  }

  @override
  bool shouldRepaint(covariant _FlamePainter oldDelegate) => false;
}

/// Tier circles for the goal card. A user with no animal tier yet (snail)
/// gets the default snail character, not an empty spot. The angel circle is
/// left out until the user has an angel tier.
RunFinishTierBadges walkingGoalBadges(
  BuildContext context, {
  required UserTier tier,
  required AngelTier angel,
}) {
  return RunFinishTierBadges(
    animalImage: tier.avatarAssetPath,
    animalLabel: tier.animalName(Localizations.localeOf(context)),
    angelImage: angel == AngelTier.preAngel ? null : angel.avatarAssetPath,
    angelLabel:
        angel == AngelTier.preAngel ? null : angel.circleLabelFor(context),
    angelEmoji: angel.emoji,
  );
}
