import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the Health Connect listing on Google Play (with HTTPS fallback).
abstract final class HealthConnectStoreLauncher {
  static const playStorePackage = 'com.google.android.apps.healthdata';
  static const marketUri =
      'market://details?id=$playStorePackage&url=healthconnect%3A%2F%2Fonboarding';
  static const httpsUri =
      'https://play.google.com/store/apps/details?id=$playStorePackage';

  static Future<bool> open() async {
    if (!Platform.isAndroid) {
      return false;
    }

    final marketOpened = await _tryLaunch(
      Uri.parse(marketUri),
      mode: LaunchMode.externalApplication,
    );
    if (marketOpened) {
      return true;
    }

    return _tryLaunch(
      Uri.parse(httpsUri),
      mode: LaunchMode.externalApplication,
    );
  }

  static Future<bool> _tryLaunch(
    Uri uri, {
    required LaunchMode mode,
  }) async {
    try {
      final canOpen = await canLaunchUrl(uri);
      if (!canOpen) {
        return false;
      }
      return await launchUrl(uri, mode: mode);
    } catch (error, stackTrace) {
      debugPrint('HealthConnectStoreLauncher: $error\n$stackTrace');
      return false;
    }
  }
}
