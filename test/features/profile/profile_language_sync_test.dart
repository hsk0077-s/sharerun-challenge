import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/profile/profile_language_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('effectiveLanguage', () {
    test('the runner\'s choice wins over the phone', () {
      expect(
        ProfileLanguageSync.effectiveLanguage(
          chosen: const Locale('ja', 'JP'),
          device: const Locale('ko', 'KR'),
        ),
        'ja',
      );
    });

    test('follows the phone when nothing was chosen', () {
      expect(
        ProfileLanguageSync.effectiveLanguage(device: const Locale('vi', 'VN')),
        'vi',
      );
      expect(
        ProfileLanguageSync.effectiveLanguage(device: const Locale('zh', 'CN')),
        'zh',
      );
    });

    test('a language the app does not ship is English, as on screen', () {
      expect(
        ProfileLanguageSync.effectiveLanguage(device: const Locale('ru', 'RU')),
        'en',
      );
    });
  });

  test('country is two capital letters or nothing', () {
    expect(ProfileLanguageSync.countryOf(const Locale('ko', 'KR')), 'KR');
    expect(ProfileLanguageSync.countryOf(const Locale('en', 'us')), 'US');
    expect(ProfileLanguageSync.countryOf(const Locale('en')), isNull);
  });

  test('sends once, then not again for the same account and language',
      () async {
    final sent = <String>[];
    Future<void> send(String language, String? country) async =>
        sent.add('$language/${country ?? '-'}');

    expect(
      await ProfileLanguageSync.sync(
        uid: 'u1',
        send: send,
        device: const Locale('ja', 'JP'),
      ),
      isTrue,
    );
    expect(
      await ProfileLanguageSync.sync(
        uid: 'u1',
        send: send,
        device: const Locale('ja', 'JP'),
      ),
      isFalse,
    );

    expect(sent, ['ja/JP']);
  });

  test('a new language choice is sent again', () async {
    final sent = <String>[];
    Future<void> send(String language, String? country) async =>
        sent.add(language);

    await ProfileLanguageSync.sync(
      uid: 'u1',
      send: send,
      device: const Locale('ko', 'KR'),
    );
    await ProfileLanguageSync.sync(
      uid: 'u1',
      chosen: const Locale('en', 'US'),
      send: send,
      device: const Locale('ko', 'KR'),
    );

    expect(sent, ['ko', 'en']);
  });

  test('a second account on the same phone is sent too', () async {
    final sent = <String>[];
    Future<void> send(String language, String? country) async =>
        sent.add(language);

    await ProfileLanguageSync.sync(
      uid: 'u1',
      send: send,
      device: const Locale('ko', 'KR'),
    );
    await ProfileLanguageSync.sync(
      uid: 'u2',
      send: send,
      device: const Locale('ko', 'KR'),
    );

    expect(sent, ['ko', 'ko']);
  });

  test('a failed send is tried again next time and never throws', () async {
    var calls = 0;
    Future<void> failing(String language, String? country) async {
      calls++;
      throw StateError('offline');
    }

    final first = await ProfileLanguageSync.sync(
      uid: 'u1',
      send: failing,
      device: const Locale('ko', 'KR'),
    );
    final second = await ProfileLanguageSync.sync(
      uid: 'u1',
      send: failing,
      device: const Locale('ko', 'KR'),
    );

    expect(first, isFalse);
    expect(second, isFalse);
    expect(calls, 2);
  });
}
