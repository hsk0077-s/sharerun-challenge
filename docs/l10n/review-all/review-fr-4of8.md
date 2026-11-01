# 번역 검수 요청 — 쉐어런 (French) · 파트 4/8

아래는 한국어 앱 "쉐어런"(걷기·달리기 앱, 회사 자금 기부 연계)의 화면 문구를 French(으)로 번역한 것입니다.
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
[main_dashboard.body.3]
KO: 좋은 오후예요
FR: Bon après-midi

[main_dashboard.body.4]
KO: 좋은 저녁이에요
FR: Bonsoir

[main_dashboard.body.5]
KO: ${_hello(DateTime.now().hour)}, $nickname님
FR: ${_hello(DateTime.now().hour)}, $nickname

[main_shell_routes.body]
KO: 결제 정보가 없어 PG 화면을 열 수 없습니다.
FR: Impossible d'ouvrir l'écran PG car les informations de paiement sont manquantes.

[main_shell_routes.body.2]
KO: 대회 정보가 없어 스폰서 결제를 열 수 없습니다.
FR: Impossible d'ouvrir le paiement sponsor car les informations sur la compétition sont manquantes.

[main_shell_routes.button]
KO: 대회 목록으로
FR: Liste des compétitions

[map_crew.body]
KO: 지도 & 크루
FR: Carte & crew

[map_crew.body.2]
KO: 크루 종합 랭킹
FR: Classement général du crew

[map_crew.body.3]
KO: ${crews[index].memberCount}명
FR: ${crews[index].memberCount} membres

[map_crew.body.4]
KO: 아직 크루 순위가 없어요
FR: Pas encore de classement de crew

[map_crew.body.5]
KO: 크루 순위가 쌓이면 여기에 나타나요.
FR: Le classement du crew apparaîtra ici au fur et à mesure.

[map_crew.body.6]
KO: ${collectRadiusMeters.round()}m 안으로 가까이 가야 받을 수 있어요.
FR: Vous devez vous rapprocher à moins de ${collectRadiusMeters.round()}m pour le récupérer.

[map_crew.body.7]
KO: +${box.rewardDiamond} DIA를 받았어요.
FR: +${box.rewardDiamond} DIA reçus.

[map_crew.body.8]
KO: ${distanceMeters!.toStringAsFixed(0)}m 떨어져 있어요
FR: À ${distanceMeters!.toStringAsFixed(0)}m

[map_crew.button]
KO: 내 위치 새로고침
FR: Actualiser la position

[map_crew.button.2]
KO: 다이아 상자 받기
FR: Récupérer le coffre DIA

[map_crew.button.3]
KO: 더 가까이 가 주세요
FR: Rapprochez-vous

[map_crew.crew_member_ranking_board.body]
KO: 크루원 랭킹 데이터 없음
FR: Aucune donnée de classement des membres du crew

[map_crew.crew_member_ranking_board.body.2]
KO: 출석률·평균 페이스가 여기에 표시됩니다.
FR: Le taux de présence et l'allure moyenne s'afficheront ici.

[map_crew.crew_member_ranking_board.body.3]
KO: 크루원 출석률 & 평균 페이스
FR: Présence et allure moyenne des membres du crew

[map_crew.crew_member_ranking_board.body.4]
KO: 출석률 높은 순 · 페이스 빠른 순으로 B2B 크루 성과를 추적합니다.
FR: Suivez les performances du crew B2B par taux de présence le plus élevé et allure la plus rapide.

[map_crew.crew_member_ranking_board.body.5]
KO: 출석 ${member.attendanceRate.toStringAsFixed(0)}%
FR: Présence ${member.attendanceRate.toStringAsFixed(0)}%

[map_crew.safe_map_panel.body]
KO: 지도 준비 중
FR: Préparation de la carte

[mini_bot.body]
KO: 궁금한 게 있으면 저를 눌러 물어보세요
FR: Touchez-moi si vous avez des questions

[mini_bot.body.10]
KO: 하루 SHARE 한도
FR: Limite quotidienne de SHARE

[mini_bot.body.11]
KO: 어떤 대회?
FR: Quelle compétition ?

[mini_bot.body.12]
KO: 순위별 상금
FR: Prix par classement

[mini_bot.body.13]
KO: 초급은 무료?
FR: Débutant est-il gratuit ?

[mini_bot.body.14]
KO: SHARE잔액
FR: Solde de SHARE

[mini_bot.body.15]
KO: VALUE잔액
FR: Solde de VALUE

[mini_bot.body.16]
KO: 등급
FR: Rang

[mini_bot.body.17]
KO: 오늘기부기여
FR: Contribution aux dons du jour

[mini_bot.body.18]
KO: 이 버전에서는 앱 안에서 결제하지 않아요.
FR: Dans cette version, aucun paiement n'est effectué dans l'application.

[mini_bot.body.19]
KO: 궁금한 걸 물어보세요
FR: Posez vos questions

[mini_bot.body.2]
KO: 오늘 목표나 SHARE가 궁금하면 물어보세요
FR: Posez-moi des questions sur vos objectifs du jour ou sur SHARE

[mini_bot.body.3]
KO: 기록 지키기가 헷갈리면 제가 알려 드려요
FR: Si vous hésitez sur la façon de préserver vos enregistrements, je peux vous aider.

[mini_bot.body.4]
KO: 어떤 챌린지가 맞는지 모르겠으면 물어보세요
FR: Demandez-moi si vous ne savez pas quel défi vous convient

[mini_bot.body.5]
KO: 참가비와 순위별 상금이 궁금하면 눌러 보세요
FR: Appuyez ici si vous souhaitez connaître les frais d'inscription et les prix par classement

[mini_bot.body.6]
KO: 초급은 무료인지도 알려 드려요
FR: Je peux aussi vous indiquer si le niveau débutant est gratuit

[mini_bot.body.7]
KO: 오늘 내 기부
FR: Mes dons du jour

[mini_bot.body.8]
KO: 내 SHARE
FR: Mon SHARE

[mini_bot.body.9]
KO: 내 등급
FR: Mon rang

[mini_bot.button]
KO: 멈추기
FR: Arrêter

[mini_bot.button.2]
KO: 말하기
FR: Parler

[mini_bot.button.3]
KO: 보내기
FR: Envoyer

[mini_bot.hint]
KO: 한글로 말해 주세요
FR: Parle ou écris ta question

[mini_bot.mini_bot_dock.accessibility]
KO: 달팽이봇
FR: Bot Escargot

[mini_bot.mini_bot_dock.body]
KO: 끌어서 옮길 수 있어요
FR: Faites glisser pour déplacer

[mini_bot.mini_bot_intent.body]
KO: 후원하기
FR: Soutenir

[mini_bot.mini_bot_intent.body.10]
KO: 다이아 교환
FR: Échange de DIA

[mini_bot.mini_bot_intent.body.11]
KO: 스폰서
FR: Sponsor

[mini_bot.mini_bot_intent.body.12]
KO: 러너 후원
FR: Parrainer un coureur

[mini_bot.mini_bot_intent.body.13]
KO: 배틀패스
FR: Battle Pass

[mini_bot.mini_bot_intent.body.14]
KO: 저는 당신의 달리기 친구, 달팽이예요. 말로 물어보면 바로 도와드릴게요. 이동하거나 결제하기 전에는 꼭 확인받아요.
FR: Je suis Escargot, votre compagnon de course. Posez-moi vos questions à la voix et je vous aiderai immédiatement. Je vous demanderai toujours confirmation avant de changer d'écran ou de payer.

[mini_bot.mini_bot_intent.body.17]
KO: 유료 구독은 Coach+ 하나예요
FR: Coach+ est le seul abonnement payant.

[mini_bot.mini_bot_intent.body.19]
KO: 상점의 기부 버튼으로 직접 눌러 주세요.
FR: Veuillez appuyer directement sur le bouton de don dans la boutique.

[mini_bot.mini_bot_intent.body.2]
KO: 구매하기
FR: Acheter

[mini_bot.mini_bot_intent.body.20]
KO: 초보 1km 챌린지로 이동할까요? 참가비는 $joinAmount예요. 참가하기를 눌러도 참가는 확정되지 않아요. 그 화면에서 직접 확인해 주세요.
FR: Accéder au défi Débutant 1 km ? Les frais de participation sont de $joinAmount. Appuyer sur Participer ne confirmera pas l'inscription. Veuillez vérifier directement sur cet écran.

[mini_bot.mini_bot_intent.body.21]
KO: 챌린지 로비로 이동할까요? 로비에서 참가할 대회를 고를 수 있어요.
FR: Accéder au salon des défis ? Vous pouvez choisir une compétition à laquelle participer dans le salon.

[mini_bot.mini_bot_intent.body.22]
KO: 운영자 상금 대회 참가비를 확인 중이에요. 대회 목록에서 서버 참가비를 확인해 주세요. 여기서는 참가하지 않아요.
FR: Vérification des frais d'inscription au concours avec prix de l'organisateur. Veuillez vérifier les frais du serveur dans la liste des compétitions. Vous ne participerez pas depuis cet écran.

[mini_bot.mini_bot_intent.body.23]
KO: 초급
FR: Débutant

[mini_bot.mini_bot_intent.body.24]
KO: 중급
FR: Intermédiaire

[mini_bot.mini_bot_intent.body.25]
KO: 상급
FR: Avancé

[mini_bot.mini_bot_intent.body.26]
KO: 하프
FR: Semi

[mini_bot.mini_bot_intent.body.27]
KO: 운영자 상금 대회로 이동할까요? 참가비는 $costs예요.$free $week $claim 이동만 하고, 참가는 확정하지 않아요.
FR: Accéder au concours avec prix de l'organisateur ? Les frais de participation sont de $costs.$free $week $claim Vous serez uniquement redirigé, l'inscription ne sera pas confirmée.

[mini_bot.mini_bot_intent.body.28]
KO: 상점의 기록 심폐소생권으로 이동할까요? $itemAmount예요. 구매하기를 눌러도 결제하지 않아요. 상점 화면에서 직접 구매해 주세요.
FR: Accéder au ticket de réanimation d'enregistrement dans la boutique ? Il coûte $itemAmount. Appuyer sur Acheter n'effectuera aucun paiement. Veuillez l'acheter directement sur l'écran de la boutique.

[mini_bot.mini_bot_intent.body.3]
KO: 참가하기
FR: Participer

[mini_bot.mini_bot_intent.body.30]
KO: 상점의 세이프 가드 칸에서 직접 구매해 주세요.
FR: Veuillez acheter directement dans la section Safe Guard de la boutique.

[mini_bot.mini_bot_intent.body.31]
KO: 다이아 교환소로 이동할까요? $chargeAmount예요. 교환하기를 눌러도 여기서는 결제되지 않아요. 교환소에서 직접 바꿔 주세요.
FR: Accéder au centre d'échange DIA ? Cela coûte $chargeAmount. Appuyer sur Échanger n'effectuera aucun paiement ici. Veuillez échanger directement dans le centre d'échange.

[mini_bot.mini_bot_intent.body.33]
KO: 그 화면의 후원 버튼으로 직접 확정해 주세요.
FR: Veuillez confirmer directement à l'aide du bouton Soutenir sur cet écran.

[mini_bot.mini_bot_intent.body.34]
KO: 브랜드 스폰서 챌린지는 아직 준비 중이에요. 지금 진행 중인 스폰서 챌린지가 없어요. 열리면 챌린지 탭에서 알려 드릴게요.
FR: Les défis sponsorisés par des marques sont encore en cours de préparation. Aucun défi sponsorisé n'est en cours pour le moment. Nous vous préviendrons dans l'onglet Défis dès leur ouverture.

[mini_bot.mini_bot_intent.body.35]
KO: 구독 관리 화면으로 이동할까요? $subscriptionAmount. 이동만 하고, 구독이나 결제는 바꾸지 않아요.
FR: Accéder à l'écran de gestion des abonnements ? $subscriptionAmount. Vous serez uniquement redirigé, votre abonnement ou paiement ne sera pas modifié.

[mini_bot.mini_bot_intent.body.36]
KO: Coach+ 안내를 열까요? 심박·상황에 맞춘 심층 코칭이에요. $coachPlusAmount. 이동만 하고, 여기서는 결제하지 않아요.
FR: Ouvrir le guide Coach+ ? Un coaching approfondi adapté à votre fréquence cardiaque et à votre situation. $coachPlusAmount. Vous serez uniquement redirigé, aucun paiement n'est effectué ici.

[mini_bot.mini_bot_intent.body.37]
KO: 배틀런 패스 화면으로 이동할까요? $battlePassAmount. 여기서는 패스를 구매하지 않아요. 보상 화면만 열어요.
FR: Accéder à l'écran du Battle Run pass ? $battlePassAmount. Vous n'achèterez pas de pass ici. Cela ouvre uniquement l'écran des récompenses.

[mini_bot.mini_bot_intent.body.38]
KO: 알겠어요. 이동은 취소했어요.
FR: Compris. La redirection a été annulée.

[mini_bot.mini_bot_intent.body.4]
KO: 이동하기
FR: Aller

[mini_bot.mini_bot_intent.body.40]
KO: 다이아 교환, 심폐소생권, 세이프가드, 구독, Coach+, 배틀패스 중에서 말해 주세요.
FR: Veuillez choisir parmi Échange de DIA, Ticket de réanimation, Safe Guard, Abonnement, Coach+ ou Passe de combat.

[mini_bot.mini_bot_intent.body.41]
KO: 마이크 권한이 없어 음성을 듣지 못했어요. 한글로 입력하거나 아래 버튼을 눌러 주세요.
FR: L'autorisation du micro n'est pas activée, impossible d'entendre votre voix. Veuillez saisir du texte ou appuyer sur le bouton ci-dessous.

[mini_bot.mini_bot_intent.body.42]
KO: 지금은 음성 인식을 쓸 수 없어요. 한글로 입력하거나 아래 버튼을 눌러 주세요.
FR: La reconnaissance vocale n'est pas disponible pour le moment. Veuillez saisir du texte ou appuyer sur le bouton ci-dessous.

[mini_bot.mini_bot_intent.body.43]
KO: 말씀을 알아듣지 못했어요. 다시 말하거나 한글로 입력해 주세요.
FR: Je n'ai pas compris. Veuillez répéter ou saisir du texte.

[mini_bot.mini_bot_intent.body.44]
KO: 듣는 중이에요. 말씀해 주세요.
FR: À l'écoute. Parlez, s'il vous plaît.

[mini_bot.mini_bot_intent.body.45]
KO: 초보 1km 챌린지로 이동할게요. 참가 확정은 그 화면에서 해 주세요. 여기서는 참가되지 않아요.
FR: Redirection vers le défi Débutant 1 km. Veuillez confirmer l'inscription sur cet écran. Vous ne pouvez pas participer depuis ici.

[mini_bot.mini_bot_intent.body.46]
KO: 챌린지 로비로 이동할게요.
FR: Redirection vers le salon des défis.

[mini_bot.mini_bot_intent.body.47]
KO: 상점 아이템 화면으로 이동할게요. 기록 심폐소생권을 눌러 구매해 주세요. 여기서는 결제되지 않아요.
FR: Redirection vers l'écran des articles de la boutique. Veuillez appuyer sur Ticket de réanimation d'enregistrement pour l'acheter. Aucun paiement ne sera effectué ici.

[mini_bot.mini_bot_intent.body.48]
KO: 상점 아이템 화면으로 이동할게요. 세이프 가드를 눌러 구매해 주세요. 여기서는 결제되지 않아요.
FR: Redirection vers l'écran des articles de la boutique. Veuillez appuyer sur Safe Guard pour l'acheter. Aucun paiement ne sera effectué ici.

[mini_bot.mini_bot_intent.body.49]
KO: 상점 기부 펀딩으로 이동할게요. 기부 버튼으로 직접 눌러 주세요. 여기서는 기부되지 않아요.
FR: Redirection vers le financement participatif de dons de la boutique. Veuillez appuyer directement sur le bouton Faire un don. Aucun don ne sera effectué ici.

[mini_bot.mini_bot_intent.body.5]
KO: 앱 소개
FR: Présentation de l'app

[mini_bot.mini_bot_intent.body.50]
KO: 다이아 교환소로 이동할게요. 교환은 그 화면에서 직접 해 주세요. 여기서는 결제되지 않아요.
FR: Redirection vers le centre d'échange DIA. Veuillez effectuer l'échange directement sur cet écran. Aucun paiement ne sera effectué ici.

[mini_bot.mini_bot_intent.body.51]
KO: 러너 후원 화면으로 이동할게요. 후원 버튼으로 직접 확정해 주세요. 여기서는 후원되지 않아요.
FR: Redirection vers l'écran Soutenir un coureur. Veuillez confirmer directement avec le bouton Soutenir. Le parrainage ne sera pas effectué ici.

[mini_bot.mini_bot_intent.body.52]
KO: 브랜드 스폰서 챌린지로 이동할게요. 참가는 그 화면에서 직접 해 주세요. 여기서는 참가되지 않아요.
FR: Redirection vers les défis sponsorisés par des marques. Veuillez participer directement sur cet écran. Vous ne pouvez pas participer depuis ici.

[mini_bot.mini_bot_intent.body.53]
KO: 구독 관리 화면으로 이동할게요. 여기서는 구독을 바꾸지 않아요.
FR: Redirection vers l'écran de gestion des abonnements. Votre abonnement ne sera pas modifié ici.

[mini_bot.mini_bot_intent.body.54]
KO: Coach+ 안내를 열게요. 월간·연간은 그 화면에서 직접 골라 주세요. 여기서는 결제되지 않아요.
FR: Ouverture du guide Coach+. Veuillez choisir l'abonnement mensuel ou annuel directement sur cet écran. Aucun paiement ne sera effectué ici.

[mini_bot.mini_bot_intent.body.55]
KO: 배틀런 패스 화면으로 이동할게요. 여기서는 패스를 구매하지 않아요.
FR: Redirection vers l'écran du Battle Run pass. Vous n'achèterez pas de pass ici.

[mini_bot.mini_bot_intent.body.56]
KO: 충전
FR: Recharger

[mini_bot.mini_bot_intent.body.57]
KO: 상금
FR: Prix

[mini_bot.mini_bot_intent.body.58]
KO: 초보
FR: Débutant

[mini_bot.mini_bot_intent.body.59]
KO: 로비
FR: Salon

[mini_bot.mini_bot_intent.body.6]
KO: 챌린지 참가
FR: Participer au défi

[mini_bot.mini_bot_intent.body.60]
KO: 참가
FR: Participer

[mini_bot.mini_bot_intent.body.61]
KO: 레이스
FR: Course

[mini_bot.mini_bot_intent.body.62]
KO: 입장
FR: Entrer

[mini_bot.mini_bot_intent.body.63]
KO: 들어가
FR: Entrer

[mini_bot.mini_bot_intent.body.64]
KO: 심폐
FR: Cardiopulmonaire

[mini_bot.mini_bot_intent.body.65]
KO: 소생
FR: Réanimation

[mini_bot.mini_bot_intent.body.66]
KO: 배틀 패스
FR: Passe de combat

[mini_bot.mini_bot_intent.body.67]
KO: 배틀런
FR: Battle Run

[mini_bot.mini_bot_intent.body.68]
KO: 코칭
FR: Coaching

[mini_bot.mini_bot_intent.body.69]
KO: 코치
FR: Coach

[mini_bot.mini_bot_intent.body.7]
KO: 심폐소생권
FR: Ticket de réanimation

[mini_bot.mini_bot_intent.body.70]
KO: 심박
FR: Fréquence cardiaque

[mini_bot.mini_bot_intent.body.71]
KO: 멤버십
FR: Adhésion

[mini_bot.mini_bot_intent.body.72]
KO: 정기
FR: Abonnement

[mini_bot.mini_bot_intent.body.73]
KO: 천사
FR: Ange

[mini_bot.mini_bot_intent.body.74]
KO: 브랜드
FR: Marque

[mini_bot.mini_bot_intent.body.75]
KO: 펀딩
FR: Financement

[mini_bot.mini_bot_intent.body.76]
KO: 유니세프
FR: UNICEF

[mini_bot.mini_bot_intent.body.77]
KO: 소개
FR: Présentation

[mini_bot.mini_bot_intent.body.78]
KO: 뭐야
FR: C'est quoi ?

[mini_bot.mini_bot_intent.body.79]
KO: 뭐니
FR: Qu'est-ce que c'est ?

[mini_bot.mini_bot_intent.body.8]
KO: 후원
FR: Soutien

[mini_bot.mini_bot_intent.body.80]
KO: 무엇
FR: Quoi

[mini_bot.mini_bot_intent.body.81]
KO: 어떤 앱
FR: Quel genre d'appli ?

[mini_bot.mini_bot_intent.body.82]
KO: 설명해
FR: Expliquez

[mini_bot.mini_bot_intent.body.9]
KO: 세이프가드
FR: Safeguard

[mock_demo_data.body]
KO: 달리기부자45
FR: CoureurRiche45

[mock_demo_data.body.10]
KO: ⚡ 네온 5K 스프린트 — 쉐어런 스폰서가 응원합니다!
FR: ⚡ Sprint 5K Néon — Le sponsor de ShareRun vous encourage !

[mock_demo_data.body.11]
KO: 🔥 완주 시 밸류 토큰 적립 보너스 이벤트 진행 중
FR: 🔥 Événement bonus d'accumulation de jetons VALUE en cours après fin de course

[mock_demo_data.body.12]
KO: 🏆 크루원과 함께 페이스를 맞춰 보세요
FR: 🏆 Adaptez votre allure avec les membres de votre crew

[mock_demo_data.body.13]
KO: 공원 입구 다이아
FR: DIA de l'entrée du parc

[mock_demo_data.body.14]
KO: 민지
FR: Minji

[mock_demo_data.body.15]
KO: 준호
FR: Junho

[mock_demo_data.body.16]
KO: 서연
FR: Seoyeon

[mock_demo_data.body.17]
KO: 태윤
FR: Taeyoon

[mock_demo_data.body.18]
KO: 네온 러너스
FR: Neon Runners

[mock_demo_data.body.2]
KO: 김민수
FR: Minsu Kim

[mock_demo_data.body.3]
KO: 현재 김민수님이 당신의 완주를 후원하고 있습니다
FR: Minsu Kim parraine actuellement la fin de votre course.

[mock_demo_data.body.4]
KO: 루키 3K 기부 런
FR: Course de Don 3K Rookie

[mock_demo_data.body.5]
KO: 기부 캠페인
FR: Campagne de Don

[mock_demo_data.body.6]
KO: 🏃 기부 캠페인: 오늘도 3K 완주에 도전하세요!
FR: 🏃 Campagne de Don : Relevez le défi de terminer 3K aujourd'hui !

[mock_demo_data.body.7]
KO: 💚 러너 여러분의 발걸음이 아이들에게 전달됩니다
FR: 💚 Chaque pas des coureurs atteint les enfants

[mock_demo_data.body.8]
KO: 🎯 참가비의 일부가 기부 풀로 적립됩니다
FR: 🎯 Une partie des frais d'inscription va au fonds de don

[mock_demo_data.body.9]
KO: 네온 5K 스프린트
FR: Sprint 5K Néon

[app.myPageGoldGrade]
KO: 골드 등급
FR: Niveau Or

[app.myPageMonthlyDistanceLabel]
KO: 이번 달 총 거리:
FR: Distance totale ce mois-ci :

[app.myPageNickname]
KO: 러너상기
FR: RunnerSangki

[app.myPageStreak]
KO: 🔥 현재 연속 출석(Streak): 12일
FR: 🔥 Série actuelle (Streak) : 12 jours

[app.myPageSubscriptionManage]
KO: 구독 관리
FR: Gérer l'abonnement

[app.promotionBlockedCooldown]
KO: 승급은 일주일에 한 번이에요. 점수는 그대로 모여 있어요
FR: La promotion a lieu une fois par semaine. Vos points restent cumulés.

[app.promotionBlockedPace]
KO: 다음 동물로 가려면 최근 30일 안에 더 빠른 달리기가 필요해요
FR: Pour passer à l'animal suivant, vous devez courir plus vite au cours des 30 derniers jours.

[app.promotionBlockedSeason]
KO: 다음 동물은 시즌 성적으로 정해져요
FR: Le prochain animal est déterminé par les résultats de la saison.

[app.promotionBlockedTournaments]
KO: 다음 동물로 가려면 대회를 몇 번 더 완주해야 해요
FR: Pour passer à l'animal suivant, vous devez terminer encore quelques compétitions.

[app.promotionHint]
KO: 대회에서 입상하면 점수가 쌓여요
FR: Vous accumulez des points en vous classant dans les compétitions

[app.promotionProgress]
KO: $points / $step점
FR: $points / $step pts

[app.promotionTitle]
KO: 다음 메달까지
FR: Jusqu'à la prochaine médaille

[my_page.body]
KO: 이용약관과 별도 · 선택 동의
FR: Indépendant des Conditions d'utilisation · Consentement optionnel

[my_page.body.2]
KO: 러닝 캘린더
FR: Calendrier de course

[my_page.body.3]
KO: 스마트워치 연동
FR: Synchronisation de la montre connectée

[my_page.body.4]
KO: 연동된 워치 없음
FR: Aucune montre connectée

[my_page.body.5]
KO: 푸시 알림
FR: Notifications push

[my_page.body.6]
KO: Mock: 50% 기부 선택
FR: Mock : Sélectionner 50 % de don

[my_page.body.7]
KO: Mock: 100% 기부 선택
FR: Mock : Sélectionner 100 % de don

[my_page.body.8]
KO: Mock: 전액 수령 선택
FR: Mock : Récupération totale sélectionnée

[my_page.body.9]
KO: ✅ 건강 데이터 연동 및 동의 완료
FR: ✅ Synchronisation et consentement des données de santé effectués

[my_page.button]
KO: 투트랙 연동 설정 열기
FR: Ouvrir paramètres de double synchro

[my_page.button.2]
KO: 우승자 명예 팝업 미리보기 (Mock)
FR: Aperçu pop-up d'honneur du vainqueur (Mock)

[my_page.button.3]
KO: 대회, 보상, 기부 알림
FR: Notifications de tournois, récompenses et dons

[my_page.button.4]
KO: 취소
FR: Annuler

[my_page.button.5]
KO: 삭제
FR: Supprimer

[my_page.button.6]
KO: [약관 전문 보기]
FR: [Voir l'intégralité des conditions]

[my_page.dialog]
KO: 계정이 삭제되고 보유한 SHARE·DIA·VALUE는 사라집니다. 러닝 기록 등 활동 기록은 30일 안에 삭제되고, 법령에 따라 보관해야 하는 결제·거래 기록은 5년간 보관한 뒤 삭제됩니다. 이 작업은 되돌릴 수 없습니다. 계속하시겠습니까?
FR: Votre compte sera supprimé et le SHARE, le DIA et le VALUE que vous détenez seront perdus. Les données d'activité telles que l'historique de course seront supprimées dans un délai de 30 jours. Les données de paiement et de transaction devant être conservées par la loi seront conservées pendant 5 ans avant suppression. Cette action est irréversible. Voulez-vous continuer ?

[my_page.toast]
KO: ✅ 민감정보 수집 동의가 완료되었습니다. 이제 러닝을 시작할 수 있습니다!
FR: ✅ Le consentement à la collecte des informations sensibles est terminé. Vous pouvez maintenant commencer à courir !

[my_page.pace_calculator.body]
KO: 목표 페이스 계산기
FR: Calculateur d'allure cible

[my_page.pace_calculator.body.2]
KO: 유효한 거리와 목표 시간을 입력하세요.
FR: Veuillez saisir une distance et un temps cible valides.

[my_page.pace_calculator.body.3]
KO: 목표 페이스: $paceMin:${paceSec.toString().padLeft(2,
FR: Allure cible : $paceMin:${paceSec.toString().padLeft(2,

[my_page.pace_calculator.body.4]
KO: )} /km
예상 완주: $finish (${distance.toStringAsFixed(1)} km)
FR: )} /km
Fin estimée : $finish (${distance.toStringAsFixed(1)} km)

[my_page.pace_calculator.hint]
KO: 목표 거리 (km)
FR: Distance cible (km)

[my_page.pace_calculator.hint.2]
KO: 시
FR: h

[my_page.pace_calculator.hint.3]
KO: 분
FR: min

[my_page.pace_calculator.hint.4]
KO: 초
FR: s

[my_page.shoe_mileage_tracker.body]
KO: 러닝화 마일리지 트래커
FR: Suivi du kilométrage des chaussures

[my_page.shoe_mileage_tracker.body.2]
KO: 장착 중 · $skinName
FR: Équipé · $skinName

[my_page.shoe_mileage_tracker.body.3]
KO: ⚠️ 500km 도달! 쿠셔닝 성능 저하 위험 — 러닝화 교체를 권장합니다.
FR: ⚠️ 500km atteints ! Risque de perte d'amorti — remplacement des chaussures recommandé.

[my_page.shoe_mileage_tracker.body.4]
KO: 교체 알림: ${(goal - totalDistanceKm).toStringAsFixed(1)} km 남음
FR: Rappel de remplacement : encore ${(goal - totalDistanceKm).toStringAsFixed(1)} km

[my_tournaments.body]
KO: 내 대회
FR: Mes tournois

[my_tournaments.body.2]
KO: 참가한 대회와 참가 상태를 확인하세요.
FR: Consultez les tournois auxquels vous participez et votre statut.

[my_tournaments.body.3]
KO: 아직 참가한 대회가 없습니다.
FR: Vous n'avez encore participé à aucun tournoi.

[my_tournaments.body.4]
KO: 참가 중
FR: En cours

[my_tournaments.body.5]
KO: 지난 대회
FR: Tournois passés

[my_tournaments.body.6]
KO: 참가비 ${p.entryFeeShare} SHARE · ${p.tournament.recruitmentSummary}
FR: Frais d'inscription ${p.entryFeeShare} SHARE · ${p.tournament.recruitmentSummary}

[my_tournaments.body.7]
KO: 환불됨
FR: Remboursé

[app.notification1BodyPrefix]
KO: 중급 3km 챌린지 기록이 승인되어
FR: Votre enregistrement du Défi 3 km Intermédiaire a été approuvé et

[app.notification1BodySuffix]
KO: 이 지갑으로 자동 입금되었습니다.
FR: ont été automatiquement déposés dans votre portefeuille.

[app.notification1Highlight]
KO: 100 밸류 토큰(VALUE)
FR: 100 jetons VALUE

[app.notification1Time]
KO: 방금 전
FR: À l'instant

[app.notification1Title]
KO: 러닝 검증 완료!
FR: Course vérifiée !

[app.notification2BodyPrefix]
KO: 서울 나이트 러너스 방장님이
FR: Le chef de Seoul Night Runners vous a offert un

[app.notification2BodySuffix]
KO: 을 선물했습니다!
FR: !

[app.notification2Highlight]
KO: '기록 심폐소생권'
FR: 'Ticket de réanimation d'enregistrement'

[app.notification2Time]
KO: 2시간 전
FR: Il y a 2 heures

[app.notification2Title]
KO: 크루 방장님의 하사품
FR: Un cadeau du chef de crew

[app.notification3Body]
KO: 대회 무산으로 인해 50,000 SHARE 현금 환불이 정상 처리되었습니다.
FR: En raison de l'annulation de la compétition, le remboursement en espèces de 50 000 SHARE a bien été traité.

[app.notification3Time]
KO: 어제
FR: Hier

[app.notification3Title]
KO: 결제 취소 완료
FR: Paiement annulé

[app.notificationCenterTitle]
KO: 알림 및 내역 (History)
FR: Notifications et historique (History)

[app.notificationPaymentEmpty]
KO: 거래 및 결제 내역이 존재하지 않습니다. 🪙
FR: Aucun historique de transaction ou de paiement. 🪙

[app.notificationPaymentReceipt]
KO: 안전 결제 영수증 완료 🪙
FR: Reçu de paiement sécurisé finalisé 🪙

[app.notificationPaymentUnknown]
KO: 알 수 없는 거래
FR: Transaction inconnue

[app.notificationSystemEmpty]
KO: 도달한 새로운 알림이 없습니다. 🔔
FR: Aucune nouvelle notification reçue. 🔔

[app.notificationSystemFallbackTitle]
KO: 알림
FR: Notification

[app.notificationTabPayment]
KO: 결제/히스토리
FR: Paiements / Historique

[app.notificationTabSystem]
KO: 시스템 알림
FR: Notifications système

[notification_center.body]
KO: ${date.month}월 ${date.day}일
FR: ${date.day}/${date.month}

[onboarding.body]
KO: 쉐어런에 오신 걸 환영해요
FR: Bienvenue sur ShareRun

[onboarding.body.2]
KO: 서비스 이용 전 필수 약관에 동의해 주세요.
FR: Veuillez accepter les conditions obligatoires avant d'utiliser le service.

[onboarding.body.3]
KO: 아래는 일반 약관과 분리된 선택 동의입니다.
FR: Ci-dessous se trouvent les consentements optionnels séparés des conditions générales.

[onboarding.body.4]
KO: 동의합니다
FR: J'accepte

[onboarding.button]
KO: 저장 중...
FR: Enregistrement...

[onboarding.button.2]
KO: 동의하고 시작하기
FR: Accepter et commencer

[onboarding.toast]
KO: 온보딩 저장 실패: $error
FR: Échec de l'enregistrement de l'intégration : $error

[onboarding.nickname_change.body]
KO: 새로운 질주를 위한 이름을 새기시겠습니까?
FR: Souhaitez-vous graver un nouveau nom pour votre course ?

[onboarding.nickname_change.body.2]
KO: 러너님의 정체성을 정밀 등록합니다.
FR: Enregistrement précis de votre identité de coureur.

[onboarding.nickname_change.body.3]
KO: 보유 $diaBalance DIA  ·  변경 수수료 $fee DIA
FR: Solde $diaBalance DIA  ·  Frais de modification $fee DIA

[onboarding.nickname_change.body.4]
KO: 100 DIA 소모하여 변경하기
FR: Dépenser 100 DIA pour modifier

[onboarding.nickname_change.body.5]
KO: 다이아몬드 부족 - 교환소로 이동하기
FR: DIA insuffisants - Aller au centre d'échange

[onboarding.nickname_change.toast]
KO: 닉네임이 변경되었습니다. (${EconomyConstants.nicknameChangeFeeDia} DIA 차감)
FR: Pseudo modifié. (${EconomyConstants.nicknameChangeFeeDia} DIA déduits)

[onboarding.nickname_setup.body]
KO: 닉네임 및 캐릭터 가동
FR: Activation du pseudo et du personnage

[onboarding.nickname_setup.body.2]
KO: 홈에 표시될 닉네임을 정하면, 예선 등급에 맞는 대두 캐릭터가 함께 깨어납니다.
FR: Dès que vous choisissez un pseudo pour l'accueil, un personnage à grosse tête correspondant à votre niveau de qualification s'éveille.

[onboarding.nickname_setup.body.3]
KO: 설정 완료
FR: Terminer la configuration

[onboarding.nickname_setup.hint]
KO: 한글·영문·숫자 2~12자
FR: 2 à 12 lettres ou chiffres

[onboarding.src_onboarding_controller.body]
KO: 예비 천사 (Pre-Angel)
FR: Pré-ange (Pre-Angel)

[onboarding.src_onboarding_controller.body.10]
KO: 누적 20회 또는 누적 300,000 SHARE 이상
FR: 20 fois cumulées ou 300 000 SHARE cumulés ou plus

[onboarding.src_onboarding_controller.body.11]
KO: 누적 50회 또는 누적 1,000,000 SHARE 이상
FR: 50 fois cumulées ou 1 000 000 SHARE cumulés ou plus

[onboarding.src_onboarding_controller.body.12]
KO: 누적 100회 또는 누적 5,000,000 SHARE 이상
FR: 100 fois cumulées ou 5 000 000 SHARE cumulés ou plus

[onboarding.src_onboarding_controller.body.13]
KO: 등에 귀여운 날개 반창고를 붙인 마스코트
FR: Mascotte avec un pansement mignon en forme d'ailes sur le dos

[onboarding.src_onboarding_controller.body.14]
KO: 등 뒤 아기 날개 배지 장착
FR: Badge de petites ailes équipé sur le dos

[onboarding.src_onboarding_controller.body.15]
KO: 은빛 날개 · 대회 입장 시 닉네임 볼드 테두리 강조
FR: Ailes argentées · Pseudo mis en valeur avec une bordure en gras lors de l'entrée au tournoi

[onboarding.src_onboarding_controller.body.16]
KO: 황금 날개 · 골드 그라데이션 닉네임 · 개설 대회 러너 1.2배 VALUE 부스트
FR: Ailes dorées · Pseudo avec dégradé doré · Boost de VALUE x1,2 pour les coureurs des tournois créés

[onboarding.src_onboarding_controller.body.17]
KO: 4익 날개 · 민트 오라 · 대회 입장 시 단독 등장 팝업
FR: 4 ailes · Aura menthe · Pop-up d'entrée exclusive lors de l'entrée au tournoi

[onboarding.src_onboarding_controller.body.18]
KO: 6익 날개 · 골드 광배 회전 · 명예의 전당 VVIP 단독 배너
FR: 6 ailes · Auréole dorée rotative · Bannière exclusive VVIP du Hall of Fame

[onboarding.src_onboarding_controller.body.19]
KO: ${n.koreanName}까지 후원 $remainCount회
FR: Plus que $remainCount parrainages jusqu'à ${n.koreanName}

[onboarding.src_onboarding_controller.body.2]
KO: 큐피드
FR: Cupidon

[onboarding.src_onboarding_controller.body.20]
KO: ${n.koreanName}까지 $remainCount회 또는 ${formatWon(remainWon)}
FR: Plus que $remainCount fois ou ${formatWon(remainWon)} jusqu'à ${n.koreanName}

[onboarding.src_onboarding_controller.body.21]
KO: 알림을 켜면 이런 이득이 있어요
FR: Activer les notifications vous apporte ces avantages

[onboarding.src_onboarding_controller.body.22]
KO: 재화 실시간 입금 알림
FR: Notification de crédit des récompenses en temps réel

[onboarding.src_onboarding_controller.body.23]
KO: 소속 크루 방장 전체 공지 긴급 수신
FR: Réception urgente des annonces générales du chef de votre crew

[onboarding.src_onboarding_controller.body.24]
KO: 러닝화 수명 도달에 따른 부상 방지 수명 알림
FR: Alerte de prévention des blessures lorsque les chaussures de running atteignent leur fin de vie
