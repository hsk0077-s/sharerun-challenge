import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../data/models/wallet_transaction_model.dart';

/// 서버 원장 한 쪽을 읽는 함수. 테스트에서 바꿔 끼울 수 있게 provider로 둔다.
typedef WalletHistoryLoader = Future<WalletHistoryPage> Function({
  Object? cursor,
});

const _emptyPage = WalletHistoryPage(rows: [], cursor: null, hasMore: false);

final walletHistoryLoaderProvider = Provider<WalletHistoryLoader>((ref) {
  final uid = ref.watch(authStateChangesProvider).asData?.value?.uid;
  final repository = ref.watch(walletRepositoryProvider);
  return ({Object? cursor}) async {
    if (uid == null || uid.isEmpty) return _emptyPage;
    return repository.fetchTransactionPage(uid, cursor: cursor);
  };
});
