import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app/providers/app_providers.dart';
import '../../app/router/route_names.dart';
import '../../app/theme/app_colors.dart';
import '../../core/api/api_exception.dart';
import '../../data/models/user_model.dart';
import '../../features/legal/widgets/health_data_consent_card.dart';

// TODO(delete?): UI가 DeviceConnectionScreen으로 통합되었습니다.
// 라우트 전환 검증 후 이 파일 삭제 가능 여부를 확인해 주세요.
class WatchSettingsScreen extends ConsumerStatefulWidget {
  const WatchSettingsScreen({super.key});

  @override
  ConsumerState<WatchSettingsScreen> createState() => _WatchSettingsScreenState();
}

class _WatchSettingsScreenState extends ConsumerState<WatchSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(activeUserProfileProvider).value;
    final authUser = ref.watch(authStateChangesProvider).value;
    final watchType = profile?.watchType ?? WatchType.none;
    final hasHealthConsent = profile?.healthDataConsent ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('스마트워치 연동')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '투트랙 연동 방식',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            '브랜드별 연동 경로를 분리해 데이터 신뢰도와 법률 방어를 강화합니다.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          if (!hasHealthConsent) ...[
            const SizedBox(height: 20),
            HealthDataConsentCard(
              value: false,
              enabled: false,
              onChanged: (_) {},
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.push(RouteNames.healthDataConsent),
              icon: const Icon(Icons.monitor_heart_outlined),
              label: const Text('건강정보 동의하고 연동 시작'),
            ),
          ],
          const SizedBox(height: 24),
          _TrackSection(
            title: 'Track A · API 연동',
            subtitle: 'Garmin / Coros / Suunto — 브랜드 클라우드 OAuth',
            accent: AppColors.electricBlue,
            options: const [
              WatchType.garmin,
              WatchType.coros,
              WatchType.suunto,
            ],
            selected: watchType,
            enabled: authUser != null && hasHealthConsent,
            onSelect: (type) => _updateWatch(
              ref: ref,
              uid: authUser?.uid,
              watchType: type,
              context: context,
              hasHealthConsent: hasHealthConsent,
            ),
          ),
          const SizedBox(height: 20),
          _TrackSection(
            title: 'Track B · OS 직접 연동',
            subtitle: 'Apple Watch / Galaxy Watch — HealthKit · Health Connect',
            accent: AppColors.neonLime,
            options: const [
              WatchType.appleWatch,
              WatchType.galaxyWatch,
            ],
            selected: watchType,
            enabled: authUser != null && hasHealthConsent,
            onSelect: (type) => _updateWatch(
              ref: ref,
              uid: authUser?.uid,
              watchType: type,
              context: context,
              hasHealthConsent: hasHealthConsent,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: authUser == null
                ? null
                : () => _updateWatch(
                      ref: ref,
                      uid: authUser.uid,
                      watchType: WatchType.none,
                      context: context,
                      hasHealthConsent: true,
                    ),
            child: const Text('연동 해제'),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBlack,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              watchType == WatchType.none
                  ? '현재 연동된 워치가 없습니다.'
                  : '현재 연동: ${watchType.displayLabel} '
                      '(${watchType.isApiTrack ? 'API Track' : 'OS Direct Track'})',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateWatch({
    required WidgetRef ref,
    required String? uid,
    required WatchType watchType,
    required BuildContext context,
    required bool hasHealthConsent,
  }) async {
    if (uid == null) {
      return;
    }

    if (watchType != WatchType.none && !hasHealthConsent) {
      final consented = await context.push<bool>(RouteNames.healthDataConsent);
      if (consented != true || !context.mounted) {
        return;
      }
    }

    if (watchType.isOsDirectTrack) {
      final permissionResult = await ref
          .read(watchRuntimePermissionsServiceProvider)
          .requestForWatchLinking();
      if (!context.mounted) {
        return;
      }
      if (!permissionResult.granted) {
        final label = permissionResult.missingPermissionLabel ?? '필수';
        if (permissionResult.openedHealthConnectInstall) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Health Connect 설치 후 다시 시도해 주세요.',
              ),
            ),
          );
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label 권한이 필요합니다.'),
            action: SnackBarAction(
              label: '설정',
              onPressed: openAppSettings,
            ),
          ),
        );
        return;
      }
    }

    try {
      await ref.read(userRepositoryProvider).updateWatchType(
            uid: uid,
            watchType: watchType,
          );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${watchType.displayLabel} 연동 설정이 저장되었습니다.')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiErrorMessage.from(error))),
      );
    }
  }
}

class _TrackSection extends StatelessWidget {
  const _TrackSection({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.options,
    required this.selected,
    required this.enabled,
    required this.onSelect,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final List<WatchType> options;
  final WatchType selected;
  final bool enabled;
  final ValueChanged<WatchType> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
          if (!enabled) ...[
            const SizedBox(height: 8),
            const Text(
              '건강정보 동의 후 선택할 수 있습니다.',
              style: TextStyle(color: AppColors.dangerRed, fontSize: 13),
            ),
          ],
          const SizedBox(height: 14),
          ...options.map(
            (type) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: selected == type ? accent : Colors.white12,
                  ),
                ),
                tileColor: selected == type
                    ? accent.withValues(alpha: 0.08)
                    : AppColors.surfaceBlack,
                leading: Icon(
                  selected == type
                      ? Icons.check_circle_rounded
                      : Icons.watch_rounded,
                  color: selected == type ? accent : AppColors.textSecondary,
                ),
                title: Text(type.displayLabel),
                subtitle: Text(
                  type.isApiTrack
                      ? '브랜드 API · OAuth'
                      : 'OS Health 데이터 직접 읽기',
                ),
                onTap: enabled ? () => onSelect(type) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
