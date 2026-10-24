import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_wear/core/sync_queue.dart';
import 'package:share_run_wear/core/watch_account.dart';
import 'package:share_run_wear/core/watch_platform.dart';
import 'package:share_run_wear/main.dart';
import 'package:share_run_wear/screens/watch_screens.dart';

class _FakeSensors implements WatchSensors {
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

class _OfflinePoster implements JsonPoster {
  final codes = <String>[];

  @override
  Future<HttpReply> post(
    Uri uri,
    Map<String, Object?> body, {
    Map<String, String> headers = const {},
  }) async {
    if (uri.path == '/auth/watch-pair') {
      codes.add(body['code']! as String);
      return const HttpReply(400, {'detail': 'invalid_code'});
    }
    throw Exception('offline');
  }
}

Future<void> _tapDigits(WidgetTester tester, String digits) async {
  for (final d in digits.split('')) {
    await tester.tap(find.byKey(PairingFace.digitKey(int.parse(d))));
    await tester.pump();
  }
}

void main() {
  testWidgets('the keypad fills six digits and submits them', (tester) async {
    String? submitted;
    await tester.pumpWidget(MaterialApp(
      home: PairingFace(
        onSubmit: (code) async {
          submitted = code;
          return '코드가 맞지 않거나 만료됐어요.';
        },
        onSkip: () {},
      ),
    ));

    await _tapDigits(tester, '4829');
    expect(find.text('482 9••'), findsOneWidget);
    await tester.tap(find.byKey(PairingFace.backKey));
    await tester.pump();
    expect(find.text('482 •••'), findsOneWidget);

    await _tapDigits(tester, '910');
    await tester.pump();
    expect(submitted, '482910');
    // 틀리면 메시지를 보여 주고 처음부터 다시 받는다.
    expect(find.text('코드가 맞지 않거나 만료됐어요.'), findsOneWidget);
    expect(find.text('••• •••'), findsOneWidget);
  });

  testWidgets('an unpaired watch asks for the code first and can be skipped',
      (tester) async {
    final poster = _OfflinePoster();
    final account = WatchAccount(
      store: MemoryStore(),
      poster: poster,
      baseUrl: 'https://api.test',
      apiKey: 'key',
    );
    await tester.pumpWidget(MaterialApp(home: RunFlow(account: account)));
    expect(find.byKey(PairingFace.codeKey), findsOneWidget);

    await _tapDigits(tester, '123456');
    await tester.pump();
    expect(poster.codes, ['123456']);
    expect(find.text('코드가 맞지 않거나 만료됐어요.'), findsOneWidget);

    await tester.tap(find.byKey(PairingFace.skipKey));
    await tester.pump();
    expect(find.byKey(PairingFace.codeKey), findsNothing);
    expect(find.text('탭해서 시작'), findsOneWidget);
  });

  testWidgets('sensor values become distance, heart rate, steps and a queued run',
      (tester) async {
    final sensors = _FakeSensors();
    final queue = SyncQueue();
    var now = DateTime.utc(2026, 10, 24, 1);
    await tester.pumpWidget(MaterialApp(
      home: RunFlow(
        queue: queue,
        clock: () => now = now.add(const Duration(seconds: 20)),
        sensors: sensors,
        newId: () => 'watch_sensor_test',
        pollInterval: const Duration(milliseconds: 100),
      ),
    ));

    await tester.tap(find.text('탭해서 시작'));
    await tester.pump();
    expect(sensors.started, 1);

    sensors.snapshot = const SensorSnapshot(
      heartRate: 150,
      steps: 40,
      distanceKm: 0.3,
      hasGps: true,
    );
    await tester.pump(const Duration(milliseconds: 150));
    sensors.snapshot = const SensorSnapshot(
      heartRate: 152,
      steps: 90,
      distanceKm: 0.5,
      hasGps: true,
    );
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.textContaining('♥ 152'), findsOneWidget);
    expect(find.textContaining('0.50km'), findsOneWidget);

    await tester.tap(find.text('달리는 중'));
    await tester.pump();
    // 일시정지 중에 센서가 거리를 더 재도 기록에는 넣지 않는다.
    sensors.snapshot = const SensorSnapshot(
      heartRate: 100,
      steps: 120,
      distanceKm: 0.9,
      hasGps: true,
    );
    await tester.pump(const Duration(milliseconds: 150));

    await tester.longPress(find.text('일시정지').first);
    await tester.pump();
    await tester.pump();

    expect(sensors.stopped, greaterThanOrEqualTo(1));
    expect(find.text('끝'), findsOneWidget);
    expect(queue.length, 1);
    final run = queue.runs.single;
    expect(run.activityId, 'watch_sensor_test');
    expect(run.distanceKm, closeTo(0.5, 0.001));
    expect(run.totalSteps, 90);
    // 일시정지 중의 심박(100)은 기록에 들어가지 않는다.
    expect(run.heartRates.toSet(), {150, 152});
  });
}
