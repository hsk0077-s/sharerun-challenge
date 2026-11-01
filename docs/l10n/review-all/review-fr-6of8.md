# 번역 검수 요청 — 쉐어런 (French) · 파트 6/8

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
[reward.winner_honor_popup.body.2]
KO: 당신의 땀방울이 세상을 바꿉니다.
FR: Vos gouttes de sueur changent le monde.

[reward.winner_honor_popup.button]
KO: 우승 상금 100% 전액 기부하기
FR: Faire don de 100 % du prix

[reward.winner_reward.body]
KO: 축하합니다! 검증된 러닝으로 우승 상금을 획득했습니다.
FR: Félicitations ! Vous avez remporté le prix en argent grâce à une course vérifiée.

[reward.winner_reward.button]
KO: 우승 상금 수령하기
FR: Récupérer le prix

[reward.winner_reward.button.2]
KO: 우승 상금 50% 기부하기
FR: Faire don de 50 % du prix

[reward.winner_reward.button.3]
KO: 100% 전액 기부하기
FR: Faire don de 100 % de la somme

[reward.winner_reward.dialog]
KO: 우승 임팩트
FR: Impact de la victoire

[run.run_tracker_provider.body]
KO: 달리기를 시작할 수 없습니다. 위치 서비스를 확인해 주세요.
FR: Impossible de démarrer la course. Veuillez vérifier les services de localisation.

[app.runResultAvgPaceLabel]
KO: 평균 페이스:
FR: Allure moyenne :

[app.runResultDonate]
KO: ❤️ 이번 달리기 기부 기여 보기
FR: ❤️ Voir ma contribution au don de cette course

[app.runResultFinalTimeLabel]
KO: 최종 시간:
FR: Temps final :

[app.runResultShare]
KO: 🔗 기록 SNS 공유하기
FR: 🔗 Partager l'enregistrement sur les réseaux sociaux

[app.runResultTitle]
KO: 축하합니다!
완주 성공 🎉
FR: Félicitations !
Course terminée avec succès 🎉

[app.runResultUnconfirmed]
KO: 서버에서 확인된 기록이 없습니다.
FR: Aucun enregistrement confirmé par le serveur.

[app.runResultValueReward]
KO: 서버 확인 노력 보상 +$tokens VALUE
FR: Récompense d'effort confirmée par le serveur +$tokens VALUE

[run_result.body]
KO: 판정: ${result.decision.name}
FR: Décision : ${result.decision.name}

[run_result.body.2]
KO: VALUE 보상: ${result.valueTokenReward}
FR: Récompense en VALUE : ${result.valueTokenReward}

[run_result.body.3]
KO: 로그인이 필요합니다.
FR: Connexion requise.

[run_result.body.4]
KO: 우승 보상 처리가 완료되었습니다.
FR: Le traitement de la récompense de victoire est terminé.

[run_result.body.5]
KO: 우승 보상 처리 실패: ${ApiErrorMessage.from(error)}
FR: Échec du traitement de la récompense de victoire : ${ApiErrorMessage.from(error)}

[run_result.button]
KO: 보상을 처리하는 중...
FR: Traitement de la récompense...

[run_result.button.2]
KO: 우승 상금 선택하기
FR: Choisir le prix de victoire

[run_result.button.3]
KO: 홈으로 돌아가기
FR: Retour à l'accueil

[run_result.title]
KO: 검증된 러닝
FR: Course vérifiée

[run_result.title.2]
KO: 인정되지 않은 기록
FR: Enregistrement non reconnu

[run_result.title.3]
KO: 검증되지 않은 기록
FR: Enregistrement non vérifié

[run_result.title.4]
KO: 러닝 결과
FR: Résultat de la course

[run_result.run_finish_image_share.body]
KO: 공유 이미지를 만들지 못했어요.
FR: Impossible de créer l'image à partager.

[run_result.run_finish_image_share.body.2]
KO: Instagram 스토리로 공유하지 못했어요.
FR: Impossible de partager dans la Story Instagram.

[run_result.run_finish_image_share.body.3]
KO: 쉐어런 완주
FR: ShareRun terminé

[run_result.run_finish_share.body]
KO: 다크
FR: Sombre

[run_result.run_finish_share.body.10]
KO: 목요일
FR: Jeudi

[run_result.run_finish_share.body.11]
KO: 금요일
FR: Vendredi

[run_result.run_finish_share.body.12]
KO: 토요일
FR: Samedi

[run_result.run_finish_share.body.13]
KO: 일요일
FR: Dimanche

[run_result.run_finish_share.body.14]
KO: ${date.month}월 ${date.day}일 ${weekdays[date.weekday - 1]}
FR: ${weekdays[date.weekday - 1]} ${date.day}/${date.month}

[run_result.run_finish_share.body.15]
KO: 이번 달리기로 운영자가 ${_grouped(won)}원을 기부할 예정이에요
FR: Grâce à cette course, l'opérateur prévoit de donner ${_grouped(won)} KRW

[run_result.run_finish_share.body.16]
KO: 오늘은 기부 인정 10km를 모두 채웠어요. 넘는 거리는 기록으로 남아요.
FR: Aujourd'hui, vous avez atteint la limite de 10 km éligibles aux dons. La distance restante sera enregistrée comme enregistrement.

[run_result.run_finish_share.body.17]
KO: 기부 참여 기록
FR: Historique de participation aux dons

[run_result.run_finish_share.body.18]
KO: 이번 달리기는 기부에 포함되지 않았어요.
FR: Cette course n'a pas été incluse dans le don.

[run_result.run_finish_share.body.19]
KO: 쉐어런 앱에서 ${distanceKm}km를 달렸어요. ⏱ 기록: $time
FR: J'ai couru ${distanceKm} km sur l'application ShareRun. ⏱ Temps : $time

[run_result.run_finish_share.body.2]
KO: 블루
FR: Bleu

[run_result.run_finish_share.body.20]
KO: 오늘의 러닝
FR: Course du jour

[run_result.run_finish_share.body.21]
KO: 평균 심박 $averageHeartRate bpm
FR: Fréquence cardiaque moyenne $averageHeartRate bpm

[run_result.run_finish_share.body.22]
KO: 구간 페이스
FR: Allure par segment

[run_result.run_finish_share.body.23]
KO: 시간
FR: Temps

[run_result.run_finish_share.body.24]
KO: 페이스
FR: Allure

[run_result.run_finish_share.body.3]
KO: 핑크
FR: Rose

[run_result.run_finish_share.body.4]
KO: 옐로
FR: Jaune

[run_result.run_finish_share.body.5]
KO: 민트
FR: Menthe

[run_result.run_finish_share.body.6]
KO: 내 사진
FR: Ma photo

[run_result.run_finish_share.body.7]
KO: 월요일
FR: Lundi

[run_result.run_finish_share.body.8]
KO: 화요일
FR: Mardi

[run_result.run_finish_share.body.9]
KO: 수요일
FR: Mercredi

[run_result.run_finish_share_flow.body]
KO: 하나만 올리기
FR: Publier un seul élément

[run_result.run_finish_share_flow.body.2]
KO: 여러 개 순서대로 올리기
FR: Publier plusieurs dans l'ordre

[run_result.run_finish_share_flow.body.3]
KO: 순서대로 공유
FR: Partager dans l'ordre

[run_result.run_finish_share_flow.body.4]
KO: 그만하기
FR: Arrêter

[run_result.run_finish_share_flow.body.5]
KO: 어떻게 올릴까요?
FR: Comment souhaitez-vous publier ?

[run_result.run_finish_share_flow.body.6]
KO: 어디에 올릴까요?
FR: Où souhaitez-vous publier ?

[run_result.run_finish_share_flow.body.7]
KO: 순서대로 올리기
FR: Publier dans l'ordre

[run_result.run_finish_share_flow.body.8]
KO: 다음: $label
FR: Suivant : $label

[run_result.run_finish_share_targets.body]
KO: Instagram 스토리
FR: Story Instagram

[run_result.run_finish_share_targets.body.2]
KO: Instagram 피드
FR: Fil Instagram

[run_result.run_finish_share_targets.body.3]
KO: 더보기
FR: Plus

[run_tracking.body]
KO: 심박 ${telemetry.currentHeartRate?.toString() ??
FR: Fréquence cardiaque ${telemetry.currentHeartRate?.toString() ??

[run_tracking.body.2]
KO: } BPM / 케이던스 ${telemetry.currentCadenceSpm?.toString() ??
FR: } BPM / Cadence ${telemetry.currentCadenceSpm?.toString() ??

[run_tracking.body.3]
KO: 자이로 안정도 ${telemetry.gyroStabilityScore.toStringAsFixed(2)}
FR: Stabilité du gyroscope ${telemetry.gyroStabilityScore.toStringAsFixed(2)}

[run_tracking.body.4]
KO: 센서를 시작하는 중...
FR: Démarrage du capteur...

[run_tracking.body.5]
KO: 러닝 검증 중...
FR: Vérification de la course...

[run_tracking.body.6]
KO: 러닝 끝내고 검증하기
FR: Terminer la course et vérifier

[run_tracking.body.7]
KO: MyPage에서 [선택] 민감정보 수집 동의 후 러닝 검증을 시작할 수 있습니다.
FR: Vous pouvez commencer la vérification de votre course après avoir accepté la collecte [Optionnelle] d'informations sensibles dans MyPage.

[run_tracking.body.8]
KO: 센서를 시작하지 못했어요: $error
FR: Échec du démarrage des capteurs : $error

[run_tracking.title]
KO: 달리기 기록
FR: Enregistrement de course

[run_tracking.toast]
KO: 러닝 검증에 실패했어요: ${ApiErrorMessage.from(error)}
FR: Échec de la vérification de la course : ${ApiErrorMessage.from(error)}

[run_tracking.ble_heart_rate_service.body]
KO: BLE 심박 센서 (${map[
FR: Capteur de fréquence cardiaque BLE (${map[

[run_tracking.ble_heart_rate_service.body.2]
KO: 이 기기에서는 블루투스 심박 스캔을 지원하지 않습니다.
FR: La recherche de fréquence cardiaque par Bluetooth n'est pas prise en charge sur cet appareil.

[run_tracking.ble_heart_rate_service.body.3]
KO: 블루투스 권한 또는 상태를 확인해 주세요.
FR: Veuillez vérifier l'autorisation ou l'état du Bluetooth.

[run_tracking.ble_heart_rate_service.body.4]
KO: 이 기기에서는 블루투스 심박 연결을 지원하지 않습니다.
FR: La connexion de fréquence cardiaque par Bluetooth n'est pas prise en charge sur cet appareil.

[run_tracking.ble_heart_rate_service.body.5]
KO: 센서 연결에 실패했습니다.
FR: Échec de la connexion au capteur.

[run_tracking.gps_tracking_service.body]
KO: 실시간 러닝 GPS 추적 중
FR: Suivi GPS de course en temps réel en cours

[run_tracking.home_start_gate.body]
KO: 마이페이지에서 민감정보 수집에 동의해주세요
FR: Veuillez accepter la collecte de données sensibles dans Ma page.

[run_tracking.home_start_gate.body.2]
KO: 로그인 후 러닝 검증을 진행할 수 있습니다.
FR: Vous pouvez procéder à la vérification de la course après vous être connecté.

[run_tracking.home_start_gate.body.3]
KO: 러닝이 시작되지 않았습니다.
FR: La course n'a pas commencé.

[run_tracking.music_controls.body]
KO: 음악을 조절하지 못했어요.
FR: Impossible de contrôler la musique.

[run_tracking.music_controls.body.2]
KO: 재생 / 일시정지
FR: Lecture / Pause

[run_tracking.music_controls.body.3]
KO: 다음 곡
FR: Titre suivant

[run_tracking.music_controls.body.4]
KO: 음악 앱 열기
FR: Ouvrir l'application musicale

[run_tracking.music_controls.body.5]
KO: 음악 앱을 찾지 못했어요. 쓰는 음악 앱을 직접 열어 주세요.
FR: Impossible de trouver une application musicale. Veuillez ouvrir votre application musicale directement.

[run_tracking.music_controls.button]
KO: 이전 곡
FR: Titre précédent

[run_tracking.run_recording_checklist.body]
KO: 화면을 끄거나 다른 앱을 켜도 경로 기록과 음성 코칭이 이어지도록 아래 항목을 확인해 주세요.
FR: Veuillez vérifier les éléments ci-dessous afin que l'enregistrement du parcours et le coaching vocal continuent même lorsque l'écran est éteint ou qu'une autre application est ouverte.

[run_tracking.run_recording_checklist.body.10]
KO: 허용하지 않아도 달리기는 시작할 수 있습니다.
FR: Vous pouvez commencer à courir même sans autoriser.

[run_tracking.run_recording_checklist.body.11]
KO: 항목을 나중에 바꿔도 됩니다.
FR: Vous pourrez modifier ces paramètres plus tard.

[run_tracking.run_recording_checklist.body.12]
KO: 필요
FR: Requis

[run_tracking.run_recording_checklist.body.2]
KO: 위치 권한
FR: Autorisation de localisation

[run_tracking.run_recording_checklist.body.3]
KO: 앱을 사용하는 동안 허용해 주세요. 항상 허용은 요청하지 않습니다.
FR: Veuillez autoriser pendant l'utilisation de l'application. Nous ne demandons pas « Toujours autoriser ».

[run_tracking.run_recording_checklist.body.4]
KO: 허용됨
FR: Autorisé

[run_tracking.run_recording_checklist.body.5]
KO: 허용하기
FR: Autoriser

[run_tracking.run_recording_checklist.body.6]
KO: 알림 권한
FR: Autorisation de notification

[run_tracking.run_recording_checklist.body.7]
KO: 달리기 기록 알림을 표시합니다. Android 13 이상에서 필요합니다.
FR: Affiche les notifications d'enregistrement de course. Requis sur Android 13 ou version ultérieure.

[run_tracking.run_recording_checklist.body.8]
KO: 배터리 최적화
FR: Optimisation de la batterie

[run_tracking.run_recording_checklist.body.9]
KO: 설정됨
FR: Configuré

[run_tracking.run_recording_checklist.button]
KO: 확인하고 달리기
FR: Confirmer et courir

[run_tracking.run_recording_checklist.title]
KO: 달리기 기록 설정
FR: Paramètres d'enregistrement de course

[run_tracking.run_recording_checklist.toast]
KO: 배터리 설정 화면을 열지 못했습니다.
FR: Impossible d'ouvrir les paramètres de la batterie.

[run_tracking.run_recording_foreground.body]
KO: 화면이 꺼져도 달리기 경로와 음성 코칭을 이어갑니다.
FR: Continue d'enregistrer le parcours et le coaching vocal même lorsque l'écran est éteint.

[run_tracking.run_recording_policy.body]
KO: 쉐어런 · 달리기 기록 중
FR: ShareRun · Enregistrement de la course

[run_tracking.run_recording_policy.body.2]
KO: 이전 달리기가 중단되었습니다
FR: La course précédente a été interrompue

[run_tracking.run_recording_policy.body.3]
KO: 앱이 중간에 종료되어 직전 달리기는 저장되지 않았습니다. 보상은 지급되지 않고, 기록도 남지 않습니다.
FR: L'application s'est fermée de manière inattendue, votre course précédente n'a donc pas été enregistrée. Aucune récompense n'est accordée et aucun historique n'est conservé.

[run_tracking.run_recording_policy.body.4]
KO: 화면이 꺼지면 달리기 기록이 중단될 수 있습니다.
FR: L'enregistrement de la course peut être interrompu lorsque l'écran s'éteint.

[run_tracking.run_recording_policy.body.5]
KO: 달리기 기록 설정 점검
FR: Vérifier les paramètres d'enregistrement de course

[run_tracking.run_recording_policy.body.6]
KO: 시스템 배터리 최적화 화면에서 쉐어런을 찾아 주세요. 삼성 갤럭시는 '제한 없음'으로 바꿔 주세요.
FR: Veuillez trouver ShareRun dans l'écran d'optimisation de la batterie du système. Sur Samsung Galaxy, modifiez l'option sur « Non restreinte ».

[run_tracking.run_session_service.body]
KO: 위치 서비스가 꺼져 있습니다.
FR: Les services de localisation sont désactivés.

[run_tracking.run_session_service.body.2]
KO: 위치 권한이 영구 거부되었습니다. 설정에서 허용해 주세요.
FR: L'autorisation de localisation a été refusée définitivement. Veuillez l'autoriser dans les paramètres.

[run_tracking.run_session_service.body.3]
KO: 위치 권한이 허용되었습니다.
FR: Autorisation de localisation accordée.

[run_tracking.run_start_preflight.button]
KO: 심박수·케이던스 검증을 위해 [선택] 건강정보 수집 동의가 필요합니다. 일반 이용약관과 별도로 Opt-in 해 주세요.
FR: Le consentement à la collecte de données de santé [Facultatif] est requis pour vérifier la fréquence cardiaque et la cadence. Veuillez accepter séparément des conditions générales.

[run_tracking.run_start_preflight.button.2]
KO: 동의 화면으로
FR: Aller à l'écran de consentement

[run_tracking.run_start_preflight.dialog]
KO: 건강정보 동의 필요
FR: Consentement aux données de santé requis

[run_tracking.run_start_preflight.toast]
KO: 로그인 후 러닝을 시작할 수 있습니다.
FR: Vous pouvez commencer à courir après vous être connecté.

[run_tracking.sponsor_live_buff_banner.body]
KO: 스폰서 라이브 버프
FR: Buff live de sponsor

[run_tracking.watch_runtime_permissions_service.body]
KO: Health Connect 앱 설치
FR: Installer l'application Health Connect

[run_tracking.watch_runtime_permissions_service.body.2]
KO: Health Connect 건강 데이터
FR: Données de santé Health Connect

[run_tracking.watch_runtime_permissions_service.body.3]
KO: 신체 활동 인식
FR: Reconnaissance de l'activité physique

[app.runningCrewCreateButton]
KO: [50 DIA 또는 30,000 SHARE로 새 크루 창설하기]
FR: [Créer un nouveau crew avec 50 DIA ou 30 000 SHARE]

[app.runningCrewEnterRoom]
KO: 크루 룸 입장하기
FR: Entrer dans le salon de crew

[app.runningCrewHeadline]
KO: 같이 달릴
크루 찾기
FR: Trouver un crew
pour courir ensemble

[app.runningCrewMyCrewName]
KO: 인천 논현 최강 크루
FR: Crew le plus fort d'Incheon Nonhyeon

[app.runningCrewMyCrewStats]
KO: 소속 크루원: 45/50명 | 누적 달성 거리: 3,240km
FR: Membres du crew : 45/50 | Distance cumulée : 3 240 km

[app.runningCrewNoCrewHint]
KO: 크루에 들어가면 함께 달린 거리를 모아 월간 순위에 도전할 수 있어요. 크루를 만들거나 아래에서 찾아보세요.
FR: Rejoignez un crew pour cumuler vos distances de course et viser le classement mensuel. Créez un crew ou trouvez-en un ci-dessous.

[app.runningCrewNoCrewName]
KO: 아직 크루가 없어요
FR: Pas encore de crew

[app.runningCrewProgressLabel]
KO: 이번 주 크루 대항전 10K 완주율
FR: Taux de réussite 10K du tournoi de crew de la semaine

[app.runningCrewTitle]
KO: 러닝 크루 (Crew)
FR: Running crew

[running_crew.body]
KO: 가입 신청
FR: Demande d'adhésion

[running_crew.body.10]
KO: 크루는 두고 나만 나가고 싶다면 먼저 "크루원 보기"에서 크루장을 넘겨 주세요.
FR: Si vous souhaitez quitter le crew sans le supprimer, transférez d'abord le rôle de chef dans « Voir les membres ».

[running_crew.body.11]
KO: ${member.nickname}님에게 크루장을 넘길까요? 나는 부크루장이 되고, 원하면 그 뒤에 크루에서 나갈 수 있어요.
FR: Transférer le rôle de chef de crew à ${member.nickname} ? Vous deviendrez co-leader et pourrez ensuite quitter le crew si vous le souhaitez.

[running_crew.body.12]
KO: 넘기기
FR: Transférer

[running_crew.body.13]
KO: 크루원
FR: Membre du crew

[running_crew.body.14]
KO: 누적 거리
FR: Distance totale

[running_crew.body.15]
KO: 크루 관리
FR: Gestion du crew

[running_crew.body.16]
KO: 공지 · 크루원 · 혜택 선물
FR: Annonces · Membres · Cadeaux d'avantages

[running_crew.body.17]
KO: 크루원 보기
FR: Voir les membres

[running_crew.body.18]
KO: ${mine.crew.memberCount}명 · 내 역할 ${_roleLabel(mine.role)}
FR: ${mine.crew.memberCount} membres · Mon rôle : ${_roleLabel(mine.role)}

[running_crew.body.19]
KO: 가입 신청 ${mine.pendingRequests}건
FR: ${mine.pendingRequests} demandes d'adhésion

[running_crew.body.2]
KO: 크루 가입
FR: Rejoindre le crew

[running_crew.body.20]
KO: 받을지 정해요
FR: Décidez d'accepter ou non

[running_crew.body.21]
KO: 처음 한 번은 무료
FR: La première fois est gratuite

[running_crew.body.22]
KO: 지금은 승인 가입
FR: Actuellement sur approbation

[running_crew.body.23]
KO: 지금은 자유 가입
FR: Actuellement adhésion libre

[running_crew.body.24]
KO: 크루원과 함께 모두 나와요
FR: Tous les membres quitteront le crew ensemble

[running_crew.body.25]
KO: 다시 가입할 수 있어요
FR: Vous pouvez rejoindre à nouveau

[running_crew.body.26]
KO: 엠블럼 바꾸기
FR: Changer d'emblème

[running_crew.body.27]
KO: 틀 ${CrewEmblem.frames.length}가지 · 문양 ${CrewEmblem.glyphIds.length}가지 · 색 ${CrewEmblem.paletteColors.length}가지
FR: ${CrewEmblem.frames.length} cadres · ${CrewEmblem.glyphIds.length} symboles · ${CrewEmblem.paletteColors.length} couleurs

[running_crew.body.28]
KO: 색 ${CrewEmblem.paletteColors.length}가지
FR: ${CrewEmblem.paletteColors.length} couleurs

[running_crew.body.29]
KO: 다른 크루 찾기
FR: Trouver d'autres crews

[running_crew.body.3]
KO: "${crew.name}" 크루는 크루장이 승인해야 들어갈 수 있어요. 신청할까요?
FR: Rejoindre le crew « ${crew.name} » nécessite l'approbation du chef. Postuler ?

[running_crew.body.30]
KO: 검색: "$_searchQuery"
FR: Recherche : « $_searchQuery »

[running_crew.body.31]
KO: 검색 결과가 없습니다.
FR: Aucun résultat de recherche.

[running_crew.body.32]
KO: 보유 SHARE ${_format(wallet.shareBalance)}
FR: SHARE possédés : ${_format(wallet.shareBalance)}

[running_crew.body.33]
KO: 크루장
FR: Chef de crew

[running_crew.body.34]
KO: 부크루장
FR: Co-leader du crew

[running_crew.body.35]
KO: 명예의 전당
FR: Temple de la renommée

[running_crew.body.36]
KO: 역대 최고 ${ranking.bestRank}위
FR: Meilleur historique : ${ranking.bestRank}e

[running_crew.body.37]
KO: 순위는 이번 달 크루 거리 ÷ 크루원 수예요. 달이 끝나면 확정돼요.
FR: Le classement correspond à la distance du crew ce mois-ci ÷ nombre de membres. Il est fixé à la fin du mois.

[running_crew.body.38]
KO: 크루 이름 검색
FR: Rechercher le nom du crew

[running_crew.body.39]
KO: 50 DIA 또는 30,000 SHARE
FR: 50 DIA ou 30 000 SHARE

[running_crew.body.4]
KO: "${crew.name}" 크루에 가입할까요?
FR: Voulez-vous rejoindre le crew « ${crew.name} » ?

[running_crew.body.40]
KO: 아직 만들어진 크루가 없어요.
FR: Aucun crew n'a encore été créé.

[running_crew.body.41]
KO: 가입 불가
FR: Impossible de rejoindre

[running_crew.body.42]
KO: 가득 참
FR: Complet

[running_crew.body.43]
KO: ${mine.crew.name} · ${mine.members.length}명
FR: ${mine.crew.name} · ${mine.members.length} membres

[running_crew.body.44]
KO: 부크루장 해제
FR: Retirer le rôle de co-leader

[running_crew.body.45]
KO: 부크루장으로
FR: Nommer co-leader

[running_crew.body.46]
KO: 신고하기
FR: Signaler

[running_crew.body.47]
KO: 가입 신청 ${requests.length}건
FR: ${requests.length} demandes d'adhésion

[running_crew.body.48]
KO: 기다리는 신청이 없어요.
FR: Aucune demande en attente.

[running_crew.body.49]
KO: "${mine.crew.name}" 크루를 없애요.
크루장인 나도 함께 크루에서 나와요.
산 엠블럼도 사라지고 되돌릴 수 없어요.

$note
FR: Le crew « ${mine.crew.name} » va être supprimé.
Moi, en tant que chef, je quitterai aussi le crew.
L'emblème acheté disparaîtra aussi et cela ne peut pas être annulé.

$note

[running_crew.body.5]
KO: 신청
FR: Postuler

[running_crew.body.6]
KO: "$name"(으)로 바꾸면 $cost DIA가 들어요. 보너스 DIA를 먼저 써요.
FR: Changer pour « $name » coûte $cost DIA. Le DIA bonus sera utilisé en premier.

[running_crew.body.7]
KO: 크루 없애기
FR: Supprimer le crew

[running_crew.body.8]
KO: "${mine.crew.name}" 크루를 없애요.
${others > 0 ?
FR: Supprimer le crew « ${mine.crew.name} ».
${others > 0 ?

[running_crew.body.9]
KO: "${mine.crew.name}" 크루를 없애요.
크루원 $others명도 모두 크루에서 나오고, 크루장인 나도 함께 크루에서 나와요.
산 엠블럼도 사라지고 되돌릴 수 없어요.

$note
FR: Le crew « ${mine.crew.name} » va être supprimé.
Les $others membres quitteront également le crew, et moi, en tant que chef, le quitterai aussi.
L'emblème acheté disparaîtra aussi et cela ne peut pas être annulé.

$note

[running_crew.button]
KO: 크루 만들기
FR: Créer un crew

[running_crew.button.10]
KO: 받기
FR: Accepter

[running_crew.button.2]
KO: 서버가 50 DIA 또는 30,000 SHARE 중 선택한 금액만 차감합니다.
FR: Le serveur déduira uniquement le montant sélectionné : 50 DIA ou 30 000 SHARE.

[running_crew.button.3]
KO: 가입 방식
FR: Mode d'adhésion

[running_crew.button.4]
KO: 자유 가입
누구나 바로 들어와요
FR: Adhésion libre
Tout le monde peut rejoindre immédiatement

[running_crew.button.5]
KO: 승인 가입
신청을 받아 크루장이 정해요
FR: Adhésion sur approbation
Le chef de crew décide après demande

[running_crew.button.6]
KO: 검색
FR: Rechercher

[running_crew.button.7]
KO: 신고
FR: Signaler

[running_crew.button.8]
KO: 신청 취소
FR: Annuler la demande

[running_crew.button.9]
KO: 거절
FR: Refuser

[running_crew.dialog]
KO: 크루 이름 바꾸기
FR: Changer le nom du crew

[running_crew.dialog.2]
KO: 다음
FR: Suivant

[running_crew.hint]
KO: 크루 검색
FR: Rechercher un crew

[running_crew.hint.2]
KO: 크루 이름 입력
FR: Entrez le nom du crew

[running_crew.hint.3]
KO: 초기화
FR: Réinitialiser

[running_crew.hint.4]
KO: 2~20자로 지어 주세요
FR: Veuillez saisir de 2 à 20 caractères

[running_crew.label]
KO: ${crew.memberCount}/${crew.maxMembers}명${crew.needsApproval ?
FR: ${crew.memberCount}/${crew.maxMembers} membres${crew.needsApproval ?

[running_crew.toast]
KO: 로그인한 뒤에 다시 시도해 주세요.
FR: Veuillez vous connecter et réessayer.

[running_crew.toast.10]
KO: 유료 엠블럼은 크루장만 살 수 있어요.
FR: Seul le chef de crew peut acheter des emblèmes payants.

[running_crew.toast.11]
KO: 이미 크루가 가진 엠블럼이에요.
FR: Le crew possède déjà cet emblème.

[running_crew.toast.12]
KO: 엠블럼을 사지 못했어요. 잠시 뒤 다시 해 주세요.
FR: Impossible d'acheter l'emblème. Veuillez réessayer dans un instant.

[running_crew.toast.13]
KO: 엠블럼은 자주 바꿀 수 없어요. 잠시 뒤에 다시 바꿔 주세요.
FR: L'emblème ne peut pas être changé fréquemment. Veuillez réessayer plus tard.

[running_crew.toast.14]
KO: 아직 쓸 수 없는 테두리나 엠블럼이에요.
FR: Ce cadre ou emblème n'est pas encore disponible.

[running_crew.toast.15]
KO: 엠블럼을 바꾸지 못했어요. 잠시 뒤 다시 해 주세요.
FR: Impossible de modifier l'emblème. Veuillez réessayer dans un instant.

[running_crew.toast.16]
KO: 이 폰에만 저장했어요. 서버에 크루가 생기면 함께 저장돼요.
FR: Enregistré uniquement sur ce téléphone. Sera sauvegardé lors de la création du crew sur le serveur.

[running_crew.toast.17]
KO: 크루 엠블럼을 바꿨어요.
FR: Emblème du crew modifié.

[running_crew.toast.18]
KO: 가입
FR: Rejoindre

[running_crew.toast.19]
KO: "${crew.name}" 크루에 가입했어요.
FR: Vous avez rejoint le crew « ${crew.name} ».

[running_crew.toast.2]
KO: 새 크루 창설 완료 (−$_createCrewDiaCost DIA)
FR: Nouveau crew créé (−$_createCrewDiaCost DIA)

[running_crew.toast.20]
KO: 가입을 신청했어요. 승인되면 크루원이 돼요.
FR: Demande envoyée. Vous deviendrez membre une fois approuvée.

[running_crew.toast.21]
KO: 이미 다른 크루에 있거나 신청해 둔 곳이 있거나 인원이 가득 찼어요.
FR: Vous êtes déjà dans un autre crew, avez une demande en attente, ou le crew est complet.

[running_crew.toast.22]
KO: 이 크루에는 들어갈 수 없어요.
FR: Impossible de rejoindre ce crew.

[running_crew.toast.23]
KO: 가입하지 못했어요. 잠시 뒤 다시 해 주세요.
FR: Échec de l'adhésion. Veuillez réessayer dans un instant.

[running_crew.toast.24]
KO: 가입 신청을 거뒀어요.
FR: Demande d'adhésion annulée.

[running_crew.toast.25]
KO: 거두지 못했어요. 잠시 뒤 다시 해 주세요.
FR: Impossible d'annuler. Veuillez réessayer dans un instant.

[running_crew.toast.26]
KO: 자유 가입으로 바꿨어요.
FR: Changé pour adhésion libre.

[running_crew.toast.27]
KO: 승인 가입으로 바꿨어요.
FR: Changé pour adhésion sur approbation.

[running_crew.toast.28]
KO: 크루 이름을 "$name"(으)로 바꿨어요.
FR: Nom du crew changé pour « $name ».

[running_crew.toast.29]
KO: 신청 목록을 불러오지 못했어요.
FR: Impossible de charger la liste des demandes.

[running_crew.toast.3]
KO: 새 크루 창설 완료 (−$_createCrewShareCost SHARE)
FR: Nouveau crew créé (−$_createCrewShareCost SHARE)

[running_crew.toast.30]
KO: ${request.nickname}님을 받았어요.
FR: ${request.nickname} a été accepté(e).

[running_crew.toast.31]
KO: ${request.nickname}님의 신청을 거절했어요.
FR: Demande de ${request.nickname} refusée.

[running_crew.toast.32]
KO: 이미 다른 크루에 있거나 인원이 가득 찼어요.
FR: Déjà dans un autre crew ou le crew est complet.

[running_crew.toast.33]
KO: 처리하지 못했어요. 잠시 뒤 다시 해 주세요.
FR: Impossible de traiter. Veuillez réessayer dans un instant.

[running_crew.toast.34]
KO: 크루를 없앴어요.
FR: Le crew a été supprimé.

[running_crew.toast.35]
KO: 없애지 못했어요. 잠시 뒤 다시 해 주세요.
FR: Impossible de supprimer. Veuillez réessayer dans un instant.

[running_crew.toast.36]
KO: 크루 나가기
FR: Quitter le crew

[running_crew.toast.37]
KO: "${mine.crew.name}" 크루에서 나갈까요? 다시 가입할 수 있어요.
FR: Voulez-vous quitter le crew « ${mine.crew.name} » ? Vous pourrez le rejoindre à nouveau.

[running_crew.toast.38]
KO: 나가기
FR: Quitter

[running_crew.toast.39]
KO: 크루에서 나왔어요.
FR: Vous avez quitté le crew.

[running_crew.toast.4]
KO: 크루 창설 실패: $error
FR: Échec de la création du crew : $error

[running_crew.toast.40]
KO: 크루장은 나갈 수 없어요.
FR: Le chef de crew ne peut pas quitter le crew.

[running_crew.toast.41]
KO: 나가지 못했어요. 잠시 뒤 다시 해 주세요.
FR: Impossible de quitter. Veuillez réessayer dans un instant.

[running_crew.toast.42]
KO: 지금은 신고할 수 없어요.
FR: Impossible de signaler pour le moment.

[running_crew.toast.43]
KO: 신고했어요. 운영자가 확인할게요.
FR: Signalement envoyé. Un administrateur va vérifier.

[running_crew.toast.44]
KO: 신고하지 못했어요. 잠시 뒤 다시 해 주세요.
FR: Impossible de signaler. Veuillez réessayer dans un instant.

[running_crew.toast.45]
KO: 크루장 넘기기
FR: Transférer le rôle de chef de crew

[running_crew.toast.46]
KO: ${member.nickname}님이 새 크루장이에요.
FR: ${member.nickname} est le nouveau chef de crew.

[running_crew.toast.47]
KO: 넘기지 못했어요. 잠시 뒤 다시 해 주세요.
FR: Impossible de transférer. Veuillez réessayer dans un instant.

[running_crew.toast.48]
KO: ${member.nickname}님을 부크루장으로 했어요.
FR: ${member.nickname} a été désigné(e) comme co-leader du crew.

[running_crew.toast.5]
KO: 전체 랭킹을 표시합니다.
FR: Affichage du classement général.

[running_crew.toast.6]
KO: "$result" 검색 결과를 표시합니다.
FR: Affichage des résultats de recherche pour « $result ».

[running_crew.toast.7]
KO: 크루에 들어가면 크루 룸을 볼 수 있어요.
FR: Rejoignez le crew pour voir la salle du crew.

[running_crew.toast.8]
KO: 엠블럼은 자주 바꿀 수 없어요. 약 $days일 뒤에 다시 바꿀 수 있어요.
FR: L'emblème ne peut pas être changé fréquemment. Vous pourrez le modifier dans environ $days jours.

[running_crew.toast.9]
KO: DIA가 부족해요.
FR: DIA insuffisants.

[security_privacy_center.body]
KO: 적립 규칙, 내 거래 내역, 기부 정산, 기록 이의 신청을 한곳에서 확인해요.
FR: Consultez les règles de gain, l'historique des transactions, les règlements de dons et les réclamations au même endroit.

[security_privacy_center.body.2]
KO: 서버 원장에 기록된 지급·사용 내역
FR: Historique de versement et d'utilisation enregistré dans le registre du serveur

[security_privacy_center.body.3]
KO: 기부 정산
FR: Règlement des dons

[security_privacy_center.body.4]
KO: 내가 기여한 금액 · 이번 달 기부
FR: Montant de ma contribution · Dons du mois

[security_privacy_center.body.5]
KO: 로그인된 기기
FR: Appareils connectés

[security_privacy_center.body.6]
KO: 내 계정을 연 기기 · 모든 기기에서 로그아웃
FR: Appareils connectés à mon compte · Se déconnecter de tous les appareils

[security_privacy_center.body.7]
KO: 기록 소명 및 고객센터
FR: Justificatif d'enregistrement et service client

[security_privacy_center.body.8]
KO: 검증 결과에 이의가 있을 때
FR: En cas de contestation des résultats de vérification
