import 'package:flutter/material.dart';

import '../../core/widgets/src_logo_header.dart';
import 'run_card_summary.dart';

/// Story poster for one finished run. 1080×1920, safe from story chrome.
///
/// Record, optional donation line, date, and the Share Run mark only.
/// Themes change color, not layout.
enum RunFinishCardTheme {
  dark,
  blue,
  pink,
  yellow,
  mint,
  photo;

  /// Color faces only. A photo is optional and is never the opening theme.
  static const colorThemes = <RunFinishCardTheme>[
    dark,
    blue,
    pink,
    yellow,
    mint
  ];

  String get label => switch (this) {
        dark => '다크',
        blue => '블루',
        pink => '핑크',
        yellow => '옐로',
        mint => '민트',
        photo => '내 사진',
      };

  /// Dot under the preview. Mint is the mint→purple face.
  Color get dot => switch (this) {
        dark => const Color(0xFF163528),
        blue => const Color(0xFF1A56C4),
        pink => const Color(0xFFF2A0C0),
        yellow => const Color(0xFFFFC857),
        mint => const Color(0xFF6B4C9A),
        photo => const Color(0xFF3E7A45),
      };
}

/// `10월 3일 토요일`
String runFinishDateLabel(DateTime date) {
  const weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
  return '${date.month}월 ${date.day}일 ${weekdays[date.weekday - 1]}';
}

/// Company donation the server recorded. Null when nothing was counted.
String? runFinishDonationLine(int? won) {
  if (won == null || won <= 0) return null;
  return '이번 달리기로 회사가 ${_grouped(won)}원을 기부해요';
}

/// Shown when this month's company donation limit is used up.
const runFinishDonationCapLine = '이번 달 기부 목표 달성!';

/// Server did not count a donation. [reason] is the server's explanation.
String runFinishDonationSkippedLine(String reason) {
  final detail = reason.trim();
  if (detail == 'cap_reached') return runFinishDonationCapLine;
  const lead = '이번 달리기는 기부에 포함되지 않았어요.';
  if (detail.isEmpty) return lead;
  return '$lead $detail';
}

/// Share text. Donation wording is included only for a server-counted amount.
String runFinishShareText({
  required String distanceKm,
  required String time,
  int? donationWon,
}) {
  final record = 'SRC 앱에서 ${distanceKm}km를 달렸어요. ⏱ 기록: $time';
  final donation = runFinishDonationLine(donationWon);
  if (donation == null) return record;
  return '$donation. $record';
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
    this.splitPaces,
    this.averageHeartRate,
    this.route,
    this.photo,
    this.frameColor,
    super.key,
  });

  static const canvasWidth = 1080.0;
  static const canvasHeight = 1920.0;

  /// Instagram story chrome sits in roughly the top and bottom 250px.
  static const storySafeInset = 280.0;

  static const distanceKey = Key('run-finish-distance');
  static const timeKey = Key('run-finish-time');
  static const paceKey = Key('run-finish-pace');
  static const dateKey = Key('run-finish-date');
  static const donationKey = Key('run-finish-donation');
  static const logoKey = Key('run-finish-logo');
  static const appNameKey = Key('run-finish-app-name');
  static const headlineKey = Key('run-finish-headline');
  static const photoKey = Key('run-finish-photo');
  static const heartRateKey = Key('run-finish-heart-rate');
  static const splitGraphKey = Key('run-finish-split-graph');

  static const appName = '쉐어 런';
  static const headline = '오늘의 러닝';
  static const fontFamily = 'ShareRunCard';

  final RunFinishCardTheme style;
  final String distanceKm;
  final String time;
  final String pace;
  final DateTime date;
  final int? donationWon;

  /// 1km 구간 페이스(초/km). 2개 미만이면 그래프를 그리지 않는다.
  final List<int>? splitPaces;

  /// 평균 심박. 없으면 줄을 그리지 않는다.
  final int? averageHeartRate;

  /// Normalized 0–1 points. Omitted when the finish screen has no route.
  final List<Offset>? route;

  /// Scenery for [RunFinishCardTheme.photo]. Session-only; never uploaded.
  final ImageProvider? photo;

  /// Owned share-card frame. Null keeps the card unchanged.
  final Color? frameColor;

  _PaceParts get _paceParts {
    var trimmed = pace.trim();
    final slash = trimmed.indexOf('/');
    var unit = '';
    if (slash > 0) {
      unit = trimmed.substring(slash).trim();
      trimmed = trimmed.substring(0, slash).trim();
    }
    final split = trimmed.indexOf(' ');
    if (split > 0) trimmed = trimmed.substring(0, split);
    return _PaceParts(trimmed, unit);
  }

  bool get _hasRoute => route != null && route!.length >= 2;

  @override
  Widget build(BuildContext context) {
    final palette = _CardPalette.of(style);
    final donation = runFinishDonationLine(donationWon);
    final media = MediaQuery.maybeOf(context) ?? const MediaQueryData();
    final paceParts = _paceParts;
    final hasPhoto = style == RunFinishCardTheme.photo && photo != null;

    return DefaultTextStyle(
      style: const TextStyle(
        decoration: TextDecoration.none,
        fontFamily: RunFinishShareCard.fontFamily,
      ),
      child: MediaQuery(
        data: media.copyWith(textScaler: TextScaler.noScaling),
        child: SizedBox(
          width: canvasWidth,
          height: canvasHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF07110E),
              gradient: hasPhoto
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: palette.background,
                      stops: const [0.0, 0.48, 1.0],
                    ),
              image: hasPhoto
                  ? DecorationImage(image: photo!, fit: BoxFit.cover)
                  : null,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasPhoto)
                  const _PhotoScrim(key: RunFinishShareCard.photoKey),
                if (!hasPhoto)
                  CustomPaint(painter: _AtmospherePainter(palette)),
                if (!hasPhoto && !_hasRoute)
                  CustomPaint(painter: _TrackFieldPainter(palette.decor)),
                if (_hasRoute)
                  CustomPaint(
                    painter:
                        _RouteGlowPainter(points: route!, color: palette.route),
                  ),
                if (_hasRoute)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          palette.background.first.withValues(alpha: 0.05),
                          palette.background.last.withValues(alpha: 0.22),
                          palette.background.last.withValues(alpha: 0.55),
                        ],
                        stops: const [0.0, 0.45, 0.78],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      76, storySafeInset, 76, storySafeInset),
                  child: _RecordColumn(
                    palette: palette,
                    dateLabel: runFinishDateLabel(date),
                    distanceKm: distanceKm,
                    time: time,
                    paceNumber: paceParts.value,
                    paceUnit: paceParts.unit,
                    donation: donation,
                    splitPaces: splitPaces,
                    averageHeartRate: averageHeartRate,
                  ),
                ),
                if (frameColor != null)
                  IgnorePointer(
                    child: DecoratedBox(
                      key: const Key('run-finish-cosmetic-frame'),
                      decoration: BoxDecoration(
                        border: Border.all(color: frameColor!, width: 36),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaceParts {
  const _PaceParts(this.value, this.unit);
  final String value;
  final String unit;
}

class _RecordColumn extends StatelessWidget {
  const _RecordColumn({
    required this.palette,
    required this.dateLabel,
    required this.distanceKm,
    required this.time,
    required this.paceNumber,
    required this.paceUnit,
    required this.donation,
    required this.splitPaces,
    required this.averageHeartRate,
  });

  final _CardPalette palette;
  final String dateLabel;
  final String distanceKm;
  final String time;
  final String paceNumber;
  final String paceUnit;
  final String? donation;
  final List<int>? splitPaces;
  final int? averageHeartRate;

  @override
  Widget build(BuildContext context) {
    final splits = splitPaces == null ? null : bucketSplitPaces(splitPaces!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          RunFinishShareCard.headline,
          key: RunFinishShareCard.headlineKey,
          style: TextStyle(
            fontFamily: RunFinishShareCard.fontFamily,
            fontSize: 96,
            fontWeight: FontWeight.w900,
            height: 1.32,
            letterSpacing: -2.4,
            color: palette.hero,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Container(
              width: 42,
              height: 6,
              decoration: BoxDecoration(
                color: palette.unit,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              dateLabel,
              key: RunFinishShareCard.dateKey,
              style: TextStyle(
                fontFamily: RunFinishShareCard.fontFamily,
                fontSize: 32,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: palette.muted,
                height: 1.35,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          '거리',
          style: TextStyle(
            fontFamily: RunFinishShareCard.fontFamily,
            fontSize: 26,
            fontWeight: FontWeight.w600,
            letterSpacing: 8,
            color: palette.unit,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 8),
        _HeroDistance(distanceKm: distanceKm, palette: palette),
        const SizedBox(height: 28),
        _StatRow(
          palette: palette,
          time: time,
          paceNumber: paceNumber,
          paceUnit: paceUnit,
        ),
        if (averageHeartRate != null) ...[
          const SizedBox(height: 18),
          Text(
            '평균 심박 $averageHeartRate bpm',
            key: RunFinishShareCard.heartRateKey,
            style: TextStyle(
              fontFamily: RunFinishShareCard.fontFamily,
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: palette.muted,
              height: 1.35,
            ),
          ),
        ],
        if (splits != null && splits.length >= 2) ...[
          const SizedBox(height: 28),
          _SplitGraph(palette: palette, paces: splits),
        ],
        if (donation != null) ...[
          const SizedBox(height: 28),
          _DonationBadge(palette: palette, donation: donation!),
        ],
        const Spacer(),
        _BrandLockup(palette: palette),
      ],
    );
  }
}

/// 구간 페이스 막대. 빠를수록 길고, 반투명이라 사진 위에서도 글자를 가리지 않는다.
class _SplitGraph extends StatelessWidget {
  const _SplitGraph({required this.palette, required this.paces});

  final _CardPalette palette;
  final List<int> paces;

  double _height(int pace, int fastest, int slowest) {
    if (slowest == fastest) return 1.0;
    return 0.35 + 0.65 * (slowest - pace) / (slowest - fastest);
  }

  @override
  Widget build(BuildContext context) {
    final fastest = paces.reduce((a, b) => a < b ? a : b);
    final slowest = paces.reduce((a, b) => a > b ? a : b);
    return DecoratedBox(
      key: RunFinishShareCard.splitGraphKey,
      decoration: BoxDecoration(
        color: palette.chip,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: palette.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 22, 26, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '구간 페이스',
              style: TextStyle(
                fontFamily: RunFinishShareCard.fontFamily,
                fontSize: 26,
                fontWeight: FontWeight.w600,
                letterSpacing: 4,
                color: palette.unit,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final pace in paces)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FractionallySizedBox(
                          heightFactor: _height(pace, fastest, slowest),
                          alignment: Alignment.bottomCenter,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: palette.hero.withValues(alpha: 0.42),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroDistance extends StatelessWidget {
  const _HeroDistance({required this.distanceKm, required this.palette});

  final String distanceKm;
  final _CardPalette palette;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            distanceKm,
            key: RunFinishShareCard.distanceKey,
            style: TextStyle(
              fontFamily: RunFinishShareCard.fontFamily,
              fontSize: 248,
              fontWeight: FontWeight.w900,
              letterSpacing: -8,
              color: palette.hero,
            ),
          ),
          const SizedBox(width: 14),
          Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: Text(
              'km',
              style: TextStyle(
                fontFamily: RunFinishShareCard.fontFamily,
                fontSize: 72,
                fontWeight: FontWeight.w700,
                color: palette.unit,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.palette,
    required this.time,
    required this.paceNumber,
    required this.paceUnit,
  });

  final _CardPalette palette;
  final String time;
  final String paceNumber;
  final String paceUnit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            palette: palette,
            kind: _LineIconKind.time,
            label: '시간',
            value: time,
            valueKey: RunFinishShareCard.timeKey,
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: _StatChip(
            palette: palette,
            kind: _LineIconKind.pace,
            label: '페이스',
            value: paceNumber,
            unit: paceUnit,
            valueKey: RunFinishShareCard.paceKey,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.palette,
    required this.kind,
    required this.label,
    required this.value,
    required this.valueKey,
    this.unit = '',
  });

  final _CardPalette palette;
  final _LineIconKind kind;
  final String label;
  final String value;
  final String unit;
  final Key valueKey;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.chip,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: palette.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 18, 22),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: palette.iconPlate,
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 64,
                height: 64,
                child:
                    CustomPaint(painter: _LineIconPainter(kind, palette.icon)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: RunFinishShareCard.fontFamily,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.6,
                      color: palette.muted,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          value,
                          key: valueKey,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: RunFinishShareCard.fontFamily,
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.2,
                            color: palette.stat,
                            height: 1.35,
                          ),
                        ),
                      ),
                      if (unit.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(
                          unit,
                          style: TextStyle(
                            fontFamily: RunFinishShareCard.fontFamily,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: palette.muted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonationBadge extends StatelessWidget {
  const _DonationBadge({required this.palette, required this.donation});

  final _CardPalette palette;
  final String donation;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.badge,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: palette.badgeInk.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 56,
                height: 56,
                child: CustomPaint(
                  painter:
                      _LineIconPainter(_LineIconKind.heart, palette.badgeInk),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                donation,
                key: RunFinishShareCard.donationKey,
                style: TextStyle(
                  fontFamily: RunFinishShareCard.fontFamily,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                  color: palette.badgeInk,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({required this.palette});

  final _CardPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: palette.hairline),
        const SizedBox(height: 26),
        Row(
          children: [
            DecoratedBox(
              key: RunFinishShareCard.logoKey,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: palette.unit.withValues(alpha: 0.85), width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  SRCLogoHeader.assetPath,
                  width: 76,
                  height: 76,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                    width: 76,
                    height: 76,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 18),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  RunFinishShareCard.appName,
                  key: RunFinishShareCard.appNameKey,
                  style: TextStyle(
                    fontFamily: RunFinishShareCard.fontFamily,
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                    color: palette.hero,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'SHARE RUN',
                  style: TextStyle(
                    fontFamily: RunFinishShareCard.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3.4,
                    color: palette.unit,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ],
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
    required this.route,
    required this.hairline,
    required this.decor,
    required this.chip,
    required this.icon,
    required this.iconPlate,
    required this.badge,
    required this.badgeInk,
  });

  final List<Color> background;
  final Color glow;
  final double glowAlpha;
  final Color hero;
  final Color unit;
  final Color muted;
  final Color stat;
  final Color route;
  final Color hairline;
  final Color decor;
  final Color chip;
  final Color icon;
  final Color iconPlate;
  final Color badge;
  final Color badgeInk;

  static _CardPalette of(RunFinishCardTheme style) {
    return switch (style) {
      RunFinishCardTheme.photo || RunFinishCardTheme.dark => const _CardPalette(
          background: [Color(0xFF07110E), Color(0xFF123028), Color(0xFF0C241C)],
          glow: Color(0xFF76C8A7),
          glowAlpha: 0.42,
          hero: Color(0xFFF7FFF9),
          unit: Color(0xFF9BE7C8),
          muted: Color(0xC7F7FFF9),
          stat: Color(0xFFFFFFFF),
          route: Color(0xFFD9FFF2),
          hairline: Color(0x38FFFFFF),
          decor: Color(0xFF9BE7C8),
          chip: Color(0xFF17362C),
          icon: Color(0xFF9BE7C8),
          iconPlate: Color(0xFF214C3C),
          badge: Color(0xFFF6D7A8),
          badgeInk: Color(0xFF2A1C08),
        ),
      RunFinishCardTheme.blue => const _CardPalette(
          background: [Color(0xFF07152E), Color(0xFF14367A), Color(0xFF0E2A62)],
          glow: Color(0xFF8EB6FF),
          glowAlpha: 0.48,
          hero: Color(0xFFF5F8FF),
          unit: Color(0xFFC5D9FF),
          muted: Color(0xC7F5F8FF),
          stat: Color(0xFFFFFFFF),
          route: Color(0xFFE4EEFF),
          hairline: Color(0x40FFFFFF),
          decor: Color(0xFFC5D9FF),
          chip: Color(0xFF173E86),
          icon: Color(0xFFD6E4FF),
          iconPlate: Color(0xFF1E4E9E),
          badge: Color(0xFFFFE3B0),
          badgeInk: Color(0xFF2A1C08),
        ),
      RunFinishCardTheme.pink => const _CardPalette(
          background: [Color(0xFFFFF7FA), Color(0xFFFFD0E2), Color(0xFFFFB4CE)],
          glow: Color(0xFFFF7AA8),
          glowAlpha: 0.38,
          hero: Color(0xFF2C1220),
          unit: Color(0xFFA61E56),
          muted: Color(0xB82C1220),
          stat: Color(0xFF2C1220),
          route: Color(0xFFA61E56),
          hairline: Color(0x332C1220),
          decor: Color(0xFFA61E56),
          chip: Color(0xFFFFF7FA),
          icon: Color(0xFFA61E56),
          iconPlate: Color(0xFFFFE0EC),
          badge: Color(0xFFA61E56),
          badgeInk: Color(0xFFFFFFFF),
        ),
      RunFinishCardTheme.yellow => const _CardPalette(
          background: [Color(0xFFFFF8EC), Color(0xFFFFE3A0), Color(0xFFFFC44A)],
          glow: Color(0xFFFFF6D8),
          glowAlpha: 0.7,
          hero: Color(0xFF2A1C08),
          unit: Color(0xFF6B3A00),
          muted: Color(0xC22A1C08),
          stat: Color(0xFF2A1C08),
          route: Color(0xFF6B3A00),
          hairline: Color(0x332A1C08),
          decor: Color(0xFF6B3A00),
          chip: Color(0xFFFFFBF3),
          icon: Color(0xFF6B3A00),
          iconPlate: Color(0xFFFFE7B8),
          badge: Color(0xFF2A1C08),
          badgeInk: Color(0xFFFFF6E4),
        ),
      RunFinishCardTheme.mint => const _CardPalette(
          background: [Color(0xFF102820), Color(0xFF1B6A56), Color(0xFF3A2770)],
          glow: Color(0xFFC9B6FF),
          glowAlpha: 0.4,
          hero: Color(0xFFF7FFF9),
          unit: Color(0xFFD4C6FF),
          muted: Color(0xD0F7FFF9),
          stat: Color(0xFFFFFFFF),
          route: Color(0xFFE6DEFF),
          hairline: Color(0x40FFFFFF),
          decor: Color(0xFFE4D4FF),
          chip: Color(0xFF1A4E44),
          icon: Color(0xFFE4D4FF),
          iconPlate: Color(0xFF24685A),
          badge: Color(0xFFF6D7A8),
          badgeInk: Color(0xFF2A1C08),
        ),
    };
  }
}

/// Darkens the top and bottom of a scenery photo so the type stays light.
class _PhotoScrim extends StatelessWidget {
  const _PhotoScrim({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xD907110E),
            Color(0xB307110E),
            Color(0x7307110E),
            Color(0x1407110E),
            Color(0x1407110E),
            Color(0x9907110E),
            Color(0xE607110E),
          ],
          stops: [0.0, 0.16, 0.40, 0.52, 0.76, 0.84, 1.0],
        ),
      ),
    );
  }
}

class _AtmospherePainter extends CustomPainter {
  const _AtmospherePainter(this.palette);

  final _CardPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    void orb(Offset center, double radius, double alpha) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              palette.glow.withValues(alpha: alpha),
              palette.glow.withValues(alpha: 0),
            ],
          ).createShader(rect),
      );
    }

    orb(Offset(size.width * 0.82, size.height * 0.08), size.width * 0.62,
        palette.glowAlpha);
    orb(Offset(size.width * 0.08, size.height * 0.92), size.width * 0.48,
        palette.glowAlpha * 0.85);
    orb(Offset(size.width * 0.5, size.height * 0.46), size.width * 0.42,
        palette.glowAlpha * 0.35);
  }

  @override
  bool shouldRepaint(covariant _AtmospherePainter oldDelegate) =>
      oldDelegate.palette != palette;
}

/// Abstract track, used when this run has no route so the poster is not empty.
class _TrackFieldPainter extends CustomPainter {
  const _TrackFieldPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final lane = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final track = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.655),
      width: size.width * 0.88,
      height: size.width * 0.40,
    );
    for (var i = 0; i < 4; i++) {
      lane
        ..strokeWidth = i == 0 ? 3.2 : 1.8
        ..color = color.withValues(alpha: i == 0 ? 0.42 : 0.22 - i * 0.03);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            track.deflate(i * 22), Radius.circular(track.height / 2)),
        lane,
      );
    }

    final start = Offset(track.left + track.width * 0.22, track.center.dy);
    canvas.drawLine(
      start.translate(0, -28),
      start.translate(0, 28),
      Paint()
        ..color = color.withValues(alpha: 0.7)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(track.right - 70, track.center.dy - 8), 9,
        Paint()..color = color);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.28);
    canvas.drawArc(
      Rect.fromCircle(
          center: Offset(size.width * 1.02, size.height * 0.16), radius: 340),
      1.6,
      1.7,
      false,
      arcPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(
          center: Offset(size.width * 1.02, size.height * 0.16), radius: 390),
      1.7,
      1.45,
      false,
      arcPaint..color = color.withValues(alpha: 0.16),
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(-30, size.height * 0.96), radius: 260),
      -1.2,
      1.5,
      false,
      arcPaint
        ..strokeWidth = 2
        ..color = color.withValues(alpha: 0.22),
    );

    const dashWidths = <double>[220, 150, 260, 110];
    for (var i = 0; i < dashWidths.length; i++) {
      final y = size.height * 0.52 + i * 22;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * 0.62, y, dashWidths[i], 7),
          const Radius.circular(4),
        ),
        Paint()..color = color.withValues(alpha: 0.20 - i * 0.03),
      );
    }

    final dot = Paint()..color = color.withValues(alpha: 0.16);
    for (var y = 48.0; y < size.height; y += 64) {
      for (var x = 36.0; x < size.width; x += 64) {
        canvas.drawCircle(Offset(x, y), 1.5, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrackFieldPainter oldDelegate) =>
      oldDelegate.color != color;
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
    final start =
        Offset(points.first.dx * size.width, points.first.dy * size.height);
    final end =
        Offset(points.last.dx * size.width, points.last.dy * size.height);
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
        Offset(point.dx.clamp(0.0, 1.0) * size.width,
            point.dy.clamp(0.0, 1.0) * size.height),
    ];
    final path = Path()..moveTo(mapped.first.dx, mapped.first.dy);
    for (var i = 1; i < mapped.length; i++) {
      final previous = mapped[i - 1];
      final current = mapped[i];
      final mid = Offset(
          (previous.dx + current.dx) / 2, (previous.dy + current.dy) / 2);
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

enum _LineIconKind { time, pace, heart }

class _LineIconPainter extends CustomPainter {
  const _LineIconPainter(this.kind, this.color);

  final _LineIconKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.07
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final c = Offset(size.width / 2, size.height / 2);
    switch (kind) {
      case _LineIconKind.time:
        final r = size.shortestSide * 0.30;
        canvas.drawCircle(c, r, paint);
        canvas.drawLine(c, c.translate(0, -r * 0.62), paint);
        canvas.drawLine(c, c.translate(r * 0.48, r * 0.18), paint);
        canvas.drawCircle(c, size.shortestSide * 0.035, Paint()..color = color);
      case _LineIconKind.pace:
        final rect = Rect.fromCircle(
            center: c.translate(0, size.height * 0.04),
            radius: size.shortestSide * 0.30);
        canvas.drawArc(rect, 2.4, 4.0, false, paint);
        canvas.drawLine(
            c, c.translate(size.width * 0.16, -size.height * 0.20), paint);
        canvas.drawCircle(c, size.shortestSide * 0.035, Paint()..color = color);
      case _LineIconKind.heart:
        final w = size.width;
        final h = size.height;
        final path = Path()
          ..moveTo(w * 0.50, h * 0.74)
          ..cubicTo(w * 0.18, h * 0.50, w * 0.16, h * 0.30, w * 0.32, h * 0.26)
          ..cubicTo(w * 0.42, h * 0.23, w * 0.48, h * 0.32, w * 0.50, h * 0.38)
          ..cubicTo(w * 0.52, h * 0.32, w * 0.58, h * 0.23, w * 0.68, h * 0.26)
          ..cubicTo(w * 0.84, h * 0.30, w * 0.82, h * 0.50, w * 0.50, h * 0.74)
          ..close();
        canvas.drawPath(path, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _LineIconPainter oldDelegate) {
    return oldDelegate.kind != kind || oldDelegate.color != color;
  }
}

/// One poster. Swipe or tap a color dot to change the background only.
class RunFinishSharePreview extends StatelessWidget {
  const RunFinishSharePreview({
    required this.controller,
    required this.styleIndex,
    required this.cardFor,
    required this.onStyleChanged,
    this.photoActive = false,
    super.key,
  });

  static const pagerKey = Key('run-finish-share-pager');

  final PageController controller;
  final int styleIndex;
  final RunFinishShareCard Function(RunFinishCardTheme style) cardFor;
  final ValueChanged<int> onStyleChanged;
  final bool photoActive;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pageWidth =
            constraints.maxWidth * controller.viewportFraction - 16;
        final height = pageWidth * 16 / 9;
        final colors = RunFinishCardTheme.colorThemes;
        return Column(
          children: [
            SizedBox(
              height: height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    key: pagerKey,
                    controller: controller,
                    itemCount: colors.length,
                    onPageChanged: onStyleChanged,
                    itemBuilder: (context, index) {
                      return _PreviewFrame(child: cardFor(colors[index]));
                    },
                  ),
                  if (photoActive)
                    _PreviewFrame(child: cardFor(RunFinishCardTheme.photo)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < colors.length; i++)
                  _ThemeDot(
                    theme: colors[i],
                    selected: !photoActive && i == styleIndex,
                    onTap: () => onStyleChanged(i),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              photoActive
                  ? RunFinishCardTheme.photo.label
                  : colors[styleIndex].label,
              key: Key(
                photoActive
                    ? 'run-finish-style-photo'
                    : 'run-finish-style-$styleIndex',
              ),
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

class _PreviewFrame extends StatelessWidget {
  const _PreviewFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
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
            child: child,
          ),
        ),
      ),
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
                color: selected
                    ? const Color(0xFF1A1D22)
                    : const Color(0x00000000),
                width: 2,
              ),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme == RunFinishCardTheme.mint ||
                        theme == RunFinishCardTheme.photo
                    ? null
                    : theme.dot,
                gradient: switch (theme) {
                  RunFinishCardTheme.mint => const LinearGradient(
                      colors: [Color(0xFF1E6A58), Color(0xFF6B4C9A)],
                    ),
                  RunFinishCardTheme.photo => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF7EB6E8), Color(0xFF3E7A45)],
                    ),
                  _ => null,
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
