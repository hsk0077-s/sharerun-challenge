import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import '../../core/api/api_exception.dart';
import '../../core/strings/app_strings.dart';
import '../../data/api/secured_action_api_client.dart';
import '../../l10n/remaining_surface.dart';
import 'providers/server_shop_inventory_provider.dart';
import 'streak_item_message.dart';

/// Server statuses that show a friend's recorded pace for this run.
bool friendGhostStatusUnlocks(String status) {
  return status == 'used' || status == 'already_used';
}

String formatPaceSecPerKm(double pace) {
  final total = pace.round();
  final minutes = total ~/ 60;
  final seconds = total % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')} /km';
}

/// Seconds per km from the server, after a friend-ghost ticket is used.
/// Null means this run is comparing against the free own-best pace.
final friendGhostPaceProvider =
    NotifierProvider<FriendGhostPaceNotifier, double?>(
  FriendGhostPaceNotifier.new,
);

class FriendGhostPaceNotifier extends Notifier<double?> {
  var _busy = false;

  @override
  double? build() => null;

  Future<FriendGhostUseResult> claim({
    required String friendUid,
    required String activityId,
  }) async {
    if (_busy) {
      return const FriendGhostUseResult(status: '');
    }
    _busy = true;
    try {
      final result = await ref.read(securedActionApiClientProvider).useFriendGhost(
            friendUid: friendUid,
            activityId: activityId,
          );
      if (friendGhostStatusUnlocks(result.status) && result.paceSecPerKm != null) {
        state = result.paceSecPerKm;
      }
      return result;
    } finally {
      _busy = false;
    }
  }

  void endRun() {
    _busy = false;
    state = null;
  }
}

/// Asks for a friend's verified run, then spends one ticket on the server.
class FriendGhostUseButton extends ConsumerStatefulWidget {
  const FriendGhostUseButton({super.key});

  @override
  ConsumerState<FriendGhostUseButton> createState() =>
      _FriendGhostUseButtonState();
}

class _FriendGhostUseButtonState extends ConsumerState<FriendGhostUseButton> {
  var _busy = false;

  Future<void> _use() async {
    if (_busy) return;
    final owned = ref
            .read(serverShopInventoryProvider)
            .asData
            ?.value
            .friendGhostCount ??
        0;
    if (owned <= 0) {
      _toast(RemainingSurface.tr(
        context,
        'shop.friend_ghost_run.toast',
        '친구 고스트 페이스 보유량이 없습니다. 상점에서 구매해 주세요.',
      ));
      return;
    }
    final picked = await showDialog<_FriendPick>(
      context: context,
      builder: (ctx) => const _FriendRunDialog(),
    );
    if (picked == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final result = await ref.read(friendGhostPaceProvider.notifier).claim(
            friendUid: picked.friendUid,
            activityId: picked.activityId,
          );
      if (!mounted) return;
      final pace = result.paceSecPerKm;
      if (friendGhostStatusUnlocks(result.status) && pace != null) {
        _toast(RemainingSurface.tr(
          context,
          'shop.friend_ghost_run.toast.2',
          '친구 고스트 ${formatPaceSecPerKm(pace)}',
          {'formatPaceSecPerKm(pace)': formatPaceSecPerKm(pace)},
        ));
      } else if (result.status == 'own_best') {
        _toast(RemainingSurface.tr(
          context,
          'shop.friend_ghost_run.toast.3',
          '내 최고 기록 비교는 무료입니다. 티켓을 쓰지 않았습니다.',
        ));
      } else {
        _toast(RemainingSurface.tr(
          context,
          'shop.friend_ghost_run.toast.4',
          '친구 기록을 확인하지 못했습니다.',
        ));
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      _toast(
        streakItemMessage(
          error,
          fallback: error.userMessage,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _toast(RemainingSurface.tr(
        context,
        'shop.friend_ghost_run.toast.5',
        '친구 고스트를 사용하지 못했습니다.',
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final count = ref.watch(serverShopInventoryProvider).asData?.value.friendGhostCount ??
        0;
    final pace = ref.watch(friendGhostPaceProvider);
    final label = pace == null
        ? RemainingSurface.tr(
            context,
            'shop.friend_ghost_run.body',
            '${AppStrings.storeItemFriendGhost} · 보유 $count',
            {
              'AppStrings.storeItemFriendGhost': AppStrings.storeItemFriendGhost,
              'count': count,
            },
          )
        : RemainingSurface.tr(
            context,
            'shop.friend_ghost_run.toast.2',
            '친구 고스트 ${formatPaceSecPerKm(pace)}',
            {'formatPaceSecPerKm(pace)': formatPaceSecPerKm(pace)},
          );
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        key: const Key('use-friend_ghost_pace'),
        onPressed: _busy ? null : _use,
        child: Text(label),
      ),
    );
  }
}

class _FriendPick {
  const _FriendPick({required this.friendUid, required this.activityId});

  final String friendUid;
  final String activityId;
}

class _FriendRunDialog extends StatefulWidget {
  const _FriendRunDialog();

  @override
  State<_FriendRunDialog> createState() => _FriendRunDialogState();
}

class _FriendRunDialogState extends State<_FriendRunDialog> {
  final _friend = TextEditingController();
  final _activity = TextEditingController();

  @override
  void dispose() {
    _friend.dispose();
    _activity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.storeItemFriendGhost),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('friend-ghost-uid'),
            controller: _friend,
            decoration: InputDecoration(
              labelText: RemainingSurface.tr(
                context,
                'shop.friend_ghost_run.hint',
                '친구 아이디',
              ),
            ),
          ),
          TextField(
            key: const Key('friend-ghost-activity'),
            controller: _activity,
            decoration: InputDecoration(
              labelText: RemainingSurface.tr(
                context,
                'shop.friend_ghost_run.hint.2',
                '기록 아이디',
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            final friendUid = _friend.text.trim();
            final activityId = _activity.text.trim();
            if (friendUid.isEmpty || activityId.isEmpty) return;
            Navigator.pop(
              context,
              _FriendPick(friendUid: friendUid, activityId: activityId),
            );
          },
          child: Text(RemainingSurface.tr(
            context,
            'shop.friend_ghost_run.body.2',
            '비교 시작',
          )),
        ),
      ],
    );
  }
}
