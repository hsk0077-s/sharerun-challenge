import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/theme/app_colors.dart';
import '../features/wallet/providers/wallet_provider.dart';

class ChargeScreen extends ConsumerWidget {
  const ChargeScreen({required this.requiredAmount, super.key});

  /// The SHARE (coupon) amount, in KRW, that must be charged.
  final int requiredAmount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bgGradientStart,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('SHARE (쿠폰) 충전'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Row(
              children: const [
                Icon(Icons.lock_rounded, size: 16, color: AppColors.textGrey),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '안전한 외부 결제(PG) 네트워크에 연결되었습니다.',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 12.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                '$requiredAmount원 결제',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textBlack,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '결제 수단',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textBlack,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            const _PaymentMethodSelector(),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '충전된 SHARE는 오프라인 러닝 대회 참가권(티켓)으로만 사용됩니다. '
                      '현금처럼 자유롭게 인출하거나 타인에게 양도할 수 없습니다.',
                      style: TextStyle(color: AppColors.error, fontSize: 12.5, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '환불 안내: 대회 시작 전 미사용 SHARE는 전액 환불 요청이 가능하며, '
              '대회 참가 확정 후에는 대회 운영 규정에 따라 환불 여부가 결정됩니다.',
              style: TextStyle(color: AppColors.textGrey, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.paymentButtonBlue,
                  foregroundColor: AppColors.textWhite,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => _pay(context, ref),
                child: Text(
                  '$requiredAmount원 안전 결제하기',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pay(BuildContext context, WidgetRef ref) {
    ref.read(walletProvider.notifier).chargeShare(requiredAmount);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '결제 시뮬레이션 성공! $requiredAmount SHARE가 충전되었습니다.',
        ),
      ),
    );
    context.pop();
  }
}

class _PaymentMethodSelector extends StatefulWidget {
  const _PaymentMethodSelector();

  @override
  State<_PaymentMethodSelector> createState() => _PaymentMethodSelectorState();
}

class _PaymentMethodSelectorState extends State<_PaymentMethodSelector> {
  static const _methods = [
    ('card', '신용/체크카드', Icons.credit_card_rounded),
    ('toss', '토스페이', Icons.account_balance_wallet_rounded),
    ('naver', '네이버페이', Icons.payments_rounded),
    ('transfer', '계좌이체', Icons.account_balance_rounded),
  ];

  String selected = 'card';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _methods.map((method) {
        final (id, label, icon) = method;
        final isSelected = selected == id;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: isSelected
                ? AppColors.primaryMint.withOpacity(0.14)
                : AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => selected = id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryMint : AppColors.borderLight,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: isSelected ? AppColors.primaryTeal : AppColors.textGrey,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: AppColors.textBlack,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: isSelected ? AppColors.primaryTeal : AppColors.borderLight,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
