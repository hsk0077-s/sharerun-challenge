import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// Donation and shop guidance that used to exist only in Korean.
///
/// Amounts stay in KRW. The numbers 100 and 7 are the product rules
/// (`VERIFIED_RUN_DONATION_KRW_PER_KM`, the DIA refund window, 1 DIA = 100 KRW).
class DonationGuidance {
  const DonationGuidance({
    required this.homeTitle,
    required this.homeDetail,
    required this.homeEmpty,
    required this.homeFail,
    required this.retry,
    required this.rule,
    required this.budget,
    required this.capReachedHome,
    required this.settlementTitle,
    required this.intro,
    required this.capReachedSettlement,
    required this.disclaimer,
    required this.fail,
    required this.back,
    required this.operatorLine,
    required this.paidByOperator,
    required this.monthLabel,
    required this.currencySuffix,
    required this.kmGaugePattern,
  });

  final String homeTitle;
  final String homeDetail;
  final String homeEmpty;
  final String homeFail;
  final String retry;
  final String rule;
  final String budget;
  final String capReachedHome;
  final String settlementTitle;
  final String intro;
  final String capReachedSettlement;
  final String disclaimer;
  final String fail;
  final String back;
  final String operatorLine;
  final String paidByOperator;
  final String monthLabel;
  final String currencySuffix;

  /// `{done}`, `{cap}`, `{pct}` are replaced by the screen.
  final String kmGaugePattern;

  String kmGauge(String doneKm, String capKm, int pct) => kmGaugePattern
      .replaceAll('{done}', doneKm)
      .replaceAll('{cap}', capKm)
      .replaceAll('{pct}', '$pct');

  static DonationGuidance of(Locale locale) =>
      byLanguage[locale.languageCode] ?? byLanguage['en']!;

  static const byLanguage = <String, DonationGuidance>{
    'ko': DonationGuidance(
      homeTitle: '오늘 나의 기부 기여',
      homeDetail: '기부 내역 ›',
      homeEmpty: '오늘은 아직 기여가 없어요',
      homeFail: '기부 정보를 불러오지 못했어요.',
      retry: '다시 시도',
      rule: '검증된 모든 달리기, 1km마다 회사(운영자) 자금으로 100원을 기부할 예정이에요.',
      budget: '운영자의 월 기부 예산 안에서 진행돼요.',
      capReachedHome: '이번 달 운영자 기부 예산을 모두 사용했어요. 넘는 거리는 기록으로 남아요.',
      settlementTitle: '내가 만든\n기부',
      intro: '달리기 1km마다 회사(운영자) 자금으로 100원을 기부할 예정이에요.',
      capReachedSettlement: '이번 달 운영자 기부 예산을 모두 사용했어요 · 넘는 거리는 기록으로 남아요',
      disclaimer:
          '운영자가 자기 돈으로 검증 1km당 100원(KRW)을 월 예산 안에서 냅니다. '
          '이용자의 기부금이 아니며 세금 공제 영수증이 발급되지 않습니다.',
      fail: '기부 정산을 불러오지 못했어요. 잠시 뒤 다시 시도해 주세요.',
      back: '뒤로',
      operatorLine: '기부는 회사(운영자) 자금으로 할 예정이에요. 앱에서는 내가 기여한 금액을 확인할 수 있어요.',
      paidByOperator: '운영자가 대신 내요 · 내 돈은 0원',
      monthLabel: '이번 달 기부',
      currencySuffix: '원',
      kmGaugePattern: '이번 달 {done} / {cap} km · {pct}%',
    ),
    'en': DonationGuidance(
      homeTitle: 'My donation today',
      homeDetail: 'History ›',
      homeEmpty: 'No contribution yet today',
      homeFail: 'Could not load the donation.',
      retry: 'Try again',
      rule: 'Every verified run is planned to give 100 KRW per km from company (operator) funds.',
      budget: 'It stays inside the operator’s monthly budget.',
      capReachedHome: 'This month’s operator budget is used up. Extra distance stays on the record.',
      settlementTitle: 'The donation\nI made possible',
      intro: 'Each running kilometre is planned to add 100 KRW donated from company (operator) funds.',
      capReachedSettlement: 'This month’s operator budget is used up · extra distance stays on the record',
      disclaimer:
          'The operator pays 100 KRW of its own money per verified kilometre, inside the monthly budget. '
          'This is not your donation and no tax receipt is issued.',
      fail: 'Could not load the settlement. Try again in a moment.',
      back: 'Back',
      operatorLine: 'The company (operator) plans to donate from its own funds. The app only shows what you made possible.',
      paidByOperator: 'The operator pays · your money is 0 KRW',
      monthLabel: 'This month',
      currencySuffix: ' KRW',
      kmGaugePattern: 'This month {done} / {cap} km · {pct}%',
    ),
    'ja': DonationGuidance(
      homeTitle: '今日の寄付への貢献',
      homeDetail: '履歴 ›',
      homeEmpty: '今日はまだ貢献がありません',
      homeFail: '寄付情報を読み込めませんでした。',
      retry: 'もう一度',
      rule: '認証されたランニングは1kmごとに、会社（運営者）の資金から100ウォンを寄付する予定です。',
      budget: '運営の月間予算の範囲で行われます。',
      capReachedHome: '今月の運営予算は使い切りました。超えた距離は記録として残ります。',
      settlementTitle: '私がつないだ\n寄付',
      intro: 'ランニング1kmごとに、会社（運営者）の資金から100ウォンを寄付する予定です。',
      capReachedSettlement: '今月の運営予算は使い切りました · 超えた距離は記録として残ります',
      disclaimer:
          '運営が自己資金で、認証1kmあたり100ウォン（KRW）を月間予算の中で支払います。'
          '利用者の寄付ではなく、税額控除の領収書はありません。',
      fail: '精算を読み込めませんでした。しばらくしてからもう一度お試しください。',
      back: '戻る',
      operatorLine: '寄付は会社（運営者）の資金で行う予定です。アプリでは自分が貢献した金額を確認できます。',
      paidByOperator: '運営が代わりに支払います · あなたの支払いは0ウォン',
      monthLabel: '今月の寄付',
      currencySuffix: ' KRW',
      kmGaugePattern: '今月 {done} / {cap} km · {pct}%',
    ),
    'zh': DonationGuidance(
      homeTitle: '今天我促成的公益',
      homeDetail: '紀錄 ›',
      homeEmpty: '今天還沒有貢獻',
      homeFail: '無法載入公益資料。',
      retry: '再試一次',
      rule: '每一段通過驗證的跑步，每 1 公里預計由公司（營運方）資金捐出 100 韓元。',
      budget: '只在營運方的每月預算內進行。',
      capReachedHome: '本月營運方預算已用完。超出的距離仍會留在紀錄裡。',
      settlementTitle: '我促成的\n公益',
      intro: '每跑 1 公里，預計以公司（營運方）資金捐出 100 韓元。',
      capReachedSettlement: '本月營運方預算已用完 · 超出的距離仍留在紀錄裡',
      disclaimer:
          '營運方用自己的錢，為每 1 公里驗證里程支付 100 韓元（KRW），且不超過每月預算。'
          '這不是使用者的捐款，也不開立抵稅收據。',
      fail: '無法載入結算。請稍後再試。',
      back: '返回',
      operatorLine: '預計由公司（營運方）出資捐款。應用程式只顯示你促成的金額。',
      paidByOperator: '由營運方代付 · 你的錢是 0 韓元',
      monthLabel: '本月公益',
      currencySuffix: ' KRW',
      kmGaugePattern: '本月 {done} / {cap} km · {pct}%',
    ),
    'es': DonationGuidance(
      homeTitle: 'Mi aporte de hoy',
      homeDetail: 'Historial ›',
      homeEmpty: 'Hoy todavía no hay aporte',
      homeFail: 'No se pudo cargar la información.',
      retry: 'Reintentar',
      rule: 'Cada carrera verificada prevé donar 100 KRW por km con fondos de la empresa (operador).',
      budget: 'Ocurre dentro del presupuesto mensual del operador.',
      capReachedHome: 'El presupuesto del operador de este mes se agotó. La distancia de más queda en el registro.',
      settlementTitle: 'La aportación\nque hice posible',
      intro: 'Cada kilómetro de carrera prevé sumar 100 KRW donados con fondos de la empresa (operador).',
      capReachedSettlement: 'El presupuesto del operador de este mes se agotó · la distancia de más queda en el registro',
      disclaimer:
          'El operador paga 100 KRW de su dinero por kilómetro verificado, dentro del presupuesto mensual. '
          'No es tu donativo y no hay recibo fiscal.',
      fail: 'No se pudo cargar el cierre. Inténtalo de nuevo en un momento.',
      back: 'Atrás',
      operatorLine: 'La empresa (operador) prevé donar con sus propios fondos. La app solo muestra lo que tú hiciste posible.',
      paidByOperator: 'Lo paga el operador · tu dinero es 0 KRW',
      monthLabel: 'Este mes',
      currencySuffix: ' KRW',
      kmGaugePattern: 'Este mes {done} / {cap} km · {pct}%',
    ),
    'pt': DonationGuidance(
      homeTitle: 'Minha contribuição de hoje',
      homeDetail: 'Histórico ›',
      homeEmpty: 'Ainda não há contribuição hoje',
      homeFail: 'Não foi possível carregar a doação.',
      retry: 'Tentar de novo',
      rule: 'Cada corrida verificada prevê doar 100 KRW por km com recursos da empresa (operadora).',
      budget: 'Isso acontece dentro do orçamento mensal da operadora.',
      capReachedHome: 'O orçamento da operadora deste mês acabou. A distância extra fica no registro.',
      settlementTitle: 'A doação\nque eu possibilitei',
      intro: 'Cada quilômetro de corrida prevê somar 100 KRW doados com recursos da empresa (operadora).',
      capReachedSettlement: 'O orçamento da operadora deste mês acabou · a distância extra fica no registro',
      disclaimer:
          'A operadora paga 100 KRW do próprio dinheiro por quilômetro verificado, dentro do orçamento mensal. '
          'Não é doação do usuário e não há recibo fiscal.',
      fail: 'Não foi possível carregar o fechamento. Tente de novo daqui a pouco.',
      back: 'Voltar',
      operatorLine: 'A empresa (operadora) pretende doar com recursos próprios. O app só mostra o que você possibilitou.',
      paidByOperator: 'A operadora paga · o seu dinheiro é 0 KRW',
      monthLabel: 'Este mês',
      currencySuffix: ' KRW',
      kmGaugePattern: 'Este mês {done} / {cap} km · {pct}%',
    ),
    'de': DonationGuidance(
      homeTitle: 'Mein Beitrag heute',
      homeDetail: 'Verlauf ›',
      homeEmpty: 'Heute noch kein Beitrag',
      homeFail: 'Die Spendeninfo konnte nicht geladen werden.',
      retry: 'Nochmal versuchen',
      rule: 'Für jeden geprüften Lauf sind 100 KRW pro km aus Mitteln des Unternehmens (Betreiber) als Spende geplant.',
      budget: 'Das bleibt im Monatsbudget des Betreibers.',
      capReachedHome: 'Das Betreiberbudget dieses Monats ist aufgebraucht. Die Extra-Distanz bleibt in der Aufzeichnung.',
      settlementTitle: 'Die Spende,\ndie ich möglich gemacht habe',
      intro: 'Für jeden Laufkilometer sind 100 KRW Spende aus Mitteln des Unternehmens (Betreiber) geplant.',
      capReachedSettlement: 'Das Betreiberbudget dieses Monats ist aufgebraucht · Extra-Distanz bleibt in der Aufzeichnung',
      disclaimer:
          'Der Betreiber zahlt 100 KRW eigenes Geld pro geprüftem Kilometer, innerhalb des Monatsbudgets. '
          'Das ist keine Spende der Nutzer und es gibt keine Steuerquittung.',
      fail: 'Die Abrechnung konnte nicht geladen werden. Versuch es gleich noch einmal.',
      back: 'Zurück',
      operatorLine: 'Das Unternehmen (Betreiber) plant, aus eigenen Mitteln zu spenden. Die App zeigt nur, was du möglich gemacht hast.',
      paidByOperator: 'Der Betreiber zahlt · dein Geld ist 0 KRW',
      monthLabel: 'Dieser Monat',
      currencySuffix: ' KRW',
      kmGaugePattern: 'Dieser Monat {done} / {cap} km · {pct}%',
    ),
    'fr': DonationGuidance(
      homeTitle: 'Ma contribution du jour',
      homeDetail: 'Historique ›',
      homeEmpty: 'Pas encore de contribution aujourd’hui',
      homeFail: 'Impossible de charger le don.',
      retry: 'Réessayer',
      rule: 'Chaque course vérifiée prévoit un don de 100 KRW par km sur les fonds de l’entreprise (opérateur).',
      budget: 'Cela reste dans le budget mensuel de l’opérateur.',
      capReachedHome: 'Le budget de l’opérateur pour ce mois est épuisé. La distance en plus reste dans l’enregistrement.',
      settlementTitle: 'Le don\nque j’ai rendu possible',
      intro: 'Chaque kilomètre de course prévoit 100 KRW de don sur les fonds de l’entreprise (opérateur).',
      capReachedSettlement: 'Le budget de l’opérateur pour ce mois est épuisé · la distance en plus reste dans l’enregistrement',
      disclaimer:
          'L’opérateur paie 100 KRW de son argent par kilomètre vérifié, dans le budget mensuel. '
          'Ce n’est pas un don de l’utilisateur et il n’y a pas de reçu fiscal.',
      fail: 'Impossible de charger le décompte. Réessayez dans un instant.',
      back: 'Retour',
      operatorLine: 'L’entreprise (opérateur) prévoit de donner sur ses propres fonds. L’appli montre seulement ce que vous avez rendu possible.',
      paidByOperator: 'L’opérateur paie · votre argent est de 0 KRW',
      monthLabel: 'Ce mois-ci',
      currencySuffix: ' KRW',
      kmGaugePattern: 'Ce mois-ci {done} / {cap} km · {pct}%',
    ),
    'vi': DonationGuidance(
      homeTitle: 'Phần tôi góp hôm nay',
      homeDetail: 'Lịch sử ›',
      homeEmpty: 'Hôm nay chưa có đóng góp',
      homeFail: 'Không tải được thông tin quyên góp.',
      retry: 'Thử lại',
      rule: 'Mỗi lần chạy đã xác minh dự kiến quyên góp 100 KRW cho mỗi km từ ngân sách công ty (đơn vị vận hành).',
      budget: 'Việc này nằm trong ngân sách tháng của đơn vị vận hành.',
      capReachedHome: 'Ngân sách tháng này đã dùng hết. Quãng đường vượt mức vẫn được ghi lại.',
      settlementTitle: 'Khoản đóng góp\ntôi tạo ra',
      intro: 'Mỗi km chạy dự kiến cộng 100 KRW quyên góp từ ngân sách công ty (đơn vị vận hành).',
      capReachedSettlement: 'Ngân sách tháng này đã dùng hết · quãng đường vượt mức vẫn được ghi lại',
      disclaimer:
          'Đơn vị vận hành trả 100 KRW tiền của mình cho mỗi km đã xác minh, trong ngân sách tháng. '
          'Đây không phải tiền quyên góp của người dùng và không có biên lai thuế.',
      fail: 'Không tải được bảng quyết toán. Hãy thử lại sau giây lát.',
      back: 'Quay lại',
      operatorLine: 'Công ty (đơn vị vận hành) dự kiến quyên góp từ ngân sách riêng. Ứng dụng chỉ hiện số bạn đã tạo ra.',
      paidByOperator: 'Đơn vị vận hành trả · tiền của bạn là 0 KRW',
      monthLabel: 'Tháng này',
      currencySuffix: ' KRW',
      kmGaugePattern: 'Tháng này {done} / {cap} km · {pct}%',
    ),
    'th': DonationGuidance(
      homeTitle: 'ส่วนที่ฉันทำให้เกิดวันนี้',
      homeDetail: 'ประวัติ ›',
      homeEmpty: 'วันนี้ยังไม่มีการร่วม',
      homeFail: 'โหลดข้อมูลการบริจาคไม่ได้',
      retry: 'ลองอีกครั้ง',
      rule: 'การวิ่งที่ยืนยันแล้วทุกครั้ง วางแผนบริจาค 100 วอนต่อ 1 กม. จากเงินของบริษัท (ผู้ให้บริการ)',
      budget: 'ทำภายในงบรายเดือนของผู้ให้บริการ',
      capReachedHome: 'งบของผู้ให้บริการเดือนนี้ใช้หมดแล้ว ระยะที่เกินจะยังอยู่ในบันทึก',
      settlementTitle: 'การสมทบ\nที่ฉันทำให้เกิด',
      intro: 'ทุก 1 กิโลเมตรที่วิ่ง วางแผนบริจาค 100 วอนจากเงินของบริษัท (ผู้ให้บริการ)',
      capReachedSettlement: 'งบของผู้ให้บริการเดือนนี้ใช้หมดแล้ว · ระยะที่เกินยังอยู่ในบันทึก',
      disclaimer:
          'ผู้ให้บริการจ่ายเงินของตนเอง 100 วอน (KRW) ต่อ 1 กม. ที่ยืนยันแล้ว ภายในงบรายเดือน '
          'ไม่ใช่เงินบริจาคของผู้ใช้ และไม่มีใบเสร็จลดหย่อนภาษี',
      fail: 'โหลดยอดสรุปไม่ได้ ลองอีกครั้งอีกสักครู่',
      back: 'กลับ',
      operatorLine: 'บริษัท (ผู้ให้บริการ) วางแผนบริจาคจากเงินของบริษัทเอง แอปแค่แสดงจำนวนที่คุณทำให้เกิด',
      paidByOperator: 'ผู้ให้บริการจ่ายให้ · เงินของคุณคือ 0 วอน',
      monthLabel: 'เดือนนี้',
      currencySuffix: ' KRW',
      kmGaugePattern: 'เดือนนี้ {done} / {cap} km · {pct}%',
    ),
    'id': DonationGuidance(
      homeTitle: 'Kontribusi saya hari ini',
      homeDetail: 'Riwayat ›',
      homeEmpty: 'Hari ini belum ada kontribusi',
      homeFail: 'Data donasi tidak bisa dimuat.',
      retry: 'Coba lagi',
      rule: 'Setiap lari terverifikasi direncanakan mendonasikan 100 KRW per km dari dana perusahaan (penyelenggara).',
      budget: 'Ini berlangsung di dalam anggaran bulanan penyelenggara.',
      capReachedHome: 'Anggaran penyelenggara bulan ini habis. Jarak selebihnya tetap tercatat.',
      settlementTitle: 'Donasi\nyang saya mungkinkan',
      intro: 'Setiap kilometer lari direncanakan menambah donasi 100 KRW dari dana perusahaan (penyelenggara).',
      capReachedSettlement: 'Anggaran penyelenggara bulan ini habis · jarak selebihnya tetap tercatat',
      disclaimer:
          'Penyelenggara membayar 100 KRW dari uangnya sendiri per kilometer terverifikasi, di dalam anggaran bulanan. '
          'Ini bukan donasi pengguna dan tidak ada bukti potong pajak.',
      fail: 'Rekap tidak bisa dimuat. Coba lagi sebentar lagi.',
      back: 'Kembali',
      operatorLine: 'Perusahaan (penyelenggara) berencana mendonasikan dari dananya sendiri. Aplikasi hanya menampilkan apa yang Anda mungkinkan.',
      paidByOperator: 'Penyelenggara yang membayar · uang Anda 0 KRW',
      monthLabel: 'Bulan ini',
      currencySuffix: ' KRW',
      kmGaugePattern: 'Bulan ini {done} / {cap} km · {pct}%',
    ),
  };
}

class ShopFundingGuidance {
  const ShopFundingGuidance({
    required this.title,
    required this.preparing,
    required this.preparingNote,
    required this.monthLabel,
    required this.note,
    required this.allReached,
    required this.capReached,
    required this.stageLinePattern,
  });

  final String title;
  final String preparing;
  final String preparingNote;
  final String monthLabel;
  final String note;
  final String allReached;
  final String capReached;
  final String stageLinePattern;

  String stageLine(int stage, String wonLabel) =>
      stageLinePattern.replaceAll('{stage}', '$stage').replaceAll('{won}', wonLabel);

  static ShopFundingGuidance of(Locale locale) =>
      byLanguage[locale.languageCode] ?? byLanguage['en']!;

  static const byLanguage = <String, ShopFundingGuidance>{
    'ko': ShopFundingGuidance(
      title: '🌍 땀방울로 만드는 기적,\n기부 펀딩',
      preparing: '준비 중',
      preparingNote: '아직 열리지 않았어요. 열리면 이번 달 모인 기부금이 여기에 보여요.',
      monthLabel: '이번 달 모인 기부금',
      note: '운영자가 대신 내요 · 내 돈은 0원. 이용자의 기부금이 아니에요.',
      allReached: '이번 달 거리 목표를 모두 채웠어요',
      capReached: '이번 달 운영자 기부 예산을 모두 사용했어요. 넘는 거리는 기록으로 남아요.',
      stageLinePattern: '목표 {stage}단계 · {won}',
    ),
    'en': ShopFundingGuidance(
      title: '🌍 A fund built from sweat,\ncharity pool',
      preparing: 'Not open yet',
      preparingNote: 'Not open yet. When it opens, this month’s pool shows here.',
      monthLabel: 'Raised this month',
      note: 'The operator pays · your money is 0 KRW. This is not your donation.',
      allReached: 'This month’s distance goal is full',
      capReached: 'This month’s operator budget is used up. Extra distance stays on the record.',
      stageLinePattern: 'Stage {stage} goal · {won}',
    ),
    'ja': ShopFundingGuidance(
      title: '🌍 汗でつくる奇跡、\n寄付ファンディング',
      preparing: '準備中',
      preparingNote: 'まだ開いていません。開くと今月集まった額がここに出ます。',
      monthLabel: '今月集まった寄付',
      note: '運営が代わりに支払います · あなたの支払いは0ウォン。利用者の寄付ではありません。',
      allReached: '今月の距離目標をすべて達成しました',
      capReached: '今月の運営予算は使い切りました。超えた距離は記録として残ります。',
      stageLinePattern: '目標ステージ{stage} · {won}',
    ),
    'zh': ShopFundingGuidance(
      title: '🌍 用汗水促成的奇蹟，\n公益募集',
      preparing: '準備中',
      preparingNote: '還沒開放。開放後，本月累計會顯示在這裡。',
      monthLabel: '本月累計',
      note: '由營運方代付 · 你的錢是 0 韓元。不是使用者的捐款。',
      allReached: '本月距離目標已滿',
      capReached: '本月營運方預算已用完。超出的距離仍留在紀錄裡。',
      stageLinePattern: '目標第 {stage} 階 · {won}',
    ),
    'es': ShopFundingGuidance(
      title: '🌍 Un fondo hecho de sudor,\nfondo solidario',
      preparing: 'Aún no',
      preparingNote: 'Todavía no está abierto. Cuando abra, el total del mes se verá aquí.',
      monthLabel: 'Reunido este mes',
      note: 'Lo paga el operador · tu dinero es 0 KRW. No es tu donativo.',
      allReached: 'La meta de distancia de este mes está completa',
      capReached: 'El presupuesto del operador de este mes se agotó. La distancia de más queda en el registro.',
      stageLinePattern: 'Meta etapa {stage} · {won}',
    ),
    'pt': ShopFundingGuidance(
      title: '🌍 Um fundo feito de suor,\nfundo solidário',
      preparing: 'Em breve',
      preparingNote: 'Ainda não abriu. Quando abrir, o total do mês aparece aqui.',
      monthLabel: 'Arrecadado neste mês',
      note: 'A operadora paga · o seu dinheiro é 0 KRW. Não é doação do usuário.',
      allReached: 'A meta de distância deste mês está cheia',
      capReached: 'O orçamento da operadora deste mês acabou. A distância extra fica no registro.',
      stageLinePattern: 'Meta etapa {stage} · {won}',
    ),
    'de': ShopFundingGuidance(
      title: '🌍 Ein Fonds aus Schweiß,\nSpendenpool',
      preparing: 'Noch nicht offen',
      preparingNote: 'Noch nicht offen. Wenn er öffnet, steht die Monatssumme hier.',
      monthLabel: 'Diesen Monat gesammelt',
      note: 'Der Betreiber zahlt · dein Geld ist 0 KRW. Keine Spende der Nutzer.',
      allReached: 'Das Distanzziel dieses Monats ist voll',
      capReached: 'Das Betreiberbudget dieses Monats ist aufgebraucht. Extra-Distanz bleibt in der Aufzeichnung.',
      stageLinePattern: 'Ziel Stufe {stage} · {won}',
    ),
    'fr': ShopFundingGuidance(
      title: '🌍 Un fonds né de la sueur,\nfonds solidaire',
      preparing: 'Pas encore ouvert',
      preparingNote: 'Pas encore ouvert. Une fois ouvert, le total du mois s’affiche ici.',
      monthLabel: 'Réuni ce mois-ci',
      note: 'L’opérateur paie · votre argent est de 0 KRW. Ce n’est pas votre don.',
      allReached: 'L’objectif de distance du mois est atteint',
      capReached: 'Le budget de l’opérateur pour ce mois est épuisé. La distance en plus reste dans l’enregistrement.',
      stageLinePattern: 'Objectif étape {stage} · {won}',
    ),
    'vi': ShopFundingGuidance(
      title: '🌍 Quỹ từ mồ hôi,\nquỹ thiện nguyện',
      preparing: 'Chưa mở',
      preparingNote: 'Chưa mở. Khi mở, số tiền tháng này hiện ở đây.',
      monthLabel: 'Đã góp tháng này',
      note: 'Đơn vị vận hành trả · tiền của bạn là 0 KRW. Không phải tiền quyên góp của người dùng.',
      allReached: 'Mục tiêu khoảng cách tháng này đã đủ',
      capReached: 'Ngân sách tháng này đã dùng hết. Quãng đường vượt mức vẫn được ghi lại.',
      stageLinePattern: 'Mục tiêu chặng {stage} · {won}',
    ),
    'th': ShopFundingGuidance(
      title: '🌍 กองทุนจากเหงื่อ,\nกองทุนสาธารณะ',
      preparing: 'ยังไม่เปิด',
      preparingNote: 'ยังไม่เปิด เมื่อเปิดแล้ว ยอดเดือนนี้จะแสดงที่นี่',
      monthLabel: 'ยอดเดือนนี้',
      note: 'ผู้ให้บริการจ่ายให้ · เงินของคุณคือ 0 วอน ไม่ใช่เงินบริจาคของผู้ใช้',
      allReached: 'เป้าหมายระยะทางเดือนนี้เต็มแล้ว',
      capReached: 'งบของผู้ให้บริการเดือนนี้ใช้หมดแล้ว ระยะที่เกินจะยังอยู่ในบันทึก',
      stageLinePattern: 'เป้าหมายขั้น {stage} · {won}',
    ),
    'id': ShopFundingGuidance(
      title: '🌍 Dana dari keringat,\ndana donasi',
      preparing: 'Belum dibuka',
      preparingNote: 'Belum dibuka. Saat dibuka, jumlah bulan ini muncul di sini.',
      monthLabel: 'Terkumpul bulan ini',
      note: 'Penyelenggara yang membayar · uang Anda 0 KRW. Bukan donasi pengguna.',
      allReached: 'Target jarak bulan ini sudah penuh',
      capReached: 'Anggaran penyelenggara bulan ini habis. Jarak selebihnya tetap tercatat.',
      stageLinePattern: 'Target tahap {stage} · {won}',
    ),
  };
}

class DiaNoticeGuidance {
  const DiaNoticeGuidance({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  static DiaNoticeGuidance of(Locale locale) =>
      byLanguage[locale.languageCode] ?? byLanguage['en']!;

  static const byLanguage = <String, DiaNoticeGuidance>{
    'ko': DiaNoticeGuidance(
      title: 'DIA 안내',
      lines: [
        '1 DIA는 100원이에요.',
        '돈으로 산 DIA(유료)와 무료로 받은 DIA(보너스)가 있어요. 쓸 때는 보너스 DIA를 먼저 써요.',
        '보너스 DIA는 현금으로 바꿀 수 없어요.',
        '배틀패스와 패스+는 유료 DIA로만 살 수 있어요.',
        '산 날부터 7일 안에, 쓰지 않은 유료 DIA는 환불할 수 있어요. 함께 받은 덤(보너스)은 같이 빠지고, 이미 쓴 덤은 환불 금액에서 DIA당 100원씩 빼요.',
      ],
    ),
    'en': DiaNoticeGuidance(
      title: 'About DIA',
      lines: [
        '1 DIA is 100 KRW.',
        'DIA you buy (paid) and DIA you receive free (bonus) are separate. Bonus DIA is spent first.',
        'Bonus DIA cannot be turned into cash.',
        'The battle pass and Pass+ can be bought only with paid DIA.',
        'Unused paid DIA can be refunded within 7 days of purchase. The bonus that came with it is removed too, and bonus you already spent is deducted at 100 KRW per DIA.',
      ],
    ),
    'ja': DiaNoticeGuidance(
      title: 'DIAについて',
      lines: [
        '1 DIAは100ウォンです。',
        'お金で買ったDIA（有料）と、無料でもらったDIA（ボーナス）があります。使うときはボーナスDIAから先に使います。',
        'ボーナスDIAは現金に換えられません。',
        'バトルパスとパス+は有料DIAでしか買えません。',
        '購入日から7日以内なら、使っていない有料DIAは返金できます。一緒にもらったボーナスは一緒に減り、すでに使ったボーナスはDIAあたり100ウォンを返金額から引きます。',
      ],
    ),
    'zh': DiaNoticeGuidance(
      title: 'DIA 說明',
      lines: [
        '1 DIA 是 100 韓元。',
        '用錢買的 DIA（付費）和免費拿到的 DIA（獎勵）是分開的。使用時先扣獎勵 DIA。',
        '獎勵 DIA 不能換成現金。',
        '戰鬥通行證和 Pass+ 只能用付費 DIA 購買。',
        '購買日起 7 天內，未使用的付費 DIA 可以退款。一併獲得的獎勵會一起扣回，已經用掉的獎勵按每 DIA 100 韓元從退款扣除。',
      ],
    ),
    'es': DiaNoticeGuidance(
      title: 'Sobre DIA',
      lines: [
        '1 DIA son 100 KRW.',
        'Hay DIA comprado (de pago) y DIA recibido gratis (bonus). Al gastar, se usa primero el bonus.',
        'El DIA bonus no se puede cambiar por dinero.',
        'El pase de batalla y Pass+ solo se compran con DIA de pago.',
        'El DIA de pago no usado se puede reembolsar en los 7 días desde la compra. El bonus que vino junto se retira, y el bonus ya gastado se descuenta a 100 KRW por DIA.',
      ],
    ),
    'pt': DiaNoticeGuidance(
      title: 'Sobre DIA',
      lines: [
        '1 DIA equivale a 100 KRW.',
        'Existe DIA comprado (pago) e DIA recebido de graça (bônus). Na hora de gastar, o bônus sai primeiro.',
        'DIA bônus não vira dinheiro.',
        'O passe de batalha e o Pass+ só podem ser comprados com DIA pago.',
        'DIA pago não usado pode ser reembolsado em até 7 dias da compra. O bônus que veio junto sai também, e o bônus já gasto é descontado a 100 KRW por DIA.',
      ],
    ),
    'de': DiaNoticeGuidance(
      title: 'Über DIA',
      lines: [
        '1 DIA sind 100 KRW.',
        'Es gibt DIA, das du kaufst (bezahlt), und DIA, das du gratis bekommst (Bonus). Verbraucht wird zuerst der Bonus.',
        'Bonus-DIA lässt sich nicht in Geld tauschen.',
        'Battle Pass und Pass+ gibt es nur für bezahltes DIA.',
        'Unbenutztes bezahltes DIA kann innerhalb von 7 Tagen nach dem Kauf erstattet werden. Der mitgegebene Bonus fällt mit weg, und schon verbrauchter Bonus wird mit 100 KRW pro DIA vom Erstattungsbetrag abgezogen.',
      ],
    ),
    'fr': DiaNoticeGuidance(
      title: 'À propos des DIA',
      lines: [
        '1 DIA vaut 100 KRW.',
        'Il y a les DIA achetés (payants) et les DIA reçus gratuitement (bonus). Les bonus sont dépensés en premier.',
        'Les DIA bonus ne se changent pas en argent.',
        'Le passe de combat et Pass+ s’achètent seulement avec des DIA payants.',
        'Les DIA payants non utilisés peuvent être remboursés dans les 7 jours après l’achat. Le bonus reçu avec est retiré, et le bonus déjà dépensé est déduit à 100 KRW par DIA.',
      ],
    ),
    'vi': DiaNoticeGuidance(
      title: 'Về DIA',
      lines: [
        '1 DIA là 100 KRW.',
        'Có DIA mua bằng tiền (trả phí) và DIA nhận miễn phí (thưởng). Khi dùng, thưởng được trừ trước.',
        'DIA thưởng không đổi được thành tiền mặt.',
        'Battle pass và Pass+ chỉ mua bằng DIA trả phí.',
        'DIA trả phí chưa dùng có thể hoàn trong 7 ngày kể từ ngày mua. Phần thưởng đi kèm sẽ bị thu lại, và phần thưởng đã dùng bị trừ 100 KRW mỗi DIA khỏi số hoàn.',
      ],
    ),
    'th': DiaNoticeGuidance(
      title: 'เกี่ยวกับ DIA',
      lines: [
        '1 DIA เท่ากับ 100 วอน',
        'มี DIA ที่ซื้อด้วยเงิน (แบบเสียเงิน) และ DIA ที่ได้ฟรี (โบนัส) เวลาใช้จะใช้โบนัสก่อน',
        'DIA โบนัสเปลี่ยนเป็นเงินสดไม่ได้',
        'แบตเทิลพาสและ Pass+ ซื้อได้ด้วย DIA แบบเสียเงินเท่านั้น',
        'DIA แบบเสียเงินที่ยังไม่ใช้ คืนเงินได้ภายใน 7 วันนับจากวันที่ซื้อ โบนัสที่ได้มาด้วยจะถูกดึงกลับ และโบนัสที่ใช้ไปแล้วจะถูกหัก 100 วอนต่อ DIA จากยอดคืน',
      ],
    ),
    'id': DiaNoticeGuidance(
      title: 'Tentang DIA',
      lines: [
        '1 DIA sama dengan 100 KRW.',
        'Ada DIA yang dibeli (berbayar) dan DIA yang didapat gratis (bonus). Saat dipakai, bonus terpakai lebih dulu.',
        'DIA bonus tidak bisa diubah menjadi uang.',
        'Battle pass dan Pass+ hanya bisa dibeli dengan DIA berbayar.',
        'DIA berbayar yang belum terpakai bisa dikembalikan dalam 7 hari sejak pembelian. Bonus yang ikut diterima ikut ditarik, dan bonus yang sudah terpakai dipotong 100 KRW per DIA dari nilai pengembalian.',
      ],
    ),
  };
}

/// Shop, refund, accessory, and donation-match copy now live in
/// `commerce_copy.dart` and `accessory_names.dart` for all 11 locales.
const koreanOnlyGuidanceSurfaces = <String>[];

List<String> missingGuidanceKeys() {
  final missing = <String>[];
  for (final locale in ShareRunLocalizations.supportedLocales) {
    final code = locale.languageCode;
    final tag = '${locale.languageCode}-${locale.countryCode}';
    final donation = DonationGuidance.byLanguage[code];
    final shop = ShopFundingGuidance.byLanguage[code];
    final dia = DiaNoticeGuidance.byLanguage[code];
    if (donation == null) missing.add('$tag.donation');
    if (shop == null) missing.add('$tag.shopFunding');
    if (dia == null) missing.add('$tag.diaNotice');
    if (dia != null && dia.lines.length != 5) missing.add('$tag.diaNotice.lines');
    if (code == 'en') continue;
    if (donation != null && donation.intro == DonationGuidance.byLanguage['en']!.intro) {
      missing.add('$tag.donation.intro=en');
    }
    if (shop != null && shop.note == ShopFundingGuidance.byLanguage['en']!.note) {
      missing.add('$tag.shopFunding.note=en');
    }
    if (dia != null && dia.lines.first == DiaNoticeGuidance.byLanguage['en']!.lines.first) {
      missing.add('$tag.diaNotice.lines=en');
    }
  }
  return missing;
}
