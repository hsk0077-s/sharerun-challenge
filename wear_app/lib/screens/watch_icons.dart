import 'package:flutter/material.dart';

/// 워치 아이콘. 그림 파일(`assets/images/watch/<이름>.png`, 192×192 투명 PNG 한 장)을 쓰고,
/// 파일이 없을 때만 기본 아이콘을 그린다(그림을 빼도 화면이 깨지지 않게).
/// 달리며 쌓이는 표시는 SHARE뿐이다. 다이아 아이콘은 없다.
abstract final class WatchIconNames {
  static const tierSnail = 'icon_tier_snail';
  static const tierTurtle = 'icon_tier_turtle';
  static const tierBeagle = 'icon_tier_beagle';
  static const tierWolf = 'icon_tier_wolf';
  static const tierZebra = 'icon_tier_zebra';
  static const tierCheetah = 'icon_tier_cheetah';
  static const share = 'icon_share';
  static const play = 'btn_play';
  static const pause = 'btn_pause';
  static const stop = 'btn_stop';
  static const gps = 'icon_gps';
  static const heartRate = 'icon_hr';

  /// 티어 동물 코드(`turtle` …)의 아이콘 이름. 모르는 코드면 null.
  static String? tier(String? code) => switch (code) {
        'snail' => tierSnail,
        'turtle' => tierTurtle,
        'beagle' => tierBeagle,
        'wolf' => tierWolf,
        'zebra' => tierZebra,
        'cheetah' => tierCheetah,
        _ => null,
      };
}

class WatchIcon extends StatelessWidget {
  const WatchIcon(
    this.name, {
    required this.size,
    required this.fallback,
    this.color = Colors.white,
    super.key,
  });

  final String name;
  final double size;
  final IconData fallback;
  final Color color;

  static String path(String name) => 'assets/images/watch/$name.png';

  @override
  Widget build(BuildContext context) => Image.asset(
        path(name),
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => Icon(fallback, size: size, color: color),
      );
}
