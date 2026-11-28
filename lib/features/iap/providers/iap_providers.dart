import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/config/app_env.dart';
import '../../../data/repositories/purchase_repository.dart';
import '../../wallet/providers/wallet_provider.dart';
import '../models/iap_ui_event.dart';
import '../payment_auth.dart';
import '../services/iap_purchase_controller.dart';
import '../../../l10n/remaining_surface.dart';

final purchaseRepositoryProvider = Provider<PurchaseRepository>(
  (ref) => PurchaseRepository(ref.watch(firestoreServiceProvider)),
);

final paymentAuthGateProvider = Provider<PaymentAuthGate>((ref) => PaymentAuthGate());

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
      if (!kDebugMode) return;
      ref.read(walletProvider.notifier).chargeShare(amount);
      final uid = ref.read(authStateChangesProvider).asData?.value?.uid ??
          ref.read(persistedAuthSessionProvider)?.uid ??
          '';
      if (uid.isEmpty || amount <= 0) return;
      unawaited(
        ref.read(walletRepositoryProvider).logClientWalletTransaction(
              uid: uid,
              title: RemainingSurface.trNow('iap.iap_providers.body', 'SHARE 충전 💳'),
              amount: amount,
              assetType: 'SHARE',
            ),
      );
    },
    confirmPayment: ref.read(paymentAuthGateProvider).confirm,
    onDiaPackPurchased: (productId, purchaseToken) async {
      final result = await ref
          .read(securedActionApiClientProvider)
          .grantDiaPack(productId, purchaseToken);
      final granted = result.accepted &&
          (result.status == 'granted' || result.status == 'already_granted');
      if (!granted) return false;
      ref.read(walletProvider.notifier).applyWalletSnapshot(
            shareBalance: result.shareBalance,
            diamondBalance: result.diamondBalance,
            valueBalance: result.valueTokenBalance,
          );
      return true;
    },
  );
  ref.onDispose(controller.dispose);
  return controller;
});

final iapUiEventsProvider = StreamProvider<IapUiEvent>((ref) {
  return ref.watch(iapPurchaseControllerProvider).uiEvents;
});

/// Play price labels for DIA packs. Empty when the packs switch is off
/// or the store cannot be reached.
final diaPackPriceLabelsProvider = FutureProvider<Map<String, String>>((ref) {
  if (!AppEnv.diaPacksEnabled) return const {};
  return ref.watch(iapPurchaseControllerProvider).queryDiaPackPriceLabels();
});
