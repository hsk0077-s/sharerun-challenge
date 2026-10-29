import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../app/app.dart';
import '../app/providers/app_providers.dart';
import '../app/router/route_names.dart';
import '../core/api/api_exception.dart';
import '../core/config/app_env.dart';
import '../features/legal/legal_links.dart';
import '../core/auth/firebase_auth_messages.dart';
import '../core/constants/economy_constants.dart';
import '../core/constants/legal_constants.dart';
import '../core/navigation/app_route_nav.dart';
import '../core/notifications/notification_service.dart';
import '../core/notifications/reminder_preferences.dart';
import '../features/pedometer/walking_challenge_notification_service.dart';
import 'device_connection_screen.dart';
import '../core/strings/app_strings.dart';
import '../l10n/surface_copy.dart';
import '../features/shop/widgets/store_look.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../data/repositories/auth_repository.dart' show authRepositoryProvider;
import '../features/onboarding/src_onboarding_controller.dart';
import '../features/onboarding/widgets/chibi_tier_avatar.dart';
import '../features/onboarding/widgets/nickname_change_sheet.dart';
import '../features/iap/widgets/coach_plus_upsell_sheet.dart';
import '../features/launch/intro_screen.dart';
import '../features/run_tracking/run_recording_checklist.dart';
import '../features/run_tracking/run_recording_policy.dart';
import '../features/mini_bot/mini_bot_dock.dart';
import '../features/voice_coaching/voice_coaching_providers.dart';
import 'pro_tools_screen.dart';
import 'login_connections_screen.dart';
import 'security_privacy_center_screen.dart';

/// 마이페이지 종합 설정 화면 — 계정·알림·프로툴·약관/지원.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _pushPrefKey = 'push_notification';

  var _permissionBusy = false;
  var _pushEnabled = false;
  var _remindersEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPushPreference();
    unawaited(_loadReminderPreference());
  }

  Future<void> _loadPushPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_pushPrefKey) ?? false;
    if (!mounted) return;
    setState(() => _pushEnabled = saved);
  }

  Future<void> _loadReminderPreference() async {
    final enabled = await ReminderPreferences.isEnabled();
    if (!mounted) return;
    setState(() => _remindersEnabled = enabled);
  }

  /// 걷기 알림(아침·점심·저녁)을 켜고 끈다. 끄면 예약된 알림을 모두 지운다.
  Future<void> _setReminders(bool enabled) async {
    setState(() => _remindersEnabled = enabled);
    await ReminderPreferences.setEnabled(enabled);
    await NotificationService.instance.applyPreference(enabled);
    if (!enabled) {
      await WalkingChallengeNotificationService.syncDailyPushes(
        enabled: false,
        nickname: ref.read(userNicknameProvider),
      );
    }
  }

  Future<void> _savePushPreference(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pushPrefKey, enabled);
  }

  Future<void> _updatePushNotifications({
    required String uid,
    required bool enabled,
  }) async {
    try {
      final userRepository = ref.read(userRepositoryProvider);
      if (enabled) {
        await ref.read(pushNotificationServiceProvider).syncTokenForUser(
              uid: uid,
              userRepository: userRepository,
              requestPermission: true,
            );
      } else {
        await userRepository.updatePushSettings(uid: uid, enabled: false);
      }
    } catch (error) {
      _showSnack(ApiErrorMessage.from(error));
    }
  }

  Future<void> _reauthLocationAndHealth() async {
    if (_permissionBusy) return;
    setState(() => _permissionBusy = true);
    try {
      final locationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!locationEnabled) {
        _showSnack('위치 서비스가 꺼져 있습니다. 시스템 설정에서 활성화해 주세요.');
        await openAppSettings();
        return;
      }

      var location = await Geolocator.checkPermission();
      if (location == LocationPermission.denied) {
        location = await Geolocator.requestPermission();
      }
      if (location == LocationPermission.deniedForever) {
        _showSnack('위치 권한이 거부되었습니다. 설정에서 허용해 주세요.');
        await openAppSettings();
        return;
      }

      final permissionResult = await ref
          .read(watchRuntimePermissionsServiceProvider)
          .requestForWatchLinking();

      if (!mounted) return;

      if (permissionResult.granted &&
          (location == LocationPermission.always ||
              location == LocationPermission.whileInUse)) {
        _showSnack('위치 및 건강 데이터 권한이 확인되었습니다.');
        return;
      }

      final label = permissionResult.missingPermissionLabel;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('권한 재인증'),
            content: Text(
              label == null
                  ? '일부 권한이 부족합니다. 시스템 설정에서 위치·건강 데이터 권한을 허용해 주세요.'
                  : '$label 권한이 필요합니다. 설정에서 허용해 주세요.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('닫기'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.tealAccent,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('설정 열기'),
              ),
            ],
          );
        },
      );
      if (confirmed == true) {
        await openAppSettings();
      }
    } catch (error) {
      _showSnack(ApiErrorMessage.from(error));
    } finally {
      if (mounted) {
        setState(() => _permissionBusy = false);
      }
    }
  }

  void _openWatchConnection() {
    AppRouteNav.push<void>(
      context,
      RouteNames.watchSettings,
      materialBuilder: (_) => const DeviceConnectionScreen(),
    );
  }

  void _openProTools() {
    AppRouteNav.push<void>(
      context,
      RouteNames.runningGearProTools,
      materialBuilder: (_) => const ProToolsScreen(),
    );
  }

  void _replayIntro() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (routeContext) => IntroScreen(
          replay: true,
          onFinished: () => Navigator.of(routeContext).pop(),
        ),
      ),
    );
  }

  void _openLoginConnections() {
    AppRouteNav.push<void>(
      context,
      RouteNames.loginConnections,
      materialBuilder: (_) => const LoginConnectionsScreen(),
    );
  }

  void _openSecurityCenter() {
    AppRouteNav.push<void>(
      context,
      RouteNames.securityCenter,
      materialBuilder: (_) => const SecurityPrivacyCenterScreen(),
    );
  }

  void _openLegalDocuments() {
    AppRouteNav.push<void>(
      context,
      RouteNames.settingsLegal,
      materialBuilder: (_) => const SettingsLegalWebViewScreen(),
    );
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('로그아웃'),
          content: const Text('현재 세션을 종료하고 로그인 화면으로 이동합니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.tealAccent,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('로그아웃'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    try {
      final joined = ref.read(joinedTournamentIdsProvider).value ?? const {};
      if (joined.isNotEmpty) {
        await ref
            .read(pushNotificationServiceProvider)
            .clearTournamentTopics(joined);
      }
      await ref.read(authRepositoryProvider).signOut();
      await ref.read(localAuthStoreProvider).clear();
      ref.read(persistedAuthSessionProvider.notifier).replace(null);
      if (!mounted) return;
      navigateToLoginScreen();
    } catch (error) {
      _showSnack(FirebaseAuthMessages.from(error));
    }
  }

  Future<void> _withdrawAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('계정 삭제'),
          content: SingleChildScrollView(
            child: Text(
              '계정을 삭제하면 아래와 같이 처리되며 되돌릴 수 없습니다.\n\n'
              '• 보유한 SHARE·DIA·VALUE가 모두 사라지고, 현금으로 돌려받지 않습니다.\n'
              '• 러닝 기록 등 활동 기록은 30일 안에 삭제됩니다. 법령에 따라 보관해야 하는 결제·거래 기록은 5년간 보관한 뒤 삭제돼요.\n'
              '${AppEnv.inAppPurchasesEnabled ? '• Coach+ 구독은 자동으로 해지되지 않습니다. Google Play 스토어의 구독 메뉴에서 직접 해지해 주세요.\n' : ''}'
              '• 크루장이라면 먼저 크루장을 다른 크루원에게 넘겨 주세요.\n\n'
              '정말 삭제하시겠습니까?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('삭제하기'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    try {
      await ref.read(securedActionApiClientProvider).deleteAccount();
      final joined = ref.read(joinedTournamentIdsProvider).value ?? const {};
      if (joined.isNotEmpty) {
        await ref
            .read(pushNotificationServiceProvider)
            .clearTournamentTopics(joined);
      }
      await ref.read(authRepositoryProvider).signOut();
      await ref.read(localAuthStoreProvider).clear();
      ref.read(persistedAuthSessionProvider.notifier).replace(null);
      if (!mounted) return;
      _showSnack('계정이 삭제되었습니다.');
      navigateToLoginScreen();
    } catch (error) {
      _showSnack(FirebaseAuthMessages.from(error));
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authStateChangesProvider).value;
    final nickname = ref.watch(userNicknameProvider);
    final tier = ref.watch(activeUserTierStructProvider);
    final displayNick =
        SrcOnboardingController.isUnsetNickname(nickname) ? '미설정' : nickname;

    void goBack() {
      if (context.canPop()) {
        context.pop();
        return;
      }
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        return;
      }
      context.go(RouteNames.myPage);
    }

    return Scaffold(
      backgroundColor: AppColors.nightBg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
          children: [
            Row(
              children: [
                IconButton(
                  key: const Key('settings-back'),
                  onPressed: goBack,
                  tooltip: '뒤로',
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.nightInk,
                  ),
                ),
                const Spacer(),
                const StoreTag('SETTINGS'),
              ],
            ),
            Text(
              AppStrings.myPageSettings,
              style: storeText(36, AppColors.nightInk, w: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            _SettingsCategoryCard(
              title: '계정 프로필 관리',
              children: [
                ListTile(
                  title: Text(
                    '닉네임 변경 (수수료 ${EconomyConstants.nicknameChangeFeeDia} DIA)',
                    style: AppTextStyles.agreementLabel.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '현재 · $displayNick',
                    style: AppTextStyles.caption,
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.textGreyLight,
                  ),
                  onTap: () => NicknameChangeSheet.show(context),
                ),
                const Divider(height: 1, color: AppColors.nightLine),
                ListTile(
                  key: const Key('login-connections-settings'),
                  title: Text(
                    '로그인 연결',
                    style: AppTextStyles.agreementLabel.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text(
                    '구글·카카오를 한 계정으로',
                    style: AppTextStyles.caption,
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.textGreyLight,
                  ),
                  onTap: _openLoginConnections,
                ),
                const Divider(height: 1, color: AppColors.nightLine),
                ListTile(
                  leading: ChibiTierAvatar(
                    tier: tier ?? UserTier.unratedFallback,
                    size: 40,
                  ),
                  title: Text(
                    '현재 내 동물 티어 확인',
                    style: AppTextStyles.agreementLabel.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: _TierBadge(
                        tier: tier ?? UserTier.unratedFallback,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _SettingsCategoryCard(
              title: '알림 및 서비스 제어',
              children: [
                SwitchListTile.adaptive(
                  key: const Key('settings-walking-reminders'),
                  title: Text(
                    '걷기 알림 (아침·점심·저녁)',
                    style: AppTextStyles.agreementLabel.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '정해진 시각에 걷기를 알려 줘요. 끄면 이 알림은 오지 않아요.',
                    style: AppTextStyles.caption,
                  ),
                  value: _remindersEnabled,
                  onChanged: (value) => unawaited(_setReminders(value)),
                ),
                const Divider(height: 1, color: AppColors.nightLine),
                SwitchListTile.adaptive(
                  title: Text(
                    '푸시 알림 수신 설정',
                    style: AppTextStyles.agreementLabel.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '재화 실시간 획득 · 크루 긴급 공지',
                    style: AppTextStyles.caption,
                  ),
                  value: _pushEnabled,
                  onChanged: (value) {
                    setState(() => _pushEnabled = value);
                    _savePushPreference(value);
                    final uid = authUser?.uid;
                    if (uid != null) {
                      _updatePushNotifications(uid: uid, enabled: value);
                    }
                  },
                ),
                const Divider(height: 1, color: AppColors.nightLine),
                SwitchListTile.adaptive(
                  title: Text(
                    AppStrings.voiceCoachingTitle,
                    style: AppTextStyles.agreementLabel.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    AppStrings.voiceCoachingSubtitle,
                    style: AppTextStyles.caption,
                  ),
                  value: ref.watch(voiceCoachingEnabledProvider),
                  onChanged: (value) {
                    unawaited(
                      ref
                          .read(voiceCoachingEnabledProvider.notifier)
                          .setEnabled(value),
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.nightLine),
                ValueListenableBuilder<bool>(
                  valueListenable: MiniBotDockSettings.visible,
                  builder: (context, visible, _) => SwitchListTile.adaptive(
                    key: const Key('mini-bot-visible-switch'),
                    title: Text(
                      '달팽이봇 버튼 보이기',
                      style: AppTextStyles.agreementLabel.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: const Text(
                      '홈과 대회 화면에 달팽이 버튼을 보여요. 끌어서 옮길 수 있어요.',
                      style: AppTextStyles.caption,
                    ),
                    value: visible,
                    onChanged: (value) =>
                        unawaited(MiniBotDockSettings.setVisible(value)),
                  ),
                ),
                if (AppEnv.inAppPurchasesEnabled) ...[
                  const Divider(height: 1, color: AppColors.nightLine),
                  ListTile(
                    key: const Key('coach-plus-settings'),
                    title: Text(
                      'Coach+',
                      style: AppTextStyles.agreementLabel.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '무료 기본 러닝 안내 · 심박·상황에 맞춘 심층 코칭',
                      style: AppTextStyles.caption,
                    ),
                    trailing: const Icon(Icons.arrow_forward_rounded),
                    onTap: () => CoachPlusUpsellSheet.show(context),
                  ),
                ],
                const Divider(height: 1, color: AppColors.nightLine),
                ListTile(
                  title: Text(
                    '위치 및 건강 데이터 권한 재인증',
                    style: AppTextStyles.agreementLabel.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    'LBS 동의 · 스마트워치 연동 권한',
                    style: AppTextStyles.caption,
                  ),
                  trailing: _permissionBusy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.textGreyLight,
                        ),
                  onTap: _permissionBusy ? null : _reauthLocationAndHealth,
                ),
                const Divider(height: 1, color: AppColors.nightLine),
                ListTile(
                  key: const Key('run-recording-checklist-menu'),
                  title: Text(
                    runRecordingChecklistMenuLabel,
                    style: AppTextStyles.agreementLabel.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '위치 · 알림 · 배터리 최적화',
                    style: AppTextStyles.caption,
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.textGreyLight,
                  ),
                  onTap: () => openRunRecordingChecklist(context),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _SettingsCategoryCard(
              title: '러너 전문 기능',
              children: [
                ListTile(
                  key: const Key('settings-watch-connection'),
                  title: Text(
                    '스마트워치 · 워치 앱 연결',
                    style: AppTextStyles.agreementLabel.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '건강 데이터 연동, 워치 앱 6자리 연결 코드',
                    style: AppTextStyles.caption,
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.textGreyLight,
                  ),
                  onTap: _openWatchConnection,
                ),
                ListTile(
                  title: Text(
                    AppStrings.proToolsTitle,
                    style: AppTextStyles.agreementLabel.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    AppStrings.proToolsSubtitle,
                    style: AppTextStyles.caption,
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.textGreyLight,
                  ),
                  onTap: _openProTools,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _SettingsCategoryCard(
              title: '보안·프라이버시',
              children: [
                ListTile(
                  key: const Key('security-center-settings'),
                  title: Text(
                    '보안·프라이버시 센터',
                    style: AppTextStyles.agreementLabel.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    FairEarningCopy.of(Localizations.localeOf(context))
                        .settingsSubtitle,
                    style: AppTextStyles.caption,
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.textGreyLight,
                  ),
                  onTap: _openSecurityCenter,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _SettingsCategoryCard(
              title: '약관 및 계정 지원',
              children: [
                ListTile(
                  key: const Key('intro-replay-settings'),
                  title: Text(
                    '소개 다시 보기',
                    style: AppTextStyles.agreementLabel.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text('쉐어런 첫 소개 3장', style: AppTextStyles.caption),
                  trailing: const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.textGreyLight,
                  ),
                  onTap: _replayIntro,
                ),
                const Divider(height: 1, color: AppColors.nightLine),
                ListTile(
                  key: const Key('terms-of-service-settings'),
                  title: Text(
                    '서비스 이용약관',
                    style: AppTextStyles.agreementLabel.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    LegalConstants.termsOfServiceLinkLabel,
                    style: AppTextStyles.caption,
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.textGreyLight,
                  ),
                  onTap: () => unawaited(LegalLinks.openTermsOfService()),
                ),
                const Divider(height: 1, color: AppColors.nightLine),
                ListTile(
                  title: Text(
                    '서비스 이용약관 및 개인정보 처리방침',
                    style: AppTextStyles.agreementLabel.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '개인정보 처리방침 전문 · 위치·건강정보 안내',
                    style: AppTextStyles.caption,
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.textGreyLight,
                  ),
                  onTap: _openLegalDocuments,
                ),
                const Divider(height: 1, color: AppColors.nightLine),
                ListTile(
                  key: const Key('ai-credit-settings'),
                  title: Text(
                    LegalConstants.aiGeneratedTitle,
                    style: AppTextStyles.agreementLabel.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    LegalConstants.aiGeneratedCredit,
                    style: AppTextStyles.caption,
                  ),
                ),
                const Divider(height: 1, color: AppColors.nightLine),
                ListTile(
                  title: Text(
                    '로그아웃',
                    style: AppTextStyles.agreementLabel.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    'Google / Apple Auth 세션 종료',
                    style: AppTextStyles.caption,
                  ),
                  onTap: authUser == null ? null : _signOut,
                ),
                const Divider(height: 1, color: AppColors.nightLine),
                ListTile(
                  title: Text(
                    '계정 삭제',
                    style: AppTextStyles.agreementLabel.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                  subtitle: Text(
                    '계정·캐시 비활성화 (되돌릴 수 없음)',
                    style: AppTextStyles.caption,
                  ),
                  onTap: authUser == null ? null : _withdrawAccount,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 설정 묶음: 작은 글머리 + 줄마다 가는 선. 카드 바탕은 없다.
class _SettingsCategoryCard extends StatelessWidget {
  const _SettingsCategoryCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.zero,
          minVerticalPadding: 10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 2),
            child: Text(
              title,
              style: storeText(
                12,
                AppColors.nightMuted,
                w: FontWeight.w800,
                ls: 0.4,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.nightLine),
          ...children,
          const Divider(height: 1, color: AppColors.nightLine),
        ],
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tier});

  final UserTier? tier;

  @override
  Widget build(BuildContext context) {
    final label = (tier ?? UserTier.unratedFallback).displayNameWithEmoji;
    final tint = tier?.medal.medalColor ?? AppColors.tealAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tint.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textBlack,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// LBS·개인정보 처리방침 상세 조회용 인앱 웹뷰.
class SettingsLegalWebViewScreen extends StatefulWidget {
  const SettingsLegalWebViewScreen({super.key});

  @override
  State<SettingsLegalWebViewScreen> createState() =>
      _SettingsLegalWebViewScreenState();
}

class _SettingsLegalWebViewScreenState
    extends State<SettingsLegalWebViewScreen> {
  late final WebViewController _controller;
  var _loading = true;

  static const _html = '''
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<style>
  body { font-family: -apple-system, BlinkMacSystemFont, 'Pretendard', sans-serif;
         margin: 20px; color: #E8EFE6; background: #070B09; line-height: 1.55; }
  h1 { font-size: 20px; margin: 0 0 12px; }
  h2 { font-size: 16px; margin: 22px 0 8px; color: #D4FF4A; }
  p { font-size: 14px; margin: 0 0 10px; color: #93A299; }
  .note { background: #101813; padding: 12px 14px; border-radius: 12px;
          font-size: 13px; color: #D4FF4A; }
</style>
</head>
<body>
  <h1>서비스 이용약관 및 개인정보 처리방침</h1>
  <h2>${LegalConstants.termsOfServiceTitle}</h2>
  <p>${LegalConstants.termsOfServiceSummary}</p>
  <h2>${LegalConstants.privacyPolicyTitle}</h2>
  <p>${LegalConstants.privacyPolicySummary}</p>
  <h2>위치기반서비스(LBS) 약관</h2>
  <p>러닝 검증·크루 맵·스탬프 투어를 위해 위치정보를 수집·이용합니다.
     동의 철회 시 위치 기반 기능이 제한될 수 있습니다.</p>
  <h2>${LegalConstants.healthDataConsentTitle}</h2>
  <p>${LegalConstants.healthDataConsentSummary}</p>
  <div class="note">${LegalConstants.ephemeralSensorPolicy}</div>
  <h2>${LegalConstants.healthDisclaimerTitle}</h2>
  <p>${LegalConstants.healthDisclaimer}</p>
</body>
</html>
''';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          // Offline or the page is unreachable: show the built-in summary
          // instead of an empty error page.
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) {
              _controller.loadHtmlString(_html);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(LegalConstants.privacyPolicyUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        foregroundColor: AppColors.textBlack,
        elevation: 0,
        title: Text(
          '약관 · 개인정보',
          style: AppTextStyles.header1.copyWith(fontSize: 18),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.tealAccent),
            ),
        ],
      ),
    );
  }
}
