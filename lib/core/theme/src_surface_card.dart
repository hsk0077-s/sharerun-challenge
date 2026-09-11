import 'package:flutter/material.dart';

import 'app_shadows.dart';
import 'src_tokens.dart';

/// Shared surface card — token-backed hook for Phase 2b+ screens.
///
/// Home / Walking / Lobby are **not** migrated in this PR.
class SrcSurfaceCard extends StatelessWidget {
  const SrcSurfaceCard({
    required this.child,
    super.key,
    this.padding,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final radius = tokens.radii.card;
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.colors.surface,
          borderRadius: radius,
          border: Border.all(color: tokens.colors.outline),
          boxShadow: AppShadows.card,
        ),
        child: Padding(
          padding: padding ?? EdgeInsets.all(tokens.spacing.md),
          child: child,
        ),
      ),
    );
  }
}
