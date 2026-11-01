# 번역 검수 요청 — 쉐어런 (French) · 파트 2/8

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
[crew.crew_emblem.body.9]
KO: ${n(t[0])}km · ${n(t[1])}km · ${n(t[2])}km  (지금 ${n(now.round())}km)
FR: ${n(t[0])}km · ${n(t[1])}km · ${n(t[2])}km  (actuellement ${n(now.round())}km)

[crew.crew_emblem.button]
KO: }이 엠블럼을 살까요?
크루가 평생 가지며 크루원 누구에게나 보여요. 크루를 없애면 함께 사라져요.
FR: }Acheter cet emblème ?
Le crew le conserve pour toujours et tous les membres peuvent le voir. Si le crew est supprimé, il disparaîtra aussi.

[crew.crew_emblem.button.2]
KO: 이 엠블럼으로 정하기
FR: Choisir cet emblème

[crew.crew_emblem.dialog]
KO: 유료 엠블럼 사기
FR: Acheter un emblème payant

[crew.crew_ranking.body]
KO: 이번 달 ${rank.rank}위 · 1인 평균 ${rank.averageKm.toStringAsFixed(1)}km
FR: ${rank.rank}e ce mois-ci · Moyenne de ${rank.averageKm.toStringAsFixed(1)}km par personne

[crew.crew_ranking.body.2]
KO: 크루원이 $minMembers명 이상이면 순위에 올라요. (지금 $myMemberCount명)
FR: Rejoint le classement quand le crew compte au moins $minMembers membres. (Actuellement $myMemberCount)

[crew.crew_ranking.body.3]
KO: 이번 달에 달리면 순위에 올라요.
FR: Courez ce mois-ci pour entrer dans le classement.

[app.crewManagerAppointVice]
KO: 부방장 임명
FR: Nommer co-leader

[app.crewManagerExpandMembers]
KO: +10명 인원 한도 확장하기 (300 DIA)
FR: Augmenter la limite de +10 membres (300 DIA)

[app.crewManagerForceKick]
KO: 강제 퇴출
FR: Expulser

[app.crewManagerGiftAngelBadge]
KO: 천사 배지를 획득하세요
FR: Obtenez le badge d'ange

[app.crewManagerGiftCpr]
KO: 🎁 심폐소생권/세이프가드 전체 선물 (DIA)
FR: 🎁 Offrir RCP / Protection à tous (DIA)

[app.crewManagerGiftDeposit]
KO: 🛡️ 크루 대항전 예치금 방장 대납 (DIA/SHARE)
FR: 🛡️ Le leader avance la caution de la bataille de crew (DIA/SHARE)

[app.crewManagerGiftPass]
KO: 🎉 크루 전용 챌린지 패스 & 스킨 구매 (DIA)
FR: 🎉 Acheter le passe de défi et skin crew (DIA)

[app.crewManagerGiftSection]
KO: 크루원 혜택 하사(선물)
FR: Offrir des avantages aux membres

[app.crewManagerMember1]
KO: 김나운
FR: Na-woon Kim

[app.crewManagerMember2]
KO: 이승우
FR: Seung-woo Lee

[app.crewManagerMember3]
KO: 최서연
FR: Seo-yeon Choi

[app.crewManagerMemberSection]
KO: 소속 팀원 관리 (50 / 50명)
FR: Gérer les membres (50 / 50)

[app.crewManagerPremiumSection]
KO: 프리미엄 설정
FR: Paramètres premium

[app.crewManagerProfileChange]
KO: 이름 변경
FR: Changer de nom

[app.crewManagerProfileLabel]
KO: 크루 프로필
FR: Profil du crew

[app.crewManagerPushNotice]
KO: 전체 공지 푸시 발송 (무료)
FR: Envoyer une notif générale (Gratuit)

[app.crewManagerSave]
KO: 관리 설정 저장하기
FR: Enregistrer les paramètres

[app.crewManagerShareWarning]
KO: SHARE 결제 시 주의하세요
FR: Soyez attentif lors du paiement en SHARE

[app.crewManagerTitle]
KO: 크루 관리 (방장 전용)
FR: Gestion de crew (Leader uniquement)

[crew_manager.body]
KO: 처음 한 번은 무료예요.
FR: La première fois est gratuite.

[crew_manager.body.10]
KO: 보유 DIA ${wallet.diamondBalance} · SHARE ${wallet.shareBalance}
FR: Solde : DIA ${wallet.diamondBalance} · SHARE ${wallet.shareBalance}

[crew_manager.body.11]
KO: 부방장: ${subs.join(
FR: Co-leaders : ${subs.join(

[crew_manager.body.12]
KO: 📢 전체 공지 푸시 (준비 중)
FR: 📢 Notification à tous (bientôt disponible)

[crew_manager.body.13]
KO: 크루 이름
FR: Nom du crew

[crew_manager.body.14]
KO: 이름 변경 (첫 1회 무료)
FR: Changer de nom (1re fois gratuite)

[crew_manager.body.15]
KO: 이름 변경 (${mine.crew.renameCostDia} DIA)
FR: Changer de nom (${mine.crew.renameCostDia} DIA)

[crew_manager.body.16]
KO: 보관함 아이템
FR: Objets de l'inventaire

[crew_manager.body.17]
KO: 🎁 크루원 전체에게 심폐소생권·세이프가드 선물 (1인당 $_giftDiaPerMember DIA)
FR: 🎁 Offrir un ticket de réanimation et un bouclier à tous les membres ($_giftDiaPerMember DIA par personne)

[crew_manager.body.18]
KO: 내가 아닌 크루원의 보관함에 하나씩 들어가요. 한 명에게만 줄 때는 아래 팀원 목록에서 골라요.
FR: Un exemplaire sera envoyé dans l'inventaire de chaque membre sauf le vôtre. Pour n'en donner qu'à une seule personne, choisissez-la dans la liste ci-dessous.

[crew_manager.body.19]
KO: 🚩 크루 응원 깃발 (15 DIA, 하루 1회)
FR: 🚩 Drapeau d'encouragement du crew (15 DIA, 1 fois par jour)

[crew_manager.body.2]
KO: 이름 바꾸기
FR: Modifier le nom

[crew_manager.body.20]
KO: 🛡️ 크루 대항전 예치금 대납 (준비 중)
FR: 🛡️ Payer la caution de la bataille de crew à la place (Bientôt)

[crew_manager.body.21]
KO: 🎉 크루 전용 챌린지 패스 & 스킨 (준비 중)
FR: 🎉 Passe de défi et skin exclusifs crew (Bientôt)

[crew_manager.body.22]
KO: 소속 팀원 관리 ($count / $limit명)
FR: Gérer les membres ($count / $limit)

[crew_manager.body.23]
KO: 소속 팀원이 없습니다.
FR: Aucun membre.

[crew_manager.body.24]
KO: $name (방장)
FR: $name (Leader)

[crew_manager.body.25]
KO: $name (부방장)
FR: $name (Co-leader)

[crew_manager.body.3]
KO: "$next"(으)로 바꾸면 $cost DIA가 들어요. 보너스 DIA를 먼저 써요.
FR: Changer pour « $next » coûte $cost DIA. Les DIA bonus seront utilisés en premier.

[crew_manager.body.4]
KO: $cost DIA 내고 바꾸기
FR: Payer $cost DIA pour modifier

[crew_manager.body.5]
KO: $cost DIA 내고 보내기
FR: Envoyer pour $cost DIA

[crew_manager.body.6]
KO: +${step.add}명 인원 한도 확장하기 (${step.costDia} DIA)
FR: Augmenter la limite de +${step.add} membres (${step.costDia} DIA)

[crew_manager.body.7]
KO: $base · ${crew.maxMembers}명을 모두 채우면 열려요
FR: $base · Se débloque une fois les ${crew.maxMembers} membres atteints

[crew_manager.body.8]
KO: 크루 정보를 불러오지 못했어요. 크루에 들어 있는지, 네트워크가 연결됐는지 확인해 주세요.
FR: Impossible de charger les informations du crew. Veuillez vérifier que vous appartenez à un crew et que votre connexion réseau fonctionne.

[crew_manager.body.9]
KO: 크루장과 부크루장만 관리할 수 있어요.
FR: Seuls le chef et les co-leaders du crew peuvent gérer cela.

[crew_manager.button]
KO: 이름을 바꿀 때마다 $cost DIA가 들어요.
FR: Coûte $cost DIA par modif.

[crew_manager.button.2]
KO: 저장
FR: Enregistrer

[crew_manager.button.3]
KO: 선물
FR: Offrir

[crew_manager.button.4]
KO: 부방장 해제
FR: Retirer co-leader

[crew_manager.dialog]
KO: 크루 이름 변경
FR: Modifier le nom du crew

[crew_manager.toast]
KO: 아직 열리지 않았어요. 준비되면 알려드릴게요.
FR: Pas encore disponible. Nous vous préviendrons dès que ce sera prêt.

[crew_manager.toast.10]
KO: ${step.costDia} DIA 내고 늘리기
FR: Payer ${step.costDia} DIA pour agrandir

[crew_manager.toast.11]
KO: 인원 한도가 ${result.maxMembers}명이 됐어요.
FR: La limite de membres est maintenant de ${result.maxMembers}.

[crew_manager.toast.12]
KO: 크루장만 늘릴 수 있어요.
FR: Seul le chef de crew peut agrandir.

[crew_manager.toast.13]
KO: 자리를 모두 채워야 하거나 이미 최대예요.
FR: Toutes les places doivent être remplies ou le maximum est atteint.

[crew_manager.toast.14]
KO: 인원 한도를 늘리지 못했어요. 잠시 뒤 다시 해 주세요.
FR: Impossible d'augmenter la limite. Veuillez réessayer plus tard.

[crew_manager.toast.15]
KO: 크루 응원 깃발을 걸었습니다. 오늘 대회 SHARE 보상이 10% 늘어납니다.
FR: Bannière d'encouragement de crew déployée. Récompenses de SHARE du concours d'aujourd'hui +10 %.

[crew_manager.toast.16]
KO: 응원 깃발을 걸지 못했습니다.
FR: Impossible de déployer la bannière d'encouragement.

[crew_manager.toast.17]
KO: 선물을 받을 크루원이 없어요.
FR: Aucun membre de crew pour recevoir des cadeaux.

[crew_manager.toast.18]
KO: 크루원 $count명 모두
FR: Les $count membres du crew

[crew_manager.toast.19]
KO: ${member.nickname}님
FR: ${member.nickname}

[crew_manager.toast.2]
KO: 크루 이름을 "$next"(으)로 바꿨어요.
FR: Le nom du crew a été changé en « $next ».

[crew_manager.toast.20]
KO: 심폐소생권·세이프가드 선물
FR: Offrir Réanimation & Protection

[crew_manager.toast.21]
KO: $who에게 심폐소생권과 세이프가드를 하나씩 보내요. 한 명당 $_giftDiaPerMember DIA, 모두 $cost DIA가 들고 보너스 DIA를 먼저 써요.
FR: Envoyez 1 Réanimation et 1 Protection à $who. $_giftDiaPerMember DIA par pers., total $cost DIA. DIA bonus utilisés d'abord.

[crew_manager.toast.22]
KO: ${result.recipients}명의 보관함에 선물을 넣었어요. (−$cost DIA)
FR: Cadeau envoyé dans l'inventaire de ${result.recipients} membres. (−$cost DIA)

[crew_manager.toast.23]
KO: 크루장만 선물할 수 있어요.
FR: Seul le chef de crew peut envoyer des cadeaux.

[crew_manager.toast.24]
KO: 그 크루원을 찾지 못했어요.
FR: Ce membre du crew est introuvable.

[crew_manager.toast.25]
KO: 선물을 보내지 못했어요. 잠시 뒤 다시 해 주세요.
FR: Échec de l'envoi du cadeau. Veuillez réessayer dans un instant.

[crew_manager.toast.26]
KO: ${member.nickname}님을 부방장으로 임명했어요.
FR: ${member.nickname} a été nommé(e) co-leader.

[crew_manager.toast.27]
KO: ${member.nickname}님을 크루원으로 돌렸어요.
FR: ${member.nickname} est redevenu(e) membre du crew.

[crew_manager.toast.28]
KO: 바꾸지 못했어요. 잠시 뒤 다시 해 주세요.
FR: Impossible de modifier. Veuillez réessayer dans un instant.

[crew_manager.toast.29]
KO: 크루원 내보내기
FR: Retirer le membre du crew

[crew_manager.toast.3]
KO: DIA가 모자라거나 쓸 수 없는 이름이에요.
FR: DIA insuffisants ou nom non valide.

[crew_manager.toast.30]
KO: ${member.nickname}님을 크루에서 내보낼까요?
FR: Retirer ${member.nickname} du crew ?

[crew_manager.toast.31]
KO: 내보내기
FR: Retirer

[crew_manager.toast.32]
KO: ${member.nickname}님을 내보냈어요.
FR: ${member.nickname} a été retiré(e).

[crew_manager.toast.33]
KO: 내보내지 못했어요. 잠시 뒤 다시 해 주세요.
FR: Impossible de retirer. Veuillez réessayer dans un instant.

[crew_manager.toast.34]
KO: 인원 한도 최대 (${crew.maxMembers}명)
FR: Capacité maximale atteinte (${crew.maxMembers})

[crew_manager.toast.4]
KO: 크루장만 이름을 바꿀 수 있어요.
FR: Seul le chef de crew peut changer le nom.

[crew_manager.toast.5]
KO: 이름을 바꾸지 못했어요. 잠시 뒤 다시 해 주세요.
FR: Échec de la modification du nom. Veuillez réessayer plus tard.

[crew_manager.toast.6]
KO: 인원 한도가 최대(${mine.crew.maxMembers}명)예요.
FR: La limite de membres est atteinte (${mine.crew.maxMembers} membres).

[crew_manager.toast.7]
KO: 자리를 모두 채우면 더 늘릴 수 있어요. (${mine.crew.maxMembers}명)
FR: Remplissez toutes les places pour agrandir. (${mine.crew.maxMembers} membres)

[crew_manager.toast.8]
KO: 인원 한도 확장
FR: Augmenter la limite de membres

[crew_manager.toast.9]
KO: 크루 인원 한도를 ${step.add}명 늘려요. ${step.costDia} DIA가 들고, 보너스 DIA를 먼저 써요.
FR: Augmentez le crew de ${step.add} membres pour ${step.costDia} DIA. DIA bonus utilisés en premier.

[crew_ranking_model.body]
KO: 쉐어런 크루
FR: Crew ShareRun

[crew_room.body]
KO: 크루에 들어 있어야 크루 룸을 볼 수 있어요. 크루에 들어갔는지, 네트워크가 연결됐는지 확인해 주세요.
FR: Vous devez faire partie d'un crew pour voir le salon de crew. Veuillez vérifier si vous avez rejoint un crew et si votre réseau est connecté.

[crew_room.body.2]
KO: } · 내 역할 ${CrewRoomScreen._roleLabel(mine.role)}
FR: } · Mon rôle : ${CrewRoomScreen._roleLabel(mine.role)}

[crew_room.body.3]
KO: 크루 대항전은 아직 열리지 않았어요. 열리면 여기서 이번 주 진행을 볼 수 있어요.
FR: Les batailles de crew n'ont pas encore commencé. Une fois ouvertes, vous pourrez suivre le progrès de la semaine ici.

[crew_room.button]
KO: 크루 룸
FR: Salon de crew

[device_connection.body]
KO: (Apple Watch 전 기종 지원)
FR: (Prend en charge tous les modèles Apple Watch)

[device_connection.body.2]
KO: Health Connect 설치 화면을 열었어요. 설치 후 다시 연결해 주세요.
FR: Écran d'installation de Health Connect ouvert. Veuillez vous reconnecter après l'installation.

[device_connection.body.3]
KO: ♥ 연결됨
FR: ♥ Connecté

[device_connection.body.4]
KO: 미연결
FR: Non connecté

[device_connection.body.5]
KO: 연결된 센서: ${snap.deviceName}
FR: Capteur connecté : ${snap.deviceName}

[device_connection.button]
KO: 워치 앱 연결 코드 · 연결된 워치
FR: Code connexion montre · Montre liée

[device_connection.button.2]
KO: 권한 설정 필요
FR: Permission requise

[device_connection.button.3]
KO: 정확한 측정을 위해 권한 설정이 필요합니다.
FR: Les autorisations sont requises pour une mesure précise.

[device_connection.dialog]
KO: 연동 불가
FR: Synchronisation impossible

[device_connection.dialog.2]
KO: 고객님의 스마트워치 OS 버전이 낮거나 호환되지 않아 연동할 수 없습니다. 워치를 최신 버전(watchOS 8+, Wear OS 3.0+)으로 업데이트해 주세요.
FR: La version du système d'exploitation de votre montre connectée est trop ancienne ou incompatible. Veuillez la mettre à jour vers la dernière version (watchOS 8+, Wear OS 3.0+).

[device_connection.toast]
KO: 등급 배정 화면 이동 실패: $e
FR: Échec de la navigation vers l'écran d'attribution de niveau : $e

[device_connection.toast.2]
KO: 건너뛰기 실패: $e
FR: Échec de l'ignorer : $e

[device_connection.toast.3]
KO: ${watchType.displayLabel} 연동이 완료되었습니다!
FR: Synchronisation ${watchType.displayLabel} terminée !

[device_connection.toast.4]
KO: Health Connect를 열 수 없어요. Play 스토어에서 설치해 주세요.
FR: Impossible d'ouvrir Health Connect. Veuillez l'installer depuis le Play Store.

[device_connection.toast.5]
KO: 권한이 거부되었습니다.
FR: Autorisation refusée.

[device_connection.toast.6]
KO: Google Health Connect 연동이 완료되었습니다!
FR: Synchronisation Google Health Connect terminée !

[device_connection.toast.7]
KO: 기기가 호환되지 않거나 연동 중 오류가 발생했습니다.
FR: L'appareil n'est pas compatible ou une erreur est survenue lors de la synchronisation.

[device_connection.toast.8]
KO: Garmin 연동 화면을 열 수 없습니다: $e
FR: Impossible d'ouvrir l'écran de synchronisation Garmin : $e

[device_connection.toast.9]
KO: ${watchType.displayLabel} 연동 설정이 저장되었습니다.
FR: Paramètres de synchronisation ${watchType.displayLabel} enregistrés.

[app.bleHrConnectButton]
KO: 연결
FR: Connecter

[app.bleHrDisconnectButton]
KO: 연결 해제
FR: Déconnecter

[app.bleHrGuideItems]
KO: 가민(Garmin)
FR: Garmin

[app.bleHrGuideItems.2]
KO: 시계 설정 → 센서 및 액세서리 → 손목 심박수 → "심박수 전송" 켜기
FR: Paramètres de la montre → Capteurs et accessoires → Fréquence cardiaque au poignet → Activer « Émettre FC »

[app.bleHrGuideItems.3]
KO: 샤오미 · 어메이즈핏
FR: Xiaomi · Amazfit

[app.bleHrGuideItems.4]
KO: 운동·심박수 설정 → "심박수 공유/전송" 켜기
FR: Paramètres d'entraînement et de FC → Activer « Partage/diffusion de la fréquence cardiaque »

[app.bleHrGuideItems.5]
KO: 가슴·암밴드 센서
FR: Capteurs de poitrine et de brassard

[app.bleHrGuideItems.6]
KO: 착용한 뒤 아래 [센서 찾기] 누르기 (Polar, Wahoo, Coospo, Magene)
FR: Enfilez-le puis appuyez sur [Rechercher le capteur] ci-dessous (Polar, Wahoo, Coospo, Magene)

[app.bleHrGuideItems.7]
KO: 갤럭시 워치 · 애플워치
FR: Galaxy Watch · Apple Watch

[app.bleHrGuideItems.8]
KO: 이 방식이 아니에요. 위의 Health Connect / Apple 건강으로 연결하세요
FR: Pas de cette manière. Veuillez vous connecter via Health Connect / Apple Santé ci-dessus

[app.bleHrGuideTitle]
KO: 내 기기별로 이렇게 하세요
FR: Instructions selon votre appareil

[app.bleHrScanningLabel]
KO: 근처 심박 센서 찾는 중...
FR: Recherche de capteurs de fréquence cardiaque à proximité...

[app.bleHrSectionSubtitle]
KO: Health Connect 지연 없이 달리는 동안 실시간 심박수(0x180D)를 바로 받습니다.
FR: Reçoit directement la fréquence cardiaque en temps réel (0x180D) pendant la course sans latence Health Connect.

[app.bleHrStopScanButton]
KO: 스캔 중지
FR: Arrêter l'analyse

[app.deviceConnectionConnect]
KO: 기기 연결
FR: Connecter l'appareil

[app.deviceConnectionExternalTitle]
KO: 외부 전문 기기 연동
FR: Synchronisation d'appareils spécialisés externes

[app.deviceConnectionGoogleCaption]
KO: (갤럭시 워치, 샤오미 미밴드, 어메이즈핏, 가민, 핏빗 등)
FR: (Galaxy Watch, Xiaomi Mi Band, Amazfit, Garmin, Fitbit, etc.)

[app.deviceConnectionNativeTitle]
KO: 네이티브 헬스 연동
FR: Synchronisation de santé native

[app.deviceConnectionNone]
KO: 연결된 기기가 없습니다
FR: Aucun appareil connecté

[app.deviceConnectionSingleActiveNote]
KO: 쉐어런은 동시에 하나의 운동 기기만 활성 연결 상태로 유지합니다.
FR: ShareRun ne maintient la connexion active qu'avec un seul appareil d'entraînement à la fois.

[app.deviceConnectionStatusTitle]
KO: 현재 연결된 기기
FR: Appareil actuellement connecté

[app.healthConnectNoSamplesTip]
KO: 권한은 연결되었어요. 밴드/워치 앱 안에서 Health Connect 데이터 쓰기 스위치가 켜져 있는지 확인해 주세요. 스마트밴드 기록은 밴드 앱 동기화 후 반영됩니다.
FR: Les autorisations sont associées. Veuillez vérifier si l'option d'écriture des données Health Connect est activée dans l'application de votre bracelet/montre. Les données du bracelet connecté apparaîtront après synchronisation avec son application.

[dia_pack_store.body]
KO: $price원 · ${pack.bonusLabel}
FR: $price won · ${pack.bonusLabel}

[dia_pack_store.body.2]
KO: 기본 ${pack.baseDia} DIA · ${pack.productId}
FR: Base ${pack.baseDia} DIA · ${pack.productId}

[dia_pack_store.title]
KO: DIA 팩
FR: Pack DIA

[diamond_box_model.body]
KO: 다이아 상자
FR: Boîte de DIA

[donation_settlement.body]
KO: 운영자가 자기 돈으로 검증 1km당 100원(KRW)을 월 예산 안에서 기부할 예정입니다. 이용자의 기부금이 아니며 세금 공제 영수증이 발급되지 않습니다.
FR: L'opérateur prévoit de donner 100 KRW par km vérifié sur son propre argent, dans la limite du budget mensuel. Il ne s'agit pas d'un don d'utilisateur et aucun reçu de déduction fiscale n'est délivré.

[economy_constants.body]
KO: 구매 후 7일 이내, 100% 미사용 분에 한해 환불 가능
FR: Remboursable dans les 7 jours suivant l'achat uniquement si 100 % inutilisé

[email_verification_guard.button]
KO: 결제·대회 참가 전에 이메일 인증을 완료해 주세요. 상단 배너에서 인증 메일을 재발송할 수 있습니다.
FR: Veuillez vérifier votre e-mail avant tout paiement ou inscription aux compétitions. Vous pouvez renvoyer l'e-mail depuis la bannière supérieure.

[email_verification_guard.dialog]
KO: 이메일 인증 필요
FR: Vérification de l'e-mail requise

[external_oauth_webview.body]
KO: 이메일 아이디를 입력해 주세요.
FR: Veuillez saisir votre adresse e-mail.

[external_oauth_webview.body.2]
KO: 올바른 이메일 형식이 아닙니다.
FR: Format d'e-mail non valide.

[external_oauth_webview.body.3]
KO: 비밀번호를 입력해 주세요.
FR: Veuillez saisir votre mot de passe.

[external_oauth_webview.body.4]
KO: 비밀번호가 너무 짧습니다.
FR: Le mot de passe est trop court.

[external_oauth_webview.toast]
KO: 연동 중 오류가 발생했습니다. 앱으로 돌아가 다시 시도해 주세요.
FR: Une erreur est survenue lors de la liaison. Veuillez revenir dans l’application et réessayer.

[app.externalPaymentNoticeHighlight]
KO: 실제 야외 물리적 활동(오프라인 러닝)
FR: une activité physique réelle en plein air (running hors ligne)

[app.externalPaymentNoticePrefix]
KO: 본 결제는
FR: Ce paiement correspond à l'achat d'un billet pour participer à

[app.externalPaymentNoticeSuffix]
KO: 참여를 위한 참가권 구매입니다.
FR: .

[app.externalPaymentRefundNote]
KO: * 미사용 쿠폰에 한해 언제든 100% 수수료 없이 환불 가능합니다.
FR: * Uniquement pour les coupons non utilisés, remboursable à 100 % à tout moment sans frais.

[app.externalPaymentSecurePaySuffix]
KO: 원 안전 결제하기
FR: KRW - Paiement sécurisé

[firebase_auth_messages.body]
KO: 로그인이 취소되었습니다.
FR: Connexion annulée.

[firebase_auth_messages.body.10]
KO: 다른 로그인 방식으로 가입된 이메일입니다.
FR: Cet e-mail est inscrit avec une autre méthode de connexion.

[firebase_auth_messages.body.11]
KO: 보안을 위해 다시 로그인한 뒤 계정 삭제를 시도해 주세요.
FR: Pour des raisons de sécurité, veuillez vous reconnecter avant de tenter de supprimer le compte.

[firebase_auth_messages.body.12]
KO: 로그인에 실패했습니다.
FR: Échec de la connexion.

[firebase_auth_messages.body.2]
KO: 이메일 형식이 올바르지 않습니다.
FR: Format d'e-mail non valide.

[firebase_auth_messages.body.3]
KO: 비활성화된 계정입니다. 고객센터에 문의해 주세요.
FR: Ce compte a été désactivé. Veuillez contacter le service client.

[firebase_auth_messages.body.4]
KO: 이메일 또는 비밀번호를 확인해 주세요.
FR: Veuillez vérifier votre e-mail ou votre mot de passe.

[firebase_auth_messages.body.5]
KO: 이미 사용 중인 이메일입니다.
FR: Cet e-mail est déjà utilisé.

[firebase_auth_messages.body.6]
KO: 비밀번호는 6자 이상이어야 합니다.
FR: Le mot de passe doit contenir au moins 6 caractères.

[firebase_auth_messages.body.7]
KO: 요청이 너무 많습니다. 잠시 후 다시 시도해 주세요.
FR: Trop de requêtes. Veuillez réessayer plus tard.

[firebase_auth_messages.body.8]
KO: 네트워크 연결을 확인해 주세요.
FR: Veuillez vérifier votre connexion réseau.

[firebase_auth_messages.body.9]
KO: Firebase 콘솔에서 익명(게스트) 로그인을 활성화해 주세요.
FR: Veuillez activer la connexion anonyme (invité) dans la console Firebase.

[app.garminAuthSubtitle]
KO: 안전한 OAuth 2.0 공식 로그인 페이지입니다.
FR: Il s'agit d'une page de connexion officielle et sécurisée OAuth 2.0.

[app.garminAuthTitle]
KO: Garmin Connect 연동
FR: Associer Garmin Connect

[app.garminCancelAndReturn]
KO: 연동을 취소하고 앱으로 돌아가기
FR: Annuler l'association et revenir à l'application

[app.garminEmailHint]
KO: 이메일 아이디
FR: Adresse e-mail

[app.garminPasswordHint]
KO: 비밀번호
FR: Mot de passe

[app.garminSignInAuthorize]
KO: 로그인하고 권한 허용
FR: Se connecter et autoriser

[app.garminSignInAuthorizeKo]
KO: (로그인 및 권한 허용)
FR: (Se connecter et autoriser)

[app.hallOfFameDonateCta]
KO: 나도 기부하고 명예의 전당 오르기 💎
FR: Donnez et rejoignez le Temple de la renommée 💎

[app.hallOfFameDonateHistoryTitle]
KO: 명예의 전당 기부 완료 🕊️
FR: Don au Temple de la renommée terminé 🕊️

[app.hallOfFameLeaderDonation]
KO: 누적 기부: 5,000,000 VALUE
FR: Dons cumulés : 5 000 000 VALUE

[app.hallOfFameLeaderName]
KO: 서울 나이트 러너스 방장님
FR: Leader des Seoul Night Runners

[app.hallOfFameLeaderTitle]
KO: 👑 이달의 소셜 임팩트 리더
FR: 👑 Leader d'impact social du mois

[app.hallOfFameRank2Badge]
KO: 🔥 불꽃 SBT 뱃지
FR: 🔥 Badge SBT Flamme

[app.hallOfFameRank2Label]
KO: 2등
FR: 2e place

[app.hallOfFameRank2Subtitle]
KO: 연속 50일 완주자
FR: Finisher 50 jours consécutifs

[app.hallOfFameRank3Badge]
KO: 🛡️ 방패 SBT 뱃지
FR: 🛡️ Badge SBT Bouclier

[app.hallOfFameRank3Label]
KO: 3등
FR: 3e place

[app.hallOfFameRank3Subtitle]
KO: 최다 크루원 후원자
FR: Plus grand soutien des membres du crew

[app.hallOfFameTitle]
KO: 명예의 전당 (Hall of Fame)
FR: Temple de la renommée (Hall of Fame)

[app.runningCrewHallOfFame]
KO: 👑 명예의 전당
FR: 👑 Temple de la renommée

[app.storeDonateHistoryTitle]
KO: 기부 펀딩 참여 🕊️
FR: Participation au financement participatif de dons 🕊️

[hall_of_fame.body]
KO: 서버 원장에서 $_donateValue VALUE를 기부했습니다.
FR: A fait un don de $_donateValue VALUE sur le grand livre du serveur.

[hall_of_fame.body.2]
KO: 서버 원장에서 $_donateValue VALUE를 기부했습니다. 잔액 $left
FR: A fait un don de $_donateValue VALUE sur le grand livre du serveur. Solde : $left

[hall_of_fame.body.3]
KO: VALUE가 부족합니다.
FR: VALUE insuffisant.

[hall_of_fame.body.4]
KO: 기부에 실패했습니다.
FR: Échec du don.

[hall_of_fame.body.5]
KO: 아직 기록이 없어요
FR: Aucun enregistrement pour le moment

[health_data_consent.body]
KO: 개인정보보호법에 따라 건강·생체 데이터는 일반 약관과 분리된 명시적 Opt-in이 필요합니다.
FR: Conformément aux lois sur la protection de la vie privée, les données de santé et biométriques nécessitent un consentement explicite, distinct des conditions générales.

[health_data_consent.button]
KO: 권한 요청 중...
FR: Demande d'autorisations...

[health_data_consent.button.2]
KO: 동의하고 워치 연동 계속
FR: Accepter et synchroniser la montre

[health_data_consent.button.3]
KO: 나중에 하기
FR: Plus tard

[health_data_consent.title]
KO: 건강정보 동의
FR: Consentement des données de santé

[health_data_consent.title.2]
KO: 스마트워치 연동 전 동의
FR: Consentement avant la synchro montre connectée

[home.home_wallet.body]
KO: $completedCount/$total회 완료 >
FR: $completedCount/$total terminés >

[iap.coach_plus_product.body]
KO: 6,900원
FR: 6,900 won

[iap.coach_plus_product.body.2]
KO: 59,000원
FR: 59,000 won

[iap.coach_plus_upsell.body]
KO: 무료
FR: Gratuit

[iap.coach_plus_upsell.body.2]
KO: 기본 러닝 안내
FR: Guidage de course basique

[iap.coach_plus_upsell.body.3]
KO: Coach+ 이용 중
FR: Coach+ en cours d'utilisation

[iap.coach_plus_upsell.button]
KO: 구매 복원
FR: Restaurer les achats

[iap.dia_pack_product.body]
KO: 보너스 없음
FR: Aucun bonus

[iap.dia_pack_product.body.2]
KO: 보너스 $bonusDia DIA
FR: Bonus de $bonusDia DIA

[iap.iap_providers.body]
KO: SHARE 충전 💳
FR: Recharger SHARE 💳

[iap.iap_purchase_controller.body]
KO: Google Play 결제 서비스를 사용할 수 없습니다. 잠시 후 다시 시도해 주세요.
FR: Le service de facturation Google Play n'est pas disponible. Veuillez réessayer plus tard.

[iap.iap_purchase_controller.body.10]
KO: 결제 처리 중 오류가 발생했습니다.
FR: Une erreur est survenue lors du traitement du paiement.

[iap.iap_purchase_controller.body.11]
KO: Coach+ 결제가 진행 중입니다.
FR: Le paiement Coach+ est en cours.

[iap.iap_purchase_controller.body.12]
KO: Coach+ 구독이 활성화되었습니다.
FR: L'abonnement Coach+ a été activé.

[iap.iap_purchase_controller.body.13]
KO: Coach+ 결제가 실패했습니다.
FR: Le paiement Coach+ a échoué.

[iap.iap_purchase_controller.body.14]
KO: Coach+ 결제가 취소되었습니다.
FR: Le paiement Coach+ a été annulé.

[iap.iap_purchase_controller.body.15]
KO: 로그인 후 Google Play 결제를 진행해 주세요.
FR: Veuillez vous connecter avant de procéder au paiement Google Play.

[iap.iap_purchase_controller.body.16]
KO: 영수증을 보안 검증 중입니다. SHARE는 검증 완료 후 지급됩니다.
FR: Votre reçu fait l'objet d'une vérification de sécurité. Les SHARE seront attribués une fois la vérification terminée.

[iap.iap_purchase_controller.body.17]
KO: 검증이 완료되어 $shareAmount SHARE가 지급되었습니다.
FR: Vérification terminée. $shareAmount SHARE ont été attribués.

[iap.iap_purchase_controller.body.18]
KO: Google 검증이 완료되어 SHARE가 지갑에 반영됩니다.
FR: La vérification Google est terminée et les SHARE seront crédités sur votre portefeuille.

[iap.iap_purchase_controller.body.19]
KO: 영수증 검증이 거절되었습니다. 고객센터로 문의해 주세요.
FR: La vérification du reçu a été rejetée. Veuillez contacter le service client.

[iap.iap_purchase_controller.body.2]
KO: 상품(${plan.productId})을 찾지 못했습니다. Play Console / App Store Connect 등록을 확인해 주세요.
FR: Produit (${plan.productId}) introuvable. Veuillez vérifier l'enregistrement dans la Play Console / App Store Connect.

[iap.iap_purchase_controller.body.20]
KO: 검증 응답이 지연되고 있습니다. 지갑 잔액을 잠시 후 다시 확인해 주세요.
FR: La réponse de vérification est retardée. Veuillez vérifier à nouveau le solde de votre portefeuille dans un instant.

[iap.iap_purchase_controller.body.21]
KO: 결제 스트림이 일시 중단되었습니다. 연결을 확인한 뒤 다시 시도해 주세요.
FR: Le flux de paiement a été interrompu. Veuillez vérifier votre connexion et réessayer.

[iap.iap_purchase_controller.body.3]
KO: 결제 창을 열 수 없습니다.
FR: Impossible d'ouvrir la fenêtre de paiement.

[iap.iap_purchase_controller.body.4]
KO: 결제를 시작하지 못했습니다. 네트워크 상태를 확인해 주세요.
FR: Impossible de lancer le paiement. Veuillez vérifier votre connexion réseau.

[iap.iap_purchase_controller.body.5]
KO: 구매 복원에 실패했습니다. 잠시 후 다시 시도해 주세요.
FR: Échec de la restauration des achats. Veuillez réessayer dans un instant.

[iap.iap_purchase_controller.body.6]
KO: 상품(${product.productId})을 찾지 못했습니다. Play Console 등록을 확인해 주세요.
FR: Produit (${product.productId}) introuvable. Veuillez vérifier l'enregistrement dans la Play Console.

[iap.iap_purchase_controller.body.7]
KO: 결제가 진행 중입니다. Google Play 승인을 기다려 주세요.
FR: Paiement en cours. Veuillez attendre l'approbation de Google Play.

[iap.iap_purchase_controller.body.8]
KO: 결제가 실패했습니다.
FR: Le paiement a échoué.

[iap.iap_purchase_controller.body.9]
KO: 결제가 취소되었습니다.
FR: Le paiement a été annulé.

[iap.payment_auth.body]
KO: 본인 확인이 취소됐어요. 결제는 진행되지 않았어요.
FR: La vérification d'identité a été annulée. Le paiement n'a pas été effectué.

[iap.payment_auth.body.2]
KO: 확인을 여러 번 틀려 잠시 막혔어요. 잠시 뒤 다시 하거나 화면 잠금(PIN, 패턴)으로 확인해 주세요. 결제는 진행되지 않았어요.
FR: Trop de tentatives incorrectes, temporairement bloqué. Veuillez réessayer dans un instant ou confirmer avec votre verrouillage d'écran (code PIN, schéma). Le paiement n'a pas été effectué.

[iap.payment_auth.body.3]
KO: 결제 전 본인 확인을 하려면 폰에 화면 잠금(지문, PIN, 패턴)이 필요해요. 기기 설정에서 화면 잠금을 켠 뒤 다시 시도해 주세요.
FR: Pour vérifier votre identité avant le paiement, un verrouillage d'écran (empreinte digitale, code PIN, schéma) est requis sur votre téléphone. Veuillez activer le verrouillage d'écran dans les paramètres de l'appareil et réessayer.

[iap.payment_auth.body.4]
KO: 본인 확인을 할 수 없어요. 잠시 뒤 다시 시도해 주세요. 결제는 진행되지 않았어요.
FR: Impossible de vérifier votre identité. Veuillez réessayer dans un instant. Le paiement n'a pas été effectué.
