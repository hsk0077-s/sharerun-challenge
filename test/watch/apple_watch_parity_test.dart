import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The Apple Watch app (Swift) cannot be built on this machine, so these
/// checks read its source. They keep it in step with Wear OS
/// (`wear_app/lib/l10n/watch_copy.dart`, `wear_app/lib/core/run_reward.dart`).
void main() {
  const dir = 'ios/ShareRunWatch Watch App';
  final copy = File('$dir/WatchCopy.swift').readAsStringSync();
  final screens = File('$dir/WatchScreens.swift').readAsStringSync();
  final workout = File('$dir/WorkoutManager.swift').readAsStringSync();
  final queue = File('$dir/WatchSyncQueue.swift').readAsStringSync();
  final account = File('$dir/WatchAccountManager.swift').readAsStringSync();
  final wearCopy = File('wear_app/lib/l10n/watch_copy.dart')
      .readAsStringSync()
      .replaceAll('\r\n', '\n');

  /// The 11 strings of one Wear OS `watchUiRows` / animal / medal row.
  List<String> wearRow(String table, String key) {
    final start = wearCopy.indexOf('const $table = ');
    expect(start, greaterThanOrEqualTo(0), reason: table);
    final at = wearCopy.indexOf("\n  '$key': [\n", start);
    expect(at, greaterThanOrEqualTo(0), reason: '$table.$key');
    final end = wearCopy.indexOf('\n  ],', at);
    final body = wearCopy.substring(at, end);
    return RegExp(r"^\s+'((?:[^'\\]|\\.)*)',\s*$", multiLine: true)
        .allMatches(body)
        .map((m) => m.group(1)!)
        .toList();
  }

  test('run and summary sentences are the same as Wear OS, in 11 languages', () {
    for (final key in [
      'kmPassed',
      'holdToStop',
      'resume',
      'pausedTitle',
      'cancelHint',
      'waitingGps',
      'unrated',
      'rewardConfirmed',
      'rewardPending',
      'rewardCapReached',
      'rewardNone',
      'rewardNotCounted',
    ]) {
      final row = wearRow('watchUiRows', key);
      expect(row, hasLength(11), reason: key);
      final swiftRow = '"$key": [${row.map((s) => '"$s"').join(', ')}]';
      expect(copy.contains(swiftRow), isTrue, reason: 'Swift row for $key');
    }
  });

  test('tier names come from the same animal and medal rows', () {
    for (final animal in ['snail', 'turtle', 'beagle', 'wolf', 'zebra', 'cheetah']) {
      final row = wearRow('watchAnimalRows', animal);
      expect(copy.contains('"$animal": [${row.map((s) => '"$s"').join(', ')}]'), isTrue,
          reason: animal);
    }
    for (final medal in ['bronze', 'silver', 'gold', 'diamond', 'master']) {
      final row = wearRow('watchMedalRows', medal);
      expect(copy.contains('"$medal": [${row.map((s) => '"$s"').join(', ')}]'), isTrue,
          reason: medal);
    }
    expect(account.contains('"/actions/watch/tier"'), isTrue);
    expect(account.contains('rememberTier(body["tier_code"])'), isTrue);
    expect(queue.contains('account.rememberTier(body["tier_code"])'), isTrue);
  });

  test('the reward line reads only server fields, like Wear OS', () {
    for (final field in ['"verified"', '"value_token_reward"', '"daily_cap_applied"']) {
      expect(queue.contains(field), isTrue, reason: field);
    }
    expect(queue.contains('[400, 409, 413, 422].contains(status) { return .notCounted }'),
        isTrue);
    expect(screens.contains('queue.reward(for: workout.lastActivityId).line'), isTrue);
    // No reward is worked out on the watch from distance.
    expect(RegExp(r'distanceKm\s*\*').hasMatch(queue.split('enum WatchRunReward')[1]
        .split('/// Persistent offline sync queue')[0]), isFalse);
  });

  test('countdown, km buzz, metric cycle, hold to stop and route line exist', () {
    expect(workout.contains('case countdown(Int)'), isTrue);
    expect(workout.contains('func beginCountdown()'), isTrue);
    expect(workout.contains('Self.buzz(.notification)'), isTrue);
    expect(workout.contains('func cycleFocus()'), isTrue);
    expect(screens.contains('struct WatchCountdownView'), isTrue);
    expect(screens.contains('struct WatchHoldButton'), isTrue);
    expect(screens.contains('minimumDuration: holdSeconds'), isTrue);
    expect(screens.contains('var holdSeconds: Double = 0.8'), isTrue);
    expect(screens.contains('struct WatchRouteShape: Shape'), isTrue);
    expect(screens.contains('onTap: { workout.cycleFocus() }'), isTrue);
    // Finishing is only on the hold button, not a plain tap or long press elsewhere.
    expect(screens.contains('WatchPausedView'), isFalse);
  });

  test('GPS keeps running in the background only during a run', () {
    expect(workout.contains('locationManager.allowsBackgroundLocationUpdates = true'), isTrue);
    expect(workout.contains('locationManager.allowsBackgroundLocationUpdates = false'), isTrue);
    final plist = File('$dir/Info.plist').readAsStringSync();
    // allowsBackgroundLocationUpdates needs the location background mode, or it crashes.
    expect(
      RegExp(r'<key>UIBackgroundModes</key>\s*<array>\s*<string>location</string>')
          .hasMatch(plist),
      isTrue,
    );
    expect(plist.contains('<string>workout-processing</string>'), isTrue);
  });
}
