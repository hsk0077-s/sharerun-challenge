import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_shapes.dart';
import 'app_text_styles.dart';

/// SRC 디자인 시스템 Material Theme.
abstract final class SrcTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryMint,
      brightness: Brightness.light,
      surface: AppColors.surfaceWhite,
      primary: AppColors.primaryMint,
      onPrimary: AppColors.textWhite,
      secondary: AppColors.primaryMintDark,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgGradientEnd,
      colorScheme: colorScheme,
      fontFamily: 'Pretendard',
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textBlack,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      textTheme: const TextTheme(
        headlineLarge: AppTextStyles.header1,
        titleMedium: AppTextStyles.subtitle1,
        labelLarge: AppTextStyles.buttonText,
        bodySmall: AppTextStyles.caption,
        bodyMedium: AppTextStyles.inputText,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppTextStyles.inputHint,
        border: AppShapes.inputBorder,
        enabledBorder: AppShapes.inputBorder,
        focusedBorder: AppShapes.inputFocusedBorder,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppShapes.buttonHeight),
          shape: AppShapes.buttonShape,
          textStyle: AppTextStyles.buttonText,
        ),
      ),
    );
  }
}
