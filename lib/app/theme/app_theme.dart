import 'package:flutter/material.dart';

import '../../core/theme/src_theme.dart';

/// Legacy theme entry. Always the SRC light token theme.
///
/// `dark` stays an alias — do not invent a Black Neon / dark palette here.
abstract final class AppTheme {
  static ThemeData get light => SrcTheme.light;

  static ThemeData get dark => SrcTheme.light;
}
