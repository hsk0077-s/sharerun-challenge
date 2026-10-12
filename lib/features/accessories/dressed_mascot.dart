import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../onboarding/src_onboarding_controller.dart';
import 'accessory_anchors.dart';
import 'accessory_catalog.dart';

/// 티어 동물에 액세서리를 입혀서 그린다. 그림 위치는 1024 판 기준 값을 [size]에 맞춰 줄인다.
/// 보여 주기만 하고 아무것도 저장하지 않는다.
class DressedMascot extends StatelessWidget {
  const DressedMascot({
    super.key,
    required this.animal,
    required this.worn,
    required this.size,
  });

  final TierAnimal animal;
  final Set<Accessory> worn;
  final double size;

  static const double _canvas = 1024;
  static const double _item = 512;

  /// 한 소품의 자리. [rect]는 돌리기 전 네모, [angle]은 시계 방향 라디안.
  @visibleForTesting
  static ({Rect rect, double angle}) placement(
    AccessoryAnchor a,
    double unit,
  ) {
    final side = _item * a.scale * unit;
    final rad = a.rotateDeg * math.pi / 180;
    // 돌려서 커진 네모의 왼쪽 위가 (x, y). 그 중심에 돌리기 전 네모를 놓는다.
    final grown = side * (math.cos(rad).abs() + math.sin(rad).abs());
    final cx = a.x * unit + grown / 2;
    final cy = a.y * unit + grown / 2;
    return (
      rect: Rect.fromCenter(center: Offset(cx, cy), width: side, height: side),
      angle: -rad,
    );
  }

  @override
  Widget build(BuildContext context) {
    final unit = size / _canvas;
    final anchors = accessoryAnchors[animal] ?? const {};

    Widget item(Accessory acc) {
      final path = acc.assetPath(animal);
      if (acc.perAnimal) {
        // 운동화·손목밴드는 판 전체 크기 그림이라 (0, 0)에 그대로 겹친다.
        return Positioned.fill(
          child: Image.asset(path, fit: BoxFit.fill, gaplessPlayback: true),
        );
      }
      final anchor = anchors[acc];
      if (anchor == null) return const SizedBox.shrink();
      final p = placement(anchor, unit);
      return Positioned.fromRect(
        rect: p.rect,
        child: Transform.rotate(
          angle: p.angle,
          child: Image.asset(path, fit: BoxFit.fill, gaplessPlayback: true),
        ),
      );
    }

    final hasHandItem = worn.any(
      (a) =>
          a == Accessory.trophy || a == Accessory.torch || a == Accessory.baton,
    );

    return SizedBox(
      key: Key('dressed-mascot-${animal.code}'),
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (worn.contains(Accessory.cape)) item(Accessory.cape),
          Positioned.fill(
            child: Image.asset(
              'assets/images/characters/tier_${animal.code}.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
            ),
          ),
          for (final slot in accessoryDrawOrder) ...[
            for (final acc in Accessory.values)
              if (acc.slot == slot && worn.contains(acc)) item(acc),
            // 손에 든 소품 위에 주먹을 덮어서 쥔 모양으로 만든다.
            if (slot == AccessorySlot.hand && hasHandItem)
              Positioned.fill(
                child: Image.asset(
                  'assets/images/accessories/fist/fist-front-${animal.code}.png',
                  fit: BoxFit.fill,
                  gaplessPlayback: true,
                ),
              ),
          ],
        ],
      ),
    );
  }
}
