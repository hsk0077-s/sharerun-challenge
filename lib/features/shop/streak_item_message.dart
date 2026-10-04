import '../../core/api/api_exception.dart';

/// Korean copy for the two streak items. Other failures keep [fallback].
String streakItemMessage(ApiException error, {required String fallback}) {
  return switch (error.detail) {
    'Safeguard hold cap is 2.' => '세이프가드는 최대 2개까지 보유할 수 있습니다.',
    'CPR monthly use cap is 2.' => '심폐소생권은 한 달에 2번까지 사용할 수 있습니다.',
    'Streak is not broken.' => '되돌릴 끊긴 스트릭이 없습니다.',
    'Streak break is outside 72 hours.' => '스트릭이 끊긴 지 72시간이 지나 되돌릴 수 없습니다.',
    'No missed day to protect.' => '막을 빠진 날이 없습니다.',
    'Insufficient Diamond balance.' => 'DIA가 부족합니다. 상점에서 구매해 주세요.',
    'No item to use.' => fallback,
    'Coach one-point daily use cap is 1.' => '코치 원포인트권은 하루에 1번까지 사용할 수 있습니다.',
    'Extra entry daily use cap is 2.' => '추가 참가권은 하루에 2번까지 사용할 수 있습니다.',
    'Prize races accept only SHARE or free tickets.' =>
      '상금 대회는 SHARE 또는 무료 참가권만 사용할 수 있습니다.',
    'Extra entry ticket is spent by joining a race.' =>
      '추가 참가권은 대회에 참가할 때 사용됩니다.',
    'No extra entry ticket.' => '사용할 추가 참가권이 없습니다.',
    'Friend recorded run is required.' => '친구의 검증된 기록을 선택해 주세요.',
    'Recorded run not found.' => '친구 기록을 찾지 못했습니다.',
    'Recorded run belongs to another runner.' => '그 기록은 선택한 친구의 기록이 아닙니다.',
    'Recorded run is not verified.' => '검증되지 않은 기록과는 비교할 수 없습니다.',
    'Recorded run has no pace.' => '그 기록에는 페이스가 없습니다.',
    'No crew.' => '소속 크루가 없습니다.',
    'Cheer flag is already up for this crew today.' =>
      '이 크루의 응원 깃발은 오늘 이미 걸려 있습니다.',
    'Friend ghost pack is spent as single uses.' =>
      '10회 묶음은 한 장씩 사용합니다.',
    _ => fallback,
  };
}
