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
  'S008': ['한복(동물)', 'Hanbok outfit (animal)', '韓服（どうぶつ）', '韓服（動物）', 'Hanbok (animal)', 'Hanbok (animal)', 'Hanbok (Tier)', 'Hanbok (animal)', 'Hanbok (thú)', 'ฮันบก (สัตว์)', 'Hanbok (hewan)'],
  'S009': ['얼룩말 마스터', 'Zebra master', 'シマウママスター', '斑馬大師', 'Maestro cebra', 'Mestre zebra', 'Zebra-Meister', 'Maître zèbre', 'Bậc thầy ngựa vằn', 'มาสเตอร์ม้าลาย', 'Master zebra'],
  'W1A': ['축구 유니폼 (동물)', 'Soccer kit (animal)', 'サッカーウェア （どうぶつ）', '足球服 （動物）', 'Equipación de fútbol (animal)', 'Uniforme de futebol (animal)', 'Fußball-Outfit (Tier)', 'Tenue de football (animal)', 'Đồ bóng đá (thú)', 'ชุดฟุตบอล (สัตว์)', 'Seragam sepak bola (hewan)'],
  'W1C': ['축구 유니폼 (캐릭터)', 'Soccer kit (character)', 'サッカーウェア （キャラクター）', '足球服 （角色）', 'Equipación de fútbol (personaje)', 'Uniforme de futebol (personagem)', 'Fußball-Outfit (Figur)', 'Tenue de football (personnage)', 'Đồ bóng đá (nhân vật)', 'ชุดฟุตบอล (ตัวละคร)', 'Seragam sepak bola (karakter)'],
  'W1B': ['축구 유니폼 (동물+캐릭터 세트)', 'Soccer kit (animal + character set)', 'サッカーウェア （どうぶつ＋キャラセット）', '足球服 （動物+角色組合）', 'Equipación de fútbol (set animal + personaje)', 'Uniforme de futebol (conjunto animal + personagem)', 'Fußball-Outfit (Set Tier + Figur)', 'Tenue de football (pack animal + personnage)', 'Đồ bóng đá (bộ thú + nhân vật)', 'ชุดฟุตบอล (ชุดสัตว์+ตัวละคร)', 'Seragam sepak bola (paket hewan + karakter)'],
  'W2A': ['육상 러닝 싱글렛 (동물)', 'Track singlet (animal)', '陸上シングレット （どうぶつ）', '田徑背心 （動物）', 'Camiseta de atletismo (animal)', 'Regata de atletismo (animal)', 'Leichtathletik-Singlet (Tier)', 'Débardeur d\'athlétisme (animal)', 'Áo ba lỗ điền kinh (thú)', 'เสื้อกล้ามกรีฑา (สัตว์)', 'Singlet atletik (hewan)'],
  'W2C': ['육상 러닝 싱글렛 (캐릭터)', 'Track singlet (character)', '陸上シングレット （キャラクター）', '田徑背心 （角色）', 'Camiseta de atletismo (personaje)', 'Regata de atletismo (personagem)', 'Leichtathletik-Singlet (Figur)', 'Débardeur d\'athlétisme (personnage)', 'Áo ba lỗ điền kinh (nhân vật)', 'เสื้อกล้ามกรีฑา (ตัวละคร)', 'Singlet atletik (karakter)'],
  'W2B': ['육상 러닝 싱글렛 (동물+캐릭터 세트)', 'Track singlet (animal + character set)', '陸上シングレット （どうぶつ＋キャラセット）', '田徑背心 （動物+角色組合）', 'Camiseta de atletismo (set animal + personaje)', 'Regata de atletismo (conjunto animal + personagem)', 'Leichtathletik-Singlet (Set Tier + Figur)', 'Débardeur d\'athlétisme (pack animal + personnage)', 'Áo ba lỗ điền kinh (bộ thú + nhân vật)', 'เสื้อกล้ามกรีฑา (ชุดสัตว์+ตัวละคร)', 'Singlet atletik (paket hewan + karakter)'],
  'W3A': ['농구 유니폼 (동물)', 'Basketball kit (animal)', 'バスケットウェア （どうぶつ）', '籃球服 （動物）', 'Equipación de baloncesto (animal)', 'Uniforme de basquete (animal)', 'Basketball-Outfit (Tier)', 'Tenue de basket (animal)', 'Đồ bóng rổ (thú)', 'ชุดบาสเกตบอล (สัตว์)', 'Seragam basket (hewan)'],
  'W3C': ['농구 유니폼 (캐릭터)', 'Basketball kit (character)', 'バスケットウェア （キャラクター）', '籃球服 （角色）', 'Equipación de baloncesto (personaje)', 'Uniforme de basquete (personagem)', 'Basketball-Outfit (Figur)', 'Tenue de basket (personnage)', 'Đồ bóng rổ (nhân vật)', 'ชุดบาสเกตบอล (ตัวละคร)', 'Seragam basket (karakter)'],
  'W3B': ['농구 유니폼 (동물+캐릭터 세트)', 'Basketball kit (animal + character set)', 'バスケットウェア （どうぶつ＋キャラセット）', '籃球服 （動物+角色組合）', 'Equipación de baloncesto (set animal + personaje)', 'Uniforme de basquete (conjunto animal + personagem)', 'Basketball-Outfit (Set Tier + Figur)', 'Tenue de basket (pack animal + personnage)', 'Đồ bóng rổ (bộ thú + nhân vật)', 'ชุดบาสเกตบอล (ชุดสัตว์+ตัวละคร)', 'Seragam basket (paket hewan + karakter)'],
  'W4A': ['야구 유니폼 (동물)', 'Baseball uniform (animal)', '野球ユニフォーム （どうぶつ）', '棒球服 （動物）', 'Uniforme de béisbol (animal)', 'Uniforme de beisebol (animal)', 'Baseball-Uniform (Tier)', 'Tenue de baseball (animal)', 'Đồng phục bóng chày (thú)', 'ชุดเบสบอล (สัตว์)', 'Seragam bisbol (hewan)'],
  'W4C': ['야구 유니폼 (캐릭터)', 'Baseball uniform (character)', '野球ユニフォーム （キャラクター）', '棒球服 （角色）', 'Uniforme de béisbol (personaje)', 'Uniforme de beisebol (personagem)', 'Baseball-Uniform (Figur)', 'Tenue de baseball (personnage)', 'Đồng phục bóng chày (nhân vật)', 'ชุดเบสบอล (ตัวละคร)', 'Seragam bisbol (karakter)'],
  'W4B': ['야구 유니폼 (동물+캐릭터 세트)', 'Baseball uniform (animal + character set)', '野球ユニフォーム （どうぶつ＋キャラセット）', '棒球服 （動物+角色組合）', 'Uniforme de béisbol (set animal + personaje)', 'Uniforme de beisebol (conjunto animal + personagem)', 'Baseball-Uniform (Set Tier + Figur)', 'Tenue de baseball (pack animal + personnage)', 'Đồng phục bóng chày (bộ thú + nhân vật)', 'ชุดเบสบอล (ชุดสัตว์+ตัวละคร)', 'Seragam bisbol (paket hewan + karakter)'],
  'W5A': ['배드민턴 유니폼 (동물)', 'Badminton kit (animal)', 'バドミントンウェア （どうぶつ）', '羽球服 （動物）', 'Equipación de bádminton (animal)', 'Uniforme de badminton (animal)', 'Badminton-Outfit (Tier)', 'Tenue de badminton (animal)', 'Đồ cầu lông (thú)', 'ชุดแบดมินตัน (สัตว์)', 'Seragam bulu tangkis (hewan)'],
  'W5C': ['배드민턴 유니폼 (캐릭터)', 'Badminton kit (character)', 'バドミントンウェア （キャラクター）', '羽球服 （角色）', 'Equipación de bádminton (personaje)', 'Uniforme de badminton (personagem)', 'Badminton-Outfit (Figur)', 'Tenue de badminton (personnage)', 'Đồ cầu lông (nhân vật)', 'ชุดแบดมินตัน (ตัวละคร)', 'Seragam bulu tangkis (karakter)'],
  'W5B': ['배드민턴 유니폼 (동물+캐릭터 세트)', 'Badminton kit (animal + character set)', 'バドミントンウェア （どうぶつ＋キャラセット）', '羽球服 （動物+角色組合）', 'Equipación de bádminton (set animal + personaje)', 'Uniforme de badminton (conjunto animal + personagem)', 'Badminton-Outfit (Set Tier + Figur)', 'Tenue de badminton (pack animal + personnage)', 'Đồ cầu lông (bộ thú + nhân vật)', 'ชุดแบดมินตัน (ชุดสัตว์+ตัวละคร)', 'Seragam bulu tangkis (paket hewan + karakter)'],
  'W6A': ['태권도 도복 (동물)', 'Taekwondo dobok (animal)', 'テコンドー道着 （どうぶつ）', '跆拳道服 （動物）', 'Dobok de taekwondo (animal)', 'Dobok de taekwondo (animal)', 'Taekwondo-Dobok (Tier)', 'Dobok de taekwondo (animal)', 'Võ phục taekwondo (thú)', 'ชุดเทควันโด (สัตว์)', 'Dobok taekwondo (hewan)'],
  'W6C': ['태권도 도복 (캐릭터)', 'Taekwondo dobok (character)', 'テコンドー道着 （キャラクター）', '跆拳道服 （角色）', 'Dobok de taekwondo (personaje)', 'Dobok de taekwondo (personagem)', 'Taekwondo-Dobok (Figur)', 'Dobok de taekwondo (personnage)', 'Võ phục taekwondo (nhân vật)', 'ชุดเทควันโด (ตัวละคร)', 'Dobok taekwondo (karakter)'],
  'W6B': ['태권도 도복 (동물+캐릭터 세트)', 'Taekwondo dobok (animal + character set)', 'テコンドー道着 （どうぶつ＋キャラセット）', '跆拳道服 （動物+角色組合）', 'Dobok de taekwondo (set animal + personaje)', 'Dobok de taekwondo (conjunto animal + personagem)', 'Taekwondo-Dobok (Set Tier + Figur)', 'Dobok de taekwondo (pack animal + personnage)', 'Võ phục taekwondo (bộ thú + nhân vật)', 'ชุดเทควันโด (ชุดสัตว์+ตัวละคร)', 'Dobok taekwondo (paket hewan + karakter)'],
  'T1M': ['한국 한복 (캐릭터·남)', 'Korean hanbok (character · male)', '韓国の韓服 （キャラ・男性）', '韓國韓服 （角色・男）', 'Hanbok de Corea (personaje · hombre)', 'Hanbok da Coreia (personagem · masc.)', 'Koreanischer Hanbok (Figur · männlich)', 'Hanbok coréen (personnage · homme)', 'Hanbok Hàn Quốc (nhân vật · nam)', 'ฮันบกเกาหลี (ตัวละคร · ชาย)', 'Hanbok Korea (karakter · pria)'],
  'T1F': ['한국 한복 (캐릭터·여)', 'Korean hanbok (character · female)', '韓国の韓服 （キャラ・女性）', '韓國韓服 （角色・女）', 'Hanbok de Corea (personaje · mujer)', 'Hanbok da Coreia (personagem · fem.)', 'Koreanischer Hanbok (Figur · weiblich)', 'Hanbok coréen (personnage · femme)', 'Hanbok Hàn Quốc (nhân vật · nữ)', 'ฮันบกเกาหลี (ตัวละคร · หญิง)', 'Hanbok Korea (karakter · wanita)'],
  'T1S': ['한국 한복 (캐릭터·남녀 세트)', 'Korean hanbok (character · male + female set)', '韓国の韓服 （キャラ・男女セット）', '韓國韓服 （角色・男女組合）', 'Hanbok de Corea (set personaje hombre + mujer)', 'Hanbok da Coreia (conjunto personagem masc. + fem.)', 'Koreanischer Hanbok (Set Figur männlich + weiblich)', 'Hanbok coréen (pack personnage homme + femme)', 'Hanbok Hàn Quốc (bộ nhân vật nam + nữ)', 'ฮันบกเกาหลี (ชุดตัวละคร ชาย+หญิง)', 'Hanbok Korea (paket karakter pria + wanita)'],
  'T2M': ['일본 유카타 (캐릭터·남)', 'Japanese yukata (character · male)', '日本の浴衣 （キャラ・男性）', '日本浴衣 （角色・男）', 'Yukata de Japón (personaje · hombre)', 'Yukata do Japão (personagem · masc.)', 'Japanischer Yukata (Figur · männlich)', 'Yukata japonais (personnage · homme)', 'Yukata Nhật Bản (nhân vật · nam)', 'ยูกาตะญี่ปุ่น (ตัวละคร · ชาย)', 'Yukata Jepang (karakter · pria)'],
  'T2F': ['일본 유카타 (캐릭터·여)', 'Japanese yukata (character · female)', '日本の浴衣 （キャラ・女性）', '日本浴衣 （角色・女）', 'Yukata de Japón (personaje · mujer)', 'Yukata do Japão (personagem · fem.)', 'Japanischer Yukata (Figur · weiblich)', 'Yukata japonais (personnage · femme)', 'Yukata Nhật Bản (nhân vật · nữ)', 'ยูกาตะญี่ปุ่น (ตัวละคร · หญิง)', 'Yukata Jepang (karakter · wanita)'],
  'T2S': ['일본 유카타 (캐릭터·남녀 세트)', 'Japanese yukata (character · male + female set)', '日本の浴衣 （キャラ・男女セット）', '日本浴衣 （角色・男女組合）', 'Yukata de Japón (set personaje hombre + mujer)', 'Yukata do Japão (conjunto personagem masc. + fem.)', 'Japanischer Yukata (Set Figur männlich + weiblich)', 'Yukata japonais (pack personnage homme + femme)', 'Yukata Nhật Bản (bộ nhân vật nam + nữ)', 'ยูกาตะญี่ปุ่น (ชุดตัวละคร ชาย+หญิง)', 'Yukata Jepang (paket karakter pria + wanita)'],
  'T3M': ['베트남 아오자이 (캐릭터·남)', 'Vietnamese áo dài (character · male)', 'ベトナムのアオザイ （キャラ・男性）', '越南奧黛 （角色・男）', 'Áo dài de Vietnam (personaje · hombre)', 'Áo dài do Vietnã (personagem · masc.)', 'Vietnamesischer Áo dài (Figur · männlich)', 'Áo dài vietnamien (personnage · homme)', 'Áo dài Việt Nam (nhân vật · nam)', 'อ๊าวหญ่ายเวียดนาม (ตัวละคร · ชาย)', 'Áo dài Vietnam (karakter · pria)'],
  'T3F': ['베트남 아오자이 (캐릭터·여)', 'Vietnamese áo dài (character · female)', 'ベトナムのアオザイ （キャラ・女性）', '越南奧黛 （角色・女）', 'Áo dài de Vietnam (personaje · mujer)', 'Áo dài do Vietnã (personagem · fem.)', 'Vietnamesischer Áo dài (Figur · weiblich)', 'Áo dài vietnamien (personnage · femme)', 'Áo dài Việt Nam (nhân vật · nữ)', 'อ๊าวหญ่ายเวียดนาม (ตัวละคร · หญิง)', 'Áo dài Vietnam (karakter · wanita)'],
  'T3S': ['베트남 아오자이 (캐릭터·남녀 세트)', 'Vietnamese áo dài (character · male + female set)', 'ベトナムのアオザイ （キャラ・男女セット）', '越南奧黛 （角色・男女組合）', 'Áo dài de Vietnam (set personaje hombre + mujer)', 'Áo dài do Vietnã (conjunto personagem masc. + fem.)', 'Vietnamesischer Áo dài (Set Figur männlich + weiblich)', 'Áo dài vietnamien (pack personnage homme + femme)', 'Áo dài Việt Nam (bộ nhân vật nam + nữ)', 'อ๊าวหญ่ายเวียดนาม (ชุดตัวละคร ชาย+หญิง)', 'Áo dài Vietnam (paket karakter pria + wanita)'],
  'T4M': ['독일 바이에른 축제복 (캐릭터·남)', 'Bavarian festival wear (Germany) (character · male)', 'ドイツ・バイエルンの祭り衣装 （キャラ・男性）', '德國巴伐利亞節慶服 （角色・男）', 'Traje festivo de Baviera (Alemania) (personaje · hombre)', 'Traje festivo da Baviera (Alemanha) (personagem · masc.)', 'Bayerische Festtracht (Deutschland) (Figur · männlich)', 'Tenue de fête bavaroise (Allemagne) (personnage · homme)', 'Trang phục lễ hội Bavaria (Đức) (nhân vật · nam)', 'ชุดเทศกาลบาวาเรีย (เยอรมนี) (ตัวละคร · ชาย)', 'Busana festival Bavaria (Jerman) (karakter · pria)'],
  'T4F': ['독일 바이에른 축제복 (캐릭터·여)', 'Bavarian festival wear (Germany) (character · female)', 'ドイツ・バイエルンの祭り衣装 （キャラ・女性）', '德國巴伐利亞節慶服 （角色・女）', 'Traje festivo de Baviera (Alemania) (personaje · mujer)', 'Traje festivo da Baviera (Alemanha) (personagem · fem.)', 'Bayerische Festtracht (Deutschland) (Figur · weiblich)', 'Tenue de fête bavaroise (Allemagne) (personnage · femme)', 'Trang phục lễ hội Bavaria (Đức) (nhân vật · nữ)', 'ชุดเทศกาลบาวาเรีย (เยอรมนี) (ตัวละคร · หญิง)', 'Busana festival Bavaria (Jerman) (karakter · wanita)'],
  'T4S': ['독일 바이에른 축제복 (캐릭터·남녀 세트)', 'Bavarian festival wear (Germany) (character · male + female set)', 'ドイツ・バイエルンの祭り衣装 （キャラ・男女セット）', '德國巴伐利亞節慶服 （角色・男女組合）', 'Traje festivo de Baviera (Alemania) (set personaje hombre + mujer)', 'Traje festivo da Baviera (Alemanha) (conjunto personagem masc. + fem.)', 'Bayerische Festtracht (Deutschland) (Set Figur männlich + weiblich)', 'Tenue de fête bavaroise (Allemagne) (pack personnage homme + femme)', 'Trang phục lễ hội Bavaria (Đức) (bộ nhân vật nam + nữ)', 'ชุดเทศกาลบาวาเรีย (เยอรมนี) (ชุดตัวละคร ชาย+หญิง)', 'Busana festival Bavaria (Jerman) (paket karakter pria + wanita)'],
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
  'partOwned': [
    '일부 버전을 이미 갖고 있어요. 남은 버전을 따로 사 주세요.',
    'You already own part of this set. Buy the remaining version on its own.',
    'このセットの一部をすでにお持ちです。残りは単品で買ってください。',
    '你已擁有此組合的一部分，請單獨購買其餘版本。',
    'Ya tienes parte de este set. Compra la versión que falta por separado.',
    'Você já tem parte deste conjunto. Compre a versão que falta separadamente.',
    'Du besitzt schon einen Teil dieses Sets. Kaufe die fehlende Version einzeln.',
    'Vous possédez déjà une partie de ce pack. Achetez la version manquante séparément.',
    'Bạn đã có một phần của bộ này. Hãy mua riêng phiên bản còn lại.',
    'คุณมีบางส่วนของชุดนี้แล้ว โปรดซื้อเวอร์ชันที่เหลือแยกต่างหาก',
    'Kamu sudah punya sebagian paket ini. Beli versi yang kurang secara terpisah.',
  ],
  'otherGender': [
    '다른 성별 버전이에요',
    'This is the other gender\'s version',
    'もう一方の性別用です',
    '這是另一個性別的版本',
    'Es la versión del otro género',
    'É a versão do outro gênero',
    'Das ist die Version für das andere Geschlecht',
    'C\'est la version de l\'autre genre',
    'Đây là phiên bản của giới tính còn lại',
    'นี่คือเวอร์ชันของอีกเพศ',
    'Ini versi untuk gender lainnya',
  ],
  'setBadge': [
    '세트',
    'Set',
    'セット',
    '組合',
    'Set',
    'Conjunto',
    'Set',
    'Pack',
    'Bộ',
    'ชุด',
    'Paket',
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
