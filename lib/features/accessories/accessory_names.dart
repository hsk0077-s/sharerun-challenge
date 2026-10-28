import 'package:flutter/widgets.dart';

/// Display names for the 46 accessories. Korean stays on [nameKo].
const accessoryNameLanguages = ['en','ja','zh','es','pt','de','fr','vi','th','id'];

String? accessoryDisplayName(String id, String languageCode) {
  final row = accessoryNames[id];
  if (row == null) return null;
  final index = accessoryNameLanguages.indexOf(languageCode);
  if (index < 0) return row[0];
  return row[index];
}

String accessoryPhrase(Locale locale, String key, {required String name, String price = ''}) {
  final code = accessoryPhrases[key]!.containsKey(locale.languageCode)
      ? locale.languageCode
      : 'en';
  return accessoryPhrases[key]![code]!
      .replaceAll('{name}', name)
      .replaceAll('{price}', price);
}

const accessoryNames = <String, List<String>>{
  'P001': ['Basic running cap', 'ベーシックキャップ', '基本跑步帽', 'Gorra básica', 'Boné básico', 'Laufkappe', 'Casquette', 'Mũ chạy cơ bản', 'หมวกวิ่งพื้นฐาน', 'Topi lari dasar'],
  'P002': ['Sweatband', 'ヘアバンド', '吸汗頭帶', 'Cinta', 'Faixa', 'Schweißband', 'Bandeau', 'Băng đô', 'ผ้าคาดเหงื่อ', 'Ikat kepala'],
  'P003': ['Star hairpin', '星のヘアピン', '星星髮夾', 'Horquilla estrella', 'Presilha estrela', 'Sternspange', 'Pince étoile', 'Kẹp tóc sao', 'กิ๊บดาว', 'Jepit bintang'],
  'P004': ['Running visor', 'バイザー', '跑步遮陽帽', 'Visera', 'Viseira', 'Sonnenschild', 'Visière', 'Lưỡi trai', 'หมวกไวเซอร์', 'Visor lari'],
  'P005': ['Bucket hat', 'バケットハット', '漁夫帽', 'Sombrero bucket', 'Chapéu bucket', 'Fischerhut', 'Bob', 'Mũ bucket', 'หมวกบักเก็ต', 'Topi bucket'],
  'P006': ['Cat-ear headband', '猫耳カチューシャ', '貓耳頭帶', 'Orejas de gato', 'Orelhas de gato', 'Katzenohren', 'Oreilles de chat', 'Bờm tai mèo', 'ที่คาดหูแมว', 'Bando telinga kucing'],
  'P009': ['Cherry blossom crown', '桜の花冠', '櫻花花冠', 'Corona de cerezo', 'Coroa de cerejeira', 'Kirschblütenkranz', 'Couronne de cerisier', 'Vương miện hoa anh đào', 'มงกุฎซากุระ', 'Mahkota sakura'],
  'P018': ['Wireless headphones', 'ワイヤレスヘッドホン', '無線耳機', 'Auriculares', 'Fones sem fio', 'Kopfhörer', 'Casque', 'Tai nghe', 'หูฟังไร้สาย', 'Headphone nirkabel'],
  'GAT': ['Gat', 'カッ', '黑笠', 'Gat', 'Gat', 'Gat', 'Gat', 'Nón gat', 'หมวกกัท', 'Topi gat'],
  'P015': ['Laurel wreath', '月桂冠', '月桂冠', 'Laurel', 'Louro', 'Lorbeer', 'Laurier', 'Nguyệt quế', 'พวงลอเรล', 'Karangan laurel'],
  'P020': ['Sport sunglasses', 'スポーツサングラス', '運動墨鏡', 'Gafas deportivas', 'Óculos esportivos', 'Sportbrille', 'Lunettes de sport', 'Kính thể thao', 'แว่นกีฬา', 'Kacamata olahraga'],
  'P021': ['Round glasses', '丸メガネ', '圓框眼鏡', 'Gafas redondas', 'Óculos redondos', 'Runde Brille', 'Lunettes rondes', 'Kính tròn', 'แว่นกลม', 'Kacamata bulat'],
  'P022': ['Aviators', 'アビエイター', '飛行員墨鏡', 'Aviador', 'Aviador', 'Pilotenbrille', 'Aviateur', 'Kính phi công', 'แว่นเอวิเอเตอร์', 'Aviator'],
  'P023': ['Mirror goggles', 'ミラーゴーグル', '鏡面風鏡', 'Gafas espejo', 'Óculos espelho', 'Spiegelbrille', 'Lunettes miroir', 'Kính tráng gương', 'แว่นปรอท', 'Kacamata cermin'],
  'P024': ['Heart sunglasses', 'ハートサングラス', '愛心墨鏡', 'Gafas corazón', 'Óculos coração', 'Herzbrille', 'Lunettes cœur', 'Kính trái tim', 'แว่นหัวใจ', 'Kacamata hati'],
  'P030': ['Baton', 'バトン', '接力棒', 'Testigo', 'Bastão', 'Staffelstab', 'Témoin', 'Gậy tiếp sức', 'กระบอง', 'Tongkat estafet'],
  'P031': ['Water bottle', '水筒', '水壺', 'Botella', 'Garrafa', 'Flasche', 'Gourde', 'Bình nước', 'กระบอกน้ำ', 'Botol minum'],
  'P032': ['Wristband', 'リストバンド', '腕帶', 'Muñequera', 'Munhequeira', 'Handgelenkband', 'Poignet', 'Băng cổ tay', 'ปลอกข้อมือ', 'Gelang tangan'],
  'P033': ['Torch', '聖火', '火炬', 'Antorcha', 'Tocha', 'Fackel', 'Flambeau', 'Đuốc', 'คบเพลิง', 'Obor'],
  'P034': ['Trophy', 'トロフィー', '獎盃', 'Trofeo', 'Troféu', 'Pokal', 'Trophée', 'Cúp', 'ถ้วยรางวัล', 'Trofi'],
  'P035': ['Cheer flag', '応援フラッグ', '應援旗', 'Bandera', 'Bandeira', 'Fahne', 'Drapeau', 'Cờ cổ vũ', 'ธงเชียร์', 'Bendera sorak'],
  'P036': ['Heart balloon', 'ハート風船', '愛心氣球', 'Globo corazón', 'Balão coração', 'Herzballon', 'Ballon cœur', 'Bóng trái tim', 'ลูกโป่งหัวใจ', 'Balon hati'],
  'P037': ['Light stick', 'ペンライト', '應援棒', 'Barra de luz', 'Bastão de luz', 'Leuchtstab', 'Bâton lumineux', 'Gậy phát sáng', 'แท่งไฟ', 'Light stick'],
  'P038': ['Donation box', '募金箱', '捐款箱', 'Hucha', 'Cofrinho', 'Spendenbüchse', 'Tirelire', 'Ống quyên góp', 'กระปุกบริจาค', 'Kotak donasi'],
  'STOPWATCH': ['Stopwatch', 'ストップウォッチ', '秒錶', 'Cronómetro', 'Cronômetro', 'Stoppuhr', 'Chronomètre', 'Đồng hồ bấm giờ', 'นาฬิกาจับเวลา', 'Stopwatch'],
  'P045': ['Running backpack', 'ランニングバッグ', '跑步背包', 'Mochila', 'Mochila de corrida', 'Laufrucksack', 'Sac à dos', 'Ba lô chạy', 'เป้วิ่ง', 'Ransel lari'],
  'P046': ['Cape', 'マント', '披風', 'Capa', 'Capa', 'Umhang', 'Cape', 'Áo choàng', 'ผ้าคลุม', 'Jubah'],
  'P047': ['Angel wings', '天使の羽', '天使之翼', 'Alas de ángel', 'Asas de anjo', 'Engelsflügel', 'Ailes d\'ange', 'Cánh thiên thần', 'ปีกนางฟ้า', 'Sayap malaikat'],
  'P058': ['Running tee', '半袖Tシャツ', '短袖跑步衫', 'Camiseta', 'Camiseta de corrida', 'Laufshirt', 'T-shirt de course', 'Áo chạy tay ngắn', 'เสื้อวิ่งแขนสั้น', 'Kaos lari'],
  'P059': ['Racing singlet', 'レーシングシングレット', '競賽背心', 'Camiseta de tirantes', 'Regata', 'Singlet', 'Débardeur', 'Áo ba lỗ', 'เสื้อกล้ามแข่ง', 'Singlet balap'],
  'P060': ['Half-zip vest', 'ハーフジップ', '半拉鍊馬甲', 'Chaleco', 'Colete', 'Halbreißverschluss', 'Gilet', 'Áo gile', 'เสื้อฮาล์ฟซิป', 'Rompi half-zip'],
  'P061': ['Sharing heart tee', 'ハートTシャツ', '分享愛心衫', 'Camiseta corazón', 'Camiseta coração', 'Herzshirt', 'T-shirt cœur', 'Áo trái tim', 'เสื้อหัวใจ', 'Kaos hati'],
  'P067': ['Racing shorts', 'レーシングショーツ', '競賽短褲', 'Shorts', 'Shorts de corrida', 'Laufshorts', 'Short', 'Quần đua', 'กางเกงขาสั้นแข่ง', 'Celana lari'],
  'P069': ['Running skirt', 'ランニングスカート', '跑步裙', 'Falda', 'Saia', 'Laufrock', 'Jupe', 'Váy chạy', 'กระโปรงวิ่ง', 'Rok lari'],
  'P074': ['Neon shoes', 'ネオンシューズ', '霓虹跑鞋', 'Zapatillas neón', 'Tênis neon', 'Neonschuhe', 'Chaussures néon', 'Giày neon', 'รองเท้าวิ่งนีออน', 'Sepatu neon'],
  'P075': ['Carbon racers', 'カーボンシューズ', '碳板競速鞋', 'Zapatillas de carbono', 'Tênis de carbono', 'Carbon-Schuhe', 'Chaussures carbone', 'Giày carbon', 'รองเท้าคาร์บอน', 'Sepatu karbon'],
  'P076': ['Cushion shoes', 'クッションシューズ', '緩震跑鞋', 'Zapatillas acolchadas', 'Tênis amortecido', 'Dämpfungsschuhe', 'Chaussures amorties', 'Giày đệm', 'รองเท้าวิ่งนุ่ม', 'Sepatu empuk'],
  'S001': ['Turtle master', 'カメマスター', '烏龜大師', 'Maestro tortuga', 'Mestre tartaruga', 'Schildkrötenmeister', 'Maître tortue', 'Bậc thầy rùa', 'มาสเตอร์เต่า', 'Master kura-kura'],
  'S002': ['Beagle master', 'ビーグルマスター', '比格大師', 'Maestro beagle', 'Mestre beagle', 'Beagle-Meister', 'Maître beagle', 'Bậc thầy beagle', 'มาสเตอร์บีเกิล', 'Master beagle'],
  'S003': ['Wolf master', 'オオカミマスター', '狼大師', 'Maestro lobo', 'Mestre lobo', 'Wolfmeister', 'Maître loup', 'Bậc thầy sói', 'มาสเตอร์หมาป่า', 'Master serigala'],
  'S004': ['Cheetah gold champion', 'チーター金チャンピオン', '獵豹金色冠軍', 'Campeón guepardo', 'Campeão guepardo', 'Geparden-Champion', 'Champion guépard', 'Nhà vô địch báo', 'แชมป์ชีตาห์ทอง', 'Juara cheetah emas'],
  'S005': ['Maple trail', '紅葉トレイル', '楓葉步道', 'Sendero de arce', 'Trilha de bordo', 'Ahorn-Trail', 'Sentier d\'érable', 'Đường lá phong', 'เส้นทางเมเปิล', 'Jejak maple'],
  'S006': ['Night runner', 'ナイトランナー', '夜間跑者', 'Corredor nocturno', 'Corredor noturno', 'Nachtläufer', 'Coureur de nuit', 'Runner đêm', 'นักวิ่งกลางคืน', 'Pelari malam'],
  'S007': ['Marathon finisher', 'マラソン完走', '馬拉松完賽', 'Finalista de maratón', 'Finalista de maratona', 'Marathon-Finisher', 'Finisher marathon', 'Về đích marathon', 'นักจบมาราธอน', 'Finisher maraton'],
  'S008': ['Hanbok', '韓服', '韓服', 'Hanbok', 'Hanbok', 'Hanbok', 'Hanbok', 'Hanbok', 'ฮันบก', 'Hanbok'],
  'S009': ['Zebra master', 'シマウママスター', '斑馬大師', 'Maestro cebra', 'Mestre zebra', 'Zebrameister', 'Maître zèbre', 'Bậc thầy ngựa vằn', 'มาสเตอร์ม้าลาย', 'Master zebra'],
};

const accessoryPhrases = <String, Map<String, String>>{
  'buy': {
    'ko': '{name}을(를) {price}로 살까요?',
    'en': 'Buy {name} for {price}?',
    'ja': '{name}を{price}で買いますか？',
    'zh': '要用 {price} 買{name}嗎？',
    'es': '¿Comprar {name} por {price}?',
    'pt': 'Comprar {name} por {price}?',
    'de': '{name} für {price} kaufen?',
    'fr': 'Acheter {name} pour {price} ?',
    'vi': 'Mua {name} với giá {price}?',
    'th': 'ซื้อ{name}ในราคา {price} ไหม?',
    'id': 'Beli {name} seharga {price}?',
  },
  'bought': {
    'ko': '{name}을(를) 샀어요.',
    'en': 'Bought {name}.',
    'ja': '{name}を買いました。',
    'zh': '買了{name}。',
    'es': 'Compraste {name}.',
    'pt': 'Você comprou {name}.',
    'de': '{name} gekauft.',
    'fr': '{name} acheté.',
    'vi': 'Đã mua {name}.',
    'th': 'ซื้อ{name}แล้ว',
    'id': '{name} terbeli.',
  },
  'wore': {
    'ko': '{name}을(를) 입었어요.',
    'en': 'Now wearing {name}.',
    'ja': '{name}を身につけました。',
    'zh': '穿上了{name}。',
    'es': 'Llevas {name}.',
    'pt': 'Você vestiu {name}.',
    'de': '{name} angezogen.',
    'fr': '{name} est porté.',
    'vi': 'Đã mặc {name}.',
    'th': 'ใส่{name}แล้ว',
    'id': 'Memakai {name}.',
  },
  'off': {
    'ko': '{name}을(를) 벗었어요.',
    'en': 'Took off {name}.',
    'ja': '{name}を外しました。',
    'zh': '脫下了{name}。',
    'es': 'Te quitaste {name}.',
    'pt': 'Você tirou {name}.',
    'de': '{name} ausgezogen.',
    'fr': '{name} est retiré.',
    'vi': 'Đã cởi {name}.',
    'th': 'ถอด{name}แล้ว',
    'id': 'Melepas {name}.',
  },
};
