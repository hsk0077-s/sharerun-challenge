import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'package:share_run_challenge/features/profile/user_profile_notifier.dart';
import 'package:share_run_challenge/l10n/app_localizations.dart';
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
  String gender = 'male',
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
        userGenderProvider.overrideWithValue(gender),
        accessoryInventoryProvider.overrideWith((ref) => Stream.value(inventory)),
      ],
      child: MaterialApp(
        locale: const Locale('ko', 'KR'),
        supportedLocales: ShareRunLocalizations.supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
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
  testWidgets('a set is bought as one product and the server is asked once', (tester) async {
    final api = await _open(tester, 'T1S');
    expect(find.byKey(AccessoryDetailSheet.buyKey), findsOneWidget);
    await tester.tap(find.byKey(AccessoryDetailSheet.buyKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AccessoryDetailSheet.buyConfirmKey));
    await tester.pumpAndSettle();
    expect(api.calls, ['buy:T1S']);
  });

  testWidgets('a set cannot be bought when one version is already owned', (tester) async {
    await _open(tester, 'T1S', inventory: const AccessoryInventory(owned: {'T1M'}));
    expect(find.byKey(AccessoryDetailSheet.buyKey), findsNothing);
    expect(find.byKey(AccessoryDetailSheet.partOwnedKey), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byKey(AccessoryDetailSheet.partOwnedKey)).onPressed,
      isNull,
    );
  });

  testWidgets('a fully owned set shows neither buy nor wear', (tester) async {
    await _open(tester, 'T2S', inventory: const AccessoryInventory(owned: {'T2M', 'T2F'}));
    expect(find.byKey(AccessoryDetailSheet.buyKey), findsNothing);
    expect(find.byKey(AccessoryDetailSheet.wearKey), findsNothing);
    expect(find.byKey(AccessoryDetailSheet.partOwnedKey), findsNothing);
  });

  testWidgets('the matching gender version is worn in the costume slot', (tester) async {
    final api = await _open(
      tester,
      'T3F',
      gender: 'female',
      inventory: const AccessoryInventory(owned: {'T3M', 'T3F'}),
    );
    await tester.tap(find.byKey(AccessoryDetailSheet.wearKey));
    await tester.pumpAndSettle();
    expect(api.calls, ['wear:costume:T3F']);
  });

  testWidgets('the other gender version is owned but locked', (tester) async {
    final api = await _open(
      tester,
      'T3F',
      gender: 'male',
      inventory: const AccessoryInventory(owned: {'T3M', 'T3F'}),
    );
    expect(find.byKey(AccessoryDetailSheet.wearKey), findsNothing);
    expect(find.byKey(AccessoryDetailSheet.otherGenderKey), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byKey(AccessoryDetailSheet.otherGenderKey)).onPressed,
      isNull,
    );
    expect(api.calls, isEmpty);
  });

  testWidgets('a sportswear costume fits either gender', (tester) async {
    for (final gender in ['male', 'female']) {
      final api = await _open(
        tester,
        'W3C',
        gender: gender,
        inventory: const AccessoryInventory(owned: {'W3C'}),
      );
      await tester.tap(find.byKey(AccessoryDetailSheet.wearKey));
      await tester.pumpAndSettle();
      expect(api.calls, ['wear:costume:W3C'], reason: gender);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('the animal outfit is worn in the outfit slot', (tester) async {
    final api = await _open(
      tester,
      'W1A',
      inventory: const AccessoryInventory(owned: {'W1A'}),
    );
    await tester.tap(find.byKey(AccessoryDetailSheet.wearKey));
    await tester.pumpAndSettle();
    expect(api.calls, ['wear:outfit:W1A']);
  });

  testWidgets('the animal + character set is bought once and offers a try-on', (tester) async {
    final api = await _open(tester, 'W5B');
    expect(find.byKey(AccessoryDetailSheet.tryOnKey), findsOneWidget);
    await tester.tap(find.byKey(AccessoryDetailSheet.buyKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AccessoryDetailSheet.buyConfirmKey));
    await tester.pumpAndSettle();
    expect(api.calls, ['buy:W5B']);
  });

  testWidgets('a character costume has no animal try-on', (tester) async {
    await _open(tester, 'T4M');
    expect(find.byKey(AccessoryDetailSheet.tryOnKey), findsNothing);
  });
}
