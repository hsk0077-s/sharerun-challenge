# 번역 검수 요청 — 쉐어런 (Thai) · 파트 2/7

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
[crew_manager.body.11]
KO: 부방장: ${subs.join(
TH: รองหัวหน้า: ${subs.join(

[crew_manager.body.12]
KO: 📢 전체 공지 푸시 (준비 중)
TH: 📢 การแจ้งเตือนประกาศทั้งหมด (กำลังเตรียมการ)

[crew_manager.body.13]
KO: 크루 이름
TH: ชื่อ crew

[crew_manager.body.14]
KO: 이름 변경 (첫 1회 무료)
TH: เปลี่ยนชื่อ (ฟรีครั้งแรก)

[crew_manager.body.15]
KO: 이름 변경 (${mine.crew.renameCostDia} DIA)
TH: เปลี่ยนชื่อ (${mine.crew.renameCostDia} DIA)

[crew_manager.body.16]
KO: 보관함 아이템
TH: ไอเทมในกล่องเก็บของ

[crew_manager.body.17]
KO: 🎁 크루원 전체에게 심폐소생권·세이프가드 선물 (1인당 $_giftDiaPerMember DIA)
TH: 🎁 มอบตั๋วฟื้นคืนชีพและเซฟการ์ดให้สมาชิกทุกคน ($_giftDiaPerMember DIA ต่อคน)

[crew_manager.body.18]
KO: 내가 아닌 크루원의 보관함에 하나씩 들어가요. 한 명에게만 줄 때는 아래 팀원 목록에서 골라요.
TH: จะส่งเข้ากล่องเก็บของของสมาชิกทุกคนยกเว้นคุณอย่างละหนึ่งชิ้น หากต้องการมอบให้เพียงคนเดียว กรุณาเลือกจากรายชื่อสมาชิกด้านล่าง

[crew_manager.body.19]
KO: 🚩 크루 응원 깃발 (15 DIA, 하루 1회)
TH: 🚩 ธงเชียร์ crew (15 DIA, วันละ 1 ครั้ง)

[crew_manager.body.2]
KO: 이름 바꾸기
TH: เปลี่ยนชื่อ

[crew_manager.body.20]
KO: 🛡️ 크루 대항전 예치금 대납 (준비 중)
TH: 🛡️ ชำระเงินมัดจำการแข่ง crew แทน (เร็ว ๆ นี้)

[crew_manager.body.21]
KO: 🎉 크루 전용 챌린지 패스 & 스킨 (준비 중)
TH: 🎉 พาสความท้าทายและสกินเฉพาะ crew (เร็ว ๆ นี้)

[crew_manager.body.22]
KO: 소속 팀원 관리 ($count / $limit명)
TH: จัดการสมาชิก ($count / $limit คน)

[crew_manager.body.23]
KO: 소속 팀원이 없습니다.
TH: ไม่มีสมาชิก

[crew_manager.body.24]
KO: $name (방장)
TH: $name (หัวหน้า)

[crew_manager.body.25]
KO: $name (부방장)
TH: $name (รองหัวหน้า)

[crew_manager.body.3]
KO: "$next"(으)로 바꾸면 $cost DIA가 들어요. 보너스 DIA를 먼저 써요.
TH: เปลี่ยนเป็น "$next" ใช้ $cost DIA ระบบจะใช้ DIA โบนัสก่อน

[crew_manager.body.4]
KO: $cost DIA 내고 바꾸기
TH: จ่าย $cost DIA เพื่อเปลี่ยน

[crew_manager.body.5]
KO: $cost DIA 내고 보내기
TH: จ่าย $cost DIA แล้วส่ง

[crew_manager.body.6]
KO: +${step.add}명 인원 한도 확장하기 (${step.costDia} DIA)
TH: ขยายขีดจำกัดสมาชิก +${step.add} คน (${step.costDia} DIA)

[crew_manager.body.7]
KO: $base · ${crew.maxMembers}명을 모두 채우면 열려요
TH: $base · ปลดล็อกเมื่อครบ ${crew.maxMembers} คน

[crew_manager.body.8]
KO: 크루 정보를 불러오지 못했어요. 크루에 들어 있는지, 네트워크가 연결됐는지 확인해 주세요.
TH: ไม่สามารถโหลดข้อมูล crew ได้ กรุณาตรวจสอบว่าคุณอยู่ใน crew หรือไม่ และการเชื่อมต่อเครือข่ายเป็นปกติหรือไม่

[crew_manager.body.9]
KO: 크루장과 부크루장만 관리할 수 있어요.
TH: เฉพาะหัวหน้าและรองหัวหน้า crew เท่านั้นที่จัดการได้

[crew_manager.button]
KO: 이름을 바꿀 때마다 $cost DIA가 들어요.
TH: เปลี่ยนชื่อใช้ $cost DIA

[crew_manager.button.2]
KO: 저장
TH: บันทึก

[crew_manager.button.3]
KO: 선물
TH: ส่งของขวัญ

[crew_manager.button.4]
KO: 부방장 해제
TH: ปลดรองหัวหน้า

[crew_manager.dialog]
KO: 크루 이름 변경
TH: เปลี่ยนชื่อ crew

[crew_manager.toast]
KO: 아직 열리지 않았어요. 준비되면 알려드릴게요.
TH: ยังไม่เปิดให้บริการ จะแจ้งให้ทราบเมื่อพร้อม

[crew_manager.toast.10]
KO: ${step.costDia} DIA 내고 늘리기
TH: จ่าย ${step.costDia} DIA เพื่อเพิ่ม

[crew_manager.toast.11]
KO: 인원 한도가 ${result.maxMembers}명이 됐어요.
TH: ขีดจำกัดสมาชิกเปลี่ยนเป็น ${result.maxMembers} คนแล้ว

[crew_manager.toast.12]
KO: 크루장만 늘릴 수 있어요.
TH: หัวหน้า crew เท่านั้นที่ขยายได้

[crew_manager.toast.13]
KO: 자리를 모두 채워야 하거나 이미 최대예요.
TH: ต้องมีสมาชิกเต็มจำนวนก่อนหรือถึงจำนวนสูงสุดแล้ว

[crew_manager.toast.14]
KO: 인원 한도를 늘리지 못했어요. 잠시 뒤 다시 해 주세요.
TH: ไม่สามารถเพิ่มขีดจำกัดจำนวนสมาชิกได้ โปรดลองอีกครั้งในภายหลัง

[crew_manager.toast.15]
KO: 크루 응원 깃발을 걸었습니다. 오늘 대회 SHARE 보상이 10% 늘어납니다.
TH: แขวนธงเชียร์ crew แล้ว รางวัล SHARE ของการแข่งขันวันนี้เพิ่มขึ้น 10%

[crew_manager.toast.16]
KO: 응원 깃발을 걸지 못했습니다.
TH: ไม่สามารถแขวนธงเชียร์ได้

[crew_manager.toast.17]
KO: 선물을 받을 크루원이 없어요.
TH: ไม่มีสมาชิก crew ที่จะรับของขวัญ

[crew_manager.toast.18]
KO: 크루원 $count명 모두
TH: สมาชิก crew ทั้งหมด $count คน

[crew_manager.toast.19]
KO: ${member.nickname}님
TH: ${member.nickname}

[crew_manager.toast.2]
KO: 크루 이름을 "$next"(으)로 바꿨어요.
TH: เปลี่ยนชื่อ crew เป็น "$next" แล้ว

[crew_manager.toast.20]
KO: 심폐소생권·세이프가드 선물
TH: มอบตั๋วกู้ชีพและเซฟการ์ดเป็นของขวัญ

[crew_manager.toast.21]
KO: $who에게 심폐소생권과 세이프가드를 하나씩 보내요. 한 명당 $_giftDiaPerMember DIA, 모두 $cost DIA가 들고 보너스 DIA를 먼저 써요.
TH: ส่งตั๋วกู้ชีพและเซฟการ์ดอย่างละ 1 ให้ $who คนละ $_giftDiaPerMember DIA รวม $cost DIA โดยใช้ DIA โบนัสก่อน

[crew_manager.toast.22]
KO: ${result.recipients}명의 보관함에 선물을 넣었어요. (−$cost DIA)
TH: ส่งของขวัญไปยังกล่องเก็บของสมาชิก ${result.recipients} คนแล้ว (−$cost DIA)

[crew_manager.toast.23]
KO: 크루장만 선물할 수 있어요.
TH: เฉพาะหัวหน้า crew เท่านั้นที่ส่งของขวัญได้

[crew_manager.toast.24]
KO: 그 크루원을 찾지 못했어요.
TH: ไม่พบสมาชิก crew ดังกล่าว

[crew_manager.toast.25]
KO: 선물을 보내지 못했어요. 잠시 뒤 다시 해 주세요.
TH: ส่งของขวัญไม่สำเร็จ กรุณาลองใหม่อีกครั้งในภายหลัง

[crew_manager.toast.26]
KO: ${member.nickname}님을 부방장으로 임명했어요.
TH: แต่งตั้ง ${member.nickname} เป็นรองหัวหน้าแล้ว

[crew_manager.toast.27]
KO: ${member.nickname}님을 크루원으로 돌렸어요.
TH: เปลี่ยน ${member.nickname} กลับเป็นสมาชิก crew แล้ว

[crew_manager.toast.28]
KO: 바꾸지 못했어요. 잠시 뒤 다시 해 주세요.
TH: ไม่สามารถเปลี่ยนแปลงได้ กรุณาลองใหม่อีกครั้งในภายหลัง

[crew_manager.toast.29]
KO: 크루원 내보내기
TH: นำสมาชิก crew ออก

[crew_manager.toast.3]
KO: DIA가 모자라거나 쓸 수 없는 이름이에요.
TH: DIA ไม่พอหรือไม่สามารถใช้ชื่อนี้ได้

[crew_manager.toast.30]
KO: ${member.nickname}님을 크루에서 내보낼까요?
TH: ต้องการนำ ${member.nickname} ออกจาก crew หรือไม่?

[crew_manager.toast.31]
KO: 내보내기
TH: นำออก

[crew_manager.toast.32]
KO: ${member.nickname}님을 내보냈어요.
TH: นำ ${member.nickname} ออกแล้ว

[crew_manager.toast.33]
KO: 내보내지 못했어요. 잠시 뒤 다시 해 주세요.
TH: นำออกไม่สำเร็จ กรุณาลองใหม่อีกครั้งในภายหลัง

[crew_manager.toast.34]
KO: 인원 한도 최대 (${crew.maxMembers}명)
TH: จำนวนสมาชิกสูงสุดแล้ว (${crew.maxMembers} คน)

[crew_manager.toast.4]
KO: 크루장만 이름을 바꿀 수 있어요.
TH: หัวหน้า crew เท่านั้นที่เปลี่ยนชื่อได้

[crew_manager.toast.5]
KO: 이름을 바꾸지 못했어요. 잠시 뒤 다시 해 주세요.
TH: ไม่สามารถเปลี่ยนชื่อได้ โปรดลองอีกครั้งในภายหลัง

[crew_manager.toast.6]
KO: 인원 한도가 최대(${mine.crew.maxMembers}명)예요.
TH: สมาชิกถึงขีดจำกัดสูงสุดแล้ว (${mine.crew.maxMembers} คน)

[crew_manager.toast.7]
KO: 자리를 모두 채우면 더 늘릴 수 있어요. (${mine.crew.maxMembers}명)
TH: เพิ่มจำนวนได้เมื่อสมาชิกเต็ม (${mine.crew.maxMembers} คน)

[crew_manager.toast.8]
KO: 인원 한도 확장
TH: เพิ่มขีดจำกัดจำนวนสมาชิก

[crew_manager.toast.9]
KO: 크루 인원 한도를 ${step.add}명 늘려요. ${step.costDia} DIA가 들고, 보너스 DIA를 먼저 써요.
TH: เพิ่มขีดจำกัด crew ${step.add} คน ใช้ ${step.costDia} DIA โดยใช้ DIA โบนัสก่อน

[crew_ranking_model.body]
KO: 쉐어런 크루
TH: ShareRun Crew

[crew_room.body]
KO: 크루에 들어 있어야 크루 룸을 볼 수 있어요. 크루에 들어갔는지, 네트워크가 연결됐는지 확인해 주세요.
TH: คุณต้องอยู่ใน crew จึงจะดูห้อง crew ได้ โปรดตรวจสอบว่าคุณได้เข้าร่วม crew และเชื่อมต่อเครือข่ายแล้วหรือไม่

[crew_room.body.2]
KO: } · 내 역할 ${CrewRoomScreen._roleLabel(mine.role)}
TH: } · บทบาทของฉัน ${CrewRoomScreen._roleLabel(mine.role)}

[crew_room.body.3]
KO: 크루 대항전은 아직 열리지 않았어요. 열리면 여기서 이번 주 진행을 볼 수 있어요.
TH: การแข่งขันระหว่าง crew ยังไม่เปิด เมื่อเปิดแล้ว คุณสามารถดูความคืบหน้าของสัปดาห์นี้ได้ที่นี่

[crew_room.button]
KO: 크루 룸
TH: ห้อง crew

[device_connection.body]
KO: (Apple Watch 전 기종 지원)
TH: (รองรับ Apple Watch ทุกรุ่น)

[device_connection.body.2]
KO: Health Connect 설치 화면을 열었어요. 설치 후 다시 연결해 주세요.
TH: เปิดหน้าการติดตั้ง Health Connect แล้ว โปรดเชื่อมต่ออีกครั้งหลังการติดตั้ง

[device_connection.body.3]
KO: ♥ 연결됨
TH: ♥ เชื่อมต่อแล้ว

[device_connection.body.4]
KO: 미연결
TH: ยังไม่เชื่อมต่อ

[device_connection.body.5]
KO: 연결된 센서: ${snap.deviceName}
TH: เซนเซอร์ที่เชื่อมต่อ: ${snap.deviceName}

[device_connection.button]
KO: 워치 앱 연결 코드 · 연결된 워치
TH: รหัสเชื่อมต่อ · นาฬิกาที่เชื่อมต่อ

[device_connection.button.2]
KO: 권한 설정 필요
TH: ต้องตั้งค่าสิทธิ์

[device_connection.button.3]
KO: 정확한 측정을 위해 권한 설정이 필요합니다.
TH: ต้องตั้งค่าสิทธิ์เพื่อการวัดค่าที่แม่นยำ

[device_connection.dialog]
KO: 연동 불가
TH: ไม่สามารถเชื่อมต่อได้

[device_connection.dialog.2]
KO: 고객님의 스마트워치 OS 버전이 낮거나 호환되지 않아 연동할 수 없습니다. 워치를 최신 버전(watchOS 8+, Wear OS 3.0+)으로 업데이트해 주세요.
TH: เวอร์ชันระบบปฏิบัติการของสมาร์ทวอทช์ของคุณเก่าเกินไปหรือไม่รองรับ โปรดอัปเดตนาฬิกาเป็นเวอร์ชันล่าสุด (watchOS 8+, Wear OS 3.0+)

[device_connection.toast]
KO: 등급 배정 화면 이동 실패: $e
TH: นำทางไปยังหน้าจัดอันดับไม่สำเร็จ: $e

[device_connection.toast.2]
KO: 건너뛰기 실패: $e
TH: ข้ามไม่สำเร็จ: $e

[device_connection.toast.3]
KO: ${watchType.displayLabel} 연동이 완료되었습니다!
TH: เชื่อมต่อ ${watchType.displayLabel} เรียบร้อยแล้ว!

[device_connection.toast.4]
KO: Health Connect를 열 수 없어요. Play 스토어에서 설치해 주세요.
TH: ไม่สามารถเปิด Health Connect ได้ โปรดติดตั้งจาก Play Store

[device_connection.toast.5]
KO: 권한이 거부되었습니다.
TH: การอนุญาตถูกปฏิเสธ

[device_connection.toast.6]
KO: Google Health Connect 연동이 완료되었습니다!
TH: เชื่อมต่อ Google Health Connect เรียบร้อยแล้ว!

[device_connection.toast.7]
KO: 기기가 호환되지 않거나 연동 중 오류가 발생했습니다.
TH: อุปกรณ์ไม่รองรับหรือเกิดข้อผิดพลาดระหว่างการเชื่อมต่อ

[device_connection.toast.8]
KO: Garmin 연동 화면을 열 수 없습니다: $e
TH: ไม่สามารถเปิดหน้าเชื่อมต่อ Garmin ได้: $e

[device_connection.toast.9]
KO: ${watchType.displayLabel} 연동 설정이 저장되었습니다.
TH: บันทึกการตั้งค่าเชื่อมต่อ ${watchType.displayLabel} เรียบร้อยแล้ว

[app.bleHrConnectButton]
KO: 연결
TH: เชื่อมต่อ

[app.bleHrDisconnectButton]
KO: 연결 해제
TH: ยกเลิกการเชื่อมต่อ

[app.bleHrGuideItems]
KO: 가민(Garmin)
TH: Garmin

[app.bleHrGuideItems.2]
KO: 시계 설정 → 센서 및 액세서리 → 손목 심박수 → "심박수 전송" 켜기
TH: การตั้งค่านาฬิกา → เซนเซอร์และอุปกรณ์เสริม → อัตราการเต้นของหัวใจที่ข้อมือ → เปิด "แพร่ภาพอัตราการเต้นของหัวใจ"

[app.bleHrGuideItems.3]
KO: 샤오미 · 어메이즈핏
TH: Xiaomi · Amazfit

[app.bleHrGuideItems.4]
KO: 운동·심박수 설정 → "심박수 공유/전송" 켜기
TH: การตั้งค่าการออกกำลังกายและอัตราการเต้นของหัวใจ → เปิด "แชร์/แพร่ภาพอัตราการเต้นของหัวใจ"

[app.bleHrGuideItems.5]
KO: 가슴·암밴드 센서
TH: เซนเซอร์รัดอกและสายรัดแขน

[app.bleHrGuideItems.6]
KO: 착용한 뒤 아래 [센서 찾기] 누르기 (Polar, Wahoo, Coospo, Magene)
TH: สวมใส่แล้วแตะ [ค้นหาเซนเซอร์] ด้านล่าง (Polar, Wahoo, Coospo, Magene)

[app.bleHrGuideItems.7]
KO: 갤럭시 워치 · 애플워치
TH: Galaxy Watch · Apple Watch

[app.bleHrGuideItems.8]
KO: 이 방식이 아니에요. 위의 Health Connect / Apple 건강으로 연결하세요
TH: ไม่ใช่วิธีนี้ โปรดเชื่อมต่อผ่าน Health Connect / Apple Health ด้านบน

[app.bleHrGuideTitle]
KO: 내 기기별로 이렇게 하세요
TH: วิธีตั้งค่าตามอุปกรณ์ของคุณ

[app.bleHrScanningLabel]
KO: 근처 심박 센서 찾는 중...
TH: กำลังค้นหาเซนเซอร์วัดอัตราการเต้นของหัวใจในบริเวณใกล้เคียง...

[app.bleHrSectionSubtitle]
KO: Health Connect 지연 없이 달리는 동안 실시간 심박수(0x180D)를 바로 받습니다.
TH: รับอัตราการเต้นของหัวใจแบบเรียลไทม์ (0x180D) ได้โดยตรงขณะวิ่ง โดยไม่มีความล่าช้าจาก Health Connect

[app.bleHrStopScanButton]
KO: 스캔 중지
TH: หยุดสแกน

[app.deviceConnectionConnect]
KO: 기기 연결
TH: เชื่อมต่ออุปกรณ์

[app.deviceConnectionExternalTitle]
KO: 외부 전문 기기 연동
TH: การเชื่อมต่ออุปกรณ์ภายนอกระดับโปร

[app.deviceConnectionGoogleCaption]
KO: (갤럭시 워치, 샤오미 미밴드, 어메이즈핏, 가민, 핏빗 등)
TH: (Galaxy Watch, Xiaomi Mi Band, Amazfit, Garmin, Fitbit ฯลฯ)

[app.deviceConnectionNativeTitle]
KO: 네이티브 헬스 연동
TH: การเชื่อมต่อสุขภาพแบบเนทีฟ

[app.deviceConnectionNone]
KO: 연결된 기기가 없습니다
TH: ไม่มีอุปกรณ์ที่เชื่อมต่อ

[app.deviceConnectionSingleActiveNote]
KO: 쉐어런은 동시에 하나의 운동 기기만 활성 연결 상태로 유지합니다.
TH: ShareRun จะคงสถานะการเชื่อมต่อที่ใช้งานอยู่กับอุปกรณ์ออกกำลังกายเพียงเครื่องเดียวในเวลาเดียวกัน

[app.deviceConnectionStatusTitle]
KO: 현재 연결된 기기
TH: อุปกรณ์ที่เชื่อมต่ออยู่ในปัจจุบัน

[app.healthConnectNoSamplesTip]
KO: 권한은 연결되었어요. 밴드/워치 앱 안에서 Health Connect 데이터 쓰기 스위치가 켜져 있는지 확인해 주세요. 스마트밴드 기록은 밴드 앱 동기화 후 반영됩니다.
TH: เชื่อมต่อสิทธิ์เรียบร้อยแล้ว โปรดตรวจสอบว่าเปิดสวิตช์เขียนข้อมูล Health Connect ในแอปสมาร์ตแบนด์/นาฬิกาแล้วหรือไม่ บันทึกของสมาร์ตแบนด์จะแสดงหลังจากซิงค์กับแอปของอุปกรณ์แล้ว

[dia_pack_store.body]
KO: $price원 · ${pack.bonusLabel}
TH: $price วอน · ${pack.bonusLabel}

[dia_pack_store.body.2]
KO: 기본 ${pack.baseDia} DIA · ${pack.productId}
TH: พื้นฐาน ${pack.baseDia} DIA · ${pack.productId}

[dia_pack_store.title]
KO: DIA 팩
TH: แพ็ก DIA

[diamond_box_model.body]
KO: 다이아 상자
TH: กล่อง DIA

[donation_settlement.body]
KO: 운영자가 자기 돈으로 검증 1km당 100원(KRW)을 월 예산 안에서 기부할 예정입니다. 이용자의 기부금이 아니며 세금 공제 영수증이 발급되지 않습니다.
TH: ผู้ดำเนินงานวางแผนบริจาค 100 วอน (KRW) ต่อ 1 กม. ที่ผ่านการตรวจสอบด้วยเงินของตนเองภายในงบประมาณประจำเดือน ไม่ใช่เงินบริจาคของผู้ใช้ และไม่มีใบเสร็จลดหย่อนภาษี

[economy_constants.body]
KO: 구매 후 7일 이내, 100% 미사용 분에 한해 환불 가능
TH: สามารถขอเงินคืนได้ภายใน 7 วันหลังจากการซื้อ เฉพาะส่วนที่ยังไม่ได้ใช้งาน 100% เท่านั้น

[email_verification_guard.button]
KO: 결제·대회 참가 전에 이메일 인증을 완료해 주세요. 상단 배너에서 인증 메일을 재발송할 수 있습니다.
TH: โปรดยืนยันอีเมลให้เสร็จสิ้นก่อนชำระเงินหรือเข้าร่วมการแข่งขัน คุณสามารถส่งอีเมลยืนยันอีกครั้งได้จากแบนเนอร์ด้านบน

[email_verification_guard.dialog]
KO: 이메일 인증 필요
TH: ต้องยืนยันอีเมล

[external_oauth_webview.body]
KO: 이메일 아이디를 입력해 주세요.
TH: กรุณากรอกอีเมลไอดี

[external_oauth_webview.body.2]
KO: 올바른 이메일 형식이 아닙니다.
TH: รูปแบบอีเมลไม่ถูกต้อง

[external_oauth_webview.body.3]
KO: 비밀번호를 입력해 주세요.
TH: กรุณากรอกรหัสผ่าน

[external_oauth_webview.body.4]
KO: 비밀번호가 너무 짧습니다.
TH: รหัสผ่านสั้นเกินไป

[external_oauth_webview.toast]
KO: 연동 중 오류가 발생했습니다. 앱으로 돌아가 다시 시도해 주세요.
TH: เกิดข้อผิดพลาดขณะเชื่อมต่อ กรุณากลับไปที่แอปแล้วลองใหม่อีกครั้ง

[app.externalPaymentNoticeHighlight]
KO: 실제 야외 물리적 활동(오프라인 러닝)
TH: กิจกรรมทางกายภาพกลางแจ้งจริง (การวิ่งออฟไลน์)

[app.externalPaymentNoticePrefix]
KO: 본 결제는
TH: การชำระเงินนี้เป็นการซื้อบัตรสำหรับ

[app.externalPaymentNoticeSuffix]
KO: 참여를 위한 참가권 구매입니다.
TH: เพื่อใช้สิทธิ์เข้าร่วม

[app.externalPaymentRefundNote]
KO: * 미사용 쿠폰에 한해 언제든 100% 수수료 없이 환불 가능합니다.
TH: * เฉพาะคูปองที่ยังไม่ได้ใช้ สามารถขอคืนเงินได้ 100% โดยไม่มีค่าธรรมเนียมตลอดเวลา

[app.externalPaymentSecurePaySuffix]
KO: 원 안전 결제하기
TH: วอน ชำระเงินอย่างปลอดภัย

[firebase_auth_messages.body]
KO: 로그인이 취소되었습니다.
TH: การเข้าสู่ระบบถูกยกเลิก

[firebase_auth_messages.body.10]
KO: 다른 로그인 방식으로 가입된 이메일입니다.
TH: อีเมลนี้ลงทะเบียนด้วยวิธีการเข้าสู่ระบบอื่นแล้ว

[firebase_auth_messages.body.11]
KO: 보안을 위해 다시 로그인한 뒤 계정 삭제를 시도해 주세요.
TH: เพื่อความปลอดภัย กรุณาลองเข้าสู่ระบบอีกครั้งก่อนลบบัญชี

[firebase_auth_messages.body.12]
KO: 로그인에 실패했습니다.
TH: เข้าสู่ระบบไม่สำเร็จ

[firebase_auth_messages.body.2]
KO: 이메일 형식이 올바르지 않습니다.
TH: รูปแบบอีเมลไม่ถูกต้อง

[firebase_auth_messages.body.3]
KO: 비활성화된 계정입니다. 고객센터에 문의해 주세요.
TH: บัญชีนี้ถูกระงับการใช้งาน กรุณาติดต่อฝ่ายบริการลูกค้า

[firebase_auth_messages.body.4]
KO: 이메일 또는 비밀번호를 확인해 주세요.
TH: กรุณาตรวจสอบอีเมลหรือรหัสผ่านของคุณ

[firebase_auth_messages.body.5]
KO: 이미 사용 중인 이메일입니다.
TH: อีเมลนี้ถูกใช้งานแล้ว

[firebase_auth_messages.body.6]
KO: 비밀번호는 6자 이상이어야 합니다.
TH: รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร

[firebase_auth_messages.body.7]
KO: 요청이 너무 많습니다. 잠시 후 다시 시도해 주세요.
TH: คำขอมากเกินไป กรุณาลองใหม่อีกครั้งในภายหลัง

[firebase_auth_messages.body.8]
KO: 네트워크 연결을 확인해 주세요.
TH: กรุณาตรวจสอบการเชื่อมต่อเครือข่ายของคุณ

[firebase_auth_messages.body.9]
KO: Firebase 콘솔에서 익명(게스트) 로그인을 활성화해 주세요.
TH: กรุณาเปิดใช้งานการเข้าสู่ระบบแบบไม่ระบุตัวตน (แขก) ในคอนโซล Firebase

[app.garminAuthSubtitle]
KO: 안전한 OAuth 2.0 공식 로그인 페이지입니다.
TH: นี่คือหน้าเข้าสู่ระบบอย่างเป็นทางการที่ปลอดภัยด้วย OAuth 2.0

[app.garminAuthTitle]
KO: Garmin Connect 연동
TH: เชื่อมต่อ Garmin Connect

[app.garminCancelAndReturn]
KO: 연동을 취소하고 앱으로 돌아가기
TH: ยกเลิกการเชื่อมต่อและกลับสู่แอป

[app.garminEmailHint]
KO: 이메일 아이디
TH: อีเมล

[app.garminPasswordHint]
KO: 비밀번호
TH: รหัสผ่าน

[app.garminSignInAuthorize]
KO: 로그인하고 권한 허용
TH: เข้าสู่ระบบและอนุญาตสิทธิ์

[app.garminSignInAuthorizeKo]
KO: (로그인 및 권한 허용)
TH: (เข้าสู่ระบบและอนุญาตสิทธิ์)

[app.hallOfFameDonateCta]
KO: 나도 기부하고 명예의 전당 오르기 💎
TH: ร่วมบริจาคและขึ้นสู่หอเกียรติยศ 💎

[app.hallOfFameDonateHistoryTitle]
KO: 명예의 전당 기부 완료 🕊️
TH: การบริจาคเข้าหอเกียรติยศเสร็จสมบูรณ์ 🕊️

[app.hallOfFameLeaderDonation]
KO: 누적 기부: 5,000,000 VALUE
TH: ยอดบริจาคสะสม: 5,000,000 VALUE

[app.hallOfFameLeaderName]
KO: 서울 나이트 러너스 방장님
TH: หัวหน้ากลุ่ม Seoul Night Runners

[app.hallOfFameLeaderTitle]
KO: 👑 이달의 소셜 임팩트 리더
TH: 👑 ผู้นำการสร้างผลกระทบต่อสังคมประจำเดือนนี้

[app.hallOfFameRank2Badge]
KO: 🔥 불꽃 SBT 뱃지
TH: 🔥 ตราสัญลักษณ์ SBT เปลวเพลิง

[app.hallOfFameRank2Label]
KO: 2등
TH: อันดับ 2

[app.hallOfFameRank2Subtitle]
KO: 연속 50일 완주자
TH: วิ่งจบครบ 50 วันติดต่อกัน

[app.hallOfFameRank3Badge]
KO: 🛡️ 방패 SBT 뱃지
TH: 🛡️ ตราสัญลักษณ์ SBT โล่

[app.hallOfFameRank3Label]
KO: 3등
TH: อันดับ 3

[app.hallOfFameRank3Subtitle]
KO: 최다 크루원 후원자
TH: ผู้สนับสนุนสมาชิก crew มากที่สุด

[app.hallOfFameTitle]
KO: 명예의 전당 (Hall of Fame)
TH: หอเกียรติยศ (Hall of Fame)

[app.runningCrewHallOfFame]
KO: 👑 명예의 전당
TH: 👑 หอเกียรติยศ

[app.storeDonateHistoryTitle]
KO: 기부 펀딩 참여 🕊️
TH: เข้าร่วมการระดมทุนบริจาค 🕊️

[hall_of_fame.body]
KO: 서버 원장에서 $_donateValue VALUE를 기부했습니다.
TH: บริจาค $_donateValue VALUE จากสมุดบัญชีแยกประเภทเซิร์ฟเวอร์เรียบร้อยแล้ว

[hall_of_fame.body.2]
KO: 서버 원장에서 $_donateValue VALUE를 기부했습니다. 잔액 $left
TH: บริจาค $_donateValue VALUE จากสมุดบัญชีแยกประเภทเซิร์ฟเวอร์เรียบร้อยแล้ว ยอดคงเหลือ $left

[hall_of_fame.body.3]
KO: VALUE가 부족합니다.
TH: VALUE ไม่เพียงพอ

[hall_of_fame.body.4]
KO: 기부에 실패했습니다.
TH: การบริจาคล้มเหลว

[hall_of_fame.body.5]
KO: 아직 기록이 없어요
TH: ยังไม่มีประวัติ

[health_data_consent.body]
KO: 개인정보보호법에 따라 건강·생체 데이터는 일반 약관과 분리된 명시적 Opt-in이 필요합니다.
TH: ตามกฎหมายคุ้มครองข้อมูลส่วนบุคคล ข้อมูลสุขภาพและไบโอเมตริกต้องได้รับความยินยอม (Opt-in) แยกจากข้อตกลงทั่วไป

[health_data_consent.button]
KO: 권한 요청 중...
TH: กำลังขอสิทธิ์...

[health_data_consent.button.2]
KO: 동의하고 워치 연동 계속
TH: ยอมรับและเชื่อมต่อนาฬิกาต่อ

[health_data_consent.button.3]
KO: 나중에 하기
TH: ไว้ทีหลัง

[health_data_consent.title]
KO: 건강정보 동의
TH: ความยินยอมข้อมูลสุขภาพ

[health_data_consent.title.2]
KO: 스마트워치 연동 전 동의
TH: ยินยอมก่อนเชื่อมต่อสมาร์ทวอทช์

[home.home_wallet.body]
KO: $completedCount/$total회 완료 >
TH: เสร็จสิ้น $completedCount/$total ครั้ง >

[iap.coach_plus_product.body]
KO: 6,900원
TH: 6,900 วอน

[iap.coach_plus_product.body.2]
KO: 59,000원
TH: 59,000 วอน

[iap.coach_plus_upsell.body]
KO: 무료
TH: ฟรี

[iap.coach_plus_upsell.body.2]
KO: 기본 러닝 안내
TH: คำแนะนำการวิ่งขั้นพื้นฐาน

[iap.coach_plus_upsell.body.3]
KO: Coach+ 이용 중
TH: กำลังใช้งาน Coach+

[iap.coach_plus_upsell.button]
KO: 구매 복원
TH: กู้คืนการซื้อ

[iap.dia_pack_product.body]
KO: 보너스 없음
TH: ไม่มีโบนัส

[iap.dia_pack_product.body.2]
KO: 보너스 $bonusDia DIA
TH: โบนัส $bonusDia DIA

[iap.iap_providers.body]
KO: SHARE 충전 💳
TH: เติม SHARE 💳

[iap.iap_purchase_controller.body]
KO: Google Play 결제 서비스를 사용할 수 없습니다. 잠시 후 다시 시도해 주세요.
TH: ไม่สามารถใช้บริการชำระเงินของ Google Play ได้ โปรดลองอีกครั้งในภายหลัง

[iap.iap_purchase_controller.body.10]
KO: 결제 처리 중 오류가 발생했습니다.
TH: เกิดข้อผิดพลาดขณะดำเนินการชำระเงิน

[iap.iap_purchase_controller.body.11]
KO: Coach+ 결제가 진행 중입니다.
TH: กำลังดำเนินการชำระเงินสำหรับ Coach+

[iap.iap_purchase_controller.body.12]
KO: Coach+ 구독이 활성화되었습니다.
TH: เปิดใช้งานการสมัครสมาชิก Coach+ แล้ว

[iap.iap_purchase_controller.body.13]
KO: Coach+ 결제가 실패했습니다.
TH: การชำระเงินสำหรับ Coach+ ล้มเหลว

[iap.iap_purchase_controller.body.14]
KO: Coach+ 결제가 취소되었습니다.
TH: ยกเลิกการชำระเงินสำหรับ Coach+ แล้ว

[iap.iap_purchase_controller.body.15]
KO: 로그인 후 Google Play 결제를 진행해 주세요.
TH: โปรดเข้าสู่ระบบก่อนดำเนินการชำระเงินผ่าน Google Play

[iap.iap_purchase_controller.body.16]
KO: 영수증을 보안 검증 중입니다. SHARE는 검증 완료 후 지급됩니다.
TH: กำลังตรวจสอบความปลอดภัยของใบเสร็จ SHARE จะถูกมอบให้หลังจากการตรวจสอบเสร็จสมบูรณ์

[iap.iap_purchase_controller.body.17]
KO: 검증이 완료되어 $shareAmount SHARE가 지급되었습니다.
TH: การตรวจสอบเสร็จสมบูรณ์ และมอบ $shareAmount SHARE แล้ว

[iap.iap_purchase_controller.body.18]
KO: Google 검증이 완료되어 SHARE가 지갑에 반영됩니다.
TH: การตรวจสอบของ Google เสร็จสมบูรณ์แล้ว และ SHARE จะแสดงในกระเป๋าเงินของคุณ

[iap.iap_purchase_controller.body.19]
KO: 영수증 검증이 거절되었습니다. 고객센터로 문의해 주세요.
TH: การตรวจสอบใบเสร็จถูกปฏิเสธ โปรดติดต่อฝ่ายบริการลูกค้า

[iap.iap_purchase_controller.body.2]
KO: 상품(${plan.productId})을 찾지 못했습니다. Play Console / App Store Connect 등록을 확인해 주세요.
TH: ไม่พบสินค้า (${plan.productId}) โปรดตรวจสอบการลงทะเบียนใน Play Console / App Store Connect

[iap.iap_purchase_controller.body.20]
KO: 검증 응답이 지연되고 있습니다. 지갑 잔액을 잠시 후 다시 확인해 주세요.
TH: การตอบกลับการตรวจสอบล่าช้า โปรดตรวจสอบยอดเงินในกระเป๋าของคุณอีกครั้งในอีกสักครู่

[iap.iap_purchase_controller.body.21]
KO: 결제 스트림이 일시 중단되었습니다. 연결을 확인한 뒤 다시 시도해 주세요.
TH: สตรีมการชำระเงินหยุดชะงักชั่วคราว โปรดตรวจสอบการเชื่อมต่อแล้วลองใหม่อีกครั้ง

[iap.iap_purchase_controller.body.3]
KO: 결제 창을 열 수 없습니다.
TH: ไม่สามารถเปิดหน้าต่างชำระเงินได้

[iap.iap_purchase_controller.body.4]
KO: 결제를 시작하지 못했습니다. 네트워크 상태를 확인해 주세요.
TH: ไม่สามารถเริ่มการชำระเงินได้ โปรดตรวจสอบการเชื่อมต่อเครือข่ายของคุณ

[iap.iap_purchase_controller.body.5]
KO: 구매 복원에 실패했습니다. 잠시 후 다시 시도해 주세요.
TH: กู้คืนการซื้อไม่สำเร็จ โปรดลองอีกครั้งในภายหลัง

[iap.iap_purchase_controller.body.6]
KO: 상품(${product.productId})을 찾지 못했습니다. Play Console 등록을 확인해 주세요.
TH: ไม่พบสินค้า (${product.productId}) โปรดตรวจสอบการลงทะเบียนใน Play Console

[iap.iap_purchase_controller.body.7]
KO: 결제가 진행 중입니다. Google Play 승인을 기다려 주세요.
TH: กำลังดำเนินการชำระเงิน โปรดรอการอนุมัติจาก Google Play

[iap.iap_purchase_controller.body.8]
KO: 결제가 실패했습니다.
TH: การชำระเงินล้มเหลว

[iap.iap_purchase_controller.body.9]
KO: 결제가 취소되었습니다.
TH: ยกเลิกการชำระเงินแล้ว

[iap.payment_auth.body]
KO: 본인 확인이 취소됐어요. 결제는 진행되지 않았어요.
TH: การยืนยันตัวตนถูกยกเลิก ไม่มีการดำเนินการชำระเงิน

[iap.payment_auth.body.2]
KO: 확인을 여러 번 틀려 잠시 막혔어요. 잠시 뒤 다시 하거나 화면 잠금(PIN, 패턴)으로 확인해 주세요. 결제는 진행되지 않았어요.
TH: ยืนยันไม่ถูกต้องหลายครั้งจึงถูกระงับชั่วคราว กรุณาลองใหม่อีกครั้งในภายหลัง หรือยืนยันด้วยการล็อกหน้าจอ (PIN, รูปแบบ) ไม่มีการดำเนินการชำระเงิน

[iap.payment_auth.body.3]
KO: 결제 전 본인 확인을 하려면 폰에 화면 잠금(지문, PIN, 패턴)이 필요해요. 기기 설정에서 화면 잠금을 켠 뒤 다시 시도해 주세요.
TH: หากต้องการยืนยันตัวตนก่อนชำระเงิน จำเป็นต้องตั้งค่าล็อกหน้าจอ (ลายนิ้วมือ, PIN, รูปแบบ) บนโทรศัพท์ กรุณาเปิดการล็อกหน้าจอในการตั้งค่าอุปกรณ์แล้วลองใหม่อีกครั้ง

[iap.payment_auth.body.4]
KO: 본인 확인을 할 수 없어요. 잠시 뒤 다시 시도해 주세요. 결제는 진행되지 않았어요.
TH: ไม่สามารถยืนยันตัวตนได้ กรุณาลองใหม่อีกครั้งในภายหลัง ไม่มีการดำเนินการชำระเงิน

[iap.payment_auth.body.5]
KO: 결제를 진행하려면 본인 확인이 필요해요.
TH: จำเป็นต้องยืนยันตัวตนเพื่อดำเนินการชำระเงิน

[iap.purchases_closed.body]
KO: 안내
TH: แจ้งเตือน

[iap.purchases_closed.title]
KO: 이 버전에서는 앱 안 결제를 받지 않아요.
TH: เวอร์ชันนี้ไม่รองรับการซื้อภายในแอป

[in_app_billing.body]
KO: DIA · SHARE로 교환
TH: แลกเปลี่ยนเป็น DIA · SHARE

[in_app_billing.body.2]
KO: Play 상품 준비 중 · 결제해도 DIA가 지급되지 않습니다
TH: กำลังเตรียมสินค้า Play · จะไม่ได้รับ DIA แม้จะชำระเงินแล้ว

[in_challenge.body]
KO: 센서 준비 중...
TH: กำลังเตรียมเซนเซอร์...

[in_challenge.body.2]
KO: Jena 검증 중...
TH: กำลังตรวจสอบ Jena...

[in_challenge.body.3]
KO: 제출 기회: ${widget.submissionsRemaining}/${widget.maxSubmissions}회 남음
TH: โอกาสในการส่ง: เหลือ ${widget.submissionsRemaining}/${widget.maxSubmissions} ครั้ง

[in_challenge.body.4]
KO: 센서 시작 실패: $e
TH: การเริ่มเซนเซอร์ล้มเหลว: $e

[in_challenge.body.5]
KO: 심박수
TH: อัตราการเต้นของหัวใจ

[in_challenge.body.6]
KO: 위치 권한이 필요합니다.
TH: จำเป็นต้องมีสิทธิ์เข้าถึงตำแหน่ง

[in_challenge.body.7]
KO: Google Maps API 키가 설정되지 않았습니다.
TH: ยังไม่ได้ตั้งค่าคีย์ Google Maps API

[in_challenge.body.8]
KO: 러닝 데이터를 검증 중입니다...
TH: กำลังตรวจสอบข้อมูลการวิ่ง...

[in_challenge.button]
KO: 강제 정지 대신 소명 기회가 부여되었습니다. 증빙 자료를 제출해 주세요.
TH: ได้รับโอกาสในการชี้แจงแทนการระงับการใช้งาน โปรดส่งหลักฐาน

[in_challenge.button.2]
KO: 소명하러 가기
TH: ไปที่การชี้แจง

[in_challenge.button.3]
KO: 시스템 설정 열기
TH: เปิดการตั้งค่าระบบ

[in_challenge.dialog]
KO: 기록 검증 보류
TH: แจ้งเตือน: รอการตรวจสอบบันทึกการวิ่ง

[in_challenge.toast]
KO: Jena 검증 실패: ${ApiErrorMessage.from(error)}
TH: การตรวจสอบ Jena ล้มเหลว: ${ApiErrorMessage.from(error)}

[app.itemInventoryBoostRunQuantityNote]
KO: 하루 1회 · 15분간 줍는 SHARE 2배 · 추가분 +240
TH: วันละ 1 ครั้ง · ได้รับ SHARE เพิ่มเป็น 2 เท่าเป็นเวลา 15 นาที · เพิ่มเติม +240

[app.itemInventoryCoachOnePointHint]
KO: 러닝을 시작하면 사용됩니다. 하루 1회.
TH: จะใช้งานเมื่อเริ่มวิ่ง วันละ 1 ครั้ง

[app.itemInventoryCprQuantity]
KO: 보유량: 3/3
TH: ครอบครอง: 3/3

[app.itemInventoryCrewCheerHint]
KO: 하루 1회. 대회 SHARE 보상만 10% 늘어납니다.
TH: วันละ 1 ครั้ง เฉพาะรางวัล SHARE จากการแข่งขันจะเพิ่มขึ้น 10%

[app.itemInventoryDonationMatchNote]
KO: 100 VALUE. 운영자 명의 1,000원이 러닝 기부 풀에 더해지고 내 이름이 함께 표시됩니다. 영수증은 없습니다.
TH: 100 VALUE เงิน 1,000 วอน (KRW) ในนามของผู้ดำเนินงานจะถูกเพิ่มลงในกองทุนบริจาคการวิ่งและแสดงชื่อของคุณควบคู่ไปด้วย ไม่มีใบเสร็จ

[app.itemInventoryDonationMatchUse]
KO: 매칭하기
TH: จับคู่

[app.itemInventoryExtraEntryHint]
KO: 모집 마감·정원 초과 참가 시 사용됩니다. 하루 2회.
TH: ใช้เมื่อเข้าร่วมหลังปิดรับสมัครหรือเกินจำนวนที่กำหนด วันละ 2 ครั้ง

[app.itemInventoryFriendGhostHint]
KO: 러닝 중 친구 기록과 비교합니다. 내 최고 기록은 무료입니다.
TH: เปรียบเทียบกับสถิติของเพื่อนระหว่างวิ่ง สถิติที่ดีที่สุดของคุณใช้ได้ฟรี

[app.itemInventoryRestDayNote]
KO: 매주 1회 무료. 추가 보유분만 VALUE로 샀습니다. 휴식일은 출석으로 세지 않고 스트릭도 끊지 않습니다.
TH: ฟรีสัปดาห์ละ 1 ครั้ง เฉพาะส่วนที่ครอบครองเพิ่มเติมซื้อด้วย VALUE วันพักจะไม่นับเป็นการเช็กอินและไม่ทำให้สตรีคขาด

[app.itemInventoryRestDayToday]
KO: 오늘 휴식
TH: พักผ่อนวันนี้

[app.itemInventoryRestDayYesterday]
KO: 어제 휴식
TH: พักผ่อนเมื่อวาน

[app.itemInventorySafeGuardQuantity]
KO: 보유량: 1/1
TH: ครอบครอง: 1/1

[app.itemInventoryTitle]
KO: 내 아이템 보관함
TH: กล่องเก็บไอเทมของฉัน

[app.itemInventoryUse]
KO: 사용하기
TH: ใช้งาน

[item_inventory.body]
KO: 보유량: ${shop.cprCount}
TH: ครอบครอง: ${shop.cprCount}

[item_inventory.body.2]
KO: 보유량: ${shop.safeGuardCount}
TH: ครอบครอง: ${shop.safeGuardCount}

[item_inventory.body.3]
KO: 보유량: ${shop.coachOnePointCount}
TH: ครอบครอง: ${shop.coachOnePointCount}

[item_inventory.body.4]
KO: 보유량: ${shop.extraEntryCount}
TH: ครอบครอง: ${shop.extraEntryCount}

[item_inventory.body.5]
KO: 보유량: ${shop.friendGhostCount}
TH: ครอบครอง: ${shop.friendGhostCount}

[item_inventory.body.6]
KO: 보유량: ${shop.crewCheerCount}
TH: ครอบครอง: ${shop.crewCheerCount}

[item_inventory.body.7]
KO: 보유량: ${shop.boostRunCount}
${AppStrings.itemInventoryBoostRunQuantityNote}
TH: จำนวนที่ครอบครอง: ${shop.boostRunCount}
${AppStrings.itemInventoryBoostRunQuantityNote}

[item_inventory.body.8]
KO: 보유량: ${shop.stepIncubatorCount}
${AppStrings.itemInventoryStepIncubatorQuantityNote}
TH: จำนวนที่ครอบครอง: ${shop.stepIncubatorCount}
${AppStrings.itemInventoryStepIncubatorQuantityNote}

[item_inventory.body.9]
KO: 추가 보유: ${shop.restDayCount}
${AppStrings.itemInventoryRestDayNote}
TH: ครอบครองเพิ่มเติม: ${shop.restDayCount}
${AppStrings.itemInventoryRestDayNote}

[item_inventory.toast]
KO: 이미 처리된 매칭입니다. VALUE는 한 번만 차감됩니다.
TH: การจับคู่ถูกดำเนินการแล้ว ระบบจะหัก VALUE เพียงครั้งเดียว

[item_inventory.toast.2]
KO: 기부 매칭을 기록했습니다.
TH: บันทึกการจับคู่บริจาคเรียบร้อยแล้ว

[item_inventory.toast.3]
KO: 기부 매칭을 기록하지 못했습니다.
TH: ไม่สามารถบันทึกการจับคู่บริจาคได้

[item_inventory.toast.4]
KO: 이미 처리된 휴식일 지정입니다.
TH: กำหนดวันพักถูกดำเนินการแล้ว

[item_inventory.toast.5]
KO: $label 완료
TH: $label เสร็จสิ้น
