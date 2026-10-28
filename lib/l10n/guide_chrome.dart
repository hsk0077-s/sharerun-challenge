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

  static GuideChrome of(Locale locale) {
    if (!_localesReady) {
      _fillLocales();
    }
    final code = ShareRunLocalizations.ofLocale(locale).localeCode.substring(0, 2);
    return _byLanguage[code] ?? _byLanguage['en']!;
  }
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
};

GuideChrome _copy(GuideChrome en, String search, String empty, String back, String using, String android, String ios) {
  return GuideChrome(
    searchHint: search,
    empty: empty,
    back: back,
    usingApp: using,
    ctaAndroid: android,
    ctaIos: ios,
    brands: en.brands,
  );
}

void _fillLocales() {
  final en = _byLanguage['en']!;
  _byLanguage['ja'] = _copy(en, 'ブランド検索（Xiaomi、Garmin、Fitbit）', '一致するブランドがありません。', '一覧', '使用アプリ', 'Health Connect を接続', 'Apple ヘルスケアを接続');
  _byLanguage['zh'] = _copy(en, '搜尋品牌（小米、Garmin、Fitbit）', '找不到相符的品牌。', '品牌列表', '使用的 App', '連接 Health Connect', '連接 Apple 健康');
  _byLanguage['es'] = _copy(en, 'Buscar marca (Xiaomi, Garmin, Fitbit)', 'Ninguna marca coincide.', 'Marcas', 'App', 'Conectar Health Connect', 'Conectar Salud de Apple');
  _byLanguage['pt'] = _copy(en, 'Buscar marca (Xiaomi, Garmin, Fitbit)', 'Nenhuma marca encontrada.', 'Marcas', 'App', 'Conectar Health Connect', 'Conectar Saúde da Apple');
  _byLanguage['de'] = _copy(en, 'Marke suchen (Xiaomi, Garmin, Fitbit)', 'Keine Marke gefunden.', 'Marken', 'App', 'Health Connect verbinden', 'Apple Health verbinden');
  _byLanguage['fr'] = _copy(en, 'Chercher une marque (Xiaomi, Garmin, Fitbit)', 'Aucune marque trouvée.', 'Marques', 'Appli', 'Connecter Health Connect', 'Connecter Santé Apple');
  _byLanguage['vi'] = _copy(en, 'Tìm hãng (Xiaomi, Garmin, Fitbit)', 'Không thấy hãng phù hợp.', 'Danh sách', 'Ứng dụng', 'Kết nối Health Connect', 'Kết nối Apple Health');
  _byLanguage['th'] = _copy(en, 'ค้นหายี่ห้อ (Xiaomi, Garmin, Fitbit)', 'ไม่พบยี่ห้อที่ตรงกัน', 'รายการ', 'แอป', 'เชื่อม Health Connect', 'เชื่อม Apple Health');
  _byLanguage['id'] = _copy(en, 'Cari merek (Xiaomi, Garmin, Fitbit)', 'Merek tidak ditemukan.', 'Merek', 'Aplikasi', 'Hubungkan Health Connect', 'Hubungkan Apple Health');
}

final bool _localesReady = () {
  _fillLocales();
  return true;
}();
