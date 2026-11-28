import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/run_tracking/models/route_point.dart';
import 'package:share_run_challenge/features/run_tracking/run_live_pace.dart';

void main() {
  test('average pace is minutes and seconds per km', () {
    expect(
      RunLivePace.averageLabel(distanceKm: 5, durationSeconds: 1500),
      "5'00\"/km",
    );
    expect(
      RunLivePace.averageLabel(distanceKm: 1.25, durationSeconds: 450),
      "6'00\"/km",
    );
    expect(
      RunLivePace.averageLabel(distanceKm: 0.05, durationSeconds: 30),
      "10'00\"/km",
    );
  });

  test('average pace is -- under 0.05 km or with no time', () {
    expect(
      RunLivePace.averageLabel(distanceKm: 0.049, durationSeconds: 600),
      '--',
    );
    expect(
      RunLivePace.averageLabel(distanceKm: 0, durationSeconds: 12),
      '--',
    );
    expect(
      RunLivePace.averageLabel(distanceKm: 1, durationSeconds: 0),
      '--',
    );
  });

  test('current pace uses a steady recent window', () {
    final points = [
      _north(0, 0),
      _north(25, 8),
      _north(50, 15),
    ];
    expect(RunLivePace.currentLabel(points), "5'00\"/km");
  });

  test('current pace is -- when the window is too short or jumps', () {
    expect(RunLivePace.currentLabel(const []), '--');
    expect(
      RunLivePace.currentLabel([_north(0, 0), _north(40, 12)]),
      '--',
      reason: 'two points are not a stable pace',
    );
    expect(
      RunLivePace.currentLabel([
        _north(0, 0),
        _north(5, 5),
        _north(10, 12),
      ]),
      '--',
      reason: '10 m in the window is GPS noise',
    );
    expect(
      RunLivePace.currentLabel([
        _north(0, 0),
        _north(200, 2),
        _north(210, 15),
      ]),
      '--',
      reason: 'a 200 m jump in 2 s is not a running pace',
    );
  });

  test('the clock stays MM:SS until an hour', () {
    expect(formatRunClock(12), '00:12');
    expect(formatRunClock(450), '07:30');
    expect(formatRunClock(3661), '1:01:01');
  });
}

/// [meters] due north of a fixed point, [seconds] after midnight UTC.
RoutePoint _north(double meters, int seconds) {
  const origin = 37.5;
  const metersPerDegree = 111320.0;
  return RoutePoint(
    latitude: origin + meters / metersPerDegree,
    longitude: 127,
    recordedAt: DateTime.utc(2026, 1, 1, 0, 0, seconds),
  );
}
