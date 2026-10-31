import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/l10n/app_locale.dart';
import 'package:share_run_challenge/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/ko_localization.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('language sheet lists follow-phone + 11 languages and applies',
      (tester) async {
    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return MaterialApp(
              locale: ref.watch(appLocaleProvider) ?? koTestLocale,
              supportedLocales: koTestSupportedLocales,
              localizationsDelegates: koTestDelegates,
              home: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showLanguageSheet(context),
                  child: const Text('open'),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('language-option-system')), findsOneWidget);
    for (final c in appLocaleChoices) {
      await tester.ensureVisible(find.byKey(Key('language-option-${c.code}')));
      expect(find.byKey(Key('language-option-${c.code}')), findsOneWidget);
    }

    await tester.tap(find.byKey(const Key('language-option-ja')));
    await tester.pumpAndSettle();
    expect(container.read(appLocaleProvider)?.languageCode, 'ja');
  });
}
