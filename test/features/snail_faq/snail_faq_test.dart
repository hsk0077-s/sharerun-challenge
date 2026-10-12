import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/features/mini_bot/mini_bot_sheet.dart';
import 'package:share_run_challenge/features/mini_bot/mini_bot_voice.dart';
import 'package:share_run_challenge/features/snail_faq/snail_faq.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SnailFaq faq;
  setUpAll(() async {
    faq = await SnailFaq.load();
  });

  String? idFor(String text) => faq.match(text)?.id;

  test('the shipped FAQ has answers, and braces only where a value is filled',
      () {
    expect(faq.entries.length, greaterThan(100));
    for (final entry in faq.entries) {
      expect(entry.answer, isNot(contains('쉐어 런')), reason: entry.id);
      // 중괄호는 내 값이 들어갈 자리일 때만 있다.
      final braces = RegExp(r'\{([^}]+)\}')
          .allMatches(entry.answer)
          .map((m) => m.group(1))
          .toSet();
      expect(braces, entry.needs.toSet(), reason: entry.id);
    }
    final personal = {for (final e in faq.entries) if (e.needs.isNotEmpty) e.id};
    expect(personal, {'SH-05', 'GR-18', 'GR-07', 'DO-03'});
  });

  test('my own values are filled in, and a missing one is never made up', () {
    final entry = faq.entries.firstWhere((e) => e.id == 'SH-05');
    expect(
      SnailFaq.answerFor(entry, {'SHARE잔액': '1,200'}),
      '지금 가지고 계신 SHARE는 1,200 SHARE예요.',
    );
    expect(SnailFaq.answerFor(entry, const {}), SnailFaq.valueUnavailable);
    expect(
      SnailFaq.answerFor(entry, {'SHARE잔액': ''}),
      SnailFaq.valueUnavailable,
    );
    final plain = faq.entries.firstWhere((e) => e.id == 'SH-01');
    expect(SnailFaq.answerFor(plain, const {}), plain.answer);
  });

  test('how the speech engine writes SHARE and the app name still matches',
      () {
    expect(idFor('셰어는 현금으로 바꿀 수 있어요'), 'SH-12');
    expect(idFor('쉐어는 현금으로 바꿀 수 있어요'), 'SH-12');
    expect(idFor('셰어런이 뭐예요'), 'AP-01');
  });

  test('every suggested chip finds its own answer and is not stolen by a move',
      () {
    for (final screen in MiniBotScreen.values) {
      for (final id in MiniBotFaqChips.forScreen(screen)) {
        final question = faq.questionOf(id);
        expect(question, isNotNull, reason: id);
        expect(idFor(question!), id, reason: question);
        expect(
          faq.matchScored(question)!.score,
          greaterThanOrEqualTo(SnailFaq.strongScore),
          reason: '$question must beat the move/confirm reading',
        );
      }
    }
    expect(
      MiniBotFaqChips.home.toSet().intersection(MiniBotFaqChips.lobby.toSet()),
      isEmpty,
    );
  });

  test('the example questions find their own answer', () {
    final misses = <String>[];
    for (final entry in faq.entries) {
      for (final text in [entry.question, ...entry.aliases]) {
        if (idFor(text) != entry.id) misses.add('${entry.id}: $text');
      }
    }
    // 같은 뜻의 질문이 여러 항목에 있어 일부는 다른 항목에 닿을 수 있다.
    expect(
      misses.length / faq.entries.fold<int>(0, (n, e) => n + 1 + e.aliases.length),
      lessThan(0.08),
      reason: misses.take(20).join('\n'),
    );
  });

  test('rephrased questions still reach the right answer', () {
    expect(idFor('쉐어런이 뭐예요'), 'AP-01');
    expect(idFor('SHARE가 뭐야?'), 'SH-01');
    expect(idFor('하루에 SHARE 최대 얼마나 받아?'), 'SH-03');
  });

  test('off-topic text gets the off-topic answer and noise finds nothing', () {
    expect(idFor('오늘 날씨 어때'), 'SYS-OFFTOPIC');
    expect(faq.match('ㅋㅋㅋㅋ'), isNull);
    expect(faq.fallbackAnswer, contains('잘 모르겠어요'));
    expect(faq.match(''), isNull);
    expect(faq.match(' '), isNull);
  });

  testWidgets('the bot sheet answers a question from the FAQ, offline',
      (tester) async {
    final voice = _Voice();
    await tester.pumpWidget(
      MaterialApp(
        theme: SrcTheme.light,
        home: Scaffold(body: MiniBotSheet(voice: voice, faq: faq)),
      ),
    );
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('mini-bot-input')),
      'SHARE는 현금으로 바꿀 수 있어요?',
    );
    await tester.tap(find.byKey(const Key('mini-bot-send')));
    await tester.pump();

    final answer = faq.match('SHARE는 현금으로 바꿀 수 있어요?')!.answer;
    expect(find.text(answer), findsOneWidget);
    expect(voice.spoken, contains(answer));
    expect(find.byKey(const Key('mini-bot-confirm')), findsNothing);
  });

  testWidgets('my confirmed value is read out, and missing ones are not guessed',
      (tester) async {
    Future<void> open(Map<String, String> values) => tester.pumpWidget(
          MaterialApp(
            theme: SrcTheme.light,
            home: Scaffold(
              body: MiniBotSheet(
                voice: _Voice(),
                faq: faq,
                faqValues: values,
              ),
            ),
          ),
        );

    await open({'SHARE잔액': '1,200'});
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('mini-bot-input')),
      '내 SHARE는 얼마 있어?',
    );
    await tester.tap(find.byKey(const Key('mini-bot-send')));
    await tester.pump();
    expect(
      find.text('지금 가지고 계신 SHARE는 1,200 SHARE예요.'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox());
    await open(const {});
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('mini-bot-input')),
      '내 SHARE는 얼마 있어?',
    );
    await tester.tap(find.byKey(const Key('mini-bot-send')));
    await tester.pump();
    expect(find.text(SnailFaq.valueUnavailable), findsOneWidget);
    expect(find.textContaining('1,200'), findsNothing);
  });

  testWidgets('home and lobby suggest different questions', (tester) async {
    Future<void> open(MiniBotScreen screen) => tester.pumpWidget(
          MaterialApp(
            theme: SrcTheme.light,
            home: Scaffold(
              body: MiniBotSheet(voice: _Voice(), faq: faq, screen: screen),
            ),
          ),
        );

    await open(MiniBotScreen.home);
    await tester.pump();
    expect(find.byKey(const Key('mini-bot-faq-chip-DO-03')), findsOneWidget);
    expect(find.byKey(const Key('mini-bot-faq-chip-CO-02')), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await open(MiniBotScreen.lobby);
    await tester.pump();
    expect(find.byKey(const Key('mini-bot-faq-chip-CO-02')), findsOneWidget);
    expect(find.byKey(const Key('mini-bot-faq-chip-DO-03')), findsNothing);

    // 칩을 누르면 그 질문의 답이 나온다.
    await tester.tap(find.byKey(const Key('mini-bot-faq-chip-CO-02')));
    await tester.pump();
    expect(find.text(faq.match(faq.questionOf('CO-02')!)!.answer), findsOneWidget);
  });

  testWidgets('a question nobody wrote gets the fallback, not a guess',
      (tester) async {
    final voice = _Voice();
    await tester.pumpWidget(
      MaterialApp(
        theme: SrcTheme.light,
        home: Scaffold(body: MiniBotSheet(voice: voice, faq: faq)),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byKey(const Key('mini-bot-input')), 'ㅋㅋㅋㅋ');
    await tester.tap(find.byKey(const Key('mini-bot-send')));
    await tester.pump();

    expect(find.text(faq.fallbackAnswer!), findsOneWidget);
  });
}

class _Voice implements MiniBotVoice {
  final spoken = <String>[];

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}
