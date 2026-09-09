import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_text_styles.dart';
import '../features/onboarding/src_onboarding_controller.dart';
import '../features/onboarding/widgets/chibi_tier_avatar.dart';

/// 달팽이 → 치타 25단계 티어 도감.
class SnailToCheetahBookPage extends ConsumerWidget {
  const SnailToCheetahBookPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tier = ref.watch(activeUserTierStructProvider) ??
        UserTier.unratedFallback;
    final nickname = ref.watch(userNicknameProvider);
    final displayName = SrcOnboardingController.isUnsetNickname(nickname)
        ? '러너'
        : nickname;
    final onboarding = ref.watch(srcOnboardingControllerProvider);
    final paceLabel = _formatPace(onboarding.averagePaceSeconds);

    return Scaffold(
      backgroundColor: AppColors.settingsBackground,
      appBar: AppBar(
        backgroundColor: AppColors.settingsBackground,
        elevation: 0,
        foregroundColor: AppColors.textBlack,
        title: Text(
          '티어 도감',
          style: AppTextStyles.header1.copyWith(fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _MyTierHeroCard(
            displayName: displayName,
            tier: tier,
            paceLabel: paceLabel,
          ),
          const SizedBox(height: 22),
          Text(
            '25단계 연대기',
            style: AppTextStyles.header1.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            '달팽이부터 치타까지 모든 등급을 열람할 수 있습니다.',
            style: AppTextStyles.caption.copyWith(color: AppColors.textGrey),
          ),
          const SizedBox(height: 14),
          ..._chapters.map(
            (chapter) => Padding(
              key: ValueKey(chapter.unlockRank),
              padding: const EdgeInsets.only(bottom: 12),
              child: _TierChapterCard(chapter: chapter),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatPace(int? secondsPerKm) {
    if (secondsPerKm == null || secondsPerKm <= 0) {
      return '최고 페이스 기록 없음';
    }
    final min = secondsPerKm ~/ 60;
    final sec = secondsPerKm % 60;
    return '최고 페이스 $min\'${sec.toString().padLeft(2, '0')}" /km';
  }
}

class _ChapterSpec {
  const _ChapterSpec({
    required this.unlockRank,
    required this.title,
    required this.subtitle,
    required this.paceGuide,
    required this.animal,
    this.isSnail = false,
  });

  final int unlockRank;
  final String title;
  final String subtitle;
  final String paceGuide;
  final TierAnimal animal;
  final bool isSnail;
}

const _chapters = <_ChapterSpec>[
  _ChapterSpec(
    unlockRank: 0,
    title: '달팽이 (Unrated)',
    subtitle: '예비 심사 미완료 / 건너뛰기 전용 임시 등급',
    paceGuide: '심사 완료 전 · 서브 티어 없음',
    animal: TierAnimal.snail,
    isSnail: true,
  ),
  _ChapterSpec(
    unlockRank: 1,
    title: '거북이',
    subtitle: '빠른 걸음 및 기초 체력 형성 단계',
    paceGuide: '평균 페이스 7분 30초 이상',
    animal: TierAnimal.turtle,
  ),
  _ChapterSpec(
    unlockRank: 2,
    title: '토끼',
    subtitle: '가벼운 조깅을 즐기는 러닝 입문자',
    paceGuide: '평균 페이스 6분 00초 ~ 7분 29초',
    animal: TierAnimal.rabbit,
  ),
  _ChapterSpec(
    unlockRank: 3,
    title: '늑대',
    subtitle: '일반 동호인 / 표준 그룹',
    paceGuide: '평균 페이스 5분 00초 ~ 5분 59초',
    animal: TierAnimal.wolf,
  ),
  _ChapterSpec(
    unlockRank: 4,
    title: '가젤',
    subtitle: '러닝 숙련자 수준',
    paceGuide: '평균 페이스 4분 00초 ~ 4분 59초',
    animal: TierAnimal.gazelle,
  ),
  _ChapterSpec(
    unlockRank: 5,
    title: '치타',
    subtitle: '아마추어 최상위권 수준',
    paceGuide: '평균 페이스 4분 00초 미만',
    animal: TierAnimal.cheetah,
  ),
];

class _MyTierHeroCard extends StatelessWidget {
  const _MyTierHeroCard({
    required this.displayName,
    required this.tier,
    required this.paceLabel,
  });

  final String displayName;
  final UserTier tier;
  final String paceLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        border: Border.all(
          color: AppColors.tealAccent.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.pulseCyan.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          ChibiTierAvatar(
            tier: tier,
            size: 128,
            floating: true,
            showNeonRing: true,
          ),
          const SizedBox(height: 14),
          Text(
            displayName,
            style: AppTextStyles.header1.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            '[${tier.koreanName}]',
            style: AppTextStyles.agreementLabel.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.tealAccent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            paceLabel,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TierChapterCard extends StatelessWidget {
  const _TierChapterCard({required this.chapter});

  final _ChapterSpec chapter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.tealAccent.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _UnlockedMascot(animal: chapter.animal, size: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter.title,
                      style: AppTextStyles.agreementLabel.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      chapter.paceGuide,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.tealAccent,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      chapter.subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textGrey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!chapter.isSnail) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final medal in TierMedal.values)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        children: [
                          _UnlockedMascot(
                            animal: chapter.animal,
                            size: 44,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            medal.labelKo,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// 달성 여부와 무관하게 순정 풀 컬러 마스코트만 그린다.
class _UnlockedMascot extends StatelessWidget {
  const _UnlockedMascot({
    required this.animal,
    required this.size,
  });

  final TierAnimal animal;
  final double size;

  @override
  Widget build(BuildContext context) {
    final needsFlip = animal == TierAnimal.turtle ||
        animal == TierAnimal.wolf ||
        animal == TierAnimal.cheetah;
    final path = UserTier(
      animal: animal,
      medal: TierMedal.gold,
    ).avatarAssetPath;
    final mascot = Image.asset(
      path,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
    if (!needsFlip) return mascot;
    return Transform.flip(flipX: true, child: mascot);
  }
}
