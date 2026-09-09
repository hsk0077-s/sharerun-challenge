import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

class SponsorRollingBanner extends StatefulWidget {
  const SponsorRollingBanner({
    required this.messages,
    super.key,
  });

  final List<String> messages;

  @override
  State<SponsorRollingBanner> createState() => _SponsorRollingBannerState();
}

class _SponsorRollingBannerState extends State<SponsorRollingBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) {
      return const SizedBox.shrink();
    }

    final tickerText = widget.messages.join('   ·   ');

    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1F2E), Color(0xFF0F3D2E)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neonLime.withValues(alpha: 0.35)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Row(
        children: [
          Container(
            width: 44,
            alignment: Alignment.center,
            color: AppColors.neonLime.withValues(alpha: 0.12),
            child: const Icon(
              Icons.campaign_rounded,
              color: AppColors.neonLime,
              size: 20,
            ),
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(-_controller.value * 420, 0),
                  child: child,
                );
              },
              child: Row(
                children: [
                  Text(
                    tickerText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 48),
                  Text(
                    tickerText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
