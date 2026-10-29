import 'package:firebase_auth/firebase_auth.dart';

import '../../data/firebase/auth_service.dart';
import '../../l10n/remaining_surface.dart';

abstract final class FirebaseAuthMessages {
  static String from(Object error) {
    if (error is AuthCancelledException) {
      return RemainingSurface.trNow('firebase_auth_messages.body', '로그인이 취소되었습니다.');
    }
    if (error is FirebaseAuthException) {
      return fromCode(error.code, fallback: error.message);
    }
    return error.toString();
  }

  static String fromCode(String code, {String? fallback}) {
    return switch (code) {
      'invalid-email' => RemainingSurface.trNow('firebase_auth_messages.body.2', '이메일 형식이 올바르지 않습니다.'),
      'user-disabled' => RemainingSurface.trNow('firebase_auth_messages.body.3', '비활성화된 계정입니다. 고객센터에 문의해 주세요.'),
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' =>
        RemainingSurface.trNow('firebase_auth_messages.body.4', '이메일 또는 비밀번호를 확인해 주세요.'),
      'email-already-in-use' => RemainingSurface.trNow('firebase_auth_messages.body.5', '이미 사용 중인 이메일입니다.'),
      'weak-password' => RemainingSurface.trNow('firebase_auth_messages.body.6', '비밀번호는 6자 이상이어야 합니다.'),
      'too-many-requests' => RemainingSurface.trNow('firebase_auth_messages.body.7', '요청이 너무 많습니다. 잠시 후 다시 시도해 주세요.'),
      'network-request-failed' => RemainingSurface.trNow('firebase_auth_messages.body.8', '네트워크 연결을 확인해 주세요.'),
      'operation-not-allowed' ||
      'admin-restricted-operation' =>
        RemainingSurface.trNow('firebase_auth_messages.body.9', 'Firebase 콘솔에서 익명(게스트) 로그인을 활성화해 주세요.'),
      'account-exists-with-different-credential' =>
        RemainingSurface.trNow('firebase_auth_messages.body.10', '다른 로그인 방식으로 가입된 이메일입니다.'),
      'requires-recent-login' =>
        RemainingSurface.trNow('firebase_auth_messages.body.11', '보안을 위해 다시 로그인한 뒤 계정 삭제를 시도해 주세요.'),
      _ => fallback ?? RemainingSurface.trNow('firebase_auth_messages.body.12', '로그인에 실패했습니다.'),
    };
  }
}
