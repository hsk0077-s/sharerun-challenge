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
          subtitle: const Text('고정 상금을 직접 지원해요. 내기 요소는 없어요.'),
        ),
        RadioListTile<SponsorPaymentOption>(
          value: SponsorPaymentOption.winnerNamedUnicefDonation,
          groupValue: value,
          activeColor: AppColors.neonLime,
          onChanged: _handleChanged,
          title: const Text('옵션 B: 운영자 이름으로 기부'),
          subtitle: const Text('후원은 운영자 이름으로 기부돼요. 내 기여는 앱에서 확인해요.'),
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
