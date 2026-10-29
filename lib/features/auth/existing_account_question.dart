import 'package:flutter/material.dart';

import '../../core/config/app_env.dart';
import '../../core/strings/app_strings.dart';
import '../../core/theme/app_text_styles.dart';

/// 확인된 이메일로 기존 계정을 못 찾았을 때의 선택.
enum ExistingAccountAnswer { google, kakao, naver, apple, create, cancel }

/// "처음 가입할 때 어떤 방법을 쓰셨나요?"
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
          title: Text(AppStrings.existingAccountTitle),
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
              if (AppEnv.appleLoginEnabled)
                methodButton(
                  current: 'apple',
                  label: AppStrings.existingAccountApple,
                  value: ExistingAccountAnswer.apple,
                  key: const Key('existing-account-apple'),
                ),
              const SizedBox(height: 16),
              Text(
                AppStrings.existingAccountCreateHint,
                style: AppTextStyles.caption,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const Key('existing-account-create'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => choose(ExistingAccountAnswer.create),
                  child: Text(AppStrings.existingAccountCreate),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  return answer ?? ExistingAccountAnswer.cancel;
}

/// 연결 직전. 대상 계정의 닉네임과 SHARE만 보여 주고 확인받는다.
Future<bool> showAccountLinkConfirm(
  BuildContext context, {
  required String methodName,
  required String nickname,
  required int shareBalance,
  String? declineLabel,
}) async {
  final resolvedDeclineLabel = declineLabel ?? AppStrings.linkConfirmNo;
  final answer = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: const Key('link-confirm-dialog'),
      title: Text(AppStrings.linkConfirmTitle(methodName)),
      content: Text(
        AppStrings.linkConfirmBody(
          nickname: nickname,
          shareBalance: shareBalance,
        ),
      ),
      actions: [
        TextButton(
          key: const Key('link-confirm-no'),
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(resolvedDeclineLabel),
        ),
        FilledButton(
          key: const Key('link-confirm-yes'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(AppStrings.linkConfirmYes),
        ),
      ],
    ),
  );
  return answer == true;
}
