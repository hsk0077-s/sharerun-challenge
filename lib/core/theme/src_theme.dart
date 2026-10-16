import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_radii.dart';
import 'app_shapes.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';
import 'src_tokens.dart';

/// SRC 디자인 시스템 Material Theme.
///
/// 앱 전체가 검정 바탕 + 라임 포인트 한 가지 테마다. [light]와 [dark]는
/// 예전 이름을 쓰는 곳이 깨지지 않게 남겨 둔 별칭이다.
abstract final class SrcTheme {
  static TextTheme get _textTheme => TextTheme(
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

  /// 예전 이름. 지금은 [night]와 같다.
  static ThemeData get light => night;

  /// 별도 다크 테마는 없다.
  static ThemeData get dark => night;

  /// 검정 바탕 + 라임 포인트.
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
      onError: c.onPrimary,
      outline: c.outline,
    );
    final base = _textTheme.apply(
      bodyColor: c.ink,
      displayColor: c.ink,
    );
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
      borderSide: BorderSide(color: c.outline),
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
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: AppRadii.cardShape,
        clipBehavior: Clip.antiAlias,
      ),
      dividerTheme: DividerThemeData(color: c.outline, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        hintStyle: AppTextStyles.inputHint,
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: c.primary, width: 1.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: base.titleLarge?.copyWith(
          color: c.ink,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: base.bodyMedium?.copyWith(color: c.muted),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: c.surface,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.ink,
        contentTextStyle: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          color: c.onPrimary,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? c.onPrimary : c.muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? c.primary
              : c.outline,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? c.primary : null,
        ),
        checkColor: WidgetStatePropertyAll(c.onPrimary),
        side: BorderSide(color: c.muted),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.outline,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          disabledBackgroundColor: AppColors.buttonDisabled,
          disabledForegroundColor: c.muted,
          minimumSize: const Size.fromHeight(AppShapes.buttonHeight),
          shape: AppRadii.pillShape,
          elevation: 0,
          textStyle: AppTextStyles.buttonText,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          disabledBackgroundColor: AppColors.buttonDisabled,
          disabledForegroundColor: c.muted,
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
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.surface,
        selectedItemColor: c.primary,
        unselectedItemColor: c.muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
