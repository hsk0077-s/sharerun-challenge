import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../onboarding/src_onboarding_controller.dart';

/// 홈 프로필 사진 옆에 놓는 동그란 등급 배지. 사진과 같은 크기의 원 안에 캐릭터를 크게 넣고
/// 아래에 등급 이름을 쓴다. 누르면 [onTap].
class TierCircleBadge extends StatelessWidget {
  const TierCircleBadge({
    super.key,
    required this.imagePath,
    required this.label,
    required this.borderColor,
    required this.size,
    required this.onTap,
    this.subLabel,
    this.fallbackEmoji,
  });

  final String imagePath;
  final String label;

  /// 작은 둘째 줄(예: 메달 이름). 없으면 쓰지 않는다.
  final String? subLabel;
  final Color borderColor;
  final double size;
  final VoidCallback onTap;
  final String? fallbackEmoji;

  /// 원 안에서 캐릭터를 키우는 배율. 그림 가장자리의 빈 곳을 채워 원이 꽉 차 보이게 한다.
  static const imageScale = 1.25;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: subLabel == null ? label : '$label $subLabel',
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(size / 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: borderColor, width: 2),
                  ),
                  child: ClipOval(
                    child: Transform.scale(
                      scale: imageScale,
                      child: Image.asset(
                        imagePath,
                        width: size,
                        height: size,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            fallbackEmoji ?? '',
                            style: TextStyle(fontSize: size * 0.45),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    color: AppColors.textBlack,
                  ),
                ),
                if (subLabel != null)
                  Text(
                    subLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      height: 1.15,
                      color: AppColors.textGrey,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 홈, 공유 카드에서 같이 쓰는 두 등급의 이름과 그림.
extension TierCircleLabels on UserTier {
  /// 동물 이름만. 달팽이는 '달팽이'.
  String get circleLabel => isSnail ? '달팽이' : animal.labelKo;

  /// 둘째 줄: 메달 이름. 달팽이는 없다.
  String? get circleSubLabel => isSnail ? null : medal.labelKo;
}

extension AngelCircleLabels on AngelTier {
  /// 원 아래에 쓰는 짧은 이름. 예비 천사는 괄호 영문을 뺀다.
  String get circleLabel => this == AngelTier.preAngel ? '예비 천사' : koreanName;
}
