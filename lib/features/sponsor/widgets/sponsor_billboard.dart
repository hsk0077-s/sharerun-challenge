import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../l10n/remaining_surface.dart';
import '../../tournaments/utils/sponsor_display.dart';

/// Neon marquee sponsor billboard for result / challenge screens.
class SponsorBillboard extends ConsumerStatefulWidget {
  const SponsorBillboard({super.key});

  @override
  ConsumerState<SponsorBillboard> createState() => _SponsorBillboardState();
}

class _SponsorBillboardState extends ConsumerState<SponsorBillboard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _marqueeController;

  @override
  void initState() {
    super.initState();
    _marqueeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _marqueeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buff = ref.watch(activeSponsorBuffProvider);
    final headline =
        buff == null ? '쉐어런' : displaySponsorName(buff.sponsorName);
    final message = buff?.message ??
        RemainingSurface.tr(
          context,
          'sponsor.sponsor_billboard.body',
          '검증된 달리기 1km마다 100원이 기부돼요',
        );

    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.electricBlue.withValues(alpha: 0.35),
            AppColors.neonLime.withValues(alpha: 0.22),
            AppColors.electricBlue.withValues(alpha: 0.35),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.neonLime.withValues(alpha: 0.35)),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonLime.withValues(alpha: 0.12),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.only(left: 12, right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.oledBlack.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.neonLime.withValues(alpha: 0.5)),
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(
                color: AppColors.neonLime,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Expanded(
            child: ClipRect(
              child: AnimatedBuilder(
                animation: _marqueeController,
                builder: (context, _) {
                  final tick = _marqueeController.value;
                  return Transform.translate(
                    offset: Offset(-tick * 280, 0),
                    child: Row(
                      children: [
                        _MarqueeChunk(headline: headline, message: message),
                        const SizedBox(width: 48),
                        _MarqueeChunk(headline: headline, message: message),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarqueeChunk extends StatelessWidget {
  const _MarqueeChunk({
    required this.headline,
    required this.message,
  });

  final String headline;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          headline,
          style: const TextStyle(
            color: AppColors.neonLime,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          message,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 12),
        const Icon(Icons.bolt_rounded, color: AppColors.electricBlue, size: 16),
      ],
    );
  }
}
