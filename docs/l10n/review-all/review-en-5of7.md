# 번역 검수 요청 — 쉐어런 (English) · 파트 5/7

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
[pedometer.walking_challenge_share.promo_line1]
KO: 쉐어런 워킹챌린지에서 함께 걷고 SHARE를 모아보세요!
EN: Walk together and collect SHARE in the ShareRun Walking Challenge!

[pedometer.walking_challenge_share.promo_line2]
KO: 걸을수록 쌓이는 SHARE, 친구와 같이 시작해요.
EN: The more you walk, the more SHARE you earn. Start with a friend!

[pedometer.walking_look.body]
KO: $pendingCoinsInt SHARE 줍기
EN: Collect $pendingCoinsInt SHARE

[pedometer.walking_look.body.2]
KO: 코인 쌓이는 중...
EN: Accumulating coins...

[app.avatarCustomizeHint]
KO: 캐릭터를 고르거나 갤러리 사진을 쓰면 바로 저장됩니다
EN: Select a character or use a photo from your gallery to save immediately

[app.avatarCustomizeTitle]
KO: 아바타 커스터마이징
EN: Avatar Customization

[app.avatarGalleryDenied]
KO: 사진 접근 권한이 필요합니다. 설정에서 허용해 주세요.
EN: Photo access permission is required. Please allow it in Settings.

[app.avatarGalleryFailed]
KO: 사진을 불러오지 못했습니다. 다시 시도해 주세요.
EN: Failed to load the photo. Please try again.

[app.avatarPickGallery]
KO: 갤러리에서 사진 선택
EN: Select Photo from Gallery

[app.myPageAngelSponsor]
KO: 천사 후원
EN: Angel Sponsorship

[app.personalSponsorBadgeHint]
KO: 후원 시 프로필에 천사 뱃지가 영구 노출됩니다
EN: When you sponsor, an Angel badge will be permanently displayed on your profile

[app.personalSponsorCelebrateHall]
KO: 명예의 전당 보기
EN: View Hall of Fame

[app.personalSponsorCelebrateTitle]
KO: 천사 후원 완료!
EN: Angel Sponsorship Complete!

[app.personalSponsorCta]
KO: 50,000 SHARE 후원하고 천사 되기
EN: Sponsor 50,000 SHARE and Become an Angel

[app.personalSponsorDonationDesc]
KO: 후원은 운영자 이름으로 기부돼요. 내 기여는 앱에서 확인할 수 있어요.
EN: Sponsorships are donated under the operator's name. You can check your contribution in the app.

[app.personalSponsorDonationTitle]
KO: [기부 후원]
EN: [Donation Sponsorship]

[app.personalSponsorMonthlyToggle]
KO: 월간 'SHARE 멤버십'으로 매월 정기 후원하기
EN: Sponsor regularly every month with a monthly 'SHARE Membership'

[app.personalSponsorPrizeDesc]
KO: 후원금이 1등 러너에게 순수 상금 보너스로 직접 지급됩니다.
EN: Sponsorship funds are paid directly to the 1st place runner as a pure prize bonus.

[app.personalSponsorPrizeTitle]
KO: [순수 상금 지원]
EN: [Direct Prize Support]

[app.personalSponsorPurposeLabel]
KO: 후원금의 사용 목적을 직접 선택해 주세요.
EN: Please select the purpose of your sponsorship directly.

[app.personalSponsorTitle]
KO: 러너 후원하기 (스폰서십)
EN: Sponsor a Runner (Sponsorship)

[personal_sponsor.body]
KO: SHARE가 부족합니다.
EN: Insufficient SHARE.

[personal_sponsor.body.10]
KO: 아직 후원한 분이 없어요.
EN: No sponsors yet.

[personal_sponsor.body.11]
KO: 이번 달 ${won(summary.monthWon ?? 0)}원 · 누적 ${won(summary.totalWon ?? 0)}원 · 참여 ${summary.sponsorCount}명
EN: This month: ${won(summary.monthWon ?? 0)} KRW · Total: ${won(summary.totalWon ?? 0)} KRW · ${summary.sponsorCount} participant(s)

[personal_sponsor.body.12]
KO: 참여 ${summary.sponsorCount}명 · 금액은 ${summary.minSponsors}명 이상 모이면 보여 드려요.
EN: ${summary.sponsorCount} participant(s) · Amount will be revealed once at least ${summary.minSponsors} people join.

[personal_sponsor.body.13]
KO: 후원 현황
EN: Sponsorship Status

[personal_sponsor.body.14]
KO: 이 내역은 나만 볼 수 있어요.
EN: Only you can see this history.

[personal_sponsor.body.15]
KO: 서버에 연결되면 볼 수 있어요.
EN: Available when connected to the server.

[personal_sponsor.body.16]
KO: 아직 후원한 내역이 없어요.
EN: No sponsorship history yet.

[personal_sponsor.body.17]
KO: 기부 후원 ${mine.donationCount}번 · ${SponsorshipStatusCard.won(mine.donationWon)}원
EN: Donation Sponsorships: ${mine.donationCount} time(s) · ${SponsorshipStatusCard.won(mine.donationWon)} KRW

[personal_sponsor.body.18]
KO: 기부 후원
EN: Donation Sponsorship

[personal_sponsor.body.19]
KO: 상금 후원
EN: Prize Sponsorship

[personal_sponsor.body.2]
KO: 후원에 실패했습니다. 잠시 후 다시 시도해 주세요.
EN: Sponsorship failed. Please try again in a moment.

[personal_sponsor.body.20]
KO: ${SponsorshipStatusCard.won(e.share)} SHARE
${SponsorshipStatusCard.won(e.won)}원
EN: ${SponsorshipStatusCard.won(e.share)} SHARE
${SponsorshipStatusCard.won(e.won)} KRW

[personal_sponsor.body.3]
KO: 날개 배지가 프로필에 장착되었습니다. 명예의 전당에서 천사 후원자를 확인할 수 있어요.
EN: Wing badge equipped to your profile. You can check Angel Sponsors in the Hall of Fame.

[personal_sponsor.body.4]
KO: 후원이 등록되었습니다. 명예의 전당에서 천사 후원 기록을 확인할 수 있어요.
EN: Sponsorship registered. You can check Angel Sponsorship records in the Hall of Fame.

[personal_sponsor.body.5]
KO: 러너
EN: Runner

[personal_sponsor.body.6]
KO: 최고 천사 등급입니다
EN: Highest Angel Tier

[personal_sponsor.body.7]
KO: 다음 [${next.koreanName}] 등급까지 후원 $remainCount회 남음!
EN: $remainCount more sponsorship(s) until next [${next.koreanName}] tier!

[personal_sponsor.body.8]
KO: 다음 [${next.koreanName}] 등급까지 후원 $remainCount회(또는 ${AngelTierX.formatWon(remainWon)}) 남음!
EN: $remainCount sponsorship(s) (or ${AngelTierX.formatWon(remainWon)}) left until next [${next.koreanName}] tier!

[personal_sponsor.body.9]
KO: 후원은 운영자 이름으로 기부돼요. 운영자는 전달만 해요.
EN: Sponsorships are donated under the operator's name. The operator acts solely as a relay.

[personal_sponsor.button]
KO: 내 후원 내역
EN: My Sponsorship History

[privacy.ai_learning_tile.body]
KO: AI 개선에 내 데이터 사용
EN: Use my data to improve AI

[privacy.ai_learning_tile.body.2]
KO: 기본은 꺼짐이에요. 켜고 끈 기록은 서버에 남고, 어느 폰에서나 같게 보여요.
EN: Default is off. Your toggle history is saved on the server and synced across all your phones.

[privacy.ai_learning_tile.toast]
KO: 저장하지 못했어요. 잠시 후 다시 시도해 주세요.
EN: Couldn't save. Please try again in a moment.

[privacy.payment_auth_tile.body]
KO: 결제 전 본인 확인을 끄려면 본인 확인이 필요해요.
EN: Identity verification is required to turn off verification before payment.

[privacy.payment_auth_tile.body.2]
KO: 설정을 바꾸지 못했어요. 잠시 후 다시 시도해 주세요.
EN: Failed to change settings. Please try again in a moment.

[privacy.payment_auth_tile.body.3]
KO: 다이아 구매와 Coach+ 결제창을 열기 전에 지문이나 화면 잠금으로 확인해요. 결제 승인은 구글 플레이가 하고, 이 확인은 한 번 더 걸러 주는 단계예요.
EN: Verify with fingerprint or screen lock before opening the DIA purchase and Coach+ checkout screens. Google Play approves payments, and this check is an extra layer of protection.

[privacy.payment_auth_tile.toast]
KO: 결제 전 본인 확인
EN: Identity verification before payment

[app.proToolsCushionWarning]
KO: 쿠션 수명이 80km 남았습니다.
부상 방지를 위해 교체 시기가 다가옵니다.
EN: 80 km of cushion life remaining.
Replacement time is approaching to prevent injury.

[app.proToolsMenuAiReport]
KO: AI 심층 러닝 리포트 (구간별 페이스 분석)
EN: In-Depth AI Running Report (Split Pace Analysis)

[app.proToolsMenuCrewRanking]
KO: 소속 크루(Crew) 출석률 랭킹 보드
EN: Affiliated Crew Attendance Ranking Board

[app.proToolsMenuPaceCalc]
KO: 목표 거리에 따른 페이스 계산기 (VDOT)
EN: Target Distance Pace Calculator (VDOT)

[app.proToolsRegisteredShoe]
KO: 등록된 러닝화: 나이키 베이퍼플라이 3
EN: Registered Running Shoes: Nike Vaporfly 3

[app.proToolsSubtitle]
KO: 장비의 수명을 관리하고 AI 리포트로 성장하세요.
EN: Manage equipment lifespan and grow with AI reports.

[app.proToolsTitle]
KO: 러닝 기어 & 프로 툴
EN: Running Gear & Pro Tools

[profile.activity_list.body]
KO: 러닝 로그
EN: Running Log

[profile.activity_list.body.2]
KO: 최근 러닝 기록이 없습니다
EN: No recent running records

[profile.activity_list.body.3]
KO: 기록
EN: Record

[profile.activity_list.body.4]
KO: 걷기
EN: Walking

[profile.activity_list.body.5]
KO: ⚠️ 기록 보류 - 소명하기 〉
EN: ⚠️ Record on hold - Submit appeal 〉

[profile.angel_tier_widgets.body]
KO: 나의 천사 연대기
EN: My Angel Chronicles

[profile.angel_tier_widgets.body.10]
KO: 6익 천사 · 영롱한 광배가 당신을 비춥니다
EN: 6-winged angel · A luminous halo shines upon you

[profile.angel_tier_widgets.body.11]
KO: 누적 100회 또는 5,000,000 SHARE 후원 시 이 자리에 오릅니다
EN: Reach this tier with 100 cumulative donations or sponsoring 5,000,000 SHARE

[profile.angel_tier_widgets.body.12]
KO: 등록된 날개가 없습니다. 단 1회 후원으로 귀여운 진짜 아기 날개를 등 뒤에 달아보세요!
EN: No wings registered. Equip real cute baby wings on your back with just 1 donation!

[profile.angel_tier_widgets.body.13]
KO: 지금 후원하고 아기 날개 달기
EN: Donate now and equip baby wings

[profile.angel_tier_widgets.body.2]
KO: 후원 $count회 · ${AngelTierX.formatWon(amount)}
EN: $count donations · ${AngelTierX.formatWon(amount)}

[profile.angel_tier_widgets.body.3]
KO: 아직 등 뒤에 장착된 진짜 날개가 없습니다. 단 1회 기부로 귀여운 아기 날개를 달아보세요!
EN: You don't have real wings on your back yet. Equip cute baby wings with just 1 donation!

[profile.angel_tier_widgets.body.4]
KO: 첫 날개 달기 👼 〉
EN: Get First Wings 👼 〉

[profile.angel_tier_widgets.body.5]
KO: 후원하고 천사 등급 올리기 〉
EN: Donate and Upgrade Angel Tier 〉

[profile.angel_tier_widgets.body.6]
KO: ❤️  내 이름으로 달리기 후원하기
EN: ❤️  Sponsor Running in My Name

[profile.angel_tier_widgets.body.7]
KO: 이번 달 명예 후원자
EN: Honorary Sponsor of the Month

[profile.angel_tier_widgets.body.8]
KO: 세라핌 VVIP 명예 전광판
EN: Seraphim VVIP Honor Board

[profile.angel_tier_widgets.body.9]
KO: 이번 달 최고 누적 기부 · 세라핌
EN: Top cumulative donation this month · Seraphim

[profile.avatar_choice.body]
KO: 남성
EN: Male

[profile.gender_profile_avatar.body]
KO: 닉네임을 설정해 주세요
EN: Please set your nickname

[profile.invite_copy.body]
KO: 내 초대 코드
EN: My Invite Code

[profile.invite_copy.body.2]
KO: 복사
EN: Copy

[profile.invite_copy.body.3]
KO: 복사했어요
EN: Copied

[profile.invite_copy.body.4]
KO: 초대 코드를 불러오지 못했어요. 다시 시도
EN: Couldn't load invite code. Try again

[profile.invite_copy.body.5]
KO: 카카오톡으로 초대하기
EN: Invite via KakaoTalk

[profile.invite_copy.body.6]
KO: 쉐어런 초대
EN: ShareRun Invite

[profile.invite_copy.body.7]
KO: 쉐어런에 초대해요!
EN: You're invited to ShareRun!

[profile.invite_copy.body.8]
KO: 초대 코드
EN: Invite Code

[profile.my_dashboard_sections.body]
KO: 프로필 꾸미기
EN: Customize Profile

[profile.my_page_referral_code_entry.body]
KO: ${AppStrings.referralRedeemDone} · $runs/${EconomyConstants.referralTrialRunsRequired} 런 · 1.1km 이상 달리면 안전해요
EN: ${AppStrings.referralRedeemDone} · $runs/${EconomyConstants.referralTrialRunsRequired} runs · Running 1.1km or more is safe

[profile.my_village_hero.button]
KO: 마을 바꾸기
EN: Change Village

[profile.my_watch.body]
KO: 스마트워치 연결됨
EN: Smartwatch connected

[profile.my_watch.body.2]
KO: 걸음·심박을 받고, 시계 앱으로도 기록해요
EN: Receive steps and heart rate, and also record with the watch app

[profile.my_watch.body.3]
KO: 걸음·심박을 휴대폰으로 받아요
EN: Receive steps and heart rate on your phone

[profile.my_watch.body.4]
KO: 시계 앱 연결됨
EN: Watch app connected

[profile.my_watch.body.5]
KO: $appName 연결됨
EN: $appName connected

[profile.my_watch.body.6]
KO: 시계에서 바로 기록해요
EN: Record directly from your watch

[profile.my_watch.body.7]
KO: 내 워치
EN: My Watch

[profile.my_watch.body.8]
KO: 워치로 더 정확하게 달리기
EN: Run more accurately with your watch

[profile.my_watch.body.9]
KO: 걸음·심박을 시계에서 바로 기록해요
EN: Record steps and heart rate directly on your watch

[profile.my_watch.button]
KO: 관리
EN: Manage

[profile.retention_widgets.body]
KO: 오늘 모은 땀방울 ${km.toStringAsFixed(1)}km / ${cap.toStringAsFixed(1)}km ($percent%)
EN: Sweat gathered today: ${km.toStringAsFixed(1)}km / ${cap.toStringAsFixed(1)}km ($percent%)

[profile.retention_widgets.body.10]
KO: 걷기 챌린지 보기
EN: View Walking Challenge

[profile.retention_widgets.body.11]
KO: 🔥 $streak일째 불꽃 유지 중!
EN: 🔥 Keeping the flame alive for $streak days!

[profile.retention_widgets.body.12]
KO: 7일 연속 실천 완료 시 10 다이아몬드(DIA) 보너스 획득! 💎
EN: Complete 7 consecutive days to earn a 10 Diamond (DIA) bonus! 💎

[profile.retention_widgets.body.2]
KO: 오늘 걸음
EN: Today's Steps

[profile.retention_widgets.body.3]
KO: ${groupedNumber(numbers.steps)} 걸음
EN: ${groupedNumber(numbers.steps)} steps

[profile.retention_widgets.body.4]
KO: 다른 폰에서 이미 SHARE가 반영됐어요
EN: SHARE has already been applied from another phone

[profile.retention_widgets.body.5]
KO: 100걸음 → 10 SHARE · 하루 최대 600
EN: 100 steps → 10 SHARE · Max 600 per day

[profile.retention_widgets.body.6]
KO: 오늘 거리 ${km.toStringAsFixed(1)} km
EN: Today's distance ${km.toStringAsFixed(1)} km

[profile.retention_widgets.body.7]
KO: 받은 SHARE ${numbers.receivedShare}
EN: Received SHARE ${numbers.receivedShare}

[profile.retention_widgets.body.8]
KO: 줍기 대기 ${numbers.pendingShare}
EN: Pending collection ${numbers.pendingShare}

[profile.retention_widgets.body.9]
KO: ${numbers.pendingShare} SHARE 줍기
EN: Collect ${numbers.pendingShare} SHARE

[profile.tier_circle_badge.body]
KO: 예비 천사
EN: Prospective Angel

[profile.village_scene.body]
KO: 기본 마을
EN: Default Village

[profile.village_scene.body.10]
KO: 마을 ${++extra}
EN: Village ${++extra}

[profile.village_scene.body.11]
KO: 마을 고르기
EN: Choose Village

[profile.village_scene.body.12]
KO: 마이 화면 맨 위 배경이 바뀌어요.
EN: The top background of your My Page will change.

[profile.village_scene.body.13]
KO: 아직 고를 수 있는 마을이 기본 하나뿐이에요.
EN: Only the default village is available right now.

[profile.village_scene.body.2]
KO: 봄 공원
EN: Spring Park

[profile.village_scene.body.3]
KO: 바닷가
EN: Seaside

[profile.village_scene.body.4]
KO: 밤 도시
EN: Night City

[profile.village_scene.body.5]
KO: 눈 마을
EN: Snow Village

[profile.village_scene.body.6]
KO: 가을 숲
EN: Autumn Forest

[profile.village_scene.body.7]
KO: 축제의 밤
EN: Festival Night

[profile.village_scene.body.8]
KO: 오로라 호수
EN: Aurora Lake

[profile.village_scene.body.9]
KO: 하늘섬
EN: Sky Island

[app.noCashPrizePool]
KO: 현금 상금 없음
EN: No Cash Prize Pool

[app.refundCancelCta]
KO: 수수료 없이 결제 취소하기 (현금 환불)
EN: Cancel payment without fees (Cash refund)

[app.refundGuaranteeTitle]
KO: 안전 환불 보장
EN: Safe Refund Guarantee

[app.refundPaymentDate]
KO: 결제일: 2026.06.25
EN: Payment Date: 2026.06.25

[app.refundPolicy1]
KO: - 전자상거래법에 의거, 결제 후 7일 이내 미사용 재화는 수수료 없이 100% 현금 환불됩니다.
EN: - According to Electronic Commerce Law, unused goods are 100% refunded in cash without fees within 7 days of payment.

[app.refundPolicy2]
KO: - 최소 인원이 모이지 않으면 참가비가 전액 돌아옵니다.
EN: - If the minimum number of participants is not reached, the entry fee will be fully refunded.

[app.refundTargetItem]
KO: [ 50,000 SHARE (미사용) ]
EN: [ 50,000 SHARE (Unused) ]

[app.refundTitle]
KO: 결제 취소 및 환불
EN: Payment Cancellation & Refund

[app.refundTotalAmount]
KO: 총 환불 예정 금액: 50,000 KRW
EN: Total Estimated Refund: 50,000 KRW

[reminder_schedule.body]
KO: 워킹챌린지 참여 독려
EN: Walking Challenge Participation Reminder

[reminder_schedule.body.2]
KO: 워킹챌린지 아침·점심·저녁 참여 독려
EN: Walking Challenge Morning, Lunch, and Evening Reminders

[reminder_schedule.body.3]
KO: 🏃 활기찬 아침, 오늘의 첫걸음을 시작해 보세요!
EN: 🏃 Start your energetic morning with your first steps of the day!

[reminder_schedule.body.4]
KO: 오늘 하루 걷는 모든 발걸음이 소중한 SHARE가 됩니다.
EN: Every step you take today becomes valuable SHARE.

[reminder_schedule.body.5]
KO: ☕ 가벼운 산책으로 활력을 충전해 볼까요?
EN: ☕ How about recharging your energy with a light walk?

[reminder_schedule.body.6]
KO: 잠깐의 가벼운 걸음이 오늘의 챌린지 목표를 완성합니다.
EN: A short, light walk completes today's challenge goal.

[reminder_schedule.body.7]
KO: 🎁 오늘 획득할 수 있는 SHARE가 남아있어요!
EN: 🎁 You still have SHARE left to earn today!

[reminder_schedule.body.8]
KO: 오늘의 걸음을 인증하고 준비된 보상을 놓치지 마세요.
EN: Verify today's steps and don't miss out on your rewards.

[report.body]
KO: 욕설·불쾌한 이름
EN: Profanity / Offensive name

[report.body.2]
KO: 선정적인 이름
EN: Sexually suggestive name

[report.body.3]
KO: 혐오·차별 표현
EN: Hate speech or discrimination

[report.body.4]
KO: 광고·도배
EN: Spam or advertising

[report.button]
KO: 운영자가 확인한 뒤 조치합니다. 신고한 사람은 상대에게 알려지지 않아요.
EN: An administrator will review and take action. Your report is anonymous.

[report.dialog]
KO: 기타
EN: Other

[report.dialog.2]
KO: "$targetName" 신고
EN: Report "$targetName"

[reward.winner_honor_popup.body]
KO: 챌린지 우승!
EN: Challenge Winner!

[reward.winner_honor_popup.body.2]
KO: 당신의 땀방울이 세상을 바꿉니다.
EN: Your drops of sweat change the world.

[reward.winner_honor_popup.button]
KO: 우승 상금 100% 전액 기부하기
EN: Donate 100% of Prize Money

[reward.winner_reward.body]
KO: 축하합니다! 검증된 러닝으로 우승 상금을 획득했습니다.
EN: Congratulations! You earned the prize money with verified running.

[reward.winner_reward.button]
KO: 우승 상금 수령하기
EN: Claim Prize Money

[reward.winner_reward.button.2]
KO: 우승 상금 50% 기부하기
EN: Donate 50% of Prize

[reward.winner_reward.button.3]
KO: 100% 전액 기부하기
EN: Donate 100% of Total

[reward.winner_reward.dialog]
KO: 우승 임팩트
EN: Winner Impact

[run.run_tracker_provider.body]
KO: 달리기를 시작할 수 없습니다. 위치 서비스를 확인해 주세요.
EN: Unable to start run. Please check location services.

[app.runResultAvgPaceLabel]
KO: 평균 페이스:
EN: Average Pace:

[app.runResultDonate]
KO: ❤️ 이번 달리기 기부 기여 보기
EN: ❤️ See my donation contribution for this run

[app.runResultFinalTimeLabel]
KO: 최종 시간:
EN: Final Time:

[app.runResultShare]
KO: 🔗 기록 SNS 공유하기
EN: 🔗 Share record on social media

[app.runResultTitle]
KO: 축하합니다!
완주 성공 🎉
EN: Congratulations!
Run Completed 🎉

[app.runResultUnconfirmed]
KO: 서버에서 확인된 기록이 없습니다.
EN: No record has been confirmed by the server.

[app.runResultValueReward]
KO: 서버 확인 노력 보상 +$tokens VALUE
EN: Server-verified effort reward +$tokens VALUE

[run_result.body]
KO: 판정: ${result.decision.name}
EN: Decision: ${result.decision.name}

[run_result.body.2]
KO: VALUE 보상: ${result.valueTokenReward}
EN: VALUE Reward: ${result.valueTokenReward}

[run_result.body.3]
KO: 로그인이 필요합니다.
EN: Login is required.

[run_result.body.4]
KO: 우승 보상 처리가 완료되었습니다.
EN: Victory reward processing is complete.

[run_result.body.5]
KO: 우승 보상 처리 실패: ${ApiErrorMessage.from(error)}
EN: Failed to process victory reward: ${ApiErrorMessage.from(error)}

[run_result.button]
KO: 보상을 처리하는 중...
EN: Processing reward...

[run_result.button.2]
KO: 우승 상금 선택하기
EN: Select Prize

[run_result.button.3]
KO: 홈으로 돌아가기
EN: Back to Home

[run_result.title]
KO: 검증된 러닝
EN: Verified Run

[run_result.title.2]
KO: 인정되지 않은 기록
EN: Unrecognized Record

[run_result.title.3]
KO: 검증되지 않은 기록
EN: Unverified Record

[run_result.title.4]
KO: 러닝 결과
EN: Run Results

[run_result.run_finish_image_share.body]
KO: 공유 이미지를 만들지 못했어요.
EN: Couldn't create the share image.

[run_result.run_finish_image_share.body.2]
KO: Instagram 스토리로 공유하지 못했어요.
EN: Couldn't share to Instagram Stories.

[run_result.run_finish_image_share.body.3]
KO: 쉐어런 완주
EN: ShareRun Completed

[run_result.run_finish_share.body]
KO: 다크
EN: Dark

[run_result.run_finish_share.body.10]
KO: 목요일
EN: Thursday

[run_result.run_finish_share.body.11]
KO: 금요일
EN: Friday

[run_result.run_finish_share.body.12]
KO: 토요일
EN: Saturday

[run_result.run_finish_share.body.13]
KO: 일요일
EN: Sunday

[run_result.run_finish_share.body.14]
KO: ${date.month}월 ${date.day}일 ${weekdays[date.weekday - 1]}
EN: ${weekdays[date.weekday - 1]}, ${date.month}/${date.day}

[run_result.run_finish_share.body.15]
KO: 이번 달리기로 운영자가 ${_grouped(won)}원을 기부할 예정이에요
EN: With this run, the operator plans to donate ${_grouped(won)} KRW

[run_result.run_finish_share.body.16]
KO: 오늘은 기부 인정 10km를 모두 채웠어요. 넘는 거리는 기록으로 남아요.
EN: You've reached the 10km donation limit for today. Any distance beyond this is still saved as your record.

[run_result.run_finish_share.body.17]
KO: 기부 참여 기록
EN: Donation Participation Record

[run_result.run_finish_share.body.18]
KO: 이번 달리기는 기부에 포함되지 않았어요.
EN: This run was not included in the donation.

[run_result.run_finish_share.body.19]
KO: 쉐어런 앱에서 ${distanceKm}km를 달렸어요. ⏱ 기록: $time
EN: I ran ${distanceKm}km on the ShareRun app. ⏱ Time: $time

[run_result.run_finish_share.body.2]
KO: 블루
EN: Blue

[run_result.run_finish_share.body.20]
KO: 오늘의 러닝
EN: Today's Run

[run_result.run_finish_share.body.21]
KO: 평균 심박 $averageHeartRate bpm
EN: Avg Heart Rate $averageHeartRate bpm

[run_result.run_finish_share.body.22]
KO: 구간 페이스
EN: Split Pace

[run_result.run_finish_share.body.23]
KO: 시간
EN: Time

[run_result.run_finish_share.body.24]
KO: 페이스
EN: Pace

[run_result.run_finish_share.body.3]
KO: 핑크
EN: Pink

[run_result.run_finish_share.body.4]
KO: 옐로
EN: Yellow

[run_result.run_finish_share.body.5]
KO: 민트
EN: Mint

[run_result.run_finish_share.body.6]
KO: 내 사진
EN: My Photo

[run_result.run_finish_share.body.7]
KO: 월요일
EN: Monday

[run_result.run_finish_share.body.8]
KO: 화요일
EN: Tuesday

[run_result.run_finish_share.body.9]
KO: 수요일
EN: Wednesday

[run_result.run_finish_share_flow.body]
KO: 하나만 올리기
EN: Post single item

[run_result.run_finish_share_flow.body.2]
KO: 여러 개 순서대로 올리기
EN: Post multiple in order

[run_result.run_finish_share_flow.body.3]
KO: 순서대로 공유
EN: Share in order

[run_result.run_finish_share_flow.body.4]
KO: 그만하기
EN: Stop

[run_result.run_finish_share_flow.body.5]
KO: 어떻게 올릴까요?
EN: How would you like to post?

[run_result.run_finish_share_flow.body.6]
KO: 어디에 올릴까요?
EN: Where would you like to post?

[run_result.run_finish_share_flow.body.7]
KO: 순서대로 올리기
EN: Post in order

[run_result.run_finish_share_flow.body.8]
KO: 다음: $label
EN: Next: $label

[run_result.run_finish_share_targets.body]
KO: Instagram 스토리
EN: Instagram Stories

[run_result.run_finish_share_targets.body.2]
KO: Instagram 피드
EN: Instagram Feed

[run_result.run_finish_share_targets.body.3]
KO: 더보기
EN: More

[run_tracking.body]
KO: 심박 ${telemetry.currentHeartRate?.toString() ??
EN: Heart rate ${telemetry.currentHeartRate?.toString() ??

[run_tracking.body.2]
KO: } BPM / 케이던스 ${telemetry.currentCadenceSpm?.toString() ??
EN: } BPM / Cadence ${telemetry.currentCadenceSpm?.toString() ??

[run_tracking.body.3]
KO: 자이로 안정도 ${telemetry.gyroStabilityScore.toStringAsFixed(2)}
EN: Gyro stability ${telemetry.gyroStabilityScore.toStringAsFixed(2)}

[run_tracking.body.4]
KO: 센서를 시작하는 중...
EN: Starting sensor...

[run_tracking.body.5]
KO: 러닝 검증 중...
EN: Verifying run...

[run_tracking.body.6]
KO: 러닝 끝내고 검증하기
EN: End Run and Verify

[run_tracking.body.7]
KO: MyPage에서 [선택] 민감정보 수집 동의 후 러닝 검증을 시작할 수 있습니다.
EN: You can start run verification after agreeing to [Optional] Sensitive Information Collection in MyPage.

[run_tracking.body.8]
KO: 센서를 시작하지 못했어요: $error
EN: Failed to start sensors: $error

[run_tracking.title]
KO: 달리기 기록
EN: Run Record

[run_tracking.toast]
KO: 러닝 검증에 실패했어요: ${ApiErrorMessage.from(error)}
EN: Run verification failed: ${ApiErrorMessage.from(error)}

[run_tracking.ble_heart_rate_service.body]
KO: BLE 심박 센서 (${map[
EN: BLE heart rate sensor (${map[

[run_tracking.ble_heart_rate_service.body.2]
KO: 이 기기에서는 블루투스 심박 스캔을 지원하지 않습니다.
EN: Bluetooth heart rate scanning is not supported on this device.

[run_tracking.ble_heart_rate_service.body.3]
KO: 블루투스 권한 또는 상태를 확인해 주세요.
EN: Please check Bluetooth permissions or status.

[run_tracking.ble_heart_rate_service.body.4]
KO: 이 기기에서는 블루투스 심박 연결을 지원하지 않습니다.
EN: Bluetooth heart rate connection is not supported on this device.

[run_tracking.ble_heart_rate_service.body.5]
KO: 센서 연결에 실패했습니다.
EN: Failed to connect to sensor.

[run_tracking.gps_tracking_service.body]
KO: 실시간 러닝 GPS 추적 중
EN: Real-time running GPS tracking in progress

[run_tracking.home_start_gate.body]
KO: 마이페이지에서 민감정보 수집에 동의해주세요
EN: Please consent to sensitive data collection in My Page.

[run_tracking.home_start_gate.body.2]
KO: 로그인 후 러닝 검증을 진행할 수 있습니다.
EN: You can proceed with run verification after logging in.

[run_tracking.home_start_gate.body.3]
KO: 러닝이 시작되지 않았습니다.
EN: Running has not started.

[run_tracking.music_controls.body]
KO: 음악을 조절하지 못했어요.
EN: Couldn't control music.

[run_tracking.music_controls.body.2]
KO: 재생 / 일시정지
EN: Play / Pause

[run_tracking.music_controls.body.3]
KO: 다음 곡
EN: Next track

[run_tracking.music_controls.body.4]
KO: 음악 앱 열기
EN: Open music app

[run_tracking.music_controls.body.5]
KO: 음악 앱을 찾지 못했어요. 쓰는 음악 앱을 직접 열어 주세요.
EN: Couldn't find a music app. Please open your music app directly.

[run_tracking.music_controls.button]
KO: 이전 곡
EN: Previous track

[run_tracking.run_recording_checklist.body]
KO: 화면을 끄거나 다른 앱을 켜도 경로 기록과 음성 코칭이 이어지도록 아래 항목을 확인해 주세요.
EN: Please check the items below so route recording and voice coaching continue even when the screen is off or another app is open.

[run_tracking.run_recording_checklist.body.10]
KO: 허용하지 않아도 달리기는 시작할 수 있습니다.
EN: You can start running even without allowing this.

[run_tracking.run_recording_checklist.body.11]
KO: 항목을 나중에 바꿔도 됩니다.
EN: You can change these settings later.

[run_tracking.run_recording_checklist.body.12]
KO: 필요
EN: Required

[run_tracking.run_recording_checklist.body.2]
KO: 위치 권한
EN: Location Permission

[run_tracking.run_recording_checklist.body.3]
KO: 앱을 사용하는 동안 허용해 주세요. 항상 허용은 요청하지 않습니다.
EN: Please allow while using the app. We do not request 'Allow all the time'.

[run_tracking.run_recording_checklist.body.4]
KO: 허용됨
EN: Allowed

[run_tracking.run_recording_checklist.body.5]
KO: 허용하기
EN: Allow

[run_tracking.run_recording_checklist.body.6]
KO: 알림 권한
EN: Notification permission

[run_tracking.run_recording_checklist.body.7]
KO: 달리기 기록 알림을 표시합니다. Android 13 이상에서 필요합니다.
EN: Displays run recording notifications. Required on Android 13 and above.

[run_tracking.run_recording_checklist.body.8]
KO: 배터리 최적화
EN: Battery optimization

[run_tracking.run_recording_checklist.body.9]
KO: 설정됨
EN: Configured

[run_tracking.run_recording_checklist.button]
KO: 확인하고 달리기
EN: Confirm and run

[run_tracking.run_recording_checklist.title]
KO: 달리기 기록 설정
EN: Run Tracking Settings

[run_tracking.run_recording_checklist.toast]
KO: 배터리 설정 화면을 열지 못했습니다.
EN: Failed to open battery settings.

[run_tracking.run_recording_foreground.body]
KO: 화면이 꺼져도 달리기 경로와 음성 코칭을 이어갑니다.
EN: Continues tracking your route and voice coaching even when the screen is off.

[run_tracking.run_recording_policy.body]
KO: 쉐어런 · 달리기 기록 중
EN: ShareRun · Recording run

[run_tracking.run_recording_policy.body.2]
KO: 이전 달리기가 중단되었습니다
EN: The previous run was interrupted

[run_tracking.run_recording_policy.body.3]
KO: 앱이 중간에 종료되어 직전 달리기는 저장되지 않았습니다. 보상은 지급되지 않고, 기록도 남지 않습니다.
EN: The app closed unexpectedly, so your previous run was not saved. Rewards are not granted, and no record is kept.

[run_tracking.run_recording_policy.body.4]
KO: 화면이 꺼지면 달리기 기록이 중단될 수 있습니다.
EN: Run recording may be interrupted when the screen turns off.

[run_tracking.run_recording_policy.body.5]
KO: 달리기 기록 설정 점검
EN: Check run recording settings

[run_tracking.run_recording_policy.body.6]
KO: 시스템 배터리 최적화 화면에서 쉐어런을 찾아 주세요. 삼성 갤럭시는 '제한 없음'으로 바꿔 주세요.
EN: Please find ShareRun in your system battery optimization settings. On Samsung Galaxy, change it to 'Unrestricted'.

[run_tracking.run_session_service.body]
KO: 위치 서비스가 꺼져 있습니다.
EN: Location services are turned off.

[run_tracking.run_session_service.body.2]
KO: 위치 권한이 영구 거부되었습니다. 설정에서 허용해 주세요.
EN: Location permission has been permanently denied. Please allow it in settings.

[run_tracking.run_session_service.body.3]
KO: 위치 권한이 허용되었습니다.
EN: Location permission granted.
