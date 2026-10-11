import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/providers/app_providers.dart';

/// Firebase 프로젝트 번호. 비밀 값이 아니다.
const _projectNumber = String.fromEnvironment(
  'PLAY_INTEGRITY_PROJECT_NUMBER',
  defaultValue: '1089697395275',
);
const _channel = MethodChannel('share_run/integrity');
const _lastKey = 'integrity_last_check_ms';
const integrityInterval = Duration(hours: 24);

/// 하루에 한 번만 확인할 때가 됐는지.
bool integrityCheckDue(int? lastMs, DateTime now) {
  if (lastMs == null) return true;
  final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
  final age = now.difference(last);
  return age.isNegative || age >= integrityInterval;
}

/// 기기·앱 무결성 확인 결과를 서버에 알린다. 서버는 기록만 하고 아무것도 막지 않는다.
/// 실패해도 앱은 그대로 쓰며, 같은 날 다시 시도하지 않는다.
Future<void> reportDeviceIntegrity(WidgetRef ref) async {
  if (!Platform.isAndroid) return;
  try {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    if (!integrityCheckDue(prefs.getInt(_lastKey), now)) return;
    await prefs.setInt(_lastKey, now.millisecondsSinceEpoch);
    final api = ref.read(securedActionApiClientProvider);
    final nonce = await api.fetchIntegrityNonce();
    if (nonce.isEmpty) return;
    final token = await _channel.invokeMethod<String>('requestToken', {
      'nonce': nonce,
      'projectNumber': _projectNumber,
    });
    if (token == null || token.isEmpty) return;
    await api.reportIntegrity(token);
  } catch (_) {}
}
