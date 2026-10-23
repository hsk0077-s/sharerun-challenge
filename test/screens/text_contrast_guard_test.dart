import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/features/onboarding/widgets/nickname_change_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_run_challenge/screens/angel_book_page.dart';
import 'package:share_run_challenge/screens/brand_sponsor_screen.dart';
import 'package:share_run_challenge/screens/create_challenge_room_screen.dart';
import 'package:share_run_challenge/screens/crew_manager_screen.dart';
import 'package:share_run_challenge/screens/device_connection_screen.dart';
import 'package:share_run_challenge/screens/health_data_consent_screen.dart';
import 'package:share_run_challenge/screens/in_challenge_screen.dart';
import 'package:share_run_challenge/screens/item_inventory_screen.dart';
import 'package:share_run_challenge/screens/level_test_running_screen.dart';
import 'package:share_run_challenge/screens/login_screen.dart';
import 'package:share_run_challenge/screens/map_crew_screen.dart';
import 'package:share_run_challenge/screens/notification_center_screen.dart';
import 'package:share_run_challenge/screens/onboarding_screen.dart';
import 'package:share_run_challenge/screens/pro_tools_screen.dart';
import 'package:share_run_challenge/screens/run_tracking_screen.dart';
import 'package:share_run_challenge/screens/smart_watch_sync_screen.dart';
import 'package:share_run_challenge/screens/watch_connection_screen.dart';
import 'package:share_run_challenge/screens/watch_settings_screen.dart';

/// 앱 글씨 색이 야간 테마(밝은 색)로 바뀐 뒤, 밝은 배경을 따로 정해 둔 화면에서 글씨가 안 보이는
/// 문제가 있었다. 아래 화면들은 글씨 대비(WCAG)를 지킨다. 새 화면을 만들 때 여기에 더한다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final screens = <String, Widget Function()>{
    'AngelBookPage': () => const AngelBookPage(),
    'BrandSponsorScreen': () => const BrandSponsorScreen(),
    'CreateChallengeRoomScreen': () => const CreateChallengeRoomScreen(),
    'CrewManagerScreen': () => const CrewManagerScreen(),
    'DeviceConnectionScreen': () => const DeviceConnectionScreen(),
    'HealthDataConsentScreen': () => const HealthDataConsentScreen(),
    'InChallengeScreen': () => const InChallengeScreen(),
    'ItemInventoryScreen': () => const ItemInventoryScreen(),
    'LevelTestRunningScreen': () => const LevelTestRunningScreen(),
    'LoginScreen': () => const LoginScreen(),
    'MapCrewScreen': () => const MapCrewScreen(),
    'NotificationCenterScreen': () => const NotificationCenterScreen(),
    'OnboardingScreen': () => const OnboardingScreen(),
    'ProToolsScreen': () => const ProToolsScreen(),
    'RunTrackingScreen': () => const RunTrackingScreen(),
    'SmartWatchSyncScreen': () => const SmartWatchSyncScreen(),
    'WatchConnectionScreen': () => const WatchConnectionScreen(),
    'WatchSettingsScreen': () => const WatchSettingsScreen(),
    'NicknameChangeSheet': () => const Scaffold(body: NicknameChangeSheet()),
  };

  for (final entry in screens.entries) {
    testWidgets('${entry.key} text is readable', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(theme: SrcTheme.night, home: entry.value()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
      tester.takeException();
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  }
}
