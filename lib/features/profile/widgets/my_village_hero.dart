import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme.dart';
import '../../accessories/accessory_catalog.dart';
import '../../accessories/accessory_inventory.dart';
import '../../accessories/dressed_mascot.dart';
import '../../onboarding/src_onboarding_controller.dart';
import '../village_scene.dart';

/// 마이 탭 맨 위 마을 풍경. 하늘, 겹친 언덕, 굽이치는 길, 나무, 깃발을 그린다.
/// 가운데에 내 티어 동물, 양옆에 나머지 동물 친구들이 선다.
class MyVillageHero extends StatelessWidget {
  const MyVillageHero({
    required this.tier,
    required this.onSettings,
    this.onChangeVillage,
    this.scene = defaultVillageScene,
    this.height = 250,
    super.key,
  });

  final UserTier tier;
  final VoidCallback onSettings;

  /// null 이면 마을 바꾸기 버튼을 숨긴다.
  final VoidCallback? onChangeVillage;
  final VillageScene scene;
  final double height;

  static String _asset(TierAnimal a) =>
      'assets/images/characters/tier_${a.code}.png';

  /// 내 동물을 뺀 친구들. 다섯 마리가 남으면(달팽이일 때) 가운데 늑대를 뺀다.
  static List<TierAnimal> friendsOf(TierAnimal mine) {
    final all = [
      TierAnimal.turtle,
      TierAnimal.beagle,
      TierAnimal.wolf,
      TierAnimal.zebra,
      TierAnimal.cheetah,
    ].where((a) => a != mine).toList();
    if (all.length > 4) all.remove(TierAnimal.wolf);
    return all;
  }

  @override
  Widget build(BuildContext context) {
    final fg = scene.asset == null ? AppColors.nightOnLime : Colors.white;
    final friends = friendsOf(tier.animal);
    final left = friends.take(2).toList();
    final right = friends.skip(2).take(2).toList();
    Widget friend(TierAnimal a, double size) => Image.asset(
          _asset(a),
          width: size,
          height: size,
          fit: BoxFit.contain,
        );
    return SizedBox(
      key: const Key('my-village-hero'),
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(40)),
              child: scene.asset == null
                  ? const CustomPaint(painter: VillagePainter())
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        // 세로로 긴 그림이라 길과 건물이 있는 아래쪽을 보여 준다.
                        Image.asset(
                          scene.asset!,
                          key: Key('my-village-bg-${scene.id}'),
                          fit: BoxFit.cover,
                          alignment: Alignment.bottomCenter,
                          cacheWidth: 1080,
                        ),
                        // 위쪽 글자와 버튼이 어떤 그림에서도 읽히게 살짝 어둡게 한다.
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.center,
                              colors: [Color(0x99000000), Color(0x00000000)],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (left.isNotEmpty)
            Positioned(left: 12, bottom: 26, child: friend(left[0], 62)),
          if (left.length > 1)
            Positioned(left: 64, bottom: 12, child: friend(left[1], 68)),
          if (right.isNotEmpty)
            Positioned(right: 62, bottom: 12, child: friend(right[0], 68)),
          if (right.length > 1)
            Positioned(right: 10, bottom: 26, child: friend(right[1], 62)),
          Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            child: Center(
              child: Consumer(
                builder: (context, ref, _) {
                  final worn = ref.watch(wornAccessoriesProvider);
                  if (worn.isNotEmpty && !tier.isSnail && canDress(tier.animal)) {
                    return DressedMascot(
                      animal: tier.animal,
                      worn: worn,
                      size: 150,
                    );
                  }
                  return Image.asset(
                    tier.avatarAssetPath,
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 22,
            right: 22,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Text(
                      'MY VILLAGE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: fg,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.2,
                          ),
                    ),
                    const Spacer(),
                    if (onChangeVillage != null)
                      IconButton(
                        key: const Key('my-village-change'),
                        onPressed: onChangeVillage,
                        tooltip: '마을 바꾸기',
                        icon: Icon(
                          Icons.landscape_outlined,
                          color: fg,
                          size: 22,
                        ),
                      ),
                    IconButton(
                      key: const Key('my-page-settings'),
                      onPressed: onSettings,
                      tooltip: AppStrings.myPageSettings,
                      icon: Icon(
                        Icons.settings_outlined,
                        color: fg,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 나눔 마을 풍경.
class VillagePainter extends CustomPainter {
  const VillagePainter({this.flag = true});

  final bool flag;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    c.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFBFE4FF), Color(0xFFE3F6E6)],
        ).createShader(Offset.zero & s),
    );
    // 구름
    final cl = Paint()..color = Colors.white.withValues(alpha: 0.85);
    for (final (x, y, r) in [
      (0.14, 0.14, 16.0),
      (0.19, 0.12, 20.0),
      (0.24, 0.15, 14.0),
      (0.78, 0.2, 14.0),
      (0.83, 0.18, 18.0),
      (0.88, 0.21, 12.0),
    ]) {
      c.drawCircle(Offset(w * x, h * y), r, cl);
    }
    // 먼 언덕
    final far = Path()
      ..moveTo(0, h * 0.52)
      ..quadraticBezierTo(w * 0.25, h * 0.36, w * 0.55, h * 0.5)
      ..quadraticBezierTo(w * 0.8, h * 0.6, w, h * 0.45)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    c.drawPath(far, Paint()..color = const Color(0xFFA9E3B0));
    // 나무
    final trunk = Paint()..color = const Color(0xFF8A6A4A);
    for (final (x, y, r, col) in [
      (0.1, 0.5, 15.0, 0xFF5CBF7A),
      (0.18, 0.52, 11.0, 0xFF73CC8A),
      (0.86, 0.47, 14.0, 0xFF5CBF7A),
      (0.93, 0.5, 10.0, 0xFF73CC8A),
    ]) {
      c.drawRect(
        Rect.fromCenter(
          center: Offset(w * x, h * y + r),
          width: 4,
          height: r * 0.9,
        ),
        trunk,
      );
      c.drawCircle(Offset(w * x, h * y), r, Paint()..color = Color(col));
    }
    // 앞 언덕
    final near = Path()
      ..moveTo(0, h * 0.72)
      ..quadraticBezierTo(w * 0.3, h * 0.58, w * 0.62, h * 0.7)
      ..quadraticBezierTo(w * 0.85, h * 0.78, w, h * 0.66)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    c.drawPath(near, Paint()..color = const Color(0xFF7ACB86));
    // 길
    final road = Path()
      ..moveTo(w * 0.47, h * 0.5)
      ..cubicTo(w * 0.62, h * 0.58, w * 0.4, h * 0.7, w * 0.36, h * 0.82)
      ..cubicTo(w * 0.34, h * 0.9, w * 0.3, h * 0.96, w * 0.28, h)
      ..lineTo(w * 0.72, h)
      ..cubicTo(w * 0.68, h * 0.92, w * 0.62, h * 0.84, w * 0.6, h * 0.78)
      ..cubicTo(w * 0.62, h * 0.66, w * 0.54, h * 0.58, w * 0.5, h * 0.5)
      ..close();
    c.drawPath(road, Paint()..color = const Color(0xFFF7E8C8));
    if (flag) {
      final pole = Paint()
        ..color = const Color(0xFF6B5A3E)
        ..strokeWidth = 2.5;
      c.drawLine(Offset(w * 0.485, h * 0.5), Offset(w * 0.485, h * 0.38), pole);
      c.drawPath(
        Path()
          ..moveTo(w * 0.485, h * 0.38)
          ..lineTo(w * 0.485 + 22, h * 0.405)
          ..lineTo(w * 0.485, h * 0.43)
          ..close(),
        Paint()..color = const Color(0xFFFF6B6B),
      );
    }
    // 하트 반짝임
    final hp = Paint()..color = const Color(0xFFFF8FB3);
    for (final (x, y) in [(0.28, 0.3), (0.72, 0.36), (0.9, 0.3)]) {
      c.drawCircle(Offset(w * x - 3, h * y), 4, hp);
      c.drawCircle(Offset(w * x + 3, h * y), 4, hp);
      c.drawPath(
        Path()
          ..moveTo(w * x - 7, h * y + 2)
          ..lineTo(w * x, h * y + 11)
          ..lineTo(w * x + 7, h * y + 2)
          ..close(),
        hp,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
