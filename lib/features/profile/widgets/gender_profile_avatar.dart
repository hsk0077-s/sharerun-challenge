import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../core/navigation/dashboard_tab_navigation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../onboarding/src_onboarding_controller.dart';
import '../../onboarding/widgets/nickname_change_sheet.dart';
import '../../onboarding/widgets/nickname_setup_sheet.dart';
import '../user_profile_notifier.dart';
import 'angel_tier_widgets.dart';

abstract final class GenderAvatarAssets {
  static const male = 'assets/images/characters/avatar_gender_male.png';
  static const female = 'assets/images/characters/avatar_gender_female.png';

  static String pathFor(String gender) =>
      gender == 'female' ? female : male;
}

/// 홈 유저네임 상단 — 성별 상반신 아바타. 탭 시 커스터마이징 시트.
class GenderProfileAvatar extends ConsumerWidget {
  const GenderProfileAvatar({
    super.key,
    this.size = 72,
  });

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gender = ref.watch(userGenderProvider);
    final asset = GenderAvatarAssets.pathFor(gender);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showGenderCustomizeSheet(context, ref),
        customBorder: const CircleBorder(),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.agreementBoxFill,
            border: Border.all(
              color: AppColors.tealAccent.withValues(alpha: 0.45),
              width: 1.5,
            ),
          ),
          child: ClipOval(
            child: Image.asset(
              asset,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => CustomPaint(
                painter: _GenderBustPainter(isFemale: gender == 'female'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 유저네임 옆 텍스트 티어. 탭 시 마이페이지.
class TextTierLabel extends StatelessWidget {
  const TextTierLabel({
    super.key,
    required this.tier,
    required this.onTap,
  });

  final UserTier tier;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          '[${tier.koreanName}]',
          style: AppTextStyles.agreementLabel.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.tealAccent,
          ),
        ),
      ),
    );
  }
}

/// 홈 헤더 공통 — 성별 아바타 / 닉네임 / 텍스트 티어.
class HomeUserIdentityHeader extends ConsumerWidget {
  const HomeUserIdentityHeader({super.key});

  static void openMyPage(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      try {
        context.pushNamed(RouteNames.myPage);
        return;
      } catch (_) {
        DashboardTabNavigation.go(context, DashboardTabNavigation.myPage);
        return;
      }
    }
    DashboardTabNavigation.go(context, DashboardTabNavigation.myPage);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nickname = ref.watch(userNicknameProvider);
    final tier = ref.watch(activeUserTierStructProvider) ??
        UserTier.unratedFallback;
    final angel = ref.watch(userAngelTierProvider);
    final displayName = SrcOnboardingController.isUnsetNickname(nickname)
        ? '닉네임을 설정해 주세요'
        : nickname;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GenderProfileAvatar(size: 72),
        const SizedBox(height: 10),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (SrcOnboardingController.isUnsetNickname(nickname)) {
                NicknameSetupSheet.show(context);
              } else {
                NicknameChangeSheet.show(context);
              }
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.header1.copyWith(
                  fontSize: 18,
                  fontWeight:
                      angel.emphasizeNickname ? FontWeight.w800 : FontWeight.w700,
                  color: angel.goldNickname
                      ? AppColors.angelGold
                      : AppColors.textBlack,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextTierLabel(
              tier: tier,
              onTap: () => openMyPage(context),
            ),
            AngelTierBadge(tier: angel),
          ],
        ),
      ],
    );
  }
}

Future<void> showGenderCustomizeSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return const _GenderCustomizeSheet();
    },
  );
}

class _GenderCustomizeSheet extends ConsumerWidget {
  const _GenderCustomizeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(userGenderProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '성별 커스터마이징',
              style: AppTextStyles.header1.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              '아바타를 선택하면 즉시 저장됩니다',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _GenderChoiceCard(
                    label: '남성 아바타',
                    asset: GenderAvatarAssets.male,
                    isFemale: false,
                    selected: selected == 'male',
                    onTap: () async {
                      await ref
                          .read(userProfileNotifierProvider.notifier)
                          .updateGender('male');
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GenderChoiceCard(
                    label: '여성 아바타',
                    asset: GenderAvatarAssets.female,
                    isFemale: true,
                    selected: selected == 'female',
                    onTap: () async {
                      await ref
                          .read(userProfileNotifierProvider.notifier)
                          .updateGender('female');
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GenderChoiceCard extends StatelessWidget {
  const _GenderChoiceCard({
    required this.label,
    required this.asset,
    required this.isFemale,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String asset;
  final bool isFemale;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.tealAccent.withValues(alpha: 0.10)
          : AppColors.agreementBoxFill,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          child: Column(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.tealAccent : AppColors.borderLight,
                    width: selected ? 2.5 : 1,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    asset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => CustomPaint(
                      painter: _GenderBustPainter(isFemale: isFemale),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: AppTextStyles.agreementLabel.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: selected ? AppColors.tealAccent : AppColors.textBlack,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenderBustPainter extends CustomPainter {
  const _GenderBustPainter({required this.isFemale});

  final bool isFemale;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final skin = Paint()..color = const Color(0xFFF3D2B3);
    final hair = Paint()
      ..color = isFemale ? const Color(0xFF3E2723) : const Color(0xFF4E342E);
    final shirt = Paint()..color = AppColors.tealAccent;

    canvas.drawCircle(Offset(w / 2, h * 0.38), w * 0.28, skin);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, h * 0.92),
        width: w * 0.72,
        height: h * 0.55,
      ),
      shirt,
    );
    if (isFemale) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w / 2, h * 0.28),
          width: w * 0.72,
          height: h * 0.42,
        ),
        hair,
      );
    } else {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(w / 2, h * 0.38), radius: w * 0.28),
        3.4,
        2.6,
        true,
        hair,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GenderBustPainter oldDelegate) =>
      oldDelegate.isFemale != isFemale;
}
