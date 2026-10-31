import 'package:flutter/material.dart';

import '../../l10n/remaining_surface.dart';

/// 구글 로그인 버튼. 구글 공식 규격을 그대로 따른다.
/// 흰 배경, 1px 회색 테두리(#747775), 알약 모양, 높이 40, 글자색 #1F1F1F(Roboto 14 Medium),
/// 왼쪽에 20px 공식 4색 G 로고. 글자는 구글이 현지화해서 쓰는 한국어 문구를 쓴다.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.label,
    this.fullWidth = false,
  });

  final VoidCallback onPressed;
  final String? label;

  /// 자리 너비를 꽉 채운다(구글 규격의 최대 너비 400까지). 아니면 내용만큼만 차지한다.
  final bool fullWidth;

  static const defaultLabel = 'Google 계정으로 로그인';
  static const buttonKey = Key('google-signin-button');
  static const logoKey = Key('google-signin-logo');

  static const _border = Color(0xFF747775);
  static const _text = Color(0xFF1F1F1F);

  /// 로그인 화면에서 다른 소셜 버튼과 맞추는 높이. 구글 규격의 최소 높이(40)보다 크다.
  static const double fullWidthHeight = 44;

  @override
  Widget build(BuildContext context) {
    final resolvedLabel = label ??
        RemainingSurface.tr(
          context,
          'widget.google_signin_button.button',
          defaultLabel,
        );
    final button = Semantics(
      button: true,
      label: resolvedLabel,
      excludeSemantics: true,
      child: Material(
        key: buttonKey,
        color: Colors.white,
        shape: const StadiumBorder(side: BorderSide(color: _border)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: fullWidth ? fullWidthHeight : 40,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    key: logoKey,
                    width: 20,
                    height: 20,
                    child: CustomPaint(painter: GoogleGLogoPainter()),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      resolvedLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _text,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (!fullWidth) return Center(child: button);
    // 구글 규격의 최대 너비(400)까지만 넓어진다.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SizedBox(width: double.infinity, child: button),
      ),
    );
  }
}

/// 구글 공식 4색 G 로고. 48×48 판에 그린 공식 경로 값을 그대로 옮겼다.
class GoogleGLogoPainter extends CustomPainter {
  const GoogleGLogoPainter();

  static const paths = <(Color, String)>[
    (
      Color(0xFFEA4335),
      'M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 '
          '14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z',
    ),
    (
      Color(0xFF4285F4),
      'M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 '
          '5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z',
    ),
    (
      Color(0xFFFBBC05),
      'M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19'
          'C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z',
    ),
    (
      Color(0xFF34A853),
      'M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 '
          '2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z',
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 48, size.height / 48);
    for (final (color, data) in paths) {
      canvas.drawPath(
        parseSvgPath(data),
        Paint()
          ..color = color
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 구글 로고에 쓰이는 SVG 경로 명령(M m L l H h V v C c S s Z z)만 읽는 작은 해석기.
Path parseSvgPath(String data) {
  final tokens = RegExp(r'[MmLlHhVvCcSsZz]|-?(?:\d+\.?\d*|\.\d+)')
      .allMatches(data)
      .map((m) => m.group(0)!)
      .toList();
  final path = Path();
  var i = 0;
  var x = 0.0, y = 0.0;
  var startX = 0.0, startY = 0.0;
  var lastC2x = 0.0, lastC2y = 0.0;
  var prevWasCubic = false;
  String? cmd;

  double next() => double.parse(tokens[i++]);
  bool isCmd(String t) => RegExp(r'^[A-Za-z]$').hasMatch(t);

  while (i < tokens.length) {
    if (isCmd(tokens[i])) cmd = tokens[i++];
    final c = cmd ??
        (throw FormatException(
          RemainingSurface.trNow(
            'widget.google_signin_button.body',
            'SVG 경로 명령이 없습니다.',
          ),
        ));
    final rel = c == c.toLowerCase();
    switch (c.toLowerCase()) {
      case 'm':
        final nx = next() + (rel ? x : 0), ny = next() + (rel ? y : 0);
        path.moveTo(nx, ny);
        x = startX = nx;
        y = startY = ny;
        cmd = rel ? 'l' : 'L'; // 이어지는 숫자는 선으로 읽는다.
        prevWasCubic = false;
      case 'l':
        final nx = next() + (rel ? x : 0), ny = next() + (rel ? y : 0);
        path.lineTo(nx, ny);
        x = nx;
        y = ny;
        prevWasCubic = false;
      case 'h':
        final nx = next() + (rel ? x : 0);
        path.lineTo(nx, y);
        x = nx;
        prevWasCubic = false;
      case 'v':
        final ny = next() + (rel ? y : 0);
        path.lineTo(x, ny);
        y = ny;
        prevWasCubic = false;
      case 'c':
        final x1 = next() + (rel ? x : 0), y1 = next() + (rel ? y : 0);
        final x2 = next() + (rel ? x : 0), y2 = next() + (rel ? y : 0);
        final nx = next() + (rel ? x : 0), ny = next() + (rel ? y : 0);
        path.cubicTo(x1, y1, x2, y2, nx, ny);
        lastC2x = x2;
        lastC2y = y2;
        x = nx;
        y = ny;
        prevWasCubic = true;
      case 's':
        final x1 = prevWasCubic ? 2 * x - lastC2x : x;
        final y1 = prevWasCubic ? 2 * y - lastC2y : y;
        final x2 = next() + (rel ? x : 0), y2 = next() + (rel ? y : 0);
        final nx = next() + (rel ? x : 0), ny = next() + (rel ? y : 0);
        path.cubicTo(x1, y1, x2, y2, nx, ny);
        lastC2x = x2;
        lastC2y = y2;
        x = nx;
        y = ny;
        prevWasCubic = true;
      case 'z':
        path.close();
        x = startX;
        y = startY;
        prevWasCubic = false;
        cmd = null; // 닫은 뒤에는 새 명령이 와야 한다.
    }
  }
  return path;
}
