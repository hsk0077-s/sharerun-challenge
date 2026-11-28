import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/auth/firebase_auth_messages.dart';

void main() {
  group('FirebaseAuthMessages', () {
    test('maps invalid credential to Korean copy', () {
      expect(
        FirebaseAuthMessages.fromCode('invalid-credential'),
        '이메일 또는 비밀번호를 확인해 주세요.',
      );
    });

    test('maps email already in use', () {
      expect(
        FirebaseAuthMessages.fromCode('email-already-in-use'),
        '이미 사용 중인 이메일입니다.',
      );
    });

    test('falls back for unknown codes', () {
      expect(
        FirebaseAuthMessages.fromCode('custom-error', fallback: 'Custom'),
        'Custom',
      );
    });

    test('unknown errors do not show the raw exception', () {
      expect(
        FirebaseAuthMessages.from(StateError('Bad state')),
        '로그인에 실패했습니다. 잠시 후 다시 시도해 주세요.',
      );
      expect(
        FirebaseAuthMessages.from(Exception('Internal Server Error')),
        isNot(contains('Internal Server Error')),
      );
      expect(
        FirebaseAuthMessages.from(Exception('Bad state')),
        isNot(contains('Exception')),
      );
    });
  });
}
