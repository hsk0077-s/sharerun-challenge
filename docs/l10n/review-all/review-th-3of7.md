# 번역 검수 요청 — 쉐어런 (Thai) · 파트 3/7

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
[item_inventory.toast.6]
KO: 휴식일을 지정하지 못했습니다.
TH: ไม่สามารถกำหนดวันพักได้

[item_inventory.toast.7]
KO: $title 보유량이 없습니다. 상점에서 구매해 주세요.
TH: คุณไม่มี $title กรุณาซื้อในร้านค้า

[item_inventory.toast.8]
KO: $title 사용 완료
TH: ใช้ $title เรียบร้อยแล้ว

[item_inventory.toast.9]
KO: $title 을 사용하지 못했습니다.
TH: ไม่สามารถใช้ $title ได้

[jena_validation.jena_pending_gate.body]
KO: 케이던스(발구름) 데이터가 없거나 0입니다. 기록이 보류되었습니다.
TH: ไม่มีข้อมูลรอบขาหรือข้อมูลเป็น 0 บันทึกของคุณถูกพักไว้

[jena_validation.jena_pending_gate.body.2]
KO: 심박수 추이가 페이스 증가에 반응하지 않아 차량·자전거·킥보드 탑승이 의심됩니다.
TH: แนวโน้มอัตราการเต้นของหัวใจไม่ตอบสนองต่อเพซที่เพิ่มขึ้น จึงสงสัยว่าอาจใช้ยานพาหนะ จักรยาน หรือสกู๊ตเตอร์

[jena_validation.jena_pending_gate.body.3]
KO: GPS 오차 범위를 넘는 순간 이동 속도가 검출되어 기록이 거절되었습니다.
TH: ตรวจพบความเร็วในการเคลื่อนที่ทันทีเกินขอบเขตข้อผิดพลาดของ GPS บันทึกจึงถูกปฏิเสธ

[jena_validation.jena_pending_gate.body.4]
KO: 비정상적인 GPS 순간 속도가 검출되어 기록이 보류되었습니다.
TH: ตรวจพบความเร็ว GPS ทันทีที่ผิดปกติ บันทึกจึงถูกพักไว้

[jena_validation.mock_jena_validation_service.body]
KO: GPS 궤적 또는 거리 데이터가 부족합니다.
TH: ข้อมูลเส้นทาง GPS หรือระยะทางไม่เพียงพอ

[jena_validation.mock_jena_validation_service.body.2]
KO: 순수 노력 러닝으로 Jena AI 검증이 완료되었습니다.
TH: การตรวจสอบโดย Jena AI เสร็จสมบูรณ์แล้วในฐานะการวิ่งด้วยความพยายามจริง

[jena_validation.verification_guidance.body]
KO: 이번 대회의 검증 최소 거리는 $distance예요. 대회 거리가 더 짧아도 1km는 넘어야 해요.
TH: ระยะทางขั้นต่ำในการตรวจสอบสำหรับการแข่งขันนี้คือ $distance แม้ว่าระยะทางการแข่งขันจะสั้นกว่า แต่ต้องเกิน 1 กม.

[jena_validation.verification_guidance.body.2]
KO: 분당 걸음 수는 120~210이어야 해요.
TH: จำนวนก้าวต่อนาทีต้องอยู่ระหว่าง 120 ถึง 210

[jena_validation.verification_guidance.body.3]
KO: 워치 심박은 운영자 대회 상급·하프·파이널에서만 필요해요.
TH: อัตราการเต้นของหัวใจจากนาฬิกาจำเป็นเฉพาะในการแข่งขันระดับสูง ฮาล์ฟ และไฟนอลของผู้ดูแลเท่านั้น

[jena_validation.verification_guidance.body.4]
KO: 이 대회는 워치 심박이 있어야 완주로 인정돼요.
TH: การแข่งขันนี้ต้องมีอัตราการเต้นของหัวใจจากนาฬิกาจึงจะถือว่าวิ่งจบสมบูรณ์

[jena_validation.verification_guidance.body.5]
KO: 기록은 언제나, 보상은 검증된 달리기에만.
TH: บันทึกได้เสมอ แต่รางวัลมีให้เฉพาะการวิ่งที่ผ่านการตรวจสอบเท่านั้น

[jena_validation.verification_guidance.body.6]
KO: 검증 안내
TH: คำแนะนำการตรวจสอบ

[jena_validation.verification_guidance.body.7]
KO: 확인하고 참가
TH: ยืนยันและเข้าร่วม

[jena_validation.verification_guidance.body.8]
KO: 다시 보지 않기
TH: ไม่ต้องแสดงอีก

[jena_validation.verification_reason.body]
KO: 거리가 이번 대회의 최소 거리보다 짧아요. 대회 거리만큼, 적어도 1km는 달려야 해요. 기록은 남고 보상은 지급되지 않아요.
TH: ระยะทางสั้นกว่าระยะทางขั้นต่ำของการแข่งขันนี้ คุณต้องวิ่งให้ได้ตามระยะทางของการแข่งขันและอย่างน้อย 1 กม. บันทึกจะยังคงอยู่ แต่จะไม่ได้รับรางวัล

[jena_validation.verification_reason.body.2]
KO: 분당 걸음 수가 120~210 범위를 벗어났어요. 기록은 남고 보상은 지급되지 않아요.
TH: จำนวนก้าวต่อนาทีอยู่นอกช่วง 120–210 บันทึกจะยังคงอยู่ แต่จะไม่ได้รับรางวัล

[jena_validation.verification_reason.body.3]
KO: 상급·하프·파이널 대회는 워치 심박이 있어야 완주로 인정돼요. 심박이 없어 보상은 지급되지 않아요.
TH: การแข่งขันระดับสูง ฮาล์ฟ และไฟนอล ต้องมีอัตราการเต้นของหัวใจจากนาฬิกาจึงจะถือว่าวิ่งจบสมบูรณ์ เนื่องจากไม่มีข้อมูลอัตราการเต้นของหัวใจ จึงไม่ได้รับรางวัล

[jena_validation.verification_reason.body.4]
KO: 평균 심박이 달리기라고 보기엔 낮아요. 기록은 남고 보상은 지급되지 않아요.
TH: อัตราการเต้นของหัวใจเฉลี่ยต่ำเกินกว่าจะเป็นการวิ่ง บันทึกจะยังคงอยู่ แต่จะไม่ได้รับรางวัล

[jena_validation.verification_reason.body.5]
KO: 심박이 거의 변하지 않아 달리기로 확인되지 않았어요. 기록은 남고 보상은 지급되지 않아요.
TH: อัตราการเต้นของหัวใจแทบไม่มีการเปลี่ยนแปลง จึงไม่สามารถยืนยันได้ว่าเป็นการวิ่ง บันทึกจะยังคงอยู่ แต่จะไม่ได้รับรางวัล

[jena_validation.verification_reason.body.6]
KO: 워치가 없어 보폭을 확인했는데, 거리와 걸음 수가 달리기 범위가 아니에요. 기록은 남고 보상은 지급되지 않아요.
TH: เนื่องจากไม่มีนาฬิกาจึงทำการตรวจสอบช่วงก้าว แต่ระยะทางและจำนวนก้าวไม่อยู่ในเกณฑ์ของการวิ่ง บันทึกจะยังคงอยู่ แต่จะไม่ได้รับรางวัล

[jena_validation.verification_reason.body.7]
KO: 이동 속도가 차량에 가까워 달리기로 인정되지 않았어요. 기록은 남고 보상은 지급되지 않아요.
TH: ความเร็วในการเคลื่อนที่ใกล้เคียงกับยานพาหนะ จึงไม่ถือว่าเป็นการวิ่ง บันทึกจะยังคงอยู่ แต่จะไม่ได้รับรางวัล

[jena_validation.verification_reason.body.8]
KO: 킥보드나 탑승으로 보여 보상은 지급되지 않아요. 기록은 남아요.
TH: ดูเหมือนว่าเป็นการใช้สกู๊ตเตอร์หรือโดยสารยานพาหนะ จึงไม่ได้รับรางวัล บันทึกจะยังคงอยู่

[jena_validation.verification_reason.body.9]
KO: 자전거 탑승으로 보여 보상은 지급되지 않아요. 기록은 남아요.
TH: ดูเหมือนว่าเป็นการปั่นจักรยาน จึงไม่ได้รับรางวัล บันทึกจะยังคงอยู่

[launch.intro.body]
KO: 걸으면 SHARE가 쌓여요
TH: เดินแล้วสะสม SHARE

[launch.intro.body.10]
KO: +100원
TH: +100 วอน

[launch.intro.body.11]
KO: 회사(운영자) 자금으로 기부 예정 · 내가 내는 돈은 없어요 · 내 기여는 앱에서 확인
TH: วางแผนจากเงินของบริษัท (ผู้ให้บริการ) · ไม่มีค่าใช้จ่ายสำหรับคุณ · ตรวจสอบการมีส่วนร่วมได้ในแอป

[launch.intro.body.13]
KO: 지금
달팽이
TH: ตอนนี้
หอยทาก

[launch.intro.body.14]
KO: 등급을
받으면
TH: เมื่อได้รับ
การจัดระดับ

[launch.intro.body.15]
KO: 티어가
오르면
TH: เมื่อระดับเทียร์
สูงขึ้น

[launch.intro.body.2]
KO: 한 걸음이 나눔이 된다
TH: ทุกก้าวเปลี่ยนเป็นการแบ่งปัน

[launch.intro.body.3]
KO: 내 기록은 어느 폰에서나 그대로예요
TH: บันทึกของคุณจะยังคงอยู่เหมือนเดิมในทุกโทรศัพท์

[launch.intro.body.4]
KO: 100걸음마다 10 SHARE를 받아요. 모은 SHARE로 대회에 참가할 수 있어요.
TH: รับ 10 SHARE ทุกๆ 100 ก้าว สามารถใช้ SHARE ที่สะสมไว้เพื่อเข้าร่วมการแข่งขันได้

[launch.intro.body.5]
KO: SHARE는 현금으로 바꿀 수 없는 활동 보상이고, 하루에 받을 수 있는 양에 한도가 있어요.
TH: SHARE เป็นรางวัลกิจกรรมที่ไม่สามารถแลกเปลี่ยนเป็นเงินสดได้ และมีขีดจำกัดจำนวนที่สามารถรับได้ต่อวัน

[launch.intro.body.6]
KO: 검증된 모든 달리기, 1km마다 운영자가 100원을 기부할 예정이에요. 내가 보탠 만큼은 앱에서 확인할 수 있어요.
TH: สำหรับการวิ่งที่ผ่านการตรวจสอบทุกครั้ง ผู้ดูแลวางแผนบริจาค 100 วอนต่อทุกๆ 1 กม. คุณสามารถตรวจสอบส่วนที่คุณมีส่วนร่วมได้ในแอป

[launch.intro.body.7]
KO: 운영자의 월 기부 예산 안에서 진행될 예정이에요. 예산을 다 쓴 달은 넘는 거리가 기록으로 남아요.
TH: วางแผนดำเนินการภายในงบประมาณการบริจาครายเดือนของผู้ดูแล ในเดือนที่ใช้งบประมาณจนหมดแล้ว ระยะทางที่เกินมาจะยังคงถูกบันทึกไว้

[launch.intro.body.8]
KO: 걷기·달리기 기록은 서버에 저장돼요. 폰을 바꿔도 로그인하면 이어져요.
TH: ประวัติการเดินและการวิ่งจะถูกบันทึกไว้บนเซิร์ฟเวอร์ แม้จะเปลี่ยนโทรศัพท์ เพียงเข้าสู่ระบบก็สามารถใช้งานต่อได้ทันที

[launch.intro.body.9]
KO: 100걸음
TH: 100 ก้าว

[launch.intro.button]
KO: 시작하기
TH: เริ่มต้น

[launch.intro.button.2]
KO: 이미 계정이 있어요 · 로그인
TH: มีบัญชีอยู่แล้ว · เข้าสู่ระบบ

[legal.health_data_consent.body]
KO: 체크해야 워치 연동·심박 검증이 활성화됩니다.
TH: ต้องทำเครื่องหมายเพื่อเปิดใช้งานการซิงค์นาฬิกาและการตรวจสอบอัตราการเต้นของหัวใจ

[legal_constants.body]
KO: 결제 취소 (현금 환불)
TH: ยกเลิกการชำระเงิน (คืนเงินสด)

[legal_constants.body.10]
KO: 마케팅·활동 알림 (선택)
TH: การแจ้งเตือนการตลาดและกิจกรรม (ไม่บังคับ)

[legal_constants.body.12]
KO: 부정 러닝·결제 어뷰징은 계정 제한 대상이 될 수 있습니다.
TH: การวิ่งทุจริตและการละเมิดการชำระเงินอาจส่งผลให้ถูกจำกัดการใช้งานบัญชี

[legal_constants.body.14]
KO: 전체 내용은 개인정보 처리방침 전문에서 확인할 수 있습니다.
TH: คุณสามารถตรวจสอบรายละเอียดทั้งหมดได้ในนโยบายความเป็นส่วนตัวฉบับเต็ม

[legal_constants.body.17]
KO: 대회 모집, 검증 결과, 리워드·기부 알림을 푸시로 받을 수 있습니다. 언제든 MyPage에서 변경할 수 있습니다.
TH: คุณสามารถรับการแจ้งเตือนแบบพุชเกี่ยวกับการรับสมัครการแข่งขัน ผลการยืนยัน รางวัล และการบริจาคได้ สามารถเปลี่ยนแปลงได้ตลอดเวลาใน MyPage

[legal_constants.body.18]
KO: 심박수·케이던스 원본 데이터는 기기 메모리에서 검증한 뒤 바로 폐기하며, 검증 결과 요약만 저장합니다.
TH: ข้อมูลดิบของอัตราการเต้นของหัวใจและรอบขาจะถูกทิ้งทันทีหลังจากการตรวจสอบในหน่วยความจำของอุปกรณ์ และจะจัดเก็บเฉพาะสรุปผลการตรวจสอบเท่านั้น

[legal_constants.body.19]
KO: 건강 정보 안내
TH: คำแนะนำข้อมูลสุขภาพ

[legal_constants.body.2]
KO: [선택] 건강정보(심박수) 수집 및 이용 동의
TH: [ไม่บังคับ] ยินยอมให้รวบรวมและใช้ข้อมูลสุขภาพ (อัตราการเต้นของหัวใจ)

[legal_constants.body.21]
KO: 가슴 통증, 어지러움 등 이상이 느껴지면 즉시 운동을 멈추고 의료진과 상담하세요.
TH: หากคุณรู้สึกเจ็บหน้าอก เวียนศีรษะ หรือมีความผิดปกติใดๆ ให้หยุดออกกำลังกายทันทีและปรึกษาแพทย์

[legal_constants.body.23]
KO: 언제든 해지할 수 있으며, 해지해도 이미 결제한 기간이 끝날 때까지 이용할 수 있습니다.
TH: คุณสามารถยกเลิกได้ตลอดเวลา และยังคงใช้งานได้จนกว่าจะสิ้นสุดระยะเวลาที่ชำระเงินแล้ว

[legal_constants.body.3]
KO: 건강정보 수집 동의 (선택 · 별도)
TH: ยินยอมให้รวบรวมข้อมูลสุขภาพ (ไม่บังคับ · แยกต่างหาก)

[legal_constants.body.4]
KO: 개인정보 처리방침 전문 보기
TH: ดูนโยบายความเป็นส่วนตัวฉบับเต็ม

[legal_constants.body.5]
KO: 서비스 이용약관 전문 보기
TH: ดูข้อกำหนดในการให้บริการฉบับเต็ม

[legal_constants.body.6]
KO: AI 생성 이미지 안내
TH: แจ้งเตือนเกี่ยวกับรูปภาพที่สร้างโดย AI

[legal_constants.body.7]
KO: 일부 그림은 AI로 생성되었습니다. Created with Grok
TH: รูปภาพบางส่วนสร้างขึ้นโดย AI Created with Grok

[legal_constants.body.8]
KO: 서비스 이용약관 (필수)
TH: ข้อกำหนดในการให้บริการ (จำเป็น)

[legal_constants.body.9]
KO: 개인정보 처리방침 (필수)
TH: นโยบายความเป็นส่วนตัว (จำเป็น)

[app.levelTestChallengeProgress]
KO: 챌린지 진행 상황: 2/3회 완료 (3.52/5.00 KM)
TH: ความคืบหน้าชาเลนจ์: เสร็จสิ้น 2/3 ครั้ง (3.52/5.00 KM)

[app.levelTestGhostPace]
KO: [고스트 페이스]
TH: [เพซโกสต์]

[app.levelTestMyLocation]
KO: [나(현재 위치)]
TH: [ฉัน (ตำแหน่งปัจจุบัน)]

[app.levelTestStartRun]
KO: 3회차 달리기 시작하기
TH: เริ่มวิ่งครั้งที่ 3

[app.levelTestStatDistance]
KO: 현재 거리
TH: ระยะทางปัจจุบัน

[app.levelTestStatPace]
KO: 현재 페이스
TH: เพซปัจจุบัน

[app.levelTestStatTime]
KO: 경과 시간
TH: เวลาที่ผ่านไป

[app.levelTestSubtitle]
KO: 검증된 달리기를 서로 다른 날 3번 마치면 등급이 배정됩니다.
TH: วิ่งที่ผ่านการยืนยันครบ 3 ครั้งในวันที่ต่างกันเพื่อรับการจัดอันดับ

[app.levelTestTitle]
KO: 혼자 뛰기 챌린지 (등급 배정)
TH: ชาเลนจ์วิ่งคนเดียว (จัดอันดับ)

[app.liveRunningEffortTip]
KO: 순수 노력 목표: 완주 시 VALUE +$valueTokens
TH: เป้าหมายความพยายามล้วนๆ: VALUE +$valueTokens เมื่อวิ่งจบ

[app.liveRunningFinish]
KO: 종료 / 저장
TH: สิ้นสุด / บันทึก

[app.liveRunningGhostPace]
KO: 고스트 페이스
TH: เพซโกสต์

[app.liveRunningRoomTitle]
KO: 3km 중급 챌린지
TH: คำท้า 3 กม. ระดับกลาง

[app.liveRunningSubmissionsLeft]
KO: 제출 기회: 2/3회 남음
TH: โอกาสส่งผล: เหลือ 2/3 ครั้ง

[app.liveRunningYouLabel]
KO: 나 (You)
TH: คุณ (You)

[app.runValidationFailed]
KO: 기록 검증에 실패했습니다. 보상이 지급되지 않았습니다.
TH: การตรวจสอบบันทึกล้มเหลว ไม่มีการมอบรางวัล

[live_running.body]
KO: 1km 초보 챌린지
TH: ท้าทาย 1 กม. มือใหม่

[live_running.body.2]
KO: 나
TH: ฉัน

[live_running.body.3]
KO: 고스트
TH: โหมดโกสต์

[live_running.body.4]
KO: 검증 중
TH: กำลังตรวจสอบ

[live_running.toast]
KO: 센서 시작 실패: $error
TH: เริ่มทำงานเซนเซอร์ไม่สำเร็จ: $error

[app.existingAccountApple]
KO: 애플로 가입했어요
TH: ฉันสมัครด้วย Apple

[app.existingAccountBody]
KO: 그 방법으로 로그인하면 지금 $provider${subjectParticle(provider)} 그 계정에 연결돼요. 닉네임과 재화도 그대로예요.
TH: หากเข้าสู่ระบบด้วยวิธีดังกล่าว $provider${subjectParticle(provider)} ปัจจุบันจะเชื่อมโยงกับบัญชีนั้น โดยชื่อเล่นและสกุลเงินของคุณจะยังคงเหมือนเดิม

[app.existingAccountCreate]
KO: 새로 시작하기
TH: เริ่มต้นใหม่

[app.existingAccountCreateHint]
KO: 기억나지 않거나 처음이신가요?
TH: จำไม่ได้หรือเพิ่งเคยมาครั้งแรกใช่ไหม?

[app.existingAccountGoogle]
KO: 구글로 가입했어요
TH: ฉันสมัครด้วย Google

[app.existingAccountKakao]
KO: 카카오로 가입했어요
TH: ฉันสมัครด้วย Kakao

[app.existingAccountNaver]
KO: 네이버로 가입했어요
TH: ฉันสมัครด้วย Naver

[app.existingAccountNotFound]
KO: 그 방법으로 가입된 계정이 없어요. 다른 방법을 골라 주세요.
TH: ไม่พบบัญชีที่สมัครด้วยวิธีดังกล่าว กรุณาเลือกวิธีอื่น

[app.existingAccountTitle]
KO: 처음 가입할 때 어떤 방법을 쓰셨나요?
TH: คุณใช้วิธีใดเมื่อสมัครสมาชิกครั้งแรก?

[app.linkAttached]
KO: $method${subjectParticle(method)} 연결됐어요. 이제 어느 쪽으로 들어와도 같은 계정이에요.
TH: $method${subjectParticle(method)} เชื่อมโยงเรียบร้อยแล้ว ตอนนี้เข้าสู่ระบบจากทางไหนก็เป็นบัญชีเดียวกัน

[app.linkConfirmNo]
KO: 아니에요, 다시 고를게요
TH: ไม่ เลือกใหม่อีกครั้ง

[app.linkConfirmTitle]
KO: 이 계정에 $method${objectParticle(method)} 연결할까요?
TH: เชื่อมโยง $method${objectParticle(method)} กับบัญชีนี้หรือไม่?

[app.linkConfirmYes]
KO: 네, 연결할게요
TH: ใช่ เชื่อมโยงเลย

[app.loginComingSoon]
KO: $provider 로그인은 준비 중입니다.
TH: การเข้าสู่ระบบด้วย $provider กำลังอยู่ในระหว่างเตรียมการ

[app.loginGoogle]
KO: Google로 계속하기
TH: ดำเนินการต่อด้วย Google

[app.loginGuest]
KO: 게스트(테스트)로 시작하기
TH: เริ่มต้นในฐานะผู้เยี่ยมชม (ทดสอบ)

[app.loginGuestLoading]
KO: 게스트 로그인 중...
TH: กำลังเข้าสู่ระบบในฐานะผู้เยี่ยมชม...

[app.loginGuestNote]
KO: 게스트 모드는 워치 연동·Health Connect 테스트용 임시 계정입니다.
TH: โหมดผู้เยี่ยมชมเป็นบัญชีชั่วคราวสำหรับการทดสอบการเชื่อมต่อนาฬิกาและ Health Connect

[app.loginKakao]
KO: Kakao로 계속하기
TH: ดำเนินการต่อด้วย Kakao

[app.loginNaver]
KO: Naver로 계속하기
TH: ดำเนินการต่อด้วย Naver

[app.loginReferralHint]
KO: 추천 코드를 입력하세요...
TH: ใส่รหัสแนะนำ...

[app.loginReferralLabel]
KO: 추천 코드가 있으신가요?
TH: คุณมีรหัสแนะนำหรือไม่?

[app.loginSaveFailed]
KO: 로그인 저장 실패: $error
TH: บันทึกการเข้าสู่ระบบไม่สำเร็จ: $error

[app.loginSubtitle]
KO: 세계를 향한 나눔의 질주
TH: การวิ่งแห่งการแบ่งปันสู่โลกกว้าง

[app.referralRedeemAlready]
KO: 이미 초대 코드를 입력했어요
TH: คุณได้ใส่รหัสเชิญไปแล้ว

[app.referralRedeemDone]
KO: 초대한 친구: 입력 완료
TH: เพื่อนที่เชิญ: กรอกเรียบร้อยแล้ว

[app.referralRedeemEntry]
KO: 초대 코드 입력
TH: ใส่รหัสเชิญ

[app.referralRedeemExpired]
KO: 가입 후 7일이 지나 입력할 수 없어요
TH: ไม่สามารถใส่ได้เนื่องจากเกิน 7 วันหลังจากการสมัครแล้ว

[app.referralRedeemFailed]
KO: 초대 코드를 등록하지 못했어요
TH: ไม่สามารถลงทะเบียนรหัสเชิญได้

[app.referralRedeemInvalid]
KO: 없는 초대 코드예요
TH: ไม่มีรหัสเชิญนี้

[app.referralRedeemSelf]
KO: 본인 코드는 입력할 수 없어요
TH: ไม่สามารถใส่รหัสของตัวเองได้

[app.referralRedeemSubmit]
KO: 등록
TH: ลงทะเบียน

[app.referralRedeemSuccess]
KO: 10,000 SHARE 지급
TH: มอบ 10,000 SHARE

[login.body]
KO: 구글 로그인에 성공했습니다!
TH: เข้าสู่ระบบด้วย Google สำเร็จ!

[login.body.2]
KO: 로그인 실패:
TH: เข้าสู่ระบบไม่สำเร็จ:

[login.body.3]
KO: 애플 로그인에 성공했습니다!
TH: เข้าสู่ระบบด้วย Apple สำเร็จ!

[login.body.4]
KO: 애플 로그인 실패:
TH: เข้าสู่ระบบด้วย Apple ไม่สำเร็จ:

[login.body.5]
KO: 네이버 로그인에 성공했습니다!
TH: เข้าสู่ระบบด้วย Naver สำเร็จ!

[login.body.6]
KO: 네이버 로그인 실패:
TH: เข้าสู่ระบบด้วย Naver ไม่สำเร็จ:

[login.body.7]
KO: 카카오 로그인에 성공했습니다!
TH: เข้าสู่ระบบด้วย Kakao สำเร็จ!

[login.body.8]
KO: 카카오 로그인 실패:
TH: เข้าสู่ระบบด้วย Kakao ไม่สำเร็จ:

[login.body.9]
KO: 닉네임 $nickname
SHARE ${groupedDigits(shareBalance)}
TH: ชื่อเล่น $nickname
SHARE ${groupedDigits(shareBalance)}

[login.button]
KO: 초대 코드가 있으신가요?
TH: คุณมีรหัสเชิญหรือไม่?

[login_connections.body]
KO: $name 연결을 해제했어요.
TH: ยกเลิกการเชื่อมต่อ $name แล้ว

[login_connections.body.2]
KO: 카카오
TH: Kakao

[login_connections.body.3]
KO: 네이버
TH: Naver

[login_connections.body.4]
KO: 애플
TH: Apple

[login_connections.body.5]
KO: 구글
TH: Google

[login_connections.body.6]
KO: 같은 계정으로 여러 방법으로 로그인할 수 있어요. 연결해 두면 어떤 방법으로 들어와도 같은 SHARE와 기록이 보여요. 마지막 로그인 방법은 해제할 수 없어요.
TH: คุณสามารถเข้าสู่ระบบได้หลายวิธีสำหรับบัญชีเดียวกัน เมื่อเชื่อมต่อแล้ว ไม่ว่าจะเข้าด้วยวิธีใดก็จะเห็น SHARE และประวัติเดียวกัน ไม่สามารถยกเลิกวิธีเข้าสู่ระบบสุดท้ายได้

[login_connections.body.7]
KO: 연결 안 됨
TH: ไม่ได้เชื่อมต่อ

[login_connections.button]
KO: 해제하면 이 $name 계정으로는 이 쉐어런 계정에 들어올 수 없어요. 다른 로그인 방법으로는 계속 쓸 수 있어요.
TH: หากยกเลิกการเชื่อมต่อ คุณจะไม่สามารถเข้าสู่บัญชี ShareRun นี้ด้วยบัญชี $name นี้ได้ คุณยังคงสามารถใช้วิธีเข้าสู่ระบบอื่นได้

[login_connections.button.2]
KO: 다시 불러오기
TH: โหลดใหม่

[login_connections.button.3]
KO: 연결하기
TH: เชื่อมต่อ

[login_connections.dialog]
KO: $name 연결 해제
TH: ยกเลิกการเชื่อมต่อ $name

[login_devices.body]
KO: 이 계정으로 앱을 연 기기예요. 기기 이름과 마지막으로 연 시각만 저장하고, 위치나 IP 주소는 저장하지 않아요.
TH: อุปกรณ์ที่เปิดแอปด้วยบัญชีนี้ จะบันทึกเฉพาะชื่ออุปกรณ์และเวลาที่เปิดล่าสุด โดยไม่บันทึกตำแหน่งหรือที่อยู่ IP

[login_devices.body.2]
KO: 앱 데이터를 지우거나 다시 설치하면 같은 폰이 한 줄 더 보일 수 있어요.
TH: การลบข้อมูลแอปหรือติดตั้งใหม่อาจทำให้โทรศัพท์เครื่องเดียวกันแสดงขึ้นมาอีกแถว

[login_devices.body.3]
KO: 아직 기록된 기기가 없어요.
TH: ยังไม่มีอุปกรณ์ที่ถูกบันทึก

[login_devices.body.4]
KO: 알 수 없는 기기
TH: ไม่รู้จักอุปกรณ์

[login_devices.body.5]
KO: $name (이 기기)
TH: $name (อุปกรณ์นี้)

[login_devices.body.6]
KO: $name · 새 기기
TH: $name · อุปกรณ์ใหม่

[login_devices.body.7]
KO: ${device.osVersion} · 앱 ${device.appVersion}
마지막으로 연 시각 $when
TH: ${device.osVersion} · แอป ${device.appVersion}
เปิดใช้งานล่าสุด $when

[login_devices.button]
KO: 이 폰을 포함해 로그인된 모든 기기에서 로그아웃돼요. 다른 기기는 잠시 뒤 로그인 화면으로 돌아가요. 계속할까요?
TH: คุณจะถูกออกจากระบบในทุกอุปกรณ์รวมถึงโทรศัพท์เครื่องนี้ อุปกรณ์อื่นจะกลับสู่หน้าจอลงชื่อเข้าใช้ในไม่ช้า ดำเนินการต่อหรือไม่?

[login_devices.dialog]
KO: 모든 기기에서 로그아웃
TH: ออกจากระบบทุกอุปกรณ์

[login_devices.toast]
KO: 로그아웃하지 못했어요. 잠시 후 다시 시도해 주세요.
TH: ไม่สามารถออกจากระบบได้ กรุณาลองใหม่อีกครั้งในภายหลัง

[app.dashboardChallenge1Sub]
KO: 참가비: 600 SHARE
TH: ค่าสมัคร: 600 SHARE

[app.dashboardChallenge1Title]
KO: 초보 1km 챌린지 🏆
TH: คำท้า 1 กม. ระดับเริ่มต้น 🏆

[app.dashboardChallenge2Sub]
KO: 참가비: 1,200 SHARE
TH: ค่าสมัคร: 1,200 SHARE

[app.dashboardChallenge2Title]
KO: 중급 3km 챌린지 (골드 대회)
TH: คำท้า 3 กม. ระดับกลาง (การแข่งขันทอง)

[app.dashboardDailyMissionCapsule]
KO: 📍 오늘의 미션 확인하기 >
TH: 📍 ตรวจสอบภารกิจวันนี้ >

[app.dashboardDiamondBalance]
KO: 💎 보유 다이아몬드: 5개
TH: 💎 DIA ที่มี: 5

[app.dashboardDiamondBalanceOf]
KO: 💎 보유 다이아몬드: $count개
TH: 💎 DIA ที่มี: $count

[app.dashboardGradeRunLabel]
KO: 등급 배정 달리기:
TH: วิ่งจัดอันดับ:

[app.dashboardGradeRunProgress]
KO: 2/3회 완료 >
TH: เสร็จสิ้น 2/3 ครั้ง >

[app.dashboardOngoingChallenges]
KO: 진행 중인 챌린지
TH: คำท้าทายที่กำลังดำเนินการ

[app.dashboardShareBalance]
KO: 보유 SHARE: 90,000
TH: SHARE ที่มี: 90,000

[app.dashboardShareBalanceOf]
KO: 보유 SHARE: $amount
TH: SHARE ที่มี: $amount

[app.dashboardStampMapTooltip]
KO: 오늘의 미션 · 스탬프 투어
TH: ภารกิจวันนี้ · ทัวร์สะสมแสตมป์

[app.dashboardValueBalance]
KO: 🌱 보유 밸류(VALUE): 5,200
TH: 🌱 VALUE ที่มี: 5,200

[app.dashboardValueBalanceOf]
KO: 🌱 보유 밸류(VALUE): $amount
TH: 🌱 VALUE ที่มี: $amount

[app.dashboardViewRoom]
KO: 대회 상세 보기
TH: ดูรายละเอียดการแข่งขัน

[app.exitGuardMessage]
KO: 나눔의 질주를 잠시 쉬어가시겠습니까? 한 번 더 누르시면 종료됩니다.
TH: ต้องการพักจากการวิ่งแห่งการแบ่งปันชั่วคราวหรือไม่? กดอีกครั้งเพื่อออก

[app.myWalletCharge]
KO: 교환하기
TH: แลกเปลี่ยน

[app.myWalletChargeDia]
KO: 다이아몬드
TH: DIA

[app.myWalletChargeDiaHint]
KO: 교환소에서 SHARE로 바꾸거나 연속 달리기로 모을 수 있어요
TH: สามารถแลกเป็น SHARE ได้ที่ศูนย์แลกเปลี่ยน หรือสะสมจากการวิ่งต่อเนื่อง

[app.myWalletChargeShareHint]
KO: 활동으로 모을 수 있어요
TH: สามารถสะสมได้จากกิจกรรม

[app.myWalletChargeValue]
KO: 밸류(VALUE)
TH: VALUE

[app.myWalletChargeValueHint]
KO: 달리기로 모을 수 있어요
TH: สามารถสะสมได้จากการวิ่ง

[app.myWalletDiamondLabel]
KO: 보유 다이아몬드: $count개
TH: DIA ที่มี: $count

[app.myWalletGradeProgress]
KO: 등급 배정 달리기: $done/$total회 완료 >
TH: วิ่งจัดอันดับ: เสร็จสิ้น $done/$total ครั้ง >

[app.myWalletInventoryCount]
KO: 보유 $count
TH: ครอบครอง $count

[app.myWalletInventoryEmpty]
KO: 아직 보유한 아이템이 없습니다.
TH: ยังไม่มีไอเทมที่ครอบครอง

[app.myWalletInventoryOpen]
KO: 보관함 보기
TH: ดูคลังเก็บของ

[app.myWalletInventoryTitle]
KO: 보유 아이템
TH: ไอเทมที่มี

[app.myWalletItemDuringRun]
KO: 달리기 중 사용 가능
TH: สามารถใช้ได้ระหว่างวิ่ง

[app.myWalletItemDuringTournament]
KO: 대회에서 사용 가능
TH: สามารถใช้ได้ในการแข่งขัน

[app.myWalletRecentTransactions]
KO: 최근 거래 내역
TH: ประวัติการทำรายการล่าสุด

[app.myWalletUse]
KO: 상점 가기
TH: ไปที่ร้านค้า

[app.myWalletValueLabel]
KO: 보유 밸류(VALUE): $amount
TH: VALUE ที่มี: $amount

[app.walletUnconfirmedNote]
KO: 서버에서 확인하는 중이에요. 지금 보이는 값은 마지막으로 확인된 값이에요.
TH: กำลังตรวจสอบกับเซิร์ฟเวอร์ ค่าที่แสดงอยู่คือค่าล่าสุดที่ได้รับการยืนยัน

[main_dashboard.body]
KO: 상품은 다이아예요 · ${AppStrings.noCashPrizePool}
TH: รางวัลคือ DIA · ${AppStrings.noCashPrizePool}

[main_dashboard.body.2]
KO: 좋은 아침이에요
TH: อรุณสวัสดิ์

[main_dashboard.body.3]
KO: 좋은 오후예요
TH: สวัสดีตอนบ่าย

[main_dashboard.body.4]
KO: 좋은 저녁이에요
TH: สวัสดีตอนเย็น

[main_dashboard.body.5]
KO: ${_hello(DateTime.now().hour)}, $nickname님
TH: ${_hello(DateTime.now().hour)}, คุณ$nickname

[main_shell_routes.body]
KO: 결제 정보가 없어 PG 화면을 열 수 없습니다.
TH: ไม่สามารถเปิดหน้าจอ PG ได้เนื่องจากไม่มีข้อมูลการชำระเงิน

[main_shell_routes.body.2]
KO: 대회 정보가 없어 스폰서 결제를 열 수 없습니다.
TH: ไม่สามารถเปิดการชำระเงินของสปอนเซอร์ได้เนื่องจากไม่มีข้อมูลการแข่งขัน

[main_shell_routes.button]
KO: 대회 목록으로
TH: ไปยังรายการแข่งขัน

[map_crew.body]
KO: 지도 & 크루
TH: แผนที่ & crew

[map_crew.body.2]
KO: 크루 종합 랭킹
TH: อันดับรวม crew

[map_crew.body.3]
KO: ${crews[index].memberCount}명
TH: ${crews[index].memberCount} คน

[map_crew.body.4]
KO: 아직 크루 순위가 없어요
TH: ยังไม่มีอันดับ crew

[map_crew.body.5]
KO: 크루 순위가 쌓이면 여기에 나타나요.
TH: อันดับ crew จะปรากฏที่นี่เมื่อมีการสะสมอันดับ

[map_crew.body.6]
KO: ${collectRadiusMeters.round()}m 안으로 가까이 가야 받을 수 있어요.
TH: คุณต้องเข้าใกล้ในระยะ ${collectRadiusMeters.round()}m ถึงจะรับได้

[map_crew.body.7]
KO: +${box.rewardDiamond} DIA를 받았어요.
TH: ได้รับ +${box.rewardDiamond} DIA

[map_crew.body.8]
KO: ${distanceMeters!.toStringAsFixed(0)}m 떨어져 있어요
TH: ห่างออกไป ${distanceMeters!.toStringAsFixed(0)}m

[map_crew.button]
KO: 내 위치 새로고침
TH: รีเฟรชตำแหน่ง

[map_crew.button.2]
KO: 다이아 상자 받기
TH: รับกล่อง DIA

[map_crew.button.3]
KO: 더 가까이 가 주세요
TH: โปรดเข้าใกล้กว่านี้

[map_crew.crew_member_ranking_board.body]
KO: 크루원 랭킹 데이터 없음
TH: ไม่มีข้อมูลอันดับสมาชิก crew

[map_crew.crew_member_ranking_board.body.2]
KO: 출석률·평균 페이스가 여기에 표시됩니다.
TH: อัตราการเข้าร่วมและเพซเฉลี่ยจะแสดงที่นี่

[map_crew.crew_member_ranking_board.body.3]
KO: 크루원 출석률 & 평균 페이스
TH: อัตราการเข้าร่วมและเพซเฉลี่ยของสมาชิก crew

[map_crew.crew_member_ranking_board.body.4]
KO: 출석률 높은 순 · 페이스 빠른 순으로 B2B 크루 성과를 추적합니다.
TH: ติดตามผลงาน B2B crew ตามลำดับอัตราการเข้าร่วมสูงสุดและเพซเร็วที่สุด

[map_crew.crew_member_ranking_board.body.5]
KO: 출석 ${member.attendanceRate.toStringAsFixed(0)}%
TH: เข้าร่วม ${member.attendanceRate.toStringAsFixed(0)}%

[map_crew.safe_map_panel.body]
KO: 지도 준비 중
TH: กำลังเตรียมแผนที่

[mini_bot.body]
KO: 궁금한 게 있으면 저를 눌러 물어보세요
TH: หากมีข้อสงสัย แตะที่ฉันเพื่อสอบถามได้เลย

[mini_bot.body.10]
KO: 하루 SHARE 한도
TH: ขีดจำกัด SHARE ต่อวัน

[mini_bot.body.11]
KO: 어떤 대회?
TH: การแข่งขันแบบไหน?

[mini_bot.body.12]
KO: 순위별 상금
TH: เงินรางวัลตามอันดับ

[mini_bot.body.13]
KO: 초급은 무료?
TH: ระดับเริ่มต้นฟรีไหม?

[mini_bot.body.14]
KO: SHARE잔액
TH: ยอดคงเหลือ SHARE

[mini_bot.body.15]
KO: VALUE잔액
TH: ยอดคงเหลือ VALUE

[mini_bot.body.16]
KO: 등급
TH: ระดับ

[mini_bot.body.17]
KO: 오늘기부기여
TH: ยอดสมทบการบริจาควันนี้

[mini_bot.body.18]
KO: 이 버전에서는 앱 안에서 결제하지 않아요.
TH: ในเวอร์ชันนี้จะไม่มีการชำระเงินภายในแอป

[mini_bot.body.19]
KO: 궁금한 걸 물어보세요
TH: ถามเรื่องที่สงสัยได้เลย

[mini_bot.body.2]
KO: 오늘 목표나 SHARE가 궁금하면 물어보세요
TH: ถามฉันเกี่ยวกับเป้าหมายของวันนี้หรือ SHARE ได้เลย

[mini_bot.body.3]
KO: 기록 지키기가 헷갈리면 제가 알려 드려요
TH: หากไม่แน่ใจเรื่องการรักษาบันทึก ฉันช่วยบอกให้ได้นะ

[mini_bot.body.4]
KO: 어떤 챌린지가 맞는지 모르겠으면 물어보세요
TH: หากไม่แน่ใจว่าชาเลนจ์ไหนเหมาะกับคุณ ถามฉันได้เลย

[mini_bot.body.5]
KO: 참가비와 순위별 상금이 궁금하면 눌러 보세요
TH: กดดูได้เลยหากสงสัยเกี่ยวกับค่าเข้าร่วมและเงินรางวัลตามอันดับ

[mini_bot.body.6]
KO: 초급은 무료인지도 알려 드려요
TH: ฉันบอกได้ด้วยนะว่าระดับเริ่มต้นฟรีหรือไม่

[mini_bot.body.7]
KO: 오늘 내 기부
TH: การบริจาคของฉันวันนี้

[mini_bot.body.8]
KO: 내 SHARE
TH: SHARE ของฉัน

[mini_bot.body.9]
KO: 내 등급
TH: ระดับของฉัน

[mini_bot.button]
KO: 멈추기
TH: หยุด

[mini_bot.button.2]
KO: 말하기
TH: พูด

[mini_bot.button.3]
KO: 보내기
TH: ส่ง

[mini_bot.hint]
KO: 한글로 말해 주세요
TH: พูดหรือพิมพ์คำถามได้เลย

[mini_bot.mini_bot_dock.accessibility]
KO: 달팽이봇
TH: บอทหอยทาก

[mini_bot.mini_bot_dock.body]
KO: 끌어서 옮길 수 있어요
TH: ลากเพื่อย้ายได้

[mini_bot.mini_bot_intent.body]
KO: 후원하기
TH: สนับสนุน

[mini_bot.mini_bot_intent.body.10]
KO: 다이아 교환
TH: แลกเปลี่ยน DIA

[mini_bot.mini_bot_intent.body.11]
KO: 스폰서
TH: สปอนเซอร์

[mini_bot.mini_bot_intent.body.12]
KO: 러너 후원
TH: สนับสนุนนักวิ่ง

[mini_bot.mini_bot_intent.body.13]
KO: 배틀패스
TH: แบทเทิลพาส

[mini_bot.mini_bot_intent.body.14]
KO: 저는 당신의 달리기 친구, 달팽이예요. 말로 물어보면 바로 도와드릴게요. 이동하거나 결제하기 전에는 꼭 확인받아요.
TH: ฉันคือหอยทาก เพื่อนวิ่งของคุณ ถามด้วยเสียงแล้วฉันจะช่วยทันที โดยจะขอการยืนยันก่อนย้ายหน้าจอหรือชำระเงินเสมอ

[mini_bot.mini_bot_intent.body.17]
KO: 유료 구독은 Coach+ 하나예요
TH: การสมัครสมาชิกแบบชำระเงินมีเพียง Coach+ เท่านั้น

[mini_bot.mini_bot_intent.body.19]
KO: 상점의 기부 버튼으로 직접 눌러 주세요.
TH: กรุณากดปุ่มบริจาคในร้านค้าด้วยตัวเอง

[mini_bot.mini_bot_intent.body.2]
KO: 구매하기
TH: ซื้อ

[mini_bot.mini_bot_intent.body.20]
KO: 초보 1km 챌린지로 이동할까요? 참가비는 $joinAmount예요. 참가하기를 눌러도 참가는 확정되지 않아요. 그 화면에서 직접 확인해 주세요.
TH: ไปยังชาเลนจ์มือใหม่ 1 กม. เลยไหม? ค่าเข้าร่วมคือ $joinAmount การกดเข้าร่วมจะยังไม่ยืนยันการเข้าร่วม กรุณาตรวจสอบโดยตรงที่หน้าจอดังกล่าว

[mini_bot.mini_bot_intent.body.21]
KO: 챌린지 로비로 이동할까요? 로비에서 참가할 대회를 고를 수 있어요.
TH: ไปยังล็อบบี้ชาเลนจ์เลยไหม? คุณสามารถเลือกการแข่งขันที่จะเข้าร่วมได้ที่ล็อบบี้

[mini_bot.mini_bot_intent.body.22]
KO: 운영자 상금 대회 참가비를 확인 중이에요. 대회 목록에서 서버 참가비를 확인해 주세요. 여기서는 참가하지 않아요.
TH: กำลังตรวจสอบค่าเข้าร่วมการแข่งขันเงินรางวัลของผู้จัด กรุณาตรวจสอบค่าเข้าร่วมจากเซิร์ฟเวอร์ในรายการแข่งขัน คุณจะไม่เข้าร่วมจากที่นี่

[mini_bot.mini_bot_intent.body.23]
KO: 초급
TH: ระดับต้น

[mini_bot.mini_bot_intent.body.24]
KO: 중급
TH: ระดับกลาง

[mini_bot.mini_bot_intent.body.25]
KO: 상급
TH: ระดับสูง

[mini_bot.mini_bot_intent.body.26]
KO: 하프
TH: ฮาล์ฟ

[mini_bot.mini_bot_intent.body.27]
KO: 운영자 상금 대회로 이동할까요? 참가비는 $costs예요.$free $week $claim 이동만 하고, 참가는 확정하지 않아요.
TH: ไปยังการแข่งขันเงินรางวัลของผู้จัดเลยไหม? ค่าเข้าร่วมคือ $costs$free $week $claim เป็นเพียงการเปลี่ยนหน้าจอ จะยังไม่ยืนยันการเข้าร่วม

[mini_bot.mini_bot_intent.body.28]
KO: 상점의 기록 심폐소생권으로 이동할까요? $itemAmount예요. 구매하기를 눌러도 결제하지 않아요. 상점 화면에서 직접 구매해 주세요.
TH: ไปยังตั๋วฟื้นฟูบันทึกในร้านค้าเลยไหม? ราคา $itemAmount การกดซื้อจะยังไม่มีการชำระเงิน กรุณาซื้อโดยตรงที่หน้าร้านค้า

[mini_bot.mini_bot_intent.body.3]
KO: 참가하기
TH: เข้าร่วม

[mini_bot.mini_bot_intent.body.30]
KO: 상점의 세이프 가드 칸에서 직접 구매해 주세요.
TH: กรุณาซื้อโดยตรงที่ช่องเซฟการ์ดในร้านค้า

[mini_bot.mini_bot_intent.body.31]
KO: 다이아 교환소로 이동할까요? $chargeAmount예요. 교환하기를 눌러도 여기서는 결제되지 않아요. 교환소에서 직접 바꿔 주세요.
TH: ไปยังจุดแลกเปลี่ยน DIA เลยไหม? ราคาคือ $chargeAmount การกดแลกเปลี่ยนจะไม่ตัดเงินที่นี่ กรุณาแลกเปลี่ยนโดยตรงที่จุดแลกเปลี่ยน

[mini_bot.mini_bot_intent.body.33]
KO: 그 화면의 후원 버튼으로 직접 확정해 주세요.
TH: กรุณายืนยันโดยตรงด้วยปุ่มสนับสนุนบนหน้าจอนั้น

[mini_bot.mini_bot_intent.body.34]
KO: 브랜드 스폰서 챌린지는 아직 준비 중이에요. 지금 진행 중인 스폰서 챌린지가 없어요. 열리면 챌린지 탭에서 알려 드릴게요.
TH: ชาเลนจ์สปอนเซอร์แบรนด์ยังอยู่ระหว่างการเตรียมการ ขณะนี้ยังไม่มีชาเลนจ์สปอนเซอร์ที่กำลังดำเนินอยู่ หากเปิดแล้วจะแจ้งให้ทราบในแท็บชาเลนจ์

[mini_bot.mini_bot_intent.body.35]
KO: 구독 관리 화면으로 이동할까요? $subscriptionAmount. 이동만 하고, 구독이나 결제는 바꾸지 않아요.
TH: ไปยังหน้าจัดการการสมัครสมาชิกเลยไหม? $subscriptionAmount เป็นเพียงการเปลี่ยนหน้าจอ จะไม่เปลี่ยนแปลงการสมัครสมาชิกหรือการชำระเงิน

[mini_bot.mini_bot_intent.body.36]
KO: Coach+ 안내를 열까요? 심박·상황에 맞춘 심층 코칭이에요. $coachPlusAmount. 이동만 하고, 여기서는 결제하지 않아요.
TH: เปิดคำแนะนำ Coach+ เลยไหม? การโค้ชเชิงลึกที่ปรับให้เหมาะกับอัตราการเต้นของหัวใจและสถานการณ์ $coachPlusAmount เป็นเพียงการเปลี่ยนหน้าจอ ไม่มีการชำระเงินที่นี่

[mini_bot.mini_bot_intent.body.37]
KO: 배틀런 패스 화면으로 이동할까요? $battlePassAmount. 여기서는 패스를 구매하지 않아요. 보상 화면만 열어요.
TH: ไปยังหน้า Battle Run pass เลยไหม? $battlePassAmount จะไม่ซื้อพาสที่นี่ เพียงเปิดหน้าจอรางวัลเท่านั้น

[mini_bot.mini_bot_intent.body.38]
KO: 알겠어요. 이동은 취소했어요.
TH: รับทราบ ยกเลิกการเปลี่ยนหน้าแล้ว

[mini_bot.mini_bot_intent.body.4]
KO: 이동하기
TH: ไปที่
