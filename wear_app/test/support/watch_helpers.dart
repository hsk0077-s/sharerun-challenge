import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_wear/core/watch_events.dart';
import 'package:share_run_wear/core/watch_haptics.dart';
import 'package:share_run_wear/core/watch_platform.dart';
import 'package:share_run_wear/screens/watch_screens.dart';

/// 시작을 누르고 3·2·1이 끝나 달리기가 시작될 때까지 시간을 보낸다.
Future<void> startRun(WidgetTester tester) async {
  await tester.tap(find.byKey(StartFace.buttonKey));
  await tester.pump();
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
  await tester.pump();
}

/// 달리는 중 화면을 왼쪽으로 밀어 조작 화면(일시정지됨)을 연다.
Future<void> swipeToControls(WidgetTester tester) async {
  await tester.fling(find.byType(PageView), const Offset(-400, 0), 2000);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 900));
}

/// 오른쪽으로 밀어 경로 화면을 연다.
Future<void> swipeToRoute(WidgetTester tester) async {
  await tester.fling(find.byType(PageView), const Offset(400, 0), 2000);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 900));
}

/// 길게 눌러 종료한다(조작 화면에서).
Future<void> holdToStop(WidgetTester tester) async {
  final gesture = await tester.startGesture(tester.getCenter(find.byKey(ControlsFace.stopKey)));
  // 고리가 다 차려면 약 800ms 누르고 있어야 한다(첫 프레임은 시작 시각만 잡는다).
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 900));
  await gesture.up();
  await tester.pump();
  await tester.pump();
}

class FakeHaptics implements WatchHaptics {
  final patterns = <List<int>>[];

  @override
  Future<void> pattern(List<int> millis) async => patterns.add(millis);
}

class FakeEvents implements WatchEvents {
  var autostart = false;
  void Function()? _network;
  void Function()? _autostartCb;

  @override
  Future<bool> consumeAutostart() async {
    final v = autostart;
    autostart = false;
    return v;
  }

  @override
  void onNetworkAvailable(void Function() callback) => _network = callback;

  @override
  void onAutostartRequested(void Function() callback) => _autostartCb = callback;

  void fireNetwork() => _network?.call();
  void fireAutostart() => _autostartCb?.call();
}

class FakeSensors implements WatchSensors {
  var snapshot = const SensorSnapshot();
  var started = 0;
  var stopped = 0;

  @override
  Future<Set<String>> requestPermissions() async => {'heartRate', 'steps', 'gps'};

  @override
  Future<void> start() async => started++;

  @override
  Future<void> stop() async => stopped++;

  @override
  Future<SensorSnapshot> read() async => snapshot;
}

/// 위도 방향으로 달리는 가짜 경로 [n]개(서울 부근).
List<GpsFix> fakeRoute(int n) => [
      for (var i = 0; i < n; i++)
        GpsFix(
          latitude: 37.5 + i * 0.0001,
          longitude: 127.0 + (i % 7) * 0.00005,
          recordedAt: DateTime.utc(2026, 11, 10, 6, 0, i % 60).toIso8601String(),
        ),
    ];
