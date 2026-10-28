import 'package:flutter/widgets.dart';

/// Copy for the DIA refund sheet. Korean matches the sheet that already shipped.
class DiaRefundCopy {
  const DiaRefundCopy._(this.code);

  final String code;

  static DiaRefundCopy of(Locale locale) {
    final code = _pack.containsKey(locale.languageCode) ? locale.languageCode : 'en';
    return DiaRefundCopy._(code);
  }

  String _t(String key) => _pack[code]![key]!;

  String get openButton => _t('open');
  String get sheetTitle => _t('title');
  String get loading => _t('loading');
  String get offline => _t('offline');
  String get dialogTitle => _t('dialog');
  String get cancel => _t('cancel');
  String get confirm => _t('confirm');
  String get pending => _t('pending');
  String get already => _t('already');
  String get failed => _t('failed');

  String window(int days) => _t('window').replaceAll('{days}', '$days');
  String empty(int days) => _t('empty').replaceAll('{days}', '$days');

  String pack(int packDia, String price) =>
      _t('pack').replaceAll('{dia}', '$packDia').replaceAll('{price}', price);

  String boughtOn(int month, int day) =>
      _t('bought').replaceAll('{month}', '$month').replaceAll('{day}', '$day');

  String eligible({
    required String refund,
    required int paidDia,
    required int bonusRevoked,
  }) {
    final base = _t('eligible')
        .replaceAll('{refund}', refund)
        .replaceAll('{paid}', '$paidDia');
    if (bonusRevoked <= 0) return base;
    return '$base${_t('bonus').replaceAll('{bonus}', '$bonusRevoked')}';
  }

  String apply(String refund) => _t('apply').replaceAll('{refund}', refund);

  String done(String refund) => _t('done').replaceAll('{refund}', refund);

  String why(String reason, String status) {
    if (reason == 'already_refunded') {
      return status == 'refunded' ? _t('whyDone') : _t('whyPending');
    }
    if (reason == 'nothing_left') return _t('whyEmpty');
    if (reason == 'period_over') return _t('whyLate');
    return _t('whyNo');
  }

  String confirmBody({
    required int paidDia,
    required int bonusRevoked,
    required String refund,
    required int bonusSpent,
    required String spent,
  }) {
    final bonus = bonusRevoked > 0
        ? _t('dropBonus').replaceAll('{bonus}', '$bonusRevoked')
        : '';
    final spentLine = bonusSpent > 0
        ? _t('spent')
            .replaceAll('{spent}', '$bonusSpent')
            .replaceAll('{won}', spent)
        : '';
    return _t('body')
        .replaceAll('{paid}', '$paidDia')
        .replaceAll('{bonus}', bonus)
        .replaceAll('{refund}', refund)
        .replaceAll('{spent}', spentLine);
  }
}

const _pack = <String, Map<String, String>>{
  'ko': {
    'open': '환불 신청하기',
    'title': 'DIA 환불',
    'window': '산 날부터 {days}일 안, 쓰지 않은 유료 DIA만 환불돼요.',
    'loading': '불러오는 중이에요…',
    'offline': '서버에 연결되면 환불할 수 있어요.',
    'empty': '{days}일 안에 산 DIA 팩이 없어요.',
    'pack': 'DIA {dia}개 팩 · {price}원',
    'bought': '{month}월 {day}일에 샀어요',
    'eligible': '환불 {refund}원 · 유료 DIA {paid}개',
    'bonus': ' + 덤 {bonus}개 회수',
    'apply': '{refund}원 환불 신청',
    'whyDone': '환불이 끝났어요.',
    'whyPending': '환불을 신청했어요. 확인 중이에요.',
    'whyEmpty': '쓰지 않은 유료 DIA가 없어서 환불할 금액이 없어요.',
    'whyLate': '환불 기간이 지났어요.',
    'whyNo': '환불할 수 없어요.',
    'dialog': '환불 신청',
    'cancel': '취소',
    'confirm': '환불 신청',
    'body': '쓰지 않은 유료 DIA {paid}개{bonus}가 빠지고 {refund}원이 환불돼요.{spent}\n신청하면 되돌릴 수 없어요.',
    'dropBonus': '와 덤 {bonus}개',
    'spent': '\n이미 쓴 덤 {spent}개는 {won}원을 뺐어요.',
    'done': '{refund}원이 환불됐어요.',
    'pending': '환불을 신청했어요. 담당자가 확인해 환불해 드려요.',
    'already': '이미 환불을 신청한 구매예요.',
    'failed': '환불하지 못했어요. 잠시 뒤 다시 해 주세요.',
  },
  'en': {
    'open': 'Request a refund',
    'title': 'DIA refund',
    'window': 'Only unused paid DIA can be refunded within {days} days of purchase.',
    'loading': 'Loading…',
    'offline': 'Refunds are available once the server is connected.',
    'empty': 'No DIA pack was bought in the last {days} days.',
    'pack': 'DIA {dia} pack · {price} KRW',
    'bought': 'Bought on {month}/{day}',
    'eligible': 'Refund {refund} KRW · paid DIA {paid}',
    'bonus': ' + {bonus} bonus recalled',
    'apply': 'Refund {refund} KRW',
    'whyDone': 'The refund is complete.',
    'whyPending': 'A refund was requested and is being checked.',
    'whyEmpty': 'There is no unused paid DIA, so there is nothing to refund.',
    'whyLate': 'The refund period has ended.',
    'whyNo': 'This purchase cannot be refunded.',
    'dialog': 'Request a refund',
    'cancel': 'Cancel',
    'confirm': 'Request a refund',
    'body': 'Unused paid DIA {paid}{bonus} will be removed and {refund} KRW will be refunded.{spent}\nThis cannot be undone.',
    'dropBonus': ' and {bonus} bonus',
    'spent': '\nBonus already spent ({spent}) deducted {won} KRW.',
    'done': '{refund} KRW was refunded.',
    'pending': 'Refund requested. A reviewer will confirm and send it.',
    'already': 'A refund was already requested for this purchase.',
    'failed': 'The refund could not be sent. Please try again shortly.',
  },
  'ja': {
    'open': '返金を申請する',
    'title': 'DIAの返金',
    'window': '購入日から{days}日以内の、未使用の有料DIAだけ返金できます。',
    'loading': '読み込み中…',
    'offline': 'サーバーにつながると返金できます。',
    'empty': '{days}日以内に買ったDIAパックはありません。',
    'pack': 'DIA {dia}個パック · {price}ウォン',
    'bought': '{month}月{day}日に購入',
    'eligible': '返金 {refund}ウォン · 有料DIA {paid}個',
    'bonus': ' + ボーナス{bonus}個を回収',
    'apply': '{refund}ウォンを返金申請',
    'whyDone': '返金が完了しました。',
    'whyPending': '返金を申請しました。確認中です。',
    'whyEmpty': '未使用の有料DIAがないため、返金できる金額がありません。',
    'whyLate': '返金期間が過ぎました。',
    'whyNo': '返金できません。',
    'dialog': '返金申請',
    'cancel': 'キャンセル',
    'confirm': '返金を申請',
    'body': '未使用の有料DIA {paid}個{bonus}が減り、{refund}ウォンが返金されます。{spent}\n申請すると元に戻せません。',
    'dropBonus': 'とボーナス{bonus}個',
    'spent': '\nすでに使ったボーナス{spent}個分として{won}ウォンを引きました。',
    'done': '{refund}ウォンが返金されました。',
    'pending': '返金を申請しました。担当者が確認して返金します。',
    'already': 'この購入はすでに返金を申請しています。',
    'failed': '返金できませんでした。しばらくしてからもう一度お試しください。',
  },
  'zh': {
    'open': '申請退款',
    'title': 'DIA 退款',
    'window': '僅購買日起 {days} 天內、尚未使用的付費 DIA 可以退款。',
    'loading': '載入中…',
    'offline': '連上伺服器後就可以退款。',
    'empty': '{days} 天內沒有購買 DIA 組合。',
    'pack': 'DIA {dia} 個組合 · {price} 韓元',
    'bought': '{month}月{day}日購買',
    'eligible': '退款 {refund} 韓元 · 付費 DIA {paid} 個',
    'bonus': ' + 收回獎勵 {bonus} 個',
    'apply': '申請退款 {refund} 韓元',
    'whyDone': '退款已完成。',
    'whyPending': '已申請退款，確認中。',
    'whyEmpty': '沒有未使用的付費 DIA，所以沒有可退金額。',
    'whyLate': '已超過退款期限。',
    'whyNo': '無法退款。',
    'dialog': '申請退款',
    'cancel': '取消',
    'confirm': '申請退款',
    'body': '未使用的付費 DIA {paid} 個{bonus}會被扣回，並退還 {refund} 韓元。{spent}\n送出後無法取消。',
    'dropBonus': '和獎勵 {bonus} 個',
    'spent': '\n已使用的獎勵 {spent} 個已扣除 {won} 韓元。',
    'done': '已退款 {refund} 韓元。',
    'pending': '已申請退款。負責人確認後會把款項退回。',
    'already': '這筆購買已經申請過退款。',
    'failed': '退款沒有送出。請稍後再試。',
  },
  'es': {
    'open': 'Pedir reembolso',
    'title': 'Reembolso de DIA',
    'window': 'Solo el DIA de pago no usado se reembolsa dentro de {days} días desde la compra.',
    'loading': 'Cargando…',
    'offline': 'El reembolso está disponible al conectar con el servidor.',
    'empty': 'No hay un pack de DIA comprado en los últimos {days} días.',
    'pack': 'Pack de {dia} DIA · {price} KRW',
    'bought': 'Comprado el {day}/{month}',
    'eligible': 'Reembolso {refund} KRW · DIA de pago {paid}',
    'bonus': ' + {bonus} de bonus retirados',
    'apply': 'Reembolsar {refund} KRW',
    'whyDone': 'El reembolso ya terminó.',
    'whyPending': 'El reembolso está pedido y en revisión.',
    'whyEmpty': 'No queda DIA de pago sin usar, así que no hay importe que devolver.',
    'whyLate': 'El plazo de reembolso terminó.',
    'whyNo': 'No se puede reembolsar.',
    'dialog': 'Pedir reembolso',
    'cancel': 'Cancelar',
    'confirm': 'Pedir reembolso',
    'body': 'Se quitarán {paid} DIA de pago no usados{bonus} y se devolverán {refund} KRW.{spent}\nNo se puede deshacer.',
    'dropBonus': ' y {bonus} de bonus',
    'spent': '\nEl bonus ya gastado ({spent}) restó {won} KRW.',
    'done': 'Se reembolsaron {refund} KRW.',
    'pending': 'Reembolso pedido. Una persona lo confirmará y lo enviará.',
    'already': 'Esta compra ya tiene un reembolso pedido.',
    'failed': 'No se pudo enviar el reembolso. Inténtalo de nuevo en un momento.',
  },
  'pt': {
    'open': 'Pedir reembolso',
    'title': 'Reembolso de DIA',
    'window': 'Só DIA pago não usado pode ser reembolsado em até {days} dias da compra.',
    'loading': 'Carregando…',
    'offline': 'O reembolso fica disponível quando o servidor conectar.',
    'empty': 'Nenhum pacote de DIA foi comprado nos últimos {days} dias.',
    'pack': 'Pacote de {dia} DIA · {price} KRW',
    'bought': 'Comprado em {day}/{month}',
    'eligible': 'Reembolso {refund} KRW · DIA pago {paid}',
    'bonus': ' + {bonus} de bônus retirados',
    'apply': 'Reembolsar {refund} KRW',
    'whyDone': 'O reembolso foi concluído.',
    'whyPending': 'O reembolso foi pedido e está em análise.',
    'whyEmpty': 'Não há DIA pago sem uso, então não há valor a devolver.',
    'whyLate': 'O prazo de reembolso acabou.',
    'whyNo': 'Não é possível reembolsar.',
    'dialog': 'Pedir reembolso',
    'cancel': 'Cancelar',
    'confirm': 'Pedir reembolso',
    'body': '{paid} DIA pagos não usados{bonus} serão retirados e {refund} KRW serão devolvidos.{spent}\nNão dá para desfazer.',
    'dropBonus': ' e {bonus} de bônus',
    'spent': '\nO bônus já gasto ({spent}) descontou {won} KRW.',
    'done': '{refund} KRW foram reembolsados.',
    'pending': 'Reembolso pedido. Alguém da equipe confirma e devolve.',
    'already': 'Esta compra já tem um reembolso pedido.',
    'failed': 'Não foi possível enviar o reembolso. Tente de novo daqui a pouco.',
  },
  'de': {
    'open': 'Erstattung beantragen',
    'title': 'DIA-Erstattung',
    'window': 'Nur ungenutztes bezahltes DIA kann innerhalb von {days} Tagen nach dem Kauf erstattet werden.',
    'loading': 'Wird geladen…',
    'offline': 'Eine Erstattung geht, sobald der Server verbunden ist.',
    'empty': 'In den letzten {days} Tagen wurde kein DIA-Paket gekauft.',
    'pack': 'DIA-Paket {dia} · {price} KRW',
    'bought': 'Gekauft am {day}.{month}.',
    'eligible': 'Erstattung {refund} KRW · bezahltes DIA {paid}',
    'bonus': ' + {bonus} Bonus zurückgezogen',
    'apply': '{refund} KRW erstatten',
    'whyDone': 'Die Erstattung ist abgeschlossen.',
    'whyPending': 'Die Erstattung ist beantragt und wird geprüft.',
    'whyEmpty': 'Es ist kein ungenutztes bezahltes DIA da, also gibt es nichts zu erstatten.',
    'whyLate': 'Die Frist ist abgelaufen.',
    'whyNo': 'Eine Erstattung ist nicht möglich.',
    'dialog': 'Erstattung beantragen',
    'cancel': 'Abbrechen',
    'confirm': 'Erstattung beantragen',
    'body': 'Ungenutztes bezahltes DIA {paid}{bonus} wird entfernt und {refund} KRW werden erstattet.{spent}\nDas lässt sich nicht rückgängig machen.',
    'dropBonus': ' und {bonus} Bonus',
    'spent': '\nSchon verbrauchter Bonus ({spent}) hat {won} KRW abgezogen.',
    'done': '{refund} KRW wurden erstattet.',
    'pending': 'Erstattung beantragt. Jemand prüft sie und zahlt sie aus.',
    'already': 'Für diesen Kauf wurde schon eine Erstattung beantragt.',
    'failed': 'Die Erstattung konnte nicht gesendet werden. Bitte gleich noch einmal versuchen.',
  },
  'fr': {
    'open': 'Demander un remboursement',
    'title': 'Remboursement DIA',
    'window': 'Seul le DIA payant non utilisé peut être remboursé dans les {days} jours après l\'achat.',
    'loading': 'Chargement…',
    'offline': 'Le remboursement est possible une fois le serveur connecté.',
    'empty': 'Aucun pack DIA acheté dans les {days} derniers jours.',
    'pack': 'Pack de {dia} DIA · {price} KRW',
    'bought': 'Acheté le {day}/{month}',
    'eligible': 'Remboursement {refund} KRW · DIA payant {paid}',
    'bonus': ' + {bonus} bonus retirés',
    'apply': 'Rembourser {refund} KRW',
    'whyDone': 'Le remboursement est terminé.',
    'whyPending': 'Le remboursement est demandé et en cours de vérification.',
    'whyEmpty': 'Il ne reste pas de DIA payant inutilisé, donc rien à rembourser.',
    'whyLate': 'Le délai de remboursement est passé.',
    'whyNo': 'Remboursement impossible.',
    'dialog': 'Demander un remboursement',
    'cancel': 'Annuler',
    'confirm': 'Demander un remboursement',
    'body': '{paid} DIA payants non utilisés{bonus} seront retirés et {refund} KRW seront remboursés.{spent}\nC\'est irréversible.',
    'dropBonus': ' et {bonus} bonus',
    'spent': '\nLe bonus déjà dépensé ({spent}) a retiré {won} KRW.',
    'done': '{refund} KRW ont été remboursés.',
    'pending': 'Remboursement demandé. Une personne le confirmera et l\'enverra.',
    'already': 'Un remboursement a déjà été demandé pour cet achat.',
    'failed': 'Le remboursement n\'a pas pu être envoyé. Réessayez dans un instant.',
  },
  'vi': {
    'open': 'Yêu cầu hoàn tiền',
    'title': 'Hoàn DIA',
    'window': 'Chỉ DIA trả phí chưa dùng được hoàn trong {days} ngày kể từ ngày mua.',
    'loading': 'Đang tải…',
    'offline': 'Có thể hoàn tiền khi đã kết nối máy chủ.',
    'empty': 'Không có gói DIA nào mua trong {days} ngày gần đây.',
    'pack': 'Gói {dia} DIA · {price} KRW',
    'bought': 'Mua ngày {day}/{month}',
    'eligible': 'Hoàn {refund} KRW · DIA trả phí {paid}',
    'bonus': ' + thu hồi {bonus} thưởng',
    'apply': 'Hoàn {refund} KRW',
    'whyDone': 'Đã hoàn tiền xong.',
    'whyPending': 'Đã gửi yêu cầu hoàn tiền và đang được kiểm tra.',
    'whyEmpty': 'Không còn DIA trả phí chưa dùng, nên không có số tiền để hoàn.',
    'whyLate': 'Đã hết hạn hoàn tiền.',
    'whyNo': 'Không hoàn được.',
    'dialog': 'Yêu cầu hoàn tiền',
    'cancel': 'Hủy',
    'confirm': 'Yêu cầu hoàn tiền',
    'body': '{paid} DIA trả phí chưa dùng{bonus} sẽ bị trừ và {refund} KRW sẽ được hoàn.{spent}\nKhông thể hoàn tác.',
    'dropBonus': ' và {bonus} thưởng',
    'spent': '\nThưởng đã dùng ({spent}) đã trừ {won} KRW.',
    'done': 'Đã hoàn {refund} KRW.',
    'pending': 'Đã yêu cầu hoàn tiền. Người phụ trách sẽ xác nhận và hoàn.',
    'already': 'Giao dịch này đã được yêu cầu hoàn tiền.',
    'failed': 'Chưa gửi được yêu cầu. Hãy thử lại sau ít phút.',
  },
  'th': {
    'open': 'ขอคืนเงิน',
    'title': 'คืนเงิน DIA',
    'window': 'คืนได้เฉพาะ DIA แบบเสียเงินที่ยังไม่ใช้ ภายใน {days} วันนับจากวันที่ซื้อ',
    'loading': 'กำลังโหลด…',
    'offline': 'ขอคืนเงินได้เมื่อเชื่อมต่อเซิร์ฟเวอร์',
    'empty': 'ไม่มีแพ็ก DIA ที่ซื้อใน {days} วันที่ผ่านมา',
    'pack': 'แพ็ก DIA {dia} ชิ้น · {price} วอน',
    'bought': 'ซื้อวันที่ {day}/{month}',
    'eligible': 'คืน {refund} วอน · DIA แบบเสียเงิน {paid} ชิ้น',
    'bonus': ' + ดึงโบนัส {bonus} ชิ้นกลับ',
    'apply': 'ขอคืน {refund} วอน',
    'whyDone': 'คืนเงินเรียบร้อยแล้ว',
    'whyPending': 'ส่งคำขอคืนเงินแล้ว กำลังตรวจสอบ',
    'whyEmpty': 'ไม่มี DIA แบบเสียเงินที่ยังไม่ใช้ จึงไม่มียอดให้คืน',
    'whyLate': 'เลยระยะเวลาคืนเงินแล้ว',
    'whyNo': 'คืนเงินไม่ได้',
    'dialog': 'ขอคืนเงิน',
    'cancel': 'ยกเลิก',
    'confirm': 'ขอคืนเงิน',
    'body': 'DIA แบบเสียเงินที่ยังไม่ใช้ {paid} ชิ้น{bonus} จะถูกหัก และคืน {refund} วอน{spent}\nส่งคำขอแล้วแก้ไขไม่ได้',
    'dropBonus': ' และโบนัส {bonus} ชิ้น',
    'spent': '\nโบนัสที่ใช้ไปแล้ว {spent} ชิ้น หักไป {won} วอน',
    'done': 'คืนเงิน {refund} วอนแล้ว',
    'pending': 'ส่งคำขอแล้ว ผู้ดูแลจะตรวจและคืนเงินให้',
    'already': 'การซื้อนี้ขอคืนเงินไปแล้ว',
    'failed': 'ส่งคำขอไม่สำเร็จ ลองอีกครั้งในอีกสักครู่',
  },
  'id': {
    'open': 'Ajukan pengembalian',
    'title': 'Pengembalian DIA',
    'window': 'Hanya DIA berbayar yang belum terpakai yang bisa dikembalikan dalam {days} hari sejak pembelian.',
    'loading': 'Memuat…',
    'offline': 'Pengembalian tersedia setelah terhubung ke server.',
    'empty': 'Tidak ada paket DIA yang dibeli dalam {days} hari terakhir.',
    'pack': 'Paket {dia} DIA · {price} KRW',
    'bought': 'Dibeli {day}/{month}',
    'eligible': 'Kembali {refund} KRW · DIA berbayar {paid}',
    'bonus': ' + {bonus} bonus ditarik',
    'apply': 'Kembalikan {refund} KRW',
    'whyDone': 'Pengembalian selesai.',
    'whyPending': 'Pengembalian sudah diajukan dan sedang diperiksa.',
    'whyEmpty': 'Tidak ada DIA berbayar yang tersisa, jadi tidak ada yang dikembalikan.',
    'whyLate': 'Batas waktu pengembalian sudah lewat.',
    'whyNo': 'Tidak bisa dikembalikan.',
    'dialog': 'Ajukan pengembalian',
    'cancel': 'Batal',
    'confirm': 'Ajukan pengembalian',
    'body': '{paid} DIA berbayar yang belum terpakai{bonus} akan dikurangi dan {refund} KRW dikembalikan.{spent}\nIni tidak bisa dibatalkan.',
    'dropBonus': ' dan {bonus} bonus',
    'spent': '\nBonus yang sudah terpakai ({spent}) memotong {won} KRW.',
    'done': '{refund} KRW sudah dikembalikan.',
    'pending': 'Pengembalian diajukan. Petugas akan meninjau dan mengirimkannya.',
    'already': 'Pembelian ini sudah diajukan pengembaliannya.',
    'failed': 'Pengembalian tidak terkirim. Coba lagi sebentar lagi.',
  },
};
