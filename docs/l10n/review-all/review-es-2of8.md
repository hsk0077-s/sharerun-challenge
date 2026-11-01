# 번역 검수 요청 — 쉐어런 (Spanish) · 파트 2/8

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
[crew.crew_emblem.button.2]
KO: 이 엠블럼으로 정하기
ES: Elegir este emblema

[crew.crew_emblem.dialog]
KO: 유료 엠블럼 사기
ES: Comprar emblema prémium

[crew.crew_ranking.body]
KO: 이번 달 ${rank.rank}위 · 1인 평균 ${rank.averageKm.toStringAsFixed(1)}km
ES: Puesto n.º ${rank.rank} este mes · Promedio por persona de ${rank.averageKm.toStringAsFixed(1)}km

[crew.crew_ranking.body.2]
KO: 크루원이 $minMembers명 이상이면 순위에 올라요. (지금 $myMemberCount명)
ES: Aparecerá en el ranking si el crew tiene $minMembers miembros o más. (Ahora $myMemberCount)

[crew.crew_ranking.body.3]
KO: 이번 달에 달리면 순위에 올라요.
ES: Corre este mes para entrar en el ranking.

[app.crewManagerAppointVice]
KO: 부방장 임명
ES: Designar colíder

[app.crewManagerExpandMembers]
KO: +10명 인원 한도 확장하기 (300 DIA)
ES: Ampliar límite en +10 miembros (300 DIA)

[app.crewManagerForceKick]
KO: 강제 퇴출
ES: Expulsar

[app.crewManagerGiftAngelBadge]
KO: 천사 배지를 획득하세요
ES: Consigue la insignia de Ángel

[app.crewManagerGiftCpr]
KO: 🎁 심폐소생권/세이프가드 전체 선물 (DIA)
ES: 🎁 Regalar RCP / Protección a todos (DIA)

[app.crewManagerGiftDeposit]
KO: 🛡️ 크루 대항전 예치금 방장 대납 (DIA/SHARE)
ES: 🛡️ El líder cubre el depósito de batalla de crew (DIA/SHARE)

[app.crewManagerGiftPass]
KO: 🎉 크루 전용 챌린지 패스 & 스킨 구매 (DIA)
ES: 🎉 Comprar pase de desafío y aspecto de crew (DIA)

[app.crewManagerGiftSection]
KO: 크루원 혜택 하사(선물)
ES: Regalar beneficios a miembros

[app.crewManagerMember1]
KO: 김나운
ES: Na-woon Kim

[app.crewManagerMember2]
KO: 이승우
ES: Seung-woo Lee

[app.crewManagerMember3]
KO: 최서연
ES: Seo-yeon Choi

[app.crewManagerMemberSection]
KO: 소속 팀원 관리 (50 / 50명)
ES: Administrar miembros (50 / 50)

[app.crewManagerPremiumSection]
KO: 프리미엄 설정
ES: Ajustes prémium

[app.crewManagerProfileChange]
KO: 이름 변경
ES: Cambiar nombre

[app.crewManagerProfileLabel]
KO: 크루 프로필
ES: Perfil del crew

[app.crewManagerPushNotice]
KO: 전체 공지 푸시 발송 (무료)
ES: Enviar notificación general (Gratis)

[app.crewManagerSave]
KO: 관리 설정 저장하기
ES: Guardar configuración

[app.crewManagerShareWarning]
KO: SHARE 결제 시 주의하세요
ES: Tenga cuidado al pagar con SHARE

[app.crewManagerTitle]
KO: 크루 관리 (방장 전용)
ES: Gestión de crew (Solo líder)

[crew_manager.body]
KO: 처음 한 번은 무료예요.
ES: La primera vez es gratis.

[crew_manager.body.10]
KO: 보유 DIA ${wallet.diamondBalance} · SHARE ${wallet.shareBalance}
ES: Saldo: DIA ${wallet.diamondBalance} · SHARE ${wallet.shareBalance}

[crew_manager.body.11]
KO: 부방장: ${subs.join(
ES: Sublíderes: ${subs.join(

[crew_manager.body.12]
KO: 📢 전체 공지 푸시 (준비 중)
ES: 📢 Notificación general (próximamente)

[crew_manager.body.13]
KO: 크루 이름
ES: Nombre del crew

[crew_manager.body.14]
KO: 이름 변경 (첫 1회 무료)
ES: Cambiar nombre (primera vez gratis)

[crew_manager.body.15]
KO: 이름 변경 (${mine.crew.renameCostDia} DIA)
ES: Cambiar nombre (${mine.crew.renameCostDia} DIA)

[crew_manager.body.16]
KO: 보관함 아이템
ES: Objetos del inventario

[crew_manager.body.17]
KO: 🎁 크루원 전체에게 심폐소생권·세이프가드 선물 (1인당 $_giftDiaPerMember DIA)
ES: 🎁 Regalar boleto de reanimación y salvaguarda a todos los miembros ($_giftDiaPerMember DIA por persona)

[crew_manager.body.18]
KO: 내가 아닌 크루원의 보관함에 하나씩 들어가요. 한 명에게만 줄 때는 아래 팀원 목록에서 골라요.
ES: Se enviará uno al inventario de cada miembro excepto tú. Para dárselo solo a una persona, selecciónala en la lista de miembros de abajo.

[crew_manager.body.19]
KO: 🚩 크루 응원 깃발 (15 DIA, 하루 1회)
ES: 🚩 Bandera de apoyo del crew (15 DIA, 1 vez al día)

[crew_manager.body.2]
KO: 이름 바꾸기
ES: Cambiar nombre

[crew_manager.body.20]
KO: 🛡️ 크루 대항전 예치금 대납 (준비 중)
ES: 🛡️ Pago del depósito de la batalla de crew en su nombre (Próximamente)

[crew_manager.body.21]
KO: 🎉 크루 전용 챌린지 패스 & 스킨 (준비 중)
ES: 🎉 Pase de desafío y aspecto exclusivos de crew (Próximamente)

[crew_manager.body.22]
KO: 소속 팀원 관리 ($count / $limit명)
ES: Administrar miembros ($count / $limit)

[crew_manager.body.23]
KO: 소속 팀원이 없습니다.
ES: No hay miembros.

[crew_manager.body.24]
KO: $name (방장)
ES: $name (Líder)

[crew_manager.body.25]
KO: $name (부방장)
ES: $name (Colíder)

[crew_manager.body.3]
KO: "$next"(으)로 바꾸면 $cost DIA가 들어요. 보너스 DIA를 먼저 써요.
ES: Cambiar a "$next" cuesta $cost DIA. Se usará primero el DIA de bonificación.

[crew_manager.body.4]
KO: $cost DIA 내고 바꾸기
ES: Pagar $cost DIA y cambiar

[crew_manager.body.5]
KO: $cost DIA 내고 보내기
ES: Pagar $cost DIA y enviar

[crew_manager.body.6]
KO: +${step.add}명 인원 한도 확장하기 (${step.costDia} DIA)
ES: Ampliar límite en +${step.add} miembros (${step.costDia} DIA)

[crew_manager.body.7]
KO: $base · ${crew.maxMembers}명을 모두 채우면 열려요
ES: $base · Se desbloquea al alcanzar los ${crew.maxMembers} miembros

[crew_manager.body.8]
KO: 크루 정보를 불러오지 못했어요. 크루에 들어 있는지, 네트워크가 연결됐는지 확인해 주세요.
ES: No se pudo cargar la información del crew. Comprueba si perteneces a un crew y tu conexión de red.

[crew_manager.body.9]
KO: 크루장과 부크루장만 관리할 수 있어요.
ES: Solo el líder y los sublíderes del crew pueden administrarlo.

[crew_manager.button]
KO: 이름을 바꿀 때마다 $cost DIA가 들어요.
ES: Cuesta $cost DIA cambiar

[crew_manager.button.2]
KO: 저장
ES: Guardar

[crew_manager.button.3]
KO: 선물
ES: Regalar

[crew_manager.button.4]
KO: 부방장 해제
ES: Destituir colíder

[crew_manager.dialog]
KO: 크루 이름 변경
ES: Cambiar nombre de crew

[crew_manager.toast]
KO: 아직 열리지 않았어요. 준비되면 알려드릴게요.
ES: Aún no está disponible. Te avisaremos cuando esté listo.

[crew_manager.toast.10]
KO: ${step.costDia} DIA 내고 늘리기
ES: Pagar ${step.costDia} DIA para ampliar

[crew_manager.toast.11]
KO: 인원 한도가 ${result.maxMembers}명이 됐어요.
ES: El límite de miembros ahora es de ${result.maxMembers}.

[crew_manager.toast.12]
KO: 크루장만 늘릴 수 있어요.
ES: Solo el líder del crew puede ampliar el límite.

[crew_manager.toast.13]
KO: 자리를 모두 채워야 하거나 이미 최대예요.
ES: Debes llenar todos los cupos o ya está al máximo.

[crew_manager.toast.14]
KO: 인원 한도를 늘리지 못했어요. 잠시 뒤 다시 해 주세요.
ES: No se pudo ampliar el límite. Inténtalo de nuevo más tarde.

[crew_manager.toast.15]
KO: 크루 응원 깃발을 걸었습니다. 오늘 대회 SHARE 보상이 10% 늘어납니다.
ES: Bandera de apoyo del crew colgada. Recompensa de SHARE del torneo de hoy +10%.

[crew_manager.toast.16]
KO: 응원 깃발을 걸지 못했습니다.
ES: No se pudo colgar la bandera de apoyo.

[crew_manager.toast.17]
KO: 선물을 받을 크루원이 없어요.
ES: No hay miembros del crew para recibir regalos.

[crew_manager.toast.18]
KO: 크루원 $count명 모두
ES: Los $count miembros del crew

[crew_manager.toast.19]
KO: ${member.nickname}님
ES: ${member.nickname}

[crew_manager.toast.2]
KO: 크루 이름을 "$next"(으)로 바꿨어요.
ES: El nombre del crew se cambió a "$next".

[crew_manager.toast.20]
KO: 심폐소생권·세이프가드 선물
ES: Regalar Reanimación y Protección

[crew_manager.toast.21]
KO: $who에게 심폐소생권과 세이프가드를 하나씩 보내요. 한 명당 $_giftDiaPerMember DIA, 모두 $cost DIA가 들고 보너스 DIA를 먼저 써요.
ES: Envía 1 Reanimación y 1 Protección a $who. $_giftDiaPerMember DIA por persona, total $cost DIA. DIA de bono se usa primero.

[crew_manager.toast.22]
KO: ${result.recipients}명의 보관함에 선물을 넣었어요. (−$cost DIA)
ES: Regalo enviado al inventario de ${result.recipients} miembros. (−$cost DIA)

[crew_manager.toast.23]
KO: 크루장만 선물할 수 있어요.
ES: Solo el líder del crew puede enviar regalos.

[crew_manager.toast.24]
KO: 그 크루원을 찾지 못했어요.
ES: No se encontró a ese miembro del crew.

[crew_manager.toast.25]
KO: 선물을 보내지 못했어요. 잠시 뒤 다시 해 주세요.
ES: No se pudo enviar el regalo. Inténtalo de nuevo más tarde.

[crew_manager.toast.26]
KO: ${member.nickname}님을 부방장으로 임명했어요.
ES: Has nombrado a ${member.nickname} como sublíder.

[crew_manager.toast.27]
KO: ${member.nickname}님을 크루원으로 돌렸어요.
ES: Se cambió a ${member.nickname} a miembro del crew.

[crew_manager.toast.28]
KO: 바꾸지 못했어요. 잠시 뒤 다시 해 주세요.
ES: No se pudo cambiar. Inténtalo de nuevo más tarde.

[crew_manager.toast.29]
KO: 크루원 내보내기
ES: Expulsar miembro del crew

[crew_manager.toast.3]
KO: DIA가 모자라거나 쓸 수 없는 이름이에요.
ES: DIA insuficiente o nombre no válido.

[crew_manager.toast.30]
KO: ${member.nickname}님을 크루에서 내보낼까요?
ES: ¿Expulsar a ${member.nickname} del crew?

[crew_manager.toast.31]
KO: 내보내기
ES: Expulsar

[crew_manager.toast.32]
KO: ${member.nickname}님을 내보냈어요.
ES: Se expulsó a ${member.nickname}.

[crew_manager.toast.33]
KO: 내보내지 못했어요. 잠시 뒤 다시 해 주세요.
ES: No se pudo expulsar. Inténtalo de nuevo más tarde.

[crew_manager.toast.34]
KO: 인원 한도 최대 (${crew.maxMembers}명)
ES: Límite máximo de miembros (${crew.maxMembers})

[crew_manager.toast.4]
KO: 크루장만 이름을 바꿀 수 있어요.
ES: Solo el líder del crew puede cambiar el nombre.

[crew_manager.toast.5]
KO: 이름을 바꾸지 못했어요. 잠시 뒤 다시 해 주세요.
ES: No se pudo cambiar el nombre. Inténtalo de nuevo más tarde.

[crew_manager.toast.6]
KO: 인원 한도가 최대(${mine.crew.maxMembers}명)예요.
ES: El límite de miembros está al máximo (${mine.crew.maxMembers} miembros).

[crew_manager.toast.7]
KO: 자리를 모두 채우면 더 늘릴 수 있어요. (${mine.crew.maxMembers}명)
ES: Llena todos los cupos para ampliar el límite. (${mine.crew.maxMembers} miembros)

[crew_manager.toast.8]
KO: 인원 한도 확장
ES: Ampliar límite de miembros

[crew_manager.toast.9]
KO: 크루 인원 한도를 ${step.add}명 늘려요. ${step.costDia} DIA가 들고, 보너스 DIA를 먼저 써요.
ES: Aumenta el límite en ${step.add} miembros por ${step.costDia} DIA. Se usa DIA de bono primero.

[crew_ranking_model.body]
KO: 쉐어런 크루
ES: Crew ShareRun

[crew_room.body]
KO: 크루에 들어 있어야 크루 룸을 볼 수 있어요. 크루에 들어갔는지, 네트워크가 연결됐는지 확인해 주세요.
ES: Debes pertenecer a un crew para ver la sala de crew. Comprueba si te has unido a un crew y si tienes conexión a internet.

[crew_room.body.2]
KO: } · 내 역할 ${CrewRoomScreen._roleLabel(mine.role)}
ES: } · Mi rol: ${CrewRoomScreen._roleLabel(mine.role)}

[crew_room.body.3]
KO: 크루 대항전은 아직 열리지 않았어요. 열리면 여기서 이번 주 진행을 볼 수 있어요.
ES: Las batallas de crew aún no han comenzado. Cuando se abran, podrás ver el progreso de esta semana aquí.

[crew_room.button]
KO: 크루 룸
ES: Sala de crew

[device_connection.body]
KO: (Apple Watch 전 기종 지원)
ES: (Compatible con todos los modelos de Apple Watch)

[device_connection.body.2]
KO: Health Connect 설치 화면을 열었어요. 설치 후 다시 연결해 주세요.
ES: Se ha abierto la pantalla de instalación de Health Connect. Vuelve a conectar después de instalar.

[device_connection.body.3]
KO: ♥ 연결됨
ES: ♥ Conectado

[device_connection.body.4]
KO: 미연결
ES: Sin conectar

[device_connection.body.5]
KO: 연결된 센서: ${snap.deviceName}
ES: Sensor conectado: ${snap.deviceName}

[device_connection.button]
KO: 워치 앱 연결 코드 · 연결된 워치
ES: Código de conexión · Reloj conectado

[device_connection.button.2]
KO: 권한 설정 필요
ES: Permiso requerido

[device_connection.button.3]
KO: 정확한 측정을 위해 권한 설정이 필요합니다.
ES: Se requieren permisos para una medición precisa.

[device_connection.dialog]
KO: 연동 불가
ES: No se puede sincronizar

[device_connection.dialog.2]
KO: 고객님의 스마트워치 OS 버전이 낮거나 호환되지 않아 연동할 수 없습니다. 워치를 최신 버전(watchOS 8+, Wear OS 3.0+)으로 업데이트해 주세요.
ES: La versión del SO de tu reloj inteligente es baja o no es compatible. Actualiza el reloj a la versión más reciente (watchOS 8+, Wear OS 3.0+).

[device_connection.toast]
KO: 등급 배정 화면 이동 실패: $e
ES: Error al ir a la pantalla de asignación de nivel: $e

[device_connection.toast.2]
KO: 건너뛰기 실패: $e
ES: Error al omitir: $e

[device_connection.toast.3]
KO: ${watchType.displayLabel} 연동이 완료되었습니다!
ES: ¡Sincronización con ${watchType.displayLabel} completada!

[device_connection.toast.4]
KO: Health Connect를 열 수 없어요. Play 스토어에서 설치해 주세요.
ES: No se puede abrir Health Connect. Instálalo desde Play Store.

[device_connection.toast.5]
KO: 권한이 거부되었습니다.
ES: Permiso denegado.

[device_connection.toast.6]
KO: Google Health Connect 연동이 완료되었습니다!
ES: ¡Sincronización con Google Health Connect completada!

[device_connection.toast.7]
KO: 기기가 호환되지 않거나 연동 중 오류가 발생했습니다.
ES: El dispositivo no es compatible o se produjo un error durante la sincronización.

[device_connection.toast.8]
KO: Garmin 연동 화면을 열 수 없습니다: $e
ES: No se puede abrir la pantalla de sincronización de Garmin: $e

[device_connection.toast.9]
KO: ${watchType.displayLabel} 연동 설정이 저장되었습니다.
ES: Se guardó la configuración de sincronización de ${watchType.displayLabel}.

[app.bleHrConnectButton]
KO: 연결
ES: Conectar

[app.bleHrDisconnectButton]
KO: 연결 해제
ES: Desconectar

[app.bleHrGuideItems]
KO: 가민(Garmin)
ES: Garmin

[app.bleHrGuideItems.2]
KO: 시계 설정 → 센서 및 액세서리 → 손목 심박수 → "심박수 전송" 켜기
ES: Ajustes del reloj → Sensores y accesorios → Frecuencia cardíaca en la muñeca → Activar "Emitir frecuencia cardíaca"

[app.bleHrGuideItems.3]
KO: 샤오미 · 어메이즈핏
ES: Xiaomi · Amazfit

[app.bleHrGuideItems.4]
KO: 운동·심박수 설정 → "심박수 공유/전송" 켜기
ES: Ajustes de entrenamiento y pulso → Activar "Compartir/transmitir frecuencia cardíaca"

[app.bleHrGuideItems.5]
KO: 가슴·암밴드 센서
ES: Sensores de pecho y brazalete

[app.bleHrGuideItems.6]
KO: 착용한 뒤 아래 [센서 찾기] 누르기 (Polar, Wahoo, Coospo, Magene)
ES: Póntelo y toca [Buscar sensor] abajo (Polar, Wahoo, Coospo, Magene)

[app.bleHrGuideItems.7]
KO: 갤럭시 워치 · 애플워치
ES: Galaxy Watch · Apple Watch

[app.bleHrGuideItems.8]
KO: 이 방식이 아니에요. 위의 Health Connect / Apple 건강으로 연결하세요
ES: No se usa este método. Conéctate a través de Health Connect / Apple Salud más arriba

[app.bleHrGuideTitle]
KO: 내 기기별로 이렇게 하세요
ES: Instrucciones según tu dispositivo

[app.bleHrScanningLabel]
KO: 근처 심박 센서 찾는 중...
ES: Buscando sensores de frecuencia cardíaca cercanos...

[app.bleHrSectionSubtitle]
KO: Health Connect 지연 없이 달리는 동안 실시간 심박수(0x180D)를 바로 받습니다.
ES: Recibe directamente la frecuencia cardíaca en tiempo real (0x180D) al correr sin demoras de Health Connect.

[app.bleHrStopScanButton]
KO: 스캔 중지
ES: Detener escaneo

[app.deviceConnectionConnect]
KO: 기기 연결
ES: Conectar dispositivo

[app.deviceConnectionExternalTitle]
KO: 외부 전문 기기 연동
ES: Integración de dispositivos profesionales externos

[app.deviceConnectionGoogleCaption]
KO: (갤럭시 워치, 샤오미 미밴드, 어메이즈핏, 가민, 핏빗 등)
ES: (Galaxy Watch, Xiaomi Mi Band, Amazfit, Garmin, Fitbit, etc.)

[app.deviceConnectionNativeTitle]
KO: 네이티브 헬스 연동
ES: Integración de salud nativa

[app.deviceConnectionNone]
KO: 연결된 기기가 없습니다
ES: No hay dispositivos conectados

[app.deviceConnectionSingleActiveNote]
KO: 쉐어런은 동시에 하나의 운동 기기만 활성 연결 상태로 유지합니다.
ES: ShareRun solo mantiene activo un dispositivo de entrenamiento a la vez.

[app.deviceConnectionStatusTitle]
KO: 현재 연결된 기기
ES: Dispositivo conectado actualmente

[app.healthConnectNoSamplesTip]
KO: 권한은 연결되었어요. 밴드/워치 앱 안에서 Health Connect 데이터 쓰기 스위치가 켜져 있는지 확인해 주세요. 스마트밴드 기록은 밴드 앱 동기화 후 반영됩니다.
ES: Los permisos están conectados. Comprueba si el interruptor de escritura de datos de Health Connect está activado dentro de la aplicación de tu pulsera/reloj. Los registros de la pulsera inteligente se reflejarán tras sincronizarla con su app.

[dia_pack_store.body]
KO: $price원 · ${pack.bonusLabel}
ES: $price won · ${pack.bonusLabel}

[dia_pack_store.body.2]
KO: 기본 ${pack.baseDia} DIA · ${pack.productId}
ES: Base ${pack.baseDia} DIA · ${pack.productId}

[dia_pack_store.title]
KO: DIA 팩
ES: Paquete DIA

[diamond_box_model.body]
KO: 다이아 상자
ES: Caja de DIA

[donation_settlement.body]
KO: 운영자가 자기 돈으로 검증 1km당 100원(KRW)을 월 예산 안에서 기부할 예정입니다. 이용자의 기부금이 아니며 세금 공제 영수증이 발급되지 않습니다.
ES: El operador planea donar 100 KRW por cada 1 km verificado de su propio dinero, dentro del presupuesto mensual. No es una donación de los usuarios y no se emiten recibos de deducción fiscal.

[economy_constants.body]
KO: 구매 후 7일 이내, 100% 미사용 분에 한해 환불 가능
ES: Reembolsable dentro de los 7 días posteriores a la compra, solo si no se ha utilizado al 100%

[email_verification_guard.button]
KO: 결제·대회 참가 전에 이메일 인증을 완료해 주세요. 상단 배너에서 인증 메일을 재발송할 수 있습니다.
ES: Completa la verificación de correo antes de pagar o unirte a competencias. Puedes reenviar el correo desde el banner superior.

[email_verification_guard.dialog]
KO: 이메일 인증 필요
ES: Verificación de correo requerida

[external_oauth_webview.body]
KO: 이메일 아이디를 입력해 주세요.
ES: Ingrese su correo electrónico.

[external_oauth_webview.body.2]
KO: 올바른 이메일 형식이 아닙니다.
ES: El formato de correo electrónico no es válido.

[external_oauth_webview.body.3]
KO: 비밀번호를 입력해 주세요.
ES: Ingrese su contraseña.

[external_oauth_webview.body.4]
KO: 비밀번호가 너무 짧습니다.
ES: La contraseña es demasiado corta.

[external_oauth_webview.toast]
KO: 연동 중 오류가 발생했습니다. 앱으로 돌아가 다시 시도해 주세요.
ES: Ocurrió un error durante la vinculación. Vuelva a la aplicación e inténtelo de nuevo.

[app.externalPaymentNoticeHighlight]
KO: 실제 야외 물리적 활동(오프라인 러닝)
ES: actividades físicas reales al aire libre (running presencial)

[app.externalPaymentNoticePrefix]
KO: 본 결제는
ES: Este pago corresponde a la compra de un boleto para participar en

[app.externalPaymentNoticeSuffix]
KO: 참여를 위한 참가권 구매입니다.
ES: .

[app.externalPaymentRefundNote]
KO: * 미사용 쿠폰에 한해 언제든 100% 수수료 없이 환불 가능합니다.
ES: * Solo para cupones no utilizados, se puede reembolsar el 100% en cualquier momento sin comisión.

[app.externalPaymentSecurePaySuffix]
KO: 원 안전 결제하기
ES: KRW Pago seguro

[firebase_auth_messages.body]
KO: 로그인이 취소되었습니다.
ES: Inicio de sesión cancelado.

[firebase_auth_messages.body.10]
KO: 다른 로그인 방식으로 가입된 이메일입니다.
ES: Este correo electrónico está registrado con otro método de inicio de sesión.

[firebase_auth_messages.body.11]
KO: 보안을 위해 다시 로그인한 뒤 계정 삭제를 시도해 주세요.
ES: Por razones de seguridad, vuelve a iniciar sesión antes de intentar eliminar la cuenta.

[firebase_auth_messages.body.12]
KO: 로그인에 실패했습니다.
ES: Error al iniciar sesión.

[firebase_auth_messages.body.2]
KO: 이메일 형식이 올바르지 않습니다.
ES: El formato del correo electrónico no es válido.

[firebase_auth_messages.body.3]
KO: 비활성화된 계정입니다. 고객센터에 문의해 주세요.
ES: Esta cuenta ha sido deshabilitada. Ponte en contacto con el servicio de atención al cliente.

[firebase_auth_messages.body.4]
KO: 이메일 또는 비밀번호를 확인해 주세요.
ES: Por favor, verifica tu correo electrónico o contraseña.

[firebase_auth_messages.body.5]
KO: 이미 사용 중인 이메일입니다.
ES: Este correo electrónico ya está en uso.

[firebase_auth_messages.body.6]
KO: 비밀번호는 6자 이상이어야 합니다.
ES: La contraseña debe tener al menos 6 caracteres.

[firebase_auth_messages.body.7]
KO: 요청이 너무 많습니다. 잠시 후 다시 시도해 주세요.
ES: Demasiadas solicitudes. Por favor, inténtalo de nuevo más tarde.

[firebase_auth_messages.body.8]
KO: 네트워크 연결을 확인해 주세요.
ES: Por favor, comprueba tu conexión de red.

[firebase_auth_messages.body.9]
KO: Firebase 콘솔에서 익명(게스트) 로그인을 활성화해 주세요.
ES: Activa el inicio de sesión anónimo (invitado) en la consola de Firebase.

[app.garminAuthSubtitle]
KO: 안전한 OAuth 2.0 공식 로그인 페이지입니다.
ES: Esta es una página de inicio de sesión oficial y segura con OAuth 2.0.

[app.garminAuthTitle]
KO: Garmin Connect 연동
ES: Vinculación con Garmin Connect

[app.garminCancelAndReturn]
KO: 연동을 취소하고 앱으로 돌아가기
ES: Cancelar vinculación y volver a la app

[app.garminEmailHint]
KO: 이메일 아이디
ES: Correo electrónico

[app.garminPasswordHint]
KO: 비밀번호
ES: Contraseña

[app.garminSignInAuthorize]
KO: 로그인하고 권한 허용
ES: Iniciar sesión y autorizar

[app.garminSignInAuthorizeKo]
KO: (로그인 및 권한 허용)
ES: (Iniciar sesión y autorizar)

[app.hallOfFameDonateCta]
KO: 나도 기부하고 명예의 전당 오르기 💎
ES: Dona y entra al Salón de la Fama 💎

[app.hallOfFameDonateHistoryTitle]
KO: 명예의 전당 기부 완료 🕊️
ES: Donación al Salón de la Fama completada 🕊️

[app.hallOfFameLeaderDonation]
KO: 누적 기부: 5,000,000 VALUE
ES: Donación acumulada: 5,000,000 VALUE

[app.hallOfFameLeaderName]
KO: 서울 나이트 러너스 방장님
ES: Líder de Seoul Night Runners

[app.hallOfFameLeaderTitle]
KO: 👑 이달의 소셜 임팩트 리더
ES: 👑 Líder de impacto social del mes

[app.hallOfFameRank2Badge]
KO: 🔥 불꽃 SBT 뱃지
ES: 🔥 Insignia SBT Llama

[app.hallOfFameRank2Label]
KO: 2등
ES: 2.º puesto

[app.hallOfFameRank2Subtitle]
KO: 연속 50일 완주자
ES: Finalizador de 50 días consecutivos

[app.hallOfFameRank3Badge]
KO: 🛡️ 방패 SBT 뱃지
ES: 🛡️ Insignia SBT Escudo

[app.hallOfFameRank3Label]
KO: 3등
ES: 3.er puesto

[app.hallOfFameRank3Subtitle]
KO: 최다 크루원 후원자
ES: Mayor patrocinador de miembros de crew

[app.hallOfFameTitle]
KO: 명예의 전당 (Hall of Fame)
ES: Salón de la Fama (Hall of Fame)

[app.runningCrewHallOfFame]
KO: 👑 명예의 전당
ES: 👑 Salón de la Fama

[app.storeDonateHistoryTitle]
KO: 기부 펀딩 참여 🕊️
ES: Participación en financiamiento de donación 🕊️

[hall_of_fame.body]
KO: 서버 원장에서 $_donateValue VALUE를 기부했습니다.
ES: Se donaron $_donateValue VALUE en el libro contable del servidor.

[hall_of_fame.body.2]
KO: 서버 원장에서 $_donateValue VALUE를 기부했습니다. 잔액 $left
ES: Se donaron $_donateValue VALUE en el libro contable del servidor. Saldo: $left

[hall_of_fame.body.3]
KO: VALUE가 부족합니다.
ES: VALUE insuficiente.

[hall_of_fame.body.4]
KO: 기부에 실패했습니다.
ES: Error al realizar la donación.

[hall_of_fame.body.5]
KO: 아직 기록이 없어요
ES: Aún no hay registros

[health_data_consent.body]
KO: 개인정보보호법에 따라 건강·생체 데이터는 일반 약관과 분리된 명시적 Opt-in이 필요합니다.
ES: De acuerdo con las leyes de privacidad, los datos biométricos y de salud requieren una autorización explícita e independiente de los términos generales.

[health_data_consent.button]
KO: 권한 요청 중...
ES: Solicitando permisos...

[health_data_consent.button.2]
KO: 동의하고 워치 연동 계속
ES: Aceptar y vincular reloj

[health_data_consent.button.3]
KO: 나중에 하기
ES: Más tarde

[health_data_consent.title]
KO: 건강정보 동의
ES: Consentimiento de datos de salud

[health_data_consent.title.2]
KO: 스마트워치 연동 전 동의
ES: Consentimiento previo a la vinculación con smartwatch

[home.home_wallet.body]
KO: $completedCount/$total회 완료 >
ES: $completedCount/$total completados >

[iap.coach_plus_product.body]
KO: 6,900원
ES: 6,900 won

[iap.coach_plus_product.body.2]
KO: 59,000원
ES: 59,000 won

[iap.coach_plus_upsell.body]
KO: 무료
ES: Gratis

[iap.coach_plus_upsell.body.2]
KO: 기본 러닝 안내
ES: Guía básica de carrera

[iap.coach_plus_upsell.body.3]
KO: Coach+ 이용 중
ES: Usando Coach+

[iap.coach_plus_upsell.button]
KO: 구매 복원
ES: Restaurar compras

[iap.dia_pack_product.body]
KO: 보너스 없음
ES: Sin bonificación

[iap.dia_pack_product.body.2]
KO: 보너스 $bonusDia DIA
ES: Bonificación de $bonusDia DIA

[iap.iap_providers.body]
KO: SHARE 충전 💳
ES: Cargar SHARE 💳

[iap.iap_purchase_controller.body]
KO: Google Play 결제 서비스를 사용할 수 없습니다. 잠시 후 다시 시도해 주세요.
ES: El servicio de facturación de Google Play no está disponible. Inténtalo de nuevo más tarde.

[iap.iap_purchase_controller.body.10]
KO: 결제 처리 중 오류가 발생했습니다.
ES: Ocurrió un error al procesar el pago.

[iap.iap_purchase_controller.body.11]
KO: Coach+ 결제가 진행 중입니다.
ES: El pago de Coach+ está en curso.

[iap.iap_purchase_controller.body.12]
KO: Coach+ 구독이 활성화되었습니다.
ES: La suscripción a Coach+ ha sido activada.

[iap.iap_purchase_controller.body.13]
KO: Coach+ 결제가 실패했습니다.
ES: El pago de Coach+ falló.

[iap.iap_purchase_controller.body.14]
KO: Coach+ 결제가 취소되었습니다.
ES: El pago de Coach+ fue cancelado.

[iap.iap_purchase_controller.body.15]
KO: 로그인 후 Google Play 결제를 진행해 주세요.
ES: Inicia sesión antes de proceder con el pago de Google Play.

[iap.iap_purchase_controller.body.16]
KO: 영수증을 보안 검증 중입니다. SHARE는 검증 완료 후 지급됩니다.
ES: El recibo está pasando por una verificación de seguridad. SHARE se otorgará una vez completada la verificación.

[iap.iap_purchase_controller.body.17]
KO: 검증이 완료되어 $shareAmount SHARE가 지급되었습니다.
ES: Verificación completada. Se ha otorgado $shareAmount SHARE.

[iap.iap_purchase_controller.body.18]
KO: Google 검증이 완료되어 SHARE가 지갑에 반영됩니다.
ES: La verificación de Google se ha completado y SHARE se reflejará en tu billetera.

[iap.iap_purchase_controller.body.19]
KO: 영수증 검증이 거절되었습니다. 고객센터로 문의해 주세요.
ES: Se rechazó la verificación del recibo. Comunícate con atención al cliente.

[iap.iap_purchase_controller.body.2]
KO: 상품(${plan.productId})을 찾지 못했습니다. Play Console / App Store Connect 등록을 확인해 주세요.
ES: No se encontró el producto (${plan.productId}). Comprueba el registro en Play Console / App Store Connect.

[iap.iap_purchase_controller.body.20]
KO: 검증 응답이 지연되고 있습니다. 지갑 잔액을 잠시 후 다시 확인해 주세요.
ES: La respuesta de verificación se está retrasando. Vuelve a consultar el saldo de tu billetera en un momento.

[iap.iap_purchase_controller.body.21]
KO: 결제 스트림이 일시 중단되었습니다. 연결을 확인한 뒤 다시 시도해 주세요.
ES: El flujo de pago se interrumpió temporalmente. Comprueba tu conexión e inténtalo de nuevo.

[iap.iap_purchase_controller.body.3]
KO: 결제 창을 열 수 없습니다.
ES: No se puede abrir la ventana de pago.

[iap.iap_purchase_controller.body.4]
KO: 결제를 시작하지 못했습니다. 네트워크 상태를 확인해 주세요.
ES: No se pudo iniciar el pago. Comprueba el estado de la red.

[iap.iap_purchase_controller.body.5]
KO: 구매 복원에 실패했습니다. 잠시 후 다시 시도해 주세요.
ES: Error al restaurar las compras. Inténtalo de nuevo más tarde.

[iap.iap_purchase_controller.body.6]
KO: 상품(${product.productId})을 찾지 못했습니다. Play Console 등록을 확인해 주세요.
ES: No se encontró el producto (${product.productId}). Comprueba el registro en Play Console.

[iap.iap_purchase_controller.body.7]
KO: 결제가 진행 중입니다. Google Play 승인을 기다려 주세요.
ES: El pago está en curso. Espera la aprobación de Google Play.

[iap.iap_purchase_controller.body.8]
KO: 결제가 실패했습니다.
ES: El pago falló.

[iap.iap_purchase_controller.body.9]
KO: 결제가 취소되었습니다.
ES: El pago fue cancelado.

[iap.payment_auth.body]
KO: 본인 확인이 취소됐어요. 결제는 진행되지 않았어요.
ES: Se canceló la verificación de identidad. No se realizó el pago.

[iap.payment_auth.body.2]
KO: 확인을 여러 번 틀려 잠시 막혔어요. 잠시 뒤 다시 하거나 화면 잠금(PIN, 패턴)으로 확인해 주세요. 결제는 진행되지 않았어요.
ES: Demasiados intentos incorrectos, bloqueo temporal. Inténtalo de nuevo en unos momentos o verifica con el bloqueo de pantalla (PIN, patrón). No se realizó el pago.

[iap.payment_auth.body.3]
KO: 결제 전 본인 확인을 하려면 폰에 화면 잠금(지문, PIN, 패턴)이 필요해요. 기기 설정에서 화면 잠금을 켠 뒤 다시 시도해 주세요.
ES: Para verificar tu identidad antes del pago, necesitas un bloqueo de pantalla (huella digital, PIN, patrón) en tu teléfono. Activa el bloqueo de pantalla en la configuración del dispositivo e inténtalo de nuevo.

[iap.payment_auth.body.4]
KO: 본인 확인을 할 수 없어요. 잠시 뒤 다시 시도해 주세요. 결제는 진행되지 않았어요.
ES: No se puede verificar tu identidad. Inténtalo de nuevo en unos momentos. No se realizó el pago.

[iap.payment_auth.body.5]
KO: 결제를 진행하려면 본인 확인이 필요해요.
ES: Se requiere verificación de identidad para continuar con el pago.

[iap.purchases_closed.body]
KO: 안내
ES: Aviso

[iap.purchases_closed.title]
KO: 이 버전에서는 앱 안 결제를 받지 않아요.
ES: Las compras dentro de la app no están disponibles en esta versión.

[in_app_billing.body]
KO: DIA · SHARE로 교환
ES: Canjear por DIA · SHARE

[in_app_billing.body.2]
KO: Play 상품 준비 중 · 결제해도 DIA가 지급되지 않습니다
ES: Preparando productos de Play · No se entregará DIA aunque realice el pago

[in_challenge.body]
KO: 센서 준비 중...
ES: Preparando sensores...

[in_challenge.body.2]
KO: Jena 검증 중...
ES: Jena verificando...

[in_challenge.body.3]
KO: 제출 기회: ${widget.submissionsRemaining}/${widget.maxSubmissions}회 남음
ES: Intentos de envío restantes: ${widget.submissionsRemaining}/${widget.maxSubmissions}

[in_challenge.body.4]
KO: 센서 시작 실패: $e
ES: Error al iniciar el sensor: $e

[in_challenge.body.5]
KO: 심박수
ES: Frecuencia cardíaca
