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

/// Natural mascot — no token-colored rect / BlendMode tint.
class WalkingMascot extends StatelessWidget {
  const WalkingMascot({
    required this.tier,
    required this.size,
    super.key,
  });

  final UserTier tier;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: 2,
            child: IgnorePointer(
              child: Container(
                width: size * 0.62,
                height: size * 0.14,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 10,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Transform.flip(
            flipX: true,
            child: _untintedMascot(),
          ),
        ],
      ),
    );
  }

  Widget _untintedMascot() {
    final image = Image.asset(
      WalkingLook.mascotAsset(tier),
      key: const Key('walking-mascot'),
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => Icon(
        Icons.pets_rounded,
        size: size * 0.55,
        color: WalkingLook.onHero,
      ),
    );
    if (!tier.isSnail) return image;
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
