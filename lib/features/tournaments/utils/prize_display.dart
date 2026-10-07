import '../../../core/strings/app_strings.dart';
import '../../../data/models/company_tournament_config.dart';
import '../../../data/models/tournament_model.dart';

/// "18만 원 상당 다이아" from server DIA and the config won rate.
/// Returns null when either number is missing, so the client does not invent one.
String? bonusDiaWorthLabel({required int dia, required int krwPerDia}) {
  if (dia <= 0 || krwPerDia <= 0) return null;
  final won = dia * krwPerDia;
  if (won % 10000 == 0) {
    return '${won ~/ 10000}만 원 상당 다이아';
  }
  return '${_grouped(won)}원 상당 다이아';
}

/// Prize line for a room card. Company races use the config total.
/// Other rooms keep their existing pool line, or say there is no cash prize.
String prizePoolLine({
  required TournamentModel room,
  required bool configLoading,
  required CompanyTournamentConfig? config,
}) {
  if (!room.isPrizeRace) {
    return room.cashPrizePoolLabel ?? AppStrings.noCashPrizePool;
  }
  if (configLoading) return '상금을 확인하는 중이에요';
  final label = bonusDiaWorthLabel(
    dia: config?.tier(room.prizeTier)?.advertisedPrizeDia ?? 0,
    krwPerDia: config?.diaKrw ?? 0,
  );
  if (label == null) return '상금을 불러오지 못했어요';
  return label;
}

String _grouped(int won) {
  final text = won.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
    buffer.write(text[i]);
  }
  return buffer.toString();
}
