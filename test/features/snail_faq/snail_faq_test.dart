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

  test('the shipped FAQ has answers and no undecided or personal rows', () {
    expect(faq.entries.length, greaterThan(100));
    for (final entry in faq.entries) {
      expect(entry.answer, isNot(contains('{')), reason: entry.id);
      expect(entry.answer, isNot(contains('쉐어 런')), reason: entry.id);
    }
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
