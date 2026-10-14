import 'package:flutter/material.dart';

import '../onboarding/src_onboarding_controller.dart';
import 'accessory_catalog.dart';

/// 티어 동물에 소품을 입혀서 그린다. 보여 주기만 하고 아무것도 저장하지 않는다.
///
/// 모든 그림이 같은 1024 판이라 위치를 계산하지 않고 순서대로 겹친다.
/// 순서: 등 → 동물 → 하의 → 상의(+백팩 끈) → 신발 → 손 → 눈 → 머리.
/// 스킨을 입으면 동물 그림 대신 스킨 그림 한 장만 그린다.
class DressedMascot extends StatelessWidget {
  const DressedMascot({
    super.key,
    required this.animal,
    required this.worn,
    required this.size,
    this.detail = 1,
  });

  final TierAnimal animal;
  final Set<Accessory> worn;
  final double size;

  /// 확대해서 보여 줄 때 그림을 더 선명하게 읽는 배수.
  final double detail;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final px = (size * dpr * detail).ceil().clamp(96, 1024);

    Widget layer(String path) => Positioned.fill(
          child: Image.asset(
            path,
            fit: BoxFit.fill,
            cacheWidth: px,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
          ),
        );

    Accessory? at(AccessorySlot slot) {
      for (final a in worn) {
        if (a.slot == slot && a.ready) return a;
      }
      return null;
    }

    final skin = at(AccessorySlot.skin);
    final back = at(AccessorySlot.back);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (skin != null)
            layer(skin.assetPath(animal))
          else ...[
            if (back != null) layer(back.assetPath(animal)),
            layer('assets/images/characters/tier_${animal.code}.png'),
            for (final slot in accessoryDrawOrder)
              if (slot != AccessorySlot.back) ...[
                if (at(slot) case final acc?) layer(acc.assetPath(animal)),
                // 백팩 끈은 상의 위에 한 번 더 겹친다.
                if (slot == AccessorySlot.top &&
                    back?.frontAssetPath(animal) != null)
                  layer(back!.frontAssetPath(animal)!),
              ],
          ],
        ],
      ),
    );
  }
}
