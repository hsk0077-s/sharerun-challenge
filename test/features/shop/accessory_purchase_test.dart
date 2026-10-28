import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/core/api/api_exception.dart';
import 'package:share_run_challenge/core/theme/src_theme.dart';
import 'package:share_run_challenge/data/api/secured_action_api_client.dart';
import 'package:share_run_challenge/data/models/pedometer_harvest_result.dart';
import 'package:share_run_challenge/data/models/wallet_model.dart';
import 'package:share_run_challenge/features/accessories/accessory_catalog.dart';
import 'package:share_run_challenge/features/accessories/accessory_inventory.dart';
import 'package:share_run_challenge/features/crew/crew_membership.dart';
import 'package:share_run_challenge/features/onboarding/src_onboarding_controller.dart';
import 'package:share_run_challenge/features/shop/widgets/accessory_shop_grid.dart';
import 'package:share_run_challenge/features/wallet/providers/wallet_provider.dart';

class _Wallet extends WalletNotifier {
  @override
  WalletState build() => WalletState.fromModel(const WalletModel(
        shareBalance: 1000,
        diamondBalance: 500,
        valueTokenBalance: 0,
        totalDonationValue: 0,
      ));
}

class _FakeApi extends Fake implements SecuredActionApiClient {
  final calls = <String>[];
  int? failWith;

  @override
  Future<PedometerHarvestResult> purchaseAccessory(String itemId) async {
    calls.add('buy:$itemId');
    if (failWith != null) {
      throw ApiException(statusCode: failWith!, detail: 'x');
    }
    return const PedometerHarvestResult(
      status: 'purchased',
      shareBalance: 1000,
      diamondBalance: 460,
      valueTokenBalance: 0,
    );
  }

  @override
  Future<void> equipAccessory({required String slot, required String itemId}) async {
    calls.add('wear:$slot:$itemId');
  }
}

Accessory _byId(String id) => accessoryCatalog.firstWhere((a) => a.id == id);

Future<_FakeApi> _open(
  WidgetTester tester,
  String id, {
  AccessoryInventory inventory = const AccessoryInventory(),
  UserTier tier = UserTier.unratedFallback,
  _FakeApi? api,
}) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final fake = api ?? _FakeApi();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        walletProvider.overrideWith(_Wallet.new),
        crewApiProvider.overrideWithValue(fake),
        accessoryInventoryProvider.overrideWith((ref) => Stream.value(inventory)),
      ],
      child: MaterialApp(
        theme: SrcTheme.night,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => AccessoryDetailSheet.show(
                context,
                accessory: _byId(id),
                animal: TierAnimal.wolf,
                tier: tier,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return fake;
}

void main() {
  testWidgets('buying asks first, then charges once through the server',
      (tester) async {
    final api = await _open(tester, 'P004');
    await tester.tap(find.byKey(AccessoryDetailSheet.buyKey));
    await tester.pumpAndSettle();
    expect(api.calls, isEmpty);
    final code = Localizations.localeOf(
      tester.element(find.byKey(AccessoryDetailSheet.buyConfirmKey)),
    ).languageCode;
    expect(
      find.textContaining(
        code == 'ko' ? '보너스 DIA가 있으면 먼저' : 'Bonus DIA is spent first',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(AccessoryDetailSheet.buyConfirmKey));
    await tester.pumpAndSettle();
    expect(api.calls, ['buy:P004']);
  });

  testWidgets('cancelling the question buys nothing', (tester) async {
    final api = await _open(tester, 'P004');
    await tester.tap(find.byKey(AccessoryDetailSheet.buyKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(api.calls, isEmpty);
  });

  testWidgets('a short balance is explained, not silently ignored',
      (tester) async {
    final api = _FakeApi()..failWith = 400;
    await _open(tester, 'P004', api: api);
    await tester.tap(find.byKey(AccessoryDetailSheet.buyKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AccessoryDetailSheet.buyConfirmKey));
    await tester.pumpAndSettle();
    expect(find.textContaining('모자라거나 이미 가진'), findsOneWidget);
  });

  testWidgets('an owned item is worn and taken off, not bought again',
      (tester) async {
    final api = await _open(
      tester,
      'P004',
      inventory: const AccessoryInventory(owned: {'P004'}),
    );
    expect(find.byKey(AccessoryDetailSheet.buyKey), findsNothing);
    expect(find.text('입기'), findsOneWidget);
    await tester.tap(find.byKey(AccessoryDetailSheet.wearKey));
    await tester.pumpAndSettle();
    expect(api.calls, ['wear:head:P004']);
  });

  testWidgets('a worn item offers to take it off', (tester) async {
    final api = await _open(
      tester,
      'P004',
      inventory: const AccessoryInventory(
        owned: {'P004'},
        worn: {'head': 'P004'},
      ),
    );
    expect(find.text('벗기'), findsOneWidget);
    await tester.tap(find.byKey(AccessoryDetailSheet.wearKey));
    await tester.pumpAndSettle();
    expect(api.calls, ['wear:head:']);
  });

  testWidgets('a master skin is locked below its tier', (tester) async {
    final api = await _open(tester, 'S003');
    expect(find.byKey(AccessoryDetailSheet.buyKey), findsNothing);
    expect(find.textContaining('티어가 되면 살 수 있어요'), findsOneWidget);
    expect(api.calls, isEmpty);
  });

  testWidgets('the tier-reward laurel is not for sale', (tester) async {
    await _open(tester, 'P015');
    expect(find.byKey(AccessoryDetailSheet.buyKey), findsNothing);
    expect(find.text('티어 보상이에요'), findsOneWidget);
  });

  test('inventory parsing reads owned items and the worn slots', () {
    final inv = AccessoryInventory.fromDocs({
      'P004': {'category': 'accessory', 'quantity': 1},
      'record_cpr_ticket': {'quantity': 3},
      'S001': {'category': 'accessory', 'quantity': 0},
      'accessory_loadout': {
        'slots': {'head': 'P004', 'eyes': ''},
      },
    });
    expect(inv.owned, {'P004'});
    expect(inv.worn, {'head': 'P004'});
    expect(inv.isWorn('P004'), isTrue);
  });
}
