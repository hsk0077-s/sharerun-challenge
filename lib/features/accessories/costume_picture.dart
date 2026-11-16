import 'package:flutter/material.dart';

import 'accessory_catalog.dart';

/// 캐릭터 의상 그림 한 장. [gender]는 'male' 또는 'female'.
/// 그림이 없거나 읽지 못하면 옷 아이콘을 보여 준다.
class CostumePicture extends StatelessWidget {
  const CostumePicture({
    super.key,
    required this.accessory,
    required this.gender,
    this.fit = BoxFit.cover,
  });

  final Accessory accessory;
  final String gender;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      accessory.characterAssetPath(gender),
      fit: fit,
      errorBuilder: (_, __, ___) => const Center(
        child: Icon(Icons.checkroom_rounded, size: 36, color: Colors.black38),
      ),
    );
  }
}
