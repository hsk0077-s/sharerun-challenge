import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/theme.dart';
import '../../../l10n/remaining_surface.dart';
import '../cheer_errors.dart';
import '../cheer_format.dart';
import '../cheers_models.dart';
import '../cheers_providers.dart';

/// "Friend runs": each friend's verified runs of the last 7 days with a
/// one-tap cheer. A row shows a nickname, distance, time and a day. No place,
/// route or start time exists in the data, so none is shown.
class FriendRunsSection extends ConsumerStatefulWidget {
  const FriendRunsSection({super.key});

  static const titleKey = Key('friend-runs-title');
  static const emptyKey = Key('friend-runs-empty');
  static const failedKey = Key('friend-runs-failed');
  static const retryKey = Key('friend-runs-retry');
  static const sheetKey = Key('cheer-reaction-sheet');
  static Key rowKey(String activityId) => Key('friend-run-$activityId');
  static Key buttonKey(String activityId) => Key('cheer-button-$activityId');
  static Key emojiKey(String activityId) => Key('cheer-emoji-$activityId');
  static Key reactionKey(CheerReaction reaction) =>
      Key('cheer-reaction-${reaction.wire}');

  @override
  ConsumerState<FriendRunsSection> createState() => _FriendRunsSectionState();
}

class _FriendRunsSectionState extends ConsumerState<FriendRunsSection> {
  /// Cheers sent from this screen, shown at once.
  final Map<String, CheerReaction> _sent = {};
  final Set<String> _sending = {};

  Future<CheerReaction?> _pickReaction() {
    return showModalBottomSheet<CheerReaction>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          key: FriendRunsSection.sheetKey,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                RemainingSurface.tr(
                    sheetContext, 'cheers.sheet.title', '어떤 응원을 보낼까요?'),
                style: Theme.of(sheetContext)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.spaceEvenly,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final reaction in CheerReaction.values)
                    InkWell(
                      key: FriendRunsSection.reactionKey(reaction),
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.of(sheetContext).pop(reaction),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(reaction.emoji,
                                style: const TextStyle(fontSize: 30)),
                            const SizedBox(height: 4),
                            Text(cheerReactionLabel(sheetContext, reaction)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cheer(FriendRun run) async {
    if (_sending.contains(run.activityId)) return;
    final reaction = await _pickReaction();
    if (reaction == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending.add(run.activityId));
    try {
      await ref
          .read(cheersApiProvider)
          .send(run.friendUid, run.activityId, reaction);
      if (!mounted) return;
      setState(() => _sent[run.activityId] = reaction);
    } catch (error) {
      if (!mounted) return;
      if (error is ApiException && error.detail == 'already_cheered') {
        ref.invalidate(friendRunsProvider);
      }
      messenger.showSnackBar(
        SnackBar(content: Text(cheerErrorMessage(context, error))),
      );
    } finally {
      if (mounted) setState(() => _sending.remove(run.activityId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final runs = ref.watch(friendRunsProvider);
    final today = kstDay(ref.watch(cheerClockProvider)());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          RemainingSurface.tr(context, 'cheers.runs.title', '친구 달리기'),
          key: FriendRunsSection.titleKey,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        SizedBox(height: tokens.spacing.xs),
        runs.when(
          skipLoadingOnReload: true,
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => Row(
            children: [
              Expanded(
                child: Text(
                  RemainingSurface.tr(context, 'cheers.runs.load_failed',
                      '친구 달리기를 불러오지 못했어요.'),
                  key: FriendRunsSection.failedKey,
                ),
              ),
              TextButton(
                key: FriendRunsSection.retryKey,
                onPressed: () => ref.invalidate(friendRunsProvider),
                child:
                    Text(RemainingSurface.tr(context, 'friends.retry', '다시 시도')),
              ),
            ],
          ),
          data: (rows) {
            if (rows.isEmpty) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: tokens.spacing.sm),
                child: Text(
                  RemainingSurface.tr(context, 'cheers.runs.empty',
                      '최근 7일 동안 친구 달리기가 없어요.'),
                  key: FriendRunsSection.emptyKey,
                ),
              );
            }
            return Column(
              children: [
                for (final run in rows)
                  _RunRow(
                    run: run,
                    today: today,
                    sent: _sent[run.activityId],
                    sending: _sending.contains(run.activityId),
                    onCheer: () => unawaited(_cheer(run)),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _RunRow extends StatelessWidget {
  const _RunRow({
    required this.run,
    required this.today,
    required this.sent,
    required this.sending,
    required this.onCheer,
  });

  final FriendRun run;
  final DateTime today;
  final CheerReaction? sent;
  final bool sending;
  final VoidCallback onCheer;

  @override
  Widget build(BuildContext context) {
    final name = run.nickname.trim().isEmpty
        ? RemainingSurface.tr(context, 'friends.nameless', '이름 없는 러너')
        : run.nickname;
    final day = parseKstDate(run.kstDate);
    final dayText = day == null ? '' : cheerDayLabel(context, day, today);
    final summary = [
      '${formatCheerDistanceKm(run.distanceKm)}km',
      formatCheerDuration(run.durationSeconds),
      if (dayText.isNotEmpty) dayText,
    ].join(' · ');
    final cheered = sent != null || run.cheered;
    final emoji = sent?.emoji ?? run.myReaction?.emoji ?? '✔';
    return Padding(
      key: FriendRunsSection.rowKey(run.activityId),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // The server does not tell us another person's avatar.
          const CircleAvatar(child: Icon(Icons.person)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (cheered) ...[
            Text(emoji,
                key: FriendRunsSection.emojiKey(run.activityId),
                style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 4),
          ],
          OutlinedButton(
            key: FriendRunsSection.buttonKey(run.activityId),
            onPressed: cheered || sending ? null : onCheer,
            child: Text(cheered
                ? RemainingSurface.tr(
                    context, 'cheers.button.cheered', '응원했어요')
                : RemainingSurface.tr(context, 'cheers.button.cheer', '응원')),
          ),
        ],
      ),
    );
  }
}
