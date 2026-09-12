import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/router/route_names.dart';
import '../core/navigation/app_route_nav.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/src_gradient_background.dart';
import '../features/onboarding/src_onboarding_controller.dart';
import '../features/profile/user_profile_notifier.dart';
import '../features/profile/widgets/gender_profile_avatar.dart';
import '../features/wallet/providers/wallet_provider.dart';
import 'hall_of_fame_screen.dart';

enum _SponsorPurpose { prize, donation }

/// 개인 스폰서십(천사 후원) 화면 (Screen 17).
class PersonalSponsorScreen extends ConsumerStatefulWidget {
  const PersonalSponsorScreen({super.key});

  @override
  ConsumerState<PersonalSponsorScreen> createState() =>
      _PersonalSponsorScreenState();
}

class _PersonalSponsorScreenState extends ConsumerState<PersonalSponsorScreen> {
  _SponsorPurpose _purpose = _SponsorPurpose.donation;
  var _monthlyMembership = true;
  var _busy = false;

  static const _donationShare = 50000;

  void _onClose() => AppRouteNav.popOrHome(context);

  Future<void> _onSponsor() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final wallet = ref.read(walletProvider);
      if (wallet.shareBalance < _donationShare) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'SHARE가 부족합니다. (필요 $_donationShare / 보유 ${wallet.shareBalance})',
            ),
          ),
        );
        return;
      }
      final previousTier = ref.read(userProfileProvider).angelTier;
      // Sync + durable, same as tournament join. `subtractShare` is async and
      // does not remember the post-spend ledger, so a stale Firestore
      // snapshot restores pre-debit SHARE and the My-page bar snaps back.
      ref.read(walletProvider.notifier).applyEntryFeeDebit(_donationShare);
      await ref.read(userProfileNotifierProvider.notifier).processDonation(
            _donationShare,
            receiptTitle: _purpose == _SponsorPurpose.prize
                ? '챌린지 상금 지원 후원 🏆'
                : '유니세프 기부 완료 🕊️',
          );
      if (!mounted) return;
      final nextTier = ref.read(userProfileProvider).angelTier;
      await _showCelebration(
        previousTier: previousTier,
        nextTier: nextTier,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showCelebration({
    required AngelTier previousTier,
    required AngelTier nextTier,
  }) async {
    final purposeLabel = _purpose == _SponsorPurpose.prize
        ? AppStrings.personalSponsorPrizeTitle
        : AppStrings.personalSponsorDonationTitle;
    final promoted = nextTier.index > previousTier.index;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppShapes.cardRadius),
          ),
          title: Text(
            AppStrings.personalSponsorCelebrateTitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.header1.copyWith(fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                nextTier.avatarAssetPath,
                width: 88,
                height: 88,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Text(
                  nextTier.emoji,
                  style: const TextStyle(fontSize: 42),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                promoted
                    ? '${previousTier.koreanName} → ${nextTier.emoji} ${nextTier.koreanName}'
                    : '${nextTier.emoji} ${nextTier.koreanName}',
                textAlign: TextAlign.center,
                style: AppTextStyles.agreementLabel.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.angelGold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$purposeLabel · 50,000 SHARE',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                promoted
                    ? '날개 배지가 프로필에 장착되었습니다. 명예의 전당에서 천사 후원자를 확인할 수 있어요.'
                    : '후원이 등록되었습니다. 명예의 전당에서 천사 후원 기록을 확인할 수 있어요.',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(height: 1.4),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              child: const Text(AppStrings.personalSponsorCelebrateDone),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Replace sponsor with HoF so Android back pops to the
                // previous tab instead of leaving HoF as the only route.
                final router = GoRouter.maybeOf(context);
                if (router != null) {
                  context.pushReplacement(RouteNames.hallOfFame);
                  return;
                }
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => const HallOfFameScreen(),
                  ),
                );
              },
              child: const Text(AppStrings.personalSponsorCelebrateHall),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: AppRouteNav.canPop(context),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        AppRouteNav.popOrHome(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.sponsorBgGradientEnd,
        body: SRCGradientBackground(
          gradient: AppColors.sponsorBackgroundGradient,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.close_rounded),
                          color: AppColors.textBlack,
                          iconSize: 26,
                          onPressed: _onClose,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: Text(
                          AppStrings.personalSponsorTitle,
                          style:
                              AppTextStyles.termsTitle.copyWith(fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppShapes.termsHorizontalPadding,
                      8,
                      AppShapes.termsHorizontalPadding,
                      16,
                    ),
                    child: Column(
                      children: [
                        const _AngelProfileSection(),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceWhite,
                            borderRadius:
                                BorderRadius.circular(AppShapes.cardRadius),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Text(
                            AppStrings.personalSponsorAmount,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.header1.copyWith(fontSize: 26),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            CupertinoSwitch(
                              value: _monthlyMembership,
                              activeTrackColor: AppColors.primaryMint,
                              onChanged: (value) =>
                                  setState(() => _monthlyMembership = value),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                AppStrings.personalSponsorMonthlyToggle,
                                style: AppTextStyles.agreementLabel.copyWith(
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            AppStrings.personalSponsorPurposeLabel,
                            style: AppTextStyles.agreementLabel.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _PurposeCard(
                          selected: _purpose == _SponsorPurpose.prize,
                          icon: '🏆',
                          title: AppStrings.personalSponsorPrizeTitle,
                          description: AppStrings.personalSponsorPrizeDesc,
                          onTap: () =>
                              setState(() => _purpose = _SponsorPurpose.prize),
                        ),
                        const SizedBox(height: 10),
                        _PurposeCard(
                          selected: _purpose == _SponsorPurpose.donation,
                          icon: '🌍',
                          title: AppStrings.personalSponsorDonationTitle,
                          description: AppStrings.personalSponsorDonationDesc,
                          showActiveBadge: true,
                          onTap: () => setState(
                              () => _purpose = _SponsorPurpose.donation),
                        ),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppShapes.termsHorizontalPadding,
                      4,
                      AppShapes.termsHorizontalPadding,
                      12,
                    ),
                    child: Material(
                      color: AppColors.primaryMint,
                      borderRadius: BorderRadius.circular(AppShapes.cardRadius),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: _onSponsor,
                        child: SizedBox(
                          width: double.infinity,
                          height: AppShapes.buttonHeight,
                          child: Center(
                            child: Text(
                              AppStrings.personalSponsorCta,
                              style: AppTextStyles.buttonText.copyWith(
                                color: AppColors.textWhite,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AngelProfileSection extends ConsumerStatefulWidget {
  const _AngelProfileSection();

  @override
  ConsumerState<_AngelProfileSection> createState() =>
      _AngelProfileSectionState();
}

class _AngelProfileSectionState extends ConsumerState<_AngelProfileSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nickname = ref.watch(userNicknameProvider);
    final profile = ref.watch(userProfileProvider);
    final tier = profile.angelTier;
    final count = profile.safeDonationCount;
    final amount = profile.safeCumulativeDonationAmount;
    final displayName =
        SrcOnboardingController.isUnsetNickname(nickname) ? '러너' : nickname;
    final progress = tier.progressToNext(
      donationCount: count,
      cumulativeDonationAmount: amount,
    );
    final stackH = switch (tier) {
      AngelTier.seraphim => 176.0,
      AngelTier.cherubim => 148.0,
      _ => 120.0,
    };

    return Column(
      children: [
        SizedBox(
          height: stackH,
          child: AnimatedBuilder(
            animation: _glow,
            builder: (context, child) {
              final pulse = 0.22 + _glow.value * 0.28;
              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  if (tier.neonAura)
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.tealAccent.withValues(alpha: pulse),
                            blurRadius: 22,
                            spreadRadius: 8,
                          ),
                          if (tier.goldNickname)
                            BoxShadow(
                              color:
                                  AppColors.angelGold.withValues(alpha: pulse),
                              blurRadius: 18,
                              spreadRadius: 4,
                            ),
                        ],
                      ),
                    ),
                  ..._wingLayer(tier),
                  const GenderProfileAvatar(size: 72),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.header1.copyWith(
            fontSize: 18,
            fontWeight:
                tier.emphasizeNickname ? FontWeight.w800 : FontWeight.w700,
            color:
                tier.goldNickname ? AppColors.angelGold : AppColors.textBlack,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${tier.emoji} ${tier.koreanName}',
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.tealAccent,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _nudgeLabel(tier, count, amount),
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textGrey,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 8,
            child: Stack(
              children: [
                const ColoredBox(
                  color: AppColors.settingsBackground,
                  child: SizedBox.expand(),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: const ColoredBox(
                    color: AppColors.tealAccent,
                    child: SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.personalSponsorBadgeHint,
          style: AppTextStyles.caption.copyWith(fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  List<Widget> _wingLayer(AngelTier tier) {
    if (tier.isPreAngel) return const [];
    final asset = tier.avatarAssetPath;
    Widget wing(double size, {double opacity = 1}) {
      return Opacity(
        opacity: opacity,
        child: Image.asset(
          asset,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Text(
            '🪽',
            style: TextStyle(fontSize: size * 0.42),
          ),
        ),
      );
    }

    switch (tier) {
      case AngelTier.cupid:
        return [
          Positioned(right: 18, top: 18, child: wing(36)),
        ];
      case AngelTier.guardian:
        return [
          Positioned(left: 8, child: wing(52, opacity: 0.92)),
          Positioned(right: 8, child: wing(52, opacity: 0.92)),
        ];
      case AngelTier.archangel:
        return [
          Positioned(left: 0, child: wing(64)),
          Positioned(right: 0, child: wing(64)),
        ];
      case AngelTier.cherubim:
        return [
          Positioned(left: 4, top: 8, child: wing(48)),
          Positioned(right: 4, top: 8, child: wing(48)),
          Positioned(left: 4, bottom: 8, child: wing(48)),
          Positioned(right: 4, bottom: 8, child: wing(48)),
        ];
      case AngelTier.seraphim:
        return [
          Positioned(left: -6, top: 4, child: wing(58)),
          Positioned(right: -6, top: 4, child: wing(58)),
          Positioned(left: -10, child: wing(72)),
          Positioned(right: -10, child: wing(72)),
          Positioned(left: -6, bottom: 0, child: wing(58)),
          Positioned(right: -6, bottom: 0, child: wing(58)),
        ];
      case AngelTier.preAngel:
        return const [];
    }
  }

  static String _nudgeLabel(AngelTier tier, int count, int amount) {
    final next = tier.next;
    if (next == null) return '최고 천사 등급입니다';
    final remainCount = (next.minDonationCount - count).clamp(0, 1 << 30);
    if (next.minDonationAmountWon <= 0) {
      return '다음 [${next.koreanName}] 등급까지 후원 $remainCount회 남음!';
    }
    final remainWon = (next.minDonationAmountWon - amount).clamp(0, 1 << 30);
    return '다음 [${next.koreanName}] 등급까지 후원 $remainCount회(또는 ${AngelTierX.formatWon(remainWon)}) 남음!';
  }
}

class _PurposeCard extends StatelessWidget {
  const _PurposeCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.showActiveBadge = false,
  });

  final bool selected;
  final String icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool showActiveBadge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.agreementBoxFill : AppColors.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        side: BorderSide(
          color: selected ? AppColors.primaryMint : AppColors.borderLight,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RadioDot(selected: selected),
              const SizedBox(width: 10),
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTextStyles.agreementLabel.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (selected && showActiveBadge)
                          Text(
                            AppStrings.personalSponsorActive,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryMint,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primaryMint : AppColors.borderGrey,
          width: selected ? 2 : 1.5,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primaryMint,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}
