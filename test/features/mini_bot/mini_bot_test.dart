import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/app/router/route_names.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/core/widgets/src_bottom_nav.dart';
import 'package:share_run_challenge/data/models/wallet_model.dart';
import 'package:share_run_challenge/features/mini_bot/mini_bot_intent.dart';
import 'package:share_run_challenge/features/mini_bot/mini_bot_navigator.dart';
import 'package:share_run_challenge/features/mini_bot/mini_bot_sheet.dart';
import 'package:share_run_challenge/features/mini_bot/mini_bot_voice.dart';
import 'package:share_run_challenge/features/shop/providers/shop_tab_provider.dart';
import 'package:share_run_challenge/features/wallet/providers/wallet_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SeededWalletNotifier extends WalletNotifier {
  @override
  WalletState build() => WalletState.fromModel(
        const WalletModel(
          shareBalance: 0,
          diamondBalance: 0,
          valueTokenBalance: 0,
          totalDonationValue: 0,
        ),
      );
}

class _RecordingVoice implements MiniBotVoice {
  final spoken = <String>[];

  @override
  Future<void> speak(String text) async {
    spoken.add(text);
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

class _ScriptedSpeech extends MiniBotSpeechToText {
  _ScriptedSpeech(this.result);

  final String? result;

  @override
  Future<String?> listen() async => result;
}

void main() {
  test('intro is a guide and does not ask to navigate', () {
    final read = MiniBotInterpreter.interpret('쉐어런이 뭐야');
    expect(read.intent, MiniBotIntent.appIntro);
    expect(read.needsConfirm, isFalse);
    expect(read.awaitsConfirm, isFalse);
    expect(read.destination, MiniBotDestination.none);
    expect(read.reply, contains('결제나 참가 확정은 하지 않아요'));
  });

  test('join phrases recommend beginner room or lobby before any move', () {
    final beginner = MiniBotInterpreter.interpret('챌린지 참가');
    expect(beginner.intent, MiniBotIntent.joinChallenge);
    expect(beginner.destination, MiniBotDestination.beginnerRoom);
    expect(beginner.awaitsConfirm, isTrue);

    final race = MiniBotInterpreter.interpret('초보 1km 레이스');
    expect(race.destination, MiniBotDestination.beginnerRoom);

    final lobby = MiniBotInterpreter.interpret('챌린지 로비로 가');
    expect(lobby.intent, MiniBotIntent.joinChallenge);
    expect(lobby.destination, MiniBotDestination.challengeLobby);
    expect(lobby.awaitsConfirm, isTrue);
  });

  test('CPR phrase opens the store card and never claims a purchase', () {
    final read = MiniBotInterpreter.interpret('CPR 심폐소생권');
    expect(read.intent, MiniBotIntent.openCprTicket);
    expect(read.destination, MiniBotDestination.cprStore);
    expect(read.awaitsConfirm, isTrue);
    expect(read.reply, contains('결제하지 않아요'));
    expect(MiniBotCopy.executed(read.destination), contains('결제되지 않아요'));
  });

  test('unknown text stays on the guide', () {
    final read = MiniBotInterpreter.interpret('오늘 날씨 어때');
    expect(read.intent, MiniBotIntent.unknown);
    expect(read.awaitsConfirm, isFalse);
    expect(read.reply, contains('앱 소개'));
  });

  test('destinations deep-link to existing lobby, beginner room, and store', () {
    expect(
      MiniBotRoutes.location(MiniBotDestination.beginnerRoom),
      RouteNames.challengeDetailForRoom(RouteNames.beginner1kmRoomId),
    );
    expect(
      MiniBotRoutes.location(MiniBotDestination.challengeLobby),
      RouteNames.tournament,
    );
    expect(
      MiniBotRoutes.location(MiniBotDestination.cprStore),
      RouteNames.storeWithFocus(StoreFocus.items.name),
    );
    expect(MiniBotRoutes.location(MiniBotDestination.none), isNull);
  });

  testWidgets('confirm is required before a move, cancel does not execute',
      (tester) async {
    final voice = _RecordingVoice();
    MiniBotRead? executed;
    await tester.pumpWidget(
      MaterialApp(
        theme: SrcTheme.light,
        home: Scaffold(
          body: MiniBotSheet(
            voice: voice,
            onExecute: (read) => executed = read,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(voice.spoken, contains(MiniBotCopy.greeting));
    expect(find.byKey(const Key('mini-bot-confirm')), findsNothing);

    await tester.tap(find.byKey(const Key('mini-bot-chip-cpr')));
    await tester.pump();

    expect(find.text(MiniBotCopy.cpr), findsOneWidget);
    expect(executed, isNull);

    await tester.tap(find.byKey(const Key('mini-bot-cancel')));
    await tester.pump();

    expect(executed, isNull);
    expect(find.byKey(const Key('mini-bot-confirm')), findsNothing);
    expect(find.text(MiniBotCopy.cancelled), findsOneWidget);
  });

  testWidgets('confirm executes the pending intent and intro does not',
      (tester) async {
    MiniBotRead? executed;
    await tester.pumpWidget(
      MaterialApp(
        theme: SrcTheme.light,
        home: Scaffold(
          body: MiniBotSheet(
            voice: const SilentMiniBotVoice(),
            onExecute: (read) => executed = read,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('mini-bot-chip-intro')));
    await tester.pump();
    expect(find.text(MiniBotCopy.intro), findsOneWidget);
    expect(find.byKey(const Key('mini-bot-confirm')), findsNothing);
    expect(executed, isNull);

    await tester.enterText(find.byKey(const Key('mini-bot-input')), '챌린지 로비');
    await tester.tap(find.byKey(const Key('mini-bot-send')));
    await tester.pump();
    expect(find.byKey(const Key('mini-bot-confirm')), findsOneWidget);

    await tester.tap(find.byKey(const Key('mini-bot-confirm')));
    await tester.pump();

    expect(executed?.destination, MiniBotDestination.challengeLobby);
    expect(find.text(MiniBotCopy.executed(MiniBotDestination.challengeLobby)),
        findsOneWidget);
  });

  testWidgets('mic hook feeds recognized text into the same confirm path',
      (tester) async {
    MiniBotRead? executed;
    await tester.pumpWidget(
      MaterialApp(
        theme: SrcTheme.light,
        home: Scaffold(
          body: MiniBotSheet(
            voice: const SilentMiniBotVoice(),
            speech: _ScriptedSpeech('초보 1km'),
            onExecute: (read) => executed = read,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('mini-bot-mic')));
    await tester.pump();
    expect(executed, isNull);
    expect(find.text(MiniBotCopy.joinBeginner), findsOneWidget);

    await tester.tap(find.byKey(const Key('mini-bot-confirm')));
    await tester.pump();
    expect(executed?.destination, MiniBotDestination.beginnerRoom);
  });

  testWidgets('unwired mic explains that typing is the MVP input',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SrcTheme.light,
        home: const Scaffold(
          body: MiniBotSheet(voice: SilentMiniBotVoice()),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('mini-bot-mic')));
    await tester.pump();
    expect(find.text(MiniBotCopy.sttUnavailable), findsOneWidget);
    expect(find.byKey(const Key('mini-bot-confirm')), findsNothing);
  });

  testWidgets('home and lobby entry buttons open the sheet', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SrcTheme.light,
        home: const Scaffold(
          floatingActionButton: MiniBotEntryButton(
            key: Key('mini-bot-entry-home'),
            heroTag: 'mini-bot-test',
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('mini-bot-entry-home')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mini-bot-sheet')), findsOneWidget);
    expect(find.text('쉐어런 미니봇'), findsOneWidget);
    expect(find.text(MiniBotCopy.greeting), findsOneWidget);
  });

  testWidgets('tab shell shows the mic button on home and the lobby only',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    Future<void> pumpTab(String location, Key entry) async {
      final router = GoRouter(
        initialLocation: location,
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) {
              return SrcBottomNav(navigationShell: navigationShell);
            },
            branches: [
              for (final path in [
                RouteNames.mainDashboard,
                RouteNames.shop,
                RouteNames.tournament,
                RouteNames.crew,
                RouteNames.myPage,
              ])
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: path,
                      builder: (context, state) => const SizedBox.shrink(),
                    ),
                  ],
                ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            walletProvider.overrideWith(_SeededWalletNotifier.new),
            recentActivitiesProvider.overrideWith(
              (ref) => Stream.value(const []),
            ),
            authStateChangesProvider.overrideWith(
              (ref) => Stream.value(null),
            ),
          ],
          child: MaterialApp.router(
            theme: SrcTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(entry), findsOneWidget);
      expect(find.byType(MiniBotEntryButton), findsOneWidget);
    }

    await pumpTab(RouteNames.mainDashboard, const Key('mini-bot-entry-home'));
    await pumpTab(RouteNames.tournament, const Key('mini-bot-entry-lobby'));

    final router = GoRouter(
      initialLocation: RouteNames.shop,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return SrcBottomNav(navigationShell: navigationShell);
          },
          branches: [
            for (final path in [
              RouteNames.mainDashboard,
              RouteNames.shop,
              RouteNames.tournament,
              RouteNames.crew,
              RouteNames.myPage,
            ])
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: path,
                    builder: (context, state) => const SizedBox.shrink(),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletProvider.overrideWith(_SeededWalletNotifier.new),
          recentActivitiesProvider.overrideWith(
            (ref) => Stream.value(const []),
          ),
          authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: MaterialApp.router(
          theme: SrcTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MiniBotEntryButton), findsNothing);
  });
}
