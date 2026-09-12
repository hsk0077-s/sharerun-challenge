import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const male = AvatarPreset(
    id: AvatarChoice.maleId,
    label: '남성',
    asset: 'assets/images/characters/avatar_gender_male.png',
  );
  static const female = AvatarPreset(
    id: AvatarChoice.femaleId,
    label: '여성',
    asset: 'assets/images/characters/avatar_gender_female.png',
  );
  static const snail = AvatarPreset(
    id: 'snail',
    label: '달팽이',
    asset: 'assets/images/characters/chibi_snail_smiling.png',
  );
  static const turtle = AvatarPreset(
    id: 'turtle',
    label: '거북이',
    asset: 'assets/images/characters/chibi_turtle_pure.png',
  );
  static const rabbit = AvatarPreset(
    id: 'rabbit',
    label: '토끼',
    asset: 'assets/images/characters/chibi_rabbit_pure.png',
  );
  static const wolf = AvatarPreset(
    id: 'wolf',
    label: '늑대',
    asset: 'assets/images/characters/chibi_wolf_pure.png',
  );
  static const gazelle = AvatarPreset(
    id: 'gazelle',
    label: '가젤',
    asset: 'assets/images/characters/chibi_gazelle_pure.png',
  );
  static const cheetah = AvatarPreset(
    id: 'cheetah',
    label: '치타',
    asset: 'assets/images/characters/chibi_cheetah_pure.png',
  );

  static const all = <AvatarPreset>[
    male,
    female,
    snail,
    turtle,
    rabbit,
    wolf,
    gazelle,
    cheetah,
  ];

  static AvatarPreset byId(String id) {
    for (final preset in all) {
      if (preset.id == id) return preset;
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
      presetId: (preset == null || preset.isEmpty)
          ? AvatarChoice.maleId
          : preset,
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
