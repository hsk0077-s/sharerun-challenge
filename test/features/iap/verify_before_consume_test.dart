import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:share_run_challenge/data/repositories/purchase_repository.dart';
import 'package:share_run_challenge/data/repositories/wallet_repository.dart';
import 'package:share_run_challenge/features/iap/models/iap_ui_event.dart';
import 'package:share_run_challenge/features/iap/services/iap_purchase_controller.dart';

class _FakeIap implements InAppPurchase {
  final stream = StreamController<List<PurchaseDetails>>.broadcast();
  final completed = <String>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #purchaseStream) return stream.stream;
    if (invocation.memberName == #isAvailable) return Future<bool>.value(true);
    if (invocation.memberName == #completePurchase) {
      completed.add(
        (invocation.positionalArguments.single as PurchaseDetails).productID,
      );
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

class _PurchaseRepo implements PurchaseRepository {
  _PurchaseRepo(this.statuses, {this.enqueueFails = false});

  final Stream<String?> statuses;
  final bool enqueueFails;

  @override
  Future<String> enqueuePendingReceipt({
    required String userId,
    required String productId,
    required int shareAmount,
    required String purchaseId,
    required String serverVerificationData,
    required String localVerificationData,
    required String source,
  }) async {
    if (enqueueFails) throw StateError('offline');
    return 'doc1';
  }

  @override
  Stream<String?> watchStatus(String purchaseDocId) => statuses;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _WalletRepo implements WalletRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PurchaseDetails _purchase() {
  return PurchaseDetails(
    purchaseID: 'GPA.1',
    productID: 'dia_pack_test',
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local',
      serverVerificationData: 'token',
      source: 'google_play',
    ),
    transactionDate: null,
    status: PurchaseStatus.purchased,
  )..pendingCompletePurchase = true;
}

void main() {
  late _FakeIap iap;
  late StreamController<String?> statuses;
  late List<IapUiEvent> events;

  IapPurchaseController build({bool enqueueFails = false}) {
    final controller = IapPurchaseController(
      purchaseRepository:
          _PurchaseRepo(statuses.stream, enqueueFails: enqueueFails),
      walletRepository: _WalletRepo(),
      readUid: () => 'u1',
      iap: iap,
      simulateProvision: false,
    );
    controller.uiEvents.listen(events.add);
    return controller;
  }

  setUp(() {
    iap = _FakeIap();
    statuses = StreamController<String?>();
    events = [];
  });

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

  test('a purchase is not consumed while the server has not confirmed it',
      () async {
    build();
    iap.stream.add([_purchase()]);
    await settle();
    statuses.add(PurchaseRepository.pendingVerify);
    await settle();

    expect(iap.completed, isEmpty);
    expect(events.map((e) => e.kind), contains(IapUiKind.verifying));
  });

  test('a verified purchase is consumed only after the server says verified',
      () async {
    build();
    iap.stream.add([_purchase()]);
    await settle();
    expect(iap.completed, isEmpty);

    statuses.add(PurchaseRepository.verified);
    await settle();

    expect(iap.completed, ['dia_pack_test']);
    expect(events.last.kind, IapUiKind.verified);
  });

  test('a rejected purchase is consumed so it does not come back forever',
      () async {
    build();
    iap.stream.add([_purchase()]);
    await settle();
    statuses.add(PurchaseRepository.rejected);
    await settle();

    expect(iap.completed, ['dia_pack_test']);
    expect(events.last.kind, IapUiKind.error);
  });

  test('a purchase the server could not take yet is left for Play to redeliver',
      () async {
    build(enqueueFails: true);
    iap.stream.add([_purchase()]);
    await settle();

    expect(iap.completed, isEmpty);
    expect(events.last.kind, IapUiKind.error);
  });

  test('the account binding is the sha256 hex of the uid', () {
    final id = IapPurchaseController.accountBindingId('u1');
    expect(id, hasLength(64));
    expect(id, IapPurchaseController.accountBindingId('u1'));
    expect(id, isNot(IapPurchaseController.accountBindingId('u2')));
  });
}
