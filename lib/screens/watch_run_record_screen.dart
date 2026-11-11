import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers/app_providers.dart';
import '../app/router/route_names.dart';
import '../data/models/activity_model.dart';
import '../l10n/watch_run_link_copy.dart';

/// 워치에서 "폰에서 자세히 보기"로 연 달리기 기록.
///
/// [activityId]가 서버에 있으면 그 기록을 보여 준다. 아직 올라오지 않았으면
/// 잠깐 기다렸다가 빈 화면 대신 안내와 최근 기록 목록을 보여 준다.
class WatchRunRecordScreen extends ConsumerStatefulWidget {
  const WatchRunRecordScreen({
    super.key,
    this.activityId,
    this.lookup,
    this.fallbackAfter = const Duration(seconds: 8),
  });

  final String? activityId;

  /// 시험용. 없으면 [ActivityRepository.getActivity]를 쓴다.
  final Future<ActivityModel?> Function(String activityId)? lookup;

  /// 기록을 못 찾았을 때 안내로 넘어가기 전 기다림.
  final Duration fallbackAfter;

  static const titleKey = Key('watch-run-record-title');
  static const syncingKey = Key('watch-run-record-syncing');
  static const distanceKey = Key('watch-run-record-distance');
  static const fallbackKey = Key('watch-run-record-fallback');
  static const seeListKey = Key('watch-run-record-see-list');

  @override
  ConsumerState<WatchRunRecordScreen> createState() =>
      _WatchRunRecordScreenState();
}

class _WatchRunRecordScreenState extends ConsumerState<WatchRunRecordScreen> {
  ActivityModel? _fetched;
  var _showFallback = false;
  Timer? _fallbackTimer;

  String? get _wantedId {
    final id = widget.activityId?.trim() ?? '';
    return id.isEmpty ? null : id;
  }

  @override
  void initState() {
    super.initState();
    final id = _wantedId;
    if (id == null) {
      _showFallback = true;
    } else {
      unawaited(_lookup(id));
      final wait = widget.fallbackAfter;
      if (wait <= Duration.zero) {
        _showFallback = true;
      } else {
        _fallbackTimer = Timer(wait, () {
          if (mounted) setState(() => _showFallback = true);
        });
      }
    }
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    super.dispose();
  }

  Future<void> _lookup(String id) async {
    try {
      final found = widget.lookup != null
          ? await widget.lookup!(id)
          : await ref.read(activityRepositoryProvider).getActivity(id);
      if (!mounted || found == null) return;
      String? uid;
      try {
        uid = ref.read(authStateChangesProvider).asData?.value?.uid;
      } catch (_) {
        uid = null;
      }
      if (uid != null &&
          uid.isNotEmpty &&
          found.userId.isNotEmpty &&
          found.userId != uid) {
        return;
      }
      setState(() => _fetched = found);
    } catch (_) {
      // 네트워크·권한 오류는 스트림의 최근 기록이나 안내 화면으로 넘긴다.
    }
  }

  ActivityModel? _match(List<ActivityModel> recent) {
    if (_fetched != null) return _fetched;
    final id = _wantedId;
    if (id == null) return null;
    for (final activity in recent) {
      if (activity.id == id) return activity;
    }
    return null;
  }

  Locale _locale(BuildContext context) =>
      Localizations.maybeLocaleOf(context) ?? const Locale('ko');

  @override
  Widget build(BuildContext context) {
    final locale = _locale(context);
    final recent = ref.watch(recentActivitiesProvider).asData?.value ?? const [];
    final match = _match(recent);
    final shown = match ??
        ( _wantedId == null && recent.isNotEmpty ? recent.first : null);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          watchRunLinkCopy(locale, 'title'),
          key: WatchRunRecordScreen.titleKey,
        ),
      ),
      body: SafeArea(
        child: shown != null
            ? _RecordBody(activity: shown, locale: locale)
            : !_showFallback
                ? _SyncingBody(locale: locale)
                : _FallbackBody(
                    locale: locale,
                    recent: recent,
                    onSeeList: () {
                      if (GoRouter.maybeOf(context) != null) {
                        context.go(RouteNames.myPage);
                      }
                    },
                  ),
      ),
    );
  }
}

class _SyncingBody extends StatelessWidget {
  const _SyncingBody({required this.locale});

  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              watchRunLinkCopy(locale, 'syncing'),
              key: WatchRunRecordScreen.syncingKey,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordBody extends StatelessWidget {
  const _RecordBody({required this.activity, required this.locale});

  final ActivityModel activity;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final date = _dateLabel(activity.completedAt);
    final duration = _durationLabel(activity.durationSeconds);
    final pace = activity.formattedPace;
    final status = switch (activity.validationStatus) {
      ActivityValidationStatus.verified => watchRunLinkCopy(locale, 'verified'),
      ActivityValidationStatus.pending => watchRunLinkCopy(locale, 'pending'),
      ActivityValidationStatus.rejected => watchRunLinkCopy(locale, 'rejected'),
      ActivityValidationStatus.underReview =>
        watchRunLinkCopy(locale, 'underReview'),
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        if (date.isNotEmpty)
          Text(date, style: textTheme.bodyMedium),
        const SizedBox(height: 12),
        Text(
          '${activity.distanceKm.toStringAsFixed(2)} km',
          key: WatchRunRecordScreen.distanceKey,
          style: textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        Text(duration, style: textTheme.headlineSmall),
        if (pace != null) ...[
          const SizedBox(height: 8),
          Text(pace, style: textTheme.titleMedium),
        ],
        const SizedBox(height: 16),
        Text(status, style: textTheme.titleSmall),
      ],
    );
  }
}

class _FallbackBody extends StatelessWidget {
  const _FallbackBody({
    required this.locale,
    required this.recent,
    required this.onSeeList,
  });

  final Locale locale;
  final List<ActivityModel> recent;
  final VoidCallback onSeeList;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        Text(
          watchRunLinkCopy(locale, 'notReady'),
          key: WatchRunRecordScreen.fallbackKey,
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        FilledButton(
          key: WatchRunRecordScreen.seeListKey,
          onPressed: onSeeList,
          child: Text(watchRunLinkCopy(locale, 'seeList')),
        ),
        if (recent.isNotEmpty) ...[
          const SizedBox(height: 24),
          for (final activity in recent.take(5))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${_dateLabel(activity.completedAt)}  '
                '${activity.distanceKm.toStringAsFixed(2)} km',
                style: textTheme.bodyMedium,
              ),
            ),
        ],
      ],
    );
  }
}

String _dateLabel(DateTime? at) {
  if (at == null) return '';
  final local = at.toLocal();
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '${local.year}.$m.$d $hh:$mm';
}

String _durationLabel(int? seconds) {
  if (seconds == null || seconds <= 0) return '--:--';
  final total = seconds;
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  final ss = s.toString().padLeft(2, '0');
  if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:$ss';
  return '$m:$ss';
}
