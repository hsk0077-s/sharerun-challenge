import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers/app_providers.dart';
import '../app/theme/app_colors.dart';
import '../core/constants/legal_constants.dart';
import '../features/legal/widgets/health_data_consent_card.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  var _termsAccepted = false;
  var _privacyAccepted = false;
  var _pushEnabled = false;
  var _healthDataConsent = false;
  var _submitting = false;

  bool get _canContinue => _termsAccepted && _privacyAccepted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Welcome to SRC',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              '서비스 이용 전 필수 약관에 동의해 주세요.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            _LegalCard(
              title: LegalConstants.termsOfServiceTitle,
              body: LegalConstants.termsOfServiceSummary,
              value: _termsAccepted,
              onChanged: (value) => setState(() => _termsAccepted = value),
            ),
            const SizedBox(height: 12),
            _LegalCard(
              title: LegalConstants.privacyPolicyTitle,
              body: LegalConstants.privacyPolicySummary,
              value: _privacyAccepted,
              onChanged: (value) => setState(() => _privacyAccepted = value),
            ),
            const SizedBox(height: 12),
            _LegalCard(
              title: LegalConstants.pushNotificationsTitle,
              body: LegalConstants.pushNotificationsSummary,
              value: _pushEnabled,
              onChanged: (value) => setState(() => _pushEnabled = value),
            ),
            const SizedBox(height: 28),
            const Divider(color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              '아래는 일반 약관과 분리된 선택 동의입니다.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            HealthDataConsentCard(
              value: _healthDataConsent,
              onChanged: (value) => setState(() => _healthDataConsent = value),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canContinue && !_submitting ? _completeOnboarding : null,
                child: Text(_submitting ? '저장 중...' : '동의하고 시작하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    final authUser = ref.read(authStateChangesProvider).value;
    if (authUser == null) {
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(userRepositoryProvider).acceptTerms(
            uid: authUser.uid,
            pushNotificationsEnabled: _pushEnabled,
          );

      if (_healthDataConsent) {
        await ref.read(userRepositoryProvider).updateHealthDataConsent(
              uid: authUser.uid,
              consent: true,
            );
      }

      if (_pushEnabled) {
        await ref.read(pushNotificationServiceProvider).syncTokenForUser(
              uid: authUser.uid,
              userRepository: ref.read(userRepositoryProvider),
              requestPermission: true,
            );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('온보딩 저장 실패: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

class _LegalCard extends StatelessWidget {
  const _LegalCard({
    required this.title,
    required this.body,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String body;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: value,
            onChanged: (checked) => onChanged(checked ?? false),
            title: const Text('동의합니다'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }
}
