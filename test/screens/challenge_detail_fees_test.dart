import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/router/route_names.dart';
import 'package:share_run_challenge/core/challenge/challenge_entry_fee.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/screens/challenge_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('beginner 1km room shows 30,000 SHARE fee', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: SrcTheme.light,
          home: const ChallengeDetailScreen(
            roomId: RouteNames.beginner1kmRoomId,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(AppStrings.dashboardChallenge1Sub), findsOneWidget);
    expect(find.textContaining('100,000'), findsNothing);
    expect(
      ChallengeEntryFee.forDistanceKm(1),
      ChallengeEntryFee.beginner1kmShare,
    );
  });

  testWidgets('intermediate 3km room shows 60,000 SHARE fee', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: SrcTheme.light,
          home: const ChallengeDetailScreen(
            roomId: RouteNames.intermediate3kmRoomId,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(AppStrings.challengeDetailEntryFee), findsOneWidget);
    expect(find.textContaining('30,000 SHARE'), findsNothing);
  });
}
