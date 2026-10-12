import 'dart:convert';

import 'package:flutter/services.dart';

/// 미리 써 둔 달팽이 FAQ 한 건. 생성형 AI 없이 이 답만 보여 준다.
class FaqEntry {
  const FaqEntry({
    required this.id,
    required this.category,
    required this.question,
    required this.aliases,
    required this.answer,
  });

  final String id;
  final String category;
  final String question;
  final List<String> aliases;
  final String answer;

  factory FaqEntry.fromJson(Map<String, dynamic> json) {
    return FaqEntry(
      id: json['id'] as String? ?? '',
      category: json['category'] as String? ?? '',
      question: json['question'] as String? ?? '',
      aliases: [
        for (final alias in (json['aliases'] as List? ?? const []))
          if (alias is String) alias,
      ],
      answer: json['answer'] as String? ?? '',
    );
  }
}

/// 질문을 FAQ와 맞춘다. 네트워크가 없어도 동작한다.
class SnailFaq {
  SnailFaq(List<FaqEntry> entries)
      : entries = List.unmodifiable(
          entries.where((e) => e.id.isNotEmpty && e.answer.isNotEmpty),
        ),
        _index = [
          for (final entry in entries)
            if (entry.id.isNotEmpty &&
                entry.answer.isNotEmpty &&
                entry.id != fallbackId)
              (
                entry: entry,
                phrases: [
                  for (final text in [entry.question, ...entry.aliases])
                    if (_normalize(text).isNotEmpty) _normalize(text),
                ],
              ),
        ];

  static const assetPath = 'assets/faq/snail_bot_faq.json';
  static const fallbackId = 'SYS-FALLBACK';

  /// 이 점수보다 낮으면 맞는 답이 없다고 본다.
  static const minScore = 0.55;

  final List<FaqEntry> entries;
  final List<({FaqEntry entry, List<String> phrases})> _index;

  static Future<SnailFaq> load([AssetBundle? bundle]) async {
    final raw = await (bundle ?? rootBundle).loadString(assetPath);
    final rows = jsonDecode(raw);
    return SnailFaq([
      if (rows is List)
        for (final row in rows)
          if (row is Map<String, dynamic>) FaqEntry.fromJson(row),
    ]);
  }

  /// 맞는 답이 없을 때 쓰는 안내 문구. FAQ에 없으면 null.
  String? get fallbackAnswer {
    for (final entry in entries) {
      if (entry.id == fallbackId) return entry.answer;
    }
    return null;
  }

  /// 가장 비슷한 FAQ. 충분히 비슷한 것이 없으면 null.
  FaqEntry? match(String text) {
    final query = _normalize(text);
    if (query.length < 2) return null;
    final grams = _bigrams(query);
    FaqEntry? best;
    var bestScore = 0.0;
    for (final item in _index) {
      for (final phrase in item.phrases) {
        final score = _score(query, grams, phrase);
        if (score > bestScore) {
          bestScore = score;
          best = item.entry;
        }
      }
    }
    return bestScore >= minScore ? best : null;
  }

  static double _score(String query, Set<String> queryGrams, String phrase) {
    if (query == phrase) return 1;
    // 짧은 말이 긴 말 안에 그대로 들어 있으면 거의 같은 질문으로 본다.
    if (phrase.length >= 4 && query.contains(phrase)) return 0.95;
    final phraseGrams = _bigrams(phrase);
    if (phraseGrams.isEmpty || queryGrams.isEmpty) return 0;
    final shared = queryGrams.intersection(phraseGrams).length;
    return 2 * shared / (queryGrams.length + phraseGrams.length);
  }

  static Set<String> _bigrams(String text) {
    if (text.length < 2) return {text};
    return {for (var i = 0; i < text.length - 1; i++) text.substring(i, i + 2)};
  }

  /// 띄어쓰기와 기호를 빼고 소문자로 바꾼다. "쉐어 런"과 "쉐어런"을 같게 본다.
  static String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^0-9a-zㄱ-ㆎ가-힣+]'), '');
  }
}
