# 번역 검수 요청 — 쉐어런 (Brazilian Portuguese) · 파트 3/8

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
[app.itemInventoryCoachOnePointHint]
KO: 러닝을 시작하면 사용됩니다. 하루 1회.
PT: Usado ao começar a correr. 1 vez ao dia.

[app.itemInventoryCprQuantity]
KO: 보유량: 3/3
PT: Possui: 3/3

[app.itemInventoryCrewCheerHint]
KO: 하루 1회. 대회 SHARE 보상만 10% 늘어납니다.
PT: 1 vez ao dia. Apenas as recompensas em SHARE do torneio aumentam 10%.

[app.itemInventoryDonationMatchNote]
KO: 100 VALUE. 운영자 명의 1,000원이 러닝 기부 풀에 더해지고 내 이름이 함께 표시됩니다. 영수증은 없습니다.
PT: 100 VALUE. 1.000 KRW em nome do operador são adicionados ao fundo de doação de corrida e seu nome é exibido junto. Recibos não são emitidos.

[app.itemInventoryDonationMatchUse]
KO: 매칭하기
PT: Combinar

[app.itemInventoryExtraEntryHint]
KO: 모집 마감·정원 초과 참가 시 사용됩니다. 하루 2회.
PT: Usado ao participar após encerramento das inscrições ou lotação. 2 vezes ao dia.

[app.itemInventoryFriendGhostHint]
KO: 러닝 중 친구 기록과 비교합니다. 내 최고 기록은 무료입니다.
PT: Compare com o recorde de um amigo enquanto corre. Seu melhor recorde pessoal é gratuito.

[app.itemInventoryRestDayNote]
KO: 매주 1회 무료. 추가 보유분만 VALUE로 샀습니다. 휴식일은 출석으로 세지 않고 스트릭도 끊지 않습니다.
PT: Grátis 1 vez por semana. Apenas a quantidade adicional foi comprada com VALUE. Dias de descanso não contam como presença e não quebram a sequência.

[app.itemInventoryRestDayToday]
KO: 오늘 휴식
PT: Descanso hoje

[app.itemInventoryRestDayYesterday]
KO: 어제 휴식
PT: Descanso ontem

[app.itemInventorySafeGuardQuantity]
KO: 보유량: 1/1
PT: Possui: 1/1

[app.itemInventoryTitle]
KO: 내 아이템 보관함
PT: Meu inventário de itens

[app.itemInventoryUse]
KO: 사용하기
PT: Usar

[item_inventory.body]
KO: 보유량: ${shop.cprCount}
PT: Possui: ${shop.cprCount}

[item_inventory.body.2]
KO: 보유량: ${shop.safeGuardCount}
PT: Possui: ${shop.safeGuardCount}

[item_inventory.body.3]
KO: 보유량: ${shop.coachOnePointCount}
PT: Possui: ${shop.coachOnePointCount}

[item_inventory.body.4]
KO: 보유량: ${shop.extraEntryCount}
PT: Possui: ${shop.extraEntryCount}

[item_inventory.body.5]
KO: 보유량: ${shop.friendGhostCount}
PT: Possui: ${shop.friendGhostCount}

[item_inventory.body.6]
KO: 보유량: ${shop.crewCheerCount}
PT: Possui: ${shop.crewCheerCount}

[item_inventory.body.7]
KO: 보유량: ${shop.boostRunCount}
${AppStrings.itemInventoryBoostRunQuantityNote}
PT: Em estoque: ${shop.boostRunCount}
${AppStrings.itemInventoryBoostRunQuantityNote}

[item_inventory.body.8]
KO: 보유량: ${shop.stepIncubatorCount}
${AppStrings.itemInventoryStepIncubatorQuantityNote}
PT: Em estoque: ${shop.stepIncubatorCount}
${AppStrings.itemInventoryStepIncubatorQuantityNote}

[item_inventory.body.9]
KO: 추가 보유: ${shop.restDayCount}
${AppStrings.itemInventoryRestDayNote}
PT: Adicional em estoque: ${shop.restDayCount}
${AppStrings.itemInventoryRestDayNote}

[item_inventory.toast]
KO: 이미 처리된 매칭입니다. VALUE는 한 번만 차감됩니다.
PT: Combinação já processada. O VALUE será deduzido apenas uma vez.

[item_inventory.toast.2]
KO: 기부 매칭을 기록했습니다.
PT: Combinação de doação registrada.

[item_inventory.toast.3]
KO: 기부 매칭을 기록하지 못했습니다.
PT: Não foi possível registrar a combinação de doação.

[item_inventory.toast.4]
KO: 이미 처리된 휴식일 지정입니다.
PT: Atribuição de dia de descanso já processada.

[item_inventory.toast.5]
KO: $label 완료
PT: $label concluído

[item_inventory.toast.6]
KO: 휴식일을 지정하지 못했습니다.
PT: Não foi possível definir o dia de descanso.

[item_inventory.toast.7]
KO: $title 보유량이 없습니다. 상점에서 구매해 주세요.
PT: Você não possui $title. Compre na loja.

[item_inventory.toast.8]
KO: $title 사용 완료
PT: $title usado

[item_inventory.toast.9]
KO: $title 을 사용하지 못했습니다.
PT: Não foi possível usar $title.

[jena_validation.jena_pending_gate.body]
KO: 케이던스(발구름) 데이터가 없거나 0입니다. 기록이 보류되었습니다.
PT: Os dados de cadência estão ausentes ou zerados. O registro foi colocado em espera.

[jena_validation.jena_pending_gate.body.2]
KO: 심박수 추이가 페이스 증가에 반응하지 않아 차량·자전거·킥보드 탑승이 의심됩니다.
PT: A frequência cardíaca não reagiu ao aumento de ritmo, levantando suspeita de uso de veículo, bicicleta ou patinete.

[jena_validation.jena_pending_gate.body.3]
KO: GPS 오차 범위를 넘는 순간 이동 속도가 검출되어 기록이 거절되었습니다.
PT: Foi detectada uma velocidade de deslocamento instantânea que excede a margem de erro do GPS, e o registro foi rejeitado.

[jena_validation.jena_pending_gate.body.4]
KO: 비정상적인 GPS 순간 속도가 검출되어 기록이 보류되었습니다.
PT: Foi detectada uma velocidade instantânea anormal de GPS, e o registro foi colocado em espera.

[jena_validation.mock_jena_validation_service.body]
KO: GPS 궤적 또는 거리 데이터가 부족합니다.
PT: Os dados de trajetória ou distância do GPS são insuficientes.

[jena_validation.mock_jena_validation_service.body.2]
KO: 순수 노력 러닝으로 Jena AI 검증이 완료되었습니다.
PT: Verificação da Jena AI concluída como corrida de esforço genuíno.

[jena_validation.verification_guidance.body]
KO: 이번 대회의 검증 최소 거리는 $distance예요. 대회 거리가 더 짧아도 1km는 넘어야 해요.
PT: A distância mínima de verificação para esta competição é $distance. Mesmo que a distância da competição seja menor, deve ser superior a 1 km.

[jena_validation.verification_guidance.body.2]
KO: 분당 걸음 수는 120~210이어야 해요.
PT: Os passos por minuto devem estar entre 120 e 210.

[jena_validation.verification_guidance.body.3]
KO: 워치 심박은 운영자 대회 상급·하프·파이널에서만 필요해요.
PT: A frequência cardíaca do relógio só é necessária em competições do operador nos níveis avançado, meia maratona e final.

[jena_validation.verification_guidance.body.4]
KO: 이 대회는 워치 심박이 있어야 완주로 인정돼요.
PT: Esta competição exige a frequência cardíaca do relógio para ser reconhecida como concluída.

[jena_validation.verification_guidance.body.5]
KO: 기록은 언제나, 보상은 검증된 달리기에만.
PT: Registros sempre, recompensas apenas para corridas verificadas.

[jena_validation.verification_guidance.body.6]
KO: 검증 안내
PT: Guia de verificação

[jena_validation.verification_guidance.body.7]
KO: 확인하고 참가
PT: Confirmar e participar

[jena_validation.verification_guidance.body.8]
KO: 다시 보지 않기
PT: Não mostrar novamente

[jena_validation.verification_reason.body]
KO: 거리가 이번 대회의 최소 거리보다 짧아요. 대회 거리만큼, 적어도 1km는 달려야 해요. 기록은 남고 보상은 지급되지 않아요.
PT: A distância é menor que a distância mínima desta competição. Você deve correr pelo menos a distância da competição e no mínimo 1 km. O registro é salvo, mas nenhuma recompensa é concedida.

[jena_validation.verification_reason.body.2]
KO: 분당 걸음 수가 120~210 범위를 벗어났어요. 기록은 남고 보상은 지급되지 않아요.
PT: Os passos por minuto ficaram fora do intervalo de 120 a 210. O registro é salvo, mas nenhuma recompensa é concedida.

[jena_validation.verification_reason.body.3]
KO: 상급·하프·파이널 대회는 워치 심박이 있어야 완주로 인정돼요. 심박이 없어 보상은 지급되지 않아요.
PT: Competições dos níveis avançado, meia maratona e final exigem a frequência cardíaca do relógio para serem consideradas concluídas. Sem dados de frequência cardíaca, nenhuma recompensa é concedida.

[jena_validation.verification_reason.body.4]
KO: 평균 심박이 달리기라고 보기엔 낮아요. 기록은 남고 보상은 지급되지 않아요.
PT: A frequência cardíaca média é muito baixa para ser considerada uma corrida. O registro é salvo, mas nenhuma recompensa é concedida.

[jena_validation.verification_reason.body.5]
KO: 심박이 거의 변하지 않아 달리기로 확인되지 않았어요. 기록은 남고 보상은 지급되지 않아요.
PT: A frequência cardíaca quase não variou, portanto não pôde ser confirmada como corrida. O registro é salvo, mas nenhuma recompensa é concedida.

[jena_validation.verification_reason.body.6]
KO: 워치가 없어 보폭을 확인했는데, 거리와 걸음 수가 달리기 범위가 아니에요. 기록은 남고 보상은 지급되지 않아요.
PT: Como não havia relógio, o comprimento da passada foi verificado, mas a distância e a contagem de passos não estão na faixa de corrida. O registro é salvo, mas nenhuma recompensa é concedida.

[jena_validation.verification_reason.body.7]
KO: 이동 속도가 차량에 가까워 달리기로 인정되지 않았어요. 기록은 남고 보상은 지급되지 않아요.
PT: A velocidade de deslocamento foi próxima à de um veículo e não foi reconhecida como corrida. O registro é salvo, mas nenhuma recompensa é concedida.

[jena_validation.verification_reason.body.8]
KO: 킥보드나 탑승으로 보여 보상은 지급되지 않아요. 기록은 남아요.
PT: Parece uso de patinete ou transporte, por isso nenhuma recompensa é concedida. O registro é salvo.

[jena_validation.verification_reason.body.9]
KO: 자전거 탑승으로 보여 보상은 지급되지 않아요. 기록은 남아요.
PT: Parece uso de bicicleta, por isso nenhuma recompensa é concedida. O registro é salvo.

[launch.intro.body]
KO: 걸으면 SHARE가 쌓여요
PT: Caminhe e acumule SHARE

[launch.intro.body.10]
KO: +100원
PT: +100 wons

[launch.intro.body.11]
KO: 회사(운영자) 자금으로 기부 예정 · 내가 내는 돈은 없어요 · 내 기여는 앱에서 확인
PT: Prevista com recursos da empresa (administração) · Nenhum custo para você · Confira sua contribuição no app

[launch.intro.body.13]
KO: 지금
달팽이
PT: Atualmente
Caracol

[launch.intro.body.14]
KO: 등급을
받으면
PT: Ao receber
um nível

[launch.intro.body.15]
KO: 티어가
오르면
PT: Ao subir
de categoria

[launch.intro.body.2]
KO: 한 걸음이 나눔이 된다
PT: Cada passo se torna uma doação

[launch.intro.body.3]
KO: 내 기록은 어느 폰에서나 그대로예요
PT: Seus registros continuam os mesmos em qualquer celular

[launch.intro.body.4]
KO: 100걸음마다 10 SHARE를 받아요. 모은 SHARE로 대회에 참가할 수 있어요.
PT: Ganhe 10 SHARE a cada 100 passos. Use os SHARE acumulados para participar de competições.

[launch.intro.body.5]
KO: SHARE는 현금으로 바꿀 수 없는 활동 보상이고, 하루에 받을 수 있는 양에 한도가 있어요.
PT: O SHARE é uma recompensa por atividade que não pode ser trocada por dinheiro, e há um limite diário para a quantidade que você pode receber.

[launch.intro.body.6]
KO: 검증된 모든 달리기, 1km마다 운영자가 100원을 기부할 예정이에요. 내가 보탠 만큼은 앱에서 확인할 수 있어요.
PT: Para cada corrida verificada, o operador pretende doar 100 wons a cada 1 km. Você pode conferir sua contribuição no app.

[launch.intro.body.7]
KO: 운영자의 월 기부 예산 안에서 진행될 예정이에요. 예산을 다 쓴 달은 넘는 거리가 기록으로 남아요.
PT: Está previsto acontecer dentro do orçamento mensal de doações do operador. Nos meses em que o orçamento for esgotado, a distância excedente continuará registrada.

[launch.intro.body.8]
KO: 걷기·달리기 기록은 서버에 저장돼요. 폰을 바꿔도 로그인하면 이어져요.
PT: Os registros de caminhada e corrida são salvos no servidor. Mesmo que troque de celular, basta fazer login para continuar.

[launch.intro.body.9]
KO: 100걸음
PT: 100 passos

[launch.intro.button]
KO: 시작하기
PT: Começar

[launch.intro.button.2]
KO: 이미 계정이 있어요 · 로그인
PT: Já tenho uma conta · Entrar

[legal.health_data_consent.body]
KO: 체크해야 워치 연동·심박 검증이 활성화됩니다.
PT: Marque para ativar a sincronização com o relógio e a verificação de frequência cardíaca.

[legal_constants.body]
KO: 결제 취소 (현금 환불)
PT: Cancelar pagamento (reembolso em dinheiro)

[legal_constants.body.10]
KO: 마케팅·활동 알림 (선택)
PT: Notificações de marketing e atividades (Opcional)

[legal_constants.body.12]
KO: 부정 러닝·결제 어뷰징은 계정 제한 대상이 될 수 있습니다.
PT: Corridas fraudulentas e abuso de pagamentos podem estar sujeitos a restrições de conta.

[legal_constants.body.14]
KO: 전체 내용은 개인정보 처리방침 전문에서 확인할 수 있습니다.
PT: Você pode conferir todos os detalhes na Política de Privacidade completa.

[legal_constants.body.17]
KO: 대회 모집, 검증 결과, 리워드·기부 알림을 푸시로 받을 수 있습니다. 언제든 MyPage에서 변경할 수 있습니다.
PT: Você pode receber notificações push sobre inscrições para competições, resultados de verificação, recompensas e doações. É possível alterar isso a qualquer momento no MyPage.

[legal_constants.body.18]
KO: 심박수·케이던스 원본 데이터는 기기 메모리에서 검증한 뒤 바로 폐기하며, 검증 결과 요약만 저장합니다.
PT: Os dados originais de frequência cardíaca e cadência são descartados imediatamente após a verificação na memória do dispositivo, sendo armazenado apenas um resumo dos resultados de verificação.

[legal_constants.body.19]
KO: 건강 정보 안내
PT: Aviso sobre informações de saúde

[legal_constants.body.2]
KO: [선택] 건강정보(심박수) 수집 및 이용 동의
PT: [Opcional] Consentimento para coleta e uso de dados de saúde (frequência cardíaca)

[legal_constants.body.21]
KO: 가슴 통증, 어지러움 등 이상이 느껴지면 즉시 운동을 멈추고 의료진과 상담하세요.
PT: Se sentir dor no peito, tontura ou qualquer anormalidade, pare de se exercitar imediatamente e consulte um médico.

[legal_constants.body.23]
KO: 언제든 해지할 수 있으며, 해지해도 이미 결제한 기간이 끝날 때까지 이용할 수 있습니다.
PT: Você pode cancelar a qualquer momento e continuar usando o serviço até o fim do período já pago.

[legal_constants.body.3]
KO: 건강정보 수집 동의 (선택 · 별도)
PT: Consentimento para coleta de dados de saúde (opcional · separado)

[legal_constants.body.4]
KO: 개인정보 처리방침 전문 보기
PT: Ver Política de Privacidade completa

[legal_constants.body.5]
KO: 서비스 이용약관 전문 보기
PT: Ver Termos de Serviço completos

[legal_constants.body.6]
KO: AI 생성 이미지 안내
PT: Aviso sobre imagens geradas por IA

[legal_constants.body.7]
KO: 일부 그림은 AI로 생성되었습니다. Created with Grok
PT: Algumas imagens foram geradas por IA. Created with Grok

[legal_constants.body.8]
KO: 서비스 이용약관 (필수)
PT: Termos de Serviço (Obrigatório)

[legal_constants.body.9]
KO: 개인정보 처리방침 (필수)
PT: Política de Privacidade (Obrigatório)

[app.levelTestChallengeProgress]
KO: 챌린지 진행 상황: 2/3회 완료 (3.52/5.00 KM)
PT: Progresso do desafio: 2/3 concluídas (3.52/5.00 KM)

[app.levelTestGhostPace]
KO: [고스트 페이스]
PT: [Ritmo fantasma]

[app.levelTestMyLocation]
KO: [나(현재 위치)]
PT: [Eu (Localização atual)]

[app.levelTestStartRun]
KO: 3회차 달리기 시작하기
PT: Iniciar 3ª corrida

[app.levelTestStatDistance]
KO: 현재 거리
PT: Distância atual

[app.levelTestStatPace]
KO: 현재 페이스
PT: Ritmo atual

[app.levelTestStatTime]
KO: 경과 시간
PT: Tempo decorrido

[app.levelTestSubtitle]
KO: 검증된 달리기를 서로 다른 날 3번 마치면 등급이 배정됩니다.
PT: Conclua 3 corridas verificadas em dias diferentes para receber sua classificação.

[app.levelTestTitle]
KO: 혼자 뛰기 챌린지 (등급 배정)
PT: Desafio de corrida solo (Classificação)

[app.liveRunningEffortTip]
KO: 순수 노력 목표: 완주 시 VALUE +$valueTokens
PT: Meta de esforço puro: VALUE +$valueTokens ao concluir

[app.liveRunningFinish]
KO: 종료 / 저장
PT: Finalizar / Salvar

[app.liveRunningGhostPace]
KO: 고스트 페이스
PT: Ritmo fantasma

[app.liveRunningRoomTitle]
KO: 3km 중급 챌린지
PT: Desafio 3 km intermediário

[app.liveRunningSubmissionsLeft]
KO: 제출 기회: 2/3회 남음
PT: Tentativas de envio: 2/3 restantes

[app.liveRunningYouLabel]
KO: 나 (You)
PT: Você (You)

[app.runValidationFailed]
KO: 기록 검증에 실패했습니다. 보상이 지급되지 않았습니다.
PT: Falha na verificação do registro. A recompensa não foi concedida.

[live_running.body]
KO: 1km 초보 챌린지
PT: Desafio de 1 km para iniciantes

[live_running.body.2]
KO: 나
PT: Eu

[live_running.body.3]
KO: 고스트
PT: Fantasma

[live_running.body.4]
KO: 검증 중
PT: Verificando

[live_running.toast]
KO: 센서 시작 실패: $error
PT: Falha ao iniciar o sensor: $error

[app.existingAccountApple]
KO: 애플로 가입했어요
PT: Cadastrei com a Apple

[app.existingAccountBody]
KO: 그 방법으로 로그인하면 지금 $provider${subjectParticle(provider)} 그 계정에 연결돼요. 닉네임과 재화도 그대로예요.
PT: Se entrar com esse método, seu $provider${subjectParticle(provider)} atual será vinculado a essa conta. Seu apelido e suas moedas também serão mantidos.

[app.existingAccountCreate]
KO: 새로 시작하기
PT: Começar do zero

[app.existingAccountCreateHint]
KO: 기억나지 않거나 처음이신가요?
PT: Não se lembra ou é sua primeira vez?

[app.existingAccountGoogle]
KO: 구글로 가입했어요
PT: Cadastrei com o Google

[app.existingAccountKakao]
KO: 카카오로 가입했어요
PT: Cadastrei com o Kakao

[app.existingAccountNaver]
KO: 네이버로 가입했어요
PT: Cadastrei com o Naver

[app.existingAccountNotFound]
KO: 그 방법으로 가입된 계정이 없어요. 다른 방법을 골라 주세요.
PT: Nenhuma conta foi encontrada com esse método. Escolha outro método.

[app.existingAccountTitle]
KO: 처음 가입할 때 어떤 방법을 쓰셨나요?
PT: Qual método você usou quando se cadastrou pela primeira vez?

[app.linkAttached]
KO: $method${subjectParticle(method)} 연결됐어요. 이제 어느 쪽으로 들어와도 같은 계정이에요.
PT: $method${subjectParticle(method)} foi vinculado. Agora você acessará a mesma conta de qualquer forma.

[app.linkConfirmNo]
KO: 아니에요, 다시 고를게요
PT: Não, escolher novamente

[app.linkConfirmTitle]
KO: 이 계정에 $method${objectParticle(method)} 연결할까요?
PT: Vincular $method${objectParticle(method)} a esta conta?

[app.linkConfirmYes]
KO: 네, 연결할게요
PT: Sim, vincular

[app.loginComingSoon]
KO: $provider 로그인은 준비 중입니다.
PT: O login com $provider estará disponível em breve.

[app.loginGoogle]
KO: Google로 계속하기
PT: Continuar com o Google

[app.loginGuest]
KO: 게스트(테스트)로 시작하기
PT: Começar como convidado (teste)

[app.loginGuestLoading]
KO: 게스트 로그인 중...
PT: Entrando como convidado...

[app.loginGuestNote]
KO: 게스트 모드는 워치 연동·Health Connect 테스트용 임시 계정입니다.
PT: O modo convidado é uma conta temporária para testar a sincronização com o relógio e o Health Connect.

[app.loginKakao]
KO: Kakao로 계속하기
PT: Continuar com o Kakao

[app.loginNaver]
KO: Naver로 계속하기
PT: Continuar com o Naver

[app.loginReferralHint]
KO: 추천 코드를 입력하세요...
PT: Digite o código de indicação...

[app.loginReferralLabel]
KO: 추천 코드가 있으신가요?
PT: Você tem um código de indicação?

[app.loginSaveFailed]
KO: 로그인 저장 실패: $error
PT: Falha ao salvar o login: $error

[app.loginSubtitle]
KO: 세계를 향한 나눔의 질주
PT: Uma corrida de compartilhamento para o mundo

[app.referralRedeemAlready]
KO: 이미 초대 코드를 입력했어요
PT: Você já inseriu um código de convite

[app.referralRedeemDone]
KO: 초대한 친구: 입력 완료
PT: Amigo convidado: Concluído

[app.referralRedeemEntry]
KO: 초대 코드 입력
PT: Inserir código de convite

[app.referralRedeemExpired]
KO: 가입 후 7일이 지나 입력할 수 없어요
PT: Não é possível inserir pois já se passaram 7 dias desde o cadastro

[app.referralRedeemFailed]
KO: 초대 코드를 등록하지 못했어요
PT: Não foi possível registrar o código de convite

[app.referralRedeemInvalid]
KO: 없는 초대 코드예요
PT: Este código de convite não existe

[app.referralRedeemSelf]
KO: 본인 코드는 입력할 수 없어요
PT: Você não pode inserir seu próprio código

[app.referralRedeemSubmit]
KO: 등록
PT: Registrar

[app.referralRedeemSuccess]
KO: 10,000 SHARE 지급
PT: 10.000 SHARE concedidos

[login.body]
KO: 구글 로그인에 성공했습니다!
PT: Login do Google realizado com sucesso!

[login.body.2]
KO: 로그인 실패:
PT: Falha no login:

[login.body.3]
KO: 애플 로그인에 성공했습니다!
PT: Login da Apple realizado com sucesso!

[login.body.4]
KO: 애플 로그인 실패:
PT: Falha no login da Apple:

[login.body.5]
KO: 네이버 로그인에 성공했습니다!
PT: Login do Naver realizado com sucesso!

[login.body.6]
KO: 네이버 로그인 실패:
PT: Falha no login do Naver:

[login.body.7]
KO: 카카오 로그인에 성공했습니다!
PT: Login do Kakao realizado com sucesso!

[login.body.8]
KO: 카카오 로그인 실패:
PT: Falha no login do Kakao:

[login.body.9]
KO: 닉네임 $nickname
SHARE ${groupedDigits(shareBalance)}
PT: Apelido $nickname
SHARE ${groupedDigits(shareBalance)}

[login.button]
KO: 초대 코드가 있으신가요?
PT: Tem um código de convite?

[login_connections.body]
KO: $name 연결을 해제했어요.
PT: Conexão com $name desfeita.

[login_connections.body.2]
KO: 카카오
PT: Kakao

[login_connections.body.3]
KO: 네이버
PT: Naver

[login_connections.body.4]
KO: 애플
PT: Apple

[login_connections.body.5]
KO: 구글
PT: Google

[login_connections.body.6]
KO: 같은 계정으로 여러 방법으로 로그인할 수 있어요. 연결해 두면 어떤 방법으로 들어와도 같은 SHARE와 기록이 보여요. 마지막 로그인 방법은 해제할 수 없어요.
PT: Você pode fazer login usando vários métodos para a mesma conta. Ao conectar, você verá o mesmo saldo de SHARE e registros em qualquer método. O último método de login não pode ser desconectado.

[login_connections.body.7]
KO: 연결 안 됨
PT: Não conectado

[login_connections.button]
KO: 해제하면 이 $name 계정으로는 이 쉐어런 계정에 들어올 수 없어요. 다른 로그인 방법으로는 계속 쓸 수 있어요.
PT: Se desconectar, você não poderá acessar esta conta do ShareRun com esta conta do $name. Você ainda poderá usar outros métodos de login.

[login_connections.button.2]
KO: 다시 불러오기
PT: Recarregar

[login_connections.button.3]
KO: 연결하기
PT: Conectar

[login_connections.dialog]
KO: $name 연결 해제
PT: Desconectar $name

[login_devices.body]
KO: 이 계정으로 앱을 연 기기예요. 기기 이름과 마지막으로 연 시각만 저장하고, 위치나 IP 주소는 저장하지 않아요.
PT: Dispositivos que abriram o app com esta conta. Salvamos apenas o nome do dispositivo e a hora do último acesso; localização e IP não são salvos.

[login_devices.body.2]
KO: 앱 데이터를 지우거나 다시 설치하면 같은 폰이 한 줄 더 보일 수 있어요.
PT: Limpar os dados do app ou reinstalar pode fazer com que o mesmo celular apareça em uma linha adicional.

[login_devices.body.3]
KO: 아직 기록된 기기가 없어요.
PT: Nenhum dispositivo registrado ainda.

[login_devices.body.4]
KO: 알 수 없는 기기
PT: Dispositivo desconhecido

[login_devices.body.5]
KO: $name (이 기기)
PT: $name (Este dispositivo)

[login_devices.body.6]
KO: $name · 새 기기
PT: $name · Novo dispositivo

[login_devices.body.7]
KO: ${device.osVersion} · 앱 ${device.appVersion}
마지막으로 연 시각 $when
PT: ${device.osVersion} · App ${device.appVersion}
Última abertura $when

[login_devices.button]
KO: 이 폰을 포함해 로그인된 모든 기기에서 로그아웃돼요. 다른 기기는 잠시 뒤 로그인 화면으로 돌아가요. 계속할까요?
PT: Você será desconectado de todos os dispositivos, incluindo este celular. Outros dispositivos voltarão à tela de login em breve. Continuar?

[login_devices.dialog]
KO: 모든 기기에서 로그아웃
PT: Sair de todos os dispositivos

[login_devices.toast]
KO: 로그아웃하지 못했어요. 잠시 후 다시 시도해 주세요.
PT: Não foi possível sair. Tente novamente em alguns instantes.

[app.dashboardChallenge1Sub]
KO: 참가비: 600 SHARE
PT: Taxa de inscrição: 600 SHARE

[app.dashboardChallenge1Title]
KO: 초보 1km 챌린지 🏆
PT: Desafio 1 km Iniciante 🏆

[app.dashboardChallenge2Sub]
KO: 참가비: 1,200 SHARE
PT: Taxa de inscrição: 1,200 SHARE

[app.dashboardChallenge2Title]
KO: 중급 3km 챌린지 (골드 대회)
PT: Desafio 3 km intermediário (competição Ouro)

[app.dashboardDailyMissionCapsule]
KO: 📍 오늘의 미션 확인하기 >
PT: 📍 Ver missões de hoje >

[app.dashboardDiamondBalance]
KO: 💎 보유 다이아몬드: 5개
PT: 💎 Saldo de DIA: 5

[app.dashboardDiamondBalanceOf]
KO: 💎 보유 다이아몬드: $count개
PT: 💎 Saldo de DIA: $count

[app.dashboardGradeRunLabel]
KO: 등급 배정 달리기:
PT: Corrida de classificação:

[app.dashboardGradeRunProgress]
KO: 2/3회 완료 >
PT: 2/3 concluídas >

[app.dashboardOngoingChallenges]
KO: 진행 중인 챌린지
PT: Desafios em andamento

[app.dashboardShareBalance]
KO: 보유 SHARE: 90,000
PT: Saldo de SHARE: 90,000

[app.dashboardShareBalanceOf]
KO: 보유 SHARE: $amount
PT: Saldo de SHARE: $amount

[app.dashboardStampMapTooltip]
KO: 오늘의 미션 · 스탬프 투어
PT: Missões de hoje · Tour de carimbos

[app.dashboardValueBalance]
KO: 🌱 보유 밸류(VALUE): 5,200
PT: 🌱 Saldo de VALUE: 5,200

[app.dashboardValueBalanceOf]
KO: 🌱 보유 밸류(VALUE): $amount
PT: 🌱 Saldo de VALUE: $amount

[app.dashboardViewRoom]
KO: 대회 상세 보기
PT: Ver detalhes da competição

[app.exitGuardMessage]
KO: 나눔의 질주를 잠시 쉬어가시겠습니까? 한 번 더 누르시면 종료됩니다.
PT: Deseja fazer uma pausa na corrida de compartilhamento? Pressione novamente para sair.

[app.myWalletCharge]
KO: 교환하기
PT: Trocar

[app.myWalletChargeDia]
KO: 다이아몬드
PT: DIA

[app.myWalletChargeDiaHint]
KO: 교환소에서 SHARE로 바꾸거나 연속 달리기로 모을 수 있어요
PT: Você pode trocar por SHARE no câmbio ou acumular com sequências de corrida.

[app.myWalletChargeShareHint]
KO: 활동으로 모을 수 있어요
PT: Você pode acumular por meio de atividades.

[app.myWalletChargeValue]
KO: 밸류(VALUE)
PT: VALUE

[app.myWalletChargeValueHint]
KO: 달리기로 모을 수 있어요
PT: Você pode acumular correndo.

[app.myWalletDiamondLabel]
KO: 보유 다이아몬드: $count개
PT: Saldo de DIA: $count

[app.myWalletGradeProgress]
KO: 등급 배정 달리기: $done/$total회 완료 >
PT: Corrida de classificação: $done/$total concluídas >

[app.myWalletInventoryCount]
KO: 보유 $count
PT: Possui $count

[app.myWalletInventoryEmpty]
KO: 아직 보유한 아이템이 없습니다.
PT: Você ainda não possui nenhum item.

[app.myWalletInventoryOpen]
KO: 보관함 보기
PT: Ver inventário

[app.myWalletInventoryTitle]
KO: 보유 아이템
PT: Itens em posse

[app.myWalletItemDuringRun]
KO: 달리기 중 사용 가능
PT: Disponível durante a corrida

[app.myWalletItemDuringTournament]
KO: 대회에서 사용 가능
PT: Disponível em competições

[app.myWalletRecentTransactions]
KO: 최근 거래 내역
PT: Transações recentes

[app.myWalletUse]
KO: 상점 가기
PT: Ir para a loja

[app.myWalletValueLabel]
KO: 보유 밸류(VALUE): $amount
PT: Saldo de VALUE: $amount

[app.walletUnconfirmedNote]
KO: 서버에서 확인하는 중이에요. 지금 보이는 값은 마지막으로 확인된 값이에요.
PT: Verificando com o servidor. O valor exibido é o último confirmado.

[main_dashboard.body]
KO: 상품은 다이아예요 · ${AppStrings.noCashPrizePool}
PT: Os prêmios são DIA · ${AppStrings.noCashPrizePool}

[main_dashboard.body.2]
KO: 좋은 아침이에요
PT: Bom dia

[main_dashboard.body.3]
KO: 좋은 오후예요
PT: Boa tarde

[main_dashboard.body.4]
KO: 좋은 저녁이에요
PT: Boa noite

[main_dashboard.body.5]
KO: ${_hello(DateTime.now().hour)}, $nickname님
PT: ${_hello(DateTime.now().hour)}, $nickname

[main_shell_routes.body]
KO: 결제 정보가 없어 PG 화면을 열 수 없습니다.
PT: Não é possível abrir a tela do PG porque as informações de pagamento estão ausentes.

[main_shell_routes.body.2]
KO: 대회 정보가 없어 스폰서 결제를 열 수 없습니다.
PT: Não é possível abrir o pagamento do patrocinador porque as informações da competição estão ausentes.

[main_shell_routes.button]
KO: 대회 목록으로
PT: Ir a competições

[map_crew.body]
KO: 지도 & 크루
PT: Mapa e crew

[map_crew.body.2]
KO: 크루 종합 랭킹
PT: Ranking geral da crew

[map_crew.body.3]
KO: ${crews[index].memberCount}명
PT: ${crews[index].memberCount} membros

[map_crew.body.4]
KO: 아직 크루 순위가 없어요
PT: Ainda não há rankings da crew

[map_crew.body.5]
KO: 크루 순위가 쌓이면 여기에 나타나요.
PT: Os rankings da crew aparecerão aqui conforme forem acumulados.

[map_crew.body.6]
KO: ${collectRadiusMeters.round()}m 안으로 가까이 가야 받을 수 있어요.
PT: Você precisa se aproximar a ${collectRadiusMeters.round()}m para resgatar.

[map_crew.body.7]
KO: +${box.rewardDiamond} DIA를 받았어요.
PT: Recebeu +${box.rewardDiamond} DIA.

[map_crew.body.8]
KO: ${distanceMeters!.toStringAsFixed(0)}m 떨어져 있어요
PT: A ${distanceMeters!.toStringAsFixed(0)}m de distância

[map_crew.button]
KO: 내 위치 새로고침
PT: Atualizar local

[map_crew.button.2]
KO: 다이아 상자 받기
PT: Resgatar caixa de DIA

[map_crew.button.3]
KO: 더 가까이 가 주세요
PT: Aproxime-se mais

[map_crew.crew_member_ranking_board.body]
KO: 크루원 랭킹 데이터 없음
PT: Sem dados de classificação de membros do crew

[map_crew.crew_member_ranking_board.body.2]
KO: 출석률·평균 페이스가 여기에 표시됩니다.
PT: A taxa de presença e o ritmo médio serão exibidos aqui.

[map_crew.crew_member_ranking_board.body.3]
KO: 크루원 출석률 & 평균 페이스
PT: Presença e ritmo médio dos membros do crew

[map_crew.crew_member_ranking_board.body.4]
KO: 출석률 높은 순 · 페이스 빠른 순으로 B2B 크루 성과를 추적합니다.
PT: Acompanhe o desempenho do crew B2B por maior taxa de presença e ritmo mais rápido.

[map_crew.crew_member_ranking_board.body.5]
KO: 출석 ${member.attendanceRate.toStringAsFixed(0)}%
PT: Presença ${member.attendanceRate.toStringAsFixed(0)}%

[map_crew.safe_map_panel.body]
KO: 지도 준비 중
PT: Preparando mapa

[mini_bot.body]
KO: 궁금한 게 있으면 저를 눌러 물어보세요
PT: Toque em mim se tiver alguma dúvida

[mini_bot.body.10]
KO: 하루 SHARE 한도
PT: Limite diário de SHARE

[mini_bot.body.11]
KO: 어떤 대회?
PT: Qual competição?

[mini_bot.body.12]
KO: 순위별 상금
PT: Prêmios por posición

[mini_bot.body.13]
KO: 초급은 무료?
PT: O nível iniciante é grátis?

[mini_bot.body.14]
KO: SHARE잔액
PT: Saldo de SHARE

[mini_bot.body.15]
KO: VALUE잔액
PT: Saldo de VALUE

[mini_bot.body.16]
KO: 등급
PT: Nível

[mini_bot.body.17]
KO: 오늘기부기여
PT: Contribuição de doação de hoje

[mini_bot.body.18]
KO: 이 버전에서는 앱 안에서 결제하지 않아요.
PT: Nesta versão não são feitos pagamentos dentro do app.

[mini_bot.body.19]
KO: 궁금한 걸 물어보세요
PT: Pergunte o que você quiser saber
