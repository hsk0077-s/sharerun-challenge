import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/legal_constants.dart';
import '../../l10n/remaining_surface.dart';

/// Languages that have their own copy of the three legal pages in `site/`
/// (`terms.ja.html`, ...). Korean is the authoritative text at `terms.html`.
const legalPageLanguages = {
  'en', 'ja', 'zh', 'es', 'pt', 'de', 'fr', 'vi', 'th', 'id',
};

/// The hosted legal page for [languageCode]: the Korean original for `ko`,
/// that language's translation when there is one, English otherwise.
String localizedLegalUrl(String koreanUrl, String languageCode) {
  if (languageCode == 'ko' || !koreanUrl.endsWith('.html')) return koreanUrl;
  final code = legalPageLanguages.contains(languageCode) ? languageCode : 'en';
  return '${koreanUrl.substring(0, koreanUrl.length - '.html'.length)}.$code.html';
}

String _forCurrentLanguage(String koreanUrl) =>
    localizedLegalUrl(koreanUrl, RemainingSurface.currentLocale.languageCode);

/// Opens the public privacy policy / account deletion pages in the browser.
abstract final class LegalLinks {
  static Future<bool> openPrivacyPolicy() =>
      _open(_forCurrentLanguage(LegalConstants.privacyPolicyUrl));

  static Future<bool> openTermsOfService() =>
      _open(_forCurrentLanguage(LegalConstants.termsOfServiceUrl));

  static Future<bool> openAccountDeletion() =>
      _open(_forCurrentLanguage(LegalConstants.accountDeletionUrl));

  static Future<bool> _open(String url) async {
    try {
      return await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (error, stackTrace) {
      debugPrint('LegalLinks: $error\n$stackTrace');
      return false;
    }
  }
}
