import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/router/route_names.dart';
import 'package:share_run_challenge/features/watch_link/watch_run_link.dart';
import 'package:share_run_challenge/l10n/watch_run_link_copy.dart';

void main() {
  group('WatchRunLink.parse', () {
    test('reads the activity id from sharerun://run/<id>', () {
      final link = WatchRunLink.parse('sharerun://run/watch_1731234567890');
      expect(link, isNotNull);
      expect(link!.activityId, 'watch_1731234567890');
      expect(link.hasActivityId, isTrue);
      expect(link.location, '${RouteNames.watchRunRecord}?id=watch_1731234567890');
      expect(link.toUriString(), 'sharerun://run/watch_1731234567890');
    });

    test('opens history when the id is missing', () {
      final link = WatchRunLink.parse('sharerun://run');
      expect(link, isNotNull);
      expect(link!.hasActivityId, isFalse);
      expect(link.location, RouteNames.watchRunRecord);
      expect(link.toUriString(), 'sharerun://run');
    });

    test('accepts an id query and ignores other schemes', () {
      expect(
        WatchRunLink.parse('sharerun://run?id=watch_abc')?.activityId,
        'watch_abc',
      );
      expect(WatchRunLink.parse('kakaoc45c63710e60f98b3fe617ae0b75c274://kakaolink'), isNull);
      expect(WatchRunLink.parse('https://sharerun.app/run/watch_abc'), isNull);
      expect(WatchRunLink.parse(''), isNull);
      expect(WatchRunLink.parse(null), isNull);
    });

    test('decodes a percent-encoded id', () {
      final link = WatchRunLink.parse('sharerun://run/watch%2Fspecial');
      expect(link?.activityId, 'watch/special');
    });
  });

  test('copy exists in every locale and is not left as Korean', () {
    for (final entry in watchRunLinkCopyRows.entries) {
      expect(entry.value, hasLength(watchRunLinkLanguageOrder.length),
          reason: entry.key);
      for (var i = 0; i < entry.value.length; i++) {
        expect(entry.value[i].trim(), isNotEmpty, reason: '${entry.key}.$i');
        if (i != 0) {
          expect(entry.value[i], isNot(entry.value.first),
              reason: '${entry.key}.${watchRunLinkLanguageOrder[i]}=ko');
        }
      }
    }
    expect(watchRunLinkCopy(const Locale('ko'), 'title'), '러닝 기록');
    expect(watchRunLinkCopy(const Locale('en'), 'title'), 'Run record');
  });
}
