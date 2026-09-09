import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Google "G" 브랜드 아이콘 (벡터 근사).
class GoogleIcon extends StatelessWidget {
  const GoogleIcon({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleIconPainter()),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.22;

    void drawArc(Color color, double start, double sweep) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    drawArc(const Color(0xFF4285F4), -0.4, 3.5);
    drawArc(const Color(0xFF34A853), 2.0, 1.8);
    drawArc(const Color(0xFFFBBC05), 3.5, 1.5);
    drawArc(const Color(0xFFEA4335), 5.0, 1.8);

    canvas.drawRect(
      Rect.fromLTWH(
        center.dx - 1,
        center.dy - radius * 0.15,
        radius * 0.65,
        radius * 0.3,
      ),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Naver "N" 브랜드 아이콘.
class NaverIcon extends StatelessWidget {
  const NaverIcon({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(
          'N',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: size * 0.85,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// Kakao 말풍선 브랜드 아이콘.
class KakaoIcon extends StatelessWidget {
  const KakaoIcon({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _KakaoIconPainter()),
    );
  }
}

class _KakaoIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.textBlack;
    final w = size.width;
    final h = size.height;

    final bubble = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h * 0.82),
      Radius.circular(h * 0.35),
    );
    canvas.drawRRect(bubble, paint);

    final tail = Path()
      ..moveTo(w * 0.22, h * 0.78)
      ..lineTo(w * 0.12, h)
      ..lineTo(w * 0.38, h * 0.78)
      ..close();
    canvas.drawPath(tail, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
