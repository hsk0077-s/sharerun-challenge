import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/data/api/identity_api_client.dart';
import 'package:share_run_challenge/data/models/user_model.dart';
import 'package:share_run_challenge/features/profile/widgets/my_watch_card.dart';

Future<void> _pump(
  WidgetTester tester, {
  required WatchType watchType,
  List<ConnectedWatch> apps = const [],
}) async {
  final profile =
      UserModel.dashboardDefault(uid: 'u1').copyWith(watchType: watchType);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeUserProfileProvider
            .overrideWith((ref) => Stream<UserModel>.value(profile)),
        connectedWatchAppsProvider.overrideWith((ref) async => apps),
      ],
      child: MaterialApp(
        theme: SrcTheme.night,
        home: const Scaffold(body: MyWatchCard()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('nothing connected: invites to connect, no "none" lines',
      (tester) async {
    await _pump(tester, watchType: WatchType.none);
    expect(find.text('워치로 더 정확하게 달리기'), findsOneWidget);
    expect(find.text('연결하기'), findsOneWidget);
    expect(find.byKey(MyWatchCard.healthLineKey), findsNothing);
    expect(find.byKey(MyWatchCard.appLineKey), findsNothing);
    expect(find.textContaining('없음'), findsNothing);
  });

  testWidgets('health data only: one clear line and no "no watch" line',
      (tester) async {
    await _pump(tester, watchType: WatchType.galaxyWatch);
    expect(find.text('내 워치'), findsOneWidget);
    expect(find.text('Galaxy Watch 연결됨'), findsOneWidget);
    expect(find.text('관리'), findsOneWidget);
    expect(find.byKey(MyWatchCard.appLineKey), findsNothing);
    expect(find.textContaining('없음'), findsNothing);
  });

  testWidgets('watch app connected: shows how many', (tester) async {
    await _pump(
      tester,
      watchType: WatchType.none,
      apps: const [ConnectedWatch(id: 'w1', label: 'Galaxy Watch6')],
    );
    expect(find.text('내 워치'), findsOneWidget);
    expect(find.text('시계 앱 1대 연결됨 · Galaxy Watch6'), findsOneWidget);
    expect(find.byKey(MyWatchCard.healthLineKey), findsNothing);
  });
}
