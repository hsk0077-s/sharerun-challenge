import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/remaining_surface.dart';

/// One installed app the finish poster can be handed to.
enum RunFinishShareTarget {
  story('story', 'Instagram 스토리', 'run_result.run_finish_share_targets.body'),
  feed('feed', 'Instagram 피드', 'run_result.run_finish_share_targets.body.2'),
  tiktok('tiktok', 'TikTok'),
  facebook('facebook', 'Facebook'),
  kakao('kakao', '카카오톡', 'pedometer.walking_challenge_share.body.3'),
  line('line', 'LINE'),
  x('x', 'X'),
  whatsapp('whatsapp', 'WhatsApp'),
  telegram('telegram', 'Telegram'),
  more('more', '더보기', 'run_result.run_finish_share_targets.body.3');

  const RunFinishShareTarget(this.id, this._ko, [this._key]);

  final String id;
  final String _ko;
  final String? _key;

  /// 화면 언어로 된 이름. 상표는 그대로다.
  String get label =>
      _key == null ? _ko : RemainingSurface.trNow(_key, _ko);

  static const catalog = <RunFinishShareTarget>[
    story,
    feed,
    tiktok,
    facebook,
    kakao,
    line,
    x,
    whatsapp,
    telegram,
    more,
  ];

  static RunFinishShareTarget? byId(String id) {
    for (final target in catalog) {
      if (target.id == id) return target;
    }
    return null;
  }
}

enum RunFinishShareMode { one, sequence }

/// Display preference only. The photo and the poster are not stored here.
abstract final class RunFinishSharePrefs {
  static const modeKey = 'run_finish_share_mode';
  static const orderKey = 'run_finish_share_order';

  static Future<RunFinishShareMode> loadMode() async {
    try {
      final name = (await SharedPreferences.getInstance()).getString(modeKey);
      if (name == RunFinishShareMode.sequence.name) {
        return RunFinishShareMode.sequence;
      }
    } catch (_) {}
    return RunFinishShareMode.one;
  }

  static Future<void> saveMode(RunFinishShareMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(modeKey, mode.name);
    } catch (_) {}
  }

  static Future<List<String>> loadOrder() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(orderKey);
      if (raw == null || raw.isEmpty) return const [];
      return [
        for (final part in raw.split(','))
          if (part.isNotEmpty) part,
      ];
    } catch (_) {
      return const [];
    }
  }

  static Future<void> saveOrder(List<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(orderKey, ids.join(','));
    } catch (_) {}
  }
}

/// Checked targets stay in the saved order. Other installed apps follow.
List<RunFinishShareTarget> orderedShareTargets({
  required List<String> installedIds,
  required List<String> savedOrder,
}) {
  final available = <String, RunFinishShareTarget>{
    for (final target in RunFinishShareTarget.catalog)
      if (target == RunFinishShareTarget.more ||
          installedIds.contains(target.id))
        target.id: target,
  };
  final ordered = <RunFinishShareTarget>[];
  for (final id in savedOrder) {
    final target = available.remove(id);
    if (target != null) ordered.add(target);
  }
  ordered.addAll(available.values);
  return ordered;
}

/// Same index rule as [ReorderableListView.onReorder].
List<T> moveShareItem<T>(List<T> items, int oldIndex, int newIndex) {
  final next = [...items];
  var insertAt = newIndex;
  if (insertAt > oldIndex) insertAt -= 1;
  final item = next.removeAt(oldIndex);
  next.insert(insertAt, item);
  return next;
}
