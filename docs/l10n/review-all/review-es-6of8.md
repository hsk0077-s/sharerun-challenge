# 번역 검수 요청 — 쉐어런 (Spanish) · 파트 6/8

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
[run_result.run_finish_share.body.15]
KO: 이번 달리기로 운영자가 ${_grouped(won)}원을 기부할 예정이에요
ES: Con esta carrera, el operador planea donar ${_grouped(won)} KRW

[run_result.run_finish_share.body.16]
KO: 오늘은 기부 인정 10km를 모두 채웠어요. 넘는 거리는 기록으로 남아요.
ES: Hoy ha completado los 10 km reconocidos para donación. La distancia que exceda se guardará como récord.

[run_result.run_finish_share.body.17]
KO: 기부 참여 기록
ES: Registro de participación en donaciones

[run_result.run_finish_share.body.18]
KO: 이번 달리기는 기부에 포함되지 않았어요.
ES: Esta carrera no se incluyó en la donación.

[run_result.run_finish_share.body.19]
KO: 쉐어런 앱에서 ${distanceKm}km를 달렸어요. ⏱ 기록: $time
ES: Corrí ${distanceKm} km en la app ShareRun. ⏱ Tiempo: $time

[run_result.run_finish_share.body.2]
KO: 블루
ES: Azul

[run_result.run_finish_share.body.20]
KO: 오늘의 러닝
ES: Carrera de hoy

[run_result.run_finish_share.body.21]
KO: 평균 심박 $averageHeartRate bpm
ES: Frecuencia cardíaca media $averageHeartRate bpm

[run_result.run_finish_share.body.22]
KO: 구간 페이스
ES: Ritmo de segmento

[run_result.run_finish_share.body.23]
KO: 시간
ES: Tiempo

[run_result.run_finish_share.body.24]
KO: 페이스
ES: Ritmo

[run_result.run_finish_share.body.3]
KO: 핑크
ES: Rosa

[run_result.run_finish_share.body.4]
KO: 옐로
ES: Amarillo

[run_result.run_finish_share.body.5]
KO: 민트
ES: Menta

[run_result.run_finish_share.body.6]
KO: 내 사진
ES: Mi foto

[run_result.run_finish_share.body.7]
KO: 월요일
ES: Lunes

[run_result.run_finish_share.body.8]
KO: 화요일
ES: Martes

[run_result.run_finish_share.body.9]
KO: 수요일
ES: Miércoles

[run_result.run_finish_share_flow.body]
KO: 하나만 올리기
ES: Publicar solo una

[run_result.run_finish_share_flow.body.2]
KO: 여러 개 순서대로 올리기
ES: Publicar varias en orden

[run_result.run_finish_share_flow.body.3]
KO: 순서대로 공유
ES: Compartir en orden

[run_result.run_finish_share_flow.body.4]
KO: 그만하기
ES: Detener

[run_result.run_finish_share_flow.body.5]
KO: 어떻게 올릴까요?
ES: ¿Cómo desea publicar?

[run_result.run_finish_share_flow.body.6]
KO: 어디에 올릴까요?
ES: ¿Dónde desea publicar?

[run_result.run_finish_share_flow.body.7]
KO: 순서대로 올리기
ES: Publicar en orden

[run_result.run_finish_share_flow.body.8]
KO: 다음: $label
ES: Siguiente: $label

[run_result.run_finish_share_targets.body]
KO: Instagram 스토리
ES: Historias de Instagram

[run_result.run_finish_share_targets.body.2]
KO: Instagram 피드
ES: Feed de Instagram

[run_result.run_finish_share_targets.body.3]
KO: 더보기
ES: Más

[run_tracking.body]
KO: 심박 ${telemetry.currentHeartRate?.toString() ??
ES: Ritmo cardíaco ${telemetry.currentHeartRate?.toString() ??

[run_tracking.body.2]
KO: } BPM / 케이던스 ${telemetry.currentCadenceSpm?.toString() ??
ES: } BPM / Cadencia ${telemetry.currentCadenceSpm?.toString() ??

[run_tracking.body.3]
KO: 자이로 안정도 ${telemetry.gyroStabilityScore.toStringAsFixed(2)}
ES: Estabilidad de giroscopio ${telemetry.gyroStabilityScore.toStringAsFixed(2)}

[run_tracking.body.4]
KO: 센서를 시작하는 중...
ES: Iniciando sensor...

[run_tracking.body.5]
KO: 러닝 검증 중...
ES: Verificando carrera...

[run_tracking.body.6]
KO: 러닝 끝내고 검증하기
ES: Finalizar carrera y verificar

[run_tracking.body.7]
KO: MyPage에서 [선택] 민감정보 수집 동의 후 러닝 검증을 시작할 수 있습니다.
ES: Puede iniciar la verificación de carrera tras aceptar la recopilación [Opcional] de información sensible en MyPage.

[run_tracking.body.8]
KO: 센서를 시작하지 못했어요: $error
ES: No se pudieron iniciar los sensores: $error

[run_tracking.title]
KO: 달리기 기록
ES: Registro de carrera

[run_tracking.toast]
KO: 러닝 검증에 실패했어요: ${ApiErrorMessage.from(error)}
ES: Error en la verificación de carrera: ${ApiErrorMessage.from(error)}

[run_tracking.ble_heart_rate_service.body]
KO: BLE 심박 센서 (${map[
ES: Sensor de frecuencia cardíaca BLE (${map[

[run_tracking.ble_heart_rate_service.body.2]
KO: 이 기기에서는 블루투스 심박 스캔을 지원하지 않습니다.
ES: Este dispositivo no admite el escaneo de frecuencia cardíaca por Bluetooth.

[run_tracking.ble_heart_rate_service.body.3]
KO: 블루투스 권한 또는 상태를 확인해 주세요.
ES: Comprueba el permiso o el estado de Bluetooth.

[run_tracking.ble_heart_rate_service.body.4]
KO: 이 기기에서는 블루투스 심박 연결을 지원하지 않습니다.
ES: Este dispositivo no admite la conexión de frecuencia cardíaca por Bluetooth.

[run_tracking.ble_heart_rate_service.body.5]
KO: 센서 연결에 실패했습니다.
ES: Error al conectar el sensor.

[run_tracking.gps_tracking_service.body]
KO: 실시간 러닝 GPS 추적 중
ES: Seguimiento GPS de carrera en tiempo real en curso

[run_tracking.home_start_gate.body]
KO: 마이페이지에서 민감정보 수집에 동의해주세요
ES: Acepta la recopilación de datos confidenciales en Mi página.

[run_tracking.home_start_gate.body.2]
KO: 로그인 후 러닝 검증을 진행할 수 있습니다.
ES: Puedes proceder con la verificación de carrera después de iniciar sesión.

[run_tracking.home_start_gate.body.3]
KO: 러닝이 시작되지 않았습니다.
ES: La carrera no ha comenzado.

[run_tracking.music_controls.body]
KO: 음악을 조절하지 못했어요.
ES: No se pudo controlar la música.

[run_tracking.music_controls.body.2]
KO: 재생 / 일시정지
ES: Reproducir / Pausar

[run_tracking.music_controls.body.3]
KO: 다음 곡
ES: Pista siguiente

[run_tracking.music_controls.body.4]
KO: 음악 앱 열기
ES: Abrir app de música

[run_tracking.music_controls.body.5]
KO: 음악 앱을 찾지 못했어요. 쓰는 음악 앱을 직접 열어 주세요.
ES: No se encontró ninguna app de música. Abre tu app de música directamente.

[run_tracking.music_controls.button]
KO: 이전 곡
ES: Pista anterior

[run_tracking.run_recording_checklist.body]
KO: 화면을 끄거나 다른 앱을 켜도 경로 기록과 음성 코칭이 이어지도록 아래 항목을 확인해 주세요.
ES: Verifique los siguientes elementos para que la grabación de ruta y el entrenamiento por voz continúen incluso con la pantalla apagada o al usar otra app.

[run_tracking.run_recording_checklist.body.10]
KO: 허용하지 않아도 달리기는 시작할 수 있습니다.
ES: Puedes empezar a correr incluso sin permitirlo.

[run_tracking.run_recording_checklist.body.11]
KO: 항목을 나중에 바꿔도 됩니다.
ES: Puedes cambiar estos ajustes más tarde.

[run_tracking.run_recording_checklist.body.12]
KO: 필요
ES: Requerido

[run_tracking.run_recording_checklist.body.2]
KO: 위치 권한
ES: Permiso de ubicación

[run_tracking.run_recording_checklist.body.3]
KO: 앱을 사용하는 동안 허용해 주세요. 항상 허용은 요청하지 않습니다.
ES: Permite el acceso mientras usas la app. No solicitamos "Permitir siempre".

[run_tracking.run_recording_checklist.body.4]
KO: 허용됨
ES: Permitido

[run_tracking.run_recording_checklist.body.5]
KO: 허용하기
ES: Permitir

[run_tracking.run_recording_checklist.body.6]
KO: 알림 권한
ES: Permiso de notificaciones

[run_tracking.run_recording_checklist.body.7]
KO: 달리기 기록 알림을 표시합니다. Android 13 이상에서 필요합니다.
ES: Muestra notificaciones del registro de carrera. Requerido en Android 13 o superior.

[run_tracking.run_recording_checklist.body.8]
KO: 배터리 최적화
ES: Optimización de batería

[run_tracking.run_recording_checklist.body.9]
KO: 설정됨
ES: Configurado

[run_tracking.run_recording_checklist.button]
KO: 확인하고 달리기
ES: Confirmar y correr

[run_tracking.run_recording_checklist.title]
KO: 달리기 기록 설정
ES: Ajustes de registro de carrera

[run_tracking.run_recording_checklist.toast]
KO: 배터리 설정 화면을 열지 못했습니다.
ES: No se pudo abrir la pantalla de ajustes de batería.

[run_tracking.run_recording_foreground.body]
KO: 화면이 꺼져도 달리기 경로와 음성 코칭을 이어갑니다.
ES: Continúa registrando la ruta y el entrenamiento por voz incluso con la pantalla apagada.

[run_tracking.run_recording_policy.body]
KO: 쉐어런 · 달리기 기록 중
ES: ShareRun · Registrando carrera

[run_tracking.run_recording_policy.body.2]
KO: 이전 달리기가 중단되었습니다
ES: La carrera anterior se interrumpió

[run_tracking.run_recording_policy.body.3]
KO: 앱이 중간에 종료되어 직전 달리기는 저장되지 않았습니다. 보상은 지급되지 않고, 기록도 남지 않습니다.
ES: La app se cerró inesperadamente, por lo que tu carrera anterior no se guardó. No se otorgan recompensas ni se guarda el registro.

[run_tracking.run_recording_policy.body.4]
KO: 화면이 꺼지면 달리기 기록이 중단될 수 있습니다.
ES: El registro de carrera puede interrumpirse si la pantalla se apaga.

[run_tracking.run_recording_policy.body.5]
KO: 달리기 기록 설정 점검
ES: Comprobar ajustes de registro de carrera

[run_tracking.run_recording_policy.body.6]
KO: 시스템 배터리 최적화 화면에서 쉐어런을 찾아 주세요. 삼성 갤럭시는 '제한 없음'으로 바꿔 주세요.
ES: Busca ShareRun en la pantalla de optimización de batería del sistema. En Samsung Galaxy, cámbialo a "Sin restricciones".

[run_tracking.run_session_service.body]
KO: 위치 서비스가 꺼져 있습니다.
ES: Los servicios de ubicación están desactivados.

[run_tracking.run_session_service.body.2]
KO: 위치 권한이 영구 거부되었습니다. 설정에서 허용해 주세요.
ES: El permiso de ubicación fue denegado permanentemente. Permítelo en ajustes.

[run_tracking.run_session_service.body.3]
KO: 위치 권한이 허용되었습니다.
ES: Permiso de ubicación concedido.

[run_tracking.run_start_preflight.button]
KO: 심박수·케이던스 검증을 위해 [선택] 건강정보 수집 동의가 필요합니다. 일반 이용약관과 별도로 Opt-in 해 주세요.
ES: Se requiere el consentimiento de [Opcional] recopilación de datos de salud para verificar la frecuencia cardíaca y la cadencia. Por favor, acepte por separado de los términos generales.

[run_tracking.run_start_preflight.button.2]
KO: 동의 화면으로
ES: Ir a pantalla de consentimiento

[run_tracking.run_start_preflight.dialog]
KO: 건강정보 동의 필요
ES: Se requiere consentimiento de datos de salud

[run_tracking.run_start_preflight.toast]
KO: 로그인 후 러닝을 시작할 수 있습니다.
ES: Puedes iniciar la carrera después de iniciar sesión.

[run_tracking.sponsor_live_buff_banner.body]
KO: 스폰서 라이브 버프
ES: Buff en vivo de patrocinador

[run_tracking.watch_runtime_permissions_service.body]
KO: Health Connect 앱 설치
ES: Instalar app Health Connect

[run_tracking.watch_runtime_permissions_service.body.2]
KO: Health Connect 건강 데이터
ES: Datos de salud de Health Connect

[run_tracking.watch_runtime_permissions_service.body.3]
KO: 신체 활동 인식
ES: Reconocimiento de actividad física

[app.runningCrewCreateButton]
KO: [50 DIA 또는 30,000 SHARE로 새 크루 창설하기]
ES: [Crear nuevo crew con 50 DIA o 30,000 SHARE]

[app.runningCrewEnterRoom]
KO: 크루 룸 입장하기
ES: Entrar a la sala de crew

[app.runningCrewHeadline]
KO: 같이 달릴
크루 찾기
ES: Encuentra un crew
para correr juntos

[app.runningCrewMyCrewName]
KO: 인천 논현 최강 크루
ES: Crew más fuerte de Incheon Nonhyeon

[app.runningCrewMyCrewStats]
KO: 소속 크루원: 45/50명 | 누적 달성 거리: 3,240km
ES: Miembros del crew: 45/50 | Distancia acumulada: 3,240 km

[app.runningCrewNoCrewHint]
KO: 크루에 들어가면 함께 달린 거리를 모아 월간 순위에 도전할 수 있어요. 크루를 만들거나 아래에서 찾아보세요.
ES: Únete a un crew para sumar la distancia recorrida juntos y competir en el ranking mensual. Crea un crew o busca uno abajo.

[app.runningCrewNoCrewName]
KO: 아직 크루가 없어요
ES: Aún no tienes un crew

[app.runningCrewProgressLabel]
KO: 이번 주 크루 대항전 10K 완주율
ES: Tasa de finalización de 10K en la batalla de crews de esta semana

[app.runningCrewTitle]
KO: 러닝 크루 (Crew)
ES: Running crew

[running_crew.body]
KO: 가입 신청
ES: Solicitud de ingreso

[running_crew.body.10]
KO: 크루는 두고 나만 나가고 싶다면 먼저 "크루원 보기"에서 크루장을 넘겨 주세요.
ES: Si quieres salir sin eliminar el crew, primero transfiere el liderazgo en "Ver miembros".

[running_crew.body.11]
KO: ${member.nickname}님에게 크루장을 넘길까요? 나는 부크루장이 되고, 원하면 그 뒤에 크루에서 나갈 수 있어요.
ES: ¿Transferir el liderazgo del crew a ${member.nickname}? Pasarás a ser sublíder y podrás salir del crew después si lo deseas.

[running_crew.body.12]
KO: 넘기기
ES: Transferir

[running_crew.body.13]
KO: 크루원
ES: Miembro del crew

[running_crew.body.14]
KO: 누적 거리
ES: Distancia total

[running_crew.body.15]
KO: 크루 관리
ES: Gestión de crew

[running_crew.body.16]
KO: 공지 · 크루원 · 혜택 선물
ES: Avisos · Miembros · Regalo de beneficios

[running_crew.body.17]
KO: 크루원 보기
ES: Ver miembros

[running_crew.body.18]
KO: ${mine.crew.memberCount}명 · 내 역할 ${_roleLabel(mine.role)}
ES: ${mine.crew.memberCount} miembros · Mi rol: ${_roleLabel(mine.role)}

[running_crew.body.19]
KO: 가입 신청 ${mine.pendingRequests}건
ES: ${mine.pendingRequests} solicitudes de unión

[running_crew.body.2]
KO: 크루 가입
ES: Unirse al crew

[running_crew.body.20]
KO: 받을지 정해요
ES: Decide si aceptar

[running_crew.body.21]
KO: 처음 한 번은 무료
ES: La primera vez es gratis

[running_crew.body.22]
KO: 지금은 승인 가입
ES: Actualmente con aprobación

[running_crew.body.23]
KO: 지금은 자유 가입
ES: Actualmente unión libre

[running_crew.body.24]
KO: 크루원과 함께 모두 나와요
ES: Todos los miembros saldrán juntos

[running_crew.body.25]
KO: 다시 가입할 수 있어요
ES: Puedes volver a unirte

[running_crew.body.26]
KO: 엠블럼 바꾸기
ES: Cambiar emblema

[running_crew.body.27]
KO: 틀 ${CrewEmblem.frames.length}가지 · 문양 ${CrewEmblem.glyphIds.length}가지 · 색 ${CrewEmblem.paletteColors.length}가지
ES: ${CrewEmblem.frames.length} marcos · ${CrewEmblem.glyphIds.length} símbolos · ${CrewEmblem.paletteColors.length} colores

[running_crew.body.28]
KO: 색 ${CrewEmblem.paletteColors.length}가지
ES: ${CrewEmblem.paletteColors.length} colores

[running_crew.body.29]
KO: 다른 크루 찾기
ES: Buscar otros crews

[running_crew.body.3]
KO: "${crew.name}" 크루는 크루장이 승인해야 들어갈 수 있어요. 신청할까요?
ES: Para unirte a "${crew.name}" se requiere la aprobación del líder. ¿Deseas solicitarlo?

[running_crew.body.30]
KO: 검색: "$_searchQuery"
ES: Buscar: "$_searchQuery"

[running_crew.body.31]
KO: 검색 결과가 없습니다.
ES: No se encontraron resultados de búsqueda.

[running_crew.body.32]
KO: 보유 SHARE ${_format(wallet.shareBalance)}
ES: SHARE en posesión: ${_format(wallet.shareBalance)}

[running_crew.body.33]
KO: 크루장
ES: Líder del crew

[running_crew.body.34]
KO: 부크루장
ES: Sublíder del crew

[running_crew.body.35]
KO: 명예의 전당
ES: Salón de la Fama

[running_crew.body.36]
KO: 역대 최고 ${ranking.bestRank}위
ES: Mejor puesto histórico: n.º ${ranking.bestRank}

[running_crew.body.37]
KO: 순위는 이번 달 크루 거리 ÷ 크루원 수예요. 달이 끝나면 확정돼요.
ES: La clasificación se calcula con la distancia del crew de este mes ÷ número de miembros. Se confirma al finalizar el mes.

[running_crew.body.38]
KO: 크루 이름 검색
ES: Buscar nombre del crew

[running_crew.body.39]
KO: 50 DIA 또는 30,000 SHARE
ES: 50 DIA o 30,000 SHARE

[running_crew.body.4]
KO: "${crew.name}" 크루에 가입할까요?
ES: ¿Quieres unirte al crew "${crew.name}"?

[running_crew.body.40]
KO: 아직 만들어진 크루가 없어요.
ES: Aún no se ha creado ningún crew.

[running_crew.body.41]
KO: 가입 불가
ES: No se puede unir

[running_crew.body.42]
KO: 가득 참
ES: Lleno

[running_crew.body.43]
KO: ${mine.crew.name} · ${mine.members.length}명
ES: ${mine.crew.name} · ${mine.members.length} miembros

[running_crew.body.44]
KO: 부크루장 해제
ES: Destituir sublíder

[running_crew.body.45]
KO: 부크루장으로
ES: Nombrar sublíder

[running_crew.body.46]
KO: 신고하기
ES: Reportar

[running_crew.body.47]
KO: 가입 신청 ${requests.length}건
ES: ${requests.length} solicitudes de unión

[running_crew.body.48]
KO: 기다리는 신청이 없어요.
ES: No hay solicitudes pendientes.

[running_crew.body.49]
KO: "${mine.crew.name}" 크루를 없애요.
크루장인 나도 함께 크루에서 나와요.
산 엠블럼도 사라지고 되돌릴 수 없어요.

$note
ES: Vas a eliminar el crew "${mine.crew.name}".
Yo, como líder, también saldré del crew.
El emblema comprado también desaparecerá y no se puede revertir.

$note

[running_crew.body.5]
KO: 신청
ES: Solicitar

[running_crew.body.6]
KO: "$name"(으)로 바꾸면 $cost DIA가 들어요. 보너스 DIA를 먼저 써요.
ES: Cambiar a "$name" cuesta $cost DIA. Se usará primero el DIA de bonificación.

[running_crew.body.7]
KO: 크루 없애기
ES: Eliminar crew

[running_crew.body.8]
KO: "${mine.crew.name}" 크루를 없애요.
${others > 0 ?
ES: Eliminar el crew "${mine.crew.name}".
${others > 0 ?

[running_crew.body.9]
KO: "${mine.crew.name}" 크루를 없애요.
크루원 $others명도 모두 크루에서 나오고, 크루장인 나도 함께 크루에서 나와요.
산 엠블럼도 사라지고 되돌릴 수 없어요.

$note
ES: Vas a eliminar el crew "${mine.crew.name}".
Los $others miembros también saldrán del crew, y yo, como líder, saldré también.
El emblema comprado también desaparecerá y no se puede revertir.

$note

[running_crew.button]
KO: 크루 만들기
ES: Crear crew

[running_crew.button.10]
KO: 받기
ES: Aceptar

[running_crew.button.2]
KO: 서버가 50 DIA 또는 30,000 SHARE 중 선택한 금액만 차감합니다.
ES: El servidor solo deducirá el monto seleccionado: 50 DIA o 30,000 SHARE.

[running_crew.button.3]
KO: 가입 방식
ES: Tipo de ingreso

[running_crew.button.4]
KO: 자유 가입
누구나 바로 들어와요
ES: Unión libre
Cualquiera puede unirse de inmediato

[running_crew.button.5]
KO: 승인 가입
신청을 받아 크루장이 정해요
ES: Unión por aprobación
El líder del crew decide tras la solicitud

[running_crew.button.6]
KO: 검색
ES: Buscar

[running_crew.button.7]
KO: 신고
ES: Reportar

[running_crew.button.8]
KO: 신청 취소
ES: Cancelar solicitud

[running_crew.button.9]
KO: 거절
ES: Rechazar

[running_crew.dialog]
KO: 크루 이름 바꾸기
ES: Cambiar nombre del crew

[running_crew.dialog.2]
KO: 다음
ES: Siguiente

[running_crew.hint]
KO: 크루 검색
ES: Buscar crew

[running_crew.hint.2]
KO: 크루 이름 입력
ES: Ingresa el nombre del crew

[running_crew.hint.3]
KO: 초기화
ES: Restablecer

[running_crew.hint.4]
KO: 2~20자로 지어 주세요
ES: Ingresa de 2 a 20 caracteres

[running_crew.label]
KO: ${crew.memberCount}/${crew.maxMembers}명${crew.needsApproval ?
ES: ${crew.memberCount}/${crew.maxMembers} miembros${crew.needsApproval ?

[running_crew.toast]
KO: 로그인한 뒤에 다시 시도해 주세요.
ES: Por favor, inicia sesión e inténtalo de nuevo.

[running_crew.toast.10]
KO: 유료 엠블럼은 크루장만 살 수 있어요.
ES: Solo el líder del crew puede comprar emblemas de pago.

[running_crew.toast.11]
KO: 이미 크루가 가진 엠블럼이에요.
ES: El crew ya posee este emblema.

[running_crew.toast.12]
KO: 엠블럼을 사지 못했어요. 잠시 뒤 다시 해 주세요.
ES: No se pudo comprar el emblema. Inténtalo de nuevo en unos momentos.

[running_crew.toast.13]
KO: 엠블럼은 자주 바꿀 수 없어요. 잠시 뒤에 다시 바꿔 주세요.
ES: El emblema no se puede cambiar con frecuencia. Inténtalo más tarde.

[running_crew.toast.14]
KO: 아직 쓸 수 없는 테두리나 엠블럼이에요.
ES: Este marco o emblema aún no está disponible.

[running_crew.toast.15]
KO: 엠블럼을 바꾸지 못했어요. 잠시 뒤 다시 해 주세요.
ES: No se pudo cambiar el emblema. Inténtalo de nuevo en unos momentos.

[running_crew.toast.16]
KO: 이 폰에만 저장했어요. 서버에 크루가 생기면 함께 저장돼요.
ES: Guardado solo en este teléfono. Se guardará cuando el crew se cree en el servidor.

[running_crew.toast.17]
KO: 크루 엠블럼을 바꿨어요.
ES: Se cambió el emblema del crew.

[running_crew.toast.18]
KO: 가입
ES: Unirse

[running_crew.toast.19]
KO: "${crew.name}" 크루에 가입했어요.
ES: Te has unido al crew "${crew.name}".

[running_crew.toast.2]
KO: 새 크루 창설 완료 (−$_createCrewDiaCost DIA)
ES: Nuevo crew creado (−$_createCrewDiaCost DIA)

[running_crew.toast.20]
KO: 가입을 신청했어요. 승인되면 크루원이 돼요.
ES: Solicitud enviada. Te convertirás en miembro una vez aprobada.

[running_crew.toast.21]
KO: 이미 다른 크루에 있거나 신청해 둔 곳이 있거나 인원이 가득 찼어요.
ES: Ya estás en otro crew, tienes una solicitud pendiente o el crew está lleno.

[running_crew.toast.22]
KO: 이 크루에는 들어갈 수 없어요.
ES: No puedes unirte a este crew.

[running_crew.toast.23]
KO: 가입하지 못했어요. 잠시 뒤 다시 해 주세요.
ES: Error al unirse. Inténtalo de nuevo en unos momentos.

[running_crew.toast.24]
KO: 가입 신청을 거뒀어요.
ES: Se canceló la solicitud de ingreso.

[running_crew.toast.25]
KO: 거두지 못했어요. 잠시 뒤 다시 해 주세요.
ES: No se pudo cancelar. Inténtalo de nuevo en unos momentos.

[running_crew.toast.26]
KO: 자유 가입으로 바꿨어요.
ES: Se cambió a unión libre.

[running_crew.toast.27]
KO: 승인 가입으로 바꿨어요.
ES: Se cambió a unión por aprobación.

[running_crew.toast.28]
KO: 크루 이름을 "$name"(으)로 바꿨어요.
ES: Se cambió el nombre del crew a "$name".

[running_crew.toast.29]
KO: 신청 목록을 불러오지 못했어요.
ES: No se pudo cargar la lista de solicitudes.

[running_crew.toast.3]
KO: 새 크루 창설 완료 (−$_createCrewShareCost SHARE)
ES: Nuevo crew creado (−$_createCrewShareCost SHARE)

[running_crew.toast.30]
KO: ${request.nickname}님을 받았어요.
ES: Se aceptó a ${request.nickname}.

[running_crew.toast.31]
KO: ${request.nickname}님의 신청을 거절했어요.
ES: Se rechazó la solicitud de ${request.nickname}.

[running_crew.toast.32]
KO: 이미 다른 크루에 있거나 인원이 가득 찼어요.
ES: Ya está en otro crew o el crew está lleno.

[running_crew.toast.33]
KO: 처리하지 못했어요. 잠시 뒤 다시 해 주세요.
ES: No se pudo procesar. Inténtalo de nuevo en unos momentos.

[running_crew.toast.34]
KO: 크루를 없앴어요.
ES: Se eliminó el crew.

[running_crew.toast.35]
KO: 없애지 못했어요. 잠시 뒤 다시 해 주세요.
ES: No se pudo eliminar. Inténtalo de nuevo en unos momentos.

[running_crew.toast.36]
KO: 크루 나가기
ES: Salir del crew

[running_crew.toast.37]
KO: "${mine.crew.name}" 크루에서 나갈까요? 다시 가입할 수 있어요.
ES: ¿Quieres salir del crew "${mine.crew.name}"? Podrás unirte de nuevo más tarde.

[running_crew.toast.38]
KO: 나가기
ES: Salir

[running_crew.toast.39]
KO: 크루에서 나왔어요.
ES: Has salido del crew.

[running_crew.toast.4]
KO: 크루 창설 실패: $error
ES: Error al crear el crew: $error

[running_crew.toast.40]
KO: 크루장은 나갈 수 없어요.
ES: El líder del crew no puede salir.

[running_crew.toast.41]
KO: 나가지 못했어요. 잠시 뒤 다시 해 주세요.
ES: No se pudo salir. Inténtalo de nuevo más tarde.

[running_crew.toast.42]
KO: 지금은 신고할 수 없어요.
ES: No se puede reportar en este momento.

[running_crew.toast.43]
KO: 신고했어요. 운영자가 확인할게요.
ES: Reporte enviado. Un administrador lo revisará.

[running_crew.toast.44]
KO: 신고하지 못했어요. 잠시 뒤 다시 해 주세요.
ES: No se pudo reportar. Inténtalo de nuevo más tarde.

[running_crew.toast.45]
KO: 크루장 넘기기
ES: Transferir líder del crew

[running_crew.toast.46]
KO: ${member.nickname}님이 새 크루장이에요.
ES: ${member.nickname} es el nuevo líder del crew.

[running_crew.toast.47]
KO: 넘기지 못했어요. 잠시 뒤 다시 해 주세요.
ES: No se pudo transferir. Inténtalo de nuevo más tarde.

[running_crew.toast.48]
KO: ${member.nickname}님을 부크루장으로 했어요.
ES: Se nombró a ${member.nickname} como sublíder del crew.

[running_crew.toast.5]
KO: 전체 랭킹을 표시합니다.
ES: Mostrando la clasificación general.

[running_crew.toast.6]
KO: "$result" 검색 결과를 표시합니다.
ES: Mostrando resultados para "$result".

[running_crew.toast.7]
KO: 크루에 들어가면 크루 룸을 볼 수 있어요.
ES: Únete al crew para ver la sala del crew.

[running_crew.toast.8]
KO: 엠블럼은 자주 바꿀 수 없어요. 약 $days일 뒤에 다시 바꿀 수 있어요.
ES: El emblema no se puede cambiar con frecuencia. Podrás cambiarlo en unos $days días.

[running_crew.toast.9]
KO: DIA가 부족해요.
ES: No tienes suficiente DIA.

[security_privacy_center.body]
KO: 적립 규칙, 내 거래 내역, 기부 정산, 기록 이의 신청을 한곳에서 확인해요.
ES: Consulta las reglas de recompensa, historial de transacciones, liquidación de donaciones y apelaciones en un solo lugar.

[security_privacy_center.body.2]
KO: 서버 원장에 기록된 지급·사용 내역
ES: Historial de pagos y uso registrado en el libro mayor del servidor

[security_privacy_center.body.3]
KO: 기부 정산
ES: Liquidación de donaciones

[security_privacy_center.body.4]
KO: 내가 기여한 금액 · 이번 달 기부
ES: Mi monto contribuido · Donaciones de este mes

[security_privacy_center.body.5]
KO: 로그인된 기기
ES: Dispositivos con sesión iniciada

[security_privacy_center.body.6]
KO: 내 계정을 연 기기 · 모든 기기에서 로그아웃
ES: Dispositivos con mi cuenta abierta · Cerrar sesión en todos los dispositivos

[security_privacy_center.body.7]
KO: 기록 소명 및 고객센터
ES: Verificación de registros y soporte

[security_privacy_center.body.8]
KO: 검증 결과에 이의가 있을 때
ES: Si tienes alguna objeción a los resultados de verificación

[share_dia_exchange.body]
KO: 이번 주 남은 한도 ${quote.remainingDia} / ${quote.weeklyCapDia} DIA
ES: Límite semanal restante: ${quote.remainingDia} / ${quote.weeklyCapDia} DIA

[share_dia_exchange.body.2]
KO: ${quote.unitDia} DIA 단위 · 교환 가능 SHARE ${quote.spendableShare}
ES: En unidades de ${quote.unitDia} DIA · SHARE canjeables: ${quote.spendableShare}

[share_dia_exchange.body.3]
KO: 추천 보상 잠금 ${quote.lockedShare} SHARE
ES: Recompensa de referido bloqueada: ${quote.lockedShare} SHARE

[share_dia_exchange.button]
KO: SHARE → DIA 교환
ES: Cambiar SHARE por DIA

[share_dia_exchange.button.2]
KO: DIA 팩 · 준비 중
ES: Paquete DIA · Próximamente

[share_dia_exchange.button.3]
KO: 교환 중...
ES: Canjeando...

[share_dia_exchange.button.4]
KO: 교환
ES: Canjear

[share_dia_exchange.toast]
KO: ${result.rateSharePerDia} SHARE = 1 DIA 교환이 반영되었습니다.
ES: Se ha aplicado el cambio de ${result.rateSharePerDia} SHARE = 1 DIA.

[shop.accessory_shop_grid.body]
KO: 아직 준비 중이에요
ES: Aún en preparación

[shop.accessory_shop_grid.body.2]
KO: ${accessory.tierLock!.labelKo} 티어
ES: Nivel ${accessory.tierLock!.labelKo}

[shop.accessory_shop_grid.button]
KO: 가격은 바뀔 수 있어요.
ES: El precio puede cambiar.

[shop.accessory_shop_grid.button.2]
KO: 입혀 보기
ES: Probar

[shop.accessory_shop_grid.button.3]
KO: 벗기
ES: Quitar

[shop.accessory_shop_grid.button.4]
KO: 입기
ES: Poner

[shop.accessory_shop_grid.button.5]
KO: ${a.tierLock!.labelKo} 티어가 되면 살 수 있어요
ES: Disponible al alcanzar nivel ${a.tierLock!.labelKo}

[shop.accessory_shop_grid.button.6]
KO: 사기 · ${a.priceLabel}
ES: Comprar · ${a.priceLabel}

[shop.accessory_shop_grid.button.7]
KO: 티어 보상이에요
ES: Es una recompensa de nivel

[shop.accessory_shop_grid.toast]
KO: 서버에 연결되면 살 수 있어요.
ES: Puedes comprar una vez conectado al servidor.

[shop.accessory_shop_grid.toast.2]
KO: }가 모자라거나 이미 가진 소품이에요.
ES: } insuficiente o accesorio ya adquirido.

[shop.accessory_shop_grid.toast.3]
KO: 아직 티어가 모자라요.
ES: Tu nivel aún no es suficiente.

[shop.accessory_shop_grid.toast.4]
KO: 사지 못했어요. 잠시 뒤 다시 해 주세요.
ES: No se pudo realizar la compra. Inténtalo de nuevo más tarde.

[shop.battle_pass_grant.body]
KO: 시즌 1 프레임
ES: Marco de la temporada 1

[shop.battle_pass_grant.body.2]
KO: 시즌 1 배지
ES: Insignia de temporada 1

[shop.battle_pass_grant.body.3]
KO: 시즌 1 플러스 프레임
ES: Marco Plus de temporada 1

[shop.battle_pass_grant.body.4]
KO: 시즌 1 스킨
ES: Diseño de temporada 1

[shop.battle_pass_grant.body.5]
KO: 시즌 1 플러스 배지
ES: Insignia Plus de temporada 1

[shop.cosmetics_catalog.body]
KO: 러닝화 스킨
ES: Diseño de zapatillas de correr

[shop.cosmetics_catalog.body.2]
KO: 결과 카드 프레임
ES: Marco de tarjeta de resultados

[shop.friend_ghost_run.body]
KO: ${AppStrings.storeItemFriendGhost} · 보유 $count
ES: ${AppStrings.storeItemFriendGhost} · Tienes: $count

[shop.friend_ghost_run.body.2]
KO: 비교 시작
ES: Iniciar comparación

[shop.friend_ghost_run.hint]
KO: 친구 아이디
ES: ID de amigo

[shop.friend_ghost_run.hint.2]
KO: 기록 아이디
ES: ID del registro

[shop.friend_ghost_run.toast]
KO: 친구 고스트 페이스 보유량이 없습니다. 상점에서 구매해 주세요.
ES: No tienes ritmo fantasma de amigo. Cómpralo en la tienda.

[shop.friend_ghost_run.toast.2]
KO: 친구 고스트 ${formatPaceSecPerKm(pace)}
ES: Fantasma de amigo ${formatPaceSecPerKm(pace)}

[shop.friend_ghost_run.toast.3]
KO: 내 최고 기록 비교는 무료입니다. 티켓을 쓰지 않았습니다.
ES: Comparar con tu mejor marca es gratis. No se usó ningún boleto.

[shop.friend_ghost_run.toast.4]
KO: 친구 기록을 확인하지 못했습니다.
ES: No se pudo verificar el registro del amigo.

[shop.friend_ghost_run.toast.5]
KO: 친구 고스트를 사용하지 못했습니다.
ES: No se pudo usar el fantasma de amigo.

[shop.server_item_use_button.body]
KO: ${widget.label} · 보유 $count
ES: ${widget.label} · En posesión $count

[shop.server_item_use_button.button]
KO: ${widget.label} · 보유 $shown/$cap
ES: ${widget.label} · En posesión $shown/$cap

[shop.server_item_use_button.toast]
KO: ${widget.label} 보유량이 없습니다.
ES: No tienes ${widget.label}.

[shop.server_item_use_button.toast.2]
KO: ${widget.label} 사용 완료
ES: Se usó ${widget.label}

[shop.server_item_use_button.toast.3]
KO: ${widget.label} 을 사용하지 못했습니다.
ES: No se pudo usar ${widget.label}.
