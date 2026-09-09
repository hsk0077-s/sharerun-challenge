import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

Future<bool> ensureEmailVerified({
  required BuildContext context,
  required User user,
}) async {
  if (user.isAnonymous) {
    return true;
  }

  await user.reload();
  final refreshed = FirebaseAuth.instance.currentUser ?? user;
  final email = refreshed.email ?? '';
  if (email.isEmpty || refreshed.emailVerified) {
    return true;
  }

  if (!context.mounted) {
    return false;
  }

  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('이메일 인증 필요'),
        content: const Text(
          '결제·대회 참가 전에 이메일 인증을 완료해 주세요. '
          '상단 배너에서 인증 메일을 재발송할 수 있습니다.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      );
    },
  );
  return false;
}
