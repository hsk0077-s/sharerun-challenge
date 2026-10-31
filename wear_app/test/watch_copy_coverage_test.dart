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
}
