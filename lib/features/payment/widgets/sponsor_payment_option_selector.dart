import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../data/models/sponsor_model.dart';

class SponsorPaymentOptionSelector extends StatelessWidget {
  const SponsorPaymentOptionSelector({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final SponsorPaymentOption value;
  final ValueChanged<SponsorPaymentOption> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RadioListTile<SponsorPaymentOption>(
          value: SponsorPaymentOption.directPrizeSupport,
          groupValue: value,
          activeColor: AppColors.neonLime,
          onChanged: _handleChanged,
          title: const Text('옵션 A: 상금 직접 지원'),
          subtitle: const Text('Fixed-prize tournament support without wagering mechanics.'),
        ),
        RadioListTile<SponsorPaymentOption>(
          value: SponsorPaymentOption.winnerNamedUnicefDonation,
          groupValue: value,
          activeColor: AppColors.neonLime,
          onChanged: _handleChanged,
          title: const Text('옵션 B: 우승자 명의 유니세프 전액 기부'),
          subtitle: const Text('Sponsor funds are donated under the winner impact flow.'),
        ),
      ],
    );
  }

  void _handleChanged(SponsorPaymentOption? option) {
    if (option != null) {
      onChanged(option);
    }
  }
}
