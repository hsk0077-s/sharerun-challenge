import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 화면 문구 이름 규칙(docs/naming-rules.md)을 지키는지 코드 문자열에서 검사한다.
void main() {
  final strings = RegExp(r'''(['"])((?:(?!\1)[^\n\\]|\\.)*)\1''');

  List<String> literals() {
    final out = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      for (final line in entity.readAsLinesSync()) {
        if (line.trimLeft().startsWith('//')) continue;
        for (final m in strings.allMatches(line)) {
          out.add('${entity.path}: ${m.group(2)}');
        }
      }
    }
    return out;
  }

  test('screen text uses the official app name and never SRC', () {
    // 개발자용 토큰 쇼케이스 화면은 앱에 노출되지 않아 제외한다.
    final bad = literals()
        .where((s) => !s.startsWith('lib/core/theme/src_token_showcase.dart'))
        .where((s) => RegExp(r'(?<![A-Za-z0-9_])SRC(?![A-Za-z0-9_])').hasMatch(s))
        .toList();
    expect(bad, isEmpty, reason: '사용자에게 보이는 문구에 SRC를 쓰지 않는다.');
  });

  test('app name is spelled 쉐어런, never 셰어런 or 쉐어 런', () {
    final bad = literals()
        .where((s) => s.contains('셰어런') || s.contains('쉐어 런'))
        .toList();
    expect(bad, isEmpty);
  });

  test('SHARE is never written in Korean and is never a token', () {
    final bad = literals()
        .where((s) => s.contains('셰어') || s.contains('쉐어토큰'))
        .toList();
    expect(bad, isEmpty);
  });

  test('the iPhone settings file follows the same naming rules', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist.contains('셰어런'), isFalse);
    expect(plist.contains('쉐어 런'), isFalse);
    expect(RegExp(r'(?<![A-Za-z0-9_])SRC(?![A-Za-z0-9_])').hasMatch(plist),
        isFalse);
    expect(plist.contains('NSFaceIDUsageDescription'), isTrue);
  });
}
