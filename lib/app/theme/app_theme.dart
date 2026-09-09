import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryMint,
      brightness: Brightness.light,
      surface: AppColors.surfaceWhite,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgWhite,
      colorScheme: colorScheme.copyWith(
        primary: AppColors.primaryMint,
        secondary: AppColors.primaryTeal,
        error: AppColors.error,
        surface: AppColors.surfaceWhite,
      ),
      cardColor: AppColors.surfaceWhite,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgWhite,
        foregroundColor: AppColors.textBlack,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceWhite,
        selectedItemColor: AppColors.primaryTeal,
        unselectedItemColor: AppColors.textGrey,
        type: BottomNavigationBarType.fixed,
      ),
      dividerColor: AppColors.borderLight,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryMint,
          foregroundColor: AppColors.textWhite,
        ),
      ),
      textTheme: Typography.blackMountainView.apply(
        bodyColor: AppColors.textBlack,
        displayColor: AppColors.textBlack,
      ),
    );
  }

  // Kept as an alias so any lingering `AppTheme.dark` references keep
  // compiling and render with the SRC mint light theme instead of the
  // legacy Black Neon shell.
  static ThemeData get dark => light;
}
