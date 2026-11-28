import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/screens/pro_tools_screen.dart';

/// Real shoe and sportswear brands are never shown as if they sponsored or
/// sold something in the app. (Watch brands in the device-link guides are a
/// separate thing: they tell people which app to open.)
const _brands = [
  '나이키', 'Nike', 'NIKE', 'ナイキ', '耐吉',
  '베이퍼플라이', 'Vaporfly',
  '아디다스', 'adidas', 'Adidas',
  '아식스', 'ASICS', 'Asics',
  '뉴발란스', 'New Balance',
  '호카', 'HOKA', 'Hoka',
  '스타벅스', 'Starbucks',
];

void main() {
  test('app strings and their translations name no sportswear brand', () {
    for (final path in [
      'lib/core/strings/app_strings.dart',
      'lib/l10n/remaining_surface.dart',
      'docs/l10n/remaining-ko-strings.json',
    ]) {
      final text = File(path).readAsStringSync();
      for (final brand in _brands) {
        expect(text.contains(brand), isFalse, reason: '$brand in $path');
      }
    }
  });

  testWidgets('pro tools shows no sample shoe or made-up mileage',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ProToolsScreen())),
    );
    await tester.pump();

    expect(find.textContaining('러닝화'), findsNothing);
    expect(find.textContaining('km /'), findsNothing);
    expect(find.textContaining('쿠션'), findsNothing);
    for (final brand in _brands) {
      expect(find.textContaining(brand), findsNothing, reason: brand);
    }
  });
}
