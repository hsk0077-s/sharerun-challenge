# 번역 검수 요청 — 쉐어런 (German) · 파트 6/8

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
[app.runResultShare]
KO: 🔗 기록 SNS 공유하기
DE: 🔗 Aufzeichnung auf Social Media teilen

[app.runResultTitle]
KO: 축하합니다!
완주 성공 🎉
DE: Herzlichen Glückwunsch!
Erfolgreich abgeschlossen 🎉

[app.runResultUnconfirmed]
KO: 서버에서 확인된 기록이 없습니다.
DE: Keine vom Server bestätigte Aufzeichnung vorhanden.

[app.runResultValueReward]
KO: 서버 확인 노력 보상 +$tokens VALUE
DE: Serverbestätigte Anstrengungsbelohnung +$tokens VALUE

[run_result.body]
KO: 판정: ${result.decision.name}
DE: Urteil: ${result.decision.name}

[run_result.body.2]
KO: VALUE 보상: ${result.valueTokenReward}
DE: VALUE-Belohnung: ${result.valueTokenReward}

[run_result.body.3]
KO: 로그인이 필요합니다.
DE: Anmeldung erforderlich.

[run_result.body.4]
KO: 우승 보상 처리가 완료되었습니다.
DE: Die Verarbeitung der Siegerbelohnung ist abgeschlossen.

[run_result.body.5]
KO: 우승 보상 처리 실패: ${ApiErrorMessage.from(error)}
DE: Fehler beim Verarbeiten der Siegerbelohnung: ${ApiErrorMessage.from(error)}

[run_result.button]
KO: 보상을 처리하는 중...
DE: Belohnung wird verarbeitet...

[run_result.button.2]
KO: 우승 상금 선택하기
DE: Siegerpreis auswählen

[run_result.button.3]
KO: 홈으로 돌아가기
DE: Zurück zur Startseite

[run_result.title]
KO: 검증된 러닝
DE: Verifizierter Lauf

[run_result.title.2]
KO: 인정되지 않은 기록
DE: Nicht anerkannte Aufzeichnung

[run_result.title.3]
KO: 검증되지 않은 기록
DE: Nicht verifizierte Aufzeichnung

[run_result.title.4]
KO: 러닝 결과
DE: Laufergebnis

[run_result.run_finish_image_share.body]
KO: 공유 이미지를 만들지 못했어요.
DE: Freigabebild konnte nicht erstellt werden.

[run_result.run_finish_image_share.body.2]
KO: Instagram 스토리로 공유하지 못했어요.
DE: Konnte nicht in der Instagram Story geteilt werden.

[run_result.run_finish_image_share.body.3]
KO: 쉐어런 완주
DE: ShareRun abgeschlossen

[run_result.run_finish_share.body]
KO: 다크
DE: Dunkel

[run_result.run_finish_share.body.10]
KO: 목요일
DE: Donnerstag

[run_result.run_finish_share.body.11]
KO: 금요일
DE: Freitag

[run_result.run_finish_share.body.12]
KO: 토요일
DE: Samstag

[run_result.run_finish_share.body.13]
KO: 일요일
DE: Sonntag

[run_result.run_finish_share.body.14]
KO: ${date.month}월 ${date.day}일 ${weekdays[date.weekday - 1]}
DE: ${weekdays[date.weekday - 1]}, ${date.day}.${date.month}.

[run_result.run_finish_share.body.15]
KO: 이번 달리기로 운영자가 ${_grouped(won)}원을 기부할 예정이에요
DE: Mit diesem Lauf plant der Betreiber, ${_grouped(won)} KRW zu spenden

[run_result.run_finish_share.body.16]
KO: 오늘은 기부 인정 10km를 모두 채웠어요. 넘는 거리는 기록으로 남아요.
DE: Heute haben Sie das Spendenlimit von 10 km vollständig erreicht. Darüber hinausgehende Distanzen werden als Rekord gespeichert.

[run_result.run_finish_share.body.17]
KO: 기부 참여 기록
DE: Nachweis der Spendenbeteiligung

[run_result.run_finish_share.body.18]
KO: 이번 달리기는 기부에 포함되지 않았어요.
DE: Dieser Lauf war nicht in der Spende enthalten.

[run_result.run_finish_share.body.19]
KO: 쉐어런 앱에서 ${distanceKm}km를 달렸어요. ⏱ 기록: $time
DE: Ich bin ${distanceKm} km in der ShareRun-App gelaufen. ⏱ Zeit: $time

[run_result.run_finish_share.body.2]
KO: 블루
DE: Blau

[run_result.run_finish_share.body.20]
KO: 오늘의 러닝
DE: Heutiger Lauf

[run_result.run_finish_share.body.21]
KO: 평균 심박 $averageHeartRate bpm
DE: Durchschnittliche Herzfrequenz $averageHeartRate bpm

[run_result.run_finish_share.body.22]
KO: 구간 페이스
DE: Split-Pace

[run_result.run_finish_share.body.23]
KO: 시간
DE: Zeit

[run_result.run_finish_share.body.24]
KO: 페이스
DE: Pace

[run_result.run_finish_share.body.3]
KO: 핑크
DE: Rosa

[run_result.run_finish_share.body.4]
KO: 옐로
DE: Gelb

[run_result.run_finish_share.body.5]
KO: 민트
DE: Minze

[run_result.run_finish_share.body.6]
KO: 내 사진
DE: Mein Foto

[run_result.run_finish_share.body.7]
KO: 월요일
DE: Montag

[run_result.run_finish_share.body.8]
KO: 화요일
DE: Dienstag

[run_result.run_finish_share.body.9]
KO: 수요일
DE: Mittwoch

[run_result.run_finish_share_flow.body]
KO: 하나만 올리기
DE: Einzeln posten

[run_result.run_finish_share_flow.body.2]
KO: 여러 개 순서대로 올리기
DE: Mehrere nacheinander posten

[run_result.run_finish_share_flow.body.3]
KO: 순서대로 공유
DE: Nacheinander teilen

[run_result.run_finish_share_flow.body.4]
KO: 그만하기
DE: Abbrechen

[run_result.run_finish_share_flow.body.5]
KO: 어떻게 올릴까요?
DE: Wie möchten Sie posten?

[run_result.run_finish_share_flow.body.6]
KO: 어디에 올릴까요?
DE: Wo möchten Sie posten?

[run_result.run_finish_share_flow.body.7]
KO: 순서대로 올리기
DE: Nacheinander posten

[run_result.run_finish_share_flow.body.8]
KO: 다음: $label
DE: Weiter: $label

[run_result.run_finish_share_targets.body]
KO: Instagram 스토리
DE: Instagram Story

[run_result.run_finish_share_targets.body.2]
KO: Instagram 피드
DE: Instagram Feed

[run_result.run_finish_share_targets.body.3]
KO: 더보기
DE: Mehr

[run_tracking.body]
KO: 심박 ${telemetry.currentHeartRate?.toString() ??
DE: Herzfrequenz ${telemetry.currentHeartRate?.toString() ??

[run_tracking.body.2]
KO: } BPM / 케이던스 ${telemetry.currentCadenceSpm?.toString() ??
DE: } BPM / Trittfrequenz ${telemetry.currentCadenceSpm?.toString() ??

[run_tracking.body.3]
KO: 자이로 안정도 ${telemetry.gyroStabilityScore.toStringAsFixed(2)}
DE: Gyroskop-Stabilität ${telemetry.gyroStabilityScore.toStringAsFixed(2)}

[run_tracking.body.4]
KO: 센서를 시작하는 중...
DE: Sensor wird gestartet...

[run_tracking.body.5]
KO: 러닝 검증 중...
DE: Lauf wird überprüft...

[run_tracking.body.6]
KO: 러닝 끝내고 검증하기
DE: Lauf beenden und überprüfen

[run_tracking.body.7]
KO: MyPage에서 [선택] 민감정보 수집 동의 후 러닝 검증을 시작할 수 있습니다.
DE: Sie können die Laufverifizierung starten, nachdem Sie der [Optionalen] Erfassung sensibler Daten in MyPage zugestimmt haben.

[run_tracking.body.8]
KO: 센서를 시작하지 못했어요: $error
DE: Sensoren konnten nicht gestartet werden: $error

[run_tracking.title]
KO: 달리기 기록
DE: Laufaufzeichnung

[run_tracking.toast]
KO: 러닝 검증에 실패했어요: ${ApiErrorMessage.from(error)}
DE: Laufverifizierung fehlgeschlagen: ${ApiErrorMessage.from(error)}

[run_tracking.ble_heart_rate_service.body]
KO: BLE 심박 센서 (${map[
DE: BLE-Herzfrequenzsensor (${map[

[run_tracking.ble_heart_rate_service.body.2]
KO: 이 기기에서는 블루투스 심박 스캔을 지원하지 않습니다.
DE: Bluetooth-Herzfrequenz-Scan wird auf diesem Gerät nicht unterstützt.

[run_tracking.ble_heart_rate_service.body.3]
KO: 블루투스 권한 또는 상태를 확인해 주세요.
DE: Bitte überprüfen Sie die Bluetooth-Berechtigung oder den Status.

[run_tracking.ble_heart_rate_service.body.4]
KO: 이 기기에서는 블루투스 심박 연결을 지원하지 않습니다.
DE: Bluetooth-Herzfrequenz-Verbindung wird auf diesem Gerät nicht unterstützt.

[run_tracking.ble_heart_rate_service.body.5]
KO: 센서 연결에 실패했습니다.
DE: Verbindung zum Sensor fehlgeschlagen.

[run_tracking.gps_tracking_service.body]
KO: 실시간 러닝 GPS 추적 중
DE: Echtzeit-GPS-Lauftracking läuft

[run_tracking.home_start_gate.body]
KO: 마이페이지에서 민감정보 수집에 동의해주세요
DE: Bitte stimmen Sie der Erfassung sensibler Daten in Meine Seite zu.

[run_tracking.home_start_gate.body.2]
KO: 로그인 후 러닝 검증을 진행할 수 있습니다.
DE: Sie können die Laufüberprüfung nach der Anmeldung fortsetzen.

[run_tracking.home_start_gate.body.3]
KO: 러닝이 시작되지 않았습니다.
DE: Der Lauf wurde nicht gestartet.

[run_tracking.music_controls.body]
KO: 음악을 조절하지 못했어요.
DE: Musik konnte nicht gesteuert werden.

[run_tracking.music_controls.body.2]
KO: 재생 / 일시정지
DE: Wiedergabe / Pause

[run_tracking.music_controls.body.3]
KO: 다음 곡
DE: Nächster Titel

[run_tracking.music_controls.body.4]
KO: 음악 앱 열기
DE: Musik-App öffnen

[run_tracking.music_controls.body.5]
KO: 음악 앱을 찾지 못했어요. 쓰는 음악 앱을 직접 열어 주세요.
DE: Keine Musik-App gefunden. Bitte öffnen Sie Ihre Musik-App direkt.

[run_tracking.music_controls.button]
KO: 이전 곡
DE: Vorheriger Titel

[run_tracking.run_recording_checklist.body]
KO: 화면을 끄거나 다른 앱을 켜도 경로 기록과 음성 코칭이 이어지도록 아래 항목을 확인해 주세요.
DE: Bitte überprüfen Sie die folgenden Punkte, damit die Routenaufzeichnung und das Sprachcoaching auch bei ausgeschaltetem Bildschirm oder geöffneter anderer App fortgesetzt werden.

[run_tracking.run_recording_checklist.body.10]
KO: 허용하지 않아도 달리기는 시작할 수 있습니다.
DE: Sie können auch ohne Erlaubnis mit dem Laufen beginnen.

[run_tracking.run_recording_checklist.body.11]
KO: 항목을 나중에 바꿔도 됩니다.
DE: Sie können diese Einstellungen später ändern.

[run_tracking.run_recording_checklist.body.12]
KO: 필요
DE: Erforderlich

[run_tracking.run_recording_checklist.body.2]
KO: 위치 권한
DE: Standortberechtigung

[run_tracking.run_recording_checklist.body.3]
KO: 앱을 사용하는 동안 허용해 주세요. 항상 허용은 요청하지 않습니다.
DE: Bitte erlauben Sie den Zugriff während der App-Nutzung. "Immer zulassen" wird nicht angefordert.

[run_tracking.run_recording_checklist.body.4]
KO: 허용됨
DE: Erlaubt

[run_tracking.run_recording_checklist.body.5]
KO: 허용하기
DE: Erlauben

[run_tracking.run_recording_checklist.body.6]
KO: 알림 권한
DE: Benachrichtigungsberechtigung

[run_tracking.run_recording_checklist.body.7]
KO: 달리기 기록 알림을 표시합니다. Android 13 이상에서 필요합니다.
DE: Zeigt Benachrichtigungen zur Laufaufzeichnung an. Erforderlich ab Android 13.

[run_tracking.run_recording_checklist.body.8]
KO: 배터리 최적화
DE: Akku-Optimierung

[run_tracking.run_recording_checklist.body.9]
KO: 설정됨
DE: Eingerichtet

[run_tracking.run_recording_checklist.button]
KO: 확인하고 달리기
DE: Bestätigen und laufen

[run_tracking.run_recording_checklist.title]
KO: 달리기 기록 설정
DE: Laufaufzeichnungs-Einstellungen

[run_tracking.run_recording_checklist.toast]
KO: 배터리 설정 화면을 열지 못했습니다.
DE: Akkueinstellungen konnten nicht geöffnet werden.

[run_tracking.run_recording_foreground.body]
KO: 화면이 꺼져도 달리기 경로와 음성 코칭을 이어갑니다.
DE: Setzt die Routenaufzeichnung und das Sprachcoaching auch bei ausgeschaltetem Bildschirm fort.

[run_tracking.run_recording_policy.body]
KO: 쉐어런 · 달리기 기록 중
DE: ShareRun · Lauf wird aufgezeichnet

[run_tracking.run_recording_policy.body.2]
KO: 이전 달리기가 중단되었습니다
DE: Der vorherige Lauf wurde unterbrochen

[run_tracking.run_recording_policy.body.3]
KO: 앱이 중간에 종료되어 직전 달리기는 저장되지 않았습니다. 보상은 지급되지 않고, 기록도 남지 않습니다.
DE: Die App wurde unerwartet beendet, daher wurde Ihr vorheriger Lauf nicht gespeichert. Es werden keine Belohnungen vergeben und kein Verlauf gespeichert.

[run_tracking.run_recording_policy.body.4]
KO: 화면이 꺼지면 달리기 기록이 중단될 수 있습니다.
DE: Die Laufaufzeichnung kann unterbrochen werden, wenn sich der Bildschirm ausschaltet.

[run_tracking.run_recording_policy.body.5]
KO: 달리기 기록 설정 점검
DE: Einstellungen für die Laufaufzeichnung prüfen

[run_tracking.run_recording_policy.body.6]
KO: 시스템 배터리 최적화 화면에서 쉐어런을 찾아 주세요. 삼성 갤럭시는 '제한 없음'으로 바꿔 주세요.
DE: Bitte suchen Sie ShareRun in der Akku-Optimierung Ihres Systems. Bei Samsung Galaxy ändern Sie dies bitte auf "Nicht eingeschränkt".

[run_tracking.run_session_service.body]
KO: 위치 서비스가 꺼져 있습니다.
DE: Standortdienste sind deaktiviert.

[run_tracking.run_session_service.body.2]
KO: 위치 권한이 영구 거부되었습니다. 설정에서 허용해 주세요.
DE: Standortberechtigung dauerhaft verweigert. Bitte in den Einstellungen zulassen.

[run_tracking.run_session_service.body.3]
KO: 위치 권한이 허용되었습니다.
DE: Standortberechtigung erteilt.

[run_tracking.run_start_preflight.button]
KO: 심박수·케이던스 검증을 위해 [선택] 건강정보 수집 동의가 필요합니다. 일반 이용약관과 별도로 Opt-in 해 주세요.
DE: Zur Überprüfung von Herzfrequenz und Schrittfrequenz ist die Zustimmung zur [Freiwillig] Erhebung von Gesundheitsdaten erforderlich. Bitte stimmen Sie separat zu den allgemeinen Nutzungsbedingungen zu.

[run_tracking.run_start_preflight.button.2]
KO: 동의 화면으로
DE: Zur Zustimmungsseite

[run_tracking.run_start_preflight.dialog]
KO: 건강정보 동의 필요
DE: Zustimmung zu Gesundheitsdaten erforderlich

[run_tracking.run_start_preflight.toast]
KO: 로그인 후 러닝을 시작할 수 있습니다.
DE: Sie können nach der Anmeldung mit dem Laufen beginnen.

[run_tracking.sponsor_live_buff_banner.body]
KO: 스폰서 라이브 버프
DE: Sponsor-Live-Buff

[run_tracking.watch_runtime_permissions_service.body]
KO: Health Connect 앱 설치
DE: Health Connect-App installieren

[run_tracking.watch_runtime_permissions_service.body.2]
KO: Health Connect 건강 데이터
DE: Health Connect-Gesundheitsdaten

[run_tracking.watch_runtime_permissions_service.body.3]
KO: 신체 활동 인식
DE: Erkennung körperlicher Aktivitäten

[app.runningCrewCreateButton]
KO: [50 DIA 또는 30,000 SHARE로 새 크루 창설하기]
DE: [Neue Crew mit 50 DIA oder 30.000 SHARE gründen]

[app.runningCrewEnterRoom]
KO: 크루 룸 입장하기
DE: Crew-Raum betreten

[app.runningCrewHeadline]
KO: 같이 달릴
크루 찾기
DE: Eine Crew finden,
um gemeinsam zu laufen

[app.runningCrewMyCrewName]
KO: 인천 논현 최강 크루
DE: Incheon Nonhyeon Stärkste Crew

[app.runningCrewMyCrewStats]
KO: 소속 크루원: 45/50명 | 누적 달성 거리: 3,240km
DE: Crew-Mitglieder: 45/50 | Gesamtdistanz: 3.240 km

[app.runningCrewNoCrewHint]
KO: 크루에 들어가면 함께 달린 거리를 모아 월간 순위에 도전할 수 있어요. 크루를 만들거나 아래에서 찾아보세요.
DE: Treten Sie einer Crew bei, um gemeinsame Laufdistanzen zu sammeln und die Monatsrangliste herauszufordern. Erstellen Sie eine Crew oder suchen Sie unten danach.

[app.runningCrewNoCrewName]
KO: 아직 크루가 없어요
DE: Noch keine Crew vorhanden

[app.runningCrewProgressLabel]
KO: 이번 주 크루 대항전 10K 완주율
DE: 10K-Abschlussquote des Crew-Wettbewerbs dieser Woche

[app.runningCrewTitle]
KO: 러닝 크루 (Crew)
DE: Running Crew

[running_crew.body]
KO: 가입 신청
DE: Beitritt anfragen

[running_crew.body.10]
KO: 크루는 두고 나만 나가고 싶다면 먼저 "크루원 보기"에서 크루장을 넘겨 주세요.
DE: Wenn Sie das Crew behalten und nur selbst austreten möchten, übertragen Sie die Anführerschaft zuerst unter „Mitglieder anzeigen“.

[running_crew.body.11]
KO: ${member.nickname}님에게 크루장을 넘길까요? 나는 부크루장이 되고, 원하면 그 뒤에 크루에서 나갈 수 있어요.
DE: Crew-Leitung an ${member.nickname} übertragen? Sie werden Co-Leiter und können die Crew danach auf Wunsch verlassen.

[running_crew.body.12]
KO: 넘기기
DE: Übertragen

[running_crew.body.13]
KO: 크루원
DE: Crew-Mitglied

[running_crew.body.14]
KO: 누적 거리
DE: Gesamtdistanz

[running_crew.body.15]
KO: 크루 관리
DE: Crew-Verwaltung

[running_crew.body.16]
KO: 공지 · 크루원 · 혜택 선물
DE: Mitteilungen · Mitglieder · Vorteilsgeschenke

[running_crew.body.17]
KO: 크루원 보기
DE: Mitglieder anzeigen

[running_crew.body.18]
KO: ${mine.crew.memberCount}명 · 내 역할 ${_roleLabel(mine.role)}
DE: ${mine.crew.memberCount} Mitglieder · Meine Rolle: ${_roleLabel(mine.role)}

[running_crew.body.19]
KO: 가입 신청 ${mine.pendingRequests}건
DE: ${mine.pendingRequests} Beitrittsanfragen

[running_crew.body.2]
KO: 크루 가입
DE: Crew beitreten

[running_crew.body.20]
KO: 받을지 정해요
DE: Entscheiden Sie über die Annahme

[running_crew.body.21]
KO: 처음 한 번은 무료
DE: Beim ersten Mal kostenlos

[running_crew.body.22]
KO: 지금은 승인 가입
DE: Derzeit mit Genehmigung

[running_crew.body.23]
KO: 지금은 자유 가입
DE: Derzeit freier Beitritt

[running_crew.body.24]
KO: 크루원과 함께 모두 나와요
DE: Alle Mitglieder verlassen die Crew gemeinsam

[running_crew.body.25]
KO: 다시 가입할 수 있어요
DE: Sie können später wieder beitreten

[running_crew.body.26]
KO: 엠블럼 바꾸기
DE: Emblem ändern

[running_crew.body.27]
KO: 틀 ${CrewEmblem.frames.length}가지 · 문양 ${CrewEmblem.glyphIds.length}가지 · 색 ${CrewEmblem.paletteColors.length}가지
DE: ${CrewEmblem.frames.length} Rahmen · ${CrewEmblem.glyphIds.length} Symbole · ${CrewEmblem.paletteColors.length} Farben

[running_crew.body.28]
KO: 색 ${CrewEmblem.paletteColors.length}가지
DE: ${CrewEmblem.paletteColors.length} Farben

[running_crew.body.29]
KO: 다른 크루 찾기
DE: Andere Crews suchen

[running_crew.body.3]
KO: "${crew.name}" 크루는 크루장이 승인해야 들어갈 수 있어요. 신청할까요?
DE: Der Beitritt zu „${crew.name}“ erfordert die Genehmigung des Anführers. Anfragen?

[running_crew.body.30]
KO: 검색: "$_searchQuery"
DE: Suche: „$_searchQuery“

[running_crew.body.31]
KO: 검색 결과가 없습니다.
DE: Keine Suchergebnisse gefunden.

[running_crew.body.32]
KO: 보유 SHARE ${_format(wallet.shareBalance)}
DE: Verfügbare SHARE: ${_format(wallet.shareBalance)}

[running_crew.body.33]
KO: 크루장
DE: Crew-Leiter

[running_crew.body.34]
KO: 부크루장
DE: Vize-Leitung

[running_crew.body.35]
KO: 명예의 전당
DE: Ruhmeshalle

[running_crew.body.36]
KO: 역대 최고 ${ranking.bestRank}위
DE: Allzeit-Bestplatzierung: Platz ${ranking.bestRank}

[running_crew.body.37]
KO: 순위는 이번 달 크루 거리 ÷ 크루원 수예요. 달이 끝나면 확정돼요.
DE: Die Platzierung berechnet sich aus Crew-Distanz dieses Monats ÷ Mitgliederzahl. Sie wird am Monatsende festgelegt.

[running_crew.body.38]
KO: 크루 이름 검색
DE: Crew-Namen suchen

[running_crew.body.39]
KO: 50 DIA 또는 30,000 SHARE
DE: 50 DIA oder 30.000 SHARE

[running_crew.body.4]
KO: "${crew.name}" 크루에 가입할까요?
DE: Möchten Sie dem Crew „${crew.name}“ beitreten?

[running_crew.body.40]
KO: 아직 만들어진 크루가 없어요.
DE: Es wurde noch keine Crew erstellt.

[running_crew.body.41]
KO: 가입 불가
DE: Beitritt nicht möglich

[running_crew.body.42]
KO: 가득 참
DE: Voll

[running_crew.body.43]
KO: ${mine.crew.name} · ${mine.members.length}명
DE: ${mine.crew.name} · ${mine.members.length} Mitglieder

[running_crew.body.44]
KO: 부크루장 해제
DE: Vize-Leitung absetzen

[running_crew.body.45]
KO: 부크루장으로
DE: Zur Vize-Leitung ernennen

[running_crew.body.46]
KO: 신고하기
DE: Melden

[running_crew.body.47]
KO: 가입 신청 ${requests.length}건
DE: ${requests.length} Beitrittsanfragen

[running_crew.body.48]
KO: 기다리는 신청이 없어요.
DE: Keine ausstehenden Anfragen vorhanden.

[running_crew.body.49]
KO: "${mine.crew.name}" 크루를 없애요.
크루장인 나도 함께 크루에서 나와요.
산 엠블럼도 사라지고 되돌릴 수 없어요.

$note
DE: Das Crew „${mine.crew.name}“ wird gelöscht.
Ich als Anführer verlasse das Crew ebenfalls.
Das gekaufte Emblem geht ebenfalls verloren und kann nicht wiederhergestellt werden.

$note

[running_crew.body.5]
KO: 신청
DE: Anfragen

[running_crew.body.6]
KO: "$name"(으)로 바꾸면 $cost DIA가 들어요. 보너스 DIA를 먼저 써요.
DE: Die Änderung zu „$name“ kostet $cost DIA. Bonus-DIA wird zuerst verwendet.

[running_crew.body.7]
KO: 크루 없애기
DE: Crew löschen

[running_crew.body.8]
KO: "${mine.crew.name}" 크루를 없애요.
${others > 0 ?
DE: Crew „${mine.crew.name}“ löschen.
${others > 0 ?

[running_crew.body.9]
KO: "${mine.crew.name}" 크루를 없애요.
크루원 $others명도 모두 크루에서 나오고, 크루장인 나도 함께 크루에서 나와요.
산 엠블럼도 사라지고 되돌릴 수 없어요.

$note
DE: Das Crew „${mine.crew.name}“ wird gelöscht.
Alle $others Mitglieder verlassen ebenfalls das Crew, und ich als Anführer verlasse es auch.
Das gekaufte Emblem geht ebenfalls verloren und kann nicht wiederhergestellt werden.

$note

[running_crew.button]
KO: 크루 만들기
DE: Crew erstellen

[running_crew.button.10]
KO: 받기
DE: Annehmen

[running_crew.button.2]
KO: 서버가 50 DIA 또는 30,000 SHARE 중 선택한 금액만 차감합니다.
DE: Der Server zieht nur den ausgewählten Betrag ab: 50 DIA oder 30.000 SHARE.

[running_crew.button.3]
KO: 가입 방식
DE: Beitrittsmethode

[running_crew.button.4]
KO: 자유 가입
누구나 바로 들어와요
DE: Offener Beitritt
Jeder kann sofort beitreten

[running_crew.button.5]
KO: 승인 가입
신청을 받아 크루장이 정해요
DE: Beitritt nach Genehmigung
Der Crew-Anführer entscheidet nach Antrag

[running_crew.button.6]
KO: 검색
DE: Suchen

[running_crew.button.7]
KO: 신고
DE: Melden

[running_crew.button.8]
KO: 신청 취소
DE: Anfrage abbrechen

[running_crew.button.9]
KO: 거절
DE: Ablehnen

[running_crew.dialog]
KO: 크루 이름 바꾸기
DE: Crew-Namen ändern

[running_crew.dialog.2]
KO: 다음
DE: Weiter

[running_crew.hint]
KO: 크루 검색
DE: Crew suchen

[running_crew.hint.2]
KO: 크루 이름 입력
DE: Crew-Namen eingeben

[running_crew.hint.3]
KO: 초기화
DE: Zurücksetzen

[running_crew.hint.4]
KO: 2~20자로 지어 주세요
DE: Bitte 2 bis 20 Zeichen eingeben

[running_crew.label]
KO: ${crew.memberCount}/${crew.maxMembers}명${crew.needsApproval ?
DE: ${crew.memberCount}/${crew.maxMembers} Mitglieder${crew.needsApproval ?

[running_crew.toast]
KO: 로그인한 뒤에 다시 시도해 주세요.
DE: Bitte melden Sie sich an und versuchen Sie es erneut.

[running_crew.toast.10]
KO: 유료 엠블럼은 크루장만 살 수 있어요.
DE: Kostenpflichtige Embleme können nur vom Crew-Anführer gekauft werden.

[running_crew.toast.11]
KO: 이미 크루가 가진 엠블럼이에요.
DE: Das Crew besitzt dieses Emblem bereits.

[running_crew.toast.12]
KO: 엠블럼을 사지 못했어요. 잠시 뒤 다시 해 주세요.
DE: Emblem konnte nicht gekauft werden. Bitte versuchen Sie es gleich nochmal.

[running_crew.toast.13]
KO: 엠블럼은 자주 바꿀 수 없어요. 잠시 뒤에 다시 바꿔 주세요.
DE: Embleme können nicht oft geändert werden. Bitte versuchen Sie es später erneut.

[running_crew.toast.14]
KO: 아직 쓸 수 없는 테두리나 엠블럼이에요.
DE: Dieser Rahmen oder dieses Emblem ist noch nicht verfügbar.

[running_crew.toast.15]
KO: 엠블럼을 바꾸지 못했어요. 잠시 뒤 다시 해 주세요.
DE: Emblem konnte nicht geändert werden. Bitte versuchen Sie es gleich nochmal.

[running_crew.toast.16]
KO: 이 폰에만 저장했어요. 서버에 크루가 생기면 함께 저장돼요.
DE: Nur auf diesem Telefon gespeichert. Wird mitgespeichert, wenn das Crew auf dem Server erstellt wird.

[running_crew.toast.17]
KO: 크루 엠블럼을 바꿨어요.
DE: Crew-Emblem wurde geändert.

[running_crew.toast.18]
KO: 가입
DE: Beitreten

[running_crew.toast.19]
KO: "${crew.name}" 크루에 가입했어요.
DE: Sie sind dem Crew „${crew.name}“ beigetreten.

[running_crew.toast.2]
KO: 새 크루 창설 완료 (−$_createCrewDiaCost DIA)
DE: Neues Crew erstellt (−$_createCrewDiaCost DIA)

[running_crew.toast.20]
KO: 가입을 신청했어요. 승인되면 크루원이 돼요.
DE: Antrag eingereicht. Sie werden Mitglied, sobald er genehmigt wird.

[running_crew.toast.21]
KO: 이미 다른 크루에 있거나 신청해 둔 곳이 있거나 인원이 가득 찼어요.
DE: Sie sind bereits in einem anderen Crew, haben eine offene Anfrage oder das Crew ist voll.

[running_crew.toast.22]
KO: 이 크루에는 들어갈 수 없어요.
DE: Beitritt zu diesem Crew nicht möglich.

[running_crew.toast.23]
KO: 가입하지 못했어요. 잠시 뒤 다시 해 주세요.
DE: Beitritt fehlgeschlagen. Bitte versuchen Sie es gleich nochmal.

[running_crew.toast.24]
KO: 가입 신청을 거뒀어요.
DE: Beitrittsanfrage zurückgezogen.

[running_crew.toast.25]
KO: 거두지 못했어요. 잠시 뒤 다시 해 주세요.
DE: Konnte nicht zurückgezogen werden. Bitte versuchen Sie es gleich nochmal.

[running_crew.toast.26]
KO: 자유 가입으로 바꿨어요.
DE: Zu offenem Beitritt geändert.

[running_crew.toast.27]
KO: 승인 가입으로 바꿨어요.
DE: Zu Beitritt nach Genehmigung geändert.

[running_crew.toast.28]
KO: 크루 이름을 "$name"(으)로 바꿨어요.
DE: Crew-Name wurde in „$name“ geändert.

[running_crew.toast.29]
KO: 신청 목록을 불러오지 못했어요.
DE: Anfragenliste konnte nicht geladen werden.

[running_crew.toast.3]
KO: 새 크루 창설 완료 (−$_createCrewShareCost SHARE)
DE: Neues Crew erstellt (−$_createCrewShareCost SHARE)

[running_crew.toast.30]
KO: ${request.nickname}님을 받았어요.
DE: ${request.nickname} wurde akzeptiert.

[running_crew.toast.31]
KO: ${request.nickname}님의 신청을 거절했어요.
DE: Anfrage von ${request.nickname} wurde abgelehnt.

[running_crew.toast.32]
KO: 이미 다른 크루에 있거나 인원이 가득 찼어요.
DE: Bereits in einem anderen Crew oder das Crew ist voll.

[running_crew.toast.33]
KO: 처리하지 못했어요. 잠시 뒤 다시 해 주세요.
DE: Verarbeitung fehlgeschlagen. Bitte versuchen Sie es gleich nochmal.

[running_crew.toast.34]
KO: 크루를 없앴어요.
DE: Crew wurde gelöscht.

[running_crew.toast.35]
KO: 없애지 못했어요. 잠시 뒤 다시 해 주세요.
DE: Konnte nicht gelöscht werden. Bitte versuchen Sie es gleich nochmal.

[running_crew.toast.36]
KO: 크루 나가기
DE: Crew verlassen

[running_crew.toast.37]
KO: "${mine.crew.name}" 크루에서 나갈까요? 다시 가입할 수 있어요.
DE: Möchten Sie das Crew „${mine.crew.name}“ verlassen? Sie können später wieder beitreten.

[running_crew.toast.38]
KO: 나가기
DE: Verlassen

[running_crew.toast.39]
KO: 크루에서 나왔어요.
DE: Sie haben das Crew verlassen.

[running_crew.toast.4]
KO: 크루 창설 실패: $error
DE: Fehler beim Erstellen des Crews: $error

[running_crew.toast.40]
KO: 크루장은 나갈 수 없어요.
DE: Der Crew-Leiter kann die Crew nicht verlassen.

[running_crew.toast.41]
KO: 나가지 못했어요. 잠시 뒤 다시 해 주세요.
DE: Verlassen fehlgeschlagen. Bitte versuchen Sie es gleich noch einmal.

[running_crew.toast.42]
KO: 지금은 신고할 수 없어요.
DE: Melden ist derzeit nicht möglich.

[running_crew.toast.43]
KO: 신고했어요. 운영자가 확인할게요.
DE: Gemeldet. Ein Administrator wird es prüfen.

[running_crew.toast.44]
KO: 신고하지 못했어요. 잠시 뒤 다시 해 주세요.
DE: Meldung fehlgeschlagen. Bitte versuchen Sie es gleich noch einmal.

[running_crew.toast.45]
KO: 크루장 넘기기
DE: Crew-Leitung übertragen

[running_crew.toast.46]
KO: ${member.nickname}님이 새 크루장이에요.
DE: ${member.nickname} ist die neue Crew-Leitung.

[running_crew.toast.47]
KO: 넘기지 못했어요. 잠시 뒤 다시 해 주세요.
DE: Übertragung fehlgeschlagen. Bitte versuchen Sie es gleich noch einmal.

[running_crew.toast.48]
KO: ${member.nickname}님을 부크루장으로 했어요.
DE: ${member.nickname} wurde zur Vize-Leitung ernannt.

[running_crew.toast.5]
KO: 전체 랭킹을 표시합니다.
DE: Gesamtrangliste wird angezeigt.

[running_crew.toast.6]
KO: "$result" 검색 결과를 표시합니다.
DE: Suchergebnisse für „$result“ werden angezeigt.

[running_crew.toast.7]
KO: 크루에 들어가면 크루 룸을 볼 수 있어요.
DE: Treten Sie dem Crew bei, um den Crew-Raum zu sehen.

[running_crew.toast.8]
KO: 엠블럼은 자주 바꿀 수 없어요. 약 $days일 뒤에 다시 바꿀 수 있어요.
DE: Embleme können nicht oft geändert werden. In etwa $days Tagen erneut möglich.

[running_crew.toast.9]
KO: DIA가 부족해요.
DE: Nicht genügend DIA.

[security_privacy_center.body]
KO: 적립 규칙, 내 거래 내역, 기부 정산, 기록 이의 신청을 한곳에서 확인해요.
DE: Prüfen Sie Belohnungsregeln, Transaktionsverlauf, Spendenabrechnungen und Reklamationen an einem Ort.

[security_privacy_center.body.2]
KO: 서버 원장에 기록된 지급·사용 내역
DE: Im Server-Hauptbuch erfasster Auszahlungs- und Nutzungsverlauf

[security_privacy_center.body.3]
KO: 기부 정산
DE: Spendenabrechnung

[security_privacy_center.body.4]
KO: 내가 기여한 금액 · 이번 달 기부
DE: Mein Beitragsbetrag · Spenden dieses Monats

[security_privacy_center.body.5]
KO: 로그인된 기기
DE: Angemeldete Geräte

[security_privacy_center.body.6]
KO: 내 계정을 연 기기 · 모든 기기에서 로그아웃
DE: Geräte mit meinem Konto · Von allen Geräten abmelden

[security_privacy_center.body.7]
KO: 기록 소명 및 고객센터
DE: Rekord-Verifizierung & Kundenservice

[security_privacy_center.body.8]
KO: 검증 결과에 이의가 있을 때
DE: Wenn Sie Einwände gegen die Verifizierungsergebnisse haben

[share_dia_exchange.body]
KO: 이번 주 남은 한도 ${quote.remainingDia} / ${quote.weeklyCapDia} DIA
DE: Verbleibendes Wochenlimit: ${quote.remainingDia} / ${quote.weeklyCapDia} DIA

[share_dia_exchange.body.2]
KO: ${quote.unitDia} DIA 단위 · 교환 가능 SHARE ${quote.spendableShare}
DE: In Einheiten von ${quote.unitDia} DIA · Umtauschbare SHARE: ${quote.spendableShare}

[share_dia_exchange.body.3]
KO: 추천 보상 잠금 ${quote.lockedShare} SHARE
DE: Gesperrte Empfehlungsbelohnung: ${quote.lockedShare} SHARE

[share_dia_exchange.button]
KO: SHARE → DIA 교환
DE: SHARE → DIA umtauschen

[share_dia_exchange.button.2]
KO: DIA 팩 · 준비 중
DE: DIA-Paket · In Kürze

[share_dia_exchange.button.3]
KO: 교환 중...
DE: Tauschen...

[share_dia_exchange.button.4]
KO: 교환
DE: Umtauschen

[share_dia_exchange.toast]
KO: ${result.rateSharePerDia} SHARE = 1 DIA 교환이 반영되었습니다.
DE: Umtausch von ${result.rateSharePerDia} SHARE = 1 DIA wurde angewendet.

[shop.accessory_shop_grid.body]
KO: 아직 준비 중이에요
DE: Noch in Vorbereitung

[shop.accessory_shop_grid.body.2]
KO: ${accessory.tierLock!.labelKo} 티어
DE: ${accessory.tierLock!.labelKo}-Rang

[shop.accessory_shop_grid.button]
KO: 가격은 바뀔 수 있어요.
DE: Preise können sich ändern.

[shop.accessory_shop_grid.button.2]
KO: 입혀 보기
DE: Anprobieren

[shop.accessory_shop_grid.button.3]
KO: 벗기
DE: Ausziehen

[shop.accessory_shop_grid.button.4]
KO: 입기
DE: Anziehen
