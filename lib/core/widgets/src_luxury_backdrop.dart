import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 다크 실버 캔버스 + 하단에서 투과되는 시안 펄스 광원.
class SrcLuxuryBackdrop extends StatefulWidget {
  const SrcLuxuryBackdrop({required this.child, super.key});

  final Widget child;

  @override
  State<SrcLuxuryBackdrop> createState() => _SrcLuxuryBackdropState();
}

class _SrcLuxuryBackdropState extends State<SrcLuxuryBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_pulse.value);
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: AppColors.luxuryCanvasGradient,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Align(
                alignment: Alignment.bottomCenter,
                child: IgnorePointer(
                  child: Container(
                    height: 280,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.bottomCenter,
                        radius: 1.15 + (t * 0.18),
                        colors: [
                          AppColors.pulseCyan.withValues(alpha: 0.22 + t * 0.14),
                          AppColors.tealAccent.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.42, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}
