import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:share_run_challenge/data/repositories/purchase_repository.dart';
import 'package:share_run_challenge/data/repositories/wallet_repository.dart';
import 'package:share_run_challenge/features/iap/models/iap_ui_event.dart';
import 'package:share_run_challenge/features/iap/models/share_iap_product.dart';
import 'package:share_run_challenge/features/iap/payment_auth.dart';
import 'package:share_run_challenge/features/iap/services/iap_purchase_controller.dart';

class _FakeIap implements InAppPurchase {
  int queries = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #purchaseStream) {
      return const Stream<List<PurchaseDetails>>.empty();
    }
    if (invocation.memberName == #isAvailable) return Future<bool>.value(true);
    if (invocation.memberName == #queryProductDetails) {
      queries++;
      return Future<ProductDetailsResponse>.value(
        ProductDetailsResponse(productDetails: [], notFoundIDs: []),
      );
    }
    return super.noSuchMethod(invocation);
  }
}

class _PurchaseRepo implements PurchaseRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _WalletRepo implements WalletRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _product = ShareIapProduct(
  productId: 'dia_pack_test',
  shareAmount: 10,
  priceKrw: 1000,
  label: 'test',
);

IapPurchaseController _controller(
  _FakeIap iap,
  Future<PaymentAuthResult> Function()? confirm,
) {
  return IapPurchaseController(
    purchaseRepository: _PurchaseRepo(),
    walletRepository: _WalletRepo(),
    readUid: () => 'u1',
    confirmPayment: confirm,
    iap: iap,
  );
}

void main() {
  test('a canceled check never reaches the store and says nothing was paid',
      () async {
    final iap = _FakeIap();
    final controller = _controller(iap, () async => PaymentAuthResult.canceled);
    final events = <IapUiEvent>[];
    controller.uiEvents.listen(events.add);

    await controller.buyConsumablePack(_product);
    await Future<void>.delayed(Duration.zero);

    expect(iap.queries, 0);
    expect(events.single.kind, IapUiKind.canceled);
    expect(events.single.message, contains('결제는 진행되지 않았어요'));
  });

  test('a phone without a screen lock is stopped with guidance', () async {
    final iap = _FakeIap();
    final controller =
        _controller(iap, () async => PaymentAuthResult.noScreenLock);
    final events = <IapUiEvent>[];
    controller.uiEvents.listen(events.add);

    await controller.buyConsumablePack(_product);
    await Future<void>.delayed(Duration.zero);

    expect(iap.queries, 0);
    expect(events.single.kind, IapUiKind.error);
    expect(events.single.message, contains('화면 잠금'));
  });

  test('an approved check lets the store lookup start', () async {
    final iap = _FakeIap();
    final controller = _controller(iap, () async => PaymentAuthResult.approved);

    await controller.buyConsumablePack(_product);

    expect(iap.queries, 1);
  });

  group('local provisioning is debug only', () {
    test('a release build never simulates a purchase', () {
      expect(
        IapPurchaseController.shouldSimulateProvision(
          mockData: true,
          localDev: true,
          debugMode: false,
        ),
        isFalse,
      );
    });

    test('a debug build simulates only with a mock or local-dev flag', () {
      expect(
        IapPurchaseController.shouldSimulateProvision(
          mockData: false,
          localDev: true,
          debugMode: true,
        ),
        isTrue,
      );
      expect(
        IapPurchaseController.shouldSimulateProvision(
          mockData: false,
          localDev: false,
          debugMode: true,
        ),
        isFalse,
      );
    });
  });
}
