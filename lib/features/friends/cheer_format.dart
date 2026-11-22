import 'package:flutter/widgets.dart';

import '../../l10n/remaining_surface.dart';
import 'cheers_models.dart';

/// Distance with two decimals, for example "5.20".
String formatCheerDistanceKm(double km) => km.toStringAsFixed(2);

/// "h:mm:ss" from one hour up, otherwise "m:ss".
String formatCheerDuration(int seconds) {
  final total = seconds < 0 ? 0 : seconds;
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
}

/// Today's date in Korea time as a date-only value.
DateTime kstDay(DateTime now) {
  final kst = now.toUtc().add(const Duration(hours: 9));
  return DateTime(kst.year, kst.month, kst.day);
}

/// "YYYY-MM-DD" to a date-only value, or null.
DateTime? parseKstDate(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) return null;
  return DateTime(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
}

/// "Today", "Yesterday", or the month and day. Both dates are date-only.
String cheerDayLabel(BuildContext? context, DateTime day, DateTime today) {
  final gap = DateTime.utc(today.year, today.month, today.day)
      .difference(DateTime.utc(day.year, day.month, day.day))
      .inDays;
  if (gap == 0) {
    return RemainingSurface.tr(context, 'cheers.day.today', '오늘');
  }
  if (gap == 1) {
    return RemainingSurface.tr(context, 'cheers.day.yesterday', '어제');
  }
  return RemainingSurface.tr(
    context,
    'cheers.day.date',
    '${day.month}월 ${day.day}일',
    {'month': '${day.month}', 'day': '${day.day}'},
  );
}

String cheerReactionLabel(BuildContext? context, CheerReaction reaction) {
  return switch (reaction) {
    CheerReaction.clap =>
      RemainingSurface.tr(context, 'cheers.reaction.clap', '박수'),
    CheerReaction.fire =>
      RemainingSurface.tr(context, 'cheers.reaction.fire', '불꽃'),
    CheerReaction.muscle =>
      RemainingSurface.tr(context, 'cheers.reaction.muscle', '파이팅'),
    CheerReaction.heart =>
      RemainingSurface.tr(context, 'cheers.reaction.heart', '하트'),
    CheerReaction.thumbs =>
      RemainingSurface.tr(context, 'cheers.reaction.thumbs', '최고'),
  };
}
