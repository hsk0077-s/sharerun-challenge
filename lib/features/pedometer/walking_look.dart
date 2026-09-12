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
enum WalkingMascotMotion { idle, walking, pickup, staticPose }

/// One frame of snail motion. Factors are of [WalkingMascot.size] so travel
/// stays visible on the real ~80–96px walking track (the smiling PNG has
/// large transparent padding — #26's 2.8%/7% lifts were ~2–7px and read as
/// static).
///
/// Product (#29): idle / waddle / harvest hop are **off**. The smiling snail
/// stays a grounded PNG. [WalkingMascot.motionEnabled] is the kill switch —
/// do not leave a half-running controller.
class WalkingMascotPose {
  const WalkingMascotPose({
    required this.lift,
    required this.slide,
    required this.tilt,
    required this.scaleX,
    required this.scaleY,
    required this.sparkle,
  });

  final double lift;
  final double slide;
  final double tilt;
  final double scaleX;
  final double scaleY;
  final double sparkle;
}

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

  /// Clean disable — idle bob, walk waddle, and harvest hop stay off.
  /// The smiling-snail asset is unchanged.
  static const motionEnabled = false;

  static const idleLoopDuration = Duration(milliseconds: 1800);
  static const walkLoopDuration = Duration(milliseconds: 460);
  static const pickupDuration = Duration(milliseconds: 720);

  static const idleLiftFactor = 0.15;
  static const walkLiftFactor = 0.18;
  static const walkSlideFactor = 0.12;
  static const idleSlideFactor = 0.045;
  static const pickupHopFactor = 0.32;

  static const groundedPose = WalkingMascotPose(
    lift: 0,
    slide: 0,
    tilt: 0,
    scaleX: 1,
    scaleY: 1,
    sparkle: 0,
  );

  static WalkingMascotPose evaluatePose({
    required WalkingMascotMotion motion,
    required double size,
    required double loopValue,
    required bool loopReversing,
    required double pickupValue,
  }) {
    if (!motionEnabled || motion == WalkingMascotMotion.staticPose) {
      return groundedPose;
    }
    final loopT = Curves.easeInOut.transform(loopValue.clamp(0.0, 1.0));
    if (motion == WalkingMascotMotion.pickup) {
      final t = pickupValue.clamp(0.0, 1.0);
      final hop = t < 0.42
          ? Curves.easeOut.transform((t / 0.42).clamp(0.0, 1.0))
          : 1 -
              Curves.easeIn.transform(
                ((t - 0.42) / 0.58).clamp(0.0, 1.0),
              );
      final lift = hop * size * pickupHopFactor;
      final scaleY = t < 0.42 ? 1 + hop * 0.10 : 1 - (1 - hop) * 0.10;
      return WalkingMascotPose(
        lift: lift,
        slide: 0,
        tilt: math.sin(t * math.pi * 2) * 0.16,
        scaleX: 2 - scaleY,
        scaleY: scaleY,
        sparkle: (1 - (t - 0.15).abs() * 1.6).clamp(0.0, 1.0),
      );
    }
    final walking = motion == WalkingMascotMotion.walking;
    final sway = math.sin(loopValue * math.pi);
    final dir = loopReversing ? -1.0 : 1.0;
    return WalkingMascotPose(
      lift: loopT * size * (walking ? walkLiftFactor : idleLiftFactor),
      slide: sway * dir * size * (walking ? walkSlideFactor : idleSlideFactor),
      tilt: sway * dir * (walking ? 0.18 : 0.07),
      scaleX: walking ? 1 + loopT * 0.06 : 1 + loopT * 0.02,
      scaleY: walking ? 1 - loopT * 0.08 : 1 - loopT * 0.025,
      sparkle: 0,
    );
  }

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
    if (!WalkingMascot.motionEnabled) {
      return WalkingMascotMotion.staticPose;
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
    );
    _pickup = AnimationController(
      vsync: this,
      duration: WalkingMascot.pickupDuration,
    );
    _tick = Listenable.merge([_loop, _pickup]);
    if (!WalkingMascot.motionEnabled) {
      return;
    }
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (WalkingMascot.motionEnabled) {
      _ensureLooping();
    }
  }

  @override
  void didUpdateWidget(covariant WalkingMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!WalkingMascot.motionEnabled) {
      return;
    }
    if (widget.pickupNonce > oldWidget.pickupNonce) {
      _celebrating = true;
      _pickup.forward(from: 0);
    }
    if (widget.moving != oldWidget.moving) {
      _syncLoopDuration();
    }
    _ensureLooping();
  }

  void _syncLoopDuration() {
    final next = widget.moving && !_pickup.isAnimating
        ? WalkingMascot.walkLoopDuration
        : WalkingMascot.idleLoopDuration;
    if (_loop.duration != next) {
      _loop.duration = next;
    }
    _ensureLooping();
  }

  void _ensureLooping() {
    if (!WalkingMascot.motionEnabled) {
      _loop.stop();
      _loop.value = 0;
      return;
    }
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
    return AnimatedBuilder(
      animation: _tick,
      builder: (context, child) {
        final pose = WalkingMascot.evaluatePose(
          motion: motion,
          size: size,
          loopValue: _loop.value,
          loopReversing: _loop.status == AnimationStatus.reverse,
          pickupValue: _pickup.value,
        );
        return _groundedStack(
          size: size,
          lift: pose.lift,
          slide: pose.slide,
          tilt: pose.tilt,
          scaleX: pose.scaleX,
          scaleY: pose.scaleY,
          sparkle: pose.sparkle,
          child: child!,
        );
      },
      child: art,
    );
  }

  Widget _groundedStack({
    required double size,
    required double lift,
    required double slide,
    required double tilt,
    required double scaleX,
    required double scaleY,
    required double sparkle,
    required Widget child,
  }) {
    final shadowScale =
        (1.0 - (lift / (size * 0.28)).clamp(0.0, 0.42)).clamp(0.58, 1.0);
    return SizedBox(
      key: Key(
        'walking-mascot-motion-${motion == WalkingMascotMotion.staticPose ? 'static' : motion.name}',
      ),
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
            key: const Key('walking-mascot-pose'),
            offset: Offset(slide, -lift),
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
