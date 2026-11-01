import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/snail_faq/snail_faq.dart';

final _hangul = RegExp(r'[가-힣]');
const _langs = ['en', 'ja', 'zh', 'es', 'pt', 'de', 'fr', 'vi', 'th', 'id'];

List<Map<String, dynamic>> _read(String path) => [
      for (final row in jsonDecode(File(path).readAsStringSync()) as List)
        row as Map<String, dynamic>,
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final base = _read('assets/faq/snail_bot_faq.json');

  for (final code in _langs) {
    group('FAQ $code', () {
      final rows = _read('assets/faq/snail_bot_faq.$code.json');
      final byId = {for (final r in rows) r['id'] as String: r};

      test('has every entry of the Korean original, once', () {
        expect(rows.length, base.length);
        expect(byId.keys.toSet(), {for (final b in base) b['id'] as String});
      });

      test('answers are in the language, with no Korean left', () {
        for (final b in base) {
          final row = byId[b['id']]!;
          final answer = row['answer'] as String;
          expect(answer.trim(), isNotEmpty, reason: '${b['id']}');
          // 내 값이 들어갈 자리 이름({SHARE잔액} 등)만 한국어일 수 있다.
          final stripped = answer.replaceAll(RegExp(r'\{[^}]*\}'), '');
          expect(_hangul.hasMatch(stripped), isFalse,
              reason: '$code ${b['id']}: $answer');
          for (final text in [
            row['question'] as String,
            ...(row['aliases'] as List).cast<String>(),
          ]) {
            expect(_hangul.hasMatch(text), isFalse,
                reason: '$code ${b['id']}: $text');
          }
        }
      });

      test('keeps the same value placeholders as the original', () {
        for (final b in base) {
          final row = byId[b['id']]!;
          expect(row['needs'], b['needs'], reason: '${b['id']}');
          for (final key in (b['needs'] as List? ?? const []).cast<String>()) {
            expect((row['answer'] as String).contains('{$key}'), isTrue,
                reason: '$code ${b['id']} {$key}');
          }
        }
      });

      test('entries that need a question have one', () {
        for (final b in base) {
          if ((b['question'] as String).isEmpty) continue;
          expect((byId[b['id']]!['question'] as String).trim(), isNotEmpty,
              reason: '${b['id']}');
        }
      });
    });
  }

  test('every translated question and alias finds its own entry', () async {
    for (final code in _langs) {
      final faq = await SnailFaq.load(null, code);
      for (final e in faq.entries) {
        if (e.question.isEmpty) continue;
        for (final text in [e.question, ...e.aliases]) {
          expect(faq.match(text)?.id, e.id, reason: '$code ${e.id}: $text');
        }
      }
    }
  });
}
