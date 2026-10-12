import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../core/navigation/dashboard_tab_navigation.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme.dart';
import '../../onboarding/src_onboarding_controller.dart';
import '../../onboarding/widgets/nickname_change_sheet.dart';
import '../../onboarding/widgets/nickname_setup_sheet.dart';
import '../avatar_choice.dart';
import '../avatar_choice_provider.dart';
import '../user_profile_notifier.dart';
import 'angel_tier_widgets.dart';

abstract final class GenderAvatarAssets {
  static const male = 'assets/images/characters/avatar_gender_male.png';
  static const female = 'assets/images/characters/avatar_gender_female.png';

  static String pathFor(String gender) => gender == 'female' ? female : male;
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
    final avatar = ref.watch(avatarChoiceProvider);
    final tokens = context.srcTokens;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('home-header-avatar'),
        onTap: () => showGenderCustomizeSheet(context, ref),
        customBorder: const CircleBorder(),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: tokens.colors.primary.withValues(alpha: 0.16),
            border: Border.all(
              color: tokens.colors.accent.withValues(alpha: 0.45),
              width: 1.5,
            ),
            boxShadow: AppShadows.rest,
          ),
          child: ClipOval(
            child: _AvatarImage(
              choice: avatar,
              genderFallback: gender,
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
    final tokens = context.srcTokens;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(tokens.radii.xs),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spacing.xxs,
          vertical: tokens.spacing.xxs / 2,
        ),
        child: Text(
          '[${tier.koreanName}]',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: tokens.colors.accent,
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
    final tier =
        ref.watch(activeUserTierStructProvider) ?? UserTier.unratedFallback;
    final angel = ref.watch(userAngelTierProvider);
    final displayName = SrcOnboardingController.isUnsetNickname(nickname)
        ? '닉네임을 설정해 주세요'
        : nickname;
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GenderProfileAvatar(size: 72),
        SizedBox(height: tokens.spacing.sm),
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
            borderRadius: BorderRadius.circular(tokens.radii.xs),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spacing.xxs / 2,
                vertical: tokens.spacing.xxs / 2,
              ),
              child: Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: angel.emphasizeNickname
                      ? FontWeight.w800
                      : FontWeight.w700,
                  color: angel.goldNickname
                      ? tokens.colors.donation
                      : tokens.colors.ink,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: tokens.spacing.xxs),
        Wrap(
          spacing: tokens.spacing.xs,
          runSpacing: tokens.spacing.xxs,
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
    isScrollControlled: true,
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
    final avatar = ref.watch(avatarChoiceProvider);
    final selected = avatar.isPhoto ? AvatarChoice.photoId : avatar.presetId;

    return SafeArea(
      child: SingleChildScrollView(
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
              AppStrings.avatarCustomizeTitle,
              style: AppTextStyles.header1.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.avatarCustomizeHint,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: AvatarPresets.all.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.78,
              ),
              itemBuilder: (context, index) {
                final preset = AvatarPresets.all[index];
                return _PresetChoiceCard(
                  preset: preset,
                  selected: selected == preset.id,
                  onTap: () async {
                    await ref
                        .read(avatarChoiceProvider.notifier)
                        .selectPreset(preset.id);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('avatar-pick-gallery'),
                onPressed: () async {
                  final ok = await ref
                      .read(avatarChoiceProvider.notifier)
                      .pickGalleryPhoto();
                  if (!context.mounted) return;
                  if (ok) {
                    Navigator.of(context).pop();
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(AppStrings.avatarGalleryFailed),
                    ),
                  );
                },
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(
                  avatar.isPhoto
                      ? '${AppStrings.avatarPickGallery} ✓'
                      : AppStrings.avatarPickGallery,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({
    required this.choice,
    required this.genderFallback,
  });

  final AvatarChoice choice;
  final String genderFallback;

  @override
  Widget build(BuildContext context) {
    final bytes = choice.photoBytes;
    if (choice.isPhoto && bytes != null) {
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _assetOrBust(
          GenderAvatarAssets.pathFor(genderFallback),
          genderFallback,
        ),
      );
    }
    final preset = AvatarPresets.byId(choice.presetId);
    return _assetOrBust(preset.asset, genderFallback);
  }

  Widget _assetOrBust(String asset, String gender) {
    return Image.asset(
      asset,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => CustomPaint(
        painter: _GenderBustPainter(isFemale: gender == 'female'),
      ),
    );
  }
}

class _PresetChoiceCard extends StatelessWidget {
  const _PresetChoiceCard({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final AvatarPreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.tealAccent.withValues(alpha: 0.10)
          : AppColors.agreementBoxFill,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: Key('avatar-preset-${preset.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? AppColors.tealAccent
                          : AppColors.borderLight,
                      width: selected ? 2.5 : 1,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      preset.asset,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => CustomPaint(
                        painter: _GenderBustPainter(
                          isFemale: preset.id == AvatarChoice.femaleId,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                preset.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.agreementLabel.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
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
