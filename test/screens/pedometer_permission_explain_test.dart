import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/data/models/user_model.dart';
import 'package:share_run_challenge/data/models/wallet_model.dart';
import 'package:share_run_challenge/features/onboarding/src_onboarding_controller.dart';
import 'package:share_run_challenge/features/pedometer/account_daily_steps_provider.dart';
import 'package:share_run_challenge/features/wallet/providers/wallet_provider.dart';
import 'package:share_run_challenge/screens/solo_pedometer_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../support/ko_localization.dart';

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

Widget _walking() {
  final profile = UserModel.dashboardDefault(uid: '');
  return ProviderScope(
    overrides: [
      needsNicknameSetupProvider.overrideWith((ref) => false),
      userNicknameProvider.overrideWith((ref) => '테스트워커'),
      activeUserProfileProvider.overrideWith(
        (ref) => Stream<UserModel>.value(profile),
      ),
      activeWalletProvider.overrideWith(
        (ref) => Stream<WalletModel>.value(_wallet),
      ),
      walletProvider.overrideWith(_SeededWalletNotifier.new),
      activeUserTierProvider.overrideWith((ref) => Stream<int>.value(0)),
      accountDailyStepsProvider.overrideWith((ref, dayKey) => Stream.value(0)),
    ],
    child: MaterialApp(
      locale: koTestLocale,
      supportedLocales: koTestSupportedLocales,
      localizationsDelegates: koTestDelegates,
      debugShowCheckedModeBanner: false,
      theme: SrcTheme.light,
      home: const SoloPedometerScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter.baseflow.com/permissions/methods');
  var requests = 0;

  setUp(() {
    requests = 0;
    SharedPreferences.setMockInitialValues({
      'is_pedometer_reset_v3_done': true,
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'checkPermissionStatus') return 0; // denied
      if (call.method == 'requestPermissions') {
        requests++;
        return <int, int>{};
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_walking());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('explains the permissions before the system asks',
      (tester) async {
    await open(tester);

    expect(find.text('걸음 수를 세려면 권한이 필요해요'), findsOneWidget);
    expect(requests, 0);

    await tester.tap(find.byKey(const Key('pedometer-permission-continue')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(requests, greaterThan(0));
  });

  testWidgets('"later" never opens the system permission window',
      (tester) async {
    await open(tester);

    await tester.tap(find.byKey(const Key('pedometer-permission-later')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(requests, 0);
  });
}
