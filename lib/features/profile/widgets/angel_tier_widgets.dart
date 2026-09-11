import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../core/navigation/app_route_nav.dart';
import '../../../core/theme/theme.dart';
import '../../../screens/angel_book_page.dart';
import '../../../screens/personal_sponsor_screen.dart';
import '../../onboarding/src_onboarding_controller.dart';
import '../user_profile_notifier.dart';

/// src-17 개인스폰서 후원결제. 도감을 거치지 않고 직행한다.
void openPersonalSponsor(BuildContext context) {
  final router = GoRouter.maybeOf(context);
  if (router != null) {
    try {
      context.pushNamed(RouteNames.personalSponsor);
      return;
    } catch (_) {
      context.push(RouteNames.personalSponsor);
      return;
    }
  }
  AppRouteNav.push<void>(
    context,
    RouteNames.personalSponsor,
    materialBuilder: (_) => const PersonalSponsorScreen(),
  );
}

void openAngelBook(BuildContext context) {
  final router = GoRouter.maybeOf(context);
  if (router != null) {
    try {
      context.pushNamed(RouteNames.angelBook);
      return;
    } catch (_) {
      context.push(RouteNames.angelBookPath);
      return;
    }
  }
  AppRouteNav.push<void>(
    context,
    RouteNames.angelBookPath,
    materialBuilder: (_) => const AngelBookPage(),
  );
}

/// 홈 유저네임 옆 콤팩트 천사 배지.
class AngelTierBadge extends StatelessWidget {
  const AngelTierBadge({super.key, required this.tier});

  final AngelTier tier;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: Image.asset(
            tier.avatarAssetPath,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Text(
              tier.emoji,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            '[${tier.koreanName}]',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.agreementLabel.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: tier.isPreAngel ? AppColors.textGrey : AppColors.angelGold,
            ),
          ),
        ),
      ],
    );
  }
}

/// Chibi 천사 마스코트. 세라핌은 헤일로 회전, 지천사+는 민트 오라.
class AngelMascot extends StatefulWidget {
  const AngelMascot({
    super.key,
    required this.tier,
    this.size = 88,
  });

  final AngelTier tier;
  final double size;

  @override
  State<AngelMascot> createState() => _AngelMascotState();
}

class _AngelMascotState extends State<AngelMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    if (widget.tier.rotatingHalo) {
      _spin.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AngelMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tier.rotatingHalo && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!widget.tier.rotatingHalo && _spin.isAnimating) {
      _spin.stop();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    Widget mascot = Image.asset(
      widget.tier.avatarAssetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => SizedBox(
        width: size,
        height: size,
        child: Center(
          child:
              Text(widget.tier.emoji, style: TextStyle(fontSize: size * 0.42)),
        ),
      ),
    );

    if (widget.tier.neonAura) {
      mascot = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.tealAccent.withValues(alpha: 0.35),
              blurRadius: 18,
              spreadRadius: 4,
            ),
          ],
        ),
        child: mascot,
      );
    }

    if (widget.tier.rotatingHalo) {
      mascot = SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -size * 0.08,
              child: RotationTransition(
                turns: _spin,
                child: Icon(
                  Icons.wb_sunny_outlined,
                  size: size * 0.28,
                  color: AppColors.angelGold,
                ),
              ),
            ),
            mascot,
          ],
        ),
      );
    }

    return mascot;
  }
}

/// 마이페이지 나의 천사 연대기 카드.
class AngelChronicleCard extends ConsumerWidget {
  const AngelChronicleCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final tier = profile.angelTier;
    final count = profile.safeDonationCount;
    final amount = profile.safeCumulativeDonationAmount;
    final isPreAngel = count == 0 || tier.isPreAngel;
    final progress = tier.progressToNext(
      donationCount: count,
      cumulativeDonationAmount: amount,
    );
    final gap = tier.nextGapLabel(
      donationCount: count,
      cumulativeDonationAmount: amount,
    );

    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(AppShapes.cardRadius),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppShapes.cardRadius),
          border: Border.all(
            color: AppColors.angelGold.withValues(alpha: 0.45),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => openAngelBook(context),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '나의 천사 연대기',
                      style: AppTextStyles.agreementLabel.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        AngelMascot(tier: tier, size: 72),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${tier.emoji} ${tier.koreanName}',
                                style: AppTextStyles.header1.copyWith(
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tier.englishName,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textGrey,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '후원 $count회 · '
                                '${AngelTierX.formatWon(amount)}',
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (isPreAngel) ...[
              const SizedBox(height: 12),
              Text(
                '아직 등 뒤에 장착된 진짜 날개가 없습니다. '
                '단 1회 기부로 귀여운 아기 날개를 달아보세요!',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 12,
                  height: 1.45,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 10),
              const _FirstWingCta(),
            ] else ...[
              const SizedBox(height: 12),
              AngelProgressBar(progress: progress, label: gap),
              const SizedBox(height: 10),
              const _PromoteAngelCta(),
            ],
          ],
        ),
      ),
    );
  }
}

/// 예비 천사 — 민트 그라데이션 첫 날개 CTA. src-17 직행.
class _FirstWingCta extends StatelessWidget {
  const _FirstWingCta();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => openPersonalSponsor(context),
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.primaryMintLight,
                AppColors.tealAccent,
              ],
            ),
          ),
          child: Center(
            child: Text(
              '첫 날개 달기 👼 〉',
              style: AppTextStyles.agreementLabel.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AppColors.textWhite,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 정식 천사 — 승급 게이지 아래 콤팩트 배너. src-17 직행.
class _PromoteAngelCta extends StatelessWidget {
  const _PromoteAngelCta();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.tealAccent.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => openPersonalSponsor(context),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(
            '후원하고 천사 등급 올리기 〉',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.tealAccent,
            ),
          ),
        ),
      ),
    );
  }
}

class AngelProgressBar extends StatelessWidget {
  const AngelProgressBar({
    super.key,
    required this.progress,
    required this.label,
  });

  final double progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 10,
            child: Stack(
              children: [
                const ColoredBox(
                  color: AppColors.settingsBackground,
                  child: SizedBox.expand(),
                ),
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.tealAccent, AppColors.angelGold],
                      ),
                    ),
                    child: SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontSize: 11,
            color: AppColors.textGrey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// 홈 지갑 아래 후원 숏컷.
class AngelSponsorBanner extends StatelessWidget {
  const AngelSponsorBanner({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    return Material(
      color: tokens.colors.donation.withValues(alpha: 0.14),
      borderRadius: tokens.radii.panel,
      child: InkWell(
        onTap: onTap ?? () => openPersonalSponsor(context),
        borderRadius: tokens.radii.panel,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spacing.md,
            vertical: tokens.spacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: tokens.radii.panel,
            border: Border.all(
              color: tokens.colors.donation.withValues(alpha: 0.45),
            ),
          ),
          child: Text(
            '❤️  내 이름으로 달리기 후원하기',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: tokens.colors.donation,
                ),
          ),
        ),
      ),
    );
  }
}

/// 명예의 전당 세라핌 VVIP 빌보드.
class SeraphimHonorBillboard extends ConsumerWidget {
  const SeraphimHonorBillboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final nickname = ref.watch(userNicknameProvider);
    final isSeraphim = profile.angelTier == AngelTier.seraphim;
    final display = SrcOnboardingController.isUnsetNickname(nickname)
        ? '이번 달 명예 후원자'
        : nickname;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        gradient: LinearGradient(
          colors: [
            AppColors.angelGold.withValues(alpha: 0.22),
            AppColors.tealAccent.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(color: AppColors.angelGold, width: 1.4),
      ),
      child: Column(
        children: [
          Text(
            '세라핌 VVIP 명예 전광판',
            style: AppTextStyles.agreementLabel.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          const AngelMascot(tier: AngelTier.seraphim, size: 96),
          const SizedBox(height: 8),
          Text(
            isSeraphim ? display : '이번 달 최고 누적 기부 · 세라핌',
            style: AppTextStyles.header1.copyWith(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            isSeraphim
                ? '6익 천사 · 영롱한 광배가 당신을 비춥니다'
                : '누적 100회 또는 5,000,000 SHARE 후원 시 이 자리에 오릅니다',
            style: AppTextStyles.caption.copyWith(color: AppColors.textGrey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

Future<void> showPreAngelGuideSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
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
              const AngelMascot(tier: AngelTier.preAngel, size: 88),
              const SizedBox(height: 12),
              Text(
                '등록된 날개가 없습니다. 단 1회 후원으로 귀여운 진짜 아기 날개를 등 뒤에 달아보세요!',
                textAlign: TextAlign.center,
                style: AppTextStyles.agreementLabel.copyWith(
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: AppShapes.buttonHeight,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    openPersonalSponsor(context);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.tealAccent,
                    foregroundColor: AppColors.textWhite,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('지금 후원하고 아기 날개 달기'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
