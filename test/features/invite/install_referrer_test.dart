import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/constants/store_links.dart';
import 'package:share_run_challenge/features/invite/install_referrer.dart';
import 'package:share_run_challenge/features/invite/invite_link.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    InstallReferrer.debugReadOverride = null;
  });

  tearDown(() => InstallReferrer.debugReadOverride = null);

  group('parseInviteCode', () {
    test('the normal referrer Play hands over', () {
      expect(InstallReferrer.parseInviteCode('invite=ABCD2345'), 'ABCD2345');
    });

    test('a lowercase code is upper-cased', () {
      expect(InstallReferrer.parseInviteCode('invite=abcd2345'), 'ABCD2345');
    });

    test('other campaign parameters around it are ignored', () {
      expect(
        InstallReferrer.parseInviteCode(
            'utm_source=google-play&utm_medium=organic&invite=ABCD2345'),
        'ABCD2345',
      );
    });

    test('a value that is still percent-encoded works', () {
      expect(InstallReferrer.parseInviteCode('invite%3DABCD2345'), 'ABCD2345');
    });

    test('surrounding whitespace is trimmed', () {
      expect(InstallReferrer.parseInviteCode('  invite=ABCD2345 \n'), 'ABCD2345');
    });

    test('empty, null and organic installs give nothing', () {
      expect(InstallReferrer.parseInviteCode(null), isNull);
      expect(InstallReferrer.parseInviteCode(''), isNull);
      expect(InstallReferrer.parseInviteCode('   '), isNull);
      expect(InstallReferrer.parseInviteCode('utm_source=google-play&utm_medium=organic'), isNull);
      expect(InstallReferrer.parseInviteCode('invite='), isNull);
    });

    test('odd values give nothing and never throw', () {
      for (final raw in [
        'invite=AB', // too short
        'invite=${'A' * 40}', // too long
        'invite=AB CD2345', // space
        'invite=AB-CD23', // symbol
        'invite=<script>alert(1)</script>',
        'invite=한글코드',
        'invite=ABCD2345&invite=ZZZZ9999&%',
        '%E0%A4%A', // broken percent escape
        'invite',
        '&&&===',
        'A' * 600, // oversized
      ]) {
        expect(() => InstallReferrer.parseInviteCode(raw), returnsNormally,
            reason: raw);
        expect(InstallReferrer.parseInviteCode(raw), isNull, reason: raw);
      }
    });
  });

  group('takeInviteCode', () {
    test('returns the code the first time and remembers it was asked', () async {
      var reads = 0;
      InstallReferrer.debugReadOverride = () async {
        reads++;
        return 'invite=ABCD2345';
      };
      expect(await InstallReferrer.takeInviteCode(), 'ABCD2345');
      expect(await InstallReferrer.takeInviteCode(), isNull);
      expect(reads, 1);
    });

    test('an install with no referrer is also asked only once', () async {
      var reads = 0;
      InstallReferrer.debugReadOverride = () async {
        reads++;
        return null;
      };
      expect(await InstallReferrer.takeInviteCode(), isNull);
      expect(await InstallReferrer.takeInviteCode(), isNull);
      expect(reads, 1);
    });

    test('a failed read is retried on the next launch', () async {
      var reads = 0;
      InstallReferrer.debugReadOverride = () async {
        reads++;
        if (reads == 1) throw StateError('service unavailable');
        return 'invite=ABCD2345';
      };
      expect(await InstallReferrer.takeInviteCode(), isNull);
      expect(await InstallReferrer.takeInviteCode(), 'ABCD2345');
    });

    test('with no Play service (tests, emulator) it just returns null', () async {
      expect(await InstallReferrer.takeInviteCode(), isNull);
    });
  });

  group('playStoreInviteUrl', () {
    test('code goes into the referrer parameter, encoded', () {
      expect(
        playStoreInviteUrl('ABCD2345'),
        '$kPlayStoreUrl&referrer=invite%3DABCD2345',
      );
      expect(
        playStoreInviteUrl('abcd2345'),
        '$kPlayStoreUrl&referrer=invite%3DABCD2345',
      );
    });

    test('no usable code gives the plain store link', () {
      for (final code in [null, '', ' ', 'no way', '<x>', 'AB', 'A' * 20]) {
        expect(playStoreInviteUrl(code), kPlayStoreUrl, reason: '$code');
      }
    });

    test('the parser reads back what the link builder wrote', () {
      final link = Uri.parse(playStoreInviteUrl('ABCD2345'));
      expect(link.queryParameters['id'], 'com.sharerun.share_run_challenge');
      expect(InstallReferrer.parseInviteCode(link.queryParameters['referrer']),
          'ABCD2345');
    });
  });
}
