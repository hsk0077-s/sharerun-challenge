import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shapes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../src_onboarding_controller.dart';

/// 최초 로그인 시 강제 표시되는 닉네임 설정 바텀시트.
class NicknameSetupSheet extends ConsumerStatefulWidget {
  const NicknameSetupSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const NicknameSetupSheet(),
    );
  }

  @override
  ConsumerState<NicknameSetupSheet> createState() => _NicknameSetupSheetState();
}

class _NicknameSetupSheetState extends ConsumerState<NicknameSetupSheet> {
  final _controller = TextEditingController();
  String? _liveError;
  var _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final error =
        ref.read(srcOnboardingControllerProvider.notifier).liveNicknameError(value);
    setState(() => _liveError = error);
  }

  Future<void> _submit() async {
    final error = ref
        .read(srcOnboardingControllerProvider.notifier)
        .liveNicknameError(_controller.text);
    final compact = _controller.text.trim().replaceAll(RegExp(r'\s+'), '');
    if (compact.isEmpty || error != null) {
      setState(() {
        _liveError = error ?? '닉네임은 공백 제외 2~12자여야 합니다.';
      });
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref
          .read(srcOnboardingControllerProvider.notifier)
          .setInitialNickname(_controller.text);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _liveError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final compactLen =
        _controller.text.trim().replaceAll(RegExp(r'\s+'), '').length;
    final canSubmit = !_submitting && _liveError == null && compactLen >= 2;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '닉네임 및 캐릭터 가동',
              style: AppTextStyles.header1.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              '홈에 표시될 닉네임을 정하면, 예선 등급에 맞는 대두 캐릭터가 함께 깨어납니다.',
              style: AppTextStyles.subtitle1.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: _controller,
              maxLength: 12,
              enabled: !_submitting,
              onChanged: _onChanged,
              style: AppTextStyles.inputText,
              decoration: InputDecoration(
                counterText: '$compactLen/12',
                hintText: '한글·영문·숫자 2~12자',
                hintStyle: AppTextStyles.inputHint,
                filled: true,
                fillColor: AppColors.agreementBoxFill,
                errorText: _liveError,
                errorStyle: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppShapes.inputRadius),
                  borderSide: const BorderSide(color: AppColors.primaryMint),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppShapes.inputRadius),
                  borderSide: const BorderSide(
                    color: AppColors.primaryMintDark,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppShapes.inputRadius),
                  borderSide: const BorderSide(color: AppColors.error),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppShapes.inputRadius),
                  borderSide: const BorderSide(color: AppColors.error, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: AppShapes.buttonHeight,
              child: FilledButton(
                onPressed: canSubmit ? _submit : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryMint,
                  disabledBackgroundColor: AppColors.buttonDisabled,
                  foregroundColor: AppColors.textWhite,
                  shape: const StadiumBorder(),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppColors.textWhite,
                        ),
                      )
                    : Text(
                        '설정 완료',
                        style: AppTextStyles.buttonText.copyWith(
                          color: AppColors.textWhite,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
