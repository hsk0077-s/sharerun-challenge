import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// Watch-guide chrome and the three steps for each brand, in the 11 locales.
class GuideChrome {
  const GuideChrome({
    required this.searchHint,
    required this.empty,
    required this.back,
    required this.usingApp,
    required this.ctaAndroid,
    required this.ctaIos,
    required this.brands,
  });

  final String searchHint;
  final String empty;
  final String back;
  final String usingApp;
  final String ctaAndroid;
  final String ctaIos;
  final Map<String, GuideBrandText> brands;

  static const brandIds = <String>[
    'xiaomi',
    'amazfit',
    'garmin',
    'fitbit',
    'samsung',
    'coros_suunto',
  ];

  static GuideChrome of(Locale locale) {
    return _byLanguage[locale.languageCode] ?? _byLanguage['en']!;
  }

  /// Keys that are absent, empty, or still the English step text.
  /// A non-English locale that only copies English fails here.
  static List<String> missingKeys() {
    final missing = <String>[];
    final english = _byLanguage['en'];
    if (english == null) return const ['en'];
    for (final locale in ShareRunLocalizations.supportedLocales) {
      final code = locale.languageCode;
      final chrome = _byLanguage[code];
      final prefix = '${locale.languageCode}-${locale.countryCode}';
      if (chrome == null) {
        missing.add(prefix);
        continue;
      }
      final chromeFields = <String, String>{
        'searchHint': chrome.searchHint,
        'empty': chrome.empty,
        'back': chrome.back,
        'usingApp': chrome.usingApp,
        'ctaAndroid': chrome.ctaAndroid,
        'ctaIos': chrome.ctaIos,
      };
      for (final entry in chromeFields.entries) {
        if (entry.value.trim().isEmpty) missing.add('$prefix.${entry.key}');
      }
      for (final id in brandIds) {
        final brand = chrome.brands[id];
        if (brand == null) {
          missing.add('$prefix.$id');
          continue;
        }
        if (brand.name.trim().isEmpty) missing.add('$prefix.$id.name');
        if (brand.steps.length != 3) {
          missing.add('$prefix.$id.steps');
          continue;
        }
        for (var i = 0; i < brand.steps.length; i++) {
          if (brand.steps[i].trim().isEmpty) {
            missing.add('$prefix.$id.steps[$i]');
          }
        }
        final englishBrand = english.brands[id];
        if (code != 'en' &&
            englishBrand != null &&
            _sameSteps(brand.steps, englishBrand.steps)) {
          missing.add('$prefix.$id.steps=en');
        }
      }
    }
    return missing;
  }
}

bool _sameSteps(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) return false;
  }
  return true;
}

class GuideBrandText {
  const GuideBrandText({required this.name, required this.steps, this.note});

  final String name;
  final List<String> steps;
  final String? note;
}

GuideBrandText _brand(String name, List<String> steps, [String? note]) =>
    GuideBrandText(name: name, steps: steps, note: note);

final _byLanguage = <String, GuideChrome>{
  'ko': GuideChrome(
    searchHint: '브랜드 검색 (예: 샤오미, 가민, 핏빗)',
    empty: '일치하는 브랜드가 없어요. 다른 이름으로 검색해 보세요.',
    back: '브랜드 목록',
    usingApp: '사용 앱',
    ctaAndroid: 'Health Connect 연결하기',
    ctaIos: 'Apple 건강 연결하기',
    brands: {
      'xiaomi': _brand('샤오미 미밴드 / 레드미 워치', [
        'Mi Fitness에서 밴드를 페어링하고 한 번 동기화해 주세요.',
        '프로필 → 타사 데이터 → Health Connect에서 걸음 수·심박수 쓰기를 허용해 주세요.',
        '쉐어런의 Health Connect 권한을 허용하거나, 심박 공유를 켜고 BLE로 연결해 주세요.',
      ], 'iOS는 Mi Fitness에서 Apple 건강을 켜 주세요.'),
      'amazfit': _brand('어메이즈핏 (Amazfit)', [
        'Zepp에서 워치를 페어링하고 동기화해 주세요.',
        '프로필 → 타사 계정 → Health Connect에서 걸음 수·심박 쓰기를 허용해 주세요.',
        '쉐어런 Health Connect를 허용하거나, 심박 공유를 켜고 BLE로 연결해 주세요.',
      ], 'iOS는 Zepp에서 Apple 건강을 켜 주세요.'),
      'garmin': _brand('가민 (Garmin)', [
        'Garmin Connect에서 워치를 동기화해 주세요.',
        '더보기 → 설정 → 연결된 앱 → Health Connect에서 심박·걸음을 허용해 주세요.',
        '쉐어런 Health Connect를 허용하거나, 워치의 심박 전송을 켜고 BLE로 연결해 주세요.',
      ], '가민에서 Health Connect로 내보내는 방향만 공식 지원입니다.'),
      'fitbit': _brand('핏빗 / 픽셀 워치', [
        'Fitbit에서 워치를 동기화해 주세요.',
        '기기 → 연결 추가 → Health Connect 동기화를 켜 주세요.',
        '쉐어런의 Health Connect 읽기 권한을 허용해 주세요.',
      ]),
      'samsung': _brand('삼성 갤럭시 워치', [
        'Samsung Health에서 워치를 연결하고 동기화해 주세요.',
        '설정 → Health Connect에서 걸음 수·심박 공유를 켜 주세요.',
        '쉐어런 Health Connect를 허용해 주세요. 갤럭시 워치 단독 앱은 6자리 코드로도 연결됩니다.',
      ]),
      'coros_suunto': _brand('코로스 / 순토', [
        'COROS 또는 Suunto 앱에서 워치를 동기화해 주세요.',
        'Android는 Health Sync로 Health Connect에 내보내거나, 워치 심박 방송을 켜 주세요.',
        '쉐어런의 BLE 심박 센서 화면에서 워치를 직접 연결해 주세요.',
      ], 'iOS는 각 앱에서 Apple 건강을 켜 주세요.'),
    },
  ),
  'en': GuideChrome(
    searchHint: 'Search a brand (Xiaomi, Garmin, Fitbit)',
    empty: 'No brand matches. Try another name.',
    back: 'Brands',
    usingApp: 'App',
    ctaAndroid: 'Connect Health Connect',
    ctaIos: 'Connect Apple Health',
    brands: {
      'xiaomi': _brand('Xiaomi Mi Band / Redmi Watch', [
        'Pair the band in Mi Fitness and sync once.',
        'Profile → Third-party data → Health Connect: allow steps and heart rate.',
        'Allow ShareRun to read Health Connect, or turn on heart-rate sharing and connect over BLE.',
      ], 'On iOS, turn on Apple Health inside Mi Fitness.'),
      'amazfit': _brand('Amazfit', [
        'Pair the watch in Zepp and sync.',
        'Profile → third-party accounts → Health Connect: allow steps and heart rate.',
        'Allow ShareRun Health Connect, or turn on heart-rate sharing and use BLE.',
      ], 'On iOS, turn on Apple Health inside Zepp.'),
      'garmin': _brand('Garmin', [
        'Sync the watch in Garmin Connect.',
        'More → Settings → Connected apps → Health Connect: allow heart rate and steps.',
        'Allow ShareRun Health Connect, or turn on heart-rate broadcast and connect over BLE.',
      ], 'Garmin export to Health Connect is one-way.'),
      'fitbit': _brand('Fitbit / Pixel Watch', [
        'Sync the watch in the Fitbit app.',
        'Device → Add connections → set up Health Connect.',
        'Allow ShareRun to read Health Connect.',
      ]),
      'samsung': _brand('Samsung Galaxy Watch', [
        'Connect the watch in Samsung Health and sync once.',
        'Settings → Health Connect: share steps and heart rate.',
        'Allow ShareRun Health Connect. The Galaxy Watch app can also pair with a 6-digit code.',
      ]),
      'coros_suunto': _brand('COROS / Suunto', [
        'Sync the watch in the COROS or Suunto app.',
        'On Android, export through Health Sync or turn on heart-rate broadcast.',
        'Connect the watch from ShareRun’s BLE heart-rate screen.',
      ], 'On iOS, turn on Apple Health in the watch app.'),
    },
  ),
  'ja': GuideChrome(
    searchHint: 'ブランド検索（Xiaomi、Garmin、Fitbit）',
    empty: '一致するブランドがありません。別の名前で検索してください。',
    back: '一覧',
    usingApp: '使用アプリ',
    ctaAndroid: 'Health Connect を接続',
    ctaIos: 'Apple ヘルスケアを接続',
    brands: {
      'xiaomi': _brand('シャオミ Mi Band / Redmi Watch', [
        'Mi Fitnessでバンドをペアリングし、一度同期してください。',
        'プロフィール → サードパーティデータ → Health Connectで、歩数と心拍の書き込みを許可してください。',
        'ShareRunのHealth Connect読み取りを許可するか、心拍共有をオンにしてBLEで接続してください。',
      ], 'iOSではMi Fitnessの中でAppleヘルスケアをオンにしてください。'),
      'amazfit': _brand('Amazfit（アマズフィット）', [
        'Zeppでウォッチをペアリングして同期してください。',
        'プロフィール → サードパーティアカウント → Health Connectで、歩数と心拍の書き込みを許可してください。',
        'ShareRunのHealth Connectを許可するか、心拍共有をオンにしてBLEで接続してください。',
      ], 'iOSではZeppの中でAppleヘルスケアをオンにしてください。'),
      'garmin': _brand('Garmin（ガーミン）', [
        'Garmin Connectでウォッチを同期してください。',
        'もっと見る → 設定 → 接続済みアプリ → Health Connectで、心拍と歩数を許可してください。',
        'ShareRunのHealth Connectを許可するか、ウォッチの心拍送信をオンにしてBLEで接続してください。',
      ], 'GarminからHealth Connectへの書き出しは一方向だけが公式です。'),
      'fitbit': _brand('Fitbit / Pixel Watch', [
        'Fitbitアプリでウォッチを同期してください。',
        'デバイス → 接続を追加 → Health Connectの同期をオンにしてください。',
        'ShareRunにHealth Connectの読み取りを許可してください。',
      ]),
      'samsung': _brand('Samsung Galaxy Watch', [
        'Samsung Healthでウォッチを接続し、一度同期してください。',
        '設定 → Health Connectで、歩数と心拍の共有をオンにしてください。',
        'ShareRunのHealth Connectを許可してください。Galaxy Watch単体アプリは6桁コードでも接続できます。',
      ]),
      'coros_suunto': _brand('COROS / Suunto', [
        'COROSまたはSuuntoアプリでウォッチを同期してください。',
        'AndroidではHealth SyncからHealth Connectへ書き出すか、ウォッチの心拍配信をオンにしてください。',
        'ShareRunのBLE心拍センサー画面からウォッチを直接接続してください。',
      ], 'iOSでは各アプリでAppleヘルスケアをオンにしてください。'),
    },
  ),
  'zh': GuideChrome(
    searchHint: '搜尋品牌（小米、Garmin、Fitbit）',
    empty: '找不到相符的品牌。請換個名稱再試。',
    back: '品牌列表',
    usingApp: '使用的 App',
    ctaAndroid: '連接 Health Connect',
    ctaIos: '連接 Apple 健康',
    brands: {
      'xiaomi': _brand('小米手環 / Redmi Watch', [
        '在 Mi Fitness 配對手環，並同步一次。',
        '個人資料 → 第三方資料 → Health Connect，允許寫入步數與心率。',
        '允許 ShareRun 讀取 Health Connect，或開啟心率分享後以 BLE 連接。',
      ], 'iOS 請在 Mi Fitness 裡開啟 Apple 健康。'),
      'amazfit': _brand('Amazfit 華米', [
        '在 Zepp 配對錶款並同步。',
        '個人資料 → 第三方帳號 → Health Connect，允許寫入步數與心率。',
        '允許 ShareRun 的 Health Connect，或開啟心率分享後用 BLE 連接。',
      ], 'iOS 請在 Zepp 裡開啟 Apple 健康。'),
      'garmin': _brand('Garmin', [
        '在 Garmin Connect 同步手錶。',
        '更多 → 設定 → 已連結的 App → Health Connect，允許心率與步數。',
        '允許 ShareRun 的 Health Connect，或開啟手錶的心率廣播後以 BLE 連接。',
      ], 'Garmin 匯出到 Health Connect 只有單向是官方支援。'),
      'fitbit': _brand('Fitbit / Pixel Watch', [
        '在 Fitbit App 同步手錶。',
        '裝置 → 新增連結 → 開啟 Health Connect 同步。',
        '允許 ShareRun 讀取 Health Connect。',
      ]),
      'samsung': _brand('三星 Galaxy Watch', [
        '在 Samsung Health 連接手錶並同步一次。',
        '設定 → Health Connect，開啟步數與心率分享。',
        '允許 ShareRun 的 Health Connect。Galaxy Watch 獨立 App 也可以用 6 位數代碼連接。',
      ]),
      'coros_suunto': _brand('COROS / Suunto', [
        '在 COROS 或 Suunto App 同步手錶。',
        'Android 請用 Health Sync 匯出到 Health Connect，或開啟手錶的心率廣播。',
        '在 ShareRun 的 BLE 心率畫面直接連接手錶。',
      ], 'iOS 請在各 App 裡開啟 Apple 健康。'),
    },
  ),
  'es': GuideChrome(
    searchHint: 'Buscar marca (Xiaomi, Garmin, Fitbit)',
    empty: 'Ninguna marca coincide. Prueba con otro nombre.',
    back: 'Marcas',
    usingApp: 'App',
    ctaAndroid: 'Conectar Health Connect',
    ctaIos: 'Conectar Salud de Apple',
    brands: {
      'xiaomi': _brand('Xiaomi Mi Band / Redmi Watch', [
        'Empareja la pulsera en Mi Fitness y sincroniza una vez.',
        'Perfil → Datos de terceros → Health Connect: permite escribir pasos y frecuencia cardíaca.',
        'Permite que ShareRun lea Health Connect, o activa compartir el pulso y conecta por BLE.',
      ], 'En iOS, activa Salud de Apple dentro de Mi Fitness.'),
      'amazfit': _brand('Amazfit', [
        'Empareja el reloj en Zepp y sincronízalo.',
        'Perfil → Cuentas de terceros → Health Connect: permite pasos y frecuencia cardíaca.',
        'Permite Health Connect de ShareRun, o activa compartir el pulso y usa BLE.',
      ], 'En iOS, activa Salud de Apple dentro de Zepp.'),
      'garmin': _brand('Garmin', [
        'Sincroniza el reloj en Garmin Connect.',
        'Más → Ajustes → Apps conectadas → Health Connect: permite pulso y pasos.',
        'Permite Health Connect de ShareRun, o activa la emisión de pulso y conecta por BLE.',
      ], 'La exportación de Garmin a Health Connect es solo de ida.'),
      'fitbit': _brand('Fitbit / Pixel Watch', [
        'Sincroniza el reloj en la app Fitbit.',
        'Dispositivo → Añadir conexiones → activa Health Connect.',
        'Permite que ShareRun lea Health Connect.',
      ]),
      'samsung': _brand('Samsung Galaxy Watch', [
        'Conecta el reloj en Samsung Health y sincroniza una vez.',
        'Ajustes → Health Connect: comparte pasos y frecuencia cardíaca.',
        'Permite Health Connect de ShareRun. La app del Galaxy Watch también se vincula con un código de 6 dígitos.',
      ]),
      'coros_suunto': _brand('COROS / Suunto', [
        'Sincroniza el reloj en la app COROS o Suunto.',
        'En Android, exporta con Health Sync o activa la emisión de pulso.',
        'Conecta el reloj desde la pantalla de sensor BLE de ShareRun.',
      ], 'En iOS, activa Salud de Apple en la app del reloj.'),
    },
  ),
  'pt': GuideChrome(
    searchHint: 'Buscar marca (Xiaomi, Garmin, Fitbit)',
    empty: 'Nenhuma marca encontrada. Tente outro nome.',
    back: 'Marcas',
    usingApp: 'App',
    ctaAndroid: 'Conectar Health Connect',
    ctaIos: 'Conectar Saúde da Apple',
    brands: {
      'xiaomi': _brand('Xiaomi Mi Band / Redmi Watch', [
        'Pareie a pulseira no Mi Fitness e sincronize uma vez.',
        'Perfil → Dados de terceiros → Health Connect: permita gravar passos e frequência cardíaca.',
        'Permita que o ShareRun leia o Health Connect, ou ligue o compartilhamento de pulso e conecte por BLE.',
      ], 'No iOS, ative o app Saúde dentro do Mi Fitness.'),
      'amazfit': _brand('Amazfit', [
        'Pareie o relógio no Zepp e sincronize.',
        'Perfil → Contas de terceiros → Health Connect: permita passos e frequência cardíaca.',
        'Permita o Health Connect do ShareRun, ou ligue o compartilhamento de pulso e use BLE.',
      ], 'No iOS, ative o app Saúde dentro do Zepp.'),
      'garmin': _brand('Garmin', [
        'Sincronize o relógio no Garmin Connect.',
        'Mais → Configurações → Apps conectados → Health Connect: permita pulso e passos.',
        'Permita o Health Connect do ShareRun, ou ligue a transmissão de pulso e conecte por BLE.',
      ], 'A exportação da Garmin para o Health Connect é só de ida.'),
      'fitbit': _brand('Fitbit / Pixel Watch', [
        'Sincronize o relógio no app Fitbit.',
        'Dispositivo → Adicionar conexões → ative o Health Connect.',
        'Permita que o ShareRun leia o Health Connect.',
      ]),
      'samsung': _brand('Samsung Galaxy Watch', [
        'Conecte o relógio no Samsung Health e sincronize uma vez.',
        'Configurações → Health Connect: compartilhe passos e frequência cardíaca.',
        'Permita o Health Connect do ShareRun. O app do Galaxy Watch também pareia com um código de 6 dígitos.',
      ]),
      'coros_suunto': _brand('COROS / Suunto', [
        'Sincronize o relógio no app COROS ou Suunto.',
        'No Android, exporte pelo Health Sync ou ligue a transmissão de pulso.',
        'Conecte o relógio na tela de sensor BLE do ShareRun.',
      ], 'No iOS, ative o app Saúde no aplicativo do relógio.'),
    },
  ),
  'de': GuideChrome(
    searchHint: 'Marke suchen (Xiaomi, Garmin, Fitbit)',
    empty: 'Keine Marke gefunden. Versuch einen anderen Namen.',
    back: 'Marken',
    usingApp: 'App',
    ctaAndroid: 'Health Connect verbinden',
    ctaIos: 'Apple Health verbinden',
    brands: {
      'xiaomi': _brand('Xiaomi Mi Band / Redmi Watch', [
        'Kopple das Band in Mi Fitness und synchronisiere einmal.',
        'Profil → Drittanbieterdaten → Health Connect: Schritte und Herzfrequenz schreiben erlauben.',
        'Erlaube ShareRun das Lesen von Health Connect, oder schalte die Pulsfreigabe ein und verbinde per BLE.',
      ], 'Unter iOS schalte Apple Health in Mi Fitness ein.'),
      'amazfit': _brand('Amazfit', [
        'Kopple die Uhr in Zepp und synchronisiere sie.',
        'Profil → Drittanbieterkonten → Health Connect: Schritte und Herzfrequenz erlauben.',
        'Erlaube ShareRun Health Connect, oder schalte die Pulsfreigabe ein und nutze BLE.',
      ], 'Unter iOS schalte Apple Health in Zepp ein.'),
      'garmin': _brand('Garmin', [
        'Synchronisiere die Uhr in Garmin Connect.',
        'Mehr → Einstellungen → Verbundene Apps → Health Connect: Puls und Schritte erlauben.',
        'Erlaube ShareRun Health Connect, oder schalte die Pulsübertragung ein und verbinde per BLE.',
      ], 'Der Export von Garmin nach Health Connect ist nur in eine Richtung offiziell.'),
      'fitbit': _brand('Fitbit / Pixel Watch', [
        'Synchronisiere die Uhr in der Fitbit-App.',
        'Gerät → Verbindungen hinzufügen → Health Connect einrichten.',
        'Erlaube ShareRun das Lesen von Health Connect.',
      ]),
      'samsung': _brand('Samsung Galaxy Watch', [
        'Verbinde die Uhr in Samsung Health und synchronisiere einmal.',
        'Einstellungen → Health Connect: Schritte und Herzfrequenz teilen.',
        'Erlaube ShareRun Health Connect. Die Galaxy-Watch-App koppelt auch mit einem 6-stelligen Code.',
      ]),
      'coros_suunto': _brand('COROS / Suunto', [
        'Synchronisiere die Uhr in der COROS- oder Suunto-App.',
        'Unter Android über Health Sync exportieren oder die Pulsübertragung einschalten.',
        'Verbinde die Uhr im BLE-Pulsbildschirm von ShareRun.',
      ], 'Unter iOS schalte Apple Health in der Uhren-App ein.'),
    },
  ),
  'fr': GuideChrome(
    searchHint: 'Chercher une marque (Xiaomi, Garmin, Fitbit)',
    empty: 'Aucune marque trouvée. Essayez un autre nom.',
    back: 'Marques',
    usingApp: 'Appli',
    ctaAndroid: 'Connecter Health Connect',
    ctaIos: 'Connecter Santé Apple',
    brands: {
      'xiaomi': _brand('Xiaomi Mi Band / Redmi Watch', [
        'Associez le bracelet dans Mi Fitness et synchronisez une fois.',
        'Profil → Données tierces → Health Connect : autorisez l’écriture des pas et de la fréquence cardiaque.',
        'Autorisez ShareRun à lire Health Connect, ou activez le partage du pouls et connectez-vous en BLE.',
      ], 'Sur iOS, activez Santé d’Apple dans Mi Fitness.'),
      'amazfit': _brand('Amazfit', [
        'Associez la montre dans Zepp et synchronisez-la.',
        'Profil → Comptes tiers → Health Connect : autorisez les pas et la fréquence cardiaque.',
        'Autorisez Health Connect de ShareRun, ou activez le partage du pouls et utilisez le BLE.',
      ], 'Sur iOS, activez Santé d’Apple dans Zepp.'),
      'garmin': _brand('Garmin', [
        'Synchronisez la montre dans Garmin Connect.',
        'Plus → Réglages → Applis connectées → Health Connect : autorisez le pouls et les pas.',
        'Autorisez Health Connect de ShareRun, ou activez la diffusion du pouls et connectez-vous en BLE.',
      ], 'L’export Garmin vers Health Connect n’est officiel que dans un sens.'),
      'fitbit': _brand('Fitbit / Pixel Watch', [
        'Synchronisez la montre dans l’appli Fitbit.',
        'Appareil → Ajouter des connexions → activez Health Connect.',
        'Autorisez ShareRun à lire Health Connect.',
      ]),
      'samsung': _brand('Samsung Galaxy Watch', [
        'Connectez la montre dans Samsung Health et synchronisez une fois.',
        'Réglages → Health Connect : partagez les pas et la fréquence cardiaque.',
        'Autorisez Health Connect de ShareRun. L’appli Galaxy Watch se couple aussi avec un code à 6 chiffres.',
      ]),
      'coros_suunto': _brand('COROS / Suunto', [
        'Synchronisez la montre dans l’appli COROS ou Suunto.',
        'Sur Android, exportez via Health Sync ou activez la diffusion du pouls.',
        'Connectez la montre depuis l’écran capteur BLE de ShareRun.',
      ], 'Sur iOS, activez Santé d’Apple dans l’appli de la montre.'),
    },
  ),
  'vi': GuideChrome(
    searchHint: 'Tìm hãng (Xiaomi, Garmin, Fitbit)',
    empty: 'Không thấy hãng phù hợp. Thử tên khác.',
    back: 'Danh sách',
    usingApp: 'Ứng dụng',
    ctaAndroid: 'Kết nối Health Connect',
    ctaIos: 'Kết nối Apple Health',
    brands: {
      'xiaomi': _brand('Xiaomi Mi Band / Redmi Watch', [
        'Ghép đôi vòng trong Mi Fitness và đồng bộ một lần.',
        'Hồ sơ → Dữ liệu bên thứ ba → Health Connect: cho phép ghi số bước và nhịp tim.',
        'Cho ShareRun đọc Health Connect, hoặc bật chia sẻ nhịp tim rồi kết nối bằng BLE.',
      ], 'Trên iOS, bật Apple Health trong Mi Fitness.'),
      'amazfit': _brand('Amazfit', [
        'Ghép đôi đồng hồ trong Zepp và đồng bộ.',
        'Hồ sơ → Tài khoản bên thứ ba → Health Connect: cho phép số bước và nhịp tim.',
        'Cho phép Health Connect của ShareRun, hoặc bật chia sẻ nhịp tim và dùng BLE.',
      ], 'Trên iOS, bật Apple Health trong Zepp.'),
      'garmin': _brand('Garmin', [
        'Đồng bộ đồng hồ trong Garmin Connect.',
        'Thêm → Cài đặt → Ứng dụng đã kết nối → Health Connect: cho phép nhịp tim và số bước.',
        'Cho phép Health Connect của ShareRun, hoặc bật phát nhịp tim rồi kết nối bằng BLE.',
      ], 'Garmin chỉ chính thức xuất một chiều sang Health Connect.'),
      'fitbit': _brand('Fitbit / Pixel Watch', [
        'Đồng bộ đồng hồ trong ứng dụng Fitbit.',
        'Thiết bị → Thêm kết nối → bật Health Connect.',
        'Cho ShareRun đọc Health Connect.',
      ]),
      'samsung': _brand('Samsung Galaxy Watch', [
        'Kết nối đồng hồ trong Samsung Health và đồng bộ một lần.',
        'Cài đặt → Health Connect: chia sẻ số bước và nhịp tim.',
        'Cho phép Health Connect của ShareRun. Ứng dụng Galaxy Watch cũng ghép bằng mã 6 số.',
      ]),
      'coros_suunto': _brand('COROS / Suunto', [
        'Đồng bộ đồng hồ trong ứng dụng COROS hoặc Suunto.',
        'Trên Android, xuất qua Health Sync hoặc bật phát nhịp tim.',
        'Kết nối đồng hồ từ màn hình cảm biến BLE của ShareRun.',
      ], 'Trên iOS, bật Apple Health trong ứng dụng của đồng hồ.'),
    },
  ),
  'th': GuideChrome(
    searchHint: 'ค้นหายี่ห้อ (Xiaomi, Garmin, Fitbit)',
    empty: 'ไม่พบยี่ห้อที่ตรงกัน ลองชื่ออื่น',
    back: 'รายการ',
    usingApp: 'แอป',
    ctaAndroid: 'เชื่อม Health Connect',
    ctaIos: 'เชื่อม Apple Health',
    brands: {
      'xiaomi': _brand('Xiaomi Mi Band / Redmi Watch', [
        'จับคู่สายรัดใน Mi Fitness แล้วซิงก์หนึ่งครั้ง',
        'โปรไฟล์ → ข้อมูลบุคคลที่สาม → Health Connect อนุญาตให้เขียนจำนวนก้าวและอัตราการเต้นของหัวใจ',
        'อนุญาตให้ ShareRun อ่าน Health Connect หรือเปิดแชร์หัวใจแล้วเชื่อมด้วย BLE',
      ], 'บน iOS ให้เปิด Apple Health ใน Mi Fitness'),
      'amazfit': _brand('Amazfit', [
        'จับคู่นาฬิกาใน Zepp แล้วซิงก์',
        'โปรไฟล์ → บัญชีบุคคลที่สาม → Health Connect อนุญาตจำนวนก้าวและหัวใจ',
        'อนุญาต Health Connect ของ ShareRun หรือเปิดแชร์หัวใจแล้วใช้ BLE',
      ], 'บน iOS ให้เปิด Apple Health ใน Zepp'),
      'garmin': _brand('Garmin', [
        'ซิงก์นาฬิกาใน Garmin Connect',
        'เพิ่มเติม → การตั้งค่า → แอปที่เชื่อมต่อ → Health Connect อนุญาตหัวใจและจำนวนก้าว',
        'อนุญาต Health Connect ของ ShareRun หรือเปิดการส่งหัวใจแล้วเชื่อมด้วย BLE',
      ], 'Garmin ส่งออกไป Health Connect ได้ทางเดียวอย่างเป็นทางการ'),
      'fitbit': _brand('Fitbit / Pixel Watch', [
        'ซิงก์นาฬิกาในแอป Fitbit',
        'อุปกรณ์ → เพิ่มการเชื่อมต่อ → เปิด Health Connect',
        'อนุญาตให้ ShareRun อ่าน Health Connect',
      ]),
      'samsung': _brand('Samsung Galaxy Watch', [
        'เชื่อมนาฬิกาใน Samsung Health แล้วซิงก์หนึ่งครั้ง',
        'การตั้งค่า → Health Connect เปิดแชร์จำนวนก้าวและหัวใจ',
        'อนุญาต Health Connect ของ ShareRun แอป Galaxy Watch เชื่อมด้วยรหัส 6 หลักได้ด้วย',
      ]),
      'coros_suunto': _brand('COROS / Suunto', [
        'ซิงก์นาฬิกาในแอป COROS หรือ Suunto',
        'บน Android ส่งออกผ่าน Health Sync หรือเปิดการกระจายหัวใจ',
        'เชื่อมนาฬิกาจากหน้าเซ็นเซอร์ BLE ของ ShareRun',
      ], 'บน iOS ให้เปิด Apple Health ในแอปของนาฬิกา'),
    },
  ),
  'id': GuideChrome(
    searchHint: 'Cari merek (Xiaomi, Garmin, Fitbit)',
    empty: 'Merek tidak ditemukan. Coba nama lain.',
    back: 'Merek',
    usingApp: 'Aplikasi',
    ctaAndroid: 'Hubungkan Health Connect',
    ctaIos: 'Hubungkan Apple Health',
    brands: {
      'xiaomi': _brand('Xiaomi Mi Band / Redmi Watch', [
        'Pasangkan gelang di Mi Fitness lalu sinkronkan sekali.',
        'Profil → Data pihak ketiga → Health Connect: izinkan menulis langkah dan detak jantung.',
        'Izinkan ShareRun membaca Health Connect, atau nyalakan berbagi detak jantung dan hubungkan lewat BLE.',
      ], 'Di iOS, nyalakan Apple Health di dalam Mi Fitness.'),
      'amazfit': _brand('Amazfit', [
        'Pasangkan jam di Zepp lalu sinkronkan.',
        'Profil → Akun pihak ketiga → Health Connect: izinkan langkah dan detak jantung.',
        'Izinkan Health Connect ShareRun, atau nyalakan berbagi detak jantung dan gunakan BLE.',
      ], 'Di iOS, nyalakan Apple Health di dalam Zepp.'),
      'garmin': _brand('Garmin', [
        'Sinkronkan jam di Garmin Connect.',
        'Lainnya → Setelan → Aplikasi terhubung → Health Connect: izinkan detak jantung dan langkah.',
        'Izinkan Health Connect ShareRun, atau nyalakan siaran detak jantung lalu hubungkan lewat BLE.',
      ], 'Ekspor Garmin ke Health Connect resmi hanya satu arah.'),
      'fitbit': _brand('Fitbit / Pixel Watch', [
        'Sinkronkan jam di aplikasi Fitbit.',
        'Perangkat → Tambah koneksi → aktifkan Health Connect.',
        'Izinkan ShareRun membaca Health Connect.',
      ]),
      'samsung': _brand('Samsung Galaxy Watch', [
        'Hubungkan jam di Samsung Health lalu sinkronkan sekali.',
        'Setelan → Health Connect: bagikan langkah dan detak jantung.',
        'Izinkan Health Connect ShareRun. Aplikasi Galaxy Watch juga bisa dipasangkan dengan kode 6 digit.',
      ]),
      'coros_suunto': _brand('COROS / Suunto', [
        'Sinkronkan jam di aplikasi COROS atau Suunto.',
        'Di Android, ekspor lewat Health Sync atau nyalakan siaran detak jantung.',
        'Hubungkan jam dari layar sensor BLE ShareRun.',
      ], 'Di iOS, nyalakan Apple Health di aplikasi jam.'),
    },
  ),
};
