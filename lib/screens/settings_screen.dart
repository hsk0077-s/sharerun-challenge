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
import '../l10n/app_locale.dart';
import '../l10n/app_localizations.dart';
import '../l10n/remaining_surface.dart';
import '../l10n/legal_fallback.dart';
import '../l10n/surface_copy.dart';
import '../l10n/surface_rest.dart';
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
    final copy = SettingsSurfaceCopy.of(Localizations.localeOf(context));
    setState(() => _permissionBusy = true);
    try {
      final locationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!locationEnabled) {
        _showSnack(copy.locationOff);
        await openAppSettings();
        return;
      }

      var location = await Geolocator.checkPermission();
      if (location == LocationPermission.denied) {
        location = await Geolocator.requestPermission();
      }
      if (location == LocationPermission.deniedForever) {
        _showSnack(copy.locationDenied);
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
        _showSnack(copy.permOk);
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
            title: Text(copy.permDialogTitle),
            content: Text(
              label == null ? copy.permShort : copy.permNeed(label),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(copy.close),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.tealAccent,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(copy.openSettings),
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
    final copy = SettingsSurfaceCopy.of(Localizations.localeOf(context));
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(copy.logoutTitle),
          content: Text(copy.logoutBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(copy.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.tealAccent,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(copy.logoutTitle),
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
    final copy = SettingsSurfaceCopy.of(Localizations.localeOf(context));
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(copy.deleteTitle),
          content: SingleChildScrollView(
            child: Text(
              copy.deleteBody(purchases: AppEnv.inAppPurchasesEnabled),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(copy.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(copy.deleteConfirm),
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
      _showSnack(
        SettingsSurfaceCopy.of(Localizations.localeOf(context)).accountDeleted,
      );
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
    final copy = SettingsSurfaceCopy.of(Localizations.localeOf(context));
    final displayNick = SrcOnboardingController.isUnsetNickname(nickname)
        ? copy.unsetNick
        : nickname;

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
                  tooltip: copy.back,
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
              RemainingSurface.tr(context, 'settings.title', '설정'),
              style: storeText(36, AppColors.nightInk, w: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            _SettingsCategoryCard(
              title: copy.catAccount,
              children: [
                ListTile(
                  title: Text(
                    copy.nickTitle(EconomyConstants.nicknameChangeFeeDia),
                    style: AppTextStyles.agreementLabel.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    copy.nickNow(displayNick),
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
                    copy.login,
                    style: AppTextStyles.agreementLabel.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    copy.loginSub,
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
                  key: const Key('language-settings'),
                  title: Text(
                    RemainingSurface.tr(context, 'settings_lang.title', '언어'),
                    style: AppTextStyles.agreementLabel.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    _languageLabel(context, ref.watch(appLocaleProvider)),
                    style: AppTextStyles.caption,
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.textGreyLight,
                  ),
                  onTap: () => showLanguageSheet(context),
                ),
                const Divider(height: 1, color: AppColors.nightLine),
                ListTile(
                  leading: ChibiTierAvatar(
                    tier: tier ?? UserTier.unratedFallback,
                    size: 40,
                  ),
                  title: Text(
                    copy.animalRow,
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
              title: copy.catAlerts,
              children: [
                SwitchListTile.adaptive(
                  key: const Key('settings-walking-reminders'),
                  title: Text(
                    copy.walkTitle,
                    style: AppTextStyles.agreementLabel.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    copy.walkSub,
                    style: AppTextStyles.caption,
                  ),
                  value: _remindersEnabled,
                  onChanged: (value) => unawaited(_setReminders(value)),
                ),
                const Divider(height: 1, color: AppColors.nightLine),
                SwitchListTile.adaptive(
                  title: Text(
                    copy.pushTitle,
                    style: AppTextStyles.agreementLabel.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    copy.pushSub,
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
                      copy.botTitle,
                      style: AppTextStyles.agreementLabel.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      copy.botSub,
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
                      copy.coachSub,
                      style: AppTextStyles.caption,
                    ),
                    trailing: const Icon(Icons.arrow_forward_rounded),
                    onTap: () => CoachPlusUpsellSheet.show(context),
                  ),
                ],
                const Divider(height: 1, color: AppColors.nightLine),
                ListTile(
                  title: Text(
                    copy.permTitle,
                    style: AppTextStyles.agreementLabel.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    copy.permSub,
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
                    copy.checkSub,
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
              title: copy.catRunner,
              children: [
                ListTile(
                  key: const Key('settings-watch-connection'),
                  title: Text(
                    copy.watchTitle,
                    style: AppTextStyles.agreementLabel.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    copy.watchSub,
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
              title: copy.catSecurity,
              children: [
                ListTile(
                  key: const Key('security-center-settings'),
                  title: Text(
                    copy.securityCenter,
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
              title: copy.catLegal,
              children: [
                ListTile(
                  key: const Key('intro-replay-settings'),
                  title: Text(
                    copy.introTitle,
                    style: AppTextStyles.agreementLabel.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(copy.introSub, style: AppTextStyles.caption),
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
                    copy.termsTitle,
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
                    copy.privacyTitle,
                    style: AppTextStyles.agreementLabel.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    copy.privacySub,
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
                    copy.logoutTitle,
                    style: AppTextStyles.agreementLabel.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    copy.logoutSub,
                    style: AppTextStyles.caption,
                  ),
                  onTap: authUser == null ? null : _signOut,
                ),
                const Divider(height: 1, color: AppColors.nightLine),
                ListTile(
                  title: Text(
                    copy.deleteTitle,
                    style: AppTextStyles.agreementLabel.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                  subtitle: Text(
                    copy.deleteSub,
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
    final unrated = tier == null || tier!.isUnrated;
    final label = unrated
        ? RemainingSurface.tr(
            context,
            'settings_tier.unrated',
            '등급 없음 · 첫 인증 1km 후 거북이 브론즈로 시작',
          )
        : tier!.gradeTitleWithEmoji(Localizations.localeOf(context));
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

  String _fallbackHtml() => legalFallbackHtml(Localizations.localeOf(context));

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
              _controller.loadHtmlString(_fallbackHtml());
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
          SettingsSurfaceCopy.of(Localizations.localeOf(context)).legalChrome,
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

String _languageLabel(BuildContext context, Locale? chosen) {
  if (chosen == null) {
    return RemainingSurface.tr(
      context,
      'settings_lang.follow',
      '기기 설정 따르기',
    );
  }
  for (final c in appLocaleChoices) {
    if (c.code == chosen.languageCode) return c.name;
  }
  return chosen.languageCode;
}

/// Bottom sheet to pick the app language (or follow the phone).
Future<void> showLanguageSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) {
        final chosen = ref.watch(appLocaleProvider);
        Widget row(String? code, String name) {
          final selected = chosen?.languageCode == code;
          return ListTile(
            key: Key('language-option-${code ?? 'system'}'),
            title: Text(name),
            trailing: selected ? const Icon(Icons.check_rounded) : null,
            onTap: () async {
              final locale = code == null
                  ? null
                  : resolveAppLocale(
                      Locale(code),
                      ShareRunLocalizations.supportedLocales,
                    );
              await ref.read(appLocaleProvider.notifier).choose(locale);
              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
            },
          );
        }

        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    RemainingSurface.tr(
                      context,
                      'settings_lang.sheet',
                      '언어 선택',
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                row(
                  null,
                  RemainingSurface.tr(
                    context,
                    'settings_lang.follow',
                    '기기 설정 따르기',
                  ),
                ),
                for (final c in appLocaleChoices) row(c.code, c.name),
              ],
            ),
          ),
        );
      },
    ),
  );
}
