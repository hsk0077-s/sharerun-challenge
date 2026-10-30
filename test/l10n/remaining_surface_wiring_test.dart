import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/boot_error_app.dart';
import 'package:share_run_challenge/core/widgets/async_value_section.dart';
import 'package:share_run_challenge/data/models/economy_state_model.dart';
import 'package:share_run_challenge/features/wallet/widgets/economy_status_card.dart';
import 'package:share_run_challenge/l10n/app_localizations.dart';
import 'package:share_run_challenge/l10n/remaining_surface.dart';

// Confirms that widgets actually wired to RemainingSurface render the
// Korean source only for ko (or a missing key), and the translation
// for every other supported locale -- for both the context-free
// (RemainingSurface.currentLocale) and BuildContext-resolved paths.
void main() {
  tearDown(() {
    RemainingSurface.currentLocale = const Locale('ko', 'KR');
  });

  group('BootErrorApp (RemainingSurface.currentLocale, no Localizations ancestor)', () {
    const ko = '앱을 시작하지 못했어요';

    Future<void> pump(WidgetTester tester, Locale locale) async {
      RemainingSurface.currentLocale = locale;
      await tester.pumpWidget(BootErrorApp(onRetry: () async {}));
      await tester.pump();
    }

    testWidgets('ko renders the Korean source verbatim', (tester) async {
      await pump(tester, const Locale('ko', 'KR'));
      expect(find.text(ko), findsOneWidget);
    });

    testWidgets('en renders the English translation, not the Korean source',
        (tester) async {
      await pump(tester, const Locale('en', 'US'));
      expect(find.text(ko), findsNothing);
      expect(find.text("Couldn't start the app"), findsOneWidget);
    });

    testWidgets('ja renders the Japanese translation, not the Korean source',
        (tester) async {
      await pump(tester, const Locale('ja', 'JP'));
      expect(find.text(ko), findsNothing);
      expect(find.text('アプリを起動できませんでした'), findsOneWidget);
    });
  });

  group('EconomyStatusCard (locale resolved from BuildContext)', () {
    const economy = EconomyStateModel(
      signupRewardClaimed: false,
      trialRunCount: 0,
      trialMilestoneRewardClaimed: false,
      firstTierGranted: false,
      referralCode: null,
      referredByUid: null,
      referralPayoutCount: 0,
      dailyMining: DailyMiningModel(dateKey: '', earnedKm: 0, earnedSrvTokens: 0),
    );
    const ko = '온보딩 & 땀방울 현황';

    Future<void> pump(WidgetTester tester, Locale locale) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: ShareRunLocalizations.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const Scaffold(body: EconomyStatusCard(economy: economy)),
        ),
      );
      await tester.pump();
    }

    testWidgets('ko renders the Korean source verbatim', (tester) async {
      await pump(tester, const Locale('ko', 'KR'));
      expect(find.text(ko), findsOneWidget);
    });

    testWidgets('en renders the English translation, not the Korean source',
        (tester) async {
      await pump(tester, const Locale('en', 'US'));
      expect(find.text(ko), findsNothing);
      expect(find.text('Onboarding & Effort Status'), findsOneWidget);
    });

    testWidgets('ja renders the Japanese translation, not the Korean source',
        (tester) async {
      await pump(tester, const Locale('ja', 'JP'));
      expect(find.text(ko), findsNothing);
      expect(find.text('オンボーディング＆汗の結晶の状況'), findsOneWidget);
    });
  });

  group('AsyncValueSection (locale resolved from BuildContext, with a placeholder)', () {
    const koPrefix = '데이터를 불러오지 못했습니다:';

    Future<void> pump(WidgetTester tester, Locale locale) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: ShareRunLocalizations.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: AsyncValueSection<int>(
              asyncValue: AsyncValue.error(Exception('boom'), StackTrace.empty),
              dataBuilder: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('ko renders the Korean source with the error substituted',
        (tester) async {
      await pump(tester, const Locale('ko', 'KR'));
      expect(find.textContaining(koPrefix), findsOneWidget);
      expect(find.text('$koPrefix Exception: boom'), findsOneWidget);
    });

    testWidgets('en renders the English translation, not the Korean source',
        (tester) async {
      await pump(tester, const Locale('en', 'US'));
      expect(find.textContaining(koPrefix), findsNothing);
      expect(find.text('Failed to load data: Exception: boom'), findsOneWidget);
    });

    testWidgets('ja renders the Japanese translation, not the Korean source',
        (tester) async {
      await pump(tester, const Locale('ja', 'JP'));
      expect(find.textContaining(koPrefix), findsNothing);
      expect(
        find.text('データを読み込めませんでした: Exception: boom'),
        findsOneWidget,
      );
    });
  });

  group('static wiring coverage', () {
    // Every RemainingSurface.tr(...)/trNow(...) call site in lib (excluding
    // the generated lookup table itself), capturing the key argument -- the
    // first quoted string literal, skipping an optional leading context
    // identifier (e.g. `context,` / `dialogContext,` / `null,`) that tr()
    // takes and trNow() does not.
    final callPattern = RegExp(
      r"RemainingSurface\.(?:tr|trNow)\(\s*(?:[A-Za-z_][A-Za-z0-9_]*\s*,\s*)?'([a-zA-Z0-9_.]+)'",
      dotAll: true,
    );

    Map<String, String> wiredKeys() {
      final found = <String, String>{};
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('lib/l10n/remaining_surface.dart')) continue;
        final content = entity.readAsStringSync();
        for (final match in callPattern.allMatches(content)) {
          found.putIfAbsent(match.group(1)!, () => entity.path);
        }
      }
      return found;
    }

    test('every key wired via tr()/trNow() exists with all 10 translations',
        () {
      final wired = wiredKeys();
      expect(wired, isNotEmpty);

      final catalog = json.decode(
        File('docs/l10n/remaining-ko-strings.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final entries = (catalog['strings'] as List).cast<Map<String, dynamic>>();
      final byKey = {for (final e in entries) e['key'] as String: e};

      const languages = [
        'en', 'ja', 'zh-TW', 'es', 'pt-BR', 'de', 'fr', 'vi', 'th', 'id',
      ];

      final missingEntry = <String>[];
      final emptyTranslation = <String>[];
      for (final entry in wired.entries) {
        final key = entry.key;
        final doc = byKey[key];
        if (doc == null) {
          missingEntry.add('$key (${entry.value})');
          continue;
        }
        for (final lang in languages) {
          final value = doc[lang];
          if (value is! String || value.trim().isEmpty) {
            emptyTranslation.add('$key.$lang (${entry.value})');
          }
        }
      }

      expect(
        missingEntry,
        isEmpty,
        reason: 'keys wired in lib/ but absent from '
            'docs/l10n/remaining-ko-strings.json:\n${missingEntry.join('\n')}',
      );
      expect(
        emptyTranslation,
        isEmpty,
        reason: 'keys wired in lib/ missing a translation for some '
            'language:\n${emptyTranslation.join('\n')}',
      );

      // Also confirm the generated lookup table (built from the same
      // catalog) actually carries every wired key for every language --
      // i.e. the committed lib/l10n/remaining_surface.dart is not stale
      // relative to the JSON catalog.
      for (final key in wired.keys) {
        for (final lang in RemainingSurface.appLanguageOf.values) {
          final text = RemainingSurface.text(Locale(lang), key);
          expect(text, isNot(equals(key)), reason: '$key/$lang');
        }
      }
    });
  });
}
