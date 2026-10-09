import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// 공정한 적립 정책. 문구만 있고 서버 값은 읽지 않는다.
/// 수치는 서버의 현재 기준과 같게 적는다. 서버 기준을 바꾸면 이 문구도 함께 고친다.
class FairEarningPolicyScreen extends StatelessWidget {
  const FairEarningPolicyScreen({super.key});

  static const sections = <({String title, List<String> lines})>[
    (
      title: '기본 원칙',
      lines: [
        '기록은 언제나 남지만, 보상은 서버가 검증한 달리기에만 드려요.',
        '화면에 보이는 SHARE·VALUE·다이아와 기부 금액은 서버가 확인한 값이에요. '
            '어느 폰에서 로그인해도 같아요.',
        '같은 달리기는 한 번만 인정돼요.',
      ],
    ),
    (
      title: '검증 기준',
      lines: [
        '달리기 거리는 방 거리 이상이어야 하고, 최소 1km예요.',
        '러닝 케이던스는 분당 120~210보 범위여야 해요.',
        '워치가 없으면 보폭과 GPS 속도로 확인해요.',
        '심박은 상급·하프·파이널 대회에서만 필수예요.',
      ],
    ),
    (
      title: '하루 한도',
      lines: [
        '걷기: 100보마다 10 SHARE, 하루 최대 600 SHARE예요.',
        '자유 달리기: 검증을 통과하면 1km당 10 VALUE, 하루 최대 5km·50 VALUE예요.',
      ],
    ),
    (
      title: '전환 한도',
      lines: [
        'SHARE는 다이아로만 바꿀 수 있고, 다이아를 SHARE로 되돌릴 수는 없어요.',
        '전환은 일주일에 20 다이아까지, 가입 7일 뒤부터 할 수 있어요.',
        'VALUE는 환전할 수 없어요.',
      ],
    ),
    (
      title: '기부',
      lines: [
        '검증된 달리기 1km마다 100원을 회사·스폰서 이름으로 기부해요.',
        '회사 기부에는 한 달 한도가 있어요. 한도가 차면 '
            '"이번 달 기부 목표 달성"으로 알려 드려요.',
      ],
    ),
    (
      title: '기록에 이의가 있다면',
      lines: [
        '검증되지 않은 기록은 달리기 결과 화면에 이유가 나와요.',
        '결과가 맞지 않다고 생각하면 설정 > 보안·프라이버시 센터 > '
            '기록 소명 및 고객센터에서 알려 주세요.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.settingsBackground,
      appBar: AppBar(
        backgroundColor: AppColors.settingsBackground,
        elevation: 0,
        foregroundColor: AppColors.textBlack,
        title: Text(
          '공정한 적립 정책',
          style: AppTextStyles.header1.copyWith(fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          for (final section in sections) ...[
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
            '일부 수치는 서버 설정에 따라 조정될 수 있어요.',
            style: AppTextStyles.caption.copyWith(color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}
