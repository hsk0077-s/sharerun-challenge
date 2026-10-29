import 'package:flutter/widgets.dart';

import '../features/accessories/accessory_catalog.dart';
import 'app_localizations.dart';

/// Accessory display names for the 11 shop locales.
///
/// Order is [accessoryLanguageOrder]. Korean matches [Accessory.nameKo].
const accessoryLanguageOrder = <String>[
  'ko',
  'en',
  'ja',
  'zh',
  'es',
  'pt',
  'de',
  'fr',
  'vi',
  'th',
  'id',
];

const accessoryNames = <String, List<String>>{
  'P001': ['기본 러닝캡', 'Basic running cap', '基本ランニングキャップ', '基本跑步帽', 'Gorra básica', 'Boné básico', 'Basic-Laufkappe', 'Casquette basique', 'Mũ chạy cơ bản', 'หมวกวิ่งพื้นฐาน', 'Topi lari dasar'],
  'P002': ['땀 헤어밴드', 'Sweat headband', 'スウェットヘアバンド', '吸汗頭帶', 'Cinta para el sudor', 'Faixa de suor', 'Schweißband', 'Bandeau anti-sueur', 'Băng đô thấm mồ hôi', 'ผ้าคาดเหงื่อ', 'Ikat kepala keringat'],
  'P003': ['별 머리핀', 'Star hairpin', '星のヘアピン', '星星髮夾', 'Horquilla de estrella', 'Grampo de estrela', 'Stern-Haarklemme', 'Pince étoile', 'Kẹp tóc ngôi sao', 'กิ๊บรูปดาว', 'Jepit bintang'],
  'P004': ['러닝 바이저', 'Running visor', 'ランニングバイザー', '跑步遮陽帽', 'Visera de correr', 'Viseira de corrida', 'Laufvisier', 'Visière de course', 'Mũ lưỡi trai chạy', 'หมวกไวเซอร์วิ่ง', 'Visor lari'],
  'P005': ['버킷햇', 'Bucket hat', 'バケットハット', '漁夫帽', 'Sombrero bucket', 'Chapéu bucket', 'Bucket-Hut', 'Bob', 'Mũ bucket', 'หมวกบัคเก็ต', 'Topi bucket'],
  'P006': ['고양이귀 머리띠', 'Cat-ear headband', '猫耳カチューシャ', '貓耳髮箍', 'Diadema de orejas de gato', 'Tiara de orelhas de gato', 'Katzenohren-Haarreif', 'Serre-tête oreilles de chat', 'Băng đô tai mèo', 'ที่คาดผมหูแมว', 'Bando telinga kucing'],
  'P009': ['벚꽃 화관', 'Cherry-blossom crown', '桜の花冠', '櫻花花冠', 'Corona de cerezo', 'Coroa de cerejeira', 'Kirschblütenkranz', 'Couronne de cerisier', 'Vương miện hoa anh đào', 'มงกุฎซากุระ', 'Mahkota sakura'],
  'P018': ['무선 헤드폰', 'Wireless headphones', 'ワイヤレスヘッドホン', '無線耳機', 'Auriculares inalámbricos', 'Fones sem fio', 'Kabellose Kopfhörer', 'Casque sans fil', 'Tai nghe không dây', 'หูฟังไร้สาย', 'Headphone nirkabel'],
  'GAT': ['갓', 'Gat hat', 'カッ（伝統の笠）', '黑笠', 'Sombrero gat', 'Chapéu gat', 'Gat-Hut', 'Chapeau gat', 'Nón gat', 'หมวกกัท', 'Topi gat'],
  'P015': ['월계관', 'Laurel wreath', '月桂冠', '月桂冠', 'Corona de laurel', 'Coroa de louros', 'Lorbeerkranz', 'Couronne de laurier', 'Vòng nguyệt quế', 'มงกุฎใบลอเรล', 'Mahkota dafnah'],
  'P020': ['스포츠 선글라스', 'Sport sunglasses', 'スポーツサングラス', '運動太陽眼鏡', 'Gafas deportivas', 'Óculos esportivos', 'Sportsonnenbrille', 'Lunettes de sport', 'Kính thể thao', 'แว่นกันแดดกีฬา', 'Kacamata olahraga'],
  'P021': ['동그란 안경', 'Round glasses', '丸眼鏡', '圓框眼鏡', 'Gafas redondas', 'Óculos redondos', 'Runde Brille', 'Lunettes rondes', 'Kính tròn', 'แว่นกลม', 'Kacamata bulat'],
  'P022': ['에비에이터', 'Aviator glasses', 'アビエイター', '飛行眼鏡', 'Gafas aviador', 'Óculos aviador', 'Pilotenbrille', 'Lunettes aviateur', 'Kính phi công', 'แว่นเอวิเอเตอร์', 'Kacamata aviator'],
  'P023': ['미러 고글', 'Mirror goggles', 'ミラーゴーグル', '鏡面護目鏡', 'Gafas de espejo', 'Óculos espelhados', 'Spiegelbrille', 'Lunettes miroir', 'Kính tráng gương', 'แว่นกระจกเงา', 'Kacamata cermin'],
  'P024': ['하트 선글라스', 'Heart sunglasses', 'ハートサングラス', '愛心太陽眼鏡', 'Gafas de corazón', 'Óculos de coração', 'Herz-Sonnenbrille', 'Lunettes cœur', 'Kính trái tim', 'แว่นรูปหัวใจ', 'Kacamata hati'],
  'P030': ['바통', 'Baton', 'バトン', '接力棒', 'Testigo', 'Bastão', 'Staffelstab', 'Témoin', 'Gậy tiếp sức', 'กระบองวิ่งผลัด', 'Tongkat estafet'],
  'P031': ['물병', 'Water bottle', '水筒', '水壺', 'Botella de agua', 'Garrafa de água', 'Trinkflasche', 'Gourde', 'Bình nước', 'ขวดน้ำ', 'Botol air'],
  'P032': ['손목밴드', 'Wristband', 'リストバンド', '腕帶', 'Muñequera', 'Munhequeira', 'Schweißband Handgelenk', 'Bracelet de poignet', 'Băng cổ tay', 'สายรัดข้อมือ', 'Gelang tangan'],
  'P033': ['성화', 'Torch', '聖火', '聖火', 'Antorcha', 'Tocha', 'Fackel', 'Torche', 'Ngọn đuốc', 'คบเพลิง', 'Obor'],
  'P034': ['트로피 들기', 'Holding a trophy', 'トロフィー', '举起獎盃', 'Trofeo en mano', 'Segurando o troféu', 'Pokal in der Hand', 'Trophée en main', 'Cầm cúp', 'ถือถ้วยรางวัล', 'Memegang piala'],
  'P035': ['응원 깃발', 'Cheer flag', '応援旗', '加油旗', 'Bandera de ánimo', 'Bandeira de torcida', 'Anfeuerungsfahne', 'Drapeau de soutien', 'Cờ cổ vũ', 'ธงเชียร์', 'Bendera sorak'],
  'P036': ['하트 풍선', 'Heart balloon', 'ハート風船', '愛心氣球', 'Globo de corazón', 'Balão de coração', 'Herzballon', 'Ballon cœur', 'Bóng bay trái tim', 'ลูกโป่งหัวใจ', 'Balon hati'],
  'P037': ['응원봉', 'Cheer stick', 'ペンライト', '應援棒', 'Palo de ánimo', 'Bastão de torcida', 'Anfeuerungsstab', 'Bâton lumineux', 'Gậy cổ vũ', 'แท่งไฟเชียร์', 'Stick sorak'],
  'P038': ['기부 저금통', 'Donation box', '寄付の貯金箱', '捐獻撲滿', 'Hucha de donación', 'Cofrinho de doação', 'Spendendose', 'Tirelire de don', 'Ống heo quyên góp', 'กระปุกบริจาค', 'Celengan donasi'],
  'STOPWATCH': ['스톱워치', 'Stopwatch', 'ストップウォッチ', '碼錶', 'Cronómetro', 'Cronômetro', 'Stoppuhr', 'Chronomètre', 'Đồng hồ bấm giờ', 'นาฬิกาจับเวลา', 'Stopwatch lari'],
  'P045': ['러닝 백팩', 'Running backpack', 'ランニングリュック', '跑步背包', 'Mochila de correr', 'Mochila de corrida', 'Laufrucksack', 'Sac à dos de course', 'Ba lô chạy bộ', 'เป้วิ่ง', 'Ransel lari'],
  'P046': ['망토', 'Cape', 'マント', '披風', 'Capa', 'Capa', 'Umhang', 'Cape', 'Áo choàng', 'ผ้าคลุม', 'Jubah'],
  'P047': ['천사 날개', 'Angel wings', '天使の翼', '天使之翼', 'Alas de ángel', 'Asas de anjo', 'Engelsflügel', 'Ailes d’ange', 'Cánh thiên thần', 'ปีกนางฟ้า', 'Sayap malaikat'],
  'P058': ['반팔 러닝티', 'Short-sleeve run shirt', '半袖ランニングT', '短袖跑步衣', 'Camiseta de correr', 'Camiseta de corrida', 'Kurzarm-Laufshirt', 'T-shirt de course', 'Áo chạy tay ngắn', 'เสื้อวิ่งแขนสั้น', 'Kaos lari lengan pendek'],
  'P059': ['레이싱 싱글렛', 'Racing singlet', 'レーシングシングレット', '競賽背心', 'Camiseta de tirantes', 'Regata de prova', 'Renn-Singlet', 'Débardeur de course', 'Áo ba lỗ thi đấu', 'เสื้อกล้ามแข่ง', 'Singlet lomba'],
  'P060': ['하프집 조끼', 'Half-zip vest', 'ハーフジップベスト', '半拉鍊背心', 'Chaleco media cremallera', 'Colete meio zíper', 'Halbzip-Weste', 'Veste demi-zip', 'Áo gile khóa nửa', 'เสื้อกั๊กซิปครึ่ง', 'Vest resleting separuh'],
  'P061': ['나눔 하트 티', 'Sharing heart tee', '分かち合いハートT', '分享愛心T恤', 'Camiseta corazón', 'Camiseta coração', 'Herz-Shirt', 'T-shirt cœur', 'Áo tim sẻ chia', 'เสื้อหัวใจแบ่งปัน', 'Kaos hati berbagi'],
  'P067': ['레이싱 쇼츠', 'Racing shorts', 'レーシングショーツ', '競賽短褲', 'Pantalón corto de carrera', 'Shorts de prova', 'Rennshorts', 'Short de course', 'Quần đua', 'กางเกงแข่ง', 'Celana lari lomba'],
  'P069': ['러닝스커트', 'Running skirt', 'ランニングスカート', '跑步裙', 'Falda de correr', 'Saia de corrida', 'Laufrock', 'Jupe de course', 'Váy chạy', 'กระโปรงวิ่ง', 'Rok lari'],
  'P074': ['네온 러닝화', 'Neon running shoes', 'ネオンランニングシューズ', '霓虹跑鞋', 'Zapatillas neón', 'Tênis neon', 'Neon-Laufschuhe', 'Chaussures néon', 'Giày chạy neon', 'รองเท้าวิ่งนีออน', 'Sepatu lari neon'],
  'P075': ['카본 레이싱화', 'Carbon racing shoes', 'カーボンレーシングシューズ', '碳板競速鞋', 'Zapatillas de carbono', 'Tênis de carbono', 'Carbon-Rennschuhe', 'Chaussures carbone', 'Giày đua carbon', 'รองเท้าแข่งคาร์บอน', 'Sepatu lomba karbon'],
  'P076': ['쿠션화', 'Cushioned shoes', 'クッションシューズ', '緩衝跑鞋', 'Zapatillas con amortiguación', 'Tênis amortecido', 'Gedämpfte Laufschuhe', 'Chaussures amorties', 'Giày đệm êm', 'รองเท้าวิ่งนุ่ม', 'Sepatu lari empuk'],
  'S001': ['거북 마스터', 'Turtle master', 'カメマスター', '烏龜大師', 'Maestro tortuga', 'Mestre tartaruga', 'Schildkröten-Meister', 'Maître tortue', 'Bậc thầy rùa', 'มาสเตอร์เต่า', 'Master kura-kura'],
  'S002': ['비글 마스터', 'Beagle master', 'ビーグルマスター', '米格魯大師', 'Maestro beagle', 'Mestre beagle', 'Beagle-Meister', 'Maître beagle', 'Bậc thầy beagle', 'มาสเตอร์บีเกิล', 'Master beagle'],
  'S003': ['늑대 마스터', 'Wolf master', 'オオカミマスター', '狼大師', 'Maestro lobo', 'Mestre lobo', 'Wolf-Meister', 'Maître loup', 'Bậc thầy sói', 'มาสเตอร์หมาป่า', 'Master serigala'],
  'S004': ['치타 금빛 챔피언', 'Cheetah gold champion', 'チーター金のチャンピオン', '獵豹金色冠軍', 'Campeón guepardo dorado', 'Campeão chita dourado', 'Gepard-Goldchampion', 'Champion guépard doré', 'Nhà vô địch báo vàng', 'แชมป์เสือชีต้าทอง', 'Juara citah emas'],
  'S005': ['단풍 트레일러', 'Maple trail runner', '紅葉トレイラー', '楓葉越野者', 'Corredor de arces', 'Corredor das folhas', 'Ahorn-Trailrunner', 'Coureur aux érables', 'Người chạy đường lá phong', 'นักวิ่งป่าเมเปิล', 'Pelari jejak maple'],
  'S006': ['야간 러너', 'Night runner', 'ナイトランナー', '夜間跑者', 'Corredor nocturno', 'Corredor noturno', 'Nachtläufer', 'Coureur de nuit', 'Người chạy đêm', 'นักวิ่งกลางคืน', 'Pelari malam'],
  'S007': ['마라톤 완주자', 'Marathon finisher', 'マラソン完走者', '馬拉松完賽者', 'Finalista de maratón', 'Concluiu a maratona', 'Marathon-Finisher', 'Finisher de marathon', 'Người về đích marathon', 'ผู้เข้าเส้นชัยมาราธอน', 'Finisher maraton'],
  'S008': ['한복', 'Hanbok outfit', '韓服', '韓服', 'Hanbok', 'Hanbok', 'Hanbok', 'Hanbok', 'Hanbok', 'ฮันบก', 'Hanbok'],
  'S009': ['얼룩말 마스터', 'Zebra master', 'シマウママスター', '斑馬大師', 'Maestro cebra', 'Mestre zebra', 'Zebra-Meister', 'Maître zèbre', 'Bậc thầy ngựa vằn', 'มาสเตอร์ม้าลาย', 'Master zebra'],
};

/// Short shop sentences that include an accessory name.
const accessoryPhrases = <String, List<String>>{
  'buyTitle': ['소품 사기', 'Buy an accessory', '小物を買う', '購買配件', 'Comprar accesorio', 'Comprar acessório', 'Zubehör kaufen', 'Acheter un accessoire', 'Mua phụ kiện', 'ซื้อของตกแต่ง', 'Beli aksesori'],
  'buyAsk': [
    '{name}을(를) {price}로 살까요?',
    'Buy {name} for {price}?',
    '{name}を{price}で買いますか？',
    '要用 {price} 買{name}嗎？',
    '¿Comprar {name} por {price}?',
    'Comprar {name} por {price}?',
    '{name} für {price} kaufen?',
    'Acheter {name} pour {price} ?',
    'Mua {name} với giá {price}?',
    'ซื้อ {name} ในราคา {price} ไหม',
    'Beli {name} seharga {price}?',
  ],
  'bonusFirst': [
    '\n보너스 DIA가 있으면 먼저 써요.',
    '\nBonus DIA is spent first when you have some.',
    '\nボーナスDIAがあるときは先に使います。',
    '\n有獎勵 DIA 時會先扣獎勵。',
    '\nSi hay DIA de regalo, se gasta primero.',
    '\nDIA bônus, se houver, é gasto primeiro.',
    '\nBonus-DIA wird zuerst verbraucht.',
    '\nLes DIA bonus sont dépensés en premier.',
    '\nDIA thưởng, nếu có, được trừ trước.',
    '\nถ้ามี DIA โบนัส จะใช้โบนัสก่อน',
    '\nDIA bonus, kalau ada, terpakai lebih dulu.',
  ],
  'cancel': ['취소', 'Cancel', 'キャンセル', '取消', 'Cancelar', 'Cancelar', 'Abbrechen', 'Annuler', 'Hủy', 'ยกเลิก', 'Batal'],
  'buy': ['사기', 'Buy', '買う', '購買', 'Comprar', 'Comprar', 'Kaufen', 'Acheter', 'Mua', 'ซื้อ', 'Beli'],
  'bought': [
    '{name}을(를) 샀어요.',
    'You bought {name}.',
    '{name}を買いました。',
    '已買下{name}。',
    'Has comprado {name}.',
    'Você comprou {name}.',
    'Du hast {name} gekauft.',
    'Vous avez acheté {name}.',
    'Bạn đã mua {name}.',
    'คุณซื้อ {name} แล้ว',
    'Kamu membeli {name}.',
  ],
  'worn': [
    '{name}을(를) 입었어요.',
    'You put on {name}.',
    '{name}を身につけました。',
    '已戴上{name}。',
    'Te has puesto {name}.',
    'Você vestiu {name}.',
    'Du hast {name} angezogen.',
    'Vous portez {name}.',
    'Bạn đã mặc {name}.',
    'คุณใส่ {name} แล้ว',
    'Kamu memakai {name}.',
  ],
  'removed': [
    '{name}을(를) 벗었어요.',
    'You took off {name}.',
    '{name}を外しました。',
    '已卸下{name}。',
    'Te has quitado {name}.',
    'Você tirou {name}.',
    'Du hast {name} abgelegt.',
    'Vous avez retiré {name}.',
    'Bạn đã tháo {name}.',
    'คุณถอด {name} แล้ว',
    'Kamu melepas {name}.',
  ],
};

String accessoryName(String id, String fallbackKo, Locale locale) {
  final row = accessoryNames[id];
  if (row == null) return fallbackKo;
  final index = accessoryLanguageOrder.indexOf(locale.languageCode);
  if (index < 0 || index >= row.length || row[index].isEmpty) {
    final english = accessoryLanguageOrder.indexOf('en');
    return row[english];
  }
  return row[index];
}

String accessoryPhrase(
  Locale locale,
  String key, {
  String name = '',
  String price = '',
}) {
  final row = accessoryPhrases[key];
  if (row == null) return '';
  final index = accessoryLanguageOrder.indexOf(locale.languageCode);
  final value = (index < 0 || index >= row.length || row[index].isEmpty)
      ? row[accessoryLanguageOrder.indexOf('en')]
      : row[index];
  return value.replaceAll('{name}', name).replaceAll('{price}', price);
}

/// Empty when every catalog id and phrase exists in all 11 locales,
/// and Korean names still match the catalog.
List<String> missingAccessoryKeys() {
  final missing = <String>[];
  final ids = accessoryCatalog.map((item) => item.id).toSet();
  for (final id in ids) {
    final row = accessoryNames[id];
    if (row == null || row.length != accessoryLanguageOrder.length) {
      missing.add('accessory.$id');
      continue;
    }
    final catalog = accessoryCatalog.firstWhere((item) => item.id == id);
    if (row.first != catalog.nameKo) missing.add('accessory.$id.ko');
    for (var i = 0; i < row.length; i++) {
      if (row[i].trim().isEmpty) {
        missing.add('accessory.$id.${accessoryLanguageOrder[i]}');
      } else if (i != 0 && row[i] == row.first) {
        missing.add('accessory.$id.${accessoryLanguageOrder[i]}=ko');
      }
    }
  }
  for (final entry in accessoryPhrases.entries) {
    if (entry.value.length != accessoryLanguageOrder.length) {
      missing.add('accessoryPhrase.${entry.key}');
      continue;
    }
    for (var i = 0; i < entry.value.length; i++) {
      if (entry.value[i].trim().isEmpty) {
        missing.add('accessoryPhrase.${entry.key}.${accessoryLanguageOrder[i]}');
      }
    }
  }
  for (final locale in ShareRunLocalizations.supportedLocales) {
    if (!accessoryLanguageOrder.contains(locale.languageCode)) {
      missing.add('accessory.locale.${locale.languageCode}');
    }
  }
  return missing;
}
