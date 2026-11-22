import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';
import 'package:share_run_challenge/features/friends/friend_errors.dart';

import 'friends_support.dart';

void main() {
  String message(int status, String detail) =>
      friendErrorMessage(null, apiError(status, detail));

  test('invalid asks the person to check the code', () {
    expect(message(400, 'invalid'), contains('코드를 확인해 주세요'));
  });

  test('self says your own code cannot be used', () {
    expect(message(400, 'self'), contains('내 친구 코드'));
  });

  test('used says the code was already used', () {
    expect(message(410, 'used'), contains('이미 사용한 코드'));
  });

  test('expired mentions 24 hours and asks for a new code', () {
    final text = message(410, 'expired');
    expect(text, contains('24시간'));
    expect(text, contains('새 코드'));
  });

  test('friend_limit says up to 50 friends', () {
    expect(message(409, 'friend_limit'), contains('50명'));
  });

  test('429 says no more codes today', () {
    final text = message(429, 'Friend invite limit reached.');
    expect(text, contains('오늘'));
    expect(text, contains('내일'));
  });

  test('invalid_report_reason is the general error', () {
    expect(message(400, 'invalid_report_reason'),
        message(500, 'something unknown'));
  });

  test('an unknown detail and a network error are the general error', () {
    expect(message(500, 'boom'), contains('잠시 후 다시'));
    expect(friendErrorMessage(null, Exception('socket closed')),
        contains('잠시 후 다시'));
    expect(friendErrorMessage(null, StateError('x')), contains('잠시 후 다시'));
  });

  test('every status gives its own wording, none is empty', () {
    final all = {
      message(400, 'invalid'),
      message(400, 'self'),
      message(410, 'used'),
      message(410, 'expired'),
      message(409, 'friend_limit'),
      message(429, 'Friend invite limit reached.'),
      message(500, 'boom'),
    };
    expect(all.length, 7);
    expect(all.every((text) => text.trim().isNotEmpty), isTrue);
  });

  test('the invalid text is not the referral-code text', () {
    final invalid = message(400, 'invalid');
    expect(invalid, isNot(AppStrings.referralRedeemInvalid));
    expect(invalid.contains('초대'), isFalse);
    expect(invalid.contains('추천'), isFalse);
    // The same holds for the other details the shared table rewrites.
    expect(message(400, 'self'), isNot(AppStrings.referralRedeemSelf));
    expect(message(410, 'expired'), isNot(AppStrings.referralRedeemExpired));
  });

  test('a blocked pair reads exactly like a code that does not exist', () {
    // The server answers both with 400 "invalid".
    expect(message(400, 'invalid'), friendInvalidCodeMessage(null));
  });
}
