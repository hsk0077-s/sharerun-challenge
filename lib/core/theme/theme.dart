/// SRC design tokens — single import for later screen restyles (Phase 2b+).
///
/// ## How to use / 사용 방법
///
/// ```dart
/// import 'package:share_run_challenge/core/theme/theme.dart';
///
/// // Color roles + spacing + radii from ThemeExtension:
/// final t = context.srcTokens;
/// Color primary = t.colors.primary;
/// double pad = t.spacing.md;
/// BorderRadius card = t.radii.card;
///
/// // Or named constants (full palette, social brands, gradients):
/// AppColors.primaryMint;
/// AppSpacing.md;
/// AppRadii.md;
/// AppShadows.card;
/// AppTextStyles.headline;
///
/// // Material already wired:
/// Theme.of(context).colorScheme.primary;   // mint
/// Theme.of(context).colorScheme.secondary; // teal accent
/// Theme.of(context).textTheme.titleLarge;
/// ```
///
/// Do **not** import `lib/app/theme/app_colors.dart` in new code — that path
/// is a compatibility shim for Walking / Lobby / My until Phase 2c–2d.
library;

export 'app_colors.dart';
export 'app_radii.dart';
export 'app_shadows.dart';
export 'app_shapes.dart';
export 'app_spacing.dart';
export 'app_text_styles.dart';
export 'src_surface_card.dart';
export 'src_theme.dart';
export 'src_tokens.dart';
