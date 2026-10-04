import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../pedometer/kst_calendar.dart';
import '../donation_match_line.dart';
import '../providers/donation_match_provider.dart';

/// Server-confirmed company match for this account. Empty when there is none.
class DonationMatchContribution extends ConsumerWidget {
  const DonationMatchContribution({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(donationMatchProvider).asData?.value ?? const [];
    final monthKey = KstCalendar.dateKey().substring(0, 7);
    final line = donationMatchSummary(entries, monthKey);
    if (line.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        line,
        key: const Key('donation-match-contribution'),
        style: AppTextStyles.caption.copyWith(
          fontSize: 12,
          height: 1.35,
          color: AppColors.textGrey,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
