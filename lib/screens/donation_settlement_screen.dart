import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../features/donation/donation_settlement.dart';

/// 기부 정산. 기부는 회사·스폰서가 하고, 앱은 내 기여를 보여 준다.
/// 기부처(수혜 단체)는 정해지기 전이라 쓰지 않는다.
class DonationSettlementScreen extends ConsumerStatefulWidget {
  const DonationSettlementScreen({super.key});

  static const retryKey = Key('donation-settlement-retry');
  static const myTotalKey = Key('donation-settlement-mine');
  static const monthKey = Key('donation-settlement-month');
  static const capKey = Key('donation-settlement-cap');

  static const intro = '달리기 1km마다 100원을 회사·스폰서 이름으로 기부해요.';
  static const capReachedLine = '이번 달 기부 목표 달성!';

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
    return Scaffold(
      backgroundColor: AppColors.settingsBackground,
      appBar: AppBar(
        backgroundColor: AppColors.settingsBackground,
        elevation: 0,
        foregroundColor: AppColors.textBlack,
        title: Text(
          '기부 정산',
          style: AppTextStyles.header1.copyWith(fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            DonationSettlementScreen.intro,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textBlack,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          if (data == null && _loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (data == null && _failed) ...[
            Text(
              '기부 정산을 불러오지 못했어요. 잠시 뒤 다시 시도해 주세요.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textGrey),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: DonationSettlementScreen.retryKey,
              onPressed: _load,
              child: const Text('다시 시도'),
            ),
          ] else if (data != null) ...[
            _Figure(
              label: '내가 기여한 금액',
              value: won(data.myTotalWon),
              valueKey: DonationSettlementScreen.myTotalKey,
            ),
            const SizedBox(height: 12),
            _Figure(
              label: '이번 달 기부',
              value: won(data.monthTotalWon),
              valueKey: DonationSettlementScreen.monthKey,
              note: data.capReached
                  ? DonationSettlementScreen.capReachedLine
                  : (data.monthCapWon > 0
                      ? '이번 달 한도 ${won(data.monthCapWon)}'
                      : null),
              noteKey: DonationSettlementScreen.capKey,
            ),
            const SizedBox(height: 18),
            Text(
              '기부는 회사·스폰서가 해요. 앱에서는 내가 기여한 금액을 확인할 수 있어요.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textGrey),
            ),
          ],
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    required this.valueKey,
    this.note,
    this.noteKey,
  });

  final String label;
  final String value;
  final Key valueKey;
  final String? note;
  final Key? noteKey;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.tealAccent.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(color: AppColors.textGrey),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              key: valueKey,
              style: AppTextStyles.header1.copyWith(fontSize: 26),
            ),
            if (note != null) ...[
              const SizedBox(height: 6),
              Text(
                note!,
                key: noteKey,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.tealAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
