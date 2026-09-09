import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/config/app_env.dart';
import '../../../data/repositories/purchase_repository.dart';
import '../../../data/repositories/wallet_repository.dart';
import '../models/iap_ui_event.dart';
import '../models/share_iap_product.dart';

/// 앱 가동 시점부터 [purchaseStream]을 구독하는 IAP 라이프사이클 게이트웨이.
class IapPurchaseController {
  IapPurchaseController({
    required PurchaseRepository purchaseRepository,
    required WalletRepository walletRepository,
    required String? Function() readUid,
    void Function(int shareAmount)? onLocalProvisionFallback,
    InAppPurchase? iap,
  })  : _purchaseRepository = purchaseRepository,
        _walletRepository = walletRepository,
        _readUid = readUid,
        _onLocalProvisionFallback = onLocalProvisionFallback,
        _iap = iap ?? InAppPurchase.instance {
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('IAP purchaseStream error: $error\n$stackTrace');
        _emit(
          const IapUiEvent(
            kind: IapUiKind.error,
            message: '결제 스트림이 일시 중단되었습니다. 연결을 확인한 뒤 다시 시도해 주세요.',
          ),
        );
        _subscription = null;
        _ensureListening();
      },
      onDone: () {
        _subscription = null;
        _ensureListening();
      },
      cancelOnError: false,
    );
  }

  final PurchaseRepository _purchaseRepository;
  final WalletRepository _walletRepository;
  final String? Function() _readUid;
  final void Function(int shareAmount)? _onLocalProvisionFallback;
  final InAppPurchase _iap;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final _ui = StreamController<IapUiEvent>.broadcast();
  var _resubscribeAttempts = 0;

  Stream<IapUiEvent> get uiEvents => _ui.stream;

  Future<bool> isStoreAvailable() async {
    try {
      return await _iap.isAvailable();
    } catch (error, stackTrace) {
      debugPrint('IAP isAvailable failed: $error\n$stackTrace');
      return false;
    }
  }

  Future<void> buyConsumablePack(ShareIapProduct product) async {
    final available = await isStoreAvailable();
    if (!available) {
      _emit(
        const IapUiEvent(
          kind: IapUiKind.unavailable,
          message: 'Google Play 결제 서비스를 사용할 수 없습니다. 잠시 후 다시 시도해 주세요.',
        ),
      );
      return;
    }

    try {
      final response = await _iap.queryProductDetails({product.productId});
      if (response.error != null || response.productDetails.isEmpty) {
        _emit(
          IapUiEvent(
            kind: IapUiKind.error,
            message: '상품(${product.productId})을 찾지 못했습니다. Play Console 등록을 확인해 주세요.',
          ),
        );
        return;
      }
      final details = response.productDetails.firstWhere(
        (item) => item.id == product.productId,
        orElse: () => response.productDetails.first,
      );
      final launched = await _iap.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: details),
      );
      if (!launched) {
        _emit(
          const IapUiEvent(
            kind: IapUiKind.error,
            message: '결제 창을 열 수 없습니다.',
          ),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('IAP buyConsumable failed: $error\n$stackTrace');
      _emit(
        const IapUiEvent(
          kind: IapUiKind.error,
          message: '결제를 시작하지 못했습니다. 네트워크 상태를 확인해 주세요.',
        ),
      );
    }
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      await _handlePurchase(purchase);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    try {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _emit(
            const IapUiEvent(
              kind: IapUiKind.pending,
              message: '결제가 진행 중입니다. Google Play 승인을 기다려 주세요.',
            ),
          );
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _submitReceiptForBackendVerification(purchase);
        case PurchaseStatus.error:
          await _completeQuietly(purchase);
          _emit(
            IapUiEvent(
              kind: IapUiKind.error,
              message: purchase.error?.message ?? '결제가 실패했습니다.',
            ),
          );
        case PurchaseStatus.canceled:
          await _completeQuietly(purchase);
          _emit(
            const IapUiEvent(
              kind: IapUiKind.canceled,
              message: '결제가 취소되었습니다.',
            ),
          );
      }
    } catch (error, stackTrace) {
      debugPrint('IAP handle purchase failed: $error\n$stackTrace');
      await _completeQuietly(purchase);
      _emit(
        const IapUiEvent(
          kind: IapUiKind.error,
          message: '결제 처리 중 오류가 발생했습니다.',
        ),
      );
    }
  }

  Future<void> _submitReceiptForBackendVerification(
    PurchaseDetails purchase,
  ) async {
    final uid = _readUid();
    if (uid == null || uid.isEmpty) {
      await _completeQuietly(purchase);
      _emit(
        const IapUiEvent(
          kind: IapUiKind.error,
          message: '로그인 후 Google Play 결제를 진행해 주세요.',
        ),
      );
      return;
    }

    final catalog = ShareIapProduct.byProductId(purchase.productID);
    final shareAmount = catalog?.shareAmount ?? 0;
    final docId = await _purchaseRepository.enqueuePendingReceipt(
      userId: uid,
      productId: purchase.productID,
      shareAmount: shareAmount,
      purchaseId: purchase.purchaseID ?? '',
      serverVerificationData: purchase.verificationData.serverVerificationData,
      localVerificationData: purchase.verificationData.localVerificationData,
      source: purchase.verificationData.source,
    );

    await _completeQuietly(purchase);
    _emit(
      IapUiEvent(
        kind: IapUiKind.verifying,
        message: '영수증을 보안 검증 중입니다. SHARE는 검증 완료 후 지급됩니다.',
        purchaseDocId: docId,
        shareAmount: shareAmount,
      ),
    );

    if (AppEnv.useLocalMockData || AppEnv.localDevMode) {
      await _simulateCloudFunctionProvision(
        uid: uid,
        purchaseDocId: docId,
        shareAmount: shareAmount,
      );
      return;
    }

    await _awaitVerifiedStatus(docId, shareAmount);
  }

  Future<void> _simulateCloudFunctionProvision({
    required String uid,
    required String purchaseDocId,
    required int shareAmount,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    try {
      await _purchaseRepository.markVerifiedForMock(purchaseDocId: purchaseDocId);
    } catch (error, stackTrace) {
      debugPrint('Mock purchase VERIFIED write skipped: $error\n$stackTrace');
    }
    if (shareAmount > 0) {
      try {
        await _walletRepository.applyShareDelta(uid, shareAmount);
      } catch (error, stackTrace) {
        debugPrint('Mock SHARE provision skipped: $error\n$stackTrace');
        _onLocalProvisionFallback?.call(shareAmount);
      }
    }
    _emit(
      IapUiEvent(
        kind: IapUiKind.verified,
        message: '검증이 완료되어 $shareAmount SHARE가 지급되었습니다.',
        purchaseDocId: purchaseDocId,
        shareAmount: shareAmount,
      ),
    );
  }

  Future<void> _awaitVerifiedStatus(String purchaseDocId, int shareAmount) async {
    try {
      final status = await _purchaseRepository
          .watchStatus(purchaseDocId)
          .firstWhere(
            (value) =>
                value == PurchaseRepository.verified ||
                value == PurchaseRepository.rejected,
          )
          .timeout(const Duration(minutes: 2));
      if (status == PurchaseRepository.verified) {
        _emit(
          IapUiEvent(
            kind: IapUiKind.verified,
            message: 'Google 검증이 완료되어 SHARE가 지갑에 반영됩니다.',
            purchaseDocId: purchaseDocId,
            shareAmount: shareAmount,
          ),
        );
        return;
      }
      _emit(
        const IapUiEvent(
          kind: IapUiKind.error,
          message: '영수증 검증이 거절되었습니다. 고객센터로 문의해 주세요.',
        ),
      );
    } on TimeoutException {
      _emit(
        const IapUiEvent(
          kind: IapUiKind.error,
          message: '검증 응답이 지연되고 있습니다. 지갑 잔액을 잠시 후 다시 확인해 주세요.',
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Watch purchase status failed: $error\n$stackTrace');
    }
  }

  Future<void> _completeQuietly(PurchaseDetails purchase) async {
    if (!purchase.pendingCompletePurchase) return;
    try {
      await _iap.completePurchase(purchase);
    } catch (error, stackTrace) {
      debugPrint('IAP completePurchase failed: $error\n$stackTrace');
    }
  }

  void _ensureListening() {
    if (_subscription != null) return;
    if (_resubscribeAttempts >= 5) return;
    _resubscribeAttempts += 1;
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('IAP resubscribe error: $error\n$stackTrace');
        _subscription = null;
        _ensureListening();
      },
      onDone: () {
        _subscription = null;
        _ensureListening();
      },
      cancelOnError: false,
    );
  }

  void _emit(IapUiEvent event) {
    if (!_ui.isClosed) _ui.add(event);
  }

  void dispose() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    unawaited(_ui.close());
  }
}
