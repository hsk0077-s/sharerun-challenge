import 'dart:math';

/// One id per attempt. A retry after a dropped response reuses it so the
/// server does not charge 심폐소생권 or 세이프가드 twice.
class ShopRequestIds {
  final Map<String, String> _retry = {};

  String begin(String key, {String Function()? mint}) {
    return _retry[key] ?? (mint ?? mintShopRequestId)();
  }

  void succeed(String key) {
    _retry.remove(key);
  }

  void failed(String key, String id, {required bool retryable}) {
    if (retryable) {
      _retry[key] = id;
      return;
    }
    _retry.remove(key);
  }
}

String mintShopRequestId() {
  final micros = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
  final salt = Random().nextInt(0x7fffffff).toRadixString(16);
  final id = 'r$micros$salt';
  if (id.length <= 64) return id;
  return id.substring(0, 64);
}
