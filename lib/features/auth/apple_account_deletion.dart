import 'package:flutter/foundation.dart';

/// Before an account is deleted on the iPhone: if Sign in with Apple is linked,
/// get a fresh one-time Apple code so the server can revoke the Apple grant
/// (Apple's rule for apps that offer Sign in with Apple).
///
/// Returns null when there is nothing to revoke, the person closes the Apple
/// sheet, or anything fails. Deleting the account never waits on Apple.
Future<String?> appleCodeForAccountDeletion({
  required TargetPlatform platform,
  required Future<List<String>> Function() fetchProviders,
  required Future<String?> Function() askAppleCode,
  void Function()? beforeAsking,
}) async {
  if (platform != TargetPlatform.iOS && platform != TargetPlatform.macOS) {
    return null;
  }
  try {
    final providers = await fetchProviders();
    if (!providers.contains('apple')) return null;
    beforeAsking?.call();
    final code = await askAppleCode();
    return (code == null || code.isEmpty) ? null : code;
  } catch (error) {
    debugPrint('Apple revoke code skipped: $error');
    return null;
  }
}
