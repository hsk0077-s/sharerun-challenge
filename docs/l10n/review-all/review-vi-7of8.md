# 번역 검수 요청 — 쉐어런 (Vietnamese) · 파트 7/8

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
[solo_pedometer.body.5]
KO: 워킹챌린지
VI: Thử thách đi bộ

[solo_pedometer.body.6]
KO: [${running.koreanName}] 산책 중
VI: [${running.koreanName}] đang đi dạo

[solo_pedometer.body.7]
KO: 내 누적 SHARE 통장 🏦
VI: Tài khoản SHARE tích lũy của tôi 🏦

[solo_pedometer.body.8]
KO: 오늘의 땀방울 : $todayCollectedCoins / ${PedometerHarvestLedger.dailyShareCap} SHARE 🪙
VI: Mồ hôi hôm nay: $todayCollectedCoins / ${PedometerHarvestLedger.dailyShareCap} SHARE 🪙

[solo_pedometer.body.9]
KO: 걸음
VI: bước

[solo_pedometer.button]
KO: 나중에
VI: Để sau

[solo_pedometer.button.2]
KO: 계속
VI: Tiếp tục

[solo_pedometer.dialog]
KO: 걸음 수를 세려면 권한이 필요해요
VI: Cần có quyền truy cập để đếm số bước

[solo_pedometer.dialog.2]
KO: • 신체 활동: 폰이 센 걸음 수를 읽습니다.
• 건강 데이터(걸음): Health Connect에 기록된 걸음 수를 읽어 화면이 꺼져 있을 때의 걸음도 반영합니다.

걸음 수는 보상 계산에만 쓰이고, 동의하지 않아도 다른 기능은 쓸 수 있어요.
VI: • Hoạt động thể chất: đọc số bước điện thoại đã đếm.
• Dữ liệu sức khỏe (số bước): đọc số bước được ghi trong Health Connect để tính cả số bước khi màn hình tắt.

Số bước chỉ dùng để tính thưởng, và bạn vẫn có thể dùng các tính năng khác dù không đồng ý.

[solo_pedometer.toast]
KO: SHARE를 줍는 중이에요. 잠시만 기다려 주세요.
VI: Đang thu thập SHARE. Vui lòng chờ trong giây lát.

[solo_pedometer.toast.2]
KO: SHARE 줍기에 실패했습니다. 네트워크를 확인한 뒤 다시 시도해 주세요.
VI: Thu thập SHARE thất bại. Vui lòng kiểm tra kết nối mạng và thử lại.

[sponsor.sponsor_billboard.body]
KO: 검증된 달리기 1km마다 100원을 기부할 예정이에요
VI: Dự kiến quyên góp 100 KRW cho mỗi 1km chạy bộ được xác minh

[sponsor_payment.body]
KO: 결제 준비 중...
VI: Đang chuẩn bị thanh toán...

[sponsor_payment.body.2]
KO: 결제 진행하기
VI: Tiến hành thanh toán

[sponsor_payment.body.3]
KO: 후원 결제
VI: Thanh toán tài trợ

[sponsor_payment.hint]
KO: 후원 금액
VI: Số tiền tài trợ

[sponsor_payment.title]
KO: 대회 후원
VI: Tài trợ giải đấu

[sponsor_payment.toast]
KO: 스폰서 결제가 대회에 반영되었습니다.
VI: Thanh toán tài trợ đã được áp dụng vào giải đấu.

[sponsor_payment.toast.2]
KO: 후원 결제에 실패했어요: $error
VI: Thanh toán tài trợ thất bại: $error

[stamp.stamp_tour_provider.body]
KO: 우리 동네 랜드마크 스탬프 찍기 ($officialVisitedCount/${officialLandmarks.length})
VI: Thu thập tem địa danh trong khu phố ($officialVisitedCount/${officialLandmarks.length})

[stamp.stamp_tour_provider.body.10]
KO: 오늘의 1km 걷기 미션을 이미 완료했습니다.
VI: Bạn đã hoàn thành nhiệm vụ đi bộ 1km hôm nay.

[stamp.stamp_tour_provider.body.11]
KO: 1km 걷기 미션 완료! ${AppStrings.stampTourOfficialDiaPending}
VI: Đã hoàn thành nhiệm vụ đi bộ 1 km! ${AppStrings.stampTourOfficialDiaPending}

[stamp.stamp_tour_provider.body.12]
KO: 아직 ${remain.toStringAsFixed(2)}km 더 걸어주세요.
VI: Vui lòng đi bộ thêm ${remain.toStringAsFixed(2)} km nữa.

[stamp.stamp_tour_provider.body.13]
KO: 공식 DIA 대기 기록에 실패했습니다.
VI: Ghi nhận DIA chính thức đang chờ xử lý thất bại.

[stamp.stamp_tour_provider.body.2]
KO: 위치 권한이 필요합니다. 설정에서 허용해 주세요.
VI: Cần quyền truy cập vị trí. Vui lòng cho phép trong Cài đặt.

[stamp.stamp_tour_provider.body.3]
KO: GPS 수신 중 오류가 발생했습니다.
VI: Đã xảy ra lỗi khi nhận tín hiệu GPS.

[stamp.stamp_tour_provider.body.4]
KO: 위치 추적을 시작할 수 없습니다.
VI: Không thể bắt đầu theo dõi vị trí.

[stamp.stamp_tour_provider.body.5]
KO: 모든 공식 랜드마크 스탬프를 이미 획득했습니다.
VI: Bạn đã nhận được tất cả tem địa danh chính thức.

[stamp.stamp_tour_provider.body.6]
KO: 현재 위치를 확인할 수 없습니다. 위치 권한을 허용해 주세요.
VI: Không thể xác định vị trí hiện tại. Vui lòng cho phép quyền vị trí.

[stamp.stamp_tour_provider.body.7]
KO: 목표 랜드마크 반경 50m 이내로 접근해 주세요.
VI: Vui lòng di chuyển đến trong phạm vi 50m từ địa danh mục tiêu.

[stamp.stamp_tour_provider.body.8]
KO: ${unlocked.name} 스탬프 획득! ${AppStrings.stampTourOfficialDiaPending}
VI: Đã nhận tem ${unlocked.name}! ${AppStrings.stampTourOfficialDiaPending}

[stamp.stamp_tour_provider.body.9]
KO: ${unlocked.name} 개인 스탬프 기록됨 (공식 DIA 없음)
VI: Đã ghi nhận tem cá nhân ${unlocked.name} (không có DIA chính thức)

[app.dashboardStampTourCta]
KO: 스탬프 투어 확인하기
VI: Xem tour tích tem

[app.stampTourLandmarkGangbyeon]
KO: 강변 공원
VI: Công viên Gangbyeon

[app.stampTourLandmarkModoil]
KO: 모도일 공원
VI: Công viên Modoil

[app.stampTourLandmarkNamsan]
KO: 남산타워
VI: Tháp Namsan

[app.stampTourMissionStamp]
KO: 우리 동네 랜드마크 스탬프 찍기 (1/3)
VI: Thu thập tem địa danh trong khu phố (1/3)

[app.stampTourMissionWalk]
KO: 오늘 가볍게 1km 걷기
VI: Đi bộ nhẹ nhàng 1km hôm nay

[app.stampTourMissionWalkReward]
KO: DIA 지급 대기
VI: Đang chờ phát DIA

[app.stampTourStampCollected]
KO: 스탬프 완료
VI: Đã thu thập tem

[app.stampTourTitle]
KO: 스탬프 투어 & 미션
VI: Tour tích tem & Nhiệm vụ

[app.stampTourVisitComplete]
KO: 방문 완료!
VI: Đã ghé thăm!

[stamp_tour.body]
KO: ${AppStrings.stampTourStampCollected} (개인)
VI: ${AppStrings.stampTourStampCollected} (Cá nhân)

[stamp_tour.body.2]
KO: 개인 스탬프 · 반경 50m
VI: Tem cá nhân · Bán kính 50m

[stamp_tour.body.3]
KO: 공식 랜드마크 · 반경 50m
VI: Địa danh chính thức · Bán kính 50m

[stamp_tour.body.4]
KO: 서울
VI: Seoul

[stamp_tour.body.5]
KO: 획득 완료
VI: Đã thu thập

[store.body]
KO: ${_groupDigits(value)}원
VI: ${_groupDigits(value)} won

[store.body.2]
KO: $out원
VI: $out won

[app.iapBillingSubtitle]
KO: 구글 플레이 공식 보안 결제를 적용합니다.
VI: Áp dụng thanh toán bảo mật chính thức của Google Play.

[app.iapBillingTitle]
KO: 다이아 교환소
VI: Đổi DIA

[app.storeBuyDia]
KO: 30 DIA 구매
VI: Mua 30 DIA

[app.storeFunctionalItems]
KO: 기능성 아이템
VI: Vật phẩm chức năng

[app.walletHistoryShortcutTooltip]
KO: 재화 히스토리
VI: Lịch sử tiền tệ

[subscription_management.body]
KO: 구독
VI: Đăng ký

[subscription_management.body.2]
KO: 무료 기본 러닝 안내
심박·상황에 맞춘 심층 코칭
VI: Hướng dẫn chạy bộ cơ bản miễn phí
Huấn luyện chuyên sâu theo nhịp tim và thể trạng

[app.termsAllAgree]
KO: [전체 동의] 쉐어런챌린지 이용약관
VI: [Đồng ý tất cả] Điều khoản dịch vụ ShareRun Challenge

[app.termsOptionalHealth]
KO: [선택] 건강정보(심박수) 수집 및
이용 동의
VI: [Tùy chọn] Đồng ý thu thập và sử dụng
thông tin sức khỏe (nhịp tim)

[app.termsRequiredAge14]
KO: [필수] 만 14세 이상입니다
VI: [Bắt buộc] Tôi từ 14 tuổi trở lên

[app.termsRequiredLocation]
KO: [필수] 위치기반서비스 이용약관 동의
VI: [Bắt buộc] Đồng ý điều khoản dịch vụ dựa trên vị trí

[app.termsRequiredPrivacy]
KO: [필수] 개인정보 수집 및 이용 동의
VI: [Bắt buộc] Đồng ý thu thập và sử dụng thông tin cá nhân

[app.termsRequiredService]
KO: [필수] 쉐어런챌린지 서비스 이용약관
VI: [Bắt buộc] Điều khoản dịch vụ ShareRun Challenge

[app.termsSubtitle]
KO: 안전하고 공정한 쉐어런 생태계를 위해 필수
항목에 동의해 주세요.
VI: Vui lòng đồng ý với các mục bắt buộc để xây dựng
hệ sinh thái ShareRun an toàn và công bằng.

[app.termsTitle]
KO: 환영합니다!
시작 전 약관 동의가
필요합니다.
VI: Chào mừng bạn!
Cần đồng ý với điều khoản
trước khi bắt đầu.

[tournament.body]
KO: 내 티어 $userTier
VI: Hạng của tôi $userTier

[tournament.body.10]
KO: 그 밖의 대회
VI: Các giải đấu khác

[tournament.body.11]
KO: 낮은 등급 대회는 참가할 수 없어요
VI: Bạn không thể tham gia giải đấu hạng thấp hơn

[tournament.body.12]
KO: 이미 참가했어요
VI: Đã tham gia

[tournament.body.13]
KO: 모집이 끝났어요
VI: Đã kết thúc tuyển quân

[tournament.body.14]
KO: 후원  ${displaySponsorName(room.sponsorName)}
VI: Nhà tài trợ  ${displaySponsorName(room.sponsorName)}

[tournament.body.15]
KO: 목표 거리
VI: Khoảng cách mục tiêu

[tournament.body.16]
KO: 참가비
VI: Phí tham gia

[tournament.body.17]
KO: 모집
VI: Tuyển quân

[tournament.body.18]
KO: 이 대회 후원하기
VI: Tài trợ giải đấu này

[tournament.body.19]
KO: 내 대회 ($count)
VI: Giải đấu của tôi ($count)

[tournament.body.2]
KO: 검증된 달리기 1km마다 100원을 기부할 예정이에요.
VI: Dự kiến quyên góp 100 KRW cho mỗi 1km chạy bộ được xác minh.

[tournament.body.3]
KO: 회사(운영자) 자금으로 기부할 예정이며 월 한도가 있어요. 기부처는 협의 중이고 정해지면 알려 드려요.
VI: Dự kiến quyên góp từ ngân sách công ty (đơn vị vận hành) và có giới hạn hàng tháng. Tổ chức nhận quyên góp đang được trao đổi và sẽ được thông báo sau khi xác định.

[tournament.body.4]
KO: 아직 열린 대회가 없어요
VI: Chưa có giải đấu nào đang mở

[tournament.body.5]
KO: 새 대회가 열리면 여기에 나타나요.
VI: Khi giải đấu mới mở, nó sẽ xuất hiện ở đây.

[tournament.body.6]
KO: 티어 대회
VI: Giải đấu xếp hạng

[tournament.body.7]
KO: 등급을 받으면 참가할 수 있어요
VI: Bạn có thể tham gia sau khi được xếp hạng

[tournament.body.8]
KO: 자유 대회
VI: Giải đấu tự do

[tournament.body.9]
KO: 누구나 참가 · 승급 점수 절반
VI: Bất kỳ ai cũng có thể tham gia · Một nửa điểm thăng cấp

[tournament.button]
KO: 무료 참가권으로 참가
VI: Tham gia bằng vé miễn phí

[tournament_detail.body]
KO: 대회를 찾을 수 없습니다.
VI: Không tìm thấy giải đấu.

[tournament_detail.body.10]
KO: 상태: ${_statusKo(room.status)}
VI: Trạng thái: ${_statusKo(room.status)}

[tournament_detail.body.11]
KO: 목표 거리: ${room.targetDistanceKm.toStringAsFixed(1)} km
VI: Khoảng cách mục tiêu: ${room.targetDistanceKm.toStringAsFixed(1)} km

[tournament_detail.body.12]
KO: 참가비: $entryFeeShare SHARE
VI: Phí tham gia: $entryFeeShare SHARE

[tournament_detail.body.13]
KO: 참가비: $feeText
VI: Phí tham gia: $feeText

[tournament_detail.body.14]
KO: 모집 인원이 차지 않아 참가비를 돌려드렸어요.
VI: Phí tham gia đã được hoàn lại do không đủ số lượng người đăng ký.

[tournament_detail.body.15]
KO: 참가 상태: ${participantStatus ==
VI: Trạng thái tham gia: ${participantStatus ==

[tournament_detail.body.16]
KO: 참가일: ${_formatDate(joinedAt!)}
VI: Ngày tham gia: ${_formatDate(joinedAt!)}

[tournament_detail.body.17]
KO: 모집 중
VI: Đang chiêu mộ

[tournament_detail.body.18]
KO: 진행 중
VI: Đang diễn ra

[tournament_detail.body.19]
KO: 취소됨
VI: Đã hủy

[tournament_detail.body.2]
KO: 추가 참가권으로 참가
VI: Tham gia bằng vé bổ sung

[tournament_detail.body.20]
KO: 인원 미달로 취소됨
VI: Đã hủy do không đủ người

[tournament_detail.body.21]
KO: 종료
VI: Đã kết thúc

[tournament_detail.body.3]
KO: ${room.entryFeeShare} SHARE로 참가
VI: Tham gia bằng ${room.entryFeeShare} SHARE

[tournament_detail.body.4]
KO: 로그인 후 참가할 수 있습니다.
VI: Bạn có thể tham gia sau khi đăng nhập.

[tournament_detail.body.5]
KO: 현재 티어에서는 참가할 수 없습니다.
VI: Không thể tham gia ở hạng hiện tại.

[tournament_detail.body.6]
KO: 정원이 가득 찼습니다.
VI: Đã đủ số lượng.

[tournament_detail.body.7]
KO: 모집이 종료된 대회입니다.
VI: Giải đấu đã kết thúc nhận đăng ký.

[tournament_detail.body.8]
KO: 스폰서 후원하기
VI: Tài trợ

[tournament_detail.body.9]
KO: 후원: ${displaySponsorName(room.sponsorName)}
VI: Nhà tài trợ: ${displaySponsorName(room.sponsorName)}

[tournament_detail.button]
KO: 이미 참가한 대회입니다.
VI: Đã tham gia giải đấu

[tournament_detail.button.2]
KO: 대회 목록에서 보기
VI: Xem trong danh sách giải đấu

[tournament_detail.button.3]
KO: 러닝 시작하기
VI: Bắt đầu chạy

[tournament_detail.title]
KO: 대회 상세
VI: Chi tiết giải đấu

[tournament_model.body]
KO: 참가자 $participantCount/$maxParticipants명
VI: $participantCount/$maxParticipants người tham gia

[tournament_model.body.2]
KO: 참가자 $participantCount명
VI: $participantCount người tham gia

[tournament_model.body.3]
KO: 기부 풀: $donationValue VALUE
VI: Quỹ quyên góp: $donationValue VALUE

[tournament_model.body.4]
KO: 쉐어런 대회
VI: Giải đấu ShareRun

[tournament_model.body.5]
KO: 쉐어런 스폰서
VI: Nhà tài trợ ShareRun

[tournaments.prize_display.body]
KO: ${won ~/ 10000}만 원 상당 다이아
VI: DIA tương đương ${won ~/ 10000}0.000 KRW

[tournaments.prize_display.body.2]
KO: ${_grouped(won)}원 상당 다이아
VI: DIA tương đương ${_grouped(won)} KRW

[tournaments.prize_display.body.3]
KO: 상금을 확인하는 중이에요
VI: Đang kiểm tra tiền thưởng

[tournaments.prize_display.body.4]
KO: 상금을 불러오지 못했어요
VI: Không thể tải tiền thưởng

[tournaments.prize_race_entry.body]
KO: 참가비 확인 중
VI: Đang kiểm tra phí tham gia

[tournaments.prize_race_entry.body.2]
KO: 참가비를 불러오지 못했습니다
VI: Không thể tải phí tham gia

[tournaments.prize_race_entry.body.3]
KO: 무료 참가
VI: Tham gia miễn phí

[tournaments.prize_race_entry.body.4]
KO: 무료 참가권 $ticketCost장
VI: $ticketCost vé tham gia miễn phí

[tournaments.prize_race_entry.body.5]
KO: $entryShare SHARE 또는 무료 참가권 $ticketCost장
VI: $entryShare SHARE hoặc $ticketCost vé tham gia miễn phí

[tournaments.prize_race_entry.body.6]
KO: $base · 보유 $held장
VI: $base · Sở hữu $held vé

[tournaments.prize_race_entry.body.7]
KO: $freeEntryLabel로 참가
VI: Tham gia bằng $freeEntryLabel

[tournaments.prize_race_entry.body.8]
KO: $entryShare SHARE로 참가
VI: Tham gia với $entryShare SHARE

[tournaments.prize_race_entry.body.9]
KO: 무료 참가권 $ticketCost장으로 참가
VI: Tham gia bằng $ticketCost vé tham gia miễn phí

[tournaments.sponsor_display.body]
KO: 운영자
VI: Nhà vận hành

[tournaments.tournament_join_flow.body]
KO: 로그인 후 챌린지에 참가할 수 있습니다.
VI: Bạn có thể tham gia thử thách sau khi đăng nhập.

[tournaments.tournament_join_flow.body.2]
KO: 이미 참가한 챌린지입니다.
VI: Bạn đã tham gia thử thách này rồi.

[tournaments.tournament_join_gate.body]
KO: SHARE 잔액이 부족합니다.
VI: Số dư SHARE không đủ.

[tournaments.tournament_join_outcome.body]
KO: 이미 참가한 챌린지입니다. 참가비는 다시 차감되지 않습니다.
VI: Bạn đã tham gia thử thách này rồi. Phí tham gia sẽ không bị trừ lại.

[tournaments.tournament_join_outcome.body.2]
KO: 참가가 거절되었습니다. 참가비는 차감되지 않았습니다.
VI: Yêu cầu tham gia bị từ chối. Phí tham gia chưa bị trừ.

[tournaments.tournament_join_outcome.body.3]
KO: 참가·결제가 완료되지 않았습니다. 서버 연결 또는 인증에 실패했습니다.
VI: Chưa hoàn tất tham gia/thanh toán. Kết nối máy chủ hoặc xác thực thất bại.

[tournaments.tournament_join_outcome.body.4]
KO: 참가 완료.
VI: Đã tham gia thành công.

[tournaments.tournament_join_outcome.body.5]
KO: 참가 완료. 참가비 $fee SHARE가 잠겼습니다.
VI: Đã tham gia thành công. Đã khóa phí tham gia $fee SHARE.

[tournaments.tournament_join_outcome.body.6]
KO: 참가 완료(디버그). 참가비 $fee SHARE가 차감되었습니다.
VI: Đã tham gia thành công (gỡ lỗi). Đã trừ phí tham gia $fee SHARE.

[user_model.body]
KO: 미연동
VI: Chưa liên kết

[user_model.body.2]
KO: 여
VI: Nữ

[user_model.body.3]
KO: 여성
VI: Nữ

[voice_coaching.voice_coaching_cues.body]
KO: 보이스 코칭을 켤게요.
VI: Bật hướng dẫn bằng giọng nói.

[voice_coaching.voice_coaching_cues.body.10]
KO: 심박이 좋아요. 이 페이스 유지해요.
VI: Nhịp tim rất tốt. Hãy duy trì tốc độ này.

[voice_coaching.voice_coaching_cues.body.11]
KO: 심박이 내려왔어요. 페이스 유지해요.
VI: Nhịp tim đã hạ xuống. Hãy duy trì tốc độ.

[voice_coaching.voice_coaching_cues.body.12]
KO: 천 보 달성! 좋아요.
VI: Đã đạt 1.000 bước! Tốt lắm.

[voice_coaching.voice_coaching_cues.body.13]
KO: 삼천 보예요. 페이스 잘 유지하고 있어요.
VI: 3.000 bước rồi. Bạn đang duy trì tốc độ rất tốt.

[voice_coaching.voice_coaching_cues.body.14]
KO: 오천 보! 잘하고 있어요.
VI: 5.000 bước! Bạn đang làm rất tốt.

[voice_coaching.voice_coaching_cues.body.15]
KO: 팔천 보. 거의 다 왔어요.
VI: 8.000 bước. Sắp tới đích rồi.

[voice_coaching.voice_coaching_cues.body.16]
KO: 만 보 달성! 오늘 정말 잘했어요.
VI: Đã đạt 10.000 bước! Hôm nay bạn làm rất tuyệt vời.

[voice_coaching.voice_coaching_cues.body.17]
KO: $steps보 달성! 좋아요.
VI: Đã đạt $steps bước! Tốt lắm.

[voice_coaching.voice_coaching_cues.body.18]
KO: 1킬로미터. 호흡 유지하고 가요.
VI: 1 km. Hãy duy trì nhịp thở và tiếp tục nào.

[voice_coaching.voice_coaching_cues.body.19]
KO: $km킬로미터. 이 페이스 유지해요.
VI: $km km. Hãy duy trì tốc độ này.

[voice_coaching.voice_coaching_cues.body.2]
KO: 워킹 챌린지 시작이에요. 천천히 걸어볼까요?
VI: Thử thách đi bộ bắt đầu. Hãy đi chậm rãi nhé?

[voice_coaching.voice_coaching_cues.body.20]
KO: 1킬로미터. 페이스 좋아요.
VI: 1 km. Tốc độ rất tốt.

[voice_coaching.voice_coaching_cues.body.21]
KO: $km킬로미터 통과. 잘하고 있어요.
VI: Vượt qua $km km. Bạn đang làm rất tốt.

[voice_coaching.voice_coaching_cues.body.3]
KO: SHARE를 수확했어요. 수고했어요.
VI: Bạn đã thu hoạch SHARE. Làm tốt lắm!

[voice_coaching.voice_coaching_cues.body.4]
KO: 오늘의 목표 거리를 채웠어요. 대단해요!
VI: Bạn đã hoàn thành cự ly mục tiêu hôm nay. Tuyệt vời!

[voice_coaching.voice_coaching_cues.body.5]
KO: 러닝을 시작해요. 호흡을 맞춰볼까요?
VI: Bắt đầu chạy bộ. Hãy điều hòa nhịp thở nhé?

[voice_coaching.voice_coaching_cues.body.6]
KO: 러닝 종료. 오늘도 잘 달렸어요.
VI: Kết thúc chạy bộ. Hôm nay bạn đã chạy rất tốt!

[voice_coaching.voice_coaching_cues.body.7]
KO: 200미터 남았어요.
VI: Còn lại 200 mét.

[voice_coaching.voice_coaching_cues.body.8]
KO: 좋아요. 호흡 유지해요.
VI: Tốt lắm. Hãy duy trì nhịp thở.

[voice_coaching.voice_coaching_cues.body.9]
KO: 심박이 높아요. 속도를 줄여요.
VI: Nhịp tim đang cao. Hãy giảm tốc độ.

[app.voiceCoachingDisable]
KO: 코칭 끄기
VI: Tắt huấn luyện

[app.voiceCoachingEnable]
KO: 코칭 켜기
VI: Bật huấn luyện

[app.voiceCoachingOffTooltip]
KO: 보이스 코칭 켜기
VI: Bật huấn luyện bằng giọng nói

[app.voiceCoachingOnTooltip]
KO: 보이스 코칭 끄기
VI: Tắt huấn luyện bằng giọng nói

[app.voiceCoachingSubtitle]
KO: 워킹·러닝 중 짧은 응원 멘트를 음성으로 들려줍니다
VI: Phát tin nhắn cổ vũ ngắn bằng giọng nói khi đi bộ hoặc chạy bộ

[app.voiceCoachingTitle]
KO: 보이스 코칭
VI: Huấn luyện bằng giọng nói

[app.voiceCoachingWalkOff]
KO: 보이스 코칭이 꺼져 있습니다
VI: Huấn luyện bằng giọng nói đang tắt.

[app.voiceCoachingWalkOn]
KO: 보이스 코칭 켜져 있음
VI: Huấn luyện bằng giọng nói đang bật

[wallet.economy_status.body]
KO: 온보딩 & 땀방울 현황
VI: Trạng thái giới thiệu & mồ hôi

[wallet.economy_status.body.2]
KO: ${EconomyConstants.signupRewardSrv} SRV 지급 완료
VI: Đã phát ${EconomyConstants.signupRewardSrv} SRV

[wallet.economy_status.body.3]
KO: 가입 후 ${EconomyConstants.signupRewardSrv} SRV 대기
VI: Đang chờ ${EconomyConstants.signupRewardSrv} SRV sau khi đăng ký

[wallet.economy_status.body.4]
KO: 예비 러닝
VI: Chạy thử nghiệm

[wallet.economy_status.body.5]
KO: ${economy.trialRunCount}/${EconomyConstants.referralTrialRunsRequired}회 · 완료 시 50,000 SHARE · 1.1km 이상 달리면 안전해요
VI: ${economy.trialRunCount}/${EconomyConstants.referralTrialRunsRequired} lần · Nhận 50.000 SHARE khi hoàn thành · Chạy từ 1,1 km trở lên để đảm bảo

[wallet.economy_status.body.6]
KO: 일일 땀방울 한도
VI: Giới hạn giọt mồ hôi hàng ngày

[wallet.economy_status.body.7]
KO: ${economy.referralPayoutCount}/${EconomyConstants.maxReferralPayouts}명 · 지인 3회 완료 시 30,000 SHARE
VI: ${economy.referralPayoutCount}/${EconomyConstants.maxReferralPayouts} người · Nhận 30.000 SHARE khi bạn bè hoàn thành 3 lần

[wallet.shop_section.body]
KO: 다이아 상점
VI: Cửa hàng DIA

[wallet.shop_section.body.2]
KO: 보유 Diamond $diamondBalance
VI: Diamond sở hữu $diamondBalance

[wallet.shop_section.body.3]
KO: DIA 충전하기
VI: Nạp DIA

[wallet.shop_section.body.4]
KO: 구매
VI: Mua

[wallet_transaction_model.body]
KO: 휴식일 지정
VI: Đặt ngày nghỉ

[wallet_transaction_model.body.10]
KO: 러닝 땀방울 적립
VI: Tích lũy giọt mồ hôi chạy bộ

[wallet_transaction_model.body.11]
KO: 신규 가입 보상
VI: Thưởng đăng ký mới

[wallet_transaction_model.body.12]
KO: 첫 경기 무료 참가권
VI: Vé tham gia miễn phí trận đầu tiên

[wallet_transaction_model.body.13]
KO: 예비 러닝 3회 달성
VI: Đạt 3 lần chạy dự bị

[wallet_transaction_model.body.14]
KO: 추천인 보상 (지연 지급)
VI: Thưởng người giới thiệu (thanh toán chậm)

[wallet_transaction_model.body.15]
KO: 초대 코드 등록
VI: Đăng ký mã mời

[wallet_transaction_model.body.16]
KO: 체험 런 1회
VI: 1 lần chạy thử

[wallet_transaction_model.body.17]
KO: 체험 런 3회 완료
VI: Hoàn thành 3 lần chạy thử

[wallet_transaction_model.body.18]
KO: 친구 체험 런 3회
VI: 3 lần chạy thử của bạn bè

[wallet_transaction_model.body.19]
KO: 친구 체험 런 3회 대기
VI: Đang chờ 3 lần chạy thử của bạn bè

[wallet_transaction_model.body.2]
KO: SHARE 충전
VI: Nạp SHARE

[wallet_transaction_model.body.20]
KO: 자비로운 실패 기부
VI: Quyên góp thất bại khoan hồng

[wallet_transaction_model.body.21]
KO: 우승 상금 수령
VI: Nhận tiền thưởng chiến thắng

[wallet_transaction_model.body.22]
KO: 우승 상금 50% 기부
VI: Quyên góp 50% tiền thưởng chiến thắng

[wallet_transaction_model.body.23]
KO: 우승 상금 전액 기부
VI: Quyên góp toàn bộ tiền thưởng chiến thắng

[wallet_transaction_model.body.24]
KO: 스폰서 결제
VI: Thanh toán nhà tài trợ

[wallet_transaction_model.body.25]
KO: Web3 외부 전송
VI: Chuyển tiền ra ngoài Web3

[wallet_transaction_model.body.26]
KO: 부정 러닝 예치금 몰수
VI: Tịch thu tiền cọc do chạy gian lận

[wallet_transaction_model.body.27]
KO: 워킹챌린지 코인 줍기
VI: Nhặt xu thử thách đi bộ

[wallet_transaction_model.body.28]
KO: 만보기 부화
VI: Ấp trứng máy đếm bước

[wallet_transaction_model.body.29]
KO: 기부 완료
VI: Quyên góp thành công

[wallet_transaction_model.body.3]
KO: 대회 참가
VI: Tham gia giải đấu

[wallet_transaction_model.body.30]
KO: 챌린지 상금 지원 후원
VI: Tài trợ hỗ trợ tiền thưởng thử thách

[wallet_transaction_model.body.31]
KO: 코스메틱 장착
VI: Trang bị vật phẩm ngoại trang

[wallet_transaction_model.body.32]
KO: 디버그 테스트 지급
VI: Cấp phát thử nghiệm gỡ lỗi

[wallet_transaction_model.body.33]
KO: SHARE → 다이아 전환
VI: Quy đổi SHARE → DIA

[wallet_transaction_model.body.34]
KO: 다이아 구매
VI: Mua DIA

[wallet_transaction_model.body.35]
KO: 연속 달리기 보너스
VI: Thưởng chạy liên tục

[wallet_transaction_model.body.36]
KO: 닉네임 변경
VI: Đổi biệt danh

[wallet_transaction_model.body.37]
KO: 크루 선물
VI: Quà crew

[wallet_transaction_model.body.38]
KO: 크루 응원 SHARE
VI: SHARE cổ vũ crew

[wallet_transaction_model.body.39]
KO: 대회 열기
VI: Tổ chức giải đấu

[wallet_transaction_model.body.4]
KO: 대회 보너스 DIA
VI: DIA thưởng giải đấu

[wallet_transaction_model.body.40]
KO: 명예의 전당 기부
VI: Quyên góp Bảng danh vọng

[wallet_transaction_model.body.41]
KO: 무료 대회 참가
VI: Tham gia giải đấu miễn phí

[wallet_transaction_model.body.42]
KO: 참가권 지급
VI: Cấp vé tham gia

[wallet_transaction_model.body.43]
KO: 참가권 대신 SHARE 지급
VI: Cấp SHARE thay vì vé

[wallet_transaction_model.body.44]
KO: 친구 체험 보상 회수
VI: Thu hồi thưởng trải nghiệm bạn bè

[wallet_transaction_model.body.45]
KO: Coach+ 심폐소생권 지급
VI: Cấp vé hồi sinh Coach+

[wallet_transaction_model.body.46]
KO: 참가권
VI: Vé tham gia

[wallet_transaction_model.body.5]
KO: 대회 상위 완주 SHARE
VI: SHARE hoàn thành top giải đấu

[wallet_transaction_model.body.6]
KO: 대회 완주 VALUE
VI: VALUE hoàn thành giải đấu

[wallet_transaction_model.body.7]
KO: 현금 환불 요청
VI: Yêu cầu hoàn tiền mặt

[wallet_transaction_model.body.8]
KO: 모집 미달 환불
VI: Hoàn tiền do không đủ người tham gia

[wallet_transaction_model.body.9]
KO: 다이아 수집
VI: Thu thập DIA

[watch_app_preview.body]
KO: 갤럭시 워치
VI: Galaxy Watch

[watch_app_preview.body.10]
KO: 갤럭시 워치 화면 시안
VI: Bản mẫu màn hình Galaxy Watch

[watch_app_preview.body.11]
KO: 워치 연결
VI: Kết nối đồng hồ

[watch_app_preview.body.12]
KO: 워치 앱에서 아래 6자리 숫자를 입력하면 이 계정으로 연결돼요. 코드는 5분 동안, 한 번만 쓸 수 있어요. 워치는 한 대만 연결돼서, 다른 워치를 연결하면 이전 워치는 해제돼요.
VI: Nhập 6 chữ số bên dưới vào ứng dụng đồng hồ để kết nối với tài khoản này. Mã có hiệu lực trong 5 phút và chỉ dùng được một lần. Chỉ có thể kết nối một đồng hồ tại một thời điểm, kết nối đồng hồ khác sẽ hủy kết nối đồng hồ trước đó.

[watch_app_preview.body.13]
KO: 남은 시간 $_countdown
VI: Thời gian còn lại $_countdown

[watch_app_preview.body.14]
KO: 예정
VI: Dự kiến

[watch_app_preview.body.15]
KO: 탭해서 다시 시작
VI: Nhấn để bắt đầu lại

[watch_app_preview.body.16]
KO: 1위!
VI: Hạng 1!

[watch_app_preview.body.17]
KO: 대회 2명 앞서요
VI: Dẫn trước 2 người trong giải

[watch_app_preview.body.18]
KO: 5:38/km · 17분
VI: 5:38/km · 17 phút

[watch_app_preview.body.19]
KO: 시안입니다. 실제 시계 화면과 조금 다를 수 있어요.
VI: Đây là bản mẫu. Màn hình thực tế có thể hơi khác một chút.

[watch_app_preview.body.2]
KO: 가장 먼저 만들어요
VI: Được phát triển đầu tiên

[watch_app_preview.body.3]
KO: 안드로이드 워치 (Wear OS)
VI: Đồng hồ Android (Wear OS)

[watch_app_preview.body.4]
KO: 갤럭시 워치 다음
VI: Sau Galaxy Watch

[watch_app_preview.body.5]
KO: 스마트 밴드 (샤오미 등)
VI: Vòng đeo tay thông minh (Xiaomi, v.v.)

[watch_app_preview.body.6]
KO: 그다음 순서로 검토해요
VI: Xem xét ở bước tiếp theo

[watch_app_preview.body.7]
KO: 가민
VI: Garmin

[watch_app_preview.body.8]
KO: 애플 워치
VI: Apple Watch

[watch_app_preview.body.9]
KO: 아래 시계 화면은 시안이에요.
VI: Màn hình đồng hồ bên dưới là bản mẫu.

[watch_app_preview.button]
KO: 이 계정에 연결한 워치가 모두 로그아웃돼요. 워치에 남은 기록은 다시 연결하기 전까지 올라가지 않아요. 휴대폰 로그인은 그대로예요.
VI: Tất cả đồng hồ kết nối với tài khoản này sẽ bị đăng xuất. Bản ghi trên đồng hồ sẽ không được tải lên cho đến khi kết nối lại. Đăng nhập trên điện thoại vẫn được giữ nguyên.

[watch_app_preview.button.2]
KO: 모두 해제
VI: Hủy tất cả

[watch_app_preview.button.3]
KO: 워치 전용 앱
VI: Ứng dụng cho đồng hồ

[watch_app_preview.button.4]
KO: 취소
VI: Hủy

[watch_app_preview.button.5]
KO: 6자리 연결 코드 받기
VI: Nhận mã kết nối 6 chữ số

[watch_app_preview.button.6]
KO: 새 코드 받기
VI: Nhận mã mới

[watch_app_preview.button.7]
KO: 연결된 워치 ${_watches.length}/3
VI: Đồng hồ đã kết nối ${_watches.length}/3

[watch_app_preview.button.8]
KO: 연결된 워치 모두 해제
VI: Hủy kết nối tất cả đồng hồ

[watch_app_preview.button.9]
KO: 연결된 워치를 모두 해제했어요.
VI: Đã hủy kết nối tất cả đồng hồ.

[watch_app_preview.dialog]
KO: 연결된 워치를 모두 해제할까요?
VI: Hủy kết nối tất cả đồng hồ?

[watch_connection.body]
KO: Garmin Connect 연동 완료
VI: Đã kết nối Garmin Connect

[watch_connection.button]
KO: 알림 허용하고 계속
VI: Cho phép thông báo và tiếp tục

[watch_connection.toast]
KO: ${watchType.displayLabel} 연동이 완료되었습니다.
VI: Đã kết nối thành công ${watchType.displayLabel}.

[watch_connection.toast.2]
KO: 연동 중 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.
VI: Đã xảy ra lỗi khi kết nối. Vui lòng thử lại sau giây lát.

[watch_connection.toast.3]
KO: Health Connect 설치 화면으로 이동했습니다. 설치 후 다시 연동해 주세요.
VI: Đã chuyển đến màn hình cài đặt Health Connect. Vui lòng kết nối lại sau khi cài đặt.

[watch_connection.toast.4]
KO: 권한이 거부되었습니다. 설정에서 건강 데이터 접근을 허용해 주세요.
VI: Quyền đã bị từ chối. Vui lòng cho phép truy cập dữ liệu sức khỏe trong Cài đặt.

[watch_connection.toast.5]
KO: 외부 기기 연동 화면을 열 수 없습니다.
VI: Không thể mở màn hình kết nối thiết bị bên ngoài.

[watch_connection.toast.6]
KO: 온보딩 상태 갱신에 실패했습니다. $error
VI: Không thể cập nhật trạng thái làm quen. $error

[watch_link.garmin_cloud_oauth_adapter.body]
KO: Garmin 연동은 아직 준비 중이에요.
VI: Tính năng liên kết Garmin đang được chuẩn bị.

[watch_link.garmin_cloud_oauth_adapter.body.2]
KO: 이메일과 비밀번호를 입력해 주세요.
VI: Vui lòng nhập email và mật khẩu.

[watch_link.garmin_cloud_oauth_adapter.body.3]
KO: 인증에 실패했습니다. Garmin 계정 정보를 확인해 주세요.
VI: Xác thực thất bại. Vui lòng kiểm tra lại thông tin tài khoản Garmin.

[watch_settings.body]
KO: 브랜드별 연동 경로를 분리해 데이터 신뢰도와 법률 방어를 강화합니다.
VI: Tách biệt lộ trình liên kết theo thương hiệu để tăng cường độ tin cậy của dữ liệu và phòng ngừa pháp lý.

[watch_settings.body.10]
KO: OS Health 데이터 직접 읽기
VI: Đọc trực tiếp dữ liệu OS Health

[watch_settings.body.2]
KO: Track A · API 연동
VI: Track A · Liên kết API

[watch_settings.body.3]
KO: Garmin / Coros / Suunto — 브랜드 클라우드 OAuth
VI: Garmin / Coros / Suunto — Đám mây thương hiệu OAuth

[watch_settings.body.4]
KO: Track B · OS 직접 연동
VI: Track B · Liên kết trực tiếp qua HĐH

[watch_settings.body.5]
KO: 연동 해제
VI: Hủy liên kết

[watch_settings.body.6]
KO: 현재 연동된 워치가 없습니다.
VI: Hiện chưa có đồng hồ nào được liên kết.

[watch_settings.body.7]
KO: 현재 연동: ${watchType.displayLabel} (${watchType.isApiTrack ?
VI: Liên kết hiện tại: ${watchType.displayLabel} (${watchType.isApiTrack ?

[watch_settings.body.8]
KO: 건강정보 동의 후 선택할 수 있습니다.
VI: Có thể chọn sau khi đồng ý với thông tin sức khỏe.

[watch_settings.body.9]
KO: 브랜드 API · OAuth
VI: API thương hiệu · OAuth

[watch_settings.button]
KO: 건강정보 동의하고 연동 시작
VI: Đồng ý dữ liệu sức khỏe và bắt đầu liên kết

[watch_settings.title]
KO: 투트랙 연동 방식
VI: Phương thức đồng bộ hóa hai chiều

[watch_settings.toast]
KO: 필수
VI: Bắt buộc
