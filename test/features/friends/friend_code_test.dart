import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/friends/friend_code.dart';

import 'friends_support.dart';

void main() {
  group('extractFriendToken', () {
    test('finds the token behind the prefix', () {
      expect(extractFriendToken('sharerun-friend:$testToken'), testToken);
    });

    test('accepts a bare token', () {
      expect(extractFriendToken(testToken), testToken);
    });

    test('ignores spaces and new lines around the code', () {
      expect(extractFriendToken('  \n sharerun-friend:$testToken \r\n'),
          testToken);
      expect(extractFriendToken('\n\t$testToken\n'), testToken);
    });

    test('finds the code inside the whole Korean share message', () {
      final text = '쉐어런에서 친구 해요. 앱 > 마이페이지 > 친구 > 친구 코드 입력에 붙여 넣어 '
          '주세요(24시간 동안 한 번만 쓸 수 있어요). 코드: sharerun-friend:$testToken\n'
          'https://play.google.com/store/apps/details?id=com.sharerun.share_run_challenge';
      expect(extractFriendToken(text), testToken);
    });

    test('finds the code inside the whole English share message', () {
      final text = "Let's be friends on ShareRun. In the app, go to My Page > "
          'Friends > Enter friend code and paste this (works once, for 24 '
          'hours). Code: sharerun-friend:$testToken\n'
          'https://play.google.com/store/apps/details?id=com.sharerun.share_run_challenge';
      expect(extractFriendToken(text), testToken);
    });

    test('finds the code in Japanese and Thai messages', () {
      expect(
        extractFriendToken(
            'コード: sharerun-friend:$testToken。\nhttps://example.com'),
        testToken,
      );
      expect(extractFriendToken('รหัส: sharerun-friend:$testToken ขอบคุณ'),
          testToken);
    });

    test('ignores upper and lower case of the prefix', () {
      expect(extractFriendToken('SHARERUN-FRIEND:$testToken'), testToken);
    });

    test('empty and blank text give null', () {
      expect(extractFriendToken(null), isNull);
      expect(extractFriendToken(''), isNull);
      expect(extractFriendToken('   \n '), isNull);
    });

    test('unrelated text gives null', () {
      expect(extractFriendToken('안녕하세요 친구 코드를 보낼게요'), isNull);
      expect(extractFriendToken('hello world'), isNull);
      expect(extractFriendToken('sharerun-friend:'), isNull);
      expect(extractFriendToken('sharerun-friend:short'), isNull);
    });

    test('a long sentence with no prefix does not pass as a bare token', () {
      expect(extractFriendToken('please use $testToken today'), isNull);
    });

    test('a token that is too long is not cut down', () {
      final tooLong = 'a' * 65;
      expect(extractFriendToken('sharerun-friend:$tooLong'), isNull);
      expect(extractFriendToken(tooLong), isNull);
    });
  });
}
