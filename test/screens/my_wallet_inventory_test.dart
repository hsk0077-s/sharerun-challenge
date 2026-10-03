import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/core/auth/local_auth_session.dart';
import 'package:share_run_challenge/core/constants/economy_constants.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/data/models/user_model.dart';
import 'package:share_run_challenge/data/models/wallet_model.dart';
import 'package:share_run_challenge/data/models/wallet_transaction_model.dart';
import 'package:share_run_challenge/features/onboarding/src_onboarding_controller.dart';
import 'package:share_run_challenge/features/profile/user_profile_notifier.dart';
import 'package:share_run_challenge/features/shop/providers/server_shop_inventory_provider.dart';
import 'package:share_run_challenge/features/shop/providers/shop_tab_provider.dart';
import 'package:share_run_challenge/features/wallet/debug_local_wallet_store.dart';
import 'package:share_run_challenge/features/wallet/providers/debug_local_share_history_provider.dart';
import 'package:share_run_challenge/features/wallet/providers/wallet_provider.dart';
import 'package:share_run_challenge/screens/my_wallet_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _wallet = WalletModel(
  shareBalance: 90000,
  diamondBalance: 5,
  valueTokenBalance: 5200,
  totalDonationValue: 0,
);

class _SeededWalletNotifier extends WalletNotifier {
  @override
  WalletState build() => WalletState.fromModel(_wallet);
}

class _SeededShopNotifier extends ShopTabNotifier {
  _SeededShopNotifier(this._initial);

  final ShopTabState _initial;

  @override
  ShopTabState build() => _initial;
}

class _SeededSession extends PersistedAuthSessionNotifier {
  @override
  LocalAuthSession? build() =>
      const LocalAuthSession(uid: 'wallet-user', isGuest: false);
}

class _QuietProfile extends UserProfileNotifier {
  @override
  UserProfile build() => UserModel.dashboardDefault(uid: 'wallet-user');
}

class _SeededHistory extends DebugLocalShareHistory {
  @override
  List<DebugLocalShareTx> build() => const [
        DebugLocalShareTx(
          id: 'tx-join',
          title: '로컬에만 있는 영수증',
          amount: -30000,
          assetType: 'SHARE',
          timestampMs: 0,
        ),
      ];
}

Widget _scopedWallet({required ServerShopInventory inventory}) {
  final profile =
      UserModel.dashboardDefault(uid: 'test-wallet').copyWith(nickname: '테스트러너');
  return ProviderScope(
    overrides: [
      needsNicknameSetupProvider.overrideWith((ref) => false),
      userNicknameProvider.overrideWith((ref) => '테스트러너'),
      activeUserProfileProvider.overrideWith(
        (ref) => Stream<UserModel>.value(profile),
      ),
      activeWalletProvider.overrideWith(
        (ref) => Stream<WalletModel>.value(_wallet),
      ),
      walletProvider.overrideWith(_SeededWalletNotifier.new),
      serverShopInventoryProvider.overrideWith(
        (ref) => Stream.value(inventory),
      ),
      shopTabProvider.overrideWith(
        () => _SeededShopNotifier(const ShopTabState()),
      ),
      hasPendingJenaAppealProvider.overrideWith((ref) => false),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: SrcTheme.light,
      home: const MyWalletScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('My Wallet shows owned shop items from the server inventory',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _scopedWallet(
        inventory: const ServerShopInventory(cprCount: 1, safeGuardCount: 2),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('wallet-inventory-section')), findsOneWidget);
    expect(find.text(AppStrings.myWalletInventoryTitle), findsOneWidget);
    expect(find.text(AppStrings.itemInventoryCprTitle), findsOneWidget);
    expect(find.text(AppStrings.itemInventorySafeGuardTitle), findsOneWidget);
    expect(find.text(AppStrings.myWalletInventoryCount(1)), findsOneWidget);
    expect(find.text(AppStrings.myWalletInventoryCount(2)), findsOneWidget);
    expect(find.text(AppStrings.myWalletInventoryEmpty), findsNothing);
    expect(find.text(AppStrings.dashboardGoldBadge), findsNothing);
  });

  testWidgets('My Wallet empty inventory still lists the section',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_scopedWallet(inventory: const ServerShopInventory()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('wallet-inventory-section')), findsOneWidget);
    expect(find.text(AppStrings.myWalletInventoryEmpty), findsOneWidget);
  });

  testWidgets('My Wallet shows real grade zero and no demo receipts',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _scopedWallet(inventory: const ServerShopInventory()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.text(
        AppStrings.myWalletGradeProgress(
          0,
          EconomyConstants.trialRunsRequired,
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        AppStrings.myWalletGradeProgress(
          3,
          EconomyConstants.trialRunsRequired,
        ),
      ),
      findsNothing,
    );
    expect(find.text(AppStrings.notificationPaymentEmpty), findsOneWidget);
    expect(find.text('+500 SHARE'), findsNothing);
    expect(find.text('-100 VALUE'), findsNothing);
    expect(find.textContaining('보유 SHARE: 90,000'), findsOneWidget);
  });

  testWidgets('My Wallet recent history uses the payment ledger',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final profile = UserModel.dashboardDefault(uid: 'test-wallet')
        .copyWith(nickname: '테스트러너');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          needsNicknameSetupProvider.overrideWith((ref) => false),
          userNicknameProvider.overrideWith((ref) => '테스트러너'),
          activeUserProfileProvider.overrideWith(
            (ref) => Stream<UserModel>.value(profile),
          ),
          activeWalletProvider.overrideWith(
            (ref) => Stream<WalletModel>.value(_wallet),
          ),
          walletProvider.overrideWith(_SeededWalletNotifier.new),
          serverShopInventoryProvider.overrideWith(
            (ref) => Stream.value(const ServerShopInventory()),
          ),
          shopTabProvider.overrideWith(
            () => _SeededShopNotifier(const ShopTabState()),
          ),
          hasPendingJenaAppealProvider.overrideWith((ref) => false),
          persistedAuthSessionProvider.overrideWith(_SeededSession.new),
          userProfileProvider.overrideWith(_QuietProfile.new),
          debugLocalShareHistoryProvider.overrideWith(_SeededHistory.new),
          recentWalletTransactionsProvider.overrideWith(
            (ref) => Stream<List<WalletTransactionModel>>.value(const [
              WalletTransactionModel(
                id: 'ledger-join',
                type: 'tournament_entry',
                shareAmount: -30000,
                valueAmount: 0,
                diamondAmount: 0,
                createdAt: null,
                tournamentId: 't1',
              ),
            ]),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: SrcTheme.light,
          home: const MyWalletScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('대회 참가'), findsOneWidget);
    expect(find.text('-30000 Share'), findsOneWidget);
    expect(find.text('로컬에만 있는 영수증'), findsNothing);
    expect(find.text(AppStrings.notificationPaymentJustNow), findsOneWidget);
    expect(find.text(AppStrings.notificationPaymentReceipt), findsOneWidget);
    expect(find.text(AppStrings.notificationPaymentEmpty), findsNothing);
    expect(find.text('+500 SHARE'), findsNothing);
  });
}
