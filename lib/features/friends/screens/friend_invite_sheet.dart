import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/theme.dart';
import '../../../l10n/remaining_surface.dart';
import '../../brag_card/brag_card_links.dart';
import '../friend_errors.dart';
import '../friends_models.dart';
import '../friends_providers.dart';

/// Test hook. Production always uses [SharePlus.instance].
@visibleForTesting
Future<ShareResult> Function(ShareParams params)? debugFriendShareOverride;

Future<void> showFriendInviteSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const FriendInviteSheet(),
  );
}

/// Makes a one-time friend code and hands it to the phone's share sheet.
/// No QR is drawn. The code is plain text the friend pastes into the app.
class FriendInviteSheet extends ConsumerStatefulWidget {
  const FriendInviteSheet({super.key});

  static const codeKey = Key('friend-invite-code');
  static const expiresKey = Key('friend-invite-expires');
  static const shareKey = Key('friend-invite-share');
  static const copyKey = Key('friend-invite-copy');
  static const errorKey = Key('friend-invite-error');

  @override
  ConsumerState<FriendInviteSheet> createState() => _FriendInviteSheetState();
}

class _FriendInviteSheetState extends ConsumerState<FriendInviteSheet> {
  FriendInvite? _invite;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_create());
  }

  Future<void> _create() async {
    try {
      final invite = await ref.read(friendsApiProvider).createInvite();
      if (!mounted) return;
      setState(() => _invite = invite);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = friendErrorMessage(context, error));
    }
  }

  /// The text a friend receives. No referral code, uid or nickname.
  String _shareText(BuildContext context, FriendInvite invite) {
    final code = invite.qrPayload;
    final message = RemainingSurface.tr(
      context,
      'friends.invite.share_text',
      '쉐어런에서 친구 해요. 앱 > 마이페이지 > 친구 > 친구 코드 입력에 붙여 넣어 주세요(24시간 동안 한 번만 쓸 수 있어요). 코드: $code',
      {'code': code},
    );
    return '$message\n$sharerunPlayStoreUrl';
  }

  Future<void> _share(FriendInvite invite) async {
    final subject = RemainingSurface.tr(
        context, 'friends.invite.share_subject', '쉐어런 친구 코드');
    final params = ShareParams(
      text: _shareText(context, invite),
      subject: subject,
      title: subject,
    );
    final send = debugFriendShareOverride ?? SharePlus.instance.share;
    try {
      await send(params);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(friendErrorMessage(context, 'share')),
      ));
    }
  }

  Future<void> _copy(FriendInvite invite) async {
    await Clipboard.setData(ClipboardData(text: invite.qrPayload));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(RemainingSurface.tr(context, 'friends.invite.copied', '복사했어요.')),
    ));
  }

  String _expiryText(BuildContext context, DateTime at) {
    String two(int n) => n.toString().padLeft(2, '0');
    final local = at.toLocal();
    final time = '${two(local.month)}/${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
    return RemainingSurface.tr(
      context,
      'friends.invite.expires',
      '$time까지 쓸 수 있어요',
      {'time': time},
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    final invite = _invite;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          tokens.spacing.page,
          0,
          tokens.spacing.page,
          tokens.spacing.page + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              RemainingSurface.tr(context, 'friends.invite.title', '친구 코드'),
              style:
                  textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            SizedBox(height: tokens.spacing.xs),
            Text(RemainingSurface.tr(context, 'friends.invite.hint',
                '이 코드를 친구에게 보내 주세요. 24시간 동안 한 번만 쓸 수 있어요.')),
            SizedBox(height: tokens.spacing.md),
            if (_error != null)
              Text(_error!, key: FriendInviteSheet.errorKey)
            else if (invite == null)
              const Center(child: CircularProgressIndicator())
            else ...[
              Container(
                padding: EdgeInsets.all(tokens.spacing.sm),
                decoration: BoxDecoration(
                  color: tokens.colors.surface,
                  borderRadius: tokens.radii.card,
                  border: Border.all(color: tokens.colors.outline),
                ),
                child: SelectableText(
                  invite.qrPayload,
                  key: FriendInviteSheet.codeKey,
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (invite.expiresAt != null) ...[
                SizedBox(height: tokens.spacing.xs),
                Text(
                  _expiryText(context, invite.expiresAt!),
                  key: FriendInviteSheet.expiresKey,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall,
                ),
              ],
              SizedBox(height: tokens.spacing.md),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      key: FriendInviteSheet.shareKey,
                      onPressed: () => unawaited(_share(invite)),
                      icon: const Icon(Icons.ios_share),
                      label: Text(RemainingSurface.tr(
                          context, 'friends.invite.share', '공유하기')),
                    ),
                  ),
                  SizedBox(width: tokens.spacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: FriendInviteSheet.copyKey,
                      onPressed: () => unawaited(_copy(invite)),
                      icon: const Icon(Icons.copy),
                      label: Text(RemainingSurface.tr(
                          context, 'friends.invite.copy', '복사')),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
