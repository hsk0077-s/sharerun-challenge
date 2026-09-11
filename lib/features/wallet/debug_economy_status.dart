import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_text_styles.dart';

enum DebugJenaReachability { unknown, ok, fail }

enum DebugGrantPhase { pending, done, failed }

/// Tiny Home-only debug readout. Release builds must not mount this.
class DebugEconomyStatus {
  const DebugEconomyStatus({
    this.jena = DebugJenaReachability.unknown,
    this.grant = DebugGrantPhase.pending,
    this.grantDetail = '',
  });

  final DebugJenaReachability jena;
  final DebugGrantPhase grant;
  final String grantDetail;

  String get homeLine {
    final jenaLabel = switch (jena) {
      DebugJenaReachability.unknown => 'Jena: …',
      DebugJenaReachability.ok => 'Jena: ok',
      DebugJenaReachability.fail => 'Jena: fail',
    };
    final grantLabel = switch (grant) {
      DebugGrantPhase.pending => 'grant: pending',
      DebugGrantPhase.done => 'grant: done',
      DebugGrantPhase.failed => grantDetail.isEmpty
          ? 'grant: failed'
          : 'grant: failed:$grantDetail',
    };
    return 'DEBUG $jenaLabel  $grantLabel';
  }

  DebugEconomyStatus copyWith({
    DebugJenaReachability? jena,
    DebugGrantPhase? grant,
    String? grantDetail,
  }) {
    return DebugEconomyStatus(
      jena: jena ?? this.jena,
      grant: grant ?? this.grant,
      grantDetail: grantDetail ?? this.grantDetail,
    );
  }

  static String shortError(Object error, {int maxChars = 32}) {
    final raw = error.toString().replaceAll('\n', ' ').trim();
    if (raw.isEmpty) return '';
    if (raw.length <= maxChars) return raw;
    return '${raw.substring(0, maxChars)}…';
  }
}

class DebugEconomyStatusNotifier extends Notifier<DebugEconomyStatus> {
  @override
  DebugEconomyStatus build() => const DebugEconomyStatus();

  void markJenaOk() {
    state = state.copyWith(jena: DebugJenaReachability.ok);
  }

  void markJenaFail() {
    state = state.copyWith(jena: DebugJenaReachability.fail);
  }

  void markGrantPending() {
    state = state.copyWith(
      grant: DebugGrantPhase.pending,
      grantDetail: '',
    );
  }

  void markGrantDone() {
    state = state.copyWith(
      grant: DebugGrantPhase.done,
      grantDetail: '',
    );
  }

  void markGrantFailed(Object error) {
    state = state.copyWith(
      grant: DebugGrantPhase.failed,
      grantDetail: DebugEconomyStatus.shortError(error),
    );
  }
}

final debugEconomyStatusProvider =
    NotifierProvider<DebugEconomyStatusNotifier, DebugEconomyStatus>(
  DebugEconomyStatusNotifier.new,
);

/// One muted line under Home wallet badges. Hidden outside [kDebugMode].
class DebugEconomyStatusLine extends ConsumerWidget {
  const DebugEconomyStatusLine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kDebugMode) return const SizedBox.shrink();
    final line = ref.watch(debugEconomyStatusProvider).homeLine;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        line,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.caption.copyWith(fontSize: 11),
      ),
    );
  }
}
