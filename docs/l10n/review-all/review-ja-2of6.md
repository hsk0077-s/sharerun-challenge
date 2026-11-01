# 번역 검수 요청 — 쉐어런 (Japanese) · 파트 2/6

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
[crew_manager.toast.34]
KO: 인원 한도 최대 (${crew.maxMembers}명)
JA: 最大メンバー上限 (${crew.maxMembers}名)

[crew_manager.toast.4]
KO: 크루장만 이름을 바꿀 수 있어요.
JA: クルーリーダーのみ名前を変更できます。

[crew_manager.toast.5]
KO: 이름을 바꾸지 못했어요. 잠시 뒤 다시 해 주세요.
JA: 名前を変更できませんでした。しばらくしてからやり直してください。

[crew_manager.toast.6]
KO: 인원 한도가 최대(${mine.crew.maxMembers}명)예요.
JA: メンバー上限に達しています（${mine.crew.maxMembers}名）。

[crew_manager.toast.7]
KO: 자리를 모두 채우면 더 늘릴 수 있어요. (${mine.crew.maxMembers}명)
JA: 定員を満たすと上限を増やせます。（${mine.crew.maxMembers}名）

[crew_manager.toast.8]
KO: 인원 한도 확장
JA: メンバー上限を拡張

[crew_manager.toast.9]
KO: 크루 인원 한도를 ${step.add}명 늘려요. ${step.costDia} DIA가 들고, 보너스 DIA를 먼저 써요.
JA: クルー定員を${step.add}名増やします。${step.costDia} DIAがかかり、ボーナスDIAを優先消費します。

[crew_ranking_model.body]
KO: 쉐어런 크루
JA: ShareRunクルー

[crew_room.body]
KO: 크루에 들어 있어야 크루 룸을 볼 수 있어요. 크루에 들어갔는지, 네트워크가 연결됐는지 확인해 주세요.
JA: クルーに参加しているとクルールームを表示できます。クルーへの参加状況とネットワーク接続をご確認ください。

[crew_room.body.2]
KO: } · 내 역할 ${CrewRoomScreen._roleLabel(mine.role)}
JA: } · 私の役割 ${CrewRoomScreen._roleLabel(mine.role)}

[crew_room.body.3]
KO: 크루 대항전은 아직 열리지 않았어요. 열리면 여기서 이번 주 진행을 볼 수 있어요.
JA: クルー対抗戦はまだ開始されていません。開始されると、ここで今週の進行状況を確認できます。

[crew_room.button]
KO: 크루 룸
JA: クルー ルーム

[device_connection.body]
KO: (Apple Watch 전 기종 지원)
JA: (Apple Watch全機種対応)

[device_connection.body.2]
KO: Health Connect 설치 화면을 열었어요. 설치 후 다시 연결해 주세요.
JA: Health Connectのインストール画面を開きました。インストール後に再連携してください。

[device_connection.body.3]
KO: ♥ 연결됨
JA: ♥ 接続済み

[device_connection.body.4]
KO: 미연결
JA: 未接続

[device_connection.body.5]
KO: 연결된 센서: ${snap.deviceName}
JA: 接続済みセンサー: ${snap.deviceName}

[device_connection.button]
KO: 워치 앱 연결 코드 · 연결된 워치
JA: ウォッチ連携コード・連携中ウォッチ

[device_connection.button.2]
KO: 권한 설정 필요
JA: 権限設定が必要

[device_connection.button.3]
KO: 정확한 측정을 위해 권한 설정이 필요합니다.
JA: 正確な計測のために権限の設定が必要です。

[device_connection.dialog]
KO: 연동 불가
JA: 連携不可

[device_connection.dialog.2]
KO: 고객님의 스마트워치 OS 버전이 낮거나 호환되지 않아 연동할 수 없습니다. 워치를 최신 버전(watchOS 8+, Wear OS 3.0+)으로 업데이트해 주세요.
JA: スマートウォッチのOSバージョンが低いか、互換性がないため連携できません。ウォッチを最新バージョン(watchOS 8+, Wear OS 3.0+)にアップデートしてください。

[device_connection.toast]
KO: 등급 배정 화면 이동 실패: $e
JA: ランク割り当て画面への移動に失敗しました: $e

[device_connection.toast.2]
KO: 건너뛰기 실패: $e
JA: スキップに失敗しました: $e

[device_connection.toast.3]
KO: ${watchType.displayLabel} 연동이 완료되었습니다!
JA: ${watchType.displayLabel}の連携が完了しました！

[device_connection.toast.4]
KO: Health Connect를 열 수 없어요. Play 스토어에서 설치해 주세요.
JA: Health Connectを開けません。Playストアからインストールしてください。

[device_connection.toast.5]
KO: 권한이 거부되었습니다.
JA: 権限が拒否されました。

[device_connection.toast.6]
KO: Google Health Connect 연동이 완료되었습니다!
JA: Google Health Connectの連携が完了しました！

[device_connection.toast.7]
KO: 기기가 호환되지 않거나 연동 중 오류가 발생했습니다.
JA: 機器が互換性がないか、連携中にエラーが発生しました。

[device_connection.toast.8]
KO: Garmin 연동 화면을 열 수 없습니다: $e
JA: Garmin連携画面を開けません: $e

[device_connection.toast.9]
KO: ${watchType.displayLabel} 연동 설정이 저장되었습니다.
JA: ${watchType.displayLabel}の連携設定が保存されました。

[app.bleHrConnectButton]
KO: 연결
JA: 接続

[app.bleHrDisconnectButton]
KO: 연결 해제
JA: 切断

[app.bleHrGuideItems]
KO: 가민(Garmin)
JA: Garmin

[app.bleHrGuideItems.2]
KO: 시계 설정 → 센서 및 액세서리 → 손목 심박수 → "심박수 전송" 켜기
JA: 時計の設定 → センサーとアクセサリ → 光学式心拍計 → 「心拍転送モード」をオンにする

[app.bleHrGuideItems.3]
KO: 샤오미 · 어메이즈핏
JA: Xiaomi・Amazfit

[app.bleHrGuideItems.4]
KO: 운동·심박수 설정 → "심박수 공유/전송" 켜기
JA: ワークアウト・心拍数設定 → 「心拍数共有/転送」をオンにする

[app.bleHrGuideItems.5]
KO: 가슴·암밴드 센서
JA: 胸部・アームバンドセンサー

[app.bleHrGuideItems.6]
KO: 착용한 뒤 아래 [센서 찾기] 누르기 (Polar, Wahoo, Coospo, Magene)
JA: 装着後に下の[センサーを探す]をタップ (Polar、Wahoo、Coospo、Magene)

[app.bleHrGuideItems.7]
KO: 갤럭시 워치 · 애플워치
JA: Galaxy Watch・Apple Watch

[app.bleHrGuideItems.8]
KO: 이 방식이 아니에요. 위의 Health Connect / Apple 건강으로 연결하세요
JA: この方法ではありません。上記のHealth Connect / Apple ヘルスケアから連携してください

[app.bleHrGuideTitle]
KO: 내 기기별로 이렇게 하세요
JA: お使いの機器別の設定方法

[app.bleHrScanningLabel]
KO: 근처 심박 센서 찾는 중...
JA: 近くの心拍センサーを検索中...

[app.bleHrSectionSubtitle]
KO: Health Connect 지연 없이 달리는 동안 실시간 심박수(0x180D)를 바로 받습니다.
JA: Health Connectの遅延なしで、走行中にリアルタイム心拍数(0x180D)を直接取得します。

[app.bleHrStopScanButton]
KO: 스캔 중지
JA: スキャン停止

[app.deviceConnectionConnect]
KO: 기기 연결
JA: 機器を接続

[app.deviceConnectionExternalTitle]
KO: 외부 전문 기기 연동
JA: 外部専門機器連携

[app.deviceConnectionGoogleCaption]
KO: (갤럭시 워치, 샤오미 미밴드, 어메이즈핏, 가민, 핏빗 등)
JA: (Galaxy Watch、Xiaomi Mi Band、Amazfit、Garmin、Fitbitなど)

[app.deviceConnectionNativeTitle]
KO: 네이티브 헬스 연동
JA: 標準ヘルスケア連携

[app.deviceConnectionNone]
KO: 연결된 기기가 없습니다
JA: 接続されている機器はありません

[app.deviceConnectionSingleActiveNote]
KO: 쉐어런은 동시에 하나의 운동 기기만 활성 연결 상태로 유지합니다.
JA: ShareRunは同時に1台のエクササイズ機器のみをアクティブ接続状態に維持します。

[app.deviceConnectionStatusTitle]
KO: 현재 연결된 기기
JA: 現在接続されている機器

[app.healthConnectNoSamplesTip]
KO: 권한은 연결되었어요. 밴드/워치 앱 안에서 Health Connect 데이터 쓰기 스위치가 켜져 있는지 확인해 주세요. 스마트밴드 기록은 밴드 앱 동기화 후 반영됩니다.
JA: 権限は連携されました。バンド/ウォッチアプリ内でHealth Connectのデータ書き込みスイッチがオンになっているかご確認ください。スマートバンドの記録はバンドアプリと同期した後に反映されます。

[dia_pack_store.body]
KO: $price원 · ${pack.bonusLabel}
JA: $priceウォン · ${pack.bonusLabel}

[dia_pack_store.body.2]
KO: 기본 ${pack.baseDia} DIA · ${pack.productId}
JA: 基本 ${pack.baseDia} DIA · ${pack.productId}

[dia_pack_store.title]
KO: DIA 팩
JA: DIAパック

[diamond_box_model.body]
KO: 다이아 상자
JA: DIAボックス

[donation_settlement.body]
KO: 운영자가 자기 돈으로 검증 1km당 100원(KRW)을 월 예산 안에서 기부할 예정입니다. 이용자의 기부금이 아니며 세금 공제 영수증이 발급되지 않습니다.
JA: 運営者が自己資金で、検証1kmあたり100ウォン(KRW)を月間予算内で寄付する予定です。ユーザーの寄付金ではなく、税額控除の領収書は発行されません。

[economy_constants.body]
KO: 구매 후 7일 이내, 100% 미사용 분에 한해 환불 가능
JA: 購入後7日以内で、100%未使用の場合に限り払い戻し可能

[email_verification_guard.button]
KO: 결제·대회 참가 전에 이메일 인증을 완료해 주세요. 상단 배너에서 인증 메일을 재발송할 수 있습니다.
JA: 決済や大会参加の前にメール認証を完了してください。上部バナーから認証メールを再送信できます。

[email_verification_guard.dialog]
KO: 이메일 인증 필요
JA: メール認証が必要です

[external_oauth_webview.body]
KO: 이메일 아이디를 입력해 주세요.
JA: メールアドレス（ID）を入力してください。

[external_oauth_webview.body.2]
KO: 올바른 이메일 형식이 아닙니다.
JA: メールアドレスの形式が正しくありません。

[external_oauth_webview.body.3]
KO: 비밀번호를 입력해 주세요.
JA: パスワードを入力してください。

[external_oauth_webview.body.4]
KO: 비밀번호가 너무 짧습니다.
JA: パスワードが短すぎます。

[external_oauth_webview.toast]
KO: 연동 중 오류가 발생했습니다. 앱으로 돌아가 다시 시도해 주세요.
JA: 連携中にエラーが発生しました。アプリに戻り再試行してください。

[app.externalPaymentNoticeHighlight]
KO: 실제 야외 물리적 활동(오프라인 러닝)
JA: 実際の屋外身体活動（オフラインランニング）

[app.externalPaymentNoticePrefix]
KO: 본 결제는
JA: 本決済は、

[app.externalPaymentNoticeSuffix]
KO: 참여를 위한 참가권 구매입니다.
JA: への参加チケットの購入です。

[app.externalPaymentRefundNote]
KO: * 미사용 쿠폰에 한해 언제든 100% 수수료 없이 환불 가능합니다.
JA: * 未使用クーポンに限り、いつでも手数料なしで100%返金可能です。

[app.externalPaymentSecurePaySuffix]
KO: 원 안전 결제하기
JA: ウォンを安全に決済

[firebase_auth_messages.body]
KO: 로그인이 취소되었습니다.
JA: ログインがキャンセルされました。

[firebase_auth_messages.body.10]
KO: 다른 로그인 방식으로 가입된 이메일입니다.
JA: 別のログイン方法で登録されているメールアドレスです。

[firebase_auth_messages.body.11]
KO: 보안을 위해 다시 로그인한 뒤 계정 삭제를 시도해 주세요.
JA: セキュリティのため、再度ログインしてからアカウント削除をお試しください。

[firebase_auth_messages.body.12]
KO: 로그인에 실패했습니다.
JA: ログインに失敗しました。

[firebase_auth_messages.body.2]
KO: 이메일 형식이 올바르지 않습니다.
JA: メールアドレスの形式が正しくありません。

[firebase_auth_messages.body.3]
KO: 비활성화된 계정입니다. 고객센터에 문의해 주세요.
JA: 無効化されたアカウントです。カスタマーサポートにお問い合わせください。

[firebase_auth_messages.body.4]
KO: 이메일 또는 비밀번호를 확인해 주세요.
JA: メールアドレスまたはパスワードをご確認ください。

[firebase_auth_messages.body.5]
KO: 이미 사용 중인 이메일입니다.
JA: 既に使用されているメールアドレスです。

[firebase_auth_messages.body.6]
KO: 비밀번호는 6자 이상이어야 합니다.
JA: パスワードは6文字以上で指定してください。

[firebase_auth_messages.body.7]
KO: 요청이 너무 많습니다. 잠시 후 다시 시도해 주세요.
JA: リクエストが多すぎます。しばらく時間をおいてから再試行してください。

[firebase_auth_messages.body.8]
KO: 네트워크 연결을 확인해 주세요.
JA: ネットワーク接続をご確認ください。

[firebase_auth_messages.body.9]
KO: Firebase 콘솔에서 익명(게스트) 로그인을 활성화해 주세요.
JA: Firebaseコンソールで匿名（ゲスト）ログインを有効にしてください。

[app.garminAuthSubtitle]
KO: 안전한 OAuth 2.0 공식 로그인 페이지입니다.
JA: 安全なOAuth 2.0公式ログインページです。

[app.garminAuthTitle]
KO: Garmin Connect 연동
JA: Garmin Connect連携

[app.garminCancelAndReturn]
KO: 연동을 취소하고 앱으로 돌아가기
JA: 連携をキャンセルしてアプリに戻る

[app.garminEmailHint]
KO: 이메일 아이디
JA: メールアドレス

[app.garminPasswordHint]
KO: 비밀번호
JA: パスワード

[app.garminSignInAuthorize]
KO: 로그인하고 권한 허용
JA: ログインして権限を許可

[app.garminSignInAuthorizeKo]
KO: (로그인 및 권한 허용)
JA: (ログインおよび権限の許可)

[app.hallOfFameDonateCta]
KO: 나도 기부하고 명예의 전당 오르기 💎
JA: 寄付して殿堂入りを目指す 💎

[app.hallOfFameDonateHistoryTitle]
KO: 명예의 전당 기부 완료 🕊️
JA: 殿堂への寄付完了 🕊️

[app.hallOfFameLeaderDonation]
KO: 누적 기부: 5,000,000 VALUE
JA: 累計寄付：5,000,000 VALUE

[app.hallOfFameLeaderName]
KO: 서울 나이트 러너스 방장님
JA: ソウルナイトランナーズ リーダー

[app.hallOfFameLeaderTitle]
KO: 👑 이달의 소셜 임팩트 리더
JA: 👑 今月のソーシャルインパクトリーダー

[app.hallOfFameRank2Badge]
KO: 🔥 불꽃 SBT 뱃지
JA: 🔥 炎のSBTバッジ

[app.hallOfFameRank2Label]
KO: 2등
JA: 2位

[app.hallOfFameRank2Subtitle]
KO: 연속 50일 완주자
JA: 50日連続完走者

[app.hallOfFameRank3Badge]
KO: 🛡️ 방패 SBT 뱃지
JA: 🛡️ 盾のSBTバッジ

[app.hallOfFameRank3Label]
KO: 3등
JA: 3位

[app.hallOfFameRank3Subtitle]
KO: 최다 크루원 후원자
JA: 最多クルー支援者

[app.hallOfFameTitle]
KO: 명예의 전당 (Hall of Fame)
JA: 殿堂 (Hall of Fame)

[app.runningCrewHallOfFame]
KO: 👑 명예의 전당
JA: 👑 殿堂

[app.storeDonateHistoryTitle]
KO: 기부 펀딩 참여 🕊️
JA: 寄付ファンディング参加 🕊️

[hall_of_fame.body]
KO: 서버 원장에서 $_donateValue VALUE를 기부했습니다.
JA: サーバー台帳から$_donateValue VALUEを寄付しました。

[hall_of_fame.body.2]
KO: 서버 원장에서 $_donateValue VALUE를 기부했습니다. 잔액 $left
JA: サーバー台帳から$_donateValue VALUEを寄付しました。残高 $left

[hall_of_fame.body.3]
KO: VALUE가 부족합니다.
JA: VALUEが不足しています。

[hall_of_fame.body.4]
KO: 기부에 실패했습니다.
JA: 寄付に失敗しました。

[hall_of_fame.body.5]
KO: 아직 기록이 없어요
JA: まだ記録がありません

[health_data_consent.body]
KO: 개인정보보호법에 따라 건강·생체 데이터는 일반 약관과 분리된 명시적 Opt-in이 필요합니다.
JA: 個人情報保護法に基づき、ヘルスケア・生体データは一般利用規約とは別の明示的なオプトインが必要です。

[health_data_consent.button]
KO: 권한 요청 중...
JA: 権限をリクエスト中...

[health_data_consent.button.2]
KO: 동의하고 워치 연동 계속
JA: 同意してウォッチ連携を続行

[health_data_consent.button.3]
KO: 나중에 하기
JA: 後で

[health_data_consent.title]
KO: 건강정보 동의
JA: ヘルスケア情報の同意

[health_data_consent.title.2]
KO: 스마트워치 연동 전 동의
JA: スマートウォッチ連携前の同意

[home.home_wallet.body]
KO: $completedCount/$total회 완료 >
JA: $completedCount/$total回完了 >

[iap.coach_plus_product.body]
KO: 6,900원
JA: 6,900ウォン

[iap.coach_plus_product.body.2]
KO: 59,000원
JA: 59,000ウォン

[iap.coach_plus_upsell.body]
KO: 무료
JA: 無料

[iap.coach_plus_upsell.body.2]
KO: 기본 러닝 안내
JA: 基本のランニング案内

[iap.coach_plus_upsell.body.3]
KO: Coach+ 이용 중
JA: Coach+ 利用中

[iap.coach_plus_upsell.button]
KO: 구매 복원
JA: 購入を復元

[iap.dia_pack_product.body]
KO: 보너스 없음
JA: ボーナスなし

[iap.dia_pack_product.body.2]
KO: 보너스 $bonusDia DIA
JA: ボーナス $bonusDia DIA

[iap.iap_providers.body]
KO: SHARE 충전 💳
JA: SHARE チャージ 💳

[iap.iap_purchase_controller.body]
KO: Google Play 결제 서비스를 사용할 수 없습니다. 잠시 후 다시 시도해 주세요.
JA: Google Play 決済サービスを利用できません。しばらくしてからもう一度お試しください。

[iap.iap_purchase_controller.body.10]
KO: 결제 처리 중 오류가 발생했습니다.
JA: 決済処理中にエラーが発生しました。

[iap.iap_purchase_controller.body.11]
KO: Coach+ 결제가 진행 중입니다.
JA: Coach+ の決済が進行中です。

[iap.iap_purchase_controller.body.12]
KO: Coach+ 구독이 활성화되었습니다.
JA: Coach+ の定期購入が有効になりました。

[iap.iap_purchase_controller.body.13]
KO: Coach+ 결제가 실패했습니다.
JA: Coach+ の決済に失敗しました。

[iap.iap_purchase_controller.body.14]
KO: Coach+ 결제가 취소되었습니다.
JA: Coach+ の決済がキャンセルされました。

[iap.iap_purchase_controller.body.15]
KO: 로그인 후 Google Play 결제를 진행해 주세요.
JA: ログインしてから Google Play 決済を行ってください。

[iap.iap_purchase_controller.body.16]
KO: 영수증을 보안 검증 중입니다. SHARE는 검증 완료 후 지급됩니다.
JA: レシートのセキュリティ検証中です。SHARE は検証完了後に付与されます。

[iap.iap_purchase_controller.body.17]
KO: 검증이 완료되어 $shareAmount SHARE가 지급되었습니다.
JA: 検証が完了し、$shareAmount SHARE が付与されました。

[iap.iap_purchase_controller.body.18]
KO: Google 검증이 완료되어 SHARE가 지갑에 반영됩니다.
JA: Google の検証が完了し、ウォレットに SHARE が反映されます。

[iap.iap_purchase_controller.body.19]
KO: 영수증 검증이 거절되었습니다. 고객센터로 문의해 주세요.
JA: レシートの検証が却下されました。カスタマーサポートまでお問い合わせください。

[iap.iap_purchase_controller.body.2]
KO: 상품(${plan.productId})을 찾지 못했습니다. Play Console / App Store Connect 등록을 확인해 주세요.
JA: 商品（${plan.productId}）が見つかりませんでした。Play Console / App Store Connect の登録をご確認ください。

[iap.iap_purchase_controller.body.20]
KO: 검증 응답이 지연되고 있습니다. 지갑 잔액을 잠시 후 다시 확인해 주세요.
JA: 検証の応答が遅延しています。しばらくしてからウォレットの残高を再度ご確認ください。

[iap.iap_purchase_controller.body.21]
KO: 결제 스트림이 일시 중단되었습니다. 연결을 확인한 뒤 다시 시도해 주세요.
JA: 決済ストリームが一時中断されました。接続を確認してからもう一度お試しください。

[iap.iap_purchase_controller.body.3]
KO: 결제 창을 열 수 없습니다.
JA: 決済画面を開くことができません。

[iap.iap_purchase_controller.body.4]
KO: 결제를 시작하지 못했습니다. 네트워크 상태를 확인해 주세요.
JA: 決済を開始できませんでした。ネットワークの状態をご確認ください。

[iap.iap_purchase_controller.body.5]
KO: 구매 복원에 실패했습니다. 잠시 후 다시 시도해 주세요.
JA: 購入の復元に失敗しました。しばらくしてからもう一度お試しください。

[iap.iap_purchase_controller.body.6]
KO: 상품(${product.productId})을 찾지 못했습니다. Play Console 등록을 확인해 주세요.
JA: 商品（${product.productId}）が見つかりませんでした。Play Console の登録をご確認ください。

[iap.iap_purchase_controller.body.7]
KO: 결제가 진행 중입니다. Google Play 승인을 기다려 주세요.
JA: 決済が進行中です。Google Play の承認をお待ちください。

[iap.iap_purchase_controller.body.8]
KO: 결제가 실패했습니다.
JA: 決済に失敗しました。

[iap.iap_purchase_controller.body.9]
KO: 결제가 취소되었습니다.
JA: 決済がキャンセルされました。

[iap.payment_auth.body]
KO: 본인 확인이 취소됐어요. 결제는 진행되지 않았어요.
JA: 本人確認がキャンセルされました。決済は行われていません。

[iap.payment_auth.body.2]
KO: 확인을 여러 번 틀려 잠시 막혔어요. 잠시 뒤 다시 하거나 화면 잠금(PIN, 패턴)으로 확인해 주세요. 결제는 진행되지 않았어요.
JA: 確認の試行回数が上限を超えたため、一時的にロックされました。しばらくしてから再試行するか、画面ロック（PIN、パターン）で認証してください。決済は行われていません。

[iap.payment_auth.body.3]
KO: 결제 전 본인 확인을 하려면 폰에 화면 잠금(지문, PIN, 패턴)이 필요해요. 기기 설정에서 화면 잠금을 켠 뒤 다시 시도해 주세요.
JA: 決済前に本人確認を行うには、端末に画面ロック（指紋、PIN、パターン）が必要です。端末の設定で画面ロックを有効にしてから、もう一度お試しください。

[iap.payment_auth.body.4]
KO: 본인 확인을 할 수 없어요. 잠시 뒤 다시 시도해 주세요. 결제는 진행되지 않았어요.
JA: 本人確認ができませんでした。しばらくしてからもう一度お試しください。決済は行われていません。

[iap.payment_auth.body.5]
KO: 결제를 진행하려면 본인 확인이 필요해요.
JA: 決済を進めるには本人確認が必要です。

[iap.purchases_closed.body]
KO: 안내
JA: ご案内

[iap.purchases_closed.title]
KO: 이 버전에서는 앱 안 결제를 받지 않아요.
JA: このバージョンではアプリ内決済をご利用いただけません。

[in_app_billing.body]
KO: DIA · SHARE로 교환
JA: DIA・SHAREに交換

[in_app_billing.body.2]
KO: Play 상품 준비 중 · 결제해도 DIA가 지급되지 않습니다
JA: Play商品準備中 · 決済してもDIAは付与されません

[in_challenge.body]
KO: 센서 준비 중...
JA: センサー準備中...

[in_challenge.body.2]
KO: Jena 검증 중...
JA: Jena検証中...

[in_challenge.body.3]
KO: 제출 기회: ${widget.submissionsRemaining}/${widget.maxSubmissions}회 남음
JA: 提出機会: 残り${widget.submissionsRemaining}/${widget.maxSubmissions}回

[in_challenge.body.4]
KO: 센서 시작 실패: $e
JA: センサーの開始に失敗: $e

[in_challenge.body.5]
KO: 심박수
JA: 心拍数

[in_challenge.body.6]
KO: 위치 권한이 필요합니다.
JA: 位置情報の権限が必要です。

[in_challenge.body.7]
KO: Google Maps API 키가 설정되지 않았습니다.
JA: Google Maps APIキーが設定されていません。

[in_challenge.body.8]
KO: 러닝 데이터를 검증 중입니다...
JA: ランニングデータを検証中...

[in_challenge.button]
KO: 강제 정지 대신 소명 기회가 부여되었습니다. 증빙 자료를 제출해 주세요.
JA: 強制停止の代わりに申し立ての機会が与えられました。証拠資料を提出してください。

[in_challenge.button.2]
KO: 소명하러 가기
JA: 申し立てをする

[in_challenge.button.3]
KO: 시스템 설정 열기
JA: システム設定を開く

[in_challenge.dialog]
KO: 기록 검증 보류
JA: 記録検証保留

[in_challenge.toast]
KO: Jena 검증 실패: ${ApiErrorMessage.from(error)}
JA: Jena検証失敗: ${ApiErrorMessage.from(error)}

[app.itemInventoryBoostRunQuantityNote]
KO: 하루 1회 · 15분간 줍는 SHARE 2배 · 추가분 +240
JA: 1日1回 · 15分間獲得SHAREが2倍 · 追加分 +240

[app.itemInventoryCoachOnePointHint]
KO: 러닝을 시작하면 사용됩니다. 하루 1회.
JA: ランニングを開始すると使用されます。1日1回。

[app.itemInventoryCprQuantity]
KO: 보유량: 3/3
JA: 所持数: 3/3

[app.itemInventoryCrewCheerHint]
KO: 하루 1회. 대회 SHARE 보상만 10% 늘어납니다.
JA: 1日1回。大会のSHARE報酬のみ10%増加します。

[app.itemInventoryDonationMatchNote]
KO: 100 VALUE. 운영자 명의 1,000원이 러닝 기부 풀에 더해지고 내 이름이 함께 표시됩니다. 영수증은 없습니다.
JA: 100 VALUE。運営者名義で1,000ウォンがランニング寄付プールに追加され、あなたの名前も一緒に表示されます。領収書は発行されません。

[app.itemInventoryDonationMatchUse]
KO: 매칭하기
JA: マッチングする

[app.itemInventoryExtraEntryHint]
KO: 모집 마감·정원 초과 참가 시 사용됩니다. 하루 2회.
JA: 募集締切・定員超過の参加時に使用されます。1日2回。

[app.itemInventoryFriendGhostHint]
KO: 러닝 중 친구 기록과 비교합니다. 내 최고 기록은 무료입니다.
JA: ランニング中に友達の記録と比較します。自分の最高記録は無料です。

[app.itemInventoryRestDayNote]
KO: 매주 1회 무료. 추가 보유분만 VALUE로 샀습니다. 휴식일은 출석으로 세지 않고 스트릭도 끊지 않습니다.
JA: 毎週1回無料。追加分のみVALUEで購入しました。休息日は出席にカウントされず、ストリークも途切れません。

[app.itemInventoryRestDayToday]
KO: 오늘 휴식
JA: 本日休息

[app.itemInventoryRestDayYesterday]
KO: 어제 휴식
JA: 昨日休息

[app.itemInventorySafeGuardQuantity]
KO: 보유량: 1/1
JA: 所持数: 1/1

[app.itemInventoryTitle]
KO: 내 아이템 보관함
JA: マイアイテム保管庫

[app.itemInventoryUse]
KO: 사용하기
JA: 使用する

[item_inventory.body]
KO: 보유량: ${shop.cprCount}
JA: 所持数: ${shop.cprCount}

[item_inventory.body.2]
KO: 보유량: ${shop.safeGuardCount}
JA: 所持数: ${shop.safeGuardCount}

[item_inventory.body.3]
KO: 보유량: ${shop.coachOnePointCount}
JA: 所持数: ${shop.coachOnePointCount}

[item_inventory.body.4]
KO: 보유량: ${shop.extraEntryCount}
JA: 所持数: ${shop.extraEntryCount}

[item_inventory.body.5]
KO: 보유량: ${shop.friendGhostCount}
JA: 所持数: ${shop.friendGhostCount}

[item_inventory.body.6]
KO: 보유량: ${shop.crewCheerCount}
JA: 所持数: ${shop.crewCheerCount}

[item_inventory.body.7]
KO: 보유량: ${shop.boostRunCount}
${AppStrings.itemInventoryBoostRunQuantityNote}
JA: 所持数: ${shop.boostRunCount}
${AppStrings.itemInventoryBoostRunQuantityNote}

[item_inventory.body.8]
KO: 보유량: ${shop.stepIncubatorCount}
${AppStrings.itemInventoryStepIncubatorQuantityNote}
JA: 所持数: ${shop.stepIncubatorCount}
${AppStrings.itemInventoryStepIncubatorQuantityNote}

[item_inventory.body.9]
KO: 추가 보유: ${shop.restDayCount}
${AppStrings.itemInventoryRestDayNote}
JA: 追加所持: ${shop.restDayCount}
${AppStrings.itemInventoryRestDayNote}

[item_inventory.toast]
KO: 이미 처리된 매칭입니다. VALUE는 한 번만 차감됩니다.
JA: すでに処理済みのマッチングです。VALUEは1回のみ引き落とされます。

[item_inventory.toast.2]
KO: 기부 매칭을 기록했습니다.
JA: 寄付マッチングを記録しました。

[item_inventory.toast.3]
KO: 기부 매칭을 기록하지 못했습니다.
JA: 寄付マッチングを記録できませんでした。

[item_inventory.toast.4]
KO: 이미 처리된 휴식일 지정입니다.
JA: 指定済みの休息日設定です。

[item_inventory.toast.5]
KO: $label 완료
JA: $label 完了

[item_inventory.toast.6]
KO: 휴식일을 지정하지 못했습니다.
JA: 休息日を指定できませんでした。

[item_inventory.toast.7]
KO: $title 보유량이 없습니다. 상점에서 구매해 주세요.
JA: $titleの所持数がありません。ショップで購入してください。

[item_inventory.toast.8]
KO: $title 사용 완료
JA: $titleの使用完了

[item_inventory.toast.9]
KO: $title 을 사용하지 못했습니다.
JA: $titleを使用できませんでした。

[jena_validation.jena_pending_gate.body]
KO: 케이던스(발구름) 데이터가 없거나 0입니다. 기록이 보류되었습니다.
JA: ケイデンス（歩頻）データがないか0です。記録が保留されました。

[jena_validation.jena_pending_gate.body.2]
KO: 심박수 추이가 페이스 증가에 반응하지 않아 차량·자전거·킥보드 탑승이 의심됩니다.
JA: 心拍数の推移がペースの上昇に連動していないため、車両・自転車・キックボード等の利用が疑われます。

[jena_validation.jena_pending_gate.body.3]
KO: GPS 오차 범위를 넘는 순간 이동 속도가 검출되어 기록이 거절되었습니다.
JA: GPSの許容誤差を超える瞬間移動速度が検出されたため、記録が却下されました。

[jena_validation.jena_pending_gate.body.4]
KO: 비정상적인 GPS 순간 속도가 검출되어 기록이 보류되었습니다.
JA: 異常なGPS瞬間速度が検出されたため、記録が保留されました。

[jena_validation.mock_jena_validation_service.body]
KO: GPS 궤적 또는 거리 데이터가 부족합니다.
JA: GPSの軌跡または距離データが不足しています。

[jena_validation.mock_jena_validation_service.body.2]
KO: 순수 노력 러닝으로 Jena AI 검증이 완료되었습니다.
JA: 純粋な努力によるランニングとしてJena AI検証が完了しました。

[jena_validation.verification_guidance.body]
KO: 이번 대회의 검증 최소 거리는 $distance예요. 대회 거리가 더 짧아도 1km는 넘어야 해요.
JA: 今大会の検証最低距離は$distanceです。大会の距離がこれより短くても、1kmを超える必要があります。

[jena_validation.verification_guidance.body.2]
KO: 분당 걸음 수는 120~210이어야 해요.
JA: 1分あたりの歩数は120〜210である必要があります。

[jena_validation.verification_guidance.body.3]
KO: 워치 심박은 운영자 대회 상급·하프·파이널에서만 필요해요.
JA: スマートウォッチの心拍数は、運営者大会の上級・ハーフ・ファイナルでのみ必要です。

[jena_validation.verification_guidance.body.4]
KO: 이 대회는 워치 심박이 있어야 완주로 인정돼요.
JA: この大会はスマートウォッチの心拍数がないと完走として認められません。

[jena_validation.verification_guidance.body.5]
KO: 기록은 언제나, 보상은 검증된 달리기에만.
JA: 記録はいつでも、報酬は検証されたランニングにのみ。

[jena_validation.verification_guidance.body.6]
KO: 검증 안내
JA: 検証のご案内

[jena_validation.verification_guidance.body.7]
KO: 확인하고 참가
JA: 確認して参加

[jena_validation.verification_guidance.body.8]
KO: 다시 보지 않기
JA: 今後表示しない

[jena_validation.verification_reason.body]
KO: 거리가 이번 대회의 최소 거리보다 짧아요. 대회 거리만큼, 적어도 1km는 달려야 해요. 기록은 남고 보상은 지급되지 않아요.
JA: 距離が今大会の最低距離より短いです。大会の距離かつ少なくとも1km以上走る必要があります。記録は残りますが、報酬は支給されません。

[jena_validation.verification_reason.body.2]
KO: 분당 걸음 수가 120~210 범위를 벗어났어요. 기록은 남고 보상은 지급되지 않아요.
JA: 1分あたりの歩数が120〜210の範囲外です。記録は残りますが、報酬は支給されません。

[jena_validation.verification_reason.body.3]
KO: 상급·하프·파이널 대회는 워치 심박이 있어야 완주로 인정돼요. 심박이 없어 보상은 지급되지 않아요.
JA: 上級・ハーフ・ファイナル大会はスマートウォッチの心拍数がないと完走として認められません。心拍数がないため報酬は支給されません。

[jena_validation.verification_reason.body.4]
KO: 평균 심박이 달리기라고 보기엔 낮아요. 기록은 남고 보상은 지급되지 않아요.
JA: 平均心拍数がランニングとみなすには低すぎます。記録は残りますが、報酬は支給されません。

[jena_validation.verification_reason.body.5]
KO: 심박이 거의 변하지 않아 달리기로 확인되지 않았어요. 기록은 남고 보상은 지급되지 않아요.
JA: 心拍数にほとんど変化が見られないため、ランニングとして確認できませんでした。記録は残りますが、報酬は支給されません。

[jena_validation.verification_reason.body.6]
KO: 워치가 없어 보폭을 확인했는데, 거리와 걸음 수가 달리기 범위가 아니에요. 기록은 남고 보상은 지급되지 않아요.
JA: スマートウォッチがないため歩幅を確認しましたが、距離と歩数がランニングの範囲外です。記録は残りますが、報酬は支給されません。

[jena_validation.verification_reason.body.7]
KO: 이동 속도가 차량에 가까워 달리기로 인정되지 않았어요. 기록은 남고 보상은 지급되지 않아요.
JA: 移動速度が車両に近いため、ランニングとして認められませんでした。記録は残りますが、報酬は支給されません。

[jena_validation.verification_reason.body.8]
KO: 킥보드나 탑승으로 보여 보상은 지급되지 않아요. 기록은 남아요.
JA: キックボードや乗り物での移動と判断されたため、報酬は支給されません。記録は残ります。

[jena_validation.verification_reason.body.9]
KO: 자전거 탑승으로 보여 보상은 지급되지 않아요. 기록은 남아요.
JA: 自転車に乗っていたと判断されたため、報酬は支給されません。記録は残ります。

[launch.intro.body]
KO: 걸으면 SHARE가 쌓여요
JA: 歩くとSHAREが貯まります

[launch.intro.body.10]
KO: +100원
JA: +100ウォン

[launch.intro.body.11]
KO: 회사(운영자) 자금으로 기부 예정 · 내가 내는 돈은 없어요 · 내 기여는 앱에서 확인
JA: 会社（運営者）の資金で寄付予定 · 自己負担はありません · 貢献度はアプリで確認

[launch.intro.body.13]
KO: 지금
달팽이
JA: 現在
カタツムリ

[launch.intro.body.14]
KO: 등급을
받으면
JA: ランクを
獲得すると

[launch.intro.body.15]
KO: 티어가
오르면
JA: ティアが
上がると

[launch.intro.body.2]
KO: 한 걸음이 나눔이 된다
JA: 一歩が分かち合いになる

[launch.intro.body.3]
KO: 내 기록은 어느 폰에서나 그대로예요
JA: どのスマホでも記録はそのままです

[launch.intro.body.4]
KO: 100걸음마다 10 SHARE를 받아요. 모은 SHARE로 대회에 참가할 수 있어요.
JA: 100歩ごとに10 SHAREを獲得できます。貯めたSHAREで大会に参加できます。

[launch.intro.body.5]
KO: SHARE는 현금으로 바꿀 수 없는 활동 보상이고, 하루에 받을 수 있는 양에 한도가 있어요.
JA: SHAREは現金に換金できないアクティビティ報酬であり、1日に獲得できる量には上限があります。

[launch.intro.body.6]
KO: 검증된 모든 달리기, 1km마다 운영자가 100원을 기부할 예정이에요. 내가 보탠 만큼은 앱에서 확인할 수 있어요.
JA: 検証されたすべてのランニングで、1kmごとに運営者が100ウォンを寄付する予定です。自分が貢献した分はアプリで確認できます。

[launch.intro.body.7]
KO: 운영자의 월 기부 예산 안에서 진행될 예정이에요. 예산을 다 쓴 달은 넘는 거리가 기록으로 남아요.
JA: 運営者の月間寄付予算の範囲内で行う予定です。予算を使い切った月は、超過した距離が記録として残ります。

[launch.intro.body.8]
KO: 걷기·달리기 기록은 서버에 저장돼요. 폰을 바꿔도 로그인하면 이어져요.
JA: ウォーキングやランニングの記録はサーバーに保存されます。機種変更してもログインすれば引き継がれます。

[launch.intro.body.9]
KO: 100걸음
JA: 100歩

[launch.intro.button]
KO: 시작하기
JA: 始める

[launch.intro.button.2]
KO: 이미 계정이 있어요 · 로그인
JA: アカウントをお持ちの方 · ログイン

[legal.health_data_consent.body]
KO: 체크해야 워치 연동·심박 검증이 활성화됩니다.
JA: チェックするとウォッチ連携・心拍検証が有効になります。

[legal_constants.body]
KO: 결제 취소 (현금 환불)
JA: 決済キャンセル（現金返金）

[legal_constants.body.10]
KO: 마케팅·활동 알림 (선택)
JA: マーケティング・アクティビティ通知（任意）

[legal_constants.body.12]
KO: 부정 러닝·결제 어뷰징은 계정 제한 대상이 될 수 있습니다.
JA: 不正なランニングや決済の不正利用はアカウント制限の対象となる場合があります。

[legal_constants.body.14]
KO: 전체 내용은 개인정보 처리방침 전문에서 확인할 수 있습니다.
JA: 詳細はプライバシーポリシーの全文でご確認いただけます。

[legal_constants.body.17]
KO: 대회 모집, 검증 결과, 리워드·기부 알림을 푸시로 받을 수 있습니다. 언제든 MyPage에서 변경할 수 있습니다.
JA: 大会の募集、検証結果、リワード・寄付の通知をプッシュで受け取ることができます。MyPageでいつでも変更可能です。

[legal_constants.body.18]
KO: 심박수·케이던스 원본 데이터는 기기 메모리에서 검증한 뒤 바로 폐기하며, 검증 결과 요약만 저장합니다.
JA: 心拍数とケイデンスの生データは端末のメモリ上で検証後すぐに破棄され、検証結果の概要のみが保存されます。

[legal_constants.body.19]
KO: 건강 정보 안내
JA: 健康情報に関するご案内

[legal_constants.body.2]
KO: [선택] 건강정보(심박수) 수집 및 이용 동의
JA: 【任意】健康情報（心拍数）の収集および利用への同意

[legal_constants.body.21]
KO: 가슴 통증, 어지러움 등 이상이 느껴지면 즉시 운동을 멈추고 의료진과 상담하세요.
JA: 胸の痛みやめまいなどの異常を感じた場合は、直ちに運動を中止し、医師にご相談ください。

[legal_constants.body.23]
KO: 언제든 해지할 수 있으며, 해지해도 이미 결제한 기간이 끝날 때까지 이용할 수 있습니다.
JA: いつでも解約でき、解約してもすでにお支払い済みの期間が終了するまでご利用いただけます。

[legal_constants.body.3]
KO: 건강정보 수집 동의 (선택 · 별도)
JA: 健康情報の収集への同意（任意・個別）

[legal_constants.body.4]
KO: 개인정보 처리방침 전문 보기
JA: プライバシーポリシーの全文を見る

[legal_constants.body.5]
KO: 서비스 이용약관 전문 보기
JA: 利用規約の全文を見る

[legal_constants.body.6]
KO: AI 생성 이미지 안내
JA: AI生成画像に関するご案内

[legal_constants.body.7]
KO: 일부 그림은 AI로 생성되었습니다. Created with Grok
JA: 一部の画像はAIによって生成されました。Created with Grok

[legal_constants.body.8]
KO: 서비스 이용약관 (필수)
JA: 利用規約（必須）

[legal_constants.body.9]
KO: 개인정보 처리방침 (필수)
JA: プライバシーポリシー（必須）

[app.levelTestChallengeProgress]
KO: 챌린지 진행 상황: 2/3회 완료 (3.52/5.00 KM)
JA: チャレンジ進行状況: 2/3回完了 (3.52/5.00 KM)

[app.levelTestGhostPace]
KO: [고스트 페이스]
JA: [ゴーストペース]

[app.levelTestMyLocation]
KO: [나(현재 위치)]
JA: [自分（現在地）]

[app.levelTestStartRun]
KO: 3회차 달리기 시작하기
JA: 3回目の走りを開始する

[app.levelTestStatDistance]
KO: 현재 거리
JA: 現在の距離

[app.levelTestStatPace]
KO: 현재 페이스
JA: 現在のペース

[app.levelTestStatTime]
KO: 경과 시간
JA: 経過時間

[app.levelTestSubtitle]
KO: 검증된 달리기를 서로 다른 날 3번 마치면 등급이 배정됩니다.
JA: 異なる日に認証ランを3回完了すると、ランクが判定されます。

[app.levelTestTitle]
KO: 혼자 뛰기 챌린지 (등급 배정)
JA: 一人走りチャレンジ（ランク判定）

[app.liveRunningEffortTip]
KO: 순수 노력 목표: 완주 시 VALUE +$valueTokens
JA: 純粋な努力目標: 完走時に VALUE +$valueTokens

[app.liveRunningFinish]
KO: 종료 / 저장
JA: 終了 / 保存

[app.liveRunningGhostPace]
KO: 고스트 페이스
JA: ゴーストペース

[app.liveRunningRoomTitle]
KO: 3km 중급 챌린지
JA: 中級3kmチャレンジ

[app.liveRunningSubmissionsLeft]
KO: 제출 기회: 2/3회 남음
JA: 提出機会: 残り2/3回

[app.liveRunningYouLabel]
KO: 나 (You)
JA: 自分 (You)

[app.runValidationFailed]
KO: 기록 검증에 실패했습니다. 보상이 지급되지 않았습니다.
JA: 記録の検証に失敗しました。報酬は付与されませんでした。

[live_running.body]
KO: 1km 초보 챌린지
JA: 1km ビギナーチャレンジ

[live_running.body.2]
KO: 나
JA: 自分

[live_running.body.3]
KO: 고스트
JA: ゴースト

[live_running.body.4]
KO: 검증 중
JA: 検証中

[live_running.toast]
KO: 센서 시작 실패: $error
JA: センサーの起動に失敗しました: $error

[app.existingAccountApple]
KO: 애플로 가입했어요
JA: Appleで登録しました

[app.existingAccountBody]
KO: 그 방법으로 로그인하면 지금 $provider${subjectParticle(provider)} 그 계정에 연결돼요. 닉네임과 재화도 그대로예요.
JA: その方法でログインすると、現在の$provider${subjectParticle(provider)}がそのアカウントに連携されます。ニックネームや保有通貨もそのまま維持されます。

[app.existingAccountCreate]
KO: 새로 시작하기
JA: 新しく始める

[app.existingAccountCreateHint]
KO: 기억나지 않거나 처음이신가요?
JA: 覚えていない、または初めてですか？

[app.existingAccountGoogle]
KO: 구글로 가입했어요
JA: Googleで登録しました

[app.existingAccountKakao]
KO: 카카오로 가입했어요
JA: Kakaoで登録しました

[app.existingAccountNaver]
KO: 네이버로 가입했어요
JA: Naverで登録しました

[app.existingAccountNotFound]
KO: 그 방법으로 가입된 계정이 없어요. 다른 방법을 골라 주세요.
JA: その方法で登録されたアカウントがありません。別の方法を選択してください。

[app.existingAccountTitle]
KO: 처음 가입할 때 어떤 방법을 쓰셨나요?
JA: 最初に登録した際はどの方法を利用しましたか？

[app.linkAttached]
KO: $method${subjectParticle(method)} 연결됐어요. 이제 어느 쪽으로 들어와도 같은 계정이에요.
JA: $method${subjectParticle(method)}が連携されました。今後はどちらからログインしても同じアカウントです。

[app.linkConfirmNo]
KO: 아니에요, 다시 고를게요
JA: いいえ、選び直します

[app.linkConfirmTitle]
KO: 이 계정에 $method${objectParticle(method)} 연결할까요?
JA: このアカウントに$method${objectParticle(method)}を連携しますか？

[app.linkConfirmYes]
KO: 네, 연결할게요
JA: はい、連携します

[app.loginComingSoon]
KO: $provider 로그인은 준비 중입니다.
JA: $provider ログインは準備中です。

[app.loginGoogle]
KO: Google로 계속하기
JA: Googleで続ける

[app.loginGuest]
KO: 게스트(테스트)로 시작하기
JA: ゲスト（テスト）で始める

[app.loginGuestLoading]
KO: 게스트 로그인 중...
JA: ゲストログイン中...
