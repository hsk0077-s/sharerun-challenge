import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';
import 'package:share_run_challenge/core/theme/src_theme.dart';
import 'package:share_run_challenge/data/models/wallet_model.dart';
import 'package:share_run_challenge/features/crew/crew_membership.dart';
import 'package:share_run_challenge/features/wallet/providers/wallet_provider.dart';
import 'package:share_run_challenge/screens/running_crew_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _wallet = WalletModel(
  shareBalance: 90000,
  diamondBalance: 5,
  valueTokenBalance: 100,
  totalDonationValue: 0,
);

class _SeededWalletNotifier extends WalletNotifier {
  @override
  WalletState build() => WalletState.fromModel(_wallet);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('the sample crew is not shown while my crew is loading',
      (tester) async {
    final reply = Completer<MyCrew?>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletProvider.overrideWith(_SeededWalletNotifier.new),
          recentActivitiesProvider
              .overrideWith((ref) => Stream.value(const [])),
          authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
          myCrewProvider.overrideWith((ref) => reply.future),
        ],
        child: MaterialApp(
          theme: SrcTheme.light,
          home: const RunningCrewScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(AppStrings.runningCrewMyCrewName), findsNothing);
    expect(find.text('45/50'), findsNothing);
    expect(find.text('3,240km'), findsNothing);

    // The server answers: no crew yet, so the sample shows as before.
    reply.complete(null);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.runningCrewMyCrewName), findsOneWidget);
    expect(find.text('45/50'), findsOneWidget);
  });
}
