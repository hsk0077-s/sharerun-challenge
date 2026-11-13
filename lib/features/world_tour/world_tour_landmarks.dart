import 'package:flutter/material.dart';

import '../../l10n/remaining_surface.dart';

/// Display data for one landmark: a flat colour with an icon for now, and the
/// translated names and story lines. The mission list itself (ids, targets,
/// progress) comes from the server.
///
/// TODO(art): replace [WorldTourLandmarkArt] with the hand-drawn illustrations
/// (see docs/world-tour-mvp.md for the list). No photo is used.
class WorldTourLandmark {
  const WorldTourLandmark({
    required this.id,
    required this.icon,
    required this.color,
  });

  final String id;
  final IconData icon;
  final Color color;

  static const eiffel = WorldTourLandmark(
    id: 'eiffel_tower',
    icon: Icons.cell_tower,
    color: Color(0xFF3B5B8C),
  );
  static const taj = WorldTourLandmark(
    id: 'taj_mahal',
    icon: Icons.account_balance,
    color: Color(0xFFB5626B),
  );
  static const fuji = WorldTourLandmark(
    id: 'mount_fuji',
    icon: Icons.terrain,
    color: Color(0xFF4F8FA3),
  );
  static const pyramids = WorldTourLandmark(
    id: 'pyramids',
    icon: Icons.change_history,
    color: Color(0xFFC9954C),
  );
  static const liberty = WorldTourLandmark(
    id: 'statue_of_liberty',
    icon: Icons.emoji_flags,
    color: Color(0xFF3E8E7E),
  );
  static const unknown = WorldTourLandmark(
    id: '',
    icon: Icons.public,
    color: Color(0xFF5B6770),
  );

  static const all = [eiffel, taj, fuji, pyramids, liberty];

  static WorldTourLandmark of(String landmarkId) {
    for (final landmark in all) {
      if (landmark.id == landmarkId) return landmark;
    }
    return unknown;
  }

  /// "프랑스 에펠탑". [fallback] is the server title for an unknown landmark.
  String name(BuildContext? context, {String fallback = ''}) {
    switch (id) {
      case 'eiffel_tower':
        return RemainingSurface.tr(context, 'wt.eiffel.name', '프랑스 에펠탑');
      case 'taj_mahal':
        return RemainingSurface.tr(context, 'wt.taj.name', '인도 타지마할');
      case 'mount_fuji':
        return RemainingSurface.tr(context, 'wt.fuji.name', '일본 후지산');
      case 'pyramids':
        return RemainingSurface.tr(context, 'wt.pyramids.name', '이집트 피라미드');
      case 'statue_of_liberty':
        return RemainingSurface.tr(
            context, 'wt.liberty.name', '미국 자유의 여신상');
    }
    return fallback;
  }

  /// "에펠탑", for "에펠탑까지 0.35km 남음".
  String shortName(BuildContext? context, {String fallback = ''}) {
    switch (id) {
      case 'eiffel_tower':
        return RemainingSurface.tr(context, 'wt.eiffel.short', '에펠탑');
      case 'taj_mahal':
        return RemainingSurface.tr(context, 'wt.taj.short', '타지마할');
      case 'mount_fuji':
        return RemainingSurface.tr(context, 'wt.fuji.short', '후지산');
      case 'pyramids':
        return RemainingSurface.tr(context, 'wt.pyramids.short', '피라미드');
      case 'statue_of_liberty':
        return RemainingSurface.tr(context, 'wt.liberty.short', '자유의 여신상');
    }
    return fallback;
  }

  /// The three story lines: start, middle, arrival. Text only.
  List<String> story(BuildContext? context) {
    switch (id) {
      case 'eiffel_tower':
        return [
          RemainingSurface.tr(
              context, 'wt.eiffel.start', '파리의 아침, 센 강변에서 가볍게 출발해요.'),
          RemainingSurface.tr(
              context, 'wt.eiffel.mid', '강바람을 맞으며 철탑이 점점 가까워져요.'),
          RemainingSurface.tr(
              context, 'wt.eiffel.arrive', '에펠탑 앞에 도착! 파리를 달렸어요.'),
        ];
      case 'taj_mahal':
        return [
          RemainingSurface.tr(context, 'wt.taj.start',
              '아그라의 이른 아침, 흰 대리석 궁전을 향해 출발해요.'),
          RemainingSurface.tr(
              context, 'wt.taj.mid', '정원 길을 따라 돔이 조금씩 커져요.'),
          RemainingSurface.tr(
              context, 'wt.taj.arrive', '타지마할 앞에 도착! 인도를 달렸어요.'),
        ];
      case 'mount_fuji':
        return [
          RemainingSurface.tr(
              context, 'wt.fuji.start', '호숫가에서 산을 바라보며 출발해요.'),
          RemainingSurface.tr(
              context, 'wt.fuji.mid', '숲길을 지나자 눈 덮인 봉우리가 가까워져요.'),
          RemainingSurface.tr(
              context, 'wt.fuji.arrive', '후지산 기슭에 도착! 일본을 달렸어요.'),
        ];
      case 'pyramids':
        return [
          RemainingSurface.tr(
              context, 'wt.pyramids.start', '사막의 아침 햇살 속에서 출발해요.'),
          RemainingSurface.tr(
              context, 'wt.pyramids.mid', '모래 언덕 너머로 거대한 삼각형이 보여요.'),
          RemainingSurface.tr(
              context, 'wt.pyramids.arrive', '피라미드 앞에 도착! 이집트를 달렸어요.'),
        ];
      case 'statue_of_liberty':
        return [
          RemainingSurface.tr(
              context, 'wt.liberty.start', '뉴욕 항구의 바람을 맞으며 출발해요.'),
          RemainingSurface.tr(
              context, 'wt.liberty.mid', '물결 너머로 횃불이 반짝여요.'),
          RemainingSurface.tr(context, 'wt.liberty.arrive',
              '자유의 여신상 앞에 도착! 미국을 달렸어요.'),
        ];
    }
    return const [];
  }
}

/// Placeholder card: a flat colour with the landmark icon. Swapped for the
/// drawn illustration later; the size and corners stay the same.
class WorldTourLandmarkArt extends StatelessWidget {
  const WorldTourLandmarkArt({
    required this.landmark,
    this.height = 120,
    this.dimmed = false,
    this.radius = 16,
    super.key,
  });

  final WorldTourLandmark landmark;
  final double height;
  final bool dimmed;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final base = landmark.color;
    return ExcludeSemantics(
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: dimmed ? base.withValues(alpha: 0.45) : base,
          borderRadius: BorderRadius.circular(radius),
        ),
        alignment: Alignment.center,
        child: Icon(
          landmark.icon,
          size: height.isFinite ? height * 0.5 : 56,
          color: Colors.white.withValues(alpha: dimmed ? 0.7 : 0.95),
        ),
      ),
    );
  }
}
