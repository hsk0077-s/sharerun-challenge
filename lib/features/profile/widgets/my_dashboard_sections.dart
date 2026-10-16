import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/router/route_names.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme.dart';
import '../../../data/models/wallet_model.dart';
import '../../../screens/my_wallet_screen.dart';
import '../../home/home_cards.dart';
import '../../home/home_navigation.dart';
import '../../onboarding/src_onboarding_controller.dart';
import '../../onboarding/widgets/nickname_change_sheet.dart';
import '../../onboarding/widgets/nickname_setup_sheet.dart';
import '../../shop/providers/shop_tab_provider.dart';
import '../../wallet/providers/wallet_provider.dart';
import '../user_profile_notifier.dart';
import 'gender_profile_avatar.dart';
import 'retention_widgets.dart';
import 'tier_circle_badge.dart';

/// 마이 탭: 티어 동물 · 나 · 천사 원 세 개. 가운데 내 사진이 가장 크다.
/// 눌렀을 때 가는 곳은 홈에 있을 때와 같다(도감, 프로필 꾸미기, 닉네임).
class MyIdentityRow extends ConsumerWidget {
  const MyIdentityRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    final nickname = ref.watch(userNicknameProvider);
    final tier =
        ref.watch(activeUserTierStructProvider) ?? UserTier.unratedFallback;
    final angel = ref.watch(userAngelTierProvider);
    final unset = SrcOnboardingController.isUnsetNickname(nickname);
    final displayName = unset ? '닉네임을 설정해 주세요' : nickname;

    Widget column({
      required Widget circle,
      required String label,
      String? sub,
      Color? subColor,
      VoidCallback? onLabelTap,
      Color? labelColor,
      Key? key,
    }) {
      return Column(
        key: key,
        mainAxisSize: MainAxisSize.min,
        children: [
          circle,
          const SizedBox(height: 8),
          InkWell(
            onTap: onLabelTap,
            borderRadius: BorderRadius.circular(tokens.radii.xs),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 116),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: textTheme.titleSmall?.copyWith(
                  color: labelColor ?? tokens.colors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 1),
            Text(
              sub,
              style: textTheme.labelSmall?.copyWith(
                color: subColor ?? tokens.colors.muted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          column(
            key: const Key('my-tier-animal'),
            circle: _IdentityCircle(
              asset: tier.avatarAssetPath,
              size: 70,
              ring: tokens.colors.accent,
              onTap: () => HomeUserIdentityHeader.openBook(
                context,
                RouteNames.tierBook,
              ),
            ),
            label: tier.circleLabel,
            sub: tier.circleSubLabel ?? '등급 심사 전',
            subColor: tokens.colors.accent,
            onLabelTap: () => HomeUserIdentityHeader.openBook(
              context,
              RouteNames.tierBook,
            ),
          ),
          const SizedBox(width: 18),
          column(
            key: const Key('my-user-circle'),
            circle: GenderProfileAvatar(size: 112),
            label: displayName,
            sub: '프로필 꾸미기',
            labelColor: angel.goldNickname ? tokens.colors.donation : null,
            onLabelTap: () {
              if (unset) {
                NicknameSetupSheet.show(context);
              } else {
                NicknameChangeSheet.show(context);
              }
            },
          ),
          const SizedBox(width: 18),
          column(
            key: const Key('my-tier-angel'),
            circle: _IdentityCircle(
              asset: angel.avatarAssetPath,
              size: 70,
              ring: tokens.colors.donation,
              onTap: () => HomeUserIdentityHeader.openBook(
                context,
                RouteNames.angelBook,
              ),
            ),
            label: angel.circleLabel,
            sub: '천사 도감',
            subColor: tokens.colors.donation,
            onLabelTap: () => HomeUserIdentityHeader.openBook(
              context,
              RouteNames.angelBook,
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityCircle extends StatelessWidget {
  const _IdentityCircle({
    required this.asset,
    required this.size,
    required this.ring,
    required this.onTap,
  });

  final String asset;
  final double size;
  final Color ring;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: ring, width: 3),
          ),
          clipBehavior: Clip.antiAlias,
          child: Transform.scale(
            scale: 1.25,
            child: Image.asset(asset, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

/// SHARE · DIAMOND · VALUE 잔액 칩 세 개. 누르면 충전·상점·기부로 간다(홈 때와 같음).
class MyWalletChips extends ConsumerWidget {
  const MyWalletChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.srcTokens;
    final wallet = ref.watch(walletProvider);
    Widget chip(
      IconData icon,
      String label,
      int value,
      Color color,
      VoidCallback onTap, {
      Key? key,
    }) {
      return Expanded(
        child: InkWell(
          key: key,
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tokens.colors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: tokens.colors.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 13, color: color),
                    const SizedBox(width: 4),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          label,
                          maxLines: 1,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: tokens.colors.muted,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    groupedNumber(value),
                    maxLines: 1,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: tokens.colors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(
          Icons.directions_walk_rounded,
          'SHARE',
          wallet.shareBalance,
          tokens.colors.accent,
          () => HomeNavigation.openInAppBilling(context),
          key: const Key('my-chip-share'),
        ),
        const SizedBox(width: 8),
        chip(
          Icons.diamond_outlined,
          'DIAMOND',
          wallet.diamondBalance,
          tokens.colors.ink,
          () => HomeNavigation.openStore(context, ref, focus: StoreFocus.items),
          key: const Key('my-chip-diamond'),
        ),
        const SizedBox(width: 8),
        chip(
          Icons.favorite_rounded,
          'VALUE',
          wallet.valueBalance,
          tokens.colors.donation,
          () =>
              HomeNavigation.openStore(context, ref, focus: StoreFocus.donate),
          key: const Key('my-chip-value'),
        ),
      ],
    );
  }
}

/// 일일 땀방울 게이지 + 내 다이아(보너스/결제 펼침) + 네 칸 바로가기.
class MyQuickSection extends ConsumerWidget {
  const MyQuickSection({
    required this.onDonation,
    required this.onTierBook,
    required this.onSettings,
    super.key,
  });

  final VoidCallback onDonation;
  final VoidCallback onTierBook;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.srcTokens;
    final wallet = ref.watch(walletProvider);
    Widget tile(IconData icon, String label, Color color, VoidCallback onTap,
        {Key? key}) {
      return Expanded(
        child: InkWell(
          key: key,
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: tokens.colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tokens.colors.outline),
            ),
            child: Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: tokens.colors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SrcSurfaceCard(
          padding: const EdgeInsets.all(14),
          child: DailyCapGauge(dailyKm: ref.watch(retentionDailyKmProvider)),
        ),
        const SizedBox(height: 8),
        HomeDiamondCard(
          wallet: (ref.watch(activeWalletProvider).asData?.value ??
                  WalletModel.empty())
              .copyWith(diamondBalance: wallet.diamondBalance),
          onOpenStore: () =>
              HomeNavigation.openStore(context, ref, focus: StoreFocus.items),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            tile(
              Icons.account_balance_wallet_outlined,
              '내 지갑',
              tokens.colors.accent,
              () => MyWalletScreen.open(context),
              key: const Key('my-tile-wallet'),
            ),
            const SizedBox(width: 8),
            tile(
              Icons.favorite_rounded,
              '기부 정산',
              tokens.colors.donation,
              onDonation,
              key: const Key('my-tile-donation'),
            ),
            const SizedBox(width: 8),
            tile(
              Icons.pets_rounded,
              '티어 도감',
              tokens.colors.accent,
              onTierBook,
              key: const Key('my-tile-tierbook'),
            ),
            const SizedBox(width: 8),
            tile(
              Icons.settings_outlined,
              '설정',
              tokens.colors.muted,
              onSettings,
              key: const Key('my-tile-settings'),
            ),
          ],
        ),
      ],
    );
  }
}

/// 마이: 다음 메달까지 승급 점수. 서버가 보낸 점수만 보여 준다.
/// 등급이 없는 달팽이는 점수 대상이 아니라서 보이지 않는다.
class PromotionProgressCard extends ConsumerWidget {
  const PromotionProgressCard({super.key});

  static const barKey = Key('promotion-progress-bar');

  /// 서버가 `promotion.step`을 아직 안 보낸 사람(대회 결과 전)용 기본값.
  /// 서버 기본 설정과 같은 값이다: 거북 20 · 비글 30 · 늑대 40 · 얼룩말 60 · 치타 60.
  static int fallbackStep(int gradeRank) {
    const steps = [20, 30, 40, 60, 60];
    final animal = ((gradeRank - 1) ~/ 5).clamp(0, 4);
    return steps[animal];
  }

  static String? blockedText(String reason) => switch (reason) {
        'cooldown' => AppStrings.promotionBlockedCooldown,
        'tournaments' => AppStrings.promotionBlockedTournaments,
        'pace' => AppStrings.promotionBlockedPace,
        'season' => AppStrings.promotionBlockedSeason,
        _ => null,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    if (profile.gradeRank <= 0 || profile.gradeRank >= 25) {
      return const SizedBox.shrink();
    }
    final tokens = context.srcTokens;
    final step = profile.promotionStep > 0
        ? profile.promotionStep
        : fallbackStep(profile.gradeRank);
    final points = profile.promotionPoints.clamp(0, step);
    final note =
        blockedText(profile.promotionBlocked) ?? AppStrings.promotionHint;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tokens.colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: tokens.colors.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.promotionTitle,
                    style: TextStyle(
                      color: tokens.colors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  AppStrings.promotionProgress(points, step),
                  style: TextStyle(
                    color: tokens.colors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                key: barKey,
                value: points / step,
                minHeight: 8,
                backgroundColor: tokens.colors.outline,
                color: tokens.colors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              note,
              style: TextStyle(color: tokens.colors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
