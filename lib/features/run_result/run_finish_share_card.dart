import 'package:flutter/material.dart';

import '../../core/widgets/src_logo_header.dart';

/// Story poster for one finished run. 1080×1920, safe from story chrome.
///
/// Record, optional donation line, date, and the Share Run mark only.
/// Themes change color, not layout.
enum RunFinishCardTheme {
  dark,
  blue,
  pink,
  yellow,
  mint;

  String get label => switch (this) {
        dark => '다크',
        blue => '블루',
        pink => '핑크',
        yellow => '옐로',
        mint => '민트',
      };

  /// Dot under the preview. Mint is the mint→purple face.
  Color get dot => switch (this) {
        dark => const Color(0xFF163528),
        blue => const Color(0xFF1A56C4),
        pink => const Color(0xFFF2A0C0),
        yellow => const Color(0xFFFFC857),
        mint => const Color(0xFF6B4C9A),
      };
}

/// `10월 3일 토요일`
String runFinishDateLabel(DateTime date) {
  const weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
  return '${date.month}월 ${date.day}일 ${weekdays[date.weekday - 1]}';
}

/// Warm line. Null when this run has no confirmed won amount.
String? runFinishDonationLine(int? won) {
  if (won == null || won <= 0) return null;
  return '이 달리기로 ${_grouped(won)}원 기부에 함께했어요';
}

String _grouped(int value) {
  final digits = value.toString();
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i;
    if (i > 0 && remaining % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}

class RunFinishShareCard extends StatelessWidget {
  const RunFinishShareCard({
    required this.style,
    required this.distanceKm,
    required this.time,
    required this.pace,
    required this.date,
    this.donationWon,
    this.route,
    super.key,
  });

  static const canvasWidth = 1080.0;
  static const canvasHeight = 1920.0;

  /// Instagram story chrome sits in roughly the top and bottom 250px.
  static const storySafeInset = 270.0;

  static const distanceKey = Key('run-finish-distance');
  static const timeKey = Key('run-finish-time');
  static const paceKey = Key('run-finish-pace');
  static const dateKey = Key('run-finish-date');
  static const donationKey = Key('run-finish-donation');
  static const logoKey = Key('run-finish-logo');
  static const appNameKey = Key('run-finish-app-name');

  static const appName = '쉐어 런';
  static const fontFamily = 'ShareRunCard';

  final RunFinishCardTheme style;
  final String distanceKm;
  final String time;
  final String pace;
  final DateTime date;
  final int? donationWon;

  /// Normalized 0–1 points. Omitted when the finish screen has no route.
  final List<Offset>? route;

  String get _paceNumber {
    final trimmed = pace.trim();
    final split = trimmed.indexOf(' ');
    if (split <= 0) return trimmed;
    return trimmed.substring(0, split);
  }

  @override
  Widget build(BuildContext context) {
    final palette = _CardPalette.of(style);
    final donation = runFinishDonationLine(donationWon);
    final media = MediaQuery.maybeOf(context) ?? const MediaQueryData();

    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.noScaling),
      child: SizedBox(
        width: canvasWidth,
        height: canvasHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: palette.background,
              stops: const [0.0, 0.46, 1.0],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.22),
                    radius: 0.85,
                    colors: [
                      palette.glow.withValues(alpha: palette.glowAlpha),
                      palette.glow.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
              if (route != null && route!.length >= 2)
                CustomPaint(
                  painter: _RouteGlowPainter(
                    points: route!,
                    color: palette.route,
                  ),
                ),
              if (route != null && route!.length >= 2)
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        palette.background.last.withValues(alpha: 0.05),
                        palette.background.last.withValues(alpha: 0.28),
                        palette.background.last.withValues(alpha: 0.62),
                      ],
                      stops: const [0.0, 0.42, 0.72],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(92, storySafeInset, 92, storySafeInset),
                child: _RecordColumn(
                  palette: palette,
                  align: CrossAxisAlignment.start,
                  textAlign: TextAlign.left,
                  dateLabel: runFinishDateLabel(date),
                  distanceKm: distanceKm,
                  time: time,
                  paceNumber: _paceNumber,
                  donation: donation,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordColumn extends StatelessWidget {
  const _RecordColumn({
    required this.palette,
    required this.align,
    required this.textAlign,
    required this.dateLabel,
    required this.distanceKm,
    required this.time,
    required this.paceNumber,
    required this.donation,
  });

  final _CardPalette palette;
  final CrossAxisAlignment align;
  final TextAlign textAlign;
  final String dateLabel;
  final String distanceKm;
  final String time;
  final String paceNumber;
  final String? donation;

  @override
  Widget build(BuildContext context) {
    final record = Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: align,
      children: [
        Text(
          dateLabel,
          key: RunFinishShareCard.dateKey,
          textAlign: textAlign,
          style: TextStyle(
            fontFamily: RunFinishShareCard.fontFamily,
            fontSize: 32,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.6,
            color: palette.muted,
            height: 1.2,
          ),
        ),
        const Spacer(),
        _HeroDistance(
          distanceKm: distanceKm,
          palette: palette,
          centered: align == CrossAxisAlignment.center,
        ),
        const SizedBox(height: 64),
        _StatRow(
          palette: palette,
          time: time,
          paceNumber: paceNumber,
          centered: align == CrossAxisAlignment.center,
        ),
        if (donation != null) ...[
          const SizedBox(height: 48),
          Text(
            donation!,
            key: RunFinishShareCard.donationKey,
            textAlign: textAlign,
            style: TextStyle(
              fontFamily: RunFinishShareCard.fontFamily,
              fontSize: 34,
              fontWeight: FontWeight.w400,
              height: 1.45,
              color: palette.donation,
            ),
          ),
        ],
        const Spacer(),
        Container(height: 1, color: palette.hairline),
        const SizedBox(height: 28),
        _BrandLockup(palette: palette),
      ],
    );
    return record;
  }
}

class _HeroDistance extends StatelessWidget {
  const _HeroDistance({
    required this.distanceKm,
    required this.palette,
    required this.centered,
  });

  final String distanceKm;
  final _CardPalette palette;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: centered ? MainAxisAlignment.center : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          distanceKm,
          key: RunFinishShareCard.distanceKey,
          style: TextStyle(
            fontFamily: RunFinishShareCard.fontFamily,
            fontSize: 176,
            fontWeight: FontWeight.w900,
            height: 0.88,
            letterSpacing: -4,
            color: palette.hero,
          ),
        ),
        const SizedBox(width: 14),
        Text(
          'km',
          style: TextStyle(
            fontFamily: RunFinishShareCard.fontFamily,
            fontSize: 36,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: palette.unit,
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.palette,
    required this.time,
    required this.paceNumber,
    required this.centered,
  });

  final _CardPalette palette;
  final String time;
  final String paceNumber;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final align = centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    return Row(
      children: [
        Expanded(
          child: _Stat(
            label: '시간',
            value: time,
            valueKey: RunFinishShareCard.timeKey,
            palette: palette,
            align: align,
          ),
        ),
        Container(
          width: 1,
          height: 84,
          color: palette.hairline,
        ),
        Expanded(
          child: _Stat(
            label: '페이스',
            value: paceNumber,
            valueKey: RunFinishShareCard.paceKey,
            palette: palette,
            align: align,
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.valueKey,
    required this.palette,
    required this.align,
  });

  final String label;
  final String value;
  final Key valueKey;
  final _CardPalette palette;
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: RunFinishShareCard.fontFamily,
              fontSize: 24,
              fontWeight: FontWeight.w400,
              letterSpacing: 2.4,
              color: palette.muted,
              height: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            key: valueKey,
            style: TextStyle(
              fontFamily: RunFinishShareCard.fontFamily,
              fontSize: 64,
              fontWeight: FontWeight.w600,
              letterSpacing: -1.2,
              color: palette.stat,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({required this.palette});

  final _CardPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          key: RunFinishShareCard.logoKey,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.hairline),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Image.asset(
              SRCLogoHeader.assetPath,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) => const SizedBox(
                width: 64,
                height: 64,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          RunFinishShareCard.appName,
          key: RunFinishShareCard.appNameKey,
          style: TextStyle(
            fontFamily: RunFinishShareCard.fontFamily,
            fontSize: 32,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            color: palette.hero,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _CardPalette {
  const _CardPalette({
    required this.background,
    required this.glow,
    required this.glowAlpha,
    required this.hero,
    required this.unit,
    required this.muted,
    required this.stat,
    required this.donation,
    required this.route,
    required this.hairline,
  });

  final List<Color> background;
  final Color glow;
  final double glowAlpha;
  final Color hero;
  final Color unit;
  final Color muted;
  final Color stat;
  final Color donation;
  final Color route;
  final Color hairline;

  static _CardPalette of(RunFinishCardTheme style) {
    return switch (style) {
      RunFinishCardTheme.dark => const _CardPalette(
          background: [Color(0xFF07110E), Color(0xFF10261E), Color(0xFF163528)],
          glow: Color(0xFF76C8A7),
          glowAlpha: 0.36,
          hero: Color(0xFFF7FFF9),
          unit: Color(0xFF9BE7C8),
          muted: Color(0xB8F7FFF9),
          stat: Color(0xFFFFFFFF),
          donation: Color(0xFFF6D7A8),
          route: Color(0xFFD9FFF2),
          hairline: Color(0x33FFFFFF),
        ),
      RunFinishCardTheme.blue => const _CardPalette(
          background: [Color(0xFF07152E), Color(0xFF12336F), Color(0xFF1A56C4)],
          glow: Color(0xFF8EB6FF),
          glowAlpha: 0.42,
          hero: Color(0xFFF5F8FF),
          unit: Color(0xFFC5D9FF),
          muted: Color(0xB8F5F8FF),
          stat: Color(0xFFFFFFFF),
          donation: Color(0xFFFFE3B0),
          route: Color(0xFFE4EEFF),
          hairline: Color(0x38FFFFFF),
        ),
      RunFinishCardTheme.pink => const _CardPalette(
          background: [Color(0xFFFFF7FA), Color(0xFFFFD9E6), Color(0xFFFFB7D0)],
          glow: Color(0xFFFF8FB3),
          glowAlpha: 0.5,
          hero: Color(0xFF2C1220),
          unit: Color(0xFFA61E56),
          muted: Color(0x9E2C1220),
          stat: Color(0xFF2C1220),
          donation: Color(0xFF7A3A16),
          route: Color(0xFFA61E56),
          hairline: Color(0x292C1220),
        ),
      RunFinishCardTheme.yellow => const _CardPalette(
          background: [Color(0xFFFFF9EE), Color(0xFFFFE7A8), Color(0xFFFFC857)],
          glow: Color(0xFFFFE08A),
          glowAlpha: 0.55,
          hero: Color(0xFF2A1C08),
          unit: Color(0xFF6B3A00),
          muted: Color(0xA32A1C08),
          stat: Color(0xFF2A1C08),
          donation: Color(0xFF6E3410),
          route: Color(0xFF6B3A00),
          hairline: Color(0x292A1C08),
        ),
      RunFinishCardTheme.mint => const _CardPalette(
          background: [Color(0xFF102820), Color(0xFF1E6A58), Color(0xFF4C2F86)],
          glow: Color(0xFFC9B6FF),
          glowAlpha: 0.34,
          hero: Color(0xFFF7FFF9),
          unit: Color(0xFFD4C6FF),
          muted: Color(0xBDF7FFF9),
          stat: Color(0xFFFFFFFF),
          donation: Color(0xFFF6D7A8),
          route: Color(0xFFE6DEFF),
          hairline: Color(0x38FFFFFF),
        ),
    };
  }
}

class _RouteGlowPainter extends CustomPainter {
  const _RouteGlowPainter({required this.points, required this.color});

  final List<Offset> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final path = _smooth(points, size);
    const passes = <(double, double, double)>[
      (64, 0.16, 22),
      (28, 0.32, 10),
      (9, 0.95, 0.6),
    ];
    for (final pass in passes) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: pass.$2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = pass.$1
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, pass.$3),
      );
    }
    final start = Offset(points.first.dx * size.width, points.first.dy * size.height);
    final end = Offset(points.last.dx * size.width, points.last.dy * size.height);
    canvas.drawCircle(start, 12, Paint()..color = color);
    canvas.drawCircle(
      end,
      16,
      Paint()
        ..color = color.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(end, 8, Paint()..color = color);
  }

  Path _smooth(List<Offset> raw, Size size) {
    final mapped = [
      for (final point in raw)
        Offset(point.dx.clamp(0.0, 1.0) * size.width, point.dy.clamp(0.0, 1.0) * size.height),
    ];
    final path = Path()..moveTo(mapped.first.dx, mapped.first.dy);
    for (var i = 1; i < mapped.length; i++) {
      final previous = mapped[i - 1];
      final current = mapped[i];
      final mid = Offset(
        (previous.dx + current.dx) / 2,
        (previous.dy + current.dy) / 2,
      );
      path.quadraticBezierTo(previous.dx, previous.dy, mid.dx, mid.dy);
    }
    path.lineTo(mapped.last.dx, mapped.last.dy);
    return path;
  }

  @override
  bool shouldRepaint(covariant _RouteGlowPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.points != points;
  }
}

/// One poster. Swipe or tap a color dot to change the background only.
class RunFinishSharePreview extends StatelessWidget {
  const RunFinishSharePreview({
    required this.controller,
    required this.styleIndex,
    required this.cardFor,
    required this.onStyleChanged,
    super.key,
  });

  static const pagerKey = Key('run-finish-share-pager');

  final PageController controller;
  final int styleIndex;
  final RunFinishShareCard Function(RunFinishCardTheme style) cardFor;
  final ValueChanged<int> onStyleChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pageWidth = constraints.maxWidth * controller.viewportFraction - 16;
        final height = pageWidth * 16 / 9;
        return Column(
          children: [
            SizedBox(
              height: height,
              child: PageView.builder(
                key: pagerKey,
                controller: controller,
                itemCount: RunFinishCardTheme.values.length,
                onPageChanged: onStyleChanged,
                itemBuilder: (context, index) {
                  final style = RunFinishCardTheme.values[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x24000000),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: cardFor(style),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < RunFinishCardTheme.values.length; i++)
                  _ThemeDot(
                    theme: RunFinishCardTheme.values[i],
                    selected: i == styleIndex,
                    onTap: () => onStyleChanged(i),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              RunFinishCardTheme.values[styleIndex].label,
              key: Key('run-finish-style-$styleIndex'),
              style: const TextStyle(
                fontFamily: RunFinishShareCard.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: Color(0xFF757575),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ThemeDot extends StatelessWidget {
  const _ThemeDot({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  final RunFinishCardTheme theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: theme.label,
      child: GestureDetector(
        key: Key('run-finish-theme-${theme.name}'),
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: selected ? 30 : 24,
            height: selected ? 30 : 24,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? const Color(0xFF1A1D22) : const Color(0x00000000),
                width: 2,
              ),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme == RunFinishCardTheme.mint ? null : theme.dot,
                gradient: theme == RunFinishCardTheme.mint
                    ? const LinearGradient(
                        colors: [Color(0xFF1E6A58), Color(0xFF6B4C9A)],
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
