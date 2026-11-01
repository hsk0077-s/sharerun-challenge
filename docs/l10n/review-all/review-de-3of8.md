# 번역 검수 요청 — 쉐어런 (German) · 파트 3/8

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
[iap.purchases_closed.body]
KO: 안내
DE: Hinweis

[iap.purchases_closed.title]
KO: 이 버전에서는 앱 안 결제를 받지 않아요.
DE: In-App-Käufe sind in dieser Version nicht verfügbar.

[in_app_billing.body]
KO: DIA · SHARE로 교환
DE: Gegen DIA · SHARE eintauschen

[in_app_billing.body.2]
KO: Play 상품 준비 중 · 결제해도 DIA가 지급되지 않습니다
DE: Play-Produkte werden vorbereitet · Auch bei Zahlung wird kein DIA gutgeschrieben

[in_challenge.body]
KO: 센서 준비 중...
DE: Sensoren werden vorbereitet...

[in_challenge.body.2]
KO: Jena 검증 중...
DE: Jena überprüft...

[in_challenge.body.3]
KO: 제출 기회: ${widget.submissionsRemaining}/${widget.maxSubmissions}회 남음
DE: Verbleibende Versuche: ${widget.submissionsRemaining}/${widget.maxSubmissions}

[in_challenge.body.4]
KO: 센서 시작 실패: $e
DE: Sensorstart fehlgeschlagen: $e

[in_challenge.body.5]
KO: 심박수
DE: Herzfrequenz

[in_challenge.body.6]
KO: 위치 권한이 필요합니다.
DE: Standortberechtigung erforderlich.

[in_challenge.body.7]
KO: Google Maps API 키가 설정되지 않았습니다.
DE: Google Maps API-Schlüssel nicht konfiguriert.

[in_challenge.body.8]
KO: 러닝 데이터를 검증 중입니다...
DE: Laufdaten werden überprüft...

[in_challenge.button]
KO: 강제 정지 대신 소명 기회가 부여되었습니다. 증빙 자료를 제출해 주세요.
DE: Anstelle einer Sperre erhalten Sie die Möglichkeit zur Stellungnahme. Nachweise einreichen.

[in_challenge.button.2]
KO: 소명하러 가기
DE: Stellungnahme abgeben

[in_challenge.button.3]
KO: 시스템 설정 열기
DE: Systemeinstellungen

[in_challenge.dialog]
KO: 기록 검증 보류
DE: Verifizierung ausstehend

[in_challenge.toast]
KO: Jena 검증 실패: ${ApiErrorMessage.from(error)}
DE: Jena-Verifizierung fehlgeschlagen: ${ApiErrorMessage.from(error)}

[app.itemInventoryBoostRunQuantityNote]
KO: 하루 1회 · 15분간 줍는 SHARE 2배 · 추가분 +240
DE: 1x täglich · 2x gesammelte SHARE für 15 Min. · Zusätzlich +240

[app.itemInventoryCoachOnePointHint]
KO: 러닝을 시작하면 사용됩니다. 하루 1회.
DE: Wird beim Starten des Laufs verwendet. 1x täglich.

[app.itemInventoryCprQuantity]
KO: 보유량: 3/3
DE: Im Besitz: 3/3

[app.itemInventoryCrewCheerHint]
KO: 하루 1회. 대회 SHARE 보상만 10% 늘어납니다.
DE: 1x täglich. Nur die SHARE-Belohnungen des Wettbewerbs steigen um 10 %.

[app.itemInventoryDonationMatchNote]
KO: 100 VALUE. 운영자 명의 1,000원이 러닝 기부 풀에 더해지고 내 이름이 함께 표시됩니다. 영수증은 없습니다.
DE: 100 VALUE. 1.000 KRW im Namen des Betreibers werden dem Lauf-Spendenpool hinzugefügt und Ihr Name wird angezeigt. Quittungen werden nicht ausgestellt.

[app.itemInventoryDonationMatchUse]
KO: 매칭하기
DE: Matchen

[app.itemInventoryExtraEntryHint]
KO: 모집 마감·정원 초과 참가 시 사용됩니다. 하루 2회.
DE: Wird bei Teilnahme nach Anmeldeschluss oder Überbelegung verwendet. 2x täglich.

[app.itemInventoryFriendGhostHint]
KO: 러닝 중 친구 기록과 비교합니다. 내 최고 기록은 무료입니다.
DE: Vergleicht beim Laufen mit dem Rekord eines Freundes. Eigener persönlicher Rekord ist kostenlos.

[app.itemInventoryRestDayNote]
KO: 매주 1회 무료. 추가 보유분만 VALUE로 샀습니다. 휴식일은 출석으로 세지 않고 스트릭도 끊지 않습니다.
DE: 1x pro Woche kostenlos. Nur zusätzliche Einheiten wurden mit VALUE gekauft. Ruhetage zählen nicht als Anwesenheit und unterbrechen die Serie nicht.

[app.itemInventoryRestDayToday]
KO: 오늘 휴식
DE: Heute ruhen

[app.itemInventoryRestDayYesterday]
KO: 어제 휴식
DE: Gestern geruht

[app.itemInventorySafeGuardQuantity]
KO: 보유량: 1/1
DE: Im Besitz: 1/1

[app.itemInventoryTitle]
KO: 내 아이템 보관함
DE: Mein Gegenstandsinventar

[app.itemInventoryUse]
KO: 사용하기
DE: Verwenden

[item_inventory.body]
KO: 보유량: ${shop.cprCount}
DE: Im Besitz: ${shop.cprCount}

[item_inventory.body.2]
KO: 보유량: ${shop.safeGuardCount}
DE: Im Besitz: ${shop.safeGuardCount}

[item_inventory.body.3]
KO: 보유량: ${shop.coachOnePointCount}
DE: Im Besitz: ${shop.coachOnePointCount}

[item_inventory.body.4]
KO: 보유량: ${shop.extraEntryCount}
DE: Im Besitz: ${shop.extraEntryCount}

[item_inventory.body.5]
KO: 보유량: ${shop.friendGhostCount}
DE: Im Besitz: ${shop.friendGhostCount}

[item_inventory.body.6]
KO: 보유량: ${shop.crewCheerCount}
DE: Im Besitz: ${shop.crewCheerCount}

[item_inventory.body.7]
KO: 보유량: ${shop.boostRunCount}
${AppStrings.itemInventoryBoostRunQuantityNote}
DE: Besitz: ${shop.boostRunCount}
${AppStrings.itemInventoryBoostRunQuantityNote}

[item_inventory.body.8]
KO: 보유량: ${shop.stepIncubatorCount}
${AppStrings.itemInventoryStepIncubatorQuantityNote}
DE: Besitz: ${shop.stepIncubatorCount}
${AppStrings.itemInventoryStepIncubatorQuantityNote}

[item_inventory.body.9]
KO: 추가 보유: ${shop.restDayCount}
${AppStrings.itemInventoryRestDayNote}
DE: Zusätzlich im Besitz: ${shop.restDayCount}
${AppStrings.itemInventoryRestDayNote}

[item_inventory.toast]
KO: 이미 처리된 매칭입니다. VALUE는 한 번만 차감됩니다.
DE: Match bereits verarbeitet. VALUE wird nur einmal abgezogen.

[item_inventory.toast.2]
KO: 기부 매칭을 기록했습니다.
DE: Spenden-Match aufgezeichnet.

[item_inventory.toast.3]
KO: 기부 매칭을 기록하지 못했습니다.
DE: Spenden-Match konnte nicht aufgezeichnet werden.

[item_inventory.toast.4]
KO: 이미 처리된 휴식일 지정입니다.
DE: Ruhetag-Zuweisung bereits verarbeitet.

[item_inventory.toast.5]
KO: $label 완료
DE: $label abgeschlossen

[item_inventory.toast.6]
KO: 휴식일을 지정하지 못했습니다.
DE: Ruhetag konnte nicht zugewiesen werden.

[item_inventory.toast.7]
KO: $title 보유량이 없습니다. 상점에서 구매해 주세요.
DE: Kein $title vorhanden. Bitte im Shop kaufen.

[item_inventory.toast.8]
KO: $title 사용 완료
DE: $title verwendet

[item_inventory.toast.9]
KO: $title 을 사용하지 못했습니다.
DE: $title konnte nicht verwendet werden.

[jena_validation.jena_pending_gate.body]
KO: 케이던스(발구름) 데이터가 없거나 0입니다. 기록이 보류되었습니다.
DE: Schrittfrequenz-Daten fehlen oder sind 0. Der Eintrag wurde zurückgestellt.

[jena_validation.jena_pending_gate.body.2]
KO: 심박수 추이가 페이스 증가에 반응하지 않아 차량·자전거·킥보드 탑승이 의심됩니다.
DE: Die Herzfrequenz reagiert nicht auf den Anstieg der Pace; es besteht Verdacht auf Nutzung von Fahrzeug, Fahrrad oder E-Scooter.

[jena_validation.jena_pending_gate.body.3]
KO: GPS 오차 범위를 넘는 순간 이동 속도가 검출되어 기록이 거절되었습니다.
DE: Es wurde eine Momentangeschwindigkeit außerhalb der GPS-Fehlertoleranz festgestellt; der Eintrag wurde abgelehnt.

[jena_validation.jena_pending_gate.body.4]
KO: 비정상적인 GPS 순간 속도가 검출되어 기록이 보류되었습니다.
DE: Es wurde eine unnormale GPS-Momentangeschwindigkeit festgestellt; der Eintrag wurde zurückgestellt.

[jena_validation.mock_jena_validation_service.body]
KO: GPS 궤적 또는 거리 데이터가 부족합니다.
DE: GPS-Routen- oder Distanzdaten sind unzureichend.

[jena_validation.mock_jena_validation_service.body.2]
KO: 순수 노력 러닝으로 Jena AI 검증이 완료되었습니다.
DE: Jena AI-Verifizierung als echter Leistungslauf abgeschlossen.

[jena_validation.verification_guidance.body]
KO: 이번 대회의 검증 최소 거리는 $distance예요. 대회 거리가 더 짧아도 1km는 넘어야 해요.
DE: Die Mindeststrecke für die Verifizierung bei diesem Wettkampf beträgt $distance. Auch wenn die Wettkampfdistanz kürzer ist, muss sie über 1 km liegen.

[jena_validation.verification_guidance.body.2]
KO: 분당 걸음 수는 120~210이어야 해요.
DE: Die Schrittfrequenz muss zwischen 120 und 210 Schritten pro Minute liegen.

[jena_validation.verification_guidance.body.3]
KO: 워치 심박은 운영자 대회 상급·하프·파이널에서만 필요해요.
DE: Die Herzfrequenzmessung über die Watch ist nur bei Betreiber-Wettkämpfen der Stufen Fortgeschritten, Halbmarathon und Finale erforderlich.

[jena_validation.verification_guidance.body.4]
KO: 이 대회는 워치 심박이 있어야 완주로 인정돼요.
DE: Für diesen Wettkampf ist die Herzfrequenzmessung über die Watch erforderlich, um als Finish anerkannt zu werden.

[jena_validation.verification_guidance.body.5]
KO: 기록은 언제나, 보상은 검증된 달리기에만.
DE: Aufzeichnung immer, Belohnungen nur für verifizierte Läufe.

[jena_validation.verification_guidance.body.6]
KO: 검증 안내
DE: Hinweise zur Verifizierung

[jena_validation.verification_guidance.body.7]
KO: 확인하고 참가
DE: Bestätigen und teilnehmen

[jena_validation.verification_guidance.body.8]
KO: 다시 보지 않기
DE: Nicht mehr anzeigen

[jena_validation.verification_reason.body]
KO: 거리가 이번 대회의 최소 거리보다 짧아요. 대회 거리만큼, 적어도 1km는 달려야 해요. 기록은 남고 보상은 지급되지 않아요.
DE: Die Distanz ist kürzer als die Mindestdistanz dieses Wettkampfs. Sie müssen mindestens die Wettkampfdistanz und mindestens 1 km laufen. Die Aufzeichnung bleibt erhalten, es wird jedoch keine Belohnung ausgezahlt.

[jena_validation.verification_reason.body.2]
KO: 분당 걸음 수가 120~210 범위를 벗어났어요. 기록은 남고 보상은 지급되지 않아요.
DE: Die Schrittfrequenz lag außerhalb des Bereichs von 120–210 Schritten pro Minute. Die Aufzeichnung bleibt erhalten, es wird jedoch keine Belohnung ausgezahlt.

[jena_validation.verification_reason.body.3]
KO: 상급·하프·파이널 대회는 워치 심박이 있어야 완주로 인정돼요. 심박이 없어 보상은 지급되지 않아요.
DE: Bei Wettkämpfen der Stufen Fortgeschritten, Halbmarathon und Finale ist die Herzfrequenzmessung über die Watch erforderlich, um als Finish anerkannt zu werden. Da keine Herzfrequenzdaten vorliegen, wird keine Belohnung ausgezahlt.

[jena_validation.verification_reason.body.4]
KO: 평균 심박이 달리기라고 보기엔 낮아요. 기록은 남고 보상은 지급되지 않아요.
DE: Die durchschnittliche Herzfrequenz ist zu niedrig, um als Lauf gewertet zu werden. Die Aufzeichnung bleibt erhalten, es wird jedoch keine Belohnung ausgezahlt.

[jena_validation.verification_reason.body.5]
KO: 심박이 거의 변하지 않아 달리기로 확인되지 않았어요. 기록은 남고 보상은 지급되지 않아요.
DE: Da sich die Herzfrequenz kaum verändert hat, konnte die Aktivität nicht als Lauf bestätigt werden. Die Aufzeichnung bleibt erhalten, es wird jedoch keine Belohnung ausgezahlt.

[jena_validation.verification_reason.body.6]
KO: 워치가 없어 보폭을 확인했는데, 거리와 걸음 수가 달리기 범위가 아니에요. 기록은 남고 보상은 지급되지 않아요.
DE: Da keine Watch vorhanden war, wurde die Schrittlänge überprüft, aber Distanz und Schrittanzahl lagen nicht im Laufbereich. Die Aufzeichnung bleibt erhalten, es wird jedoch keine Belohnung ausgezahlt.

[jena_validation.verification_reason.body.7]
KO: 이동 속도가 차량에 가까워 달리기로 인정되지 않았어요. 기록은 남고 보상은 지급되지 않아요.
DE: Die Geschwindigkeit entsprach eher einem Fahrzeug und wurde daher nicht als Lauf anerkannt. Die Aufzeichnung bleibt erhalten, es wird jedoch keine Belohnung ausgezahlt.

[jena_validation.verification_reason.body.8]
KO: 킥보드나 탑승으로 보여 보상은 지급되지 않아요. 기록은 남아요.
DE: Es scheint sich um die Nutzung eines Rollers oder Fahrzeugs zu handeln, daher wird keine Belohnung ausgezahlt. Die Aufzeichnung bleibt erhalten.

[jena_validation.verification_reason.body.9]
KO: 자전거 탑승으로 보여 보상은 지급되지 않아요. 기록은 남아요.
DE: Es scheint sich um eine Fahrradfahrt zu handeln, daher wird keine Belohnung ausgezahlt. Die Aufzeichnung bleibt erhalten.

[launch.intro.body]
KO: 걸으면 SHARE가 쌓여요
DE: Gehen Sie und sammeln Sie SHARE

[launch.intro.body.10]
KO: +100원
DE: +100 Won

[launch.intro.body.11]
KO: 회사(운영자) 자금으로 기부 예정 · 내가 내는 돈은 없어요 · 내 기여는 앱에서 확인
DE: Geplant aus Mitteln des Unternehmens (Betreiber) · Keine Kosten für Sie · Beitrag in der App einsehen

[launch.intro.body.13]
KO: 지금
달팽이
DE: Aktuell
Schnecke

[launch.intro.body.14]
KO: 등급을
받으면
DE: Nach der
Einstufung

[launch.intro.body.15]
KO: 티어가
오르면
DE: Wenn die Stufe
steigt

[launch.intro.body.2]
KO: 한 걸음이 나눔이 된다
DE: Jeder Schritt wird zum Teilen

[launch.intro.body.3]
KO: 내 기록은 어느 폰에서나 그대로예요
DE: Ihre Rekorde bleiben auf jedem Smartphone erhalten

[launch.intro.body.4]
KO: 100걸음마다 10 SHARE를 받아요. 모은 SHARE로 대회에 참가할 수 있어요.
DE: Erhalten Sie 10 SHARE alle 100 Schritte. Mit den gesammelten SHARE können Sie an Wettkämpfen teilnehmen.

[launch.intro.body.5]
KO: SHARE는 현금으로 바꿀 수 없는 활동 보상이고, 하루에 받을 수 있는 양에 한도가 있어요.
DE: SHARE ist eine Aktivitätsbelohnung, die nicht in Bargeld umgetauscht werden kann, und es gibt ein tägliches Limit für den Erhalt.

[launch.intro.body.6]
KO: 검증된 모든 달리기, 1km마다 운영자가 100원을 기부할 예정이에요. 내가 보탠 만큼은 앱에서 확인할 수 있어요.
DE: Für jeden verifizierten Lauf plant der Betreiber, 100 Won pro 1 km zu spenden. Sie können Ihren Beitrag in der App einsehen.

[launch.intro.body.7]
KO: 운영자의 월 기부 예산 안에서 진행될 예정이에요. 예산을 다 쓴 달은 넘는 거리가 기록으로 남아요.
DE: Das ist im Rahmen des monatlichen Spendenbudgets des Betreibers geplant. In Monaten, in denen das Budget aufgebraucht ist, wird die überschüssige Distanz als Aufzeichnung gespeichert.

[launch.intro.body.8]
KO: 걷기·달리기 기록은 서버에 저장돼요. 폰을 바꿔도 로그인하면 이어져요.
DE: Geh- und Laufaufzeichnungen werden auf dem Server gespeichert. Selbst wenn Sie das Smartphone wechseln, melden Sie sich einfach an, um fortzufahren.

[launch.intro.body.9]
KO: 100걸음
DE: 100 Schritte

[launch.intro.button]
KO: 시작하기
DE: Starten

[launch.intro.button.2]
KO: 이미 계정이 있어요 · 로그인
DE: Bereits ein Konto? · Anmelden

[legal.health_data_consent.body]
KO: 체크해야 워치 연동·심박 검증이 활성화됩니다.
DE: Muss markiert werden, um Smartwatch-Synchronisierung und Herzfrequenzüberprüfung zu aktivieren.

[legal_constants.body]
KO: 결제 취소 (현금 환불)
DE: Zahlung stornieren (Bargeldrückerstattung)

[legal_constants.body.10]
KO: 마케팅·활동 알림 (선택)
DE: Marketing- und Aktivitätsbenachrichtigungen (Optional)

[legal_constants.body.12]
KO: 부정 러닝·결제 어뷰징은 계정 제한 대상이 될 수 있습니다.
DE: Betrügerisches Laufen und Zahlungsmissbrauch können zu Kontoeinschränkungen führen.

[legal_constants.body.14]
KO: 전체 내용은 개인정보 처리방침 전문에서 확인할 수 있습니다.
DE: Die vollständigen Einzelheiten finden Sie in der vollständigen Datenschutzrichtlinie.

[legal_constants.body.17]
KO: 대회 모집, 검증 결과, 리워드·기부 알림을 푸시로 받을 수 있습니다. 언제든 MyPage에서 변경할 수 있습니다.
DE: Sie können Push-Benachrichtigungen zu Wettbewerbsanmeldungen, Verifizierungsergebnissen, Belohnungen und Spenden erhalten. Sie können dies jederzeit in MyPage ändern.

[legal_constants.body.18]
KO: 심박수·케이던스 원본 데이터는 기기 메모리에서 검증한 뒤 바로 폐기하며, 검증 결과 요약만 저장합니다.
DE: Rohdaten zu Herzfrequenz und Schrittfrequenz werden nach der Überprüfung im Gerätespeicher sofort verworfen, und es wird nur eine Zusammenfassung der Verifizierungsergebnisse gespeichert.

[legal_constants.body.19]
KO: 건강 정보 안내
DE: Hinweis zu Gesundheitsinformationen

[legal_constants.body.2]
KO: [선택] 건강정보(심박수) 수집 및 이용 동의
DE: [Optional] Einwilligung zur Erfassung und Nutzung von Gesundheitsdaten (Herzfrequenz)

[legal_constants.body.21]
KO: 가슴 통증, 어지러움 등 이상이 느껴지면 즉시 운동을 멈추고 의료진과 상담하세요.
DE: Wenn Sie Brustschmerzen, Schwindel oder andere Auffälligkeiten bemerken, brechen Sie das Training sofort ab und konsultieren Sie einen Arzt.

[legal_constants.body.23]
KO: 언제든 해지할 수 있으며, 해지해도 이미 결제한 기간이 끝날 때까지 이용할 수 있습니다.
DE: Sie können jederzeit kündigen und den Dienst bis zum Ende des bereits bezahlten Zeitraums weiter nutzen.

[legal_constants.body.3]
KO: 건강정보 수집 동의 (선택 · 별도)
DE: Einwilligung zur Erfassung von Gesundheitsdaten (Optional · Separat)

[legal_constants.body.4]
KO: 개인정보 처리방침 전문 보기
DE: Vollständige Datenschutzrichtlinie anzeigen

[legal_constants.body.5]
KO: 서비스 이용약관 전문 보기
DE: Vollständige Nutzungsbedingungen anzeigen

[legal_constants.body.6]
KO: AI 생성 이미지 안내
DE: Hinweis zu KI-generierten Bildern

[legal_constants.body.7]
KO: 일부 그림은 AI로 생성되었습니다. Created with Grok
DE: Einige Bilder wurden mit KI erstellt. Created with Grok

[legal_constants.body.8]
KO: 서비스 이용약관 (필수)
DE: Nutzungsbedingungen (Erforderlich)

[legal_constants.body.9]
KO: 개인정보 처리방침 (필수)
DE: Datenschutzrichtlinie (Erforderlich)

[app.levelTestChallengeProgress]
KO: 챌린지 진행 상황: 2/3회 완료 (3.52/5.00 KM)
DE: Herausforderungsfortschritt: 2/3 abgeschlossen (3,52/5,00 KM)

[app.levelTestGhostPace]
KO: [고스트 페이스]
DE: [Ghost-Pace]

[app.levelTestMyLocation]
KO: [나(현재 위치)]
DE: [Ich (Aktueller Standort)]

[app.levelTestStartRun]
KO: 3회차 달리기 시작하기
DE: 3. Lauf starten

[app.levelTestStatDistance]
KO: 현재 거리
DE: Aktuelle Distanz

[app.levelTestStatPace]
KO: 현재 페이스
DE: Aktuelle Pace

[app.levelTestStatTime]
KO: 경과 시간
DE: Verstrichene Zeit

[app.levelTestSubtitle]
KO: 검증된 달리기를 서로 다른 날 3번 마치면 등급이 배정됩니다.
DE: Schließen Sie 3 verifizierte Läufe an verschiedenen Tagen ab, um eine Einstufung zu erhalten.

[app.levelTestTitle]
KO: 혼자 뛰기 챌린지 (등급 배정)
DE: Solo-Lauf-Herausforderung (Einstufung)

[app.liveRunningEffortTip]
KO: 순수 노력 목표: 완주 시 VALUE +$valueTokens
DE: Reines Anstrengungsziel: VALUE +$valueTokens bei Abschluss

[app.liveRunningFinish]
KO: 종료 / 저장
DE: Beenden / Speichern

[app.liveRunningGhostPace]
KO: 고스트 페이스
DE: Ghost-Pace

[app.liveRunningRoomTitle]
KO: 3km 중급 챌린지
DE: 3-km-Herausforderung für Fortgeschrittene

[app.liveRunningSubmissionsLeft]
KO: 제출 기회: 2/3회 남음
DE: Verbleibende Einreichungen: 2/3

[app.liveRunningYouLabel]
KO: 나 (You)
DE: Du (You)

[app.runValidationFailed]
KO: 기록 검증에 실패했습니다. 보상이 지급되지 않았습니다.
DE: Aufzeichnungsüberprüfung fehlgeschlagen. Belohnung wurde nicht vergeben.

[live_running.body]
KO: 1km 초보 챌린지
DE: 1 km Anfänger-Challenge

[live_running.body.2]
KO: 나
DE: Ich

[live_running.body.3]
KO: 고스트
DE: Geist

[live_running.body.4]
KO: 검증 중
DE: Wird überprüft

[live_running.toast]
KO: 센서 시작 실패: $error
DE: Sensorstart fehlgeschlagen: $error

[app.existingAccountApple]
KO: 애플로 가입했어요
DE: Ich habe mich mit Apple registriert

[app.existingAccountBody]
KO: 그 방법으로 로그인하면 지금 $provider${subjectParticle(provider)} 그 계정에 연결돼요. 닉네임과 재화도 그대로예요.
DE: Wenn Sie sich mit dieser Methode anmelden, wird Ihr aktuelles $provider${subjectParticle(provider)} mit diesem Konto verknüpft. Ihr Nickname und Ihre Währung bleiben ebenfalls erhalten.

[app.existingAccountCreate]
KO: 새로 시작하기
DE: Neu starten

[app.existingAccountCreateHint]
KO: 기억나지 않거나 처음이신가요?
DE: Erinnern Sie sich nicht oder sind Sie zum ersten Mal hier?

[app.existingAccountGoogle]
KO: 구글로 가입했어요
DE: Ich habe mich mit Google registriert

[app.existingAccountKakao]
KO: 카카오로 가입했어요
DE: Ich habe mich mit Kakao registriert

[app.existingAccountNaver]
KO: 네이버로 가입했어요
DE: Ich habe mich mit Naver registriert

[app.existingAccountNotFound]
KO: 그 방법으로 가입된 계정이 없어요. 다른 방법을 골라 주세요.
DE: Mit dieser Methode wurde kein Konto gefunden. Bitte wählen Sie eine andere Methode.

[app.existingAccountTitle]
KO: 처음 가입할 때 어떤 방법을 쓰셨나요?
DE: Welche Methode haben Sie bei der ersten Registrierung verwendet?

[app.linkAttached]
KO: $method${subjectParticle(method)} 연결됐어요. 이제 어느 쪽으로 들어와도 같은 계정이에요.
DE: $method${subjectParticle(method)} wurde verknüpft. Ab jetzt greifen Sie über beide Wege auf dasselbe Konto zu.

[app.linkConfirmNo]
KO: 아니에요, 다시 고를게요
DE: Nein, neu auswählen

[app.linkConfirmTitle]
KO: 이 계정에 $method${objectParticle(method)} 연결할까요?
DE: $method${objectParticle(method)} mit diesem Konto verknüpfen?

[app.linkConfirmYes]
KO: 네, 연결할게요
DE: Ja, verknüpfen

[app.loginComingSoon]
KO: $provider 로그인은 준비 중입니다.
DE: Anmeldung mit $provider ist in Vorbereitung.

[app.loginGoogle]
KO: Google로 계속하기
DE: Mit Google fortfahren

[app.loginGuest]
KO: 게스트(테스트)로 시작하기
DE: Als Gast (Test) starten

[app.loginGuestLoading]
KO: 게스트 로그인 중...
DE: Gast-Anmeldung läuft...

[app.loginGuestNote]
KO: 게스트 모드는 워치 연동·Health Connect 테스트용 임시 계정입니다.
DE: Der Gastmodus ist ein temporäres Konto zum Testen der Watch-Verbindung und von Health Connect.

[app.loginKakao]
KO: Kakao로 계속하기
DE: Mit Kakao fortfahren

[app.loginNaver]
KO: Naver로 계속하기
DE: Mit Naver fortfahren

[app.loginReferralHint]
KO: 추천 코드를 입력하세요...
DE: Empfehlungscode eingeben...

[app.loginReferralLabel]
KO: 추천 코드가 있으신가요?
DE: Haben Sie einen Empfehlungscode?

[app.loginSaveFailed]
KO: 로그인 저장 실패: $error
DE: Fehler beim Speichern der Anmeldung: $error

[app.loginSubtitle]
KO: 세계를 향한 나눔의 질주
DE: Ein Lauf des Teilens für die Welt

[app.referralRedeemAlready]
KO: 이미 초대 코드를 입력했어요
DE: Sie haben bereits einen Einladungscode eingegeben

[app.referralRedeemDone]
KO: 초대한 친구: 입력 완료
DE: Eingeladener Freund: Eingegeben

[app.referralRedeemEntry]
KO: 초대 코드 입력
DE: Einladungscode eingeben

[app.referralRedeemExpired]
KO: 가입 후 7일이 지나 입력할 수 없어요
DE: Eingabe nicht möglich, da seit der Registrierung mehr als 7 Tage vergangen sind

[app.referralRedeemFailed]
KO: 초대 코드를 등록하지 못했어요
DE: Der Einladungscode konnte nicht registriert werden

[app.referralRedeemInvalid]
KO: 없는 초대 코드예요
DE: Dieser Einladungscode existiert nicht

[app.referralRedeemSelf]
KO: 본인 코드는 입력할 수 없어요
DE: Sie können Ihren eigenen Code nicht eingeben

[app.referralRedeemSubmit]
KO: 등록
DE: Registrieren

[app.referralRedeemSuccess]
KO: 10,000 SHARE 지급
DE: 10.000 SHARE gutgeschrieben

[login.body]
KO: 구글 로그인에 성공했습니다!
DE: Google-Login erfolgreich!

[login.body.2]
KO: 로그인 실패:
DE: Anmeldung fehlgeschlagen:

[login.body.3]
KO: 애플 로그인에 성공했습니다!
DE: Apple-Login erfolgreich!

[login.body.4]
KO: 애플 로그인 실패:
DE: Apple-Login fehlgeschlagen:

[login.body.5]
KO: 네이버 로그인에 성공했습니다!
DE: Naver-Login erfolgreich!

[login.body.6]
KO: 네이버 로그인 실패:
DE: Naver-Login fehlgeschlagen:

[login.body.7]
KO: 카카오 로그인에 성공했습니다!
DE: Kakao-Login erfolgreich!

[login.body.8]
KO: 카카오 로그인 실패:
DE: Kakao-Login fehlgeschlagen:

[login.body.9]
KO: 닉네임 $nickname
SHARE ${groupedDigits(shareBalance)}
DE: Nickname $nickname
SHARE ${groupedDigits(shareBalance)}

[login.button]
KO: 초대 코드가 있으신가요?
DE: Haben Sie einen Einladungscode?

[login_connections.body]
KO: $name 연결을 해제했어요.
DE: Verbindung zu $name getrennt.

[login_connections.body.2]
KO: 카카오
DE: Kakao

[login_connections.body.3]
KO: 네이버
DE: Naver

[login_connections.body.4]
KO: 애플
DE: Apple

[login_connections.body.5]
KO: 구글
DE: Google

[login_connections.body.6]
KO: 같은 계정으로 여러 방법으로 로그인할 수 있어요. 연결해 두면 어떤 방법으로 들어와도 같은 SHARE와 기록이 보여요. 마지막 로그인 방법은 해제할 수 없어요.
DE: Sie können sich auf verschiedene Arten für dasselbe Konto anmelden. Nach der Verknüpfung sehen Sie mit jeder Methode dasselbe SHARE und dieselben Verläufe. Die letzte Anmeldemethode kann nicht getrennt werden.

[login_connections.body.7]
KO: 연결 안 됨
DE: Nicht verbunden

[login_connections.button]
KO: 해제하면 이 $name 계정으로는 이 쉐어런 계정에 들어올 수 없어요. 다른 로그인 방법으로는 계속 쓸 수 있어요.
DE: Nach der Trennung können Sie mit diesem $name-Konto nicht mehr auf dieses ShareRun-Konto zugreifen. Andere Anmeldemethoden funktionieren weiterhin.

[login_connections.button.2]
KO: 다시 불러오기
DE: Neu laden

[login_connections.button.3]
KO: 연결하기
DE: Verbinden

[login_connections.dialog]
KO: $name 연결 해제
DE: $name-Verbindung trennen

[login_devices.body]
KO: 이 계정으로 앱을 연 기기예요. 기기 이름과 마지막으로 연 시각만 저장하고, 위치나 IP 주소는 저장하지 않아요.
DE: Geräte, die die App mit diesem Konto geöffnet haben. Es werden nur Gerätename und letzte Zugriffszeit gespeichert, keine Standort- oder IP-Daten.

[login_devices.body.2]
KO: 앱 데이터를 지우거나 다시 설치하면 같은 폰이 한 줄 더 보일 수 있어요.
DE: Das Löschen von App-Daten oder Neuinstallieren kann dazu führen, dass dasselbe Smartphone als weiterer Eintrag erscheint.

[login_devices.body.3]
KO: 아직 기록된 기기가 없어요.
DE: Noch keine erfassten Geräte.

[login_devices.body.4]
KO: 알 수 없는 기기
DE: Unbekanntes Gerät

[login_devices.body.5]
KO: $name (이 기기)
DE: $name (Dieses Gerät)

[login_devices.body.6]
KO: $name · 새 기기
DE: $name · Neues Gerät

[login_devices.body.7]
KO: ${device.osVersion} · 앱 ${device.appVersion}
마지막으로 연 시각 $when
DE: ${device.osVersion} · App ${device.appVersion}
Zuletzt geöffnet $when

[login_devices.button]
KO: 이 폰을 포함해 로그인된 모든 기기에서 로그아웃돼요. 다른 기기는 잠시 뒤 로그인 화면으로 돌아가요. 계속할까요?
DE: Sie werden auf allen Geräten einschließlich dieses Smartphones abgemeldet. Andere Geräte kehren in Kürze zum Login-Bildschirm zurück. Fortfahren?

[login_devices.dialog]
KO: 모든 기기에서 로그아웃
DE: Auf allen Geräten abmelden

[login_devices.toast]
KO: 로그아웃하지 못했어요. 잠시 후 다시 시도해 주세요.
DE: Abmeldung fehlgeschlagen. Bitte versuchen Sie es später erneut.

[app.dashboardChallenge1Sub]
KO: 참가비: 600 SHARE
DE: Teilnahmegebühr: 600 SHARE

[app.dashboardChallenge1Title]
KO: 초보 1km 챌린지 🏆
DE: 1-km-Herausforderung für Anfänger 🏆

[app.dashboardChallenge2Sub]
KO: 참가비: 1,200 SHARE
DE: Teilnahmegebühr: 1,200 SHARE

[app.dashboardChallenge2Title]
KO: 중급 3km 챌린지 (골드 대회)
DE: 3-km-Herausforderung für Fortgeschrittene (Gold-Wettbewerb)

[app.dashboardDailyMissionCapsule]
KO: 📍 오늘의 미션 확인하기 >
DE: 📍 Heutige Missionen ansehen >

[app.dashboardDiamondBalance]
KO: 💎 보유 다이아몬드: 5개
DE: 💎 Verfügbare DIA: 5

[app.dashboardDiamondBalanceOf]
KO: 💎 보유 다이아몬드: $count개
DE: 💎 Verfügbare DIA: $count

[app.dashboardGradeRunLabel]
KO: 등급 배정 달리기:
DE: Einstufungslauf:

[app.dashboardGradeRunProgress]
KO: 2/3회 완료 >
DE: 2/3 abgeschlossen >

[app.dashboardOngoingChallenges]
KO: 진행 중인 챌린지
DE: Laufende Herausforderungen

[app.dashboardShareBalance]
KO: 보유 SHARE: 90,000
DE: Verfügbare SHARE: 90,000

[app.dashboardShareBalanceOf]
KO: 보유 SHARE: $amount
DE: Verfügbare SHARE: $amount

[app.dashboardStampMapTooltip]
KO: 오늘의 미션 · 스탬프 투어
DE: Heutige Missionen · Stempel-Tour

[app.dashboardValueBalance]
KO: 🌱 보유 밸류(VALUE): 5,200
DE: 🌱 Verfügbare VALUE: 5,200

[app.dashboardValueBalanceOf]
KO: 🌱 보유 밸류(VALUE): $amount
DE: 🌱 Verfügbare VALUE: $amount

[app.dashboardViewRoom]
KO: 대회 상세 보기
DE: Wettbewerbsdetails anzeigen

[app.exitGuardMessage]
KO: 나눔의 질주를 잠시 쉬어가시겠습니까? 한 번 더 누르시면 종료됩니다.
DE: Möchten Sie eine Pause vom Lauf des Teilens einlegen? Drücken Sie erneut, um zu beenden.

[app.myWalletCharge]
KO: 교환하기
DE: Umtauschen

[app.myWalletChargeDia]
KO: 다이아몬드
DE: DIA

[app.myWalletChargeDiaHint]
KO: 교환소에서 SHARE로 바꾸거나 연속 달리기로 모을 수 있어요
DE: Sie können es in der Wechselstube in SHARE umtauschen oder durch Laufserien sammeln.

[app.myWalletChargeShareHint]
KO: 활동으로 모을 수 있어요
DE: Kann durch Aktivitäten gesammelt werden.

[app.myWalletChargeValue]
KO: 밸류(VALUE)
DE: VALUE

[app.myWalletChargeValueHint]
KO: 달리기로 모을 수 있어요
DE: Kann durch Laufen gesammelt werden.

[app.myWalletDiamondLabel]
KO: 보유 다이아몬드: $count개
DE: Verfügbare DIA: $count

[app.myWalletGradeProgress]
KO: 등급 배정 달리기: $done/$total회 완료 >
DE: Einstufungslauf: $done/$total abgeschlossen >

[app.myWalletInventoryCount]
KO: 보유 $count
DE: Im Besitz: $count

[app.myWalletInventoryEmpty]
KO: 아직 보유한 아이템이 없습니다.
DE: Sie besitzen noch keine Gegenstände.

[app.myWalletInventoryOpen]
KO: 보관함 보기
DE: Inventar ansehen

[app.myWalletInventoryTitle]
KO: 보유 아이템
DE: Verfügbare Gegenstände

[app.myWalletItemDuringRun]
KO: 달리기 중 사용 가능
DE: Während des Laufs nutzbar

[app.myWalletItemDuringTournament]
KO: 대회에서 사용 가능
DE: Im Wettbewerb nutzbar

[app.myWalletRecentTransactions]
KO: 최근 거래 내역
DE: Letzte Transaktionen

[app.myWalletUse]
KO: 상점 가기
DE: Zum Shop

[app.myWalletValueLabel]
KO: 보유 밸류(VALUE): $amount
DE: Verfügbare VALUE: $amount

[app.walletUnconfirmedNote]
KO: 서버에서 확인하는 중이에요. 지금 보이는 값은 마지막으로 확인된 값이에요.
DE: Wird mit dem Server überprüft. Der angezeigte Wert ist der zuletzt bestätigte Wert.

[main_dashboard.body]
KO: 상품은 다이아예요 · ${AppStrings.noCashPrizePool}
DE: Preise sind DIA · ${AppStrings.noCashPrizePool}

[main_dashboard.body.2]
KO: 좋은 아침이에요
DE: Guten Morgen

[main_dashboard.body.3]
KO: 좋은 오후예요
DE: Guten Tag

[main_dashboard.body.4]
KO: 좋은 저녁이에요
DE: Guten Abend

[main_dashboard.body.5]
KO: ${_hello(DateTime.now().hour)}, $nickname님
DE: ${_hello(DateTime.now().hour)}, $nickname

[main_shell_routes.body]
KO: 결제 정보가 없어 PG 화면을 열 수 없습니다.
DE: PG-Bildschirm kann nicht geöffnet werden, da Zahlungsinformationen fehlen.

[main_shell_routes.body.2]
KO: 대회 정보가 없어 스폰서 결제를 열 수 없습니다.
DE: Sponsorenzahlung kann nicht geöffnet werden, da Wettbewerbsinformationen fehlen.
