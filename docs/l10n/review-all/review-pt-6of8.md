# 번역 검수 요청 — 쉐어런 (Brazilian Portuguese) · 파트 6/8

아래는 한국어 앱 "쉐어런"(걷기·달리기 앱, 회사 자금 기부 연계)의 화면 문구를 Brazilian Portuguese(으)로 번역한 것입니다.
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
[run_result.run_finish_share_flow.body.2]
KO: 여러 개 순서대로 올리기
PT: Postar várias em ordem

[run_result.run_finish_share_flow.body.3]
KO: 순서대로 공유
PT: Compartilhar em ordem

[run_result.run_finish_share_flow.body.4]
KO: 그만하기
PT: Parar

[run_result.run_finish_share_flow.body.5]
KO: 어떻게 올릴까요?
PT: Como deseja postar?

[run_result.run_finish_share_flow.body.6]
KO: 어디에 올릴까요?
PT: Onde deseja postar?

[run_result.run_finish_share_flow.body.7]
KO: 순서대로 올리기
PT: Postar em ordem

[run_result.run_finish_share_flow.body.8]
KO: 다음: $label
PT: Próximo: $label

[run_result.run_finish_share_targets.body]
KO: Instagram 스토리
PT: Stories do Instagram

[run_result.run_finish_share_targets.body.2]
KO: Instagram 피드
PT: Feed do Instagram

[run_result.run_finish_share_targets.body.3]
KO: 더보기
PT: Mais

[run_tracking.body]
KO: 심박 ${telemetry.currentHeartRate?.toString() ??
PT: Frequência cardíaca ${telemetry.currentHeartRate?.toString() ??

[run_tracking.body.2]
KO: } BPM / 케이던스 ${telemetry.currentCadenceSpm?.toString() ??
PT: } BPM / Cadência ${telemetry.currentCadenceSpm?.toString() ??

[run_tracking.body.3]
KO: 자이로 안정도 ${telemetry.gyroStabilityScore.toStringAsFixed(2)}
PT: Estabilidade do giroscópio ${telemetry.gyroStabilityScore.toStringAsFixed(2)}

[run_tracking.body.4]
KO: 센서를 시작하는 중...
PT: Iniciando sensor...

[run_tracking.body.5]
KO: 러닝 검증 중...
PT: Verificando corrida...

[run_tracking.body.6]
KO: 러닝 끝내고 검증하기
PT: Finalizar corrida e verificar

[run_tracking.body.7]
KO: MyPage에서 [선택] 민감정보 수집 동의 후 러닝 검증을 시작할 수 있습니다.
PT: Você pode iniciar a verificação de corrida após concordar com a Coleta [Opcional] de Informações Sensíveis no MyPage.

[run_tracking.body.8]
KO: 센서를 시작하지 못했어요: $error
PT: Falha ao iniciar os sensores: $error

[run_tracking.title]
KO: 달리기 기록
PT: Registro de Corrida

[run_tracking.toast]
KO: 러닝 검증에 실패했어요: ${ApiErrorMessage.from(error)}
PT: Falha na verificação de corrida: ${ApiErrorMessage.from(error)}

[run_tracking.ble_heart_rate_service.body]
KO: BLE 심박 센서 (${map[
PT: Sensor de frequência cardíaca BLE (${map[

[run_tracking.ble_heart_rate_service.body.2]
KO: 이 기기에서는 블루투스 심박 스캔을 지원하지 않습니다.
PT: Este dispositivo não suporta a busca de frequência cardíaca via Bluetooth.

[run_tracking.ble_heart_rate_service.body.3]
KO: 블루투스 권한 또는 상태를 확인해 주세요.
PT: Verifique a permissão ou o status do Bluetooth.

[run_tracking.ble_heart_rate_service.body.4]
KO: 이 기기에서는 블루투스 심박 연결을 지원하지 않습니다.
PT: Este dispositivo não suporta a conexão de frequência cardíaca via Bluetooth.

[run_tracking.ble_heart_rate_service.body.5]
KO: 센서 연결에 실패했습니다.
PT: Falha ao conectar o sensor.

[run_tracking.gps_tracking_service.body]
KO: 실시간 러닝 GPS 추적 중
PT: Rastreamento GPS de corrida em tempo real em andamento

[run_tracking.home_start_gate.body]
KO: 마이페이지에서 민감정보 수집에 동의해주세요
PT: Consinta com a coleta de dados confidenciais em Minha Página.

[run_tracking.home_start_gate.body.2]
KO: 로그인 후 러닝 검증을 진행할 수 있습니다.
PT: Você pode prosseguir com a verificação da corrida após fazer login.

[run_tracking.home_start_gate.body.3]
KO: 러닝이 시작되지 않았습니다.
PT: A corrida não foi iniciada.

[run_tracking.music_controls.body]
KO: 음악을 조절하지 못했어요.
PT: Não foi possível controlar a música.

[run_tracking.music_controls.body.2]
KO: 재생 / 일시정지
PT: Reproduzir / Pausar

[run_tracking.music_controls.body.3]
KO: 다음 곡
PT: Próxima faixa

[run_tracking.music_controls.body.4]
KO: 음악 앱 열기
PT: Abrir app de música

[run_tracking.music_controls.body.5]
KO: 음악 앱을 찾지 못했어요. 쓰는 음악 앱을 직접 열어 주세요.
PT: Não encontramos um app de música. Abra o app de música que você usa diretamente.

[run_tracking.music_controls.button]
KO: 이전 곡
PT: Faixa anterior

[run_tracking.run_recording_checklist.body]
KO: 화면을 끄거나 다른 앱을 켜도 경로 기록과 음성 코칭이 이어지도록 아래 항목을 확인해 주세요.
PT: Verifique os itens abaixo para que o registro da rota e a orientação por voz continuem mesmo com a tela desligada ou ao usar outro app.

[run_tracking.run_recording_checklist.body.10]
KO: 허용하지 않아도 달리기는 시작할 수 있습니다.
PT: Você pode começar a correr mesmo sem permitir.

[run_tracking.run_recording_checklist.body.11]
KO: 항목을 나중에 바꿔도 됩니다.
PT: Você pode alterar essas configurações mais tarde.

[run_tracking.run_recording_checklist.body.12]
KO: 필요
PT: Obrigatório

[run_tracking.run_recording_checklist.body.2]
KO: 위치 권한
PT: Permissão de localização

[run_tracking.run_recording_checklist.body.3]
KO: 앱을 사용하는 동안 허용해 주세요. 항상 허용은 요청하지 않습니다.
PT: Permita durante o uso do app. Não solicitamos "Permitir o tempo todo".

[run_tracking.run_recording_checklist.body.4]
KO: 허용됨
PT: Permitido

[run_tracking.run_recording_checklist.body.5]
KO: 허용하기
PT: Permitir

[run_tracking.run_recording_checklist.body.6]
KO: 알림 권한
PT: Permissão de notificações

[run_tracking.run_recording_checklist.body.7]
KO: 달리기 기록 알림을 표시합니다. Android 13 이상에서 필요합니다.
PT: Exibe notificações de registro de corrida. Necessário no Android 13 ou superior.

[run_tracking.run_recording_checklist.body.8]
KO: 배터리 최적화
PT: Otimização de bateria

[run_tracking.run_recording_checklist.body.9]
KO: 설정됨
PT: Configurado

[run_tracking.run_recording_checklist.button]
KO: 확인하고 달리기
PT: Confirmar e correr

[run_tracking.run_recording_checklist.title]
KO: 달리기 기록 설정
PT: Configurações de registro de corrida

[run_tracking.run_recording_checklist.toast]
KO: 배터리 설정 화면을 열지 못했습니다.
PT: Não foi possível abrir a tela de configurações da bateria.

[run_tracking.run_recording_foreground.body]
KO: 화면이 꺼져도 달리기 경로와 음성 코칭을 이어갑니다.
PT: Continua registrando o percurso e o treino por voz mesmo com a tela desligada.

[run_tracking.run_recording_policy.body]
KO: 쉐어런 · 달리기 기록 중
PT: ShareRun · Gravando corrida

[run_tracking.run_recording_policy.body.2]
KO: 이전 달리기가 중단되었습니다
PT: A corrida anterior foi interrompida

[run_tracking.run_recording_policy.body.3]
KO: 앱이 중간에 종료되어 직전 달리기는 저장되지 않았습니다. 보상은 지급되지 않고, 기록도 남지 않습니다.
PT: O app foi encerrado inesperadamente, portanto a corrida anterior não foi salva. As recompensas não foram concedidas e nenhum registro foi salvo.

[run_tracking.run_recording_policy.body.4]
KO: 화면이 꺼지면 달리기 기록이 중단될 수 있습니다.
PT: O registro da corrida pode ser interrompido se a tela for desligada.

[run_tracking.run_recording_policy.body.5]
KO: 달리기 기록 설정 점검
PT: Verificar configurações de gravação de corrida

[run_tracking.run_recording_policy.body.6]
KO: 시스템 배터리 최적화 화면에서 쉐어런을 찾아 주세요. 삼성 갤럭시는 '제한 없음'으로 바꿔 주세요.
PT: Encontre o ShareRun na tela de otimização de bateria do sistema. No Samsung Galaxy, mude para "Irrestrito".

[run_tracking.run_session_service.body]
KO: 위치 서비스가 꺼져 있습니다.
PT: Os serviços de localização estão desativados.

[run_tracking.run_session_service.body.2]
KO: 위치 권한이 영구 거부되었습니다. 설정에서 허용해 주세요.
PT: A permissão de localização foi negada permanentemente. Permita nas configurações.

[run_tracking.run_session_service.body.3]
KO: 위치 권한이 허용되었습니다.
PT: Permissão de localização concedida.

[run_tracking.run_start_preflight.button]
KO: 심박수·케이던스 검증을 위해 [선택] 건강정보 수집 동의가 필요합니다. 일반 이용약관과 별도로 Opt-in 해 주세요.
PT: O consentimento para [Opcional] coleta de dados de saúde é necessário para verificar frequência cardíaca e cadência. Faça a adesão separadamente dos termos gerais.

[run_tracking.run_start_preflight.button.2]
KO: 동의 화면으로
PT: Ir para tela de consentimento

[run_tracking.run_start_preflight.dialog]
KO: 건강정보 동의 필요
PT: Consentimento de dados de saúde necessário

[run_tracking.run_start_preflight.toast]
KO: 로그인 후 러닝을 시작할 수 있습니다.
PT: Você pode iniciar a corrida após fazer login.

[run_tracking.sponsor_live_buff_banner.body]
KO: 스폰서 라이브 버프
PT: Buff ao vivo do patrocinador

[run_tracking.watch_runtime_permissions_service.body]
KO: Health Connect 앱 설치
PT: Instalar app Health Connect

[run_tracking.watch_runtime_permissions_service.body.2]
KO: Health Connect 건강 데이터
PT: Dados de saúde do Health Connect

[run_tracking.watch_runtime_permissions_service.body.3]
KO: 신체 활동 인식
PT: Reconhecimento de atividade física

[app.runningCrewCreateButton]
KO: [50 DIA 또는 30,000 SHARE로 새 크루 창설하기]
PT: [Criar nova crew com 50 DIA ou 30.000 SHARE]

[app.runningCrewEnterRoom]
KO: 크루 룸 입장하기
PT: Entrar na sala do crew

[app.runningCrewHeadline]
KO: 같이 달릴
크루 찾기
PT: Encontre um crew
para correr junto

[app.runningCrewMyCrewName]
KO: 인천 논현 최강 크루
PT: Crew mais forte de Incheon Nonhyeon

[app.runningCrewMyCrewStats]
KO: 소속 크루원: 45/50명 | 누적 달성 거리: 3,240km
PT: Membros da crew: 45/50 | Distância acumulada: 3.240 km

[app.runningCrewNoCrewHint]
KO: 크루에 들어가면 함께 달린 거리를 모아 월간 순위에 도전할 수 있어요. 크루를 만들거나 아래에서 찾아보세요.
PT: Entre em uma crew para somar a distância percorrida juntos e disputar o ranking mensal. Crie uma crew ou procure uma abaixo.

[app.runningCrewNoCrewName]
KO: 아직 크루가 없어요
PT: Ainda não tem uma crew

[app.runningCrewProgressLabel]
KO: 이번 주 크루 대항전 10K 완주율
PT: Taxa de conclusão dos 10K da batalha de crews desta semana

[app.runningCrewTitle]
KO: 러닝 크루 (Crew)
PT: Running crew

[running_crew.body]
KO: 가입 신청
PT: Solicitar entrada

[running_crew.body.10]
KO: 크루는 두고 나만 나가고 싶다면 먼저 "크루원 보기"에서 크루장을 넘겨 주세요.
PT: Se quiser sair sem excluir o crew, transfira a liderança em "Ver membros" primeiro.

[running_crew.body.11]
KO: ${member.nickname}님에게 크루장을 넘길까요? 나는 부크루장이 되고, 원하면 그 뒤에 크루에서 나갈 수 있어요.
PT: Deseja transferir a liderança do crew para ${member.nickname}? Você se tornará vice-líder e poderá sair do crew depois se quiser.

[running_crew.body.12]
KO: 넘기기
PT: Transferir

[running_crew.body.13]
KO: 크루원
PT: Membro do crew

[running_crew.body.14]
KO: 누적 거리
PT: Distância total

[running_crew.body.15]
KO: 크루 관리
PT: Gerenciar crew

[running_crew.body.16]
KO: 공지 · 크루원 · 혜택 선물
PT: Avisos · Membros · Benefícios de presente

[running_crew.body.17]
KO: 크루원 보기
PT: Ver membros

[running_crew.body.18]
KO: ${mine.crew.memberCount}명 · 내 역할 ${_roleLabel(mine.role)}
PT: ${mine.crew.memberCount} membros · Minha função: ${_roleLabel(mine.role)}

[running_crew.body.19]
KO: 가입 신청 ${mine.pendingRequests}건
PT: ${mine.pendingRequests} solicitações de entrada

[running_crew.body.2]
KO: 크루 가입
PT: Entrar no crew

[running_crew.body.20]
KO: 받을지 정해요
PT: Decida se aceita

[running_crew.body.21]
KO: 처음 한 번은 무료
PT: A primeira vez é gratuita

[running_crew.body.22]
KO: 지금은 승인 가입
PT: Atualmente com aprovação

[running_crew.body.23]
KO: 지금은 자유 가입
PT: Atualmente entrada livre

[running_crew.body.24]
KO: 크루원과 함께 모두 나와요
PT: Todos os membros sairão juntos

[running_crew.body.25]
KO: 다시 가입할 수 있어요
PT: Você pode entrar novamente

[running_crew.body.26]
KO: 엠블럼 바꾸기
PT: Alterar emblema

[running_crew.body.27]
KO: 틀 ${CrewEmblem.frames.length}가지 · 문양 ${CrewEmblem.glyphIds.length}가지 · 색 ${CrewEmblem.paletteColors.length}가지
PT: ${CrewEmblem.frames.length} molduras · ${CrewEmblem.glyphIds.length} símbolos · ${CrewEmblem.paletteColors.length} cores

[running_crew.body.28]
KO: 색 ${CrewEmblem.paletteColors.length}가지
PT: ${CrewEmblem.paletteColors.length} cores

[running_crew.body.29]
KO: 다른 크루 찾기
PT: Buscar outros crews

[running_crew.body.3]
KO: "${crew.name}" 크루는 크루장이 승인해야 들어갈 수 있어요. 신청할까요?
PT: Para entrar no "${crew.name}", é necessária a aprovação do líder. Deseja solicitar?

[running_crew.body.30]
KO: 검색: "$_searchQuery"
PT: Pesquisar: "$_searchQuery"

[running_crew.body.31]
KO: 검색 결과가 없습니다.
PT: Nenhum resultado encontrado.

[running_crew.body.32]
KO: 보유 SHARE ${_format(wallet.shareBalance)}
PT: Saldo de SHARE: ${_format(wallet.shareBalance)}

[running_crew.body.33]
KO: 크루장
PT: Líder do crew

[running_crew.body.34]
KO: 부크루장
PT: Vice-líder do crew

[running_crew.body.35]
KO: 명예의 전당
PT: Hall da Fama

[running_crew.body.36]
KO: 역대 최고 ${ranking.bestRank}위
PT: Melhor histórico: ${ranking.bestRank}º lugar

[running_crew.body.37]
KO: 순위는 이번 달 크루 거리 ÷ 크루원 수예요. 달이 끝나면 확정돼요.
PT: A classificação é a distância do crew deste mês ÷ número de membros. É confirmada no fim do mês.

[running_crew.body.38]
KO: 크루 이름 검색
PT: Buscar nome do crew

[running_crew.body.39]
KO: 50 DIA 또는 30,000 SHARE
PT: 50 DIA ou 30.000 SHARE

[running_crew.body.4]
KO: "${crew.name}" 크루에 가입할까요?
PT: Quer entrar no crew "${crew.name}"?

[running_crew.body.40]
KO: 아직 만들어진 크루가 없어요.
PT: Nenhum crew foi criado ainda.

[running_crew.body.41]
KO: 가입 불가
PT: Não é possível entrar

[running_crew.body.42]
KO: 가득 참
PT: Lotado

[running_crew.body.43]
KO: ${mine.crew.name} · ${mine.members.length}명
PT: ${mine.crew.name} · ${mine.members.length} membros

[running_crew.body.44]
KO: 부크루장 해제
PT: Remover vice-líder

[running_crew.body.45]
KO: 부크루장으로
PT: Nomear vice-líder

[running_crew.body.46]
KO: 신고하기
PT: Denunciar

[running_crew.body.47]
KO: 가입 신청 ${requests.length}건
PT: ${requests.length} solicitações de entrada

[running_crew.body.48]
KO: 기다리는 신청이 없어요.
PT: Não há solicitações pendentes.

[running_crew.body.49]
KO: "${mine.crew.name}" 크루를 없애요.
크루장인 나도 함께 크루에서 나와요.
산 엠블럼도 사라지고 되돌릴 수 없어요.

$note
PT: Você vai excluir o crew "${mine.crew.name}".
Eu, como líder, também saio do crew.
O emblema comprado também desaparece, e isso não pode ser desfeito.

$note

[running_crew.body.5]
KO: 신청
PT: Solicitar

[running_crew.body.6]
KO: "$name"(으)로 바꾸면 $cost DIA가 들어요. 보너스 DIA를 먼저 써요.
PT: Mudar para "$name" custa $cost DIA. O DIA bônus será usado primeiro.

[running_crew.body.7]
KO: 크루 없애기
PT: Excluir crew

[running_crew.body.8]
KO: "${mine.crew.name}" 크루를 없애요.
${others > 0 ?
PT: Excluir o crew "${mine.crew.name}".
${others > 0 ?

[running_crew.body.9]
KO: "${mine.crew.name}" 크루를 없애요.
크루원 $others명도 모두 크루에서 나오고, 크루장인 나도 함께 크루에서 나와요.
산 엠블럼도 사라지고 되돌릴 수 없어요.

$note
PT: Você vai excluir o crew "${mine.crew.name}".
Os $others membros também saem do crew, e eu, como líder, também saio.
O emblema comprado também desaparece, e isso não pode ser desfeito.

$note

[running_crew.button]
KO: 크루 만들기
PT: Criar crew

[running_crew.button.10]
KO: 받기
PT: Aceitar

[running_crew.button.2]
KO: 서버가 50 DIA 또는 30,000 SHARE 중 선택한 금액만 차감합니다.
PT: O servidor descontará apenas o valor selecionado: 50 DIA ou 30.000 SHARE.

[running_crew.button.3]
KO: 가입 방식
PT: Modo de entrada

[running_crew.button.4]
KO: 자유 가입
누구나 바로 들어와요
PT: Entrada livre
Qualquer pessoa pode entrar imediatamente

[running_crew.button.5]
KO: 승인 가입
신청을 받아 크루장이 정해요
PT: Entrada por aprovação
O líder do crew decide após a solicitação

[running_crew.button.6]
KO: 검색
PT: Buscar

[running_crew.button.7]
KO: 신고
PT: Denunciar

[running_crew.button.8]
KO: 신청 취소
PT: Cancelar solicitação

[running_crew.button.9]
KO: 거절
PT: Recusar

[running_crew.dialog]
KO: 크루 이름 바꾸기
PT: Alterar nome do crew

[running_crew.dialog.2]
KO: 다음
PT: Avançar

[running_crew.hint]
KO: 크루 검색
PT: Buscar crew

[running_crew.hint.2]
KO: 크루 이름 입력
PT: Digite o nome do crew

[running_crew.hint.3]
KO: 초기화
PT: Redefinir

[running_crew.hint.4]
KO: 2~20자로 지어 주세요
PT: Digite de 2 a 20 caracteres

[running_crew.label]
KO: ${crew.memberCount}/${crew.maxMembers}명${crew.needsApproval ?
PT: ${crew.memberCount}/${crew.maxMembers} membros${crew.needsApproval ?

[running_crew.toast]
KO: 로그인한 뒤에 다시 시도해 주세요.
PT: Faça login e tente novamente.

[running_crew.toast.10]
KO: 유료 엠블럼은 크루장만 살 수 있어요.
PT: Apenas o líder do crew pode comprar emblemas pagos.

[running_crew.toast.11]
KO: 이미 크루가 가진 엠블럼이에요.
PT: O crew já possui este emblema.

[running_crew.toast.12]
KO: 엠블럼을 사지 못했어요. 잠시 뒤 다시 해 주세요.
PT: Não foi possível comprar o emblema. Tente novamente em instantes.

[running_crew.toast.13]
KO: 엠블럼은 자주 바꿀 수 없어요. 잠시 뒤에 다시 바꿔 주세요.
PT: Os emblemas não podem ser alterados com frequência. Tente novamente mais tarde.

[running_crew.toast.14]
KO: 아직 쓸 수 없는 테두리나 엠블럼이에요.
PT: Esta moldura ou emblema ainda não está disponível.

[running_crew.toast.15]
KO: 엠블럼을 바꾸지 못했어요. 잠시 뒤 다시 해 주세요.
PT: Não foi possível alterar o emblema. Tente novamente em instantes.

[running_crew.toast.16]
KO: 이 폰에만 저장했어요. 서버에 크루가 생기면 함께 저장돼요.
PT: Salvo apenas neste celular. Será salvo quando o crew for criado no servidor.

[running_crew.toast.17]
KO: 크루 엠블럼을 바꿨어요.
PT: O emblema do crew foi alterado.

[running_crew.toast.18]
KO: 가입
PT: Entrar

[running_crew.toast.19]
KO: "${crew.name}" 크루에 가입했어요.
PT: Você entrou no crew "${crew.name}".

[running_crew.toast.2]
KO: 새 크루 창설 완료 (−$_createCrewDiaCost DIA)
PT: Novo crew criado (−$_createCrewDiaCost DIA)

[running_crew.toast.20]
KO: 가입을 신청했어요. 승인되면 크루원이 돼요.
PT: Solicitação enviada. Você se tornará membro quando for aprovado.

[running_crew.toast.21]
KO: 이미 다른 크루에 있거나 신청해 둔 곳이 있거나 인원이 가득 찼어요.
PT: Você já está em outro crew, possui uma solicitação pendente ou o crew está cheio.

[running_crew.toast.22]
KO: 이 크루에는 들어갈 수 없어요.
PT: Não é possível entrar neste crew.

[running_crew.toast.23]
KO: 가입하지 못했어요. 잠시 뒤 다시 해 주세요.
PT: Falha ao entrar. Tente novamente em instantes.

[running_crew.toast.24]
KO: 가입 신청을 거뒀어요.
PT: Solicitação de entrada cancelada.

[running_crew.toast.25]
KO: 거두지 못했어요. 잠시 뒤 다시 해 주세요.
PT: Não foi possível cancelar. Tente novamente em instantes.

[running_crew.toast.26]
KO: 자유 가입으로 바꿨어요.
PT: Alterado para entrada livre.

[running_crew.toast.27]
KO: 승인 가입으로 바꿨어요.
PT: Alterado para entrada por aprovação.

[running_crew.toast.28]
KO: 크루 이름을 "$name"(으)로 바꿨어요.
PT: Nome do crew alterado para "$name".

[running_crew.toast.29]
KO: 신청 목록을 불러오지 못했어요.
PT: Não foi possível carregar a lista de solicitações.

[running_crew.toast.3]
KO: 새 크루 창설 완료 (−$_createCrewShareCost SHARE)
PT: Novo crew criado (−$_createCrewShareCost SHARE)

[running_crew.toast.30]
KO: ${request.nickname}님을 받았어요.
PT: Aceitou ${request.nickname}.

[running_crew.toast.31]
KO: ${request.nickname}님의 신청을 거절했어요.
PT: Recusou a solicitação de ${request.nickname}.

[running_crew.toast.32]
KO: 이미 다른 크루에 있거나 인원이 가득 찼어요.
PT: Já está em outro crew ou o crew está cheio.

[running_crew.toast.33]
KO: 처리하지 못했어요. 잠시 뒤 다시 해 주세요.
PT: Não foi possível processar. Tente novamente em instantes.

[running_crew.toast.34]
KO: 크루를 없앴어요.
PT: O crew foi excluído.

[running_crew.toast.35]
KO: 없애지 못했어요. 잠시 뒤 다시 해 주세요.
PT: Não foi possível excluir. Tente novamente em instantes.

[running_crew.toast.36]
KO: 크루 나가기
PT: Sair do crew

[running_crew.toast.37]
KO: "${mine.crew.name}" 크루에서 나갈까요? 다시 가입할 수 있어요.
PT: Deseja sair do crew "${mine.crew.name}"? Você poderá entrar novamente mais tarde.

[running_crew.toast.38]
KO: 나가기
PT: Sair

[running_crew.toast.39]
KO: 크루에서 나왔어요.
PT: Você saiu do crew.

[running_crew.toast.4]
KO: 크루 창설 실패: $error
PT: Falha ao criar crew: $error

[running_crew.toast.40]
KO: 크루장은 나갈 수 없어요.
PT: O líder do crew não pode sair.

[running_crew.toast.41]
KO: 나가지 못했어요. 잠시 뒤 다시 해 주세요.
PT: Não foi possível sair. Tente novamente em breve.

[running_crew.toast.42]
KO: 지금은 신고할 수 없어요.
PT: Não é possível denunciar no momento.

[running_crew.toast.43]
KO: 신고했어요. 운영자가 확인할게요.
PT: Denúncia enviada. Um administrador irá verificar.

[running_crew.toast.44]
KO: 신고하지 못했어요. 잠시 뒤 다시 해 주세요.
PT: Não foi possível denunciar. Tente novamente em breve.

[running_crew.toast.45]
KO: 크루장 넘기기
PT: Transferir liderança do crew

[running_crew.toast.46]
KO: ${member.nickname}님이 새 크루장이에요.
PT: ${member.nickname} é o novo líder do crew.

[running_crew.toast.47]
KO: 넘기지 못했어요. 잠시 뒤 다시 해 주세요.
PT: Não foi possível transferir. Tente novamente em breve.

[running_crew.toast.48]
KO: ${member.nickname}님을 부크루장으로 했어요.
PT: ${member.nickname} foi definido(a) como vice-líder do crew.

[running_crew.toast.5]
KO: 전체 랭킹을 표시합니다.
PT: Exibindo o ranking geral.

[running_crew.toast.6]
KO: "$result" 검색 결과를 표시합니다.
PT: Exibindo resultados para "$result".

[running_crew.toast.7]
KO: 크루에 들어가면 크루 룸을 볼 수 있어요.
PT: Junte-se ao crew para ver a sala do crew.

[running_crew.toast.8]
KO: 엠블럼은 자주 바꿀 수 없어요. 약 $days일 뒤에 다시 바꿀 수 있어요.
PT: Os emblemas não podem ser alterados com frequência. Tente novamente em cerca de $days dias.

[running_crew.toast.9]
KO: DIA가 부족해요.
PT: DIA insuficiente.

[security_privacy_center.body]
KO: 적립 규칙, 내 거래 내역, 기부 정산, 기록 이의 신청을 한곳에서 확인해요.
PT: Confira as regras de acúmulo, histórico de transações, liquidação de doações e recursos de registros em um só lugar.

[security_privacy_center.body.2]
KO: 서버 원장에 기록된 지급·사용 내역
PT: Histórico de pagamentos e uso registrado no livro-razão do servidor

[security_privacy_center.body.3]
KO: 기부 정산
PT: Liquidação de doações

[security_privacy_center.body.4]
KO: 내가 기여한 금액 · 이번 달 기부
PT: Valor com que contribuí · Doações deste mês

[security_privacy_center.body.5]
KO: 로그인된 기기
PT: Dispositivos conectados

[security_privacy_center.body.6]
KO: 내 계정을 연 기기 · 모든 기기에서 로그아웃
PT: Dispositivos com minha conta aberta · Sair de todos os dispositivos

[security_privacy_center.body.7]
KO: 기록 소명 및 고객센터
PT: Verificação de registros e atendimento

[security_privacy_center.body.8]
KO: 검증 결과에 이의가 있을 때
PT: Quando você discordar dos resultados de verificação

[share_dia_exchange.body]
KO: 이번 주 남은 한도 ${quote.remainingDia} / ${quote.weeklyCapDia} DIA
PT: Limite semanal restante: ${quote.remainingDia} / ${quote.weeklyCapDia} DIA

[share_dia_exchange.body.2]
KO: ${quote.unitDia} DIA 단위 · 교환 가능 SHARE ${quote.spendableShare}
PT: Em unidades de ${quote.unitDia} DIA · SHARE trocável: ${quote.spendableShare}

[share_dia_exchange.body.3]
KO: 추천 보상 잠금 ${quote.lockedShare} SHARE
PT: Recompensa de indicação bloqueada: ${quote.lockedShare} SHARE

[share_dia_exchange.button]
KO: SHARE → DIA 교환
PT: Trocar SHARE por DIA

[share_dia_exchange.button.2]
KO: DIA 팩 · 준비 중
PT: Pacote DIA · Em breve

[share_dia_exchange.button.3]
KO: 교환 중...
PT: Trocando...

[share_dia_exchange.button.4]
KO: 교환
PT: Trocar

[share_dia_exchange.toast]
KO: ${result.rateSharePerDia} SHARE = 1 DIA 교환이 반영되었습니다.
PT: Troca de ${result.rateSharePerDia} SHARE = 1 DIA realizada.

[shop.accessory_shop_grid.body]
KO: 아직 준비 중이에요
PT: Ainda em preparação

[shop.accessory_shop_grid.body.2]
KO: ${accessory.tierLock!.labelKo} 티어
PT: Nível ${accessory.tierLock!.labelKo}

[shop.accessory_shop_grid.button]
KO: 가격은 바뀔 수 있어요.
PT: O preço pode mudar.

[shop.accessory_shop_grid.button.2]
KO: 입혀 보기
PT: Experimentar

[shop.accessory_shop_grid.button.3]
KO: 벗기
PT: Tirar

[shop.accessory_shop_grid.button.4]
KO: 입기
PT: Vestir

[shop.accessory_shop_grid.button.5]
KO: ${a.tierLock!.labelKo} 티어가 되면 살 수 있어요
PT: Disponível no nível ${a.tierLock!.labelKo}

[shop.accessory_shop_grid.button.6]
KO: 사기 · ${a.priceLabel}
PT: Comprar · ${a.priceLabel}

[shop.accessory_shop_grid.button.7]
KO: 티어 보상이에요
PT: É uma recompensa de nível

[shop.accessory_shop_grid.toast]
KO: 서버에 연결되면 살 수 있어요.
PT: Você pode comprar assim que conectar ao servidor.

[shop.accessory_shop_grid.toast.2]
KO: }가 모자라거나 이미 가진 소품이에요.
PT: } insuficiente ou acessório já adquirido.

[shop.accessory_shop_grid.toast.3]
KO: 아직 티어가 모자라요.
PT: Seu nível ainda não é suficiente.

[shop.accessory_shop_grid.toast.4]
KO: 사지 못했어요. 잠시 뒤 다시 해 주세요.
PT: Não foi possível comprar. Tente novamente em instantes.

[shop.battle_pass_grant.body]
KO: 시즌 1 프레임
PT: Moldura da Temporada 1

[shop.battle_pass_grant.body.2]
KO: 시즌 1 배지
PT: Emblema da Temporada 1

[shop.battle_pass_grant.body.3]
KO: 시즌 1 플러스 프레임
PT: Moldura Plus da Temporada 1

[shop.battle_pass_grant.body.4]
KO: 시즌 1 스킨
PT: Visual da Temporada 1

[shop.battle_pass_grant.body.5]
KO: 시즌 1 플러스 배지
PT: Emblema Plus da Temporada 1

[shop.cosmetics_catalog.body]
KO: 러닝화 스킨
PT: Visual de tênis de corrida

[shop.cosmetics_catalog.body.2]
KO: 결과 카드 프레임
PT: Moldura do cartão de resultado

[shop.friend_ghost_run.body]
KO: ${AppStrings.storeItemFriendGhost} · 보유 $count
PT: ${AppStrings.storeItemFriendGhost} · Em estoque: $count

[shop.friend_ghost_run.body.2]
KO: 비교 시작
PT: Iniciar comparação

[shop.friend_ghost_run.hint]
KO: 친구 아이디
PT: ID do amigo

[shop.friend_ghost_run.hint.2]
KO: 기록 아이디
PT: ID do registro

[shop.friend_ghost_run.toast]
KO: 친구 고스트 페이스 보유량이 없습니다. 상점에서 구매해 주세요.
PT: Você não tem Ritmo Fantasma de Amigo. Compre na loja.

[shop.friend_ghost_run.toast.2]
KO: 친구 고스트 ${formatPaceSecPerKm(pace)}
PT: Fantasma de amigo ${formatPaceSecPerKm(pace)}

[shop.friend_ghost_run.toast.3]
KO: 내 최고 기록 비교는 무료입니다. 티켓을 쓰지 않았습니다.
PT: Comparar com seu melhor recorde é grátis. Nenhum tíquete foi usado.

[shop.friend_ghost_run.toast.4]
KO: 친구 기록을 확인하지 못했습니다.
PT: Não foi possível verificar o registro do amigo.

[shop.friend_ghost_run.toast.5]
KO: 친구 고스트를 사용하지 못했습니다.
PT: Não foi possível usar o fantasma de amigo.

[shop.server_item_use_button.body]
KO: ${widget.label} · 보유 $count
PT: ${widget.label} · Possui $count

[shop.server_item_use_button.button]
KO: ${widget.label} · 보유 $shown/$cap
PT: ${widget.label} · Possui $shown/$cap

[shop.server_item_use_button.toast]
KO: ${widget.label} 보유량이 없습니다.
PT: Você não possui ${widget.label}.

[shop.server_item_use_button.toast.2]
KO: ${widget.label} 사용 완료
PT: ${widget.label} usado(a)

[shop.server_item_use_button.toast.3]
KO: ${widget.label} 을 사용하지 못했습니다.
PT: Não foi possível usar ${widget.label}.

[shop.store_look.body]
KO: 심박·상황에 맞춘 심층 코칭
PT: Treinamento aprofundado adaptado à frequência cardíaca e à situação

[shop.store_look.body.2]
KO: 월간
PT: Mensal

[shop.store_look.body.3]
KO: 연간
PT: Anual

[shop.store_look.body.4]
KO: 보관함 $owned
PT: Inventário $owned

[shop.streak_item_message.body]
KO: 세이프가드는 최대 2개까지 보유할 수 있습니다.
PT: Você pode ter até 2 Safeguards.

[shop.streak_item_message.body.10]
KO: 그 기록에는 페이스가 없습니다.
PT: Esse registro não possui dados de ritmo.

[shop.streak_item_message.body.11]
KO: 10회 묶음은 한 장씩 사용합니다.
PT: O pacote de 10 é usado um tíquete de cada vez.

[shop.streak_item_message.body.12]
KO: 이미 보유한 코스메틱입니다.
PT: Você já possui este item cosmético.

[shop.streak_item_message.body.13]
KO: 이번 시즌에 판매하지 않는 아이템입니다.
PT: Este item não está à venda nesta temporada.

[shop.streak_item_message.body.14]
KO: 보유한 뒤에 장착할 수 있습니다.
PT: Você pode equipar após obter.

[shop.streak_item_message.body.15]
KO: 코스메틱은 사용해서 사라지지 않습니다.
PT: Itens cosméticos não são consumidos após o uso.

[shop.streak_item_message.body.2]
KO: 심폐소생권은 한 달에 2번까지 사용할 수 있습니다.
PT: Os tíquetes de reanimação podem ser usados até 2 vezes por mês.

[shop.streak_item_message.body.3]
KO: 되돌릴 끊긴 스트릭이 없습니다.
PT: Não há sequência interrompida para restaurar.

[shop.streak_item_message.body.4]
KO: 스트릭이 끊긴 지 72시간이 지나 되돌릴 수 없습니다.
PT: Já se passaram mais de 72 horas desde que a sequência foi interrompida, portanto não é possível restaurá-la.

[shop.streak_item_message.body.5]
KO: 막을 빠진 날이 없습니다.
PT: Não há dias perdidos para proteger.

[shop.streak_item_message.body.6]
KO: 추가 참가권은 대회에 참가할 때 사용됩니다.
PT: Os tíquetes de entrada extras são usados ao participar de competições.

[shop.streak_item_message.body.7]
KO: 친구 기록을 찾지 못했습니다.
PT: Não foi possível encontrar o registro do amigo.
