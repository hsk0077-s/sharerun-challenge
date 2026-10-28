import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_wear/core/sync_queue.dart';
import 'package:share_run_wear/core/watch_platform.dart';

PendingRun _run(String id) => PendingRun(
      activityId: id,
      distanceKm: 3,
      durationSeconds: 1020,
      heartRates: const [140, 150],
      startedAt: DateTime.utc(2026, 10, 25, 9),
      endedAt: DateTime.utc(2026, 10, 25, 9, 17),
    );

void main() {
  test('the same activity id is queued once, so a retry cannot pay twice', () {
    final queue = SyncQueue();
    expect(queue.add(_run('a')), isTrue);
    expect(queue.add(_run('a')), isFalse);
    expect(queue.length, 1);
  });

  test('the oldest runs drop first when the queue is full', () {
    final queue = SyncQueue(maxRuns: 2)
      ..add(_run('a'))
      ..add(_run('b'))
      ..add(_run('c'));
    expect(queue.runs.map((r) => r.activityId), ['b', 'c']);
  });

  test('a run leaves the queue only when the server settled it', () {
    final queue = SyncQueue()..add(_run('a'))..add(_run('b'));
    queue.acknowledge('a');
    expect(queue.runs.map((r) => r.activityId), ['b']);
  });

  test('the queue survives a restart and ignores a broken saved value', () {
    final queue = SyncQueue()..add(_run('a'));
    final again = SyncQueue.decode(queue.encode());
    expect(again.runs.single.activityId, 'a');
    expect(again.runs.single.heartRates, [140, 150]);
    expect(SyncQueue.decode('not json').length, 0);
  });

  test('the body uses the field names of POST /actions/validate-run', () {
    final body = _run('a').toValidateRunBody(deviceId: 'watch-1');
    expect(body.keys, containsAll([
      'activity_id',
      'distance_km',
      'duration_seconds',
      'heart_rates',
      'cadence_spm',
      'gyro_stability_score',
      'gps_route',
    ]));
    expect(body['device_id'], 'watch-1');
    expect(body['gps_route'], isEmpty);
    expect(body['pace_samples'], isEmpty);
    expect((body['device_info']! as Map)['watch_used'], isTrue);
    expect(const PendingSteps(dayKey: '2026-10-25', steps: 8000).toBody(), {
      'day_key': '2026-10-25',
      'steps': 8000,
      'source': 'sensor',
    });
  });

  test('a measured route and pace are not sent empty', () {
    final run = buildPendingRun(
      activityId: 'a',
      distanceKm: 1.2,
      movingTime: const Duration(minutes: 6),
      heartRates: const [150],
      startedAt: DateTime.utc(2026, 10, 25, 9),
      endedAt: DateTime.utc(2026, 10, 25, 9, 6),
      gpsRoute: const [
        GpsFix(latitude: 37.5, longitude: 127.0, recordedAt: '2026-10-25T09:00:00Z'),
        GpsFix(latitude: 37.51, longitude: 127.01, recordedAt: '2026-10-25T09:06:00Z'),
      ],
      paceSamples: const [
        {'secondsPerKm': 300, 'recordedAt': '2026-10-25T09:03:00Z'},
      ],
    );
    final body = run!.toValidateRunBody();
    expect(body['gps_route'], hasLength(2));
    expect((body['gps_route'] as List).first, containsPair('latitude', 37.5));
    expect(body['pace_samples'], [
      {'secondsPerKm': 300, 'recordedAt': '2026-10-25T09:03:00Z'},
    ]);
    final queue = SyncQueue()..add(run);
    final again = SyncQueue.decode(queue.encode());
    expect(again.runs.single.gpsRoute, hasLength(2));
    expect(again.runs.single.paceSamples.single['secondsPerKm'], 300);
  });

  test('a run with no distance or time is not queued', () {
    expect(
      buildPendingRun(
        activityId: 'a',
        distanceKm: 0,
        movingTime: const Duration(minutes: 5),
        heartRates: const [],
        startedAt: DateTime.utc(2026, 10, 25),
        endedAt: DateTime.utc(2026, 10, 25),
      ),
      isNull,
    );
  });
}
