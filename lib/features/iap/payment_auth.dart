import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 결제창을 열기 전 본인 확인 결과.
enum PaymentAuthResult {
  approved,
  canceled,
  lockedOut,
  noScreenLock,
  unavailable,
}

/// 확인이 통과하지 못했을 때 사용자에게 보여 줄 문구. 결제는 시작하지 않았다.
String paymentAuthMessage(PaymentAuthResult result) {
  switch (result) {
    case PaymentAuthResult.approved:
      return '';
    case PaymentAuthResult.canceled:
      return '본인 확인이 취소됐어요. 결제는 진행되지 않았어요.';
    case PaymentAuthResult.lockedOut:
      return '확인을 여러 번 틀려 잠시 막혔어요. 잠시 뒤 다시 하거나 화면 잠금(PIN, 패턴)으로 확인해 주세요. 결제는 진행되지 않았어요.';
    case PaymentAuthResult.noScreenLock:
      return '결제 전 본인 확인을 하려면 폰에 화면 잠금(지문, PIN, 패턴)이 필요해요. 기기 설정에서 화면 잠금을 켠 뒤 다시 시도해 주세요.';
    case PaymentAuthResult.unavailable:
      return '본인 확인을 할 수 없어요. 잠시 뒤 다시 시도해 주세요. 결제는 진행되지 않았어요.';
  }
}

/// 실제 돈이 나가는 결제(구글 플레이 결제창)를 열기 직전의 본인 확인.
///
/// 지문이나 얼굴로 확인하고, 안 되면 폰 화면 잠금(PIN, 패턴, 비밀번호)으로 대신한다.
/// 결제 자체의 승인은 구글 플레이가 하고 서버가 영수증을 검증한다. 이 확인은 그
/// 앞에서 폰이 풀려 있을 때의 실수나 몰래 하는 결제를 한 번 걸러 주는 장치다.
class PaymentAuthGate {
  PaymentAuthGate({
    LocalAuthentication? auth,
    DateTime Function()? now,
    this.grace = const Duration(seconds: 60),
  })  : _auth = auth ?? LocalAuthentication(),
        _now = now ?? DateTime.now;

  static const enabledKey = 'payment_auth_enabled';

  final LocalAuthentication _auth;
  final DateTime Function() _now;

  /// 한 번 통과하면 이 시간 동안은 다시 묻지 않는다(연달아 결제할 때의 편의).
  final Duration grace;

  DateTime? _lastApproved;

  /// 이 폰의 설정. 기본은 켬이다(폰마다 지문 사정이 달라 폰에 저장한다).
  Future<bool> isEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(enabledKey) ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(enabledKey, value);
    _lastApproved = null;
  }

  Future<PaymentAuthResult> confirm({
    String reason = '결제를 진행하려면 본인 확인이 필요해요.',
    bool ignoreSetting = false,
  }) async {
    if (!ignoreSetting && !await isEnabled()) return PaymentAuthResult.approved;
    final last = _lastApproved;
    if (last != null && _now().difference(last) < grace) {
      return PaymentAuthResult.approved;
    }
    try {
      if (!await _auth.isDeviceSupported()) {
        return PaymentAuthResult.noScreenLock;
      }
      final ok = await _auth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
      if (!ok) return PaymentAuthResult.canceled;
      _lastApproved = _now();
      return PaymentAuthResult.approved;
    } on LocalAuthException catch (error) {
      return switch (error.code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.timeout =>
          PaymentAuthResult.canceled,
        LocalAuthExceptionCode.noCredentialsSet ||
        LocalAuthExceptionCode.noBiometricsEnrolled ||
        LocalAuthExceptionCode.noBiometricHardware =>
          PaymentAuthResult.noScreenLock,
        LocalAuthExceptionCode.temporaryLockout ||
        LocalAuthExceptionCode.biometricLockout =>
          PaymentAuthResult.lockedOut,
        _ => PaymentAuthResult.unavailable,
      };
    } catch (error) {
      debugPrint('PaymentAuthGate: $error');
      return PaymentAuthResult.unavailable;
    }
  }
}
