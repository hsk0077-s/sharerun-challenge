import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

// [핀셋 복구] 터미널에서 생성한 Firebase 설정 파일을 정확히 불러옵니다.
import 'firebase_options.dart'; 

import 'app/app.dart';
import 'app/app_config.dart';
import 'app/providers/app_providers.dart';
import 'core/auth/auth_session_bootstrap.dart';
import 'core/config/app_env.dart';
import 'core/notifications/notification_service.dart';
import 'features/iap/widgets/iap_lifecycle_host.dart';
import 'features/pedometer/solo_pedometer_foreground.dart';
import 'features/pedometer/walking_challenge_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await KakaoSdk.init(nativeAppKey: 'c45c63710e60f98b3fe617ae0b75c274');
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("DotEnv Load Error: $e");
    // fallback if needed
  }
  await AppEnv.load();

  SoloPedometerForeground.bindUi();
  unawaited(WalkingChallengeNotificationService.ensureInitialized());
  unawaited(NotificationService.instance.initialize());

  // 파이어베이스 백엔드 엔진 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final bootstrap = await AuthSessionBootstrap.run();
  AppConfig.initialRoute = bootstrap.initialRoute;

  // TODO: PM TEST INITIALIZATION — debug only. Release must not seed balances.
  if (kDebugMode) {
    await _runPmTestInitializationOnce();
  }

  runApp(
    ProviderScope(
      overrides: [
        if (bootstrap.session != null)
          persistedAuthSessionProvider.overrideWith(() {
            final notifier = PersistedAuthSessionNotifier();
            notifier.seed(bootstrap.session);
            return notifier;
          }),
      ],
      child: const IapLifecycleHost(
        child: ShareRunChallengeApp(),
      ),
    ),
  );
}

// TODO: PM TEST INITIALIZATION
// ---------------------------------------------------------------------------
// [임시] PM 테스트 환경 1회 구축 스크립트.
// 다음 빌드에서 비활성화하려면:
//   1) main() 안의 `_runPmTestInitializationOnce()` 호출을 주석 처리하거나
//   2) 이 함수 전체를 삭제하세요.
// 재실행이 필요하면 SharedPreferences 키 `pm_qa_test_init_v1_done` 을 제거하세요.
// ---------------------------------------------------------------------------
Future<void> _runPmTestInitializationOnce() async {
  if (!kDebugMode) {
    return;
  }
  const doneKey = 'pm_qa_test_init_v1_done';
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(doneKey) ?? false) return;

    for (final key in prefs.getKeys().toList()) {
      if (key == doneKey) continue;
      if (key == 'SHARE' || key == 'DIA' || key == 'VALUE') continue;
      final isStepCache = key.contains('step') ||
          key.contains('steps') ||
          key.contains('_km') ||
          key.contains('claimed') ||
          key.contains('collectedShare') ||
          key.contains('collected_share') ||
          key.contains('hasReceivedMilestone') ||
          key.contains('hasReceivedBonus') ||
          key.contains('hasReceivedChallenge') ||
          key.contains('solo_pedo_') ||
          key.contains('src_smart_push') ||
          key == 'lastSavedDate';
      if (isStepCache) {
        await prefs.remove(key);
      }
    }

    var sensorTotal = 0;
    try {
      final event = await Pedometer.stepCountStream.first.timeout(
        const Duration(seconds: 3),
      );
      sensorTotal = event.steps;
    } catch (e) {
      debugPrint('PM TEST INIT sensor read skipped: $e');
    }
    final todayIso = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setInt('stepOffset', sensorTotal);
    await prefs.setInt('${todayIso}_step_offset', sensorTotal);
    await prefs.setString('lastSavedDate', todayIso);
    await prefs.setDouble('collected_share_coins', 0);
    await prefs.setBool('src_smart_push_fired_morning', false);
    await prefs.setBool('src_smart_push_fired_lunch', false);
    await prefs.setBool('src_smart_push_fired_evening', false);
    await prefs.setBool('src_smart_push_sniped_m1', false);
    await prefs.setBool('src_smart_push_sniped_m2', false);
    await prefs.setBool('src_smart_push_sniped_m3', false);
    await prefs.setString('src_smart_push_date', todayIso);

    await prefs.setInt('SHARE', 200000);
    await prefs.setInt('DIA', 500);
    await prefs.setInt('VALUE', 52000);

    await prefs.setBool(doneKey, true);
    debugPrint(
      'PM TEST INIT done — steps offset=$sensorTotal, '
      'SHARE=200000 DIA=500 VALUE=52000',
    );
  } catch (e, st) {
    debugPrint('PM TEST INIT failed: $e\n$st');
  }
}
