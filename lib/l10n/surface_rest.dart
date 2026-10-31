import 'package:flutter/widgets.dart';

/// Home cards, settings categories, the wallet, and grade animals.
///
/// The 90 keys were rewritten as product copy a native reader can use.
/// Country watch-share figures in the debate note are still assumptions.
/// Product numbers stay in the code that already owns them.
const restLanguageOrder = <String>[
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

const homeSurfaceRows = <String, List<String>>{
  'linkWatch': [
    '워치 연동',
    'Link a watch',
    'ウォッチ連携',
    '連結手錶',
    'Vincular un reloj',
    'Vincular relógio',
    'Uhr verbinden',
    'Lier la montre',
    'Liên kết đồng hồ',
    'เชื่อมนาฬิกา',
    'Hubungkan jam tangan',
  ],
  'linking': [
    '연동 중...',
    'Linking...',
    '連携中...',
    '連結中...',
    'Vinculando...',
    'Vinculando...',
    'Verbinden...',
    'Connexion...',
    'Đang liên kết...',
    'กำลังเชื่อม...',
    'Menghubungkan...',
  ],
  'myWallet': [
    '내 지갑',
    'My wallet',
    'マイウォレット',
    '我的錢包',
    'Mi cartera',
    'Minha carteira',
    'Mein Geldbeutel',
    'Mon portefeuille',
    'Ví của tôi',
    'กระเป๋าของฉัน',
    'Dompet saya',
  ],
  'recruiting': [
    '모집 중인 챌린지',
    'Open challenges',
    '募集中のチャレンジ',
    '招募中的挑戰',
    'Retos abiertos',
    'Desafios abertos',
    'Offene Challenges',
    'Défis ouverts',
    'Thử thách đang mở',
    'ชาเลนจ์ที่เปิดรับ',
    'Tantangan yang dibuka',
  ],
  'recruitingEmpty': [
    '모집 중인 대회가 아직 없어요.',
    'No race is open yet.',
    '募集中の大会はまだありません。',
    '還沒有招募中的賽事。',
    'Todavía no hay una carrera abierta.',
    'Ainda não há uma prova aberta.',
    'Noch ist kein Rennen offen.',
    'Aucune course n’est ouverte.',
    'Chưa có giải nào đang mở.',
    'ยังไม่มีการแข่งขันที่เปิดรับ',
    'Belum ada lomba yang dibuka.',
  ],
  'diamondTitle': [
    '다이아몬드 잔액',
    'Diamond balance',
    'ダイヤ残高',
    '鑽石餘額',
    'Saldo de diamantes',
    'Saldo de diamantes',
    'Diamant-Guthaben',
    'Solde de diamants',
    'Số dư kim cương',
    'ยอดเพชร',
    'Saldo berlian',
  ],
  'diaBalance': [
    'DIA 잔액',
    'DIA balance',
    'DIA残高',
    'DIA 餘額',
    'Saldo DIA',
    'Saldo DIA',
    'DIA-Guthaben',
    'Solde DIA',
    'Số dư DIA',
    'ยอด DIA',
    'Saldo DIA',
  ],
  'tierLocked': [
    '티어 {tier} 대회는 잠겨 있어요',
    'Tier {tier} races are locked',
    'ティア{tier}の大会はロック中です',
    '等級 {tier} 的賽事尚未解鎖',
    'Las carreras de nivel {tier} están cerradas',
    'As provas do nível {tier} estão fechadas',
    'Rennen der Stufe {tier} sind gesperrt',
    'Les courses de palier {tier} sont verrouillées',
    'Giải hạng {tier} đang khóa',
    'การแข่งขันระดับ {tier} ยังล็อกอยู่',
    'Lomba tingkat {tier} masih terkunci',
  ],
  'roomFull': [
    '정원이 가득 찼어요',
    'This race is full',
    '定員に達しました',
    '名額已滿',
    'La carrera está llena',
    'A prova está cheia',
    'Das Rennen ist voll',
    'La course est complète',
    'Giải đã đủ người',
    'การแข่งขันเต็มแล้ว',
    'Lomba sudah penuh',
  ],
  'healthNeed': [
    'Health Connect 권한이 필요합니다. 상단 워치 연동을 먼저 완료해 주세요.',
    'Health Connect permission is required. Finish linking the watch at the top first.',
    'Health Connectの許可が必要です。先に上のウォッチ連携を終えてください。',
    '需要 Health Connect 權限。請先完成上方的手錶連結。',
    'Hace falta el permiso de Health Connect. Termina antes de vincular el reloj arriba.',
    'A permissão do Health Connect é necessária. Termine antes o vínculo do relógio no topo.',
    'Health Connect braucht eine Erlaubnis. Verbinde zuerst oben die Uhr.',
    'L’autorisation Health Connect est requise. Terminez d’abord la liaison en haut.',
    'Cần quyền Health Connect. Hãy liên kết đồng hồ ở phía trên trước.',
    'ต้องอนุญาต Health Connect โปรดเชื่อมนาฬิกาด้านบนก่อน',
    'Izin Health Connect diperlukan. Hubungkan jam di atas terlebih dahulu.',
  ],
  'healthOk': [
    'Health Connect 권한이 허용되었습니다.',
    'Health Connect permission was allowed.',
    'Health Connectを許可しました。',
    '已允許 Health Connect。',
    'Se permitió Health Connect.',
    'O Health Connect foi permitido.',
    'Health Connect wurde erlaubt.',
    'Health Connect a été autorisé.',
    'Đã cho phép Health Connect.',
    'อนุญาต Health Connect แล้ว',
    'Health Connect diizinkan.',
  ],
  'healthDenied': [
    'Health Connect 권한이 거부되었거나 취소되었습니다.',
    'Health Connect permission was denied or cancelled.',
    'Health Connectは拒否されたか取り消されました。',
    'Health Connect 被拒絕或已取消。',
    'El permiso de Health Connect se denegó o se canceló.',
    'A permissão do Health Connect foi negada ou cancelada.',
    'Health Connect wurde abgelehnt oder abgebrochen.',
    'Health Connect a été refusé ou annulé.',
    'Quyền Health Connect bị từ chối hoặc đã hủy.',
    'สิทธิ์ Health Connect ถูกปฏิเสธหรือยกเลิก',
    'Izin Health Connect ditolak atau dibatalkan.',
  ],
  'healthFail': [
    'Health Connect 권한 요청 실패: {error}',
    'Health Connect request failed: {error}',
    'Health Connectの要求に失敗しました: {error}',
    'Health Connect 請求失敗：{error}',
    'Falló la solicitud de Health Connect: {error}',
    'Falha ao pedir o Health Connect: {error}',
    'Health-Connect-Anfrage fehlgeschlagen: {error}',
    'Échec de la demande Health Connect : {error}',
    'Yêu cầu Health Connect thất bại: {error}',
    'ขอ Health Connect ไม่สำเร็จ: {error}',
    'Permintaan Health Connect gagal: {error}',
  ],
  'diamondMine': [
    '내 다이아',
    'My diamonds',
    'マイダイヤ',
    '我的鑽石',
    'Mis diamantes',
    'Meus diamantes',
    'Meine Diamanten',
    'Mes diamants',
    'Kim cương của tôi',
    'เพชรของฉัน',
    'Berlian saya',
  ],
  'bonusDia': [
    '보너스 다이아',
    'Bonus diamonds',
    'ボーナスダイヤ',
    '獎勵鑽石',
    'Diamantes de bono',
    'Diamantes de bônus',
    'Bonus-Diamanten',
    'Diamants bonus',
    'Kim cương thưởng',
    'เพชรโบนัส',
    'Berlian bonus',
  ],
  'useFirst': [
    '먼저 사용',
    'Used first',
    '先に使用',
    '優先使用',
    'Se usa primero',
    'Usado primeiro',
    'Zuerst verbraucht',
    'Utilisé d’abord',
    'Dùng trước',
    'ใช้ก่อน',
    'Dipakai dulu',
  ],
  'paidDia': [
    '결제 다이아',
    'Paid diamonds',
    '購入ダイヤ',
    '付費鑽石',
    'Diamantes de pago',
    'Diamantes pagos',
    'Bezahlte Diamanten',
    'Diamants payants',
    'Kim cương đã mua',
    'เพชรที่จ่ายเงิน',
    'Berlian berbayar',
  ],
  'bonusNote': [
    '보너스 다이아는 대회 상금으로 받으며 먼저 사용돼요.',
    'Bonus diamonds come from race prizes and are spent first.',
    'ボーナスダイヤは大会の賞でもらい、先に使われます。',
    '獎勵鑽石來自賽事獎金，並且優先使用。',
    'Los diamantes de bono salen de los premios y se gastan primero.',
    'Os diamantes de bônus vêm dos prêmios e são gastos primeiro.',
    'Bonus-Diamanten kommen aus Rennpreisen und werden zuerst verbraucht.',
    'Les diamants bonus viennent des prix et sont dépensés d’abord.',
    'Kim cương thưởng đến từ giải thưởng và được dùng trước.',
    'เพชรโบนัสมาจากรางวัลการแข่งขันและถูกใช้ก่อน',
    'Berlian bonus datang dari hadiah lomba dan dipakai lebih dulu.',
  ],
  'bonusRefundNote': [
    '보너스 다이아는 대회 상금으로 받으며 먼저 사용돼요.\n환불은 결제 다이아 기준이에요.',
    'Bonus diamonds come from race prizes and are spent first.\nRefunds follow the paid diamonds.',
    'ボーナスダイヤは大会の賞でもらい、先に使われます。\n返金は購入ダイヤが基準です。',
    '獎勵鑽石來自賽事獎金，並且優先使用。\n退款以付費鑽石為準。',
    'Los diamantes de bono salen de los premios y se gastan primero.\nEl reembolso sigue a los diamantes de pago.',
    'Os diamantes de bônus vêm dos prêmios e são gastos primeiro.\nO reembolso segue os diamantes pagos.',
    'Bonus-Diamanten kommen aus Rennpreisen und werden zuerst verbraucht.\nErstattungen richten sich nach den bezahlten Diamanten.',
    'Les diamants bonus viennent des prix et sont dépensés d’abord.\nLe remboursement suit les diamants payants.',
    'Kim cương thưởng đến từ giải thưởng và được dùng trước.\nHoàn tiền theo kim cương đã mua.',
    'เพชรโบนัสมาจากรางวัลการแข่งขันและถูกใช้ก่อน\nการคืนเงินยึดตามเพชรที่จ่ายเงิน',
    'Berlian bonus datang dari hadiah lomba dan dipakai lebih dulu.\nPengembalian dana mengikuti berlian berbayar.',
  ],
  'openDiaShop': [
    '다이아 상점 가기',
    'Open the diamond shop',
    'ダイヤショップへ',
    '前往鑽石商店',
    'Ir a la tienda de diamantes',
    'Abrir a loja de diamantes',
    'Zum Diamant-Shop',
    'Ouvrir la boutique de diamants',
    'Mở cửa hàng kim cương',
    'ไปร้านเพชร',
    'Buka toko berlian',
  ],
};

const settingsSurfaceRows = <String, List<String>>{
  'catAccount': [
    '계정 프로필 관리',
    'Account and profile',
    'アカウントとプロフィール',
    '帳號與個人資料',
    'Cuenta y perfil',
    'Conta e perfil',
    'Konto und Profil',
    'Compte et profil',
    'Tài khoản và hồ sơ',
    'บัญชีและโปรไฟล์',
    'Akun dan profil',
  ],
  'catAlerts': [
    '알림 및 서비스 제어',
    'Alerts and controls',
    '通知と操作',
    '通知與服務控制',
    'Avisos y controles',
    'Alertas e controles',
    'Hinweise und Steuerung',
    'Alertes et réglages',
    'Thông báo và điều khiển',
    'การแจ้งเตือนและการควบคุม',
    'Notifikasi dan kontrol',
  ],
  'catRunner': [
    '러너 전문 기능',
    'Runner tools',
    'ランナー機能',
    '跑者功能',
    'Herramientas de corredor',
    'Ferramentas de corredor',
    'Läufer-Werkzeuge',
    'Outils du coureur',
    'Công cụ runner',
    'เครื่องมือนักวิ่ง',
    'Alat pelari',
  ],
  'catSecurity': [
    '보안·프라이버시',
    'Security and privacy',
    'セキュリティとプライバシー',
    '安全與隱私',
    'Seguridad y privacidad',
    'Segurança e privacidade',
    'Sicherheit und Datenschutz',
    'Sécurité et confidentialité',
    'Bảo mật và quyền riêng tư',
    'ความปลอดภัยและความเป็นส่วนตัว',
    'Keamanan dan privasi',
  ],
  'catLegal': [
    '약관 및 계정 지원',
    'Terms and account help',
    '規約とアカウント支援',
    '條款與帳號支援',
    'Términos y ayuda de la cuenta',
    'Termos e ajuda da conta',
    'Bedingungen und Kontohilfe',
    'Conditions et aide du compte',
    'Điều khoản và hỗ trợ tài khoản',
    'ข้อกำหนดและความช่วยเหลือบัญชี',
    'Ketentuan dan bantuan akun',
  ],
  'nickTitle': [
    '닉네임 변경 (수수료 {dia} DIA)',
    'Change nickname (fee {dia} DIA)',
    'ニックネーム変更（手数料 {dia} DIA）',
    '變更暱稱（手續費 {dia} DIA）',
    'Cambiar apodo (comisión {dia} DIA)',
    'Mudar apelido (taxa {dia} DIA)',
    'Spitzname ändern (Gebühr {dia} DIA)',
    'Changer le pseudo (frais {dia} DIA)',
    'Đổi biệt danh (phí {dia} DIA)',
    'เปลี่ยนชื่อเล่น (ค่าธรรมเนียม {dia} DIA)',
    'Ubah nama panggilan (biaya {dia} DIA)',
  ],
  'nickNow': [
    '현재 · {name}',
    'Now · {name}',
    '現在 · {name}',
    '目前 · {name}',
    'Ahora · {name}',
    'Agora · {name}',
    'Aktuell · {name}',
    'Actuel · {name}',
    'Hiện tại · {name}',
    'ตอนนี้ · {name}',
    'Sekarang · {name}',
  ],
  'login': [
    '로그인 연결',
    'Sign-in links',
    'ログイン連携',
    '登入連結',
    'Vínculos de acceso',
    'Vínculos de login',
    'Anmelde-Verknüpfungen',
    'Connexions de compte',
    'Liên kết đăng nhập',
    'การเชื่อมต่อเข้าสู่ระบบ',
    'Tautan masuk',
  ],
  'loginSub': [
    '구글·카카오를 한 계정으로',
    'Google and Kakao on one account',
    'GoogleとKakaoを一つのアカウントに',
    '把 Google 與 Kakao 收到同一個帳號',
    'Google y Kakao en una cuenta',
    'Google e Kakao numa conta',
    'Google und Kakao in einem Konto',
    'Google et Kakao sur un compte',
    'Google và Kakao trên một tài khoản',
    'Google และ Kakao ในบัญชีเดียว',
    'Google dan Kakao dalam satu akun',
  ],
  'animalRow': [
    '현재 내 동물 티어 확인',
    'See my animal grade',
    '今の動物グレードを見る',
    '查看目前的動物等級',
    'Ver mi grado de animal',
    'Ver meu grau de animal',
    'Meine Tier-Stufe ansehen',
    'Voir mon grade animal',
    'Xem hạng thú của tôi',
    'ดูระดับสัตว์ของฉัน',
    'Lihat tingkat hewan saya',
  ],
  'walkTitle': [
    '걷기 알림 (아침·점심·저녁)',
    'Walk reminders (morning, noon, evening)',
    '歩き通知（朝・昼・夜）',
    '步行提醒（早·午·晚）',
    'Avisos para caminar (mañana, mediodía, noche)',
    'Lembretes de caminhada (manhã, meio-dia, noite)',
    'Geherinnerungen (Morgen, Mittag, Abend)',
    'Rappels de marche (matin, midi, soir)',
    'Nhắc đi bộ (sáng, trưa, tối)',
    'เตือนเดิน (เช้า เที่ยง เย็น)',
    'Pengingat jalan (pagi, siang, malam)',
  ],
  'walkSub': [
    '정해진 시각에 걷기를 알려 줘요. 끄면 이 알림은 오지 않아요.',
    'A reminder at set times. Turn it off and these alerts stop.',
    '決まった時刻に歩きを知らせます。オフにすると止まります。',
    '在固定時間提醒步行。關閉後就不再通知。',
    'Avisa a caminar a horas fijas. Si lo apagas, estos avisos paran.',
    'Avisa para caminhar em horários fixos. Desligado, esses alertas param.',
    'Erinnert zu festen Zeiten ans Gehen. Ausgeschaltet kommen sie nicht.',
    'Rappelle de marcher à heures fixes. Désactivé, ces alertes s’arrêtent.',
    'Nhắc đi bộ vào giờ đã định. Tắt thì những nhắc này dừng.',
    'เตือนให้เดินตามเวลาที่กำหนด ปิดแล้วการแจ้งเตือนนี้จะหยุด',
    'Mengingatkan jalan pada jam yang ditentukan. Dimatikan, peringatan ini berhenti.',
  ],
  'pushTitle': [
    '푸시 알림 수신 설정',
    'Push alerts',
    'プッシュ通知',
    '推播通知',
    'Alertas push',
    'Alertas push',
    'Push-Mitteilungen',
    'Alertes push',
    'Thông báo đẩy',
    'การแจ้งเตือนพุช',
    'Notifikasi push',
  ],
  'pushSub': [
    '재화 실시간 획득 · 크루 긴급 공지',
    'Live rewards · urgent crew notices',
    '報酬の即時獲得 · クルー緊急告知',
    '即時獲得獎勵 · 隊伍緊急公告',
    'Recompensas al momento · avisos urgentes del equipo',
    'Recompensas na hora · avisos urgentes da equipe',
    'Sofortige Belohnungen · dringende Crew-Hinweise',
    'Gains en direct · avis urgents d’équipe',
    'Nhận thưởng ngay · thông báo khẩn của đội',
    'รับรางวัลทันที · ประกาศด่วนของทีม',
    'Hadiah langsung · pengumuman mendesak kru',
  ],
  'botTitle': [
    '달팽이봇 버튼 보이기',
    'Show the snail bot button',
    'カタツムリボットのボタンを表示',
    '顯示蝸牛機器人按鈕',
    'Mostrar el botón del bot caracol',
    'Mostrar o botão do bot caracol',
    'Schneckenbot-Knopf zeigen',
    'Afficher le bouton du bot escargot',
    'Hiện nút bot ốc sên',
    'แสดงปุ่มบอทหอยทาก',
    'Tampilkan tombol bot siput',
  ],
  'botSub': [
    '홈과 대회 화면에 달팽이 버튼을 보여요. 끌어서 옮길 수 있어요.',
    'Shows the snail button on Home and races. You can drag it.',
    'ホームと大会にカタツムリのボタンを出します。ドラッグで動かせます。',
    '在首頁和賽事顯示蝸牛按鈕。可以拖著移動。',
    'Muestra el botón del caracol en Inicio y en las carreras. Se puede arrastrar.',
    'Mostra o botão do caracol no Início e nas provas. Dá para arrastar.',
    'Zeigt den Schneckenknopf auf Start und Rennen. Er lässt sich ziehen.',
    'Affiche le bouton escargot sur l’accueil et les courses. On peut le glisser.',
    'Hiện nút ốc sên ở Trang chủ và giải đấu. Có thể kéo đi.',
    'แสดงปุ่มหอยทากที่หน้าแรกและการแข่งขัน ลากย้ายได้',
    'Menampilkan tombol siput di Beranda dan lomba. Bisa diseret.',
  ],
  'coachSub': [
    '무료 기본 러닝 안내 · 심박·상황에 맞춘 심층 코칭',
    'Free basic cues · deeper coaching from heart rate and context',
    '無料の基本ガイド · 心拍と状況に合わせた深いコーチング',
    '免費基本跑步提示 · 依心率與情境的深入指導',
    'Guía básica gratis · coaching según pulso y contexto',
    'Guia básica grátis · coaching pelo pulso e pelo contexto',
    'Kostenlose Basis-Hinweise · tieferes Coaching nach Puls und Lage',
    'Repères gratuits · coaching selon le pouls et le contexte',
    'Hướng dẫn chạy cơ bản miễn phí · coaching theo nhịp tim và tình huống',
    'คำแนะนำวิ่งพื้นฐานฟรี · โค้ชตามชีพจรและสถานการณ์',
    'Panduan lari dasar gratis · coaching menurut detak dan situasi',
  ],
  'permTitle': [
    '위치 및 건강 데이터 권한 재인증',
    'Allow location and health data again',
    '位置と健康データの許可をやり直す',
    '重新允許位置與健康資料',
    'Volver a permitir ubicación y salud',
    'Permitir de novo localização e saúde',
    'Ort und Gesundheitsdaten erneut erlauben',
    'Autoriser à nouveau lieu et santé',
    'Cho phép lại vị trí và dữ liệu sức khỏe',
    'อนุญาตตำแหน่งและข้อมูลสุขภาพอีกครั้ง',
    'Izinkan lagi lokasi dan data kesehatan',
  ],
  'permSub': [
    'LBS 동의 · 스마트워치 연동 권한',
    'Location consent · watch-link permission',
    '位置情報の同意 · ウォッチ連携の許可',
    '位置同意 · 手錶連結權限',
    'Consentimiento de ubicación · permiso del reloj',
    'Consentimento de localização · permissão do relógio',
    'Ort-Zustimmung · Uhr-Verknüpfung',
    'Accord de lieu · permission de la montre',
    'Đồng ý vị trí · quyền liên kết đồng hồ',
    'ความยินยอมตำแหน่ง · สิทธิ์เชื่อมนาฬิกา',
    'Izin lokasi · izin tautan jam',
  ],
  'checkSub': [
    '위치 · 알림 · 배터리 최적화',
    'Location · alerts · battery',
    '位置 · 通知 · バッテリー',
    '位置 · 通知 · 電池',
    'Ubicación · avisos · batería',
    'Localização · alertas · bateria',
    'Ort · Hinweise · Akku',
    'Lieu · alertes · batterie',
    'Vị trí · thông báo · pin',
    'ตำแหน่ง · การแจ้งเตือน · แบตเตอรี่',
    'Lokasi · notifikasi · baterai',
  ],
  'watchTitle': [
    '스마트워치 · 워치 앱 연결',
    'Smartwatch · watch app',
    'スマートウォッチ · ウォッチアプリ',
    '智慧手錶 · 手錶 App',
    'Reloj · app del reloj',
    'Relógio · app do relógio',
    'Smartwatch · Uhren-App',
    'Montre · app montre',
    'Đồng hồ thông minh · app đồng hồ',
    'สมาร์ทวอทช์ · แอปนาฬิกา',
    'Jam pintar · aplikasi jam',
  ],
  'watchSub': [
    '건강 데이터 연동, 워치 앱 6자리 연결 코드',
    'Health data, and the watch app’s 6-digit code',
    '健康データの連携と、ウォッチアプリの6桁コード',
    '健康資料連結，以及手錶 App 的 6 位數代碼',
    'Datos de salud y el código de 6 dígitos de la app del reloj',
    'Dados de saúde e o código de 6 dígitos do app do relógio',
    'Gesundheitsdaten und der 6-stellige Code der Uhren-App',
    'Données de santé et le code à 6 chiffres de l’app montre',
    'Dữ liệu sức khỏe và mã 6 số của app đồng hồ',
    'ข้อมูลสุขภาพ และรหัส 6 หลักของแอปนาฬิกา',
    'Data kesehatan dan kode 6 digit aplikasi jam',
  ],
  'introTitle': [
    '소개 다시 보기',
    'See the intro again',
    '紹介をもう一度',
    '再看一次介紹',
    'Ver la intro otra vez',
    'Ver a introdução de novo',
    'Intro noch einmal',
    'Revoir l’intro',
    'Xem lại phần giới thiệu',
    'ดูคำแนะนำอีกครั้ง',
    'Lihat pengantar lagi',
  ],
  'introSub': [
    '쉐어런 첫 소개 3장',
    'Three ShareRun intro cards',
    'ShareRunの最初の紹介3枚',
    'ShareRun 開場介紹 3 張',
    'Tres tarjetas de intro de ShareRun',
    'Três cartões de intro do ShareRun',
    'Drei ShareRun-Intro-Karten',
    'Trois cartes d’intro ShareRun',
    'Ba thẻ giới thiệu ShareRun',
    'การ์ดแนะนำ ShareRun 3 ใบ',
    'Tiga kartu pengantar ShareRun',
  ],
  'termsTitle': [
    '서비스 이용약관',
    'Terms of service',
    '利用規約',
    '服務條款',
    'Términos del servicio',
    'Termos de serviço',
    'Nutzungsbedingungen',
    'Conditions d’utilisation',
    'Điều khoản dịch vụ',
    'ข้อกำหนดการใช้บริการ',
    'Ketentuan layanan',
  ],
  'privacyTitle': [
    '서비스 이용약관 및 개인정보 처리방침',
    'Terms and privacy policy',
    '利用規約とプライバシー',
    '服務條款與隱私權政策',
    'Términos y privacidad',
    'Termos e privacidade',
    'Bedingungen und Datenschutz',
    'Conditions et confidentialité',
    'Điều khoản và quyền riêng tư',
    'ข้อกำหนดและนโยบายความเป็นส่วนตัว',
    'Ketentuan dan kebijakan privasi',
  ],
  'privacySub': [
    '개인정보 처리방침 전문 · 위치·건강정보 안내',
    'Full privacy policy · location and health notice',
    'プライバシー全文 · 位置と健康情報の案内',
    '隱私權政策全文 · 位置與健康資料說明',
    'Política de privacidad completa · aviso de ubicación y salud',
    'Política de privacidade completa · aviso de localização e saúde',
    'Volle Datenschutzerklärung · Hinweis zu Ort und Gesundheit',
    'Politique complète · avis lieu et santé',
    'Chính sách quyền riêng tư đầy đủ · vị trí và sức khỏe',
    'นโยบายความเป็นส่วนตัวฉบับเต็ม · ตำแหน่งและสุขภาพ',
    'Kebijakan privasi lengkap · lokasi dan kesehatan',
  ],
  'logoutTitle': [
    '로그아웃',
    'Sign out',
    'ログアウト',
    '登出',
    'Cerrar sesión',
    'Sair',
    'Abmelden',
    'Se déconnecter',
    'Đăng xuất',
    'ออกจากระบบ',
    'Keluar',
  ],
  'logoutSub': [
    'Google / Apple Auth 세션 종료',
    'End the Google / Apple session',
    'Google / Appleのセッションを終了',
    '結束 Google / Apple 工作階段',
    'Cierra la sesión de Google / Apple',
    'Encerra a sessão Google / Apple',
    'Google- / Apple-Sitzung beenden',
    'Termine la session Google / Apple',
    'Kết thúc phiên Google / Apple',
    'จบเซสชัน Google / Apple',
    'Akhiri sesi Google / Apple',
  ],
  'deleteTitle': [
    '계정 삭제',
    'Delete account',
    'アカウント削除',
    '刪除帳號',
    'Eliminar cuenta',
    'Excluir conta',
    'Konto löschen',
    'Supprimer le compte',
    'Xóa tài khoản',
    'ลบบัญชี',
    'Hapus akun',
  ],
  'deleteSub': [
    '계정·캐시 비활성화 (되돌릴 수 없음)',
    'Turns off the account and cache (cannot be undone)',
    'アカウントとキャッシュを無効にします（元に戻せません）',
    '停用帳號與快取（無法復原）',
    'Desactiva la cuenta y la caché (no se puede deshacer)',
    'Desativa a conta e o cache (não dá para desfazer)',
    'Konto und Cache werden abgeschaltet (nicht rückgängig)',
    'Désactive le compte et le cache (irréversible)',
    'Tắt tài khoản và bộ nhớ đệm (không hoàn tác được)',
    'ปิดบัญชีและแคช (ย้อนกลับไม่ได้)',
    'Menonaktifkan akun dan cache (tidak bisa dibatalkan)',
  ],
  'back': [
    '뒤로',
    'Back',
    '戻る',
    '返回',
    'Atrás',
    'Voltar',
    'Zurück',
    'Retour',
    'Quay lại',
    'กลับ',
    'Kembali',
  ],
  'logoutBody': [
    '현재 세션을 종료하고 로그인 화면으로 이동합니다.',
    'This ends the session and opens the sign-in screen.',
    '現在のセッションを終えてログイン画面へ移ります。',
    '結束目前的工作階段並回到登入畫面。',
    'Esto cierra la sesión y abre el acceso.',
    'Isso encerra a sessão e abre a tela de login.',
    'Das beendet die Sitzung und öffnet die Anmeldung.',
    'Cela termine la session et ouvre l’écran de connexion.',
    'Phiên hiện tại kết thúc và màn hình đăng nhập mở ra.',
    'จบเซสชันนี้แล้วไปที่หน้าเข้าสู่ระบบ',
    'Sesi ini berakhir dan layar masuk terbuka.',
  ],
  'cancel': [
    '취소',
    'Cancel',
    'キャンセル',
    '取消',
    'Cancelar',
    'Cancelar',
    'Abbrechen',
    'Annuler',
    'Hủy',
    'ยกเลิก',
    'Batal',
  ],
  'deleteBody': [
    '계정을 삭제하면 아래와 같이 처리되며 되돌릴 수 없습니다.\n\n'
        '• 보유한 SHARE·DIA·VALUE가 모두 사라지고, 현금으로 돌려받지 않습니다.\n'
        '• 러닝 기록 등 활동 기록은 30일 안에 삭제됩니다. 법령에 따라 보관해야 하는 결제·거래 기록은 5년간 보관한 뒤 삭제돼요.\n'
        '{coach}'
        '• 크루장이라면 먼저 크루장을 다른 크루원에게 넘겨 주세요.\n\n'
        '정말 삭제하시겠습니까?',
    'Deleting the account does the following and cannot be undone.\n\n'
        '• SHARE, DIA, and VALUE are removed and are not paid out in cash.\n'
        '• Run history and other activity are deleted within 30 days. Payment records the law requires are kept for 5 years, then deleted.\n'
        '{coach}'
        '• If you lead a crew, hand that role to another member first.\n\n'
        'Delete it anyway?',
    'アカウントを削除すると次のように処理され、元に戻せません。\n\n'
        '• 持っている SHARE・DIA・VALUE は消え、現金では戻りません。\n'
        '• ランニングなどの活動記録は30日以内に削除されます。法令で保管する決済・取引記録は5年保管したあと削除します。\n'
        '{coach}'
        '• クルー長なら、先に他のメンバーへ役を渡してください。\n\n'
        '本当に削除しますか？',
    '刪除帳號後會依下列方式處理，而且無法復原。\n\n'
        '• 持有的 SHARE、DIA、VALUE 都會消失，不會以現金退還。\n'
        '• 跑步等活動紀錄會在 30 天內刪除。依法須保存的付款與交易紀錄會保存 5 年後刪除。\n'
        '{coach}'
        '• 如果你是隊長，請先把隊長交給其他隊員。\n\n'
        '確定要刪除嗎？',
    'Eliminar la cuenta hace lo siguiente y no se puede deshacer.\n\n'
        '• SHARE, DIA y VALUE desaparecen y no se devuelven en efectivo.\n'
        '• El historial de carrera y otra actividad se borra en 30 días. Los pagos que la ley exige se guardan 5 años y luego se borran.\n'
        '{coach}'
        '• Si lideras un equipo, pasa ese papel a otro miembro primero.\n\n'
        '¿Eliminarla de todos modos?',
    'Excluir a conta faz o seguinte e não pode ser desfeito.\n\n'
        '• SHARE, DIA e VALUE somem e não voltam em dinheiro.\n'
        '• O histórico de corrida e outra atividade é apagado em 30 dias. Pagamentos que a lei exige ficam 5 anos e depois são apagados.\n'
        '{coach}'
        '• Se você lidera uma equipe, passe o papel a outro membro antes.\n\n'
        'Excluir mesmo assim?',
    'Das Konto zu löschen macht Folgendes und lässt sich nicht rückgängig machen.\n\n'
        '• SHARE, DIA und VALUE verschwinden und werden nicht in bar ausgezahlt.\n'
        '• Lauf- und andere Aktivitätsdaten werden innerhalb von 30 Tagen gelöscht. Zahlungsbelege, die das Gesetz verlangt, bleiben 5 Jahre und werden dann gelöscht.\n'
        '{coach}'
        '• Wenn du eine Crew leitest, übergib die Rolle zuerst.\n\n'
        'Trotzdem löschen?',
    'Supprimer le compte fait ceci et ne peut pas être annulé.\n\n'
        '• SHARE, DIA et VALUE disparaissent et ne sont pas rendus en argent.\n'
        '• L’historique de course et les autres activités sont effacés sous 30 jours. Les paiements exigés par la loi sont gardés 5 ans, puis effacés.\n'
        '{coach}'
        '• Si vous dirigez une équipe, transmettez ce rôle d’abord.\n\n'
        'Le supprimer quand même ?',
    'Xóa tài khoản sẽ xử lý như sau và không hoàn tác được.\n\n'
        '• SHARE, DIA và VALUE biến mất và không được trả bằng tiền mặt.\n'
        '• Lịch sử chạy và hoạt động khác bị xóa trong 30 ngày. Hồ sơ thanh toán mà luật yêu cầu được giữ 5 năm rồi xóa.\n'
        '{coach}'
        '• Nếu bạn là đội trưởng, hãy chuyển vai đó trước.\n\n'
        'Vẫn xóa?',
    'การลบบัญชีทำตามนี้และย้อนกลับไม่ได้\n\n'
        '• SHARE, DIA และ VALUE หายไป และไม่คืนเป็นเงินสด\n'
        '• ประวัติการวิ่งและกิจกรรมอื่นจะถูกลบภายใน 30 วัน บันทึกการชำระที่กฎหมายกำหนดจะเก็บ 5 ปีแล้วจึงลบ\n'
        '{coach}'
        '• ถ้าคุณเป็นหัวหน้าทีม ให้ส่งบทบาทนั้นก่อน\n\n'
        'ลบจริงหรือไม่?',
    'Menghapus akun melakukan hal berikut dan tidak bisa dibatalkan.\n\n'
        '• SHARE, DIA, dan VALUE hilang dan tidak dikembalikan sebagai uang tunai.\n'
        '• Riwayat lari dan aktivitas lain dihapus dalam 30 hari. Catatan pembayaran yang diwajibkan hukum disimpan 5 tahun, lalu dihapus.\n'
        '{coach}'
        '• Jika kamu ketua kru, serahkan peran itu lebih dulu.\n\n'
        'Tetap hapus?',
  ],
  'deleteCoach': [
    '• Coach+ 구독은 자동으로 해지되지 않습니다. Google Play 스토어의 구독 메뉴에서 직접 해지해 주세요.',
    '• Coach+ does not cancel on its own. Cancel it in Google Play subscriptions.',
    '• Coach+は自動では解約されません。Google Playの定期購入から解約してください。',
    '• Coach+ 不會自動取消。請到 Google Play 的訂閱選單自行取消。',
    '• Coach+ no se cancela solo. Cancélalo en las suscripciones de Google Play.',
    '• O Coach+ não cancela sozinho. Cancele nas assinaturas do Google Play.',
    '• Coach+ endet nicht von allein. Kündige es in den Google-Play-Abos.',
    '• Coach+ ne s’arrête pas seul. Résiliez-le dans les abonnements Google Play.',
    '• Coach+ không tự hủy. Hãy hủy trong mục đăng ký của Google Play.',
    '• Coach+ ไม่ยกเลิกเอง โปรดยกเลิกในเมนูการสมัครของ Google Play',
    '• Coach+ tidak berhenti sendiri. Batalkan di langganan Google Play.',
  ],
  'deleteConfirm': [
    '삭제하기',
    'Delete',
    '削除する',
    '刪除',
    'Eliminar',
    'Excluir',
    'Löschen',
    'Supprimer',
    'Xóa',
    'ลบ',
    'Hapus',
  ],
  'close': [
    '닫기',
    'Close',
    '閉じる',
    '關閉',
    'Cerrar',
    'Fechar',
    'Schließen',
    'Fermer',
    'Đóng',
    'ปิด',
    'Tutup',
  ],
  'openSettings': [
    '설정 열기',
    'Open settings',
    '設定を開く',
    '開啟設定',
    'Abrir ajustes',
    'Abrir ajustes',
    'Einstellungen öffnen',
    'Ouvrir les réglages',
    'Mở cài đặt',
    'เปิดการตั้งค่า',
    'Buka setelan',
  ],
  'locationOff': [
    '위치 서비스가 꺼져 있습니다. 시스템 설정에서 활성화해 주세요.',
    'Location is off. Turn it on in system settings.',
    '位置情報サービスがオフです。システムの設定でオンにしてください。',
    '定位服務已關閉。請在系統設定中開啟。',
    'La ubicación está apagada. Actívala en los ajustes del sistema.',
    'A localização está desligada. Ative nos ajustes do sistema.',
    'Ort ist aus. Schalte ihn in den Systemeinstellungen ein.',
    'La localisation est coupée. Activez-la dans les réglages du système.',
    'Dịch vụ vị trí đang tắt. Hãy bật trong cài đặt hệ thống.',
    'บริการตำแหน่งปิดอยู่ โปรดเปิดในการตั้งค่าระบบ',
    'Layanan lokasi mati. Nyalakan di setelan sistem.',
  ],
  'locationDenied': [
    '위치 권한이 거부되었습니다. 설정에서 허용해 주세요.',
    'Location permission was denied. Allow it in settings.',
    '位置情報の許可が拒否されました。設定で許可してください。',
    '定位權限被拒絕。請在設定中允許。',
    'Se denegó la ubicación. Permítela en ajustes.',
    'A localização foi negada. Permita nos ajustes.',
    'Der Ort wurde abgelehnt. Erlaube ihn in den Einstellungen.',
    'La localisation a été refusée. Autorisez-la dans les réglages.',
    'Quyền vị trí bị từ chối. Hãy cho phép trong cài đặt.',
    'สิทธิ์ตำแหน่งถูกปฏิเสธ โปรดอนุญาตในการตั้งค่า',
    'Izin lokasi ditolak. Izinkan di setelan.',
  ],
  'permOk': [
    '위치 및 건강 데이터 권한이 확인되었습니다.',
    'Location and health permissions are in place.',
    '位置と健康データの許可を確認しました。',
    '已確認位置與健康資料權限。',
    'Los permisos de ubicación y salud están listos.',
    'As permissões de localização e saúde estão prontas.',
    'Ort- und Gesundheitsrechte sind bestätigt.',
    'Les permissions de lieu et de santé sont en place.',
    'Đã xác nhận quyền vị trí và sức khỏe.',
    'ยืนยันสิทธิ์ตำแหน่งและสุขภาพแล้ว',
    'Izin lokasi dan kesehatan sudah ada.',
  ],
  'permDialogTitle': [
    '권한 재인증',
    'Allow again',
    '許可のやり直し',
    '重新授權',
    'Permitir de nuevo',
    'Permitir de novo',
    'Erneut erlauben',
    'Autoriser à nouveau',
    'Cho phép lại',
    'อนุญาตอีกครั้ง',
    'Izinkan lagi',
  ],
  'permShort': [
    '일부 권한이 부족합니다. 시스템 설정에서 위치·건강 데이터 권한을 허용해 주세요.',
    'Some permissions are missing. Allow location and health data in system settings.',
    '一部の許可が足りません。システムの設定で位置と健康データを許可してください。',
    '部分權限不足。請在系統設定允許位置與健康資料。',
    'Faltan permisos. Permite ubicación y salud en los ajustes del sistema.',
    'Faltam permissões. Permita localização e saúde nos ajustes do sistema.',
    'Es fehlen Rechte. Erlaube Ort und Gesundheit in den Systemeinstellungen.',
    'Il manque des permissions. Autorisez lieu et santé dans les réglages.',
    'Thiếu một số quyền. Hãy cho phép vị trí và sức khỏe trong cài đặt hệ thống.',
    'สิทธิ์บางอย่างไม่พอ โปรดอนุญาตตำแหน่งและสุขภาพในการตั้งค่าระบบ',
    'Sebagian izin kurang. Izinkan lokasi dan kesehatan di setelan sistem.',
  ],
  'permNeed': [
    '{label} 권한이 필요합니다. 설정에서 허용해 주세요.',
    '{label} permission is required. Allow it in settings.',
    '{label}の許可が必要です。設定で許可してください。',
    '需要 {label} 權限。請在設定中允許。',
    'Hace falta el permiso de {label}. Permítelo en ajustes.',
    'A permissão de {label} é necessária. Permita nos ajustes.',
    'Die Berechtigung {label} fehlt. Erlaube sie in den Einstellungen.',
    'La permission {label} est requise. Autorisez-la dans les réglages.',
    'Cần quyền {label}. Hãy cho phép trong cài đặt.',
    'ต้องมีสิทธิ์ {label} โปรดอนุญาตในการตั้งค่า',
    'Izin {label} diperlukan. Izinkan di setelan.',
  ],
  'accountDeleted': [
    '계정이 삭제되었습니다.',
    'The account was deleted.',
    'アカウントを削除しました。',
    '帳號已刪除。',
    'La cuenta fue eliminada.',
    'A conta foi excluída.',
    'Das Konto wurde gelöscht.',
    'Le compte a été supprimé.',
    'Tài khoản đã được xóa.',
    'ลบบัญชีแล้ว',
    'Akun sudah dihapus.',
  ],
  'unsetNick': [
    '미설정',
    'Not set',
    '未設定',
    '未設定',
    'Sin definir',
    'Não definido',
    'Nicht gesetzt',
    'Non défini',
    'Chưa đặt',
    'ยังไม่ตั้ง',
    'Belum diatur',
  ],
  'securityCenter': [
    '보안·프라이버시 센터',
    'Security and privacy center',
    'セキュリティとプライバシーセンター',
    '安全與隱私中心',
    'Centro de seguridad y privacidad',
    'Central de segurança e privacidade',
    'Zentrum für Sicherheit und Datenschutz',
    'Centre sécurité et confidentialité',
    'Trung tâm bảo mật và quyền riêng tư',
    'ศูนย์ความปลอดภัยและความเป็นส่วนตัว',
    'Pusat keamanan dan privasi',
  ],
  'legalChrome': [
    '약관 · 개인정보',
    'Terms · privacy',
    '規約 · プライバシー',
    '條款 · 隱私',
    'Términos · privacidad',
    'Termos · privacidade',
    'Bedingungen · Datenschutz',
    'Conditions · confidentialité',
    'Điều khoản · quyền riêng tư',
    'ข้อกำหนด · ความเป็นส่วนตัว',
    'Ketentuan · privasi',
  ],
};

const walletSurfaceRows = <String, List<String>>{
  'recent': [
    '최근 내역',
    'Recent activity',
    '最近の履歴',
    '最近紀錄',
    'Actividad reciente',
    'Atividade recente',
    'Letzte Vorgänge',
    'Activité récente',
    'Gần đây',
    'รายการล่าสุด',
    'Aktivitas terbaru',
  ],
  'shareHint': [
    '걷고 뛰면 쌓여요. 상점에서 쓸 수 있어요.',
    'Walking and running add to it. Spend it in the shop.',
    '歩いたり走ったりすると貯まります。ショップで使えます。',
    '走路和跑步會累積。可以在商店使用。',
    'Caminar y correr lo acumulan. Se gasta en la tienda.',
    'Caminhar e correr acumulam. Dá para gastar na loja.',
    'Gehen und Laufen füllen es. Ausgeben kannst du es im Shop.',
    'Marcher et courir l’augmentent. On le dépense dans la boutique.',
    'Đi bộ và chạy sẽ cộng vào. Dùng được ở cửa hàng.',
    'เดินและวิ่งแล้วสะสม ใช้ในร้านได้',
    'Jalan dan lari menambahnya. Bisa dipakai di toko.',
  ],
  'useStore': [
    '상점에서 쓰기',
    'Spend in the shop',
    'ショップで使う',
    '在商店使用',
    'Gastar en la tienda',
    'Gastar na loja',
    'Im Shop ausgeben',
    'Dépenser dans la boutique',
    'Dùng ở cửa hàng',
    'ใช้ในร้าน',
    'Pakai di toko',
  ],
  'historyTitle': [
    '내 거래 내역',
    'My transactions',
    '取引履歴',
    '我的交易紀錄',
    'Mis movimientos',
    'Minhas transações',
    'Meine Vorgänge',
    'Mes opérations',
    'Giao dịch của tôi',
    'รายการของฉัน',
    'Transaksi saya',
  ],
  'historyNote': [
    '서버 원장에 기록된 내역이에요. 한 번 기록된 내역은 지워지지 않아요.',
    'This is the server ledger. A recorded line is not erased.',
    'サーバーの台帳です。一度記録された行は消えません。',
    '這是伺服器帳本。記下來的一筆不會被擦掉。',
    'Es el libro del servidor. Una línea registrada no se borra.',
    'É o livro do servidor. Uma linha registrada não é apagada.',
    'Das ist das Server-Buch. Eine eingetragene Zeile wird nicht gelöscht.',
    'C’est le livre du serveur. Une ligne enregistrée n’est pas effacée.',
    'Đây là sổ của máy chủ. Dòng đã ghi không bị xóa.',
    'นี่คือสมุดของเซิร์ฟเวอร์ รายการที่บันทึกแล้วไม่ถูกลบ',
    'Ini buku server. Baris yang tercatat tidak dihapus.',
  ],
  'more': [
    '더 보기',
    'More',
    'もっと見る',
    '看更多',
    'Ver más',
    'Ver mais',
    'Mehr',
    'Voir plus',
    'Xem thêm',
    'ดูเพิ่ม',
    'Lihat lagi',
  ],
  'historyError': [
    '내역을 불러오지 못했어요. 잠시 뒤 다시 시도해 주세요.',
    'The list did not load. Try again in a moment.',
    '履歴を読み込めませんでした。しばらくしてからもう一度。',
    '紀錄沒有載入。請稍後再試。',
    'La lista no cargó. Inténtalo dentro de un momento.',
    'A lista não carregou. Tente de novo daqui a pouco.',
    'Die Liste kam nicht. Versuch es gleich noch einmal.',
    'La liste n’a pas chargé. Réessayez dans un instant.',
    'Danh sách chưa tải được. Hãy thử lại sau một lát.',
    'โหลดรายการไม่ได้ โปรดลองอีกครั้งอีกสักครู่',
    'Daftar tidak termuat. Coba lagi sebentar lagi.',
  ],
  'retry': [
    '다시 시도',
    'Try again',
    'もう一度',
    '再試一次',
    'Reintentar',
    'Tentar de novo',
    'Nochmal',
    'Réessayer',
    'Thử lại',
    'ลองอีกครั้ง',
    'Coba lagi',
  ],
};

const animalRows = <String, List<String>>{
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

const medalRows = <String, List<String>>{
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

const gradeUiRows = <String, List<String>>{
  'unrated': [
    '등급 심사 전',
    'Grade not set',
    'グレード判定前',
    '尚未評級',
    'Grado sin asignar',
    'Grau ainda não definido',
    'Stufe noch offen',
    'Grade pas encore fixé',
    'Chưa xét hạng',
    'ยังไม่จัดระดับ',
    'Tingkat belum ditetapkan',
  ],
  'myGrade': [
    '내 등급 {name}',
    'My grade {name}',
    '自分のグレード {name}',
    '我的等級 {name}',
    'Mi grado {name}',
    'Meu grau {name}',
    'Meine Stufe {name}',
    'Mon grade {name}',
    'Hạng của tôi {name}',
    'ระดับของฉัน {name}',
    'Tingkat saya {name}',
  ],
};

const _restTables = <Map<String, List<String>>>[
  homeSurfaceRows,
  settingsSurfaceRows,
  walletSurfaceRows,
  animalRows,
  medalRows,
  gradeUiRows,
];

String restAt(Map<String, List<String>> rows, String key, String languageCode) {
  final values = rows[key];
  if (values == null || values.length != restLanguageOrder.length) return '';
  final index = restLanguageOrder.indexOf(languageCode);
  if (index < 0) return '';
  return values[index];
}

String restFill(String pattern, Map<String, String> slots) {
  var text = pattern;
  for (final slot in slots.entries) {
    text = text.replaceAll('{${slot.key}}', slot.value);
  }
  return text;
}

String _languageOf(Locale locale) =>
    restLanguageOrder.contains(locale.languageCode) ? locale.languageCode : 'en';

class HomeSurfaceCopy {
  const HomeSurfaceCopy._(this.languageCode);

  final String languageCode;

  static HomeSurfaceCopy of(Locale locale) => HomeSurfaceCopy._(_languageOf(locale));

  String _at(String key) => restAt(homeSurfaceRows, key, languageCode);

  String get linkWatch => _at('linkWatch');
  String get linking => _at('linking');
  String get myWallet => _at('myWallet');
  String get recruiting => _at('recruiting');
  String get recruitingEmpty => _at('recruitingEmpty');
  String get diamondTitle => _at('diamondTitle');
  String get diaBalance => _at('diaBalance');
  String get diamondMine => _at('diamondMine');
  String get bonusDia => _at('bonusDia');
  String get useFirst => _at('useFirst');
  String get paidDia => _at('paidDia');
  String get bonusNote => _at('bonusNote');
  String get bonusRefundNote => _at('bonusRefundNote');
  String get openDiaShop => _at('openDiaShop');
  String get roomFull => _at('roomFull');
  String get healthNeed => _at('healthNeed');
  String get healthOk => _at('healthOk');
  String get healthDenied => _at('healthDenied');

  String tierLocked(int tier) => restFill(_at('tierLocked'), {'tier': '$tier'});

  String healthFail(Object error) =>
      restFill(_at('healthFail'), {'error': '$error'});
}

class SettingsSurfaceCopy {
  const SettingsSurfaceCopy._(this.languageCode);

  final String languageCode;

  static SettingsSurfaceCopy of(Locale locale) =>
      SettingsSurfaceCopy._(_languageOf(locale));

  String _at(String key) => restAt(settingsSurfaceRows, key, languageCode);

  String get catAccount => _at('catAccount');
  String get catAlerts => _at('catAlerts');
  String get catRunner => _at('catRunner');
  String get catSecurity => _at('catSecurity');
  String get catLegal => _at('catLegal');
  String get login => _at('login');
  String get loginSub => _at('loginSub');
  String get animalRow => _at('animalRow');
  String get walkTitle => _at('walkTitle');
  String get walkSub => _at('walkSub');
  String get pushTitle => _at('pushTitle');
  String get pushSub => _at('pushSub');
  String get botTitle => _at('botTitle');
  String get botSub => _at('botSub');
  String get coachSub => _at('coachSub');
  String get permTitle => _at('permTitle');
  String get permSub => _at('permSub');
  String get checkSub => _at('checkSub');
  String get watchTitle => _at('watchTitle');
  String get watchSub => _at('watchSub');
  String get introTitle => _at('introTitle');
  String get introSub => _at('introSub');
  String get termsTitle => _at('termsTitle');
  String get privacyTitle => _at('privacyTitle');
  String get privacySub => _at('privacySub');
  String get logoutTitle => _at('logoutTitle');
  String get logoutSub => _at('logoutSub');
  String get deleteTitle => _at('deleteTitle');
  String get deleteSub => _at('deleteSub');
  String get back => _at('back');
  String get logoutBody => _at('logoutBody');
  String get cancel => _at('cancel');
  String get deleteConfirm => _at('deleteConfirm');
  String get close => _at('close');
  String get openSettings => _at('openSettings');
  String get locationOff => _at('locationOff');
  String get locationDenied => _at('locationDenied');
  String get permOk => _at('permOk');
  String get permDialogTitle => _at('permDialogTitle');
  String get permShort => _at('permShort');
  String get accountDeleted => _at('accountDeleted');
  String get unsetNick => _at('unsetNick');
  String get securityCenter => _at('securityCenter');
  String get legalChrome => _at('legalChrome');

  String nickTitle(int dia) => restFill(_at('nickTitle'), {'dia': '$dia'});

  String nickNow(String name) => restFill(_at('nickNow'), {'name': name});

  String permNeed(String label) => restFill(_at('permNeed'), {'label': label});

  String deleteBody({required bool purchases}) {
    final coach = purchases ? '${_at('deleteCoach')}\n' : '';
    return restFill(_at('deleteBody'), {'coach': coach});
  }
}

class WalletSurfaceCopy {
  const WalletSurfaceCopy._(this.languageCode);

  final String languageCode;

  static WalletSurfaceCopy of(Locale locale) =>
      WalletSurfaceCopy._(_languageOf(locale));

  String _at(String key) => restAt(walletSurfaceRows, key, languageCode);

  String get recent => _at('recent');
  String get shareHint => _at('shareHint');
  String get useStore => _at('useStore');
  String get historyTitle => _at('historyTitle');
  String get historyNote => _at('historyNote');
  String get more => _at('more');
  String get historyError => _at('historyError');
  String get retry => _at('retry');
}

String animalLabel(Locale locale, String code) =>
    restAt(animalRows, code, _languageOf(locale));

String medalLabel(Locale locale, String code) =>
    restAt(medalRows, code, _languageOf(locale));

String unratedGradeLabel(Locale locale) =>
    restAt(gradeUiRows, 'unrated', _languageOf(locale));

String myGradeLabel(Locale locale, String name) =>
    restFill(restAt(gradeUiRows, 'myGrade', _languageOf(locale)), {'name': name});

/// Leaf strings in the draft tables. The same count in every locale.
int restSurfaceKeyCount() =>
    _restTables.fold(0, (sum, table) => sum + table.length);

/// Empty when home, settings, wallet, animals, and medals exist in all 11 locales.
List<String> missingRestSurfaceKeys(Iterable<Locale> locales) {
  final missing = <String>[];
  for (final locale in locales) {
    final code = locale.languageCode;
    final tag = '${locale.languageCode}-${locale.countryCode}';
    if (!restLanguageOrder.contains(code)) {
      missing.add('$tag.rest');
      continue;
    }
    for (final table in _restTables) {
      for (final entry in table.entries) {
        if (entry.value.length != restLanguageOrder.length) {
          missing.add('$tag.rest.${entry.key}.length');
          continue;
        }
        final value = restAt(table, entry.key, code);
        if (value.trim().isEmpty) missing.add('$tag.rest.${entry.key}');
        if (code != 'ko' && value == entry.value.first) {
          missing.add('$tag.rest.${entry.key}=ko');
        }
      }
    }
  }
  return missing;
}
