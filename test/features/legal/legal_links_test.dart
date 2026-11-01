import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/constants/legal_constants.dart';
import 'package:share_run_challenge/features/legal/legal_links.dart';

void main() {
  const docs = [
    LegalConstants.privacyPolicyUrl,
    LegalConstants.termsOfServiceUrl,
    LegalConstants.accountDeletionUrl,
  ];

  test('Korean keeps the authoritative page', () {
    for (final url in docs) {
      expect(localizedLegalUrl(url, 'ko'), url);
    }
  });

  test('each language opens its own translation, unknown ones fall back to English', () {
    expect(localizedLegalUrl(LegalConstants.termsOfServiceUrl, 'ja'),
        'https://share-run-challenge.web.app/terms.ja.html');
    expect(localizedLegalUrl(LegalConstants.privacyPolicyUrl, 'zh'),
        'https://share-run-challenge.web.app/privacy.zh.html');
    expect(localizedLegalUrl(LegalConstants.accountDeletionUrl, 'xx'),
        'https://share-run-challenge.web.app/account-deletion.en.html');
  });

  test('every language the app links to has a page in site/', () {
    for (final url in docs) {
      final name = url.split('/').last.replaceAll('.html', '');
      for (final code in legalPageLanguages) {
        expect(File('site/$name.$code.html').existsSync(), isTrue,
            reason: 'site/$name.$code.html is missing');
      }
    }
  });
}
