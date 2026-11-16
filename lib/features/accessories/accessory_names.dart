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
  'S008': ['Hanbok (animal)', '韓服（どうぶつ）', '韓服（動物）', 'Hanbok (animal)', 'Hanbok (animal)', 'Hanbok (Tier)', 'Hanbok (animal)', 'Hanbok (thú)', 'ฮันบก (สัตว์)', 'Hanbok (hewan)'],
  'S009': ['Zebra master', 'シマウママスター', '斑馬大師', 'Maestro cebra', 'Mestre zebra', 'Zebrameister', 'Maître zèbre', 'Bậc thầy ngựa vằn', 'มาสเตอร์ม้าลาย', 'Master zebra'],
  'W1A': ['Soccer kit (animal)', 'サッカーウェア （どうぶつ）', '足球服 （動物）', 'Equipación de fútbol (animal)', 'Uniforme de futebol (animal)', 'Fußball-Outfit (Tier)', 'Tenue de football (animal)', 'Đồ bóng đá (thú)', 'ชุดฟุตบอล (สัตว์)', 'Seragam sepak bola (hewan)'],
  'W1C': ['Soccer kit (character)', 'サッカーウェア （キャラクター）', '足球服 （角色）', 'Equipación de fútbol (personaje)', 'Uniforme de futebol (personagem)', 'Fußball-Outfit (Figur)', 'Tenue de football (personnage)', 'Đồ bóng đá (nhân vật)', 'ชุดฟุตบอล (ตัวละคร)', 'Seragam sepak bola (karakter)'],
  'W1B': ['Soccer kit (animal + character set)', 'サッカーウェア （どうぶつ＋キャラセット）', '足球服 （動物+角色組合）', 'Equipación de fútbol (set animal + personaje)', 'Uniforme de futebol (conjunto animal + personagem)', 'Fußball-Outfit (Set Tier + Figur)', 'Tenue de football (pack animal + personnage)', 'Đồ bóng đá (bộ thú + nhân vật)', 'ชุดฟุตบอล (ชุดสัตว์+ตัวละคร)', 'Seragam sepak bola (paket hewan + karakter)'],
  'W2A': ['Track singlet (animal)', '陸上シングレット （どうぶつ）', '田徑背心 （動物）', 'Camiseta de atletismo (animal)', 'Regata de atletismo (animal)', 'Leichtathletik-Singlet (Tier)', 'Débardeur d\'athlétisme (animal)', 'Áo ba lỗ điền kinh (thú)', 'เสื้อกล้ามกรีฑา (สัตว์)', 'Singlet atletik (hewan)'],
  'W2C': ['Track singlet (character)', '陸上シングレット （キャラクター）', '田徑背心 （角色）', 'Camiseta de atletismo (personaje)', 'Regata de atletismo (personagem)', 'Leichtathletik-Singlet (Figur)', 'Débardeur d\'athlétisme (personnage)', 'Áo ba lỗ điền kinh (nhân vật)', 'เสื้อกล้ามกรีฑา (ตัวละคร)', 'Singlet atletik (karakter)'],
  'W2B': ['Track singlet (animal + character set)', '陸上シングレット （どうぶつ＋キャラセット）', '田徑背心 （動物+角色組合）', 'Camiseta de atletismo (set animal + personaje)', 'Regata de atletismo (conjunto animal + personagem)', 'Leichtathletik-Singlet (Set Tier + Figur)', 'Débardeur d\'athlétisme (pack animal + personnage)', 'Áo ba lỗ điền kinh (bộ thú + nhân vật)', 'เสื้อกล้ามกรีฑา (ชุดสัตว์+ตัวละคร)', 'Singlet atletik (paket hewan + karakter)'],
  'W3A': ['Basketball kit (animal)', 'バスケットウェア （どうぶつ）', '籃球服 （動物）', 'Equipación de baloncesto (animal)', 'Uniforme de basquete (animal)', 'Basketball-Outfit (Tier)', 'Tenue de basket (animal)', 'Đồ bóng rổ (thú)', 'ชุดบาสเกตบอล (สัตว์)', 'Seragam basket (hewan)'],
  'W3C': ['Basketball kit (character)', 'バスケットウェア （キャラクター）', '籃球服 （角色）', 'Equipación de baloncesto (personaje)', 'Uniforme de basquete (personagem)', 'Basketball-Outfit (Figur)', 'Tenue de basket (personnage)', 'Đồ bóng rổ (nhân vật)', 'ชุดบาสเกตบอล (ตัวละคร)', 'Seragam basket (karakter)'],
  'W3B': ['Basketball kit (animal + character set)', 'バスケットウェア （どうぶつ＋キャラセット）', '籃球服 （動物+角色組合）', 'Equipación de baloncesto (set animal + personaje)', 'Uniforme de basquete (conjunto animal + personagem)', 'Basketball-Outfit (Set Tier + Figur)', 'Tenue de basket (pack animal + personnage)', 'Đồ bóng rổ (bộ thú + nhân vật)', 'ชุดบาสเกตบอล (ชุดสัตว์+ตัวละคร)', 'Seragam basket (paket hewan + karakter)'],
  'W4A': ['Baseball uniform (animal)', '野球ユニフォーム （どうぶつ）', '棒球服 （動物）', 'Uniforme de béisbol (animal)', 'Uniforme de beisebol (animal)', 'Baseball-Uniform (Tier)', 'Tenue de baseball (animal)', 'Đồng phục bóng chày (thú)', 'ชุดเบสบอล (สัตว์)', 'Seragam bisbol (hewan)'],
  'W4C': ['Baseball uniform (character)', '野球ユニフォーム （キャラクター）', '棒球服 （角色）', 'Uniforme de béisbol (personaje)', 'Uniforme de beisebol (personagem)', 'Baseball-Uniform (Figur)', 'Tenue de baseball (personnage)', 'Đồng phục bóng chày (nhân vật)', 'ชุดเบสบอล (ตัวละคร)', 'Seragam bisbol (karakter)'],
  'W4B': ['Baseball uniform (animal + character set)', '野球ユニフォーム （どうぶつ＋キャラセット）', '棒球服 （動物+角色組合）', 'Uniforme de béisbol (set animal + personaje)', 'Uniforme de beisebol (conjunto animal + personagem)', 'Baseball-Uniform (Set Tier + Figur)', 'Tenue de baseball (pack animal + personnage)', 'Đồng phục bóng chày (bộ thú + nhân vật)', 'ชุดเบสบอล (ชุดสัตว์+ตัวละคร)', 'Seragam bisbol (paket hewan + karakter)'],
  'W5A': ['Badminton kit (animal)', 'バドミントンウェア （どうぶつ）', '羽球服 （動物）', 'Equipación de bádminton (animal)', 'Uniforme de badminton (animal)', 'Badminton-Outfit (Tier)', 'Tenue de badminton (animal)', 'Đồ cầu lông (thú)', 'ชุดแบดมินตัน (สัตว์)', 'Seragam bulu tangkis (hewan)'],
  'W5C': ['Badminton kit (character)', 'バドミントンウェア （キャラクター）', '羽球服 （角色）', 'Equipación de bádminton (personaje)', 'Uniforme de badminton (personagem)', 'Badminton-Outfit (Figur)', 'Tenue de badminton (personnage)', 'Đồ cầu lông (nhân vật)', 'ชุดแบดมินตัน (ตัวละคร)', 'Seragam bulu tangkis (karakter)'],
  'W5B': ['Badminton kit (animal + character set)', 'バドミントンウェア （どうぶつ＋キャラセット）', '羽球服 （動物+角色組合）', 'Equipación de bádminton (set animal + personaje)', 'Uniforme de badminton (conjunto animal + personagem)', 'Badminton-Outfit (Set Tier + Figur)', 'Tenue de badminton (pack animal + personnage)', 'Đồ cầu lông (bộ thú + nhân vật)', 'ชุดแบดมินตัน (ชุดสัตว์+ตัวละคร)', 'Seragam bulu tangkis (paket hewan + karakter)'],
  'W6A': ['Taekwondo dobok (animal)', 'テコンドー道着 （どうぶつ）', '跆拳道服 （動物）', 'Dobok de taekwondo (animal)', 'Dobok de taekwondo (animal)', 'Taekwondo-Dobok (Tier)', 'Dobok de taekwondo (animal)', 'Võ phục taekwondo (thú)', 'ชุดเทควันโด (สัตว์)', 'Dobok taekwondo (hewan)'],
  'W6C': ['Taekwondo dobok (character)', 'テコンドー道着 （キャラクター）', '跆拳道服 （角色）', 'Dobok de taekwondo (personaje)', 'Dobok de taekwondo (personagem)', 'Taekwondo-Dobok (Figur)', 'Dobok de taekwondo (personnage)', 'Võ phục taekwondo (nhân vật)', 'ชุดเทควันโด (ตัวละคร)', 'Dobok taekwondo (karakter)'],
  'W6B': ['Taekwondo dobok (animal + character set)', 'テコンドー道着 （どうぶつ＋キャラセット）', '跆拳道服 （動物+角色組合）', 'Dobok de taekwondo (set animal + personaje)', 'Dobok de taekwondo (conjunto animal + personagem)', 'Taekwondo-Dobok (Set Tier + Figur)', 'Dobok de taekwondo (pack animal + personnage)', 'Võ phục taekwondo (bộ thú + nhân vật)', 'ชุดเทควันโด (ชุดสัตว์+ตัวละคร)', 'Dobok taekwondo (paket hewan + karakter)'],
  'T1M': ['Korean hanbok (character · male)', '韓国の韓服 （キャラ・男性）', '韓國韓服 （角色・男）', 'Hanbok de Corea (personaje · hombre)', 'Hanbok da Coreia (personagem · masc.)', 'Koreanischer Hanbok (Figur · männlich)', 'Hanbok coréen (personnage · homme)', 'Hanbok Hàn Quốc (nhân vật · nam)', 'ฮันบกเกาหลี (ตัวละคร · ชาย)', 'Hanbok Korea (karakter · pria)'],
  'T1F': ['Korean hanbok (character · female)', '韓国の韓服 （キャラ・女性）', '韓國韓服 （角色・女）', 'Hanbok de Corea (personaje · mujer)', 'Hanbok da Coreia (personagem · fem.)', 'Koreanischer Hanbok (Figur · weiblich)', 'Hanbok coréen (personnage · femme)', 'Hanbok Hàn Quốc (nhân vật · nữ)', 'ฮันบกเกาหลี (ตัวละคร · หญิง)', 'Hanbok Korea (karakter · wanita)'],
  'T1S': ['Korean hanbok (character · male + female set)', '韓国の韓服 （キャラ・男女セット）', '韓國韓服 （角色・男女組合）', 'Hanbok de Corea (set personaje hombre + mujer)', 'Hanbok da Coreia (conjunto personagem masc. + fem.)', 'Koreanischer Hanbok (Set Figur männlich + weiblich)', 'Hanbok coréen (pack personnage homme + femme)', 'Hanbok Hàn Quốc (bộ nhân vật nam + nữ)', 'ฮันบกเกาหลี (ชุดตัวละคร ชาย+หญิง)', 'Hanbok Korea (paket karakter pria + wanita)'],
  'T2M': ['Japanese yukata (character · male)', '日本の浴衣 （キャラ・男性）', '日本浴衣 （角色・男）', 'Yukata de Japón (personaje · hombre)', 'Yukata do Japão (personagem · masc.)', 'Japanischer Yukata (Figur · männlich)', 'Yukata japonais (personnage · homme)', 'Yukata Nhật Bản (nhân vật · nam)', 'ยูกาตะญี่ปุ่น (ตัวละคร · ชาย)', 'Yukata Jepang (karakter · pria)'],
  'T2F': ['Japanese yukata (character · female)', '日本の浴衣 （キャラ・女性）', '日本浴衣 （角色・女）', 'Yukata de Japón (personaje · mujer)', 'Yukata do Japão (personagem · fem.)', 'Japanischer Yukata (Figur · weiblich)', 'Yukata japonais (personnage · femme)', 'Yukata Nhật Bản (nhân vật · nữ)', 'ยูกาตะญี่ปุ่น (ตัวละคร · หญิง)', 'Yukata Jepang (karakter · wanita)'],
  'T2S': ['Japanese yukata (character · male + female set)', '日本の浴衣 （キャラ・男女セット）', '日本浴衣 （角色・男女組合）', 'Yukata de Japón (set personaje hombre + mujer)', 'Yukata do Japão (conjunto personagem masc. + fem.)', 'Japanischer Yukata (Set Figur männlich + weiblich)', 'Yukata japonais (pack personnage homme + femme)', 'Yukata Nhật Bản (bộ nhân vật nam + nữ)', 'ยูกาตะญี่ปุ่น (ชุดตัวละคร ชาย+หญิง)', 'Yukata Jepang (paket karakter pria + wanita)'],
  'T3M': ['Vietnamese áo dài (character · male)', 'ベトナムのアオザイ （キャラ・男性）', '越南奧黛 （角色・男）', 'Áo dài de Vietnam (personaje · hombre)', 'Áo dài do Vietnã (personagem · masc.)', 'Vietnamesischer Áo dài (Figur · männlich)', 'Áo dài vietnamien (personnage · homme)', 'Áo dài Việt Nam (nhân vật · nam)', 'อ๊าวหญ่ายเวียดนาม (ตัวละคร · ชาย)', 'Áo dài Vietnam (karakter · pria)'],
  'T3F': ['Vietnamese áo dài (character · female)', 'ベトナムのアオザイ （キャラ・女性）', '越南奧黛 （角色・女）', 'Áo dài de Vietnam (personaje · mujer)', 'Áo dài do Vietnã (personagem · fem.)', 'Vietnamesischer Áo dài (Figur · weiblich)', 'Áo dài vietnamien (personnage · femme)', 'Áo dài Việt Nam (nhân vật · nữ)', 'อ๊าวหญ่ายเวียดนาม (ตัวละคร · หญิง)', 'Áo dài Vietnam (karakter · wanita)'],
  'T3S': ['Vietnamese áo dài (character · male + female set)', 'ベトナムのアオザイ （キャラ・男女セット）', '越南奧黛 （角色・男女組合）', 'Áo dài de Vietnam (set personaje hombre + mujer)', 'Áo dài do Vietnã (conjunto personagem masc. + fem.)', 'Vietnamesischer Áo dài (Set Figur männlich + weiblich)', 'Áo dài vietnamien (pack personnage homme + femme)', 'Áo dài Việt Nam (bộ nhân vật nam + nữ)', 'อ๊าวหญ่ายเวียดนาม (ชุดตัวละคร ชาย+หญิง)', 'Áo dài Vietnam (paket karakter pria + wanita)'],
  'T4M': ['Bavarian festival wear (Germany) (character · male)', 'ドイツ・バイエルンの祭り衣装 （キャラ・男性）', '德國巴伐利亞節慶服 （角色・男）', 'Traje festivo de Baviera (Alemania) (personaje · hombre)', 'Traje festivo da Baviera (Alemanha) (personagem · masc.)', 'Bayerische Festtracht (Deutschland) (Figur · männlich)', 'Tenue de fête bavaroise (Allemagne) (personnage · homme)', 'Trang phục lễ hội Bavaria (Đức) (nhân vật · nam)', 'ชุดเทศกาลบาวาเรีย (เยอรมนี) (ตัวละคร · ชาย)', 'Busana festival Bavaria (Jerman) (karakter · pria)'],
  'T4F': ['Bavarian festival wear (Germany) (character · female)', 'ドイツ・バイエルンの祭り衣装 （キャラ・女性）', '德國巴伐利亞節慶服 （角色・女）', 'Traje festivo de Baviera (Alemania) (personaje · mujer)', 'Traje festivo da Baviera (Alemanha) (personagem · fem.)', 'Bayerische Festtracht (Deutschland) (Figur · weiblich)', 'Tenue de fête bavaroise (Allemagne) (personnage · femme)', 'Trang phục lễ hội Bavaria (Đức) (nhân vật · nữ)', 'ชุดเทศกาลบาวาเรีย (เยอรมนี) (ตัวละคร · หญิง)', 'Busana festival Bavaria (Jerman) (karakter · wanita)'],
  'T4S': ['Bavarian festival wear (Germany) (character · male + female set)', 'ドイツ・バイエルンの祭り衣装 （キャラ・男女セット）', '德國巴伐利亞節慶服 （角色・男女組合）', 'Traje festivo de Baviera (Alemania) (set personaje hombre + mujer)', 'Traje festivo da Baviera (Alemanha) (conjunto personagem masc. + fem.)', 'Bayerische Festtracht (Deutschland) (Set Figur männlich + weiblich)', 'Tenue de fête bavaroise (Allemagne) (pack personnage homme + femme)', 'Trang phục lễ hội Bavaria (Đức) (bộ nhân vật nam + nữ)', 'ชุดเทศกาลบาวาเรีย (เยอรมนี) (ชุดตัวละคร ชาย+หญิง)', 'Busana festival Bavaria (Jerman) (paket karakter pria + wanita)'],
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
