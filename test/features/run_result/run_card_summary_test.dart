import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/run_result/run_card_summary.dart';
import 'package:share_run_challenge/features/run_tracking/models/route_point.dart';

// 100 m of latitude, about.
const _step = 100 / 111195;

List<RoutePoint> _line(List<int> secondsPerStep) {
  final start = DateTime(2026, 10, 3, 7);
  var at = start;
  final points = <RoutePoint>[
    RoutePoint(latitude: 37.0, longitude: 127.0, recordedAt: at),
  ];
  for (var i = 0; i < secondsPerStep.length; i++) {
    at = at.add(Duration(seconds: secondsPerStep[i]));
    points.add(
      RoutePoint(
        latitude: 37.0 + _step * (i + 1),
        longitude: 127.0,
        recordedAt: at,
      ),
    );
  }
  return points;
}

void main() {
  test('splits are whole kilometres and ignore the partial rest', () {
    final slowKm = List<int>.filled(10, 30); // 300 s
    final fastKm = List<int>.filled(10, 27); // 270 s
    final partial = List<int>.filled(4, 30);

    final splits = kmSplitPaceSeconds(_line([...slowKm, ...fastKm, ...partial]));

    expect(splits.length, 2);
    expect(splits[0], closeTo(300, 2));
    expect(splits[1], closeTo(270, 2));
  });

  test('under one kilometre or no movement gives no splits', () {
    expect(kmSplitPaceSeconds(const []), isEmpty);
    expect(kmSplitPaceSeconds(_line(List<int>.filled(8, 30))), isEmpty);
  });

  test('bars are capped by averaging neighbours', () {
    final many = List<int>.generate(24, (i) => 300 + i);
    final bars = bucketSplitPaces(many);
    expect(bars.length, 12);
    expect(bars.first, 301); // (300 + 301) / 2, rounded
    expect(bucketSplitPaces([300, 310]), [300, 310]);
  });

  test('heart rate average drops impossible readings', () {
    expect(averageHeartRateOf(const []), isNull);
    expect(averageHeartRateOf(const [0, 0, 300]), isNull);
    expect(averageHeartRateOf(const [150, 160, 0, 170]), 160);
  });
}
