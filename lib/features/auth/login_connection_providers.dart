import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import '../../data/api/identity_api_client.dart';
import '../../data/repositories/auth_repository.dart';

final identityApiClientProvider = Provider<IdentityApiClient>(
  (ref) => IdentityApiClient(
    baseUri: ref.watch(jenaBaseUriProvider),
    firebaseAuth: ref.watch(firebaseAuthProvider),
  ),
);

/// 카카오 로그인 창을 띄워 토큰을 받는다. 취소하면 null. 시험에서는 이 값을 바꿔 끼운다.
final kakaoAccessTokenProvider = Provider<Future<String?> Function()>(
  (ref) => ref.watch(authRepositoryProvider).kakaoAccessToken,
);

/// 네이버 로그인 창을 띄워 토큰을 받는다. 닫으면 null. 시험에서는 이 값을 바꿔 끼운다.
final naverAccessTokenProvider = Provider<Future<String?> Function()>(
  (ref) => ref.watch(authRepositoryProvider).naverAccessToken,
);

/// 애플 로그인 창을 띄워 ID 토큰을 받는다. 닫으면 null. 시험에서는 이 값을 바꿔 끼운다.
final appleIdTokenProvider = Provider<Future<String?> Function()>(
  (ref) => ref.watch(authRepositoryProvider).appleIdToken,
);

/// 구글 로그인 창을 띄워 ID 토큰을 받는다. 닫으면 null. 시험에서는 이 값을 바꿔 끼운다.
final googleIdTokenProvider = Provider<Future<String?> Function()>(
  (ref) => ref.watch(authRepositoryProvider).googleIdToken,
);
