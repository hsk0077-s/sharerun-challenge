# 번역 검수 요청 — 쉐어런 (German) · 파트 4/8

아래는 한국어 앱 "쉐어런"(걷기·달리기 앱, 회사 자금 기부 연계)의 화면 문구를 German(으)로 번역한 것입니다.
원어민 시각에서 검수해 주세요.

검수 기준:
1. 오역과 누락
2. 어색하거나 그 나라에서 쓰지 않는 표현
3. 한국어에 없는 약속·단정이 들어간 곳 (특히 기부, 보상, 환불, 탈퇴 관련)
4. 숫자·금액·고유명사가 원문과 다른 곳
5. "운영자(회사 또는 운영 주체)"를 그 나라에서 오해 없는 말로 옮겼는지

지켜야 할 것:
- SHARE, DIA, VALUE, Coach+, ShareRun은 번역하지 않습니다.
- `${...}`, `{...}` 같은 자리표시자는 그대로 두어야 합니다.
- 기부는 "이미 했다"가 아니라 "할 예정"이라는 뜻이어야 합니다.
- 앱 화면 문구이므로 짧고 친절하게.

출력 형식 (문제가 있는 항목만, 표로):
| ID | 원문(한국어) | 현재 번역 | 문제 | 고친 문장 |
문제가 없는 항목은 적지 말고, 마지막에 "문제 없음: N개"라고만 적어 주세요.

---
[main_shell_routes.button]
KO: 대회 목록으로
DE: Zur Wettbewerbsliste

[map_crew.body]
KO: 지도 & 크루
DE: Karte & crew

[map_crew.body.2]
KO: 크루 종합 랭킹
DE: Gesamtes crew-Ranking

[map_crew.body.3]
KO: ${crews[index].memberCount}명
DE: ${crews[index].memberCount} Mitglieder

[map_crew.body.4]
KO: 아직 크루 순위가 없어요
DE: Noch keine crew-Rangliste vorhanden

[map_crew.body.5]
KO: 크루 순위가 쌓이면 여기에 나타나요.
DE: Die crew-Rangliste wird hier angezeigt, sobald Verläufe vorliegen.

[map_crew.body.6]
KO: ${collectRadiusMeters.round()}m 안으로 가까이 가야 받을 수 있어요.
DE: Sie müssen sich bis auf ${collectRadiusMeters.round()}m nähern, um es zu erhalten.

[map_crew.body.7]
KO: +${box.rewardDiamond} DIA를 받았어요.
DE: +${box.rewardDiamond} DIA erhalten.

[map_crew.body.8]
KO: ${distanceMeters!.toStringAsFixed(0)}m 떨어져 있어요
DE: ${distanceMeters!.toStringAsFixed(0)}m entfernt

[map_crew.button]
KO: 내 위치 새로고침
DE: Standort aktualisieren

[map_crew.button.2]
KO: 다이아 상자 받기
DE: DIA-Box abholen

[map_crew.button.3]
KO: 더 가까이 가 주세요
DE: Bitte näher herangehen

[map_crew.crew_member_ranking_board.body]
KO: 크루원 랭킹 데이터 없음
DE: Keine Ranglistendaten der Crew-Mitglieder

[map_crew.crew_member_ranking_board.body.2]
KO: 출석률·평균 페이스가 여기에 표시됩니다.
DE: Anwesenheitsquote und durchschnittliche Pace werden hier angezeigt.

[map_crew.crew_member_ranking_board.body.3]
KO: 크루원 출석률 & 평균 페이스
DE: Crew-Mitglieder Anwesenheit & durchschnittliche Pace

[map_crew.crew_member_ranking_board.body.4]
KO: 출석률 높은 순 · 페이스 빠른 순으로 B2B 크루 성과를 추적합니다.
DE: Verfolgen Sie die B2B-Crew-Leistung nach höchster Anwesenheitsquote und schnellster Pace.

[map_crew.crew_member_ranking_board.body.5]
KO: 출석 ${member.attendanceRate.toStringAsFixed(0)}%
DE: Anwesenheit ${member.attendanceRate.toStringAsFixed(0)}%

[map_crew.safe_map_panel.body]
KO: 지도 준비 중
DE: Karte wird vorbereitet

[mini_bot.body]
KO: 궁금한 게 있으면 저를 눌러 물어보세요
DE: Tippen Sie mich an, wenn Sie Fragen haben

[mini_bot.body.10]
KO: 하루 SHARE 한도
DE: Tägliches SHARE-Limit

[mini_bot.body.11]
KO: 어떤 대회?
DE: Welcher Wettbewerb?

[mini_bot.body.12]
KO: 순위별 상금
DE: Preise nach Rang

[mini_bot.body.13]
KO: 초급은 무료?
DE: Ist Anfänger kostenlos?

[mini_bot.body.14]
KO: SHARE잔액
DE: SHARE-Guthaben

[mini_bot.body.15]
KO: VALUE잔액
DE: VALUE-Guthaben

[mini_bot.body.16]
KO: 등급
DE: Rang

[mini_bot.body.17]
KO: 오늘기부기여
DE: Heutiger Spendenbeitrag

[mini_bot.body.18]
KO: 이 버전에서는 앱 안에서 결제하지 않아요.
DE: In dieser Version werden keine In-App-Zahlungen durchgeführt.

[mini_bot.body.19]
KO: 궁금한 걸 물어보세요
DE: Fragen Sie einfach, was Sie wissen möchten

[mini_bot.body.2]
KO: 오늘 목표나 SHARE가 궁금하면 물어보세요
DE: Fragen Sie mich nach den heutigen Zielen oder zu SHARE

[mini_bot.body.3]
KO: 기록 지키기가 헷갈리면 제가 알려 드려요
DE: Wenn Sie unsicher sind, wie Sie Ihre Rekorde schützen, helfe ich Ihnen gerne.

[mini_bot.body.4]
KO: 어떤 챌린지가 맞는지 모르겠으면 물어보세요
DE: Fragen Sie mich, wenn Sie nicht sicher sind, welche Challenge zu Ihnen passt

[mini_bot.body.5]
KO: 참가비와 순위별 상금이 궁금하면 눌러 보세요
DE: Tippen Sie hier, wenn Sie mehr über Teilnahmegebühren und Preisgelder nach Rang erfahren möchten

[mini_bot.body.6]
KO: 초급은 무료인지도 알려 드려요
DE: Ich kann Ihnen auch sagen, ob das Anfängerlevel kostenlos ist

[mini_bot.body.7]
KO: 오늘 내 기부
DE: Meine heutigen Spenden

[mini_bot.body.8]
KO: 내 SHARE
DE: Mein SHARE

[mini_bot.body.9]
KO: 내 등급
DE: Mein Rang

[mini_bot.button]
KO: 멈추기
DE: Stopp

[mini_bot.button.2]
KO: 말하기
DE: Sprechen

[mini_bot.button.3]
KO: 보내기
DE: Senden

[mini_bot.hint]
KO: 한글로 말해 주세요
DE: Sprich oder tippe deine Frage

[mini_bot.mini_bot_dock.accessibility]
KO: 달팽이봇
DE: Schnecken-Bot

[mini_bot.mini_bot_dock.body]
KO: 끌어서 옮길 수 있어요
DE: Zum Verschieben ziehen

[mini_bot.mini_bot_intent.body]
KO: 후원하기
DE: Unterstützen

[mini_bot.mini_bot_intent.body.10]
KO: 다이아 교환
DE: DIA-Tausch

[mini_bot.mini_bot_intent.body.11]
KO: 스폰서
DE: Sponsor

[mini_bot.mini_bot_intent.body.12]
KO: 러너 후원
DE: Läufer unterstützen

[mini_bot.mini_bot_intent.body.13]
KO: 배틀패스
DE: Battle Pass

[mini_bot.mini_bot_intent.body.14]
KO: 저는 당신의 달리기 친구, 달팽이예요. 말로 물어보면 바로 도와드릴게요. 이동하거나 결제하기 전에는 꼭 확인받아요.
DE: Ich bin Ihre Schnecke, Ihr Laufbegleiter. Fragen Sie mich einfach per Sprache und ich helfe Ihnen sofort. Vor jedem Bildschirmwechsel oder einer Zahlung frage ich immer nach Ihrer Bestätigung.

[mini_bot.mini_bot_intent.body.17]
KO: 유료 구독은 Coach+ 하나예요
DE: Coach+ ist das einzige kostenpflichtige Abonnement.

[mini_bot.mini_bot_intent.body.19]
KO: 상점의 기부 버튼으로 직접 눌러 주세요.
DE: Bitte tippen Sie direkt im Shop auf den Spenden-Button.

[mini_bot.mini_bot_intent.body.2]
KO: 구매하기
DE: Kaufen

[mini_bot.mini_bot_intent.body.20]
KO: 초보 1km 챌린지로 이동할까요? 참가비는 $joinAmount예요. 참가하기를 눌러도 참가는 확정되지 않아요. 그 화면에서 직접 확인해 주세요.
DE: Zur 1-km-Anfänger-Challenge wechseln? Die Teilnahmegebühr beträgt $joinAmount. Das Tippen auf „Teilnehmen“ bestätigt die Teilnahme noch nicht. Bitte prüfen Sie es direkt auf diesem Bildschirm.

[mini_bot.mini_bot_intent.body.21]
KO: 챌린지 로비로 이동할까요? 로비에서 참가할 대회를 고를 수 있어요.
DE: Zur Challenge-Lobby wechseln? In der Lobby können Sie einen Wettbewerb zur Teilnahme auswählen.

[mini_bot.mini_bot_intent.body.22]
KO: 운영자 상금 대회 참가비를 확인 중이에요. 대회 목록에서 서버 참가비를 확인해 주세요. 여기서는 참가하지 않아요.
DE: Teilnahmegebühr für den Host-Preis-Wettbewerb wird überprüft. Bitte prüfen Sie die Server-Teilnahmegebühr in der Wettbewerbsliste. Hier wird keine Teilnahme durchgeführt.

[mini_bot.mini_bot_intent.body.23]
KO: 초급
DE: Anfänger

[mini_bot.mini_bot_intent.body.24]
KO: 중급
DE: Mittelstufe

[mini_bot.mini_bot_intent.body.25]
KO: 상급
DE: Fortgeschritten

[mini_bot.mini_bot_intent.body.26]
KO: 하프
DE: Halb

[mini_bot.mini_bot_intent.body.27]
KO: 운영자 상금 대회로 이동할까요? 참가비는 $costs예요.$free $week $claim 이동만 하고, 참가는 확정하지 않아요.
DE: Zum Host-Preis-Wettbewerb wechseln? Die Teilnahmegebühr beträgt $costs.$free $week $claim Sie werden nur weitergeleitet; die Teilnahme wird nicht bestätigt.

[mini_bot.mini_bot_intent.body.28]
KO: 상점의 기록 심폐소생권으로 이동할까요? $itemAmount예요. 구매하기를 눌러도 결제하지 않아요. 상점 화면에서 직접 구매해 주세요.
DE: Zum Rekord-Wiederbelebungs-Ticket im Shop wechseln? Es kostet $itemAmount. Das Tippen auf „Kaufen“ führt keine Zahlung aus. Bitte kaufen Sie es direkt auf dem Shop-Bildschirm.

[mini_bot.mini_bot_intent.body.3]
KO: 참가하기
DE: Teilnehmen

[mini_bot.mini_bot_intent.body.30]
KO: 상점의 세이프 가드 칸에서 직접 구매해 주세요.
DE: Bitte kaufen Sie es direkt im Bereich „Safe Guard“ des Shops.

[mini_bot.mini_bot_intent.body.31]
KO: 다이아 교환소로 이동할까요? $chargeAmount예요. 교환하기를 눌러도 여기서는 결제되지 않아요. 교환소에서 직접 바꿔 주세요.
DE: Zur DIA-Tauschbörse wechseln? Es kostet $chargeAmount. Das Tippen auf „Tauschen“ führt hier keine Zahlung aus. Bitte tauschen Sie direkt in der Tauschbörse um.

[mini_bot.mini_bot_intent.body.33]
KO: 그 화면의 후원 버튼으로 직접 확정해 주세요.
DE: Bitte bestätigen Sie es direkt über die Unterstützen-Schaltfläche auf diesem Bildschirm.

[mini_bot.mini_bot_intent.body.34]
KO: 브랜드 스폰서 챌린지는 아직 준비 중이에요. 지금 진행 중인 스폰서 챌린지가 없어요. 열리면 챌린지 탭에서 알려 드릴게요.
DE: Marken-Sponsoren-Challenges sind noch in Vorbereitung. Derzeit gibt es keine laufenden Sponsoren-Challenges. Wir benachrichtigen Sie im Challenge-Tab, sobald sie verfügbar sind.

[mini_bot.mini_bot_intent.body.35]
KO: 구독 관리 화면으로 이동할까요? $subscriptionAmount. 이동만 하고, 구독이나 결제는 바꾸지 않아요.
DE: Zur Abonnementverwaltung wechseln? $subscriptionAmount. Sie werden nur weitergeleitet; Ihr Abonnement oder Ihre Zahlung wird nicht geändert.

[mini_bot.mini_bot_intent.body.36]
KO: Coach+ 안내를 열까요? 심박·상황에 맞춘 심층 코칭이에요. $coachPlusAmount. 이동만 하고, 여기서는 결제하지 않아요.
DE: Coach+-Anleitung öffnen? Tiefgehendes Coaching, abgestimmt auf Puls und Situation. $coachPlusAmount. Sie werden nur weitergeleitet; hier wird keine Zahlung fällig.

[mini_bot.mini_bot_intent.body.37]
KO: 배틀런 패스 화면으로 이동할까요? $battlePassAmount. 여기서는 패스를 구매하지 않아요. 보상 화면만 열어요.
DE: Zum Bildschirm „Battle Run pass“ wechseln? $battlePassAmount. Hier wird kein Pass gekauft. Es öffnet sich nur der Belohnungsbildschirm.

[mini_bot.mini_bot_intent.body.38]
KO: 알겠어요. 이동은 취소했어요.
DE: Verstanden. Die Weiterleitung wurde abgebrochen.

[mini_bot.mini_bot_intent.body.4]
KO: 이동하기
DE: Wechseln

[mini_bot.mini_bot_intent.body.40]
KO: 다이아 교환, 심폐소생권, 세이프가드, 구독, Coach+, 배틀패스 중에서 말해 주세요.
DE: Bitte wählen Sie zwischen DIA-Tausch, Wiederbelebungs-Ticket, Safe Guard, Abo, Coach+ oder Battle Pass.

[mini_bot.mini_bot_intent.body.41]
KO: 마이크 권한이 없어 음성을 듣지 못했어요. 한글로 입력하거나 아래 버튼을 눌러 주세요.
DE: Mikrofonberechtigung fehlt, daher konnte die Spracheingabe nicht gehört werden. Bitte geben Sie Text ein oder tippen Sie auf die Schaltfläche unten.

[mini_bot.mini_bot_intent.body.42]
KO: 지금은 음성 인식을 쓸 수 없어요. 한글로 입력하거나 아래 버튼을 눌러 주세요.
DE: Die Spracherkennung ist derzeit nicht verfügbar. Bitte geben Sie Text ein oder tippen Sie auf die Schaltfläche unten.

[mini_bot.mini_bot_intent.body.43]
KO: 말씀을 알아듣지 못했어요. 다시 말하거나 한글로 입력해 주세요.
DE: Ich habe Sie nicht verstanden. Bitte wiederholen Sie es oder geben Sie Text ein.

[mini_bot.mini_bot_intent.body.44]
KO: 듣는 중이에요. 말씀해 주세요.
DE: Ich höre zu. Bitte sprechen Sie.

[mini_bot.mini_bot_intent.body.45]
KO: 초보 1km 챌린지로 이동할게요. 참가 확정은 그 화면에서 해 주세요. 여기서는 참가되지 않아요.
DE: Weiterleitung zur 1-km-Anfänger-Challenge. Bitte bestätigen Sie die Teilnahme auf diesem Bildschirm. Hier wird keine Teilnahme durchgeführt.

[mini_bot.mini_bot_intent.body.46]
KO: 챌린지 로비로 이동할게요.
DE: Weiterleitung zur Challenge-Lobby.

[mini_bot.mini_bot_intent.body.47]
KO: 상점 아이템 화면으로 이동할게요. 기록 심폐소생권을 눌러 구매해 주세요. 여기서는 결제되지 않아요.
DE: Weiterleitung zum Shop-Artikelbildschirm. Bitte tippen Sie auf „Rekord-Wiederbelebungs-Ticket“, um es zu kaufen. Hier wird keine Zahlung ausgeführt.

[mini_bot.mini_bot_intent.body.48]
KO: 상점 아이템 화면으로 이동할게요. 세이프 가드를 눌러 구매해 주세요. 여기서는 결제되지 않아요.
DE: Weiterleitung zum Shop-Artikelbildschirm. Bitte tippen Sie auf „Safe Guard“, um ihn zu kaufen. Hier wird keine Zahlung ausgeführt.

[mini_bot.mini_bot_intent.body.49]
KO: 상점 기부 펀딩으로 이동할게요. 기부 버튼으로 직접 눌러 주세요. 여기서는 기부되지 않아요.
DE: Weiterleitung zum Shop-Spenden-Crowdfunding. Bitte tippen Sie direkt auf die Spenden-Schaltfläche. Hier wird keine Spende getätigt.

[mini_bot.mini_bot_intent.body.5]
KO: 앱 소개
DE: Über die App

[mini_bot.mini_bot_intent.body.50]
KO: 다이아 교환소로 이동할게요. 교환은 그 화면에서 직접 해 주세요. 여기서는 결제되지 않아요.
DE: Weiterleitung zur DIA-Tauschbörse. Bitte führen Sie den Umtausch direkt auf diesem Bildschirm durch. Hier wird keine Zahlung ausgeführt.

[mini_bot.mini_bot_intent.body.51]
KO: 러너 후원 화면으로 이동할게요. 후원 버튼으로 직접 확정해 주세요. 여기서는 후원되지 않아요.
DE: Weiterleitung zum Bildschirm „Läufer unterstützen“. Bitte bestätigen Sie direkt über die Unterstützen-Schaltfläche. Hier wird keine Unterstützung durchgeführt.

[mini_bot.mini_bot_intent.body.52]
KO: 브랜드 스폰서 챌린지로 이동할게요. 참가는 그 화면에서 직접 해 주세요. 여기서는 참가되지 않아요.
DE: Weiterleitung zu den Marken-Sponsoren-Challenges. Bitte nehmen Sie direkt auf diesem Bildschirm teil. Hier wird keine Teilnahme durchgeführt.

[mini_bot.mini_bot_intent.body.53]
KO: 구독 관리 화면으로 이동할게요. 여기서는 구독을 바꾸지 않아요.
DE: Weiterleitung zur Abonnementverwaltung. Hier wird Ihr Abonnement nicht geändert.

[mini_bot.mini_bot_intent.body.54]
KO: Coach+ 안내를 열게요. 월간·연간은 그 화면에서 직접 골라 주세요. 여기서는 결제되지 않아요.
DE: Coach+-Anleitung wird geöffnet. Bitte wählen Sie monatlich oder jährlich direkt auf diesem Bildschirm aus. Hier wird keine Zahlung ausgeführt.

[mini_bot.mini_bot_intent.body.55]
KO: 배틀런 패스 화면으로 이동할게요. 여기서는 패스를 구매하지 않아요.
DE: Weiterleitung zum Bildschirm „Battle Run pass“. Hier wird kein Pass gekauft.

[mini_bot.mini_bot_intent.body.56]
KO: 충전
DE: Aufladen

[mini_bot.mini_bot_intent.body.57]
KO: 상금
DE: Preisgeld

[mini_bot.mini_bot_intent.body.58]
KO: 초보
DE: Anfänger

[mini_bot.mini_bot_intent.body.59]
KO: 로비
DE: Lobby

[mini_bot.mini_bot_intent.body.6]
KO: 챌린지 참가
DE: An Challenge teilnehmen

[mini_bot.mini_bot_intent.body.60]
KO: 참가
DE: Teilnehmen

[mini_bot.mini_bot_intent.body.61]
KO: 레이스
DE: Rennen

[mini_bot.mini_bot_intent.body.62]
KO: 입장
DE: Eintreten

[mini_bot.mini_bot_intent.body.63]
KO: 들어가
DE: Reingehen

[mini_bot.mini_bot_intent.body.64]
KO: 심폐
DE: Kardiopulmonal

[mini_bot.mini_bot_intent.body.65]
KO: 소생
DE: Wiederbelebung

[mini_bot.mini_bot_intent.body.66]
KO: 배틀 패스
DE: Battle Pass

[mini_bot.mini_bot_intent.body.67]
KO: 배틀런
DE: Battle Run

[mini_bot.mini_bot_intent.body.68]
KO: 코칭
DE: Coaching

[mini_bot.mini_bot_intent.body.69]
KO: 코치
DE: Coach

[mini_bot.mini_bot_intent.body.7]
KO: 심폐소생권
DE: Wiederbelebungs-Ticket

[mini_bot.mini_bot_intent.body.70]
KO: 심박
DE: Herzfrequenz

[mini_bot.mini_bot_intent.body.71]
KO: 멤버십
DE: Mitgliedschaft

[mini_bot.mini_bot_intent.body.72]
KO: 정기
DE: Abo

[mini_bot.mini_bot_intent.body.73]
KO: 천사
DE: Engel

[mini_bot.mini_bot_intent.body.74]
KO: 브랜드
DE: Marke

[mini_bot.mini_bot_intent.body.75]
KO: 펀딩
DE: Finanzierung

[mini_bot.mini_bot_intent.body.76]
KO: 유니세프
DE: UNICEF

[mini_bot.mini_bot_intent.body.77]
KO: 소개
DE: Einführung

[mini_bot.mini_bot_intent.body.78]
KO: 뭐야
DE: Was ist das?

[mini_bot.mini_bot_intent.body.79]
KO: 뭐니
DE: Worum geht es?

[mini_bot.mini_bot_intent.body.8]
KO: 후원
DE: Unterstützung

[mini_bot.mini_bot_intent.body.80]
KO: 무엇
DE: Was

[mini_bot.mini_bot_intent.body.81]
KO: 어떤 앱
DE: Was für eine App?

[mini_bot.mini_bot_intent.body.82]
KO: 설명해
DE: Erklären

[mini_bot.mini_bot_intent.body.9]
KO: 세이프가드
DE: Safeguard

[mock_demo_data.body]
KO: 달리기부자45
DE: LaufProfi45

[mock_demo_data.body.10]
KO: ⚡ 네온 5K 스프린트 — 쉐어런 스폰서가 응원합니다!
DE: ⚡ Neon 5K Sprint — Der ShareRun-Sponsor feuert Sie an!

[mock_demo_data.body.11]
KO: 🔥 완주 시 밸류 토큰 적립 보너스 이벤트 진행 중
DE: 🔥 Bonus-Event für das Sammeln von VALUE-Tokens bei Abschluss läuft

[mock_demo_data.body.12]
KO: 🏆 크루원과 함께 페이스를 맞춰 보세요
DE: 🏆 Stimmen Sie Ihr Tempo mit Ihren Crew-Mitgliedern ab

[mock_demo_data.body.13]
KO: 공원 입구 다이아
DE: Parkeingang DIA

[mock_demo_data.body.14]
KO: 민지
DE: Minji

[mock_demo_data.body.15]
KO: 준호
DE: Junho

[mock_demo_data.body.16]
KO: 서연
DE: Seoyeon

[mock_demo_data.body.17]
KO: 태윤
DE: Taeyoon

[mock_demo_data.body.18]
KO: 네온 러너스
DE: Neon Runners

[mock_demo_data.body.2]
KO: 김민수
DE: Minsu Kim

[mock_demo_data.body.3]
KO: 현재 김민수님이 당신의 완주를 후원하고 있습니다
DE: Minsu Kim sponsert derzeit Ihren Laufabschluss.

[mock_demo_data.body.4]
KO: 루키 3K 기부 런
DE: Rookie 3K Spendenlauf

[mock_demo_data.body.5]
KO: 기부 캠페인
DE: Spendenkampagne

[mock_demo_data.body.6]
KO: 🏃 기부 캠페인: 오늘도 3K 완주에 도전하세요!
DE: 🏃 Spendenkampagne: Fordern Sie sich heute heraus, 3K zu schaffen!

[mock_demo_data.body.7]
KO: 💚 러너 여러분의 발걸음이 아이들에게 전달됩니다
DE: 💚 Jeder Schritt unserer Läufer erreicht die Kinder

[mock_demo_data.body.8]
KO: 🎯 참가비의 일부가 기부 풀로 적립됩니다
DE: 🎯 Ein Teil der Teilnahmegebühr fließt in den Spendenpool

[mock_demo_data.body.9]
KO: 네온 5K 스프린트
DE: Neon 5K Sprint

[app.myPageGoldGrade]
KO: 골드 등급
DE: Gold-Stufe

[app.myPageMonthlyDistanceLabel]
KO: 이번 달 총 거리:
DE: Gesamtdistanz diesen Monat:

[app.myPageNickname]
KO: 러너상기
DE: RunnerSangki

[app.myPageStreak]
KO: 🔥 현재 연속 출석(Streak): 12일
DE: 🔥 Aktuelle Serie (Streak): 12 Tage

[app.myPageSubscriptionManage]
KO: 구독 관리
DE: Abonnement verwalten

[app.promotionBlockedCooldown]
KO: 승급은 일주일에 한 번이에요. 점수는 그대로 모여 있어요
DE: Beförderungen finden einmal pro Woche statt. Ihre Punkte bleiben erhalten.

[app.promotionBlockedPace]
KO: 다음 동물로 가려면 최근 30일 안에 더 빠른 달리기가 필요해요
DE: Um das nächste Tier zu erreichen, benötigen Sie einen schnelleren Lauf innerhalb der letzten 30 Tage.

[app.promotionBlockedSeason]
KO: 다음 동물은 시즌 성적으로 정해져요
DE: Das nächste Tier wird durch die Saisonergebnisse bestimmt.

[app.promotionBlockedTournaments]
KO: 다음 동물로 가려면 대회를 몇 번 더 완주해야 해요
DE: Um das nächste Tier zu erreichen, müssen Sie noch ein paar Wettbewerbe abschließen.

[app.promotionHint]
KO: 대회에서 입상하면 점수가 쌓여요
DE: Punkte werden gesammelt, wenn Sie bei Wettbewerben eine Platzierung erreichen

[app.promotionProgress]
KO: $points / $step점
DE: $points / $step Pkt.

[app.promotionTitle]
KO: 다음 메달까지
DE: Bis zur nächsten Medaille

[my_page.body]
KO: 이용약관과 별도 · 선택 동의
DE: Getrennt von den Nutzungsbedingungen · Optionale Zustimmung

[my_page.body.2]
KO: 러닝 캘린더
DE: Laufkalender

[my_page.body.3]
KO: 스마트워치 연동
DE: Smartwatch-Synchronisierung

[my_page.body.4]
KO: 연동된 워치 없음
DE: Keine verknüpfte Watch

[my_page.body.5]
KO: 푸시 알림
DE: Push-Benachrichtigungen

[my_page.body.6]
KO: Mock: 50% 기부 선택
DE: Mock: 50 % Spende auswählen

[my_page.body.7]
KO: Mock: 100% 기부 선택
DE: Mock: 100 % Spende auswählen

[my_page.body.8]
KO: Mock: 전액 수령 선택
DE: Mock: Vollständige Abholung gewählt

[my_page.body.9]
KO: ✅ 건강 데이터 연동 및 동의 완료
DE: ✅ Verknüpfung und Einwilligung der Gesundheitsdaten abgeschlossen

[my_page.button]
KO: 투트랙 연동 설정 열기
DE: Zwei-Wege-Sync-Einstellungen öffnen

[my_page.button.2]
KO: 우승자 명예 팝업 미리보기 (Mock)
DE: Vorschau Sieger-Ehren-Popup (Mock)

[my_page.button.3]
KO: 대회, 보상, 기부 알림
DE: Benachrichtigungen für Turniere, Belohnungen & Spenden

[my_page.button.4]
KO: 취소
DE: Abbrechen

[my_page.button.5]
KO: 삭제
DE: Löschen

[my_page.button.6]
KO: [약관 전문 보기]
DE: [Vollständige AGB anzeigen]

[my_page.dialog]
KO: 계정이 삭제되고 보유한 SHARE·DIA·VALUE는 사라집니다. 러닝 기록 등 활동 기록은 30일 안에 삭제되고, 법령에 따라 보관해야 하는 결제·거래 기록은 5년간 보관한 뒤 삭제됩니다. 이 작업은 되돌릴 수 없습니다. 계속하시겠습니까?
DE: Ihr Konto wird gelöscht und Ihr vorhandenes SHARE, DIA und VALUE geht verloren. Aktivitätsdaten wie der Laufverlauf werden innerhalb von 30 Tagen gelöscht. Zahlungs- und Transaktionsdaten, die gesetzlich aufbewahrt werden müssen, werden 5 Jahre lang gespeichert und danach gelöscht. Dieser Vorgang kann nicht widerrufen werden. Möchten Sie fortfahren?

[my_page.toast]
KO: ✅ 민감정보 수집 동의가 완료되었습니다. 이제 러닝을 시작할 수 있습니다!
DE: ✅ Die Zustimmung zur Erfassung sensibler Daten ist abgeschlossen. Sie können nun mit dem Laufen beginnen!

[my_page.pace_calculator.body]
KO: 목표 페이스 계산기
DE: Ziel-Pace-Rechner

[my_page.pace_calculator.body.2]
KO: 유효한 거리와 목표 시간을 입력하세요.
DE: Bitte geben Sie eine gültige Distanz und Zielzeit ein.

[my_page.pace_calculator.body.3]
KO: 목표 페이스: $paceMin:${paceSec.toString().padLeft(2,
DE: Ziel-Pace: $paceMin:${paceSec.toString().padLeft(2,

[my_page.pace_calculator.body.4]
KO: )} /km
예상 완주: $finish (${distance.toStringAsFixed(1)} km)
DE: )} /km
Geschätzte Zielzeit: $finish (${distance.toStringAsFixed(1)} km)

[my_page.pace_calculator.hint]
KO: 목표 거리 (km)
DE: Zieldistanz (km)

[my_page.pace_calculator.hint.2]
KO: 시
DE: Std.

[my_page.pace_calculator.hint.3]
KO: 분
DE: Min.

[my_page.pace_calculator.hint.4]
KO: 초
DE: Sek.

[my_page.shoe_mileage_tracker.body]
KO: 러닝화 마일리지 트래커
DE: Laufschuh-Kilometer-Tracker

[my_page.shoe_mileage_tracker.body.2]
KO: 장착 중 · $skinName
DE: Ausgerüstet · $skinName

[my_page.shoe_mileage_tracker.body.3]
KO: ⚠️ 500km 도달! 쿠셔닝 성능 저하 위험 — 러닝화 교체를 권장합니다.
DE: ⚠️ 500km erreicht! Gefahr nachlassender Dämpfung — Austausch der Laufschuhe empfohlen.

[my_page.shoe_mileage_tracker.body.4]
KO: 교체 알림: ${(goal - totalDistanceKm).toStringAsFixed(1)} km 남음
DE: Austausch-Erinnerung: Noch ${(goal - totalDistanceKm).toStringAsFixed(1)} km

[my_tournaments.body]
KO: 내 대회
DE: Meine Turniere

[my_tournaments.body.2]
KO: 참가한 대회와 참가 상태를 확인하세요.
DE: Überprüfen Sie Ihre Turniere und den Teilnahme-Status.

[my_tournaments.body.3]
KO: 아직 참가한 대회가 없습니다.
DE: Sie haben noch an keinen Turnieren teilgenommen.

[my_tournaments.body.4]
KO: 참가 중
DE: Teilnahme

[my_tournaments.body.5]
KO: 지난 대회
DE: Vergangene Turniere

[my_tournaments.body.6]
KO: 참가비 ${p.entryFeeShare} SHARE · ${p.tournament.recruitmentSummary}
DE: Teilnahmegebühr ${p.entryFeeShare} SHARE · ${p.tournament.recruitmentSummary}

[my_tournaments.body.7]
KO: 환불됨
DE: Rückerstattet

[app.notification1BodyPrefix]
KO: 중급 3km 챌린지 기록이 승인되어
DE: Ihr Datensatz für die 3-km-Herausforderung (Mittelstufe) wurde genehmigt und

[app.notification1BodySuffix]
KO: 이 지갑으로 자동 입금되었습니다.
DE: wurden automatisch auf Ihr Wallet überwiesen.

[app.notification1Highlight]
KO: 100 밸류 토큰(VALUE)
DE: 100 VALUE-Token

[app.notification1Time]
KO: 방금 전
DE: Gerade eben

[app.notification1Title]
KO: 러닝 검증 완료!
DE: Laufüberprüfung abgeschlossen!

[app.notification2BodyPrefix]
KO: 서울 나이트 러너스 방장님이
DE: Der Leiter von Seoul Night Runners hat Ihnen ein

[app.notification2BodySuffix]
KO: 을 선물했습니다!
DE: geschenkt!

[app.notification2Highlight]
KO: '기록 심폐소생권'
DE: 'Datensatz-Wiederbelebungsticket'

[app.notification2Time]
KO: 2시간 전
DE: Vor 2 Stunden

[app.notification2Title]
KO: 크루 방장님의 하사품
DE: Geschenk vom Crew-Leiter

[app.notification3Body]
KO: 대회 무산으로 인해 50,000 SHARE 현금 환불이 정상 처리되었습니다.
DE: Aufgrund der Absage des Wettbewerbs wurde Ihre Barrückerstattung von 50.000 SHARE erfolgreich bearbeitet.

[app.notification3Time]
KO: 어제
DE: Gestern

[app.notification3Title]
KO: 결제 취소 완료
DE: Zahlung storniert

[app.notificationCenterTitle]
KO: 알림 및 내역 (History)
DE: Benachrichtigungen & Verlauf (History)

[app.notificationPaymentEmpty]
KO: 거래 및 결제 내역이 존재하지 않습니다. 🪙
DE: Kein Transaktions- oder Zahlungsverlauf vorhanden. 🪙

[app.notificationPaymentReceipt]
KO: 안전 결제 영수증 완료 🪙
DE: Beleg für sichere Zahlung ausgestellt 🪙

[app.notificationPaymentUnknown]
KO: 알 수 없는 거래
DE: Unbekannte Transaktion

[app.notificationSystemEmpty]
KO: 도달한 새로운 알림이 없습니다. 🔔
DE: Keine neuen Benachrichtigungen eingetroffen. 🔔

[app.notificationSystemFallbackTitle]
KO: 알림
DE: Benachrichtigung

[app.notificationTabPayment]
KO: 결제/히스토리
DE: Zahlungen / Verlauf

[app.notificationTabSystem]
KO: 시스템 알림
DE: Systembenachrichtigungen

[notification_center.body]
KO: ${date.month}월 ${date.day}일
DE: ${date.day}.${date.month}.

[onboarding.body]
KO: 쉐어런에 오신 걸 환영해요
DE: Willkommen bei ShareRun

[onboarding.body.2]
KO: 서비스 이용 전 필수 약관에 동의해 주세요.
DE: Bitte stimmen Sie den erforderlichen Nutzungsbedingungen zu, bevor Sie den Dienst nutzen.

[onboarding.body.3]
KO: 아래는 일반 약관과 분리된 선택 동의입니다.
DE: Nachfolgend finden Sie die optionalen Zustimmungen, getrennt von den allgemeinen Bedingungen.

[onboarding.body.4]
KO: 동의합니다
DE: Ich stimme zu

[onboarding.button]
KO: 저장 중...
DE: Speichern...

[onboarding.button.2]
KO: 동의하고 시작하기
DE: Zustimmen und Starten

[onboarding.toast]
KO: 온보딩 저장 실패: $error
DE: Onboarding-Speicherung fehlgeschlagen: $error

[onboarding.nickname_change.body]
KO: 새로운 질주를 위한 이름을 새기시겠습니까?
DE: Möchten Sie einen neuen Namen für Ihren Lauf eingravieren?

[onboarding.nickname_change.body.2]
KO: 러너님의 정체성을 정밀 등록합니다.
DE: Ihre Läuferidentität wird präzise registriert.

[onboarding.nickname_change.body.3]
KO: 보유 $diaBalance DIA  ·  변경 수수료 $fee DIA
DE: Guthaben $diaBalance DIA  ·  Änderungsgebühr $fee DIA

[onboarding.nickname_change.body.4]
KO: 100 DIA 소모하여 변경하기
DE: Für 100 DIA ändern

[onboarding.nickname_change.body.5]
KO: 다이아몬드 부족 - 교환소로 이동하기
DE: Nicht genug DIA - Zur Tauschbörse

[onboarding.nickname_change.toast]
KO: 닉네임이 변경되었습니다. (${EconomyConstants.nicknameChangeFeeDia} DIA 차감)
DE: Spitzname wurde geändert. (${EconomyConstants.nicknameChangeFeeDia} DIA abgezogen)

[onboarding.nickname_setup.body]
KO: 닉네임 및 캐릭터 가동
DE: Spitzname & Charakter-Aktivierung

[onboarding.nickname_setup.body.2]
KO: 홈에 표시될 닉네임을 정하면, 예선 등급에 맞는 대두 캐릭터가 함께 깨어납니다.
DE: Sobald Sie einen Spitznamen für die Startseite festlegen, erwacht ein Großkopf-Charakter passend zu Ihrer Qualifikationsstufe.

[onboarding.nickname_setup.body.3]
KO: 설정 완료
DE: Einrichtung abschließen

[onboarding.nickname_setup.hint]
KO: 한글·영문·숫자 2~12자
DE: 2–12 Buchstaben oder Zahlen

[onboarding.src_onboarding_controller.body]
KO: 예비 천사 (Pre-Angel)
DE: Pre-Angel

[onboarding.src_onboarding_controller.body.10]
KO: 누적 20회 또는 누적 300,000 SHARE 이상
DE: Kumulativ 20 Mal oder kumulativ mindestens 300.000 SHARE

[onboarding.src_onboarding_controller.body.11]
KO: 누적 50회 또는 누적 1,000,000 SHARE 이상
DE: Kumulativ 50 Mal oder kumulativ mindestens 1.000.000 SHARE

[onboarding.src_onboarding_controller.body.12]
KO: 누적 100회 또는 누적 5,000,000 SHARE 이상
DE: Kumulativ 100 Mal oder kumulativ mindestens 5.000.000 SHARE

[onboarding.src_onboarding_controller.body.13]
KO: 등에 귀여운 날개 반창고를 붙인 마스코트
DE: Maskottchen mit einem niedlichen Flügel-Pflaster auf dem Rücken

[onboarding.src_onboarding_controller.body.14]
KO: 등 뒤 아기 날개 배지 장착
DE: Abzeichen mit Babyflügeln auf dem Rücken angelegt

[onboarding.src_onboarding_controller.body.15]
KO: 은빛 날개 · 대회 입장 시 닉네임 볼드 테두리 강조
DE: Silberne Flügel · Spitzname wird beim Betreten des Turniers mit fettem Rahmen hervorgehoben

[onboarding.src_onboarding_controller.body.16]
KO: 황금 날개 · 골드 그라데이션 닉네임 · 개설 대회 러너 1.2배 VALUE 부스트
DE: Goldene Flügel · Spitzname mit Gold-Farbverlauf · 1,2-facher VALUE-Boost für Läufer in erstellten Turnieren

[onboarding.src_onboarding_controller.body.17]
KO: 4익 날개 · 민트 오라 · 대회 입장 시 단독 등장 팝업
DE: 4 Flügel · Minz-Aura · Exklusives Auftritts-Pop-up beim Betreten des Turniers

[onboarding.src_onboarding_controller.body.18]
KO: 6익 날개 · 골드 광배 회전 · 명예의 전당 VVIP 단독 배너
DE: 6 Flügel · Rotierende goldene Aureole · Exklusives VVIP-Banner in der Hall of Fame

[onboarding.src_onboarding_controller.body.19]
KO: ${n.koreanName}까지 후원 $remainCount회
DE: Noch $remainCount Sponsorings bis ${n.koreanName}

[onboarding.src_onboarding_controller.body.2]
KO: 큐피드
DE: Cupid

[onboarding.src_onboarding_controller.body.20]
KO: ${n.koreanName}까지 $remainCount회 또는 ${formatWon(remainWon)}
DE: Noch $remainCount Mal oder ${formatWon(remainWon)} bis ${n.koreanName}

[onboarding.src_onboarding_controller.body.21]
KO: 알림을 켜면 이런 이득이 있어요
DE: Benachrichtigungen aktivieren bringt diese Vorteile

[onboarding.src_onboarding_controller.body.22]
KO: 재화 실시간 입금 알림
DE: Echtzeit-Benachrichtigung über Guthabeneingang

[onboarding.src_onboarding_controller.body.23]
KO: 소속 크루 방장 전체 공지 긴급 수신
DE: Dringender Empfang allgemeiner Mitteilungen des Leiters Ihrer crew

[onboarding.src_onboarding_controller.body.24]
KO: 러닝화 수명 도달에 따른 부상 방지 수명 알림
DE: Verletzungspräventions-Hinweis, wenn die Laufschuhe das Ende ihrer Lebensdauer erreichen

[onboarding.src_onboarding_controller.body.25]
KO: DIA 잔액 부족: 필요 $requiredDia, 보유 $availableDia
DE: Unzureichendes DIA-Guthaben: erforderlich $requiredDia, vorhanden $availableDia

[onboarding.src_onboarding_controller.body.26]
KO: 시발
DE: Scheiße

[onboarding.src_onboarding_controller.body.27]
KO: 씨발
DE: ficken

[onboarding.src_onboarding_controller.body.28]
KO: 병신
DE: Spast

[onboarding.src_onboarding_controller.body.29]
KO: 지랄
DE: Schwachsinn

[onboarding.src_onboarding_controller.body.3]
KO: 수호천사
DE: Schutzengel

[onboarding.src_onboarding_controller.body.30]
KO: 좆
DE: Schwanz

[onboarding.src_onboarding_controller.body.31]
KO: 존나
DE: verdammt

[onboarding.src_onboarding_controller.body.32]
KO: 개새끼
DE: Hurensohn

[onboarding.src_onboarding_controller.body.33]
KO: 씹
DE: Fotze
