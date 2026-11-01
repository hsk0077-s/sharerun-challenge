# 번역 검수 요청 — 쉐어런 (German) · 파트 2/8

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
[crew.crew_emblem.body.9]
KO: ${n(t[0])}km · ${n(t[1])}km · ${n(t[2])}km  (지금 ${n(now.round())}km)
DE: ${n(t[0])}km · ${n(t[1])}km · ${n(t[2])}km  (aktuell ${n(now.round())}km)

[crew.crew_emblem.button]
KO: }이 엠블럼을 살까요?
크루가 평생 가지며 크루원 누구에게나 보여요. 크루를 없애면 함께 사라져요.
DE: }Dieses Emblem kaufen?
Die Crew behält es dauerhaft und alle Crew-Mitglieder können es sehen. Wird die Crew gelöscht, geht es verloren.

[crew.crew_emblem.button.2]
KO: 이 엠블럼으로 정하기
DE: Dieses Emblem wählen

[crew.crew_emblem.dialog]
KO: 유료 엠블럼 사기
DE: Kostenpflichtiges Emblem kaufen

[crew.crew_ranking.body]
KO: 이번 달 ${rank.rank}위 · 1인 평균 ${rank.averageKm.toStringAsFixed(1)}km
DE: Diesen Monat Platz ${rank.rank} · Durchschn. ${rank.averageKm.toStringAsFixed(1)}km pro Person

[crew.crew_ranking.body.2]
KO: 크루원이 $minMembers명 이상이면 순위에 올라요. (지금 $myMemberCount명)
DE: Wird gerankt, wenn die Crew mindestens $minMembers Mitglieder hat. (Derzeit $myMemberCount)

[crew.crew_ranking.body.3]
KO: 이번 달에 달리면 순위에 올라요.
DE: Laufen Sie diesen Monat, um im Ranking zu erscheinen.

[app.crewManagerAppointVice]
KO: 부방장 임명
DE: Co-Leiter ernennen

[app.crewManagerExpandMembers]
KO: +10명 인원 한도 확장하기 (300 DIA)
DE: Mitgliederlimit um +10 erweitern (300 DIA)

[app.crewManagerForceKick]
KO: 강제 퇴출
DE: Rauswerfen

[app.crewManagerGiftAngelBadge]
KO: 천사 배지를 획득하세요
DE: Verdienen Sie sich das Engel-Abzeichen

[app.crewManagerGiftCpr]
KO: 🎁 심폐소생권/세이프가드 전체 선물 (DIA)
DE: 🎁 HLW / Schutz für alle verschenken (DIA)

[app.crewManagerGiftDeposit]
KO: 🛡️ 크루 대항전 예치금 방장 대납 (DIA/SHARE)
DE: 🛡️ Leiter übernimmt Kaution für crew-Wettkampf (DIA/SHARE)

[app.crewManagerGiftPass]
KO: 🎉 크루 전용 챌린지 패스 & 스킨 구매 (DIA)
DE: 🎉 Exklusiven crew-Challenge-Pass & Skin kaufen (DIA)

[app.crewManagerGiftSection]
KO: 크루원 혜택 하사(선물)
DE: Mitgliedervorteile schenken

[app.crewManagerMember1]
KO: 김나운
DE: Na-woon Kim

[app.crewManagerMember2]
KO: 이승우
DE: Seung-woo Lee

[app.crewManagerMember3]
KO: 최서연
DE: Seo-yeon Choi

[app.crewManagerMemberSection]
KO: 소속 팀원 관리 (50 / 50명)
DE: Mitglieder verwalten (50 / 50)

[app.crewManagerPremiumSection]
KO: 프리미엄 설정
DE: Premium-Einstellungen

[app.crewManagerProfileChange]
KO: 이름 변경
DE: Name ändern

[app.crewManagerProfileLabel]
KO: 크루 프로필
DE: Crew-Profil

[app.crewManagerPushNotice]
KO: 전체 공지 푸시 발송 (무료)
DE: Ankündigungs-Push senden (Kostenlos)

[app.crewManagerSave]
KO: 관리 설정 저장하기
DE: Verwaltungseinstellungen speichern

[app.crewManagerShareWarning]
KO: SHARE 결제 시 주의하세요
DE: Bitte beachten Sie die Hinweise bei Zahlung mit SHARE

[app.crewManagerTitle]
KO: 크루 관리 (방장 전용)
DE: Crew-Verwaltung (Nur Leiter)

[crew_manager.body]
KO: 처음 한 번은 무료예요.
DE: Beim ersten Mal kostenlos.

[crew_manager.body.10]
KO: 보유 DIA ${wallet.diamondBalance} · SHARE ${wallet.shareBalance}
DE: Guthaben: DIA ${wallet.diamondBalance} · SHARE ${wallet.shareBalance}

[crew_manager.body.11]
KO: 부방장: ${subs.join(
DE: Vize-Leitung: ${subs.join(

[crew_manager.body.12]
KO: 📢 전체 공지 푸시 (준비 중)
DE: 📢 Push-Benachrichtigung an alle (in Vorbereitung)

[crew_manager.body.13]
KO: 크루 이름
DE: Crew-Name

[crew_manager.body.14]
KO: 이름 변경 (첫 1회 무료)
DE: Name ändern (erstes Mal kostenlos)

[crew_manager.body.15]
KO: 이름 변경 (${mine.crew.renameCostDia} DIA)
DE: Name ändern (${mine.crew.renameCostDia} DIA)

[crew_manager.body.16]
KO: 보관함 아이템
DE: Inventargegenstände

[crew_manager.body.17]
KO: 🎁 크루원 전체에게 심폐소생권·세이프가드 선물 (1인당 $_giftDiaPerMember DIA)
DE: 🎁 Wiederbelebungs-Ticket & Schutzschild an alle schenken ($_giftDiaPerMember DIA pro Person)

[crew_manager.body.18]
KO: 내가 아닌 크루원의 보관함에 하나씩 들어가요. 한 명에게만 줄 때는 아래 팀원 목록에서 골라요.
DE: Wird an das Inventar aller Crew-Mitglieder außer Ihrem eigenen gesendet. Um es nur einer Person zu schenken, wählen Sie sie aus der Liste unten aus.

[crew_manager.body.19]
KO: 🚩 크루 응원 깃발 (15 DIA, 하루 1회)
DE: 🚩 Crew-Anfeuerungsflagge (15 DIA, einmal täglich)

[crew_manager.body.2]
KO: 이름 바꾸기
DE: Namen ändern

[crew_manager.body.20]
KO: 🛡️ 크루 대항전 예치금 대납 (준비 중)
DE: 🛡️ Kaution für den crew-Wettkampf stellvertretend zahlen (In Kürze)

[crew_manager.body.21]
KO: 🎉 크루 전용 챌린지 패스 & 스킨 (준비 중)
DE: 🎉 Exklusiver crew-Challenge-Pass & Skin (In Kürze)

[crew_manager.body.22]
KO: 소속 팀원 관리 ($count / $limit명)
DE: Mitglieder verwalten ($count / $limit)

[crew_manager.body.23]
KO: 소속 팀원이 없습니다.
DE: Keine Mitglieder vorhanden.

[crew_manager.body.24]
KO: $name (방장)
DE: $name (Leiter)

[crew_manager.body.25]
KO: $name (부방장)
DE: $name (Co-Leiter)

[crew_manager.body.3]
KO: "$next"(으)로 바꾸면 $cost DIA가 들어요. 보너스 DIA를 먼저 써요.
DE: Änderung zu „$next“ kostet $cost DIA. Bonus-DIA werden zuerst verbraucht.

[crew_manager.body.4]
KO: $cost DIA 내고 바꾸기
DE: Für $cost DIA ändern

[crew_manager.body.5]
KO: $cost DIA 내고 보내기
DE: Für $cost DIA senden

[crew_manager.body.6]
KO: +${step.add}명 인원 한도 확장하기 (${step.costDia} DIA)
DE: Mitgliederlimit um +${step.add} erweitern (${step.costDia} DIA)

[crew_manager.body.7]
KO: $base · ${crew.maxMembers}명을 모두 채우면 열려요
DE: $base · Wird freigeschaltet, wenn alle ${crew.maxMembers} Plätze belegt sind

[crew_manager.body.8]
KO: 크루 정보를 불러오지 못했어요. 크루에 들어 있는지, 네트워크가 연결됐는지 확인해 주세요.
DE: Crew-Informationen konnten nicht geladen werden. Bitte prüfen Sie, ob Sie einer Crew angehören und die Netzwerkverbindung besteht.

[crew_manager.body.9]
KO: 크루장과 부크루장만 관리할 수 있어요.
DE: Nur die Crew-Leitung und Vize-Leitung können dies verwalten.

[crew_manager.button]
KO: 이름을 바꿀 때마다 $cost DIA가 들어요.
DE: Kostet $cost DIA pro Änderung

[crew_manager.button.2]
KO: 저장
DE: Speichern

[crew_manager.button.3]
KO: 선물
DE: Schenken

[crew_manager.button.4]
KO: 부방장 해제
DE: Co-Leiter abberufen

[crew_manager.dialog]
KO: 크루 이름 변경
DE: crew-Namen ändern

[crew_manager.toast]
KO: 아직 열리지 않았어요. 준비되면 알려드릴게요.
DE: Noch nicht verfügbar. Wir benachrichtigen Sie, sobald es bereit ist.

[crew_manager.toast.10]
KO: ${step.costDia} DIA 내고 늘리기
DE: Für ${step.costDia} DIA erweitern

[crew_manager.toast.11]
KO: 인원 한도가 ${result.maxMembers}명이 됐어요.
DE: Mitgliederlimit beträgt nun ${result.maxMembers}.

[crew_manager.toast.12]
KO: 크루장만 늘릴 수 있어요.
DE: Nur der crew-Leiter kann erweitern.

[crew_manager.toast.13]
KO: 자리를 모두 채워야 하거나 이미 최대예요.
DE: Alle Plätze müssen voll sein oder Limit ist erreicht.

[crew_manager.toast.14]
KO: 인원 한도를 늘리지 못했어요. 잠시 뒤 다시 해 주세요.
DE: Mitgliederlimit konnte nicht erweitert werden. Bitte später erneut versuchen.

[crew_manager.toast.15]
KO: 크루 응원 깃발을 걸었습니다. 오늘 대회 SHARE 보상이 10% 늘어납니다.
DE: crew-Anfeuerungsbanner aufgehängt. Heutige Wettbewerbs-SHARE-Belohnungen +10 %.

[crew_manager.toast.16]
KO: 응원 깃발을 걸지 못했습니다.
DE: Anfeuerungsbanner konnte nicht aufgehängt werden.

[crew_manager.toast.17]
KO: 선물을 받을 크루원이 없어요.
DE: Keine crew-Mitglieder zum Beschenken vorhanden.

[crew_manager.toast.18]
KO: 크루원 $count명 모두
DE: Alle $count crew-Mitglieder

[crew_manager.toast.19]
KO: ${member.nickname}님
DE: ${member.nickname}

[crew_manager.toast.2]
KO: 크루 이름을 "$next"(으)로 바꿨어요.
DE: crew-Name in „$next“ geändert.

[crew_manager.toast.20]
KO: 심폐소생권·세이프가드 선물
DE: Wiederbelebung & Schutzschild schenken

[crew_manager.toast.21]
KO: $who에게 심폐소생권과 세이프가드를 하나씩 보내요. 한 명당 $_giftDiaPerMember DIA, 모두 $cost DIA가 들고 보너스 DIA를 먼저 써요.
DE: Senden Sie 1 Wiederbelebung & 1 Schutzschild an $who. Kostet $_giftDiaPerMember DIA p.P., gesamt $cost DIA (Bonus-DIA zuerst).

[crew_manager.toast.22]
KO: ${result.recipients}명의 보관함에 선물을 넣었어요. (−$cost DIA)
DE: Geschenk an das Inventar von ${result.recipients} Mitgliedern gesendet. (−$cost DIA)

[crew_manager.toast.23]
KO: 크루장만 선물할 수 있어요.
DE: Nur die Crew-Leitung kann Geschenke senden.

[crew_manager.toast.24]
KO: 그 크루원을 찾지 못했어요.
DE: Dieses Crew-Mitglied wurde nicht gefunden.

[crew_manager.toast.25]
KO: 선물을 보내지 못했어요. 잠시 뒤 다시 해 주세요.
DE: Geschenk konnte nicht gesendet werden. Bitte versuchen Sie es gleich noch einmal.

[crew_manager.toast.26]
KO: ${member.nickname}님을 부방장으로 임명했어요.
DE: ${member.nickname} wurde zur Vize-Leitung ernannt.

[crew_manager.toast.27]
KO: ${member.nickname}님을 크루원으로 돌렸어요.
DE: ${member.nickname} wurde wieder zum Crew-Mitglied.

[crew_manager.toast.28]
KO: 바꾸지 못했어요. 잠시 뒤 다시 해 주세요.
DE: Änderung fehlgeschlagen. Bitte versuchen Sie es gleich noch einmal.

[crew_manager.toast.29]
KO: 크루원 내보내기
DE: Crew-Mitglied entfernen

[crew_manager.toast.3]
KO: DIA가 모자라거나 쓸 수 없는 이름이에요.
DE: Nicht genug DIA oder ungültiger Name.

[crew_manager.toast.30]
KO: ${member.nickname}님을 크루에서 내보낼까요?
DE: ${member.nickname} aus der Crew entfernen?

[crew_manager.toast.31]
KO: 내보내기
DE: Entfernen

[crew_manager.toast.32]
KO: ${member.nickname}님을 내보냈어요.
DE: ${member.nickname} wurde entfernt.

[crew_manager.toast.33]
KO: 내보내지 못했어요. 잠시 뒤 다시 해 주세요.
DE: Entfernen fehlgeschlagen. Bitte versuchen Sie es gleich noch einmal.

[crew_manager.toast.34]
KO: 인원 한도 최대 (${crew.maxMembers}명)
DE: Maximale Mitgliederzahl erreicht (${crew.maxMembers})

[crew_manager.toast.4]
KO: 크루장만 이름을 바꿀 수 있어요.
DE: Nur der crew-Leiter kann den Namen ändern.

[crew_manager.toast.5]
KO: 이름을 바꾸지 못했어요. 잠시 뒤 다시 해 주세요.
DE: Namen konnte nicht geändert werden. Bitte versuchen Sie es später erneut.

[crew_manager.toast.6]
KO: 인원 한도가 최대(${mine.crew.maxMembers}명)예요.
DE: Mitgliederlimit ist erreicht (${mine.crew.maxMembers} Mitglieder).

[crew_manager.toast.7]
KO: 자리를 모두 채우면 더 늘릴 수 있어요. (${mine.crew.maxMembers}명)
DE: Füllen Sie alle Plätze, um zu erweitern. (${mine.crew.maxMembers} Mitglieder)

[crew_manager.toast.8]
KO: 인원 한도 확장
DE: Mitgliederlimit erweitern

[crew_manager.toast.9]
KO: 크루 인원 한도를 ${step.add}명 늘려요. ${step.costDia} DIA가 들고, 보너스 DIA를 먼저 써요.
DE: crew-Limit um ${step.add} erhöhen. Kostet ${step.costDia} DIA; Bonus-DIA werden zuerst genutzt.

[crew_ranking_model.body]
KO: 쉐어런 크루
DE: ShareRun-Crew

[crew_room.body]
KO: 크루에 들어 있어야 크루 룸을 볼 수 있어요. 크루에 들어갔는지, 네트워크가 연결됐는지 확인해 주세요.
DE: Sie müssen einer Crew angehören, um den Crew-Raum zu sehen. Bitte prüfen Sie, ob Sie einer Crew beigetreten sind und eine Netzwerkverbindung besteht.

[crew_room.body.2]
KO: } · 내 역할 ${CrewRoomScreen._roleLabel(mine.role)}
DE: } · Meine Rolle: ${CrewRoomScreen._roleLabel(mine.role)}

[crew_room.body.3]
KO: 크루 대항전은 아직 열리지 않았어요. 열리면 여기서 이번 주 진행을 볼 수 있어요.
DE: Crew-Wettkämpfe haben noch nicht begonnen. Sobald sie starten, können Sie hier den Fortschritt dieser Woche sehen.

[crew_room.button]
KO: 크루 룸
DE: Crew-Raum

[device_connection.body]
KO: (Apple Watch 전 기종 지원)
DE: (Unterstützt alle Apple Watch-Modelle)

[device_connection.body.2]
KO: Health Connect 설치 화면을 열었어요. 설치 후 다시 연결해 주세요.
DE: Installationsbildschirm für Health Connect wurde geöffnet. Bitte nach der Installation erneut verbinden.

[device_connection.body.3]
KO: ♥ 연결됨
DE: ♥ Verbunden

[device_connection.body.4]
KO: 미연결
DE: Nicht verbunden

[device_connection.body.5]
KO: 연결된 센서: ${snap.deviceName}
DE: Verbundener Sensor: ${snap.deviceName}

[device_connection.button]
KO: 워치 앱 연결 코드 · 연결된 워치
DE: Uhr-Verbindungscode · Verbundene Uhr

[device_connection.button.2]
KO: 권한 설정 필요
DE: Rechte einrichten

[device_connection.button.3]
KO: 정확한 측정을 위해 권한 설정이 필요합니다.
DE: Für genaue Messungen sind Berechtigungseinstellungen erforderlich.

[device_connection.dialog]
KO: 연동 불가
DE: Verknüpfung nicht möglich

[device_connection.dialog.2]
KO: 고객님의 스마트워치 OS 버전이 낮거나 호환되지 않아 연동할 수 없습니다. 워치를 최신 버전(watchOS 8+, Wear OS 3.0+)으로 업데이트해 주세요.
DE: Die OS-Version Ihrer Smartwatch ist zu alt oder nicht kompatibel. Bitte aktualisieren Sie Ihre Uhr auf die neueste Version (watchOS 8+, Wear OS 3.0+).

[device_connection.toast]
KO: 등급 배정 화면 이동 실패: $e
DE: Fehler beim Wechseln zum Rang-Zuweisungsbildschirm: $e

[device_connection.toast.2]
KO: 건너뛰기 실패: $e
DE: Überspringen fehlgeschlagen: $e

[device_connection.toast.3]
KO: ${watchType.displayLabel} 연동이 완료되었습니다!
DE: ${watchType.displayLabel}-Verknüpfung abgeschlossen!

[device_connection.toast.4]
KO: Health Connect를 열 수 없어요. Play 스토어에서 설치해 주세요.
DE: Health Connect kann nicht geöffnet werden. Bitte aus dem Play Store installieren.

[device_connection.toast.5]
KO: 권한이 거부되었습니다.
DE: Berechtigung verweigert.

[device_connection.toast.6]
KO: Google Health Connect 연동이 완료되었습니다!
DE: Google Health Connect-Verknüpfung abgeschlossen!

[device_connection.toast.7]
KO: 기기가 호환되지 않거나 연동 중 오류가 발생했습니다.
DE: Gerät ist nicht kompatibel oder bei der Verknüpfung ist ein Fehler aufgetreten.

[device_connection.toast.8]
KO: Garmin 연동 화면을 열 수 없습니다: $e
DE: Garmin-Verknüpfungsbildschirm kann nicht geöffnet werden: $e

[device_connection.toast.9]
KO: ${watchType.displayLabel} 연동 설정이 저장되었습니다.
DE: ${watchType.displayLabel}-Verknüpfungseinstellungen gespeichert.

[app.bleHrConnectButton]
KO: 연결
DE: Verbinden

[app.bleHrDisconnectButton]
KO: 연결 해제
DE: Trennen

[app.bleHrGuideItems]
KO: 가민(Garmin)
DE: Garmin

[app.bleHrGuideItems.2]
KO: 시계 설정 → 센서 및 액세서리 → 손목 심박수 → "심박수 전송" 켜기
DE: Uhreneinstellungen → Sensoren und Zubehör → Herzfrequenz am Handgelenk → „Herzfrequenz senden“ einschalten

[app.bleHrGuideItems.3]
KO: 샤오미 · 어메이즈핏
DE: Xiaomi · Amazfit

[app.bleHrGuideItems.4]
KO: 운동·심박수 설정 → "심박수 공유/전송" 켜기
DE: Trainings- und Herzfrequenzeinstellungen → „Herzfrequenz teilen/senden“ einschalten

[app.bleHrGuideItems.5]
KO: 가슴·암밴드 센서
DE: Brust- und Armbandsensoren

[app.bleHrGuideItems.6]
KO: 착용한 뒤 아래 [센서 찾기] 누르기 (Polar, Wahoo, Coospo, Magene)
DE: Anlegen und unten auf [Sensor suchen] tippen (Polar, Wahoo, Coospo, Magene)

[app.bleHrGuideItems.7]
KO: 갤럭시 워치 · 애플워치
DE: Galaxy Watch · Apple Watch

[app.bleHrGuideItems.8]
KO: 이 방식이 아니에요. 위의 Health Connect / Apple 건강으로 연결하세요
DE: Nicht auf diese Weise. Bitte verbinden Sie sich oben über Health Connect / Apple Health

[app.bleHrGuideTitle]
KO: 내 기기별로 이렇게 하세요
DE: Anleitung für Ihr Gerät

[app.bleHrScanningLabel]
KO: 근처 심박 센서 찾는 중...
DE: Suche nach Herzfrequenzsensoren in der Nähe...

[app.bleHrSectionSubtitle]
KO: Health Connect 지연 없이 달리는 동안 실시간 심박수(0x180D)를 바로 받습니다.
DE: Erfasst die Echtzeit-Herzfrequenz (0x180D) beim Laufen direkt ohne Health Connect-Verzögerung.

[app.bleHrStopScanButton]
KO: 스캔 중지
DE: Scan stoppen

[app.deviceConnectionConnect]
KO: 기기 연결
DE: Gerät verbinden

[app.deviceConnectionExternalTitle]
KO: 외부 전문 기기 연동
DE: Verknüpfung externer Spezialgeräte

[app.deviceConnectionGoogleCaption]
KO: (갤럭시 워치, 샤오미 미밴드, 어메이즈핏, 가민, 핏빗 등)
DE: (Galaxy Watch, Xiaomi Mi Band, Amazfit, Garmin, Fitbit usw.)

[app.deviceConnectionNativeTitle]
KO: 네이티브 헬스 연동
DE: Native Health-Verknüpfung

[app.deviceConnectionNone]
KO: 연결된 기기가 없습니다
DE: Keine Geräte verbunden

[app.deviceConnectionSingleActiveNote]
KO: 쉐어런은 동시에 하나의 운동 기기만 활성 연결 상태로 유지합니다.
DE: ShareRun hält jeweils nur ein Trainingsgerät gleichzeitig im aktiven Verbindungsstatus.

[app.deviceConnectionStatusTitle]
KO: 현재 연결된 기기
DE: Aktuell verbundenes Gerät

[app.healthConnectNoSamplesTip]
KO: 권한은 연결되었어요. 밴드/워치 앱 안에서 Health Connect 데이터 쓰기 스위치가 켜져 있는지 확인해 주세요. 스마트밴드 기록은 밴드 앱 동기화 후 반영됩니다.
DE: Berechtigungen sind verknüpft. Bitte prüfen Sie, ob der Schalter zum Schreiben von Health Connect-Daten in Ihrer Band-/Watch-App aktiviert ist. Smartband-Aufzeichnungen werden nach der Synchronisierung mit der Band-App übernommen.

[dia_pack_store.body]
KO: $price원 · ${pack.bonusLabel}
DE: $price Won · ${pack.bonusLabel}

[dia_pack_store.body.2]
KO: 기본 ${pack.baseDia} DIA · ${pack.productId}
DE: Basis ${pack.baseDia} DIA · ${pack.productId}

[dia_pack_store.title]
KO: DIA 팩
DE: DIA-Paket

[diamond_box_model.body]
KO: 다이아 상자
DE: DIA-Box

[donation_settlement.body]
KO: 운영자가 자기 돈으로 검증 1km당 100원(KRW)을 월 예산 안에서 기부할 예정입니다. 이용자의 기부금이 아니며 세금 공제 영수증이 발급되지 않습니다.
DE: Der Betreiber plant, pro verifiziertem 1 km 100 KRW aus eigenem Geld im Rahmen des monatlichen Budgets zu spenden. Dies ist keine Spende der Nutzer, und es werden keine steuerlich absetzbaren Quittungen ausgestellt.

[economy_constants.body]
KO: 구매 후 7일 이내, 100% 미사용 분에 한해 환불 가능
DE: Rückerstattung innerhalb von 7 Tagen nach dem Kauf nur bei 100 % ungenutztem Zustand möglich

[email_verification_guard.button]
KO: 결제·대회 참가 전에 이메일 인증을 완료해 주세요. 상단 배너에서 인증 메일을 재발송할 수 있습니다.
DE: Bitte schließen Sie die E-Mail-Bestätigung vor Zahlungen oder Wettbewerbsteilnahmen ab. Sie können die Bestätigungsmail über das obere Banner erneut senden.

[email_verification_guard.dialog]
KO: 이메일 인증 필요
DE: E-Mail-Bestätigung erforderlich

[external_oauth_webview.body]
KO: 이메일 아이디를 입력해 주세요.
DE: Bitte geben Sie Ihre E-Mail-Adresse ein.

[external_oauth_webview.body.2]
KO: 올바른 이메일 형식이 아닙니다.
DE: Ungültiges E-Mail-Format.

[external_oauth_webview.body.3]
KO: 비밀번호를 입력해 주세요.
DE: Bitte geben Sie Ihr Passwort ein.

[external_oauth_webview.body.4]
KO: 비밀번호가 너무 짧습니다.
DE: Passwort ist zu kurz.

[external_oauth_webview.toast]
KO: 연동 중 오류가 발생했습니다. 앱으로 돌아가 다시 시도해 주세요.
DE: Bei der Verknüpfung ist ein Fehler aufgetreten. Bitte kehren Sie zur App zurück und versuchen Sie es erneut.

[app.externalPaymentNoticeHighlight]
KO: 실제 야외 물리적 활동(오프라인 러닝)
DE: tatsächlichen körperlichen Aktivitäten im Freien (Offline-Running)

[app.externalPaymentNoticePrefix]
KO: 본 결제는
DE: Diese Zahlung dient dem Erwerb eines Tickets zur Teilnahme an

[app.externalPaymentNoticeSuffix]
KO: 참여를 위한 참가권 구매입니다.
DE: .

[app.externalPaymentRefundNote]
KO: * 미사용 쿠폰에 한해 언제든 100% 수수료 없이 환불 가능합니다.
DE: * Nur für unbenutzte Gutscheine, jederzeit 100 % gebührenfrei erstattbar.

[app.externalPaymentSecurePaySuffix]
KO: 원 안전 결제하기
DE: KRW sicher zahlen

[firebase_auth_messages.body]
KO: 로그인이 취소되었습니다.
DE: Anmeldung wurde abgebrochen.

[firebase_auth_messages.body.10]
KO: 다른 로그인 방식으로 가입된 이메일입니다.
DE: Diese E-Mail ist mit einer anderen Anmeldemethode registriert.

[firebase_auth_messages.body.11]
KO: 보안을 위해 다시 로그인한 뒤 계정 삭제를 시도해 주세요.
DE: Aus Sicherheitsgründen melden Sie sich bitte erneut an, bevor Sie versuchen, das Konto zu löschen.

[firebase_auth_messages.body.12]
KO: 로그인에 실패했습니다.
DE: Anmeldung fehlgeschlagen.

[firebase_auth_messages.body.2]
KO: 이메일 형식이 올바르지 않습니다.
DE: Ungültiges E-Mail-Format.

[firebase_auth_messages.body.3]
KO: 비활성화된 계정입니다. 고객센터에 문의해 주세요.
DE: Dieses Konto wurde deaktiviert. Bitte wenden Sie sich an den Kundenservice.

[firebase_auth_messages.body.4]
KO: 이메일 또는 비밀번호를 확인해 주세요.
DE: Bitte überprüfen Sie Ihre E-Mail-Adresse oder Ihr Passwort.

[firebase_auth_messages.body.5]
KO: 이미 사용 중인 이메일입니다.
DE: Diese E-Mail-Adresse wird bereits verwendet.

[firebase_auth_messages.body.6]
KO: 비밀번호는 6자 이상이어야 합니다.
DE: Das Passwort muss mindestens 6 Zeichen lang sein.

[firebase_auth_messages.body.7]
KO: 요청이 너무 많습니다. 잠시 후 다시 시도해 주세요.
DE: Zu viele Anfragen. Bitte versuchen Sie es später erneut.

[firebase_auth_messages.body.8]
KO: 네트워크 연결을 확인해 주세요.
DE: Bitte überprüfen Sie Ihre Netzwerkverbindung.

[firebase_auth_messages.body.9]
KO: Firebase 콘솔에서 익명(게스트) 로그인을 활성화해 주세요.
DE: Bitte aktivieren Sie die anonyme (Gast-)Anmeldung in der Firebase-Konsole.

[app.garminAuthSubtitle]
KO: 안전한 OAuth 2.0 공식 로그인 페이지입니다.
DE: Dies ist eine sichere, offizielle OAuth 2.0-Anmeldeseite.

[app.garminAuthTitle]
KO: Garmin Connect 연동
DE: Garmin Connect-Verknüpfung

[app.garminCancelAndReturn]
KO: 연동을 취소하고 앱으로 돌아가기
DE: Verknüpfung abbrechen und zur App zurückkehren

[app.garminEmailHint]
KO: 이메일 아이디
DE: E-Mail-Adresse

[app.garminPasswordHint]
KO: 비밀번호
DE: Passwort

[app.garminSignInAuthorize]
KO: 로그인하고 권한 허용
DE: Anmelden und autorisieren

[app.garminSignInAuthorizeKo]
KO: (로그인 및 권한 허용)
DE: (Anmelden und autorisieren)

[app.hallOfFameDonateCta]
KO: 나도 기부하고 명예의 전당 오르기 💎
DE: Spenden und in die Ruhmeshalle aufsteigen 💎

[app.hallOfFameDonateHistoryTitle]
KO: 명예의 전당 기부 완료 🕊️
DE: Spende für die Ruhmeshalle abgeschlossen 🕊️

[app.hallOfFameLeaderDonation]
KO: 누적 기부: 5,000,000 VALUE
DE: Gespendet gesamt: 5.000.000 VALUE

[app.hallOfFameLeaderName]
KO: 서울 나이트 러너스 방장님
DE: Leiter der Seoul Night Runners

[app.hallOfFameLeaderTitle]
KO: 👑 이달의 소셜 임팩트 리더
DE: 👑 Social-Impact-Leader des Monats

[app.hallOfFameRank2Badge]
KO: 🔥 불꽃 SBT 뱃지
DE: 🔥 Flammen-SBT-Abzeichen

[app.hallOfFameRank2Label]
KO: 2등
DE: 2. Platz

[app.hallOfFameRank2Subtitle]
KO: 연속 50일 완주자
DE: 50 Tage in Folge absolviert

[app.hallOfFameRank3Badge]
KO: 🛡️ 방패 SBT 뱃지
DE: 🛡️ Schild-SBT-Abzeichen

[app.hallOfFameRank3Label]
KO: 3등
DE: 3. Platz

[app.hallOfFameRank3Subtitle]
KO: 최다 크루원 후원자
DE: Größter Crew-Unterstützer

[app.hallOfFameTitle]
KO: 명예의 전당 (Hall of Fame)
DE: Ruhmeshalle (Hall of Fame)

[app.runningCrewHallOfFame]
KO: 👑 명예의 전당
DE: 👑 Ruhmeshalle

[app.storeDonateHistoryTitle]
KO: 기부 펀딩 참여 🕊️
DE: An Spenden-Funding teilgenommen 🕊️

[hall_of_fame.body]
KO: 서버 원장에서 $_donateValue VALUE를 기부했습니다.
DE: Im Server-Ledger wurden $_donateValue VALUE gespendet.

[hall_of_fame.body.2]
KO: 서버 원장에서 $_donateValue VALUE를 기부했습니다. 잔액 $left
DE: Im Server-Ledger wurden $_donateValue VALUE gespendet. Guthaben: $left

[hall_of_fame.body.3]
KO: VALUE가 부족합니다.
DE: Nicht genügend VALUE.

[hall_of_fame.body.4]
KO: 기부에 실패했습니다.
DE: Spende fehlgeschlagen.

[hall_of_fame.body.5]
KO: 아직 기록이 없어요
DE: Noch keine Einträge

[health_data_consent.body]
KO: 개인정보보호법에 따라 건강·생체 데이터는 일반 약관과 분리된 명시적 Opt-in이 필요합니다.
DE: Gemäß Datenschutzgesetzen erfordern Gesundheits- und Biometriedaten eine ausdrückliche Einwilligung, getrennt von den allgemeinen AGB.

[health_data_consent.button]
KO: 권한 요청 중...
DE: Berechtigungen anfragen...

[health_data_consent.button.2]
KO: 동의하고 워치 연동 계속
DE: Zustimmen & Uhr verknüpfen

[health_data_consent.button.3]
KO: 나중에 하기
DE: Später

[health_data_consent.title]
KO: 건강정보 동의
DE: Einwilligung zu Gesundheitsdaten

[health_data_consent.title.2]
KO: 스마트워치 연동 전 동의
DE: Einwilligung vor Smartwatch-Verknüpfung

[home.home_wallet.body]
KO: $completedCount/$total회 완료 >
DE: $completedCount/$total abgeschlossen >

[iap.coach_plus_product.body]
KO: 6,900원
DE: 6,900 Won

[iap.coach_plus_product.body.2]
KO: 59,000원
DE: 59,000 Won

[iap.coach_plus_upsell.body]
KO: 무료
DE: Kostenlos

[iap.coach_plus_upsell.body.2]
KO: 기본 러닝 안내
DE: Grundlegende Laufanleitung

[iap.coach_plus_upsell.body.3]
KO: Coach+ 이용 중
DE: Coach+ aktiv

[iap.coach_plus_upsell.button]
KO: 구매 복원
DE: Käufe wiederherstellen

[iap.dia_pack_product.body]
KO: 보너스 없음
DE: Kein Bonus

[iap.dia_pack_product.body.2]
KO: 보너스 $bonusDia DIA
DE: Bonus: $bonusDia DIA

[iap.iap_providers.body]
KO: SHARE 충전 💳
DE: SHARE aufladen 💳

[iap.iap_purchase_controller.body]
KO: Google Play 결제 서비스를 사용할 수 없습니다. 잠시 후 다시 시도해 주세요.
DE: Der Google Play-Abrechnungsdienst ist nicht verfügbar. Bitte versuchen Sie es später erneut.

[iap.iap_purchase_controller.body.10]
KO: 결제 처리 중 오류가 발생했습니다.
DE: Bei der Zahlungsabwicklung ist ein Fehler aufgetreten.

[iap.iap_purchase_controller.body.11]
KO: Coach+ 결제가 진행 중입니다.
DE: Coach+-Zahlung wird verarbeitet.

[iap.iap_purchase_controller.body.12]
KO: Coach+ 구독이 활성화되었습니다.
DE: Coach+-Abonnement wurde aktiviert.

[iap.iap_purchase_controller.body.13]
KO: Coach+ 결제가 실패했습니다.
DE: Coach+-Zahlung fehlgeschlagen.

[iap.iap_purchase_controller.body.14]
KO: Coach+ 결제가 취소되었습니다.
DE: Coach+-Zahlung wurde abgebrochen.

[iap.iap_purchase_controller.body.15]
KO: 로그인 후 Google Play 결제를 진행해 주세요.
DE: Bitte melden Sie sich an, bevor Sie mit der Google Play-Zahlung fortfahren.

[iap.iap_purchase_controller.body.16]
KO: 영수증을 보안 검증 중입니다. SHARE는 검증 완료 후 지급됩니다.
DE: Ihr Beleg wird einer Sicherheitsprüfung unterzogen. SHARE werden nach Abschluss der Überprüfung gutgeschrieben.

[iap.iap_purchase_controller.body.17]
KO: 검증이 완료되어 $shareAmount SHARE가 지급되었습니다.
DE: Überprüfung abgeschlossen. $shareAmount SHARE wurden gutgeschrieben.

[iap.iap_purchase_controller.body.18]
KO: Google 검증이 완료되어 SHARE가 지갑에 반영됩니다.
DE: Die Google-Überprüfung ist abgeschlossen und SHARE wird in Ihrer Wallet aktualisiert.

[iap.iap_purchase_controller.body.19]
KO: 영수증 검증이 거절되었습니다. 고객센터로 문의해 주세요.
DE: Belegprüfung wurde abgelehnt. Bitte wenden Sie sich an den Kundenservice.

[iap.iap_purchase_controller.body.2]
KO: 상품(${plan.productId})을 찾지 못했습니다. Play Console / App Store Connect 등록을 확인해 주세요.
DE: Produkt (${plan.productId}) wurde nicht gefunden. Bitte überprüfen Sie die Registrierung in der Play Console / im App Store Connect.

[iap.iap_purchase_controller.body.20]
KO: 검증 응답이 지연되고 있습니다. 지갑 잔액을 잠시 후 다시 확인해 주세요.
DE: Die Antwort auf die Überprüfung verzögert sich. Bitte überprüfen Sie Ihr Wallet-Guthaben in Kürze erneut.

[iap.iap_purchase_controller.body.21]
KO: 결제 스트림이 일시 중단되었습니다. 연결을 확인한 뒤 다시 시도해 주세요.
DE: Der Zahlungsstream wurde unterbrochen. Bitte überprüfen Sie Ihre Verbindung und versuchen Sie es erneut.

[iap.iap_purchase_controller.body.3]
KO: 결제 창을 열 수 없습니다.
DE: Das Zahlungsfenster konnte nicht geöffnet werden.

[iap.iap_purchase_controller.body.4]
KO: 결제를 시작하지 못했습니다. 네트워크 상태를 확인해 주세요.
DE: Zahlung konnte nicht gestartet werden. Bitte überprüfen Sie Ihre Netzwerkverbindung.

[iap.iap_purchase_controller.body.5]
KO: 구매 복원에 실패했습니다. 잠시 후 다시 시도해 주세요.
DE: Käufe konnten nicht wiederhergestellt werden. Bitte versuchen Sie es später erneut.

[iap.iap_purchase_controller.body.6]
KO: 상품(${product.productId})을 찾지 못했습니다. Play Console 등록을 확인해 주세요.
DE: Produkt (${product.productId}) wurde nicht gefunden. Bitte überprüfen Sie die Registrierung in der Play Console.

[iap.iap_purchase_controller.body.7]
KO: 결제가 진행 중입니다. Google Play 승인을 기다려 주세요.
DE: Zahlung wird verarbeitet. Bitte warten Sie auf die Genehmigung von Google Play.

[iap.iap_purchase_controller.body.8]
KO: 결제가 실패했습니다.
DE: Zahlung fehlgeschlagen.

[iap.iap_purchase_controller.body.9]
KO: 결제가 취소되었습니다.
DE: Zahlung wurde abgebrochen.

[iap.payment_auth.body]
KO: 본인 확인이 취소됐어요. 결제는 진행되지 않았어요.
DE: Die Identitätsprüfung wurde abgebrochen. Die Zahlung wurde nicht durchgeführt.

[iap.payment_auth.body.2]
KO: 확인을 여러 번 틀려 잠시 막혔어요. 잠시 뒤 다시 하거나 화면 잠금(PIN, 패턴)으로 확인해 주세요. 결제는 진행되지 않았어요.
DE: Zu viele Fehlversuche, vorübergehend gesperrt. Bitte versuchen Sie es gleich noch einmal oder bestätigen Sie mit Ihrer Bildschirmsperre (PIN, Muster). Die Zahlung wurde nicht durchgeführt.

[iap.payment_auth.body.3]
KO: 결제 전 본인 확인을 하려면 폰에 화면 잠금(지문, PIN, 패턴)이 필요해요. 기기 설정에서 화면 잠금을 켠 뒤 다시 시도해 주세요.
DE: Um Ihre Identität vor der Zahlung zu bestätigen, ist eine Bildschirmsperre (Fingerabdruck, PIN, Muster) auf Ihrem Smartphone erforderlich. Bitte aktivieren Sie die Bildschirmsperre in den Geräteeinstellungen und versuchen Sie es erneut.

[iap.payment_auth.body.4]
KO: 본인 확인을 할 수 없어요. 잠시 뒤 다시 시도해 주세요. 결제는 진행되지 않았어요.
DE: Identitätsprüfung nicht möglich. Bitte versuchen Sie es gleich noch einmal. Die Zahlung wurde nicht durchgeführt.

[iap.payment_auth.body.5]
KO: 결제를 진행하려면 본인 확인이 필요해요.
DE: Zur Fortsetzung der Zahlung ist eine Identitätsprüfung erforderlich.
