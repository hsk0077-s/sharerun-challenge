import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/config/app_env.dart';

/// 지갑 숫자가 서버에서 확인된 값이면 true.
/// 오프라인이거나 아직 서버 응답을 받기 전이면 false이고, 이때 화면의 숫자는
/// 마지막으로 확인된 값이다. 로그인 전이나 데모 모드에서는 확인할 것이 없어 true.
final walletServerConfirmedProvider = Provider<bool>((ref) {
  if (AppEnv.useLocalMockData) return true;
  final uid = ref.watch(authStateChangesProvider).asData?.value?.uid ?? '';
  if (uid.isEmpty) return true;
  final confirmed = ref.watch(_walletConfirmedStreamProvider(uid));
  return confirmed.asData?.value ?? false;
});

final _walletConfirmedStreamProvider =
    StreamProvider.autoDispose.family<bool, String>((ref, uid) {
  return ref.watch(walletRepositoryProvider).watchWalletServerConfirmed(uid);
});
