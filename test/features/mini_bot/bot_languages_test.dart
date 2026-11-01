import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/mini_bot/mini_bot_intent.dart';
import 'package:share_run_challenge/features/mini_bot/mini_bot_sheet.dart';
import 'package:share_run_challenge/features/mini_bot/mini_bot_voice.dart';
import 'package:share_run_challenge/features/snail_faq/snail_faq.dart';
import 'package:share_run_challenge/l10n/remaining_surface.dart';

final _hangul = RegExp(r'[가-힣]');
const _langs = ['en', 'ja', 'zh', 'es', 'pt', 'de', 'fr', 'vi', 'th', 'id'];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final saved = RemainingSurface.currentLocale;
  tearDown(() => RemainingSurface.currentLocale = saved);

  group('typed commands in each language reach the same screen', () {
    // (말, 가야 할 곳)
    final cases = <String, MiniBotDestination>{
      // 안전 가드
      'safe guard': MiniBotDestination.safeGuardStore,
      'セーフガード': MiniBotDestination.safeGuardStore,
      'salvaguarda': MiniBotDestination.safeGuardStore,
      'garde-fou': MiniBotDestination.safeGuardStore,
      // 심폐소생권
      'cpr ticket': MiniBotDestination.cprStore,
      '蘇生チケット': MiniBotDestination.cprStore,
      'boleto de reanimación': MiniBotDestination.cprStore,
      'wiederbelebung': MiniBotDestination.cprStore,
      'vé hồi sinh': MiniBotDestination.cprStore,
      // 다이아 교환
      'exchange dia': MiniBotDestination.shareCharge,
      'ダイヤを交換したい': MiniBotDestination.shareCharge,
      'quiero canjear': MiniBotDestination.shareCharge,
      'tukar dia': MiniBotDestination.shareCharge,
      // 기부
      'donation': MiniBotDestination.donateStore,
      '寄付したい': MiniBotDestination.donateStore,
      'quiero donar donación': MiniBotDestination.donateStore,
      'บริจาค': MiniBotDestination.donateStore,
      // 챌린지 로비
      'challenge lobby': MiniBotDestination.challengeLobby,
      'チャレンジロビー': MiniBotDestination.challengeLobby,
      'sảnh': MiniBotDestination.challengeLobby,
      // 초보 챌린지
      'join the beginner challenge': MiniBotDestination.beginnerRoom,
      '初心者チャレンジに参加': MiniBotDestination.beginnerRoom,
      'unirse reto principiante': MiniBotDestination.beginnerRoom,
      'tantangan pemula': MiniBotDestination.beginnerRoom,
      // 배틀패스
      'battle pass': MiniBotDestination.battlePass,
      'バトルパス': MiniBotDestination.battlePass,
      'pase de batalla': MiniBotDestination.battlePass,
    };
    cases.forEach((text, destination) {
      test(text, () {
        final read = MiniBotInterpreter.interpret(text);
        expect(read.destination, destination, reason: text);
      });
    });

    test('an app-intro question in another language shows the intro', () {
      for (final text in ['what is sharerun', 'ShareRunって何', 'qué es sharerun']) {
        expect(MiniBotInterpreter.interpret(text).intent, MiniBotIntent.appIntro,
            reason: text);
      }
    });

    test('nonsense in any language is not guessed', () {
      expect(MiniBotInterpreter.interpret('zzzz qqqq').intent,
          MiniBotIntent.unknown);
    });
  });

  test('chips keep working, and their names follow the app language', () {
    for (final chip in MiniBotPrompts.chips) {
      // 칩은 한국어 명령으로 해석되므로 언어와 상관없이 같은 곳으로 간다.
      RemainingSurface.currentLocale = const Locale('ko', 'KR');
      final koRead = MiniBotInterpreter.interpret(chip.prompt);
      for (final code in _langs) {
        RemainingSurface.currentLocale = Locale(code);
        expect(MiniBotInterpreter.interpret(chip.prompt).destination,
            koRead.destination,
            reason: '$code ${chip.id}');
        if (chip.id != 'coach-plus') {
          expect(_hangul.hasMatch(chip.label), isFalse,
              reason: '$code ${chip.id}: ${chip.label}');
        }
      }
    }
  });

  test('every FAQ chip and bubble is translated', () {
    for (final code in _langs) {
      RemainingSurface.currentLocale = Locale(code);
      final texts = [
        for (final id in [
          ...MiniBotFaqChips.home,
          ...MiniBotFaqChips.lobby,
        ])
          MiniBotFaqChips.shortLabel(id)!,
        ...MiniBotBubble.home,
        ...MiniBotBubble.lobby,
      ];
      for (final text in texts) {
        expect(_hangul.hasMatch(text), isFalse, reason: '$code: $text');
      }
    }
  });

  group('FAQ per language', () {
    final values = {
      'SHARE잔액': '1,200',
      '오늘기부기여': '300',
      '등급': 'A',
    };

    test('each language answers its chip questions in its own language',
        () async {
      for (final code in _langs) {
        final faq = await SnailFaq.load(null, code);
        for (final id in [...MiniBotFaqChips.home, ...MiniBotFaqChips.lobby]) {
          final question = faq.questionOf(id)!;
          expect(_hangul.hasMatch(question), isFalse, reason: '$code $id');
          final hit = faq.match(question);
          expect(hit?.id, id, reason: '$code $id: $question');
          final answer = SnailFaq.answerFor(hit!, values);
          expect(_hangul.hasMatch(answer), isFalse, reason: '$code $id');
        }
        expect(_hangul.hasMatch(faq.fallbackAnswer ?? ''), isFalse,
            reason: code);
      }
    });

    test('Korean stays as it was', () async {
      final faq = await SnailFaq.load(null, 'ko');
      expect(faq.questionOf('CO-02'), '대회 참가비는 얼마예요?');
      expect(faq.match('쉐어런이 뭐예요')?.id, 'AP-01');
    });

    test('a language with no translation file falls back to Korean', () async {
      final faq = await SnailFaq.load(null, 'xx');
      expect(faq.questionOf('CO-02'), '대회 참가비는 얼마예요?');
    });

    test('filled values appear in translated answers', () async {
      final faq = await SnailFaq.load(null, 'en');
      final answer =
          SnailFaq.answerFor(faq.entries.firstWhere((e) => e.id == 'SH-05'), values);
      expect(answer, contains('1,200'));
    });
  });

  group('voice language follows the app language', () {
    test('picks an installed recognizer for the language', () {
      expect(miniBotLocaleId(['en_US', 'ja_JP'], 'ja'), 'ja_JP');
      expect(miniBotLocaleId(['en-US', 'vi-VN'], 'vi'), 'vi-VN');
      expect(miniBotLocaleId(['zh_CN', 'zh_TW'], 'zh'), 'zh_TW');
      expect(miniBotLocaleId(['zh_CN'], 'zh'), 'zh_CN');
    });

    test('falls back to the default locale when none is installed', () {
      expect(miniBotLocaleId(['en_US'], 'de'), 'de_DE');
      expect(miniBotLocaleId(const [], 'th'), 'th_TH');
      expect(miniBotLocaleId(['en_US', 'ja_JP'], 'ko'), 'ko_KR');
    });

    test('all 11 languages have a speaking language', () {
      for (final code in ['ko', ..._langs]) {
        expect(miniBotVoiceLocales.containsKey(code), isTrue, reason: code);
      }
      expect(miniBotVoiceLocale('xx'), 'en-US');
    });
  });
}
