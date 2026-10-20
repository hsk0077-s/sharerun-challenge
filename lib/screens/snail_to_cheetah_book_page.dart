import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/navigation/dashboard_tab_navigation.dart';
import '../core/theme/theme.dart';
import '../features/shop/widgets/store_look.dart';
import '../features/accessories/accessory_catalog.dart';
import '../features/accessories/try_on_sheet.dart';
import '../features/onboarding/src_onboarding_controller.dart';

/// 달팽이 → 치타 25단계 티어 도감.
/// 위에는 다섯 친구를 한눈에(완료·현재·다음), 아래에는 25단계 연대기를 둔다.
class SnailToCheetahBookPage extends ConsumerWidget {
  const SnailToCheetahBookPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tier =
        ref.watch(activeUserTierStructProvider) ?? UserTier.unratedFallback;
    final c = context.srcTokens.colors;
    final myRank = tier.animalUnlockRank;

    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 4, 16, tier.isSnail ? 200 : 40),
          children: [
            Row(
              children: [
                IconButton(
                  key: const Key('tier-book-back'),
                  onPressed: () => Navigator.of(context).maybePop(),
                  tooltip: '뒤로',
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  icon: Icon(Icons.arrow_back_rounded, color: c.ink),
                ),
                const Spacer(),
                const StoreTag('TIER BOOK'),
              ],
            ),
            Text(
              '티어 도감',
              style: storeText(36, c.ink, w: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              '달릴수록 새로운 친구를 만나요',
              style: storeText(14, c.muted),
            ),
            const SizedBox(height: 16),
            GridView.count(
              key: const Key('tier-book-grid'),
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.82,
              padding: EdgeInsets.zero,
              children: [
                for (final chapter in _chapters.where((e) => !e.isSnail))
                  _BookGridCard(
                    chapter: chapter,
                    state: chapter.unlockRank < myRank
                        ? _BookState.done
                        : (chapter.unlockRank == myRank
                            ? _BookState.current
                            : _BookState.next),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              '25단계 연대기',
              style: storeText(18, c.ink, w: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              '달팽이부터 치타까지 모든 등급을 열람할 수 있어요. 카드를 누르면 액세서리를 입혀 볼 수 있어요.',
              style: storeText(13, c.muted, h: 1.5),
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
      ),
      bottomSheet: tier.isSnail ? const _UnratedGuide() : null,
    );
  }
}

enum _BookState { done, current, next }

/// 다섯 친구 중 한 칸. 현재 티어는 라임 테두리다.
class _BookGridCard extends StatelessWidget {
  const _BookGridCard({required this.chapter, required this.state});

  final _ChapterSpec chapter;
  final _BookState state;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    final current = state == _BookState.current;
    final label = switch (state) {
      _BookState.done => '완료',
      _BookState.current => '현재',
      _BookState.next => '도전',
    };
    final path = UserTier(
      animal: chapter.animal,
      medal: TierMedal.gold,
    ).avatarAssetPath;
    return InkWell(
      key: Key('tier-book-card-${chapter.animal.code}'),
      borderRadius: BorderRadius.circular(22),
      onTap: () => TryOnSheet.show(
        context,
        animal: chapter.animal,
        title: chapter.title,
      ),
      child: Ink(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: current ? c.primary : c.outline,
            width: current ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Opacity(
                  opacity: state == _BookState.next ? 0.55 : 1,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: current ? c.primary : c.outline,
                        width: 2,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Transform.scale(
                      scale: 1.25,
                      child: Image.asset(path, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              chapter.title,
              style: storeText(14, c.ink, w: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: storeText(
                14,
                current ? c.primary : c.muted,
                w: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 아직 티어가 없을 때(등급 심사 전) 아래에 붙는 안내.
class _UnratedGuide extends StatelessWidget {
  const _UnratedGuide();

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    return Container(
      key: const Key('tier-book-unrated-guide'),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1512),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
        border: Border.all(color: c.outline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: c.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: c.surface,
              shape: BoxShape.circle,
              border: Border.all(color: c.primary, width: 3),
            ),
            clipBehavior: Clip.antiAlias,
            child: Transform.scale(
              scale: 1.25,
              child: Image.asset(
                'assets/images/characters/chibi_snail_smiling.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '아직 티어가 없어요',
            style: storeText(18, c.ink, w: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            '첫 달리기가 심사되면 티어가 정해지고\n옷과 소품을 입힐 수 있어요',
            textAlign: TextAlign.center,
            style: storeText(14, c.muted, h: 1.5),
          ),
          const SizedBox(height: 16),
          StorePillButton(
            key: const Key('tier-book-go-run'),
            label: '달리러 가기',
            icon: Icons.directions_run_rounded,
            onPressed: () => DashboardTabNavigation.go(
              context,
              DashboardTabNavigation.home,
            ),
          ),
        ],
      ),
    );
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
    subtitle: '등급 배정 전 임시 등급',
    paceGuide: '검증 달리기 3회 전 · 서브 티어 없음',
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
    title: '비글',
    subtitle: '가벼운 조깅을 즐기는 러닝 입문자',
    paceGuide: '평균 페이스 6분 00초 ~ 7분 29초',
    animal: TierAnimal.beagle,
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
    title: '얼룩말',
    subtitle: '러닝 숙련자 수준',
    paceGuide: '평균 페이스 4분 00초 ~ 4분 59초',
    animal: TierAnimal.zebra,
  ),
  _ChapterSpec(
    unlockRank: 5,
    title: '치타',
    subtitle: '아마추어 최상위권 수준',
    paceGuide: '평균 페이스 4분 00초 미만',
    animal: TierAnimal.cheetah,
  ),
];

class _TierChapterCard extends StatelessWidget {
  const _TierChapterCard({required this.chapter});

  final _ChapterSpec chapter;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.nightLine),
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
    // 달팽이는 입힐 그림이 없어서 눌러도 열리지 않는다.
    if (!canDress(chapter.animal)) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('tier-book-try-on-${chapter.animal.code}'),
        borderRadius: BorderRadius.circular(16),
        onTap: () => TryOnSheet.show(
          context,
          animal: chapter.animal,
          title: chapter.title,
        ),
        child: card,
      ),
    );
  }
}

/// 도감에서 티어가 올라갈수록 캐릭터를 조금씩 크게 그린다. 거북이가 기준(1.0).
/// 한 단계에 8%. 4%일 때는 폰에서 차이가 보이지 않았다.
abstract final class TierBookScale {
  static double of(TierAnimal animal) => switch (animal) {
        TierAnimal.snail => 0.92,
        TierAnimal.turtle => 1.0,
        TierAnimal.beagle => 1.08,
        TierAnimal.wolf => 1.16,
        TierAnimal.zebra => 1.24,
        TierAnimal.cheetah => 1.32,
      };

  /// 칸 높이. 가장 큰 치타에 맞춰서 줄이 흔들리지 않게 한다.
  static double slot(double size) => size * of(TierAnimal.cheetah);
}

/// 달성 여부와 무관하게 순정 풀 컬러 마스코트만 그린다.
/// 칸 크기는 같고, 캐릭터는 발이 닿는 아래쪽 기준선에 맞춰 티어별로 크기만 다르다.
class _UnlockedMascot extends StatelessWidget {
  const _UnlockedMascot({
    required this.animal,
    required this.size,
  });

  final TierAnimal animal;
  final double size;

  @override
  Widget build(BuildContext context) {
    final path = UserTier(
      animal: animal,
      medal: TierMedal.gold,
    ).avatarAssetPath;
    final slot = TierBookScale.slot(size);
    final drawn = size * TierBookScale.of(animal);
    return SizedBox(
      key: Key('tier-book-mascot-${animal.code}'),
      width: slot,
      height: slot,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Image.asset(
          path,
          width: drawn,
          height: drawn,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
