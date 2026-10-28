import 'package:flutter/widgets.dart';

/// Face copy for the standalone watch. Same 11 language codes as the phone app.
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
