import '../../core/api/api_exception.dart';

/// Korean copy for the two streak items. Other failures keep [fallback].
String streakItemMessage(ApiException error, {required String fallback}) {
  return switch (error.detail) {
    'Safeguard hold cap is 2.' => '세이프가드는 최대 2개까지 보유할 수 있습니다.',
    'CPR monthly use cap is 2.' => '심폐소생권은 한 달에 2번까지 사용할 수 있습니다.',
    'Streak is not broken.' => '되돌릴 끊긴 스트릭이 없습니다.',
    'Streak break is outside 72 hours.' =>
      '스트릭이 끊긴 지 72시간이 지나 되돌릴 수 없습니다.',
    'No missed day to protect.' => '막을 빠진 날이 없습니다.',
    'Insufficient Diamond balance.' => 'DIA가 부족합니다. 상점에서 구매해 주세요.',
    'No item to use.' => fallback,
    _ => fallback,
  };
}
