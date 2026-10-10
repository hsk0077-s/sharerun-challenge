import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:share_run_challenge/features/iap/payment_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuth implements LocalAuthentication {
  _FakeAuth({
    this.supported = true,
    this.result = true,
    this.error,
  });

  final bool supported;
  final bool result;
  final LocalAuthException? error;
  int calls = 0;

  // 쓰는 메서드(isDeviceSupported, authenticate)만 흉내 낸다.
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #isDeviceSupported) {
      return Future<bool>.value(supported);
    }
    if (invocation.memberName == #authenticate) {
      calls++;
      final e = error;
      if (e != null) return Future<bool>.error(e);
      return Future<bool>.value(result);
    }
    return super.noSuchMethod(invocation);
  }
}

LocalAuthException _ex(LocalAuthExceptionCode code) =>
    LocalAuthException(code: code);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a passed check lets the payment start and is not repeated within 60s',
      () async {
    var now = DateTime.utc(2026, 10, 11, 12);
    final fake = _FakeAuth();
    final gate = PaymentAuthGate(auth: fake, now: () => now);

    expect(await gate.confirm(), PaymentAuthResult.approved);
    now = now.add(const Duration(seconds: 30));
    expect(await gate.confirm(), PaymentAuthResult.approved);
    expect(fake.calls, 1);

    now = now.add(const Duration(seconds: 40));
    expect(await gate.confirm(), PaymentAuthResult.approved);
    expect(fake.calls, 2);
  });

  test('cancel, lockout and a missing screen lock each stop the payment',
      () async {
    expect(
      await PaymentAuthGate(auth: _FakeAuth(result: false)).confirm(),
      PaymentAuthResult.canceled,
    );
    expect(
      await PaymentAuthGate(
        auth: _FakeAuth(error: _ex(LocalAuthExceptionCode.userCanceled)),
      ).confirm(),
      PaymentAuthResult.canceled,
    );
    expect(
      await PaymentAuthGate(
        auth: _FakeAuth(error: _ex(LocalAuthExceptionCode.temporaryLockout)),
      ).confirm(),
      PaymentAuthResult.lockedOut,
    );
    expect(
      await PaymentAuthGate(auth: _FakeAuth(supported: false)).confirm(),
      PaymentAuthResult.noScreenLock,
    );
    expect(
      await PaymentAuthGate(
        auth: _FakeAuth(error: _ex(LocalAuthExceptionCode.noCredentialsSet)),
      ).confirm(),
      PaymentAuthResult.noScreenLock,
    );
    expect(
      await PaymentAuthGate(
        auth: _FakeAuth(error: _ex(LocalAuthExceptionCode.uiUnavailable)),
      ).confirm(),
      PaymentAuthResult.unavailable,
    );
  });

  test('a failed check is never remembered as approved', () async {
    final fake = _FakeAuth(result: false);
    final gate = PaymentAuthGate(auth: fake);
    expect(await gate.confirm(), PaymentAuthResult.canceled);
    expect(await gate.confirm(), PaymentAuthResult.canceled);
    expect(fake.calls, 2);
  });

  test('the setting is on by default and off skips the check', () async {
    final fake = _FakeAuth(result: false);
    final gate = PaymentAuthGate(auth: fake);
    expect(await gate.isEnabled(), isTrue);

    await gate.setEnabled(false);
    expect(await gate.isEnabled(), isFalse);
    expect(await gate.confirm(), PaymentAuthResult.approved);
    expect(fake.calls, 0);
    // 끌 때의 확인은 설정과 상관없이 한다.
    expect(
      await gate.confirm(ignoreSetting: true),
      PaymentAuthResult.canceled,
    );
  });

  test('every blocked result has a user message that says nothing was paid',
      () {
    for (final result in PaymentAuthResult.values) {
      if (result == PaymentAuthResult.approved) {
        expect(paymentAuthMessage(result), isEmpty);
      } else {
        expect(paymentAuthMessage(result), isNotEmpty);
      }
    }
    expect(paymentAuthMessage(PaymentAuthResult.canceled), contains('결제는 진행되지 않았어요'));
    expect(paymentAuthMessage(PaymentAuthResult.lockedOut), contains('결제는 진행되지 않았어요'));
  });
}
