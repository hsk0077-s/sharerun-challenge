import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/providers/app_providers.dart';
import '../jena_validation/run_device_info.dart';

/// 서버가 돌려준 로그인 기기 한 줄. 위치·IP는 없다.
class LoginDevice {
  const LoginDevice({
    required this.deviceId,
    required this.model,
    required this.osVersion,
    required this.appVersion,
    required this.lastSeenAt,
    required this.current,
    this.firstSeenAt,
  });

  final String deviceId;
  final String model;
  final String osVersion;
  final String appVersion;
  final DateTime? lastSeenAt;
  final DateTime? firstSeenAt;
  final bool current;

  /// 이 계정에 처음 나타난 지 하루가 안 된 다른 기기.
  bool isNew({DateTime? now}) {
    final first = firstSeenAt;
    if (current || first == null) return false;
    return (now ?? DateTime.now()).difference(first).inHours < 24;
  }

  factory LoginDevice.fromJson(Map<String, dynamic> json) {
    return LoginDevice(
      deviceId: json['device_id'] as String? ?? '',
      model: json['model'] as String? ?? '',
      osVersion: json['os_version'] as String? ?? '',
      appVersion: json['app_version'] as String? ?? '',
      lastSeenAt: DateTime.tryParse(json['last_seen_at'] as String? ?? ''),
      firstSeenAt: DateTime.tryParse(json['first_seen_at'] as String? ?? ''),
      current: json['current'] == true,
    );
  }
}

const _installIdKey = 'login_install_id';

/// 이 설치를 구분하는 무작위 값. 계정·기기 일련번호와 무관하다.
Future<String> installId() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(_installIdKey);
  if (saved != null && saved.length >= 16) return saved;
  final random = Random.secure();
  final id = List.generate(
    32,
    (_) => random.nextInt(16).toRadixString(16),
  ).join();
  await prefs.setString(_installIdKey, id);
  return id;
}

/// 로그인 상태로 앱이 열릴 때 이 기기를 서버에 알린다. 실패해도 앱은 그대로 쓴다.
Future<void> registerThisDevice(WidgetRef ref) async {
  try {
    final info = await RunDeviceInfo.collect(
      watchUsed: false,
      heartRateUsed: false,
    );
    await ref.read(securedActionApiClientProvider).registerLoginDevice(
          deviceId: await installId(),
          model: info.model,
          osVersion: info.osVersion,
          appVersion: info.appVersion,
          fcmToken:
              await ref.read(pushNotificationServiceProvider).currentToken() ??
                  '',
        );
  } catch (_) {}
}

final loginDevicesProvider = FutureProvider.autoDispose<List<LoginDevice>>(
  (ref) async {
    final rows = await ref
        .watch(securedActionApiClientProvider)
        .fetchLoginDevices(await installId());
    return rows.map(LoginDevice.fromJson).toList();
  },
  retry: (_, __) => null,
);
