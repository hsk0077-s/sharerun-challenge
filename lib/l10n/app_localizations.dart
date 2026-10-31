import 'package:flutter/widgets.dart';

/// Core in-app UI & wearable connection localization dictionary covering
/// all 11 global target locales (`ko`, `en`, `ja`, `zh_TW`, `es`, `pt_BR`, `de`, `fr`, `vi`, `th`, `id`).
@immutable
class ShareRunLocalizedStrings {
  const ShareRunLocalizedStrings({
    required this.localeCode,
    required this.appTitle,
    required this.slogan,
    required this.navHome,
    required this.navChallenge,
    required this.navCrew,
    required this.navStore,
    required this.navWallet,
    required this.navMyPage,
    required this.deviceConnectionTitle,
    required this.wearableGuideEntry,
    required this.bleHrSectionTitle,
    required this.bleHrScanButton,
    required this.startRunCta,
    required this.pedometerRuleSummary,
    required this.donationRuleSummary,
    required this.charityDisclosure,
  });

  final String localeCode;
  final String appTitle;
  final String slogan;
  final String navHome;
  final String navChallenge;
  final String navCrew;
  final String navStore;
  final String navWallet;
  final String navMyPage;
  final String deviceConnectionTitle;
  final String wearableGuideEntry;
  final String bleHrSectionTitle;
  final String bleHrScanButton;
  final String startRunCta;
  final String pedometerRuleSummary;
  final String donationRuleSummary;

  /// Operator-paid, one Korea-registered payee. Not a user donation.
  final String charityDisclosure;
}

abstract final class ShareRunLocalizations {
  static const supportedLocales = <Locale>[
    Locale('ko', 'KR'),
    Locale('en', 'US'),
    Locale('ja', 'JP'),
    Locale('zh', 'TW'),
    Locale('es', 'ES'),
    Locale('pt', 'BR'),
    Locale('de', 'DE'),
    Locale('fr', 'FR'),
    Locale('vi', 'VN'),
    Locale('th', 'TH'),
    Locale('id', 'ID'),
  ];

  /// The strings for the language the screen is showing; English when the
  /// language is not one we ship.
  static ShareRunLocalizedStrings of(BuildContext context) {
    final code = Localizations.maybeLocaleOf(context)?.languageCode;
    return byLanguage[code] ?? byLanguage['en']!;
  }

  static const Map<String, ShareRunLocalizedStrings> byLanguage = {
    'ko': ShareRunLocalizedStrings(
      localeCode: 'ko-KR',
      appTitle: '쉐어런',
      slogan: '심장이 뛰는 한, 나눔도 달린다',
      navHome: '홈',
      navChallenge: '챌린지',
      navCrew: '크루',
      navStore: '상점',
      navWallet: '지갑',
      navMyPage: '마이페이지',
      deviceConnectionTitle: '스마트워치 · 건강 데이터 연동',
      wearableGuideEntry: '내 워치·스마트밴드 연결 방법 찾기',
      bleHrSectionTitle: '실시간 블루투스 심박 센서 (BLE) 직접 연결',
      bleHrScanButton: '센서 찾기',
      startRunCta: '달리기 시작하기',
      pedometerRuleSummary: '100걸음 = 10 SHARE (일일 기본 600 SHARE 한도)',
      donationRuleSummary: '검증 러닝 1km = 100원 상당 기부 풀 적립 (월간 운영자 한도 내)',
      charityDisclosure:
          '운영자가 자기 돈으로, 전 세계 거리를 한 달 예산에 모아 한국에 등록된 한 단체에 냅니다. 이용자의 기부금이 아니고 세금 공제 영수증은 없습니다.',
    ),
    'en': ShareRunLocalizedStrings(
      localeCode: 'en-US',
      appTitle: 'ShareRun',
      slogan: 'As long as your heart beats, sharing runs on',
      navHome: 'Home',
      navChallenge: 'Challenges',
      navCrew: 'Crew',
      navStore: 'Shop',
      navWallet: 'Wallet',
      navMyPage: 'My Page',
      deviceConnectionTitle: 'Smartwatch & Health Data Sync',
      wearableGuideEntry: 'How to connect my watch or smartband',
      bleHrSectionTitle: 'Direct BLE Heart Rate Sensor (0x180D)',
      bleHrScanButton: 'Scan Sensors',
      startRunCta: 'Start Running',
      pedometerRuleSummary: '100 steps = 10 SHARE (600 SHARE/day base cap)',
      donationRuleSummary: 'Verified 1 km = 100 KRW equiv. charity pool (within monthly cap)',
      charityDisclosure:
          'The operator pays its own money from one worldwide monthly budget to a single charity registered in Korea. This is not your donation and no tax receipt is issued.',
    ),
    'ja': ShareRunLocalizedStrings(
      localeCode: 'ja-JP',
      appTitle: 'ShareRun',
      slogan: '心臓が鼓動する限り、分かち合いも走り続ける',
      navHome: 'ホーム',
      navChallenge: 'チャレンジ',
      navCrew: 'クルー',
      navStore: 'ショップ',
      navWallet: 'ウォレット',
      navMyPage: 'マイページ',
      deviceConnectionTitle: 'スマートウォッチ・ヘルスデータ連携',
      wearableGuideEntry: 'お使いのウォッチ・スマートバンドの接続方法を探す',
      bleHrSectionTitle: 'リアルタイムBLE心拍センサー直接接続 (0x180D)',
      bleHrScanButton: 'センサーを探す',
      startRunCta: 'ランニング開始',
      pedometerRuleSummary: '100歩 = 10 SHARE（1日基本600 SHARE上限）',
      donationRuleSummary: '認証ラン1km = 100ウォン相当を寄付プールに積立（月間上限内）',
      charityDisclosure:
          '運営者が自己資金で、世界中の距離をひとつの月間予算にまとめ、韓国で登録された一つの団体へ支払います。利用者の寄付ではなく、税額控除の領収書はありません。',
    ),
    'zh': ShareRunLocalizedStrings(
      localeCode: 'zh-TW',
      appTitle: 'ShareRun 享跑',
      slogan: '只要心跳不止，分享就持續奔跑',
      navHome: '首頁',
      navChallenge: '挑戰賽',
      navCrew: '跑團',
      navStore: '商店',
      navWallet: '錢包',
      navMyPage: '我的主頁',
      deviceConnectionTitle: '智慧手錶與健康資料連動',
      wearableGuideEntry: '尋找我的手錶／智慧手環連線方式',
      bleHrSectionTitle: '即時藍牙心率感測器 (BLE 0x180D) 直接連線',
      bleHrScanButton: '搜尋感測器',
      startRunCta: '開始跑步',
      pedometerRuleSummary: '100 步 = 10 SHARE（每日基本上限 600 SHARE）',
      donationRuleSummary: '驗證跑步 1km = 提撥 100 韓元等值公益池（每月上限內）',
      charityDisclosure:
          '這是營運方的自有資金，把全球驗證里程合成一個每月預算，結算給韓國登記的單一團體。不是使用者的捐款，也不開立抵稅收據。',
    ),
    'es': ShareRunLocalizedStrings(
      localeCode: 'es-ES',
      appTitle: 'ShareRun',
      slogan: 'Mientras lata tu corazón, la solidaridad sigue corriendo',
      navHome: 'Inicio',
      navChallenge: 'Retos',
      navCrew: 'Crew',
      navStore: 'Tienda',
      navWallet: 'Cartera',
      navMyPage: 'Mi Perfil',
      deviceConnectionTitle: 'Reloj Inteligente y Datos de Salud',
      wearableGuideEntry: 'Cómo conectar mi reloj o pulsera inteligente',
      bleHrSectionTitle: 'Sensor Cardíaco Bluetooth (BLE 0x180D) en Vivo',
      bleHrScanButton: 'Buscar Sensor',
      startRunCta: 'Empezar a Correr',
      pedometerRuleSummary: '100 pasos = 10 SHARE (límite base 600 SHARE/día)',
      donationRuleSummary: '1 km verificado = 100 KRW equiv. al fondo solidario (con tope mensual)',
      charityDisclosure:
          'El operador paga con su dinero, en un presupuesto mensual mundial, a una sola entidad registrada en Corea. No es tu donativo y no hay recibo fiscal.',
    ),
    'pt': ShareRunLocalizedStrings(
      localeCode: 'pt-BR',
      appTitle: 'ShareRun',
      slogan: 'Enquanto o coração bater, a solidariedade continua correndo',
      navHome: 'Início',
      navChallenge: 'Desafios',
      navCrew: 'Crew',
      navStore: 'Loja',
      navWallet: 'Carteira',
      navMyPage: 'Meu Perfil',
      deviceConnectionTitle: 'Smartwatch e Dados de Saúde',
      wearableGuideEntry: 'Como conectar meu smartwatch ou smartband',
      bleHrSectionTitle: 'Sensor Cardíaco Bluetooth (BLE 0x180D) ao Vivo',
      bleHrScanButton: 'Buscar Sensor',
      startRunCta: 'Iniciar Corrida',
      pedometerRuleSummary: '100 passos = 10 SHARE (limite base de 600 SHARE/dia)',
      donationRuleSummary: '1 km verificado = 100 KRW equiv. para doação (dentro do teto mensal)',
      charityDisclosure:
          'A operadora paga com o próprio dinheiro, num orçamento mensal mundial, a uma entidade registrada na Coreia. Não é doação do usuário e não há recibo fiscal.',
    ),
    'de': ShareRunLocalizedStrings(
      localeCode: 'de-DE',
      appTitle: 'ShareRun',
      slogan: 'Solange dein Herz schlägt, läuft das Teilen weiter',
      navHome: 'Start',
      navChallenge: 'Challenges',
      navCrew: 'Crew',
      navStore: 'Shop',
      navWallet: 'Wallet',
      navMyPage: 'Mein Profil',
      deviceConnectionTitle: 'Smartwatch & Gesundheitsdaten verbinden',
      wearableGuideEntry: 'Anleitung für meine Smartwatch / mein Fitnessband',
      bleHrSectionTitle: 'Direkter BLE-Herzfrequenzsensor (0x180D)',
      bleHrScanButton: 'Sensor suchen',
      startRunCta: 'Lauf starten',
      pedometerRuleSummary: '100 Schritte = 10 SHARE (600 SHARE Tageslimit)',
      donationRuleSummary: '1 verifizierter km = 100 KRW Äquiv. Spendenpool (im Monatslimit)',
      charityDisclosure:
          'Der Betreiber zahlt eigenes Geld aus einem weltweiten Monatsbudget an eine in Korea registrierte Stelle. Kein Spendenbeitrag der Nutzer und keine Steuerquittung.',
    ),
    'fr': ShareRunLocalizedStrings(
      localeCode: 'fr-FR',
      appTitle: 'ShareRun',
      slogan: 'Tant que votre cœur bat, le partage court aussi',
      navHome: 'Accueil',
      navChallenge: 'Défis',
      navCrew: 'Crew',
      navStore: 'Boutique',
      navWallet: 'Portefeuille',
      navMyPage: 'Mon Profil',
      deviceConnectionTitle: 'Montre Connectée & Données de Santé',
      wearableGuideEntry: 'Comment connecter ma montre ou mon bracelet',
      bleHrSectionTitle: 'Capteur Cardiaque Bluetooth Direct (BLE 0x180D)',
      bleHrScanButton: 'Rechercher un capteur',
      startRunCta: 'Démarrer la course',
      pedometerRuleSummary: '100 pas = 10 SHARE (plafond de base 600 SHARE/jour)',
      donationRuleSummary: '1 km vérifié = équiv. 100 KRW au fonds caritatif (plafond mensuel)',
      charityDisclosure:
          'L\'opérateur paie avec son argent, sur un budget mensuel mondial, à un seul organisme enregistré en Corée. Ce n\'est pas un don de l\'utilisateur et il n\'y a pas de reçu fiscal.',
    ),
    'vi': ShareRunLocalizedStrings(
      localeCode: 'vi-VN',
      appTitle: 'ShareRun',
      slogan: 'Chừng nào trái tim còn đập, sự sẻ chia vẫn tiếp tục chạy',
      navHome: 'Trang chủ',
      navChallenge: 'Thử thách',
      navCrew: 'Crew',
      navStore: 'Cửa hàng',
      navWallet: 'Ví',
      navMyPage: 'Cá nhân',
      deviceConnectionTitle: 'Liên kết Đồng hồ & Dữ liệu Sức khỏe',
      wearableGuideEntry: 'Cách kết nối đồng hồ / vòng đeo tay thông minh',
      bleHrSectionTitle: 'Kết nối trực tiếp Cảm biến Nhịp tim BLE (0x180D)',
      bleHrScanButton: 'Tìm cảm biến',
      startRunCta: 'Bắt đầu chạy',
      pedometerRuleSummary: '100 bước = 10 SHARE (hạn mức cơ bản 600 SHARE/ngày)',
      donationRuleSummary: '1 km hợp lệ = góp 100 KRW vào quỹ thiện nguyện (trong hạn mức tháng)',
      charityDisclosure:
          'Đơn vị vận hành dùng tiền của mình, gộp km toàn cầu vào một ngân sách tháng, chi cho một tổ chức đăng ký tại Hàn Quốc. Không phải tiền quyên góp của người dùng và không có biên lai thuế.',
    ),
    'th': ShareRunLocalizedStrings(
      localeCode: 'th-TH',
      appTitle: 'ShareRun',
      slogan: 'ตราบใดที่หัวใจยังเต้น การแบ่งปันก็ยังคงวิ่งต่อไป',
      navHome: 'หน้าแรก',
      navChallenge: 'ชาเลนจ์',
      navCrew: 'Crew',
      navStore: 'ร้านค้า',
      navWallet: 'กระเป๋า',
      navMyPage: 'โปรไฟล์',
      deviceConnectionTitle: 'เชื่อมต่อสมาร์ทวอทช์และข้อมูลสุขภาพ',
      wearableGuideEntry: 'ค้นหาวิธีเชื่อมต่อสมาร์ทวอทช์ / สมาร์ทแบนด์',
      bleHrSectionTitle: 'เชื่อมต่อเซ็นเซอร์วัดหัวใจบลูทูธโดยตรง (BLE 0x180D)',
      bleHrScanButton: 'ค้นหาเซ็นเซอร์',
      startRunCta: 'เริ่มวิ่ง',
      pedometerRuleSummary: '100 ก้าว = 10 SHARE (สูงสุด 600 SHARE/วัน)',
      donationRuleSummary: 'วิ่งที่ยืนยันแล้ว 1 กม. = สมทบทุน 100 วอน (ภายในวงเงินรายเดือน)',
      charityDisclosure:
          'ผู้ให้บริการจ่ายด้วยเงินของตนเอง จากงบรายเดือนเดียวทั่วโลก ให้องค์กรที่จดทะเบียนในเกาหลี ไม่ใช่เงินบริจาคของผู้ใช้ และไม่มีใบเสร็จลดหย่อนภาษี',
    ),
    'id': ShareRunLocalizedStrings(
      localeCode: 'id-ID',
      appTitle: 'ShareRun',
      slogan: 'Selama jantung berdetak, berbagi terus berlari',
      navHome: 'Beranda',
      navChallenge: 'Tantangan',
      navCrew: 'Crew',
      navStore: 'Toko',
      navWallet: 'Dompet',
      navMyPage: 'Profil',
      deviceConnectionTitle: 'Sinkronisasi Smartwatch & Data Kesehatan',
      wearableGuideEntry: 'Cara menghubungkan smartwatch atau smartband saya',
      bleHrSectionTitle: 'Sensor Detak Jantung Bluetooth Langsung (BLE 0x180D)',
      bleHrScanButton: 'Cari Sensor',
      startRunCta: 'Mulai Lari',
      pedometerRuleSummary: '100 langkah = 10 SHARE (batas dasar 600 SHARE/hari)',
      donationRuleSummary: '1 km terverifikasi = setara 100 KRW ke dana donasi (batas bulanan)',
      charityDisclosure:
          'Penyelenggara membayar dengan uangnya sendiri, dari satu anggaran bulanan dunia, ke satu lembaga terdaftar di Korea. Bukan donasi pengguna dan tanpa bukti potong pajak.',
    ),
  };

  static ShareRunLocalizedStrings ofLocale(Locale locale) {
    return byLanguage[locale.languageCode] ?? byLanguage['en']!;
  }
}

/// Empty when every supported locale has the core phrases, and a non-Korean
/// locale did not keep the Korean slogan.
List<String> missingCoreLocaleKeys() {
  final missing = <String>[];
  final korean = ShareRunLocalizations.byLanguage['ko'];
  for (final locale in ShareRunLocalizations.supportedLocales) {
    final code = locale.languageCode;
    final tag = '${locale.languageCode}-${locale.countryCode}';
    final row = ShareRunLocalizations.byLanguage[code];
    if (row == null) {
      missing.add('$tag.core');
      continue;
    }
    final fields = <String, String>{
      'appTitle': row.appTitle,
      'slogan': row.slogan,
      'navHome': row.navHome,
      'navChallenge': row.navChallenge,
      'navCrew': row.navCrew,
      'navStore': row.navStore,
      'navWallet': row.navWallet,
      'navMyPage': row.navMyPage,
      'deviceConnectionTitle': row.deviceConnectionTitle,
      'wearableGuideEntry': row.wearableGuideEntry,
      'bleHrSectionTitle': row.bleHrSectionTitle,
      'bleHrScanButton': row.bleHrScanButton,
      'startRunCta': row.startRunCta,
      'pedometerRuleSummary': row.pedometerRuleSummary,
      'donationRuleSummary': row.donationRuleSummary,
      'charityDisclosure': row.charityDisclosure,
    };
    for (final entry in fields.entries) {
      if (entry.value.trim().isEmpty) missing.add('$tag.core.${entry.key}');
    }
    if (code != 'ko' && korean != null && row.slogan == korean.slogan) {
      missing.add('$tag.core.slogan=ko');
    }
    if (code != 'ko' && korean != null && row.charityDisclosure == korean.charityDisclosure) {
      missing.add('$tag.core.charity=ko');
    }
  }
  return missing;
}
