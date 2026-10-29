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
