import 'package:flutter/material.dart';

import 'app_shadows.dart';
import 'src_tokens.dart';

/// Shared surface card — token-backed hook for Phase 2b+ screens.
class SrcSurfaceCard extends StatelessWidget {
  const SrcSurfaceCard({
    required this.child,
    super.key,
    this.padding,
    this.margin,
    this.onTap,
    this.borderColor,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final radius = tokens.radii.card;
    final decoration = BoxDecoration(
      color: tokens.colors.surface,
      borderRadius: radius,
      border: Border.all(color: borderColor ?? tokens.colors.outline),
      boxShadow: AppShadows.card,
    );
    final content = Padding(
      padding: padding ?? EdgeInsets.all(tokens.spacing.md),
      child: child,
    );
    final painted = DecoratedBox(
      decoration: decoration,
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: radius,
                child: content,
              ),
            ),
    );
    final clipped = onTap == null
        ? painted
        : ClipRRect(borderRadius: radius, child: painted);
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: SizedBox(
        width: width,
        height: height,
        child: clipped,
      ),
    );
  }
}
