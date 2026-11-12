/// 0.35 -> "0.35", 3.0 -> "3", 3.02 -> "3.02". Never more than two decimals.
String formatTourKm(double km) {
  final rounded = (km * 100).round() / 100;
  if (rounded == rounded.roundToDouble()) return rounded.round().toString();
  var text = rounded.toStringAsFixed(2);
  if (text.endsWith('0')) text = text.substring(0, text.length - 1);
  return text;
}

/// 1450 -> "24:10", 3725 -> "1:02:05".
String formatTourDuration(int seconds) {
  final s = seconds < 0 ? 0 : seconds;
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final sec = s % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(sec)}' : '${two(m)}:${two(sec)}';
}
