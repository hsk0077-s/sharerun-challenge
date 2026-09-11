import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radii.dart';
import 'app_spacing.dart';

/// Bundled SRC design tokens attached via [ThemeExtension].
///
/// Access: `context.srcTokens` (see [SrcTokensContext]).
/// 스크린은 매직 넘버 대신 이 확장에서 spacing / radii / color roles를 읽습니다.
@immutable
class SrcTokens extends ThemeExtension<SrcTokens> {
  const SrcTokens({
    required this.colors,
    required this.spacing,
    required this.radii,
  });

  static const light = SrcTokens(
    colors: SrcColorRoles.light,
    spacing: SrcSpacingTokens.standard,
    radii: SrcRadiiTokens.standard,
  );

  final SrcColorRoles colors;
  final SrcSpacingTokens spacing;
  final SrcRadiiTokens radii;

  @override
  SrcTokens copyWith({
    SrcColorRoles? colors,
    SrcSpacingTokens? spacing,
    SrcRadiiTokens? radii,
  }) {
    return SrcTokens(
      colors: colors ?? this.colors,
      spacing: spacing ?? this.spacing,
      radii: radii ?? this.radii,
    );
  }

  @override
  SrcTokens lerp(ThemeExtension<SrcTokens>? other, double t) {
    if (other is! SrcTokens) return this;
    if (t < 0.5) return this;
    return other;
  }
}

/// 1 primary + 1 accent + neutrals, plus donation gold.
@immutable
class SrcColorRoles {
  const SrcColorRoles({
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.onAccent,
    required this.donation,
    required this.canvas,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.outline,
    required this.danger,
    required this.success,
    required this.warning,
  });

  static const light = SrcColorRoles(
    primary: AppColors.primaryMint,
    onPrimary: AppColors.textWhite,
    accent: AppColors.tealAccent,
    onAccent: AppColors.textWhite,
    donation: AppColors.angelGold,
    canvas: AppColors.bgGradientEnd,
    surface: AppColors.surfaceWhite,
    ink: AppColors.textBlack,
    muted: AppColors.textGrey,
    outline: AppColors.borderLight,
    danger: AppColors.error,
    success: AppColors.success,
    warning: AppColors.warning,
  );

  final Color primary;
  final Color onPrimary;
  final Color accent;
  final Color onAccent;
  final Color donation;
  final Color canvas;
  final Color surface;
  final Color ink;
  final Color muted;
  final Color outline;
  final Color danger;
  final Color success;
  final Color warning;
}

@immutable
class SrcSpacingTokens {
  const SrcSpacingTokens({
    required this.xxs,
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
    required this.page,
  });

  static const standard = SrcSpacingTokens(
    xxs: AppSpacing.xxs,
    xs: AppSpacing.xs,
    sm: AppSpacing.sm,
    md: AppSpacing.md,
    lg: AppSpacing.lg,
    xl: AppSpacing.xl,
    xxl: AppSpacing.xxl,
    page: AppSpacing.page,
  );

  final double xxs;
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;
  final double page;
}

@immutable
class SrcRadiiTokens {
  const SrcRadiiTokens({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.pill,
  });

  static const standard = SrcRadiiTokens(
    xs: AppRadii.xs,
    sm: AppRadii.sm,
    md: AppRadii.md,
    lg: AppRadii.lg,
    xl: AppRadii.xl,
    pill: AppRadii.pill,
  );

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double pill;

  BorderRadius get card => BorderRadius.circular(md);
  BorderRadius get panel => BorderRadius.circular(lg);
  BorderRadius get capsule => BorderRadius.circular(pill);
}

/// `Theme.of(context).extension<SrcTokens>()` 단축.
extension SrcTokensContext on BuildContext {
  SrcTokens get srcTokens =>
      Theme.of(this).extension<SrcTokens>() ?? SrcTokens.light;
}
