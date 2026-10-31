import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../l10n/surface_copy.dart';

/// 공정한 적립 정책. 문구만 있고 서버 값은 읽지 않는다.
/// 수치는 서버의 현재 기준과 같게 적는다. 서버 기준을 바꾸면 이 문구도 함께 고친다.
/// 문장은 11개 로케일의 초벌이다. 원어민 검수 전에 광고 랜딩으로 쓰지 않는다.
class FairEarningPolicyScreen extends StatelessWidget {
  const FairEarningPolicyScreen({super.key});

  static List<FairBlock> get sections =>
      FairEarningCopy.of(const Locale('ko')).sections;

  @override
  Widget build(BuildContext context) {
    final copy = FairEarningCopy.of(Localizations.localeOf(context));
    return Scaffold(
      backgroundColor: AppColors.settingsBackground,
      appBar: AppBar(
        backgroundColor: AppColors.settingsBackground,
        elevation: 0,
        foregroundColor: AppColors.textBlack,
        title: Text(
          copy.screenTitle,
          style: AppTextStyles.header1.copyWith(fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          for (final section in copy.sections) ...[
            Text(
              section.title,
              style: AppTextStyles.header1.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 8),
            for (final line in section.lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '• $line',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textBlack,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            const SizedBox(height: 18),
          ],
          Text(
            copy.footnote,
            style: AppTextStyles.caption.copyWith(color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}
