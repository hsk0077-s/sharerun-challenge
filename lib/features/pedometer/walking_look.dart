import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:share_run_challenge/core/theme/theme.dart';

import '../onboarding/src_onboarding_controller.dart';

/// Walking Challenge look — Runday-leaning polish, **this screen only**.
///
/// Does not change [SrcTokens] / Home / Lobby. Gold stays reserved for
/// harvest and donation moments.
abstract final class WalkingLook {
  static const heroDeep = Color(0xFF0C2F2C);
  static const heroMid = Color(0xFF146057);
  static const heroLift = Color(0xFF1E8F7C);
  static const pageMist = Color(0xFFF3F7F5);
  static const onHero = Color(0xFFF7FFFC);
  static const onHeroMuted = Color(0xB8F7FFFC);
  static const harvestHi = Color(0xFFF6D56B);
  static const harvestLo = AppColors.angelGold;
  static const harvestInk = Color(0xFF3A2A08);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      heroDeep,
      heroMid,
      heroLift,
    ],
    stops: [0.0, 0.48, 1.0],
  );

  static const pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      pageMist,
      AppColors.bgGradientEnd,
    ],
  );

  static const harvestGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [harvestHi, harvestLo],
  );

  static List<BoxShadow> get harvestGlow => [
        BoxShadow(
          color: harvestLo.withValues(alpha: 0.42),
          blurRadius: 22,
          offset: const Offset(0, 8),
        ),
      ];

  static const glassLift = [
    BoxShadow(
      color: Color(0x140C2F2C),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  /// Same walking-challenge snail as after #21 (`chibi_snail_disappointed`),
  /// derived to a smile with the sigh puff removed. Not the gold-medal mascot.
  static const snailWalkingAsset =
      'assets/images/characters/chibi_snail_smiling.png';

  /// Alpha-only knockout for the snail PNG's opaque near-white plate.
  /// Does **not** tint pixels (no `primaryMint` / `BlendMode.multiply` rect).
  static const whitePlateKnockout = ColorFilter.matrix(<double>[
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    -4, -4, -4, 11.6, 0,
  ]);

  static String mascotAsset(UserTier tier) {
    if (tier.isSnail) return snailWalkingAsset;
    return tier.avatarAssetPath;
  }
}

/// Light mascot motion — Flutter [AnimationController] only.
/// No Rive / Lottie pipeline; the smiling-snail PNG stays the same asset.
enum WalkingMascotMotion { idle, walking, pickup }

/// Natural mascot — no token-colored rect / BlendMode tint.
class WalkingMascot extends StatefulWidget {
  const WalkingMascot({
    required this.tier,
    required this.size,
    this.moving = false,
    this.pickupNonce = 0,
    super.key,
  });

  final UserTier tier;
  final double size;

  /// Pedometer is counting (sensor / pedestrian walking).
  final bool moving;

  /// Increment to play a one-shot harvest pickup hop.
  final int pickupNonce;

  static const idleLoopDuration = Duration(milliseconds: 2400);
  static const walkLoopDuration = Duration(milliseconds: 520);
  static const pickupDuration = Duration(milliseconds: 720);

  @override
  State<WalkingMascot> createState() => _WalkingMascotState();
}

class _WalkingMascotState extends State<WalkingMascot>
    with TickerProviderStateMixin {
  late final AnimationController _loop;
  late final AnimationController _pickup;
  late final Listenable _tick;
  var _celebrating = false;

  WalkingMascotMotion get motion {
    if (MediaQuery.disableAnimationsOf(context)) {
      return WalkingMascotMotion.idle;
    }
    if (_celebrating) return WalkingMascotMotion.pickup;
    if (widget.moving) return WalkingMascotMotion.walking;
    return WalkingMascotMotion.idle;
  }

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: widget.moving
          ? WalkingMascot.walkLoopDuration
          : WalkingMascot.idleLoopDuration,
    )..repeat(reverse: true);
    _pickup = AnimationController(
      vsync: this,
      duration: WalkingMascot.pickupDuration,
    );
    _tick = Listenable.merge([_loop, _pickup]);
    _pickup.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _celebrating = false;
          _syncLoopDuration();
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant WalkingMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pickupNonce > oldWidget.pickupNonce) {
      _celebrating = true;
      _pickup.forward(from: 0);
    }
    if (widget.moving != oldWidget.moving) {
      _syncLoopDuration();
    }
  }

  void _syncLoopDuration() {
    final next = widget.moving && !_pickup.isAnimating
        ? WalkingMascot.walkLoopDuration
        : WalkingMascot.idleLoopDuration;
    if (_loop.duration == next) return;
    _loop.duration = next;
    if (!_loop.isAnimating) {
      _loop.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    _pickup.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final art = _untintedMascot();
    if (MediaQuery.disableAnimationsOf(context)) {
      return _groundedStack(
        size: size,
        lift: 0,
        tilt: 0,
        scaleX: 1,
        scaleY: 1,
        sparkle: 0,
        child: art,
      );
    }

    return AnimatedBuilder(
      animation: _tick,
      builder: (context, child) {
        final current = motion;
        final loopT = Curves.easeInOut.transform(_loop.value.clamp(0.0, 1.0));
        var lift = 0.0;
        var tilt = 0.0;
        var scaleX = 1.0;
        var scaleY = 1.0;
        var sparkle = 0.0;

        if (current == WalkingMascotMotion.pickup) {
          final t = _pickup.value.clamp(0.0, 1.0);
          final hop = t < 0.42
              ? Curves.easeOut.transform((t / 0.42).clamp(0.0, 1.0))
              : 1 -
                  Curves.easeIn.transform(
                    ((t - 0.42) / 0.58).clamp(0.0, 1.0),
                  );
          lift = hop * size * 0.16;
          scaleY = t < 0.42 ? 1 + hop * 0.07 : 1 - (1 - hop) * 0.07;
          scaleX = 2 - scaleY;
          tilt = math.sin(t * math.pi * 2) * 0.11;
          sparkle = (1 - (t - 0.15).abs() * 1.6).clamp(0.0, 1.0);
        } else {
          final walking = current == WalkingMascotMotion.walking;
          final amp = size * (walking ? 0.07 : 0.028);
          lift = loopT * amp;
          final sway = math.sin(_loop.value * math.pi);
          final dir = _loop.status == AnimationStatus.reverse ? -1.0 : 1.0;
          tilt = sway * dir * (walking ? 0.085 : 0.02);
          if (walking) {
            scaleY = 1 - loopT * 0.045;
            scaleX = 1 + loopT * 0.025;
          }
        }

        return _groundedStack(
          size: size,
          lift: lift,
          tilt: tilt,
          scaleX: scaleX,
          scaleY: scaleY,
          sparkle: sparkle,
          child: child!,
        );
      },
      child: art,
    );
  }

  Widget _groundedStack({
    required double size,
    required double lift,
    required double tilt,
    required double scaleX,
    required double scaleY,
    required double sparkle,
    required Widget child,
  }) {
    final shadowScale =
        (1.0 - (lift / (size * 0.28)).clamp(0.0, 0.42)).clamp(0.58, 1.0);
    return SizedBox(
      key: Key('walking-mascot-motion-${motion.name}'),
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: 2,
            child: IgnorePointer(
              child: Transform.scale(
                scaleX: shadowScale,
                scaleY: 0.72 + shadowScale * 0.28,
                child: Container(
                  width: size * 0.62,
                  height: size * 0.14,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(size),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: 0.22 * shadowScale,
                        ),
                        blurRadius: 10,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (sparkle > 0) ..._pickupSparkles(size, sparkle),
          Transform.translate(
            offset: Offset(0, -lift),
            child: Transform.rotate(
              angle: tilt,
              alignment: Alignment.bottomCenter,
              child: Transform.scale(
                scaleX: scaleX,
                scaleY: scaleY,
                alignment: Alignment.bottomCenter,
                child: Transform.flip(
                  flipX: true,
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _pickupSparkles(double size, double sparkle) {
    const offsets = <Offset>[
      Offset(-0.34, -0.72),
      Offset(0.30, -0.86),
      Offset(0.02, -1.02),
    ];
    return [
      for (var i = 0; i < offsets.length; i++)
        Positioned(
          left: size * (0.5 + offsets[i].dx) - 3.5,
          top: size * (0.5 + offsets[i].dy) - sparkle * 10,
          child: IgnorePointer(
            child: Opacity(
              opacity: sparkle,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: i.isEven
                      ? WalkingLook.harvestHi
                      : WalkingLook.harvestLo,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: WalkingLook.harvestHi.withValues(alpha: 0.55),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const SizedBox(width: 7, height: 7),
              ),
            ),
          ),
        ),
    ];
  }

  Widget _untintedMascot() {
    final image = Image.asset(
      WalkingLook.mascotAsset(widget.tier),
      key: const Key('walking-mascot'),
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => Icon(
        Icons.pets_rounded,
        size: widget.size * 0.55,
        color: WalkingLook.onHero,
      ),
    );
    if (!widget.tier.isSnail) return image;
    return ColorFiltered(
      colorFilter: WalkingLook.whitePlateKnockout,
      child: image,
    );
  }
}

/// Glamorous harvest CTA — gold gradient + glow. Behavior stays with [onPressed].
class WalkingHarvestCta extends StatelessWidget {
  const WalkingHarvestCta({
    required this.hasPendingCoins,
    required this.pendingCoinsInt,
    required this.onPressed,
    super.key,
  });

  final bool hasPendingCoins;
  final int pendingCoinsInt;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(tokens.radii.pill);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: hasPendingCoins ? WalkingLook.harvestGlow : const [],
      ),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: hasPendingCoins
                ? WalkingLook.harvestGradient
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      WalkingLook.harvestHi.withValues(alpha: 0.42),
                      WalkingLook.harvestLo.withValues(alpha: 0.32),
                    ],
                  ),
            borderRadius: radius,
          ),
          child: FilledButton(
            key: const Key('walking-harvest-cta'),
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              foregroundColor: WalkingLook.harvestInk,
              shadowColor: Colors.transparent,
              elevation: 0,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(borderRadius: radius),
            ),
            child: Text(
              hasPendingCoins
                  ? '$pendingCoinsInt SHARE 줍기'
                  : '코인 쌓이는 중...',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 17,
                letterSpacing: -0.2,
                color: WalkingLook.harvestInk,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
