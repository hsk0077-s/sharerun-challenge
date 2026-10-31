import 'package:flutter/widgets.dart';

import 'app_localizations.dart';
import 'surface_rest.dart';

/// Draft copy for screens that were still Korean only.
///
/// Numbers are the product rules (120–210 spm, 600 SHARE, 10 VALUE, 5 km,
/// 20 DIA, 7 days, 1,200 SHARE, 100 KRW). Sentences are a first pass.
/// Do not use them on an ad landing page before a native review.
const surfaceLanguageOrder = <String>[
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

class FairBlock {
  const FairBlock(this.title, this.lines);

  final String title;
  final List<String> lines;
}

class FairEarningCopy {
  const FairEarningCopy({
    required this.screenTitle,
    required this.footnote,
    required this.menuTitle,
    required this.menuSubtitle,
    required this.settingsSubtitle,
    required this.sections,
  });

  final String screenTitle;
  final String footnote;
  final String menuTitle;
  final String menuSubtitle;
  final String settingsSubtitle;
  final List<FairBlock> sections;

  static FairEarningCopy of(Locale locale) =>
      byLanguage[locale.languageCode] ?? byLanguage['en']!;

  static const byLanguage = <String, FairEarningCopy>{
    'ko': FairEarningCopy(
      screenTitle: '공정한 적립 정책',
      footnote: '일부 수치는 서버 설정에 따라 조정될 수 있어요.',
      menuTitle: '공정한 적립 정책',
      menuSubtitle: '검증 기준 · 하루 한도 · 기부 규칙',
      settingsSubtitle: '공정한 적립 정책 · 기록 소명',
      sections: [
        FairBlock('기본 원칙', [
          '기록은 언제나 남지만, 보상은 서버가 검증한 달리기에만 드려요.',
          '화면에 보이는 SHARE·VALUE·다이아와 기부 금액은 서버가 확인한 값이에요. '
              '어느 폰에서 로그인해도 같아요.',
          '같은 달리기는 한 번만 인정돼요.',
        ]),
        FairBlock('검증 기준', [
          '달리기 거리는 대회 거리 이상이어야 하고, 최소 1km예요.',
          '러닝 케이던스는 분당 120~210보 범위여야 해요.',
          '워치가 없으면 보폭과 GPS 속도로 확인해요.',
          '심박은 상급·하프·파이널 대회에서만 필수예요.',
        ]),
        FairBlock('하루 한도', [
          '걷기: 100보마다 10 SHARE, 하루 최대 600 SHARE예요.',
          '자유 달리기: 검증을 통과하면 1km당 10 VALUE, 하루 최대 5km·50 VALUE예요.',
        ]),
        FairBlock('조작된 기기 이용 제한', [
          '루팅·탈옥 등으로 변조된 휴대폰은 구글 Play Integrity로 기기와 앱의 '
              '무결성을 확인해요.',
          '무결성 확인 결과는 서버에 기록되고, 조작이 확인되면 공정한 기록을 위해 '
              '그 기기에서 발생한 활동의 적립이 제한될 수 있어요.',
        ]),
        FairBlock('제재 단계와 소명', [
          '1차로는 의심되는 기록만 적립에서 인정하지 않아요.',
          '같은 문제가 반복되면 보상 지급이 제한되거나 계정이 보호 조치(일시 제한)될 수 있어요.',
          '억울한 점이 있다면 언제든 설정 > 보안·프라이버시 센터 > 기록 소명 및 고객센터에서 '
              '이의를 제기할 수 있어요.',
        ]),
        FairBlock('전환 한도', [
          'SHARE는 다이아로만 바꿀 수 있고, 다이아를 SHARE로 되돌릴 수는 없어요.',
          '전환은 일주일에 20 다이아까지, 가입 7일 뒤부터 할 수 있어요.',
          'VALUE는 환전할 수 없어요.',
        ]),
        FairBlock('기부', [
          '검증된 달리기 1km마다 회사(운영자) 자금으로 100원을 기부할 예정이에요.',
          '운영자 기부에는 한 달 한도가 있어요. 한도가 차면 '
              '"이번 달 운영자 기부 예산을 모두 사용했어요"로 알려 드려요.',
        ]),
        FairBlock('기록에 이의가 있다면', [
          '검증되지 않은 기록은 달리기 결과 화면에 이유가 나와요.',
          '결과가 맞지 않다고 생각하면 설정 > 보안·프라이버시 센터 > '
              '기록 소명 및 고객센터에서 알려 주세요.',
        ]),
      ],
    ),
    'en': FairEarningCopy(
      screenTitle: 'Fair earning policy',
      footnote: 'Some figures can change with the server settings.',
      menuTitle: 'Fair earning policy',
      menuSubtitle: 'Checks · daily caps · donation rules',
      settingsSubtitle: 'Fair earning policy · record appeal',
      sections: [
        FairBlock('Basic rules', [
          'The record always stays. Rewards are only for runs the server verified.',
          'SHARE, VALUE, diamonds, and the donation amount on screen are the server’s figures. '
              'They match on every phone you sign in with.',
          'The same run counts once.',
        ]),
        FairBlock('What gets verified', [
          'The distance has to meet the race distance, and at least 1 km.',
          'Running cadence has to stay between 120 and 210 steps per minute.',
          'Without a watch, stride and GPS speed are checked.',
          'Heart rate is required only for advanced, half, and final races.',
        ]),
        FairBlock('Daily caps', [
          'Walking: 10 SHARE per 100 steps, up to 600 SHARE a day.',
          'A free run that passes verification earns 10 VALUE per 1 km, up to 5 km and 50 VALUE a day.',
        ]),
        FairBlock('Modified devices', [
          'A phone modified by rooting or jailbreak is checked with Google Play Integrity.',
          'The result is stored on the server. If tampering is confirmed, earning from activity on that device can be limited.',
        ]),
        FairBlock('Limits and appeals', [
          'The first step leaves only the doubtful record out of earning.',
          'If the same problem repeats, rewards can be limited or the account can be paused.',
          'If that seems wrong, open Settings > Security and privacy > Record appeal and support.',
        ]),
        FairBlock('Exchange cap', [
          'SHARE can be exchanged for diamonds only. Diamonds cannot be turned back into SHARE.',
          'Exchange is up to 20 diamonds a week, starting 7 days after sign-up.',
          'VALUE cannot be cashed out.',
        ]),
        FairBlock('Donation', [
          'For each verified 1 km, 100 KRW is planned to be donated from company (operator) funds.',
          'The operator’s donation has a monthly cap. When it is full, the app says the month’s operator donation budget is used up.',
        ]),
        FairBlock('If a record looks wrong', [
          'A run that did not verify shows the reason on the result screen.',
          'If the result looks wrong, tell us in Settings > Security and privacy > Record appeal and support.',
        ]),
      ],
    ),
    'ja': FairEarningCopy(
      screenTitle: '公正な獲得ポリシー',
      footnote: '一部の数字はサーバー設定で変わることがあります。',
      menuTitle: '公正な獲得ポリシー',
      menuSubtitle: '検証基準 · 1日の上限 · 寄付ルール',
      settingsSubtitle: '公正な獲得ポリシー · 記録の申し立て',
      sections: [
        FairBlock('基本', [
          '記録は残ります。報酬はサーバーが検証した走りだけです。',
          '画面のSHARE・VALUE・ダイヤと寄付額はサーバーが確認した値です。どのスマホでログインしても同じです。',
          '同じ走りは一度だけ認められます。',
        ]),
        FairBlock('検証の基準', [
          '距離は大会の距離以上で、最低1kmです。',
          'ランニングのケイデンスは毎分120〜210歩です。',
          'ウォッチがないときは歩幅とGPS速度で確認します。',
          '心拍が必須なのは上級・ハーフ・ファイナルだけです。',
        ]),
        FairBlock('1日の上限', [
          '歩き: 100歩ごとに10 SHARE、1日最大600 SHAREです。',
          '自由走りは検証を通ると1kmあたり10 VALUE、1日最大5km・50 VALUEです。',
        ]),
        FairBlock('改変された端末', [
          'ルートや脱獄で改変されたスマホはGoogle Play Integrityで端末とアプリを確認します。',
          '結果はサーバーに残ります。改変が確認されると、その端末の活動の獲得が制限されることがあります。',
        ]),
        FairBlock('制限と申し立て', [
          '最初は疑わしい記録だけを獲得の対象から外します。',
          '同じ問題が続くと、報酬が制限されるかアカウントが一時停止されることがあります。',
          '納得できないときは設定 > セキュリティとプライバシー > 記録の申し立てから知らせてください。',
        ]),
        FairBlock('交換の上限', [
          'SHAREはダイヤにだけ換えられます。ダイヤをSHAREに戻すことはできません。',
          '交換は週20ダイヤまで、登録から7日後からです。',
          'VALUEは換金できません。',
        ]),
        FairBlock('寄付', [
          '検証された1kmごとに、会社（運営者）の資金から100ウォンを寄付する予定です。',
          '運営者の寄付には月の上限があります。上限に達すると、その月の運営者寄付予算を使い切ったと知らせます。',
        ]),
        FairBlock('記録に納得できないとき', [
          '検証されなかった記録は結果画面に理由が出ます。',
          '結果が違うと思うときは設定 > セキュリティとプライバシー > 記録の申し立てから知らせてください。',
        ]),
      ],
    ),
    'zh': FairEarningCopy(
      screenTitle: '公平累積說明',
      footnote: '部分數字可能依伺服器設定調整。',
      menuTitle: '公平累積說明',
      menuSubtitle: '驗證標準 · 每日上限 · 捐款規則',
      settingsSubtitle: '公平累積說明 · 紀錄申訴',
      sections: [
        FairBlock('基本原則', [
          '紀錄都會留下。獎勵只給伺服器驗證過的跑步。',
          '畫面上的 SHARE、VALUE、鑽石和捐款金額是伺服器確認的數字。換手機登入也一樣。',
          '同一次跑步只承認一次。',
        ]),
        FairBlock('驗證標準', [
          '距離要達到賽事距離，而且至少 1 公里。',
          '跑步步頻要在每分鐘 120～210 步。',
          '沒有手錶時，用步幅和 GPS 速度確認。',
          '心率只在進階、半程和決賽必填。',
        ]),
        FairBlock('每日上限', [
          '走路：每 100 步 10 SHARE，每天最多 600 SHARE。',
          '通過驗證的自由跑，每 1 公里 10 VALUE，每天最多 5 公里、50 VALUE。',
        ]),
        FairBlock('遭竄改的裝置', [
          '遭 root 或越獄改過的手機，會用 Google Play Integrity 檢查裝置和 App。',
          '結果會記在伺服器。若確認遭到竄改，該裝置上的活動可能無法累積。',
        ]),
        FairBlock('限制與申訴', [
          '第一次只把有疑慮的紀錄排除在累積之外。',
          '同樣的問題若重複，獎勵可能被限制，或帳號被暫時限制。',
          '若覺得不妥，請到設定 > 安全性與隱私 > 紀錄申訴與客服提出。',
        ]),
        FairBlock('兌換上限', [
          'SHARE 只能換成鑽石。鑽石不能換回 SHARE。',
          '兌換每週最多 20 顆鑽石，註冊滿 7 天後才能開始。',
          'VALUE 不能換成現金。',
        ]),
        FairBlock('捐款', [
          '每 1 公里通過驗證的跑步，預計以公司（營運方）資金捐出 100 韓元。',
          '營運方捐款有每月上限。額滿時會告知本月營運方捐款預算已用完。',
        ]),
        FairBlock('若紀錄看起來不對', [
          '未通過驗證的紀錄會在結果畫面顯示原因。',
          '若結果不對，請到設定 > 安全性與隱私 > 紀錄申訴與客服告知。',
        ]),
      ],
    ),
    'es': FairEarningCopy(
      screenTitle: 'Política de ganancias justas',
      footnote:
          'Algunas cifras pueden cambiar con la configuración del servidor.',
      menuTitle: 'Política de ganancias justas',
      menuSubtitle: 'Controles · topes diarios · donación',
      settingsSubtitle: 'Política de ganancias justas · apelación',
      sections: [
        FairBlock('Reglas básicas', [
          'El registro se queda. La recompensa es solo para carreras que el servidor verificó.',
          'SHARE, VALUE, diamantes y el importe de la donación en pantalla son cifras del servidor. Coinciden en cualquier teléfono.',
          'La misma carrera cuenta una vez.',
        ]),
        FairBlock('Qué se verifica', [
          'La distancia tiene que alcanzar la de la carrera, y al menos 1 km.',
          'La cadencia tiene que estar entre 120 y 210 pasos por minuto.',
          'Sin reloj, se miran la zancada y la velocidad GPS.',
          'La frecuencia cardíaca solo es obligatoria en avanzado, medio y final.',
        ]),
        FairBlock('Topes diarios', [
          'Caminar: 10 SHARE por cada 100 pasos, hasta 600 SHARE al día.',
          'Una carrera libre verificada da 10 VALUE por 1 km, hasta 5 km y 50 VALUE al día.',
        ]),
        FairBlock('Dispositivos modificados', [
          'Un teléfono con root o jailbreak se comprueba con Google Play Integrity.',
          'El resultado queda en el servidor. Si hay manipulación, las ganancias de esa actividad pueden limitarse.',
        ]),
        FairBlock('Límites y apelaciones', [
          'El primer paso deja fuera solo el registro dudoso.',
          'Si el problema se repite, las recompensas pueden limitarse o la cuenta pausarse.',
          'Si no estás de acuerdo, entra en Ajustes > Seguridad y privacidad > Apelación del registro.',
        ]),
        FairBlock('Tope de cambio', [
          'SHARE solo se cambia por diamantes. Los diamantes no vuelven a SHARE.',
          'El cambio es de hasta 20 diamantes por semana, desde 7 días después del registro.',
          'VALUE no se puede cobrar en dinero.',
        ]),
        FairBlock('Donación', [
          'Por cada 1 km verificado se prevé donar 100 KRW con fondos de la empresa (operador).',
          'La donación del operador tiene un tope mensual. Al llenarse, la app avisa de que el presupuesto del mes se agotó.',
        ]),
        FairBlock('Si un registro no cuadra', [
          'Una carrera no verificada muestra el motivo en la pantalla de resultado.',
          'Si el resultado no cuadra, avisa en Ajustes > Seguridad y privacidad > Apelación del registro.',
        ]),
      ],
    ),
    'pt': FairEarningCopy(
      screenTitle: 'Política de ganhos justos',
      footnote: 'Alguns números podem mudar com a configuração do servidor.',
      menuTitle: 'Política de ganhos justos',
      menuSubtitle: 'Checagens · limites diários · doação',
      settingsSubtitle: 'Política de ganhos justos · recurso',
      sections: [
        FairBlock('Regras básicas', [
          'O registro fica. A recompensa é só para corridas que o servidor verificou.',
          'SHARE, VALUE, diamantes e o valor da doação na tela são números do servidor. São os mesmos em qualquer telefone.',
          'A mesma corrida conta uma vez.',
        ]),
        FairBlock('O que é verificado', [
          'A distância precisa atingir a da prova, e no mínimo 1 km.',
          'A cadência precisa ficar entre 120 e 210 passos por minuto.',
          'Sem relógio, a passada e a velocidade do GPS são checadas.',
          'A frequência cardíaca só é obrigatória no avançado, no meio e na final.',
        ]),
        FairBlock('Limites diários', [
          'Caminhada: 10 SHARE a cada 100 passos, até 600 SHARE por dia.',
          'Uma corrida livre verificada rende 10 VALUE por 1 km, até 5 km e 50 VALUE por dia.',
        ]),
        FairBlock('Aparelhos modificados', [
          'Um telefone com root ou jailbreak é checado com o Google Play Integrity.',
          'O resultado fica no servidor. Se a alteração for confirmada, os ganhos dessa atividade podem ser limitados.',
        ]),
        FairBlock('Limites e recursos', [
          'No primeiro passo, só o registro duvidoso fica de fora dos ganhos.',
          'Se o problema se repetir, as recompensas podem ser limitadas ou a conta pausada.',
          'Se parecer errado, abra Ajustes > Segurança e privacidade > Recurso do registro.',
        ]),
        FairBlock('Limite de troca', [
          'SHARE só vira diamante. Diamante não volta a SHARE.',
          'A troca é de até 20 diamantes por semana, a partir de 7 dias após o cadastro.',
          'VALUE não pode ser sacado.',
        ]),
        FairBlock('Doação', [
          'A cada 1 km verificado, prevê-se doar 100 KRW com recursos da empresa (operadora).',
          'A doação do operador tem um teto mensal. Quando enche, o app avisa que o orçamento do mês acabou.',
        ]),
        FairBlock('Se um registro parecer errado', [
          'Uma corrida não verificada mostra o motivo na tela de resultado.',
          'Se o resultado não bater, avise em Ajustes > Segurança e privacidade > Recurso do registro.',
        ]),
      ],
    ),
    'de': FairEarningCopy(
      screenTitle: 'Faire Gutschrift',
      footnote: 'Einige Zahlen können sich mit den Servereinstellungen ändern.',
      menuTitle: 'Faire Gutschrift',
      menuSubtitle: 'Prüfung · Tagesgrenzen · Spende',
      settingsSubtitle: 'Faire Gutschrift · Einspruch',
      sections: [
        FairBlock('Grundregeln', [
          'Die Aufzeichnung bleibt. Belohnt wird nur ein Lauf, den der Server geprüft hat.',
          'SHARE, VALUE, Diamanten und der Spendenbetrag auf dem Bildschirm kommen vom Server. Sie sind auf jedem Telefon gleich.',
          'Derselbe Lauf zählt einmal.',
        ]),
        FairBlock('Was geprüft wird', [
          'Die Strecke muss die Renndistanz erreichen, mindestens 1 km.',
          'Die Kadenz muss zwischen 120 und 210 Schritten pro Minute liegen.',
          'Ohne Uhr werden Schrittlänge und GPS-Tempo geprüft.',
          'Die Herzfrequenz ist nur bei Fortgeschritten, Halb und Finale nötig.',
        ]),
        FairBlock('Tagesgrenzen', [
          'Gehen: 10 SHARE je 100 Schritte, höchstens 600 SHARE am Tag.',
          'Ein geprüfter freier Lauf gibt 10 VALUE je 1 km, höchstens 5 km und 50 VALUE am Tag.',
        ]),
        FairBlock('Veränderte Geräte', [
          'Ein gerootetes oder gejailbreaktes Telefon wird mit Google Play Integrity geprüft.',
          'Das Ergebnis liegt auf dem Server. Bei bestätigter Manipulation kann die Gutschrift von diesem Gerät begrenzt werden.',
        ]),
        FairBlock('Grenzen und Einspruch', [
          'Zuerst fällt nur die zweifelhafte Aufzeichnung aus der Gutschrift.',
          'Wiederholt sich das Problem, können Belohnungen begrenzt oder das Konto pausiert werden.',
          'Wenn das falsch wirkt: Einstellungen > Sicherheit und Datenschutz > Einspruch zur Aufzeichnung.',
        ]),
        FairBlock('Tauschgrenze', [
          'SHARE wird nur in Diamanten getauscht. Diamanten werden nicht zurück in SHARE getauscht.',
          'Der Tausch ist bis zu 20 Diamanten pro Woche, ab 7 Tagen nach der Anmeldung.',
          'VALUE kann nicht ausgezahlt werden.',
        ]),
        FairBlock('Spende', [
          'Für jeden geprüften Kilometer sind 100 KRW Spende aus Mitteln des Unternehmens (Betreiber) geplant.',
          'Die Spende des Betreibers hat eine Monatsgrenze. Ist sie voll, sagt die App, dass das Budget des Monats aufgebraucht ist.',
        ]),
        FairBlock('Wenn eine Aufzeichnung nicht stimmt', [
          'Ein nicht geprüfter Lauf zeigt den Grund auf dem Ergebnisbildschirm.',
          'Wenn das Ergebnis nicht stimmt: Einstellungen > Sicherheit und Datenschutz > Einspruch zur Aufzeichnung.',
        ]),
      ],
    ),
    'fr': FairEarningCopy(
      screenTitle: 'Règles de gain équitable',
      footnote:
          'Certains chiffres peuvent changer avec les réglages du serveur.',
      menuTitle: 'Règles de gain équitable',
      menuSubtitle: 'Contrôles · plafonds du jour · don',
      settingsSubtitle: 'Règles de gain équitable · recours',
      sections: [
        FairBlock('Règles de base', [
          'L’enregistrement reste. La récompense ne vaut que pour une course vérifiée par le serveur.',
          'SHARE, VALUE, diamants et le montant du don à l’écran viennent du serveur. Ils sont les mêmes sur chaque téléphone.',
          'La même course ne compte qu’une fois.',
        ]),
        FairBlock('Ce qui est vérifié', [
          'La distance doit atteindre celle de la course, et au moins 1 km.',
          'La cadence doit rester entre 120 et 210 pas par minute.',
          'Sans montre, la foulée et la vitesse GPS sont contrôlées.',
          'La fréquence cardiaque n’est obligatoire qu’en avancé, semi et finale.',
        ]),
        FairBlock('Plafonds du jour', [
          'Marche : 10 SHARE pour 100 pas, jusqu’à 600 SHARE par jour.',
          'Une course libre vérifiée donne 10 VALUE par 1 km, jusqu’à 5 km et 50 VALUE par jour.',
        ]),
        FairBlock('Appareils modifiés', [
          'Un téléphone rooté ou jailbreaké est contrôlé avec Google Play Integrity.',
          'Le résultat est gardé sur le serveur. Si la modification est confirmée, les gains de cette activité peuvent être limités.',
        ]),
        FairBlock('Limites et recours', [
          'La première étape écarte seulement l’enregistrement douteux.',
          'Si le problème se répète, les récompenses peuvent être limitées ou le compte mis en pause.',
          'Si cela semble faux : Réglages > Sécurité et confidentialité > Recours sur l’enregistrement.',
        ]),
        FairBlock('Plafond d’échange', [
          'SHARE ne s’échange que contre des diamants. Les diamants ne redeviennent pas des SHARE.',
          'L’échange va jusqu’à 20 diamants par semaine, à partir de 7 jours après l’inscription.',
          'VALUE ne peut pas être encaissé.',
        ]),
        FairBlock('Don', [
          'Pour chaque kilomètre vérifié, un don de 100 KRW est prévu sur les fonds de l’entreprise (opérateur).',
          'Le don de l’opérateur a un plafond mensuel. Une fois plein, l’app dit que le budget du mois est épuisé.',
        ]),
        FairBlock('Si un enregistrement semble faux', [
          'Une course non vérifiée montre la raison sur l’écran de résultat.',
          'Si le résultat ne va pas : Réglages > Sécurité et confidentialité > Recours sur l’enregistrement.',
        ]),
      ],
    ),
    'vi': FairEarningCopy(
      screenTitle: 'Quy tắc tích lũy công bằng',
      footnote: 'Một số con số có thể đổi theo cài đặt máy chủ.',
      menuTitle: 'Quy tắc tích lũy công bằng',
      menuSubtitle: 'Kiểm tra · hạn mức ngày · quyên góp',
      settingsSubtitle: 'Quy tắc tích lũy công bằng · khiếu nại',
      sections: [
        FairBlock('Nguyên tắc', [
          'Bản ghi luôn được giữ. Phần thưởng chỉ dành cho lần chạy máy chủ đã xác minh.',
          'SHARE, VALUE, kim cương và số tiền quyên góp trên màn hình là số của máy chủ. Đăng nhập điện thoại nào cũng vậy.',
          'Cùng một lần chạy chỉ được tính một lần.',
        ]),
        FairBlock('Tiêu chí xác minh', [
          'Quãng đường phải đạt cự ly giải, và ít nhất 1 km.',
          'Nhịp chạy phải trong khoảng 120–210 bước mỗi phút.',
          'Không có đồng hồ thì kiểm tra sải chân và tốc độ GPS.',
          'Nhịp tim chỉ bắt buộc ở giải nâng cao, bán marathon và chung kết.',
        ]),
        FairBlock('Hạn mức mỗi ngày', [
          'Đi bộ: 10 SHARE mỗi 100 bước, tối đa 600 SHARE một ngày.',
          'Chạy tự do đã xác minh được 10 VALUE mỗi 1 km, tối đa 5 km và 50 VALUE một ngày.',
        ]),
        FairBlock('Máy bị sửa', [
          'Điện thoại root hoặc jailbreak được kiểm bằng Google Play Integrity.',
          'Kết quả được lưu trên máy chủ. Nếu xác nhận bị sửa, tích lũy từ hoạt động trên máy đó có thể bị giới hạn.',
        ]),
        FairBlock('Giới hạn và khiếu nại', [
          'Lần đầu chỉ loại bản ghi đáng ngờ khỏi phần tích lũy.',
          'Nếu lỗi lặp lại, phần thưởng có thể bị giới hạn hoặc tài khoản bị tạm khóa.',
          'Nếu thấy không đúng: Cài đặt > Bảo mật và quyền riêng tư > Khiếu nại bản ghi.',
        ]),
        FairBlock('Hạn mức đổi', [
          'SHARE chỉ đổi được sang kim cương. Kim cương không đổi ngược lại SHARE.',
          'Mỗi tuần đổi tối đa 20 kim cương, bắt đầu sau 7 ngày đăng ký.',
          'VALUE không rút thành tiền.',
        ]),
        FairBlock('Quyên góp', [
          'Mỗi 1 km đã xác minh, dự kiến quyên góp 100 KRW từ ngân sách công ty (đơn vị vận hành).',
          'Khoản quyên góp của đơn vị vận hành có trần mỗi tháng. Khi đầy, ứng dụng báo ngân sách tháng đã hết.',
        ]),
        FairBlock('Nếu bản ghi có vẻ sai', [
          'Lần chạy không được xác minh hiện lý do trên màn hình kết quả.',
          'Nếu kết quả không đúng: Cài đặt > Bảo mật và quyền riêng tư > Khiếu nại bản ghi.',
        ]),
      ],
    ),
    'th': FairEarningCopy(
      screenTitle: 'นโยบายสะสมอย่างเป็นธรรม',
      footnote: 'ตัวเลขบางส่วนอาจเปลี่ยนตามค่าที่เซิร์ฟเวอร์ตั้งไว้',
      menuTitle: 'นโยบายสะสมอย่างเป็นธรรม',
      menuSubtitle: 'เกณฑ์ตรวจ · เพดานรายวัน · การบริจาค',
      settingsSubtitle: 'นโยบายสะสมอย่างเป็นธรรม · อุทธรณ์บันทึก',
      sections: [
        FairBlock('หลักพื้นฐาน', [
          'บันทึกยังอยู่ รางวัลให้เฉพาะการวิ่งที่เซิร์ฟเวอร์ตรวจแล้ว',
          'SHARE, VALUE, เพชร และยอดบริจาคบนหน้าจอเป็นตัวเลขจากเซิร์ฟเวอร์ เข้าสู่ระบบโทรศัพท์เครื่องไหนก็เหมือนกัน',
          'การวิ่งครั้งเดียวกันนับครั้งเดียว',
        ]),
        FairBlock('เกณฑ์ตรวจ', [
          'ระยะต้องถึงระยะของรายการ และอย่างน้อย 1 กม.',
          'เคเดนซ์การวิ่งต้องอยู่ที่ 120–210 ก้าวต่อนาที',
          'ถ้าไม่มีนาฬิกา จะตรวจจากความยาวก้าวและความเร็ว GPS',
          'อัตราหัวใจจำเป็นเฉพาะรายการขั้นสูง ฮาล์ฟ และรอบชิง',
        ]),
        FairBlock('เพดานรายวัน', [
          'เดิน: 100 ก้าวได้ 10 SHARE สูงสุด 600 SHARE ต่อวัน',
          'วิ่งอิสระที่ผ่านการตรวจได้ 10 VALUE ต่อ 1 กม. สูงสุด 5 กม. และ 50 VALUE ต่อวัน',
        ]),
        FairBlock('เครื่องที่ถูกดัดแปลง', [
          'โทรศัพท์ที่รูตหรือเจลเบรกจะถูกตรวจด้วย Google Play Integrity',
          'ผลถูกบันทึกบนเซิร์ฟเวอร์ ถ้ายืนยันว่าถูกดัดแปลง การสะสมจากกิจกรรมบนเครื่องนั้นอาจถูกจำกัด',
        ]),
        FairBlock('ข้อจำกัดและการอุทธรณ์', [
          'ขั้นแรกจะไม่นับเฉพาะบันทึกที่น่าสงสัย',
          'ถ้าปัญหาเดิมซ้ำ รางวัลอาจถูกจำกัดหรือบัญชีถูกพักชั่วคราว',
          'ถ้าเห็นว่าไม่ถูกต้อง ไปที่การตั้งค่า > ความปลอดภัยและความเป็นส่วนตัว > อุทธรณ์บันทึก',
        ]),
        FairBlock('เพดานการแลก', [
          'SHARE แลกเป็นเพชรได้อย่างเดียว เพชรแลกกลับเป็น SHARE ไม่ได้',
          'แลกได้ไม่เกิน 20 เพชรต่อสัปดาห์ เริ่มหลังสมัคร 7 วัน',
          'VALUE แลกเป็นเงินไม่ได้',
        ]),
        FairBlock('การบริจาค', [
          'ทุก 1 กม. ที่ตรวจแล้ว วางแผนบริจาค 100 วอนจากเงินของบริษัท (ผู้ให้บริการ)',
          'การบริจาคของผู้ให้บริการมีเพดานรายเดือน เมื่อเต็ม แอปจะบอกว่างบเดือนนี้ใช้หมดแล้ว',
        ]),
        FairBlock('ถ้าบันทึกดูไม่ตรง', [
          'การวิ่งที่ไม่ผ่านการตรวจจะแสดงเหตุผลบนหน้าผลลัพธ์',
          'ถ้าผลไม่ตรง แจ้งที่การตั้งค่า > ความปลอดภัยและความเป็นส่วนตัว > อุทธรณ์บันทึก',
        ]),
      ],
    ),
    'id': FairEarningCopy(
      screenTitle: 'Kebijakan perolehan yang adil',
      footnote: 'Sebagian angka dapat berubah mengikuti pengaturan server.',
      menuTitle: 'Kebijakan perolehan yang adil',
      menuSubtitle: 'Pemeriksaan · batas harian · donasi',
      settingsSubtitle: 'Kebijakan perolehan yang adil · banding',
      sections: [
        FairBlock('Aturan dasar', [
          'Catatan tetap tersimpan. Hadiah hanya untuk lari yang diverifikasi server.',
          'SHARE, VALUE, berlian, dan jumlah donasi di layar adalah angka server. Sama di ponsel mana pun.',
          'Lari yang sama dihitung sekali.',
        ]),
        FairBlock('Yang diverifikasi', [
          'Jarak harus mencapai jarak lomba, dan minimal 1 km.',
          'Kadens lari harus antara 120 dan 210 langkah per menit.',
          'Tanpa jam, panjang langkah dan kecepatan GPS yang diperiksa.',
          'Detak jantung wajib hanya pada lomba lanjutan, setengah, dan final.',
        ]),
        FairBlock('Batas harian', [
          'Jalan: 10 SHARE tiap 100 langkah, paling banyak 600 SHARE sehari.',
          'Lari bebas yang lolos verifikasi memberi 10 VALUE per 1 km, paling banyak 5 km dan 50 VALUE sehari.',
        ]),
        FairBlock('Perangkat yang diubah', [
          'Ponsel yang di-root atau di-jailbreak diperiksa dengan Google Play Integrity.',
          'Hasilnya tersimpan di server. Jika perubahan terbukti, perolehan dari aktivitas perangkat itu dapat dibatasi.',
        ]),
        FairBlock('Batasan dan banding', [
          'Langkah pertama hanya mengeluarkan catatan yang meragukan dari perolehan.',
          'Jika masalah yang sama berulang, hadiah dapat dibatasi atau akun dijeda.',
          'Jika itu terasa salah: Setelan > Keamanan dan privasi > Banding catatan.',
        ]),
        FairBlock('Batas penukaran', [
          'SHARE hanya ditukar menjadi berlian. Berlian tidak dapat dikembalikan menjadi SHARE.',
          'Penukaran sampai 20 berlian seminggu, mulai 7 hari setelah daftar.',
          'VALUE tidak dapat dicairkan.',
        ]),
        FairBlock('Donasi', [
          'Setiap 1 km terverifikasi direncanakan mendonasikan 100 KRW dari dana perusahaan (penyelenggara).',
          'Donasi operator punya batas bulanan. Saat penuh, aplikasi memberi tahu bahwa anggaran bulan ini habis.',
        ]),
        FairBlock('Jika catatan terasa salah', [
          'Lari yang tidak terverifikasi menampilkan alasannya di layar hasil.',
          'Jika hasilnya tidak pas: Setelan > Keamanan dan privasi > Banding catatan.',
        ]),
      ],
    ),
  };
}

String _row(Map<String, List<String>> rows, String key, String languageCode) {
  final values = rows[key];
  if (values == null || values.isEmpty) return '';
  final index = surfaceLanguageOrder.indexOf(languageCode);
  if (index < 0 || index >= values.length) return values[1];
  return values[index];
}

String _fill(String pattern, Map<String, String> slots) {
  var text = pattern;
  for (final slot in slots.entries) {
    text = text.replaceAll('{${slot.key}}', slot.value);
  }
  return text;
}

const shopChromeRows = <String, List<String>>{
  'tabRecommended': [
    '추천',
    'For you',
    'おすすめ',
    '推薦',
    'Para ti',
    'Para você',
    'Für dich',
    'Pour vous',
    'Gợi ý',
    'แนะนำ',
    'Untukmu',
  ],
  'tabDiamond': [
    '다이아',
    'Diamonds',
    'ダイヤ',
    '鑽石',
    'Diamantes',
    'Diamantes',
    'Diamanten',
    'Diamants',
    'Kim cương',
    'เพชร',
    'Berlian',
  ],
  'tabItems': [
    '아이템',
    'Items',
    'アイテム',
    '道具',
    'Objetos',
    'Itens',
    'Gegenstände',
    'Objets',
    'Vật phẩm',
    'ไอเท็ม',
    'Item',
  ],
  'tabCosmetics': [
    '꾸미기',
    'Look',
    'きせかえ',
    '造型',
    'Estilo',
    'Visual',
    'Look',
    'Style',
    'Diện mạo',
    'สไตล์',
    'Gaya',
  ],
  'seeAll': [
    '전체 보기',
    'See all',
    'すべて見る',
    '看全部',
    'Ver todo',
    'Ver tudo',
    'Alle anzeigen',
    'Tout voir',
    'Xem tất cả',
    'ดูทั้งหมด',
    'Lihat semua',
  ],
  'diaTopUp': [
    '다이아 충전',
    'Top up DIA',
    'ダイヤをチャージ',
    '儲值鑽石',
    'Recargar DIA',
    'Recarregar DIA',
    'DIA aufladen',
    'Recharger des DIA',
    'Nạp DIA',
    'เติม DIA',
    'Isi DIA',
  ],
  'runningItems': [
    '러닝 아이템',
    'Run items',
    'ランニングアイテム',
    '跑步道具',
    'Objetos de carrera',
    'Itens de corrida',
    'Lauf-Items',
    'Objets de course',
    'Vật phẩm chạy',
    'ไอเท็มวิ่ง',
    'Item lari',
  ],
  'battlePassSection': [
    '배틀런 패스',
    'Battle Run Pass',
    'バトルランパス',
    '戰鬥跑通行證',
    'Pase Battle Run',
    'Passe Battle Run',
    'Battle-Run-Pass',
    'Pass Battle Run',
    'Thẻ Battle Run',
    'บัตร Battle Run',
    'Pas Battle Run',
  ],
  'battlePassTitle': [
    '배틀런 챌린지 패스',
    'Battle Run challenge pass',
    'バトルランチャレンジパス',
    '戰鬥跑挑戰通行證',
    'Pase del desafío Battle Run',
    'Passe do desafio Battle Run',
    'Battle-Run-Challenge-Pass',
    'Pass du défi Battle Run',
    'Thẻ thử thách Battle Run',
    'บัตรชาเลนจ์ Battle Run',
    'Pas tantangan Battle Run',
  ],
  'battlePassSubtitle': [
    '시즌 보상 · 패스+',
    'Season rewards · Pass+',
    'シーズン報酬 · パス+',
    '賽季獎勵 · 通行證+',
    'Recompensas de temporada · Pase+',
    'Recompensas da temporada · Passe+',
    'Saisonbelohnungen · Pass+',
    'Récompenses de saison · Pass+',
    'Thưởng mùa · Thẻ+',
    'รางวัลซีซัน · พาส+',
    'Hadiah musim · Pas+',
  ],
  'cosmetics': [
    '꾸미기',
    'Looks',
    'きせかえ',
    '造型',
    'Estilos',
    'Visuais',
    'Looks',
    'Styles',
    'Diện mạo',
    'สไตล์',
    'Gaya',
  ],
  'donationFunding': [
    '기부 펀딩',
    'Donation funding',
    '寄付ファンディング',
    '捐款募資',
    'Financiación del donativo',
    'Financiamento da doação',
    'Spendenfinanzierung',
    'Financement du don',
    'Gây quỹ quyên góp',
    'ระดมทุนบริจาค',
    'Pendanaan donasi',
  ],
  'popular': [
    '인기',
    'Hot',
    '人気',
    '熱門',
    'Popular',
    'Popular',
    'Beliebt',
    'Populaire',
    'Phổ biến',
    'ยอดนิยม',
    'Populer',
  ],
  'preparing': [
    '준비 중',
    'Not open yet',
    '準備中',
    '準備中',
    'Aún no',
    'Em breve',
    'Noch nicht offen',
    'Pas encore ouvert',
    'Chưa mở',
    'ยังไม่เปิด',
    'Belum dibuka',
  ],
  'bonus': [
    '+{n} 보너스',
    '+{n} bonus',
    '+{n}ボーナス',
    '+{n} 獎勵',
    '+{n} extra',
    '+{n} bônus',
    '+{n} Bonus',
    '+{n} bonus',
    '+{n} thưởng',
    '+{n} โบนัส',
    '+{n} bonus',
  ],
  'packsClosed': [
    'Play 상품이 열리면 구매할 수 있어요. 지금은 결제해도 DIA가 지급되지 않아요.',
    'You can buy these when Play products open. Paying now does not grant DIA.',
    'Playの商品が開いてから購入できます。今支払ってもDIAは付与されません。',
    'Play 商品開放後才能購買。現在付款也不會發放 DIA。',
    'Podrás comprarlos cuando se abran los productos de Play. Pagar ahora no da DIA.',
    'Dá para comprar quando os produtos Play abrirem. Pagar agora não entrega DIA.',
    'Kauf ist möglich, wenn Play-Produkte offen sind. Zahlen gibt jetzt kein DIA.',
    'L’achat ouvrira avec les produits Play. Payer maintenant ne donne pas de DIA.',
    'Mua được khi sản phẩm Play mở. Thanh toán lúc này không nhận DIA.',
    'ซื้อได้เมื่อสินค้า Play เปิด จ่ายตอนนี้ไม่ได้รับ DIA',
    'Bisa dibeli saat produk Play dibuka. Membayar sekarang tidak memberi DIA.',
  ],
  'shareExchange': [
    'SHARE로 교환',
    'Exchange SHARE',
    'SHAREと交換',
    '用 SHARE 兌換',
    'Canjear SHARE',
    'Trocar SHARE',
    'SHARE eintauschen',
    'Échanger des SHARE',
    'Đổi SHARE',
    'แลก SHARE',
    'Tukar SHARE',
  ],
  'shareToDia': [
    'SHARE를 DIA로',
    'SHARE to DIA',
    'SHAREをDIAに',
    '將 SHARE 換成 DIA',
    'SHARE a DIA',
    'SHARE para DIA',
    'SHARE zu DIA',
    'SHARE vers DIA',
    'SHARE sang DIA',
    'SHARE เป็น DIA',
    'SHARE ke DIA',
  ],
  'shareToDiaNote': [
    '1,200 SHARE = 1 DIA · 주간 한도 안에서 교환',
    '1,200 SHARE = 1 DIA · inside the weekly cap',
    '1,200 SHARE = 1 DIA · 週間上限の中で交換',
    '1,200 SHARE = 1 DIA · 在每週上限內兌換',
    '1,200 SHARE = 1 DIA · dentro del tope semanal',
    '1,200 SHARE = 1 DIA · dentro do limite semanal',
    '1,200 SHARE = 1 DIA · innerhalb der Wochengrenze',
    '1,200 SHARE = 1 DIA · dans le plafond de la semaine',
    '1,200 SHARE = 1 DIA · trong hạn mức tuần',
    '1,200 SHARE = 1 DIA · ภายในเพดานรายสัปดาห์',
    '1,200 SHARE = 1 DIA · di dalam batas mingguan',
  ],
  'keepRecord': [
    '기록 지키기',
    'Keep the record',
    '記録を守る',
    '保住紀錄',
    'Cuida tu marca',
    'Proteja sua marca',
    'Rekord sichern',
    'Garder le record',
    'Giữ thành tích',
    'รักษาสถิติ',
    'Jaga catatan',
  ],
  'runTogether': [
    '같이 달리기',
    'Run together',
    '一緒に走る',
    '一起跑',
    'Correr juntos',
    'Correr juntos',
    'Zusammen laufen',
    'Courir ensemble',
    'Chạy cùng nhau',
    'วิ่งด้วยกัน',
    'Lari bersama',
  ],
  'ghostPack': [
    '10회 묶음 {n}',
    '10-pack {n}',
    '10回セット {n}',
    '10次組合 {n}',
    'Pack de 10 {n}',
    'Pacote de 10 {n}',
    '10er-Pack {n}',
    'Lot de 10 {n}',
    'Gói 10 lần {n}',
    'แพ็ก 10 ครั้ง {n}',
    'Paket 10 kali {n}',
  ],
  'tournament': [
    '대회',
    'Races',
    '大会',
    '賽事',
    'Carreras',
    'Provas',
    'Rennen',
    'Courses',
    'Giải chạy',
    'รายการแข่ง',
    'Lomba',
  ],
  'entryPack': [
    '3장 묶음 {n}',
    '3-pack {n}',
    '3枚セット {n}',
    '3張組合 {n}',
    'Pack de 3 {n}',
    'Pacote de 3 {n}',
    '3er-Pack {n}',
    'Lot de 3 {n}',
    'Gói 3 vé {n}',
    'แพ็ก 3 ใบ {n}',
    'Paket 3 lembar {n}',
  ],
  'view': [
    '보기',
    'View',
    '見る',
    '查看',
    'Ver',
    'Ver',
    'Ansehen',
    'Voir',
    'Xem',
    'ดู',
    'Lihat',
  ],
  'earnBySteps': [
    '걸음으로 얻기',
    'Earn with steps',
    '歩数で得る',
    '用步數獲得',
    'Gana con pasos',
    'Ganhe com passos',
    'Mit Schritten verdienen',
    'Gagner avec les pas',
    'Nhận bằng bước chân',
    'ได้จากก้าว',
    'Dapat dari langkah',
  ],
  'confirm': [
    '확인',
    'OK',
    '確認',
    '確定',
    'Aceptar',
    'OK',
    'OK',
    'OK',
    'OK',
    'ตกลง',
    'OK',
  ],
  'alreadyValue': [
    '이미 처리된 구매입니다. VALUE는 한 번만 차감됩니다.',
    'This purchase was already processed. VALUE is charged once.',
    'すでに処理された購入です。VALUEは一度だけ引かれます。',
    '這筆購買已經處理。VALUE 只扣一次。',
    'Esta compra ya se procesó. VALUE se cobra una vez.',
    'Esta compra já foi processada. VALUE é cobrado uma vez.',
    'Dieser Kauf ist schon verarbeitet. VALUE wird einmal abgezogen.',
    'Cet achat est déjà traité. VALUE n’est débité qu’une fois.',
    'Giao dịch này đã được xử lý. VALUE chỉ trừ một lần.',
    'การซื้อนี้ดำเนินการแล้ว VALUE ถูกหักครั้งเดียว',
    'Pembelian ini sudah diproses. VALUE dipotong sekali.',
  ],
  'alreadyShare': [
    '이미 처리된 구매입니다. SHARE는 한 번만 차감됩니다.',
    'This purchase was already processed. SHARE is charged once.',
    'すでに処理された購入です。SHAREは一度だけ引かれます。',
    '這筆購買已經處理。SHARE 只扣一次。',
    'Esta compra ya se procesó. SHARE se cobra una vez.',
    'Esta compra já foi processada. SHARE é cobrado uma vez.',
    'Dieser Kauf ist schon verarbeitet. SHARE wird einmal abgezogen.',
    'Cet achat est déjà traité. SHARE n’est débité qu’une fois.',
    'Giao dịch này đã được xử lý. SHARE chỉ trừ một lần.',
    'การซื้อนี้ดำเนินการแล้ว SHARE ถูกหักครั้งเดียว',
    'Pembelian ini sudah diproses. SHARE dipotong sekali.',
  ],
  'alreadyDia': [
    '이미 처리된 구매입니다. DIA는 한 번만 차감됩니다.',
    'This purchase was already processed. DIA is charged once.',
    'すでに処理された購入です。DIAは一度だけ引かれます。',
    '這筆購買已經處理。DIA 只扣一次。',
    'Esta compra ya se procesó. DIA se cobra una vez.',
    'Esta compra já foi processada. DIA é cobrado uma vez.',
    'Dieser Kauf ist schon verarbeitet. DIA wird einmal abgezogen.',
    'Cet achat est déjà traité. DIA n’est débité qu’une fois.',
    'Giao dịch này đã được xử lý. DIA chỉ trừ một lần.',
    'การซื้อนี้ดำเนินการแล้ว DIA ถูกหักครั้งเดียว',
    'Pembelian ini sudah diproses. DIA dipotong sekali.',
  ],
  'donationMatchDone': [
    '기부 매칭을 기록했습니다. 운영자 명의 기부에 내 이름이 함께 표시됩니다.',
    'Donation match recorded. Your name is shown with the operator’s donation.',
    '寄付マッチングを記録しました。運営者名義の寄付にあなたの名前も表示されます。',
    '已記錄捐款配對。你的名字會和營運方名義的捐款一起顯示。',
    'Emparejamiento de donación registrado. Tu nombre aparece con la donación del operador.',
    'A correspondência de doação foi registrada. Seu nome aparece com a doação do operador.',
    'Spenden-Matching ist notiert. Dein Name steht bei der Spende des Betreibers.',
    'Le matching du don est noté. Votre nom apparaît avec le don de l’opérateur.',
    'Đã ghi nhận ghép quyên góp. Tên của bạn hiện cùng khoản quyên góp của đơn vị vận hành.',
    'บันทึกการจับคู่บริจาคแล้ว ชื่อของคุณแสดงคู่กับการบริจาคในนามผู้ให้บริการ',
    'Pencocokan donasi tercatat. Namamu tampil bersama donasi atas nama operator.',
  ],
  'bought': [
    '{name}을 구매했습니다.',
    'Purchased {name}.',
    '{name}を購入しました。',
    '已購買{name}。',
    'Compraste {name}.',
    'Você comprou {name}.',
    '{name} gekauft.',
    '{name} acheté.',
    'Đã mua {name}.',
    'ซื้อ {name} แล้ว',
    '{name} dibeli.',
  ],
  'buyFailed': [
    '{name}을 구매하지 못했습니다.',
    'Could not purchase {name}.',
    '{name}を購入できませんでした。',
    '無法購買{name}。',
    'No se pudo comprar {name}.',
    'Não foi possível comprar {name}.',
    '{name} konnte nicht gekauft werden.',
    'Achat de {name} impossible.',
    'Không mua được {name}.',
    'ซื้อ {name} ไม่สำเร็จ',
    'Tidak bisa membeli {name}.',
  ],
  'diaShort': [
    'DIA가 부족합니다. 상점에서 구매해 주세요.',
    'Not enough DIA. Buy more in the shop.',
    'DIAが足りません。ショップで購入してください。',
    'DIA 不足。請到商店購買。',
    'No hay suficiente DIA. Cómpralo en la tienda.',
    'DIA insuficiente. Compre na loja.',
    'Nicht genug DIA. Kauf sie im Shop.',
    'Pas assez de DIA. Achetez-en dans la boutique.',
    'Không đủ DIA. Hãy mua ở cửa hàng.',
    'DIA ไม่พอ ซื้อได้ที่ร้าน',
    'DIA tidak cukup. Beli di toko.',
  ],
};

class ShopChrome {
  const ShopChrome._(this.languageCode);

  final String languageCode;

  static ShopChrome of(Locale locale) {
    final code = surfaceLanguageOrder.contains(locale.languageCode)
        ? locale.languageCode
        : 'en';
    return ShopChrome._(code);
  }

  String _at(String key) => _row(shopChromeRows, key, languageCode);

  String get tabRecommended => _at('tabRecommended');
  String get tabDiamond => _at('tabDiamond');
  String get tabItems => _at('tabItems');
  String get tabCosmetics => _at('tabCosmetics');
  String get seeAll => _at('seeAll');
  String get diaTopUp => _at('diaTopUp');
  String get runningItems => _at('runningItems');
  String get battlePassSection => _at('battlePassSection');
  String get battlePassTitle => _at('battlePassTitle');
  String get battlePassSubtitle => _at('battlePassSubtitle');
  String get cosmetics => _at('cosmetics');
  String get donationFunding => _at('donationFunding');
  String get popular => _at('popular');
  String get preparing => _at('preparing');
  String get packsClosed => _at('packsClosed');
  String get shareExchange => _at('shareExchange');
  String get shareToDia => _at('shareToDia');
  String get shareToDiaNote => _at('shareToDiaNote');
  String get keepRecord => _at('keepRecord');
  String get runTogether => _at('runTogether');
  String get tournament => _at('tournament');
  String get view => _at('view');
  String get earnBySteps => _at('earnBySteps');
  String get confirm => _at('confirm');
  String get alreadyValue => _at('alreadyValue');
  String get alreadyShare => _at('alreadyShare');
  String get alreadyDia => _at('alreadyDia');
  String get donationMatchDone => _at('donationMatchDone');
  String get diaShort => _at('diaShort');

  String bonus(int amount) => _fill(_at('bonus'), {'n': '$amount'});
  String ghostPack(int cost) => _fill(_at('ghostPack'), {'n': '$cost'});
  String entryPack(int cost) => _fill(_at('entryPack'), {'n': '$cost'});
  String bought(String name) => _fill(_at('bought'), {'name': name});
  String buyFailed(String name) => _fill(_at('buyFailed'), {'name': name});
}

const gradeGuideRows = <String, List<String>>{
  'title': [
    '등급 배정',
    'Grade',
    'グレード',
    '等級',
    'Grado',
    'Grau',
    'Stufe',
    'Grade',
    'Hạng',
    'ระดับ',
    'Tingkat',
  ],
  'intro': [
    '첫 인증 1km를 마치면 거북이 브론즈로 시작합니다. '
        '그 다음은 기록이 쌓인 날마다 한 칸씩만 움직입니다.',
    'Your first verified 1 km starts you at turtle bronze. '
        'After that you move one step on each day that adds a record.',
    '検証された最初の1kmでカメのブロンズから始まります。'
        'その後は記録が積み上がった日に一段階だけ動きます。',
    '完成第一次通過驗證的 1 公里後，從烏龜銅牌開始。之後每個有紀錄的日子只移動一階。',
    'El primer kilómetro verificado empieza en tortuga bronce. '
        'Después avanzas un escalón cada día que suma un registro.',
    'O primeiro 1 km verificado começa na tartaruga bronze. '
        'Depois você anda um degrau em cada dia que soma um registro.',
    'Der erste geprüfte Kilometer startet bei Schildkröte Bronze. '
        'Danach rückst du an jedem Tag mit einem neuen Eintrag eine Stufe vor.',
    'Le premier kilomètre vérifié commence à tortue bronze. '
        'Ensuite vous avancez d’un cran chaque jour qui ajoute un enregistrement.',
    '1 km được xác minh đầu tiên bắt đầu ở rùa đồng. '
        'Sau đó mỗi ngày có thêm bản ghi chỉ tiến một bậc.',
    '1 กม. ที่ตรวจแล้วครั้งแรกเริ่มที่เต่าบรอนซ์ จากนั้นแต่ละวันที่มีบันทึกจะขยับทีละขั้น',
    '1 km terverifikasi pertama mulai dari kura-kura perunggu. '
        'Setelah itu kamu naik satu tingkat pada setiap hari yang menambah catatan.',
  ],
  'progress': [
    '아직 등급이 없어요. 첫 인증 1km를 달리면 시작해요',
    'No grade yet. It starts after your first verified 1 km',
    'まだグレードはありません。初回の認証1kmを走ると始まります',
    '尚無等級。完成首次認證 1km 後開始',
    'Aún sin grado. Empieza tras tu primer 1 km verificado',
    'Ainda sem grau. Começa após o primeiro 1 km verificado',
    'Noch keine Stufe. Sie beginnt nach dem ersten verifizierten 1 km',
    'Pas encore de grade. Il démarre après votre premier 1 km vérifié',
    'Chưa có hạng. Hạng bắt đầu sau 1km đầu tiên được xác thực',
    'ยังไม่มีระดับ จะเริ่มหลังวิ่งที่ยืนยันแล้ว 1 กม. ครั้งแรก',
    'Belum ada tingkat. Dimulai setelah 1 km terverifikasi pertama',
  ],
  'assigned': [
    '배정된 등급: {name}',
    'Assigned grade: {name}',
    '割り当てられたグレード: {name}',
    '已分配等級：{name}',
    'Grado asignado: {name}',
    'Grau atribuído: {name}',
    'Zugewiesene Stufe: {name}',
    'Grade attribué : {name}',
    'Hạng đã gán: {name}',
    'ระดับที่กำหนด: {name}',
    'Tingkat yang ditetapkan: {name}',
  ],
  'sameDay': [
    '기록은 서버에서 확인된 뒤에 반영돼요. 같은 날 달린 기록은 하루로 세요.',
    'Records count after the server confirms them. Runs on the same day count as one day.',
    '記録はサーバーが確認してから反映されます。同じ日の走りは1日として数えます。',
    '紀錄在伺服器確認後才會計入。同一天的跑步算一天。',
    'Los registros cuentan cuando el servidor los confirma. Las carreras del mismo día cuentan como un día.',
    'Os registros contam depois que o servidor os confirma. Corridas no mesmo dia contam como um dia.',
    'Einträge zählen, sobald der Server sie bestätigt hat. Läufe am selben Tag zählen als ein Tag.',
    'Les enregistrements comptent une fois confirmés par le serveur. Les courses du même jour comptent pour un jour.',
    'Bản ghi được tính sau khi máy chủ xác nhận. Các lần chạy trong cùng một ngày tính là một ngày.',
    'บันทึกจะนับหลังเซิร์ฟเวอร์ยืนยัน การวิ่งในวันเดียวกันนับเป็นหนึ่งวัน',
    'Catatan dihitung setelah server mengonfirmasi. Lari di hari yang sama dihitung satu hari.',
  ],
  'skipNote': [
    '등급은 홈에서 달리면서 정해져요. 지금 건너뛰어도 괜찮아요.',
    'Your grade is set by running from Home. Skipping now is fine.',
    'グレードはホームから走ると決まります。今は飛ばしても大丈夫です。',
    '等級會在首頁跑步時決定。現在先跳過也可以。',
    'El grado se decide corriendo desde Inicio. Puedes saltarlo ahora.',
    'O grau é definido correndo a partir do Início. Pular agora não tem problema.',
    'Die Stufe entsteht beim Laufen von der Startseite. Überspringen ist in Ordnung.',
    'Le grade se décide en courant depuis l’accueil. Vous pouvez passer pour l’instant.',
    'Hạng được quyết khi chạy từ Trang chủ. Bỏ qua lúc này cũng được.',
    'ระดับถูกกำหนดเมื่อวิ่งจากหน้าแรก ข้ามตอนนี้ได้',
    'Tingkat ditentukan dengan lari dari Beranda. Melewatinya sekarang tidak apa-apa.',
  ],
  'startRun': [
    '달리기 시작하기',
    'Start a run',
    '走り始める',
    '開始跑步',
    'Empezar a correr',
    'Começar a correr',
    'Lauf starten',
    'Commencer à courir',
    'Bắt đầu chạy',
    'เริ่มวิ่ง',
    'Mulai lari',
  ],
  'goHome': [
    '홈으로 가기',
    'Go to Home',
    'ホームへ',
    '前往首頁',
    'Ir al inicio',
    'Ir para o início',
    'Zur Startseite',
    'Aller à l’accueil',
    'Về trang chủ',
    'ไปหน้าแรก',
    'Ke Beranda',
  ],
  'homeEntry': [
    '등급 안내',
    'About grades',
    'グレードの案内',
    '等級說明',
    'Sobre los grados',
    'Sobre os graus',
    'Infos zu Stufen',
    'À propos des grades',
    'Giới thiệu về hạng',
    'เกี่ยวกับระดับ',
    'Tentang tingkat',
  ],
};

class GradeGuide {
  const GradeGuide._(this.languageCode);

  final String languageCode;

  static GradeGuide of(Locale locale) {
    final code = surfaceLanguageOrder.contains(locale.languageCode)
        ? locale.languageCode
        : 'en';
    return GradeGuide._(code);
  }

  String _at(String key) => _row(gradeGuideRows, key, languageCode);

  String get title => _at('title');
  String get intro => _at('intro');
  String get sameDay => _at('sameDay');
  String get skipNote => _at('skipNote');
  String get startRun => _at('startRun');
  String get goHome => _at('goHome');

  String get progress => _at('progress');

  String assigned(String name) => _fill(_at('assigned'), {'name': name});

  String get homeEntry => _at('homeEntry');
}

/// Empty when fair-earning, shop chrome, and grade guide exist in all 11 locales.
List<String> missingSurfaceKeys() {
  final missing = <String>[];
  final koreanFair = FairEarningCopy.byLanguage['ko']!;
  for (final locale in ShareRunLocalizations.supportedLocales) {
    final code = locale.languageCode;
    final tag = '${locale.languageCode}-${locale.countryCode}';
    final fair = FairEarningCopy.byLanguage[code];
    if (fair == null) {
      missing.add('$tag.fair');
      continue;
    }
    final fairFields = <String, String>{
      'screenTitle': fair.screenTitle,
      'footnote': fair.footnote,
      'menuTitle': fair.menuTitle,
      'menuSubtitle': fair.menuSubtitle,
      'settingsSubtitle': fair.settingsSubtitle,
    };
    final koreanFields = <String, String>{
      'screenTitle': koreanFair.screenTitle,
      'footnote': koreanFair.footnote,
      'menuTitle': koreanFair.menuTitle,
      'menuSubtitle': koreanFair.menuSubtitle,
      'settingsSubtitle': koreanFair.settingsSubtitle,
    };
    for (final field in fairFields.entries) {
      if (field.value.trim().isEmpty) missing.add('$tag.fair.${field.key}');
      if (code != 'ko' && field.value == koreanFields[field.key]) {
        missing.add('$tag.fair.${field.key}=ko');
      }
    }
    if (fair.sections.length != koreanFair.sections.length) {
      missing.add('$tag.fair.sections');
    } else {
      for (var index = 0; index < fair.sections.length; index++) {
        final block = fair.sections[index];
        final korean = koreanFair.sections[index];
        if (block.title.trim().isEmpty) missing.add('$tag.fair.section$index');
        if (code != 'ko' && block.title == korean.title) {
          missing.add('$tag.fair.section$index=ko');
        }
        if (block.lines.length != korean.lines.length) {
          missing.add('$tag.fair.section$index.lines');
          continue;
        }
        for (var line = 0; line < block.lines.length; line++) {
          if (block.lines[line].trim().isEmpty) {
            missing.add('$tag.fair.section$index.$line');
          }
          if (code != 'ko' && block.lines[line] == korean.lines[line]) {
            missing.add('$tag.fair.section$index.$line=ko');
          }
        }
      }
    }
    if (!surfaceLanguageOrder.contains(code)) {
      missing.add('$tag.surface');
      continue;
    }
    for (final table in [shopChromeRows, gradeGuideRows]) {
      final name = identical(table, shopChromeRows) ? 'shopChrome' : 'grade';
      for (final entry in table.entries) {
        if (entry.value.length != surfaceLanguageOrder.length) {
          missing.add('$tag.$name.${entry.key}.length');
          continue;
        }
        final value = _row(table, entry.key, code);
        if (value.trim().isEmpty) missing.add('$tag.$name.${entry.key}');
        if (code != 'ko' && value == entry.value.first) {
          missing.add('$tag.$name.${entry.key}=ko');
        }
      }
    }
  }
  missing.addAll(missingRestSurfaceKeys(ShareRunLocalizations.supportedLocales));
  return missing;
}
