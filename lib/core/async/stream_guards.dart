import 'dart:async';

import 'package:flutter/foundation.dart';

/// Maps stream errors to [fallback] so Riverpod [StreamProvider]s stay on
/// [AsyncData] instead of [AsyncError] (which can surface as a debug red
/// ErrorWidget for a frame, then recover when the next snapshot arrives).
Stream<T> onStreamErrorEmit<T>(
  Stream<T> source,
  T fallback, {
  String? debugLabel,
}) {
  return source.transform(
    StreamTransformer<T, T>.fromHandlers(
      handleData: (data, sink) => sink.add(data),
      handleError: (error, stack, sink) {
        debugPrint('${debugLabel ?? 'stream'} error: $error');
        sink.add(fallback);
      },
    ),
  );
}
