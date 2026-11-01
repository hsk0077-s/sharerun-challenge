# 번역 검수 요청 — 쉐어런 (English) · 파트 2/7

아래는 한국어 앱 "쉐어런"(걷기·달리기 앱, 회사 자금 기부 연계)의 화면 문구를 English(으)로 번역한 것입니다.
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
[app.crewManagerShareWarning]
KO: SHARE 결제 시 주의하세요
EN: Please take caution when paying with SHARE

[app.crewManagerTitle]
KO: 크루 관리 (방장 전용)
EN: Crew Management (Leader Only)

[crew_manager.body]
KO: 처음 한 번은 무료예요.
EN: The first change is free.

[crew_manager.body.10]
KO: 보유 DIA ${wallet.diamondBalance} · SHARE ${wallet.shareBalance}
EN: Balance: DIA ${wallet.diamondBalance} · SHARE ${wallet.shareBalance}

[crew_manager.body.11]
KO: 부방장: ${subs.join(
EN: Co-leaders: ${subs.join(

[crew_manager.body.12]
KO: 📢 전체 공지 푸시 (준비 중)
EN: 📢 Push Announcement to All (Coming Soon)

[crew_manager.body.13]
KO: 크루 이름
EN: Crew name

[crew_manager.body.14]
KO: 이름 변경 (첫 1회 무료)
EN: Change Name (1st time free)

[crew_manager.body.15]
KO: 이름 변경 (${mine.crew.renameCostDia} DIA)
EN: Change Name (${mine.crew.renameCostDia} DIA)

[crew_manager.body.16]
KO: 보관함 아이템
EN: Inventory items

[crew_manager.body.17]
KO: 🎁 크루원 전체에게 심폐소생권·세이프가드 선물 (1인당 $_giftDiaPerMember DIA)
EN: 🎁 Gift CPR Ticket & Safeguard to all members ($_giftDiaPerMember DIA each)

[crew_manager.body.18]
KO: 내가 아닌 크루원의 보관함에 하나씩 들어가요. 한 명에게만 줄 때는 아래 팀원 목록에서 골라요.
EN: One will be sent to each crew member's inventory, except yours. Select from the member list below to send to just one person.

[crew_manager.body.19]
KO: 🚩 크루 응원 깃발 (15 DIA, 하루 1회)
EN: 🚩 Crew Cheering Flag (15 DIA, once daily)

[crew_manager.body.2]
KO: 이름 바꾸기
EN: Change name

[crew_manager.body.20]
KO: 🛡️ 크루 대항전 예치금 대납 (준비 중)
EN: 🛡️ Pay crew battle deposit on behalf (Coming Soon)

[crew_manager.body.21]
KO: 🎉 크루 전용 챌린지 패스 & 스킨 (준비 중)
EN: 🎉 Crew-exclusive challenge pass & skin (Coming Soon)

[crew_manager.body.22]
KO: 소속 팀원 관리 ($count / $limit명)
EN: Manage members ($count / $limit)

[crew_manager.body.23]
KO: 소속 팀원이 없습니다.
EN: No members yet.

[crew_manager.body.24]
KO: $name (방장)
EN: $name (Leader)

[crew_manager.body.25]
KO: $name (부방장)
EN: $name (Co-leader)

[crew_manager.body.3]
KO: "$next"(으)로 바꾸면 $cost DIA가 들어요. 보너스 DIA를 먼저 써요.
EN: Changing to "$next" costs $cost DIA. Bonus DIA will be used first.

[crew_manager.body.4]
KO: $cost DIA 내고 바꾸기
EN: Pay $cost DIA to change

[crew_manager.body.5]
KO: $cost DIA 내고 보내기
EN: Pay $cost DIA to send

[crew_manager.body.6]
KO: +${step.add}명 인원 한도 확장하기 (${step.costDia} DIA)
EN: Expand capacity by +${step.add} (${step.costDia} DIA)

[crew_manager.body.7]
KO: $base · ${crew.maxMembers}명을 모두 채우면 열려요
EN: $base · Unlocks when full (${crew.maxMembers} members)

[crew_manager.body.8]
KO: 크루 정보를 불러오지 못했어요. 크루에 들어 있는지, 네트워크가 연결됐는지 확인해 주세요.
EN: Failed to load crew info. Please check if you belong to a crew and your network is connected.

[crew_manager.body.9]
KO: 크루장과 부크루장만 관리할 수 있어요.
EN: Only the crew leader and co-leaders can manage this.

[crew_manager.button]
KO: 이름을 바꿀 때마다 $cost DIA가 들어요.
EN: Costs $cost DIA per change

[crew_manager.button.2]
KO: 저장
EN: Save

[crew_manager.button.3]
KO: 선물
EN: Gift

[crew_manager.button.4]
KO: 부방장 해제
EN: Dismiss Co-leader

[crew_manager.dialog]
KO: 크루 이름 변경
EN: Change crew name

[crew_manager.toast]
KO: 아직 열리지 않았어요. 준비되면 알려드릴게요.
EN: Not open yet. We'll let you know when it's ready.

[crew_manager.toast.10]
KO: ${step.costDia} DIA 내고 늘리기
EN: Pay ${step.costDia} DIA to expand

[crew_manager.toast.11]
KO: 인원 한도가 ${result.maxMembers}명이 됐어요.
EN: Member limit is now ${result.maxMembers}.

[crew_manager.toast.12]
KO: 크루장만 늘릴 수 있어요.
EN: Only the crew leader can expand.

[crew_manager.toast.13]
KO: 자리를 모두 채워야 하거나 이미 최대예요.
EN: Must fill all spots first or limit is already maxed.

[crew_manager.toast.14]
KO: 인원 한도를 늘리지 못했어요. 잠시 뒤 다시 해 주세요.
EN: Failed to expand member limit. Please try again later.

[crew_manager.toast.15]
KO: 크루 응원 깃발을 걸었습니다. 오늘 대회 SHARE 보상이 10% 늘어납니다.
EN: crew cheer banner hung. Today's contest SHARE rewards +10%.

[crew_manager.toast.16]
KO: 응원 깃발을 걸지 못했습니다.
EN: Failed to hang cheer banner.

[crew_manager.toast.17]
KO: 선물을 받을 크루원이 없어요.
EN: No crew members to receive gifts.

[crew_manager.toast.18]
KO: 크루원 $count명 모두
EN: All $count crew members

[crew_manager.toast.19]
KO: ${member.nickname}님
EN: ${member.nickname}

[crew_manager.toast.2]
KO: 크루 이름을 "$next"(으)로 바꿨어요.
EN: crew name changed to "$next".

[crew_manager.toast.20]
KO: 심폐소생권·세이프가드 선물
EN: Gift Revival & Safeguard

[crew_manager.toast.21]
KO: $who에게 심폐소생권과 세이프가드를 하나씩 보내요. 한 명당 $_giftDiaPerMember DIA, 모두 $cost DIA가 들고 보너스 DIA를 먼저 써요.
EN: Send 1 Revival and 1 Safeguard to $who. Costs $_giftDiaPerMember DIA each, total $cost DIA. Bonus DIA used first.

[crew_manager.toast.22]
KO: ${result.recipients}명의 보관함에 선물을 넣었어요. (−$cost DIA)
EN: Gifts sent to ${result.recipients} members' inventory. (−$cost DIA)

[crew_manager.toast.23]
KO: 크루장만 선물할 수 있어요.
EN: Only the crew leader can send gifts.

[crew_manager.toast.24]
KO: 그 크루원을 찾지 못했어요.
EN: Could not find that crew member.

[crew_manager.toast.25]
KO: 선물을 보내지 못했어요. 잠시 뒤 다시 해 주세요.
EN: Failed to send the gift. Please try again in a moment.

[crew_manager.toast.26]
KO: ${member.nickname}님을 부방장으로 임명했어요.
EN: Appointed ${member.nickname} as co-leader.

[crew_manager.toast.27]
KO: ${member.nickname}님을 크루원으로 돌렸어요.
EN: Changed ${member.nickname} back to crew member.

[crew_manager.toast.28]
KO: 바꾸지 못했어요. 잠시 뒤 다시 해 주세요.
EN: Failed to update. Please try again in a moment.

[crew_manager.toast.29]
KO: 크루원 내보내기
EN: Remove crew member

[crew_manager.toast.3]
KO: DIA가 모자라거나 쓸 수 없는 이름이에요.
EN: Not enough DIA or invalid name.

[crew_manager.toast.30]
KO: ${member.nickname}님을 크루에서 내보낼까요?
EN: Remove ${member.nickname} from the crew?

[crew_manager.toast.31]
KO: 내보내기
EN: Remove

[crew_manager.toast.32]
KO: ${member.nickname}님을 내보냈어요.
EN: Removed ${member.nickname}.

[crew_manager.toast.33]
KO: 내보내지 못했어요. 잠시 뒤 다시 해 주세요.
EN: Failed to remove. Please try again in a moment.

[crew_manager.toast.34]
KO: 인원 한도 최대 (${crew.maxMembers}명)
EN: Max member capacity reached (${crew.maxMembers})

[crew_manager.toast.4]
KO: 크루장만 이름을 바꿀 수 있어요.
EN: Only the crew leader can change the name.

[crew_manager.toast.5]
KO: 이름을 바꾸지 못했어요. 잠시 뒤 다시 해 주세요.
EN: Failed to change name. Please try again later.

[crew_manager.toast.6]
KO: 인원 한도가 최대(${mine.crew.maxMembers}명)예요.
EN: Member limit is at max (${mine.crew.maxMembers} members).

[crew_manager.toast.7]
KO: 자리를 모두 채우면 더 늘릴 수 있어요. (${mine.crew.maxMembers}명)
EN: Fill all spots to expand limit. (${mine.crew.maxMembers} members)

[crew_manager.toast.8]
KO: 인원 한도 확장
EN: Expand member limit

[crew_manager.toast.9]
KO: 크루 인원 한도를 ${step.add}명 늘려요. ${step.costDia} DIA가 들고, 보너스 DIA를 먼저 써요.
EN: Expand crew limit by ${step.add}. Costs ${step.costDia} DIA; bonus DIA used first.

[crew_ranking_model.body]
KO: 쉐어런 크루
EN: ShareRun Crew

[crew_room.body]
KO: 크루에 들어 있어야 크루 룸을 볼 수 있어요. 크루에 들어갔는지, 네트워크가 연결됐는지 확인해 주세요.
EN: You must be in a crew to view the Crew Room. Please check if you have joined a crew and if your network is connected.

[crew_room.body.2]
KO: } · 내 역할 ${CrewRoomScreen._roleLabel(mine.role)}
EN: } · My role: ${CrewRoomScreen._roleLabel(mine.role)}

[crew_room.body.3]
KO: 크루 대항전은 아직 열리지 않았어요. 열리면 여기서 이번 주 진행을 볼 수 있어요.
EN: Crew battles haven't started yet. Once open, you can view this week's progress here.

[crew_room.button]
KO: 크루 룸
EN: Crew Room

[device_connection.body]
KO: (Apple Watch 전 기종 지원)
EN: (Supports all Apple Watch models)

[device_connection.body.2]
KO: Health Connect 설치 화면을 열었어요. 설치 후 다시 연결해 주세요.
EN: Opened the Health Connect installation screen. Please reconnect after installing.

[device_connection.body.3]
KO: ♥ 연결됨
EN: ♥ Connected

[device_connection.body.4]
KO: 미연결
EN: Not Connected

[device_connection.body.5]
KO: 연결된 센서: ${snap.deviceName}
EN: Connected Sensor: ${snap.deviceName}

[device_connection.button]
KO: 워치 앱 연결 코드 · 연결된 워치
EN: Watch Connection Code · Linked Watch

[device_connection.button.2]
KO: 권한 설정 필요
EN: Permission Required

[device_connection.button.3]
KO: 정확한 측정을 위해 권한 설정이 필요합니다.
EN: Permission settings are required for accurate measurement.

[device_connection.dialog]
KO: 연동 불가
EN: Sync Unavailable

[device_connection.dialog.2]
KO: 고객님의 스마트워치 OS 버전이 낮거나 호환되지 않아 연동할 수 없습니다. 워치를 최신 버전(watchOS 8+, Wear OS 3.0+)으로 업데이트해 주세요.
EN: Your smartwatch OS version is too low or incompatible. Please update your watch to the latest version (watchOS 8+, Wear OS 3.0+).

[device_connection.toast]
KO: 등급 배정 화면 이동 실패: $e
EN: Failed to navigate to tier assignment screen: $e

[device_connection.toast.2]
KO: 건너뛰기 실패: $e
EN: Skip failed: $e

[device_connection.toast.3]
KO: ${watchType.displayLabel} 연동이 완료되었습니다!
EN: ${watchType.displayLabel} sync complete!

[device_connection.toast.4]
KO: Health Connect를 열 수 없어요. Play 스토어에서 설치해 주세요.
EN: Unable to open Health Connect. Please install it from the Play Store.

[device_connection.toast.5]
KO: 권한이 거부되었습니다.
EN: Permission was denied.

[device_connection.toast.6]
KO: Google Health Connect 연동이 완료되었습니다!
EN: Google Health Connect sync complete!

[device_connection.toast.7]
KO: 기기가 호환되지 않거나 연동 중 오류가 발생했습니다.
EN: Device is not compatible or an error occurred during sync.

[device_connection.toast.8]
KO: Garmin 연동 화면을 열 수 없습니다: $e
EN: Unable to open Garmin sync screen: $e

[device_connection.toast.9]
KO: ${watchType.displayLabel} 연동 설정이 저장되었습니다.
EN: ${watchType.displayLabel} sync settings saved.

[app.bleHrConnectButton]
KO: 연결
EN: Connect

[app.bleHrDisconnectButton]
KO: 연결 해제
EN: Disconnect

[app.bleHrGuideItems]
KO: 가민(Garmin)
EN: Garmin

[app.bleHrGuideItems.2]
KO: 시계 설정 → 센서 및 액세서리 → 손목 심박수 → "심박수 전송" 켜기
EN: Watch Settings → Sensors & Accessories → Wrist Heart Rate → Turn on "Broadcast Heart Rate"

[app.bleHrGuideItems.3]
KO: 샤오미 · 어메이즈핏
EN: Xiaomi · Amazfit

[app.bleHrGuideItems.4]
KO: 운동·심박수 설정 → "심박수 공유/전송" 켜기
EN: Workout & Heart Rate Settings → Turn on "Heart Rate Sharing/Broadcast"

[app.bleHrGuideItems.5]
KO: 가슴·암밴드 센서
EN: Chest & Armband Sensors

[app.bleHrGuideItems.6]
KO: 착용한 뒤 아래 [센서 찾기] 누르기 (Polar, Wahoo, Coospo, Magene)
EN: Put it on and tap [Find Sensor] below (Polar, Wahoo, Coospo, Magene)

[app.bleHrGuideItems.7]
KO: 갤럭시 워치 · 애플워치
EN: Galaxy Watch · Apple Watch

[app.bleHrGuideItems.8]
KO: 이 방식이 아니에요. 위의 Health Connect / Apple 건강으로 연결하세요
EN: Not this method. Please connect via Health Connect / Apple Health above

[app.bleHrGuideTitle]
KO: 내 기기별로 이렇게 하세요
EN: How to set up your device

[app.bleHrScanningLabel]
KO: 근처 심박 센서 찾는 중...
EN: Searching for nearby heart rate sensors...

[app.bleHrSectionSubtitle]
KO: Health Connect 지연 없이 달리는 동안 실시간 심박수(0x180D)를 바로 받습니다.
EN: Directly receives real-time heart rate (0x180D) while running without Health Connect delay.

[app.bleHrStopScanButton]
KO: 스캔 중지
EN: Stop Scan

[app.deviceConnectionConnect]
KO: 기기 연결
EN: Connect Device

[app.deviceConnectionExternalTitle]
KO: 외부 전문 기기 연동
EN: External Professional Device Sync

[app.deviceConnectionGoogleCaption]
KO: (갤럭시 워치, 샤오미 미밴드, 어메이즈핏, 가민, 핏빗 등)
EN: (Galaxy Watch, Xiaomi Mi Band, Amazfit, Garmin, Fitbit, etc.)

[app.deviceConnectionNativeTitle]
KO: 네이티브 헬스 연동
EN: Native Health Sync

[app.deviceConnectionNone]
KO: 연결된 기기가 없습니다
EN: No connected devices

[app.deviceConnectionSingleActiveNote]
KO: 쉐어런은 동시에 하나의 운동 기기만 활성 연결 상태로 유지합니다.
EN: ShareRun maintains an active connection with only one workout device at a time.

[app.deviceConnectionStatusTitle]
KO: 현재 연결된 기기
EN: Currently Connected Device

[app.healthConnectNoSamplesTip]
KO: 권한은 연결되었어요. 밴드/워치 앱 안에서 Health Connect 데이터 쓰기 스위치가 켜져 있는지 확인해 주세요. 스마트밴드 기록은 밴드 앱 동기화 후 반영됩니다.
EN: Permissions are connected. Please check if the Health Connect data write switch is turned on inside your band/watch app. Smart band records will appear after syncing with the band app.

[dia_pack_store.body]
KO: $price원 · ${pack.bonusLabel}
EN: $price won · ${pack.bonusLabel}

[dia_pack_store.body.2]
KO: 기본 ${pack.baseDia} DIA · ${pack.productId}
EN: Base ${pack.baseDia} DIA · ${pack.productId}

[dia_pack_store.title]
KO: DIA 팩
EN: DIA Pack

[diamond_box_model.body]
KO: 다이아 상자
EN: DIA Box

[donation_settlement.body]
KO: 운영자가 자기 돈으로 검증 1km당 100원(KRW)을 월 예산 안에서 기부할 예정입니다. 이용자의 기부금이 아니며 세금 공제 영수증이 발급되지 않습니다.
EN: The operator plans to donate 100 KRW per verified 1km from its own money within the monthly budget. This is not a user donation, and tax deduction receipts are not issued.

[economy_constants.body]
KO: 구매 후 7일 이내, 100% 미사용 분에 한해 환불 가능
EN: Refundable within 7 days of purchase only if 100% unused

[email_verification_guard.button]
KO: 결제·대회 참가 전에 이메일 인증을 완료해 주세요. 상단 배너에서 인증 메일을 재발송할 수 있습니다.
EN: Please complete email verification before making payments or entering competitions. You can resend the verification email from the top banner.

[email_verification_guard.dialog]
KO: 이메일 인증 필요
EN: Email verification required

[external_oauth_webview.body]
KO: 이메일 아이디를 입력해 주세요.
EN: Please enter your email ID.

[external_oauth_webview.body.2]
KO: 올바른 이메일 형식이 아닙니다.
EN: Invalid email format.

[external_oauth_webview.body.3]
KO: 비밀번호를 입력해 주세요.
EN: Please enter your password.

[external_oauth_webview.body.4]
KO: 비밀번호가 너무 짧습니다.
EN: Password is too short.

[external_oauth_webview.toast]
KO: 연동 중 오류가 발생했습니다. 앱으로 돌아가 다시 시도해 주세요.
EN: An error occurred during linking. Please return to the app and try again.

[app.externalPaymentNoticeHighlight]
KO: 실제 야외 물리적 활동(오프라인 러닝)
EN: actual outdoor physical activity (offline running)

[app.externalPaymentNoticePrefix]
KO: 본 결제는
EN: This payment is for purchasing an entry ticket to

[app.externalPaymentNoticeSuffix]
KO: 참여를 위한 참가권 구매입니다.
EN: .

[app.externalPaymentRefundNote]
KO: * 미사용 쿠폰에 한해 언제든 100% 수수료 없이 환불 가능합니다.
EN: * Unused coupons can be refunded 100% at any time without any fees.

[app.externalPaymentSecurePaySuffix]
KO: 원 안전 결제하기
EN: KRW Secure Payment

[firebase_auth_messages.body]
KO: 로그인이 취소되었습니다.
EN: Login cancelled.

[firebase_auth_messages.body.10]
KO: 다른 로그인 방식으로 가입된 이메일입니다.
EN: This email is registered with a different sign-in method.

[firebase_auth_messages.body.11]
KO: 보안을 위해 다시 로그인한 뒤 계정 삭제를 시도해 주세요.
EN: For security reasons, please log in again before deleting your account.

[firebase_auth_messages.body.12]
KO: 로그인에 실패했습니다.
EN: Failed to sign in.

[firebase_auth_messages.body.2]
KO: 이메일 형식이 올바르지 않습니다.
EN: Invalid email format.

[firebase_auth_messages.body.3]
KO: 비활성화된 계정입니다. 고객센터에 문의해 주세요.
EN: This account has been disabled. Please contact customer support.

[firebase_auth_messages.body.4]
KO: 이메일 또는 비밀번호를 확인해 주세요.
EN: Please check your email or password.

[firebase_auth_messages.body.5]
KO: 이미 사용 중인 이메일입니다.
EN: This email is already in use.

[firebase_auth_messages.body.6]
KO: 비밀번호는 6자 이상이어야 합니다.
EN: Password must be at least 6 characters long.

[firebase_auth_messages.body.7]
KO: 요청이 너무 많습니다. 잠시 후 다시 시도해 주세요.
EN: Too many requests. Please try again later.

[firebase_auth_messages.body.8]
KO: 네트워크 연결을 확인해 주세요.
EN: Please check your network connection.

[firebase_auth_messages.body.9]
KO: Firebase 콘솔에서 익명(게스트) 로그인을 활성화해 주세요.
EN: Please enable anonymous (guest) sign-in in the Firebase console.

[app.garminAuthSubtitle]
KO: 안전한 OAuth 2.0 공식 로그인 페이지입니다.
EN: This is a secure official OAuth 2.0 login page.

[app.garminAuthTitle]
KO: Garmin Connect 연동
EN: Garmin Connect Integration

[app.garminCancelAndReturn]
KO: 연동을 취소하고 앱으로 돌아가기
EN: Cancel integration and return to app

[app.garminEmailHint]
KO: 이메일 아이디
EN: Email address

[app.garminPasswordHint]
KO: 비밀번호
EN: Password

[app.garminSignInAuthorize]
KO: 로그인하고 권한 허용
EN: Sign in and authorize

[app.garminSignInAuthorizeKo]
KO: (로그인 및 권한 허용)
EN: (Sign in and authorize)

[app.hallOfFameDonateCta]
KO: 나도 기부하고 명예의 전당 오르기 💎
EN: Donate and enter the Hall of Fame 💎

[app.hallOfFameDonateHistoryTitle]
KO: 명예의 전당 기부 완료 🕊️
EN: Hall of Fame Donation Completed 🕊️

[app.hallOfFameLeaderDonation]
KO: 누적 기부: 5,000,000 VALUE
EN: Total Donated: 5,000,000 VALUE

[app.hallOfFameLeaderName]
KO: 서울 나이트 러너스 방장님
EN: Seoul Night Runners Leader

[app.hallOfFameLeaderTitle]
KO: 👑 이달의 소셜 임팩트 리더
EN: 👑 Social Impact Leader of the Month

[app.hallOfFameRank2Badge]
KO: 🔥 불꽃 SBT 뱃지
EN: 🔥 Flame SBT Badge

[app.hallOfFameRank2Label]
KO: 2등
EN: 2nd Place

[app.hallOfFameRank2Subtitle]
KO: 연속 50일 완주자
EN: 50-Day Consecutive Finisher

[app.hallOfFameRank3Badge]
KO: 🛡️ 방패 SBT 뱃지
EN: 🛡️ Shield SBT Badge

[app.hallOfFameRank3Label]
KO: 3등
EN: 3rd Place

[app.hallOfFameRank3Subtitle]
KO: 최다 크루원 후원자
EN: Top Crew Supporter

[app.hallOfFameTitle]
KO: 명예의 전당 (Hall of Fame)
EN: Hall of Fame

[app.runningCrewHallOfFame]
KO: 👑 명예의 전당
EN: 👑 Hall of Fame

[app.storeDonateHistoryTitle]
KO: 기부 펀딩 참여 🕊️
EN: Donation Funding Joined 🕊️

[hall_of_fame.body]
KO: 서버 원장에서 $_donateValue VALUE를 기부했습니다.
EN: Donated $_donateValue VALUE on the server ledger.

[hall_of_fame.body.2]
KO: 서버 원장에서 $_donateValue VALUE를 기부했습니다. 잔액 $left
EN: Donated $_donateValue VALUE on the server ledger. Balance: $left

[hall_of_fame.body.3]
KO: VALUE가 부족합니다.
EN: Not enough VALUE.

[hall_of_fame.body.4]
KO: 기부에 실패했습니다.
EN: Donation failed.

[hall_of_fame.body.5]
KO: 아직 기록이 없어요
EN: No records yet

[health_data_consent.body]
KO: 개인정보보호법에 따라 건강·생체 데이터는 일반 약관과 분리된 명시적 Opt-in이 필요합니다.
EN: In accordance with privacy laws, health and biometric data require explicit opt-in separate from general terms.

[health_data_consent.button]
KO: 권한 요청 중...
EN: Requesting permissions...

[health_data_consent.button.2]
KO: 동의하고 워치 연동 계속
EN: Agree & Continue Watch Sync

[health_data_consent.button.3]
KO: 나중에 하기
EN: Do it later

[health_data_consent.title]
KO: 건강정보 동의
EN: Health Data Consent

[health_data_consent.title.2]
KO: 스마트워치 연동 전 동의
EN: Consent Before Smartwatch Sync

[home.home_wallet.body]
KO: $completedCount/$total회 완료 >
EN: $completedCount/$total completed >

[iap.coach_plus_product.body]
KO: 6,900원
EN: 6,900 won

[iap.coach_plus_product.body.2]
KO: 59,000원
EN: 59,000 won

[iap.coach_plus_upsell.body]
KO: 무료
EN: Free

[iap.coach_plus_upsell.body.2]
KO: 기본 러닝 안내
EN: Basic running guidance

[iap.coach_plus_upsell.body.3]
KO: Coach+ 이용 중
EN: Using Coach+

[iap.coach_plus_upsell.button]
KO: 구매 복원
EN: Restore Purchases

[iap.dia_pack_product.body]
KO: 보너스 없음
EN: No bonus

[iap.dia_pack_product.body.2]
KO: 보너스 $bonusDia DIA
EN: Bonus $bonusDia DIA

[iap.iap_providers.body]
KO: SHARE 충전 💳
EN: Charge SHARE 💳

[iap.iap_purchase_controller.body]
KO: Google Play 결제 서비스를 사용할 수 없습니다. 잠시 후 다시 시도해 주세요.
EN: Google Play billing service is unavailable. Please try again later.

[iap.iap_purchase_controller.body.10]
KO: 결제 처리 중 오류가 발생했습니다.
EN: An error occurred while processing payment.

[iap.iap_purchase_controller.body.11]
KO: Coach+ 결제가 진행 중입니다.
EN: Coach+ payment is in progress.

[iap.iap_purchase_controller.body.12]
KO: Coach+ 구독이 활성화되었습니다.
EN: Coach+ subscription has been activated.

[iap.iap_purchase_controller.body.13]
KO: Coach+ 결제가 실패했습니다.
EN: Coach+ payment failed.

[iap.iap_purchase_controller.body.14]
KO: Coach+ 결제가 취소되었습니다.
EN: Coach+ payment was cancelled.

[iap.iap_purchase_controller.body.15]
KO: 로그인 후 Google Play 결제를 진행해 주세요.
EN: Please log in before proceeding with Google Play payment.

[iap.iap_purchase_controller.body.16]
KO: 영수증을 보안 검증 중입니다. SHARE는 검증 완료 후 지급됩니다.
EN: Your receipt is undergoing security verification. SHARE will be issued once verification is complete.

[iap.iap_purchase_controller.body.17]
KO: 검증이 완료되어 $shareAmount SHARE가 지급되었습니다.
EN: Verification is complete and $shareAmount SHARE has been granted.

[iap.iap_purchase_controller.body.18]
KO: Google 검증이 완료되어 SHARE가 지갑에 반영됩니다.
EN: Google verification is complete and SHARE will be reflected in your wallet.

[iap.iap_purchase_controller.body.19]
KO: 영수증 검증이 거절되었습니다. 고객센터로 문의해 주세요.
EN: Receipt verification was rejected. Please contact customer support.

[iap.iap_purchase_controller.body.2]
KO: 상품(${plan.productId})을 찾지 못했습니다. Play Console / App Store Connect 등록을 확인해 주세요.
EN: Product (${plan.productId}) not found. Please check registration in Play Console / App Store Connect.

[iap.iap_purchase_controller.body.20]
KO: 검증 응답이 지연되고 있습니다. 지갑 잔액을 잠시 후 다시 확인해 주세요.
EN: Verification response is delayed. Please check your wallet balance again shortly.

[iap.iap_purchase_controller.body.21]
KO: 결제 스트림이 일시 중단되었습니다. 연결을 확인한 뒤 다시 시도해 주세요.
EN: The payment stream was interrupted. Please check your connection and try again.

[iap.iap_purchase_controller.body.3]
KO: 결제 창을 열 수 없습니다.
EN: Unable to open the payment window.

[iap.iap_purchase_controller.body.4]
KO: 결제를 시작하지 못했습니다. 네트워크 상태를 확인해 주세요.
EN: Could not initiate payment. Please check your network connection.

[iap.iap_purchase_controller.body.5]
KO: 구매 복원에 실패했습니다. 잠시 후 다시 시도해 주세요.
EN: Failed to restore purchases. Please try again in a moment.

[iap.iap_purchase_controller.body.6]
KO: 상품(${product.productId})을 찾지 못했습니다. Play Console 등록을 확인해 주세요.
EN: Product (${product.productId}) not found. Please check registration in Play Console.

[iap.iap_purchase_controller.body.7]
KO: 결제가 진행 중입니다. Google Play 승인을 기다려 주세요.
EN: Payment is in progress. Please wait for Google Play approval.

[iap.iap_purchase_controller.body.8]
KO: 결제가 실패했습니다.
EN: Payment failed.

[iap.iap_purchase_controller.body.9]
KO: 결제가 취소되었습니다.
EN: Payment was cancelled.

[iap.payment_auth.body]
KO: 본인 확인이 취소됐어요. 결제는 진행되지 않았어요.
EN: Identity verification was canceled. The payment was not processed.

[iap.payment_auth.body.2]
KO: 확인을 여러 번 틀려 잠시 막혔어요. 잠시 뒤 다시 하거나 화면 잠금(PIN, 패턴)으로 확인해 주세요. 결제는 진행되지 않았어요.
EN: Too many incorrect attempts, temporarily locked. Please try again in a moment or verify with your screen lock (PIN, pattern). The payment was not processed.

[iap.payment_auth.body.3]
KO: 결제 전 본인 확인을 하려면 폰에 화면 잠금(지문, PIN, 패턴)이 필요해요. 기기 설정에서 화면 잠금을 켠 뒤 다시 시도해 주세요.
EN: To verify your identity before payment, a screen lock (fingerprint, PIN, pattern) is required on your phone. Please turn on screen lock in device settings and try again.

[iap.payment_auth.body.4]
KO: 본인 확인을 할 수 없어요. 잠시 뒤 다시 시도해 주세요. 결제는 진행되지 않았어요.
EN: Unable to verify your identity. Please try again in a moment. The payment was not processed.

[iap.payment_auth.body.5]
KO: 결제를 진행하려면 본인 확인이 필요해요.
EN: Identity verification is required to proceed with payment.

[iap.purchases_closed.body]
KO: 안내
EN: Notice

[iap.purchases_closed.title]
KO: 이 버전에서는 앱 안 결제를 받지 않아요.
EN: In-app purchases are not available in this version.

[in_app_billing.body]
KO: DIA · SHARE로 교환
EN: Exchange with DIA · SHARE

[in_app_billing.body.2]
KO: Play 상품 준비 중 · 결제해도 DIA가 지급되지 않습니다
EN: Play products in preparation · DIA will not be awarded upon payment

[in_challenge.body]
KO: 센서 준비 중...
EN: Preparing sensors...

[in_challenge.body.2]
KO: Jena 검증 중...
EN: Jena verifying...

[in_challenge.body.3]
KO: 제출 기회: ${widget.submissionsRemaining}/${widget.maxSubmissions}회 남음
EN: Submissions left: ${widget.submissionsRemaining}/${widget.maxSubmissions}

[in_challenge.body.4]
KO: 센서 시작 실패: $e
EN: Sensor start failed: $e

[in_challenge.body.5]
KO: 심박수
EN: Heart Rate

[in_challenge.body.6]
KO: 위치 권한이 필요합니다.
EN: Location permission is required.

[in_challenge.body.7]
KO: Google Maps API 키가 설정되지 않았습니다.
EN: Google Maps API key is not configured.

[in_challenge.body.8]
KO: 러닝 데이터를 검증 중입니다...
EN: Verifying running data...

[in_challenge.button]
KO: 강제 정지 대신 소명 기회가 부여되었습니다. 증빙 자료를 제출해 주세요.
EN: An opportunity to explain was granted instead of suspension. Please submit evidence.

[in_challenge.button.2]
KO: 소명하러 가기
EN: Submit Appeal

[in_challenge.button.3]
KO: 시스템 설정 열기
EN: Open System Settings

[in_challenge.dialog]
KO: 기록 검증 보류
EN: Record Verification On Hold

[in_challenge.toast]
KO: Jena 검증 실패: ${ApiErrorMessage.from(error)}
EN: Jena verification failed: ${ApiErrorMessage.from(error)}

[app.itemInventoryBoostRunQuantityNote]
KO: 하루 1회 · 15분간 줍는 SHARE 2배 · 추가분 +240
EN: Once daily · 2x SHARE collected for 15 min · Extra +240

[app.itemInventoryCoachOnePointHint]
KO: 러닝을 시작하면 사용됩니다. 하루 1회.
EN: Used when starting a run. Once daily.

[app.itemInventoryCprQuantity]
KO: 보유량: 3/3
EN: Owned: 3/3

[app.itemInventoryCrewCheerHint]
KO: 하루 1회. 대회 SHARE 보상만 10% 늘어납니다.
EN: Once daily. Only contest SHARE rewards increase by 10%.

[app.itemInventoryDonationMatchNote]
KO: 100 VALUE. 운영자 명의 1,000원이 러닝 기부 풀에 더해지고 내 이름이 함께 표시됩니다. 영수증은 없습니다.
EN: 100 VALUE. 1,000 KRW under the operator's name is added to the running donation pool, and your name is displayed with it. Receipts are not provided.

[app.itemInventoryDonationMatchUse]
KO: 매칭하기
EN: Match

[app.itemInventoryExtraEntryHint]
KO: 모집 마감·정원 초과 참가 시 사용됩니다. 하루 2회.
EN: Used when joining after registration closes or capacity is full. Twice daily.

[app.itemInventoryFriendGhostHint]
KO: 러닝 중 친구 기록과 비교합니다. 내 최고 기록은 무료입니다.
EN: Compare with a friend's record while running. Your personal best is free.

[app.itemInventoryRestDayNote]
KO: 매주 1회 무료. 추가 보유분만 VALUE로 샀습니다. 휴식일은 출석으로 세지 않고 스트릭도 끊지 않습니다.
EN: Free once weekly. Only additional items were bought with VALUE. Rest days do not count as attendance and do not break streaks.

[app.itemInventoryRestDayToday]
KO: 오늘 휴식
EN: Rest Today

[app.itemInventoryRestDayYesterday]
KO: 어제 휴식
EN: Rest Yesterday

[app.itemInventorySafeGuardQuantity]
KO: 보유량: 1/1
EN: Owned: 1/1

[app.itemInventoryTitle]
KO: 내 아이템 보관함
EN: My Item Inventory

[app.itemInventoryUse]
KO: 사용하기
EN: Use

[item_inventory.body]
KO: 보유량: ${shop.cprCount}
EN: Owned: ${shop.cprCount}

[item_inventory.body.2]
KO: 보유량: ${shop.safeGuardCount}
EN: Owned: ${shop.safeGuardCount}

[item_inventory.body.3]
KO: 보유량: ${shop.coachOnePointCount}
EN: Owned: ${shop.coachOnePointCount}

[item_inventory.body.4]
KO: 보유량: ${shop.extraEntryCount}
EN: Owned: ${shop.extraEntryCount}

[item_inventory.body.5]
KO: 보유량: ${shop.friendGhostCount}
EN: Owned: ${shop.friendGhostCount}

[item_inventory.body.6]
KO: 보유량: ${shop.crewCheerCount}
EN: Owned: ${shop.crewCheerCount}

[item_inventory.body.7]
KO: 보유량: ${shop.boostRunCount}
${AppStrings.itemInventoryBoostRunQuantityNote}
EN: Owned: ${shop.boostRunCount}
${AppStrings.itemInventoryBoostRunQuantityNote}

[item_inventory.body.8]
KO: 보유량: ${shop.stepIncubatorCount}
${AppStrings.itemInventoryStepIncubatorQuantityNote}
EN: Owned: ${shop.stepIncubatorCount}
${AppStrings.itemInventoryStepIncubatorQuantityNote}

[item_inventory.body.9]
KO: 추가 보유: ${shop.restDayCount}
${AppStrings.itemInventoryRestDayNote}
EN: Extra owned: ${shop.restDayCount}
${AppStrings.itemInventoryRestDayNote}

[item_inventory.toast]
KO: 이미 처리된 매칭입니다. VALUE는 한 번만 차감됩니다.
EN: Match already processed. VALUE will only be deducted once.
