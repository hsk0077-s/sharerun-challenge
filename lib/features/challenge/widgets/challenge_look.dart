import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';

/// 챌린지 탭 세 화면이 같이 쓰는 작은 글자 조각.
/// 지도(화면 이동 지도)의 작은 영문 라벨과 구역 제목 모양이다.
class ChallengeTag extends StatelessWidget {
  const ChallengeTag(this.text, {this.color, super.key});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color ?? tokens.colors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
            height: 1.0,
          ),
    );
  }
}

class ChallengeSectionLabel extends StatelessWidget {
  const ChallengeSectionLabel(this.text, {this.trailing, super.key});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Text(
            text,
            style: textTheme.titleMedium?.copyWith(
              color: tokens.colors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          if (trailing != null)
            Text(
              trailing!,
              style: textTheme.labelMedium?.copyWith(
                color: tokens.colors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}
