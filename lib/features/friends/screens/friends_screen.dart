import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../core/theme/theme.dart';
import '../../../l10n/remaining_surface.dart';
import '../cheer_errors.dart';
import '../cheers_providers.dart';
import '../friend_errors.dart';
import '../friends_models.dart';
import '../friends_providers.dart';
import 'friend_accept_sheet.dart';
import 'cheer_settings_sheet.dart';
import 'friend_invite_sheet.dart';
import 'friend_runs_section.dart';

/// The small "Friends" row on the My tab. It only opens the friends screen.
class MyPageFriendsEntry extends StatelessWidget {
  const MyPageFriendsEntry({super.key});

  static const entryKey = Key('my-page-friends-entry');

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(top: tokens.spacing.sm),
      child: InkWell(
        key: entryKey,
        borderRadius: tokens.radii.card,
        onTap: () => context.push(RouteNames.friends),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Icon(Icons.people_outline, color: tokens.colors.ink),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  RemainingSurface.tr(context, 'friends.entry.title', '친구'),
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: tokens.colors.ink,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: tokens.colors.ink),
            ],
          ),
        ),
      ),
    );
  }
}

enum _RowAction { remove, block, reportAndBlock, toggleMute }

/// The friend list. A friend shows as the default avatar and a nickname only;
/// the server gives no place, route or run record and none is shown.
class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  static const createKey = Key('friends-create-code');
  static const enterKey = Key('friends-enter-code');
  static const listKey = Key('friends-list');
  static const emptyKey = Key('friends-empty');
  static const inboxButtonKey = Key('friends-cheer-inbox');
  static const inboxBadgeKey = Key('friends-cheer-badge');
  static const settingsButtonKey = Key('friends-cheer-settings');
  static const muteItemKey = Key('friend-menu-mute');
  static const retryKey = Key('friends-retry');
  static const confirmKey = Key('friends-confirm');
  static const cancelKey = Key('friends-cancel');
  static Key rowKey(String uid) => Key('friend-row-$uid');
  static Key menuKey(String uid) => Key('friend-menu-$uid');
  static const removeItemKey = Key('friend-menu-remove');
  static const blockItemKey = Key('friend-menu-block');
  static const reportItemKey = Key('friend-menu-report');
  static Key reasonKey(FriendReportReason reason) =>
      Key('friend-reason-${reason.wire}');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.srcTokens;
    final friends = ref.watch(friendsListProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          RemainingSurface.tr(context, 'friends.screen.title', '친구'),
        ),
        actions: [
          const _InboxButton(),
          IconButton(
            key: settingsButtonKey,
            tooltip: RemainingSurface.tr(
                context, 'cheers.settings.title', '응원 설정'),
            icon: const Icon(Icons.tune),
            onPressed: () => unawaited(showCheerSettingsSheet(context)),
          ),
        ],
      ),
      body: friends.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _LoadFailed(
          onRetry: () => ref.invalidate(friendsListProvider),
        ),
        data: (rows) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(friendsListProvider);
            ref.invalidate(friendRunsProvider);
            ref.invalidate(cheerInboxProvider);
            ref.invalidate(cheerSettingsProvider);
            await ref.read(friendsListProvider.future);
            try {
              await ref.read(friendRunsProvider.future);
            } catch (_) {
              // The section shows its own retry.
            }
          },
          child: ListView(
            key: listKey,
            padding: EdgeInsets.all(tokens.spacing.page),
            children: [
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      key: createKey,
                      onPressed: () =>
                          unawaited(showFriendInviteSheet(context)),
                      icon: const Icon(Icons.share_outlined),
                      label: Text(
                        RemainingSurface.tr(
                            context, 'friends.create_code', '친구 코드 만들기'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  SizedBox(width: tokens.spacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: enterKey,
                      onPressed: () =>
                          unawaited(showFriendAcceptSheet(context)),
                      icon: const Icon(Icons.content_paste),
                      label: Text(
                        RemainingSurface.tr(
                            context, 'friends.enter_code', '친구 코드 입력'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: tokens.spacing.md),
              const FriendRunsSection(),
              SizedBox(height: tokens.spacing.md),
              if (rows.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: tokens.spacing.lg),
                  child: Text(
                    RemainingSurface.tr(context, 'friends.empty',
                        '아직 친구가 없어요. 친구 코드를 만들어 보내 보세요.'),
                    key: emptyKey,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                )
              else
                for (final friend in rows) _FriendRow(friend: friend),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendRow extends ConsumerWidget {
  const _FriendRow({required this.friend});

  final Friend friend;

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    _RowAction action,
  ) async {
    final api = ref.read(friendsApiProvider);
    final messenger = ScaffoldMessenger.of(context);
    String? reason;
    switch (action) {
      case _RowAction.remove:
        final ok = await _confirm(
          context,
          title:
              RemainingSurface.tr(context, 'friends.remove.title', '친구를 끊을까요?'),
          body: RemainingSurface.tr(context, 'friends.remove.body',
              '서로의 친구 목록에서 사라져요. 상대에게는 알림이 가지 않아요.'),
          confirm: RemainingSurface.tr(context, 'friends.action.remove', '끊기'),
        );
        if (ok != true) return;
      case _RowAction.block:
        final ok = await _confirm(
          context,
          title: RemainingSurface.tr(context, 'friends.block.title', '차단할까요?'),
          body: RemainingSurface.tr(context, 'friends.block.body',
              '서로의 친구 목록에서 사라지고, 이 사람의 친구 코드는 쓸 수 없어요. 상대에게는 알림이 가지 않아요.'),
          confirm: RemainingSurface.tr(context, 'friends.action.block', '차단하기'),
        );
        if (ok != true) return;
      case _RowAction.reportAndBlock:
        final picked = await _pickReason(context);
        if (picked == null) return;
        reason = picked.wire;
      case _RowAction.toggleMute:
        final muted = ref
                .read(cheerSettingsProvider)
                .value
                ?.mutedFriends
                .contains(friend.uid) ??
            false;
        try {
          await ref.read(cheersApiProvider).updateSettings(
                friendUid: friend.uid,
                muted: !muted,
              );
          ref.invalidate(cheerSettingsProvider);
        } catch (error) {
          if (!context.mounted) return;
          messenger.showSnackBar(
            SnackBar(content: Text(cheerErrorMessage(context, error))),
          );
        }
        return;
    }
    if (!context.mounted) return;
    final done = switch (action) {
      _RowAction.remove =>
        RemainingSurface.tr(context, 'friends.done.removed', '친구를 끊었어요.'),
      _ => RemainingSurface.tr(context, 'friends.done.blocked', '차단했어요.'),
    };
    try {
      if (action == _RowAction.remove) {
        await api.remove(friend.uid);
      } else {
        await api.block(friend.uid, reportReason: reason);
      }
      ref.invalidate(friendsListProvider);
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (error) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(friendErrorMessage(context, error))),
      );
    }
  }

  Future<bool?> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String confirm,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            key: FriendsScreen.cancelKey,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(RemainingSurface.tr(
                dialogContext, 'friends.action.cancel', '취소')),
          ),
          TextButton(
            key: FriendsScreen.confirmKey,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirm),
          ),
        ],
      ),
    );
  }

  Future<FriendReportReason?> _pickReason(BuildContext context) {
    String label(FriendReportReason reason) => switch (reason) {
          FriendReportReason.offensiveName => RemainingSurface.tr(
              context, 'friends.reason.offensive_name', '부적절한 이름'),
          FriendReportReason.sexual =>
            RemainingSurface.tr(context, 'friends.reason.sexual', '성적인 내용'),
          FriendReportReason.hate =>
            RemainingSurface.tr(context, 'friends.reason.hate', '혐오 표현'),
          FriendReportReason.spam =>
            RemainingSurface.tr(context, 'friends.reason.spam', '스팸'),
          FriendReportReason.other =>
            RemainingSurface.tr(context, 'friends.reason.other', '기타'),
        };
    return showDialog<FriendReportReason>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(RemainingSurface.tr(
            dialogContext, 'friends.menu.report_block', '신고하고 차단')),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(RemainingSurface.tr(dialogContext,
                'friends.report.body', '신고 이유를 골라 주세요. 상대에게는 알림이 가지 않아요.')),
          ),
          for (final reason in FriendReportReason.values)
            SimpleDialogOption(
              key: FriendsScreen.reasonKey(reason),
              onPressed: () => Navigator.of(dialogContext).pop(reason),
              child: Text(label(reason)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = friend.nickname.trim().isEmpty
        ? RemainingSurface.tr(context, 'friends.nameless', '이름 없는 러너')
        : friend.nickname;
    final muted = ref
            .watch(cheerSettingsProvider)
            .value
            ?.mutedFriends
            .contains(friend.uid) ??
        false;
    return ListTile(
      key: FriendsScreen.rowKey(friend.uid),
      contentPadding: EdgeInsets.zero,
      // The server does not tell us another person's avatar, so everyone gets
      // the neutral default.
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: PopupMenuButton<_RowAction>(
        key: FriendsScreen.menuKey(friend.uid),
        onSelected: (action) => unawaited(_onAction(context, ref, action)),
        itemBuilder: (menuContext) => [
          PopupMenuItem(
            key: FriendsScreen.removeItemKey,
            value: _RowAction.remove,
            child: Text(RemainingSurface.tr(
                menuContext, 'friends.menu.remove', '친구 끊기')),
          ),
          PopupMenuItem(
            key: FriendsScreen.blockItemKey,
            value: _RowAction.block,
            child: Text(
                RemainingSurface.tr(menuContext, 'friends.menu.block', '차단')),
          ),
          PopupMenuItem(
            key: FriendsScreen.reportItemKey,
            value: _RowAction.reportAndBlock,
            child: Text(RemainingSurface.tr(
                menuContext, 'friends.menu.report_block', '신고하고 차단')),
          ),
          PopupMenuItem(
            key: FriendsScreen.muteItemKey,
            value: _RowAction.toggleMute,
            child: Text(muted
                ? RemainingSurface.tr(menuContext, 'cheers.menu.unmute',
                    '이 친구 응원 알림 켜기')
                : RemainingSurface.tr(menuContext, 'cheers.menu.mute',
                    '이 친구 응원 알림 끄기')),
          ),
        ],
      ),
    );
  }
}

/// The inbox icon. A small number shows how many cheers are unread; with
/// none there is no badge.
class _InboxButton extends ConsumerWidget {
  const _InboxButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(cheerInboxProvider).value?.unreadCount ?? 0;
    return IconButton(
      key: FriendsScreen.inboxButtonKey,
      tooltip: RemainingSurface.tr(context, 'cheers.inbox.title', '받은 응원'),
      icon: unread > 0
          ? Badge(
              key: FriendsScreen.inboxBadgeKey,
              label: Text(unread > 99 ? '99+' : '$unread'),
              child: const Icon(Icons.favorite_border),
            )
          : const Icon(Icons.favorite_border),
      onPressed: () => context.push(RouteNames.cheerInbox),
    );
  }
}

class _LoadFailed extends StatelessWidget {
  const _LoadFailed({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(tokens.spacing.page),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              RemainingSurface.tr(
                  context, 'friends.load_failed', '친구 목록을 불러오지 못했어요.'),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: tokens.spacing.sm),
            FilledButton(
              key: FriendsScreen.retryKey,
              onPressed: onRetry,
              child:
                  Text(RemainingSurface.tr(context, 'friends.retry', '다시 시도')),
            ),
          ],
        ),
      ),
    );
  }
}
