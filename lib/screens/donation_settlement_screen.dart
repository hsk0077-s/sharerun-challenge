import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/theme.dart';
import '../features/donation/donation_settlement.dart';
import '../features/profile/my_page_activity_stats.dart';
import '../features/shop/providers/donation_match_provider.dart';
import '../features/shop/widgets/store_look.dart';

/// 기부 정산. 기부는 운영자·스폰서가 하고, 앱은 내 기여를 보여 준다.
/// 기부처(수혜 단체)는 정해지기 전이라 쓰지 않는다.
class DonationSettlementScreen extends ConsumerStatefulWidget {
  const DonationSettlementScreen({super.key});

  static const retryKey = Key('donation-settlement-retry');
  static const myTotalKey = Key('donation-settlement-mine');
  static const monthKey = Key('donation-settlement-month');
  static const capKey = Key('donation-settlement-cap');

  static const intro = '달리기 1km마다 100원을 운영자·스폰서 이름으로 기부해요.';
  static const capReachedLine =
      '이번 달 운영자 기부 예산을 모두 사용했어요 · 넘는 거리는 기록으로 남아요';
  static const disclaimer =
      '운영자가 자기 돈으로 검증 1km당 100원(KRW)을 월 예산 안에서 냅니다. '
      '이용자의 기부금이 아니며 세금 공제 영수증이 발급되지 않습니다.';

  @override
  ConsumerState<DonationSettlementScreen> createState() =>
      _DonationSettlementScreenState();
}

class _DonationSettlementScreenState
    extends ConsumerState<DonationSettlementScreen> {
  DonationSettlement? _data;
  bool _loading = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final data = await ref.read(donationSettlementLoaderProvider)();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  static String kmGauge(int totalWon, int capWon) {
    String km(int wonAmount) {
      final whole = wonAmount ~/ 100;
      final digits = whole.toString();
      final out = StringBuffer();
      for (var i = 0; i < digits.length; i++) {
        final remaining = digits.length - i;
        if (i > 0 && remaining % 3 == 0) out.write(',');
        out.write(digits[i]);
      }
      return out.toString();
    }

    final pct = capWon <= 0 ? 0 : ((totalWon / capWon) * 100).round();
    return '이번 달 ${km(totalWon)} / ${km(capWon)} km · $pct%';
  }

  static String won(int value) {
    final digits = value.toString();
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final remaining = digits.length - i;
      if (i > 0 && remaining % 3 == 0) out.write(',');
      out.write(digits[i]);
    }
    return '$out원';
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final c = context.srcTokens.colors;
    final now = DateTime.now();
    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
          children: [
            Row(
              children: [
                IconButton(
                  key: const Key('donation-back'),
                  onPressed: () => Navigator.of(context).maybePop(),
                  tooltip: '뒤로',
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  icon: Icon(Icons.arrow_back_rounded, color: c.ink),
                ),
                const Spacer(),
                const StoreTag('DONATION'),
                const SizedBox(width: 12),
                StoreTag(
                    '${now.year} · ${now.month.toString().padLeft(2, '0')}'),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '내가 만든\n기부',
              style: storeText(36, c.ink, w: FontWeight.w900, h: 1.1),
            ),
            const SizedBox(height: 6),
            Text(
              DonationSettlementScreen.intro,
              style: storeText(14, c.muted, h: 1.5),
            ),
            const SizedBox(height: 16),
            if (data == null && _loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (data == null && _failed) ...[
              Text(
                '기부 정산을 불러오지 못했어요. 잠시 뒤 다시 시도해 주세요.',
                style: storeText(14, c.muted),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                key: DonationSettlementScreen.retryKey,
                onPressed: _load,
                child: const Text('다시 시도'),
              ),
            ] else if (data != null) ...[
              _GoldTile(
                total: won(data.myTotalWon),
                totalKey: DonationSettlementScreen.myTotalKey,
              ),
              const SizedBox(height: 10),
              _MonthTile(
                total: won(data.monthTotalWon),
                totalKey: DonationSettlementScreen.monthKey,
                cap: data.monthCapWon,
                monthTotal: data.monthTotalWon,
                capReached: data.capReached,
                capLabel: data.capReached
                    ? DonationSettlementScreen.capReachedLine
                    : (data.monthCapWon > 0
                        ? _DonationSettlementScreenState.kmGauge(
                            data.monthTotalWon, data.monthCapWon)
                        : null),
                capKey: DonationSettlementScreen.capKey,
              ),
              const SizedBox(height: 10),
              _MonthStats(
                days: ref
                    .watch(myPageActivityStatsProvider)
                    .activeMonthDays
                    .length,
                km: ref.watch(myPageActivityStatsProvider).monthKm,
                matches: ref
                        .watch(donationMatchProvider)
                        .asData
                        ?.value
                        .where(
                          (e) =>
                              e.monthKey == donationMonthKey() &&
                              e.companyWon > 0,
                        )
                        .length ??
                    0,
              ),
              const SizedBox(height: 18),
              Text(
                '기부는 운영자·스폰서가 해요. 앱에서는 내가 기여한 금액을 확인할 수 있어요.',
                style: storeText(13, c.muted, h: 1.5),
              ),
              const SizedBox(height: 8),
              Text(
                DonationSettlementScreen.disclaimer,
                style: storeText(13, c.muted, h: 1.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 내가 기여한 금액. 금색은 기부에만 쓴다.
class _GoldTile extends StatelessWidget {
  const _GoldTile({required this.total, required this.totalKey});

  final String total;
  final Key totalKey;

  static const _gold = Color(0xFFE8B84B);

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A2310), Color(0xFF14110A)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StoreTag('TOTAL', color: _gold),
          const SizedBox(height: 8),
          Text(
            total,
            key: totalKey,
            style: storeText(36, c.ink, w: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            '운영자가 대신 내요 · 내 돈은 0원',
            style: storeText(14, const Color(0xFFC9B27A)),
          ),
        ],
      ),
    );
  }
}

/// 이번 달 전체 기부와 한도 막대.
class _MonthTile extends StatelessWidget {
  const _MonthTile({
    required this.total,
    required this.totalKey,
    required this.cap,
    required this.monthTotal,
    required this.capReached,
    required this.capLabel,
    required this.capKey,
  });

  final String total;
  final Key totalKey;
  final int cap;
  final int monthTotal;
  final bool capReached;
  final String? capLabel;
  final Key capKey;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    final pct = cap > 0 ? (monthTotal / cap).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StoreTag('THIS MONTH'),
          const SizedBox(height: 6),
          Text(
            '이번 달 기부',
            style: storeText(14, c.muted, w: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            total,
            key: totalKey,
            style: storeText(26, c.ink, w: FontWeight.w900),
          ),
          if (cap > 0) ...[
            const SizedBox(height: 14),
            Container(
              height: 3,
              color: c.outline,
              child: FractionallySizedBox(
                widthFactor: pct,
                alignment: Alignment.centerLeft,
                child: Container(color: const Color(0xFFE8B84B)),
              ),
            ),
          ],
          if (capLabel != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  capLabel!,
                  key: capKey,
                  style: storeText(12, c.muted, w: FontWeight.w700),
                ),
                const Spacer(),
                if (cap > 0)
                  Text(
                    '${(pct * 100).round()}%',
                    style: storeText(
                      12,
                      const Color(0xFFE8B84B),
                      w: FontWeight.w800,
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

/// 이번 달 활동한 날 · 거리 · 기부 매칭 횟수.
class _MonthStats extends StatelessWidget {
  const _MonthStats({
    required this.days,
    required this.km,
    required this.matches,
  });

  final int days;
  final double km;
  final int matches;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    Widget tile(String value, String label, {Color? color}) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: c.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: storeText(
                      26,
                      color ?? c.ink,
                      w: FontWeight.w900,
                      h: 1.05,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                StoreTag(label),
              ],
            ),
          ),
        );
    return Row(
      key: const Key('donation-month-stats'),
      children: [
        tile('$days', 'DAYS'),
        const SizedBox(width: 10),
        tile(km.toStringAsFixed(1), 'KM'),
        const SizedBox(width: 10),
        tile('$matches', 'MATCH', color: const Color(0xFFE8B84B)),
      ],
    );
  }
}
