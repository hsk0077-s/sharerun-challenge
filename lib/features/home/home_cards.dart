import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme.dart';
import '../../data/models/wallet_model.dart';
import '../donation/today_donation.dart';

/// 천 단위 쉼표. `1250` → `1,250`.
String groupedNumber(int value) {
  final digits = value.abs().toString();
  final out = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i;
    if (i > 0 && remaining % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}

/// 내 다이아. 기본은 총 다이아만 보이고, 누르면 보너스 / 결제로 펼쳐진다.
/// 보너스 다이아부터 쓰이며 환불은 결제 다이아 기준이다(서버 규칙).
class HomeDiamondCard extends StatefulWidget {
  const HomeDiamondCard({
    required this.wallet,
    required this.onOpenStore,
    super.key,
  });

  final WalletModel wallet;
  final VoidCallback onOpenStore;

  static const toggleKey = Key('home-diamond-toggle');
  static const totalKey = Key('home-diamond-total');
  static const bonusKey = Key('home-diamond-bonus');
  static const paidKey = Key('home-diamond-paid');
  static const storeKey = Key('home-diamond-store');

  @override
  State<HomeDiamondCard> createState() => _HomeDiamondCardState();
}

class _HomeDiamondCardState extends State<HomeDiamondCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    final wallet = widget.wallet;
    return SrcSurfaceCard(
      padding: EdgeInsets.all(tokens.spacing.md),
      borderColor: tokens.colors.accent.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: HomeDiamondCard.toggleKey,
            borderRadius: tokens.radii.card,
            onTap: () => setState(() => _open = !_open),
            child: Row(
              children: [
                Icon(Icons.diamond_outlined, color: tokens.colors.accent),
                SizedBox(width: tokens.spacing.xs),
                Flexible(
                  child: Text(
                    '내 다이아',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      color: tokens.colors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(width: tokens.spacing.xs),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${groupedNumber(wallet.diamondBalance)} DIA',
                        key: HomeDiamondCard.totalKey,
                        style: textTheme.titleLarge?.copyWith(
                          color: tokens.colors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
                Icon(
                  _open ? Icons.expand_less : Icons.expand_more,
                  color: tokens.colors.muted,
                ),
              ],
            ),
          ),
          if (_open) ...[
            SizedBox(height: tokens.spacing.sm),
            if (wallet.hasDiamondSplit) ...[
              _SplitRow(
                label: '보너스 다이아',
                badge: '먼저 사용',
                value: wallet.freeDiamondBalance,
                valueKey: HomeDiamondCard.bonusKey,
              ),
              SizedBox(height: tokens.spacing.xs),
              _SplitRow(
                label: '결제 다이아',
                value: wallet.paidDiamondBalance,
                valueKey: HomeDiamondCard.paidKey,
              ),
              SizedBox(height: tokens.spacing.xs),
            ],
            Text(
              '보너스 다이아는 대회 상금으로 받으며 먼저 사용돼요.\n'
              '환불은 결제 다이아 기준이에요.',
              style: textTheme.bodySmall?.copyWith(
                color: tokens.colors.muted,
                height: 1.45,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: HomeDiamondCard.storeKey,
                onPressed: widget.onOpenStore,
                child: const Text('다이아 상점 가기'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SplitRow extends StatelessWidget {
  const _SplitRow({
    required this.label,
    required this.value,
    required this.valueKey,
    this.badge,
  });

  final String label;
  final int value;
  final Key valueKey;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Text(label, style: textTheme.bodyMedium),
        if (badge != null) ...[
          SizedBox(width: tokens.spacing.xs),
          DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.colors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                badge!,
                style: textTheme.labelSmall?.copyWith(
                  color: tokens.colors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
        const Spacer(),
        Text(
          groupedNumber(value),
          key: valueKey,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

/// 오늘 나의 기부 기여. 기부는 회사·스폰서가 하고, 금액은 서버 기부 원장의 오늘 합계다.
/// 기부처(수혜 단체)는 정해지기 전이라 쓰지 않는다.
class HomeDonationCard extends ConsumerWidget {
  const HomeDonationCard({required this.onOpenSettlement, super.key});

  final VoidCallback onOpenSettlement;

  static const amountKey = Key('home-donation-today');
  static const capKey = Key('home-donation-cap');
  static const detailKey = Key('home-donation-detail');
  static const retryKey = Key('home-donation-retry');

  static const rule = '검증된 모든 달리기, 1km마다 회사·스폰서 이름으로 100원을 기부해요.';
  static const budget = '회사의 월 기부 예산 안에서 진행돼요.';
  static const capReachedLine = '이번 달 기부 목표 달성!';
  static const slogan = '심장이 뛰는 한, 나눔도 달린다';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    final today = ref.watch(todayDonationProvider);
    return SrcSurfaceCard(
      padding: EdgeInsets.all(tokens.spacing.md),
      color: tokens.colors.donation.withValues(alpha: 0.08),
      borderColor: tokens.colors.donation.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, color: tokens.colors.donation, size: 20),
              SizedBox(width: tokens.spacing.xs),
              Expanded(
                child: Text(
                  '오늘 나의 기부 기여',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: tokens.colors.ink,
                  ),
                ),
              ),
              TextButton(
                key: HomeDonationCard.detailKey,
                onPressed: onOpenSettlement,
                child: const Text('기부 내역 ›'),
              ),
            ],
          ),
          today.when(
            data: (data) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.todayWon > 0
                      ? '${groupedNumber(data.todayWon)}원'
                      : '오늘은 아직 기여가 없어요',
                  key: HomeDonationCard.amountKey,
                  style: (data.todayWon > 0
                          ? textTheme.headlineSmall
                          : textTheme.titleSmall)
                      ?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: tokens.colors.ink,
                  ),
                ),
                if (data.capReached) ...[
                  SizedBox(height: tokens.spacing.xxs),
                  Text(
                    HomeDonationCard.capReachedLine,
                    key: HomeDonationCard.capKey,
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: tokens.colors.accent,
                    ),
                  ),
                ],
              ],
            ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, __) => Row(
              children: [
                Expanded(
                  child: Text(
                    '기부 정보를 불러오지 못했어요.',
                    style: textTheme.bodySmall?.copyWith(
                      color: tokens.colors.muted,
                    ),
                  ),
                ),
                TextButton(
                  key: HomeDonationCard.retryKey,
                  onPressed: () => ref.invalidate(todayDonationProvider),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
          SizedBox(height: tokens.spacing.xs),
          Text(
            '${HomeDonationCard.rule}\n${HomeDonationCard.budget}',
            style: textTheme.bodySmall?.copyWith(
              color: tokens.colors.muted,
              height: 1.45,
            ),
          ),
          SizedBox(height: tokens.spacing.xs),
          Text(
            HomeDonationCard.slogan,
            style: textTheme.labelMedium?.copyWith(
              color: tokens.colors.donation,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
