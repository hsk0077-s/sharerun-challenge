# 번역 검수 요청 — 쉐어런 (Vietnamese) · 파트 3/8

아래는 한국어 앱 "쉐어런"(걷기·달리기 앱, 회사 자금 기부 연계)의 화면 문구를 Vietnamese(으)로 번역한 것입니다.
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
[item_inventory.body.4]
KO: 보유량: ${shop.extraEntryCount}
VI: Sở hữu: ${shop.extraEntryCount}

[item_inventory.body.5]
KO: 보유량: ${shop.friendGhostCount}
VI: Sở hữu: ${shop.friendGhostCount}

[item_inventory.body.6]
KO: 보유량: ${shop.crewCheerCount}
VI: Sở hữu: ${shop.crewCheerCount}

[item_inventory.body.7]
KO: 보유량: ${shop.boostRunCount}
${AppStrings.itemInventoryBoostRunQuantityNote}
VI: Sở hữu: ${shop.boostRunCount}
${AppStrings.itemInventoryBoostRunQuantityNote}

[item_inventory.body.8]
KO: 보유량: ${shop.stepIncubatorCount}
${AppStrings.itemInventoryStepIncubatorQuantityNote}
VI: Sở hữu: ${shop.stepIncubatorCount}
${AppStrings.itemInventoryStepIncubatorQuantityNote}

[item_inventory.body.9]
KO: 추가 보유: ${shop.restDayCount}
${AppStrings.itemInventoryRestDayNote}
VI: Sở hữu thêm: ${shop.restDayCount}
${AppStrings.itemInventoryRestDayNote}

[item_inventory.toast]
KO: 이미 처리된 매칭입니다. VALUE는 한 번만 차감됩니다.
VI: Ghép cặp đã được xử lý. VALUE chỉ bị trừ một lần.

[item_inventory.toast.2]
KO: 기부 매칭을 기록했습니다.
VI: Đã ghi nhận ghép cặp quyên góp.

[item_inventory.toast.3]
KO: 기부 매칭을 기록하지 못했습니다.
VI: Không thể ghi nhận ghép cặp quyên góp.

[item_inventory.toast.4]
KO: 이미 처리된 휴식일 지정입니다.
VI: Đã xử lý thiết lập ngày nghỉ.

[item_inventory.toast.5]
KO: $label 완료
VI: $label hoàn thành

[item_inventory.toast.6]
KO: 휴식일을 지정하지 못했습니다.
VI: Không thể thiết lập ngày nghỉ.

[item_inventory.toast.7]
KO: $title 보유량이 없습니다. 상점에서 구매해 주세요.
VI: Không có $title. Vui lòng mua trong cửa hàng.

[item_inventory.toast.8]
KO: $title 사용 완료
VI: Đã dùng $title

[item_inventory.toast.9]
KO: $title 을 사용하지 못했습니다.
VI: Không thể sử dụng $title.

[jena_validation.jena_pending_gate.body]
KO: 케이던스(발구름) 데이터가 없거나 0입니다. 기록이 보류되었습니다.
VI: Dữ liệu nhịp chân (cadence) bị thiếu hoặc bằng 0. Bản ghi đã bị tạm giữ.

[jena_validation.jena_pending_gate.body.2]
KO: 심박수 추이가 페이스 증가에 반응하지 않아 차량·자전거·킥보드 탑승이 의심됩니다.
VI: Xu hướng nhịp tim không phản ứng với sự gia tăng tốc độ, nghi ngờ sử dụng phương tiện, xe đạp hoặc xe trượt scooter.

[jena_validation.jena_pending_gate.body.3]
KO: GPS 오차 범위를 넘는 순간 이동 속도가 검출되어 기록이 거절되었습니다.
VI: Phát hiện tốc độ di chuyển tức thời vượt quá phạm vi sai số GPS nên bản ghi đã bị từ chối.

[jena_validation.jena_pending_gate.body.4]
KO: 비정상적인 GPS 순간 속도가 검출되어 기록이 보류되었습니다.
VI: Phát hiện tốc độ GPS tức thời bất thường nên bản ghi đã bị tạm giữ.

[jena_validation.mock_jena_validation_service.body]
KO: GPS 궤적 또는 거리 데이터가 부족합니다.
VI: Dữ liệu quỹ đạo GPS hoặc khoảng cách không đủ.

[jena_validation.mock_jena_validation_service.body.2]
KO: 순수 노력 러닝으로 Jena AI 검증이 완료되었습니다.
VI: Đã hoàn thành xác minh Jena AI với tư cách là lần chạy nỗ lực thực sự.

[jena_validation.verification_guidance.body]
KO: 이번 대회의 검증 최소 거리는 $distance예요. 대회 거리가 더 짧아도 1km는 넘어야 해요.
VI: Quãng đường xác minh tối thiểu cho giải chạy này là $distance. Dù cự ly giải chạy ngắn hơn thì vẫn phải vượt quá 1 km.

[jena_validation.verification_guidance.body.2]
KO: 분당 걸음 수는 120~210이어야 해요.
VI: Số bước mỗi phút phải từ 120 đến 210.

[jena_validation.verification_guidance.body.3]
KO: 워치 심박은 운영자 대회 상급·하프·파이널에서만 필요해요.
VI: Nhịp tim từ đồng hồ chỉ bắt buộc trong các giải chạy của ban quản trị ở cấp độ Nâng cao, Bán marathon và Chung kết.

[jena_validation.verification_guidance.body.4]
KO: 이 대회는 워치 심박이 있어야 완주로 인정돼요.
VI: Giải chạy này yêu cầu phải có nhịp tim từ đồng hồ để được công nhận hoàn thành.

[jena_validation.verification_guidance.body.5]
KO: 기록은 언제나, 보상은 검증된 달리기에만.
VI: Bản ghi luôn được lưu, phần thưởng chỉ dành cho các lượt chạy đã xác minh.

[jena_validation.verification_guidance.body.6]
KO: 검증 안내
VI: Hướng dẫn xác minh

[jena_validation.verification_guidance.body.7]
KO: 확인하고 참가
VI: Xác nhận và tham gia

[jena_validation.verification_guidance.body.8]
KO: 다시 보지 않기
VI: Không hiển thị lại

[jena_validation.verification_reason.body]
KO: 거리가 이번 대회의 최소 거리보다 짧아요. 대회 거리만큼, 적어도 1km는 달려야 해요. 기록은 남고 보상은 지급되지 않아요.
VI: Quãng đường ngắn hơn cự ly tối thiểu của giải chạy này. Bạn phải chạy đủ cự ly của giải và ít nhất là 1 km. Bản ghi vẫn được lưu nhưng phần thưởng sẽ không được trao.

[jena_validation.verification_reason.body.2]
KO: 분당 걸음 수가 120~210 범위를 벗어났어요. 기록은 남고 보상은 지급되지 않아요.
VI: Số bước mỗi phút nằm ngoài phạm vi 120–210. Bản ghi vẫn được lưu nhưng phần thưởng sẽ không được trao.

[jena_validation.verification_reason.body.3]
KO: 상급·하프·파이널 대회는 워치 심박이 있어야 완주로 인정돼요. 심박이 없어 보상은 지급되지 않아요.
VI: Các giải chạy Nâng cao, Bán marathon và Chung kết yêu cầu phải có nhịp tim từ đồng hồ mới được công nhận hoàn thành. Không có nhịp tim nên phần thưởng sẽ không được trao.

[jena_validation.verification_reason.body.4]
KO: 평균 심박이 달리기라고 보기엔 낮아요. 기록은 남고 보상은 지급되지 않아요.
VI: Nhịp tim trung bình quá thấp để được tính là chạy bộ. Bản ghi vẫn được lưu nhưng phần thưởng sẽ không được trao.

[jena_validation.verification_reason.body.5]
KO: 심박이 거의 변하지 않아 달리기로 확인되지 않았어요. 기록은 남고 보상은 지급되지 않아요.
VI: Nhịp tim hầu như không thay đổi nên không thể xác nhận là chạy bộ. Bản ghi vẫn được lưu nhưng phần thưởng sẽ không được trao.

[jena_validation.verification_reason.body.6]
KO: 워치가 없어 보폭을 확인했는데, 거리와 걸음 수가 달리기 범위가 아니에요. 기록은 남고 보상은 지급되지 않아요.
VI: Do không có đồng hồ nên đã kiểm tra sải chân, nhưng quãng đường và số bước không nằm trong phạm vi chạy bộ. Bản ghi vẫn được lưu nhưng phần thưởng sẽ không được trao.

[jena_validation.verification_reason.body.7]
KO: 이동 속도가 차량에 가까워 달리기로 인정되지 않았어요. 기록은 남고 보상은 지급되지 않아요.
VI: Tốc độ di chuyển gần với tốc độ xe cộ nên không được công nhận là chạy bộ. Bản ghi vẫn được lưu nhưng phần thưởng sẽ không được trao.

[jena_validation.verification_reason.body.8]
KO: 킥보드나 탑승으로 보여 보상은 지급되지 않아요. 기록은 남아요.
VI: Có vẻ như đã sử dụng xe trượt hoặc phương tiện di chuyển nên phần thưởng sẽ không được trao. Bản ghi vẫn được lưu.

[jena_validation.verification_reason.body.9]
KO: 자전거 탑승으로 보여 보상은 지급되지 않아요. 기록은 남아요.
VI: Có vẻ như đã đi xe đạp nên phần thưởng sẽ không được trao. Bản ghi vẫn được lưu.

[launch.intro.body]
KO: 걸으면 SHARE가 쌓여요
VI: Đi bộ để tích lũy SHARE

[launch.intro.body.10]
KO: +100원
VI: +100 won

[launch.intro.body.11]
KO: 회사(운영자) 자금으로 기부 예정 · 내가 내는 돈은 없어요 · 내 기여는 앱에서 확인
VI: Dự kiến từ ngân sách công ty (đơn vị vận hành) · Bạn hoàn toàn không mất phí · Kiểm tra đóng góp trên ứng dụng

[launch.intro.body.13]
KO: 지금
달팽이
VI: Hiện tại
Ốc sên

[launch.intro.body.14]
KO: 등급을
받으면
VI: Khi nhận
xếp hạng

[launch.intro.body.15]
KO: 티어가
오르면
VI: Khi thăng
hạng

[launch.intro.body.2]
KO: 한 걸음이 나눔이 된다
VI: Mỗi bước chân trở thành sự sẻ chia

[launch.intro.body.3]
KO: 내 기록은 어느 폰에서나 그대로예요
VI: Hồ sơ của bạn vẫn giữ nguyên trên mọi điện thoại

[launch.intro.body.4]
KO: 100걸음마다 10 SHARE를 받아요. 모은 SHARE로 대회에 참가할 수 있어요.
VI: Nhận 10 SHARE sau mỗi 100 bước. Bạn có thể dùng SHARE tích lũy để tham gia giải chạy.

[launch.intro.body.5]
KO: SHARE는 현금으로 바꿀 수 없는 활동 보상이고, 하루에 받을 수 있는 양에 한도가 있어요.
VI: SHARE là phần thưởng hoạt động không thể quy đổi thành tiền mặt và có giới hạn số lượng có thể nhận mỗi ngày.

[launch.intro.body.6]
KO: 검증된 모든 달리기, 1km마다 운영자가 100원을 기부할 예정이에요. 내가 보탠 만큼은 앱에서 확인할 수 있어요.
VI: Với mỗi lượt chạy được xác minh, ban quản trị dự kiến quyên góp 100 won cho mỗi 1 km. Bạn có thể kiểm tra phần đóng góp của mình trong ứng dụng.

[launch.intro.body.7]
KO: 운영자의 월 기부 예산 안에서 진행될 예정이에요. 예산을 다 쓴 달은 넘는 거리가 기록으로 남아요.
VI: Chương trình dự kiến diễn ra trong phạm vi ngân sách quyên góp hàng tháng của ban quản trị. Vào tháng dùng hết ngân sách, quãng đường vượt mức vẫn được lưu lại làm bản ghi.

[launch.intro.body.8]
KO: 걷기·달리기 기록은 서버에 저장돼요. 폰을 바꿔도 로그인하면 이어져요.
VI: Bản ghi đi bộ và chạy được lưu trên máy chủ. Kể cả khi đổi điện thoại, chỉ cần đăng nhập là có thể tiếp tục.

[launch.intro.body.9]
KO: 100걸음
VI: 100 bước

[launch.intro.button]
KO: 시작하기
VI: Bắt đầu

[launch.intro.button.2]
KO: 이미 계정이 있어요 · 로그인
VI: Đã có tài khoản · Đăng nhập

[legal.health_data_consent.body]
KO: 체크해야 워치 연동·심박 검증이 활성화됩니다.
VI: Phải chọn để kích hoạt đồng bộ hóa đồng hồ và xác minh nhịp tim.

[legal_constants.body]
KO: 결제 취소 (현금 환불)
VI: Hủy thanh toán (hoàn tiền mặt)

[legal_constants.body.10]
KO: 마케팅·활동 알림 (선택)
VI: Thông báo tiếp thị và hoạt động (Tùy chọn)

[legal_constants.body.12]
KO: 부정 러닝·결제 어뷰징은 계정 제한 대상이 될 수 있습니다.
VI: Chạy gian lận và lạm dụng thanh toán có thể dẫn đến việc bị hạn chế tài khoản.

[legal_constants.body.14]
KO: 전체 내용은 개인정보 처리방침 전문에서 확인할 수 있습니다.
VI: Có thể xem toàn bộ nội dung trong toàn văn Chính sách quyền riêng tư.

[legal_constants.body.17]
KO: 대회 모집, 검증 결과, 리워드·기부 알림을 푸시로 받을 수 있습니다. 언제든 MyPage에서 변경할 수 있습니다.
VI: Bạn có thể nhận thông báo đẩy về tuyển chọn giải đấu, kết quả xác minh, phần thưởng và quyên góp. Có thể thay đổi bất kỳ lúc nào trong MyPage.

[legal_constants.body.18]
KO: 심박수·케이던스 원본 데이터는 기기 메모리에서 검증한 뒤 바로 폐기하며, 검증 결과 요약만 저장합니다.
VI: Dữ liệu gốc về nhịp tim và guồng chân sẽ bị hủy ngay sau khi xác minh trong bộ nhớ thiết bị, chỉ lưu lại bản tóm tắt kết quả xác minh.

[legal_constants.body.19]
KO: 건강 정보 안내
VI: Thông tin sức khỏe

[legal_constants.body.2]
KO: [선택] 건강정보(심박수) 수집 및 이용 동의
VI: [Tùy chọn] Đồng ý thu thập và sử dụng thông tin sức khỏe (nhịp tim)

[legal_constants.body.21]
KO: 가슴 통증, 어지러움 등 이상이 느껴지면 즉시 운동을 멈추고 의료진과 상담하세요.
VI: Nếu cảm thấy đau ngực, chóng mặt hoặc bất thường, hãy ngừng tập thể dục ngay lập tức và tham khảo ý kiến bác sĩ.

[legal_constants.body.23]
KO: 언제든 해지할 수 있으며, 해지해도 이미 결제한 기간이 끝날 때까지 이용할 수 있습니다.
VI: Bạn có thể hủy bất kỳ lúc nào và vẫn có thể sử dụng cho đến khi kết thúc khoảng thời gian đã thanh toán.

[legal_constants.body.3]
KO: 건강정보 수집 동의 (선택 · 별도)
VI: Đồng ý thu thập thông tin sức khỏe (tùy chọn · riêng biệt)

[legal_constants.body.4]
KO: 개인정보 처리방침 전문 보기
VI: Xem toàn văn Chính sách quyền riêng tư

[legal_constants.body.5]
KO: 서비스 이용약관 전문 보기
VI: Xem toàn văn Điều khoản dịch vụ

[legal_constants.body.6]
KO: AI 생성 이미지 안내
VI: Thông báo về hình ảnh do AI tạo

[legal_constants.body.7]
KO: 일부 그림은 AI로 생성되었습니다. Created with Grok
VI: Một số hình ảnh được tạo bởi AI. Created with Grok

[legal_constants.body.8]
KO: 서비스 이용약관 (필수)
VI: Điều khoản dịch vụ (Bắt buộc)

[legal_constants.body.9]
KO: 개인정보 처리방침 (필수)
VI: Chính sách quyền riêng tư (Bắt buộc)

[app.levelTestChallengeProgress]
KO: 챌린지 진행 상황: 2/3회 완료 (3.52/5.00 KM)
VI: Tiến độ thử thách: Hoàn thành 2/3 lần (3.52/5.00 KM)

[app.levelTestGhostPace]
KO: [고스트 페이스]
VI: [Tốc độ ảo]

[app.levelTestMyLocation]
KO: [나(현재 위치)]
VI: [Tôi (Vị trí hiện tại)]

[app.levelTestStartRun]
KO: 3회차 달리기 시작하기
VI: Bắt đầu lượt chạy thứ 3

[app.levelTestStatDistance]
KO: 현재 거리
VI: Khoảng cách hiện tại

[app.levelTestStatPace]
KO: 현재 페이스
VI: Tốc độ hiện tại

[app.levelTestStatTime]
KO: 경과 시간
VI: Thời gian đã trôi qua

[app.levelTestSubtitle]
KO: 검증된 달리기를 서로 다른 날 3번 마치면 등급이 배정됩니다.
VI: Hoàn thành 3 lần chạy đã xác minh vào các ngày khác nhau để nhận xếp hạng.

[app.levelTestTitle]
KO: 혼자 뛰기 챌린지 (등급 배정)
VI: Thử thách chạy một mình (Xếp hạng)

[app.liveRunningEffortTip]
KO: 순수 노력 목표: 완주 시 VALUE +$valueTokens
VI: Mục tiêu nỗ lực thuần túy: VALUE +$valueTokens khi hoàn thành

[app.liveRunningFinish]
KO: 종료 / 저장
VI: Kết thúc / Lưu

[app.liveRunningGhostPace]
KO: 고스트 페이스
VI: Tốc độ ảo

[app.liveRunningRoomTitle]
KO: 3km 중급 챌린지
VI: Thử thách 3km trung cấp

[app.liveRunningSubmissionsLeft]
KO: 제출 기회: 2/3회 남음
VI: Lượt gửi: còn lại 2/3

[app.liveRunningYouLabel]
KO: 나 (You)
VI: Bạn (You)

[app.runValidationFailed]
KO: 기록 검증에 실패했습니다. 보상이 지급되지 않았습니다.
VI: Xác minh bản ghi thất bại. Phần thưởng chưa được trao.

[live_running.body]
KO: 1km 초보 챌린지
VI: Thử thách 1km cho người mới

[live_running.body.2]
KO: 나
VI: Tôi

[live_running.body.3]
KO: 고스트
VI: Ghost

[live_running.body.4]
KO: 검증 중
VI: Đang xác minh

[live_running.toast]
KO: 센서 시작 실패: $error
VI: Khởi động cảm biến thất bại: $error

[app.existingAccountApple]
KO: 애플로 가입했어요
VI: Tôi đã đăng ký bằng Apple

[app.existingAccountBody]
KO: 그 방법으로 로그인하면 지금 $provider${subjectParticle(provider)} 그 계정에 연결돼요. 닉네임과 재화도 그대로예요.
VI: Nếu đăng nhập bằng phương thức đó, $provider${subjectParticle(provider)} hiện tại sẽ được liên kết với tài khoản đó. Biệt danh và tiền tệ cũng sẽ được giữ nguyên.

[app.existingAccountCreate]
KO: 새로 시작하기
VI: Bắt đầu lại

[app.existingAccountCreateHint]
KO: 기억나지 않거나 처음이신가요?
VI: Không nhớ hoặc bạn là người mới?

[app.existingAccountGoogle]
KO: 구글로 가입했어요
VI: Tôi đã đăng ký bằng Google

[app.existingAccountKakao]
KO: 카카오로 가입했어요
VI: Tôi đã đăng ký bằng Kakao

[app.existingAccountNaver]
KO: 네이버로 가입했어요
VI: Tôi đã đăng ký bằng Naver

[app.existingAccountNotFound]
KO: 그 방법으로 가입된 계정이 없어요. 다른 방법을 골라 주세요.
VI: Không tìm thấy tài khoản nào được đăng ký bằng phương thức đó. Vui lòng chọn phương thức khác.

[app.existingAccountTitle]
KO: 처음 가입할 때 어떤 방법을 쓰셨나요?
VI: Bạn đã dùng phương thức nào khi đăng ký lần đầu?

[app.linkAttached]
KO: $method${subjectParticle(method)} 연결됐어요. 이제 어느 쪽으로 들어와도 같은 계정이에요.
VI: $method${subjectParticle(method)} đã được liên kết. Giờ đây bạn đăng nhập bằng cách nào cũng là cùng một tài khoản.

[app.linkConfirmNo]
KO: 아니에요, 다시 고를게요
VI: Không, chọn lại

[app.linkConfirmTitle]
KO: 이 계정에 $method${objectParticle(method)} 연결할까요?
VI: Liên kết $method${objectParticle(method)} với tài khoản này?

[app.linkConfirmYes]
KO: 네, 연결할게요
VI: Có, liên kết

[app.loginComingSoon]
KO: $provider 로그인은 준비 중입니다.
VI: Đăng nhập bằng $provider đang được chuẩn bị.

[app.loginGoogle]
KO: Google로 계속하기
VI: Tiếp tục với Google

[app.loginGuest]
KO: 게스트(테스트)로 시작하기
VI: Bắt đầu với tư cách khách (Thử nghiệm)

[app.loginGuestLoading]
KO: 게스트 로그인 중...
VI: Đang đăng nhập với tư cách khách...

[app.loginGuestNote]
KO: 게스트 모드는 워치 연동·Health Connect 테스트용 임시 계정입니다.
VI: Chế độ khách là tài khoản tạm thời để thử nghiệm liên kết đồng hồ và Health Connect.

[app.loginKakao]
KO: Kakao로 계속하기
VI: Tiếp tục với Kakao

[app.loginNaver]
KO: Naver로 계속하기
VI: Tiếp tục với Naver

[app.loginReferralHint]
KO: 추천 코드를 입력하세요...
VI: Nhập mã giới thiệu...

[app.loginReferralLabel]
KO: 추천 코드가 있으신가요?
VI: Bạn có mã giới thiệu không?

[app.loginSaveFailed]
KO: 로그인 저장 실패: $error
VI: Lưu đăng nhập thất bại: $error

[app.loginSubtitle]
KO: 세계를 향한 나눔의 질주
VI: Cuộc chạy sẻ chia hướng ra thế giới

[app.referralRedeemAlready]
KO: 이미 초대 코드를 입력했어요
VI: Bạn đã nhập mã mời rồi

[app.referralRedeemDone]
KO: 초대한 친구: 입력 완료
VI: Bạn bè đã mời: Đã nhập

[app.referralRedeemEntry]
KO: 초대 코드 입력
VI: Nhập mã mời

[app.referralRedeemExpired]
KO: 가입 후 7일이 지나 입력할 수 없어요
VI: Không thể nhập do đã quá 7 ngày kể từ khi đăng ký

[app.referralRedeemFailed]
KO: 초대 코드를 등록하지 못했어요
VI: Không thể đăng ký mã mời

[app.referralRedeemInvalid]
KO: 없는 초대 코드예요
VI: Mã mời không tồn tại

[app.referralRedeemSelf]
KO: 본인 코드는 입력할 수 없어요
VI: Bạn không thể nhập mã của chính mình

[app.referralRedeemSubmit]
KO: 등록
VI: Đăng ký

[app.referralRedeemSuccess]
KO: 10,000 SHARE 지급
VI: Đã tặng 10.000 SHARE

[login.body]
KO: 구글 로그인에 성공했습니다!
VI: Đăng nhập Google thành công!

[login.body.2]
KO: 로그인 실패:
VI: Đăng nhập thất bại:

[login.body.3]
KO: 애플 로그인에 성공했습니다!
VI: Đăng nhập Apple thành công!

[login.body.4]
KO: 애플 로그인 실패:
VI: Đăng nhập Apple thất bại:

[login.body.5]
KO: 네이버 로그인에 성공했습니다!
VI: Đăng nhập Naver thành công!

[login.body.6]
KO: 네이버 로그인 실패:
VI: Đăng nhập Naver thất bại:

[login.body.7]
KO: 카카오 로그인에 성공했습니다!
VI: Đăng nhập Kakao thành công!

[login.body.8]
KO: 카카오 로그인 실패:
VI: Đăng nhập Kakao thất bại:

[login.body.9]
KO: 닉네임 $nickname
SHARE ${groupedDigits(shareBalance)}
VI: Biệt danh $nickname
SHARE ${groupedDigits(shareBalance)}

[login.button]
KO: 초대 코드가 있으신가요?
VI: Bạn có mã mời không?

[login_connections.body]
KO: $name 연결을 해제했어요.
VI: Đã hủy liên kết $name.

[login_connections.body.2]
KO: 카카오
VI: Kakao

[login_connections.body.3]
KO: 네이버
VI: Naver

[login_connections.body.4]
KO: 애플
VI: Apple

[login_connections.body.5]
KO: 구글
VI: Google

[login_connections.body.6]
KO: 같은 계정으로 여러 방법으로 로그인할 수 있어요. 연결해 두면 어떤 방법으로 들어와도 같은 SHARE와 기록이 보여요. 마지막 로그인 방법은 해제할 수 없어요.
VI: Bạn có thể đăng nhập bằng nhiều phương thức cho cùng một tài khoản. Khi liên kết, bạn sẽ thấy cùng số dư SHARE và lịch sử bất kể đăng nhập bằng cách nào. Không thể hủy phương thức đăng nhập cuối cùng.

[login_connections.body.7]
KO: 연결 안 됨
VI: Chưa liên kết

[login_connections.button]
KO: 해제하면 이 $name 계정으로는 이 쉐어런 계정에 들어올 수 없어요. 다른 로그인 방법으로는 계속 쓸 수 있어요.
VI: Nếu hủy liên kết, bạn không thể truy cập tài khoản ShareRun này bằng tài khoản $name này nữa. Bạn vẫn có thể dùng phương thức đăng nhập khác.

[login_connections.button.2]
KO: 다시 불러오기
VI: Tải lại

[login_connections.button.3]
KO: 연결하기
VI: Liên kết

[login_connections.dialog]
KO: $name 연결 해제
VI: Hủy liên kết $name

[login_devices.body]
KO: 이 계정으로 앱을 연 기기예요. 기기 이름과 마지막으로 연 시각만 저장하고, 위치나 IP 주소는 저장하지 않아요.
VI: Thiết bị đã mở ứng dụng bằng tài khoản này. Chỉ lưu tên thiết bị và thời gian mở gần nhất, không lưu vị trí hay địa chỉ IP.

[login_devices.body.2]
KO: 앱 데이터를 지우거나 다시 설치하면 같은 폰이 한 줄 더 보일 수 있어요.
VI: Xóa dữ liệu ứng dụng hoặc cài đặt lại có thể làm xuất hiện thêm một dòng cho cùng một điện thoại.

[login_devices.body.3]
KO: 아직 기록된 기기가 없어요.
VI: Chưa có thiết bị nào được ghi nhận.

[login_devices.body.4]
KO: 알 수 없는 기기
VI: Thiết bị không xác định

[login_devices.body.5]
KO: $name (이 기기)
VI: $name (Thiết bị này)

[login_devices.body.6]
KO: $name · 새 기기
VI: $name · Thiết bị mới

[login_devices.body.7]
KO: ${device.osVersion} · 앱 ${device.appVersion}
마지막으로 연 시각 $when
VI: ${device.osVersion} · Ứng dụng ${device.appVersion}
Mở lần cuối $when

[login_devices.button]
KO: 이 폰을 포함해 로그인된 모든 기기에서 로그아웃돼요. 다른 기기는 잠시 뒤 로그인 화면으로 돌아가요. 계속할까요?
VI: Bạn sẽ bị đăng xuất khỏi tất cả thiết bị bao gồm cả điện thoại này. Các thiết bị khác sẽ trở lại màn hình đăng nhập sau chốc lát. Tiếp tục?

[login_devices.dialog]
KO: 모든 기기에서 로그아웃
VI: Đăng xuất khỏi tất cả thiết bị

[login_devices.toast]
KO: 로그아웃하지 못했어요. 잠시 후 다시 시도해 주세요.
VI: Không thể đăng xuất. Vui lòng thử lại sau giây lát.

[app.dashboardChallenge1Sub]
KO: 참가비: 600 SHARE
VI: Phí tham gia: 600 SHARE

[app.dashboardChallenge1Title]
KO: 초보 1km 챌린지 🏆
VI: Thử thách 1km cho người mới 🏆

[app.dashboardChallenge2Sub]
KO: 참가비: 1,200 SHARE
VI: Phí tham gia: 1,200 SHARE

[app.dashboardChallenge2Title]
KO: 중급 3km 챌린지 (골드 대회)
VI: Thử thách 3km trung cấp (giải đấu Vàng)

[app.dashboardDailyMissionCapsule]
KO: 📍 오늘의 미션 확인하기 >
VI: 📍 Kiểm tra nhiệm vụ hôm nay >

[app.dashboardDiamondBalance]
KO: 💎 보유 다이아몬드: 5개
VI: 💎 DIA sở hữu: 5

[app.dashboardDiamondBalanceOf]
KO: 💎 보유 다이아몬드: $count개
VI: 💎 DIA sở hữu: $count

[app.dashboardGradeRunLabel]
KO: 등급 배정 달리기:
VI: Chạy phân hạng:

[app.dashboardGradeRunProgress]
KO: 2/3회 완료 >
VI: Đã hoàn thành 2/3 >

[app.dashboardOngoingChallenges]
KO: 진행 중인 챌린지
VI: Thử thách đang diễn ra

[app.dashboardShareBalance]
KO: 보유 SHARE: 90,000
VI: SHARE sở hữu: 90,000

[app.dashboardShareBalanceOf]
KO: 보유 SHARE: $amount
VI: SHARE sở hữu: $amount

[app.dashboardStampMapTooltip]
KO: 오늘의 미션 · 스탬프 투어
VI: Nhiệm vụ hôm nay · Chuyến tham quan tích tem

[app.dashboardValueBalance]
KO: 🌱 보유 밸류(VALUE): 5,200
VI: 🌱 VALUE sở hữu: 5,200

[app.dashboardValueBalanceOf]
KO: 🌱 보유 밸류(VALUE): $amount
VI: 🌱 VALUE sở hữu: $amount

[app.dashboardViewRoom]
KO: 대회 상세 보기
VI: Xem chi tiết giải đấu

[app.exitGuardMessage]
KO: 나눔의 질주를 잠시 쉬어가시겠습니까? 한 번 더 누르시면 종료됩니다.
VI: Bạn có muốn tạm nghỉ hành trình sẻ chia không? Nhấn lần nữa để thoát.

[app.myWalletCharge]
KO: 교환하기
VI: Quy đổi

[app.myWalletChargeDia]
KO: 다이아몬드
VI: DIA

[app.myWalletChargeDiaHint]
KO: 교환소에서 SHARE로 바꾸거나 연속 달리기로 모을 수 있어요
VI: Bạn có thể đổi sang SHARE tại sàn quy đổi hoặc tích lũy qua chuỗi ngày chạy bộ.

[app.myWalletChargeShareHint]
KO: 활동으로 모을 수 있어요
VI: Có thể tích lũy thông qua các hoạt động.

[app.myWalletChargeValue]
KO: 밸류(VALUE)
VI: VALUE

[app.myWalletChargeValueHint]
KO: 달리기로 모을 수 있어요
VI: Có thể tích lũy bằng cách chạy bộ.

[app.myWalletDiamondLabel]
KO: 보유 다이아몬드: $count개
VI: DIA sở hữu: $count

[app.myWalletGradeProgress]
KO: 등급 배정 달리기: $done/$total회 완료 >
VI: Chạy xếp hạng: Đã hoàn thành $done/$total lần >

[app.myWalletInventoryCount]
KO: 보유 $count
VI: Sở hữu $count

[app.myWalletInventoryEmpty]
KO: 아직 보유한 아이템이 없습니다.
VI: Chưa có vật phẩm nào.

[app.myWalletInventoryOpen]
KO: 보관함 보기
VI: Xem kho lưu trữ

[app.myWalletInventoryTitle]
KO: 보유 아이템
VI: Vật phẩm sở hữu

[app.myWalletItemDuringRun]
KO: 달리기 중 사용 가능
VI: Có thể dùng trong khi chạy

[app.myWalletItemDuringTournament]
KO: 대회에서 사용 가능
VI: Có thể dùng trong giải đấu

[app.myWalletRecentTransactions]
KO: 최근 거래 내역
VI: Lịch sử giao dịch gần đây

[app.myWalletUse]
KO: 상점 가기
VI: Đến cửa hàng

[app.myWalletValueLabel]
KO: 보유 밸류(VALUE): $amount
VI: VALUE sở hữu: $amount

[app.walletUnconfirmedNote]
KO: 서버에서 확인하는 중이에요. 지금 보이는 값은 마지막으로 확인된 값이에요.
VI: Đang kiểm tra với máy chủ. Giá trị hiển thị là giá trị được xác nhận gần nhất.

[main_dashboard.body]
KO: 상품은 다이아예요 · ${AppStrings.noCashPrizePool}
VI: Phần thưởng là DIA · ${AppStrings.noCashPrizePool}

[main_dashboard.body.2]
KO: 좋은 아침이에요
VI: Chào buổi sáng

[main_dashboard.body.3]
KO: 좋은 오후예요
VI: Chào buổi chiều

[main_dashboard.body.4]
KO: 좋은 저녁이에요
VI: Chào buổi tối

[main_dashboard.body.5]
KO: ${_hello(DateTime.now().hour)}, $nickname님
VI: ${_hello(DateTime.now().hour)}, $nickname

[main_shell_routes.body]
KO: 결제 정보가 없어 PG 화면을 열 수 없습니다.
VI: Không thể mở màn hình PG vì thiếu thông tin thanh toán.

[main_shell_routes.body.2]
KO: 대회 정보가 없어 스폰서 결제를 열 수 없습니다.
VI: Không thể mở thanh toán nhà tài trợ vì thiếu thông tin giải đấu.

[main_shell_routes.button]
KO: 대회 목록으로
VI: Danh sách giải đấu

[map_crew.body]
KO: 지도 & 크루
VI: Bản đồ & crew

[map_crew.body.2]
KO: 크루 종합 랭킹
VI: Xếp hạng tổng thể crew

[map_crew.body.3]
KO: ${crews[index].memberCount}명
VI: ${crews[index].memberCount} thành viên

[map_crew.body.4]
KO: 아직 크루 순위가 없어요
VI: Chưa có xếp hạng crew

[map_crew.body.5]
KO: 크루 순위가 쌓이면 여기에 나타나요.
VI: Xếp hạng crew sẽ xuất hiện ở đây khi có dữ liệu.

[map_crew.body.6]
KO: ${collectRadiusMeters.round()}m 안으로 가까이 가야 받을 수 있어요.
VI: Bạn cần đến gần trong vòng ${collectRadiusMeters.round()}m để nhận.

[map_crew.body.7]
KO: +${box.rewardDiamond} DIA를 받았어요.
VI: Đã nhận +${box.rewardDiamond} DIA.

[map_crew.body.8]
KO: ${distanceMeters!.toStringAsFixed(0)}m 떨어져 있어요
VI: Cách ${distanceMeters!.toStringAsFixed(0)}m

[map_crew.button]
KO: 내 위치 새로고침
VI: Làm mới vị trí

[map_crew.button.2]
KO: 다이아 상자 받기
VI: Nhận hộp DIA

[map_crew.button.3]
KO: 더 가까이 가 주세요
VI: Hãy đến gần hơn

[map_crew.crew_member_ranking_board.body]
KO: 크루원 랭킹 데이터 없음
VI: Không có dữ liệu xếp hạng thành viên crew

[map_crew.crew_member_ranking_board.body.2]
KO: 출석률·평균 페이스가 여기에 표시됩니다.
VI: Tỷ lệ tham gia và tốc độ trung bình sẽ hiển thị ở đây.

[map_crew.crew_member_ranking_board.body.3]
KO: 크루원 출석률 & 평균 페이스
VI: Tỷ lệ tham gia & tốc độ trung bình của thành viên crew

[map_crew.crew_member_ranking_board.body.4]
KO: 출석률 높은 순 · 페이스 빠른 순으로 B2B 크루 성과를 추적합니다.
VI: Theo dõi thành tích B2B crew theo thứ tự tỷ lệ tham gia cao nhất và tốc độ nhanh nhất.

[map_crew.crew_member_ranking_board.body.5]
KO: 출석 ${member.attendanceRate.toStringAsFixed(0)}%
VI: Tham gia ${member.attendanceRate.toStringAsFixed(0)}%

[map_crew.safe_map_panel.body]
KO: 지도 준비 중
VI: Đang chuẩn bị bản đồ

[mini_bot.body]
KO: 궁금한 게 있으면 저를 눌러 물어보세요
VI: Nếu có thắc mắc, hãy chạm vào tôi để hỏi nhé

[mini_bot.body.10]
KO: 하루 SHARE 한도
VI: Hạn mức SHARE mỗi ngày

[mini_bot.body.11]
KO: 어떤 대회?
VI: Cuộc thi nào?

[mini_bot.body.12]
KO: 순위별 상금
VI: Tiền thưởng theo thứ hạng

[mini_bot.body.13]
KO: 초급은 무료?
VI: Sơ cấp có miễn phí không?

[mini_bot.body.14]
KO: SHARE잔액
VI: Số dư SHARE

[mini_bot.body.15]
KO: VALUE잔액
VI: Số dư VALUE

[mini_bot.body.16]
KO: 등급
VI: Cấp bậc

[mini_bot.body.17]
KO: 오늘기부기여
VI: Đóng góp quyên góp hôm nay

[mini_bot.body.18]
KO: 이 버전에서는 앱 안에서 결제하지 않아요.
VI: Trong phiên bản này, thanh toán không được thực hiện trong ứng dụng.

[mini_bot.body.19]
KO: 궁금한 걸 물어보세요
VI: Hãy hỏi bất cứ điều gì bạn thắc mắc

[mini_bot.body.2]
KO: 오늘 목표나 SHARE가 궁금하면 물어보세요
VI: Hãy hỏi tôi nếu bạn thắc mắc về mục tiêu hôm nay hoặc SHARE nhé

[mini_bot.body.3]
KO: 기록 지키기가 헷갈리면 제가 알려 드려요
VI: Nếu bạn băn khoăn về cách bảo vệ bản ghi, tôi sẽ hướng dẫn bạn.

[mini_bot.body.4]
KO: 어떤 챌린지가 맞는지 모르겠으면 물어보세요
VI: Hãy hỏi tôi nếu bạn không biết thử thách nào phù hợp với mình

[mini_bot.body.5]
KO: 참가비와 순위별 상금이 궁금하면 눌러 보세요
VI: Nhấn vào đây nếu bạn muốn biết phí tham gia và tiền thưởng theo thứ hạng

[mini_bot.body.6]
KO: 초급은 무료인지도 알려 드려요
VI: Tôi cũng có thể cho bạn biết cấp độ sơ cấp có miễn phí hay không

[mini_bot.body.7]
KO: 오늘 내 기부
VI: Đóng góp hôm nay của tôi

[mini_bot.body.8]
KO: 내 SHARE
VI: SHARE của tôi

[mini_bot.body.9]
KO: 내 등급
VI: Cấp bậc của tôi

[mini_bot.button]
KO: 멈추기
VI: Dừng

[mini_bot.button.2]
KO: 말하기
VI: Nói

[mini_bot.button.3]
KO: 보내기
VI: Gửi

[mini_bot.hint]
KO: 한글로 말해 주세요
VI: Hãy nói hoặc nhập câu hỏi

[mini_bot.mini_bot_dock.accessibility]
KO: 달팽이봇
VI: Bot Ốc Sên

[mini_bot.mini_bot_dock.body]
KO: 끌어서 옮길 수 있어요
VI: Kéo để di chuyển

[mini_bot.mini_bot_intent.body]
KO: 후원하기
VI: Tài trợ

[mini_bot.mini_bot_intent.body.10]
KO: 다이아 교환
VI: Đổi DIA

[mini_bot.mini_bot_intent.body.11]
KO: 스폰서
VI: Nhà tài trợ

[mini_bot.mini_bot_intent.body.12]
KO: 러너 후원
VI: Tài trợ vận động viên

[mini_bot.mini_bot_intent.body.13]
KO: 배틀패스
VI: Battle Pass

[mini_bot.mini_bot_intent.body.14]
KO: 저는 당신의 달리기 친구, 달팽이예요. 말로 물어보면 바로 도와드릴게요. 이동하거나 결제하기 전에는 꼭 확인받아요.
VI: Tôi là Ốc Sên, bạn đồng hành chạy bộ của bạn. Hãy hỏi bằng giọng nói, tôi sẽ giúp bạn ngay. Tôi luôn xin xác nhận trước khi chuyển màn hình hoặc thanh toán.

[mini_bot.mini_bot_intent.body.17]
KO: 유료 구독은 Coach+ 하나예요
VI: Đăng ký trả phí duy nhất là Coach+.

[mini_bot.mini_bot_intent.body.19]
KO: 상점의 기부 버튼으로 직접 눌러 주세요.
VI: Vui lòng nhấn trực tiếp vào nút quyên góp trong cửa hàng.

[mini_bot.mini_bot_intent.body.2]
KO: 구매하기
VI: Mua

[mini_bot.mini_bot_intent.body.20]
KO: 초보 1km 챌린지로 이동할까요? 참가비는 $joinAmount예요. 참가하기를 눌러도 참가는 확정되지 않아요. 그 화면에서 직접 확인해 주세요.
VI: Chuyển đến Thử thách 1km cho người mới bắt đầu? Phí tham gia là $joinAmount. Nhấn Tham gia sẽ chưa xác nhận đăng ký. Vui lòng xác nhận trực tiếp trên màn hình đó.

[mini_bot.mini_bot_intent.body.21]
KO: 챌린지 로비로 이동할까요? 로비에서 참가할 대회를 고를 수 있어요.
VI: Chuyển đến Sảnh thử thách? Bạn có thể chọn giải đấu muốn tham gia tại sảnh.

[mini_bot.mini_bot_intent.body.22]
KO: 운영자 상금 대회 참가비를 확인 중이에요. 대회 목록에서 서버 참가비를 확인해 주세요. 여기서는 참가하지 않아요.
VI: Đang kiểm tra phí tham gia giải thưởng của ban tổ chức. Vui lòng kiểm tra phí tham gia từ máy chủ trong danh sách giải đấu. Bạn không thể đăng ký tại đây.

[mini_bot.mini_bot_intent.body.23]
KO: 초급
VI: Sơ cấp
