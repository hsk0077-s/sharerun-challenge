import 'package:flutter/material.dart';

import '../../l10n/remaining_surface.dart';
import 'world_tour_models.dart';

/// Display data for one landmark: a flat colour with an icon for now, and the
/// translated names and story lines. The mission list itself (ids, targets,
/// progress) comes from the server.
///
/// All 13 landmarks have drawn pictures (see [WorldTourLandmark.hasArt]); the
/// flat colour + icon is only the fallback. No photo is used. The ids must match
/// the `landmarkId` of the server missions (backend/jena_ai/app/services/world_tour.py).
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
  static const bigBen = WorldTourLandmark(
    id: 'big_ben',
    icon: Icons.access_time,
    color: Color(0xFF8A3B3B),
  );
  static const liberty = WorldTourLandmark(
    id: 'statue_of_liberty',
    icon: Icons.emoji_flags,
    color: Color(0xFF3E8E7E),
  );
  static const gwanghwamun = WorldTourLandmark(
    id: 'gwanghwamun',
    icon: Icons.fort,
    color: Color(0xFF2F5D8A),
  );
  static const taroko = WorldTourLandmark(
    id: 'taroko_gorge',
    icon: Icons.landscape,
    color: Color(0xFF3E9C9A),
  );
  static const alhambra = WorldTourLandmark(
    id: 'alhambra',
    icon: Icons.castle,
    color: Color(0xFFC0713A),
  );
  static const iguazu = WorldTourLandmark(
    id: 'iguazu_falls',
    icon: Icons.water,
    color: Color(0xFF2E7D4F),
  );
  static const neuschwanstein = WorldTourLandmark(
    id: 'neuschwanstein',
    icon: Icons.castle,
    color: Color(0xFF5C7FA8),
  );
  static const halong = WorldTourLandmark(
    id: 'ha_long_bay',
    icon: Icons.sailing,
    color: Color(0xFF2E9E8F),
  );
  static const ayutthaya = WorldTourLandmark(
    id: 'ayutthaya',
    icon: Icons.account_balance,
    color: Color(0xFFC2603A),
  );
  static const bali = WorldTourLandmark(
    id: 'bali_rice_terraces',
    icon: Icons.grass,
    color: Color(0xFF7FAE3A),
  );
  static const unknown = WorldTourLandmark(
    id: '',
    icon: Icons.public,
    color: Color(0xFF5B6770),
  );

  static const all = [
    eiffel,
    taj,
    fuji,
    bigBen,
    liberty,
    gwanghwamun,
    taroko,
    alhambra,
    iguazu,
    neuschwanstein,
    halong,
    ayutthaya,
    bali,
  ];

  /// Landmarks that have their four scene pictures in
  /// `assets/images/world_tour/`.
  static const artIds = {
    'eiffel_tower',
    'taj_mahal',
    'mount_fuji',
    'big_ben',
    'statue_of_liberty',
    'gwanghwamun',
    'taroko_gorge',
    'alhambra',
    'iguazu_falls',
    'neuschwanstein',
    'ha_long_bay',
    'ayutthaya',
    'bali_rice_terraces',
  };

  bool get hasArt => artIds.contains(id);

  /// Asset path of [scene] for this landmark, or null when it has no picture.
  String? artAsset(WorldTourArtScene scene) =>
      hasArt ? 'assets/images/world_tour/${id}_${scene.fileSuffix}.webp' : null;

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
      case 'big_ben':
        return RemainingSurface.tr(context, 'wt.big_ben.name', '영국 런던 빅벤');
      case 'statue_of_liberty':
        return RemainingSurface.tr(context, 'wt.liberty.name', '미국 자유의 여신상');
      case 'gwanghwamun':
        return RemainingSurface.tr(context, 'wt.gwanghwamun.name', '한국 서울 광화문');
      case 'taroko_gorge':
        return RemainingSurface.tr(
          context,
          'wt.taroko_gorge.name',
          '대만 타이루거 협곡',
        );
      case 'alhambra':
        return RemainingSurface.tr(context, 'wt.alhambra.name', '스페인 알람브라 궁전');
      case 'iguazu_falls':
        return RemainingSurface.tr(
          context,
          'wt.iguazu_falls.name',
          '브라질 이구아수 폭포',
        );
      case 'neuschwanstein':
        return RemainingSurface.tr(
          context,
          'wt.neuschwanstein.name',
          '독일 노이슈반슈타인 성',
        );
      case 'ha_long_bay':
        return RemainingSurface.tr(context, 'wt.ha_long_bay.name', '베트남 하롱베이');
      case 'ayutthaya':
        return RemainingSurface.tr(context, 'wt.ayutthaya.name', '태국 아유타야 유적');
      case 'bali_rice_terraces':
        return RemainingSurface.tr(
          context,
          'wt.bali_rice_terraces.name',
          '인도네시아 발리 계단식 논',
        );
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
      case 'big_ben':
        return RemainingSurface.tr(context, 'wt.big_ben.short', '빅벤');
      case 'statue_of_liberty':
        return RemainingSurface.tr(context, 'wt.liberty.short', '자유의 여신상');
      case 'gwanghwamun':
        return RemainingSurface.tr(context, 'wt.gwanghwamun.short', '광화문');
      case 'taroko_gorge':
        return RemainingSurface.tr(context, 'wt.taroko_gorge.short', '타이루거');
      case 'alhambra':
        return RemainingSurface.tr(context, 'wt.alhambra.short', '알람브라');
      case 'iguazu_falls':
        return RemainingSurface.tr(context, 'wt.iguazu_falls.short', '이구아수');
      case 'neuschwanstein':
        return RemainingSurface.tr(
          context,
          'wt.neuschwanstein.short',
          '노이슈반슈타인',
        );
      case 'ha_long_bay':
        return RemainingSurface.tr(context, 'wt.ha_long_bay.short', '하롱베이');
      case 'ayutthaya':
        return RemainingSurface.tr(context, 'wt.ayutthaya.short', '아유타야');
      case 'bali_rice_terraces':
        return RemainingSurface.tr(
          context,
          'wt.bali_rice_terraces.short',
          '발리',
        );
    }
    return fallback;
  }

  /// The three story lines: start, middle, arrival. Text only.
  List<String> story(BuildContext? context) {
    switch (id) {
      case 'eiffel_tower':
        return [
          RemainingSurface.tr(
            context,
            'wt.eiffel.start',
            '파리의 아침, 센 강변에서 가볍게 출발해요.',
          ),
          RemainingSurface.tr(
            context,
            'wt.eiffel.mid',
            '강바람을 맞으며 철탑이 점점 가까워져요.',
          ),
          RemainingSurface.tr(
            context,
            'wt.eiffel.arrive',
            '에펠탑 앞에 도착! 파리를 달렸어요.',
          ),
        ];
      case 'taj_mahal':
        return [
          RemainingSurface.tr(
            context,
            'wt.taj.start',
            '아그라의 이른 아침, 흰 대리석 궁전을 향해 출발해요.',
          ),
          RemainingSurface.tr(context, 'wt.taj.mid', '정원 길을 따라 돔이 조금씩 커져요.'),
          RemainingSurface.tr(
            context,
            'wt.taj.arrive',
            '타지마할 앞에 도착! 인도를 달렸어요.',
          ),
        ];
      case 'mount_fuji':
        return [
          RemainingSurface.tr(context, 'wt.fuji.start', '호숫가에서 산을 바라보며 출발해요.'),
          RemainingSurface.tr(
            context,
            'wt.fuji.mid',
            '숲길을 지나자 눈 덮인 봉우리가 가까워져요.',
          ),
          RemainingSurface.tr(
            context,
            'wt.fuji.arrive',
            '후지산 기슭에 도착! 일본을 달렸어요.',
          ),
        ];
      case 'big_ben':
        return [
          RemainingSurface.tr(
            context,
            'wt.big_ben.start',
            '회색 구름 아래 템스강 공원에서 출발해요.',
          ),
          RemainingSurface.tr(
            context,
            'wt.big_ben.mid',
            '강 건너편에 고딕 시계탑이 보이기 시작해요.',
          ),
          RemainingSurface.tr(
            context,
            'wt.big_ben.arrive',
            '빅벤 앞에 도착! 런던을 달렸어요.',
          ),
        ];
      case 'statue_of_liberty':
        return [
          RemainingSurface.tr(
            context,
            'wt.liberty.start',
            '뉴욕 항구의 바람을 맞으며 출발해요.',
          ),
          RemainingSurface.tr(context, 'wt.liberty.mid', '물결 너머로 횃불이 반짝여요.'),
          RemainingSurface.tr(
            context,
            'wt.liberty.arrive',
            '자유의 여신상 앞에 도착! 미국을 달렸어요.',
          ),
        ];
      case 'gwanghwamun':
        return [
          RemainingSurface.tr(
            context,
            'wt.gwanghwamun.start',
            '서울의 이른 아침, 광화문광장에서 가볍게 출발해요.',
          ),
          RemainingSurface.tr(
            context,
            'wt.gwanghwamun.mid',
            '넓은 길 끝으로 기와지붕 문이 보이기 시작해요.',
          ),
          RemainingSurface.tr(
            context,
            'wt.gwanghwamun.arrive',
            '광화문 앞에 도착! 한국 서울을 달렸어요.',
          ),
        ];
      case 'taroko_gorge':
        return [
          RemainingSurface.tr(
            context,
            'wt.taroko_gorge.start',
            '대만 화롄의 맑은 아침, 협곡 입구에서 출발해요.',
          ),
          RemainingSurface.tr(
            context,
            'wt.taroko_gorge.mid',
            '푸른 물길 옆으로 대리석 절벽이 가까워져요.',
          ),
          RemainingSurface.tr(
            context,
            'wt.taroko_gorge.arrive',
            '타이루거 협곡에 도착! 대만을 달렸어요.',
          ),
        ];
      case 'alhambra':
        return [
          RemainingSurface.tr(
            context,
            'wt.alhambra.start',
            '그라나다의 아침 햇살 속에서 출발해요.',
          ),
          RemainingSurface.tr(
            context,
            'wt.alhambra.mid',
            '언덕 위로 붉은 성벽이 보이기 시작해요.',
          ),
          RemainingSurface.tr(
            context,
            'wt.alhambra.arrive',
            '알람브라 궁전 앞에 도착! 스페인을 달렸어요.',
          ),
        ];
      case 'iguazu_falls':
        return [
          RemainingSurface.tr(
            context,
            'wt.iguazu_falls.start',
            '열대 숲길에서 물소리를 들으며 출발해요.',
          ),
          RemainingSurface.tr(
            context,
            'wt.iguazu_falls.mid',
            '안개 너머로 폭포 소리가 점점 커져요.',
          ),
          RemainingSurface.tr(
            context,
            'wt.iguazu_falls.arrive',
            '이구아수 폭포 앞에 도착! 브라질을 달렸어요.',
          ),
        ];
      case 'neuschwanstein':
        return [
          RemainingSurface.tr(
            context,
            'wt.neuschwanstein.start',
            '알프스 자락의 숲길에서 출발해요.',
          ),
          RemainingSurface.tr(
            context,
            'wt.neuschwanstein.mid',
            '나무 사이로 하얀 성탑이 보이기 시작해요.',
          ),
          RemainingSurface.tr(
            context,
            'wt.neuschwanstein.arrive',
            '노이슈반슈타인 성 앞에 도착! 독일을 달렸어요.',
          ),
        ];
      case 'ha_long_bay':
        return [
          RemainingSurface.tr(
            context,
            'wt.ha_long_bay.start',
            '잔잔한 바닷가에서 아침 안개 속으로 출발해요.',
          ),
          RemainingSurface.tr(
            context,
            'wt.ha_long_bay.mid',
            '안개 너머로 바위섬들이 하나둘 나타나요.',
          ),
          RemainingSurface.tr(
            context,
            'wt.ha_long_bay.arrive',
            '하롱베이에 도착! 베트남을 달렸어요.',
          ),
        ];
      case 'ayutthaya':
        return [
          RemainingSurface.tr(
            context,
            'wt.ayutthaya.start',
            '이른 아침, 오래된 벽돌 길에서 출발해요.',
          ),
          RemainingSurface.tr(
            context,
            'wt.ayutthaya.mid',
            '나무 사이로 오래된 탑이 보이기 시작해요.',
          ),
          RemainingSurface.tr(
            context,
            'wt.ayutthaya.arrive',
            '아유타야 유적 앞에 도착! 태국을 달렸어요.',
          ),
        ];
      case 'bali_rice_terraces':
        return [
          RemainingSurface.tr(
            context,
            'wt.bali_rice_terraces.start',
            '발리의 푸른 아침, 논길에서 출발해요.',
          ),
          RemainingSurface.tr(
            context,
            'wt.bali_rice_terraces.mid',
            '계단처럼 이어진 초록 논이 펼쳐져요.',
          ),
          RemainingSurface.tr(
            context,
            'wt.bali_rice_terraces.arrive',
            '발리 계단식 논에 도착! 인도네시아를 달렸어요.',
          ),
        ];
    }
    return const [];
  }
}

/// Which picture of a landmark to show. The three approach scenes follow the
/// three story lines (start / middle / arrival); [poster] is only the
/// background of the arrival share card.
enum WorldTourArtScene {
  far('approach_far'),
  mid('approach_mid'),
  close('approach_close'),
  poster('poster');

  const WorldTourArtScene(this.fileSuffix);

  final String fileSuffix;

  /// Not started, or under a third of the way: far. Under way: mid.
  /// Finished: close.
  static WorldTourArtScene forMission(WorldTourMission mission) {
    if (mission.completed) return close;
    if (!mission.started || mission.progressKm * 3 < mission.targetKm) {
      return far;
    }
    return mid;
  }
}

/// Landmark picture card. Landmarks with a drawn picture show the WebP for
/// [scene]; the others (and a picture that fails to load) show a flat colour
/// with the landmark icon. Height, corners and [dimmed] behave the same either
/// way.
class WorldTourLandmarkArt extends StatelessWidget {
  const WorldTourLandmarkArt({
    required this.landmark,
    this.scene = WorldTourArtScene.far,
    this.height = 120,
    this.dimmed = false,
    this.radius = 16,
    super.key,
  });

  final WorldTourLandmark landmark;
  final WorldTourArtScene scene;
  final double height;
  final bool dimmed;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final asset = landmark.artAsset(scene);
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: asset == null
            ? _placeholder()
            : ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: ColoredBox(
                  color: landmark.color,
                  child: Opacity(
                    opacity: dimmed ? 0.45 : 1,
                    child: Image.asset(
                      asset,
                      key: ValueKey(asset),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _placeholder() {
    final base = landmark.color;
    return Container(
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
    );
  }
}
