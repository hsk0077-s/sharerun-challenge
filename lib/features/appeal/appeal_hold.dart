import '../../data/models/activity_model.dart';

/// 소명 화면이 보여 주는 "검증이 보류된 실제 기록" 한 건.
class AppealHold {
  const AppealHold({required this.activity});

  final ActivityModel activity;

  String get title {
    final km = activity.distanceKm.toStringAsFixed(2);
    return '$km km 달리기';
  }

  String get dateLabel {
    final at = activity.completedAt?.toLocal();
    if (at == null) return '';
    final hh = at.hour.toString().padLeft(2, '0');
    final mm = at.minute.toString().padLeft(2, '0');
    return '${at.month}월 ${at.day}일 $hh:$mm';
  }

  /// 서버가 남긴 보류 이유(한글 문장). 없거나 코드뿐이면 일반 문구를 쓴다.
  String get reason => holdReasonText(activity.jenaReason);
}

const _generalReason = '서버 검증에서 확인이 더 필요하다고 판단했어요.';

final _hangul = RegExp(r'[가-힣]');

String holdReasonText(String? serverReason) {
  final text = serverReason?.trim() ?? '';
  if (text.isEmpty || !_hangul.hasMatch(text)) return _generalReason;
  return text;
}

/// [activityId]가 있으면 그 기록, 없으면 보류된 기록 중 가장 최근 것. 보류가 아니면 null.
AppealHold? pendingHoldFor(
  List<ActivityModel> activities, {
  String? activityId,
}) {
  final wanted = activityId?.trim() ?? '';
  ActivityModel? pick;
  for (final activity in activities) {
    if (!activity.needsJenaAppeal) continue;
    if (wanted.isNotEmpty) {
      if (activity.id == wanted) {
        pick = activity;
        break;
      }
      continue;
    }
    final best = pick?.completedAt;
    final at = activity.completedAt;
    if (pick == null || (at != null && (best == null || at.isAfter(best)))) {
      pick = activity;
    }
  }
  return pick == null ? null : AppealHold(activity: pick);
}
