# 번역 검수 요청 — 쉐어런 (French) · 파트 7/8

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
[share_dia_exchange.body]
KO: 이번 주 남은 한도 ${quote.remainingDia} / ${quote.weeklyCapDia} DIA
FR: Limite hebdomadaire restante : ${quote.remainingDia} / ${quote.weeklyCapDia} DIA

[share_dia_exchange.body.2]
KO: ${quote.unitDia} DIA 단위 · 교환 가능 SHARE ${quote.spendableShare}
FR: Par tranches de ${quote.unitDia} DIA · SHARE échangeables : ${quote.spendableShare}

[share_dia_exchange.body.3]
KO: 추천 보상 잠금 ${quote.lockedShare} SHARE
FR: Récompense de parrainage verrouillée : ${quote.lockedShare} SHARE

[share_dia_exchange.button]
KO: SHARE → DIA 교환
FR: Échanger SHARE → DIA

[share_dia_exchange.button.2]
KO: DIA 팩 · 준비 중
FR: Pack DIA · Bientôt disponible

[share_dia_exchange.button.3]
KO: 교환 중...
FR: Échange en cours...

[share_dia_exchange.button.4]
KO: 교환
FR: Échanger

[share_dia_exchange.toast]
KO: ${result.rateSharePerDia} SHARE = 1 DIA 교환이 반영되었습니다.
FR: Échange de ${result.rateSharePerDia} SHARE = 1 DIA appliqué.

[shop.accessory_shop_grid.body]
KO: 아직 준비 중이에요
FR: En cours de préparation

[shop.accessory_shop_grid.body.2]
KO: ${accessory.tierLock!.labelKo} 티어
FR: Palier ${accessory.tierLock!.labelKo}

[shop.accessory_shop_grid.button]
KO: 가격은 바뀔 수 있어요.
FR: Les prix peuvent changer.

[shop.accessory_shop_grid.button.2]
KO: 입혀 보기
FR: Essayer

[shop.accessory_shop_grid.button.3]
KO: 벗기
FR: Enlever

[shop.accessory_shop_grid.button.4]
KO: 입기
FR: Mettre

[shop.accessory_shop_grid.button.5]
KO: ${a.tierLock!.labelKo} 티어가 되면 살 수 있어요
FR: Achetable au palier ${a.tierLock!.labelKo}

[shop.accessory_shop_grid.button.6]
KO: 사기 · ${a.priceLabel}
FR: Acheter · ${a.priceLabel}

[shop.accessory_shop_grid.button.7]
KO: 티어 보상이에요
FR: C'est une récompense de palier

[shop.accessory_shop_grid.toast]
KO: 서버에 연결되면 살 수 있어요.
FR: Vous pouvez acheter une fois connecté au serveur.

[shop.accessory_shop_grid.toast.2]
KO: }가 모자라거나 이미 가진 소품이에요.
FR: } insuffisant ou accessoire déjà possédé.

[shop.accessory_shop_grid.toast.3]
KO: 아직 티어가 모자라요.
FR: Votre palier n'est pas encore suffisant.

[shop.accessory_shop_grid.toast.4]
KO: 사지 못했어요. 잠시 뒤 다시 해 주세요.
FR: Échec de l'achat. Veuillez réessayer dans un instant.

[shop.battle_pass_grant.body]
KO: 시즌 1 프레임
FR: Cadre de la saison 1

[shop.battle_pass_grant.body.2]
KO: 시즌 1 배지
FR: Badge de saison 1

[shop.battle_pass_grant.body.3]
KO: 시즌 1 플러스 프레임
FR: Cadre Plus de saison 1

[shop.battle_pass_grant.body.4]
KO: 시즌 1 스킨
FR: Skin de saison 1

[shop.battle_pass_grant.body.5]
KO: 시즌 1 플러스 배지
FR: Badge Plus de saison 1

[shop.cosmetics_catalog.body]
KO: 러닝화 스킨
FR: Skin de chaussures de course

[shop.cosmetics_catalog.body.2]
KO: 결과 카드 프레임
FR: Cadre de carte de résultat

[shop.friend_ghost_run.body]
KO: ${AppStrings.storeItemFriendGhost} · 보유 $count
FR: ${AppStrings.storeItemFriendGhost} · Possédé(s) : $count

[shop.friend_ghost_run.body.2]
KO: 비교 시작
FR: Démarrer la comparaison

[shop.friend_ghost_run.hint]
KO: 친구 아이디
FR: ID de l'ami

[shop.friend_ghost_run.hint.2]
KO: 기록 아이디
FR: ID de l'enregistrement

[shop.friend_ghost_run.toast]
KO: 친구 고스트 페이스 보유량이 없습니다. 상점에서 구매해 주세요.
FR: Vous n'avez plus d'Allure fantôme d'ami. Veuillez en acheter dans la boutique.

[shop.friend_ghost_run.toast.2]
KO: 친구 고스트 ${formatPaceSecPerKm(pace)}
FR: Fantôme d'ami ${formatPaceSecPerKm(pace)}

[shop.friend_ghost_run.toast.3]
KO: 내 최고 기록 비교는 무료입니다. 티켓을 쓰지 않았습니다.
FR: La comparaison avec votre record personnel est gratuite. Aucun ticket n'a été utilisé.

[shop.friend_ghost_run.toast.4]
KO: 친구 기록을 확인하지 못했습니다.
FR: Impossible de vérifier l'enregistrement de l'ami.

[shop.friend_ghost_run.toast.5]
KO: 친구 고스트를 사용하지 못했습니다.
FR: Impossible d'utiliser le fantôme d'ami.

[shop.server_item_use_button.body]
KO: ${widget.label} · 보유 $count
FR: ${widget.label} · Possédé $count

[shop.server_item_use_button.button]
KO: ${widget.label} · 보유 $shown/$cap
FR: ${widget.label} · Possédé $shown/$cap

[shop.server_item_use_button.toast]
KO: ${widget.label} 보유량이 없습니다.
FR: Vous ne possédez aucun ${widget.label}.

[shop.server_item_use_button.toast.2]
KO: ${widget.label} 사용 완료
FR: ${widget.label} utilisé

[shop.server_item_use_button.toast.3]
KO: ${widget.label} 을 사용하지 못했습니다.
FR: Impossible d'utiliser ${widget.label}.

[shop.store_look.body]
KO: 심박·상황에 맞춘 심층 코칭
FR: Coaching approfondi adapté à la fréquence cardiaque et aux situations

[shop.store_look.body.2]
KO: 월간
FR: Mensuel

[shop.store_look.body.3]
KO: 연간
FR: Annuel

[shop.store_look.body.4]
KO: 보관함 $owned
FR: Inventaire $owned

[shop.streak_item_message.body]
KO: 세이프가드는 최대 2개까지 보유할 수 있습니다.
FR: Vous pouvez posséder jusqu'à 2 Safeguards.

[shop.streak_item_message.body.10]
KO: 그 기록에는 페이스가 없습니다.
FR: Cet enregistrement ne contient pas de données d'allure.

[shop.streak_item_message.body.11]
KO: 10회 묶음은 한 장씩 사용합니다.
FR: Le pack de 10 s'utilise un ticket à la fois.

[shop.streak_item_message.body.12]
KO: 이미 보유한 코스메틱입니다.
FR: Vous possédez déjà cet élément cosmétique.

[shop.streak_item_message.body.13]
KO: 이번 시즌에 판매하지 않는 아이템입니다.
FR: Cet article n'est pas en vente cette saison.

[shop.streak_item_message.body.14]
KO: 보유한 뒤에 장착할 수 있습니다.
FR: Vous pouvez l'équiper après l'avoir obtenu.

[shop.streak_item_message.body.15]
KO: 코스메틱은 사용해서 사라지지 않습니다.
FR: Les éléments cosmétiques ne disparaissent pas après utilisation.

[shop.streak_item_message.body.2]
KO: 심폐소생권은 한 달에 2번까지 사용할 수 있습니다.
FR: Les tickets de réanimation peuvent être utilisés jusqu'à 2 fois par mois.

[shop.streak_item_message.body.3]
KO: 되돌릴 끊긴 스트릭이 없습니다.
FR: Aucune série interrompue à restaurer.

[shop.streak_item_message.body.4]
KO: 스트릭이 끊긴 지 72시간이 지나 되돌릴 수 없습니다.
FR: Plus de 72 heures se sont écoulées depuis l'interruption de la série, elle ne peut donc pas être restaurée.

[shop.streak_item_message.body.5]
KO: 막을 빠진 날이 없습니다.
FR: Il n'y a aucun jour manqué à protéger.

[shop.streak_item_message.body.6]
KO: 추가 참가권은 대회에 참가할 때 사용됩니다.
FR: Les tickets d'entrée supplémentaires sont utilisés lors de la participation à des compétitions.

[shop.streak_item_message.body.7]
KO: 친구 기록을 찾지 못했습니다.
FR: Impossible de trouver l'enregistrement de l'ami.

[shop.streak_item_message.body.8]
KO: 그 기록은 선택한 친구의 기록이 아닙니다.
FR: Cet enregistrement n'appartient pas à l'ami sélectionné.

[shop.streak_item_message.body.9]
KO: 검증되지 않은 기록과는 비교할 수 없습니다.
FR: Impossible de comparer avec des enregistrements non vérifiés.

[app.watchSyncApple]
KO: Apple 건강 연동하기
FR: Associer Apple Santé

[app.watchSyncComplete]
KO: 연동 완료하고 시작하기
FR: Terminer la synchronisation et commencer

[app.watchSyncExternalDevices]
KO: 가민, 순토, 코로스 등 외부 전문 기기를 사용하시나요?
FR: Utilisez-vous des appareils spécialisés externes comme Garmin, Suunto ou COROS ?

[app.watchSyncGoogle]
KO: Google Health Connect 연동하기
FR: Associer Google Health Connect

[app.watchSyncSkip]
KO: 건너뛰기
FR: Ignorer

[app.watchSyncSubtitle]
KO: 러닝 검증을 위해 심박수와 걸음 수 데이터가 필요합니다.
FR: Les données de fréquence cardiaque et de pas sont requises pour la vérification de la course.

[app.watchSyncTitle]
KO: 정확한 기록 측정을 위해
스마트워치를 연결해 주세요.
FR: Veuillez connecter votre montre connectée
pour une mesure précise des enregistrements.

[snail_faq.body]
KO: 지금은 값을 불러오지 못했어요. 연결된 뒤에 다시 물어봐 주세요.
FR: Impossible de charger les valeurs pour le moment. Veuillez réessayer une fois connecté.

[snail_to_cheetah_book.body]
KO: 티어 도감
FR: Guide des rangs

[snail_to_cheetah_book.body.10]
KO: 달팽이 (Unrated)
FR: Escargot (Unrated)

[snail_to_cheetah_book.body.11]
KO: 등급 배정 전 임시 등급
FR: Rang provisoire avant attribution

[snail_to_cheetah_book.body.13]
KO: 빠른 걸음 및 기초 체력 형성 단계
FR: Étape de marche rapide et de développement de l'endurance de base

[snail_to_cheetah_book.body.14]
KO: 평균 페이스 7분 30초 이상
FR: Allure moyenne de 7'30" ou plus

[snail_to_cheetah_book.body.15]
KO: 가벼운 조깅을 즐기는 러닝 입문자
FR: Débutants appréciant un jogging léger

[snail_to_cheetah_book.body.16]
KO: 평균 페이스 6분 00초 ~ 7분 29초
FR: Allure moyenne de 6'00" à 7'29"

[snail_to_cheetah_book.body.17]
KO: 일반 동호인 / 표준 그룹
FR: Coureurs réguliers / Groupe standard

[snail_to_cheetah_book.body.18]
KO: 평균 페이스 5분 00초 ~ 5분 59초
FR: Allure moyenne de 5'00" à 5'59"

[snail_to_cheetah_book.body.19]
KO: 러닝 숙련자 수준
FR: Niveau coureur expérimenté

[snail_to_cheetah_book.body.2]
KO: 달릴수록 새로운 친구를 만나요
FR: Rencontrez de nouveaux amis au fil de vos courses

[snail_to_cheetah_book.body.20]
KO: 평균 페이스 4분 00초 ~ 4분 59초
FR: Allure moyenne de 4'00" à 4'59"

[snail_to_cheetah_book.body.21]
KO: 아마추어 최상위권 수준
FR: Niveau amateur d'élite

[snail_to_cheetah_book.body.22]
KO: 평균 페이스 4분 00초 미만
FR: Allure moyenne inférieure à 4'00"

[snail_to_cheetah_book.body.3]
KO: 25단계 연대기
FR: Chronique en 25 étapes

[snail_to_cheetah_book.body.4]
KO: 달팽이부터 치타까지 모든 등급을 열람할 수 있어요. 카드를 누르면 액세서리를 입혀 볼 수 있어요.
FR: Vous pouvez consulter tous les rangs, de l'Escargot au Guépard. Touchez une carte pour essayer des accessoires.

[snail_to_cheetah_book.body.5]
KO: 완료
FR: Terminé

[snail_to_cheetah_book.body.6]
KO: 현재
FR: Actuel

[snail_to_cheetah_book.body.7]
KO: 도전
FR: Défi

[snail_to_cheetah_book.body.8]
KO: 아직 티어가 없어요
FR: Vous n'avez pas encore de rang

[snail_to_cheetah_book.body.9]
KO: 첫 달리기가 심사되면 티어가 정해지고
옷과 소품을 입힐 수 있어요
FR: Une fois votre première course examinée, votre palier sera défini
et vous pourrez équiper des tenues et des accessoires

[snail_to_cheetah_book.button]
KO: 달리러 가기
FR: Aller courir

[solo_pedometer.body]
KO: 등급 목표 달성률: $percent%
FR: Taux d'atteinte de l'objectif de palier : $percent%

[solo_pedometer.body.10]
KO: 줍기 대기 : $pendingCoinsInt SHARE
FR: En attente de collecte : $pendingCoinsInt SHARE

[solo_pedometer.body.11]
KO: 워킹챌린지 혜택 알림 받는 중 🔔
FR: Réception des notifications d'avantages du défi marche 🔔

[solo_pedometer.body.12]
KO: 혜택 알림이 완전히 꺼져 있습니다 🔕
FR: Les notifications d'avantages sont complètement désactivées 🔕

[solo_pedometer.body.13]
KO: 알림 해지
FR: Désactiver les notifications

[solo_pedometer.body.14]
KO: 알림 받기
FR: Activer les notifications

[solo_pedometer.body.15]
KO: 월
FR: Lun

[solo_pedometer.body.16]
KO: 화
FR: Mar

[solo_pedometer.body.17]
KO: 수
FR: Mer

[solo_pedometer.body.18]
KO: 목
FR: Jeu

[solo_pedometer.body.19]
KO: 금
FR: Ven

[solo_pedometer.body.2]
KO: 등급 목표 달성 · 만보 달성!
FR: Objectif de palier atteint · 10 000 pas franchis !

[solo_pedometer.body.20]
KO: 토
FR: Sam

[solo_pedometer.body.21]
KO: 일
FR: Dim

[solo_pedometer.body.22]
KO: 이번 주 분석 일지
FR: Journal d'analyse de la semaine

[solo_pedometer.body.23]
KO: 날짜를 선택하면 그날의 걸음 수가 표시됩니다.
FR: Sélectionnez une date pour afficher le nombre de pas de cette journée.

[solo_pedometer.body.24]
KO: ${selected.month}월 ${selected.day}일의 누적 걸음수: ${_comma(displaySelectedSteps)}보
FR: Pas cumulés le ${selected.day}/${selected.month} : ${_comma(displaySelectedSteps)} pas

[solo_pedometer.body.3]
KO: 등급 목표 달성! 만보까지 ${comma(left)}걸음
FR: Objectif de palier atteint ! Plus que ${comma(left)} pas jusqu'à 10 000

[solo_pedometer.body.4]
KO: 아직 주울 SHARE가 없어요. 조금 더 걸어보세요.
FR: Pas encore de SHARE à collecter. Essayez de marcher encore un peu.

[solo_pedometer.body.5]
KO: 워킹챌린지
FR: Défi marche

[solo_pedometer.body.6]
KO: [${running.koreanName}] 산책 중
FR: En promenade avec [${running.koreanName}]

[solo_pedometer.body.7]
KO: 내 누적 SHARE 통장 🏦
FR: Mon solde SHARE cumulé 🏦

[solo_pedometer.body.8]
KO: 오늘의 땀방울 : $todayCollectedCoins / ${PedometerHarvestLedger.dailyShareCap} SHARE 🪙
FR: Effort du jour : $todayCollectedCoins / ${PedometerHarvestLedger.dailyShareCap} SHARE 🪙

[solo_pedometer.body.9]
KO: 걸음
FR: pas

[solo_pedometer.button]
KO: 나중에
FR: Plus tard

[solo_pedometer.button.2]
KO: 계속
FR: Continuer

[solo_pedometer.dialog]
KO: 걸음 수를 세려면 권한이 필요해요
FR: Autorisation requise pour compter les pas

[solo_pedometer.dialog.2]
KO: • 신체 활동: 폰이 센 걸음 수를 읽습니다.
• 건강 데이터(걸음): Health Connect에 기록된 걸음 수를 읽어 화면이 꺼져 있을 때의 걸음도 반영합니다.

걸음 수는 보상 계산에만 쓰이고, 동의하지 않아도 다른 기능은 쓸 수 있어요.
FR: • Activité physique : lit le nombre de pas comptés par votre téléphone.
• Données de santé (pas) : lit les pas enregistrés dans Health Connect afin d'inclure aussi les pas effectués écran éteint.

Le nombre de pas n'est utilisé que pour calculer les récompenses, et vous pouvez continuer à utiliser les autres fonctionnalités même sans donner votre accord.

[solo_pedometer.toast]
KO: SHARE를 줍는 중이에요. 잠시만 기다려 주세요.
FR: Collecte de SHARE en cours. Veuillez patienter.

[solo_pedometer.toast.2]
KO: SHARE 줍기에 실패했습니다. 네트워크를 확인한 뒤 다시 시도해 주세요.
FR: Échec de la collecte de SHARE. Veuillez vérifier votre réseau et réessayer.

[sponsor.sponsor_billboard.body]
KO: 검증된 달리기 1km마다 100원을 기부할 예정이에요
FR: Un don de 100 KRW est prévu pour chaque kilomètre de course vérifié

[sponsor_payment.body]
KO: 결제 준비 중...
FR: Préparation du paiement...

[sponsor_payment.body.2]
KO: 결제 진행하기
FR: Procéder au paiement

[sponsor_payment.body.3]
KO: 후원 결제
FR: Paiement du parrainage

[sponsor_payment.hint]
KO: 후원 금액
FR: Montant du parrainage

[sponsor_payment.title]
KO: 대회 후원
FR: Parrainage de compétition

[sponsor_payment.toast]
KO: 스폰서 결제가 대회에 반영되었습니다.
FR: Le paiement du parrainage a été appliqué à la compétition.

[sponsor_payment.toast.2]
KO: 후원 결제에 실패했어요: $error
FR: Échec du paiement du parrainage : $error

[stamp.stamp_tour_provider.body]
KO: 우리 동네 랜드마크 스탬프 찍기 ($officialVisitedCount/${officialLandmarks.length})
FR: Obtenir les tampons des lieux emblématiques du quartier ($officialVisitedCount/${officialLandmarks.length})

[stamp.stamp_tour_provider.body.10]
KO: 오늘의 1km 걷기 미션을 이미 완료했습니다.
FR: Vous avez déjà terminé la mission de marche de 1 km d'aujourd'hui.

[stamp.stamp_tour_provider.body.11]
KO: 1km 걷기 미션 완료! ${AppStrings.stampTourOfficialDiaPending}
FR: Mission de marche de 1 km terminée ! ${AppStrings.stampTourOfficialDiaPending}

[stamp.stamp_tour_provider.body.12]
KO: 아직 ${remain.toStringAsFixed(2)}km 더 걸어주세요.
FR: Veuillez marcher encore ${remain.toStringAsFixed(2)} km.

[stamp.stamp_tour_provider.body.13]
KO: 공식 DIA 대기 기록에 실패했습니다.
FR: Échec de l'enregistrement du DIA officiel en attente.

[stamp.stamp_tour_provider.body.2]
KO: 위치 권한이 필요합니다. 설정에서 허용해 주세요.
FR: L'autorisation de localisation est requise. Veuillez l'activer dans les paramètres.

[stamp.stamp_tour_provider.body.3]
KO: GPS 수신 중 오류가 발생했습니다.
FR: Une erreur s'est produite lors de la réception du signal GPS.

[stamp.stamp_tour_provider.body.4]
KO: 위치 추적을 시작할 수 없습니다.
FR: Impossible de démarrer le suivi de la localisation.

[stamp.stamp_tour_provider.body.5]
KO: 모든 공식 랜드마크 스탬프를 이미 획득했습니다.
FR: Vous avez déjà obtenu tous les tampons des lieux emblématiques officiels.

[stamp.stamp_tour_provider.body.6]
KO: 현재 위치를 확인할 수 없습니다. 위치 권한을 허용해 주세요.
FR: Impossible de déterminer votre position actuelle. Veuillez autoriser l'accès à la localisation.

[stamp.stamp_tour_provider.body.7]
KO: 목표 랜드마크 반경 50m 이내로 접근해 주세요.
FR: Veuillez vous approcher à moins de 50 mètres du lieu emblématique cible.

[stamp.stamp_tour_provider.body.8]
KO: ${unlocked.name} 스탬프 획득! ${AppStrings.stampTourOfficialDiaPending}
FR: Tampon de ${unlocked.name} obtenu ! ${AppStrings.stampTourOfficialDiaPending}

[stamp.stamp_tour_provider.body.9]
KO: ${unlocked.name} 개인 스탬프 기록됨 (공식 DIA 없음)
FR: Tampon personnel de ${unlocked.name} enregistré (pas de DIA officiel)

[app.dashboardStampTourCta]
KO: 스탬프 투어 확인하기
FR: Voir le tour des tampons

[app.stampTourLandmarkGangbyeon]
KO: 강변 공원
FR: Parc Gangbyeon

[app.stampTourLandmarkModoil]
KO: 모도일 공원
FR: Parc Modoil

[app.stampTourLandmarkNamsan]
KO: 남산타워
FR: Tour Namsan

[app.stampTourMissionStamp]
KO: 우리 동네 랜드마크 스탬프 찍기 (1/3)
FR: Obtenir les tampons des lieux emblématiques du quartier (1/3)

[app.stampTourMissionWalk]
KO: 오늘 가볍게 1km 걷기
FR: Marcher tranquillement 1 km aujourd'hui

[app.stampTourMissionWalkReward]
KO: DIA 지급 대기
FR: Distribution de DIA en attente

[app.stampTourStampCollected]
KO: 스탬프 완료
FR: Tampon obtenu

[app.stampTourTitle]
KO: 스탬프 투어 & 미션
FR: Tour des tampons et missions

[app.stampTourVisitComplete]
KO: 방문 완료!
FR: Visite terminée !

[stamp_tour.body]
KO: ${AppStrings.stampTourStampCollected} (개인)
FR: ${AppStrings.stampTourStampCollected} (Personnel)

[stamp_tour.body.2]
KO: 개인 스탬프 · 반경 50m
FR: Tampon personnel · Rayon 50 m

[stamp_tour.body.3]
KO: 공식 랜드마크 · 반경 50m
FR: Lieu emblématique officiel · Rayon 50 m

[stamp_tour.body.4]
KO: 서울
FR: Séoul

[stamp_tour.body.5]
KO: 획득 완료
FR: Obtenu

[store.body]
KO: ${_groupDigits(value)}원
FR: ${_groupDigits(value)} won

[store.body.2]
KO: $out원
FR: $out won

[app.iapBillingSubtitle]
KO: 구글 플레이 공식 보안 결제를 적용합니다.
FR: Utilise le paiement sécurisé officiel de Google Play.

[app.iapBillingTitle]
KO: 다이아 교환소
FR: Échange de DIA

[app.storeBuyDia]
KO: 30 DIA 구매
FR: Acheter 30 DIA

[app.storeFunctionalItems]
KO: 기능성 아이템
FR: Objets fonctionnels

[app.walletHistoryShortcutTooltip]
KO: 재화 히스토리
FR: Historique des devises

[subscription_management.body]
KO: 구독
FR: Abonnement

[subscription_management.body.2]
KO: 무료 기본 러닝 안내
심박·상황에 맞춘 심층 코칭
FR: Guide de course de base gratuit
Coaching approfondi selon fréquence cardiaque et situation

[app.termsAllAgree]
KO: [전체 동의] 쉐어런챌린지 이용약관
FR: [Tout accepter] Conditions d'utilisation de ShareRun Challenge

[app.termsOptionalHealth]
KO: [선택] 건강정보(심박수) 수집 및
이용 동의
FR: [Facultatif] Consentement à la collecte et à l'utilisation
des données de santé (fréquence cardiaque)

[app.termsRequiredAge14]
KO: [필수] 만 14세 이상입니다
FR: [Obligatoire] J'ai 14 ans ou plus

[app.termsRequiredLocation]
KO: [필수] 위치기반서비스 이용약관 동의
FR: [Obligatoire] Consentement aux conditions d'utilisation des services basés sur la localisation

[app.termsRequiredPrivacy]
KO: [필수] 개인정보 수집 및 이용 동의
FR: [Obligatoire] Consentement à la collecte et à l'utilisation des informations personnelles

[app.termsRequiredService]
KO: [필수] 쉐어런챌린지 서비스 이용약관
FR: [Obligatoire] Conditions d'utilisation du service ShareRun Challenge

[app.termsSubtitle]
KO: 안전하고 공정한 쉐어런 생태계를 위해 필수
항목에 동의해 주세요.
FR: Veuillez accepter les éléments requis pour garantir un écosystème
ShareRun sûr et équitable.

[app.termsTitle]
KO: 환영합니다!
시작 전 약관 동의가
필요합니다.
FR: Bienvenue !
Vous devez accepter les conditions
avant de commencer.

[tournament.body]
KO: 내 티어 $userTier
FR: Mon palier $userTier

[tournament.body.10]
KO: 그 밖의 대회
FR: Autres tournois

[tournament.body.11]
KO: 낮은 등급 대회는 참가할 수 없어요
FR: Vous ne pouvez pas participer à des tournois de niveau inférieur

[tournament.body.12]
KO: 이미 참가했어요
FR: Déjà inscrit

[tournament.body.13]
KO: 모집이 끝났어요
FR: Les inscriptions sont terminées

[tournament.body.14]
KO: 후원  ${displaySponsorName(room.sponsorName)}
FR: Sponsor  ${displaySponsorName(room.sponsorName)}

[tournament.body.15]
KO: 목표 거리
FR: Distance cible

[tournament.body.16]
KO: 참가비
FR: Frais d'inscription

[tournament.body.17]
KO: 모집
FR: Inscriptions

[tournament.body.18]
KO: 이 대회 후원하기
FR: Sponsoriser ce tournoi

[tournament.body.19]
KO: 내 대회 ($count)
FR: Mes tournois ($count)

[tournament.body.2]
KO: 검증된 달리기 1km마다 100원을 기부할 예정이에요.
FR: Un don de 100 KRW est prévu pour chaque kilomètre de course vérifié.

[tournament.body.3]
KO: 회사(운영자) 자금으로 기부할 예정이며 월 한도가 있어요. 기부처는 협의 중이고 정해지면 알려 드려요.
FR: Les dons sont prévus sur les fonds de l'entreprise (opérateur), avec un plafond mensuel. L'organisme bénéficiaire est encore en discussion et sera communiqué une fois désigné.

[tournament.body.4]
KO: 아직 열린 대회가 없어요
FR: Aucun tournoi n'est ouvert pour l'instant

[tournament.body.5]
KO: 새 대회가 열리면 여기에 나타나요.
FR: Lorsqu'un nouveau tournoi s'ouvrira, il apparaîtra ici.

[tournament.body.6]
KO: 티어 대회
FR: Tournoi de palier

[tournament.body.7]
KO: 등급을 받으면 참가할 수 있어요
FR: Vous pouvez participer dès que vous obtenez un palier

[tournament.body.8]
KO: 자유 대회
FR: Tournoi ouvert

[tournament.body.9]
KO: 누구나 참가 · 승급 점수 절반
FR: Accessible à tous · Points de promotion réduits de moitié

[tournament.button]
KO: 무료 참가권으로 참가
FR: Participer avec un ticket gratuit

[tournament_detail.body]
KO: 대회를 찾을 수 없습니다.
FR: Concours introuvable.

[tournament_detail.body.10]
KO: 상태: ${_statusKo(room.status)}
FR: Statut : ${_statusKo(room.status)}

[tournament_detail.body.11]
KO: 목표 거리: ${room.targetDistanceKm.toStringAsFixed(1)} km
FR: Distance cible : ${room.targetDistanceKm.toStringAsFixed(1)} km

[tournament_detail.body.12]
KO: 참가비: $entryFeeShare SHARE
FR: Frais d'inscription : $entryFeeShare SHARE

[tournament_detail.body.13]
KO: 참가비: $feeText
FR: Frais d'inscription : $feeText

[tournament_detail.body.14]
KO: 모집 인원이 차지 않아 참가비를 돌려드렸어요.
FR: Les frais d'inscription vous ont été remboursés car le nombre minimum de participants n'a pas été atteint.

[tournament_detail.body.15]
KO: 참가 상태: ${participantStatus ==
FR: Statut de participation : ${participantStatus ==

[tournament_detail.body.16]
KO: 참가일: ${_formatDate(joinedAt!)}
FR: Date d'inscription : ${_formatDate(joinedAt!)}

[tournament_detail.body.17]
KO: 모집 중
FR: Recrutement en cours

[tournament_detail.body.18]
KO: 진행 중
FR: En cours

[tournament_detail.body.19]
KO: 취소됨
FR: Annulé

[tournament_detail.body.2]
KO: 추가 참가권으로 참가
FR: Participer avec un ticket supplémentaire

[tournament_detail.body.20]
KO: 인원 미달로 취소됨
FR: Annulé faute de participants

[tournament_detail.body.21]
KO: 종료
FR: Terminé

[tournament_detail.body.3]
KO: ${room.entryFeeShare} SHARE로 참가
FR: Participer pour ${room.entryFeeShare} SHARE

[tournament_detail.body.4]
KO: 로그인 후 참가할 수 있습니다.
FR: Vous devez vous connecter pour participer.

[tournament_detail.body.5]
KO: 현재 티어에서는 참가할 수 없습니다.
FR: Impossible de participer depuis votre niveau actuel.

[tournament_detail.body.6]
KO: 정원이 가득 찼습니다.
FR: Capacité maximale atteinte.

[tournament_detail.body.7]
KO: 모집이 종료된 대회입니다.
FR: Les inscriptions à ce concours sont terminées.

[tournament_detail.body.8]
KO: 스폰서 후원하기
FR: Parrainer

[tournament_detail.body.9]
KO: 후원: ${displaySponsorName(room.sponsorName)}
FR: Sponsor : ${displaySponsorName(room.sponsorName)}

[tournament_detail.button]
KO: 이미 참가한 대회입니다.
FR: Déjà inscrit

[tournament_detail.button.2]
KO: 대회 목록에서 보기
FR: Voir dans la liste des concours

[tournament_detail.button.3]
KO: 러닝 시작하기
FR: Commencer la course

[tournament_detail.title]
KO: 대회 상세
FR: Détails du concours

[tournament_model.body]
KO: 참가자 $participantCount/$maxParticipants명
FR: $participantCount/$maxParticipants participants

[tournament_model.body.2]
KO: 참가자 $participantCount명
FR: $participantCount participants

[tournament_model.body.3]
KO: 기부 풀: $donationValue VALUE
FR: Cagnotte de don : $donationValue VALUE

[tournament_model.body.4]
KO: 쉐어런 대회
FR: Tournoi ShareRun

[tournament_model.body.5]
KO: 쉐어런 스폰서
FR: Sponsor de ShareRun

[tournaments.prize_display.body]
KO: ${won ~/ 10000}만 원 상당 다이아
FR: DIA d'une valeur de ${won ~/ 10000}0 000 KRW

[tournaments.prize_display.body.2]
KO: ${_grouped(won)}원 상당 다이아
FR: DIA d'une valeur de ${_grouped(won)} KRW

[tournaments.prize_display.body.3]
KO: 상금을 확인하는 중이에요
FR: Vérification de la récompense...

[tournaments.prize_display.body.4]
KO: 상금을 불러오지 못했어요
FR: Impossible de charger la récompense

[tournaments.prize_race_entry.body]
KO: 참가비 확인 중
FR: Vérification des frais d'inscription

[tournaments.prize_race_entry.body.2]
KO: 참가비를 불러오지 못했습니다
FR: Impossible de charger les frais d'inscription

[tournaments.prize_race_entry.body.3]
KO: 무료 참가
FR: Entrée gratuite

[tournaments.prize_race_entry.body.4]
KO: 무료 참가권 $ticketCost장
FR: $ticketCost billet(s) d'entrée gratuite

[tournaments.prize_race_entry.body.5]
KO: $entryShare SHARE 또는 무료 참가권 $ticketCost장
FR: $entryShare SHARE ou $ticketCost billet(s) d'entrée gratuite

[tournaments.prize_race_entry.body.6]
KO: $base · 보유 $held장
FR: $base · En possession : $held

[tournaments.prize_race_entry.body.7]
KO: $freeEntryLabel로 참가
FR: Participer avec $freeEntryLabel

[tournaments.prize_race_entry.body.8]
KO: $entryShare SHARE로 참가
FR: Participer avec $entryShare SHARE

[tournaments.prize_race_entry.body.9]
KO: 무료 참가권 $ticketCost장으로 참가
FR: Participer avec $ticketCost billet(s) d'entrée gratuite

[tournaments.sponsor_display.body]
KO: 운영자
FR: Opérateur

[tournaments.tournament_join_flow.body]
KO: 로그인 후 챌린지에 참가할 수 있습니다.
FR: Connectez-vous pour participer au défi.

[tournaments.tournament_join_flow.body.2]
KO: 이미 참가한 챌린지입니다.
FR: Vous participez déjà à ce défi.

[tournaments.tournament_join_gate.body]
KO: SHARE 잔액이 부족합니다.
FR: Solde de SHARE insuffisant.

[tournaments.tournament_join_outcome.body]
KO: 이미 참가한 챌린지입니다. 참가비는 다시 차감되지 않습니다.
FR: Vous participez déjà à ce défi. Les frais d'inscription ne seront pas déduits à nouveau.

[tournaments.tournament_join_outcome.body.2]
KO: 참가가 거절되었습니다. 참가비는 차감되지 않았습니다.
FR: Participation refusée. Les frais d'inscription n'ont pas été déduits.

[tournaments.tournament_join_outcome.body.3]
KO: 참가·결제가 완료되지 않았습니다. 서버 연결 또는 인증에 실패했습니다.
FR: La participation/le paiement n'a pas pu être finalisé. Échec de la connexion au serveur ou de l'authentification.

[tournaments.tournament_join_outcome.body.4]
KO: 참가 완료.
FR: Inscription terminée.

[tournaments.tournament_join_outcome.body.5]
KO: 참가 완료. 참가비 $fee SHARE가 잠겼습니다.
FR: Inscription terminée. Les frais d'inscription de $fee SHARE ont été verrouillés.

[tournaments.tournament_join_outcome.body.6]
KO: 참가 완료(디버그). 참가비 $fee SHARE가 차감되었습니다.
FR: Inscription terminée (débogage). Les frais d'inscription de $fee SHARE ont été déduits.

[user_model.body]
KO: 미연동
FR: Non associé

[user_model.body.2]
KO: 여
FR: F

[user_model.body.3]
KO: 여성
FR: Femme

[voice_coaching.voice_coaching_cues.body]
KO: 보이스 코칭을 켤게요.
FR: Activation du coaching vocal.

[voice_coaching.voice_coaching_cues.body.10]
KO: 심박이 좋아요. 이 페이스 유지해요.
FR: Votre fréquence cardiaque est bonne. Maintenez cette allure.

[voice_coaching.voice_coaching_cues.body.11]
KO: 심박이 내려왔어요. 페이스 유지해요.
FR: Votre fréquence cardiaque a baissé. Maintenez votre allure.

[voice_coaching.voice_coaching_cues.body.12]
KO: 천 보 달성! 좋아요.
FR: 1 000 pas atteints ! Très bien.

[voice_coaching.voice_coaching_cues.body.13]
KO: 삼천 보예요. 페이스 잘 유지하고 있어요.
FR: 3 000 pas. Vous maintenez une bonne allure.

[voice_coaching.voice_coaching_cues.body.14]
KO: 오천 보! 잘하고 있어요.
FR: 5 000 pas ! Vous vous débrouillez très bien.

[voice_coaching.voice_coaching_cues.body.15]
KO: 팔천 보. 거의 다 왔어요.
FR: 8 000 pas. C'est presque terminé.

[voice_coaching.voice_coaching_cues.body.16]
KO: 만 보 달성! 오늘 정말 잘했어요.
FR: 10 000 pas atteints ! Vous avez vraiment assuré aujourd'hui.

[voice_coaching.voice_coaching_cues.body.17]
KO: $steps보 달성! 좋아요.
FR: $steps pas atteints ! Très bien.

[voice_coaching.voice_coaching_cues.body.18]
KO: 1킬로미터. 호흡 유지하고 가요.
FR: 1 kilomètre. Maintenez votre respiration et continuez.
