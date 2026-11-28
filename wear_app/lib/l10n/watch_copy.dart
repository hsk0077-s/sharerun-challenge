import 'package:flutter/widgets.dart';

/// Face copy for the standalone watch. Same 11 language codes as the phone app.
/// 원어민 검수 전. 광고 랜딩에 쓰지 않는다.
class WatchCopy {
  const WatchCopy({
    required this.start,
    required this.linked,
    required this.tapToStart,
    required this.pairingHint,
    required this.checking,
    required this.later,
    required this.running,
    required this.paused,
    required this.pauseHint,
    required this.rankAlert,
    required this.leading,
    required this.done,
    required this.nothingToUpload,
  });

  final String start;
  final String linked;
  final String tapToStart;
  final String pairingHint;
  final String checking;
  final String later;
  final String running;
  final String paused;
  final String pauseHint;
  final String rankAlert;
  final String leading;
  final String done;
  final String nothingToUpload;

  String aheadOf(int people) =>
      start == '시작' ? '대회 $people명 앞서요' : '$rankAlert +$people';

  String uploadPending(int count) =>
      start == '시작' ? '휴대폰 연결 시 올려요 ($count)' : '$done ($count)';

  static WatchCopy of(Locale locale) => _all[locale.languageCode] ?? _all['en']!;

  static String minutes(Locale locale, int count) =>
      _watchRow(minutePatterns, locale.languageCode).replaceAll('{n}', '$count');

  static String rankPlace(Locale locale, int rank) =>
      _watchRow(rankPatterns, locale.languageCode).replaceAll('{n}', '$rank');

  /// Known pairing codes become the locale sentence. Anything else is shown as-is.
  static String pairingError(Locale locale, String code) =>
      pairingErrorRows.containsKey(code) ? _watchRow(pairingErrorRows[code]!, locale.languageCode) : code;

  static WatchCopy ofContext(BuildContext context) =>
      of(WidgetsBinding.instance.platformDispatcher.locale);
}

const _ko = WatchCopy(
  start: '시작',
  linked: '연결됨',
  tapToStart: '탭해서 시작',
  pairingHint: '휴대폰 앱의 6자리',
  checking: '확인하는 중',
  later: '나중에',
  running: '달리는 중',
  paused: '일시정지',
  pauseHint: '탭해서 다시 시작\n길게 눌러 끝내기',
  rankAlert: '대회 알림',
  leading: '선두예요',
  done: '끝',
  nothingToUpload: '올릴 기록 없음',
);

const _en = WatchCopy(
  start: 'Start',
  linked: 'Linked',
  tapToStart: 'Tap to start',
  pairingHint: '6 digits from the phone',
  checking: 'Checking',
  later: 'Later',
  running: 'Running',
  paused: 'Paused',
  pauseHint: 'Tap to resume\nHold to finish',
  rankAlert: 'Race',
  leading: 'In the lead',
  done: 'Done',
  nothingToUpload: 'Nothing to upload',
);

final _all = <String, WatchCopy>{
  'ko': _ko,
  'en': _en,
  'ja': const WatchCopy(
    start: '開始',
    linked: '接続済み',
    tapToStart: 'タップで開始',
    pairingHint: 'スマホの6桁',
    checking: '確認中',
    later: 'あとで',
    running: '走行中',
    paused: '一時停止',
    pauseHint: 'タップで再開\n長押しで終了',
    rankAlert: 'レース',
    leading: '先頭です',
    done: '終了',
    nothingToUpload: '送る記録なし',
  ),
  'zh': const WatchCopy(
    start: '開始',
    linked: '已連結',
    tapToStart: '點一下開始',
    pairingHint: '手機上的 6 位數',
    checking: '確認中',
    later: '稍後',
    running: '跑步中',
    paused: '暫停',
    pauseHint: '點一下繼續\n長按結束',
    rankAlert: '比賽',
    leading: '目前領先',
    done: '結束',
    nothingToUpload: '沒有要上傳的紀錄',
  ),
  'es': const WatchCopy(
    start: 'Empezar',
    linked: 'Vinculado',
    tapToStart: 'Toca para empezar',
    pairingHint: '6 dígitos del teléfono',
    checking: 'Comprobando',
    later: 'Luego',
    running: 'Corriendo',
    paused: 'Pausa',
    pauseHint: 'Toca para seguir\nMantén para terminar',
    rankAlert: 'Carrera',
    leading: 'Vas primero',
    done: 'Fin',
    nothingToUpload: 'Nada que subir',
  ),
  'pt': const WatchCopy(
    start: 'Começar',
    linked: 'Ligado',
    tapToStart: 'Toque para começar',
    pairingHint: '6 dígitos do telefone',
    checking: 'Verificando',
    later: 'Depois',
    running: 'Correndo',
    paused: 'Pausa',
    pauseHint: 'Toque para continuar\nSegure para terminar',
    rankAlert: 'Prova',
    leading: 'Na frente',
    done: 'Fim',
    nothingToUpload: 'Nada para enviar',
  ),
  'de': const WatchCopy(
    start: 'Start',
    linked: 'Verbunden',
    tapToStart: 'Tippen zum Start',
    pairingHint: '6 Ziffern vom Telefon',
    checking: 'Prüfen',
    later: 'Später',
    running: 'Läuft',
    paused: 'Pause',
    pauseHint: 'Tippen zum Weiter\nHalten zum Ende',
    rankAlert: 'Rennen',
    leading: 'In Führung',
    done: 'Fertig',
    nothingToUpload: 'Nichts zum Senden',
  ),
  'fr': const WatchCopy(
    start: 'Démarrer',
    linked: 'Lié',
    tapToStart: 'Touchez pour démarrer',
    pairingHint: '6 chiffres du téléphone',
    checking: 'Vérification',
    later: 'Plus tard',
    running: 'Course',
    paused: 'Pause',
    pauseHint: 'Touchez pour reprendre\nMaintenez pour finir',
    rankAlert: 'Course',
    leading: 'En tête',
    done: 'Fin',
    nothingToUpload: 'Rien à envoyer',
  ),
  'vi': const WatchCopy(
    start: 'Bắt đầu',
    linked: 'Đã nối',
    tapToStart: 'Chạm để bắt đầu',
    pairingHint: '6 số trên điện thoại',
    checking: 'Đang kiểm tra',
    later: 'Để sau',
    running: 'Đang chạy',
    paused: 'Tạm dừng',
    pauseHint: 'Chạm để chạy tiếp\nGiữ để kết thúc',
    rankAlert: 'Giải',
    leading: 'Đang dẫn đầu',
    done: 'Xong',
    nothingToUpload: 'Không có bản ghi để gửi',
  ),
  'th': const WatchCopy(
    start: 'เริ่ม',
    linked: 'เชื่อมแล้ว',
    tapToStart: 'แตะเพื่อเริ่ม',
    pairingHint: 'รหัส 6 หลักจากโทรศัพท์',
    checking: 'กำลังตรวจ',
    later: 'ภายหลัง',
    running: 'กำลังวิ่ง',
    paused: 'พัก',
    pauseHint: 'แตะเพื่อวิ่งต่อ\nกดค้างเพื่อจบ',
    rankAlert: 'รายการ',
    leading: 'นำอยู่',
    done: 'จบ',
    nothingToUpload: 'ไม่มีรายการจะส่ง',
  ),
  'id': const WatchCopy(
    start: 'Mulai',
    linked: 'Terhubung',
    tapToStart: 'Ketuk untuk mulai',
    pairingHint: '6 angka dari ponsel',
    checking: 'Memeriksa',
    later: 'Nanti',
    running: 'Berlari',
    paused: 'Jeda',
    pauseHint: 'Ketuk untuk lanjut\nTahan untuk selesai',
    rankAlert: 'Lomba',
    leading: 'Di depan',
    done: 'Selesai',
    nothingToUpload: 'Tidak ada yang diunggah',
  ),
};

/// ko, en, ja, zh, es, pt, de, fr, vi, th, id. 원어민 검수 전.
const watchLanguageOrder = <String>[
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

/// 2차 화면 개편(페어링·달리는 중·조작·결과)에 쓰는 문구. 줄 순서는 [watchLanguageOrder].
/// `{n}`은 숫자로 바뀐다. 원어민 검수 전.
const watchUiRows = <String, List<String>>{
  'pairTop': [
    '폰에서 코드 입력',
    'Enter code from phone',
    'スマホのコードを入力',
    '輸入手機上的代碼',
    'Código del móvil',
    'Código do celular',
    'Code vom Handy',
    'Code du téléphone',
    'Nhập mã từ điện thoại',
    'ใส่รหัสจากโทรศัพท์',
    'Masukkan kode dari ponsel',
  ],
  'pausedTitle': [
    '일시정지됨',
    'Paused',
    '一時停止中',
    '已暫停',
    'En pausa',
    'Pausado',
    'Pausiert',
    'En pause',
    'Đã tạm dừng',
    'หยุดชั่วคราว',
    'Dijeda',
  ],
  'resume': [
    '재개',
    'Resume',
    '再開',
    '繼續',
    'Reanudar',
    'Retomar',
    'Weiter',
    'Reprendre',
    'Tiếp tục',
    'ต่อ',
    'Lanjut',
  ],
  'stop': [
    '종료',
    'Stop',
    '終了',
    '結束',
    'Detener',
    'Parar',
    'Beenden',
    'Arrêter',
    'Dừng',
    'จบ',
    'Selesai',
  ],
  'runEnded': [
    '러닝 종료',
    'Run ended',
    'ランニング終了',
    '跑步結束',
    'Carrera terminada',
    'Corrida encerrada',
    'Lauf beendet',
    'Course terminée',
    'Kết thúc chạy',
    'จบการวิ่ง',
    'Lari selesai',
  ],
  'confirm': [
    '확인',
    'OK',
    'OK',
    '確認',
    'OK',
    'OK',
    'OK',
    'OK',
    'OK',
    'ตกลง',
    'OK',
  ],
  'kmPassed': [
    '{n}km 통과',
    '{n} km passed',
    '{n}km 通過',
    '通過 {n} 公里',
    '{n} km completados',
    '{n} km concluídos',
    '{n} km geschafft',
    '{n} km parcourus',
    'Qua {n} km',
    'ผ่าน {n} กม.',
    'Lewat {n} km',
  ],
  'donationPlanned': [
    '{n}원 기부 예정',
    '{n} KRW to be donated',
    '{n}ウォン寄付予定',
    '預計捐出 {n} 韓元',
    'Se donarán {n} KRW',
    'Serão doados {n} KRW',
    '{n} KRW Spende geplant',
    '{n} KRW de don prévu',
    'Dự kiến quyên góp {n} KRW',
    'จะบริจาค {n} KRW',
    'Rencana donasi {n} KRW',
  ],
  'afterVerify': [
    '인증 후',
    'after verification',
    '認証後',
    '驗證後',
    'tras verificación',
    'após verificação',
    'nach Prüfung',
    'après vérification',
    'sau khi xác minh',
    'หลังตรวจสอบ',
    'setelah verifikasi',
  ],
  'holdToStop': [
    '길게 눌러 종료',
    'Hold to stop',
    '長押しで終了',
    '長按結束',
    'Mantén para detener',
    'Segure para parar',
    'Halten zum Beenden',
    'Maintenir pour arrêter',
    'Giữ để dừng',
    'กดค้างเพื่อจบ',
    'Tahan untuk berhenti',
  ],
  'pendingUpload': [
    '올릴 기록 {n}',
    'To upload: {n}',
    'アップロード待ち {n}',
    '待上傳 {n}',
    'Por subir: {n}',
    'Para enviar: {n}',
    'Zu senden: {n}',
    'À envoyer : {n}',
    'Chờ tải lên: {n}',
    'รออัปโหลด {n}',
    'Menunggu unggah: {n}',
  ],
  'seeOnPhone': [
    '자세한 건 폰에서 보기',
    'See details on phone',
    '詳細はスマホで',
    '詳情請在手機查看',
    'Detalles en el móvil',
    'Detalhes no celular',
    'Details am Handy',
    'Détails sur le téléphone',
    'Xem chi tiết trên điện thoại',
    'ดูรายละเอียดในโทรศัพท์',
    'Lihat detail di ponsel',
  ],
  'openedOnPhone': [
    '폰에서 열었어요',
    'Opened on phone',
    'スマホで開きました',
    '已在手機開啟',
    'Abierto en el móvil',
    'Aberto no celular',
    'Auf dem Handy geöffnet',
    'Ouvert sur le téléphone',
    'Đã mở trên điện thoại',
    'เปิดบนโทรศัพท์แล้ว',
    'Terbuka di ponsel',
  ],
  'openOnPhoneFailed': [
    '폰을 열 수 없어요',
    "Couldn't open the phone",
    'スマホを開けません',
    '無法開啟手機',
    'No se pudo abrir el móvil',
    'Não foi possível abrir o celular',
    'Handy konnte nicht geöffnet werden',
    "Impossible d'ouvrir le téléphone",
    'Không mở được điện thoại',
    'เปิดโทรศัพท์ไม่ได้',
    'Tidak bisa membuka ponsel',
  ],
  'waitingGps': [
    'GPS 신호 기다리는 중',
    'Waiting for GPS',
    'GPS信号を待っています',
    '等待 GPS 訊號',
    'Esperando GPS',
    'Aguardando GPS',
    'Warte auf GPS',
    'En attente du GPS',
    'Đang chờ GPS',
    'รอสัญญาณ GPS',
    'Menunggu GPS',
  ],
  'reconnect': [
    '연결이 만료됐어요. 다시 연결해 주세요',
    'Connection expired. Pair again',
    '接続の期限が切れました。再接続してください',
    '連線已過期，請重新連線',
    'La conexión caducó. Vuelve a conectar',
    'A conexão expirou. Conecte de novo',
    'Verbindung abgelaufen. Neu verbinden',
    'Connexion expirée. Reconnectez',
    'Kết nối đã hết hạn. Hãy kết nối lại',
    'การเชื่อมต่อหมดอายุ โปรดเชื่อมต่อใหม่',
    'Koneksi kedaluwarsa. Hubungkan lagi',
  ],
  'unrated': [
    '평가 전',
    'Not rated yet',
    '評価前',
    '尚未評級',
    'Sin evaluar',
    'Sem avaliação',
    'Noch nicht bewertet',
    'Pas encore évalué',
    'Chưa xếp hạng',
    'ยังไม่ประเมิน',
    'Belum dinilai',
  ],
  'cancelHint': [
    '눌러서 취소',
    'Tap to cancel',
    'タップで取消',
    '點一下取消',
    'Toca para cancelar',
    'Toque para cancelar',
    'Tippen zum Abbrechen',
    'Touchez pour annuler',
    'Chạm để hủy',
    'แตะเพื่อยกเลิก',
    'Ketuk untuk batal',
  ],
  'glanceWorld': [
    '월드투어',
    'World Tour',
    'ワールドツアー',
    '世界巡迴',
    'Gira mundial',
    'Volta ao mundo',
    'Welttour',
    'Tour du monde',
    'Vòng quanh thế giới',
    'ทัวร์โลก',
    'Tur dunia',
  ],
  'glanceChallenge': [
    '챌린지',
    'Challenge',
    'チャレンジ',
    '挑戰',
    'Reto',
    'Desafio',
    'Herausforderung',
    'Défi',
    'Thử thách',
    'ชาเลนจ์',
    'Tantangan',
  ],
  'glanceCrew': [
    '크루',
    'Crew',
    'クルー',
    '隊伍',
    'Equipo',
    'Equipe',
    'Mannschaft',
    'Équipe',
    'Đội',
    'ทีม',
    'Kru',
  ],
  'glanceDia': [
    'DIA {n}개',
    'DIA {n}',
    'DIA {n}',
    'DIA {n}',
    'DIA {n}',
    'DIA {n}',
    'DIA {n}',
    'DIA {n}',
    'DIA {n}',
    'DIA {n}',
    'DIA {n}',
  ],
  'glanceShopHint': [
    '폰에서 상점을 열어 주세요',
    'Open the shop on your phone',
    'スマホでショップを開いてください',
    '請在手機打開商店',
    'Abre la tienda en el móvil',
    'Abra a loja no celular',
    'Öffne den Shop am Handy',
    'Ouvrez la boutique sur le téléphone',
    'Hãy mở cửa hàng trên điện thoại',
    'เปิดร้านบนโทรศัพท์',
    'Buka toko di ponsel',
  ],
  'glanceOpenShop': [
    '누르면 폰 상점을 열어요',
    'Tap to open the shop on your phone',
    'タップでスマホのショップを開きます',
    '點一下就在手機打開商店',
    'Toca para abrir la tienda en el móvil',
    'Toque para abrir a loja no celular',
    'Tippen öffnet den Shop am Handy',
    'Touchez pour ouvrir la boutique sur le téléphone',
    'Chạm để mở cửa hàng trên điện thoại',
    'แตะเพื่อเปิดร้านในโทรศัพท์',
    'Ketuk untuk membuka toko di ponsel',
  ],
  'glanceShopOpened': [
    '폰에서 상점을 열었어요',
    'Shop opened on your phone',
    'スマホでショップを開きました',
    '已在手機打開商店',
    'Tienda abierta en el móvil',
    'Loja aberta no celular',
    'Shop auf dem Handy geöffnet',
    'Boutique ouverte sur le téléphone',
    'Đã mở cửa hàng trên điện thoại',
    'เปิดร้านบนโทรศัพท์แล้ว',
    'Toko terbuka di ponsel',
  ],
  'glanceShopFailed': [
    '폰에서 상점을 열 수 없어요',
    "Couldn't open the shop on your phone",
    'スマホでショップを開けません',
    '無法在手機打開商店',
    'No se pudo abrir la tienda',
    'Não foi possível abrir a loja',
    'Shop am Handy ließ sich nicht öffnen',
    'Impossible d’ouvrir la boutique',
    'Không mở được cửa hàng trên điện thoại',
    'เปิดร้านบนโทรศัพท์ไม่ได้',
    'Tidak bisa membuka toko di ponsel',
  ],
  'glanceOffline': [
    '달팽이봇이 연결을 기다리는 중이에요',
    'Snail Bot is waiting to connect',
    'カタツムリボットが接続を待っています',
    '蝸牛機器人正在等連線',
    'Caracolbot espera conexión',
    'Caracolbot espera a ligação',
    'Schneckenbot wartet auf Verbindung',
    'Escargotbot attend la connexion',
    'Bot ốc sên đang chờ kết nối',
    'บอทหอยทากกำลังรอเชื่อมต่อ',
    'Bot siput sedang menunggu koneksi',
  ],
  'glanceUnpaired': [
    '폰 앱에서 워치를 연결해 주세요',
    'Pair this watch in the phone app',
    'スマホアプリでウォッチを接続してください',
    '請在手機 App 連接手錶',
    'Conecta el reloj en la app del móvil',
    'Conecte o relógio no app do celular',
    'Verbinde die Uhr in der Handy-App',
    'Reliez la montre dans l’app du téléphone',
    'Hãy nối đồng hồ trong app điện thoại',
    'เชื่อมนาฬิกาในแอปโทรศัพท์',
    'Hubungkan jam di aplikasi ponsel',
  ],
  'glanceNoCrew': [
    '참여 중인 크루가 없어요',
    'You are not in a crew',
    '参加中のクルーはありません',
    '沒有參加中的隊伍',
    'No estás en un equipo',
    'Você não está em uma equipe',
    'Du bist in keiner Mannschaft',
    'Tu n’es dans aucune équipe',
    'Bạn chưa ở trong đội nào',
    'คุณยังไม่ได้อยู่ในทีม',
    'Kamu belum punya kru',
  ],
  'glanceNoRace': [
    '참여 중인 대회가 없어요',
    'You are not in a race',
    '参加中の大会はありません',
    '沒有參加中的比賽',
    'No estás en una carrera',
    'Você não está em uma prova',
    'Du bist in keinem Rennen',
    'Tu n’es dans aucune course',
    'Bạn chưa tham gia giải nào',
    'คุณยังไม่ได้ลงแข่ง',
    'Kamu belum ikut lomba',
  ],
  'glanceInRace': [
    '대회 참여 중',
    'In a race',
    '大会に参加中',
    '比賽參加中',
    'En una carrera',
    'Em uma prova',
    'Im Rennen',
    'Dans une course',
    'Đang tham gia giải',
    'กำลังลงแข่ง',
    'Sedang ikut lomba',
  ],
  'glanceRemain': [
    '{n} km 남음',
    '{n} km left',
    'あと {n} km',
    '還剩 {n} 公里',
    'Faltan {n} km',
    'Faltam {n} km',
    'Noch {n} km',
    'Encore {n} km',
    'Còn {n} km',
    'อีก {n} กม.',
    'Sisa {n} km',
  ],
  'glanceOverall': [
    '전체 {n}',
    'Overall {n}',
    '全体 {n}',
    '全部 {n}',
    'Total {n}',
    'No total {n}',
    'Gesamt {n}',
    'Au total {n}',
    'Tổng {n}',
    'ทั้งหมด {n}',
    'Keseluruhan {n}',
  ],
  'glanceWeekLine': [
    '이번 주 {n}',
    'This week {n}',
    '今週 {n}',
    '本週 {n}',
    'Esta semana {n}',
    'Esta semana {n}',
    'Diese Woche {n}',
    'Cette semaine {n}',
    'Tuần này {n}',
    'สัปดาห์นี้ {n}',
    'Minggu ini {n}',
  ],
  'glanceMonthRank': [
    '이번 달 {n}위',
    'This month #{n}',
    '今月 {n}位',
    '本月第 {n} 名',
    'Este mes, {n}.º',
    'Este mês, {n}º',
    'Diesen Monat Platz {n}',
    'Ce mois-ci : {n}e',
    'Tháng này hạng {n}',
    'เดือนนี้ อันดับ {n}',
    'Bulan ini peringkat {n}',
  ],
  'glanceUnranked': [
    '이번 달은 순위 밖이에요',
    'No rank this month',
    '今月は順位外です',
    '本月未進排名',
    'Sin puesto este mes',
    'Sem lugar este mês',
    'Diesen Monat ohne Platz',
    'Pas de place ce mois-ci',
    'Tháng này chưa có hạng',
    'เดือนนี้ยังไม่มีอันดับ',
    'Bulan ini belum berperingkat',
  ],
  'glanceAllDone': [
    '월드투어를 다 달렸어요',
    'World tour complete',
    'ワールドツアー完走',
    '世界巡迴跑完了',
    'Gira mundial completa',
    'Volta ao mundo completa',
    'Welttour geschafft',
    'Tour du monde terminé',
    'Đã chạy hết vòng thế giới',
    'ทัวร์โลกครบแล้ว',
    'Tur dunia selesai',
  ],
};

/// Country then city for each world-tour landmark. Order is [watchLanguageOrder].
const watchPlaceRows = <String, List<List<String>>>{
  'eiffel_tower': [
    ['프랑스', 'France', 'フランス', '法國', 'Francia', 'França', 'Frankreich', 'France', 'Pháp', 'ฝรั่งเศส', 'Prancis'],
    ['파리', 'Paris', 'パリ', '巴黎', 'París', 'Paris', 'Paris', 'Paris', 'Paris', 'ปารีส', 'Paris'],
  ],
  'taj_mahal': [
    ['인도', 'India', 'インド', '印度', 'India', 'Índia', 'Indien', 'Inde', 'Ấn Độ', 'อินเดีย', 'India'],
    ['아그라', 'Agra', 'アグラ', '阿格拉', 'Agra', 'Agra', 'Agra', 'Agra', 'Agra', 'อักรา', 'Agra'],
  ],
  'mount_fuji': [
    ['일본', 'Japan', '日本', '日本', 'Japón', 'Japão', 'Japan', 'Japon', 'Nhật Bản', 'ญี่ปุ่น', 'Jepang'],
    ['후지', 'Fuji', '富士', '富士', 'Fuji', 'Fuji', 'Fuji', 'Fuji', 'Phú Sĩ', 'ฟูจิ', 'Fuji'],
  ],
  'big_ben': [
    ['영국', 'United Kingdom', 'イギリス', '英國', 'Reino Unido', 'Reino Unido', 'Vereinigtes Königreich', 'Royaume-Uni', 'Anh', 'สหราชอาณาจักร', 'Britania Raya'],
    ['런던', 'London', 'ロンドン', '倫敦', 'Londres', 'Londres', 'London', 'Londres', 'Luân Đôn', 'ลอนดอน', 'London'],
  ],
  'statue_of_liberty': [
    ['미국', 'United States', 'アメリカ', '美國', 'Estados Unidos', 'Estados Unidos', 'Vereinigte Staaten', 'États-Unis', 'Mỹ', 'สหรัฐ', 'Amerika Serikat'],
    ['뉴욕', 'New York', 'ニューヨーク', '紐約', 'Nueva York', 'Nova York', 'New York', 'New York', 'New York', 'นิวยอร์ก', 'New York'],
  ],
  'gwanghwamun': [
    ['한국', 'Korea', '韓国', '韓國', 'Corea', 'Coreia', 'Korea', 'Corée', 'Hàn Quốc', 'เกาหลี', 'Korea'],
    ['서울', 'Seoul', 'ソウル', '首爾', 'Seúl', 'Seul', 'Seoul', 'Séoul', 'Seoul', 'โซล', 'Seoul'],
  ],
  'taroko_gorge': [
    ['대만', 'Taiwan', '台湾', '台灣', 'Taiwán', 'Taiwan', 'Taiwan', 'Taïwan', 'Đài Loan', 'ไต้หวัน', 'Taiwan'],
    ['화롄', 'Hualien', '花蓮', '花蓮', 'Hualien', 'Hualien', 'Hualien', 'Hualien', 'Hoa Liên', 'ฮวาเหลียน', 'Hualien'],
  ],
  'alhambra': [
    ['스페인', 'Spain', 'スペイン', '西班牙', 'España', 'Espanha', 'Spanien', 'Espagne', 'Tây Ban Nha', 'สเปน', 'Spanyol'],
    ['그라나다', 'Granada', 'グラナダ', '格拉納達', 'Granada', 'Granada', 'Granada', 'Grenade', 'Granada', 'กรานาดา', 'Granada'],
  ],
  'iguazu_falls': [
    ['브라질', 'Brazil', 'ブラジル', '巴西', 'Brasil', 'Brasil', 'Brasilien', 'Brésil', 'Brazil', 'บราซิล', 'Brasil'],
    ['이구아수', 'Iguazu', 'イグアス', '伊瓜蘇', 'Iguazú', 'Iguaçu', 'Iguaçu', 'Iguaçu', 'Iguazu', 'อีกวาซู', 'Iguazu'],
  ],
  'neuschwanstein': [
    ['독일', 'Germany', 'ドイツ', '德國', 'Alemania', 'Alemanha', 'Deutschland', 'Allemagne', 'Đức', 'เยอรมนี', 'Jerman'],
    ['슈방가우', 'Schwangau', 'シュヴァンガウ', '施旺高', 'Schwangau', 'Schwangau', 'Schwangau', 'Schwangau', 'Schwangau', 'ชวานเกา', 'Schwangau'],
  ],
  'ha_long_bay': [
    ['베트남', 'Vietnam', 'ベトナム', '越南', 'Vietnam', 'Vietnã', 'Vietnam', 'Viêt Nam', 'Việt Nam', 'เวียดนาม', 'Vietnam'],
    ['하롱', 'Ha Long', 'ハロン', '下龍', 'Ha Long', 'Ha Long', 'Ha Long', 'Ha Long', 'Hạ Long', 'ฮาลอง', 'Ha Long'],
  ],
  'ayutthaya': [
    ['태국', 'Thailand', 'タイ', '泰國', 'Tailandia', 'Tailândia', 'Thailand', 'Thaïlande', 'Thái Lan', 'ไทย', 'Thailand'],
    ['아유타야', 'Ayutthaya', 'アユタヤ', '大城', 'Ayutthaya', 'Ayutthaya', 'Ayutthaya', 'Ayutthaya', 'Ayutthaya', 'อยุธยา', 'Ayutthaya'],
  ],
  'bali_rice_terraces': [
    ['인도네시아', 'Indonesia', 'インドネシア', '印尼', 'Indonesia', 'Indonésia', 'Indonesien', 'Indonésie', 'Indonesia', 'อินโดนีเซีย', 'Indonesia'],
    ['발리', 'Bali', 'バリ', '峇里', 'Bali', 'Bali', 'Bali', 'Bali', 'Bali', 'บาหลี', 'Bali'],
  ],
};

/// Localized country or city. Null when this watch build does not know the landmark.
String? watchPlaceName(Locale locale, String? landmarkId, {required bool city}) {
  final rows = watchPlaceRows[landmarkId];
  if (rows == null || rows.length < 2) return null;
  return _watchRow(rows[city ? 1 : 0], locale.languageCode);
}

/// [watchUiRows]의 한 문구. `{n}` 자리에 [n]을 넣는다.
String watchUi(Locale locale, String key, {Object? n}) {
  final row = watchUiRows[key]!;
  final index = watchLanguageOrder.indexOf(locale.languageCode);
  final text = row[index < 0 ? 1 : index];
  return n == null ? text : text.replaceAll('{n}', '$n');
}

const minutePatterns = <String>[
  '{n}분',
  '{n} min',
  '{n}分',
  '{n} 分',
  '{n} min',
  '{n} min',
  '{n} Min.',
  '{n} min',
  '{n} phút',
  '{n} นาที',
  '{n} mnt',
];

const rankPatterns = <String>[
  '{n}위',
  '#{n}',
  '{n}位',
  '第{n}名',
  '{n}.º',
  '{n}º',
  'Platz {n}',
  '{n}e',
  'Hạng {n}',
  'อันดับ {n}',
  'Peringkat {n}',
];

const pairingErrorRows = <String, List<String>>{
  'no_server': [
    '서버 설정이 없는 빌드예요.',
    'This build has no server settings.',
    'このビルドにはサーバー設定がありません。',
    '這個版本沒有伺服器設定。',
    'Esta compilación no tiene servidor.',
    'Esta versão não tem servidor.',
    'Dieser Build hat keine Serveradresse.',
    'Cette version n’a pas de serveur.',
    'Bản dựng này chưa có máy chủ.',
    'รุ่นนี้ยังไม่มีการตั้งค่าเซิร์ฟเวอร์',
    'Build ini belum punya server.',
  ],
  'need_six_digits': [
    '숫자 6자리를 입력해 주세요.',
    'Enter 6 digits.',
    '6桁の数字を入力してください。',
    '請輸入 6 位數字。',
    'Escribe 6 dígitos.',
    'Digite 6 números.',
    'Bitte 6 Ziffern eingeben.',
    'Saisissez 6 chiffres.',
    'Nhập 6 chữ số.',
    'กรอกตัวเลข 6 หลัก',
    'Masukkan 6 angka.',
  ],
  'bad_url': [
    '잘못된 서버 주소예요.',
    'The server address is invalid.',
    'サーバーアドレスが正しくありません。',
    '伺服器網址不正確。',
    'La dirección del servidor no es válida.',
    'O endereço do servidor é inválido.',
    'Die Serveradresse ist ungültig.',
    'L’adresse du serveur est invalide.',
    'Địa chỉ máy chủ không đúng.',
    'ที่อยู่เซิร์ฟเวอร์ไม่ถูกต้อง',
    'Alamat server tidak valid.',
  ],
  'rate_limited': [
    '잠시 뒤에 다시 해 주세요.',
    'Try again in a moment.',
    '少し待ってからもう一度試してください。',
    '請稍後再試。',
    'Inténtalo de nuevo en un momento.',
    'Tente de novo daqui a pouco.',
    'Bitte kurz warten und erneut versuchen.',
    'Réessayez dans un instant.',
    'Hãy thử lại sau giây lát.',
    'ลองอีกครั้งในอีกสักครู่',
    'Coba lagi sebentar lagi.',
  ],
  'watch_limit': [
    '연결된 워치가 이미 3개예요. 휴대폰에서 하나를 해제해 주세요.',
    'Three watches are already linked. Remove one on the phone.',
    '接続済みのウォッチがすでに3台です。スマホで1台解除してください。',
    '已連結 3 支手錶。請在手機上解除一支。',
    'Ya hay 3 relojes vinculados. Quita uno en el teléfono.',
    'Já há 3 relógios ligados. Remova um no telefone.',
    'Es sind schon 3 Uhren verbunden. Entferne eine am Telefon.',
    '3 montres sont déjà liées. Retirez-en une sur le téléphone.',
    'Đã nối 3 đồng hồ. Hãy gỡ một chiếc trên điện thoại.',
    'เชื่อมนาฬิกาครบ 3 เรือนแล้ว โปรดยกเลิกหนึ่งเรือนบนโทรศัพท์',
    'Sudah ada 3 jam terhubung. Lepas satu di ponsel.',
  ],
  'bad_code': [
    '코드가 맞지 않거나 만료됐어요.',
    'The code is wrong or expired.',
    'コードが違うか、期限が切れています。',
    '代碼不對或已過期。',
    'El código no es válido o caducó.',
    'O código está errado ou expirou.',
    'Der Code stimmt nicht oder ist abgelaufen.',
    'Le code est faux ou expiré.',
    'Mã không đúng hoặc đã hết hạn.',
    'รหัสไม่ถูกต้องหรือหมดอายุ',
    'Kode salah atau kedaluwarsa.',
  ],
  'auth_url': [
    'Firebase 인증 주소 오류',
    'Firebase sign-in address is invalid.',
    'Firebaseの認証アドレスが不正です。',
    'Firebase 驗證網址錯誤。',
    'La dirección de acceso de Firebase no es válida.',
    'O endereço de login do Firebase é inválido.',
    'Die Firebase-Anmeldeadresse ist ungültig.',
    'L’adresse de connexion Firebase est invalide.',
    'Địa chỉ đăng nhập Firebase không đúng.',
    'ที่อยู่เข้าสู่ระบบ Firebase ไม่ถูกต้อง',
    'Alamat masuk Firebase tidak valid.',
  ],
  'sign_in_failed': [
    '로그인을 마치지 못했어요. 다시 시도해 주세요.',
    'Sign-in did not finish. Try again.',
    'ログインを完了できませんでした。もう一度試してください。',
    '登入沒有完成。請再試一次。',
    'El acceso no terminó. Inténtalo otra vez.',
    'O login não terminou. Tente de novo.',
    'Die Anmeldung wurde nicht fertig. Bitte erneut versuchen.',
    'La connexion ne s’est pas terminée. Réessayez.',
    'Đăng nhập chưa xong. Hãy thử lại.',
    'การลงชื่อเข้าใช้ไม่สำเร็จ โปรดลองอีกครั้ง',
    'Masuk belum selesai. Coba lagi.',
  ],
  'offline': [
    '연결할 수 없어요. 인터넷을 확인해 주세요.',
    'Can’t connect. Check the internet.',
    '接続できません。インターネットを確認してください。',
    '連不上。請確認網路。',
    'No hay conexión. Revisa internet.',
    'Não foi possível conectar. Verifique a internet.',
    'Keine Verbindung. Bitte das Internet prüfen.',
    'Connexion impossible. Vérifiez internet.',
    'Không kết nối được. Hãy kiểm tra mạng.',
    'เชื่อมต่อไม่ได้ โปรดตรวจอินเทอร์เน็ต',
    'Tidak bisa terhubung. Periksa internet.',
  ],
};

/// Phone app animal names (`animalRows`), same language order as [watchLanguageOrder].
const watchAnimalRows = <String, List<String>>{
  'snail': [
    '달팽이',
    'Snail',
    'カタツムリ',
    '蝸牛',
    'Caracol',
    'Caracol',
    'Schnecke',
    'Escargot',
    'Ốc sên',
    'หอยทาก',
    'Siput',
  ],
  'turtle': [
    '거북이',
    'Turtle',
    'カメ',
    '烏龜',
    'Tortuga',
    'Tartaruga',
    'Schildkröte',
    'Tortue',
    'Rùa',
    'เต่า',
    'Kura-kura',
  ],
  'beagle': [
    '비글',
    'Beagle',
    'ビーグル',
    '米格魯',
    'Beagle',
    'Beagle',
    'Beagle',
    'Beagle',
    'Beagle',
    'บีเกิล',
    'Beagle',
  ],
  'wolf': [
    '늑대',
    'Wolf',
    'オオカミ',
    '狼',
    'Lobo',
    'Lobo',
    'Wolf',
    'Loup',
    'Sói',
    'หมาป่า',
    'Serigala',
  ],
  'zebra': [
    '얼룩말',
    'Zebra',
    'シマウマ',
    '斑馬',
    'Cebra',
    'Zebra',
    'Zebra',
    'Zèbre',
    'Ngựa vằn',
    'ม้าลาย',
    'Zebra',
  ],
  'cheetah': [
    '치타',
    'Cheetah',
    'チーター',
    '獵豹',
    'Guepardo',
    'Guepardo',
    'Gepard',
    'Guépard',
    'Báo săn',
    'ชีตาห์',
    'Cheetah',
  ],
};

/// Phone app medal names (`medalRows`). Same order as [watchLanguageOrder].
const watchMedalRows = <String, List<String>>{
  'bronze': [
    '브론즈',
    'Bronze',
    'ブロンズ',
    '銅牌',
    'Bronce',
    'Bronze',
    'Bronze',
    'Bronze',
    'Đồng',
    'บรอนซ์',
    'Perunggu',
  ],
  'silver': [
    '실버',
    'Silver',
    'シルバー',
    '銀牌',
    'Plata',
    'Prata',
    'Silber',
    'Argent',
    'Bạc',
    'ซิลเวอร์',
    'Perak',
  ],
  'gold': [
    '골드',
    'Gold',
    'ゴールド',
    '金牌',
    'Oro',
    'Ouro',
    'Gold',
    'Or',
    'Vàng',
    'โกลด์',
    'Emas',
  ],
  'diamond': [
    '다이아',
    'Diamond',
    'ダイヤ',
    '鑽石',
    'Diamante',
    'Diamante',
    'Diamant',
    'Diamant',
    'Kim cương',
    'ไดมอนด์',
    'Berlian',
  ],
  'master': [
    '마스터',
    'Master',
    'マスター',
    '大師',
    'Maestro',
    'Mestre',
    'Meister',
    'Maître',
    'Bậc thầy',
    'มาสเตอร์',
    'Master',
  ],
};

/// Localized grade title for a server tier code.
///
/// `cheetah` is the animal only. `cheetah_gold` is animal then medal, the same
/// order as the phone's grade title. `snail` has no medal line here; the start
/// screen uses the unrated sentence instead. Unknown codes return null.
String? watchTierLabel(Locale locale, String? code) {
  final raw = code?.trim().toLowerCase();
  if (raw == null || raw.isEmpty) return null;
  final parts = raw.split('_');
  final animal = watchAnimalRows[parts.first];
  if (animal == null || parts.first == 'snail') return null;
  final animalName = _watchRow(animal, locale.languageCode);
  if (parts.length < 2) return animalName;
  final medal = watchMedalRows[parts[1]];
  if (medal == null) return animalName;
  return '$animalName ${_watchRow(medal, locale.languageCode)}';
}

String _watchRow(List<String> row, String languageCode) {
  final index = watchLanguageOrder.indexOf(languageCode);
  if (index < 0 || index >= row.length || row[index].trim().isEmpty) {
    return row[watchLanguageOrder.indexOf('en')];
  }
  return row[index];
}

/// Empty when every face, minute, rank, and pairing row exists in 11 locales.
List<String> missingWatchCopyKeys() {
  final missing = <String>[];
  for (final code in watchLanguageOrder) {
    final copy = _all[code];
    if (copy == null) {
      missing.add('watch.$code');
      continue;
    }
    final fields = <String, String>{
      'start': copy.start,
      'linked': copy.linked,
      'tapToStart': copy.tapToStart,
      'pairingHint': copy.pairingHint,
      'checking': copy.checking,
      'later': copy.later,
      'running': copy.running,
      'paused': copy.paused,
      'pauseHint': copy.pauseHint,
      'rankAlert': copy.rankAlert,
      'leading': copy.leading,
      'done': copy.done,
      'nothingToUpload': copy.nothingToUpload,
    };
    for (final entry in fields.entries) {
      if (entry.value.trim().isEmpty) missing.add('watch.$code.${entry.key}');
    }
    if (code != 'ko' && copy.start == _all['ko']!.start) {
      missing.add('watch.$code.start=ko');
    }
  }
  for (final table in <String, List<String>>{
    'minutes': minutePatterns,
    'rank': rankPatterns,
  }.entries) {
    if (table.value.length != watchLanguageOrder.length) {
      missing.add('watch.${table.key}.length');
      continue;
    }
    for (var i = 0; i < table.value.length; i++) {
      if (table.value[i].trim().isEmpty) {
        missing.add('watch.${table.key}.${watchLanguageOrder[i]}');
      } else if (i != 0 && table.value[i] == table.value.first) {
        missing.add('watch.${table.key}.${watchLanguageOrder[i]}=ko');
      }
    }
  }
  for (final entry in watchUiRows.entries) {
    if (entry.value.length != watchLanguageOrder.length) {
      missing.add('watch.ui.${entry.key}.length');
      continue;
    }
    for (var i = 0; i < entry.value.length; i++) {
      if (entry.value[i].trim().isEmpty) {
        missing.add('watch.ui.${entry.key}.${watchLanguageOrder[i]}');
      } else if (i != 0 &&
          entry.value[i] == entry.value.first &&
          entry.key != 'confirm') {
        missing.add('watch.ui.${entry.key}.${watchLanguageOrder[i]}=ko');
      }
    }
  }
  for (final table in <String, Map<String, List<String>>>{
    'animal': watchAnimalRows,
    'medal': watchMedalRows,
  }.entries) {
    for (final entry in table.value.entries) {
      if (entry.value.length != watchLanguageOrder.length) {
        missing.add('watch.${table.key}.${entry.key}.length');
        continue;
      }
      for (var i = 0; i < entry.value.length; i++) {
        if (entry.value[i].trim().isEmpty) {
          missing.add('watch.${table.key}.${entry.key}.${watchLanguageOrder[i]}');
        } else if (i != 0 && entry.value[i] == entry.value.first) {
          missing.add('watch.${table.key}.${entry.key}.${watchLanguageOrder[i]}=ko');
        }
      }
    }
  }
  for (final entry in watchPlaceRows.entries) {
    if (entry.value.length != 2) {
      missing.add('watch.place.${entry.key}.parts');
      continue;
    }
    for (var part = 0; part < entry.value.length; part++) {
      final row = entry.value[part];
      final which = part == 0 ? 'country' : 'city';
      if (row.length != watchLanguageOrder.length) {
        missing.add('watch.place.${entry.key}.$which.length');
        continue;
      }
      for (var i = 0; i < row.length; i++) {
        if (row[i].trim().isEmpty) {
          missing.add('watch.place.${entry.key}.$which.${watchLanguageOrder[i]}');
        } else if (i != 0 && row[i] == row.first) {
          missing.add('watch.place.${entry.key}.$which.${watchLanguageOrder[i]}=ko');
        }
      }
    }
  }
  for (final entry in pairingErrorRows.entries) {
    if (entry.value.length != watchLanguageOrder.length) {
      missing.add('watch.pairing.${entry.key}.length');
      continue;
    }
    for (var i = 0; i < entry.value.length; i++) {
      if (entry.value[i].trim().isEmpty) {
        missing.add('watch.pairing.${entry.key}.${watchLanguageOrder[i]}');
      } else if (i != 0 && entry.value[i] == entry.value.first) {
        missing.add('watch.pairing.${entry.key}.${watchLanguageOrder[i]}=ko');
      }
    }
  }
  return missing;
}
