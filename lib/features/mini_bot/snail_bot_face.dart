import 'package:flutter/material.dart';

/// 달팽이봇 얼굴. 같은 그림을 버튼과 대화 화면 머리글이 함께 쓴다.
enum SnailBotMood {
  /// 기본.
  smiling('assets/images/snailbot/face_smiling.png'),

  /// 마이크로 듣는 중.
  listening('assets/images/snailbot/face_listening.png'),

  /// 답했거나 이동 확인이 끝났을 때.
  joy('assets/images/snailbot/face_joy.png'),

  /// 못 알아들었거나 마이크가 안 될 때.
  disappointed('assets/images/snailbot/face_disappointed.png');

  const SnailBotMood(this.asset);

  final String asset;
}

class SnailBotFace extends StatelessWidget {
  const SnailBotFace({
    super.key,
    required this.size,
    this.mood = SnailBotMood.smiling,
  });

  final double size;
  final SnailBotMood mood;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      mood.asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
      errorBuilder: (_, __, ___) => Icon(
        Icons.chat_bubble_outline_rounded,
        size: size * 0.6,
      ),
    );
  }
}
