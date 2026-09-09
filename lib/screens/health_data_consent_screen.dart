import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers/app_providers.dart';
import '../app/theme/app_colors.dart';
import '../features/legal/widgets/health_data_consent_card.dart';

/// Dedicated health-data opt-in screen (PIPA defense — separate from ToS).
class HealthDataConsentScreen extends ConsumerStatefulWidget {
  const HealthDataConsentScreen({
    this.onConsented,
    super.key,
  });

  final VoidCallback? onConsented;

  @override
  ConsumerState<HealthDataConsentScreen> createState() =>
      _HealthDataConsentScreenState();
}

class _HealthDataConsentScreenState extends ConsumerState<HealthDataConsentScreen> {
  var _consented = false;
  var _submitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('건강정보 동의')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '스마트워치 연동 전 동의',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            '개인정보보호법에 따라 건강·생체 데이터는 일반 약관과 분리된 '
            '명시적 Opt-in이 필요합니다.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 20),
          HealthDataConsentCard(
            value: _consented,
            onChanged: (value) => setState(() => _consented = value),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _consented && !_submitting ? _requestHealthPermissions : null,
            child: Text(_submitting ? '권한 요청 중...' : '동의하고 워치 연동 계속'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
            child: const Text('나중에 하기'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestHealthPermissions() async {
    setState(() => _submitting = true);
    try {
      await ref.read(healthDataServiceProvider).requestWatchLinkAuthorization();
      if (!mounted) {
        return;
      }
      widget.onConsented?.call();
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}
