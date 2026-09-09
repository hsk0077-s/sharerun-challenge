import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../core/constants/economy_constants.dart';
import '../../../core/navigation/app_route_nav.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shapes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../screens/in_app_billing_screen.dart';
import '../../profile/user_profile_notifier.dart';
import '../../wallet/providers/wallet_provider.dart';
import '../src_onboarding_controller.dart';

/// 프리미엄 닉네임 편집 — 100 DIA 차감 / 부족 시 충전소 이송.
class NicknameChangeSheet extends ConsumerStatefulWidget {
  const NicknameChangeSheet({super.key});

  static Future<void> show(BuildContext context) async {
    final goBilling = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => const NicknameChangeSheet(),
    );
    if (goBilling == true && context.mounted) {
      _openInAppBilling(context);
    }
  }

  static void _openInAppBilling(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      try {
        context.pushNamed(RouteNames.inAppBilling);
        return;
      } catch (_) {
        context.push(RouteNames.inAppBilling);
        return;
      }
    }
    AppRouteNav.push<void>(
      context,
      RouteNames.inAppBilling,
      materialBuilder: (_) => const InAppBillingScreen(),
    );
  }

  @override
  ConsumerState<NicknameChangeSheet> createState() =>
      _NicknameChangeSheetState();
}

class _NicknameChangeSheetState extends ConsumerState<NicknameChangeSheet> {
  final _controller = TextEditingController();
  String? _liveError;
  var _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final current = ref.read(userNicknameProvider);
      if (current.isNotEmpty &&
          !SrcOnboardingController.isUnsetNickname(current)) {
        _controller.text = current;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() => _liveError = NicknameValidator.validate(value));
  }

  Future<void> _submitChange() async {
    final error = NicknameValidator.validate(_controller.text);
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
          .changeUserNickname(_controller.text);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      Navigator.of(context).pop(false);
      messenger?.showSnackBar(
        const SnackBar(
          content: Text(
            '닉네임이 변경되었습니다. '
            '(${EconomyConstants.nicknameChangeFeeDia} DIA 차감)',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on InsufficientDiaException {
      if (!mounted) return;
      Navigator.of(context).pop(true);
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
    final maxHeight = MediaQuery.sizeOf(context).height * 0.58;
    final walletDia = ref.watch(walletProvider).diamondBalance;
    final profileDia = ref.watch(userProfileProvider).wallet.diamondBalance;
    final diaBalance = walletDia >= profileDia ? walletDia : profileDia;
    final fee = EconomyConstants.nicknameChangeFeeDia;
    final hasEnoughDia = diaBalance >= fee;
    final compactLen =
        _controller.text.trim().replaceAll(RegExp(r'\s+'), '').length;
    final nicknameReady =
        !_submitting && _liveError == null && compactLen >= 2;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.glassFill,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(color: AppColors.glassRim, width: 0.5),
                ),
                child: Padding(
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
                            color: AppColors.borderGrey,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        '새로운 질주를 위한 이름을 새기시겠습니까?',
                        style: AppTextStyles.header1.copyWith(fontSize: 20),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '러너님의 정체성을 정밀 등록합니다.',
                        style: AppTextStyles.subtitle1.copyWith(
                          fontSize: 13,
                          color: AppColors.textGrey,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.settingsBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.diamond_outlined,
                              size: 18,
                              color: AppColors.tealAccent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '보유 $diaBalance DIA  ·  변경 수수료 $fee DIA',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textBlack,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
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
                          fillColor: AppColors.surfaceWhite.withValues(
                            alpha: 0.72,
                          ),
                          errorText: _liveError,
                          errorStyle: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppShapes.inputRadius),
                            borderSide: const BorderSide(
                              color: AppColors.borderLight,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppShapes.inputRadius),
                            borderSide: const BorderSide(
                              color: AppColors.tealAccent,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppShapes.inputRadius),
                            borderSide: const BorderSide(
                              color: AppColors.error,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppShapes.inputRadius),
                            borderSide: const BorderSide(
                              color: AppColors.error,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      if (_liveError != null) const SizedBox(height: 4),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: AppShapes.buttonHeight,
                        child: FilledButton(
                          onPressed: _submitting
                              ? null
                              : (hasEnoughDia
                                  ? (nicknameReady ? _submitChange : null)
                                  : () => Navigator.of(context).pop(true)),
                          style: FilledButton.styleFrom(
                            backgroundColor: hasEnoughDia
                                ? AppColors.tealAccent
                                : AppColors.tossBlue,
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
                                  hasEnoughDia
                                      ? '100 DIA 소모하여 변경하기'
                                      : '다이아몬드 부족 - 충전소로 이동하기',
                                  style: AppTextStyles.buttonText.copyWith(
                                    color: AppColors.textWhite,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
