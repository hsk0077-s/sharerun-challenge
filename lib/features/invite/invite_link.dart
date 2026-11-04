import '../../core/constants/store_links.dart';

/// Invite codes the server hands out are 8 characters from `A-Z` (no I, L, O)
/// and `2-9`. The checks here are looser on purpose (4 to 16 letters and
/// digits, any case) so a code format change on the server does not break the
/// link, but strict enough that nothing odd ever lands in a store URL.
final _inviteCodePattern = RegExp(r'^[A-Za-z0-9]{4,16}$');

/// `ABCD2345` for a usable code, otherwise null.
String? normalizeInviteCode(String? raw) {
  final code = raw?.trim() ?? '';
  if (!_inviteCodePattern.hasMatch(code)) return null;
  return code.toUpperCase();
}

/// Store link that carries the sender's invite code to Play Install Referrer:
/// `...&referrer=invite%3DABCD2345`. Without a usable code it is the plain
/// store link.
String playStoreInviteUrl(String? inviteCode) {
  final code = normalizeInviteCode(inviteCode);
  if (code == null) return kPlayStoreUrl;
  return '$kPlayStoreUrl&referrer=${Uri.encodeComponent('invite=$code')}';
}
