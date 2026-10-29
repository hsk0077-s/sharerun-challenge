import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/l10n/remaining_surface.dart';

void main() {
  tearDown(() {
    RemainingSurface.currentLocale = const Locale('ko', 'KR');
  });

  group('trNow', () {
    test('defaults to Korean', () {
      expect(RemainingSurface.currentLocale.languageCode, 'ko');
    });

    test('returns ko verbatim for the ko locale', () {
      RemainingSurface.currentLocale = const Locale('ko', 'KR');
      final result = RemainingSurface.trNow(
        'watch_connection.toast',
        '\${watchType.displayLabel} 연동이 완료되었습니다.',
        {'watchType.displayLabel': 'Garmin'},
      );
      expect(result, 'Garmin 연동이 완료되었습니다.');
    });

    test('returns the translated string with placeholders substituted', () {
      RemainingSurface.currentLocale = const Locale('en', 'US');
      final result = RemainingSurface.trNow(
        'watch_connection.toast',
        '\${watchType.displayLabel} 연동이 완료되었습니다.',
        {'watchType.displayLabel': 'Garmin'},
      );
      expect(result, 'Garmin connected successfully.');
    });

    test('falls back to ko when the key is missing for that language', () {
      RemainingSurface.currentLocale = const Locale('en', 'US');
      final result = RemainingSurface.trNow(
        'no_such_key.does_not_exist',
        '아직 번역이 없어요.',
      );
      expect(result, '아직 번역이 없어요.');
    });

    test('falls back to ko for an unsupported language', () {
      RemainingSurface.currentLocale = const Locale('pl', 'PL');
      final result = RemainingSurface.trNow(
        'watch_connection.toast',
        '\${watchType.displayLabel} 연동이 완료되었습니다.',
        {'watchType.displayLabel': 'Garmin'},
      );
      expect(result, 'Garmin 연동이 완료되었습니다.');
    });

    test('substitutes bare \$name placeholders', () {
      RemainingSurface.currentLocale = const Locale('en', 'US');
      final result = RemainingSurface.trNow(
        'tournaments.prize_race_entry.body.6',
        '\$base · 보유: \$held',
        {'base': '10 SHARE', 'held': '3'},
      );
      expect(result, '10 SHARE · Owned: 3');
    });
  });

  group('tr', () {
    test('uses currentLocale when context is null', () {
      RemainingSurface.currentLocale = const Locale('en', 'US');
      final result = RemainingSurface.tr(
        null,
        'watch_connection.toast',
        '\${watchType.displayLabel} 연동이 완료되었습니다.',
        {'watchType.displayLabel': 'Garmin'},
      );
      expect(result, 'Garmin connected successfully.');
    });

    testWidgets('resolves the locale from the widget tree', (tester) async {
      RemainingSurface.currentLocale = const Locale('ko', 'KR');
      late BuildContext capturedContext;
      await tester.pumpWidget(
        Localizations(
          locale: const Locale('en', 'US'),
          delegates: const [DefaultWidgetsLocalizations.delegate],
          child: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      final result = RemainingSurface.tr(
        capturedContext,
        'watch_connection.toast',
        '\${watchType.displayLabel} 연동이 완료되었습니다.',
        {'watchType.displayLabel': 'Garmin'},
      );
      expect(result, 'Garmin connected successfully.');
    });
  });
}
