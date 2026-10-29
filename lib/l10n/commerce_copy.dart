import 'package:flutter/widgets.dart';

import '../core/strings/app_strings.dart';
import '../features/shop/cosmetics_catalog.dart';
import 'accessory_names.dart';
import 'app_localizations.dart';

/// Shop item names, cosmetic names, the DIA refund sheet, and the donation
/// match line. Korean strings match the copy the screens already shipped.
///
/// Each row is [accessoryLanguageOrder]: ko, en, ja, zh, es, pt, de, fr, vi, th, id.
const shopCopyRows = <String, List<String>>{
  'cpr': [
    '기록 심폐소생권',
    'Record revival ticket',
    '記録蘇生チケット',
    '紀錄急救券',
    'Ticket para revivir la racha',
    'Ticket para reviver a sequência',
    'Ticket für die Serie',
    'Ticket pour raviver la série',
    'Vé hồi sinh chuỗi',
    'ตั๋วกู้สถิติ',
    'Tiket pemulih rekor',
  ],
  'safeGuard': [
    '세이프 가드',
    'Safe guard',
    'セーフガード',
    '安全守護',
    'Salvaguardia',
    'Salvaguarda',
    'Schutzschild',
    'Garde-fou',
    'Lá chắn an toàn',
    'การ์ดป้องกัน',
    'Pelindung aman',
  ],
  'coach': [
    '코치 원포인트권',
    'Coach one-point ticket',
    'コーチワンポイント券',
    '教練重點券',
    'Ticket de un consejo',
    'Ticket de um ponto do técnico',
    'Coach-Einpunkt-Ticket',
    'Ticket un conseil coach',
    'Vé một lời khuyên',
    'ตั๋วคำแนะนำโค้ช',
    'Tiket satu saran pelatih',
  ],
  'extraEntry': [
    '추가 참가권',
    'Extra entry ticket',
    '追加参加券',
    '加場參賽券',
    'Entrada extra',
    'Entrada extra',
    'Extra-Startplatz',
    'Dossard supplémentaire',
    'Vé tham gia thêm',
    'ตั๋วเข้าร่วมเพิ่ม',
    'Tiket ikut tambahan',
  ],
  'extraEntryPack': [
    '추가 참가권 3장',
    'Extra entry, pack of 3',
    '追加参加券3枚',
    '加場參賽券 3 張',
    'Entrada extra, pack de 3',
    'Entrada extra, pacote de 3',
    'Extra-Startplatz, 3er-Pack',
    'Dossard supplémentaire, lot de 3',
    'Vé thêm, bộ 3',
    'ตั๋วเพิ่ม 3 ใบ',
    'Tiket tambahan, paket 3',
  ],
  'friendGhost': [
    '친구 고스트 페이스',
    'Friend ghost pace',
    '友達ゴーストペース',
    '朋友幽靈配速',
    'Ritmo fantasma de un amigo',
    'Ritmo fantasma do amigo',
    'Freundes-Geisterpace',
    'Allure fantôme d’un ami',
    'Pace bóng bạn bè',
    'เพซโกสต์เพื่อน',
    'Pace hantu teman',
  ],
  'friendGhostPack': [
    '친구 고스트 10회',
    'Friend ghost, 10 runs',
    '友達ゴースト10回',
    '朋友幽靈 10 次',
    'Fantasma de amigo, 10 veces',
    'Fantasma do amigo, 10 vezes',
    'Freundes-Geist, 10 Läufe',
    'Fantôme d’ami, 10 sorties',
    'Bóng bạn, 10 lần',
    'โกสต์เพื่อน 10 ครั้ง',
    'Hantu teman, 10 kali',
  ],
  'crewCheer': [
    '크루 응원 깃발',
    'Crew cheer flag',
    'クルー応援旗',
    '跑團加油旗',
    'Bandera de ánimo del crew',
    'Bandeira de torcida do crew',
    'Crew-Anfeuerungsfahne',
    'Drapeau du crew',
    'Cờ cổ vũ crew',
    'ธงเชียร์ครูว',
    'Bendera sorak kru',
  ],
  'boostRun': [
    '부스트 런',
    'Boost run',
    'ブーストラン',
    '加速跑',
    'Carrera boost',
    'Corrida boost',
    'Boost-Lauf',
    'Course boost',
    'Chạy tăng tốc',
    'รันบูสต์',
    'Lari boost',
  ],
  'boostRunNote': [
    '하루 1회 · 15분간 걸음 SHARE 2배',
    'Once a day · double step SHARE for 15 minutes',
    '1日1回 · 15分間、歩数SHAREが2倍',
    '每天 1 次 · 15 分鐘步數 SHARE 雙倍',
    '1 vez al día · SHARE de pasos x2 durante 15 min',
    '1 vez por dia · SHARE dos passos em dobro por 15 min',
    '1× am Tag · Schritt-SHARE 15 Min. verdoppelt',
    '1 fois par jour · SHARE des pas doublé 15 min',
    '1 lần/ngày · SHARE bước chân x2 trong 15 phút',
    'วันละ 1 ครั้ง · SHARE จากก้าวเป็น 2 เท่า 15 นาที',
    '1 kali sehari · SHARE langkah x2 selama 15 menit',
  ],
  'stepIncubator': [
    '만보기 부화기',
    'Step incubator',
    '歩数ふ化器',
    '計步孵化器',
    'Incubadora de pasos',
    'Incubadora de passos',
    'Schritt-Inkubator',
    'Incubateur de pas',
    'Lồng ấp bước chân',
    'ตู้ฟักก้าวเดิน',
    'Inkubator langkah',
  ],
  'stepIncubatorNote': [
    '검증 걸음 30,000보에 민트 러닝화',
    'Mint running shoes at 30,000 verified steps',
    '認証30,000歩でミントのシューズ',
    '驗證 30,000 步獲得薄荷跑鞋',
    'Zapatillas menta a los 30.000 pasos verificados',
    'Tênis menta aos 30.000 passos verificados',
    'Mint-Laufschuhe bei 30.000 geprüften Schritten',
    'Chaussures menthe à 30 000 pas vérifiés',
    'Giày bạc hà ở 30.000 bước đã xác minh',
    'รองเท้ามินต์เมื่อก้าวที่ยืนยันครบ 30,000',
    'Sepatu mint pada 30.000 langkah terverifikasi',
  ],
  'restDay': [
    '휴식일 지정권',
    'Rest-day ticket',
    '休息日指定券',
    '休息日指定券',
    'Ticket de día de descanso',
    'Ticket de dia de descanso',
    'Ruhetag-Ticket',
    'Ticket jour de repos',
    'Vé ngày nghỉ',
    'ตั๋ววันพัก',
    'Tiket hari istirahat',
  ],
  'restDayNote': [
    '매주 1장 무료 · 추가는 VALUE',
    'One free each week · extras cost VALUE',
    '毎週1枚無料 · 追加はVALUE',
    '每週 1 張免費 · 加買用 VALUE',
    '1 gratis por semana · las extras cuestan VALUE',
    '1 grátis por semana · extras custam VALUE',
    '1 gratis pro Woche · weitere kosten VALUE',
    '1 gratuit par semaine · les suivants coûtent des VALUE',
    '1 vé miễn phí mỗi tuần · vé thêm tốn VALUE',
    'ฟรีสัปดาห์ละ 1 ใบ · ใบเพิ่มใช้ VALUE',
    '1 gratis tiap minggu · tambahan pakai VALUE',
  ],
  'donationMatch': [
    '기부 매칭권',
    'Donation match ticket',
    '寄付マッチ券',
    '公益加碼券',
    'Ticket de igualación',
    'Ticket de matching',
    'Spenden-Match-Ticket',
    'Ticket de don équivalent',
    'Vé đối ứng quyên góp',
    'ตั๋วจับคู่เงินบริจาค',
    'Tiket padanan donasi',
  ],
  'donationMatchNote': [
    '한 달에 1회 · 운영자 1,000원',
    'Once a month · operator pays 1,000 KRW',
    '月1回 · 運営が1,000ウォン',
    '每月 1 次 · 營運方出 1,000 韓元',
    '1 vez al mes · el operador pone 1.000 KRW',
    '1 vez por mês · o operador põe 1.000 KRW',
    '1× im Monat · Betreiber zahlt 1.000 KRW',
    '1 fois par mois · l’opérateur verse 1 000 KRW',
    '1 lần/tháng · bên vận hành trả 1.000 KRW',
    'เดือนละ 1 ครั้ง · ผู้ดำเนินงานจ่าย 1,000 วอน',
    '1 kali sebulan · operator membayar 1.000 KRW',
  ],
  'starBoost': [
    '스타 부스트',
    'Star boost',
    'スターブースト',
    '星星加速',
    'Impulso estrella',
    'Impulso estrela',
    'Stern-Boost',
    'Boost étoile',
    'Tăng sao',
    'บูสต์ดาว',
    'Boost bintang',
  ],
  'sharePack': [
    'SHARE 팩',
    'SHARE pack',
    'SHAREパック',
    'SHARE 包',
    'Pack SHARE',
    'Pacote SHARE',
    'SHARE-Paket',
    'Pack SHARE',
    'Gói SHARE',
    'แพ็ก SHARE',
    'Paket SHARE',
  ],
  'battlePass': [
    '배틀런 패스',
    'Battle Run pass',
    'バトルランパス',
    '戰鬥跑通行證',
    'Pase Battle Run',
    'Passe Battle Run',
    'Battle-Run-Pass',
    'Passe Battle Run',
    'Thẻ Battle Run',
    'พาส Battle Run',
    'Pass Battle Run',
  ],
  'battlePassNote': [
    '시즌 보상 · 패스+',
    'Season rewards · Pass+',
    'シーズン報酬 · パス+',
    '賽季獎勵 · Pass+',
    'Premios de temporada · Pass+',
    'Prêmios da temporada · Pass+',
    'Saisonbelohnung · Pass+',
    'Récompenses de saison · Pass+',
    'Thưởng mùa · Pass+',
    'รางวัลซีซัน · Pass+',
    'Hadiah musim · Pass+',
  ],
  'cosmeticsTitle': [
    '코스메틱',
    'Cosmetics',
    'コスメ',
    '外觀',
    'Cosméticos',
    'Cosméticos',
    'Kosmetik',
    'Cosmétiques',
    'Trang phục',
    'ของตกแต่ง',
    'Kosmetik',
  ],
  'cosmeticsNote': [
    '무료 DIA로 살 수 있습니다. 기록과 랭킹은 바뀌지 않습니다.',
    'You can buy these with free DIA. Records and rank do not change.',
    '無料DIAで買えます。記録と順位は変わりません。',
    '可用免費 DIA 購買。紀錄與排名不會改變。',
    'Se compran con DIA gratis. El registro y el rango no cambian.',
    'Dá para comprar com DIA grátis. Recorde e ranking não mudam.',
    'Kauf mit Gratis-DIA. Rekorde und Rang bleiben gleich.',
    'Achetables avec des DIA gratuits. Records et rang inchangés.',
    'Mua bằng DIA miễn phí. Thành tích và hạng không đổi.',
    'ซื้อด้วย DIA ฟรีได้ สถิติและอันดับไม่เปลี่ยน',
    'Bisa dibeli dengan DIA gratis. Rekor dan peringkat tidak berubah.',
  ],
  'cosmeticOwned': ['보유', 'Owned', '所持', '已擁有', 'Tienes', 'Você tem', 'Im Besitz', 'Possédé', 'Đang có', 'มีแล้ว', 'Dimiliki'],
  'cosmeticEquip': ['장착', 'Equip', '装備', '裝備', 'Equipar', 'Equipar', 'Anlegen', 'Équiper', 'Trang bị', 'สวม', 'Pakai'],
  'cosmeticUnequip': ['해제', 'Unequip', '外す', '卸下', 'Quitar', 'Tirar', 'Ablegen', 'Retirer', 'Tháo', 'ถอด', 'Lepas'],
  'cosmeticSeasonEnded': ['시즌 종료', 'Season ended', 'シーズン終了', '賽季結束', 'Temporada terminada', 'Temporada encerrada', 'Saison beendet', 'Saison terminée', 'Mùa đã kết thúc', 'ซีซันจบแล้ว', 'Musim selesai'],
  'cosmeticLimited': ['시즌 한정', 'Season limited', 'シーズン限定', '賽季限定', 'Edición de temporada', 'Edição de temporada', 'Saisonlimitiert', 'Édition de saison', 'Giới hạn mùa', 'จำกัดซีซัน', 'Edisi musim'],
  'valueTitle': ['VALUE 상세', 'VALUE details', 'VALUEの詳細', 'VALUE 說明', 'Detalle de VALUE', 'Detalhe de VALUE', 'VALUE-Details', 'Détail VALUE', 'Chi tiết VALUE', 'รายละเอียด VALUE', 'Detail VALUE'],
  'valueBody': [
    'VALUE는 현금으로 바꿀 수 없는 명예 재화예요. 기부처 투표, 명예의 전당, 칭호·배지 등에 쓰여요.',
    'VALUE is an honor currency you cannot cash out. It is used for charity votes, the hall of fame, and titles or badges.',
    'VALUEは現金にできない名誉の通貨です。寄付先の投票、名誉の殿堂、称号・バッジに使います。',
    'VALUE 是不能換成現金的榮譽貨幣。用於公益投票、名人堂、稱號與徽章。',
    'VALUE es una moneda de honor que no se cambia por dinero. Sirve para votar la causa, el salón de la fama y títulos o insignias.',
    'VALUE é uma moeda de honra que não vira dinheiro. Serve para votar a causa, o hall da fama e títulos ou emblemas.',
    'VALUE ist eine Ehrenwährung ohne Auszahlung. Sie gilt für die Spendenwahl, die Ruhmeshalle und Titel oder Abzeichen.',
    'VALUE est une monnaie d’honneur, pas de l’argent. Elle sert au vote de la cause, au panthéon et aux titres ou badges.',
    'VALUE là tiền danh dự, không đổi ra tiền mặt. Dùng để bầu nơi nhận, bảng vinh danh, danh hiệu và huy hiệu.',
    'VALUE เป็นเหรียญเกียรติยศ เปลี่ยนเป็นเงินสดไม่ได้ ใช้โหวตปลายทาง หอเกียรติยศ และฉายาหรือเหรียญ',
    'VALUE adalah mata uang kehormatan, tidak bisa diuangkan. Dipakai untuk memilih penerima, aula kehormatan, dan gelar atau lencana.',
  ],
  'shoeMint': ['민트 러닝화', 'Mint running shoes', 'ミントのシューズ', '薄荷跑鞋', 'Zapatillas menta', 'Tênis menta', 'Mint-Laufschuhe', 'Chaussures menthe', 'Giày bạc hà', 'รองเท้ามินต์', 'Sepatu mint'],
  'shoeBlue': ['블루 러닝화', 'Blue running shoes', 'ブルーのシューズ', '藍色跑鞋', 'Zapatillas azules', 'Tênis azul', 'Blaue Laufschuhe', 'Chaussures bleues', 'Giày xanh dương', 'รองเท้าสีน้ำเงิน', 'Sepatu biru'],
  'shoePink': ['핑크 러닝화', 'Pink running shoes', 'ピンクのシューズ', '粉色跑鞋', 'Zapatillas rosas', 'Tênis rosa', 'Rosa Laufschuhe', 'Chaussures roses', 'Giày hồng', 'รองเท้าสีชมพู', 'Sepatu merah muda'],
  'shoeGold': ['시즌 1 골드 러닝화', 'Season 1 gold running shoes', 'シーズン1ゴールドシューズ', '第 1 賽季金色跑鞋', 'Zapatillas oro temporada 1', 'Tênis ouro temporada 1', 'Gold-Laufschuhe Saison 1', 'Chaussures or saison 1', 'Giày vàng mùa 1', 'รองเท้าทองซีซัน 1', 'Sepatu emas musim 1'],
  'frameBlue': ['블루 결과 프레임', 'Blue result frame', 'ブルー結果フレーム', '藍色成績框', 'Marco azul', 'Moldura azul', 'Blauer Ergebnisrahmen', 'Cadre bleu', 'Khung kết quả xanh', 'กรอบผลสีน้ำเงิน', 'Bingkai hasil biru'],
  'framePink': ['핑크 결과 프레임', 'Pink result frame', 'ピンク結果フレーム', '粉色成績框', 'Marco rosa', 'Moldura rosa', 'Rosa Ergebnisrahmen', 'Cadre rose', 'Khung kết quả hồng', 'กรอบผลสีชมพู', 'Bingkai hasil merah muda'],
  'frameMint': ['민트 결과 프레임', 'Mint result frame', 'ミント結果フレーム', '薄荷成績框', 'Marco menta', 'Moldura menta', 'Mint-Ergebnisrahmen', 'Cadre menthe', 'Khung kết quả bạc hà', 'กรอบผลมินต์', 'Bingkai hasil mint'],
  'frameGold': ['시즌 1 골드 프레임', 'Season 1 gold frame', 'シーズン1ゴールドフレーム', '第 1 賽季金色框', 'Marco oro temporada 1', 'Moldura ouro temporada 1', 'Goldrahmen Saison 1', 'Cadre or saison 1', 'Khung vàng mùa 1', 'กรอบทองซีซัน 1', 'Bingkai emas musim 1'],
};

const _cosmeticIds = <String, String>{
  'shoe_mint': 'shoeMint',
  'shoe_blue': 'shoeBlue',
  'shoe_pink': 'shoePink',
  'shoe_season_gold': 'shoeGold',
  'frame_blue': 'frameBlue',
  'frame_pink': 'framePink',
  'frame_mint': 'frameMint',
  'frame_season_gold': 'frameGold',
};

const _shopKorean = <String, String>{
  'cpr': AppStrings.storeItemCpr,
  'safeGuard': AppStrings.storeItemSafeGuard,
  'coach': AppStrings.storeItemCoachOnePoint,
  'extraEntry': AppStrings.storeItemExtraEntry,
  'extraEntryPack': AppStrings.storeItemExtraEntryPack,
  'friendGhost': AppStrings.storeItemFriendGhost,
  'friendGhostPack': AppStrings.storeItemFriendGhostPack,
  'crewCheer': AppStrings.storeItemCrewCheer,
  'boostRun': AppStrings.storeItemBoostRun,
  'boostRunNote': AppStrings.storeItemBoostRunNote,
  'stepIncubator': AppStrings.storeItemStepIncubator,
  'stepIncubatorNote': AppStrings.storeItemStepIncubatorNote,
  'restDay': AppStrings.storeItemRestDay,
  'restDayNote': AppStrings.storeItemRestDayNote,
  'donationMatch': AppStrings.storeItemDonationMatch,
  'donationMatchNote': AppStrings.storeItemDonationMatchNote,
  'starBoost': AppStrings.storeItemStarBoost,
  'sharePack': AppStrings.storeItemSharePack,
  'cosmeticsTitle': AppStrings.storeCosmeticsTitle,
  'cosmeticsNote': AppStrings.storeCosmeticsNote,
  'cosmeticOwned': AppStrings.storeCosmeticOwned,
  'cosmeticEquip': AppStrings.storeCosmeticEquip,
  'cosmeticUnequip': AppStrings.storeCosmeticUnequip,
  'cosmeticSeasonEnded': AppStrings.storeCosmeticSeasonEnded,
  'cosmeticLimited': AppStrings.storeCosmeticLimited,
  'valueTitle': AppStrings.storeValueDetailTitle,
  'valueBody': AppStrings.storeValueDetailBody,
};

class ShopCopy {
  const ShopCopy._(this.languageCode);

  final String languageCode;

  static ShopCopy of(Locale locale) {
    final code = shopCopyRows['cpr']!.asMap().containsKey(
          accessoryLanguageOrder.indexOf(locale.languageCode),
        )
        ? locale.languageCode
        : 'en';
    final index = accessoryLanguageOrder.indexOf(code);
    if (index < 0) return const ShopCopy._('en');
    return ShopCopy._(accessoryLanguageOrder[index]);
  }

  String _at(String key) {
    final row = shopCopyRows[key];
    if (row == null) return '';
    final index = accessoryLanguageOrder.indexOf(languageCode);
    if (index < 0 || index >= row.length) return row[1];
    return row[index];
  }

  String get cpr => _at('cpr');
  String get safeGuard => _at('safeGuard');
  String get coach => _at('coach');
  String get extraEntry => _at('extraEntry');
  String get extraEntryPack => _at('extraEntryPack');
  String get friendGhost => _at('friendGhost');
  String get friendGhostPack => _at('friendGhostPack');
  String get crewCheer => _at('crewCheer');
  String get boostRun => _at('boostRun');
  String get boostRunNote => _at('boostRunNote');
  String get stepIncubator => _at('stepIncubator');
  String get stepIncubatorNote => _at('stepIncubatorNote');
  String get restDay => _at('restDay');
  String get restDayNote => _at('restDayNote');
  String get donationMatch => _at('donationMatch');
  String get donationMatchNote => _at('donationMatchNote');
  String get starBoost => _at('starBoost');
  String get sharePack => _at('sharePack');
  String get battlePass => _at('battlePass');
  String get battlePassNote => _at('battlePassNote');
  String get cosmeticsTitle => _at('cosmeticsTitle');
  String get cosmeticsNote => _at('cosmeticsNote');
  String get cosmeticOwned => _at('cosmeticOwned');
  String get cosmeticEquip => _at('cosmeticEquip');
  String get cosmeticUnequip => _at('cosmeticUnequip');
  String get cosmeticSeasonEnded => _at('cosmeticSeasonEnded');
  String get cosmeticLimited => _at('cosmeticLimited');
  String get valueTitle => _at('valueTitle');
  String get valueBody => _at('valueBody');

  String cosmeticName(String id, String fallback) {
    final key = _cosmeticIds[id];
    if (key == null) return fallback;
    final name = _at(key);
    return name.isEmpty ? fallback : name;
  }
}

const donationMatchRows = <String, List<String>>{
  'line': [
    '{sponsor} 명의 {won}원 · {name} 기여',
    '{won} KRW in {sponsor}’s name · {name} made it possible',
    '{sponsor}名義 {won}ウォン · {name}の貢献',
    '{sponsor} 名義 {won} 韓元 · {name} 促成',
    '{won} KRW a nombre de {sponsor} · aporte de {name}',
    '{won} KRW em nome de {sponsor} · contribuição de {name}',
    '{won} KRW im Namen von {sponsor} · Beitrag von {name}',
    '{won} KRW au nom de {sponsor} · apport de {name}',
    '{won} KRW dưới tên {sponsor} · {name} góp phần',
    '{won} วอน ในนาม {sponsor} · {name} เป็นผู้ทำให้เกิด',
    '{won} KRW atas nama {sponsor} · kontribusi {name}',
  ],
  'member': [
    '회원',
    'member',
    '会員',
    '會員',
    'miembro',
    'membro',
    'Mitglied',
    'membre',
    'thành viên',
    'สมาชิก',
    'anggota',
  ],
};

class DonationMatchCopy {
  const DonationMatchCopy._(this.languageCode);

  final String languageCode;

  static DonationMatchCopy of(Locale locale) {
    final index = accessoryLanguageOrder.indexOf(locale.languageCode);
    if (index < 0) return const DonationMatchCopy._('en');
    return DonationMatchCopy._(locale.languageCode);
  }

  String _at(String key) {
    final row = donationMatchRows[key]!;
    final index = accessoryLanguageOrder.indexOf(languageCode);
    if (index < 0 || index >= row.length) return row[1];
    return row[index];
  }

  String get member => _at('member');

  String line(String sponsor, String won, String name) => _at('line')
      .replaceAll('{sponsor}', sponsor)
      .replaceAll('{won}', won)
      .replaceAll('{name}', name);
}

const refundRows = <String, List<String>>{
  'openButton': ['환불 신청하기', 'Request a refund', '返金を申請', '申請退款', 'Pedir reembolso', 'Pedir reembolso', 'Erstattung beantragen', 'Demander un remboursement', 'Yêu cầu hoàn tiền', 'ขอคืนเงิน', 'Ajukan pengembalian'],
  'title': ['DIA 환불', 'DIA refund', 'DIAの返金', 'DIA 退款', 'Reembolso de DIA', 'Reembolso de DIA', 'DIA-Erstattung', 'Remboursement DIA', 'Hoàn DIA', 'คืนเงิน DIA', 'Pengembalian DIA'],
  'window': [
    '산 날부터 {days}일 안, 쓰지 않은 유료 DIA만 환불돼요.',
    'Only unused paid DIA can be refunded within {days} days of purchase.',
    '購入日から{days}日以内、未使用の有料DIAだけ返金できます。',
    '購買日起 {days} 天內，只有未使用的付費 DIA 可以退款。',
    'Solo el DIA de pago no usado se reembolsa dentro de {days} días desde la compra.',
    'Só o DIA pago não usado é reembolsado em até {days} dias da compra.',
    'Nur ungenutztes bezahltes DIA wird innerhalb von {days} Tagen nach dem Kauf erstattet.',
    'Seuls les DIA payants non utilisés sont remboursés dans les {days} jours après l’achat.',
    'Chỉ DIA trả phí chưa dùng được hoàn trong {days} ngày kể từ ngày mua.',
    'คืนได้เฉพาะ DIA แบบเสียเงินที่ยังไม่ใช้ ภายใน {days} วันนับจากวันที่ซื้อ',
    'Hanya DIA berbayar yang belum terpakai yang dikembalikan dalam {days} hari sejak pembelian.',
  ],
  'loading': ['불러오는 중이에요…', 'Loading…', '読み込み中…', '載入中…', 'Cargando…', 'Carregando…', 'Wird geladen…', 'Chargement…', 'Đang tải…', 'กำลังโหลด…', 'Memuat…'],
  'offline': [
    '서버에 연결되면 환불할 수 있어요.',
    'You can refund once the server is connected.',
    'サーバーにつながると返金できます。',
    '連上伺服器後就能退款。',
    'Podrás reembolsar cuando haya servidor.',
    'Dá para reembolsar quando o servidor conectar.',
    'Erstatten geht, sobald der Server verbunden ist.',
    'Le remboursement s’ouvre quand le serveur répond.',
    'Hoàn được khi đã nối máy chủ.',
    'เชื่อมเซิร์ฟเวอร์แล้วจึงขอคืนเงินได้',
    'Bisa dikembalikan setelah server terhubung.',
  ],
  'empty': [
    '{days}일 안에 산 DIA 팩이 없어요.',
    'No DIA pack bought in the last {days} days.',
    '{days}日以内に買ったDIAパックはありません。',
    '{days} 天內沒有買過 DIA 包。',
    'No hay un pack de DIA comprado en {days} días.',
    'Nenhum pacote de DIA comprado em {days} dias.',
    'Kein DIA-Paket in den letzten {days} Tagen gekauft.',
    'Aucun pack DIA acheté dans les {days} jours.',
    'Không có gói DIA nào mua trong {days} ngày.',
    'ไม่มีแพ็ก DIA ที่ซื้อใน {days} วัน',
    'Tidak ada paket DIA yang dibeli dalam {days} hari.',
  ],
  'pack': [
    'DIA {count}개 팩 · {price}원',
    'DIA pack of {count} · {price} KRW',
    'DIA {count}個パック · {price}ウォン',
    'DIA {count} 個包 · {price} 韓元',
    'Pack de {count} DIA · {price} KRW',
    'Pacote de {count} DIA · {price} KRW',
    'DIA-Paket mit {count} · {price} KRW',
    'Pack de {count} DIA · {price} KRW',
    'Gói {count} DIA · {price} KRW',
    'แพ็ก DIA {count} ชิ้น · {price} วอน',
    'Paket {count} DIA · {price} KRW',
  ],
  'boughtOn': [
    '{month}월 {day}일에 샀어요',
    'Bought on {month}/{day}',
    '{month}月{day}日に買いました',
    '{month} 月 {day} 日購買',
    'Comprado el {day}/{month}',
    'Comprado em {day}/{month}',
    'Gekauft am {day}.{month}.',
    'Acheté le {day}/{month}',
    'Mua ngày {day}/{month}',
    'ซื้อวันที่ {day}/{month}',
    'Dibeli {day}/{month}',
  ],
  'summary': [
    '환불 {won}원 · 유료 DIA {paid}개',
    'Refund {won} KRW · paid DIA {paid}',
    '返金 {won}ウォン · 有料DIA {paid}個',
    '退款 {won} 韓元 · 付費 DIA {paid} 個',
    'Reembolso {won} KRW · DIA de pago {paid}',
    'Reembolso {won} KRW · DIA pago {paid}',
    'Erstattung {won} KRW · bezahltes DIA {paid}',
    'Remboursement {won} KRW · DIA payants {paid}',
    'Hoàn {won} KRW · DIA trả phí {paid}',
    'คืน {won} วอน · DIA แบบเสียเงิน {paid} ชิ้น',
    'Kembali {won} KRW · DIA berbayar {paid}',
  ],
  'bonusRevoke': [
    ' + 덤 {bonus}개 회수',
    ' + {bonus} bonus taken back',
    ' + おまけ{bonus}個を回収',
    ' + 收回獎勵 {bonus} 個',
    ' + se retiran {bonus} de regalo',
    ' + {bonus} de bônus voltam',
    ' + {bonus} Bonus zurück',
    ' + {bonus} bonus repris',
    ' + thu {bonus} thưởng',
    ' + ดึงโบนัส {bonus} ชิ้นกลับ',
    ' + {bonus} bonus ditarik',
  ],
  'requestButton': [
    '{won}원 환불 신청',
    'Request {won} KRW',
    '{won}ウォンを返金申請',
    '申請退 {won} 韓元',
    'Pedir {won} KRW',
    'Pedir {won} KRW',
    '{won} KRW beantragen',
    'Demander {won} KRW',
    'Yêu cầu hoàn {won} KRW',
    'ขอคืน {won} วอน',
    'Ajukan {won} KRW',
  ],
  'confirmTitle': ['환불 신청', 'Request a refund', '返金を申請', '申請退款', 'Pedir reembolso', 'Pedir reembolso', 'Erstattung beantragen', 'Demander un remboursement', 'Yêu cầu hoàn tiền', 'ขอคืนเงิน', 'Ajukan pengembalian'],
  'cancel': ['취소', 'Cancel', 'キャンセル', '取消', 'Cancelar', 'Cancelar', 'Abbrechen', 'Annuler', 'Hủy', 'ยกเลิก', 'Batal'],
  'confirmButton': ['환불 신청', 'Request refund', '返金を申請', '申請退款', 'Pedir reembolso', 'Pedir reembolso', 'Beantragen', 'Demander', 'Yêu cầu hoàn', 'ขอคืนเงิน', 'Ajukan'],
  'doneToast': [
    '{won}원이 환불됐어요.',
    '{won} KRW was refunded.',
    '{won}ウォンが返金されました。',
    '已退 {won} 韓元。',
    'Se reembolsaron {won} KRW.',
    '{won} KRW foram reembolsados.',
    '{won} KRW wurden erstattet.',
    '{won} KRW ont été remboursés.',
    'Đã hoàn {won} KRW.',
    'คืน {won} วอนแล้ว',
    '{won} KRW sudah dikembalikan.',
  ],
  'pendingToast': [
    '환불을 신청했어요. 담당자가 확인해 환불해 드려요.',
    'Refund requested. Someone will check it and pay it back.',
    '返金を申請しました。担当者が確認して返金します。',
    '已申請退款。專人確認後會退還。',
    'Reembolso pedido. Alguien lo revisará y lo devolverá.',
    'Reembolso pedido. Alguém confere e devolve.',
    'Erstattung beantragt. Jemand prüft sie und zahlt zurück.',
    'Remboursement demandé. Quelqu’un vérifie et rembourse.',
    'Đã yêu cầu hoàn. Người phụ trách sẽ kiểm tra và hoàn.',
    'ขอคืนเงินแล้ว เจ้าหน้าที่จะตรวจแล้วคืนให้',
    'Pengembalian diajukan. Petugas akan memeriksa dan mengembalikan.',
  ],
  'already': [
    '이미 환불을 신청한 구매예요.',
    'This purchase already has a refund request.',
    'この購入はすでに返金申請済みです。',
    '這筆購買已經申請過退款。',
    'Esta compra ya tiene una solicitud.',
    'Esta compra já tem um pedido.',
    'Für diesen Kauf gibt es schon einen Antrag.',
    'Cet achat a déjà une demande.',
    'Lần mua này đã được yêu cầu hoàn.',
    'การซื้อนี้ขอคืนเงินไปแล้ว',
    'Pembelian ini sudah diajukan.',
  ],
  'failed': [
    '환불하지 못했어요. 잠시 뒤 다시 해 주세요.',
    'Could not refund. Try again in a moment.',
    '返金できませんでした。しばらくしてからもう一度。',
    '無法退款。請稍後再試。',
    'No se pudo reembolsar. Prueba de nuevo en un momento.',
    'Não deu para reembolsar. Tente de novo daqui a pouco.',
    'Erstattung fehlgeschlagen. Gleich noch einmal versuchen.',
    'Remboursement impossible. Réessayez dans un instant.',
    'Không hoàn được. Hãy thử lại sau.',
    'คืนเงินไม่สำเร็จ ลองอีกครั้งอีกสักครู่',
    'Tidak berhasil dikembalikan. Coba lagi sebentar lagi.',
  ],
  'whyPending': ['환불을 신청했어요. 확인 중이에요.', 'Refund requested. It is being checked.', '返金を申請しました。確認中です。', '已申請退款，確認中。', 'Reembolso pedido. En revisión.', 'Reembolso pedido. Em análise.', 'Beantragt. Wird geprüft.', 'Demandé. En cours de vérification.', 'Đã yêu cầu. Đang kiểm tra.', 'ขอแล้ว กำลังตรวจ', 'Diajukan. Sedang diperiksa.'],
  'whyDone': ['환불이 끝났어요.', 'The refund is done.', '返金が完了しました。', '退款已完成。', 'El reembolso ya está hecho.', 'O reembolso já foi feito.', 'Die Erstattung ist abgeschlossen.', 'Le remboursement est fait.', 'Đã hoàn xong.', 'คืนเงินเสร็จแล้ว', 'Pengembalian selesai.'],
  'whyNothing': [
    '쓰지 않은 유료 DIA가 없어서 환불할 금액이 없어요.',
    'There is no unused paid DIA, so there is nothing to refund.',
    '未使用の有料DIAがないので、返金する金額がありません。',
    '沒有未使用的付費 DIA，所以沒有可退金額。',
    'No queda DIA de pago sin usar, así que no hay importe.',
    'Não há DIA pago sem usar, então não há valor.',
    'Kein ungenutztes bezahltes DIA, also kein Betrag.',
    'Pas de DIA payant inutilisé, donc rien à rendre.',
    'Không còn DIA trả phí chưa dùng, nên không có số tiền hoàn.',
    'ไม่มี DIA แบบเสียเงินที่ยังไม่ใช้ จึงไม่มียอดคืน',
    'Tidak ada DIA berbayar yang belum terpakai, jadi tidak ada nominal.',
  ],
  'whyPeriod': ['환불 기간이 지났어요.', 'The refund period is over.', '返金期間が過ぎました。', '已過退款期限。', 'El plazo de reembolso pasó.', 'O prazo de reembolso passou.', 'Die Frist ist vorbei.', 'Le délai est passé.', 'Đã hết hạn hoàn.', 'เลยระยะคืนเงินแล้ว', 'Masa pengembalian sudah lewat.'],
  'whyOther': ['환불할 수 없어요.', 'This cannot be refunded.', '返金できません。', '無法退款。', 'No se puede reembolsar.', 'Não dá para reembolsar.', 'Das kann nicht erstattet werden.', 'Remboursement impossible.', 'Không thể hoàn.', 'คืนเงินไม่ได้', 'Tidak bisa dikembalikan.'],
  'confirmIrreversible': [
    '신청하면 되돌릴 수 없어요.',
    'You cannot undo the request.',
    '申請するとやり直せません。',
    '送出後無法取消。',
    'Si lo pides, no se puede deshacer.',
    'Se pedir, não dá para desfazer.',
    'Der Antrag lässt sich nicht zurücknehmen.',
    'Une fois demandé, on ne peut pas annuler.',
    'Đã yêu cầu thì không hoàn tác được.',
    'เมื่อขอแล้ว ยกเลิกไม่ได้',
    'Setelah diajukan, tidak bisa dibatalkan.',
  ],
  'confirmSpent': [
    '이미 쓴 덤 {spent}개는 {won}원을 뺐어요.',
    'The {spent} bonus already used took {won} KRW off.',
    'すでに使ったおまけ{spent}個分として{won}ウォンを引きました。',
    '已用掉的獎勵 {spent} 個，扣了 {won} 韓元。',
    'Los {spent} de regalo ya usados restaron {won} KRW.',
    'Os {spent} de bônus já usados tiraram {won} KRW.',
    'Der schon genutzte Bonus ({spent}) hat {won} KRW abgezogen.',
    'Les {spent} bonus déjà utilisés ont retiré {won} KRW.',
    '{spent} thưởng đã dùng bị trừ {won} KRW.',
    'โบนัสที่ใช้ไปแล้ว {spent} ชิ้น ถูกหัก {won} วอน',
    '{spent} bonus yang sudah terpakai mengurangi {won} KRW.',
  ],
  'confirmLead': [
    '쓰지 않은 유료 DIA {paid}개',
    'Unused paid DIA: {paid}',
    '未使用の有料DIA {paid}個',
    '未使用的付費 DIA {paid} 個',
    'DIA de pago sin usar: {paid}',
    'DIA pago sem usar: {paid}',
    'Ungenutztes bezahltes DIA: {paid}',
    'DIA payants non utilisés : {paid}',
    'DIA trả phí chưa dùng: {paid}',
    'DIA แบบเสียเงินที่ยังไม่ใช้ {paid} ชิ้น',
    'DIA berbayar yang belum terpakai: {paid}',
  ],
  'confirmBonus': [
    '와 덤 {bonus}개',
    ' and {bonus} bonus',
    'とおまけ{bonus}個',
    '和獎勵 {bonus} 個',
    ' y {bonus} de regalo',
    ' e {bonus} de bônus',
    ' und {bonus} Bonus',
    ' et {bonus} bonus',
    ' và {bonus} thưởng',
    ' และโบนัส {bonus} ชิ้น',
    ' dan {bonus} bonus',
  ],
  'confirmDrop': [
    '가 빠지고 {won}원이 환불돼요.',
    ' will be removed and {won} KRW refunded.',
    'が減り、{won}ウォンが返金されます。',
    '會被扣掉，並退 {won} 韓元。',
    ' se quitan y se reembolsan {won} KRW.',
    ' saem e {won} KRW são reembolsados.',
    ' werden abgezogen und {won} KRW erstattet.',
    ' sont retirés et {won} KRW sont remboursés.',
    ' sẽ bị trừ và hoàn {won} KRW.',
    ' จะถูกหัก และคืน {won} วอน',
    ' akan dikurangi dan {won} KRW dikembalikan.',
  ],
};

class DiaRefundCopy {
  const DiaRefundCopy._(this.languageCode);

  final String languageCode;

  static DiaRefundCopy of(Locale locale) {
    final index = accessoryLanguageOrder.indexOf(locale.languageCode);
    if (index < 0) return const DiaRefundCopy._('en');
    return DiaRefundCopy._(locale.languageCode);
  }

  String _at(String key) {
    final row = refundRows[key]!;
    final index = accessoryLanguageOrder.indexOf(languageCode);
    if (index < 0 || index >= row.length) return row[1];
    return row[index];
  }

  String fill(String key, Map<String, String> values) {
    var text = _at(key);
    for (final entry in values.entries) {
      text = text.replaceAll('{${entry.key}}', entry.value);
    }
    return text;
  }

  String get openButton => _at('openButton');
  String get title => _at('title');
  String get loading => _at('loading');
  String get offline => _at('offline');
  String get confirmTitle => _at('confirmTitle');
  String get cancel => _at('cancel');
  String get confirmButton => _at('confirmButton');
  String get pendingToast => _at('pendingToast');
  String get already => _at('already');
  String get failed => _at('failed');
  String get whyPending => _at('whyPending');
  String get whyDone => _at('whyDone');
  String get whyNothing => _at('whyNothing');
  String get whyPeriod => _at('whyPeriod');
  String get whyOther => _at('whyOther');

  String window(int days) => fill('window', {'days': '$days'});
  String empty(int days) => fill('empty', {'days': '$days'});
  String pack(int count, String price) => fill('pack', {'count': '$count', 'price': price});
  String boughtOn(int month, int day) => fill('boughtOn', {'month': '$month', 'day': '$day'});
  String summary(String won, int paid) => fill('summary', {'won': won, 'paid': '$paid'});
  String bonusRevoke(int bonus) => fill('bonusRevoke', {'bonus': '$bonus'});
  String requestButton(String won) => fill('requestButton', {'won': won});
  String doneToast(String won) => fill('doneToast', {'won': won});

  /// Same sentence the Korean sheet shipped, including the line break.
  String confirmBody({
    required int paidDia,
    required int bonusRevoked,
    required String refundWon,
    required int bonusSpent,
    required String spentWon,
  }) {
    final bonus = bonusRevoked > 0 ? fill('confirmBonus', {'bonus': '$bonusRevoked'}) : '';
    final spent = bonusSpent > 0
        ? '\n${fill('confirmSpent', {'spent': '$bonusSpent', 'won': spentWon})}'
        : '';
    final lead = fill('confirmLead', {'paid': '$paidDia'});
    final drop = fill('confirmDrop', {'won': refundWon});
    return '$lead$bonus$drop$spent\n${_at('confirmIrreversible')}';
  }
}

String _rowAt(List<String>? row, String languageCode) {
  if (row == null || row.isEmpty) return '';
  final index = accessoryLanguageOrder.indexOf(languageCode);
  if (index < 0 || index >= row.length) return '';
  return row[index];
}

List<String> missingCommerceKeys() {
  final missing = <String>[];
  missing.addAll(missingAccessoryKeys());
  const tables = <String, Map<String, List<String>>>{
    'shop': shopCopyRows,
    'donationMatch': donationMatchRows,
    'refund': refundRows,
  };
  for (final locale in ShareRunLocalizations.supportedLocales) {
    final code = locale.languageCode;
    final tag = '${locale.languageCode}-${locale.countryCode}';
    if (!accessoryLanguageOrder.contains(code)) {
      missing.add('$tag.commerce');
      continue;
    }
    for (final table in tables.entries) {
      for (final entry in table.value.entries) {
        if (entry.value.length != accessoryLanguageOrder.length) {
          missing.add('$tag.${table.key}.${entry.key}.length');
          continue;
        }
        final value = _rowAt(entry.value, code);
        if (value.trim().isEmpty) missing.add('$tag.${table.key}.${entry.key}');
        if (code != 'ko' && value == entry.value.first) {
          missing.add('$tag.${table.key}.${entry.key}=ko');
        }
      }
    }
    final refund = DiaRefundCopy.of(locale);
    final body = refund.confirmBody(
      paidDia: 120,
      bonusRevoked: 10,
      refundWon: '12,000',
      bonusSpent: 6,
      spentWon: '600',
    );
    if (body.trim().isEmpty) missing.add('$tag.refund.confirmBody');
  }
  for (final entry in _shopKorean.entries) {
    final row = shopCopyRows[entry.key];
    if (row == null || row.first != entry.value) {
      missing.add('shop.${entry.key}.koDrift');
    }
  }
  for (final item in CosmeticsCatalog.defaults.items) {
    final key = _cosmeticIds[item.id];
    final row = key == null ? null : shopCopyRows[key];
    if (row == null || row.first != item.name) {
      missing.add('cosmetic.${item.id}.koDrift');
    }
  }
  return missing;
}
