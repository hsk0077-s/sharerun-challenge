import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../src_onboarding_controller.dart';

/// 머리가 전신의 약 2/3인 Chibi SD 러닝 마스코트 + 목걸이 메달.
/// 달팽이·예비 심사 미완이어도 블러/자물쇠/회색조 없이 원본 컬러로 그린다.
class ChibiTierAvatar extends StatelessWidget {
  const ChibiTierAvatar({
    super.key,
    required this.tier,
    this.size = 88,
    this.floating = false,
    this.showNeonRing = false,
  });

  final UserTier? tier;
  final double size;
  final bool floating;
  final bool showNeonRing;

  static Widget unmaskedAsset(UserTier resolved, double size) {
    return Image.asset(
      resolved.avatarAssetPath,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _ChibiPainter(tier: resolved)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = tier;
    Widget mascot = SizedBox(
      width: size,
      height: size,
      child: resolved == null
          ? CustomPaint(painter: const _ChibiPainter(tier: null))
          : unmaskedAsset(resolved, size),
    );

    if (showNeonRing) {
      mascot = SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(size),
              painter: const _NeonDonutPainter(),
            ),
            Padding(
              padding: EdgeInsets.all(size * 0.14),
              child: resolved == null
                  ? CustomPaint(painter: const _ChibiPainter(tier: null))
                  : unmaskedAsset(resolved, size),
            ),
          ],
        ),
      );
    }

    if (floating) {
      return _FloatingBob(child: mascot);
    }
    return mascot;
  }
}

class _FloatingBob extends StatefulWidget {
  const _FloatingBob({required this.child});

  final Widget child;

  @override
  State<_FloatingBob> createState() => _FloatingBobState();
}

class _FloatingBobState extends State<_FloatingBob>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final y = (Curves.easeInOut.transform(_controller.value) - 0.5) * 8;
        return Transform.translate(offset: Offset(0, y), child: child);
      },
      child: widget.child,
    );
  }
}

class _NeonDonutPainter extends CustomPainter {
  const _NeonDonutPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide * 0.46;
    final glow = Paint()
      ..color = AppColors.pulseCyan.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.07
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final ring = Paint()
      ..shader = SweepGradient(
        colors: [
          AppColors.pulseCyan,
          AppColors.tealAccent,
          AppColors.pulseCyan.withValues(alpha: 0.4),
          AppColors.pulseCyan,
        ],
      ).createShader(Rect.fromCircle(center: c, radius: r))
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.035;
    canvas.drawCircle(c, r, glow);
    canvas.drawCircle(c, r, ring);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChibiPainter extends CustomPainter {
  const _ChibiPainter({required this.tier});

  final UserTier? tier;

  Color get _bodyColor {
    if (tier == null) return AppColors.primaryMint;
    return switch (tier!.animal) {
      TierAnimal.turtle => const Color(0xFF66BB6A),
      TierAnimal.rabbit => const Color(0xFFFFCC80),
      TierAnimal.wolf => const Color(0xFF90A4AE),
      TierAnimal.gazelle => const Color(0xFFA1887F),
      TierAnimal.cheetah => const Color(0xFFFFB74D),
      TierAnimal.snail => const Color(0xFFA8B5A0),
    };
  }

  Color get _medalColor =>
      tier?.medal.medalColor ?? AppColors.tierMedalGold;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final isSnail = tier?.animal == TierAnimal.snail;
    final headR = h * (1 / 3); // diameter ≈ 2/3 height
    final headCenter = Offset(w / 2, headR + h * 0.02);
    final bodyTop = headCenter.dy + headR * 0.72;

    final bodyPaint = Paint()..color = _bodyColor;
    final headPaint = Paint()..color = _bodyColor.withValues(alpha: 0.95);
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035;

    // Small running body (bottom 1/3).
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w / 2, bodyTop + h * 0.14),
        width: w * 0.38,
        height: h * 0.28,
      ),
      Radius.circular(w * 0.12),
    );
    canvas.drawRRect(bodyRect, bodyPaint);

    // Legs in a running pose.
    final leg = Paint()
      ..color = _bodyColor
      ..strokeWidth = w * 0.07
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.42, h * 0.82),
      Offset(w * 0.28, h * 0.96),
      leg,
    );
    canvas.drawLine(
      Offset(w * 0.58, h * 0.82),
      Offset(w * 0.72, h * 0.94),
      leg,
    );

    // Medal on the neck — 달팽이(미심사)는 메달 수식 제외.
    if (!isSnail) {
      final medalCenter = Offset(w / 2, bodyTop + h * 0.02);
      canvas.drawCircle(medalCenter, w * 0.09, Paint()..color = _medalColor);
      canvas.drawCircle(medalCenter, w * 0.09, stroke);
    }

    // Oversized chibi head.
    canvas.drawCircle(headCenter, headR, headPaint);
    canvas.drawCircle(headCenter, headR, stroke);

    // Eyes (달팽이는 실망한 처진 눈).
    final eye = Paint()..color = AppColors.textBlack;
    final eyeY = isSnail
        ? headCenter.dy + headR * 0.02
        : headCenter.dy - headR * 0.08;
    canvas.drawCircle(
      Offset(headCenter.dx - headR * 0.32, eyeY),
      headR * 0.11,
      eye,
    );
    canvas.drawCircle(
      Offset(headCenter.dx + headR * 0.32, eyeY),
      headR * 0.11,
      eye,
    );

    // Smile / disappointed frown.
    final mouth = Paint()
      ..color = AppColors.textBlack
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.025
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(
          headCenter.dx,
          headCenter.dy + headR * (isSnail ? 0.38 : 0.18),
        ),
        width: headR * 0.7,
        height: headR * 0.45,
      ),
      isSnail ? 3.4 : 0.15,
      isSnail ? 2.5 : 2.8,
      false,
      mouth,
    );

    // Animal emoji hint (ear / shell cue).
    if (tier?.animal == TierAnimal.rabbit ||
        tier?.animal == TierAnimal.cheetah) {
      final ear = Paint()..color = _bodyColor;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(headCenter.dx - headR * 0.55, headCenter.dy - headR * 0.85),
          width: headR * 0.35,
          height: headR * 0.7,
        ),
        ear,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(headCenter.dx + headR * 0.55, headCenter.dy - headR * 0.85),
          width: headR * 0.35,
          height: headR * 0.7,
        ),
        ear,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChibiPainter oldDelegate) =>
      oldDelegate.tier != tier;
}
