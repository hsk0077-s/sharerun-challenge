import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../debug_local_wallet_store.dart';

class DebugLocalShareHistory extends Notifier<List<DebugLocalShareTx>> {
  @override
  List<DebugLocalShareTx> build() => const [];

  void replace(List<DebugLocalShareTx> next) {
    state = List<DebugLocalShareTx>.unmodifiable(next);
  }
}

final debugLocalShareHistoryProvider =
    NotifierProvider<DebugLocalShareHistory, List<DebugLocalShareTx>>(
  DebugLocalShareHistory.new,
);
