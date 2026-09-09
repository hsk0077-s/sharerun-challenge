import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../data/repositories/purchase_repository.dart';
import '../../wallet/providers/wallet_provider.dart';
import '../models/iap_ui_event.dart';
import '../services/iap_purchase_controller.dart';

final purchaseRepositoryProvider = Provider<PurchaseRepository>(
  (ref) => PurchaseRepository(ref.watch(firestoreServiceProvider)),
);

final iapPurchaseControllerProvider = Provider<IapPurchaseController>((ref) {
  final controller = IapPurchaseController(
    purchaseRepository: ref.watch(purchaseRepositoryProvider),
    walletRepository: ref.watch(walletRepositoryProvider),
    readUid: () {
      final auth = ref.read(authStateChangesProvider).asData?.value;
      if (auth != null && auth.uid.isNotEmpty) return auth.uid;
      return ref.read(persistedAuthSessionProvider)?.uid;
    },
    onLocalProvisionFallback: (amount) {
      ref.read(walletProvider.notifier).chargeShare(amount);
      final uid = ref.read(authStateChangesProvider).asData?.value?.uid ??
          ref.read(persistedAuthSessionProvider)?.uid ??
          '';
      if (uid.isEmpty || amount <= 0) return;
      unawaited(
        ref.read(walletRepositoryProvider).logClientWalletTransaction(
              uid: uid,
              title: 'SHARE 충전 💳',
              amount: amount,
              assetType: 'SHARE',
            ),
      );
    },
  );
  ref.onDispose(controller.dispose);
  return controller;
});

final iapUiEventsProvider = StreamProvider<IapUiEvent>((ref) {
  return ref.watch(iapPurchaseControllerProvider).uiEvents;
});
