import 'package:flutter/material.dart';

/// SRC elevation shadows — rest / card / raised / nav.
///
/// Alphas match existing dashboard cards (~6% ink) and glass (cyan 8%).
abstract final class AppShadows {
  static const Color _ink06 = Color(0x0F000000);
  static const Color _glassCyan08 = Color(0x1400F0FF);

  static const List<BoxShadow> rest = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> card = [
    BoxShadow(
      color: _ink06,
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> raised = [
    BoxShadow(
      color: _ink06,
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];

  /// Glass cards — cyan wash already used by [SrcGlassCard].
  static const List<BoxShadow> glass = [
    BoxShadow(
      color: _glassCyan08,
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> nav = [
    BoxShadow(
      color: _ink06,
      blurRadius: 12,
      offset: Offset(0, -2),
    ),
  ];

  /// Material elevation used by [ThemeData.cardTheme] (no drop shadow drawn
  /// twice — cards use [card] BoxShadow instead).
  static const double cardElevation = 0;
}
