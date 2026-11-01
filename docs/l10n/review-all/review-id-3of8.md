# 번역 검수 요청 — 쉐어런 (Indonesian) · 파트 3/8

아래는 한국어 앱 "쉐어런"(걷기·달리기 앱, 회사 자금 기부 연계)의 화면 문구를 Indonesian(으)로 번역한 것입니다.
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
[app.itemInventoryRestDayNote]
KO: 매주 1회 무료. 추가 보유분만 VALUE로 샀습니다. 휴식일은 출석으로 세지 않고 스트릭도 끊지 않습니다.
ID: Gratis 1 kali per minggu. Hanya jumlah tambahan yang dibeli dengan VALUE. Hari istirahat tidak dihitung sebagai kehadiran dan tidak memutus rentetan.

[app.itemInventoryRestDayToday]
KO: 오늘 휴식
ID: Istirahat Hari Ini

[app.itemInventoryRestDayYesterday]
KO: 어제 휴식
ID: Istirahat Kemarin

[app.itemInventorySafeGuardQuantity]
KO: 보유량: 1/1
ID: Dimiliki: 1/1

[app.itemInventoryTitle]
KO: 내 아이템 보관함
ID: Penyimpanan Item Saya

[app.itemInventoryUse]
KO: 사용하기
ID: Gunakan

[item_inventory.body]
KO: 보유량: ${shop.cprCount}
ID: Dimiliki: ${shop.cprCount}

[item_inventory.body.2]
KO: 보유량: ${shop.safeGuardCount}
ID: Dimiliki: ${shop.safeGuardCount}

[item_inventory.body.3]
KO: 보유량: ${shop.coachOnePointCount}
ID: Dimiliki: ${shop.coachOnePointCount}

[item_inventory.body.4]
KO: 보유량: ${shop.extraEntryCount}
ID: Dimiliki: ${shop.extraEntryCount}

[item_inventory.body.5]
KO: 보유량: ${shop.friendGhostCount}
ID: Dimiliki: ${shop.friendGhostCount}

[item_inventory.body.6]
KO: 보유량: ${shop.crewCheerCount}
ID: Dimiliki: ${shop.crewCheerCount}

[item_inventory.body.7]
KO: 보유량: ${shop.boostRunCount}
${AppStrings.itemInventoryBoostRunQuantityNote}
ID: Dimiliki: ${shop.boostRunCount}
${AppStrings.itemInventoryBoostRunQuantityNote}

[item_inventory.body.8]
KO: 보유량: ${shop.stepIncubatorCount}
${AppStrings.itemInventoryStepIncubatorQuantityNote}
ID: Dimiliki: ${shop.stepIncubatorCount}
${AppStrings.itemInventoryStepIncubatorQuantityNote}

[item_inventory.body.9]
KO: 추가 보유: ${shop.restDayCount}
${AppStrings.itemInventoryRestDayNote}
ID: Tambahan dimiliki: ${shop.restDayCount}
${AppStrings.itemInventoryRestDayNote}

[item_inventory.toast]
KO: 이미 처리된 매칭입니다. VALUE는 한 번만 차감됩니다.
ID: Pencocokan sudah diproses. VALUE hanya akan dipotong satu kali.

[item_inventory.toast.2]
KO: 기부 매칭을 기록했습니다.
ID: Pencocokan donasi telah dicatat.

[item_inventory.toast.3]
KO: 기부 매칭을 기록하지 못했습니다.
ID: Gagal mencatat pencocokan donasi.

[item_inventory.toast.4]
KO: 이미 처리된 휴식일 지정입니다.
ID: Penetapan hari istirahat sudah diproses.

[item_inventory.toast.5]
KO: $label 완료
ID: $label selesai

[item_inventory.toast.6]
KO: 휴식일을 지정하지 못했습니다.
ID: Gagal menetapkan hari istirahat.

[item_inventory.toast.7]
KO: $title 보유량이 없습니다. 상점에서 구매해 주세요.
ID: Anda tidak memiliki $title. Silakan beli di toko.

[item_inventory.toast.8]
KO: $title 사용 완료
ID: $title berhasil digunakan

[item_inventory.toast.9]
KO: $title 을 사용하지 못했습니다.
ID: Gagal menggunakan $title.

[jena_validation.jena_pending_gate.body]
KO: 케이던스(발구름) 데이터가 없거나 0입니다. 기록이 보류되었습니다.
ID: Data kadens tidak ada atau bernilai 0. Catatan ditangguhkan.

[jena_validation.jena_pending_gate.body.2]
KO: 심박수 추이가 페이스 증가에 반응하지 않아 차량·자전거·킥보드 탑승이 의심됩니다.
ID: Tren detak jantung tidak merespons peningkatan pace, dicurigai menggunakan kendaraan, sepeda, atau skuter.

[jena_validation.jena_pending_gate.body.3]
KO: GPS 오차 범위를 넘는 순간 이동 속도가 검출되어 기록이 거절되었습니다.
ID: Kecepatan pergerakan instan yang melebihi batas toleransi GPS terdeteksi, sehingga catatan ditolak.

[jena_validation.jena_pending_gate.body.4]
KO: 비정상적인 GPS 순간 속도가 검출되어 기록이 보류되었습니다.
ID: Kecepatan instan GPS yang tidak normal terdeteksi, sehingga catatan ditangguhkan.

[jena_validation.mock_jena_validation_service.body]
KO: GPS 궤적 또는 거리 데이터가 부족합니다.
ID: Data trek GPS atau jarak tidak mencukupi.

[jena_validation.mock_jena_validation_service.body.2]
KO: 순수 노력 러닝으로 Jena AI 검증이 완료되었습니다.
ID: Verifikasi Jena AI selesai sebagai lari dengan usaha murni.

[jena_validation.verification_guidance.body]
KO: 이번 대회의 검증 최소 거리는 $distance예요. 대회 거리가 더 짧아도 1km는 넘어야 해요.
ID: Jarak verifikasi minimum untuk kompetisi ini adalah $distance. Meskipun jarak kompetisi lebih pendek, jarak harus melebihi 1 km.

[jena_validation.verification_guidance.body.2]
KO: 분당 걸음 수는 120~210이어야 해요.
ID: Jumlah langkah per menit harus antara 120–210.

[jena_validation.verification_guidance.body.3]
KO: 워치 심박은 운영자 대회 상급·하프·파이널에서만 필요해요.
ID: Detak jantung smartwatch hanya diperlukan pada kompetisi pengelola tingkat Tingkat Lanjut, Half, dan Final.

[jena_validation.verification_guidance.body.4]
KO: 이 대회는 워치 심박이 있어야 완주로 인정돼요.
ID: Kompetisi ini membutuhkan detak jantung smartwatch untuk diakui telah menyelesaikan lari.

[jena_validation.verification_guidance.body.5]
KO: 기록은 언제나, 보상은 검증된 달리기에만.
ID: Catatan selalu disimpan, hadiah hanya untuk lari yang terverifikasi.

[jena_validation.verification_guidance.body.6]
KO: 검증 안내
ID: Panduan Verifikasi

[jena_validation.verification_guidance.body.7]
KO: 확인하고 참가
ID: Konfirmasi dan Ikuti

[jena_validation.verification_guidance.body.8]
KO: 다시 보지 않기
ID: Jangan tampilkan lagi

[jena_validation.verification_reason.body]
KO: 거리가 이번 대회의 최소 거리보다 짧아요. 대회 거리만큼, 적어도 1km는 달려야 해요. 기록은 남고 보상은 지급되지 않아요.
ID: Jarak lebih pendek dari jarak minimum kompetisi ini. Anda harus berlari setidaknya sejauh jarak kompetisi dan minimal 1 km. Catatan tetap tersimpan, tetapi hadiah tidak diberikan.

[jena_validation.verification_reason.body.2]
KO: 분당 걸음 수가 120~210 범위를 벗어났어요. 기록은 남고 보상은 지급되지 않아요.
ID: Jumlah langkah per menit berada di luar rentang 120–210. Catatan tetap tersimpan, tetapi hadiah tidak diberikan.

[jena_validation.verification_reason.body.3]
KO: 상급·하프·파이널 대회는 워치 심박이 있어야 완주로 인정돼요. 심박이 없어 보상은 지급되지 않아요.
ID: Kompetisi Tingkat Lanjut, Half, dan Final memerlukan detak jantung smartwatch untuk diakui selesai. Karena tidak ada detak jantung, hadiah tidak diberikan.

[jena_validation.verification_reason.body.4]
KO: 평균 심박이 달리기라고 보기엔 낮아요. 기록은 남고 보상은 지급되지 않아요.
ID: Detak jantung rata-rata terlalu rendah untuk dianggap sebagai lari. Catatan tetap tersimpan, tetapi hadiah tidak diberikan.

[jena_validation.verification_reason.body.5]
KO: 심박이 거의 변하지 않아 달리기로 확인되지 않았어요. 기록은 남고 보상은 지급되지 않아요.
ID: Detak jantung hampir tidak berubah sehingga tidak dapat dikonfirmasi sebagai lari. Catatan tetap tersimpan, tetapi hadiah tidak diberikan.

[jena_validation.verification_reason.body.6]
KO: 워치가 없어 보폭을 확인했는데, 거리와 걸음 수가 달리기 범위가 아니에요. 기록은 남고 보상은 지급되지 않아요.
ID: Karena tidak ada smartwatch, panjang langkah diperiksa, tetapi jarak dan jumlah langkah tidak berada dalam rentang lari. Catatan tetap tersimpan, tetapi hadiah tidak diberikan.

[jena_validation.verification_reason.body.7]
KO: 이동 속도가 차량에 가까워 달리기로 인정되지 않았어요. 기록은 남고 보상은 지급되지 않아요.
ID: Kecepatan pergerakan mendekati kendaraan sehingga tidak diakui sebagai lari. Catatan tetap tersimpan, tetapi hadiah tidak diberikan.

[jena_validation.verification_reason.body.8]
KO: 킥보드나 탑승으로 보여 보상은 지급되지 않아요. 기록은 남아요.
ID: Tampaknya menggunakan skuter atau kendaraan, sehingga hadiah tidak diberikan. Catatan tetap tersimpan.

[jena_validation.verification_reason.body.9]
KO: 자전거 탑승으로 보여 보상은 지급되지 않아요. 기록은 남아요.
ID: Tampaknya bersepeda, sehingga hadiah tidak diberikan. Catatan tetap tersimpan.

[launch.intro.body]
KO: 걸으면 SHARE가 쌓여요
ID: Berjalanlah dan kumpulkan SHARE

[launch.intro.body.10]
KO: +100원
ID: +100 won

[launch.intro.body.11]
KO: 회사(운영자) 자금으로 기부 예정 · 내가 내는 돈은 없어요 · 내 기여는 앱에서 확인
ID: Direncanakan dari dana perusahaan (penyelenggara) · Anda tidak dikenakan biaya · Cek kontribusi di aplikasi

[launch.intro.body.13]
KO: 지금
달팽이
ID: Saat ini
Siput

[launch.intro.body.14]
KO: 등급을
받으면
ID: Setelah
mendapat tingkat

[launch.intro.body.15]
KO: 티어가
오르면
ID: Saat tier
naik

[launch.intro.body.2]
KO: 한 걸음이 나눔이 된다
ID: Setiap langkah menjadi bentuk berbagi

[launch.intro.body.3]
KO: 내 기록은 어느 폰에서나 그대로예요
ID: Catatan Anda tetap sama di ponsel mana pun

[launch.intro.body.4]
KO: 100걸음마다 10 SHARE를 받아요. 모은 SHARE로 대회에 참가할 수 있어요.
ID: Dapatkan 10 SHARE setiap 100 langkah. Gunakan SHARE yang terkumpul untuk mengikuti kompetisi.

[launch.intro.body.5]
KO: SHARE는 현금으로 바꿀 수 없는 활동 보상이고, 하루에 받을 수 있는 양에 한도가 있어요.
ID: SHARE adalah hadiah aktivitas yang tidak dapat ditukarkan dengan uang tunai, dan ada batas jumlah yang dapat diterima per hari.

[launch.intro.body.6]
KO: 검증된 모든 달리기, 1km마다 운영자가 100원을 기부할 예정이에요. 내가 보탠 만큼은 앱에서 확인할 수 있어요.
ID: Untuk setiap lari yang terverifikasi, pengelola berencana mendonasikan 100 won per 1 km. Anda dapat melihat kontribusi Anda di aplikasi.

[launch.intro.body.7]
KO: 운영자의 월 기부 예산 안에서 진행될 예정이에요. 예산을 다 쓴 달은 넘는 거리가 기록으로 남아요.
ID: Ini direncanakan berjalan dalam batas anggaran donasi bulanan pengelola. Pada bulan ketika anggaran habis, jarak lebih akan tetap tercatat.

[launch.intro.body.8]
KO: 걷기·달리기 기록은 서버에 저장돼요. 폰을 바꿔도 로그인하면 이어져요.
ID: Catatan jalan dan lari disimpan di server. Bahkan jika berganti ponsel, Anda cukup masuk untuk melanjutkan.

[launch.intro.body.9]
KO: 100걸음
ID: 100 langkah

[launch.intro.button]
KO: 시작하기
ID: Mulai

[launch.intro.button.2]
KO: 이미 계정이 있어요 · 로그인
ID: Sudah punya akun · Masuk

[legal.health_data_consent.body]
KO: 체크해야 워치 연동·심박 검증이 활성화됩니다.
ID: Harus dicentang untuk mengaktifkan sinkronisasi jam tangan dan verifikasi detak jantung.

[legal_constants.body]
KO: 결제 취소 (현금 환불)
ID: Batalkan pembayaran (pengembalian uang tunai)

[legal_constants.body.10]
KO: 마케팅·활동 알림 (선택)
ID: Notifikasi Pemasaran & Aktivitas (Opsional)

[legal_constants.body.12]
KO: 부정 러닝·결제 어뷰징은 계정 제한 대상이 될 수 있습니다.
ID: Lari curang dan penyalahgunaan pembayaran dapat dikenakan pembatasan akun.

[legal_constants.body.14]
KO: 전체 내용은 개인정보 처리방침 전문에서 확인할 수 있습니다.
ID: Rincian lengkap dapat ditemukan di teks lengkap Kebijakan Privasi.

[legal_constants.body.17]
KO: 대회 모집, 검증 결과, 리워드·기부 알림을 푸시로 받을 수 있습니다. 언제든 MyPage에서 변경할 수 있습니다.
ID: Anda dapat menerima notifikasi push untuk perekrutan kompetisi, hasil verifikasi, hadiah, dan donasi. Anda dapat mengubahnya kapan saja di MyPage.

[legal_constants.body.18]
KO: 심박수·케이던스 원본 데이터는 기기 메모리에서 검증한 뒤 바로 폐기하며, 검증 결과 요약만 저장합니다.
ID: Data asli detak jantung dan kadens segera dimusnahkan setelah diverifikasi di memori perangkat, dan hanya ringkasan hasil verifikasi yang disimpan.

[legal_constants.body.19]
KO: 건강 정보 안내
ID: Pemberitahuan Informasi Kesehatan

[legal_constants.body.2]
KO: [선택] 건강정보(심박수) 수집 및 이용 동의
ID: [Opsional] Persetujuan Pengumpulan dan Penggunaan Informasi Kesehatan (Detak Jantung)

[legal_constants.body.21]
KO: 가슴 통증, 어지러움 등 이상이 느껴지면 즉시 운동을 멈추고 의료진과 상담하세요.
ID: Jika Anda merasakan nyeri dada, pusing, atau kelainan lainnya, segera hentikan olahraga dan konsultasikan dengan dokter.

[legal_constants.body.23]
KO: 언제든 해지할 수 있으며, 해지해도 이미 결제한 기간이 끝날 때까지 이용할 수 있습니다.
ID: Anda dapat membatalkan kapan saja dan tetap dapat menggunakannya hingga akhir periode yang telah dibayar.

[legal_constants.body.3]
KO: 건강정보 수집 동의 (선택 · 별도)
ID: Persetujuan Pengumpulan Informasi Kesehatan (Opsional · Terpisah)

[legal_constants.body.4]
KO: 개인정보 처리방침 전문 보기
ID: Lihat Kebijakan Privasi Lengkap

[legal_constants.body.5]
KO: 서비스 이용약관 전문 보기
ID: Lihat Ketentuan Layanan Lengkap

[legal_constants.body.6]
KO: AI 생성 이미지 안내
ID: Pemberitahuan Gambar Buatan AI

[legal_constants.body.7]
KO: 일부 그림은 AI로 생성되었습니다. Created with Grok
ID: Beberapa gambar dibuat oleh AI. Created with Grok

[legal_constants.body.8]
KO: 서비스 이용약관 (필수)
ID: Ketentuan Layanan (Wajib)

[legal_constants.body.9]
KO: 개인정보 처리방침 (필수)
ID: Kebijakan Privasi (Wajib)

[app.levelTestChallengeProgress]
KO: 챌린지 진행 상황: 2/3회 완료 (3.52/5.00 KM)
ID: Progres Tantangan: 2/3 selesai (3.52/5.00 KM)

[app.levelTestGhostPace]
KO: [고스트 페이스]
ID: [Pace Ghost]

[app.levelTestMyLocation]
KO: [나(현재 위치)]
ID: [Saya (Lokasi Saat Ini)]

[app.levelTestStartRun]
KO: 3회차 달리기 시작하기
ID: Mulai Lari ke-3

[app.levelTestStatDistance]
KO: 현재 거리
ID: Jarak Saat Ini

[app.levelTestStatPace]
KO: 현재 페이스
ID: Pace Saat Ini

[app.levelTestStatTime]
KO: 경과 시간
ID: Waktu Berlalu

[app.levelTestSubtitle]
KO: 검증된 달리기를 서로 다른 날 3번 마치면 등급이 배정됩니다.
ID: Selesaikan 3 lari terverifikasi pada hari yang berbeda untuk mendapatkan peringkat.

[app.levelTestTitle]
KO: 혼자 뛰기 챌린지 (등급 배정)
ID: Tantangan Lari Solo (Penempatan)

[app.liveRunningEffortTip]
KO: 순수 노력 목표: 완주 시 VALUE +$valueTokens
ID: Target usaha murni: VALUE +$valueTokens saat selesai

[app.liveRunningFinish]
KO: 종료 / 저장
ID: Selesai / Simpan

[app.liveRunningGhostPace]
KO: 고스트 페이스
ID: Pace Ghost

[app.liveRunningRoomTitle]
KO: 3km 중급 챌린지
ID: Tantangan 3 km Menengah

[app.liveRunningSubmissionsLeft]
KO: 제출 기회: 2/3회 남음
ID: Kesempatan kirim: tersisa 2/3

[app.liveRunningYouLabel]
KO: 나 (You)
ID: Anda (You)

[app.runValidationFailed]
KO: 기록 검증에 실패했습니다. 보상이 지급되지 않았습니다.
ID: Verifikasi rekaman gagal. Hadiah tidak diberikan.

[live_running.body]
KO: 1km 초보 챌린지
ID: Tantangan Pemula 1km

[live_running.body.2]
KO: 나
ID: Saya

[live_running.body.3]
KO: 고스트
ID: Ghost

[live_running.body.4]
KO: 검증 중
ID: Memverifikasi

[live_running.toast]
KO: 센서 시작 실패: $error
ID: Gagal memulai sensor: $error

[app.existingAccountApple]
KO: 애플로 가입했어요
ID: Saya mendaftar dengan Apple

[app.existingAccountBody]
KO: 그 방법으로 로그인하면 지금 $provider${subjectParticle(provider)} 그 계정에 연결돼요. 닉네임과 재화도 그대로예요.
ID: Jika Anda masuk dengan metode tersebut, $provider${subjectParticle(provider)} saat ini akan ditautkan ke akun tersebut. Nama panggilan dan mata uang Anda juga tetap sama.

[app.existingAccountCreate]
KO: 새로 시작하기
ID: Mulai dari awal

[app.existingAccountCreateHint]
KO: 기억나지 않거나 처음이신가요?
ID: Tidak ingat atau baru pertama kali?

[app.existingAccountGoogle]
KO: 구글로 가입했어요
ID: Saya mendaftar dengan Google

[app.existingAccountKakao]
KO: 카카오로 가입했어요
ID: Saya mendaftar dengan Kakao

[app.existingAccountNaver]
KO: 네이버로 가입했어요
ID: Saya mendaftar dengan Naver

[app.existingAccountNotFound]
KO: 그 방법으로 가입된 계정이 없어요. 다른 방법을 골라 주세요.
ID: Tidak ada akun yang terdaftar dengan metode tersebut. Silakan pilih metode lain.

[app.existingAccountTitle]
KO: 처음 가입할 때 어떤 방법을 쓰셨나요?
ID: Metode apa yang Anda gunakan saat pertama kali mendaftar?

[app.linkAttached]
KO: $method${subjectParticle(method)} 연결됐어요. 이제 어느 쪽으로 들어와도 같은 계정이에요.
ID: $method${subjectParticle(method)} telah ditautkan. Sekarang Anda akan mengakses akun yang sama lewat cara mana pun.

[app.linkConfirmNo]
KO: 아니에요, 다시 고를게요
ID: Tidak, pilih lagi

[app.linkConfirmTitle]
KO: 이 계정에 $method${objectParticle(method)} 연결할까요?
ID: Tautkan $method${objectParticle(method)} ke akun ini?

[app.linkConfirmYes]
KO: 네, 연결할게요
ID: Ya, tautkan

[app.loginComingSoon]
KO: $provider 로그인은 준비 중입니다.
ID: Masuk dengan $provider sedang dipersiapkan.

[app.loginGoogle]
KO: Google로 계속하기
ID: Lanjutkan dengan Google

[app.loginGuest]
KO: 게스트(테스트)로 시작하기
ID: Mulai sebagai Tamu (Tes)

[app.loginGuestLoading]
KO: 게스트 로그인 중...
ID: Masuk sebagai tamu...

[app.loginGuestNote]
KO: 게스트 모드는 워치 연동·Health Connect 테스트용 임시 계정입니다.
ID: Mode tamu adalah akun sementara untuk menguji integrasi jam tangan dan Health Connect.

[app.loginKakao]
KO: Kakao로 계속하기
ID: Lanjutkan dengan Kakao

[app.loginNaver]
KO: Naver로 계속하기
ID: Lanjutkan dengan Naver

[app.loginReferralHint]
KO: 추천 코드를 입력하세요...
ID: Masukkan kode referral...

[app.loginReferralLabel]
KO: 추천 코드가 있으신가요?
ID: Punya kode referral?

[app.loginSaveFailed]
KO: 로그인 저장 실패: $error
ID: Gagal menyimpan login: $error

[app.loginSubtitle]
KO: 세계를 향한 나눔의 질주
ID: Lari berbagi menuju dunia

[app.referralRedeemAlready]
KO: 이미 초대 코드를 입력했어요
ID: Anda sudah memasukkan kode undangan

[app.referralRedeemDone]
KO: 초대한 친구: 입력 완료
ID: Teman yang diundang: Selesai dimasukkan

[app.referralRedeemEntry]
KO: 초대 코드 입력
ID: Masukkan Kode Undangan

[app.referralRedeemExpired]
KO: 가입 후 7일이 지나 입력할 수 없어요
ID: Tidak dapat dimasukkan karena sudah lebih dari 7 hari sejak mendaftar

[app.referralRedeemFailed]
KO: 초대 코드를 등록하지 못했어요
ID: Gagal mendaftarkan kode undangan

[app.referralRedeemInvalid]
KO: 없는 초대 코드예요
ID: Kode undangan tidak ditemukan

[app.referralRedeemSelf]
KO: 본인 코드는 입력할 수 없어요
ID: Tidak dapat memasukkan kode milik sendiri

[app.referralRedeemSubmit]
KO: 등록
ID: Daftar

[app.referralRedeemSuccess]
KO: 10,000 SHARE 지급
ID: 10.000 SHARE diberikan

[login.body]
KO: 구글 로그인에 성공했습니다!
ID: Login Google berhasil!

[login.body.2]
KO: 로그인 실패:
ID: Gagal login:

[login.body.3]
KO: 애플 로그인에 성공했습니다!
ID: Login Apple berhasil!

[login.body.4]
KO: 애플 로그인 실패:
ID: Gagal login Apple:

[login.body.5]
KO: 네이버 로그인에 성공했습니다!
ID: Login Naver berhasil!

[login.body.6]
KO: 네이버 로그인 실패:
ID: Gagal login Naver:

[login.body.7]
KO: 카카오 로그인에 성공했습니다!
ID: Login Kakao berhasil!

[login.body.8]
KO: 카카오 로그인 실패:
ID: Gagal login Kakao:

[login.body.9]
KO: 닉네임 $nickname
SHARE ${groupedDigits(shareBalance)}
ID: Nama panggilan $nickname
SHARE ${groupedDigits(shareBalance)}

[login.button]
KO: 초대 코드가 있으신가요?
ID: Punya kode undangan?

[login_connections.body]
KO: $name 연결을 해제했어요.
ID: Berhasil memutuskan sambungan $name.

[login_connections.body.2]
KO: 카카오
ID: Kakao

[login_connections.body.3]
KO: 네이버
ID: Naver

[login_connections.body.4]
KO: 애플
ID: Apple

[login_connections.body.5]
KO: 구글
ID: Google

[login_connections.body.6]
KO: 같은 계정으로 여러 방법으로 로그인할 수 있어요. 연결해 두면 어떤 방법으로 들어와도 같은 SHARE와 기록이 보여요. 마지막 로그인 방법은 해제할 수 없어요.
ID: Anda dapat login menggunakan beberapa metode untuk akun yang sama. Setelah terhubung, Anda akan melihat saldo SHARE dan riwayat yang sama lewat metode apa pun. Metode login terakhir tidak dapat diputuskan.

[login_connections.body.7]
KO: 연결 안 됨
ID: Belum Terhubung

[login_connections.button]
KO: 해제하면 이 $name 계정으로는 이 쉐어런 계정에 들어올 수 없어요. 다른 로그인 방법으로는 계속 쓸 수 있어요.
ID: Jika diputuskan, Anda tidak dapat mengakses akun ShareRun ini dengan akun $name ini. Anda masih dapat menggunakan metode login lain.

[login_connections.button.2]
KO: 다시 불러오기
ID: Muat Ulang

[login_connections.button.3]
KO: 연결하기
ID: Hubungkan

[login_connections.dialog]
KO: $name 연결 해제
ID: Putuskan sambungan $name

[login_devices.body]
KO: 이 계정으로 앱을 연 기기예요. 기기 이름과 마지막으로 연 시각만 저장하고, 위치나 IP 주소는 저장하지 않아요.
ID: Perangkat yang membuka aplikasi dengan akun ini. Hanya nama perangkat dan waktu terakhir dibuka yang disimpan, lokasi atau alamat IP tidak disimpan.

[login_devices.body.2]
KO: 앱 데이터를 지우거나 다시 설치하면 같은 폰이 한 줄 더 보일 수 있어요.
ID: Menghapus data aplikasi atau menginstal ulang dapat membuat ponsel yang sama muncul dalam baris tambahan.

[login_devices.body.3]
KO: 아직 기록된 기기가 없어요.
ID: Belum ada perangkat yang tercatat.

[login_devices.body.4]
KO: 알 수 없는 기기
ID: Perangkat tidak dikenal

[login_devices.body.5]
KO: $name (이 기기)
ID: $name (Perangkat ini)

[login_devices.body.6]
KO: $name · 새 기기
ID: $name · Perangkat baru

[login_devices.body.7]
KO: ${device.osVersion} · 앱 ${device.appVersion}
마지막으로 연 시각 $when
ID: ${device.osVersion} · Aplikasi ${device.appVersion}
Terakhir dibuka $when

[login_devices.button]
KO: 이 폰을 포함해 로그인된 모든 기기에서 로그아웃돼요. 다른 기기는 잠시 뒤 로그인 화면으로 돌아가요. 계속할까요?
ID: Anda akan keluar dari semua perangkat termasuk ponsel ini. Perangkat lain akan kembali ke layar login sesaat lagi. Lanjutkan?

[login_devices.dialog]
KO: 모든 기기에서 로그아웃
ID: Keluar dari semua perangkat

[login_devices.toast]
KO: 로그아웃하지 못했어요. 잠시 후 다시 시도해 주세요.
ID: Gagal keluar. Silakan coba lagi sebentar lagi.

[app.dashboardChallenge1Sub]
KO: 참가비: 600 SHARE
ID: Biaya pendaftaran: 600 SHARE

[app.dashboardChallenge1Title]
KO: 초보 1km 챌린지 🏆
ID: Tantangan 1 km Pemula 🏆

[app.dashboardChallenge2Sub]
KO: 참가비: 1,200 SHARE
ID: Biaya pendaftaran: 1,200 SHARE

[app.dashboardChallenge2Title]
KO: 중급 3km 챌린지 (골드 대회)
ID: Tantangan 3 km Menengah (Kompetisi Emas)

[app.dashboardDailyMissionCapsule]
KO: 📍 오늘의 미션 확인하기 >
ID: 📍 Cek misi hari ini >

[app.dashboardDiamondBalance]
KO: 💎 보유 다이아몬드: 5개
ID: 💎 DIA yang dimiliki: 5

[app.dashboardDiamondBalanceOf]
KO: 💎 보유 다이아몬드: $count개
ID: 💎 DIA yang dimiliki: $count

[app.dashboardGradeRunLabel]
KO: 등급 배정 달리기:
ID: Lari Penentuan Peringkat:

[app.dashboardGradeRunProgress]
KO: 2/3회 완료 >
ID: 2/3 selesai >

[app.dashboardOngoingChallenges]
KO: 진행 중인 챌린지
ID: Tantangan yang Sedang Berjalan

[app.dashboardShareBalance]
KO: 보유 SHARE: 90,000
ID: SHARE yang dimiliki: 90,000

[app.dashboardShareBalanceOf]
KO: 보유 SHARE: $amount
ID: SHARE yang dimiliki: $amount

[app.dashboardStampMapTooltip]
KO: 오늘의 미션 · 스탬프 투어
ID: Misi Hari Ini · Tur Stempel

[app.dashboardValueBalance]
KO: 🌱 보유 밸류(VALUE): 5,200
ID: 🌱 VALUE yang dimiliki: 5,200

[app.dashboardValueBalanceOf]
KO: 🌱 보유 밸류(VALUE): $amount
ID: 🌱 VALUE yang dimiliki: $amount

[app.dashboardViewRoom]
KO: 대회 상세 보기
ID: Lihat Detail Kompetisi

[app.exitGuardMessage]
KO: 나눔의 질주를 잠시 쉬어가시겠습니까? 한 번 더 누르시면 종료됩니다.
ID: Ingin istirahat sejenak dari lari berbagi? Tekan sekali lagi untuk keluar.

[app.myWalletCharge]
KO: 교환하기
ID: Tukar

[app.myWalletChargeDia]
KO: 다이아몬드
ID: DIA

[app.myWalletChargeDiaHint]
KO: 교환소에서 SHARE로 바꾸거나 연속 달리기로 모을 수 있어요
ID: Anda dapat menukarnya dengan SHARE di tempat penukaran atau mengumpulkannya melalui lari beruntun.

[app.myWalletChargeShareHint]
KO: 활동으로 모을 수 있어요
ID: Dapat dikumpulkan melalui aktivitas.

[app.myWalletChargeValue]
KO: 밸류(VALUE)
ID: VALUE

[app.myWalletChargeValueHint]
KO: 달리기로 모을 수 있어요
ID: Dapat dikumpulkan dengan berlari.

[app.myWalletDiamondLabel]
KO: 보유 다이아몬드: $count개
ID: DIA yang dimiliki: $count

[app.myWalletGradeProgress]
KO: 등급 배정 달리기: $done/$total회 완료 >
ID: Lari Penempatan: $done/$total selesai >

[app.myWalletInventoryCount]
KO: 보유 $count
ID: Dimiliki $count

[app.myWalletInventoryEmpty]
KO: 아직 보유한 아이템이 없습니다.
ID: Belum ada item yang dimiliki.

[app.myWalletInventoryOpen]
KO: 보관함 보기
ID: Lihat Inventaris

[app.myWalletInventoryTitle]
KO: 보유 아이템
ID: Item yang Dimiliki

[app.myWalletItemDuringRun]
KO: 달리기 중 사용 가능
ID: Dapat digunakan saat berlari

[app.myWalletItemDuringTournament]
KO: 대회에서 사용 가능
ID: Dapat digunakan dalam kompetisi

[app.myWalletRecentTransactions]
KO: 최근 거래 내역
ID: Riwayat Transaksi Terbaru

[app.myWalletUse]
KO: 상점 가기
ID: Pergi ke Toko

[app.myWalletValueLabel]
KO: 보유 밸류(VALUE): $amount
ID: VALUE yang dimiliki: $amount

[app.walletUnconfirmedNote]
KO: 서버에서 확인하는 중이에요. 지금 보이는 값은 마지막으로 확인된 값이에요.
ID: Sedang memeriksa dengan server. Nilai yang ditampilkan adalah nilai terakhir yang dikonfirmasi.

[main_dashboard.body]
KO: 상품은 다이아예요 · ${AppStrings.noCashPrizePool}
ID: Hadiahnya adalah DIA · ${AppStrings.noCashPrizePool}

[main_dashboard.body.2]
KO: 좋은 아침이에요
ID: Selamat pagi

[main_dashboard.body.3]
KO: 좋은 오후예요
ID: Selamat siang

[main_dashboard.body.4]
KO: 좋은 저녁이에요
ID: Selamat malam

[main_dashboard.body.5]
KO: ${_hello(DateTime.now().hour)}, $nickname님
ID: ${_hello(DateTime.now().hour)}, $nickname

[main_shell_routes.body]
KO: 결제 정보가 없어 PG 화면을 열 수 없습니다.
ID: Tidak dapat membuka layar PG karena informasi pembayaran tidak ada.

[main_shell_routes.body.2]
KO: 대회 정보가 없어 스폰서 결제를 열 수 없습니다.
ID: Tidak dapat membuka pembayaran sponsor karena informasi kompetisi tidak ada.

[main_shell_routes.button]
KO: 대회 목록으로
ID: Daftar Kompetisi

[map_crew.body]
KO: 지도 & 크루
ID: Peta & crew

[map_crew.body.2]
KO: 크루 종합 랭킹
ID: Peringkat keseluruhan crew

[map_crew.body.3]
KO: ${crews[index].memberCount}명
ID: ${crews[index].memberCount} anggota

[map_crew.body.4]
KO: 아직 크루 순위가 없어요
ID: Belum ada peringkat crew

[map_crew.body.5]
KO: 크루 순위가 쌓이면 여기에 나타나요.
ID: Peringkat crew akan muncul di sini setelah terkumpul.

[map_crew.body.6]
KO: ${collectRadiusMeters.round()}m 안으로 가까이 가야 받을 수 있어요.
ID: Anda harus mendekat dalam jarak ${collectRadiusMeters.round()}m untuk mengambilnya.

[map_crew.body.7]
KO: +${box.rewardDiamond} DIA를 받았어요.
ID: Menerima +${box.rewardDiamond} DIA.

[map_crew.body.8]
KO: ${distanceMeters!.toStringAsFixed(0)}m 떨어져 있어요
ID: Berjarak ${distanceMeters!.toStringAsFixed(0)}m

[map_crew.button]
KO: 내 위치 새로고침
ID: Perbarui Lokasi

[map_crew.button.2]
KO: 다이아 상자 받기
ID: Ambil Kotak DIA

[map_crew.button.3]
KO: 더 가까이 가 주세요
ID: Harap mendekat lagi

[map_crew.crew_member_ranking_board.body]
KO: 크루원 랭킹 데이터 없음
ID: Tidak ada data peringkat anggota crew

[map_crew.crew_member_ranking_board.body.2]
KO: 출석률·평균 페이스가 여기에 표시됩니다.
ID: Tingkat kehadiran dan pace rata-rata akan ditampilkan di sini.

[map_crew.crew_member_ranking_board.body.3]
KO: 크루원 출석률 & 평균 페이스
ID: Tingkat Kehadiran & Pace Rata-rata Anggota Crew

[map_crew.crew_member_ranking_board.body.4]
KO: 출석률 높은 순 · 페이스 빠른 순으로 B2B 크루 성과를 추적합니다.
ID: Lacak performa B2B crew berdasarkan kehadiran tertinggi dan pace tercepat.

[map_crew.crew_member_ranking_board.body.5]
KO: 출석 ${member.attendanceRate.toStringAsFixed(0)}%
ID: Kehadiran ${member.attendanceRate.toStringAsFixed(0)}%

[map_crew.safe_map_panel.body]
KO: 지도 준비 중
ID: Menyiapkan peta

[mini_bot.body]
KO: 궁금한 게 있으면 저를 눌러 물어보세요
ID: Ketuk saya jika Anda memiliki pertanyaan

[mini_bot.body.10]
KO: 하루 SHARE 한도
ID: Batas SHARE Harian

[mini_bot.body.11]
KO: 어떤 대회?
ID: Kompetisi apa?

[mini_bot.body.12]
KO: 순위별 상금
ID: Hadiah berdasarkan Peringkat

[mini_bot.body.13]
KO: 초급은 무료?
ID: Tingkat pemula gratis?

[mini_bot.body.14]
KO: SHARE잔액
ID: Saldo SHARE

[mini_bot.body.15]
KO: VALUE잔액
ID: Saldo VALUE

[mini_bot.body.16]
KO: 등급
ID: Tingkat

[mini_bot.body.17]
KO: 오늘기부기여
ID: Kontribusi Donasi Hari Ini

[mini_bot.body.18]
KO: 이 버전에서는 앱 안에서 결제하지 않아요.
ID: Dalam versi ini, pembayaran dalam aplikasi tidak diproses.

[mini_bot.body.19]
KO: 궁금한 걸 물어보세요
ID: Tanyakan apa yang ingin Anda ketahui

[mini_bot.body.2]
KO: 오늘 목표나 SHARE가 궁금하면 물어보세요
ID: Tanyakan kepada saya tentang target hari ini atau SHARE

[mini_bot.body.3]
KO: 기록 지키기가 헷갈리면 제가 알려 드려요
ID: Jika Anda bingung cara melindungi rekor, saya bisa beri tahu.

[mini_bot.body.4]
KO: 어떤 챌린지가 맞는지 모르겠으면 물어보세요
ID: Tanyakan kepada saya jika Anda tidak tahu tantangan mana yang cocok

[mini_bot.body.5]
KO: 참가비와 순위별 상금이 궁금하면 눌러 보세요
ID: Ketuk di sini jika Anda ingin tahu biaya masuk dan hadiah berdasarkan peringkat

[mini_bot.body.6]
KO: 초급은 무료인지도 알려 드려요
ID: Saya juga bisa memberi tahu apakah tingkat pemula gratis

[mini_bot.body.7]
KO: 오늘 내 기부
ID: Donasi Saya Hari Ini

[mini_bot.body.8]
KO: 내 SHARE
ID: SHARE Saya

[mini_bot.body.9]
KO: 내 등급
ID: Tingkat Saya

[mini_bot.button]
KO: 멈추기
ID: Berhenti

[mini_bot.button.2]
KO: 말하기
ID: Bicara

[mini_bot.button.3]
KO: 보내기
ID: Kirim

[mini_bot.hint]
KO: 한글로 말해 주세요
ID: Ucapkan atau ketik pertanyaanmu

[mini_bot.mini_bot_dock.accessibility]
KO: 달팽이봇
ID: Bot Siput

[mini_bot.mini_bot_dock.body]
KO: 끌어서 옮길 수 있어요
ID: Seret untuk memindahkan

[mini_bot.mini_bot_intent.body]
KO: 후원하기
ID: Donasi

[mini_bot.mini_bot_intent.body.10]
KO: 다이아 교환
ID: Penukaran DIA

[mini_bot.mini_bot_intent.body.11]
KO: 스폰서
ID: Sponsor

[mini_bot.mini_bot_intent.body.12]
KO: 러너 후원
ID: Dukungan Pelari

[mini_bot.mini_bot_intent.body.13]
KO: 배틀패스
ID: Battle Pass
