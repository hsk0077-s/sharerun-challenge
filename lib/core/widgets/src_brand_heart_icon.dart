import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 로그인 목업과 동일한 SRC 하트·기부함·러너 벡터 아이콘.
class SRCBrandHeartIcon extends StatelessWidget {
  const SRCBrandHeartIcon({
    super.key,
    this.size = 128,
    this.color = AppColors.primaryMint,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SRCBrandHeartIconPainter(color: color),
      ),
    );
  }
}

class _SRCBrandHeartIconPainter extends CustomPainter {
  _SRCBrandHeartIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.055
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    // Heart outline
    final heart = Path()
      ..moveTo(w * 0.50, h * 0.88)
      ..cubicTo(w * 0.18, h * 0.68, w * 0.08, h * 0.42, w * 0.28, h * 0.28)
      ..cubicTo(w * 0.38, h * 0.20, w * 0.46, h * 0.26, w * 0.50, h * 0.36)
      ..cubicTo(w * 0.54, h * 0.26, w * 0.62, h * 0.20, w * 0.72, h * 0.28)
      ..cubicTo(w * 0.92, h * 0.42, w * 0.82, h * 0.68, w * 0.50, h * 0.88);
    canvas.drawPath(heart, paint);

    // Gift box inside heart
    final boxPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045;
    final box = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.42, h * 0.52),
        width: w * 0.22,
        height: w * 0.18,
      ),
      Radius.circular(w * 0.02),
    );
    canvas.drawRRect(box, boxPaint);
    canvas.drawLine(
      Offset(w * 0.42, h * 0.43),
      Offset(w * 0.42, h * 0.61),
      boxPaint,
    );
    canvas.drawLine(
      Offset(w * 0.31, h * 0.48),
      Offset(w * 0.53, h * 0.48),
      boxPaint,
    );
    // Ribbon loops
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w * 0.37, h * 0.40),
        width: w * 0.10,
        height: w * 0.08,
      ),
      3.6,
      2.2,
      false,
      boxPaint,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w * 0.47, h * 0.40),
        width: w * 0.10,
        height: w * 0.08,
      ),
      3.6,
      2.2,
      false,
      boxPaint,
    );

    // Runner silhouette on right of heart
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.68, h * 0.34), w * 0.045, fill);
    final body = Path()
      ..moveTo(w * 0.68, h * 0.40)
      ..lineTo(w * 0.62, h * 0.52)
      ..lineTo(w * 0.70, h * 0.52)
      ..lineTo(w * 0.74, h * 0.64)
      ..lineTo(w * 0.78, h * 0.62)
      ..lineTo(w * 0.72, h * 0.50)
      ..lineTo(w * 0.80, h * 0.48)
      ..lineTo(w * 0.78, h * 0.44)
      ..lineTo(w * 0.70, h * 0.46)
      ..close();
    canvas.drawPath(body, fill);
    canvas.drawLine(
      Offset(w * 0.64, h * 0.52),
      Offset(w * 0.58, h * 0.62),
      Paint()
        ..color = color
        ..strokeWidth = w * 0.04
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(w * 0.70, h * 0.52),
      Offset(w * 0.66, h * 0.66),
      Paint()
        ..color = color
        ..strokeWidth = w * 0.04
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SRCBrandHeartIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
