import 'package:flutter/widgets.dart';

/// 워치에서 연 달리기 기록 화면 문구. 줄 순서는 ko, en, ja, zh, es, pt, de, fr, vi, th, id.
/// 원어민 검수 전.
const watchRunLinkLanguageOrder = <String>[
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

const watchRunLinkCopyRows = <String, List<String>>{
  'title': [
    '러닝 기록',
    'Run record',
    'ランニング記録',
    '跑步紀錄',
    'Registro de carrera',
    'Registro da corrida',
    'Laufprotokoll',
    'Relevé de course',
    'Nhật ký chạy',
    'บันทึกการวิ่ง',
    'Catatan lari',
  ],
  'syncing': [
    '기록을 불러오는 중',
    'Getting your run ready',
    '記録を読み込んでいます',
    '正在載入紀錄',
    'Cargando tu carrera',
    'Carregando sua corrida',
    'Lauf wird geladen',
    'Chargement de la course',
    'Đang tải bản chạy',
    'กำลังโหลดการวิ่ง',
    'Memuat lari Anda',
  ],
  'notReady': [
    '아직 폰에 올라오지 않았어요. 잠시 후 기록 목록에서 확인할 수 있어요.',
    "This run isn't on the phone yet. You can find it in your history in a moment.",
    'まだスマホに届いていません。しばらくして記録一覧で確認できます。',
    '尚未同步到手機。稍後可在紀錄列表中查看。',
    'Esta carrera aún no está en el móvil. En un momento la verás en el historial.',
    'Esta corrida ainda não está no celular. Em instantes você a verá no histórico.',
    'Dieser Lauf ist noch nicht auf dem Handy. Gleich findest du ihn in der Übersicht.',
    "Cette course n'est pas encore sur le téléphone. Vous la verrez bientôt dans l'historique.",
    'Bản chạy này chưa có trên điện thoại. Bạn sẽ thấy nó trong lịch sử sau một lúc.',
    'การวิ่งนี้ยังไม่มาที่โทรศัพท์ คุณจะเห็นในประวัติในอีกสักครู่',
    'Lari ini belum ada di ponsel. Sebentar lagi ada di riwayat.',
  ],
  'seeList': [
    '기록 목록 보기',
    'See run history',
    '記録一覧を見る',
    '查看紀錄列表',
    'Ver el historial',
    'Ver o histórico',
    'Verlauf ansehen',
    "Voir l'historique",
    'Xem lịch sử chạy',
    'ดูประวัติการวิ่ง',
    'Lihat riwayat lari',
  ],
  'verified': [
    '인증됨',
    'Verified',
    '認証済み',
    '已驗證',
    'Verificada',
    'Verificada',
    'Bestätigt',
    'Vérifiée',
    'Đã xác minh',
    'ยืนยันแล้ว',
    'Terverifikasi',
  ],
  'pending': [
    '확인 중',
    'Checking',
    '確認中',
    '確認中',
    'En revisión',
    'Em análise',
    'In Prüfung',
    'Vérification',
    'Đang kiểm tra',
    'กำลังตรวจสอบ',
    'Sedang dicek',
  ],
  'rejected': [
    '미인증',
    'Not verified',
    '未認証',
    '未驗證',
    'No verificada',
    'Não verificada',
    'Nicht bestätigt',
    'Non vérifiée',
    'Chưa xác minh',
    'ยังไม่ยืนยัน',
    'Belum terverifikasi',
  ],
  'underReview': [
    '심사 중',
    'Under review',
    '審査中',
    '審核中',
    'En revisión',
    'Em análise',
    'In Prüfung',
    'En examen',
    'Đang xem xét',
    'กำลังพิจารณา',
    'Sedang ditinjau',
  ],
};

String watchRunLinkCopy(Locale locale, String key) {
  final row = watchRunLinkCopyRows[key];
  if (row == null || row.isEmpty) return key;
  final index = watchRunLinkLanguageOrder.indexOf(locale.languageCode);
  if (index < 0 || index >= row.length || row[index].trim().isEmpty) {
    return row[watchRunLinkLanguageOrder.indexOf('en')];
  }
  return row[index];
}
