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
import '../core/auth/firebase_auth_messages.dart';
import '../core/constants/economy_constants.dart';
import '../core/constants/legal_constants.dart';
import '../core/navigation/app_route_nav.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_text_styles.dart';
import '../data/repositories/auth_repository.dart'
    show authRepositoryProvider;
import '../features/onboarding/src_onboarding_controller.dart';
import '../features/onboarding/widgets/chibi_tier_avatar.dart';
import '../features/onboarding/widgets/nickname_change_sheet.dart';
import 'pro_tools_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadPushPreference();
  }

  Future<void> _loadPushPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_pushPrefKey) ?? false;
    if (!mounted) return;
    setState(() => _pushEnabled = saved);
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

  void _openProTools() {
    AppRouteNav.push<void>(
      context,
      RouteNames.runningGearProTools,
      materialBuilder: (_) => const ProToolsScreen(),
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
          title: const Text('회원 탈퇴'),
          content: const Text(
            '탈퇴 시 Firebase Auth 계정과 Wallet 잔액이 서버에서 삭제·익명화되며 '
            '로컬 캐시도 초기됩니다. 이 작업은 되돌릴 수 없습니다.\n\n'
            '정말 탈퇴하시겠습니까?',
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
              child: const Text('탈퇴하기'),
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
      _showSnack('회원 탈퇴가 완료되었습니다.');
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
    final displayNick = SrcOnboardingController.isUnsetNickname(nickname)
        ? '미설정'
        : nickname;

    return Scaffold(
      backgroundColor: AppColors.settingsBackground,
      appBar: AppBar(
        backgroundColor: AppColors.settingsBackground,
        elevation: 0,
        foregroundColor: AppColors.textBlack,
        title: Text(
          AppStrings.myPageSettings,
          style: AppTextStyles.header1.copyWith(fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
              return;
            }
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
              return;
            }
            context.go(RouteNames.myPage);
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppShapes.termsHorizontalPadding,
          8,
          AppShapes.termsHorizontalPadding,
          32,
        ),
        children: [
          _SettingsCategoryCard(
            title: '계정 프로필 관리',
            children: [
              ListTile(
                leading: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.tealAccent,
                ),
                title: Text(
                  '닉네임 변경 (수수료 ${EconomyConstants.nicknameChangeFeeDia} DIA)',
                  style: AppTextStyles.agreementLabel.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '현재 · $displayNick',
                  style: AppTextStyles.caption,
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textGreyLight,
                ),
                onTap: () => NicknameChangeSheet.show(context),
              ),
              const Divider(height: 1, color: AppColors.borderLight),
              ListTile(
                leading: ChibiTierAvatar(
                  tier: tier ?? UserTier.unratedFallback,
                  size: 40,
                ),
                title: Text(
                  '현재 내 동물 티어 확인',
                  style: AppTextStyles.agreementLabel.copyWith(
                    fontWeight: FontWeight.w600,
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
          const SizedBox(height: 14),
          _SettingsCategoryCard(
            title: '알림 및 서비스 제어',
            children: [
              SwitchListTile.adaptive(
                secondary: const Icon(
                  Icons.notifications_active_outlined,
                  color: AppColors.tealAccent,
                ),
                title: Text(
                  '푸시 알림 수신 설정',
                  style: AppTextStyles.agreementLabel.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '재화 실시간 획득 · 크루 긴급 공지',
                  style: AppTextStyles.caption,
                ),
                value: _pushEnabled,
                activeThumbColor: AppColors.tealAccent,
                activeTrackColor: AppColors.tealAccent.withValues(alpha: 0.4),
                onChanged: (value) {
                  setState(() => _pushEnabled = value);
                  _savePushPreference(value);
                  final uid = authUser?.uid;
                  if (uid != null) {
                    _updatePushNotifications(uid: uid, enabled: value);
                  }
                },
              ),
              const Divider(height: 1, color: AppColors.borderLight),
              ListTile(
                leading: const Icon(
                  Icons.health_and_safety_outlined,
                  color: AppColors.tealAccent,
                ),
                title: Text(
                  '위치 및 건강 데이터 권한 재인증',
                  style: AppTextStyles.agreementLabel.copyWith(
                    fontWeight: FontWeight.w600,
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
                        Icons.chevron_right_rounded,
                        color: AppColors.textGreyLight,
                      ),
                onTap: _permissionBusy ? null : _reauthLocationAndHealth,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SettingsCategoryCard(
            title: '러너 전문 기능',
            children: [
              ListTile(
                leading: const Icon(
                  Icons.sports_score_outlined,
                  color: AppColors.tealAccent,
                ),
                title: Text(
                  AppStrings.proToolsTitle,
                  style: AppTextStyles.agreementLabel.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  AppStrings.proToolsSubtitle,
                  style: AppTextStyles.caption,
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textGreyLight,
                ),
                onTap: _openProTools,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SettingsCategoryCard(
            title: '약관 및 계정 지원',
            children: [
              ListTile(
                leading: const Icon(
                  Icons.description_outlined,
                  color: AppColors.tealAccent,
                ),
                title: Text(
                  '서비스 이용약관 및 개인정보 처리방침',
                  style: AppTextStyles.agreementLabel.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'LBS · 민감정보 핀셋 처리방침',
                  style: AppTextStyles.caption,
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textGreyLight,
                ),
                onTap: _openLegalDocuments,
              ),
              const Divider(height: 1, color: AppColors.borderLight),
              ListTile(
                leading: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.tealAccent,
                ),
                title: Text(
                  '로그아웃',
                  style: AppTextStyles.agreementLabel.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Google / Apple Auth 세션 종료',
                  style: AppTextStyles.caption,
                ),
                onTap: authUser == null ? null : _signOut,
              ),
              const Divider(height: 1, color: AppColors.borderLight),
              ListTile(
                leading: const Icon(
                  Icons.person_off_outlined,
                  color: AppColors.error,
                ),
                title: Text(
                  '회원 탈퇴 (Account Withdrawal)',
                  style: AppTextStyles.agreementLabel.copyWith(
                    fontWeight: FontWeight.w600,
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
    );
  }
}

class _SettingsCategoryCard extends StatelessWidget {
  const _SettingsCategoryCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.tealAccent.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.tealAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.tealAccent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 4),
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
         margin: 20px; color: #171717; line-height: 1.55; }
  h1 { font-size: 20px; margin: 0 0 12px; }
  h2 { font-size: 16px; margin: 22px 0 8px; color: #11B79C; }
  p { font-size: 14px; margin: 0 0 10px; color: #3f3f46; }
  .note { background: #E8F7F2; padding: 12px 14px; border-radius: 12px;
          font-size: 13px; color: #0f766e; }
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
        ),
      )
      ..loadHtmlString(_html);
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
