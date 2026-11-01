# 번역 검수 요청 — 쉐어런 (French) · 파트 3/8

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
[iap.payment_auth.body.5]
KO: 결제를 진행하려면 본인 확인이 필요해요.
FR: La vérification d'identité est requise pour procéder au paiement.

[iap.purchases_closed.body]
KO: 안내
FR: Information

[iap.purchases_closed.title]
KO: 이 버전에서는 앱 안 결제를 받지 않아요.
FR: Les achats intégrés ne sont pas disponibles dans cette version.

[in_app_billing.body]
KO: DIA · SHARE로 교환
FR: Échanger contre DIA · SHARE

[in_app_billing.body.2]
KO: Play 상품 준비 중 · 결제해도 DIA가 지급되지 않습니다
FR: Produits Play en cours de préparation · Aucun DIA ne sera attribué même en cas de paiement

[in_challenge.body]
KO: 센서 준비 중...
FR: Préparation des capteurs...

[in_challenge.body.2]
KO: Jena 검증 중...
FR: Vérification par Jena en cours...

[in_challenge.body.3]
KO: 제출 기회: ${widget.submissionsRemaining}/${widget.maxSubmissions}회 남음
FR: Soumissions restantes : ${widget.submissionsRemaining}/${widget.maxSubmissions}

[in_challenge.body.4]
KO: 센서 시작 실패: $e
FR: Échec du démarrage du capteur : $e

[in_challenge.body.5]
KO: 심박수
FR: Fréquence cardiaque

[in_challenge.body.6]
KO: 위치 권한이 필요합니다.
FR: L'autorisation de localisation est requise.

[in_challenge.body.7]
KO: Google Maps API 키가 설정되지 않았습니다.
FR: La clé API Google Maps n'est pas configurée.

[in_challenge.body.8]
KO: 러닝 데이터를 검증 중입니다...
FR: Vérification des données de course...

[in_challenge.button]
KO: 강제 정지 대신 소명 기회가 부여되었습니다. 증빙 자료를 제출해 주세요.
FR: Une opportunité de justification a été accordée au lieu d'une suspension. Soumettez vos preuves.

[in_challenge.button.2]
KO: 소명하러 가기
FR: Déposer un recours

[in_challenge.button.3]
KO: 시스템 설정 열기
FR: Ouvrir les paramètres

[in_challenge.dialog]
KO: 기록 검증 보류
FR: Avis : vérification de l’activité en attente

[in_challenge.toast]
KO: Jena 검증 실패: ${ApiErrorMessage.from(error)}
FR: Échec de la vérification Jena : ${ApiErrorMessage.from(error)}

[app.itemInventoryBoostRunQuantityNote]
KO: 하루 1회 · 15분간 줍는 SHARE 2배 · 추가분 +240
FR: 1 fois par jour · SHARE collectés doublés pendant 15 min · Supplément +240

[app.itemInventoryCoachOnePointHint]
KO: 러닝을 시작하면 사용됩니다. 하루 1회.
FR: Utilisé au début de la course. 1 fois par jour.

[app.itemInventoryCprQuantity]
KO: 보유량: 3/3
FR: En possession : 3/3

[app.itemInventoryCrewCheerHint]
KO: 하루 1회. 대회 SHARE 보상만 10% 늘어납니다.
FR: 1 fois par jour. Seules les récompenses en SHARE de concours augmentent de 10 %.

[app.itemInventoryDonationMatchNote]
KO: 100 VALUE. 운영자 명의 1,000원이 러닝 기부 풀에 더해지고 내 이름이 함께 표시됩니다. 영수증은 없습니다.
FR: 100 VALUE. 1 000 KRW au nom de l'opérateur sont ajoutés au fonds de dons de course et votre nom est affiché. Aucun reçu n'est délivré.

[app.itemInventoryDonationMatchUse]
KO: 매칭하기
FR: Associer

[app.itemInventoryExtraEntryHint]
KO: 모집 마감·정원 초과 참가 시 사용됩니다. 하루 2회.
FR: Utilisé pour participer après la clôture ou en dépassement d'effectif. 2 fois par jour.

[app.itemInventoryFriendGhostHint]
KO: 러닝 중 친구 기록과 비교합니다. 내 최고 기록은 무료입니다.
FR: Compare avec le record d'un ami pendant la course. Votre propre record personnel est gratuit.

[app.itemInventoryRestDayNote]
KO: 매주 1회 무료. 추가 보유분만 VALUE로 샀습니다. 휴식일은 출석으로 세지 않고 스트릭도 끊지 않습니다.
FR: Gratuit 1 fois par semaine. Seules les réserves supplémentaires ont été achetées avec VALUE. Les jours de repos ne comptent pas comme présence et n'interrompent pas la série.

[app.itemInventoryRestDayToday]
KO: 오늘 휴식
FR: Repos aujourd'hui

[app.itemInventoryRestDayYesterday]
KO: 어제 휴식
FR: Repos hier

[app.itemInventorySafeGuardQuantity]
KO: 보유량: 1/1
FR: En possession : 1/1

[app.itemInventoryTitle]
KO: 내 아이템 보관함
FR: Mon inventaire d'objets

[app.itemInventoryUse]
KO: 사용하기
FR: Utiliser

[item_inventory.body]
KO: 보유량: ${shop.cprCount}
FR: En possession : ${shop.cprCount}

[item_inventory.body.2]
KO: 보유량: ${shop.safeGuardCount}
FR: En possession : ${shop.safeGuardCount}

[item_inventory.body.3]
KO: 보유량: ${shop.coachOnePointCount}
FR: En possession : ${shop.coachOnePointCount}

[item_inventory.body.4]
KO: 보유량: ${shop.extraEntryCount}
FR: En possession : ${shop.extraEntryCount}

[item_inventory.body.5]
KO: 보유량: ${shop.friendGhostCount}
FR: En possession : ${shop.friendGhostCount}

[item_inventory.body.6]
KO: 보유량: ${shop.crewCheerCount}
FR: En possession : ${shop.crewCheerCount}

[item_inventory.body.7]
KO: 보유량: ${shop.boostRunCount}
${AppStrings.itemInventoryBoostRunQuantityNote}
FR: Quantité possédée : ${shop.boostRunCount}
${AppStrings.itemInventoryBoostRunQuantityNote}

[item_inventory.body.8]
KO: 보유량: ${shop.stepIncubatorCount}
${AppStrings.itemInventoryStepIncubatorQuantityNote}
FR: Quantité possédée : ${shop.stepIncubatorCount}
${AppStrings.itemInventoryStepIncubatorQuantityNote}

[item_inventory.body.9]
KO: 추가 보유: ${shop.restDayCount}
${AppStrings.itemInventoryRestDayNote}
FR: Réserve supplémentaire : ${shop.restDayCount}
${AppStrings.itemInventoryRestDayNote}

[item_inventory.toast]
KO: 이미 처리된 매칭입니다. VALUE는 한 번만 차감됩니다.
FR: Match déjà traité. Les VALUE ne seront déduits qu'une seule fois.

[item_inventory.toast.2]
KO: 기부 매칭을 기록했습니다.
FR: Match de don enregistré.

[item_inventory.toast.3]
KO: 기부 매칭을 기록하지 못했습니다.
FR: Impossible d'enregistrer le match de don.

[item_inventory.toast.4]
KO: 이미 처리된 휴식일 지정입니다.
FR: Désignation de jour de repos déjà traitée.

[item_inventory.toast.5]
KO: $label 완료
FR: $label terminé

[item_inventory.toast.6]
KO: 휴식일을 지정하지 못했습니다.
FR: Impossible de définir le jour de repos.

[item_inventory.toast.7]
KO: $title 보유량이 없습니다. 상점에서 구매해 주세요.
FR: Vous n'avez pas de $title. Veuillez en acheter dans la boutique.

[item_inventory.toast.8]
KO: $title 사용 완료
FR: $title utilisé

[item_inventory.toast.9]
KO: $title 을 사용하지 못했습니다.
FR: Impossible d'utiliser $title.

[jena_validation.jena_pending_gate.body]
KO: 케이던스(발구름) 데이터가 없거나 0입니다. 기록이 보류되었습니다.
FR: Les données de cadence sont manquantes ou nulles. Votre enregistrement a été mis en attente.

[jena_validation.jena_pending_gate.body.2]
KO: 심박수 추이가 페이스 증가에 반응하지 않아 차량·자전거·킥보드 탑승이 의심됩니다.
FR: Votre fréquence cardiaque n'a pas réagi à l'augmentation de l'allure, ce qui suggère l'utilisation d'un véhicule, d'un vélo ou d'une trottinette.

[jena_validation.jena_pending_gate.body.3]
KO: GPS 오차 범위를 넘는 순간 이동 속도가 검출되어 기록이 거절되었습니다.
FR: Une vitesse de déplacement instantanée dépassant la marge d'erreur du GPS a été détectée ; l'enregistrement a été rejeté.

[jena_validation.jena_pending_gate.body.4]
KO: 비정상적인 GPS 순간 속도가 검출되어 기록이 보류되었습니다.
FR: Une vitesse instantanée GPS anormale a été détectée ; l'enregistrement a été mis en attente.

[jena_validation.mock_jena_validation_service.body]
KO: GPS 궤적 또는 거리 데이터가 부족합니다.
FR: Données de tracé GPS ou de distance insuffisantes.

[jena_validation.mock_jena_validation_service.body.2]
KO: 순수 노력 러닝으로 Jena AI 검증이 완료되었습니다.
FR: Vérification Jena AI terminée en tant que course d'effort authentique.

[jena_validation.verification_guidance.body]
KO: 이번 대회의 검증 최소 거리는 $distance예요. 대회 거리가 더 짧아도 1km는 넘어야 해요.
FR: La distance minimale de vérification pour cette compétition est de $distance. Même si la distance de la compétition est inférieure, elle doit dépasser 1 km.

[jena_validation.verification_guidance.body.2]
KO: 분당 걸음 수는 120~210이어야 해요.
FR: Le nombre de pas par minute doit être compris entre 120 et 210.

[jena_validation.verification_guidance.body.3]
KO: 워치 심박은 운영자 대회 상급·하프·파이널에서만 필요해요.
FR: La fréquence cardiaque de la montre n'est requise que pour les compétitions de l'organisateur aux niveaux Avancé, Semi-marathon et Finale.

[jena_validation.verification_guidance.body.4]
KO: 이 대회는 워치 심박이 있어야 완주로 인정돼요.
FR: Cette compétition nécessite la fréquence cardiaque de la montre pour valider l'arrivée.

[jena_validation.verification_guidance.body.5]
KO: 기록은 언제나, 보상은 검증된 달리기에만.
FR: L'enregistrement est toujours garanti, les récompenses ne sont remises que pour les courses vérifiées.

[jena_validation.verification_guidance.body.6]
KO: 검증 안내
FR: Guide de vérification

[jena_validation.verification_guidance.body.7]
KO: 확인하고 참가
FR: Confirmer et participer

[jena_validation.verification_guidance.body.8]
KO: 다시 보지 않기
FR: Ne plus afficher

[jena_validation.verification_reason.body]
KO: 거리가 이번 대회의 최소 거리보다 짧아요. 대회 거리만큼, 적어도 1km는 달려야 해요. 기록은 남고 보상은 지급되지 않아요.
FR: La distance est inférieure à la distance minimale de cette compétition. Vous devez courir au moins la distance de la compétition et au minimum 1 km. L'enregistrement est conservé, mais aucune récompense n'est accordée.

[jena_validation.verification_reason.body.2]
KO: 분당 걸음 수가 120~210 범위를 벗어났어요. 기록은 남고 보상은 지급되지 않아요.
FR: Le nombre de pas par minute était en dehors de la plage de 120 à 210. L'enregistrement est conservé, mais aucune récompense n'est accordée.

[jena_validation.verification_reason.body.3]
KO: 상급·하프·파이널 대회는 워치 심박이 있어야 완주로 인정돼요. 심박이 없어 보상은 지급되지 않아요.
FR: Les compétitions Avancé, Semi-marathon et Finale nécessitent la fréquence cardiaque de la montre pour valider l'arrivée. En l'absence de fréquence cardiaque, aucune récompense n'est accordée.

[jena_validation.verification_reason.body.4]
KO: 평균 심박이 달리기라고 보기엔 낮아요. 기록은 남고 보상은 지급되지 않아요.
FR: La fréquence cardiaque moyenne est trop faible pour correspondre à une course. L'enregistrement est conservé, mais aucune récompense n'est accordée.

[jena_validation.verification_reason.body.5]
KO: 심박이 거의 변하지 않아 달리기로 확인되지 않았어요. 기록은 남고 보상은 지급되지 않아요.
FR: La fréquence cardiaque n'a presque pas varié, l'activité n'a donc pas pu être confirmée comme une course. L'enregistrement est conservé, mais aucune récompense n'est accordée.

[jena_validation.verification_reason.body.6]
KO: 워치가 없어 보폭을 확인했는데, 거리와 걸음 수가 달리기 범위가 아니에요. 기록은 남고 보상은 지급되지 않아요.
FR: En l'absence de montre, la foulée a été vérifiée, mais la distance et le nombre de pas ne correspondent pas à une course. L'enregistrement est conservé, mais aucune récompense n'est accordée.

[jena_validation.verification_reason.body.7]
KO: 이동 속도가 차량에 가까워 달리기로 인정되지 않았어요. 기록은 남고 보상은 지급되지 않아요.
FR: La vitesse de déplacement était proche de celle d'un véhicule et n'a pas été reconnue comme une course. L'enregistrement est conservé, mais aucune récompense n'est accordée.

[jena_validation.verification_reason.body.8]
KO: 킥보드나 탑승으로 보여 보상은 지급되지 않아요. 기록은 남아요.
FR: Il semble s'agir d'une utilisation de trottinette ou d'un véhicule, aucune récompense n'est donc accordée. L'enregistrement est conservé.

[jena_validation.verification_reason.body.9]
KO: 자전거 탑승으로 보여 보상은 지급되지 않아요. 기록은 남아요.
FR: Il semble s'agir d'un trajet à vélo, aucune récompense n'est donc accordée. L'enregistrement est conservé.

[launch.intro.body]
KO: 걸으면 SHARE가 쌓여요
FR: Marchez pour cumuler des SHARE

[launch.intro.body.10]
KO: +100원
FR: +100 wons

[launch.intro.body.11]
KO: 회사(운영자) 자금으로 기부 예정 · 내가 내는 돈은 없어요 · 내 기여는 앱에서 확인
FR: Prévu sur les fonds de l'entreprise (opérateur) · Aucun frais pour vous · Vérifiez votre contribution dans l'application

[launch.intro.body.13]
KO: 지금
달팽이
FR: Actuel
Escargot

[launch.intro.body.14]
KO: 등급을
받으면
FR: Une fois
classé

[launch.intro.body.15]
KO: 티어가
오르면
FR: En montant
de palier

[launch.intro.body.2]
KO: 한 걸음이 나눔이 된다
FR: Chaque pas devient un partage

[launch.intro.body.3]
KO: 내 기록은 어느 폰에서나 그대로예요
FR: Vos données restent identiques sur n'importe quel téléphone

[launch.intro.body.4]
KO: 100걸음마다 10 SHARE를 받아요. 모은 SHARE로 대회에 참가할 수 있어요.
FR: Recevez 10 SHARE tous les 100 pas. Utilisez les SHARE cumulés pour participer à des compétitions.

[launch.intro.body.5]
KO: SHARE는 현금으로 바꿀 수 없는 활동 보상이고, 하루에 받을 수 있는 양에 한도가 있어요.
FR: SHARE est une récompense d'activité qui ne peut pas être échangée contre de l'argent réel, et le montant quotidien pouvant être reçu est limité.

[launch.intro.body.6]
KO: 검증된 모든 달리기, 1km마다 운영자가 100원을 기부할 예정이에요. 내가 보탠 만큼은 앱에서 확인할 수 있어요.
FR: Pour chaque course vérifiée, l'opérateur prévoit de donner 100 wons par kilomètre. Vous pouvez vérifier votre contribution dans l'application.

[launch.intro.body.7]
KO: 운영자의 월 기부 예산 안에서 진행될 예정이에요. 예산을 다 쓴 달은 넘는 거리가 기록으로 남아요.
FR: Cela est prévu dans la limite du budget mensuel de dons de l'opérateur. Si le budget est épuisé au cours du mois, la distance excédentaire reste enregistrée.

[launch.intro.body.8]
KO: 걷기·달리기 기록은 서버에 저장돼요. 폰을 바꿔도 로그인하면 이어져요.
FR: Les enregistrements de marche et de course sont sauvegardés sur le serveur. Même si vous changez de téléphone, connectez-vous pour continuer.

[launch.intro.body.9]
KO: 100걸음
FR: 100 pas

[launch.intro.button]
KO: 시작하기
FR: Commencer

[launch.intro.button.2]
KO: 이미 계정이 있어요 · 로그인
FR: J'ai déjà un compte · Connexion

[legal.health_data_consent.body]
KO: 체크해야 워치 연동·심박 검증이 활성화됩니다.
FR: Cochez pour activer la synchronisation de la montre et la vérification de la fréquence cardiaque.

[legal_constants.body]
KO: 결제 취소 (현금 환불)
FR: Annuler le paiement (remboursement en espèces)

[legal_constants.body.10]
KO: 마케팅·활동 알림 (선택)
FR: Notifications de marketing et d'activité (Facultatif)

[legal_constants.body.12]
KO: 부정 러닝·결제 어뷰징은 계정 제한 대상이 될 수 있습니다.
FR: Les courses frauduleuses et l'abus de paiement peuvent faire l'objet de restrictions de compte.

[legal_constants.body.14]
KO: 전체 내용은 개인정보 처리방침 전문에서 확인할 수 있습니다.
FR: Vous pouvez consulter l'intégralité des détails dans la politique de confidentialité complète.

[legal_constants.body.17]
KO: 대회 모집, 검증 결과, 리워드·기부 알림을 푸시로 받을 수 있습니다. 언제든 MyPage에서 변경할 수 있습니다.
FR: Vous pouvez recevoir des notifications push concernant les inscriptions aux compétitions, les résultats de vérification, les récompenses et les dons. Vous pouvez modifier cela à tout moment dans MyPage.

[legal_constants.body.18]
KO: 심박수·케이던스 원본 데이터는 기기 메모리에서 검증한 뒤 바로 폐기하며, 검증 결과 요약만 저장합니다.
FR: Les données brutes de fréquence cardiaque et de cadence sont supprimées immédiatement après vérification dans la mémoire de l'appareil, et seul un résumé des résultats de vérification est enregistré.

[legal_constants.body.19]
KO: 건강 정보 안내
FR: Informations sur la santé

[legal_constants.body.2]
KO: [선택] 건강정보(심박수) 수집 및 이용 동의
FR: [Facultatif] Consentement à la collecte et à l'utilisation des données de santé (fréquence cardiaque)

[legal_constants.body.21]
KO: 가슴 통증, 어지러움 등 이상이 느껴지면 즉시 운동을 멈추고 의료진과 상담하세요.
FR: Si vous ressentez une douleur thoracique, des étourdissements ou toute anomalie, arrêtez immédiatement l'exercice et consultez un médecin.

[legal_constants.body.23]
KO: 언제든 해지할 수 있으며, 해지해도 이미 결제한 기간이 끝날 때까지 이용할 수 있습니다.
FR: Vous pouvez annuler à tout moment et continuer à utiliser le service jusqu'à la fin de la période déjà payée.

[legal_constants.body.3]
KO: 건강정보 수집 동의 (선택 · 별도)
FR: Consentement à la collecte des données de santé (facultatif · distinct)

[legal_constants.body.4]
KO: 개인정보 처리방침 전문 보기
FR: Afficher l'intégralité de la politique de confidentialité

[legal_constants.body.5]
KO: 서비스 이용약관 전문 보기
FR: Afficher l'intégralité des conditions d'utilisation

[legal_constants.body.6]
KO: AI 생성 이미지 안내
FR: Avis sur les images générées par IA

[legal_constants.body.7]
KO: 일부 그림은 AI로 생성되었습니다. Created with Grok
FR: Certaines images ont été générées par IA. Created with Grok

[legal_constants.body.8]
KO: 서비스 이용약관 (필수)
FR: Conditions d'utilisation (Obligatoire)

[legal_constants.body.9]
KO: 개인정보 처리방침 (필수)
FR: Politique de confidentialité (Obligatoire)

[app.levelTestChallengeProgress]
KO: 챌린지 진행 상황: 2/3회 완료 (3.52/5.00 KM)
FR: Progression du défi : 2/3 terminé(s) (3,52/5,00 KM)

[app.levelTestGhostPace]
KO: [고스트 페이스]
FR: [Allure fantôme]

[app.levelTestMyLocation]
KO: [나(현재 위치)]
FR: [Moi (Position actuelle)]

[app.levelTestStartRun]
KO: 3회차 달리기 시작하기
FR: Démarrer la 3e course

[app.levelTestStatDistance]
KO: 현재 거리
FR: Distance actuelle

[app.levelTestStatPace]
KO: 현재 페이스
FR: Allure actuelle

[app.levelTestStatTime]
KO: 경과 시간
FR: Temps écoulé

[app.levelTestSubtitle]
KO: 검증된 달리기를 서로 다른 날 3번 마치면 등급이 배정됩니다.
FR: Effectuez 3 courses vérifiées sur des jours différents pour obtenir votre niveau.

[app.levelTestTitle]
KO: 혼자 뛰기 챌린지 (등급 배정)
FR: Défi de course en solo (Classement)

[app.liveRunningEffortTip]
KO: 순수 노력 목표: 완주 시 VALUE +$valueTokens
FR: Objectif d'effort pur : VALUE +$valueTokens à la fin

[app.liveRunningFinish]
KO: 종료 / 저장
FR: Terminer / Enregistrer

[app.liveRunningGhostPace]
KO: 고스트 페이스
FR: Allure fantôme

[app.liveRunningRoomTitle]
KO: 3km 중급 챌린지
FR: Défi 3 km Intermédiaire

[app.liveRunningSubmissionsLeft]
KO: 제출 기회: 2/3회 남음
FR: Tentatives de soumission : 2/3 restantes

[app.liveRunningYouLabel]
KO: 나 (You)
FR: Vous (You)

[app.runValidationFailed]
KO: 기록 검증에 실패했습니다. 보상이 지급되지 않았습니다.
FR: Échec de la vérification de l'enregistrement. La récompense n'a pas été attribuée.

[live_running.body]
KO: 1km 초보 챌린지
FR: Défi 1 km débutant

[live_running.body.2]
KO: 나
FR: Moi

[live_running.body.3]
KO: 고스트
FR: Fantôme

[live_running.body.4]
KO: 검증 중
FR: Vérification en cours

[live_running.toast]
KO: 센서 시작 실패: $error
FR: Échec du démarrage du capteur : $error

[app.existingAccountApple]
KO: 애플로 가입했어요
FR: Je me suis inscrit avec Apple

[app.existingAccountBody]
KO: 그 방법으로 로그인하면 지금 $provider${subjectParticle(provider)} 그 계정에 연결돼요. 닉네임과 재화도 그대로예요.
FR: Si vous vous connectez avec cette méthode, votre $provider${subjectParticle(provider)} actuel sera associé à ce compte. Votre pseudo et vos devises seront également conservés.

[app.existingAccountCreate]
KO: 새로 시작하기
FR: Recommencer à zéro

[app.existingAccountCreateHint]
KO: 기억나지 않거나 처음이신가요?
FR: Vous ne vous en souvenez plus ou c'est votre première fois ?

[app.existingAccountGoogle]
KO: 구글로 가입했어요
FR: Je me suis inscrit avec Google

[app.existingAccountKakao]
KO: 카카오로 가입했어요
FR: Je me suis inscrit avec Kakao

[app.existingAccountNaver]
KO: 네이버로 가입했어요
FR: Je me suis inscrit avec Naver

[app.existingAccountNotFound]
KO: 그 방법으로 가입된 계정이 없어요. 다른 방법을 골라 주세요.
FR: Aucun compte trouvé avec cette méthode. Veuillez en choisir une autre.

[app.existingAccountTitle]
KO: 처음 가입할 때 어떤 방법을 쓰셨나요?
FR: Quelle méthode avez-vous utilisée lors de votre première inscription ?

[app.linkAttached]
KO: $method${subjectParticle(method)} 연결됐어요. 이제 어느 쪽으로 들어와도 같은 계정이에요.
FR: $method${subjectParticle(method)} a été associé. Vous accéderez désormais au même compte dans les deux cas.

[app.linkConfirmNo]
KO: 아니에요, 다시 고를게요
FR: Non, choisir à nouveau

[app.linkConfirmTitle]
KO: 이 계정에 $method${objectParticle(method)} 연결할까요?
FR: Associer $method${objectParticle(method)} à ce compte ?

[app.linkConfirmYes]
KO: 네, 연결할게요
FR: Oui, associer

[app.loginComingSoon]
KO: $provider 로그인은 준비 중입니다.
FR: La connexion avec $provider sera bientôt disponible.

[app.loginGoogle]
KO: Google로 계속하기
FR: Continuer avec Google

[app.loginGuest]
KO: 게스트(테스트)로 시작하기
FR: Commencer en tant qu'invité (test)

[app.loginGuestLoading]
KO: 게스트 로그인 중...
FR: Connexion en tant qu'invité...

[app.loginGuestNote]
KO: 게스트 모드는 워치 연동·Health Connect 테스트용 임시 계정입니다.
FR: Le mode invité est un compte temporaire pour tester la synchronisation de la montre et Health Connect.

[app.loginKakao]
KO: Kakao로 계속하기
FR: Continuer avec Kakao

[app.loginNaver]
KO: Naver로 계속하기
FR: Continuer avec Naver

[app.loginReferralHint]
KO: 추천 코드를 입력하세요...
FR: Entrez le code de parrainage...

[app.loginReferralLabel]
KO: 추천 코드가 있으신가요?
FR: Avez-vous un code de parrainage ?

[app.loginSaveFailed]
KO: 로그인 저장 실패: $error
FR: Échec de l'enregistrement de la connexion : $error

[app.loginSubtitle]
KO: 세계를 향한 나눔의 질주
FR: Une course de partage vers le monde

[app.referralRedeemAlready]
KO: 이미 초대 코드를 입력했어요
FR: Vous avez déjà saisi un code d'invitation

[app.referralRedeemDone]
KO: 초대한 친구: 입력 완료
FR: Ami invité : Saisie terminée

[app.referralRedeemEntry]
KO: 초대 코드 입력
FR: Saisir le code d'invitation

[app.referralRedeemExpired]
KO: 가입 후 7일이 지나 입력할 수 없어요
FR: Impossible de le saisir car plus de 7 jours se sont écoulés depuis l'inscription

[app.referralRedeemFailed]
KO: 초대 코드를 등록하지 못했어요
FR: Impossible d'enregistrer le code d'invitation

[app.referralRedeemInvalid]
KO: 없는 초대 코드예요
FR: Ce code d'invitation n'existe pas

[app.referralRedeemSelf]
KO: 본인 코드는 입력할 수 없어요
FR: Vous ne pouvez pas saisir votre propre code

[app.referralRedeemSubmit]
KO: 등록
FR: Enregistrer

[app.referralRedeemSuccess]
KO: 10,000 SHARE 지급
FR: 10 000 SHARE accordés

[login.body]
KO: 구글 로그인에 성공했습니다!
FR: Connexion Google réussie !

[login.body.2]
KO: 로그인 실패:
FR: Échec de la connexion :

[login.body.3]
KO: 애플 로그인에 성공했습니다!
FR: Connexion Apple réussie !

[login.body.4]
KO: 애플 로그인 실패:
FR: Échec de la connexion Apple :

[login.body.5]
KO: 네이버 로그인에 성공했습니다!
FR: Connexion Naver réussie !

[login.body.6]
KO: 네이버 로그인 실패:
FR: Échec de la connexion Naver :

[login.body.7]
KO: 카카오 로그인에 성공했습니다!
FR: Connexion Kakao réussie !

[login.body.8]
KO: 카카오 로그인 실패:
FR: Échec de la connexion Kakao :

[login.body.9]
KO: 닉네임 $nickname
SHARE ${groupedDigits(shareBalance)}
FR: Pseudo $nickname
SHARE ${groupedDigits(shareBalance)}

[login.button]
KO: 초대 코드가 있으신가요?
FR: Avez-vous un code d'invitation ?

[login_connections.body]
KO: $name 연결을 해제했어요.
FR: $name a été déconnecté.

[login_connections.body.2]
KO: 카카오
FR: Kakao

[login_connections.body.3]
KO: 네이버
FR: Naver

[login_connections.body.4]
KO: 애플
FR: Apple

[login_connections.body.5]
KO: 구글
FR: Google

[login_connections.body.6]
KO: 같은 계정으로 여러 방법으로 로그인할 수 있어요. 연결해 두면 어떤 방법으로 들어와도 같은 SHARE와 기록이 보여요. 마지막 로그인 방법은 해제할 수 없어요.
FR: Vous pouvez vous connecter via plusieurs méthodes pour un même compte. Une fois liés, votre solde SHARE et vos historiques restent identiques quel que soit le moyen utilisé. Vous ne pouvez pas déconnecter votre dernière méthode de connexion.

[login_connections.body.7]
KO: 연결 안 됨
FR: Non connecté

[login_connections.button]
KO: 해제하면 이 $name 계정으로는 이 쉐어런 계정에 들어올 수 없어요. 다른 로그인 방법으로는 계속 쓸 수 있어요.
FR: Si vous déconnectez ce compte $name, vous ne pourrez plus accéder à ce compte ShareRun avec. Vous pourrez toujours vous connecter via d'autres méthodes.

[login_connections.button.2]
KO: 다시 불러오기
FR: Recharger

[login_connections.button.3]
KO: 연결하기
FR: Connecter

[login_connections.dialog]
KO: $name 연결 해제
FR: Déconnecter $name

[login_devices.body]
KO: 이 계정으로 앱을 연 기기예요. 기기 이름과 마지막으로 연 시각만 저장하고, 위치나 IP 주소는 저장하지 않아요.
FR: Appareils ayant ouvert l'application avec ce compte. Seuls le nom de l'appareil et l'heure de dernière ouverture sont enregistrés ; l'emplacement et l'adresse IP ne le sont pas.

[login_devices.body.2]
KO: 앱 데이터를 지우거나 다시 설치하면 같은 폰이 한 줄 더 보일 수 있어요.
FR: Effacer les données de l'application ou la réinstaller peut faire apparaître une ligne supplémentaire pour le même téléphone.

[login_devices.body.3]
KO: 아직 기록된 기기가 없어요.
FR: Aucun appareil enregistré pour le moment.

[login_devices.body.4]
KO: 알 수 없는 기기
FR: Appareil inconnu

[login_devices.body.5]
KO: $name (이 기기)
FR: $name (Cet appareil)

[login_devices.body.6]
KO: $name · 새 기기
FR: $name · Nouvel appareil

[login_devices.body.7]
KO: ${device.osVersion} · 앱 ${device.appVersion}
마지막으로 연 시각 $when
FR: ${device.osVersion} · App ${device.appVersion}
Dernière ouverture $when

[login_devices.button]
KO: 이 폰을 포함해 로그인된 모든 기기에서 로그아웃돼요. 다른 기기는 잠시 뒤 로그인 화면으로 돌아가요. 계속할까요?
FR: Vous serez déconnecté de tous les appareils, y compris ce téléphone. Les autres appareils reviendront sous peu à l'écran de connexion. Continuer ?

[login_devices.dialog]
KO: 모든 기기에서 로그아웃
FR: Se déconnecter de tous les appareils

[login_devices.toast]
KO: 로그아웃하지 못했어요. 잠시 후 다시 시도해 주세요.
FR: Échec de la déconnexion. Veuillez réessayer dans un instant.

[app.dashboardChallenge1Sub]
KO: 참가비: 600 SHARE
FR: Frais d'inscription : 600 SHARE

[app.dashboardChallenge1Title]
KO: 초보 1km 챌린지 🏆
FR: Défi 1 km Débutant 🏆

[app.dashboardChallenge2Sub]
KO: 참가비: 1,200 SHARE
FR: Frais d'inscription : 1,200 SHARE

[app.dashboardChallenge2Title]
KO: 중급 3km 챌린지 (골드 대회)
FR: Défi 3 km Intermédiaire (compétition Or)

[app.dashboardDailyMissionCapsule]
KO: 📍 오늘의 미션 확인하기 >
FR: 📍 Voir les missions du jour >

[app.dashboardDiamondBalance]
KO: 💎 보유 다이아몬드: 5개
FR: 💎 DIA possédés : 5

[app.dashboardDiamondBalanceOf]
KO: 💎 보유 다이아몬드: $count개
FR: 💎 DIA possédés : $count

[app.dashboardGradeRunLabel]
KO: 등급 배정 달리기:
FR: Course de classement :

[app.dashboardGradeRunProgress]
KO: 2/3회 완료 >
FR: 2/3 terminées >

[app.dashboardOngoingChallenges]
KO: 진행 중인 챌린지
FR: Défis en cours

[app.dashboardShareBalance]
KO: 보유 SHARE: 90,000
FR: SHARE possédés : 90,000

[app.dashboardShareBalanceOf]
KO: 보유 SHARE: $amount
FR: SHARE possédés : $amount

[app.dashboardStampMapTooltip]
KO: 오늘의 미션 · 스탬프 투어
FR: Missions du jour · Tournée des tampons

[app.dashboardValueBalance]
KO: 🌱 보유 밸류(VALUE): 5,200
FR: 🌱 VALUE possédés : 5,200

[app.dashboardValueBalanceOf]
KO: 🌱 보유 밸류(VALUE): $amount
FR: 🌱 VALUE possédés : $amount

[app.dashboardViewRoom]
KO: 대회 상세 보기
FR: Voir les détails du concours

[app.exitGuardMessage]
KO: 나눔의 질주를 잠시 쉬어가시겠습니까? 한 번 더 누르시면 종료됩니다.
FR: Voulez-vous faire une pause dans votre course de partage ? Appuyez à nouveau pour quitter.

[app.myWalletCharge]
KO: 교환하기
FR: Échanger

[app.myWalletChargeDia]
KO: 다이아몬드
FR: DIA

[app.myWalletChargeDiaHint]
KO: 교환소에서 SHARE로 바꾸거나 연속 달리기로 모을 수 있어요
FR: Vous pouvez l'échanger contre des SHARE au bureau d'échange ou en accumuler grâce à vos séries de course.

[app.myWalletChargeShareHint]
KO: 활동으로 모을 수 있어요
FR: Vous pouvez en collecter grâce à vos activités.

[app.myWalletChargeValue]
KO: 밸류(VALUE)
FR: VALUE

[app.myWalletChargeValueHint]
KO: 달리기로 모을 수 있어요
FR: Vous pouvez en collecter en courant.

[app.myWalletDiamondLabel]
KO: 보유 다이아몬드: $count개
FR: DIA possédés : $count

[app.myWalletGradeProgress]
KO: 등급 배정 달리기: $done/$total회 완료 >
FR: Course de classement : $done/$total terminée(s) >

[app.myWalletInventoryCount]
KO: 보유 $count
FR: Possédé : $count

[app.myWalletInventoryEmpty]
KO: 아직 보유한 아이템이 없습니다.
FR: Vous ne possédez aucun article pour le moment.

[app.myWalletInventoryOpen]
KO: 보관함 보기
FR: Voir l'inventaire

[app.myWalletInventoryTitle]
KO: 보유 아이템
FR: Objets possédés

[app.myWalletItemDuringRun]
KO: 달리기 중 사용 가능
FR: Utilisable pendant la course

[app.myWalletItemDuringTournament]
KO: 대회에서 사용 가능
FR: Utilisable en compétition

[app.myWalletRecentTransactions]
KO: 최근 거래 내역
FR: Transactions récentes

[app.myWalletUse]
KO: 상점 가기
FR: Aller à la boutique

[app.myWalletValueLabel]
KO: 보유 밸류(VALUE): $amount
FR: VALUE possédés : $amount

[app.walletUnconfirmedNote]
KO: 서버에서 확인하는 중이에요. 지금 보이는 값은 마지막으로 확인된 값이에요.
FR: Vérification auprès du serveur. La valeur affichée est la dernière valeur confirmée.

[main_dashboard.body]
KO: 상품은 다이아예요 · ${AppStrings.noCashPrizePool}
FR: Les prix sont des DIA · ${AppStrings.noCashPrizePool}

[main_dashboard.body.2]
KO: 좋은 아침이에요
FR: Bonjour
