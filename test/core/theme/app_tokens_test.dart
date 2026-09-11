import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/theme/app_theme.dart';
import 'package:share_run_challenge/core/theme/theme.dart';

void main() {
  test('color roles stay a single mint primary and teal accent', () {
    expect(AppColors.primary, AppColors.primaryMint);
    expect(AppColors.accent, AppColors.tealAccent);
    expect(AppColors.neonLime, AppColors.primaryMint);
    expect(AppColors.electricBlue, AppColors.tealAccent);
    expect(AppColors.cardBlack, AppColors.surfaceWhite);
    expect(AppColors.dangerRed, AppColors.error);
    expect(AppColors.primaryTeal, AppColors.tealAccent);
    expect(SrcTokens.light.colors.primary, AppColors.primaryMint);
    expect(SrcTokens.light.colors.accent, AppColors.tealAccent);
    expect(SrcTokens.light.colors.donation, AppColors.angelGold);
  });

  test('spacing is a 4pt grid and radii stay ordered', () {
    const spaces = <double>[
      AppSpacing.xxs,
      AppSpacing.xs,
      AppSpacing.sm,
      AppSpacing.md,
      AppSpacing.lg,
      AppSpacing.xl,
      AppSpacing.xxl,
      AppSpacing.xxxl,
    ];
    for (final space in spaces) {
      expect(space % 4, 0);
    }
    expect(AppSpacing.page, AppSpacing.lg);
    expect(AppShapes.cardRadius, AppRadii.md);
    expect(AppShapes.buttonRadius, AppRadii.pill);
    expect(AppShapes.inputRadius, AppRadii.sm);
    expect(AppRadii.xs, lessThan(AppRadii.sm));
    expect(AppRadii.sm, lessThan(AppRadii.md));
    expect(AppRadii.md, lessThan(AppRadii.lg));
    expect(AppRadii.lg, lessThan(AppRadii.xl));
    expect(AppRadii.xl, lessThan(AppRadii.pill));
  });

  test('shadow lists are non-empty and card elevation stays flat', () {
    expect(AppShadows.rest, isNotEmpty);
    expect(AppShadows.card, isNotEmpty);
    expect(AppShadows.raised, isNotEmpty);
    expect(AppShadows.glass, isNotEmpty);
    expect(AppShadows.nav, isNotEmpty);
    expect(AppShadows.cardElevation, 0);
  });

  test('SrcTheme.light wires ColorScheme and ThemeExtension', () {
    final theme = SrcTheme.light;
    expect(theme.brightness, Brightness.light);
    expect(theme.colorScheme.primary, AppColors.primaryMint);
    expect(theme.colorScheme.secondary, AppColors.tealAccent);
    expect(theme.colorScheme.tertiary, AppColors.angelGold);
    expect(theme.colorScheme.error, AppColors.error);
    expect(theme.extension<SrcTokens>(), SrcTokens.light);
    expect(AppTheme.dark.brightness, Brightness.light);
    expect(AppTheme.dark.extension<SrcTokens>(), SrcTokens.light);
    expect(
      theme.textTheme.headlineLarge?.fontSize,
      AppTextStyles.header1.fontSize,
    );
    expect(
      theme.textTheme.headlineLarge?.fontWeight,
      AppTextStyles.header1.fontWeight,
    );
    expect(
      theme.textTheme.labelLarge?.fontSize,
      AppTextStyles.buttonText.fontSize,
    );
  });

  test('ThemeExtension lerp returns a SrcTokens instance', () {
    final lerped = SrcTokens.light.lerp(SrcTokens.light, 0.4);
    expect(lerped, isA<SrcTokens>());
    expect(lerped.colors.primary, AppColors.primaryMint);
  });
}
