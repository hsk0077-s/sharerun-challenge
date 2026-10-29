import '../../l10n/app_localizations.dart';

/// 마이 화면 초대 카드의 문구. 앱이 지원하는 언어별로 나눈다.
/// 원어민 검수 전. 광고 랜딩에 쓰지 않는다.
///
/// 한국어만 카카오톡 직접 초대 버튼을 쓰고, 다른 언어는 휴대폰 공유 창(어느 앱으로든)으로 보낸다.
class InviteCopy {
  const InviteCopy({
    required this.title,
    required this.copyLabel,
    required this.copiedMessage,
    required this.loadFailedMessage,
    required this.buttonLabel,
    required this.shareSubject,
    required this.shareLead,
    required this.codeLabel,
  });

  final String title;
  final String copyLabel;
  final String copiedMessage;
  final String loadFailedMessage;
  final String buttonLabel;
  final String shareSubject;

  /// 공유 문구 첫 줄(예: "쉐어런에 초대해요!").
  final String shareLead;

  /// 코드 앞 말(예: "초대 코드").
  final String codeLabel;

  /// 받는 사람이 읽을 공유 문구. 보상 금액은 넣지 않는다.
  String shareText(String code, String storeUrl) =>
      '$shareLead\n$codeLabel: $code\n$storeUrl';
}

const _en = InviteCopy(
  title: 'My invite code',
  copyLabel: 'Copy',
  copiedMessage: 'Copied',
  loadFailedMessage: "Couldn't load your invite code. Tap to retry",
  buttonLabel: 'Invite friends',
  shareSubject: 'Join ShareRun',
  shareLead: 'Join me on ShareRun!',
  codeLabel: 'Invite code',
);

const inviteCopyByLanguage = <String, InviteCopy>{
  'ko': InviteCopy(
    title: '내 초대 코드',
    copyLabel: '복사',
    copiedMessage: '복사했어요',
    loadFailedMessage: '초대 코드를 불러오지 못했어요. 다시 시도',
    buttonLabel: '카카오톡으로 초대하기',
    shareSubject: '쉐어런 초대',
    shareLead: '쉐어런에 초대해요!',
    codeLabel: '초대 코드',
  ),
  'en': _en,
  'ja': InviteCopy(
    title: '私の招待コード',
    copyLabel: 'コピー',
    copiedMessage: 'コピーしました',
    loadFailedMessage: '招待コードを読み込めませんでした。もう一度試す',
    buttonLabel: '友だちを招待',
    shareSubject: 'ShareRunへの招待',
    shareLead: 'ShareRunに招待します！',
    codeLabel: '招待コード',
  ),
  'zh': InviteCopy(
    title: '我的邀請碼',
    copyLabel: '複製',
    copiedMessage: '已複製',
    loadFailedMessage: '無法載入邀請碼，請再試一次',
    buttonLabel: '邀請朋友',
    shareSubject: '邀請你加入 ShareRun',
    shareLead: '邀請你一起加入 ShareRun！',
    codeLabel: '邀請碼',
  ),
  'es': InviteCopy(
    title: 'Mi código de invitación',
    copyLabel: 'Copiar',
    copiedMessage: 'Copiado',
    loadFailedMessage: 'No se pudo cargar el código. Toca para reintentar',
    buttonLabel: 'Invitar amigos',
    shareSubject: 'Únete a ShareRun',
    shareLead: '¡Únete a ShareRun conmigo!',
    codeLabel: 'Código de invitación',
  ),
  'pt': InviteCopy(
    title: 'Meu código de convite',
    copyLabel: 'Copiar',
    copiedMessage: 'Copiado',
    loadFailedMessage:
        'Não foi possível carregar o código. Toque para tentar de novo',
    buttonLabel: 'Convidar amigos',
    shareSubject: 'Entre no ShareRun',
    shareLead: 'Entre no ShareRun comigo!',
    codeLabel: 'Código de convite',
  ),
  'de': InviteCopy(
    title: 'Mein Einladungscode',
    copyLabel: 'Kopieren',
    copiedMessage: 'Kopiert',
    loadFailedMessage:
        'Einladungscode konnte nicht geladen werden. Tippe zum Wiederholen',
    buttonLabel: 'Freunde einladen',
    shareSubject: 'Komm zu ShareRun',
    shareLead: 'Komm mit zu ShareRun!',
    codeLabel: 'Einladungscode',
  ),
  'fr': InviteCopy(
    title: "Mon code d'invitation",
    copyLabel: 'Copier',
    copiedMessage: 'Copié',
    loadFailedMessage: "Impossible de charger le code. Touchez pour réessayer",
    buttonLabel: 'Inviter des amis',
    shareSubject: 'Rejoignez ShareRun',
    shareLead: 'Rejoignez-moi sur ShareRun !',
    codeLabel: "Code d'invitation",
  ),
  'vi': InviteCopy(
    title: 'Mã mời của tôi',
    copyLabel: 'Sao chép',
    copiedMessage: 'Đã sao chép',
    loadFailedMessage: 'Không tải được mã mời. Chạm để thử lại',
    buttonLabel: 'Mời bạn bè',
    shareSubject: 'Tham gia ShareRun',
    shareLead: 'Cùng tham gia ShareRun nhé!',
    codeLabel: 'Mã mời',
  ),
  'th': InviteCopy(
    title: 'รหัสเชิญของฉัน',
    copyLabel: 'คัดลอก',
    copiedMessage: 'คัดลอกแล้ว',
    loadFailedMessage: 'โหลดรหัสเชิญไม่สำเร็จ แตะเพื่อลองอีกครั้ง',
    buttonLabel: 'เชิญเพื่อน',
    shareSubject: 'ร่วมสนุกกับ ShareRun',
    shareLead: 'มาร่วมสนุกกับ ShareRun ด้วยกัน!',
    codeLabel: 'รหัสเชิญ',
  ),
  'id': InviteCopy(
    title: 'Kode undangan saya',
    copyLabel: 'Salin',
    copiedMessage: 'Tersalin',
    loadFailedMessage: 'Gagal memuat kode undangan. Ketuk untuk mencoba lagi',
    buttonLabel: 'Undang teman',
    shareSubject: 'Gabung ke ShareRun',
    shareLead: 'Yuk gabung ShareRun bersamaku!',
    codeLabel: 'Kode undangan',
  ),
};

/// 앱 언어 코드(예: `ko`)에 맞는 초대 문구. 모르는 언어는 영어.
InviteCopy inviteCopyFor(String languageCode) =>
    inviteCopyByLanguage[languageCode.toLowerCase()] ?? _en;

List<String> missingInviteKeys() {
  final missing = <String>[];
  final korean = inviteCopyByLanguage['ko'];
  for (final locale in ShareRunLocalizations.supportedLocales) {
    final code = locale.languageCode;
    final tag = '${locale.languageCode}-${locale.countryCode}';
    final row = inviteCopyByLanguage[code];
    if (row == null) {
      missing.add('$tag.invite');
      continue;
    }
    final fields = <String, String>{
      'title': row.title,
      'copyLabel': row.copyLabel,
      'copiedMessage': row.copiedMessage,
      'loadFailedMessage': row.loadFailedMessage,
      'buttonLabel': row.buttonLabel,
      'shareSubject': row.shareSubject,
      'shareLead': row.shareLead,
      'codeLabel': row.codeLabel,
    };
    for (final entry in fields.entries) {
      if (entry.value.trim().isEmpty) missing.add('$tag.invite.${entry.key}');
    }
    if (code != 'ko' && korean != null && row.title == korean.title) {
      missing.add('$tag.invite.title=ko');
    }
  }
  return missing;
}
