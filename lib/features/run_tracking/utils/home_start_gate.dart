/// Fail-closed Home START / live-run session guards.
///
/// Does not credit or debit SHARE/DIA/VALUE. Jena validate remains server-owned.
abstract final class HomeStartGate {
  static String? startBlockReason({
    required bool signedIn,
    required bool healthConsent,
  }) {
    if (!signedIn) {
      return '로그인 후 러닝을 시작할 수 있습니다.';
    }
    if (!healthConsent) {
      return '마이페이지에서 민감정보 수집에 동의해주세요';
    }
    return null;
  }

  static String? validateBlockReason({
    required bool signedIn,
    required bool sessionStarted,
  }) {
    if (!signedIn) {
      return '로그인 후 러닝 검증을 진행할 수 있습니다.';
    }
    if (!sessionStarted) {
      return '러닝이 시작되지 않았습니다.';
    }
    return null;
  }
}
