import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/run_tracking/utils/home_start_gate.dart';

void main() {
  test('START fails closed without login or health consent', () {
    expect(
      HomeStartGate.startBlockReason(signedIn: false, healthConsent: true),
      '로그인 후 러닝을 시작할 수 있습니다.',
    );
    expect(
      HomeStartGate.startBlockReason(signedIn: true, healthConsent: false),
      '마이페이지에서 민감정보 수집에 동의해주세요',
    );
    expect(
      HomeStartGate.startBlockReason(signedIn: true, healthConsent: true),
      isNull,
    );
  });

  test('validate fails closed unless signed in and session started', () {
    expect(
      HomeStartGate.validateBlockReason(
        signedIn: false,
        sessionStarted: true,
      ),
      '로그인 후 러닝 검증을 진행할 수 있습니다.',
    );
    expect(
      HomeStartGate.validateBlockReason(
        signedIn: true,
        sessionStarted: false,
      ),
      '러닝이 시작되지 않았습니다.',
    );
    expect(
      HomeStartGate.validateBlockReason(
        signedIn: true,
        sessionStarted: true,
      ),
      isNull,
    );
  });
}
