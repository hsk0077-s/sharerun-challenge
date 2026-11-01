# 번역 검수 요청 — 쉐어런 (Japanese) · 파트 3/6

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
[app.loginGuestNote]
KO: 게스트 모드는 워치 연동·Health Connect 테스트용 임시 계정입니다.
JA: ゲストモードは、ウォッチ連携・Health Connectテスト用の一時アカウントです。

[app.loginKakao]
KO: Kakao로 계속하기
JA: Kakaoで続ける

[app.loginNaver]
KO: Naver로 계속하기
JA: Naverで続ける

[app.loginReferralHint]
KO: 추천 코드를 입력하세요...
JA: 紹介コードを入力してください...

[app.loginReferralLabel]
KO: 추천 코드가 있으신가요?
JA: 紹介コードをお持ちですか？

[app.loginSaveFailed]
KO: 로그인 저장 실패: $error
JA: ログイン情報の保存に失敗しました: $error

[app.loginSubtitle]
KO: 세계를 향한 나눔의 질주
JA: 世界へと広がる分かち合いの疾走

[app.referralRedeemAlready]
KO: 이미 초대 코드를 입력했어요
JA: すでに招待コードを入力済みです

[app.referralRedeemDone]
KO: 초대한 친구: 입력 완료
JA: 招待した友達: 入力完了

[app.referralRedeemEntry]
KO: 초대 코드 입력
JA: 招待コードを入力

[app.referralRedeemExpired]
KO: 가입 후 7일이 지나 입력할 수 없어요
JA: 登録から7日が経過しているため入力できません

[app.referralRedeemFailed]
KO: 초대 코드를 등록하지 못했어요
JA: 招待コードを登録できませんでした

[app.referralRedeemInvalid]
KO: 없는 초대 코드예요
JA: 存在しない招待コードです

[app.referralRedeemSelf]
KO: 본인 코드는 입력할 수 없어요
JA: ご自身のコードは入力できません

[app.referralRedeemSubmit]
KO: 등록
JA: 登録

[app.referralRedeemSuccess]
KO: 10,000 SHARE 지급
JA: 10,000 SHARE 付与

[login.body]
KO: 구글 로그인에 성공했습니다!
JA: Googleログインに成功しました！

[login.body.2]
KO: 로그인 실패:
JA: ログイン失敗：

[login.body.3]
KO: 애플 로그인에 성공했습니다!
JA: Appleログインに成功しました！

[login.body.4]
KO: 애플 로그인 실패:
JA: Appleログイン失敗：

[login.body.5]
KO: 네이버 로그인에 성공했습니다!
JA: Naverログインに成功しました！

[login.body.6]
KO: 네이버 로그인 실패:
JA: Naverログイン失敗：

[login.body.7]
KO: 카카오 로그인에 성공했습니다!
JA: Kakaoログインに成功しました！

[login.body.8]
KO: 카카오 로그인 실패:
JA: Kakaoログイン失敗：

[login.body.9]
KO: 닉네임 $nickname
SHARE ${groupedDigits(shareBalance)}
JA: ニックネーム $nickname
SHARE ${groupedDigits(shareBalance)}

[login.button]
KO: 초대 코드가 있으신가요?
JA: 招待コードをお持ちですか？

[login_connections.body]
KO: $name 연결을 해제했어요.
JA: $nameの連携を解除しました。

[login_connections.body.2]
KO: 카카오
JA: Kakao

[login_connections.body.3]
KO: 네이버
JA: Naver

[login_connections.body.4]
KO: 애플
JA: Apple

[login_connections.body.5]
KO: 구글
JA: Google

[login_connections.body.6]
KO: 같은 계정으로 여러 방법으로 로그인할 수 있어요. 연결해 두면 어떤 방법으로 들어와도 같은 SHARE와 기록이 보여요. 마지막 로그인 방법은 해제할 수 없어요.
JA: 同じアカウントに複数の方法でログインできます。連携しておくと、どの方法でログインしても同じSHAREと記録が表示されます。最後のログイン方法は解除できません。

[login_connections.body.7]
KO: 연결 안 됨
JA: 未連携

[login_connections.button]
KO: 해제하면 이 $name 계정으로는 이 쉐어런 계정에 들어올 수 없어요. 다른 로그인 방법으로는 계속 쓸 수 있어요.
JA: 解除するとこの$nameアカウントではこのShareRunアカウントにアクセスできなくなります。他のログイン方法では引き続きご利用いただけます。

[login_connections.button.2]
KO: 다시 불러오기
JA: 再読み込み

[login_connections.button.3]
KO: 연결하기
JA: 連携する

[login_connections.dialog]
KO: $name 연결 해제
JA: $name 連携解除

[login_devices.body]
KO: 이 계정으로 앱을 연 기기예요. 기기 이름과 마지막으로 연 시각만 저장하고, 위치나 IP 주소는 저장하지 않아요.
JA: このアカウントでアプリを開いた端末です。端末名と最終アクセスタイムのみ保存し、位置情報やIPアドレスは保存しません。

[login_devices.body.2]
KO: 앱 데이터를 지우거나 다시 설치하면 같은 폰이 한 줄 더 보일 수 있어요.
JA: アプリのデータを削除するか再インストールすると、同じスマホがもう1行表示される場合があります。

[login_devices.body.3]
KO: 아직 기록된 기기가 없어요.
JA: まだ記録された端末はありません。

[login_devices.body.4]
KO: 알 수 없는 기기
JA: 不明な端末

[login_devices.body.5]
KO: $name (이 기기)
JA: $name（この端末）

[login_devices.body.6]
KO: $name · 새 기기
JA: $name · 新しい端末

[login_devices.body.7]
KO: ${device.osVersion} · 앱 ${device.appVersion}
마지막으로 연 시각 $when
JA: ${device.osVersion} · アプリ ${device.appVersion}
最終起動時間 $when

[login_devices.button]
KO: 이 폰을 포함해 로그인된 모든 기기에서 로그아웃돼요. 다른 기기는 잠시 뒤 로그인 화면으로 돌아가요. 계속할까요?
JA: このスマホを含むログイン中のすべての端末からログアウトされます。他の端末は間もなくログイン画面に戻ります。続行しますか？

[login_devices.dialog]
KO: 모든 기기에서 로그아웃
JA: すべての端末からログアウト

[login_devices.toast]
KO: 로그아웃하지 못했어요. 잠시 후 다시 시도해 주세요.
JA: ログアウトできませんでした。しばらくしてから再度お試しください。

[app.dashboardChallenge1Sub]
KO: 참가비: 600 SHARE
JA: 参加費: 600 SHARE

[app.dashboardChallenge1Title]
KO: 초보 1km 챌린지 🏆
JA: 初心者1kmチャレンジ 🏆

[app.dashboardChallenge2Sub]
KO: 참가비: 1,200 SHARE
JA: 参加費: 1,200 SHARE

[app.dashboardChallenge2Title]
KO: 중급 3km 챌린지 (골드 대회)
JA: 中級3kmチャレンジ（ゴールド大会）

[app.dashboardDailyMissionCapsule]
KO: 📍 오늘의 미션 확인하기 >
JA: 📍 今日のミッションを確認する >

[app.dashboardDiamondBalance]
KO: 💎 보유 다이아몬드: 5개
JA: 💎 保有 DIA: 5

[app.dashboardDiamondBalanceOf]
KO: 💎 보유 다이아몬드: $count개
JA: 💎 保有 DIA: $count

[app.dashboardGradeRunLabel]
KO: 등급 배정 달리기:
JA: ランク決定ラン:

[app.dashboardGradeRunProgress]
KO: 2/3회 완료 >
JA: 2/3回完了 >

[app.dashboardOngoingChallenges]
KO: 진행 중인 챌린지
JA: 進行中のチャレンジ

[app.dashboardShareBalance]
KO: 보유 SHARE: 90,000
JA: 保有 SHARE: 90,000

[app.dashboardShareBalanceOf]
KO: 보유 SHARE: $amount
JA: 保有 SHARE: $amount

[app.dashboardStampMapTooltip]
KO: 오늘의 미션 · 스탬프 투어
JA: 今日のミッション · スタンプツアー

[app.dashboardValueBalance]
KO: 🌱 보유 밸류(VALUE): 5,200
JA: 🌱 保有 VALUE: 5,200

[app.dashboardValueBalanceOf]
KO: 🌱 보유 밸류(VALUE): $amount
JA: 🌱 保有 VALUE: $amount

[app.dashboardViewRoom]
KO: 대회 상세 보기
JA: 大会詳細を見る

[app.exitGuardMessage]
KO: 나눔의 질주를 잠시 쉬어가시겠습니까? 한 번 더 누르시면 종료됩니다.
JA: 分かち合いの走りを少し休みますか？もう一度押すと終了します。

[app.myWalletCharge]
KO: 교환하기
JA: 交換する

[app.myWalletChargeDia]
KO: 다이아몬드
JA: DIA

[app.myWalletChargeDiaHint]
KO: 교환소에서 SHARE로 바꾸거나 연속 달리기로 모을 수 있어요
JA: 交換所でSHAREに交換するか、連続ランで集めることができます。

[app.myWalletChargeShareHint]
KO: 활동으로 모을 수 있어요
JA: アクティビティで集めることができます。

[app.myWalletChargeValue]
KO: 밸류(VALUE)
JA: VALUE

[app.myWalletChargeValueHint]
KO: 달리기로 모을 수 있어요
JA: ランニングで集めることができます。

[app.myWalletDiamondLabel]
KO: 보유 다이아몬드: $count개
JA: 保有 DIA: $count

[app.myWalletGradeProgress]
KO: 등급 배정 달리기: $done/$total회 완료 >
JA: ランク判定ラン: $done/$total回完了 >

[app.myWalletInventoryCount]
KO: 보유 $count
JA: 所持 $count

[app.myWalletInventoryEmpty]
KO: 아직 보유한 아이템이 없습니다.
JA: 所持しているアイテムはまだありません。

[app.myWalletInventoryOpen]
KO: 보관함 보기
JA: 保管箱を見る

[app.myWalletInventoryTitle]
KO: 보유 아이템
JA: 保有アイテム

[app.myWalletItemDuringRun]
KO: 달리기 중 사용 가능
JA: ランニング中に使用可能

[app.myWalletItemDuringTournament]
KO: 대회에서 사용 가능
JA: 大会で使用可能

[app.myWalletRecentTransactions]
KO: 최근 거래 내역
JA: 最近の取引履歴

[app.myWalletUse]
KO: 상점 가기
JA: ショップへ行く

[app.myWalletValueLabel]
KO: 보유 밸류(VALUE): $amount
JA: 保有 VALUE: $amount

[app.walletUnconfirmedNote]
KO: 서버에서 확인하는 중이에요. 지금 보이는 값은 마지막으로 확인된 값이에요.
JA: サーバーで確認中です。表示されている値は最後に確認された値です。

[main_dashboard.body]
KO: 상품은 다이아예요 · ${AppStrings.noCashPrizePool}
JA: 賞品はDIAです · ${AppStrings.noCashPrizePool}

[main_dashboard.body.2]
KO: 좋은 아침이에요
JA: おはようございます

[main_dashboard.body.3]
KO: 좋은 오후예요
JA: こんにちは

[main_dashboard.body.4]
KO: 좋은 저녁이에요
JA: こんばんは

[main_dashboard.body.5]
KO: ${_hello(DateTime.now().hour)}, $nickname님
JA: ${_hello(DateTime.now().hour)}、$nicknameさん

[main_shell_routes.body]
KO: 결제 정보가 없어 PG 화면을 열 수 없습니다.
JA: 決済情報がないためPG画面を開くことができません。

[main_shell_routes.body.2]
KO: 대회 정보가 없어 스폰서 결제를 열 수 없습니다.
JA: 大会情報がないためスポンサー決済を開くことができません。

[main_shell_routes.button]
KO: 대회 목록으로
JA: 大会一覧へ

[map_crew.body]
KO: 지도 & 크루
JA: マップ＆クルー

[map_crew.body.2]
KO: 크루 종합 랭킹
JA: クルー総合ランキング

[map_crew.body.3]
KO: ${crews[index].memberCount}명
JA: ${crews[index].memberCount}人

[map_crew.body.4]
KO: 아직 크루 순위가 없어요
JA: まだクルーのランキングがありません

[map_crew.body.5]
KO: 크루 순위가 쌓이면 여기에 나타나요.
JA: クルーランキングが蓄積されるとここに表示されます。

[map_crew.body.6]
KO: ${collectRadiusMeters.round()}m 안으로 가까이 가야 받을 수 있어요.
JA: ${collectRadiusMeters.round()}m以内に近づくと受け取れます。

[map_crew.body.7]
KO: +${box.rewardDiamond} DIA를 받았어요.
JA: +${box.rewardDiamond} DIAを受け取りました。

[map_crew.body.8]
KO: ${distanceMeters!.toStringAsFixed(0)}m 떨어져 있어요
JA: ${distanceMeters!.toStringAsFixed(0)}m 離れています

[map_crew.button]
KO: 내 위치 새로고침
JA: 現在地を更新

[map_crew.button.2]
KO: 다이아 상자 받기
JA: DIAボックスを受け取る

[map_crew.button.3]
KO: 더 가까이 가 주세요
JA: もっと近づいてください

[map_crew.crew_member_ranking_board.body]
KO: 크루원 랭킹 데이터 없음
JA: クルーメンバーのランキングデータがありません

[map_crew.crew_member_ranking_board.body.2]
KO: 출석률·평균 페이스가 여기에 표시됩니다.
JA: 出席率・平均ペースがここに表示されます。

[map_crew.crew_member_ranking_board.body.3]
KO: 크루원 출석률 & 평균 페이스
JA: クルーメンバーの出席率＆平均ペース

[map_crew.crew_member_ranking_board.body.4]
KO: 출석률 높은 순 · 페이스 빠른 순으로 B2B 크루 성과를 추적합니다.
JA: 出席率の高い順・ペースの速い順でB2Bクルーの実績を追跡します。

[map_crew.crew_member_ranking_board.body.5]
KO: 출석 ${member.attendanceRate.toStringAsFixed(0)}%
JA: 出席 ${member.attendanceRate.toStringAsFixed(0)}%

[map_crew.safe_map_panel.body]
KO: 지도 준비 중
JA: マップの準備中

[mini_bot.body]
KO: 궁금한 게 있으면 저를 눌러 물어보세요
JA: 気になることがあればタップして聞いてください

[mini_bot.body.10]
KO: 하루 SHARE 한도
JA: 1日のSHARE上限

[mini_bot.body.11]
KO: 어떤 대회?
JA: どんな大会？

[mini_bot.body.12]
KO: 순위별 상금
JA: 順位別の賞金

[mini_bot.body.13]
KO: 초급은 무료?
JA: 初級は無料？

[mini_bot.body.14]
KO: SHARE잔액
JA: SHARE残高

[mini_bot.body.15]
KO: VALUE잔액
JA: VALUE残高

[mini_bot.body.16]
KO: 등급
JA: ランク

[mini_bot.body.17]
KO: 오늘기부기여
JA: 今日の寄付貢献

[mini_bot.body.18]
KO: 이 버전에서는 앱 안에서 결제하지 않아요.
JA: このバージョンではアプリ内決済を行いません。

[mini_bot.body.19]
KO: 궁금한 걸 물어보세요
JA: 気になることを聞いてみてください

[mini_bot.body.2]
KO: 오늘 목표나 SHARE가 궁금하면 물어보세요
JA: 今日の目標やSHAREについて気になることがあれば聞いてください

[mini_bot.body.3]
KO: 기록 지키기가 헷갈리면 제가 알려 드려요
JA: 記録の維持に迷ったら、私がお教えします

[mini_bot.body.4]
KO: 어떤 챌린지가 맞는지 모르겠으면 물어보세요
JA: どのチャレンジが合っているかわからない時は聞いてください

[mini_bot.body.5]
KO: 참가비와 순위별 상금이 궁금하면 눌러 보세요
JA: 参加費や順位別の賞金が気になる場合はタップしてみてください

[mini_bot.body.6]
KO: 초급은 무료인지도 알려 드려요
JA: 初級が無料かどうかもお教えします

[mini_bot.body.7]
KO: 오늘 내 기부
JA: 今日の私の寄付

[mini_bot.body.8]
KO: 내 SHARE
JA: 私のSHARE

[mini_bot.body.9]
KO: 내 등급
JA: 私のランク

[mini_bot.button]
KO: 멈추기
JA: 停止

[mini_bot.button.2]
KO: 말하기
JA: 話す

[mini_bot.button.3]
KO: 보내기
JA: 送信

[mini_bot.hint]
KO: 한글로 말해 주세요
JA: 話すか、入力してください

[mini_bot.mini_bot_dock.accessibility]
KO: 달팽이봇
JA: カタツムリボット

[mini_bot.mini_bot_dock.body]
KO: 끌어서 옮길 수 있어요
JA: ドラッグして移動できます

[mini_bot.mini_bot_intent.body]
KO: 후원하기
JA: 支援する

[mini_bot.mini_bot_intent.body.10]
KO: 다이아 교환
JA: DIA交換

[mini_bot.mini_bot_intent.body.11]
KO: 스폰서
JA: スポンサー

[mini_bot.mini_bot_intent.body.12]
KO: 러너 후원
JA: ランナー支援

[mini_bot.mini_bot_intent.body.13]
KO: 배틀패스
JA: バトルパス

[mini_bot.mini_bot_intent.body.14]
KO: 저는 당신의 달리기 친구, 달팽이예요. 말로 물어보면 바로 도와드릴게요. 이동하거나 결제하기 전에는 꼭 확인받아요.
JA: 私はあなたのランニング仲間、カタツムリです。声で質問していただければすぐにお手伝いします。画面の移動や決済の前には必ず確認を取ります。

[mini_bot.mini_bot_intent.body.17]
KO: 유료 구독은 Coach+ 하나예요
JA: 有料サブスクリプションはCoach+のみです

[mini_bot.mini_bot_intent.body.19]
KO: 상점의 기부 버튼으로 직접 눌러 주세요.
JA: ショップの寄付ボタンを直接タップしてください。

[mini_bot.mini_bot_intent.body.2]
KO: 구매하기
JA: 購入する

[mini_bot.mini_bot_intent.body.20]
KO: 초보 1km 챌린지로 이동할까요? 참가비는 $joinAmount예요. 참가하기를 눌러도 참가는 확정되지 않아요. 그 화면에서 직접 확인해 주세요.
JA: 初心者1kmチャレンジへ移動しますか？参加費は$joinAmountです。「参加する」を押してもエントリーは確定しません。その画面で直接ご確認ください。

[mini_bot.mini_bot_intent.body.21]
KO: 챌린지 로비로 이동할까요? 로비에서 참가할 대회를 고를 수 있어요.
JA: チャレンジロビーへ移動しますか？ロビーで参加する大会を選択できます。

[mini_bot.mini_bot_intent.body.22]
KO: 운영자 상금 대회 참가비를 확인 중이에요. 대회 목록에서 서버 참가비를 확인해 주세요. 여기서는 참가하지 않아요.
JA: 主催者賞金大会の参加費を確認中です。大会一覧でサーバーの参加費をご確認ください。ここではエントリーされません。

[mini_bot.mini_bot_intent.body.23]
KO: 초급
JA: 初級

[mini_bot.mini_bot_intent.body.24]
KO: 중급
JA: 中級

[mini_bot.mini_bot_intent.body.25]
KO: 상급
JA: 上級

[mini_bot.mini_bot_intent.body.26]
KO: 하프
JA: ハーフ

[mini_bot.mini_bot_intent.body.27]
KO: 운영자 상금 대회로 이동할까요? 참가비는 $costs예요.$free $week $claim 이동만 하고, 참가는 확정하지 않아요.
JA: 主催者賞金大会へ移動しますか？参加費は$costsです。$free $week $claim 画面へ移動するだけで、エントリーは確定しません。

[mini_bot.mini_bot_intent.body.28]
KO: 상점의 기록 심폐소생권으로 이동할까요? $itemAmount예요. 구매하기를 눌러도 결제하지 않아요. 상점 화면에서 직접 구매해 주세요.
JA: ショップの記録蘇生チケットへ移動しますか？価格は$itemAmountです。「購入」を押しても決済は行われません。ショップ画面で直接ご購入ください。

[mini_bot.mini_bot_intent.body.3]
KO: 참가하기
JA: 参加する

[mini_bot.mini_bot_intent.body.30]
KO: 상점의 세이프 가드 칸에서 직접 구매해 주세요.
JA: ショップのセーフガード欄から直接ご購入ください。

[mini_bot.mini_bot_intent.body.31]
KO: 다이아 교환소로 이동할까요? $chargeAmount예요. 교환하기를 눌러도 여기서는 결제되지 않아요. 교환소에서 직접 바꿔 주세요.
JA: DIA交換所へ移動しますか？価格は$chargeAmountです。「交換する」を押してもここでは決済されません。交換所で直接交換してください。

[mini_bot.mini_bot_intent.body.33]
KO: 그 화면의 후원 버튼으로 직접 확정해 주세요.
JA: その画面の応援ボタンから直接確定してください。

[mini_bot.mini_bot_intent.body.34]
KO: 브랜드 스폰서 챌린지는 아직 준비 중이에요. 지금 진행 중인 스폰서 챌린지가 없어요. 열리면 챌린지 탭에서 알려 드릴게요.
JA: ブランドスポンサーチャレンジは現在準備中です。現在進行中のスポンサーチャレンジはありません。開始されたらチャレンジタブでお知らせします。

[mini_bot.mini_bot_intent.body.35]
KO: 구독 관리 화면으로 이동할까요? $subscriptionAmount. 이동만 하고, 구독이나 결제는 바꾸지 않아요.
JA: サブスクリプション管理画面へ移動しますか？$subscriptionAmount。画面へ移動するだけで、登録内容や決済は変更されません。

[mini_bot.mini_bot_intent.body.36]
KO: Coach+ 안내를 열까요? 심박·상황에 맞춘 심층 코칭이에요. $coachPlusAmount. 이동만 하고, 여기서는 결제하지 않아요.
JA: Coach+の案内を開きますか？心拍数や状況に合わせた詳細なコーチングです。$coachPlusAmount。画面へ移動するだけで、ここでは決済されません。

[mini_bot.mini_bot_intent.body.37]
KO: 배틀런 패스 화면으로 이동할까요? $battlePassAmount. 여기서는 패스를 구매하지 않아요. 보상 화면만 열어요.
JA: Battle Run pass画面へ移動しますか？$battlePassAmount。ここではパスを購入しません。報酬画面を開くだけです。

[mini_bot.mini_bot_intent.body.38]
KO: 알겠어요. 이동은 취소했어요.
JA: かしこまりました。移動をキャンセルしました。

[mini_bot.mini_bot_intent.body.4]
KO: 이동하기
JA: 移動する

[mini_bot.mini_bot_intent.body.40]
KO: 다이아 교환, 심폐소생권, 세이프가드, 구독, Coach+, 배틀패스 중에서 말해 주세요.
JA: DIA交換、蘇生チケット、セーフガード、サブスクリプション、Coach+、バトルパスの中からお話しください。

[mini_bot.mini_bot_intent.body.41]
KO: 마이크 권한이 없어 음성을 듣지 못했어요. 한글로 입력하거나 아래 버튼을 눌러 주세요.
JA: マイクの権限がないため音声を認識できませんでした。テキストを入力するか下のボタンを押してください。

[mini_bot.mini_bot_intent.body.42]
KO: 지금은 음성 인식을 쓸 수 없어요. 한글로 입력하거나 아래 버튼을 눌러 주세요.
JA: 現在、音声認識をご利用いただけません。テキストを入力するか下のボタンを押してください。

[mini_bot.mini_bot_intent.body.43]
KO: 말씀을 알아듣지 못했어요. 다시 말하거나 한글로 입력해 주세요.
JA: お話しが聞き取れませんでした。もう一度話すか、テキストを入力してください。

[mini_bot.mini_bot_intent.body.44]
KO: 듣는 중이에요. 말씀해 주세요.
JA: 聞き取り中です。お話しください。

[mini_bot.mini_bot_intent.body.45]
KO: 초보 1km 챌린지로 이동할게요. 참가 확정은 그 화면에서 해 주세요. 여기서는 참가되지 않아요.
JA: 初心者1kmチャレンジへ移動します。参加の確定はその画面で行ってください。ここではエントリーされません。

[mini_bot.mini_bot_intent.body.46]
KO: 챌린지 로비로 이동할게요.
JA: チャレンジロビーへ移動します。

[mini_bot.mini_bot_intent.body.47]
KO: 상점 아이템 화면으로 이동할게요. 기록 심폐소생권을 눌러 구매해 주세요. 여기서는 결제되지 않아요.
JA: ショップのアイテム画面へ移動します。記録蘇生チケットをタップしてご購入ください。ここでは決済されません。

[mini_bot.mini_bot_intent.body.48]
KO: 상점 아이템 화면으로 이동할게요. 세이프 가드를 눌러 구매해 주세요. 여기서는 결제되지 않아요.
JA: ショップのアイテム画面へ移動します。セーフガードをタップしてご購入ください。ここでは決済されません。

[mini_bot.mini_bot_intent.body.49]
KO: 상점 기부 펀딩으로 이동할게요. 기부 버튼으로 직접 눌러 주세요. 여기서는 기부되지 않아요.
JA: ショップの寄付ファンディングへ移動します。「寄付」ボタンを直接タップしてください。ここでは寄付されません。

[mini_bot.mini_bot_intent.body.5]
KO: 앱 소개
JA: アプリの紹介

[mini_bot.mini_bot_intent.body.50]
KO: 다이아 교환소로 이동할게요. 교환은 그 화면에서 직접 해 주세요. 여기서는 결제되지 않아요.
JA: DIA交換所へ移動します。交換はその画面で直接行ってください。ここでは決済されません。

[mini_bot.mini_bot_intent.body.51]
KO: 러너 후원 화면으로 이동할게요. 후원 버튼으로 직접 확정해 주세요. 여기서는 후원되지 않아요.
JA: ランナー応援画面へ移動します。応援ボタンから直接確定してください。ここでは応援されません。

[mini_bot.mini_bot_intent.body.52]
KO: 브랜드 스폰서 챌린지로 이동할게요. 참가는 그 화면에서 직접 해 주세요. 여기서는 참가되지 않아요.
JA: ブランドスポンサーチャレンジへ移動します。参加はその画面で直接行ってください。ここではエントリーされません。

[mini_bot.mini_bot_intent.body.53]
KO: 구독 관리 화면으로 이동할게요. 여기서는 구독을 바꾸지 않아요.
JA: サブスクリプション管理画面へ移動します。ここでは登録内容は変更されません。

[mini_bot.mini_bot_intent.body.54]
KO: Coach+ 안내를 열게요. 월간·연간은 그 화면에서 직접 골라 주세요. 여기서는 결제되지 않아요.
JA: Coach+の案内を開きます。月額・年額はその画面で直接お選びください。ここでは決済されません。

[mini_bot.mini_bot_intent.body.55]
KO: 배틀런 패스 화면으로 이동할게요. 여기서는 패스를 구매하지 않아요.
JA: Battle Run pass画面へ移動します。ここではパスを購入しません。

[mini_bot.mini_bot_intent.body.56]
KO: 충전
JA: チャージ

[mini_bot.mini_bot_intent.body.57]
KO: 상금
JA: 賞金

[mini_bot.mini_bot_intent.body.58]
KO: 초보
JA: 初心者

[mini_bot.mini_bot_intent.body.59]
KO: 로비
JA: ロビー

[mini_bot.mini_bot_intent.body.6]
KO: 챌린지 참가
JA: チャレンジに参加

[mini_bot.mini_bot_intent.body.60]
KO: 참가
JA: 参加

[mini_bot.mini_bot_intent.body.61]
KO: 레이스
JA: レース

[mini_bot.mini_bot_intent.body.62]
KO: 입장
JA: 入場

[mini_bot.mini_bot_intent.body.63]
KO: 들어가
JA: 入る

[mini_bot.mini_bot_intent.body.64]
KO: 심폐
JA: 心肺

[mini_bot.mini_bot_intent.body.65]
KO: 소생
JA: 蘇生

[mini_bot.mini_bot_intent.body.66]
KO: 배틀 패스
JA: バトルパス

[mini_bot.mini_bot_intent.body.67]
KO: 배틀런
JA: バトルラン

[mini_bot.mini_bot_intent.body.68]
KO: 코칭
JA: コーチング

[mini_bot.mini_bot_intent.body.69]
KO: 코치
JA: コーチ

[mini_bot.mini_bot_intent.body.7]
KO: 심폐소생권
JA: CPRチケット

[mini_bot.mini_bot_intent.body.70]
KO: 심박
JA: 心拍

[mini_bot.mini_bot_intent.body.71]
KO: 멤버십
JA: メンバーシップ

[mini_bot.mini_bot_intent.body.72]
KO: 정기
JA: 定期

[mini_bot.mini_bot_intent.body.73]
KO: 천사
JA: 天使

[mini_bot.mini_bot_intent.body.74]
KO: 브랜드
JA: ブランド

[mini_bot.mini_bot_intent.body.75]
KO: 펀딩
JA: ファンディング

[mini_bot.mini_bot_intent.body.76]
KO: 유니세프
JA: UNICEF

[mini_bot.mini_bot_intent.body.77]
KO: 소개
JA: 紹介

[mini_bot.mini_bot_intent.body.78]
KO: 뭐야
JA: 何？

[mini_bot.mini_bot_intent.body.79]
KO: 뭐니
JA: 何なの？

[mini_bot.mini_bot_intent.body.8]
KO: 후원
JA: 支援

[mini_bot.mini_bot_intent.body.80]
KO: 무엇
JA: 何

[mini_bot.mini_bot_intent.body.81]
KO: 어떤 앱
JA: どんなアプリ

[mini_bot.mini_bot_intent.body.82]
KO: 설명해
JA: 説明して

[mini_bot.mini_bot_intent.body.9]
KO: 세이프가드
JA: セーフガード

[mock_demo_data.body]
KO: 달리기부자45
JA: ランニング長者45

[mock_demo_data.body.10]
KO: ⚡ 네온 5K 스프린트 — 쉐어런 스폰서가 응원합니다!
JA: ⚡ ネオン 5Kスプリント — ShareRunスポンサーが応援しています！

[mock_demo_data.body.11]
KO: 🔥 완주 시 밸류 토큰 적립 보너스 이벤트 진행 중
JA: 🔥 完走時にVALUEトークン獲得ボーナスイベント開催中

[mock_demo_data.body.12]
KO: 🏆 크루원과 함께 페이스를 맞춰 보세요
JA: 🏆 クルーメンバーと一緒にペースを合わせましょう

[mock_demo_data.body.13]
KO: 공원 입구 다이아
JA: 公園入口DIA

[mock_demo_data.body.14]
KO: 민지
JA: ミンジ

[mock_demo_data.body.15]
KO: 준호
JA: ジュノ

[mock_demo_data.body.16]
KO: 서연
JA: ソヨン

[mock_demo_data.body.17]
KO: 태윤
JA: テユン

[mock_demo_data.body.18]
KO: 네온 러너스
JA: ネオンランナーズ

[mock_demo_data.body.2]
KO: 김민수
JA: キム・ミンス

[mock_demo_data.body.3]
KO: 현재 김민수님이 당신의 완주를 후원하고 있습니다
JA: 現在、キム・ミンスさんがあなたの完走をスポンサーしています

[mock_demo_data.body.4]
KO: 루키 3K 기부 런
JA: ルーキー 3K 寄付ラン

[mock_demo_data.body.5]
KO: 기부 캠페인
JA: 寄付キャンペーン

[mock_demo_data.body.6]
KO: 🏃 기부 캠페인: 오늘도 3K 완주에 도전하세요!
JA: 🏃 寄付キャンペーン: 今日も3K完走に挑戦しましょう!

[mock_demo_data.body.7]
KO: 💚 러너 여러분의 발걸음이 아이들에게 전달됩니다
JA: 💚 ランナーの皆様の一歩が子どもたちに届きます

[mock_demo_data.body.8]
KO: 🎯 참가비의 일부가 기부 풀로 적립됩니다
JA: 🎯 参加費の一部が寄付プールに積立されます

[mock_demo_data.body.9]
KO: 네온 5K 스프린트
JA: ネオン 5Kスプリント

[app.myPageGoldGrade]
KO: 골드 등급
JA: ゴールドランク

[app.myPageMonthlyDistanceLabel]
KO: 이번 달 총 거리:
JA: 今月の総距離:

[app.myPageNickname]
KO: 러너상기
JA: ランナーサンギ

[app.myPageStreak]
KO: 🔥 현재 연속 출석(Streak): 12일
JA: 🔥 現在の連続出席（Streak）: 12日

[app.myPageSubscriptionManage]
KO: 구독 관리
JA: サブスクリプション管理

[app.promotionBlockedCooldown]
KO: 승급은 일주일에 한 번이에요. 점수는 그대로 모여 있어요
JA: 昇級は週に1回です。ポイントはそのまま保持されています

[app.promotionBlockedPace]
KO: 다음 동물로 가려면 최근 30일 안에 더 빠른 달리기가 필요해요
JA: 次の動物に進むには、過去30日以内により速いランニングが必要です

[app.promotionBlockedSeason]
KO: 다음 동물은 시즌 성적으로 정해져요
JA: 次の動物はシーズン成績によって決定されます

[app.promotionBlockedTournaments]
KO: 다음 동물로 가려면 대회를 몇 번 더 완주해야 해요
JA: 次の動物に進むには、あと数回大会を完走する必要があります

[app.promotionHint]
KO: 대회에서 입상하면 점수가 쌓여요
JA: 大会で入賞するとポイントが貯まります

[app.promotionProgress]
KO: $points / $step점
JA: $points / $step点

[app.promotionTitle]
KO: 다음 메달까지
JA: 次のメダルまで

[my_page.body]
KO: 이용약관과 별도 · 선택 동의
JA: 利用規約とは別 · 任意同意

[my_page.body.2]
KO: 러닝 캘린더
JA: ランニングカレンダー

[my_page.body.3]
KO: 스마트워치 연동
JA: スマートウォッチ連携

[my_page.body.4]
KO: 연동된 워치 없음
JA: 連携されたウォッチなし

[my_page.body.5]
KO: 푸시 알림
JA: プッシュ通知

[my_page.body.6]
KO: Mock: 50% 기부 선택
JA: Mock: 50%寄付を選択

[my_page.body.7]
KO: Mock: 100% 기부 선택
JA: Mock: 100%寄付を選択

[my_page.body.8]
KO: Mock: 전액 수령 선택
JA: Mock: 全額受取を選択

[my_page.body.9]
KO: ✅ 건강 데이터 연동 및 동의 완료
JA: ✅ ヘルスケアデータの連携および同意完了

[my_page.button]
KO: 투트랙 연동 설정 열기
JA: ツートラック連携設定を開く

[my_page.button.2]
KO: 우승자 명예 팝업 미리보기 (Mock)
JA: 勝者栄誉ポップアップ予告 (Mock)

[my_page.button.3]
KO: 대회, 보상, 기부 알림
JA: 大会・報酬・寄付の通知

[my_page.button.4]
KO: 취소
JA: キャンセル

[my_page.button.5]
KO: 삭제
JA: 削除

[my_page.button.6]
KO: [약관 전문 보기]
JA: [利用規約の全文を見る]

[my_page.dialog]
KO: 계정이 삭제되고 보유한 SHARE·DIA·VALUE는 사라집니다. 러닝 기록 등 활동 기록은 30일 안에 삭제되고, 법령에 따라 보관해야 하는 결제·거래 기록은 5년간 보관한 뒤 삭제됩니다. 이 작업은 되돌릴 수 없습니다. 계속하시겠습니까?
JA: アカウントが削除され、保有しているSHARE・DIA・VALUEは消えます。ランニング記録などの活動記録は30日以内に削除され、法令により保管が必要な決済・取引記録は5年間保管後に削除されます。この操作は元に戻せません。続けますか？

[my_page.toast]
KO: ✅ 민감정보 수집 동의가 완료되었습니다. 이제 러닝을 시작할 수 있습니다!
JA: ✅ センシティブ情報の収集への同意が完了しました。これでランニングを始めることができます！

[my_page.pace_calculator.body]
KO: 목표 페이스 계산기
JA: 目標ペース計算機

[my_page.pace_calculator.body.2]
KO: 유효한 거리와 목표 시간을 입력하세요.
JA: 有効な距離と目標時間を入力してください。

[my_page.pace_calculator.body.3]
KO: 목표 페이스: $paceMin:${paceSec.toString().padLeft(2,
JA: 目標ペース: $paceMin:${paceSec.toString().padLeft(2,

[my_page.pace_calculator.body.4]
KO: )} /km
예상 완주: $finish (${distance.toStringAsFixed(1)} km)
JA: )} /km
予想完走: $finish (${distance.toStringAsFixed(1)} km)

[my_page.pace_calculator.hint]
KO: 목표 거리 (km)
JA: 目標距離 (km)

[my_page.pace_calculator.hint.2]
KO: 시
JA: 時間

[my_page.pace_calculator.hint.3]
KO: 분
JA: 分

[my_page.pace_calculator.hint.4]
KO: 초
JA: 秒

[my_page.shoe_mileage_tracker.body]
KO: 러닝화 마일리지 트래커
JA: ランニングシューズのマイレージトラッカー

[my_page.shoe_mileage_tracker.body.2]
KO: 장착 중 · $skinName
JA: 装備中 · $skinName

[my_page.shoe_mileage_tracker.body.3]
KO: ⚠️ 500km 도달! 쿠셔닝 성능 저하 위험 — 러닝화 교체를 권장합니다.
JA: ⚠️ 500km到達！クッション性能低下の危険 — ランニングシューズの交換を推奨します。

[my_page.shoe_mileage_tracker.body.4]
KO: 교체 알림: ${(goal - totalDistanceKm).toStringAsFixed(1)} km 남음
JA: 交換リマインダー: 残り${(goal - totalDistanceKm).toStringAsFixed(1)} km

[my_tournaments.body]
KO: 내 대회
JA: マイ大会

[my_tournaments.body.2]
KO: 참가한 대회와 참가 상태를 확인하세요.
JA: 参加した大会と参加状態を確認してください。

[my_tournaments.body.3]
KO: 아직 참가한 대회가 없습니다.
JA: まだ参加した大会がありません。

[my_tournaments.body.4]
KO: 참가 중
JA: 参加中

[my_tournaments.body.5]
KO: 지난 대회
JA: 過去の大会

[my_tournaments.body.6]
KO: 참가비 ${p.entryFeeShare} SHARE · ${p.tournament.recruitmentSummary}
JA: 参加費 ${p.entryFeeShare} SHARE · ${p.tournament.recruitmentSummary}

[my_tournaments.body.7]
KO: 환불됨
JA: 返金済み

[app.notification1BodyPrefix]
KO: 중급 3km 챌린지 기록이 승인되어
JA: 中級3kmチャレンジの記録が承認され、

[app.notification1BodySuffix]
KO: 이 지갑으로 자동 입금되었습니다.
JA: がお財布に自動で入金されました。

[app.notification1Highlight]
KO: 100 밸류 토큰(VALUE)
JA: 100 VALUEトークン

[app.notification1Time]
KO: 방금 전
JA: たった今

[app.notification1Title]
KO: 러닝 검증 완료!
JA: ランニング検証完了！

[app.notification2BodyPrefix]
KO: 서울 나이트 러너스 방장님이
JA: ソウル・ナイト・ランナーズのリーダーが

[app.notification2BodySuffix]
KO: 을 선물했습니다!
JA: をプレゼントしました！

[app.notification2Highlight]
KO: '기록 심폐소생권'
JA: 「記録蘇生チケット」

[app.notification2Time]
KO: 2시간 전
JA: 2時間前

[app.notification2Title]
KO: 크루 방장님의 하사품
JA: クルーリーダーからの贈り物

[app.notification3Body]
KO: 대회 무산으로 인해 50,000 SHARE 현금 환불이 정상 처리되었습니다.
JA: 大会の中止に伴い、50,000 SHAREの現金返金処理が正常に完了しました。

[app.notification3Time]
KO: 어제
JA: 昨日

[app.notification3Title]
KO: 결제 취소 완료
JA: 決済キャンセル完了

[app.notificationCenterTitle]
KO: 알림 및 내역 (History)
JA: 通知および履歴 (History)

[app.notificationPaymentEmpty]
KO: 거래 및 결제 내역이 존재하지 않습니다. 🪙
JA: 取引および決済履歴が存在しません。🪙

[app.notificationPaymentReceipt]
KO: 안전 결제 영수증 완료 🪙
JA: 安全決済の領収書発行完了 🪙

[app.notificationPaymentUnknown]
KO: 알 수 없는 거래
JA: 不明な取引

[app.notificationSystemEmpty]
KO: 도달한 새로운 알림이 없습니다. 🔔
JA: 新しい通知はありません。🔔

[app.notificationSystemFallbackTitle]
KO: 알림
JA: 通知

[app.notificationTabPayment]
KO: 결제/히스토리
JA: 決済／履歴

[app.notificationTabSystem]
KO: 시스템 알림
JA: システム通知

[notification_center.body]
KO: ${date.month}월 ${date.day}일
JA: ${date.month}月${date.day}日

[onboarding.body]
KO: 쉐어런에 오신 걸 환영해요
JA: ShareRunへようこそ

[onboarding.body.2]
KO: 서비스 이용 전 필수 약관에 동의해 주세요.
JA: サービスのご利用前に必須利用規約にご同意ください。

[onboarding.body.3]
KO: 아래는 일반 약관과 분리된 선택 동의입니다.
JA: 以下は一般規約とは別の任意同意項目です。

[onboarding.body.4]
KO: 동의합니다
JA: 同意します

[onboarding.button]
KO: 저장 중...
JA: 保存中...

[onboarding.button.2]
KO: 동의하고 시작하기
JA: 同意して始める

[onboarding.toast]
KO: 온보딩 저장 실패: $error
JA: オンボーディングの保存に失敗しました: $error

[onboarding.nickname_change.body]
KO: 새로운 질주를 위한 이름을 새기시겠습니까?
JA: 新たな疾走のための名前を刻みますか？

[onboarding.nickname_change.body.2]
KO: 러너님의 정체성을 정밀 등록합니다.
JA: ランナーのアイデンティティを精密に登録します。

[onboarding.nickname_change.body.3]
KO: 보유 $diaBalance DIA  ·  변경 수수료 $fee DIA
JA: 所持 $diaBalance DIA  ·  変更手数料 $fee DIA

[onboarding.nickname_change.body.4]
KO: 100 DIA 소모하여 변경하기
JA: 100 DIAを消費して変更する

[onboarding.nickname_change.body.5]
KO: 다이아몬드 부족 - 교환소로 이동하기
JA: DIAが不足しています - 交換所へ移動

[onboarding.nickname_change.toast]
KO: 닉네임이 변경되었습니다. (${EconomyConstants.nicknameChangeFeeDia} DIA 차감)
JA: ニックネームが変更されました。(${EconomyConstants.nicknameChangeFeeDia} DIA控除)

[onboarding.nickname_setup.body]
KO: 닉네임 및 캐릭터 가동
JA: ニックネームとキャラクターの起動

[onboarding.nickname_setup.body.2]
KO: 홈에 표시될 닉네임을 정하면, 예선 등급에 맞는 대두 캐릭터가 함께 깨어납니다.
JA: ホームに表示されるニックネームを設定すると、予選ランクに合わせたビッグヘッドキャラクターが目覚めます。

[onboarding.nickname_setup.body.3]
KO: 설정 완료
JA: 設定完了

[onboarding.nickname_setup.hint]
KO: 한글·영문·숫자 2~12자
JA: 文字・英数字 2〜12文字

[onboarding.src_onboarding_controller.body]
KO: 예비 천사 (Pre-Angel)
JA: 見習い天使（Pre-Angel）

[onboarding.src_onboarding_controller.body.10]
KO: 누적 20회 또는 누적 300,000 SHARE 이상
JA: 累計20回または累計300,000 SHARE以上

[onboarding.src_onboarding_controller.body.11]
KO: 누적 50회 또는 누적 1,000,000 SHARE 이상
JA: 累計50回または累計1,000,000 SHARE以上

[onboarding.src_onboarding_controller.body.12]
KO: 누적 100회 또는 누적 5,000,000 SHARE 이상
JA: 累計100回または累計5,000,000 SHARE以上

[onboarding.src_onboarding_controller.body.13]
KO: 등에 귀여운 날개 반창고를 붙인 마스코트
JA: 背中に可愛い羽根の絆創膏を貼ったマスコット

[onboarding.src_onboarding_controller.body.14]
KO: 등 뒤 아기 날개 배지 장착
JA: 背中に小さな天使の羽根バッジを装着

[onboarding.src_onboarding_controller.body.15]
KO: 은빛 날개 · 대회 입장 시 닉네임 볼드 테두리 강조
JA: 銀色の翼 · 大会入場時にニックネームを太枠で強調

[onboarding.src_onboarding_controller.body.16]
KO: 황금 날개 · 골드 그라데이션 닉네임 · 개설 대회 러너 1.2배 VALUE 부스트
JA: 黄金の翼 · ゴールドグラデーションのニックネーム · 主催大会のランナーに1.2倍のVALUEブースト

[onboarding.src_onboarding_controller.body.17]
KO: 4익 날개 · 민트 오라 · 대회 입장 시 단독 등장 팝업
JA: 4枚の翼 · ミントオーラ · 大会入場時に単独登場ポップアップ

[onboarding.src_onboarding_controller.body.18]
KO: 6익 날개 · 골드 광배 회전 · 명예의 전당 VVIP 단독 배너
JA: 6枚の翼 · 回転するゴールド後光 · 殿堂VVIP単独バナー

[onboarding.src_onboarding_controller.body.19]
KO: ${n.koreanName}까지 후원 $remainCount회
JA: ${n.koreanName}までスポンサー$remainCount回

[onboarding.src_onboarding_controller.body.2]
KO: 큐피드
JA: キューピッド

[onboarding.src_onboarding_controller.body.20]
KO: ${n.koreanName}까지 $remainCount회 또는 ${formatWon(remainWon)}
JA: ${n.koreanName}まで$remainCount回または${formatWon(remainWon)}

[onboarding.src_onboarding_controller.body.21]
KO: 알림을 켜면 이런 이득이 있어요
JA: 通知をオンにすると、こんなメリットがあります

[onboarding.src_onboarding_controller.body.22]
KO: 재화 실시간 입금 알림
JA: 財貨のリアルタイム入金通知

[onboarding.src_onboarding_controller.body.23]
KO: 소속 크루 방장 전체 공지 긴급 수신
JA: 所属crewリーダーの全体お知らせを緊急受信

[onboarding.src_onboarding_controller.body.24]
KO: 러닝화 수명 도달에 따른 부상 방지 수명 알림
JA: ランニングシューズの寿命による怪我防止通知

[onboarding.src_onboarding_controller.body.25]
KO: DIA 잔액 부족: 필요 $requiredDia, 보유 $availableDia
JA: DIA残高不足：必要 $requiredDia、保有 $availableDia

[onboarding.src_onboarding_controller.body.26]
KO: 시발
JA: クソ

[onboarding.src_onboarding_controller.body.27]
KO: 씨발
JA: くそったれ

[onboarding.src_onboarding_controller.body.28]
KO: 병신
JA: アホ

[onboarding.src_onboarding_controller.body.29]
KO: 지랄
JA: ふざけるな

[onboarding.src_onboarding_controller.body.3]
KO: 수호천사
JA: 守護天使

[onboarding.src_onboarding_controller.body.30]
KO: 좆
JA: ちんこ

[onboarding.src_onboarding_controller.body.31]
KO: 존나
JA: マジで

[onboarding.src_onboarding_controller.body.32]
KO: 개새끼
JA: クソ野郎

[onboarding.src_onboarding_controller.body.33]
KO: 씹
JA: まんこ

[onboarding.src_onboarding_controller.body.34]
KO: 니미
JA: くたばれ
