import 'package:flutter/material.dart';

/// Server cosmetics catalog. Code defaults match the API defaults so a
/// missing config doc still lists the same items. The phone does not invent
/// a price the server did not confirm once the catalog request succeeds.
class CosmeticItem {
  const CosmeticItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.limited,
    required this.season,
    required this.asset,
    required this.accent,
  });

  final String id;
  final String name;
  final String category;
  final int price;
  final bool limited;
  final String season;
  final String asset;
  final String accent;

  factory CosmeticItem.fromJson(Map<String, dynamic> json) {
    final price = json['price'];
    return CosmeticItem(
      id: _text(json['id']),
      name: _text(json['name']),
      category: _text(json['category']),
      price: price is num ? price.toInt() : 0,
      limited: json['limited'] == true,
      season: _text(json['season']),
      asset: _text(json['asset']),
      accent: _text(json['accent']),
    );
  }
}

class CosmeticsCatalog {
  const CosmeticsCatalog({required this.season, required this.items});

  final String season;
  final List<CosmeticItem> items;

  static const defaults = CosmeticsCatalog(
    season: 'season_1',
    items: [
      CosmeticItem(
        id: 'avatar_snail',
        name: '달팽이 러너',
        category: runnerAvatar,
        price: 30,
        limited: false,
        season: '',
        asset: 'assets/images/characters/chibi_snail_smiling.png',
        accent: '',
      ),
      CosmeticItem(
        id: 'avatar_rabbit',
        name: '토끼 러너',
        category: runnerAvatar,
        price: 80,
        limited: false,
        season: '',
        asset: 'assets/images/characters/chibi_rabbit_pure.png',
        accent: '',
      ),
      CosmeticItem(
        id: 'avatar_cheetah',
        name: '치타 러너',
        category: runnerAvatar,
        price: 150,
        limited: false,
        season: '',
        asset: 'assets/images/characters/chibi_cheetah_pure.png',
        accent: '',
      ),
      CosmeticItem(
        id: 'avatar_season_wolf',
        name: '시즌 1 늑대 러너',
        category: runnerAvatar,
        price: 280,
        limited: true,
        season: 'season_1',
        asset: 'assets/images/characters/chibi_wolf_pure.png',
        accent: '',
      ),
      CosmeticItem(
        id: 'shoe_mint',
        name: '민트 러닝화',
        category: shoeSkin,
        price: 40,
        limited: false,
        season: '',
        asset: '',
        accent: '#1E6A58',
      ),
      CosmeticItem(
        id: 'shoe_blue',
        name: '블루 러닝화',
        category: shoeSkin,
        price: 70,
        limited: false,
        season: '',
        asset: '',
        accent: '#1A56C4',
      ),
      CosmeticItem(
        id: 'shoe_pink',
        name: '핑크 러닝화',
        category: shoeSkin,
        price: 120,
        limited: false,
        season: '',
        asset: '',
        accent: '#F2A0C0',
      ),
      CosmeticItem(
        id: 'shoe_season_gold',
        name: '시즌 1 골드 러닝화',
        category: shoeSkin,
        price: 300,
        limited: true,
        season: 'season_1',
        asset: '',
        accent: '#FFC857',
      ),
      CosmeticItem(
        id: 'frame_blue',
        name: '블루 결과 프레임',
        category: shareFrame,
        price: 50,
        limited: false,
        season: '',
        asset: '',
        accent: 'blue',
      ),
      CosmeticItem(
        id: 'frame_pink',
        name: '핑크 결과 프레임',
        category: shareFrame,
        price: 90,
        limited: false,
        season: '',
        asset: '',
        accent: 'pink',
      ),
      CosmeticItem(
        id: 'frame_mint',
        name: '민트 결과 프레임',
        category: shareFrame,
        price: 140,
        limited: false,
        season: '',
        asset: '',
        accent: 'mint',
      ),
      CosmeticItem(
        id: 'frame_season_gold',
        name: '시즌 1 골드 프레임',
        category: shareFrame,
        price: 260,
        limited: true,
        season: 'season_1',
        asset: '',
        accent: 'yellow',
      ),
    ],
  );

  factory CosmeticsCatalog.fromJson(Map<String, dynamic> json) {
    final season = _text(json['season']);
    final rows = json['items'];
    final items = <CosmeticItem>[];
    if (rows is List) {
      for (final row in rows) {
        if (row is Map<String, dynamic>) {
          final item = CosmeticItem.fromJson(row);
          if (item.id.isNotEmpty && item.name.isNotEmpty && item.price > 0) {
            items.add(item);
          }
        }
      }
    }
    if (items.isEmpty) return defaults;
    return CosmeticsCatalog(
      season: season.isEmpty ? defaults.season : season,
      items: items,
    );
  }

  bool onSale(CosmeticItem item) {
    if (!item.limited) return true;
    return item.season.isNotEmpty && item.season == season;
  }
}

const runnerAvatar = 'runner_avatar';
const shoeSkin = 'shoe_skin';
const shareFrame = 'share_frame';
const cosmeticLoadoutDocId = 'cosmetic_loadout';
const cosmeticCategories = {runnerAvatar, shoeSkin, shareFrame};

String cosmeticCategoryLabel(String category) {
  return switch (category) {
    runnerAvatar => '러너 아바타',
    shoeSkin => '러닝화 스킨',
    shareFrame => '결과 카드 프레임',
    _ => category,
  };
}

class CosmeticSlot {
  const CosmeticSlot({
    this.id = '',
    this.name = '',
    this.asset = '',
    this.accent = '',
  });

  final String id;
  final String name;
  final String asset;
  final String accent;

  bool get isEquipped => id.isNotEmpty;

  static CosmeticSlot fromJson(Object? raw) {
    if (raw is! Map) return const CosmeticSlot();
    return CosmeticSlot(
      id: _text(raw['id']),
      name: _text(raw['name']),
      asset: _text(raw['asset']),
      accent: _text(raw['accent']),
    );
  }
}

class CosmeticLoadout {
  const CosmeticLoadout({
    this.avatar = const CosmeticSlot(),
    this.shoe = const CosmeticSlot(),
    this.frame = const CosmeticSlot(),
  });

  final CosmeticSlot avatar;
  final CosmeticSlot shoe;
  final CosmeticSlot frame;

  CosmeticSlot slotFor(String category) {
    return switch (category) {
      runnerAvatar => avatar,
      shoeSkin => shoe,
      shareFrame => frame,
      _ => const CosmeticSlot(),
    };
  }

  static CosmeticLoadout fromDoc(Map<String, dynamic>? data) {
    final slots = data?['slots'];
    if (slots is! Map) return const CosmeticLoadout();
    return CosmeticLoadout(
      avatar: CosmeticSlot.fromJson(slots[runnerAvatar]),
      shoe: CosmeticSlot.fromJson(slots[shoeSkin]),
      frame: CosmeticSlot.fromJson(slots[shareFrame]),
    );
  }
}

/// Frame and shoe colors already used by the share card. No new artwork.
Color? cosmeticAccentColor(String? accent) {
  if (accent == null || accent.isEmpty) return null;
  return switch (accent) {
    'dark' => const Color(0xFF163528),
    'blue' => const Color(0xFF1A56C4),
    'pink' => const Color(0xFFF2A0C0),
    'yellow' => const Color(0xFFFFC857),
    'mint' => const Color(0xFF1E6A58),
    _ => _hex(accent),
  };
}

Color? _hex(String accent) {
  final text = accent.startsWith('#') ? accent.substring(1) : accent;
  if (text.length != 6) return null;
  final value = int.tryParse(text, radix: 16);
  if (value == null) return null;
  return Color(0xFF000000 | value);
}

String _text(Object? raw) => raw is String ? raw.trim() : '';
