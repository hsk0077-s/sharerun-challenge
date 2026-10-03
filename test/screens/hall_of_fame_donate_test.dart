import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/data/models/user_model.dart';
import 'package:share_run_challenge/features/onboarding/src_onboarding_controller.dart';
import 'package:share_run_challenge/core/api/api_exception.dart';
import 'package:share_run_challenge/data/models/pedometer_harvest_result.dart';
import 'package:share_run_challenge/features/profile/user_profile_notifier.dart';
import 'package:share_run_challenge/features/wallet/hall_of_fame_donate.dart';
import 'package:share_run_challenge/features/wallet/providers/wallet_provider.dart';
import 'package:share_run_challenge/screens/hall_of_fame_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SpyWallet extends WalletNotifier {
  @override
  WalletState build() => WalletState(valueBalance: _initialValue);

  @override
  void creditValue(int amount) {
    _creditCalls++;
    state = state.copyWith(valueBalance: state.valueBalance + amount);
  }

  @override
  void debitValue(int amount) {
    if (amount <= 0) return;
    _debited += amount;
    state = state.copyWith(
      valueBalance: (state.valueBalance - amount).clamp(0, 1 << 31),
    );
  }
}

class _QuietProfile extends UserProfileNotifier {
  @override
  UserProfile build() => UserModel.dashboardDefault(uid: '');
}

int _initialValue = 0;
int _creditCalls = 0;
int _debited = 0;
int _donateCalls = 0;
late Completer<PedometerHarvestResult> _donateGate;

Widget _screen() {
  return ProviderScope(
    overrides: [
      walletProvider.overrideWith(_SpyWallet.new),
      userProfileNotifierProvider.overrideWith(_QuietProfile.new),
      userNicknameProvider.overrideWith((ref) => ''),
      hallOfFameDonateProvider.overrideWith((ref) {
        return () {
          _donateCalls++;
          return _donateGate.future;
        };
      }),
    ],
    child: MaterialApp(
      theme: SrcTheme.light,
      home: const HallOfFameScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _initialValue = 0;
    _creditCalls = 0;
    _debited = 0;
    _donateCalls = 0;
    _donateGate = Completer<PedometerHarvestResult>();
  });

  testWidgets('empty leaderboard and insufficient VALUE does not mint',
      (tester) async {
    _donateGate.completeError(
      const ApiException(statusCode: 400, detail: 'Insufficient SRV (Value Token) balance.'),
    );
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_screen());
    await tester.pump();

    expect(find.text('아직 기록이 없어요'), findsOneWidget);
    expect(find.text(AppStrings.hallOfFameLeaderName), findsNothing);
    expect(find.text(AppStrings.hallOfFameLeaderDonation), findsNothing);
    expect(find.text(AppStrings.hallOfFameRank2Value), findsNothing);
    expect(find.text(AppStrings.hallOfFameRank3Value), findsNothing);

    await tester.tap(find.text(AppStrings.hallOfFameDonateCta));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('VALUE가 부족합니다.'), findsOneWidget);
    expect(_creditCalls, 0);
    expect(_debited, 0);
    expect(_donateCalls, 1);
  });

  testWidgets('enough VALUE debits once and does not claim a ranking',
      (tester) async {
    _initialValue = 1000;
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_screen());
    await tester.pump();

    final button = find.text(AppStrings.hallOfFameDonateCta);
    await tester.tap(button);
    await tester.pump();
    await tester.tap(button);
    await tester.pump();

    expect(_creditCalls, 0);
    expect(_debited, 0);
    expect(_donateCalls, 1);

    _donateGate.complete(
      const PedometerHarvestResult(
        status: 'donated',
        valueTokenBalance: 500,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('서버 원장에서 500 VALUE를 기부했습니다'), findsOneWidget);
    expect(find.textContaining('잔액 500'), findsOneWidget);
    expect(find.textContaining('이 기기에서'), findsNothing);
    expect(find.textContaining('기부 완료'), findsNothing);
  });
}
