import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app.dart';
import '../app/providers/app_providers.dart';
import '../app/router/route_names.dart';
import '../app/theme/app_colors.dart';
import '../core/api/api_exception.dart';
import '../core/auth/firebase_auth_messages.dart';
import '../core/auth/health_data_consent_store.dart';
import '../core/config/app_env.dart';
import '../data/models/activity_model.dart';
import '../data/models/user_model.dart';
import '../core/constants/legal_constants.dart';
import '../features/my_page/widgets/pace_calculator_card.dart';
import '../features/my_page/widgets/shoe_mileage_tracker.dart';
import '../features/reward/view/winner_honor_popup.dart';

class MyPageScreen extends ConsumerStatefulWidget {
  const MyPageScreen({super.key});

  @override
  ConsumerState<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends ConsumerState<MyPageScreen> {
  final _healthDataConsentStore = HealthDataConsentStore();
  var _isHealthDataAgreed = false;

  @override
  void initState() {
    super.initState();
    _loadHealthDataAgreed();
  }

  Future<void> _loadHealthDataAgreed() async {
    final agreed = await _healthDataConsentStore.readAgreed();
    if (!mounted) {
      return;
    }
    setState(() => _isHealthDataAgreed = agreed);
  }

  Future<void> _onHealthDataConsentEnabled(bool value) async {
    if (_isHealthDataAgreed || !value) {
      return;
    }

    setState(() => _isHealthDataAgreed = true);
    await _healthDataConsentStore.writeAgreed(true);

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          '✅ 민감정보 수집 동의가 완료되었습니다. 이제 러닝을 시작할 수 있습니다!',
        ),
        backgroundColor: AppColors.cardBlack,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _showHealthDataTerms() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceBlack,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    LegalConstants.healthDataConsentTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardBlack,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.electricBlue.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Text(
                      '이용약관과 별도 · 선택 동의',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LegalConstants.healthDataConsentSummary,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              height: 1.55,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            LegalConstants.ephemeralSensorPolicy,
                            style: TextStyle(
                              color: AppColors.electricBlue.withValues(alpha: 0.9),
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.neonLime,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activities = ref.watch(recentActivitiesProvider).value ?? const [];
    final profile = ref.watch(activeUserProfileProvider).value;
    final authUser = ref.watch(authStateChangesProvider).value;
    final watchType = profile?.watchType ?? WatchType.none;
    final healthConsent = _isHealthDataAgreed;
    final pushEnabled = profile?.pushNotificationsEnabled ?? false;
    final verifiedRuns = activities
        .where((activity) =>
            activity.validationStatus == ActivityValidationStatus.verified)
        .toList();
    final totalDistance = verifiedRuns.fold<double>(
      0,
      (sum, activity) => sum + activity.distanceKm,
    );
    final calendarDays = _last30Days();
    final verifiedRunDays = _verifiedRunDays(verifiedRuns);
    final crownDay = _crownDay(verifiedRuns);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('마이페이지', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 18),
        _SectionCard(
          title: '러닝 캘린더',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: calendarDays.map((day) {
              final hasRun = verifiedRunDays.contains(day);
              final showCrown =
                  crownDay != null && _isSameDay(day, crownDay);
              return Icon(
                showCrown
                    ? Icons.workspace_premium_rounded
                    : Icons.circle,
                color: hasRun ? AppColors.neonLime : Colors.white12,
                size: 18,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          child: ShoeMileageTracker(totalDistanceKm: totalDistance),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          child: const PaceCalculatorCard(),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: '스마트워치 연동',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                watchType == WatchType.none
                    ? '연동된 워치 없음'
                    : '${watchType.displayLabel} · '
                        '${watchType.isApiTrack ? 'API Track' : 'OS Direct Track'}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => context.push(RouteNames.watchSettings),
                icon: const Icon(Icons.watch_rounded),
                label: const Text('투트랙 연동 설정 열기'),
              ),
            ],
          ),
        ),
        if (AppEnv.useLocalMockData) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _previewWinnerPopup,
            icon: const Icon(Icons.celebration_rounded),
            label: const Text('우승자 명예 팝업 미리보기 (Mock)'),
          ),
        ],
        const SizedBox(height: 12),
        _HealthDataConsentSection(
          isAgreed: healthConsent,
          onConsentEnabled: _onHealthDataConsentEnabled,
          onViewTerms: _showHealthDataTerms,
        ),
        SwitchListTile(
          value: pushEnabled,
          onChanged: authUser == null
              ? null
              : (value) => _updatePushNotifications(
                    uid: authUser.uid,
                    enabled: value,
                  ),
          title: const Text('푸시 알림'),
          subtitle: const Text('대회, 보상, 기부 알림'),
        ),
        if (authUser != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _signOut(),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('로그아웃'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.dangerRed,
              side: const BorderSide(color: AppColors.dangerRed),
            ),
            onPressed: () => _deleteAccount(),
            icon: const Icon(Icons.delete_forever_rounded),
            label: const Text('계정 삭제'),
          ),
        ],
      ],
    );
  }

  Future<void> _previewWinnerPopup() async {
    await WinnerHonorPopup.show(
      context: context,
      rewardValueToken: 800,
      onDonateHalf: () => _showSnack('Mock: 50% 기부 선택'),
      onDonateAll: () => _showSnack('Mock: 100% 기부 선택'),
      onClaimAll: () => _showSnack('Mock: 전액 수령 선택'),
    );
  }

  Future<void> _updateHealthConsent({
    required String uid,
    required bool consent,
  }) async {
    try {
      await ref.read(userRepositoryProvider).updateHealthDataConsent(
            uid: uid,
            consent: consent,
          );
    } catch (error) {
      _showSnack(ApiErrorMessage.from(error));
    }
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

  List<DateTime> _last30Days() {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    return List.generate(
      30,
      (index) => start.subtract(Duration(days: 29 - index)),
    );
  }

  Set<DateTime> _verifiedRunDays(List<ActivityModel> verifiedRuns) {
    return verifiedRuns
        .where((activity) => activity.completedAt != null)
        .map(
          (activity) => DateTime(
            activity.completedAt!.year,
            activity.completedAt!.month,
            activity.completedAt!.day,
          ),
        )
        .toSet();
  }

  DateTime? _crownDay(List<ActivityModel> verifiedRuns) {
    final dated = verifiedRuns
        .where((activity) => activity.completedAt != null)
        .toList()
      ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
    if (dated.isEmpty) {
      return null;
    }
    final completedAt = dated.first.completedAt!;
    return DateTime(completedAt.year, completedAt.month, completedAt.day);
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  Future<void> _signOut() async {
    final joined = ref.read(joinedTournamentIdsProvider).value ?? const {};
    if (joined.isNotEmpty) {
      await ref.read(pushNotificationServiceProvider).clearTournamentTopics(joined);
    }
    await ref.read(localAuthStoreProvider).clear();
    ref.read(persistedAuthSessionProvider.notifier).replace(null);
    if (!mounted) {
      return;
    }
    navigateToLoginScreen();
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('계정 삭제'),
          content: const Text(
            '계정과 Wallet 잔액이 서버에서 삭제·익명화됩니다. '
            '이 작업은 되돌릴 수 없습니다. 계속하시겠습니까?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.dangerRed,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref.read(securedActionApiClientProvider).deleteAccount();
      final joined = ref.read(joinedTournamentIdsProvider).value ?? const {};
      if (joined.isNotEmpty) {
        await ref
            .read(pushNotificationServiceProvider)
            .clearTournamentTopics(joined);
      }
      await ref.read(localAuthStoreProvider).clear();
      ref.read(persistedAuthSessionProvider.notifier).replace(null);
      if (!mounted) {
        return;
      }
      _showSnack('계정이 삭제되었습니다.');
      navigateToLoginScreen();
    } catch (error) {
      _showSnack(FirebaseAuthMessages.from(error));
    }
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _HealthDataConsentSection extends StatelessWidget {
  const _HealthDataConsentSection({
    required this.isAgreed,
    required this.onConsentEnabled,
    required this.onViewTerms,
  });

  final bool isAgreed;
  final ValueChanged<bool> onConsentEnabled;
  final VoidCallback onViewTerms;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isAgreed
              ? AppColors.neonLime.withValues(alpha: 0.55)
              : AppColors.electricBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.monitor_heart_outlined,
                color: isAgreed ? AppColors.neonLime : AppColors.electricBlue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  LegalConstants.healthDataConsentTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            LegalConstants.healthDataConsentSummary,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.45,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          if (isAgreed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceBlack,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.neonLime.withValues(alpha: 0.45),
                ),
              ),
              child: const Text(
                '✅ 건강 데이터 연동 및 동의 완료',
                style: TextStyle(
                  color: AppColors.neonLime,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceBlack,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.electricBlue.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      LegalConstants.healthDataConsentLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Switch.adaptive(
                    value: false,
                    onChanged: onConsentEnabled,
                    activeThumbColor: AppColors.neonLime,
                    activeTrackColor: AppColors.neonLime.withValues(alpha: 0.35),
                    inactiveThumbColor: AppColors.textSecondary,
                    inactiveTrackColor: AppColors.cardBlack,
                  ),
                ],
              ),
            ),
          if (!isAgreed) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onViewTerms,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.electricBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text(
                  '[약관 전문 보기]',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.electricBlue,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    this.title,
    required this.child,
  });

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}
