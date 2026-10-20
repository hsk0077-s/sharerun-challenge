import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/legal_constants.dart';

/// Opens the public privacy policy / account deletion pages in the browser.
abstract final class LegalLinks {
  static Future<bool> openPrivacyPolicy() =>
      _open(LegalConstants.privacyPolicyUrl);

  static Future<bool> openAccountDeletion() =>
      _open(LegalConstants.accountDeletionUrl);

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
