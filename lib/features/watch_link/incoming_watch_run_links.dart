import 'package:flutter/services.dart';

const watchRunLinksChannel = 'share_run/links';

/// 네이티브가 받은 `sharerun://…` 주소를 Dart로 넘겨 준다.
class IncomingWatchRunLinks {
  IncomingWatchRunLinks([MethodChannel? channel])
      : _channel = channel ?? const MethodChannel(watchRunLinksChannel);

  final MethodChannel _channel;

  Future<String?> getInitialLink() async {
    try {
      return await _channel.invokeMethod<String>('getInitialLink');
    } catch (_) {
      return null;
    }
  }

  void listen(void Function(String raw) onLink) {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'onLink') return;
      final raw = call.arguments;
      if (raw is String && raw.trim().isNotEmpty) onLink(raw);
    });
  }

  void dispose() {
    _channel.setMethodCallHandler(null);
  }
}
