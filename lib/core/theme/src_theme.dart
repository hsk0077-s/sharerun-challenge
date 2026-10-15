import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_radii.dart';
import 'app_shadows.dart';
import 'app_shapes.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';
import 'src_tokens.dart';

/// SRC 디자인 시스템 Material Theme.
///
/// Light only. [dark] is an alias so lingering `darkTheme:` refs stay mint.
abstract final class SrcTheme {
  static ThemeData get light {
    const tokens = SrcTokens.light;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryMint,
      brightness: Brightness.light,
      surface: AppColors.surfaceWhite,
      primary: AppColors.primaryMint,
      onPrimary: AppColors.textWhite,
      secondary: AppColors.tealAccent,
      onSecondary: AppColors.textWhite,
      tertiary: AppColors.angelGold,
      onTertiary: AppColors.textBlack,
      error: AppColors.error,
      onError: AppColors.textWhite,
      outline: AppColors.borderLight,
    );

    final textTheme = TextTheme(
      displaySmall: AppTextStyles.display,
      headlineLarge: AppTextStyles.header1,
      headlineMedium: AppTextStyles.title,
      headlineSmall: AppTextStyles.header1,
      titleLarge: AppTextStyles.title,
      titleMedium: AppTextStyles.subtitle1,
      titleSmall: AppTextStyles.agreementLabel,
      bodyLarge: AppTextStyles.subtitle1.copyWith(color: AppColors.textBlack),
      bodyMedium: AppTextStyles.inputText,
      bodySmall: AppTextStyles.caption,
      labelLarge: AppTextStyles.buttonText,
      labelMedium: AppTextStyles.caption.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textBlack,
      ),
      labelSmall: AppTextStyles.overline,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppTextStyles.fontFamily,
      scaffoldBackgroundColor: AppColors.bgGradientEnd,
      colorScheme: colorScheme,
      extensions: const <ThemeExtension<dynamic>>[tokens],
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textBlack,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: AppColors.surfaceWhite,
        elevation: AppShadows.cardElevation,
        shadowColor: AppColors.textBlack.withValues(alpha: 0.08),
        margin: EdgeInsets.zero,
        shape: AppRadii.cardShape,
        clipBehavior: Clip.antiAlias,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        hintStyle: AppTextStyles.inputHint,
        border: AppShapes.inputBorder,
        enabledBorder: AppShapes.inputBorder,
        focusedBorder: AppShapes.inputFocusedBorder,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryMint,
          foregroundColor: AppColors.textWhite,
          disabledBackgroundColor: AppColors.buttonDisabled,
          disabledForegroundColor: AppColors.textWhite,
          minimumSize: const Size.fromHeight(AppShapes.buttonHeight),
          shape: AppRadii.pillShape,
          elevation: 0,
          textStyle: AppTextStyles.buttonText,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryMint,
          foregroundColor: AppColors.textWhite,
          disabledBackgroundColor: AppColors.buttonDisabled,
          disabledForegroundColor: AppColors.textWhite,
          textStyle: AppTextStyles.buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryMint,
          side: const BorderSide(color: AppColors.primaryMint),
          textStyle: AppTextStyles.buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.tealAccent,
          textStyle: AppTextStyles.link.copyWith(
            decoration: TextDecoration.none,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceWhite,
        selectedItemColor: AppColors.primaryMint,
        unselectedItemColor: AppColors.textGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  /// No separate dark theme — keeps the mint light shell.
  static ThemeData get dark => light;

  /// 검정 바탕 + 라임 포인트. 새 디자인으로 바뀐 화면만 `Theme(data: SrcTheme.night)`로 감싼다.
  /// 글자 색은 [SrcTokens.night]의 ink/muted로 맞춘다.
  static ThemeData get night {
    const tokens = SrcTokens.night;
    const c = SrcColorRoles.night;
    final scheme = ColorScheme.fromSeed(
      seedColor: c.primary,
      brightness: Brightness.dark,
      surface: c.surface,
      primary: c.primary,
      onPrimary: c.onPrimary,
      secondary: c.accent,
      onSecondary: c.onAccent,
      tertiary: c.donation,
      onTertiary: c.onPrimary,
      error: c.danger,
      outline: c.outline,
    );
    final base = light.textTheme.apply(
      bodyColor: c.ink,
      displayColor: c.ink,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppTextStyles.fontFamily,
      scaffoldBackgroundColor: c.canvas,
      colorScheme: scheme,
      extensions: const <ThemeExtension<dynamic>>[tokens],
      textTheme: base.copyWith(
        bodySmall: base.bodySmall?.copyWith(color: c.muted),
        labelMedium: base.labelMedium?.copyWith(color: c.ink),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: c.ink,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      dividerTheme: DividerThemeData(color: c.outline, thickness: 1, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          textStyle: AppTextStyles.buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.primary,
          side: BorderSide(color: c.primary),
          textStyle: AppTextStyles.buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primary,
          textStyle: AppTextStyles.link.copyWith(
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}
