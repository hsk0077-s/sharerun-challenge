# 번역 검수 요청 — 쉐어런 (Thai) · 파트 5/7

아래는 한국어 앱 "쉐어런"(걷기·달리기 앱, 회사 자금 기부 연계)의 화면 문구를 Thai(으)로 번역한 것입니다.
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
[app.personalSponsorBadgeHint]
KO: 후원 시 프로필에 천사 뱃지가 영구 노출됩니다
TH: เมื่อสนับสนุน ตราแองเจิลจะแสดงบนโปรไฟล์ของคุณอย่างถาวร

[app.personalSponsorCelebrateHall]
KO: 명예의 전당 보기
TH: ดูหอเกียรติยศ

[app.personalSponsorCelebrateTitle]
KO: 천사 후원 완료!
TH: การสนับสนุนแองเจิลเสร็จสมบูรณ์!

[app.personalSponsorCta]
KO: 50,000 SHARE 후원하고 천사 되기
TH: สนับสนุน 50,000 SHARE แล้วเป็นแองเจิล

[app.personalSponsorDonationDesc]
KO: 후원은 운영자 이름으로 기부돼요. 내 기여는 앱에서 확인할 수 있어요.
TH: เงินสนับสนุนจะถูกบริจาคในนามของผู้ดำเนินงาน คุณสามารถตรวจสอบการมีส่วนร่วมของคุณได้ในแอป

[app.personalSponsorDonationTitle]
KO: [기부 후원]
TH: [การสนับสนุนการบริจาค]

[app.personalSponsorMonthlyToggle]
KO: 월간 'SHARE 멤버십'으로 매월 정기 후원하기
TH: สนับสนุนเป็นประจำทุกเดือนด้วย 'สมาชิกภาพ SHARE' รายเดือน

[app.personalSponsorPrizeDesc]
KO: 후원금이 1등 러너에게 순수 상금 보너스로 직접 지급됩니다.
TH: เงินสนับสนุนจะจ่ายตรงให้กับนักวิ่งอันดับ 1 ในรูปแบบโบนัสเงินรางวัลล้วน

[app.personalSponsorPrizeTitle]
KO: [순수 상금 지원]
TH: [สนับสนุนเงินรางวัลโดยตรง]

[app.personalSponsorPurposeLabel]
KO: 후원금의 사용 목적을 직접 선택해 주세요.
TH: โปรดเลือกวัตถุประสงค์ในการใช้เงินสนับสนุนด้วยตัวคุณเอง

[app.personalSponsorTitle]
KO: 러너 후원하기 (스폰서십)
TH: สนับสนุนนักวิ่ง (การสปอนเซอร์)

[personal_sponsor.body]
KO: SHARE가 부족합니다.
TH: SHARE ไม่เพียงพอ

[personal_sponsor.body.10]
KO: 아직 후원한 분이 없어요.
TH: ยังไม่มีผู้สปอนเซอร์

[personal_sponsor.body.11]
KO: 이번 달 ${won(summary.monthWon ?? 0)}원 · 누적 ${won(summary.totalWon ?? 0)}원 · 참여 ${summary.sponsorCount}명
TH: เดือนนี้ ${won(summary.monthWon ?? 0)} วอน · สะสม ${won(summary.totalWon ?? 0)} วอน · ผู้เข้าร่วม ${summary.sponsorCount} คน

[personal_sponsor.body.12]
KO: 참여 ${summary.sponsorCount}명 · 금액은 ${summary.minSponsors}명 이상 모이면 보여 드려요.
TH: ผู้เข้าร่วม ${summary.sponsorCount} คน · จำนวนเงินจะแสดงเมื่อมีผู้เข้าร่วมตั้งแต่ ${summary.minSponsors} คนขึ้นไป

[personal_sponsor.body.13]
KO: 후원 현황
TH: สถานะการสปอนเซอร์

[personal_sponsor.body.14]
KO: 이 내역은 나만 볼 수 있어요.
TH: มีเพียงคุณเท่านั้นที่เห็นประวัตินี้

[personal_sponsor.body.15]
KO: 서버에 연결되면 볼 수 있어요.
TH: จะดูได้เมื่อเชื่อมต่อกับเซิร์ฟเวอร์

[personal_sponsor.body.16]
KO: 아직 후원한 내역이 없어요.
TH: ยังไม่มีประวัติการสปอนเซอร์

[personal_sponsor.body.17]
KO: 기부 후원 ${mine.donationCount}번 · ${SponsorshipStatusCard.won(mine.donationWon)}원
TH: การสปอนเซอร์บริจาค ${mine.donationCount} ครั้ง · ${SponsorshipStatusCard.won(mine.donationWon)} วอน

[personal_sponsor.body.18]
KO: 기부 후원
TH: การสปอนเซอร์บริจาค

[personal_sponsor.body.19]
KO: 상금 후원
TH: การสปอนเซอร์เงินรางวัล

[personal_sponsor.body.2]
KO: 후원에 실패했습니다. 잠시 후 다시 시도해 주세요.
TH: สปอนเซอร์ไม่สำเร็จ โปรดลองอีกครั้งในภายหลัง

[personal_sponsor.body.20]
KO: ${SponsorshipStatusCard.won(e.share)} SHARE
${SponsorshipStatusCard.won(e.won)}원
TH: ${SponsorshipStatusCard.won(e.share)} SHARE
${SponsorshipStatusCard.won(e.won)} วอน

[personal_sponsor.body.3]
KO: 날개 배지가 프로필에 장착되었습니다. 명예의 전당에서 천사 후원자를 확인할 수 있어요.
TH: ติดตั้งตราสัญลักษณ์ปีกในโปรไฟล์เรียบร้อยแล้ว คุณสามารถตรวจสอบผู้สปอนเซอร์เทวดาได้ในหอเกียรติยศ

[personal_sponsor.body.4]
KO: 후원이 등록되었습니다. 명예의 전당에서 천사 후원 기록을 확인할 수 있어요.
TH: บันทึกการสปอนเซอร์เรียบร้อยแล้ว คุณสามารถตรวจสอบบันทึกการสปอนเซอร์เทวดาได้ในหอเกียรติยศ

[personal_sponsor.body.5]
KO: 러너
TH: นักวิ่ง

[personal_sponsor.body.6]
KO: 최고 천사 등급입니다
TH: ระดับเทวดาสูงสุด

[personal_sponsor.body.7]
KO: 다음 [${next.koreanName}] 등급까지 후원 $remainCount회 남음!
TH: เหลือการสปอนเซอร์อีก $remainCount ครั้ง เพื่อไปยังระดับ [${next.koreanName}] ถัดไป!

[personal_sponsor.body.8]
KO: 다음 [${next.koreanName}] 등급까지 후원 $remainCount회(또는 ${AngelTierX.formatWon(remainWon)}) 남음!
TH: เหลือการสปอนเซอร์อีก $remainCount ครั้ง (หรือ ${AngelTierX.formatWon(remainWon)}) เพื่อไปยังระดับ [${next.koreanName}] ถัดไป!

[personal_sponsor.body.9]
KO: 후원은 운영자 이름으로 기부돼요. 운영자는 전달만 해요.
TH: เงินสปอนเซอร์จะถูกบริจาคในนามของผู้ดำเนินงาน ผู้ดำเนินงานทำหน้าที่เพียงส่งต่อเท่านั้น

[personal_sponsor.button]
KO: 내 후원 내역
TH: ประวัติของฉัน

[privacy.ai_learning_tile.body]
KO: AI 개선에 내 데이터 사용
TH: ใช้ข้อมูลของฉันเพื่อพัฒนา AI

[privacy.ai_learning_tile.body.2]
KO: 기본은 꺼짐이에요. 켜고 끈 기록은 서버에 남고, 어느 폰에서나 같게 보여요.
TH: ปิดไว้เป็นค่าเริ่มต้น ประวัติการเปิด/ปิดจะถูกบันทึกไว้บนเซิร์ฟเวอร์ และแสดงผลเหมือนกันในทุกโทรศัพท์

[privacy.ai_learning_tile.toast]
KO: 저장하지 못했어요. 잠시 후 다시 시도해 주세요.
TH: บันทึกไม่สำเร็จ โปรดลองอีกครั้งในภายหลัง

[privacy.payment_auth_tile.body]
KO: 결제 전 본인 확인을 끄려면 본인 확인이 필요해요.
TH: จำเป็นต้องยืนยันตัวตนเพื่อปิดการยืนยันตัวตนก่อนชำระเงิน

[privacy.payment_auth_tile.body.2]
KO: 설정을 바꾸지 못했어요. 잠시 후 다시 시도해 주세요.
TH: ไม่สามารถเปลี่ยนการตั้งค่าได้ กรุณาลองใหม่อีกครั้งในภายหลัง

[privacy.payment_auth_tile.body.3]
KO: 다이아 구매와 Coach+ 결제창을 열기 전에 지문이나 화면 잠금으로 확인해요. 결제 승인은 구글 플레이가 하고, 이 확인은 한 번 더 걸러 주는 단계예요.
TH: ยืนยันด้วยลายนิ้วมือหรือการล็อกหน้าจอก่อนเปิดหน้าจอสั่งซื้อ DIA และชำระเงิน Coach+ การอนุมัติการชำระเงินดำเนินการโดย Google Play และการตรวจสอบนี้เป็นขั้นตอนป้องกันอีกชั้นหนึ่ง

[privacy.payment_auth_tile.toast]
KO: 결제 전 본인 확인
TH: ยืนยันตัวตนก่อนชำระเงิน

[app.proToolsCushionWarning]
KO: 쿠션 수명이 80km 남았습니다.
부상 방지를 위해 교체 시기가 다가옵니다.
TH: อายุการใช้งานระบบลดแรงกระแทกเหลือ 80 กม.
ใกล้ถึงเวลาเปลี่ยนเพื่อป้องกันการบาดเจ็บ

[app.proToolsMenuAiReport]
KO: AI 심층 러닝 리포트 (구간별 페이스 분석)
TH: รายงานการวิ่งเชิงลึกโดย AI (การวิเคราะห์เพซตามช่วง)

[app.proToolsMenuCrewRanking]
KO: 소속 크루(Crew) 출석률 랭킹 보드
TH: กระดานอันดับการเข้าร่วมของ crew ที่สังกัด

[app.proToolsMenuPaceCalc]
KO: 목표 거리에 따른 페이스 계산기 (VDOT)
TH: เครื่องคำนวณเพซตามระยะทางเป้าหมาย (VDOT)

[app.proToolsRegisteredShoe]
KO: 등록된 러닝화: 나이키 베이퍼플라이 3
TH: รองเท้าวิ่งที่ลงทะเบียน: Nike Vaporfly 3

[app.proToolsSubtitle]
KO: 장비의 수명을 관리하고 AI 리포트로 성장하세요.
TH: จัดการอายุการใช้งานของอุปกรณ์และพัฒนาด้วยรายงาน AI

[app.proToolsTitle]
KO: 러닝 기어 & 프로 툴
TH: อุปกรณ์วิ่งและเครื่องมือระดับโปร

[profile.activity_list.body]
KO: 러닝 로그
TH: บันทึกการวิ่ง

[profile.activity_list.body.2]
KO: 최근 러닝 기록이 없습니다
TH: ไม่มีประวัติการวิ่งล่าสุด

[profile.activity_list.body.3]
KO: 기록
TH: ประวัติ

[profile.activity_list.body.4]
KO: 걷기
TH: การเดิน

[profile.activity_list.body.5]
KO: ⚠️ 기록 보류 - 소명하기 〉
TH: ⚠️ ระงับการบันทึก - ยื่นคำร้องชี้แจง 〉

[profile.angel_tier_widgets.body]
KO: 나의 천사 연대기
TH: พงศาวดารทูตสวรรค์ของฉัน

[profile.angel_tier_widgets.body.10]
KO: 6익 천사 · 영롱한 광배가 당신을 비춥니다
TH: ทูตสวรรค์ 6 ปีก · รัศมีอันเจิดจ้าส่องสว่างมาที่คุณ

[profile.angel_tier_widgets.body.11]
KO: 누적 100회 또는 5,000,000 SHARE 후원 시 이 자리에 오릅니다
TH: ขึ้นสู่ตำแหน่งนี้เมื่อสนับสนุนสะสมครบ 100 ครั้ง หรือ 5,000,000 SHARE

[profile.angel_tier_widgets.body.12]
KO: 등록된 날개가 없습니다. 단 1회 후원으로 귀여운 진짜 아기 날개를 등 뒤에 달아보세요!
TH: ไม่มีปีกที่ลงทะเบียนไว้ ติดปีกเด็กน้อยของจริงสุดน่ารักไว้ที่ด้านหลังด้วยการสนับสนุนเพียง 1 ครั้ง!

[profile.angel_tier_widgets.body.13]
KO: 지금 후원하고 아기 날개 달기
TH: สนับสนุนตอนนี้และติดปีกเด็กน้อย

[profile.angel_tier_widgets.body.2]
KO: 후원 $count회 · ${AngelTierX.formatWon(amount)}
TH: สนับสนุน $count ครั้ง · ${AngelTierX.formatWon(amount)}

[profile.angel_tier_widgets.body.3]
KO: 아직 등 뒤에 장착된 진짜 날개가 없습니다. 단 1회 기부로 귀여운 아기 날개를 달아보세요!
TH: คุณยังไม่มีปีกของจริงติดอยู่ด้านหลัง ติดปีกเด็กน้อยสุดน่ารักด้วยการบริจาคเพียง 1 ครั้ง!

[profile.angel_tier_widgets.body.4]
KO: 첫 날개 달기 👼 〉
TH: ติดปีกคู่แรก 👼 〉

[profile.angel_tier_widgets.body.5]
KO: 후원하고 천사 등급 올리기 〉
TH: สนับสนุนและอัปเกรดระดับทูตสวรรค์ 〉

[profile.angel_tier_widgets.body.6]
KO: ❤️  내 이름으로 달리기 후원하기
TH: ❤️  สนับสนุนการวิ่งในชื่อของฉัน

[profile.angel_tier_widgets.body.7]
KO: 이번 달 명예 후원자
TH: ผู้สนับสนุนกิตติมศักดิ์ประจำเดือนนี้

[profile.angel_tier_widgets.body.8]
KO: 세라핌 VVIP 명예 전광판
TH: ป้ายเกียรติยศ Seraphim VVIP

[profile.angel_tier_widgets.body.9]
KO: 이번 달 최고 누적 기부 · 세라핌
TH: ยอดบริจาคสะสมสูงสุดในเดือนนี้ · เซราฟิม

[profile.avatar_choice.body]
KO: 남성
TH: ชาย

[profile.gender_profile_avatar.body]
KO: 닉네임을 설정해 주세요
TH: โปรดตั้งชื่อเล่นของคุณ

[profile.invite_copy.body]
KO: 내 초대 코드
TH: รหัสเชิญของฉัน

[profile.invite_copy.body.2]
KO: 복사
TH: คัดลอก

[profile.invite_copy.body.3]
KO: 복사했어요
TH: คัดลอกแล้ว

[profile.invite_copy.body.4]
KO: 초대 코드를 불러오지 못했어요. 다시 시도
TH: โหลดรหัสเชิญไม่สำเร็จ ลองใหม่อีกครั้ง

[profile.invite_copy.body.5]
KO: 카카오톡으로 초대하기
TH: เชิญผ่าน KakaoTalk

[profile.invite_copy.body.6]
KO: 쉐어런 초대
TH: คำเชิญ ShareRun

[profile.invite_copy.body.7]
KO: 쉐어런에 초대해요!
TH: ขอเชิญเข้าร่วม ShareRun!

[profile.invite_copy.body.8]
KO: 초대 코드
TH: รหัสเชิญ

[profile.my_dashboard_sections.body]
KO: 프로필 꾸미기
TH: ตกแต่งโปรไฟล์

[profile.my_page_referral_code_entry.body]
KO: ${AppStrings.referralRedeemDone} · $runs/${EconomyConstants.referralTrialRunsRequired} 런 · 1.1km 이상 달리면 안전해요
TH: ${AppStrings.referralRedeemDone} · $runs/${EconomyConstants.referralTrialRunsRequired} วิ่ง · วิ่งตั้งแต่ 1.1 กม. ขึ้นไปจะปลอดภัยแน่นอน

[profile.my_village_hero.button]
KO: 마을 바꾸기
TH: เปลี่ยนหมู่บ้าน

[profile.my_watch.body]
KO: 스마트워치 연결됨
TH: เชื่อมต่อสมาร์ตวอตช์แล้ว

[profile.my_watch.body.2]
KO: 걸음·심박을 받고, 시계 앱으로도 기록해요
TH: รับข้อมูลก้าวเดินและอัตราการเต้นของหัวใจ พร้อมบันทึกด้วยแอปบนนาฬิกาได้ด้วย

[profile.my_watch.body.3]
KO: 걸음·심박을 휴대폰으로 받아요
TH: รับข้อมูลก้าวเดินและอัตราการเต้นของหัวใจบนโทรศัพท์

[profile.my_watch.body.4]
KO: 시계 앱 연결됨
TH: เชื่อมต่อแอปนาฬิกาแล้ว

[profile.my_watch.body.5]
KO: $appName 연결됨
TH: เชื่อมต่อ $appName แล้ว

[profile.my_watch.body.6]
KO: 시계에서 바로 기록해요
TH: บันทึกได้โดยตรงจากนาฬิกา

[profile.my_watch.body.7]
KO: 내 워치
TH: นาฬิกาของฉัน

[profile.my_watch.body.8]
KO: 워치로 더 정확하게 달리기
TH: วิ่งได้แม่นยำยิ่งขึ้นด้วยนาฬิกา

[profile.my_watch.body.9]
KO: 걸음·심박을 시계에서 바로 기록해요
TH: บันทึกข้อมูลก้าวเดินและอัตราการเต้นของหัวใจได้โดยตรงจากนาฬิกา

[profile.my_watch.button]
KO: 관리
TH: จัดการ

[profile.retention_widgets.body]
KO: 오늘 모은 땀방울 ${km.toStringAsFixed(1)}km / ${cap.toStringAsFixed(1)}km ($percent%)
TH: หยาดเหงื่อที่สะสมวันนี้ ${km.toStringAsFixed(1)}km / ${cap.toStringAsFixed(1)}km ($percent%)

[profile.retention_widgets.body.10]
KO: 걷기 챌린지 보기
TH: ดูการแข่งขันเดิน

[profile.retention_widgets.body.11]
KO: 🔥 $streak일째 불꽃 유지 중!
TH: 🔥 รักษาสตรีคต่อเนื่องมา $streak วันแล้ว!

[profile.retention_widgets.body.12]
KO: 7일 연속 실천 완료 시 10 다이아몬드(DIA) 보너스 획득! 💎
TH: ทำต่อเนื่องครบ 7 วันเพื่อรับโบนัส 10 ไดมอนด์ (DIA)! 💎

[profile.retention_widgets.body.2]
KO: 오늘 걸음
TH: ก้าวเดินวันนี้

[profile.retention_widgets.body.3]
KO: ${groupedNumber(numbers.steps)} 걸음
TH: ${groupedNumber(numbers.steps)} ก้าว

[profile.retention_widgets.body.4]
KO: 다른 폰에서 이미 SHARE가 반영됐어요
TH: SHARE ถูกบันทึกจากโทรศัพท์เครื่องอื่นแล้ว

[profile.retention_widgets.body.5]
KO: 100걸음 → 10 SHARE · 하루 최대 600
TH: 100 ก้าว → 10 SHARE · สูงสุด 600 ต่อวัน

[profile.retention_widgets.body.6]
KO: 오늘 거리 ${km.toStringAsFixed(1)} km
TH: ระยะทางวันนี้ ${km.toStringAsFixed(1)} กม.

[profile.retention_widgets.body.7]
KO: 받은 SHARE ${numbers.receivedShare}
TH: SHARE ที่ได้รับ ${numbers.receivedShare}

[profile.retention_widgets.body.8]
KO: 줍기 대기 ${numbers.pendingShare}
TH: รอเก็บ ${numbers.pendingShare}

[profile.retention_widgets.body.9]
KO: ${numbers.pendingShare} SHARE 줍기
TH: เก็บ ${numbers.pendingShare} SHARE

[profile.tier_circle_badge.body]
KO: 예비 천사
TH: ทูตสวรรค์ฝึกหัด

[profile.village_scene.body]
KO: 기본 마을
TH: หมู่บ้านเริ่มต้น

[profile.village_scene.body.10]
KO: 마을 ${++extra}
TH: หมู่บ้าน ${++extra}

[profile.village_scene.body.11]
KO: 마을 고르기
TH: เลือกหมู่บ้าน

[profile.village_scene.body.12]
KO: 마이 화면 맨 위 배경이 바뀌어요.
TH: พื้นหลังด้านบนสุดของหน้าของฉันจะเปลี่ยนไป

[profile.village_scene.body.13]
KO: 아직 고를 수 있는 마을이 기본 하나뿐이에요.
TH: ตอนนี้มีเพียงหมู่บ้านเริ่มต้นเพียงแห่งเดียวให้เลือก

[profile.village_scene.body.2]
KO: 봄 공원
TH: สวนสาธารณะฤดูใบไม้ผลิ

[profile.village_scene.body.3]
KO: 바닷가
TH: ริมทะเล

[profile.village_scene.body.4]
KO: 밤 도시
TH: เมืองยามค่ำคืน

[profile.village_scene.body.5]
KO: 눈 마을
TH: หมู่บ้านหิมะ

[profile.village_scene.body.6]
KO: 가을 숲
TH: ป่าฤดูใบไม้ร่วง

[profile.village_scene.body.7]
KO: 축제의 밤
TH: คืนเทศกาล

[profile.village_scene.body.8]
KO: 오로라 호수
TH: ทะเลสาบออโรรา

[profile.village_scene.body.9]
KO: 하늘섬
TH: เกาะลอยฟ้า

[app.noCashPrizePool]
KO: 현금 상금 없음
TH: ไม่มีเงินรางวัลเป็นเงินสด

[app.refundCancelCta]
KO: 수수료 없이 결제 취소하기 (현금 환불)
TH: ยกเลิกการชำระเงินโดยไม่มีค่าธรรมเนียม (คืนเงินสด)

[app.refundGuaranteeTitle]
KO: 안전 환불 보장
TH: รับประกันการคืนเงินอย่างปลอดภัย

[app.refundPaymentDate]
KO: 결제일: 2026.06.25
TH: วันที่ชำระเงิน: 2026.06.25

[app.refundPolicy1]
KO: - 전자상거래법에 의거, 결제 후 7일 이내 미사용 재화는 수수료 없이 100% 현금 환불됩니다.
TH: - ตามกฎหมายพาณิชย์อิเล็กทรอนิกส์ สินค้าที่ยังไม่ได้ใช้งานภายใน 7 วันหลังชำระเงินจะได้รับเงินคืนเป็นเงินสด 100% โดยไม่มีค่าธรรมเนียม

[app.refundPolicy2]
KO: - 최소 인원이 모이지 않으면 참가비가 전액 돌아옵니다.
TH: - หากมีผู้เข้าร่วมไม่ครบตามจำนวนขั้นต่ำ จะคืนค่าธรรมเนียมการเข้าร่วมเต็มจำนวน

[app.refundTargetItem]
KO: [ 50,000 SHARE (미사용) ]
TH: [ 50,000 SHARE (ยังไม่ได้ใช้) ]

[app.refundTitle]
KO: 결제 취소 및 환불
TH: การยกเลิกการชำระเงินและการคืนเงิน

[app.refundTotalAmount]
KO: 총 환불 예정 금액: 50,000 KRW
TH: จำนวนเงินคืนโดยประมาณทั้งหมด: 50,000 KRW

[reminder_schedule.body]
KO: 워킹챌린지 참여 독려
TH: กระตุ้นการเข้าร่วมชาเลนจ์เดิน

[reminder_schedule.body.2]
KO: 워킹챌린지 아침·점심·저녁 참여 독려
TH: กระตุ้นการเข้าร่วมชาเลนจ์เดิน เช้า กลางวัน เย็น

[reminder_schedule.body.3]
KO: 🏃 활기찬 아침, 오늘의 첫걸음을 시작해 보세요!
TH: 🏃 เช้าที่สดใส เริ่มต้นก้าวแรกของวันนี้กันเถอะ!

[reminder_schedule.body.4]
KO: 오늘 하루 걷는 모든 발걸음이 소중한 SHARE가 됩니다.
TH: ทุกย่างก้าวที่คุณเดินในวันนี้จะกลายเป็น SHARE อันมีค่า

[reminder_schedule.body.5]
KO: ☕ 가벼운 산책으로 활력을 충전해 볼까요?
TH: ☕ มาเติมพลังด้วยการเดินเล่นเบาๆ กันไหม?

[reminder_schedule.body.6]
KO: 잠깐의 가벼운 걸음이 오늘의 챌린지 목표를 완성합니다.
TH: การเดินเบาๆ เพียงครู่เดียวจะช่วยให้เป้าหมายชาเลนจ์วันนี้สำเร็จ

[reminder_schedule.body.7]
KO: 🎁 오늘 획득할 수 있는 SHARE가 남아있어요!
TH: 🎁 ยังมี SHARE ที่คุณสามารถรับได้ในวันนี้เหลืออยู่!

[reminder_schedule.body.8]
KO: 오늘의 걸음을 인증하고 준비된 보상을 놓치지 마세요.
TH: ยืนยันการเดินของวันนี้และอย่าพลาดรางวัลที่เตรียมไว้

[report.body]
KO: 욕설·불쾌한 이름
TH: คำหยาบหรือชื่อที่ไม่เหมาะสม

[report.body.2]
KO: 선정적인 이름
TH: ชื่อลามกอนาจาร

[report.body.3]
KO: 혐오·차별 표현
TH: การแสดงความเกลียดชังหรือการเลือกปฏิบัติ

[report.body.4]
KO: 광고·도배
TH: โฆษณาหรือสแปม

[report.button]
KO: 운영자가 확인한 뒤 조치합니다. 신고한 사람은 상대에게 알려지지 않아요.
TH: ผู้ดูแลระบบจะตรวจสอบและดำเนินการให้ โดยที่อีกฝ่ายจะไม่ทราบว่าใครเป็นผู้รายงาน

[report.dialog]
KO: 기타
TH: อื่นๆ

[report.dialog.2]
KO: "$targetName" 신고
TH: รายงาน "$targetName"

[reward.winner_honor_popup.body]
KO: 챌린지 우승!
TH: ผู้ชนะการแข่งขัน!

[reward.winner_honor_popup.body.2]
KO: 당신의 땀방울이 세상을 바꿉니다.
TH: หยาดเหงื่อของคุณเปลี่ยนโลกได้

[reward.winner_honor_popup.button]
KO: 우승 상금 100% 전액 기부하기
TH: บริจาคเงินรางวัลเต็ม 100%

[reward.winner_reward.body]
KO: 축하합니다! 검증된 러닝으로 우승 상금을 획득했습니다.
TH: ยินดีด้วย! คุณได้รับเงินรางวัลชนะเลิศจากการวิ่งที่ผ่านการยืนยันแล้ว

[reward.winner_reward.button]
KO: 우승 상금 수령하기
TH: รับเงินรางวัล

[reward.winner_reward.button.2]
KO: 우승 상금 50% 기부하기
TH: บริจาคเงินรางวัล 50%

[reward.winner_reward.button.3]
KO: 100% 전액 기부하기
TH: บริจาคเต็มจำนวน 100%

[reward.winner_reward.dialog]
KO: 우승 임팩트
TH: ผลตอบแทนจากชัยชนะ

[run.run_tracker_provider.body]
KO: 달리기를 시작할 수 없습니다. 위치 서비스를 확인해 주세요.
TH: ไม่สามารถเริ่มการวิ่งได้ กรุณาตรวจสอบบริการตำแหน่ง

[app.runResultAvgPaceLabel]
KO: 평균 페이스:
TH: เพซเฉลี่ย:

[app.runResultDonate]
KO: ❤️ 이번 달리기 기부 기여 보기
TH: ❤️ ดูส่วนร่วมในการบริจาคของการวิ่งครั้งนี้

[app.runResultFinalTimeLabel]
KO: 최종 시간:
TH: เวลาสุดท้าย:

[app.runResultShare]
KO: 🔗 기록 SNS 공유하기
TH: 🔗 แชร์บันทึกลงโซเชียลมีเดีย

[app.runResultTitle]
KO: 축하합니다!
완주 성공 🎉
TH: ยินดีด้วย!
วิ่งสำเร็จเรียบร้อย 🎉

[app.runResultUnconfirmed]
KO: 서버에서 확인된 기록이 없습니다.
TH: ไม่มีบันทึกที่ได้รับการยืนยันจากเซิร์ฟเวอร์

[app.runResultValueReward]
KO: 서버 확인 노력 보상 +$tokens VALUE
TH: รางวัลความพยายามที่เซิร์ฟเวอร์ยืนยัน +$tokens VALUE

[run_result.body]
KO: 판정: ${result.decision.name}
TH: ผลการตัดสิน: ${result.decision.name}

[run_result.body.2]
KO: VALUE 보상: ${result.valueTokenReward}
TH: รางวัล VALUE: ${result.valueTokenReward}

[run_result.body.3]
KO: 로그인이 필요합니다.
TH: จำเป็นต้องเข้าสู่ระบบ

[run_result.body.4]
KO: 우승 보상 처리가 완료되었습니다.
TH: การประมวลผลรางวัลชนะเลิศเสร็จสมบูรณ์แล้ว

[run_result.body.5]
KO: 우승 보상 처리 실패: ${ApiErrorMessage.from(error)}
TH: การประมวลผลรางวัลชนะเลิศล้มเหลว: ${ApiErrorMessage.from(error)}

[run_result.button]
KO: 보상을 처리하는 중...
TH: กำลังดำเนินการรางวัล...

[run_result.button.2]
KO: 우승 상금 선택하기
TH: เลือกเงินรางวัลชนะเลิศ

[run_result.button.3]
KO: 홈으로 돌아가기
TH: กลับสู่หน้าหลัก

[run_result.title]
KO: 검증된 러닝
TH: การวิ่งที่ผ่านการตรวจสอบ

[run_result.title.2]
KO: 인정되지 않은 기록
TH: บันทึกที่ไม่ได้รับการรับรอง

[run_result.title.3]
KO: 검증되지 않은 기록
TH: บันทึกที่ยังไม่ได้รับการตรวจสอบ

[run_result.title.4]
KO: 러닝 결과
TH: ผลการวิ่ง

[run_result.run_finish_image_share.body]
KO: 공유 이미지를 만들지 못했어요.
TH: ไม่สามารถสร้างรูปภาพสำหรับแชร์ได้

[run_result.run_finish_image_share.body.2]
KO: Instagram 스토리로 공유하지 못했어요.
TH: ไม่สามารถแชร์ไปยังสตอรี่ Instagram ได้

[run_result.run_finish_image_share.body.3]
KO: 쉐어런 완주
TH: วิ่ง ShareRun สำเร็จ

[run_result.run_finish_share.body]
KO: 다크
TH: มืด

[run_result.run_finish_share.body.10]
KO: 목요일
TH: วันพฤหัสบดี

[run_result.run_finish_share.body.11]
KO: 금요일
TH: วันศุกร์

[run_result.run_finish_share.body.12]
KO: 토요일
TH: วันเสาร์

[run_result.run_finish_share.body.13]
KO: 일요일
TH: วันอาทิตย์

[run_result.run_finish_share.body.14]
KO: ${date.month}월 ${date.day}일 ${weekdays[date.weekday - 1]}
TH: ${weekdays[date.weekday - 1]} ${date.day}/${date.month}

[run_result.run_finish_share.body.15]
KO: 이번 달리기로 운영자가 ${_grouped(won)}원을 기부할 예정이에요
TH: จากการวิ่งครั้งนี้ ผู้ดำเนินงานวางแผนบริจาค ${_grouped(won)} วอน

[run_result.run_finish_share.body.16]
KO: 오늘은 기부 인정 10km를 모두 채웠어요. 넘는 거리는 기록으로 남아요.
TH: วันนี้คุณทำระยะทางบริจาคครบ 10 กม. แล้ว ระยะทางที่เกินมาจะยังคงบันทึกไว้ในบันทึกของคุณ

[run_result.run_finish_share.body.17]
KO: 기부 참여 기록
TH: ประวัติการเข้าร่วมบริจาค

[run_result.run_finish_share.body.18]
KO: 이번 달리기는 기부에 포함되지 않았어요.
TH: การวิ่งครั้งนี้ไม่รวมอยู่ในการบริจาค

[run_result.run_finish_share.body.19]
KO: 쉐어런 앱에서 ${distanceKm}km를 달렸어요. ⏱ 기록: $time
TH: ฉันวิ่งได้ ${distanceKm} กม. บนแอป ShareRun ⏱ บันทึก: $time

[run_result.run_finish_share.body.2]
KO: 블루
TH: น้ำเงิน

[run_result.run_finish_share.body.20]
KO: 오늘의 러닝
TH: การวิ่งวันนี้

[run_result.run_finish_share.body.21]
KO: 평균 심박 $averageHeartRate bpm
TH: อัตราการเต้นของหัวใจเฉลี่ย $averageHeartRate bpm

[run_result.run_finish_share.body.22]
KO: 구간 페이스
TH: เพซแต่ละช่วง

[run_result.run_finish_share.body.23]
KO: 시간
TH: เวลา

[run_result.run_finish_share.body.24]
KO: 페이스
TH: เพซ

[run_result.run_finish_share.body.3]
KO: 핑크
TH: ชมพู

[run_result.run_finish_share.body.4]
KO: 옐로
TH: เหลือง

[run_result.run_finish_share.body.5]
KO: 민트
TH: มินต์

[run_result.run_finish_share.body.6]
KO: 내 사진
TH: รูปภาพของฉัน

[run_result.run_finish_share.body.7]
KO: 월요일
TH: วันจันทร์

[run_result.run_finish_share.body.8]
KO: 화요일
TH: วันอังคาร

[run_result.run_finish_share.body.9]
KO: 수요일
TH: วันพุธ

[run_result.run_finish_share_flow.body]
KO: 하나만 올리기
TH: โพสต์รายการเดียว

[run_result.run_finish_share_flow.body.2]
KO: 여러 개 순서대로 올리기
TH: โพสต์หลายรายการตามลำดับ

[run_result.run_finish_share_flow.body.3]
KO: 순서대로 공유
TH: แชร์ตามลำดับ

[run_result.run_finish_share_flow.body.4]
KO: 그만하기
TH: หยุด

[run_result.run_finish_share_flow.body.5]
KO: 어떻게 올릴까요?
TH: ต้องการโพสต์อย่างไร?

[run_result.run_finish_share_flow.body.6]
KO: 어디에 올릴까요?
TH: ต้องการโพสต์ที่ไหน?

[run_result.run_finish_share_flow.body.7]
KO: 순서대로 올리기
TH: โพสต์ตามลำดับ

[run_result.run_finish_share_flow.body.8]
KO: 다음: $label
TH: ถัดไป: $label

[run_result.run_finish_share_targets.body]
KO: Instagram 스토리
TH: สตอรี่ Instagram

[run_result.run_finish_share_targets.body.2]
KO: Instagram 피드
TH: ฟีด Instagram

[run_result.run_finish_share_targets.body.3]
KO: 더보기
TH: เพิ่มเติม

[run_tracking.body]
KO: 심박 ${telemetry.currentHeartRate?.toString() ??
TH: อัตราการเต้นของหัวใจ ${telemetry.currentHeartRate?.toString() ??

[run_tracking.body.2]
KO: } BPM / 케이던스 ${telemetry.currentCadenceSpm?.toString() ??
TH: } BPM / จังหวะการก้าว ${telemetry.currentCadenceSpm?.toString() ??

[run_tracking.body.3]
KO: 자이로 안정도 ${telemetry.gyroStabilityScore.toStringAsFixed(2)}
TH: ความเสถียรของไจโร ${telemetry.gyroStabilityScore.toStringAsFixed(2)}

[run_tracking.body.4]
KO: 센서를 시작하는 중...
TH: กำลังเริ่มทำงานเซนเซอร์...

[run_tracking.body.5]
KO: 러닝 검증 중...
TH: กำลังตรวจสอบการวิ่ง...

[run_tracking.body.6]
KO: 러닝 끝내고 검증하기
TH: สิ้นสุดการวิ่งและตรวจสอบ

[run_tracking.body.7]
KO: MyPage에서 [선택] 민감정보 수집 동의 후 러닝 검증을 시작할 수 있습니다.
TH: คุณสามารถเริ่มการตรวจสอบการวิ่งได้หลังจากยินยอมการเก็บรวบรวมข้อมูลที่ละเอียดอ่อน [เลือกได้] ใน MyPage

[run_tracking.body.8]
KO: 센서를 시작하지 못했어요: $error
TH: ไม่สามารถเริ่มใช้งานเซนเซอร์ได้: $error

[run_tracking.title]
KO: 달리기 기록
TH: บันทึกการวิ่ง

[run_tracking.toast]
KO: 러닝 검증에 실패했어요: ${ApiErrorMessage.from(error)}
TH: การตรวจสอบการวิ่งล้มเหลว: ${ApiErrorMessage.from(error)}

[run_tracking.ble_heart_rate_service.body]
KO: BLE 심박 센서 (${map[
TH: เซนเซอร์วัดอัตราการเต้นของหัวใจ BLE (${map[

[run_tracking.ble_heart_rate_service.body.2]
KO: 이 기기에서는 블루투스 심박 스캔을 지원하지 않습니다.
TH: อุปกรณ์นี้ไม่รองรับการสแกนอัตราการเต้นของหัวใจผ่านบลูทูธ

[run_tracking.ble_heart_rate_service.body.3]
KO: 블루투스 권한 또는 상태를 확인해 주세요.
TH: โปรดตรวจสอบสิทธิ์หรือสถานะของบลูทูธ

[run_tracking.ble_heart_rate_service.body.4]
KO: 이 기기에서는 블루투스 심박 연결을 지원하지 않습니다.
TH: อุปกรณ์นี้ไม่รองรับการเชื่อมต่ออัตราการเต้นของหัวใจผ่านบลูทูธ

[run_tracking.ble_heart_rate_service.body.5]
KO: 센서 연결에 실패했습니다.
TH: เชื่อมต่อเซนเซอร์ไม่สำเร็จ

[run_tracking.gps_tracking_service.body]
KO: 실시간 러닝 GPS 추적 중
TH: กำลังติดตาม GPS การวิ่งแบบเรียลไทม์

[run_tracking.home_start_gate.body]
KO: 마이페이지에서 민감정보 수집에 동의해주세요
TH: โปรดยินยอมให้รวบรวมข้อมูลที่ละเอียดอ่อนในหน้าของฉัน

[run_tracking.home_start_gate.body.2]
KO: 로그인 후 러닝 검증을 진행할 수 있습니다.
TH: คุณสามารถดำเนินการยืนยันการวิ่งได้หลังจากเข้าสู่ระบบ

[run_tracking.home_start_gate.body.3]
KO: 러닝이 시작되지 않았습니다.
TH: ยังไม่ได้เริ่มการวิ่ง

[run_tracking.music_controls.body]
KO: 음악을 조절하지 못했어요.
TH: ไม่สามารถควบคุมเพลงได้

[run_tracking.music_controls.body.2]
KO: 재생 / 일시정지
TH: เล่น / หยุดชั่วคราว

[run_tracking.music_controls.body.3]
KO: 다음 곡
TH: เพลงถัดไป

[run_tracking.music_controls.body.4]
KO: 음악 앱 열기
TH: เปิดแอปเพลง

[run_tracking.music_controls.body.5]
KO: 음악 앱을 찾지 못했어요. 쓰는 음악 앱을 직접 열어 주세요.
TH: ไม่พบแอปเพลง โปรดเปิดแอปเพลงที่คุณใช้งานโดยตรง

[run_tracking.music_controls.button]
KO: 이전 곡
TH: เพลงก่อนหน้า

[run_tracking.run_recording_checklist.body]
KO: 화면을 끄거나 다른 앱을 켜도 경로 기록과 음성 코칭이 이어지도록 아래 항목을 확인해 주세요.
TH: โปรดตรวจสอบรายการด้านล่างเพื่อให้แน่ใจว่าการบันทึกเส้นทางและการฝึกสอนด้วยเสียงจะดำเนินต่อไปแม้หน้าจอจะปิดหรือเปิดแอปอื่นอยู่

[run_tracking.run_recording_checklist.body.10]
KO: 허용하지 않아도 달리기는 시작할 수 있습니다.
TH: คุณสามารถเริ่มวิ่งได้แม้จะไม่อนุญาต

[run_tracking.run_recording_checklist.body.11]
KO: 항목을 나중에 바꿔도 됩니다.
TH: คุณสามารถเปลี่ยนรายการเหล่านี้ในภายหลังได้

[run_tracking.run_recording_checklist.body.12]
KO: 필요
TH: จำเป็น

[run_tracking.run_recording_checklist.body.2]
KO: 위치 권한
TH: สิทธิ์เข้าถึงตำแหน่ง

[run_tracking.run_recording_checklist.body.3]
KO: 앱을 사용하는 동안 허용해 주세요. 항상 허용은 요청하지 않습니다.
TH: โปรดอนุญาตขณะใช้งานแอป เราจะไม่ขอ "อนุญาตตลอดเวลา"

[run_tracking.run_recording_checklist.body.4]
KO: 허용됨
TH: อนุญาตแล้ว

[run_tracking.run_recording_checklist.body.5]
KO: 허용하기
TH: อนุญาต

[run_tracking.run_recording_checklist.body.6]
KO: 알림 권한
TH: การอนุญาตการแจ้งเตือน

[run_tracking.run_recording_checklist.body.7]
KO: 달리기 기록 알림을 표시합니다. Android 13 이상에서 필요합니다.
TH: แสดงการแจ้งเตือนการบันทึกการวิ่ง จำเป็นสำหรับ Android 13 ขึ้นไป

[run_tracking.run_recording_checklist.body.8]
KO: 배터리 최적화
TH: การเพิ่มประสิทธิภาพแบตเตอรี่

[run_tracking.run_recording_checklist.body.9]
KO: 설정됨
TH: ตั้งค่าแล้ว

[run_tracking.run_recording_checklist.button]
KO: 확인하고 달리기
TH: ยืนยันแล้ววิ่ง

[run_tracking.run_recording_checklist.title]
KO: 달리기 기록 설정
TH: การตั้งค่าการบันทึกการวิ่ง

[run_tracking.run_recording_checklist.toast]
KO: 배터리 설정 화면을 열지 못했습니다.
TH: ไม่สามารถเปิดหน้าจอการตั้งค่าแบตเตอรี่ได้

[run_tracking.run_recording_foreground.body]
KO: 화면이 꺼져도 달리기 경로와 음성 코칭을 이어갑니다.
TH: บันทึกเส้นทางการวิ่งและการโค้ชด้วยเสียงต่อไปแม้หน้าจอจะดับ

[run_tracking.run_recording_policy.body]
KO: 쉐어런 · 달리기 기록 중
TH: ShareRun · กำลังบันทึกการวิ่ง

[run_tracking.run_recording_policy.body.2]
KO: 이전 달리기가 중단되었습니다
TH: การวิ่งครั้งก่อนถูกขัดจังหวะ

[run_tracking.run_recording_policy.body.3]
KO: 앱이 중간에 종료되어 직전 달리기는 저장되지 않았습니다. 보상은 지급되지 않고, 기록도 남지 않습니다.
TH: แอปปิดลงกะทันหัน จึงไม่ได้บันทึกการวิ่งครั้งล่าสุด ไม่มีการมอบรางวัลและไม่มีการเก็บประวัติ

[run_tracking.run_recording_policy.body.4]
KO: 화면이 꺼지면 달리기 기록이 중단될 수 있습니다.
TH: การบันทึกการวิ่งอาจถูกขัดจังหวะเมื่อหน้าจอดับ

[run_tracking.run_recording_policy.body.5]
KO: 달리기 기록 설정 점검
TH: ตรวจสอบการตั้งค่าการบันทึกการวิ่ง

[run_tracking.run_recording_policy.body.6]
KO: 시스템 배터리 최적화 화면에서 쉐어런을 찾아 주세요. 삼성 갤럭시는 '제한 없음'으로 바꿔 주세요.
TH: โปรดค้นหา ShareRun ในหน้าจอการเพิ่มประสิทธิภาพแบตเตอรี่ของระบบ สำหรับ Samsung Galaxy โปรดเปลี่ยนเป็น 'ไม่จำกัด'

[run_tracking.run_session_service.body]
KO: 위치 서비스가 꺼져 있습니다.
TH: บริการตำแหน่งถูกปิดใช้งาน

[run_tracking.run_session_service.body.2]
KO: 위치 권한이 영구 거부되었습니다. 설정에서 허용해 주세요.
TH: สิทธิ์เข้าถึงตำแหน่งถูกปฏิเสธอย่างถาวร โปรดอนุญาตในการตั้งค่า

[run_tracking.run_session_service.body.3]
KO: 위치 권한이 허용되었습니다.
TH: อนุญาตสิทธิ์เข้าถึงตำแหน่งแล้ว

[run_tracking.run_start_preflight.button]
KO: 심박수·케이던스 검증을 위해 [선택] 건강정보 수집 동의가 필요합니다. 일반 이용약관과 별도로 Opt-in 해 주세요.
TH: จำเป็นต้องมีความยินยอมในการเก็บรวบรวมข้อมูลสุขภาพ [ทางเลือก] เพื่อยืนยันอัตราการเต้นของหัวใจและรอบขา โปรดเลือกเข้าร่วมแยกต่างหากจากข้อกำหนดทั่วไป

[run_tracking.run_start_preflight.button.2]
KO: 동의 화면으로
TH: ไปที่หน้าจอยินยอม

[run_tracking.run_start_preflight.dialog]
KO: 건강정보 동의 필요
TH: จำเป็นต้องมีความยินยอมข้อมูลสุขภาพ

[run_tracking.run_start_preflight.toast]
KO: 로그인 후 러닝을 시작할 수 있습니다.
TH: คุณสามารถเริ่มวิ่งได้หลังจากเข้าสู่ระบบ

[run_tracking.sponsor_live_buff_banner.body]
KO: 스폰서 라이브 버프
TH: บัฟสดจากสปอนเซอร์

[run_tracking.watch_runtime_permissions_service.body]
KO: Health Connect 앱 설치
TH: ติดตั้งแอป Health Connect

[run_tracking.watch_runtime_permissions_service.body.2]
KO: Health Connect 건강 데이터
TH: ข้อมูลสุขภาพ Health Connect

[run_tracking.watch_runtime_permissions_service.body.3]
KO: 신체 활동 인식
TH: การรับรู้กิจกรรมทางกาย

[app.runningCrewCreateButton]
KO: [50 DIA 또는 30,000 SHARE로 새 크루 창설하기]
TH: [สร้าง crew ใหม่ด้วย 50 DIA หรือ 30,000 SHARE]

[app.runningCrewEnterRoom]
KO: 크루 룸 입장하기
TH: เข้าสู่ห้อง crew

[app.runningCrewHeadline]
KO: 같이 달릴
크루 찾기
TH: ค้นหา crew
เพื่อวิ่งไปด้วยกัน
