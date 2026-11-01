import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/remaining_surface.dart';
import '../../l10n/surface_rest.dart';

/// Cosmetic Home-header avatar. Independent of walking-mascot / pay-to-win.
@immutable
class AvatarChoice {
  const AvatarChoice({
    required this.presetId,
    this.photoBase64,
  });

  static const photoId = 'photo';
  static const maleId = 'male';
  static const femaleId = 'female';

  final String presetId;
  final String? photoBase64;

  bool get isPhoto =>
      presetId == photoId && photoBase64 != null && photoBase64!.isNotEmpty;

  Uint8List? get photoBytes {
    final raw = photoBase64;
    if (raw == null || raw.isEmpty) return null;
    try {
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  AvatarChoice copyWith({
    String? presetId,
    String? photoBase64,
    bool clearPhoto = false,
  }) {
    return AvatarChoice(
      presetId: presetId ?? this.presetId,
      photoBase64: clearPhoto ? null : (photoBase64 ?? this.photoBase64),
    );
  }

  Map<String, String> toPrefs() {
    return {
      'presetId': presetId,
      if (photoBase64 != null && photoBase64!.isNotEmpty)
        'photoBase64': photoBase64!,
    };
  }

  factory AvatarChoice.fromPrefs(Map<String, String> raw) {
    final id = (raw['presetId'] ?? '').trim();
    return AvatarChoice(
      presetId: id.isEmpty ? maleId : id,
      photoBase64: raw['photoBase64'],
    );
  }

  factory AvatarChoice.fromGender(String gender) {
    return AvatarChoice(
      presetId: gender == femaleId ? femaleId : maleId,
    );
  }
}

@immutable
class AvatarPreset {
  const AvatarPreset({
    required this.id,
    required this.label,
    required this.asset,
  });

  final String id;
  final String label;
  final String asset;
}

/// Extra Home-header characters beyond male/female. Cosmetic only.
abstract final class AvatarPresets {
  static AvatarPreset get male => AvatarPreset(
        id: AvatarChoice.maleId,
        label: RemainingSurface.trNow(
          'profile.avatar_choice.body',
          '남성',
        ),
        asset: 'assets/images/characters/avatar_gender_male.png',
      );
  static AvatarPreset get female => AvatarPreset(
    id: AvatarChoice.femaleId,
    label: RemainingSurface.trNow('profile.avatar_choice.female', '여성'),
    asset: 'assets/images/characters/avatar_gender_female.png',
  );
  static AvatarPreset get snail => AvatarPreset(
    id: 'snail',
    label: animalLabel(RemainingSurface.currentLocale, 'snail'),
    asset: 'assets/images/characters/chibi_snail_smiling.png',
  );
  static AvatarPreset get turtle => AvatarPreset(
    id: 'turtle',
    label: animalLabel(RemainingSurface.currentLocale, 'turtle'),
    asset: 'assets/images/characters/tier_turtle.png',
  );
  static AvatarPreset get beagle => AvatarPreset(
    id: 'beagle',
    label: animalLabel(RemainingSurface.currentLocale, 'beagle'),
    asset: 'assets/images/characters/tier_beagle.png',
  );
  static AvatarPreset get wolf => AvatarPreset(
    id: 'wolf',
    label: animalLabel(RemainingSurface.currentLocale, 'wolf'),
    asset: 'assets/images/characters/tier_wolf.png',
  );
  static AvatarPreset get zebra => AvatarPreset(
    id: 'zebra',
    label: animalLabel(RemainingSurface.currentLocale, 'zebra'),
    asset: 'assets/images/characters/tier_zebra.png',
  );
  static AvatarPreset get cheetah => AvatarPreset(
    id: 'cheetah',
    label: animalLabel(RemainingSurface.currentLocale, 'cheetah'),
    asset: 'assets/images/characters/tier_cheetah.png',
  );

  /// 고르기 화면에 보여 주는 목록. 동물(달팽이 포함)은 티어 캐릭터라 여기서 고르게 하지 않는다.
  static List<AvatarPreset> get all => <AvatarPreset>[male, female];

  /// 예전에 동물을 골라 둔 사람의 사진이 깨지지 않게 [byId]는 이 목록까지 찾는다.
  static List<AvatarPreset> get _legacy => <AvatarPreset>[
    snail,
    turtle,
    beagle,
    wolf,
    zebra,
    cheetah,
  ];

  static AvatarPreset byId(String id) {
    // 예전에 저장된 이름을 새 이름으로 이어 준다.
    final current = switch (id) {
      'rabbit' || 'maltese' => 'beagle',
      'gazelle' || 'horse' => 'zebra',
      _ => id,
    };
    for (final preset in [...all, ..._legacy]) {
      if (preset.id == current) return preset;
    }
    return male;
  }
}

/// Device-local avatar choice. Survives process death / app restart.
class AvatarChoiceStore {
  const AvatarChoiceStore();

  static const presetKey = 'src.home_avatar.preset';
  static const photoKey = 'src.home_avatar.photo_b64';

  Future<AvatarChoice?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final preset = prefs.getString(presetKey);
    final photo = prefs.getString(photoKey);
    if ((preset == null || preset.isEmpty) &&
        (photo == null || photo.isEmpty)) {
      return null;
    }
    return AvatarChoice(
      presetId:
          (preset == null || preset.isEmpty) ? AvatarChoice.maleId : preset,
      photoBase64: photo,
    );
  }

  Future<void> write(AvatarChoice choice) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(presetKey, choice.presetId);
    final photo = choice.photoBase64;
    if (photo == null || photo.isEmpty) {
      await prefs.remove(photoKey);
    } else {
      await prefs.setString(photoKey, photo);
    }
  }
}
