import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primaryMint = Color(0xFF66D2B3);
  static const primaryTeal = Color(0xFF11B79C);
  static const bgWhite = Color(0xFFFFFFFF);
  static const bgGradientStart = Color(0xFFEDF7F2);
  static const bgGradientEnd = Color(0xFFF7FBFA);
  static const surfaceWhite = Color(0xFFFFFFFF);
  static const textBlack = Color(0xFF171717);
  static const textGrey = Color(0xFF6B7280);
  static const textWhite = Color(0xFFFFFFFF);
  static const borderLight = Color(0xFFE4E4E7);
  static const error = Color(0xFFE25555);
  static const paymentButtonBlue = Color(0xFF2F80ED);
  // Keep aliases so old dark refs compile if any remain temporarily:
  static const oledBlack = bgWhite;
  static const surfaceBlack = bgGradientEnd;
  static const cardBlack = surfaceWhite;
  static const neonLime = primaryMint;
  static const electricBlue = primaryTeal;
  static const dangerRed = error;
  static const textPrimary = textBlack;
  static const textSecondary = textGrey;
}
