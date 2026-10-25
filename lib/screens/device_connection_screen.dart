import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

import '../app/providers/app_providers.dart';
import '../app/router/route_names.dart';
import '../core/api/api_exception.dart';
import '../core/config/app_env.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/src_gradient_background.dart';
import '../core/widgets/src_sync_button.dart';
import '../data/models/user_model.dart';
import 'garmin_auth_screen.dart';
import 'health_data_consent_screen.dart';
import 'wearable_brand_guide_sheet.dart';

/// 네이티브 헬스(Apple Health / Google Health Connect) + 외부 기기 연동 화면.
class DeviceConnectionScreen extends ConsumerStatefulWidget {
  const DeviceConnectionScreen({super.key});

  @override
  ConsumerState<DeviceConnectionScreen> createState() =>
      _DeviceConnectionScreenState();
}

class _DeviceConnectionScreenState
    extends ConsumerState<DeviceConnectionScreen> {
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authStateChangesProvider);
    final profileAsync = ref.watch(activeUserProfileProvider);

    // AsyncValue / null 방어 — 로딩·에러 시 강제 렌더로 레드스크린 방지
    if (authAsync.isLoading || profileAsync.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bgGradientEnd,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryMint),
        ),
      );
    }

    final authUser = authAsync.value;
    final profile = profileAsync.value;
    final watchType = profile?.watchType ?? WatchType.none;

    return Scaffold(
      backgroundColor: AppColors.bgGradientEnd,
      body: SRCGradientBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppShapes.termsHorizontalPadding,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: AppColors.textBlack,
                      onPressed: _busy ? null : _safeBack,
                    ),
                    Expanded(
                      child: Text(
                        AppStrings.deviceConnectionTitle,
                        style: AppTextStyles.termsTitle.copyWith(fontSize: 20),
                      ),
                    ),
                    TextButton(
                      onPressed: _busy ? null : () => _onSkip(authUser?.uid),
                      child: Text(
                        AppStrings.watchSyncSkip,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppShapes.termsHorizontalPadding,
                    8,
                    AppShapes.termsHorizontalPadding,
                    24,
                  ),
                  children: [
                    _StatusCard(watchType: watchType),
                    const SizedBox(height: 24),

                    // ── Section B: 네이티브 헬스 연동 ───────────────
                    Text(
                      AppStrings.deviceConnectionNativeTitle,
                      style: AppTextStyles.header1.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    _NativeHealthConnectTile(
                      label: AppStrings.watchSyncApple,
                      caption: '(Apple Watch 전 기종 지원)',
                      leading: const AppleHealthIcon(),
                      enabled: !_busy && authUser != null,
                      onPressed: () => _connectNativeHealth(
                        watchType: WatchType.appleWatch,
                        uid: authUser?.uid,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _NativeHealthConnectTile(
                      label: AppStrings.watchSyncGoogle,
                      caption: AppStrings.deviceConnectionGoogleCaption,
                      leading: const GoogleHealthConnectIcon(),
                      enabled: !_busy && authUser != null,
                      onPressed: () =>
                          _connectGoogleHealthConnect(uid: authUser?.uid),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      key: const Key('wearable-guide-entry'),
                      onPressed: () => showWearableBrandGuide(
                        context,
                        onConnect: () => _connectFromGuide(authUser?.uid),
                      ),
                      icon: const Icon(Icons.search_rounded),
                      label: const Text(AppStrings.wearableGuideEntry),
                    ),
                    const SizedBox(height: 24),
                    const _BleHeartRateSection(),
                    const SizedBox(height: 28),

                    Text(
                      AppStrings.deviceConnectionExternalTitle,
                      style: AppTextStyles.header1.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    _ExternalDeviceTile(
                      label: WatchType.garmin.displayLabel,
                      selected: watchType == WatchType.garmin,
                      enabled: !_busy && authUser != null,
                      onConnect: AppEnv.garminLinkEnabled
                          ? () => _openGarminOAuth(authUser?.uid)
                          : _showComingSoonDialog,
                    ),
                    const SizedBox(height: 8),
                    _ExternalDeviceTile(
                      label: WatchType.suunto.displayLabel,
                      selected: watchType == WatchType.suunto,
                      enabled: !_busy && authUser != null,
                      onConnect: _showComingSoonDialog,
                    ),
                    const SizedBox(height: 8),
                    _ExternalDeviceTile(
                      label: WatchType.coros.displayLabel,
                      selected: watchType == WatchType.coros,
                      enabled: !_busy && authUser != null,
                      onConnect: _showComingSoonDialog,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      key: const Key('watch-app-preview-entry'),
                      onPressed: () => context.push(RouteNames.watchAppPreview),
                      child: const Text('워치 전용 앱 (예정) 미리 보기'),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      AppStrings.deviceConnectionSingleActiveNote,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textGreyLight,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _safeBack() {
    try {
      final nav = Navigator.of(context);
      if (nav.canPop()) {
        nav.pop();
        return;
      }
      final router = GoRouter.maybeOf(context);
      if (router != null && router.canPop()) {
        router.pop();
      }
    } catch (_) {
      // ignore — empty stack must not crash
    }
  }

  Future<void> _goPreliminaryEval() async {
    if (!mounted || !context.mounted) return;
    try {
      final router = GoRouter.maybeOf(context);
      if (router != null) {
        context.go(RouteNames.preliminaryEval);
        return;
      }
      if (!context.mounted) return;
      await Navigator.of(context)
          .pushReplacementNamed(RouteNames.preliminaryEval);
    } catch (e) {
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('등급 배정 화면 이동 실패: $e')),
      );
    }
  }

  Future<void> _onSkip(String? uid) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (uid != null) {
        await ref.read(userRepositoryProvider).skipDeviceOnboarding(uid: uid);
      }
      if (!mounted || !context.mounted) return;
      await _goPreliminaryEval();
    } catch (e) {
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('건너뛰기 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _connectNativeHealth({
    required WatchType watchType,
    required String? uid,
  }) async {
    if (_busy) return;
    if (uid == null) {
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final health = Health();
      await health.configure();
      const types = <HealthDataType>[
        HealthDataType.HEART_RATE,
        HealthDataType.STEPS,
      ];
      final permissions = List<HealthDataAccess>.filled(
        types.length,
        HealthDataAccess.READ,
      );
      final granted = await health.requestAuthorization(
        types,
        permissions: permissions,
      );
      if (!granted) {
        if (!mounted || !context.mounted) return;
        await _showIncompatibleWatchDialog();
        return;
      }

      await ref.read(userRepositoryProvider).updateWatchType(
            uid: uid,
            watchType: watchType,
          );
      await ref.read(userRepositoryProvider).completeNativeDeviceOnboarding(
            uid: uid,
          );

      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${watchType.displayLabel} 연동이 완료되었습니다!'),
          backgroundColor: AppColors.primaryMint,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      await _goPreliminaryEval();
    } on PlatformException catch (_) {
      if (!mounted || !context.mounted) return;
      await _showIncompatibleWatchDialog();
    } catch (_) {
      if (!mounted || !context.mounted) return;
      await _showIncompatibleWatchDialog();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// iOS는 Apple 건강, 그 외는 Health Connect로 연결 (브랜드 가이드 CTA).
  Future<void> _connectFromGuide(String? uid) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _connectNativeHealth(watchType: WatchType.appleWatch, uid: uid);
    }
    return _connectGoogleHealthConnect(uid: uid);
  }

  Future<void> _connectGoogleHealthConnect({required String? uid}) async {
    if (_busy) return;
    if (uid == null) {
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final service = ref.read(healthDataServiceProvider);
      final result = await service.requestWatchLinkAuthorization();
      if (!mounted || !context.mounted) return;

      if (!result.granted) {
        final message = result.openedInstall
            ? 'Health Connect 설치 화면을 열었어요. 설치 후 다시 연결해 주세요.'
            : result.installLaunchFailed
                ? 'Health Connect를 열 수 없어요. Play 스토어에서 설치해 주세요.'
                : '권한이 거부되었습니다.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        return;
      }

      await ref.read(userRepositoryProvider).updateWatchType(
            uid: uid,
            watchType: WatchType.galaxyWatch,
          );
      await ref.read(userRepositoryProvider).completeNativeDeviceOnboarding(
            uid: uid,
          );

      final samples = await service.readRecentSampleCounts();
      if (!mounted || !context.mounted) return;
      if (samples != null && samples.isEmpty) {
        await _showNoSamplesTipDialog();
        if (!mounted || !context.mounted) return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Google Health Connect 연동이 완료되었습니다!'),
          backgroundColor: AppColors.primaryMint,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      await _goPreliminaryEval();
    } catch (e) {
      debugPrint('Google Health Connect error: $e');
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('기기가 호환되지 않거나 연동 중 오류가 발생했습니다.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showNoSamplesTipDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('Health Connect'),
          content: const Text(AppStrings.healthConnectNoSamplesTip),
          actions: [
            TextButton(
              key: const Key('health-connect-tip-ok'),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showComingSoonDialog() async {
    if (!mounted || !context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('준비 중'),
          content: const Text(
            '준비 중입니다. 빠른 시일 내에 연동 서비스를 제공하겠습니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showIncompatibleWatchDialog() async {
    if (!mounted || !context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('연동 불가'),
          content: const Text(
            '고객님의 스마트워치 OS 버전이 낮거나 호환되지 않아 연동할 수 없습니다. '
            '워치를 최신 버전(watchOS 8+, Wear OS 3.0+)으로 업데이트해 주세요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openGarminOAuth(String? uid) async {
    if (!mounted || !context.mounted) return;
    try {
      final router = GoRouter.maybeOf(context);
      if (router != null) {
        await context.push(RouteNames.garminAuth);
      } else {
        await Navigator.of(context).pushNamed(RouteNames.garminAuth);
      }
      // X로 닫으면 여기로 복귀만 함 — 헬스 동의/_updateWatch 호출 금지
    } catch (_) {
      if (!mounted || !context.mounted) return;
      try {
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const GarminAuthScreen(),
          ),
        );
      } catch (e) {
        if (!mounted || !context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Garmin 연동 화면을 열 수 없습니다: $e')),
        );
      }
    }
  }

  Future<void> _showPermissionRequiredDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('권한 설정 필요'),
          content: const Text('정확한 측정을 위해 권한 설정이 필요합니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('닫기'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                openAppSettings();
              },
              child: const Text(
                '설정 열기',
                style: TextStyle(
                  color: AppColors.primaryMintDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateWatch({
    required String? uid,
    required WatchType watchType,
  }) async {
    if (uid == null || !mounted || !context.mounted) return;

    final hasHealthConsent =
        ref.read(activeUserProfileProvider).value?.healthDataConsent ?? false;

    if (watchType != WatchType.none && !hasHealthConsent) {
      final consented = await _openHealthConsent();
      if (consented != true || !mounted || !context.mounted) return;
    }

    if (watchType.isOsDirectTrack) {
      try {
        final permissionResult = await ref
            .read(watchRuntimePermissionsServiceProvider)
            .requestForWatchLinking();
        if (!mounted || !context.mounted) return;
        if (!permissionResult.granted) {
          await _showIncompatibleWatchDialog();
          return;
        }
      } on PlatformException catch (_) {
        if (!mounted || !context.mounted) return;
        await _showIncompatibleWatchDialog();
        return;
      } catch (_) {
        if (!mounted || !context.mounted) return;
        await _showIncompatibleWatchDialog();
        return;
      }
    }

    try {
      await ref.read(userRepositoryProvider).updateWatchType(
            uid: uid,
            watchType: watchType,
          );
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${watchType.displayLabel} 연동 설정이 저장되었습니다.')),
      );
    } catch (error) {
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiErrorMessage.from(error))),
      );
    }
  }

  /// MaterialApp / GoRouter 모두에서 안전하게 동의 화면 오픈.
  Future<bool?> _openHealthConsent() async {
    try {
      final router = GoRouter.maybeOf(context);
      if (router != null) {
        return context.push<bool>(RouteNames.healthDataConsent);
      }
      return Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => const HealthDataConsentScreen(),
        ),
      );
    } catch (_) {
      return null;
    }
  }
}

class _NativeHealthConnectTile extends StatelessWidget {
  const _NativeHealthConnectTile({
    required this.label,
    required this.caption,
    required this.leading,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final String caption;
  final Widget leading;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.buttonText.copyWith(
                        color: enabled
                            ? AppColors.textBlack
                            : AppColors.textGreyLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      caption,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textGreyLight,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: enabled ? AppColors.primaryMint : AppColors.borderGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.watchType});

  final WatchType watchType;

  @override
  Widget build(BuildContext context) {
    final connected = watchType != WatchType.none;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppShapes.cardBorderRadius,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.agreementBoxFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              connected ? Icons.watch_rounded : Icons.watch_off_outlined,
              color: AppColors.primaryMint,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.deviceConnectionStatusTitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  connected
                      ? watchType.displayLabel
                      : AppStrings.deviceConnectionNone,
                  style: AppTextStyles.buttonText.copyWith(
                    color: AppColors.textBlack,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExternalDeviceTile extends StatelessWidget {
  const _ExternalDeviceTile({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onConnect,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppShapes.cardBorderRadius,
        border: Border.all(
          color: selected ? AppColors.primaryMint : AppColors.borderLight,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Icon(
          selected ? Icons.check_circle_rounded : Icons.watch_rounded,
          color: selected ? AppColors.primaryMint : AppColors.textGrey,
        ),
        title: Text(
          label,
          style: AppTextStyles.buttonText.copyWith(
            color: AppColors.textBlack,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: SizedBox(
          height: 36,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryMint,
              foregroundColor: AppColors.nightOnLime,
              disabledBackgroundColor: AppColors.buttonDisabled,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: enabled ? onConnect : null,
            child: const Text(
              AppStrings.deviceConnectionConnect,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

class _BleHeartRateSection extends ConsumerWidget {
  const _BleHeartRateSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(bleHeartRateServiceProvider);
    final snapAsync = ref.watch(bleHeartRateSnapshotProvider);
    final snap = snapAsync.asData?.value ?? service.snapshot;

    return Container(
      key: const Key('ble-hr-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppShapes.cardBorderRadius,
        border: Border.all(
          color: snap.isConnected ? AppColors.primaryMint : AppColors.borderLight,
          width: snap.isConnected ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bluetooth_searching_rounded,
                color: AppColors.primaryMint,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.bleHrSectionTitle,
                  style: AppTextStyles.buttonText.copyWith(
                    color: AppColors.textBlack,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                key: const Key('ble-hr-live-bpm'),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: snap.isConnected
                      ? AppColors.primaryMint
                      : AppColors.agreementBoxFill,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  snap.lastBpm != null
                      ? '♥ ${snap.lastBpm} BPM'
                      : (snap.isConnected ? '♥ 연결됨' : '미연결'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: snap.isConnected
                        ? AppColors.nightOnLime
                        : AppColors.textGrey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.bleHrSectionSubtitle,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textGrey,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.bleHrBroadcastGuideGarmin,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textGreyLight,
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            AppStrings.bleHrBroadcastGuideXiaomiAmazfit,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textGreyLight,
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            AppStrings.bleHrBroadcastGuideStrap,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textGreyLight,
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
          if (snap.deviceName != null && snap.isConnected) ...[
            const SizedBox(height: 10),
            Text(
              '연결된 센서: ${snap.deviceName}',
              key: const Key('ble-hr-connected-device'),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textBlack,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (snap.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              snap.errorMessage!,
              key: const Key('ble-hr-error'),
              style: AppTextStyles.caption.copyWith(
                color: Colors.redAccent,
              ),
            ),
          ],
          if (snap.discoveredDevices.isNotEmpty && !snap.isConnected) ...[
            const SizedBox(height: 10),
            for (final device in snap.discoveredDevices)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.favorite_rounded,
                      size: 16,
                      color: AppColors.primaryMint,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${device.name} (${device.rssi} dBm)',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textBlack,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 30,
                      child: FilledButton(
                        key: Key('ble-hr-connect-${device.id}'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryMint,
                          foregroundColor: AppColors.nightOnLime,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: () => service.connect(device),
                        child: const Text(
                          AppStrings.bleHrConnectButton,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (!snap.isConnected)
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('ble-hr-scan-button'),
                    onPressed: snap.isScanning
                        ? () => service.stopScan()
                        : () => service.startScan(),
                    icon: Icon(
                      snap.isScanning
                          ? Icons.stop_circle_outlined
                          : Icons.bluetooth_searching_rounded,
                      size: 18,
                    ),
                    label: Text(
                      snap.isScanning
                          ? AppStrings.bleHrStopScanButton
                          : AppStrings.bleHrScanButton,
                    ),
                  ),
                ),
              if (snap.isConnected)
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('ble-hr-disconnect-button'),
                    onPressed: () => service.disconnect(),
                    icon: const Icon(Icons.bluetooth_disabled_rounded, size: 18),
                    label: const Text(AppStrings.bleHrDisconnectButton),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
