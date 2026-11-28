import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../l10n/remaining_surface.dart';
import '../cheer_errors.dart';
import '../cheers_models.dart';
import '../cheers_providers.dart';
import '../friends_providers.dart';

Future<void> showCheerSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const CheerSettingsSheet(),
  );
}

/// Cheer alerts for everyone and for each friend. A switch that is ON means
/// "I get these alerts" (the server stores the opposite: muteAll /
/// mutedFriends). A switch saves at once and goes back if the server refuses.
/// Nobody is told about a switch.
class CheerSettingsSheet extends ConsumerStatefulWidget {
  const CheerSettingsSheet({super.key});

  static const muteAllKey = Key('cheer-mute-all');
  static const noteKey = Key('cheer-settings-note');
  static Key friendKey(String uid) => Key('cheer-mute-friend-$uid');

  @override
  ConsumerState<CheerSettingsSheet> createState() => _CheerSettingsSheetState();
}

class _CheerSettingsSheetState extends ConsumerState<CheerSettingsSheet> {
  /// What the switches show right now. Null until the server answers.
  CheerSettings? _shown;
  bool _busy = false;

  Future<void> _save(
    CheerSettings optimistic, {
    bool? muteAll,
    String? friendUid,
    bool? muted,
  }) async {
    final before = _shown ?? ref.read(cheerSettingsProvider).value;
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _shown = optimistic;
      _busy = true;
    });
    try {
      final saved = await ref.read(cheersApiProvider).updateSettings(
            muteAll: muteAll,
            friendUid: friendUid,
            muted: muted,
          );
      if (!mounted) return;
      setState(() => _shown = saved);
      ref.invalidate(cheerSettingsProvider);
    } catch (error) {
      if (!mounted) return;
      setState(() => _shown = before);
      messenger.showSnackBar(
        SnackBar(content: Text(cheerErrorMessage(context, error))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    final settings = _shown ?? ref.watch(cheerSettingsProvider).value;
    final friends = ref.watch(friendsListProvider).value ?? const [];
    final loadFailed = settings == null && ref.watch(cheerSettingsProvider).hasError;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          tokens.spacing.page,
          0,
          tokens.spacing.page,
          tokens.spacing.page,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              RemainingSurface.tr(context, 'cheers.settings.title', '응원 설정'),
              style:
                  textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            SizedBox(height: tokens.spacing.xs),
            Text(
              RemainingSurface.tr(context, 'cheers.settings.note',
                  '꺼도 친구에게는 알려지지 않아요. 받은 응원은 응원함에 그대로 쌓여요.'),
              key: CheerSettingsSheet.noteKey,
              style: textTheme.bodyMedium,
            ),
            SizedBox(height: tokens.spacing.sm),
            if (settings == null)
              Padding(
                padding: EdgeInsets.all(tokens.spacing.md),
                child: Center(
                  child: loadFailed
                      ? Text(RemainingSurface.tr(context,
                          'friends.error.generic', '잠시 후 다시 시도해 주세요.'))
                      : const CircularProgressIndicator(),
                ),
              )
            else ...[
              SwitchListTile(
                key: CheerSettingsSheet.muteAllKey,
                contentPadding: EdgeInsets.zero,
                title: Text(RemainingSurface.tr(
                    context, 'cheers.settings.receive_all', '응원 알림 받기')),
                // 켜짐 = 받음. 서버에는 반대로 muteAll로 저장한다.
                value: !settings.muteAll,
                onChanged: _busy
                    ? null
                    : (receive) => unawaited(_save(
                          settings.copyWith(muteAll: !receive),
                          muteAll: !receive,
                        )),
              ),
              if (friends.isNotEmpty) ...[
                const Divider(),
                Text(
                  RemainingSurface.tr(context, 'cheers.settings.friends_receive',
                      '친구별 응원 알림'),
                  style: textTheme.titleSmall,
                ),
                for (final friend in friends)
                  SwitchListTile(
                    key: CheerSettingsSheet.friendKey(friend.uid),
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      friend.nickname.trim().isEmpty
                          ? RemainingSurface.tr(
                              context, 'friends.nameless', '이름 없는 러너')
                          : friend.nickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // 켜짐 = 이 친구의 응원 알림을 받음.
                    value: !settings.mutedFriends.contains(friend.uid),
                    onChanged: _busy
                        ? null
                        : (receive) => unawaited(_save(
                              settings.copyWith(
                                mutedFriends: [
                                  for (final uid in settings.mutedFriends)
                                    if (uid != friend.uid) uid,
                                  if (!receive) friend.uid,
                                ],
                              ),
                              friendUid: friend.uid,
                              muted: !receive,
                            )),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
