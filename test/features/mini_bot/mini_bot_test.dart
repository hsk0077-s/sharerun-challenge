import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/app/router/route_names.dart';
import 'package:share_run_challenge/core/config/app_env.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/core/widgets/src_bottom_nav.dart';
import 'package:share_run_challenge/core/widgets/src_dashboard_bottom_nav.dart';
import 'package:share_run_challenge/data/models/company_tournament_config.dart';
import 'package:share_run_challenge/data/models/wallet_model.dart';
import 'package:share_run_challenge/features/mini_bot/mini_bot_dock.dart';
import 'package:share_run_challenge/features/mini_bot/mini_bot_intent.dart';
import 'package:share_run_challenge/features/mini_bot/mini_bot_navigator.dart';
import 'package:share_run_challenge/features/mini_bot/mini_bot_sheet.dart';
import 'package:share_run_challenge/features/mini_bot/mini_bot_voice.dart';
import 'package:share_run_challenge/features/shop/providers/shop_tab_provider.dart';
import 'package:share_run_challenge/features/wallet/providers/wallet_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/ko_localization.dart';

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

  final MiniBotListen result;

  @override
  Future<MiniBotListen> listen() async => result;
}

class _GateSpeech extends MiniBotSpeechToText {
  final gate = Completer<MiniBotListen>();

  @override
  Future<MiniBotListen> listen() => gate.future;

  @override
  Future<void> stop() async {
    if (!gate.isCompleted) gate.complete(const MiniBotListen.cancelled());
  }
}

void main() {
  bubbleTests();
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

  test('destinations deep-link to existing lobby, beginner room, and store',
      () {
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
    expect(
      MiniBotRoutes.location(MiniBotDestination.safeGuardStore),
      RouteNames.storeWithFocus(StoreFocus.items.name),
    );
    expect(
      MiniBotRoutes.location(MiniBotDestination.donateStore),
      RouteNames.storeWithFocus(StoreFocus.donate.name),
    );
    expect(
      MiniBotRoutes.location(MiniBotDestination.shareCharge),
      RouteNames.inAppBilling,
    );
    expect(
      MiniBotRoutes.location(MiniBotDestination.personalSponsor),
      isNull,
    );
    expect(
      MiniBotRoutes.location(MiniBotDestination.brandSponsor),
      isNull,
    );
    expect(
      MiniBotRoutes.location(MiniBotDestination.subscription),
      isNull,
    );
    expect(MiniBotRoutes.location(MiniBotDestination.coachPlus), isNull);
    expect(
      MiniBotRoutes.location(MiniBotDestination.battlePass),
      RouteNames.battlePass,
    );
    expect(MiniBotRoutes.location(MiniBotDestination.none), isNull);

    AppEnv.debugInAppPurchasesOverride = true;
    addTearDown(() => AppEnv.debugInAppPurchasesOverride = null);
    expect(
      MiniBotRoutes.location(MiniBotDestination.personalSponsor),
      RouteNames.personalSponsor,
    );
    expect(
      MiniBotRoutes.location(MiniBotDestination.subscription),
      RouteNames.subscriptionManagement,
    );
    AppEnv.debugInAppPurchasesOverride = null;
  });

  test('spend phrases recommend an existing screen and wait for a tap', () {
    final donate = MiniBotInterpreter.interpret('후원');
    expect(donate.intent, MiniBotIntent.donate);
    expect(donate.destination, MiniBotDestination.donateStore);
    expect(donate.awaitsConfirm, isTrue);
    expect(donate.confirmLabel, '후원하기');
    expect(donate.amountLabel, '500 VALUE');
    expect(donate.reply, contains('기부가 끝나지 않아요'));

    final guard = MiniBotInterpreter.interpret('세이프 가드');
    expect(guard.destination, MiniBotDestination.safeGuardStore);
    expect(guard.confirmLabel, '구매하기');
    expect(guard.amountLabel, '30 DIA');

    final charge = MiniBotInterpreter.interpret('SHARE 충전');
    expect(charge.destination, MiniBotDestination.shareCharge);
    expect(charge.confirmLabel, '교환하기');
    expect(charge.amountLabel, contains('1,200 SHARE'));
    expect(charge.reply, contains('결제되지 않아요'));

    final join = MiniBotInterpreter.interpret('챌린지 참가');
    expect(join.destination, MiniBotDestination.beginnerRoom);
    expect(join.confirmLabel, '참가하기');
    expect(join.amountLabel, '600 SHARE');
    expect(join.reply, contains('참가는 확정되지 않아요'));

    const prize = CompanyTournamentConfig(
      tiers: {
        'beginner': CompanyTournamentTier(entryShare: 300, freeTicketCost: 1),
        'mid': CompanyTournamentTier(entryShare: 1200, freeTicketCost: 1),
        'advanced': CompanyTournamentTier(entryShare: 2400, freeTicketCost: 2),
        'half': CompanyTournamentTier(entryShare: 4200, freeTicketCost: 3),
      },
      weeklyLimitLabelKo: '같은 등급은 일주일에 1번만 참가할 수 있어요.',
    );
    final race = MiniBotInterpreter.interpret('상금 대회', prizeConfig: prize);
    expect(race.destination, MiniBotDestination.challengeLobby);
    expect(race.reply, contains('300 SHARE'));
    expect(race.reply, contains('1,200 SHARE'));
    expect(race.reply, contains('2,400 SHARE'));
    expect(race.reply, contains('4,200 SHARE'));
    expect(race.reply, contains('일주일에 1번'));
    expect(race.reply, isNot(contains('첫 2회 무료')));

    final free = MiniBotInterpreter.interpret(
      '상금',
      prizeConfig: const CompanyTournamentConfig(
        tiers: {
          'beginner': CompanyTournamentTier(entryShare: 300, freeTicketCost: 1),
        },
        beginnerFreeEntryEligible: true,
        freeEntryLabelKo: '첫 2회 무료',
      ),
    );
    expect(free.reply, contains('첫 2회 무료'));

    final pending = MiniBotInterpreter.interpret('상금 대회');
    expect(pending.reply, contains('확인 중'));
    expect(pending.reply, isNot(contains('600 SHARE')));

    final runner = MiniBotInterpreter.interpret('러너 후원');
    expect(runner.intent, MiniBotIntent.sponsorRunner);
    expect(runner.destination, MiniBotDestination.personalSponsor);
    expect(runner.confirmLabel, '후원하기');
    expect(runner.amountLabel, '50,000 SHARE');
    expect(runner.reply, contains('후원이 끝나지 않아요'));

    final sponsor = MiniBotInterpreter.interpret('스폰서');
    expect(sponsor.intent, MiniBotIntent.brandSponsor);
    // 실제 스폰서가 없어서 이동 없이 "준비 중"이라고만 답한다.
    expect(sponsor.destination, MiniBotDestination.none);
    expect(sponsor.awaitsConfirm, isFalse);
    expect(sponsor.reply, contains('준비 중'));

    final subscription = MiniBotInterpreter.interpret('정기 후원');
    expect(subscription.destination, MiniBotDestination.subscription);
    expect(subscription.confirmLabel, '이동하기');
    expect(subscription.reply, contains('바꾸지 않아요'));

    for (final phrase in [
      '코치',
      'Coach+',
      '심박 코칭',
      '코칭',
      '심박',
      'coach',
      '구독 코치',
    ]) {
      final coach = MiniBotInterpreter.interpret(phrase);
      expect(coach.intent, MiniBotIntent.coachPlus, reason: phrase);
      expect(coach.destination, MiniBotDestination.coachPlus, reason: phrase);
      expect(coach.awaitsConfirm, isTrue, reason: phrase);
      expect(coach.confirmLabel, '이동하기', reason: phrase);
      expect(coach.reply, contains('결제하지 않아요'), reason: phrase);
      expect(
        MiniBotCopy.executed(coach.destination),
        contains('결제되지 않아요'),
        reason: phrase,
      );
    }
    expect(
      MiniBotInterpreter.interpret('구독').destination,
      MiniBotDestination.subscription,
    );

    final pass = MiniBotInterpreter.interpret('배틀패스');
    expect(pass.destination, MiniBotDestination.battlePass);
    expect(pass.reply, contains('구매하지 않아요'));

    final brand = MiniBotInterpreter.interpret('브랜드 스폰서');
    expect(brand.destination, MiniBotDestination.none);
    expect(brand.awaitsConfirm, isFalse);
    expect(brand.reply, contains('준비 중'));
  });

  test('chip labels use the same interpreter as typed text', () {
    expect(
      MiniBotPrompts.chips.map((chip) => chip.label).toList(),
      [
        '앱 소개',
        '챌린지 로비',
        '후원',
        '스폰서',
        '러너 후원',
        '챌린지 참가',
        '다이아 교환',
        '심폐소생권',
        '세이프가드',
        '구독',
        'Coach+',
        '배틀패스',
      ],
    );
    for (final chip in MiniBotPrompts.chips) {
      final read = MiniBotInterpreter.interpret(chip.label);
      if (chip.id == 'brand') {
        expect(read.destination, MiniBotDestination.none);
        expect(read.reply, contains('준비 중'));
      }
      if (chip.id == 'runner') {
        expect(read.destination, MiniBotDestination.personalSponsor);
      }
      // 소개와 준비 중 안내는 이동하지 않으므로 확인 단계가 없다.
      if (chip.id == 'intro' || chip.id == 'brand') {
        expect(read.awaitsConfirm, isFalse);
      } else {
        expect(read.awaitsConfirm, isTrue, reason: chip.label);
      }
      expect(
        MiniBotCopy.executed(read.destination),
        isNot(contains('완료')),
        reason: chip.label,
      );
    }
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

    final cprChip = find.byKey(const Key('mini-bot-chip-cpr'));
    await tester.scrollUntilVisible(
      cprChip,
      160,
      scrollable: find.descendant(
        of: find.byKey(const Key('mini-bot-chips')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(cprChip);
    await tester.pump();

    expect(find.text(MiniBotCopy.cpr), findsOneWidget);
    expect(find.text('구매하기'), findsOneWidget);
    expect(find.text('30 DIA'), findsOneWidget);
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

    final introChip = find.byKey(const Key('mini-bot-chip-intro'));
    await tester.scrollUntilVisible(
      introChip,
      160,
      scrollable: find.descendant(
        of: find.byKey(const Key('mini-bot-chips')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(introChip);
    await tester.pump();
    expect(find.text(MiniBotCopy.intro), findsOneWidget);
    expect(find.byKey(const Key('mini-bot-confirm')), findsNothing);
    expect(executed, isNull);

    await tester.enterText(find.byKey(const Key('mini-bot-input')), '챌린지 로비');
    await tester.tap(find.byKey(const Key('mini-bot-send')));
    await tester.pump();
    expect(find.byKey(const Key('mini-bot-confirm')), findsOneWidget);
    expect(find.text('이동하기'), findsOneWidget);

    await tester.tap(find.byKey(const Key('mini-bot-confirm')));
    await tester.pump();

    expect(executed?.destination, MiniBotDestination.challengeLobby);
    final executedText =
        MiniBotCopy.executed(MiniBotDestination.challengeLobby);
    await tester.scrollUntilVisible(
      find.text(executedText),
      48,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('mini-bot-sheet')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text(executedText), findsOneWidget);
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
            speech: _ScriptedSpeech(const MiniBotListen.heard('초보 1km')),
            onExecute: (read) => executed = read,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('mini-bot-mic')));
    await tester.pump();
    expect(executed, isNull);
    expect(find.text('초보 1km'), findsOneWidget);
    expect(find.text(MiniBotCopy.joinBeginner), findsOneWidget);

    await tester.tap(find.byKey(const Key('mini-bot-confirm')));
    await tester.pump();
    expect(executed?.destination, MiniBotDestination.beginnerRoom);
  });

  testWidgets('speech errors stay on the guide and keep typing',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SrcTheme.light,
        home: Scaffold(
          body: MiniBotSheet(
            voice: const SilentMiniBotVoice(),
            speech: _ScriptedSpeech(const MiniBotListen.denied()),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('mini-bot-mic')));
    await tester.pump();
    expect(find.text(MiniBotCopy.micDenied), findsOneWidget);
    expect(find.byKey(const Key('mini-bot-confirm')), findsNothing);

    await tester.enterText(find.byKey(const Key('mini-bot-input')), '앱 소개');
    await tester.tap(find.byKey(const Key('mini-bot-send')));
    await tester.pump();
    expect(find.text(MiniBotCopy.intro), findsOneWidget);
    expect(find.byKey(const Key('mini-bot-confirm')), findsNothing);

    await tester.tap(find.byKey(const Key('mini-bot-chip-join')));
    await tester.pumpAndSettle();
    expect(find.text(MiniBotCopy.joinBeginner), findsOneWidget);
    expect(find.byKey(const Key('mini-bot-confirm')), findsOneWidget);
  });

  testWidgets('empty or missing speech does not navigate', (tester) async {
    Future<void> pump(MiniBotListen result) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SrcTheme.light,
          home: Scaffold(
            body: MiniBotSheet(
              key: UniqueKey(),
              voice: const SilentMiniBotVoice(),
              speech: _ScriptedSpeech(result),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('mini-bot-mic')));
      await tester.pump();
    }

    await pump(const MiniBotListen.empty());
    expect(find.text(MiniBotCopy.sttEmpty), findsOneWidget);
    expect(find.byKey(const Key('mini-bot-confirm')), findsNothing);

    await pump(const MiniBotListen.unavailable());
    expect(find.text(MiniBotCopy.sttUnavailable), findsOneWidget);
    expect(find.byKey(const Key('mini-bot-input')), findsOneWidget);
    expect(find.byKey(const Key('mini-bot-confirm')), findsNothing);
  });

  testWidgets('spoken intro stays a guide and cancel keeps the sheet',
      (tester) async {
    MiniBotRead? executed;
    final speech = _GateSpeech();
    await tester.pumpWidget(
      MaterialApp(
        theme: SrcTheme.light,
        home: Scaffold(
          body: MiniBotSheet(
            voice: const SilentMiniBotVoice(),
            speech: speech,
            onExecute: (read) => executed = read,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('mini-bot-mic')));
    await tester.pump();
    expect(find.byKey(const Key('mini-bot-listening')), findsOneWidget);
    expect(find.text(MiniBotCopy.listening), findsOneWidget);
    expect(executed, isNull);

    speech.gate.complete(const MiniBotListen.heard('앱 소개'));
    await tester.pump();
    expect(find.text(MiniBotCopy.intro), findsOneWidget);
    expect(find.byKey(const Key('mini-bot-confirm')), findsNothing);
    expect(find.byKey(const Key('mini-bot-listening')), findsNothing);

    await tester.enterText(find.byKey(const Key('mini-bot-input')), '챌린지 로비');
    await tester.tap(find.byKey(const Key('mini-bot-send')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mini-bot-cancel')));
    await tester.pumpAndSettle();
    expect(executed, isNull);
    expect(find.text(MiniBotCopy.cancelled), findsOneWidget);
    expect(find.byKey(const Key('mini-bot-sheet')), findsOneWidget);
  });

  test('korean locale prefers an installed ko id', () {
    expect(miniBotKoreanLocaleId(['en_US', 'ko_KR']), 'ko_KR');
    expect(miniBotKoreanLocaleId(['en_US', 'ko-KR']), 'ko-KR');
    expect(miniBotKoreanLocaleId(['en_US', 'ja_JP']), 'ko_KR');
  });

  test('missing recognizer does not throw and stays off the navigate path',
      () async {
    final heard = await MiniBotSpeechToTextHook().listen().timeout(
          const Duration(seconds: 3),
        );
    expect(heard.kind, isNot(MiniBotListenKind.heard));
    expect(
      heard.kind,
      anyOf(
        MiniBotListenKind.unavailable,
        MiniBotListenKind.denied,
        MiniBotListenKind.empty,
      ),
    );
  });

  test('speech errors map to deny, silence, or unavailable', () {
    expect(
      MiniBotSpeechToTextHook.failureFor('error_permission').kind,
      MiniBotListenKind.denied,
    );
    expect(
      MiniBotSpeechToTextHook.failureFor(
        'error_speech_recognizer_request_not_authorized',
      ).kind,
      MiniBotListenKind.denied,
    );
    expect(
      MiniBotSpeechToTextHook.failureFor('error_no_match').kind,
      MiniBotListenKind.empty,
    );
    expect(
      MiniBotSpeechToTextHook.failureFor('error_speech_timeout').kind,
      MiniBotListenKind.empty,
    );
    expect(
      MiniBotSpeechToTextHook.failureFor('error_network').kind,
      MiniBotListenKind.unavailable,
    );
    expect(
      MiniBotSpeechToTextHook.failureFor('error_language_unavailable').kind,
      MiniBotListenKind.unavailable,
    );
  });

  testWidgets('donation chip recommends a screen and cancel spends nothing',
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

    final labels = tester
        .widgetList<ActionChip>(find.byType(ActionChip))
        .map((chip) => (chip.label as Text).data)
        .toList();
    expect(labels.first, '앱 소개');
    expect(labels[1], '챌린지 로비');
    expect(labels[3], '스폰서');
    expect(labels, isNot(contains('러너 후원')));
    expect(labels, isNot(contains('구독')));
    expect(labels, isNot(contains('Coach+')));
    expect(labels[4], '챌린지 참가');

    await tester.tap(find.byKey(const Key('mini-bot-chip-donate')));
    await tester.pump();
    expect(executed, isNull);
    expect(find.text('후원하기'), findsOneWidget);
    expect(find.text('500 VALUE'), findsOneWidget);

    await tester.tap(find.byKey(const Key('mini-bot-cancel')));
    await tester.pump();
    expect(executed, isNull);
    expect(find.byKey(const Key('mini-bot-amount')), findsNothing);
  });

  testWidgets('spoken donation uses the same confirm button as the chip',
      (tester) async {
    MiniBotRead? executed;
    await tester.pumpWidget(
      MaterialApp(
        theme: SrcTheme.light,
        home: Scaffold(
          body: MiniBotSheet(
            voice: const SilentMiniBotVoice(),
            speech: _ScriptedSpeech(const MiniBotListen.heard('기부할게')),
            onExecute: (read) => executed = read,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('mini-bot-mic')));
    await tester.pump();
    expect(executed, isNull);
    expect(find.text('후원하기'), findsOneWidget);

    await tester.tap(find.byKey(const Key('mini-bot-confirm')));
    await tester.pump();
    expect(executed?.destination, MiniBotDestination.donateStore);
    expect(
      MiniBotCopy.executed(MiniBotDestination.donateStore),
      contains('기부되지 않아요'),
    );
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

    await tester.pump();
    await tester.tap(find.byKey(const Key('mini-bot-entry-home')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mini-bot-sheet')), findsOneWidget);
    expect(find.text('달팽이봇'), findsOneWidget);
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

  testWidgets('shell mic sits above the bottom tab bar', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    const insets = FakeViewPadding(top: 47, bottom: 34);
    tester.view.padding = insets;
    tester.view.viewPadding = insets;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final router = GoRouter(
      initialLocation: RouteNames.mainDashboard,
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
          recentActivitiesProvider
              .overrideWith((ref) => Stream.value(const [])),
          authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: MaterialApp.router(
          locale: koTestLocale,
          supportedLocales: koTestSupportedLocales,
          localizationsDelegates: koTestDelegates,
          theme: SrcTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fab = tester.getRect(find.byType(MiniBotEntryButton));
    final nav = tester.getRect(find.byType(DashboardBottomNav));
    expect(fab.overlaps(nav), isFalse);
    expect(
      nav.top - fab.bottom,
      greaterThanOrEqualTo(miniBotFabBottomClearance),
    );
    for (final label in [
      AppStrings.dashboardNavHome,
      AppStrings.dashboardNavStore,
      AppStrings.dashboardNavChallenge,
      AppStrings.dashboardNavCrew,
      AppStrings.dashboardNavMyPage,
    ]) {
      expect(
        fab.overlaps(tester.getRect(find.text(label))),
        isFalse,
        reason: label,
      );
    }

    router.go(RouteNames.tournament);
    await tester.pumpAndSettle();
    final lobbyFab =
        tester.getRect(find.byKey(const Key('mini-bot-entry-lobby')));
    final lobbyNav = tester.getRect(find.byType(DashboardBottomNav));
    expect(lobbyFab.overlaps(lobbyNav), isFalse);
    expect(
      lobbyNav.top - lobbyFab.bottom,
      greaterThanOrEqualTo(miniBotFabBottomClearance),
    );
  });

  testWidgets('open sheet keeps chips above the speak control', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    const insets = FakeViewPadding(top: 47, bottom: 34);
    tester.view.padding = insets;
    tester.view.viewPadding = insets;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(
      MaterialApp(
        theme: SrcTheme.light,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.3),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const Scaffold(
          body: SizedBox.expand(),
          floatingActionButton: MiniBotEntryButton(
            heroTag: 'mini-bot-sheet-layout',
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.tap(find.byType(MiniBotEntryButton));
    await tester.pumpAndSettle();

    final sheet = tester.getRect(find.byKey(const Key('mini-bot-sheet')));
    final mic = tester.getRect(find.byKey(const Key('mini-bot-mic')));
    expect(mic.bottom, lessThanOrEqualTo(sheet.bottom));
    for (final key in const [
      'mini-bot-chip-intro',
      'mini-bot-chip-join',
    ]) {
      final chip = tester.getRect(find.byKey(Key(key)));
      expect(chip.overlaps(mic), isFalse, reason: key);
      expect(mic.top - chip.bottom, greaterThanOrEqualTo(8), reason: key);
      expect(chip.top, greaterThanOrEqualTo(sheet.top), reason: key);
      expect(chip.bottom, lessThanOrEqualTo(sheet.bottom), reason: key);
    }
  });

  testWidgets(
      'coach chip confirm waits, then routes to Coach+ without charging',
      (tester) async {
    AppEnv.debugInAppPurchasesOverride = true;
    addTearDown(() => AppEnv.debugInAppPurchasesOverride = null);
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

    final chip = find.byKey(const Key('mini-bot-chip-coach-plus'));
    await tester.scrollUntilVisible(
      chip,
      160,
      scrollable: find.descendant(
        of: find.byKey(const Key('mini-bot-chips')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(chip);
    await tester.pump();

    expect(executed, isNull);
    expect(find.text('이동하기'), findsOneWidget);
    expect(find.textContaining('결제하지 않아요'), findsWidgets);

    await tester.tap(find.byKey(const Key('mini-bot-confirm')));
    await tester.pump();

    expect(executed?.destination, MiniBotDestination.coachPlus);
    expect(executed?.intent, MiniBotIntent.coachPlus);
    expect(MiniBotCopy.executed(executed!.destination), contains('결제되지 않아요'));
  });
}

void bubbleTests() {
  group('달팽이봇 말풍선', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{
        MiniBotDockSettings.hintSeenKey: true,
      });
      MiniBotDock.resetMessagesForTest();
      MiniBotDockSettings.resetForTest();
    });

    testWidgets('shows once per screen after launch, then disappears',
        (tester) async {
      Widget app() => MaterialApp(
            home: Scaffold(
              body: Center(
                child: MiniBotDock(
                  onOpen: () {},
                  message: '궁금한 게 있으면 저를 눌러 물어보세요',
                  messageId: 'home',
                ),
              ),
            ),
          );
      await tester.pumpWidget(app());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(MiniBotDock.messageKey), findsOneWidget);
      expect(find.text('궁금한 게 있으면 저를 눌러 물어보세요'), findsOneWidget);

      await tester.pump(const Duration(seconds: 6));
      expect(find.byKey(MiniBotDock.messageKey), findsNothing);

      // 같은 화면을 다시 열어도 이번 실행에서는 다시 뜨지 않는다.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(MiniBotDock.messageKey), findsNothing);
    });

    testWidgets('the first-run drag hint comes first, no bubble over it',
        (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MiniBotDock(
                onOpen: () {},
                message: '말풍선',
                messageId: 'lobby',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(MiniBotDock.hintKey), findsOneWidget);
      expect(find.byKey(MiniBotDock.messageKey), findsNothing);
      await tester.pump(const Duration(seconds: 7));
    });

    test('text rotates by day and only says what the bot can answer', () {
      final a =
          MiniBotBubble.forScreen(MiniBotScreen.home, DateTime(2026, 10, 1));
      final b =
          MiniBotBubble.forScreen(MiniBotScreen.home, DateTime(2026, 10, 2));
      expect(a, isNot(b));
      expect(MiniBotBubble.lobby, hasLength(3));
      expect(
        MiniBotBubble.forScreen(MiniBotScreen.lobby, DateTime(2026, 10, 1)),
        isIn(MiniBotBubble.lobby),
      );
    });
  });
}
