import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';

/// Diagnostics stored with a run. Model, OS, app version, and whether a
/// watch or heart-rate source was used. No account, serial, or location.
class RunDeviceInfo {
  const RunDeviceInfo({
    required this.model,
    required this.osVersion,
    required this.appVersion,
    required this.watchUsed,
    required this.heartRateUsed,
  });

  static const fallbackAppVersion = '1.0.0';

  final String model;
  final String osVersion;
  final String appVersion;
  final bool watchUsed;
  final bool heartRateUsed;

  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'os_version': osVersion,
      'app_version': appVersion,
      'watch_used': watchUsed,
      'heart_rate_used': heartRateUsed,
    };
  }

  static Future<RunDeviceInfo> collect({
    required bool watchUsed,
    required bool heartRateUsed,
    Future<({String model, String osVersion})> Function()? readDevice,
    Future<String> Function()? readAppVersion,
  }) async {
    var model = '';
    var osVersion = '';
    try {
      final device = await (readDevice ?? readPhoneDevice)();
      model = device.model;
      osVersion = device.osVersion;
    } catch (_) {}
    var appVersion = '';
    try {
      appVersion = await (readAppVersion ?? readInstalledAppVersion)();
    } catch (_) {}
    return RunDeviceInfo(
      model: clipDeviceField(model),
      osVersion: clipDeviceField(
        osVersion.isEmpty ? _platformOsLabel() : osVersion,
      ),
      appVersion: clipDeviceField(
        appVersion.isEmpty ? fallbackAppVersion : appVersion,
        32,
      ),
      watchUsed: watchUsed,
      heartRateUsed: heartRateUsed,
    );
  }
}

String clipDeviceField(String value, [int limit = 80]) {
  final cleaned = value.replaceAll(RegExp(r'[\u0000-\u001F\u007F]'), ' ');
  final collapsed = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (collapsed.length <= limit) return collapsed;
  return collapsed.substring(0, limit);
}

String _platformOsLabel() {
  final raw = Platform.operatingSystemVersion.trim();
  if (raw.isEmpty) return Platform.operatingSystem;
  if (Platform.isAndroid && !raw.toLowerCase().startsWith('android')) {
    return 'Android $raw';
  }
  if (Platform.isIOS && !raw.toLowerCase().startsWith('ios')) {
    return 'iOS $raw';
  }
  return raw;
}

Future<({String model, String osVersion})> readPhoneDevice() async {
  var model = Platform.isAndroid ? '' : Platform.operatingSystem;
  var release = '';
  if (Platform.isAndroid) {
    try {
      final result = await Process.run('getprop', ['ro.product.model']);
      model = '${result.stdout}'.trim();
    } catch (_) {}
    try {
      final result =
          await Process.run('getprop', ['ro.build.version.release']);
      release = '${result.stdout}'.trim();
    } catch (_) {}
  }
  if (model.isEmpty) model = Platform.operatingSystem;
  return (
    model: model,
    osVersion: androidOsLabel(release) ?? _platformOsLabel(),
  );
}

/// 안드로이드 버전 번호("12")를 "Android 12"로. 비어 있으면 null.
String? androidOsLabel(String release) {
  final trimmed = release.trim();
  if (trimmed.isEmpty) return null;
  return 'Android $trimmed';
}

Future<String> readInstalledAppVersion() async {
  final info = await PackageInfo.fromPlatform();
  final version = info.version.trim();
  final build = info.buildNumber.trim();
  if (version.isEmpty) return RunDeviceInfo.fallbackAppVersion;
  if (build.isEmpty) return version;
  return '$version+$build';
}
