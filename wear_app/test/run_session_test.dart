import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_wear/core/run_session.dart';

void main() {
  late DateTime now;
  late RunSession session;

  setUp(() {
    now = DateTime.utc(2026, 10, 25, 9);
    session = RunSession(clock: () => now);
  });

  test('moving time leaves out the paused minutes', () {
    session.start();
    now = now.add(const Duration(minutes: 10));
    session.pause();
    now = now.add(const Duration(minutes: 5));
    session.resume();
    now = now.add(const Duration(minutes: 7));
    session.finish();
    expect(session.movingTime, const Duration(minutes: 17));
    expect(session.phase, RunPhase.finished);
  });

  test('distance and heart rate only count while running', () {
    session.addDistance(1);
    session.start();
    session.addDistance(1.8);
    session.addHeartRate(148);
    session.addHeartRate(5); // 비현실적인 값은 버린다
    session.addHeartRate(300);
    session.pause();
    session.addDistance(5);
    expect(session.distanceKm, 1.8);
    expect(session.heartRates, [148]);
    expect(session.lastHeartRate, 148);
  });

  test('pace is seconds per km and formats like 5:42', () {
    session.start();
    session.addDistance(1.8);
    now = now.add(const Duration(seconds: 1026)); // 17:06 / 1.8km = 5:42
    expect(session.paceSecondsPerKm, 570);
    expect(formatPace(342), '5:42');
    expect(formatPace(0), '--:--');
    expect(formatKm(3), '3.00');
  });

  test('a finished run cannot be restarted or paused', () {
    session.start();
    session.finish();
    session
      ..start()
      ..pause()
      ..resume();
    expect(session.phase, RunPhase.finished);
  });
}
