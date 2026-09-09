import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

import '../app/providers/app_providers.dart';
import '../app/router/route_names.dart';
import '../core/api/api_exception.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/src_gradient_background.dart';
import '../core/widgets/src_sync_button.dart';
import '../data/models/user_model.dart';
import 'garmin_auth_screen.dart';
import 'health_data_consent_screen.dart';

/// 네이티브 헬스(Apple Health / Google Health Connect) + 외부 기기 연동 화면.
class DeviceConnectionScreen extends ConsumerStatefulWidget {
  const DeviceConnectionScreen({super.key});

  @override
  ConsumerState<DeviceConnectionScreen> createState() =>
      _DeviceConnectionScreenState();
}

class _DeviceConnectionScreenState extends ConsumerState<DeviceConnectionScreen> {
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
                      caption: '(Galaxy Watch, Pixel Watch 등 Wear OS 기기 지원)',
                      leading: const GoogleHealthConnectIcon(),
                      enabled: !_busy && authUser != null,
                      onPressed: () async {
                        try {
                          Health().configure();

                          final types = [
                            HealthDataType.STEPS,
                            HealthDataType.HEART_RATE,
                            HealthDataType.ACTIVE_ENERGY_BURNED,
                          ];
                          // 1단계: 이미 권한이 부여되어 있는지 사전 체크
                          bool? hasPermissions = await Health().hasPermissions(types);
                          if (hasPermissions == true) {
                            // 이미 연동된 경우 팝업 후 5회 등급심사로 진행
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('이미 구글 헬스 커넥트와 연동되어 있습니다.'), backgroundColor: Color(0xFF00CBA9)),
                              );
                            }
                            await _finishWatchAndContinue(
                              uid: authUser?.uid,
                              watchType: WatchType.galaxyWatch,
                            );
                            return;
                          }
                          // 2단계: 권한이 없을 경우에만 권한 창 띄우기
                          final bool isAuthorized = await Health().requestAuthorization(types);
                          if (isAuthorized) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('구글 헬스 커넥트 연동 완료'), backgroundColor: Color(0xFF00CBA9)),
                              );
                            }
                            await _finishWatchAndContinue(
                              uid: authUser?.uid,
                              watchType: WatchType.galaxyWatch,
                            );
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('권한이 거부되었습니다.')),
                              );
                            }
                          }
                        } catch (e) {
                          debugPrint('Health Connect Error: $e');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('기기가 호환되지 않거나 연동 중 오류가 발생했습니다.')),
                            );
                          }
                        }
                      },
                    ),
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
                      onConnect: () => _openGarminOAuth(authUser?.uid),
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
        SnackBar(content: Text('등급심사 화면 이동 실패: $e')),
      );
    }
  }

  /// Persist watch link (when possible) then continue onboarding → 5회 등급심사.
  Future<void> _finishWatchAndContinue({
    required String? uid,
    required WatchType watchType,
  }) async {
    if (uid != null) {
      try {
        await ref.read(userRepositoryProvider).updateWatchType(
              uid: uid,
              watchType: watchType,
            );
        await ref.read(userRepositoryProvider).completeNativeDeviceOnboarding(
              uid: uid,
            );
      } catch (_) {
        // Navigation must continue even if profile write fails offline.
      }
    }
    if (!mounted || !context.mounted) return;
    await _goPreliminaryEval();
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
        HealthDataType.ACTIVE_ENERGY_BURNED,
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

  Future<void> _connectGoogleHealthConnect({required String? uid}) async {
    if (uid == null) {
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    try {
      final health = Health();
      await health.configure();
      const types = <HealthDataType>[
        HealthDataType.HEART_RATE,
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
      ];
      final permissions = List<HealthDataAccess>.filled(
        types.length,
        HealthDataAccess.READ,
      );

      final bool isAuthorized = await health.requestAuthorization(
        types,
        permissions: permissions,
      );

      if (isAuthorized != true) return;

      await ref.read(userRepositoryProvider).updateWatchType(
            uid: uid,
            watchType: WatchType.galaxyWatch,
          );
      await ref.read(userRepositoryProvider).completeNativeDeviceOnboarding(
            uid: uid,
          );

      if (!mounted || !context.mounted) return;
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
    }
  }

  Future<void> _showHealthConnectUnavailableDialog(Health? health) async {
    if (!mounted || !context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('Health Connect'),
          content: const Text(
            'Health Connect 권한을 확인할 수 없거나 앱이 설치되지 않았습니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('닫기'),
            ),
            if (health != null)
              TextButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  try {
                    await health.installHealthConnect();
                  } catch (_) {
                    await openAppSettings();
                  }
                },
                child: const Text(
                  '설치/설정',
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
        ref.read(activeUserProfileProvider).value?.healthDataConsent ??
            false;

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
              foregroundColor: AppColors.textWhite,
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
