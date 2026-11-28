import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_wear/l10n/watch_copy.dart';

void main() {
  test('watch face, minutes, rank, and pairing errors exist in every locale', () {
    final missing = missingWatchCopyKeys();
    expect(missing, isEmpty, reason: missing.join('\n'));
  });

  test('a Korean pairing code stays the sentence the screen already showed', () {
    const ko = Locale('ko');
    expect(
      WatchCopy.pairingError(ko, 'bad_code'),
      '코드가 맞지 않거나 만료됐어요.',
    );
    expect(WatchCopy.minutes(ko, 12), '12분');
    expect(WatchCopy.minutes(const Locale('en'), 12), '12 min');
    expect(WatchCopy.pairingError(const Locale('en'), 'not-a-code'), 'not-a-code');
  });

  test('tier codes become the phone app name in every watch language', () {
    expect(watchTierLabel(const Locale('ko'), 'cheetah_gold'), '치타 골드');
    expect(watchTierLabel(const Locale('en'), 'cheetah_gold'), 'Cheetah Gold');
    expect(watchTierLabel(const Locale('ja'), 'wolf_bronze'), 'オオカミ ブロンズ');
    expect(watchTierLabel(const Locale('fr'), 'beagle_silver'), 'Beagle Argent');
    expect(watchTierLabel(const Locale('ko'), 'cheetah'), '치타');
    expect(watchTierLabel(const Locale('en'), 'cheetah'), 'Cheetah');
    expect(watchTierLabel(const Locale('ko'), 'snail'), isNull);
    expect(watchTierLabel(const Locale('ko'), 'maltese'), isNull);
    expect(watchTierLabel(const Locale('ko'), '  CHEETAH_GOLD '), '치타 골드');
    for (final code in watchLanguageOrder) {
      final label = watchTierLabel(Locale(code), 'cheetah_gold');
      expect(label, isNotNull, reason: code);
      expect(label!.trim(), isNotEmpty, reason: code);
      if (code != 'ko') expect(label, isNot('치타 골드'), reason: code);
    }
  });
}
