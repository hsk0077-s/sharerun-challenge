import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/async/stream_guards.dart';

void main() {
  test('onStreamErrorEmit keeps the stream alive with a fallback', () async {
    final controller = StreamController<int>();
    final values = <int>[];
    final sub = onStreamErrorEmit(
      controller.stream,
      -1,
      debugLabel: 'test',
    ).listen(values.add);

    controller.add(1);
    controller.addError(StateError('permission-denied'));
    controller.add(2);
    await Future<void>.delayed(Duration.zero);

    expect(values, [1, -1, 2]);
    await sub.cancel();
    await controller.close();
  });
}
