import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../l10n/remaining_surface.dart';
import '../cheer_format.dart';
import '../cheers_models.dart';
import '../cheers_providers.dart';

/// Cheers a person received, newest first. Opening it marks them seen once.
/// There is no reply button.
class CheerInboxScreen extends ConsumerStatefulWidget {
  const CheerInboxScreen({super.key});

  static const listKey = Key('cheer-inbox-list');
  static const emptyKey = Key('cheer-inbox-empty');
  static const failedKey = Key('cheer-inbox-failed');
  static const retryKey = Key('cheer-inbox-retry');
  static Key itemKey(int index) => Key('cheer-inbox-item-$index');

  @override
  ConsumerState<CheerInboxScreen> createState() => _CheerInboxScreenState();
}

class _CheerInboxScreenState extends ConsumerState<CheerInboxScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(_markSeen());
  }

  Future<void> _markSeen() async {
    final api = ref.read(cheersApiProvider);
    try {
      await api.markSeen();
    } catch (_) {
      return; // The badge stays; nothing else breaks.
    }
    if (!mounted) return;
    // The friends screen badge reads this same provider.
    ref.invalidate(cheerInboxProvider);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final inbox = ref.watch(cheerInboxProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(RemainingSurface.tr(context, 'cheers.inbox.title', '받은 응원')),
      ),
      body: inbox.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Padding(
            padding: EdgeInsets.all(tokens.spacing.page),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  RemainingSurface.tr(context, 'cheers.inbox.load_failed',
                      '받은 응원을 불러오지 못했어요.'),
                  key: CheerInboxScreen.failedKey,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: tokens.spacing.sm),
                FilledButton(
                  key: CheerInboxScreen.retryKey,
                  onPressed: () => ref.invalidate(cheerInboxProvider),
                  child: Text(
                      RemainingSurface.tr(context, 'friends.retry', '다시 시도')),
                ),
              ],
            ),
          ),
        ),
        data: (data) {
          if (data.cheers.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(tokens.spacing.page),
                child: Text(
                  RemainingSurface.tr(
                      context, 'cheers.inbox.empty', '아직 받은 응원이 없어요.'),
                  key: CheerInboxScreen.emptyKey,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final now = ref.watch(cheerClockProvider)();
          final today = DateTime(now.year, now.month, now.day);
          return ListView.builder(
            key: CheerInboxScreen.listKey,
            padding: EdgeInsets.all(tokens.spacing.page),
            itemCount: data.cheers.length,
            itemBuilder: (context, index) => _CheerRow(
              key: CheerInboxScreen.itemKey(index),
              cheer: data.cheers[index],
              today: today,
            ),
          );
        },
      ),
    );
  }
}

class _CheerRow extends StatelessWidget {
  const _CheerRow({super.key, required this.cheer, required this.today});

  final ReceivedCheer cheer;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final name = cheer.nickname.trim().isEmpty
        ? RemainingSurface.tr(context, 'friends.nameless', '이름 없는 러너')
        : cheer.nickname;
    final at = cheer.createdAt?.toLocal();
    final dayText = at == null
        ? ''
        : cheerDayLabel(context, DateTime(at.year, at.month, at.day), today);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Text(cheer.reaction.emoji, style: const TextStyle(fontSize: 30)),
      title: Text(RemainingSurface.tr(
        context,
        'cheers.inbox.item',
        '$name님이 응원했어요',
        {'name': name},
      )),
      subtitle: dayText.isEmpty ? null : Text(dayText),
    );
  }
}
