/// Pulls the one-time friend token out of whatever the user pasted.
///
/// The shared text reads "... Code: sharerun-friend:TOKEN" in the sender's
/// language, so the token is found by its prefix. A bare token on its own is
/// accepted too. Anything else gives null and the server is never called.
const friendCodePrefix = 'sharerun-friend:';

// The server makes 32 characters (token_urlsafe(24)). It checks 20..64.
final _prefixed = RegExp(
  '${RegExp.escape(friendCodePrefix)}([A-Za-z0-9_-]{20,64})(?![A-Za-z0-9_-])',
  caseSensitive: false,
);
final _bare = RegExp(r'^[A-Za-z0-9_-]{20,64}$');

String? extractFriendToken(String? text) {
  final trimmed = (text ?? '').trim();
  if (trimmed.isEmpty) return null;
  final match = _prefixed.firstMatch(trimmed);
  if (match != null) return match.group(1);
  if (_bare.hasMatch(trimmed)) return trimmed;
  return null;
}
