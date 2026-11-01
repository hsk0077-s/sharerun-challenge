# 번역 검수 요청 — 쉐어런 (Spanish) · 파트 3/8

아래는 한국어 앱 "쉐어런"(걷기·달리기 앱, 회사 자금 기부 연계)의 화면 문구를 Spanish(으)로 번역한 것입니다.
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
[in_challenge.body.6]
KO: 위치 권한이 필요합니다.
ES: Se requiere permiso de ubicación.

[in_challenge.body.7]
KO: Google Maps API 키가 설정되지 않았습니다.
ES: La clave de la API de Google Maps no está configurada.

[in_challenge.body.8]
KO: 러닝 데이터를 검증 중입니다...
ES: Verificando datos de carrera...

[in_challenge.button]
KO: 강제 정지 대신 소명 기회가 부여되었습니다. 증빙 자료를 제출해 주세요.
ES: Se otorgó una oportunidad de explicación en lugar de suspensión. Envíe pruebas.

[in_challenge.button.2]
KO: 소명하러 가기
ES: Ir a apelar

[in_challenge.button.3]
KO: 시스템 설정 열기
ES: Abrir ajustes de sistema

[in_challenge.dialog]
KO: 기록 검증 보류
ES: Aviso: verificación de la actividad pendiente

[in_challenge.toast]
KO: Jena 검증 실패: ${ApiErrorMessage.from(error)}
ES: Error de verificación de Jena: ${ApiErrorMessage.from(error)}

[app.itemInventoryBoostRunQuantityNote]
KO: 하루 1회 · 15분간 줍는 SHARE 2배 · 추가분 +240
ES: 1 vez al día · Doble de SHARE recolectados por 15 min · Adicional +240

[app.itemInventoryCoachOnePointHint]
KO: 러닝을 시작하면 사용됩니다. 하루 1회.
ES: Se usa al empezar a correr. 1 vez al día.

[app.itemInventoryCprQuantity]
KO: 보유량: 3/3
ES: En posesión: 3/3

[app.itemInventoryCrewCheerHint]
KO: 하루 1회. 대회 SHARE 보상만 10% 늘어납니다.
ES: 1 vez al día. Solo las recompensas de SHARE del torneo aumentan un 10%.

[app.itemInventoryDonationMatchNote]
KO: 100 VALUE. 운영자 명의 1,000원이 러닝 기부 풀에 더해지고 내 이름이 함께 표시됩니다. 영수증은 없습니다.
ES: 100 VALUE. Se añaden 1.000 KRW a nombre del operador al fondo de donaciones para correr y se muestra tu nombre junto a él. No se emiten recibos.

[app.itemInventoryDonationMatchUse]
KO: 매칭하기
ES: Emparejar

[app.itemInventoryExtraEntryHint]
KO: 모집 마감·정원 초과 참가 시 사용됩니다. 하루 2회.
ES: Se usa al unirse tras el cierre de inscripciones o cupo completo. 2 veces al día.

[app.itemInventoryFriendGhostHint]
KO: 러닝 중 친구 기록과 비교합니다. 내 최고 기록은 무료입니다.
ES: Compara con el récord de un amigo mientras corres. Tu mejor marca personal es gratis.

[app.itemInventoryRestDayNote]
KO: 매주 1회 무료. 추가 보유분만 VALUE로 샀습니다. 휴식일은 출석으로 세지 않고 스트릭도 끊지 않습니다.
ES: Gratis 1 vez por semana. Solo la cantidad adicional se compró con VALUE. Los días de descanso no cuentan como asistencia y no rompen la racha.

[app.itemInventoryRestDayToday]
KO: 오늘 휴식
ES: Descanso hoy

[app.itemInventoryRestDayYesterday]
KO: 어제 휴식
ES: Descanso ayer

[app.itemInventorySafeGuardQuantity]
KO: 보유량: 1/1
ES: En posesión: 1/1

[app.itemInventoryTitle]
KO: 내 아이템 보관함
ES: Mi inventario de objetos

[app.itemInventoryUse]
KO: 사용하기
ES: Usar

[item_inventory.body]
KO: 보유량: ${shop.cprCount}
ES: En posesión: ${shop.cprCount}

[item_inventory.body.2]
KO: 보유량: ${shop.safeGuardCount}
ES: En posesión: ${shop.safeGuardCount}

[item_inventory.body.3]
KO: 보유량: ${shop.coachOnePointCount}
ES: En posesión: ${shop.coachOnePointCount}

[item_inventory.body.4]
KO: 보유량: ${shop.extraEntryCount}
ES: En posesión: ${shop.extraEntryCount}

[item_inventory.body.5]
KO: 보유량: ${shop.friendGhostCount}
ES: En posesión: ${shop.friendGhostCount}

[item_inventory.body.6]
KO: 보유량: ${shop.crewCheerCount}
ES: En posesión: ${shop.crewCheerCount}

[item_inventory.body.7]
KO: 보유량: ${shop.boostRunCount}
${AppStrings.itemInventoryBoostRunQuantityNote}
ES: En posesión: ${shop.boostRunCount}
${AppStrings.itemInventoryBoostRunQuantityNote}

[item_inventory.body.8]
KO: 보유량: ${shop.stepIncubatorCount}
${AppStrings.itemInventoryStepIncubatorQuantityNote}
ES: En posesión: ${shop.stepIncubatorCount}
${AppStrings.itemInventoryStepIncubatorQuantityNote}

[item_inventory.body.9]
KO: 추가 보유: ${shop.restDayCount}
${AppStrings.itemInventoryRestDayNote}
ES: Posesión adicional: ${shop.restDayCount}
${AppStrings.itemInventoryRestDayNote}

[item_inventory.toast]
KO: 이미 처리된 매칭입니다. VALUE는 한 번만 차감됩니다.
ES: Emparejamiento ya procesado. VALUE solo se deducirá una vez.

[item_inventory.toast.2]
KO: 기부 매칭을 기록했습니다.
ES: Se registró el emparejamiento de donación.

[item_inventory.toast.3]
KO: 기부 매칭을 기록하지 못했습니다.
ES: No se pudo registrar el emparejamiento de donación.

[item_inventory.toast.4]
KO: 이미 처리된 휴식일 지정입니다.
ES: La asignación de día de descanso ya fue procesada.

[item_inventory.toast.5]
KO: $label 완료
ES: $label completado

[item_inventory.toast.6]
KO: 휴식일을 지정하지 못했습니다.
ES: No se pudo establecer el día de descanso.

[item_inventory.toast.7]
KO: $title 보유량이 없습니다. 상점에서 구매해 주세요.
ES: No tienes $title. Cómpralo en la tienda.

[item_inventory.toast.8]
KO: $title 사용 완료
ES: $title usado

[item_inventory.toast.9]
KO: $title 을 사용하지 못했습니다.
ES: No se pudo usar $title.

[jena_validation.jena_pending_gate.body]
KO: 케이던스(발구름) 데이터가 없거나 0입니다. 기록이 보류되었습니다.
ES: Los datos de cadencia no existen o son 0. Se ha puesto el registro en espera.

[jena_validation.jena_pending_gate.body.2]
KO: 심박수 추이가 페이스 증가에 반응하지 않아 차량·자전거·킥보드 탑승이 의심됩니다.
ES: La frecuencia cardíaca no respondió al aumento de ritmo, por lo que se sospecha el uso de vehículo, bicicleta o patinete.

[jena_validation.jena_pending_gate.body.3]
KO: GPS 오차 범위를 넘는 순간 이동 속도가 검출되어 기록이 거절되었습니다.
ES: Se detectó una velocidad de movimiento instantánea que excede el margen de error del GPS y se rechazó el registro.

[jena_validation.jena_pending_gate.body.4]
KO: 비정상적인 GPS 순간 속도가 검출되어 기록이 보류되었습니다.
ES: Se detectó una velocidad instantánea de GPS anormal y se puso el registro en espera.

[jena_validation.mock_jena_validation_service.body]
KO: GPS 궤적 또는 거리 데이터가 부족합니다.
ES: Los datos de distancia o trayectoria GPS son insuficientes.

[jena_validation.mock_jena_validation_service.body.2]
KO: 순수 노력 러닝으로 Jena AI 검증이 완료되었습니다.
ES: Verificación de Jena AI completada como carrera de esfuerzo genuino.

[jena_validation.verification_guidance.body]
KO: 이번 대회의 검증 최소 거리는 $distance예요. 대회 거리가 더 짧아도 1km는 넘어야 해요.
ES: La distancia mínima de verificación para esta competencia es $distance. Aunque la distancia de la competencia sea menor, debe superar 1 km.

[jena_validation.verification_guidance.body.2]
KO: 분당 걸음 수는 120~210이어야 해요.
ES: Los pasos por minuto deben estar entre 120 y 210.

[jena_validation.verification_guidance.body.3]
KO: 워치 심박은 운영자 대회 상급·하프·파이널에서만 필요해요.
ES: La frecuencia cardíaca del reloj solo es necesaria en las competencias del operador de nivel avanzado, medio maratón y final.

[jena_validation.verification_guidance.body.4]
KO: 이 대회는 워치 심박이 있어야 완주로 인정돼요.
ES: Esta competencia requiere la frecuencia cardíaca del reloj para ser reconocida como completada.

[jena_validation.verification_guidance.body.5]
KO: 기록은 언제나, 보상은 검증된 달리기에만.
ES: Registros siempre, recompensas solo para carreras verificadas.

[jena_validation.verification_guidance.body.6]
KO: 검증 안내
ES: Guía de verificación

[jena_validation.verification_guidance.body.7]
KO: 확인하고 참가
ES: Confirmar y participar

[jena_validation.verification_guidance.body.8]
KO: 다시 보지 않기
ES: No volver a mostrar

[jena_validation.verification_reason.body]
KO: 거리가 이번 대회의 최소 거리보다 짧아요. 대회 거리만큼, 적어도 1km는 달려야 해요. 기록은 남고 보상은 지급되지 않아요.
ES: La distancia es menor que la distancia mínima de esta competencia. Debes correr al menos la distancia de la competencia y al menos 1 km. El registro se guarda, pero no se otorgan recompensas.

[jena_validation.verification_reason.body.2]
KO: 분당 걸음 수가 120~210 범위를 벗어났어요. 기록은 남고 보상은 지급되지 않아요.
ES: Los pasos por minuto estuvieron fuera del rango de 120 a 210. El registro se guarda, pero no se otorgan recompensas.

[jena_validation.verification_reason.body.3]
KO: 상급·하프·파이널 대회는 워치 심박이 있어야 완주로 인정돼요. 심박이 없어 보상은 지급되지 않아요.
ES: Las competencias de nivel avanzado, medio maratón y final requieren la frecuencia cardíaca del reloj para considerarse finalizadas. Al no haber frecuencia cardíaca, no se otorgan recompensas.

[jena_validation.verification_reason.body.4]
KO: 평균 심박이 달리기라고 보기엔 낮아요. 기록은 남고 보상은 지급되지 않아요.
ES: La frecuencia cardíaca promedio es demasiado baja para considerarse una carrera. El registro se guarda, pero no se otorgan recompensas.

[jena_validation.verification_reason.body.5]
KO: 심박이 거의 변하지 않아 달리기로 확인되지 않았어요. 기록은 남고 보상은 지급되지 않아요.
ES: La frecuencia cardíaca casi no cambió, por lo que no se pudo confirmar como carrera. El registro se guarda, pero no se otorgan recompensas.

[jena_validation.verification_reason.body.6]
KO: 워치가 없어 보폭을 확인했는데, 거리와 걸음 수가 달리기 범위가 아니에요. 기록은 남고 보상은 지급되지 않아요.
ES: Como no había reloj se revisó la zancada, pero la distancia y el número de pasos no están en el rango de carrera. El registro se guarda, pero no se otorgan recompensas.

[jena_validation.verification_reason.body.7]
KO: 이동 속도가 차량에 가까워 달리기로 인정되지 않았어요. 기록은 남고 보상은 지급되지 않아요.
ES: La velocidad de movimiento era similar a la de un vehículo y no fue reconocida como carrera. El registro se guarda, pero no se otorgan recompensas.

[jena_validation.verification_reason.body.8]
KO: 킥보드나 탑승으로 보여 보상은 지급되지 않아요. 기록은 남아요.
ES: Parece tratarse de un patinete o vehículo, por lo que no se otorgan recompensas. El registro se conserva.

[jena_validation.verification_reason.body.9]
KO: 자전거 탑승으로 보여 보상은 지급되지 않아요. 기록은 남아요.
ES: Parece tratarse de un trayecto en bicicleta, por lo que no se otorgan recompensas. El registro se conserva.

[launch.intro.body]
KO: 걸으면 SHARE가 쌓여요
ES: Camina y acumula SHARE

[launch.intro.body.10]
KO: +100원
ES: +100 wones

[launch.intro.body.11]
KO: 회사(운영자) 자금으로 기부 예정 · 내가 내는 돈은 없어요 · 내 기여는 앱에서 확인
ES: Prevista con fondos de la empresa (operador) · Sin costo alguno para ti · Consulta tu contribución en la app

[launch.intro.body.13]
KO: 지금
달팽이
ES: Actualmente
Caracol

[launch.intro.body.14]
KO: 등급을
받으면
ES: Al recibir
calificación

[launch.intro.body.15]
KO: 티어가
오르면
ES: Al subir
de nivel

[launch.intro.body.2]
KO: 한 걸음이 나눔이 된다
ES: Cada paso se convierte en ayuda

[launch.intro.body.3]
KO: 내 기록은 어느 폰에서나 그대로예요
ES: Tus registros se mantienen en cualquier teléfono

[launch.intro.body.4]
KO: 100걸음마다 10 SHARE를 받아요. 모은 SHARE로 대회에 참가할 수 있어요.
ES: Recibe 10 SHARE cada 100 pasos. Puedes usar los SHARE acumulados para participar en competencias.

[launch.intro.body.5]
KO: SHARE는 현금으로 바꿀 수 없는 활동 보상이고, 하루에 받을 수 있는 양에 한도가 있어요.
ES: SHARE es una recompensa por actividad que no se puede canjear por efectivo, y existe un límite en la cantidad que puedes recibir por día.

[launch.intro.body.6]
KO: 검증된 모든 달리기, 1km마다 운영자가 100원을 기부할 예정이에요. 내가 보탠 만큼은 앱에서 확인할 수 있어요.
ES: Por cada carrera verificada, el operador planea donar 100 wones por cada 1 km. Puedes consultar tu contribución en la app.

[launch.intro.body.7]
KO: 운영자의 월 기부 예산 안에서 진행될 예정이에요. 예산을 다 쓴 달은 넘는 거리가 기록으로 남아요.
ES: Está previsto hacerlo dentro del presupuesto mensual de donaciones del operador. Si el presupuesto se agota en el mes, la distancia excedente quedará registrada.

[launch.intro.body.8]
KO: 걷기·달리기 기록은 서버에 저장돼요. 폰을 바꿔도 로그인하면 이어져요.
ES: Los registros de caminata y carrera se guardan en el servidor. Aunque cambies de teléfono, puedes continuar iniciando sesión.

[launch.intro.body.9]
KO: 100걸음
ES: 100 pasos

[launch.intro.button]
KO: 시작하기
ES: Empezar

[launch.intro.button.2]
KO: 이미 계정이 있어요 · 로그인
ES: Ya tengo una cuenta · Iniciar sesión

[legal.health_data_consent.body]
KO: 체크해야 워치 연동·심박 검증이 활성화됩니다.
ES: Debes marcar esta casilla para activar la sincronización con el reloj y la verificación de frecuencia cardíaca.

[legal_constants.body]
KO: 결제 취소 (현금 환불)
ES: Cancelar pago (reembolso en efectivo)

[legal_constants.body.10]
KO: 마케팅·활동 알림 (선택)
ES: Notificaciones de marketing y actividades (Opcional)

[legal_constants.body.12]
KO: 부정 러닝·결제 어뷰징은 계정 제한 대상이 될 수 있습니다.
ES: Las carreras fraudulentas y el abuso de pagos pueden estar sujetos a restricciones de cuenta.

[legal_constants.body.14]
KO: 전체 내용은 개인정보 처리방침 전문에서 확인할 수 있습니다.
ES: Puede consultar todos los detalles en el texto completo de la política de privacidad.

[legal_constants.body.17]
KO: 대회 모집, 검증 결과, 리워드·기부 알림을 푸시로 받을 수 있습니다. 언제든 MyPage에서 변경할 수 있습니다.
ES: Puede recibir notificaciones push sobre convocatorias de competencias, resultados de verificación, recompensas y donaciones. Puede cambiarlas en cualquier momento en MyPage.

[legal_constants.body.18]
KO: 심박수·케이던스 원본 데이터는 기기 메모리에서 검증한 뒤 바로 폐기하며, 검증 결과 요약만 저장합니다.
ES: Los datos originales de frecuencia cardíaca y cadencia se descartan inmediatamente después de la verificación en la memoria del dispositivo y solo se almacena un resumen de los resultados de la verificación.

[legal_constants.body.19]
KO: 건강 정보 안내
ES: Aviso de información de salud

[legal_constants.body.2]
KO: [선택] 건강정보(심박수) 수집 및 이용 동의
ES: [Opcional] Consentimiento para recopilación y uso de información de salud (frecuencia cardíaca)

[legal_constants.body.21]
KO: 가슴 통증, 어지러움 등 이상이 느껴지면 즉시 운동을 멈추고 의료진과 상담하세요.
ES: Si siente dolor en el pecho, mareos o cualquier anomalía, detenga el ejercicio de inmediato y consulte a un médico.

[legal_constants.body.23]
KO: 언제든 해지할 수 있으며, 해지해도 이미 결제한 기간이 끝날 때까지 이용할 수 있습니다.
ES: Puedes cancelar en cualquier momento y seguirás teniendo acceso hasta el final del período ya pagado.

[legal_constants.body.3]
KO: 건강정보 수집 동의 (선택 · 별도)
ES: Consentimiento para recopilar información de salud (opcional · separado)

[legal_constants.body.4]
KO: 개인정보 처리방침 전문 보기
ES: Ver política de privacidad completa

[legal_constants.body.5]
KO: 서비스 이용약관 전문 보기
ES: Ver términos del servicio completos

[legal_constants.body.6]
KO: AI 생성 이미지 안내
ES: Aviso sobre imágenes generadas por IA

[legal_constants.body.7]
KO: 일부 그림은 AI로 생성되었습니다. Created with Grok
ES: Algunas imágenes fueron generadas por IA. Created with Grok

[legal_constants.body.8]
KO: 서비스 이용약관 (필수)
ES: Términos del servicio (Obligatorio)

[legal_constants.body.9]
KO: 개인정보 처리방침 (필수)
ES: Política de privacidad (Obligatorio)

[app.levelTestChallengeProgress]
KO: 챌린지 진행 상황: 2/3회 완료 (3.52/5.00 KM)
ES: Progreso del desafío: 2/3 completadas (3.52/5.00 KM)

[app.levelTestGhostPace]
KO: [고스트 페이스]
ES: [Ritmo fantasma]

[app.levelTestMyLocation]
KO: [나(현재 위치)]
ES: [Yo (Ubicación actual)]

[app.levelTestStartRun]
KO: 3회차 달리기 시작하기
ES: Iniciar 3.ª carrera

[app.levelTestStatDistance]
KO: 현재 거리
ES: Distancia actual

[app.levelTestStatPace]
KO: 현재 페이스
ES: Ritmo actual

[app.levelTestStatTime]
KO: 경과 시간
ES: Tiempo transcurrido

[app.levelTestSubtitle]
KO: 검증된 달리기를 서로 다른 날 3번 마치면 등급이 배정됩니다.
ES: Complete 3 carreras verificadas en días diferentes para obtener su nivel.

[app.levelTestTitle]
KO: 혼자 뛰기 챌린지 (등급 배정)
ES: Desafío de carrera individual (Clasificación)

[app.liveRunningEffortTip]
KO: 순수 노력 목표: 완주 시 VALUE +$valueTokens
ES: Objetivo de puro esfuerzo: VALUE +$valueTokens al completar

[app.liveRunningFinish]
KO: 종료 / 저장
ES: Finalizar / Guardar

[app.liveRunningGhostPace]
KO: 고스트 페이스
ES: Ritmo fantasma

[app.liveRunningRoomTitle]
KO: 3km 중급 챌린지
ES: Desafío de 3 km intermedio

[app.liveRunningSubmissionsLeft]
KO: 제출 기회: 2/3회 남음
ES: Intentos de envío: 2/3 restantes

[app.liveRunningYouLabel]
KO: 나 (You)
ES: Tú (You)

[app.runValidationFailed]
KO: 기록 검증에 실패했습니다. 보상이 지급되지 않았습니다.
ES: Error en la verificación del registro. No se otorgó ninguna recompensa.

[live_running.body]
KO: 1km 초보 챌린지
ES: Desafío de 1 km para principiantes

[live_running.body.2]
KO: 나
ES: Yo

[live_running.body.3]
KO: 고스트
ES: Fantasma

[live_running.body.4]
KO: 검증 중
ES: Verificando

[live_running.toast]
KO: 센서 시작 실패: $error
ES: Error al iniciar el sensor: $error

[app.existingAccountApple]
KO: 애플로 가입했어요
ES: Me registré con Apple

[app.existingAccountBody]
KO: 그 방법으로 로그인하면 지금 $provider${subjectParticle(provider)} 그 계정에 연결돼요. 닉네임과 재화도 그대로예요.
ES: Si inicias sesión con ese método, tu $provider${subjectParticle(provider)} actual se vinculará a esa cuenta. Tu apodo y tus monedas se mantendrán iguales.

[app.existingAccountCreate]
KO: 새로 시작하기
ES: Comenzar de nuevo

[app.existingAccountCreateHint]
KO: 기억나지 않거나 처음이신가요?
ES: ¿No te acuerdas o es tu primera vez?

[app.existingAccountGoogle]
KO: 구글로 가입했어요
ES: Me registré con Google

[app.existingAccountKakao]
KO: 카카오로 가입했어요
ES: Me registré con Kakao

[app.existingAccountNaver]
KO: 네이버로 가입했어요
ES: Me registré con Naver

[app.existingAccountNotFound]
KO: 그 방법으로 가입된 계정이 없어요. 다른 방법을 골라 주세요.
ES: No se encontró ninguna cuenta con ese método. Elige otro método.

[app.existingAccountTitle]
KO: 처음 가입할 때 어떤 방법을 쓰셨나요?
ES: ¿Qué método utilizaste cuando te registraste por primera vez?

[app.linkAttached]
KO: $method${subjectParticle(method)} 연결됐어요. 이제 어느 쪽으로 들어와도 같은 계정이에요.
ES: $method${subjectParticle(method)} se ha vinculado. Ahora accederás a la misma cuenta de cualquier forma.

[app.linkConfirmNo]
KO: 아니에요, 다시 고를게요
ES: No, elegir de nuevo

[app.linkConfirmTitle]
KO: 이 계정에 $method${objectParticle(method)} 연결할까요?
ES: ¿Vincular $method${objectParticle(method)} a esta cuenta?

[app.linkConfirmYes]
KO: 네, 연결할게요
ES: Sí, vincular

[app.loginComingSoon]
KO: $provider 로그인은 준비 중입니다.
ES: El inicio de sesión con $provider estará disponible pronto.

[app.loginGoogle]
KO: Google로 계속하기
ES: Continuar con Google

[app.loginGuest]
KO: 게스트(테스트)로 시작하기
ES: Comenzar como invitado (prueba)

[app.loginGuestLoading]
KO: 게스트 로그인 중...
ES: Iniciando sesión como invitado...

[app.loginGuestNote]
KO: 게스트 모드는 워치 연동·Health Connect 테스트용 임시 계정입니다.
ES: El modo invitado es una cuenta temporal para probar la sincronización con el reloj y Health Connect.

[app.loginKakao]
KO: Kakao로 계속하기
ES: Continuar con Kakao

[app.loginNaver]
KO: Naver로 계속하기
ES: Continuar con Naver

[app.loginReferralHint]
KO: 추천 코드를 입력하세요...
ES: Introduce tu código de referido...

[app.loginReferralLabel]
KO: 추천 코드가 있으신가요?
ES: ¿Tienes un código de referido?

[app.loginSaveFailed]
KO: 로그인 저장 실패: $error
ES: Error al guardar el inicio de sesión: $error

[app.loginSubtitle]
KO: 세계를 향한 나눔의 질주
ES: Una carrera de compartir hacia el mundo

[app.referralRedeemAlready]
KO: 이미 초대 코드를 입력했어요
ES: Ya has ingresado un código de invitación

[app.referralRedeemDone]
KO: 초대한 친구: 입력 완료
ES: Amigo invitado: Completado

[app.referralRedeemEntry]
KO: 초대 코드 입력
ES: Ingresar código de invitación

[app.referralRedeemExpired]
KO: 가입 후 7일이 지나 입력할 수 없어요
ES: No se puede ingresar porque han pasado 7 días desde el registro

[app.referralRedeemFailed]
KO: 초대 코드를 등록하지 못했어요
ES: No se pudo registrar el código de invitación

[app.referralRedeemInvalid]
KO: 없는 초대 코드예요
ES: Este código de invitación no existe

[app.referralRedeemSelf]
KO: 본인 코드는 입력할 수 없어요
ES: No puedes ingresar tu propio código

[app.referralRedeemSubmit]
KO: 등록
ES: Registrar

[app.referralRedeemSuccess]
KO: 10,000 SHARE 지급
ES: 10,000 SHARE otorgados

[login.body]
KO: 구글 로그인에 성공했습니다!
ES: ¡Inicio de sesión en Google con éxito!

[login.body.2]
KO: 로그인 실패:
ES: Error al iniciar sesión:

[login.body.3]
KO: 애플 로그인에 성공했습니다!
ES: ¡Inicio de sesión en Apple con éxito!

[login.body.4]
KO: 애플 로그인 실패:
ES: Error al iniciar sesión con Apple:

[login.body.5]
KO: 네이버 로그인에 성공했습니다!
ES: ¡Inicio de sesión en Naver con éxito!

[login.body.6]
KO: 네이버 로그인 실패:
ES: Error al iniciar sesión con Naver:

[login.body.7]
KO: 카카오 로그인에 성공했습니다!
ES: ¡Inicio de sesión en Kakao con éxito!

[login.body.8]
KO: 카카오 로그인 실패:
ES: Error al iniciar sesión con Kakao:

[login.body.9]
KO: 닉네임 $nickname
SHARE ${groupedDigits(shareBalance)}
ES: Apodo $nickname
SHARE ${groupedDigits(shareBalance)}

[login.button]
KO: 초대 코드가 있으신가요?
ES: ¿Tienes un código de invitación?

[login_connections.body]
KO: $name 연결을 해제했어요.
ES: Se ha desconectado $name.

[login_connections.body.2]
KO: 카카오
ES: Kakao

[login_connections.body.3]
KO: 네이버
ES: Naver

[login_connections.body.4]
KO: 애플
ES: Apple

[login_connections.body.5]
KO: 구글
ES: Google

[login_connections.body.6]
KO: 같은 계정으로 여러 방법으로 로그인할 수 있어요. 연결해 두면 어떤 방법으로 들어와도 같은 SHARE와 기록이 보여요. 마지막 로그인 방법은 해제할 수 없어요.
ES: Puede iniciar sesión con varios métodos para la misma cuenta. Si los vincula, verá el mismo saldo de SHARE y registros sin importar el método. No se puede desconectar el último método de inicio de sesión.

[login_connections.body.7]
KO: 연결 안 됨
ES: No conectado

[login_connections.button]
KO: 해제하면 이 $name 계정으로는 이 쉐어런 계정에 들어올 수 없어요. 다른 로그인 방법으로는 계속 쓸 수 있어요.
ES: Si se desconecta, no podrá acceder a esta cuenta de ShareRun con esta cuenta de $name. Podrá seguir usando otros métodos de inicio de sesión.

[login_connections.button.2]
KO: 다시 불러오기
ES: Recargar

[login_connections.button.3]
KO: 연결하기
ES: Conectar

[login_connections.dialog]
KO: $name 연결 해제
ES: Desconectar $name

[login_devices.body]
KO: 이 계정으로 앱을 연 기기예요. 기기 이름과 마지막으로 연 시각만 저장하고, 위치나 IP 주소는 저장하지 않아요.
ES: Dispositivos que abrieron la app con esta cuenta. Solo se guardan el nombre del dispositivo y la última hora de acceso; no la ubicación ni la dirección IP.

[login_devices.body.2]
KO: 앱 데이터를 지우거나 다시 설치하면 같은 폰이 한 줄 더 보일 수 있어요.
ES: Borrar los datos de la app o reinstalarla puede hacer que aparezca otra línea para el mismo teléfono.

[login_devices.body.3]
KO: 아직 기록된 기기가 없어요.
ES: Aún no hay dispositivos registrados.

[login_devices.body.4]
KO: 알 수 없는 기기
ES: Dispositivo desconocido

[login_devices.body.5]
KO: $name (이 기기)
ES: $name (Este dispositivo)

[login_devices.body.6]
KO: $name · 새 기기
ES: $name · Nuevo dispositivo

[login_devices.body.7]
KO: ${device.osVersion} · 앱 ${device.appVersion}
마지막으로 연 시각 $when
ES: ${device.osVersion} · App ${device.appVersion}
Último acceso $when

[login_devices.button]
KO: 이 폰을 포함해 로그인된 모든 기기에서 로그아웃돼요. 다른 기기는 잠시 뒤 로그인 화면으로 돌아가요. 계속할까요?
ES: Cerrarás sesión en todos los dispositivos, incluido este teléfono. Otros dispositivos volverán a la pantalla de inicio pronto. ¿Continuar?

[login_devices.dialog]
KO: 모든 기기에서 로그아웃
ES: Cerrar sesión en todos los dispositivos

[login_devices.toast]
KO: 로그아웃하지 못했어요. 잠시 후 다시 시도해 주세요.
ES: No se pudo cerrar sesión. Inténtalo de nuevo más tarde.

[app.dashboardChallenge1Sub]
KO: 참가비: 600 SHARE
ES: Cuota de inscripción: 600 SHARE

[app.dashboardChallenge1Title]
KO: 초보 1km 챌린지 🏆
ES: Desafío de 1 km para principiantes 🏆

[app.dashboardChallenge2Sub]
KO: 참가비: 1,200 SHARE
ES: Cuota de inscripción: 1,200 SHARE

[app.dashboardChallenge2Title]
KO: 중급 3km 챌린지 (골드 대회)
ES: Desafío de 3 km intermedio (competición Oro)

[app.dashboardDailyMissionCapsule]
KO: 📍 오늘의 미션 확인하기 >
ES: 📍 Ver misiones de hoy >

[app.dashboardDiamondBalance]
KO: 💎 보유 다이아몬드: 5개
ES: 💎 DIA en posesión: 5

[app.dashboardDiamondBalanceOf]
KO: 💎 보유 다이아몬드: $count개
ES: 💎 DIA en posesión: $count

[app.dashboardGradeRunLabel]
KO: 등급 배정 달리기:
ES: Carrera de asignación de nivel:

[app.dashboardGradeRunProgress]
KO: 2/3회 완료 >
ES: 2/3 completadas >

[app.dashboardOngoingChallenges]
KO: 진행 중인 챌린지
ES: Desafíos en curso

[app.dashboardShareBalance]
KO: 보유 SHARE: 90,000
ES: SHARE en posesión: 90,000

[app.dashboardShareBalanceOf]
KO: 보유 SHARE: $amount
ES: SHARE en posesión: $amount

[app.dashboardStampMapTooltip]
KO: 오늘의 미션 · 스탬프 투어
ES: Misiones de hoy · Ruta de sellos

[app.dashboardValueBalance]
KO: 🌱 보유 밸류(VALUE): 5,200
ES: 🌱 VALUE en posesión: 5,200

[app.dashboardValueBalanceOf]
KO: 🌱 보유 밸류(VALUE): $amount
ES: 🌱 VALUE en posesión: $amount

[app.dashboardViewRoom]
KO: 대회 상세 보기
ES: Ver detalles de la competición

[app.exitGuardMessage]
KO: 나눔의 질주를 잠시 쉬어가시겠습니까? 한 번 더 누르시면 종료됩니다.
ES: ¿Desea tomar un descanso de la carrera de compartir? Presione de nuevo para salir.

[app.myWalletCharge]
KO: 교환하기
ES: Canjear

[app.myWalletChargeDia]
KO: 다이아몬드
ES: DIA

[app.myWalletChargeDiaHint]
KO: 교환소에서 SHARE로 바꾸거나 연속 달리기로 모을 수 있어요
ES: Puedes cambiarlo por SHARE en el intercambio o acumularlo con rachas de carrera.

[app.myWalletChargeShareHint]
KO: 활동으로 모을 수 있어요
ES: Puedes acumularlo a través de actividades.

[app.myWalletChargeValue]
KO: 밸류(VALUE)
ES: VALUE

[app.myWalletChargeValueHint]
KO: 달리기로 모을 수 있어요
ES: Puedes acumularlo corriendo.

[app.myWalletDiamondLabel]
KO: 보유 다이아몬드: $count개
ES: DIA en posesión: $count

[app.myWalletGradeProgress]
KO: 등급 배정 달리기: $done/$total회 완료 >
ES: Carrera de clasificación: $done/$total completadas >

[app.myWalletInventoryCount]
KO: 보유 $count
ES: En posesión: $count

[app.myWalletInventoryEmpty]
KO: 아직 보유한 아이템이 없습니다.
ES: Aún no tienes ningún artículo.

[app.myWalletInventoryOpen]
KO: 보관함 보기
ES: Ver inventario

[app.myWalletInventoryTitle]
KO: 보유 아이템
ES: Objetos en posesión

[app.myWalletItemDuringRun]
KO: 달리기 중 사용 가능
ES: Disponible durante la carrera

[app.myWalletItemDuringTournament]
KO: 대회에서 사용 가능
ES: Disponible en competiciones

[app.myWalletRecentTransactions]
KO: 최근 거래 내역
ES: Transacciones recientes

[app.myWalletUse]
KO: 상점 가기
ES: Ir a la tienda

[app.myWalletValueLabel]
KO: 보유 밸류(VALUE): $amount
ES: VALUE en posesión: $amount

[app.walletUnconfirmedNote]
KO: 서버에서 확인하는 중이에요. 지금 보이는 값은 마지막으로 확인된 값이에요.
ES: Comprobando con el servidor. El valor mostrado es el último confirmado.

[main_dashboard.body]
KO: 상품은 다이아예요 · ${AppStrings.noCashPrizePool}
ES: Los premios son DIA · ${AppStrings.noCashPrizePool}

[main_dashboard.body.2]
KO: 좋은 아침이에요
ES: Buenos días

[main_dashboard.body.3]
KO: 좋은 오후예요
ES: Buenas tardes

[main_dashboard.body.4]
KO: 좋은 저녁이에요
ES: Buenas noches

[main_dashboard.body.5]
KO: ${_hello(DateTime.now().hour)}, $nickname님
ES: ${_hello(DateTime.now().hour)}, $nickname

[main_shell_routes.body]
KO: 결제 정보가 없어 PG 화면을 열 수 없습니다.
ES: No se puede abrir la pantalla de pago porque falta la información de pago.

[main_shell_routes.body.2]
KO: 대회 정보가 없어 스폰서 결제를 열 수 없습니다.
ES: No se puede abrir el pago de patrocinador porque falta la información de la competición.

[main_shell_routes.button]
KO: 대회 목록으로
ES: Ir a competiciones

[map_crew.body]
KO: 지도 & 크루
ES: Mapa y crew

[map_crew.body.2]
KO: 크루 종합 랭킹
ES: Clasificación general de crew

[map_crew.body.3]
KO: ${crews[index].memberCount}명
ES: ${crews[index].memberCount} miembros

[map_crew.body.4]
KO: 아직 크루 순위가 없어요
ES: Aún no hay clasificaciones de crew

[map_crew.body.5]
KO: 크루 순위가 쌓이면 여기에 나타나요.
ES: Las clasificaciones de crew aparecerán aquí conforme se acumulen.

[map_crew.body.6]
KO: ${collectRadiusMeters.round()}m 안으로 가까이 가야 받을 수 있어요.
ES: Debe acercarse a menos de ${collectRadiusMeters.round()}m para reclamarlo.

[map_crew.body.7]
KO: +${box.rewardDiamond} DIA를 받았어요.
ES: Se recibieron +${box.rewardDiamond} DIA.

[map_crew.body.8]
KO: ${distanceMeters!.toStringAsFixed(0)}m 떨어져 있어요
ES: A ${distanceMeters!.toStringAsFixed(0)}m de distancia

[map_crew.button]
KO: 내 위치 새로고침
ES: Actualizar ubicación

[map_crew.button.2]
KO: 다이아 상자 받기
ES: Reclamar caja DIA

[map_crew.button.3]
KO: 더 가까이 가 주세요
ES: Acérquese más

[map_crew.crew_member_ranking_board.body]
KO: 크루원 랭킹 데이터 없음
ES: Sin datos de clasificación de miembros del crew

[map_crew.crew_member_ranking_board.body.2]
KO: 출석률·평균 페이스가 여기에 표시됩니다.
ES: La tasa de asistencia y el ritmo promedio se mostrarán aquí.
