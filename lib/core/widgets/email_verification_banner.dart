import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import '../../app/theme/app_colors.dart';
import '../../core/config/app_env.dart';

class EmailVerificationBanner extends ConsumerStatefulWidget {
  const EmailVerificationBanner({super.key});

  @override
  ConsumerState<EmailVerificationBanner> createState() =>
      _EmailVerificationBannerState();
}

class _EmailVerificationBannerState extends ConsumerState<EmailVerificationBanner> {
  var _sending = false;

  @override
  Widget build(BuildContext context) {
    if (AppEnv.useLocalMockData) {
      return const SizedBox.shrink();
    }

    final user = ref.watch(authStateChangesProvider).asData?.value;
    if (user == null || user.isAnonymous) {
      return const SizedBox.shrink();
    }

    final hasEmail = (user.email ?? '').isNotEmpty;
    if (!hasEmail || user.emailVerified) {
      return const SizedBox.shrink();
    }

    return Material(
      color: AppColors.cardBlack,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(
          children: [
            const Icon(Icons.mark_email_unread_rounded, color: AppColors.neonLime),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '이메일 인증을 완료해 주세요. 결제·대회 참가 전에 필요할 수 있습니다.',
                style: TextStyle(fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: _sending ? null : _sendVerificationEmail,
              child: Text(_sending ? '발송 중...' : '재발송'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendVerificationEmail() async {
    setState(() => _sending = true);
    try {
      await ref.read(authServiceProvider).sendEmailVerification();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증 메일을 발송했습니다.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('인증 메일 발송 실패: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }
}
