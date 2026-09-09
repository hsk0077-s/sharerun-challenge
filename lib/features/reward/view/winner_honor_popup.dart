import 'dart:math';

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

class WinnerHonorPopup extends StatefulWidget {
  const WinnerHonorPopup({
    required this.rewardValueToken,
    required this.onDonateHalf,
    required this.onDonateAll,
    this.onClaimAll,
    super.key,
  });

  final int rewardValueToken;
  final VoidCallback onDonateHalf;
  final VoidCallback onDonateAll;
  final VoidCallback? onClaimAll;

  static Future<void> show({
    required BuildContext context,
    required int rewardValueToken,
    required VoidCallback onDonateHalf,
    required VoidCallback onDonateAll,
    VoidCallback? onClaimAll,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      pageBuilder: (context, animation, secondaryAnimation) {
        return WinnerHonorPopup(
          rewardValueToken: rewardValueToken,
          onDonateHalf: () {
            Navigator.of(context).pop();
            onDonateHalf();
          },
          onDonateAll: () {
            Navigator.of(context).pop();
            onDonateAll();
          },
          onClaimAll: onClaimAll == null
              ? null
              : () {
                  Navigator.of(context).pop();
                  onClaimAll();
                },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<WinnerHonorPopup> createState() => _WinnerHonorPopupState();
}

class _WinnerHonorPopupState extends State<WinnerHonorPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _particles = <_Particle>[];
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    for (var i = 0; i < 48; i++) {
      _particles.add(_Particle.random(_random));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 360,
              height: 520,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _FireworksPainter(
                      particles: _particles,
                      progress: _controller.value,
                    ),
                  );
                },
              ),
            ),
            Container(
              width: 340,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              decoration: BoxDecoration(
                color: AppColors.cardBlack,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.neonLime.withValues(alpha: 0.45),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonLime.withValues(alpha: 0.15),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: AppColors.neonLime,
                    size: 72,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '챌린지 우승!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.neonLime,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '당신의 땀방울이 세상을 바꿉니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '+${widget.rewardValueToken} SRV',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppColors.electricBlue,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.neonLime,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: widget.onDonateHalf,
                      child: const Text(
                        '우승 상금 50% 기부하기',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.electricBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: widget.onDonateAll,
                      child: const Text(
                        '우승 상금 100% 전액 기부하기',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  if (widget.onClaimAll != null) ...[
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: widget.onClaimAll,
                      child: const Text('우승 상금 수령하기'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.color,
    required this.speed,
    required this.angle,
  });

  final double x;
  final double y;
  final Color color;
  final double speed;
  final double angle;

  factory _Particle.random(Random random) {
    final colors = [
      AppColors.neonLime,
      AppColors.electricBlue,
      Colors.purpleAccent,
      Colors.amberAccent,
    ];
    return _Particle(
      x: random.nextDouble(),
      y: random.nextDouble(),
      color: colors[random.nextInt(colors.length)],
      speed: 0.15 + random.nextDouble() * 0.35,
      angle: random.nextDouble() * pi * 2,
    );
  }
}

class _FireworksPainter extends CustomPainter {
  _FireworksPainter({
    required this.particles,
    required this.progress,
  });

  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final phase = (progress + particle.speed) % 1.0;
      final radius = phase * size.shortestSide * 0.45;
      final center = Offset(size.width * 0.5, size.height * 0.42);
      final dx = cos(particle.angle) * radius;
      final dy = sin(particle.angle) * radius;
      final paint = Paint()
        ..color = particle.color.withValues(alpha: (1 - phase).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        center + Offset(dx + (particle.x - 0.5) * 20, dy + (particle.y - 0.5) * 20),
        3 + (1 - phase) * 2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FireworksPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
