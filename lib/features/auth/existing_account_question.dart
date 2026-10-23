import 'package:flutter/material.dart';

import '../../core/strings/app_strings.dart';

/// 확인된 이메일로 기존 계정을 못 찾았을 때의 선택.
enum ExistingAccountAnswer { google, kakao, naver, create, cancel }

/// "예전에 다른 방법으로 가입하셨나요?"
///
/// 계정을 만들기 전에 묻는다. 예전에 쓰던 방법을 고르면 그 로그인 뒤에
/// 방금 고른 방법을 연결하고, 새 계정은 사람이 명시적으로 고른 뒤에만 만든다.
Future<ExistingAccountAnswer> showExistingAccountQuestion(
  BuildContext context, {
  required String provider,
  required String providerName,
}) async {
  final answer = await showDialog<ExistingAccountAnswer>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      void choose(ExistingAccountAnswer value) {
        Navigator.of(dialogContext).pop(value);
      }

      Widget methodButton({
        required String current,
        required String label,
        required ExistingAccountAnswer value,
        required Key key,
      }) {
        if (provider == current) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: FilledButton(
            key: key,
            onPressed: () => choose(value),
            child: Text(label),
          ),
        );
      }

      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          choose(ExistingAccountAnswer.cancel);
        },
        child: AlertDialog(
          key: const Key('existing-account-question'),
          title: const Text(AppStrings.existingAccountTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(AppStrings.existingAccountBody(providerName)),
              const SizedBox(height: 12),
              methodButton(
                current: 'google',
                label: AppStrings.existingAccountGoogle,
                value: ExistingAccountAnswer.google,
                key: const Key('existing-account-google'),
              ),
              methodButton(
                current: 'kakao',
                label: AppStrings.existingAccountKakao,
                value: ExistingAccountAnswer.kakao,
                key: const Key('existing-account-kakao'),
              ),
              methodButton(
                current: 'naver',
                label: AppStrings.existingAccountNaver,
                value: ExistingAccountAnswer.naver,
                key: const Key('existing-account-naver'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                key: const Key('existing-account-create'),
                onPressed: () => choose(ExistingAccountAnswer.create),
                child: const Text(AppStrings.existingAccountCreate),
              ),
              TextButton(
                key: const Key('existing-account-cancel'),
                onPressed: () => choose(ExistingAccountAnswer.cancel),
                child: const Text(AppStrings.existingAccountCancel),
              ),
            ],
          ),
        ),
      );
    },
  );
  return answer ?? ExistingAccountAnswer.cancel;
}
