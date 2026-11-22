import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/friends/cheer_errors.dart';

import 'friends_support.dart';

void main() {
  test('each cheer detail has its own message', () {
    expect(cheerErrorMessage(null, apiError(404, 'not_found')),
        '이 기록에는 응원할 수 없어요.');
    expect(cheerErrorMessage(null, apiError(409, 'already_cheered')),
        '이미 응원했어요.');
    expect(cheerErrorMessage(null, apiError(429, 'friend_daily_limit')),
        contains('이 친구에게는 오늘 이미 응원했어요'));
    expect(cheerErrorMessage(null, apiError(429, 'friend_daily_limit')),
        contains('내일'));
    expect(cheerErrorMessage(null, apiError(429, 'daily_limit')),
        '오늘 응원은 20번까지예요.');
  });

  test('self, invalid_reaction and invalid get the general message', () {
    for (final detail in ['self', 'invalid_reaction', 'invalid']) {
      expect(cheerErrorMessage(null, apiError(400, detail)),
          '잠시 후 다시 시도해 주세요.',
          reason: detail);
    }
  });

  test('unknown details and network errors get the general message', () {
    expect(cheerErrorMessage(null, apiError(500, 'boom')),
        '잠시 후 다시 시도해 주세요.');
    expect(cheerErrorMessage(null, apiError(404, 'something else')),
        '잠시 후 다시 시도해 주세요.');
    expect(cheerErrorMessage(null, Exception('offline')),
        '잠시 후 다시 시도해 주세요.');
  });

  test('not_found never says blocked, and none mention referral words', () {
    final texts = [
      for (final detail in [
        'not_found',
        'already_cheered',
        'friend_daily_limit',
        'daily_limit',
        'self',
        'invalid',
      ])
        cheerErrorMessage(null, apiError(400, detail)),
    ];
    expect(cheerErrorMessage(null, apiError(404, 'not_found')).contains('차단'),
        isFalse);
    for (final text in texts) {
      expect(text.contains('차단'), isFalse);
      expect(text.contains('추천'), isFalse);
      expect(text.contains('초대'), isFalse);
    }
  });
}
