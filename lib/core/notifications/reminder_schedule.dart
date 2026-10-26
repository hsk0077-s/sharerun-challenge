import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 아침·점심·저녁 리마인더는 몇 분 늦어도 괜찮으므로 "정확한 시각 알람"을 쓰지 않는다.
/// 정확한 알람은 안드로이드 14 이상에서 사용자가 "알람 및 리마인더" 권한을 직접 허용해야
/// 하고, 허용하지 않으면 예약이 조용히 실패해 알림이 오지 않는다. 이 방식은 권한이 필요 없다.
const reminderScheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;

/// 기기에서 시간대를 알아내지 못하거나 시간대 목록에 없는 이름이면 이 값으로 되돌아간다.
/// 예전 앱은 모두 한국 시간으로 예약했으므로 같은 동작을 유지한다.
const reminderFallbackZone = 'Asia/Seoul';

/// [lookup]이 돌려준 시간대 이름이 [isKnown]에서 쓸 수 있으면 그것을, 아니면 [reminderFallbackZone].
Future<String> resolveReminderZone(
  Future<String> Function() lookup, {
  required bool Function(String name) isKnown,
}) async {
  try {
    final name = (await lookup()).trim();
    if (name.isNotEmpty && isKnown(name)) return name;
  } catch (_) {
    // 아래의 기본값을 쓴다.
  }
  return reminderFallbackZone;
}

/// 하루 세 번(아침·점심·저녁) 걷기 리마인더 문구.
class ReminderCopy {
  const ReminderCopy({
    required this.channelName,
    required this.channelDescription,
    required this.morningTitle,
    required this.morningBody,
    required this.lunchTitle,
    required this.lunchBody,
    required this.eveningTitle,
    required this.eveningBody,
  });

  final String channelName;
  final String channelDescription;
  final String morningTitle;
  final String morningBody;
  final String lunchTitle;
  final String lunchBody;
  final String eveningTitle;
  final String eveningBody;
}

const _englishCopy = ReminderCopy(
  channelName: 'Walking challenge reminders',
  channelDescription: 'Morning, noon and evening walking reminders',
  morningTitle: '🏃 Good morning! Take your first steps of the day',
  morningBody: 'Every step you take today turns into SHARE.',
  lunchTitle: '☕ How about a short walk to recharge?',
  lunchBody: 'A few steps now can complete today\'s challenge.',
  eveningTitle: '🎁 You still have SHARE to earn today!',
  eveningBody: 'Verify today\'s steps and don\'t miss your reward.',
);

const reminderCopyByLanguage = <String, ReminderCopy>{
  'ko': ReminderCopy(
    channelName: '워킹챌린지 참여 독려',
    channelDescription: '워킹챌린지 아침·점심·저녁 참여 독려',
    morningTitle: '🏃 활기찬 아침, 오늘의 첫걸음을 시작해 보세요!',
    morningBody: '오늘 하루 걷는 모든 발걸음이 소중한 SHARE가 됩니다.',
    lunchTitle: '☕ 가벼운 산책으로 활력을 충전해 볼까요?',
    lunchBody: '잠깐의 가벼운 걸음이 오늘의 챌린지 목표를 완성합니다.',
    eveningTitle: '🎁 오늘 획득할 수 있는 SHARE가 남아있어요!',
    eveningBody: '오늘의 걸음을 인증하고 준비된 보상을 놓치지 마세요.',
  ),
  'en': _englishCopy,
  'ja': ReminderCopy(
    channelName: 'ウォーキングチャレンジのお知らせ',
    channelDescription: '朝・昼・夜のウォーキングのお知らせ',
    morningTitle: '🏃 おはようございます！今日の一歩を始めましょう',
    morningBody: '今日歩く一歩一歩が大切なSHAREになります。',
    lunchTitle: '☕ 軽い散歩でリフレッシュしませんか？',
    lunchBody: '少し歩くだけで今日のチャレンジが達成できます。',
    eveningTitle: '🎁 今日もらえるSHAREが残っています！',
    eveningBody: '今日の歩数を認証して、報酬を受け取りましょう。',
  ),
  'zh': ReminderCopy(
    channelName: '健走挑戰提醒',
    channelDescription: '早上、中午、晚上的健走提醒',
    morningTitle: '🏃 早安！開始今天的第一步吧',
    morningBody: '今天走的每一步都會變成珍貴的 SHARE。',
    lunchTitle: '☕ 來一段輕鬆的散步，補充活力吧？',
    lunchBody: '稍微走一走，就能完成今天的挑戰目標。',
    eveningTitle: '🎁 今天還有可以獲得的 SHARE！',
    eveningBody: '驗證今天的步數，別錯過獎勵。',
  ),
  'es': ReminderCopy(
    channelName: 'Recordatorios del reto de caminar',
    channelDescription:
        'Recordatorios para caminar por la mañana, al mediodía y por la noche',
    morningTitle: '🏃 ¡Buenos días! Da tus primeros pasos del día',
    morningBody: 'Cada paso que des hoy se convierte en SHARE.',
    lunchTitle: '☕ ¿Un paseo corto para recargar energías?',
    lunchBody: 'Unos pasos ahora pueden completar el reto de hoy.',
    eveningTitle: '🎁 ¡Aún puedes ganar SHARE hoy!',
    eveningBody: 'Verifica tus pasos de hoy y no pierdas tu recompensa.',
  ),
  'pt': ReminderCopy(
    channelName: 'Lembretes do desafio de caminhada',
    channelDescription:
        'Lembretes de caminhada de manhã, ao meio-dia e à noite',
    morningTitle: '🏃 Bom dia! Comece com os primeiros passos de hoje',
    morningBody: 'Cada passo que você der hoje vira SHARE.',
    lunchTitle: '☕ Que tal uma caminhada curta para recarregar?',
    lunchBody: 'Alguns passos agora podem completar o desafio de hoje.',
    eveningTitle: '🎁 Ainda há SHARE para ganhar hoje!',
    eveningBody: 'Valide seus passos de hoje e não perca sua recompensa.',
  ),
  'de': ReminderCopy(
    channelName: 'Erinnerungen zur Walking-Challenge',
    channelDescription: 'Spaziergang-Erinnerungen morgens, mittags und abends',
    morningTitle: '🏃 Guten Morgen! Starte mit den ersten Schritten des Tages',
    morningBody: 'Jeder Schritt heute wird zu SHARE.',
    lunchTitle: '☕ Wie wäre es mit einem kurzen Spaziergang?',
    lunchBody:
        'Ein paar Schritte jetzt können die heutige Challenge abschließen.',
    eveningTitle: '🎁 Heute kannst du noch SHARE verdienen!',
    eveningBody: 'Bestätige deine Schritte und verpasse deine Belohnung nicht.',
  ),
  'fr': ReminderCopy(
    channelName: 'Rappels du défi de marche',
    channelDescription: 'Rappels de marche le matin, à midi et le soir',
    morningTitle: '🏃 Bonjour ! Faites vos premiers pas de la journée',
    morningBody: 'Chaque pas aujourd\'hui devient du SHARE.',
    lunchTitle: '☕ Une petite promenade pour recharger les batteries ?',
    lunchBody: 'Quelques pas maintenant peuvent valider le défi du jour.',
    eveningTitle: '🎁 Il reste du SHARE à gagner aujourd\'hui !',
    eveningBody: 'Validez vos pas du jour et ne manquez pas votre récompense.',
  ),
  'vi': ReminderCopy(
    channelName: 'Nhắc nhở thử thách đi bộ',
    channelDescription: 'Nhắc đi bộ buổi sáng, trưa và tối',
    morningTitle: '🏃 Chào buổi sáng! Hãy bắt đầu những bước chân đầu tiên',
    morningBody: 'Mỗi bước chân hôm nay đều trở thành SHARE.',
    lunchTitle: '☕ Đi dạo một chút để nạp lại năng lượng nhé?',
    lunchBody: 'Vài bước chân nhẹ nhàng giúp hoàn thành thử thách hôm nay.',
    eveningTitle: '🎁 Hôm nay bạn vẫn còn SHARE để nhận!',
    eveningBody: 'Xác nhận số bước hôm nay và đừng bỏ lỡ phần thưởng.',
  ),
  'th': ReminderCopy(
    channelName: 'การแจ้งเตือนชาเลนจ์เดิน',
    channelDescription: 'แจ้งเตือนการเดินช่วงเช้า กลางวัน และเย็น',
    morningTitle: '🏃 อรุณสวัสดิ์! เริ่มก้าวแรกของวันนี้กัน',
    morningBody: 'ทุกก้าวที่เดินวันนี้จะกลายเป็น SHARE',
    lunchTitle: '☕ เดินเล่นเบาๆ เพื่อเติมพลังกันไหม',
    lunchBody: 'เดินอีกนิดเดียวก็ทำชาเลนจ์ของวันนี้สำเร็จได้',
    eveningTitle: '🎁 วันนี้ยังมี SHARE ให้รับอยู่!',
    eveningBody: 'ยืนยันก้าวเดินของวันนี้ แล้วอย่าพลาดรางวัล',
  ),
  'id': ReminderCopy(
    channelName: 'Pengingat tantangan berjalan',
    channelDescription: 'Pengingat berjalan pagi, siang, dan malam',
    morningTitle: '🏃 Selamat pagi! Mulai langkah pertama hari ini',
    morningBody: 'Setiap langkah hari ini menjadi SHARE.',
    lunchTitle: '☕ Jalan santai sebentar untuk mengisi energi?',
    lunchBody:
        'Beberapa langkah sekarang bisa menyelesaikan tantangan hari ini.',
    eveningTitle: '🎁 Hari ini kamu masih bisa mendapat SHARE!',
    eveningBody: 'Verifikasi langkah hari ini dan jangan lewatkan hadiahmu.',
  ),
};

/// 앱 언어 코드(예: `ko`, `en`)에 맞는 리마인더 문구. 모르는 언어는 영어.
ReminderCopy reminderCopyFor(String languageCode) =>
    reminderCopyByLanguage[languageCode.toLowerCase()] ?? _englishCopy;
