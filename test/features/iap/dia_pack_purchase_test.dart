import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:share_run_challenge/data/repositories/purchase_repository.dart';
import 'package:share_run_challenge/data/repositories/wallet_repository.dart';
import 'package:share_run_challenge/features/iap/models/dia_pack_product.dart';
import 'package:share_run_challenge/features/iap/models/iap_ui_event.dart';
import 'package:share_run_challenge/features/iap/services/iap_purchase_controller.dart';

class _FakeIap implements InAppPurchase {
  final stream = StreamController<List<PurchaseDetails>>.broadcast();
  final completed = <String>[];
  final buys = <({String id, bool autoConsume})>[];
  bool available = true;
  bool launch = true;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #purchaseStream) return stream.stream;
    if (invocation.memberName == #isAvailable) {
      return Future<bool>.value(available);
    }
    if (invocation.memberName == #completePurchase) {
      completed.add(
        (invocation.positionalArguments.single as PurchaseDetails).productID,
      );
      return Future<void>.value();
    }
    if (invocation.memberName == #queryProductDetails) {
      final ids = invocation.positionalArguments.single as Set<String>;
      return Future<ProductDetailsResponse>.value(
        ProductDetailsResponse(
          productDetails: [
            for (final id in ids)
              ProductDetails(
                id: id,
                title: id,
                description: id,
                price: '₩$id',
                rawPrice: 1,
                currencyCode: 'KRW',
              ),
          ],
          notFoundIDs: const [],
        ),
      );
    }
    if (invocation.memberName == #buyConsumable) {
      final param = invocation.positionalArguments.isNotEmpty
          ? invocation.positionalArguments.first
          : invocation.namedArguments[#purchaseParam];
      final details = (param as PurchaseParam).productDetails;
      final auto = invocation.namedArguments[#autoConsume] as bool? ?? true;
      buys.add((id: details.id, autoConsume: auto));
      return Future<bool>.value(launch);
    }
    if (invocation.memberName == #restorePurchases) {
      return Future<void>.value();
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

PurchaseDetails _purchase({
  String productId = 'dia_pack_130',
  PurchaseStatus status = PurchaseStatus.purchased,
  String token = 'play-token-130',
}) {
  return PurchaseDetails(
    purchaseID: 'GPA.1',
    productID: productId,
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local',
      serverVerificationData: token,
      source: 'google_play',
    ),
    transactionDate: null,
    status: status,
  )..pendingCompletePurchase = true;
}

void main() {
  late _FakeIap iap;
  late List<IapUiEvent> events;
  late List<({String productId, String token})> grants;
  bool grantOk = true;
  bool grantThrows = false;

  IapPurchaseController build() {
    final controller = IapPurchaseController(
      purchaseRepository: _PurchaseRepo(),
      walletRepository: _WalletRepo(),
      readUid: () => 'u1',
      iap: iap,
      simulateProvision: false,
      onDiaPackPurchased: (productId, token) async {
        grants.add((productId: productId, token: token));
        if (grantThrows) throw StateError('offline');
        return grantOk;
      },
    );
    controller.uiEvents.listen(events.add);
    return controller;
  }

  setUp(() {
    iap = _FakeIap();
    events = [];
    grants = [];
    grantOk = true;
    grantThrows = false;
  });

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

  test('catalog ids and prices match the Play products', () {
    expect(
      DiaPackProduct.catalog.map((pack) => pack.productId),
      DiaPackProduct.productIds,
    );
    expect(
      DiaPackProduct.catalog.map((pack) => pack.priceKrw).toList(),
      [1200, 5900, 12000, 33000, 59000, 119000],
    );
    expect(DiaPackProduct.byProductId('dia_pack_60')?.totalDia, 60);
    expect(DiaPackProduct.isDiaPackId('share_pack_1000'), isFalse);
  });

  test('a DIA pack is bought as a consumable that the plugin does not consume',
      () async {
    final controller = build();
    await controller.buyDiaPack(DiaPackProduct.catalog[2]);
    expect(iap.buys, [(id: 'dia_pack_130', autoConsume: false)]);
  });

  test('a purchase is not consumed until the server grants it', () async {
    build();
    iap.stream.add([_purchase()]);
    await settle();
    expect(grants, [(productId: 'dia_pack_130', token: 'play-token-130')]);
    expect(iap.completed, ['dia_pack_130']);
    expect(events.last.kind, IapUiKind.verified);
  });

  test('a refused grant is left for Play to deliver again', () async {
    grantOk = false;
    build();
    iap.stream.add([_purchase()]);
    await settle();
    expect(iap.completed, isEmpty);
    expect(events.last.kind, IapUiKind.error);
  });

  test('a grant that throws is not consumed', () async {
    grantThrows = true;
    build();
    iap.stream.add([_purchase()]);
    await settle();
    expect(iap.completed, isEmpty);
    expect(events.last.kind, IapUiKind.error);
  });

  test('pending, canceled, and error do not call the grant', () async {
    build();
    iap.stream.add([_purchase(status: PurchaseStatus.pending)]);
    await settle();
    expect(grants, isEmpty);
    expect(iap.completed, isEmpty);
    expect(events.last.kind, IapUiKind.pending);

    iap.stream.add([_purchase(status: PurchaseStatus.canceled)]);
    await settle();
    expect(events.last.kind, IapUiKind.canceled);
    expect(iap.completed, ['dia_pack_130']);

    iap.stream.add([_purchase(status: PurchaseStatus.error)]);
    await settle();
    expect(events.last.kind, IapUiKind.error);
    expect(grants, isEmpty);
  });

  test('a restored unfinished pack is granted and then consumed', () async {
    build();
    iap.stream.add([
      _purchase(status: PurchaseStatus.restored, productId: 'dia_pack_12'),
    ]);
    await settle();
    expect(grants.single.productId, 'dia_pack_12');
    expect(iap.completed, ['dia_pack_12']);
  });

  test('a restored SHARE pack is not sent to the DIA grant', () async {
    build();
    iap.stream.add([
      _purchase(status: PurchaseStatus.restored, productId: 'share_pack_1000'),
    ]);
    await settle();
    expect(grants, isEmpty);
    expect(iap.completed, isEmpty);
  });
}
