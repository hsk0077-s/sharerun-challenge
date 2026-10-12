import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/features/mini_bot/mini_bot_sheet.dart';
import 'package:share_run_challenge/features/mini_bot/mini_bot_voice.dart';
import 'package:share_run_challenge/features/mini_bot/snail_bot_face.dart';
import 'package:share_run_challenge/features/snail_faq/snail_faq.dart';

class _Voice implements MiniBotVoice {
  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

class _GateSpeech extends MiniBotSpeechToText {
  final gate = Completer<MiniBotListen>();

  @override
  Future<MiniBotListen> listen() => gate.future;
}

String _faceAsset(WidgetTester tester) {
  final image = tester.widget<Image>(
    find.descendant(
      of: find.byKey(const Key('mini-bot-face')),
      matching: find.byType(Image),
    ),
  );
  return (image.image as AssetImage).assetName;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SnailFaq faq;
  setUpAll(() async {
    faq = await SnailFaq.load();
  });

  Future<_GateSpeech> openSheet(WidgetTester tester) async {
    final speech = _GateSpeech();
    await tester.pumpWidget(
      MaterialApp(
        theme: SrcTheme.light,
        home: Scaffold(
          body: MiniBotSheet(voice: _Voice(), speech: speech, faq: faq),
        ),
      ),
    );
    await tester.pump();
    return speech;
  }

  Future<void> ask(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('mini-bot-input')), text);
    await tester.tap(find.byKey(const Key('mini-bot-send')));
    await tester.pump();
  }

  test('every mood has its own picture file', () {
    final assets = SnailBotMood.values.map((mood) => mood.asset).toSet();
    expect(assets, hasLength(SnailBotMood.values.length));
  });

  testWidgets('the floating button is the snail face, not a mic icon',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SrcTheme.light,
        home: const Scaffold(
          floatingActionButton: MiniBotEntryButton(heroTag: 'test'),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(SnailBotFace), findsOneWidget);
    expect(find.byIcon(Icons.mic_none_rounded), findsNothing);
    expect(
      find.bySemanticsLabel('달팽이봇'),
      findsWidgets,
    );
  });

  testWidgets('the header face follows what just happened', (tester) async {
    final speech = await openSheet(tester);
    expect(_faceAsset(tester), SnailBotMood.smiling.asset);

    // 듣는 중
    await tester.tap(find.byKey(const Key('mini-bot-mic')));
    await tester.pump();
    expect(_faceAsset(tester), SnailBotMood.listening.asset);
    speech.gate.complete(const MiniBotListen.cancelled());
    await tester.pump();
    expect(_faceAsset(tester), SnailBotMood.smiling.asset);

    // FAQ로 답함
    await ask(tester, 'SHARE는 현금으로 바꿀 수 있어요?');
    expect(_faceAsset(tester), SnailBotMood.joy.asset);

    // 모르는 말
    await ask(tester, 'ㅋㅋㅋㅋ');
    expect(_faceAsset(tester), SnailBotMood.disappointed.asset);
  });

  testWidgets('a mic that cannot be used shows the disappointed face',
      (tester) async {
    final speech = await openSheet(tester);
    await tester.tap(find.byKey(const Key('mini-bot-mic')));
    await tester.pump();
    speech.gate.complete(const MiniBotListen.denied());
    await tester.pump();
    expect(_faceAsset(tester), SnailBotMood.disappointed.asset);
  });
}
