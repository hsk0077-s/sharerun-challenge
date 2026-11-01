# 번역 검수 요청 — 쉐어런 (Japanese) · 파트 6/6

아래는 한국어 앱 "쉐어런"(걷기·달리기 앱, 회사 자금 기부 연계)의 화면 문구를 Japanese(으)로 번역한 것입니다.
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
[app.termsAllAgree]
KO: [전체 동의] 쉐어런챌린지 이용약관
JA: 【すべて同意】ShareRunチャレンジ利用規約

[app.termsOptionalHealth]
KO: [선택] 건강정보(심박수) 수집 및
이용 동의
JA: 【任意】健康情報（心拍数）の収集および
利用への同意

[app.termsRequiredAge14]
KO: [필수] 만 14세 이상입니다
JA: 【必須】14歳以上です

[app.termsRequiredLocation]
KO: [필수] 위치기반서비스 이용약관 동의
JA: 【必須】位置情報サービス利用規約への同意

[app.termsRequiredPrivacy]
KO: [필수] 개인정보 수집 및 이용 동의
JA: 【必須】個人情報の収集および利用への同意

[app.termsRequiredService]
KO: [필수] 쉐어런챌린지 서비스 이용약관
JA: 【必須】ShareRunチャレンジサービス利用規約

[app.termsSubtitle]
KO: 안전하고 공정한 쉐어런 생태계를 위해 필수
항목에 동의해 주세요.
JA: 安全で公正なShareRunエコシステムのために、
必須項目に同意してください。

[app.termsTitle]
KO: 환영합니다!
시작 전 약관 동의가
필요합니다.
JA: ようこそ！
開始する前に利用規約への
同意が必要です。

[tournament.body]
KO: 내 티어 $userTier
JA: マイティア $userTier

[tournament.body.10]
KO: 그 밖의 대회
JA: その他の大会

[tournament.body.11]
KO: 낮은 등급 대회는 참가할 수 없어요
JA: 下位ティアの大会には参加できません

[tournament.body.12]
KO: 이미 참가했어요
JA: 既に参加しています

[tournament.body.13]
KO: 모집이 끝났어요
JA: 募集が終了しました

[tournament.body.14]
KO: 후원  ${displaySponsorName(room.sponsorName)}
JA: スポンサー  ${displaySponsorName(room.sponsorName)}

[tournament.body.15]
KO: 목표 거리
JA: 目標距離

[tournament.body.16]
KO: 참가비
JA: 参加費

[tournament.body.17]
KO: 모집
JA: 募集

[tournament.body.18]
KO: 이 대회 후원하기
JA: この大会をスポンサーする

[tournament.body.19]
KO: 내 대회 ($count)
JA: マイ大会 ($count)

[tournament.body.2]
KO: 검증된 달리기 1km마다 100원을 기부할 예정이에요.
JA: 検証されたランニング1kmごとに100ウォンを寄付する予定です。

[tournament.body.3]
KO: 회사(운영자) 자금으로 기부할 예정이며 월 한도가 있어요. 기부처는 협의 중이고 정해지면 알려 드려요.
JA: 会社（運営者）の資金で寄付する予定で、月間上限があります。寄付先は協議中で、決まり次第お知らせします。

[tournament.body.4]
KO: 아직 열린 대회가 없어요
JA: 現在開催中の大会はありません

[tournament.body.5]
KO: 새 대회가 열리면 여기에 나타나요.
JA: 新しい大会が開催されるとここに表示されます。

[tournament.body.6]
KO: 티어 대회
JA: ティア大会

[tournament.body.7]
KO: 등급을 받으면 참가할 수 있어요
JA: ランクを獲得すると参加できます

[tournament.body.8]
KO: 자유 대회
JA: 自由大会

[tournament.body.9]
KO: 누구나 참가 · 승급 점수 절반
JA: 誰でも参加可能 · 昇格ポイント半分

[tournament.button]
KO: 무료 참가권으로 참가
JA: 無料参加チケットで参加

[tournament_detail.body]
KO: 대회를 찾을 수 없습니다.
JA: 大会が見つかりません。

[tournament_detail.body.10]
KO: 상태: ${_statusKo(room.status)}
JA: ステータス: ${_statusKo(room.status)}

[tournament_detail.body.11]
KO: 목표 거리: ${room.targetDistanceKm.toStringAsFixed(1)} km
JA: 目標距離: ${room.targetDistanceKm.toStringAsFixed(1)} km

[tournament_detail.body.12]
KO: 참가비: $entryFeeShare SHARE
JA: 参加費: $entryFeeShare SHARE

[tournament_detail.body.13]
KO: 참가비: $feeText
JA: 参加費: $feeText

[tournament_detail.body.14]
KO: 모집 인원이 차지 않아 참가비를 돌려드렸어요.
JA: 定員に満たなかったため、参加費を返金いたしました。

[tournament_detail.body.15]
KO: 참가 상태: ${participantStatus ==
JA: 参加ステータス: ${participantStatus ==

[tournament_detail.body.16]
KO: 참가일: ${_formatDate(joinedAt!)}
JA: 参加日: ${_formatDate(joinedAt!)}

[tournament_detail.body.17]
KO: 모집 중
JA: 募集中

[tournament_detail.body.18]
KO: 진행 중
JA: 進行中

[tournament_detail.body.19]
KO: 취소됨
JA: キャンセル済み

[tournament_detail.body.2]
KO: 추가 참가권으로 참가
JA: 追加参加券で参加

[tournament_detail.body.20]
KO: 인원 미달로 취소됨
JA: 定員不足のためキャンセル

[tournament_detail.body.21]
KO: 종료
JA: 終了

[tournament_detail.body.3]
KO: ${room.entryFeeShare} SHARE로 참가
JA: ${room.entryFeeShare} SHAREで参加

[tournament_detail.body.4]
KO: 로그인 후 참가할 수 있습니다.
JA: ログイン後に参加できます。

[tournament_detail.body.5]
KO: 현재 티어에서는 참가할 수 없습니다.
JA: 現在のティアでは参加できません。

[tournament_detail.body.6]
KO: 정원이 가득 찼습니다.
JA: 定員に達しました。

[tournament_detail.body.7]
KO: 모집이 종료된 대회입니다.
JA: 募集が終了した大会です。

[tournament_detail.body.8]
KO: 스폰서 후원하기
JA: スポンサー支援

[tournament_detail.body.9]
KO: 후원: ${displaySponsorName(room.sponsorName)}
JA: スポンサー: ${displaySponsorName(room.sponsorName)}

[tournament_detail.button]
KO: 이미 참가한 대회입니다.
JA: 参加済みの大会です

[tournament_detail.button.2]
KO: 대회 목록에서 보기
JA: 大会一覧で見る

[tournament_detail.button.3]
KO: 러닝 시작하기
JA: ランニングを開始

[tournament_detail.title]
KO: 대회 상세
JA: 大会詳細

[tournament_model.body]
KO: 참가자 $participantCount/$maxParticipants명
JA: 参加者 $participantCount/$maxParticipants名

[tournament_model.body.2]
KO: 참가자 $participantCount명
JA: 参加者 $participantCount名

[tournament_model.body.3]
KO: 기부 풀: $donationValue VALUE
JA: 寄付プール: $donationValue VALUE

[tournament_model.body.4]
KO: 쉐어런 대회
JA: ShareRun大会

[tournament_model.body.5]
KO: 쉐어런 스폰서
JA: ShareRunスポンサー

[tournaments.prize_display.body]
KO: ${won ~/ 10000}만 원 상당 다이아
JA: ${won ~/ 10000}万ウォン相当のDIA

[tournaments.prize_display.body.2]
KO: ${_grouped(won)}원 상당 다이아
JA: ${_grouped(won)}ウォン相当のDIA

[tournaments.prize_display.body.3]
KO: 상금을 확인하는 중이에요
JA: 賞金を確認しています

[tournaments.prize_display.body.4]
KO: 상금을 불러오지 못했어요
JA: 賞金を読み込めませんでした

[tournaments.prize_race_entry.body]
KO: 참가비 확인 중
JA: 参加費を確認中

[tournaments.prize_race_entry.body.2]
KO: 참가비를 불러오지 못했습니다
JA: 参加費を読み込めませんでした

[tournaments.prize_race_entry.body.3]
KO: 무료 참가
JA: 無料参加

[tournaments.prize_race_entry.body.4]
KO: 무료 참가권 $ticketCost장
JA: 無料参加券 $ticketCost枚

[tournaments.prize_race_entry.body.5]
KO: $entryShare SHARE 또는 무료 참가권 $ticketCost장
JA: $entryShare SHARE または 無料参加券 $ticketCost枚

[tournaments.prize_race_entry.body.6]
KO: $base · 보유 $held장
JA: $base · 所持 $held枚

[tournaments.prize_race_entry.body.7]
KO: $freeEntryLabel로 참가
JA: $freeEntryLabel で参加

[tournaments.prize_race_entry.body.8]
KO: $entryShare SHARE로 참가
JA: $entryShare SHAREで参加

[tournaments.prize_race_entry.body.9]
KO: 무료 참가권 $ticketCost장으로 참가
JA: 無料参加券 $ticketCost枚で参加

[tournaments.sponsor_display.body]
KO: 운영자
JA: 運営者

[tournaments.tournament_join_flow.body]
KO: 로그인 후 챌린지에 참가할 수 있습니다.
JA: ログイン後にチャレンジに参加できます。

[tournaments.tournament_join_flow.body.2]
KO: 이미 참가한 챌린지입니다.
JA: 既に参加済みのチャレンジです。

[tournaments.tournament_join_gate.body]
KO: SHARE 잔액이 부족합니다.
JA: SHARE残高が不足しています。

[tournaments.tournament_join_outcome.body]
KO: 이미 참가한 챌린지입니다. 참가비는 다시 차감되지 않습니다.
JA: 既に参加済みのチャレンジです。参加費は再度差し引かれません。

[tournaments.tournament_join_outcome.body.2]
KO: 참가가 거절되었습니다. 참가비는 차감되지 않았습니다.
JA: 参加が拒否されました。参加費は差し引かれていません。

[tournaments.tournament_join_outcome.body.3]
KO: 참가·결제가 완료되지 않았습니다. 서버 연결 또는 인증에 실패했습니다.
JA: 参加・決済が完了しませんでした。サーバー接続または認証に失敗しました。

[tournaments.tournament_join_outcome.body.4]
KO: 참가 완료.
JA: 参加完了。

[tournaments.tournament_join_outcome.body.5]
KO: 참가 완료. 참가비 $fee SHARE가 잠겼습니다.
JA: 参加が完了しました。参加費として $fee SHARE がロックされました。

[tournaments.tournament_join_outcome.body.6]
KO: 참가 완료(디버그). 참가비 $fee SHARE가 차감되었습니다.
JA: 参加完了(デバッグ)。参加費 $fee SHAREが差し引かれました。

[user_model.body]
KO: 미연동
JA: 未連携

[user_model.body.2]
KO: 여
JA: 女

[user_model.body.3]
KO: 여성
JA: 女性

[voice_coaching.voice_coaching_cues.body]
KO: 보이스 코칭을 켤게요.
JA: 音声コーチングを開始します。

[voice_coaching.voice_coaching_cues.body.10]
KO: 심박이 좋아요. 이 페이스 유지해요.
JA: 心拍数は良好です。このペースを維持しましょう。

[voice_coaching.voice_coaching_cues.body.11]
KO: 심박이 내려왔어요. 페이스 유지해요.
JA: 心拍数が落ち着きました。ペースを維持しましょう。

[voice_coaching.voice_coaching_cues.body.12]
KO: 천 보 달성! 좋아요.
JA: 1,000歩達成！いい調子です。

[voice_coaching.voice_coaching_cues.body.13]
KO: 삼천 보예요. 페이스 잘 유지하고 있어요.
JA: 3,000歩です。いいペースを維持できています。

[voice_coaching.voice_coaching_cues.body.14]
KO: 오천 보! 잘하고 있어요.
JA: 5,000歩！よく頑張っています。

[voice_coaching.voice_coaching_cues.body.15]
KO: 팔천 보. 거의 다 왔어요.
JA: 8,000歩です。もうすぐそこです。

[voice_coaching.voice_coaching_cues.body.16]
KO: 만 보 달성! 오늘 정말 잘했어요.
JA: 10,000歩達成！今日は本当によく頑張りました。

[voice_coaching.voice_coaching_cues.body.17]
KO: $steps보 달성! 좋아요.
JA: $steps歩達成！いい調子です。

[voice_coaching.voice_coaching_cues.body.18]
KO: 1킬로미터. 호흡 유지하고 가요.
JA: 1キロメートル。呼吸を維持して進みましょう。

[voice_coaching.voice_coaching_cues.body.19]
KO: $km킬로미터. 이 페이스 유지해요.
JA: $kmキロメートル。このペースを維持しましょう。

[voice_coaching.voice_coaching_cues.body.2]
KO: 워킹 챌린지 시작이에요. 천천히 걸어볼까요?
JA: ウォーキングチャレンジのスタートです。ゆっくり歩いてみましょう。

[voice_coaching.voice_coaching_cues.body.20]
KO: 1킬로미터. 페이스 좋아요.
JA: 1キロメートル。いいペースです。

[voice_coaching.voice_coaching_cues.body.21]
KO: $km킬로미터 통과. 잘하고 있어요.
JA: $kmキロメートル通過。順調です。

[voice_coaching.voice_coaching_cues.body.3]
KO: SHARE를 수확했어요. 수고했어요.
JA: SHAREを獲得しました。お疲れさまでした。

[voice_coaching.voice_coaching_cues.body.4]
KO: 오늘의 목표 거리를 채웠어요. 대단해요!
JA: 今日の目標距離を達成しました。素晴らしいです！

[voice_coaching.voice_coaching_cues.body.5]
KO: 러닝을 시작해요. 호흡을 맞춰볼까요?
JA: ランニングを開始します。呼吸を合わせてみましょう。

[voice_coaching.voice_coaching_cues.body.6]
KO: 러닝 종료. 오늘도 잘 달렸어요.
JA: ランニング終了。今日もお疲れさまでした。

[voice_coaching.voice_coaching_cues.body.7]
KO: 200미터 남았어요.
JA: 残り200メートルです。

[voice_coaching.voice_coaching_cues.body.8]
KO: 좋아요. 호흡 유지해요.
JA: いい調子です。呼吸を維持しましょう。

[voice_coaching.voice_coaching_cues.body.9]
KO: 심박이 높아요. 속도를 줄여요.
JA: 心拍数が高くなっています。ペースを落としましょう。

[app.voiceCoachingDisable]
KO: 코칭 끄기
JA: コーチングをオフにする

[app.voiceCoachingEnable]
KO: 코칭 켜기
JA: コーチングをオンにする

[app.voiceCoachingOffTooltip]
KO: 보이스 코칭 켜기
JA: ボイスコーチングをオンにする

[app.voiceCoachingOnTooltip]
KO: 보이스 코칭 끄기
JA: ボイスコーチングをオフにする

[app.voiceCoachingSubtitle]
KO: 워킹·러닝 중 짧은 응원 멘트를 음성으로 들려줍니다
JA: ウォーキング・ランニング中に短い応援メッセージを音声でお届けします

[app.voiceCoachingTitle]
KO: 보이스 코칭
JA: ボイスコーチング

[app.voiceCoachingWalkOff]
KO: 보이스 코칭이 꺼져 있습니다
JA: ボイスコーチングはオフになっています。

[app.voiceCoachingWalkOn]
KO: 보이스 코칭 켜져 있음
JA: ボイスコーチング オン

[wallet.economy_status.body]
KO: 온보딩 & 땀방울 현황
JA: オンボーディング＆汗の結晶の状況

[wallet.economy_status.body.2]
KO: ${EconomyConstants.signupRewardSrv} SRV 지급 완료
JA: ${EconomyConstants.signupRewardSrv} SRV 付与完了

[wallet.economy_status.body.3]
KO: 가입 후 ${EconomyConstants.signupRewardSrv} SRV 대기
JA: 登録後に ${EconomyConstants.signupRewardSrv} SRV 待機中

[wallet.economy_status.body.4]
KO: 예비 러닝
JA: トライアルラン

[wallet.economy_status.body.5]
KO: ${economy.trialRunCount}/${EconomyConstants.referralTrialRunsRequired}회 · 완료 시 50,000 SHARE · 1.1km 이상 달리면 안전해요
JA: ${economy.trialRunCount}/${EconomyConstants.referralTrialRunsRequired}回 · 完了時に 50,000 SHARE · 1.1km以上走ると安全です

[wallet.economy_status.body.6]
KO: 일일 땀방울 한도
JA: 1日の汗のしずく上限

[wallet.economy_status.body.7]
KO: ${economy.referralPayoutCount}/${EconomyConstants.maxReferralPayouts}명 · 지인 3회 완료 시 30,000 SHARE
JA: ${economy.referralPayoutCount}/${EconomyConstants.maxReferralPayouts}人 · 友達が3回完了すると 30,000 SHARE

[wallet.shop_section.body]
KO: 다이아 상점
JA: DIAショップ

[wallet.shop_section.body.2]
KO: 보유 Diamond $diamondBalance
JA: 保有 Diamond $diamondBalance

[wallet.shop_section.body.3]
KO: DIA 충전하기
JA: DIAをチャージ

[wallet.shop_section.body.4]
KO: 구매
JA: 購入

[wallet_transaction_model.body]
KO: 휴식일 지정
JA: 休息日設定

[wallet_transaction_model.body.10]
KO: 러닝 땀방울 적립
JA: ランニングの汗のしずく獲得

[wallet_transaction_model.body.11]
KO: 신규 가입 보상
JA: 新規登録特典

[wallet_transaction_model.body.12]
KO: 첫 경기 무료 참가권
JA: 初回試合無料参加チケット

[wallet_transaction_model.body.13]
KO: 예비 러닝 3회 달성
JA: 予備ラン3回達成

[wallet_transaction_model.body.14]
KO: 추천인 보상 (지연 지급)
JA: 紹介者特典（遅延支給）

[wallet_transaction_model.body.15]
KO: 초대 코드 등록
JA: 招待コード登録

[wallet_transaction_model.body.16]
KO: 체험 런 1회
JA: 体験ラン1回

[wallet_transaction_model.body.17]
KO: 체험 런 3회 완료
JA: 体験ラン3回完了

[wallet_transaction_model.body.18]
KO: 친구 체험 런 3회
JA: 友達の体験ラン3回

[wallet_transaction_model.body.19]
KO: 친구 체험 런 3회 대기
JA: 友達の体験ラン3回待ち

[wallet_transaction_model.body.2]
KO: SHARE 충전
JA: SHAREチャージ

[wallet_transaction_model.body.20]
KO: 자비로운 실패 기부
JA: 慈悲深い失敗寄付

[wallet_transaction_model.body.21]
KO: 우승 상금 수령
JA: 優勝賞金の受け取り

[wallet_transaction_model.body.22]
KO: 우승 상금 50% 기부
JA: 優勝賞金の50%を寄付

[wallet_transaction_model.body.23]
KO: 우승 상금 전액 기부
JA: 優勝賞金の全額を寄付

[wallet_transaction_model.body.24]
KO: 스폰서 결제
JA: スポンサー決済

[wallet_transaction_model.body.25]
KO: Web3 외부 전송
JA: Web3外部送信

[wallet_transaction_model.body.26]
KO: 부정 러닝 예치금 몰수
JA: 不正ランニング保証金没収

[wallet_transaction_model.body.27]
KO: 워킹챌린지 코인 줍기
JA: ウォーキングチャレンジのコイン拾い

[wallet_transaction_model.body.28]
KO: 만보기 부화
JA: 万歩計の孵化

[wallet_transaction_model.body.29]
KO: 기부 완료
JA: 寄付完了

[wallet_transaction_model.body.3]
KO: 대회 참가
JA: 大会参加

[wallet_transaction_model.body.30]
KO: 챌린지 상금 지원 후원
JA: チャレンジ賞金支援スポンサー

[wallet_transaction_model.body.31]
KO: 코스메틱 장착
JA: コスメティック装着

[wallet_transaction_model.body.32]
KO: 디버그 테스트 지급
JA: デバッグテスト支給

[wallet_transaction_model.body.33]
KO: SHARE → 다이아 전환
JA: SHARE → DIAへの変換

[wallet_transaction_model.body.34]
KO: 다이아 구매
JA: DIAの購入

[wallet_transaction_model.body.35]
KO: 연속 달리기 보너스
JA: 連続ランニングボーナス

[wallet_transaction_model.body.36]
KO: 닉네임 변경
JA: ニックネーム変更

[wallet_transaction_model.body.37]
KO: 크루 선물
JA: クルーギフト

[wallet_transaction_model.body.38]
KO: 크루 응원 SHARE
JA: クルー応援SHARE

[wallet_transaction_model.body.39]
KO: 대회 열기
JA: 大会を開催

[wallet_transaction_model.body.4]
KO: 대회 보너스 DIA
JA: 大会ボーナスDIA

[wallet_transaction_model.body.40]
KO: 명예의 전당 기부
JA: 殿堂入り寄付

[wallet_transaction_model.body.41]
KO: 무료 대회 참가
JA: 無料大会に参加

[wallet_transaction_model.body.42]
KO: 참가권 지급
JA: 参加チケット支給

[wallet_transaction_model.body.43]
KO: 참가권 대신 SHARE 지급
JA: チケットの代わりにSHAREを支給

[wallet_transaction_model.body.44]
KO: 친구 체험 보상 회수
JA: 友達体験特典の回収

[wallet_transaction_model.body.45]
KO: Coach+ 심폐소생권 지급
JA: Coach+蘇生チケット支給

[wallet_transaction_model.body.46]
KO: 참가권
JA: 参加チケット

[wallet_transaction_model.body.5]
KO: 대회 상위 완주 SHARE
JA: 大会上位完走SHARE

[wallet_transaction_model.body.6]
KO: 대회 완주 VALUE
JA: 大会完走VALUE

[wallet_transaction_model.body.7]
KO: 현금 환불 요청
JA: 現金返金リクエスト

[wallet_transaction_model.body.8]
KO: 모집 미달 환불
JA: 定員割れ返金

[wallet_transaction_model.body.9]
KO: 다이아 수집
JA: DIA収集

[watch_app_preview.body]
KO: 갤럭시 워치
JA: Galaxy Watch

[watch_app_preview.body.10]
KO: 갤럭시 워치 화면 시안
JA: Galaxy Watch画面サンプル

[watch_app_preview.body.11]
KO: 워치 연결
JA: ウォッチ連携

[watch_app_preview.body.12]
KO: 워치 앱에서 아래 6자리 숫자를 입력하면 이 계정으로 연결돼요. 코드는 5분 동안, 한 번만 쓸 수 있어요. 워치는 한 대만 연결돼서, 다른 워치를 연결하면 이전 워치는 해제돼요.
JA: ウォッチアプリで以下の6桁の数字を入力すると、このアカウントに連携されます。コードは5分間、1回のみ有効です。ウォッチは1台のみ連携可能なため、別のウォッチを連携すると前のウォッチは解除されます。

[watch_app_preview.body.13]
KO: 남은 시간 $_countdown
JA: 残り時間 $_countdown

[watch_app_preview.body.14]
KO: 예정
JA: 予定

[watch_app_preview.body.15]
KO: 탭해서 다시 시작
JA: タップして再始動

[watch_app_preview.body.16]
KO: 1위!
JA: 1位！

[watch_app_preview.body.17]
KO: 대회 2명 앞서요
JA: 大会で2人リード

[watch_app_preview.body.18]
KO: 5:38/km · 17분
JA: 5:38/km · 17分

[watch_app_preview.body.19]
KO: 시안입니다. 실제 시계 화면과 조금 다를 수 있어요.
JA: サンプル画面です。実際の時計画面とは多少異なる場合があります。

[watch_app_preview.body.2]
KO: 가장 먼저 만들어요
JA: 一番最初に作成します

[watch_app_preview.body.3]
KO: 안드로이드 워치 (Wear OS)
JA: Androidウォッチ (Wear OS)

[watch_app_preview.body.4]
KO: 갤럭시 워치 다음
JA: Galaxy Watchの次

[watch_app_preview.body.5]
KO: 스마트 밴드 (샤오미 등)
JA: スマートバンド（Xiaomiなど）

[watch_app_preview.body.6]
KO: 그다음 순서로 검토해요
JA: 次に検討します

[watch_app_preview.body.7]
KO: 가민
JA: Garmin

[watch_app_preview.body.8]
KO: 애플 워치
JA: Apple Watch

[watch_app_preview.body.9]
KO: 아래 시계 화면은 시안이에요.
JA: 以下の時計画面はサンプルです。

[watch_app_preview.button]
KO: 이 계정에 연결한 워치가 모두 로그아웃돼요. 워치에 남은 기록은 다시 연결하기 전까지 올라가지 않아요. 휴대폰 로그인은 그대로예요.
JA: このアカウントに連携されたウォッチがすべてログアウトされます。ウォッチに残った記録は再連携するまでアップロードされません。スマホのログインは維持されます。

[watch_app_preview.button.2]
KO: 모두 해제
JA: すべて解除

[watch_app_preview.button.3]
KO: 워치 전용 앱
JA: ウォッチ専用アプリ

[watch_app_preview.button.4]
KO: 취소
JA: キャンセル

[watch_app_preview.button.5]
KO: 6자리 연결 코드 받기
JA: 6桁のコードを取得

[watch_app_preview.button.6]
KO: 새 코드 받기
JA: 新しいコードを取得

[watch_app_preview.button.7]
KO: 연결된 워치 ${_watches.length}/3
JA: 連携中のウォッチ ${_watches.length}/3

[watch_app_preview.button.8]
KO: 연결된 워치 모두 해제
JA: 連携中のウォッチをすべて解除

[watch_app_preview.button.9]
KO: 연결된 워치를 모두 해제했어요.
JA: 連携中のウォッチをすべて解除しました。

[watch_app_preview.dialog]
KO: 연결된 워치를 모두 해제할까요?
JA: 連携中のウォッチをすべて解除しますか？

[watch_connection.body]
KO: Garmin Connect 연동 완료
JA: Garmin Connect連携完了

[watch_connection.button]
KO: 알림 허용하고 계속
JA: 通知を許可して続ける

[watch_connection.toast]
KO: ${watchType.displayLabel} 연동이 완료되었습니다.
JA: ${watchType.displayLabel}の連携が完了しました。

[watch_connection.toast.2]
KO: 연동 중 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.
JA: 連携中にエラーが発生しました。しばらくしてからもう一度お試しください。

[watch_connection.toast.3]
KO: Health Connect 설치 화면으로 이동했습니다. 설치 후 다시 연동해 주세요.
JA: Health Connectのインストール画面に移動しました。インストール後に再度連携してください。

[watch_connection.toast.4]
KO: 권한이 거부되었습니다. 설정에서 건강 데이터 접근을 허용해 주세요.
JA: 権限が拒否されました。設定でヘルスケアデータへのアクセスを許可してください。

[watch_connection.toast.5]
KO: 외부 기기 연동 화면을 열 수 없습니다.
JA: 外部機器の連携画面を開けません。

[watch_connection.toast.6]
KO: 온보딩 상태 갱신에 실패했습니다. $error
JA: オンボーディング状態の更新に失敗しました。$error

[watch_link.garmin_cloud_oauth_adapter.body]
KO: Garmin 연동은 아직 준비 중이에요.
JA: Garmin連携は現在準備中です。

[watch_link.garmin_cloud_oauth_adapter.body.2]
KO: 이메일과 비밀번호를 입력해 주세요.
JA: メールアドレスとパスワードを入力してください。

[watch_link.garmin_cloud_oauth_adapter.body.3]
KO: 인증에 실패했습니다. Garmin 계정 정보를 확인해 주세요.
JA: 認証に失敗しました。Garminアカウント情報を確認してください。

[watch_settings.body]
KO: 브랜드별 연동 경로를 분리해 데이터 신뢰도와 법률 방어를 강화합니다.
JA: ブランド別に連携ルートを分離し、データの信頼性と法的防御を強化します。

[watch_settings.body.10]
KO: OS Health 데이터 직접 읽기
JA: OS Healthデータを直接読み取り

[watch_settings.body.2]
KO: Track A · API 연동
JA: Track A · API連携

[watch_settings.body.3]
KO: Garmin / Coros / Suunto — 브랜드 클라우드 OAuth
JA: Garmin / Coros / Suunto — ブランドクラウドOAuth

[watch_settings.body.4]
KO: Track B · OS 직접 연동
JA: Track B · OS直接連携

[watch_settings.body.5]
KO: 연동 해제
JA: 連携解除

[watch_settings.body.6]
KO: 현재 연동된 워치가 없습니다.
JA: 現在連携されているウォッチはありません。

[watch_settings.body.7]
KO: 현재 연동: ${watchType.displayLabel} (${watchType.isApiTrack ?
JA: 現在の連携: ${watchType.displayLabel} (${watchType.isApiTrack ?

[watch_settings.body.8]
KO: 건강정보 동의 후 선택할 수 있습니다.
JA: 健康データへの同意後に選択できます。

[watch_settings.body.9]
KO: 브랜드 API · OAuth
JA: ブランドAPI · OAuth

[watch_settings.button]
KO: 건강정보 동의하고 연동 시작
JA: 健康データに同意して連携を開始

[watch_settings.title]
KO: 투트랙 연동 방식
JA: ツートラック連携方式

[watch_settings.toast]
KO: 필수
JA: 必須

[watch_settings.toast.2]
KO: Health Connect 설치 후 다시 시도해 주세요.
JA: Health Connectをインストールしてからもう一度お試しください。

[watch_settings.toast.3]
KO: $label 권한이 필요합니다.
JA: $labelの権限が必要です。

[watch_settings.toast.4]
KO: 설정
JA: 設定

[widget.apple_login_button.button]
KO: Apple로 계속하기
JA: Appleで続ける

[widget.async_value_section.body]
KO: 데이터를 불러오지 못했습니다: $error
JA: データを読み込めませんでした: $error

[widget.email_verification_banner.button]
KO: 이메일 인증을 완료해 주세요. 결제·대회 참가 전에 필요할 수 있습니다.
JA: メール認証を完了してください。決済や大会参加前に必要になる場合があります。

[widget.email_verification_banner.button.2]
KO: 발송 중...
JA: 送信中...

[widget.email_verification_banner.button.3]
KO: 재발송
JA: 再送

[widget.email_verification_banner.toast]
KO: 인증 메일을 발송했습니다.
JA: 認証メールを送信しました。

[widget.email_verification_banner.toast.2]
KO: 인증 메일 발송 실패: $error
JA: 認証メールの送信に失敗しました: $error

[widget.google_signin_button.body]
KO: SVG 경로 명령이 없습니다.
JA: SVGパスコマンドがありません。

[widget.google_signin_button.button]
KO: Google 계정으로 로그인
JA: Googleでログイン

[widget.kakao_login_button.accessibility]
KO: 카카오 로그인
JA: Kakaoログイン

[widget.naver_login_button.accessibility]
KO: 네이버 로그인
JA: Naverログイン

[widget.src_bottom_nav.toast]
KO: +10 Dia 획득!
JA: +10 Dia獲得！

[widget.src_logo.accessibility]
KO: 쉐어런 로고
JA: ShareRunロゴ
