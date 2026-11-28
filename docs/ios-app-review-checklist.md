# iOS App Store 심사 입력표 (App Store Connect)

작성일: 2026-11-28. 근거: `ios/Runner/Info.plist`, `ios/Runner/PrivacyInfo.xcprivacy`, 워치 앱 `ios/ShareRunWatch Watch App/`, `docs/play-data-safety.md`, `site/privacy.html`.
**초안입니다.** App Store Connect에 넣기 전에 대표님이 한 번 더 확인합니다. Play 답변(`docs/play-data-safety.md`)과 내용이 같아야 합니다.

- 번들 ID: `com.sharerun.shareRunChallenge`, 워치: `com.sharerun.shareRunChallenge.watchkitapp`
- 팀: `7C429Q46CL` (자동 서명)
- iOS는 이전 전까지 **무료 앱**입니다. 결제 스위치는 꺼진 채로 빌드합니다(`docs/ios-testflight-setup.md`).

---

## 1. 심사 전에 꼭 할 것 (막히는 항목)

| # | 항목 | 왜 | 할 일 |
|---|---|---|---|
| 1 | **Sign in with Apple 켜기** | 구글·카카오·네이버 로그인이 있는 앱은 애플 로그인도 있어야 합니다(지침 4.8). 지금 기본값은 꺼짐이고 화면에 "준비 중"으로 보입니다 | iOS 빌드의 `DART_DEFINES_JSON`에 `"APPLE_LOGIN_ENABLED": "true"`. Firebase 인증에서 Apple 제공업체 켜기 |
| 2 | **심사관 로그인 방법** | 소셜 로그인만 있으면 심사관이 들어갈 수 없습니다(지침 2.1) | 아래 "심사 메모"의 테스트 계정 준비. 애플 로그인이 켜져 있으면 심사관이 자기 Apple ID로 들어갈 수도 있지만, 데이터가 있는 계정을 따로 주는 것이 안전합니다 |
| 3 | **푸시 알림 키(APNs)** | 친구 응원·대회 알림을 iPhone에 보내려면 필요합니다. 없어도 심사는 통과하지만 알림이 안 옵니다 | Apple Developer → Keys에서 APNs 키(.p8)를 만들어 Firebase 콘솔 → 프로젝트 설정 → 클라우드 메시징 → Apple 앱 구성에 올림 |
| 4 | **HealthKit 기능** | 앱이 Apple 건강에서 걸음 수를 읽습니다 | Apple Developer → Identifiers에서 두 번들 ID 모두 HealthKit 켜짐 확인(자동 서명이 켜 줄 수 있음) |

## 2. 앱 개인정보 (App Privacy) 답변

App Store Connect → 앱 → **앱 개인정보** → "데이터를 수집합니까?" → **예**.

모든 항목 공통:
- **추적(Tracking): 아니요.** 광고 SDK, 광고 ID, 다른 회사 앱·웹사이트와 데이터를 합치는 일이 없습니다. 그래서 앱 추적 투명성(ATT) 팝업도 없습니다.
- **사용자에게 연결됨: 예.** 모두 로그인 계정에 묶여 저장됩니다.
- **목적: 앱 기능.** (부정 기록 방지도 앱 기능에 포함해 답합니다. 애플 선택지에 "부정 행위 방지"가 따로 있으면 그것도 고릅니다.)

| Apple 데이터 유형 | 쉐어런에서 무엇 | 수집 | 연결 | 추적 | 메모 |
|---|---|---|---|---|---|
| 연락처 정보 > 이메일 주소 | 로그인 이메일 | 예 | 예 | 아니요 | |
| 건강 및 피트니스 > 건강 | 심박수(블루투스 센서·Apple Watch), 걸음 수(Apple 건강) | 예 | 예 | 아니요 | 심박 원본은 검증 계산에만 쓰고 저장하지 않음 |
| 건강 및 피트니스 > 피트니스 | 달리기 거리·시간·속도, 하루 걸음 | 예 | 예 | 아니요 | |
| 위치 > 정확한 위치 | 달리기 경로 | 예 | 예 | 아니요 | 출발·도착 300m는 빼고 저장 |
| 사용자 콘텐츠 > 사진 또는 비디오 | 기록 소명 증빙 사진 | 예 | 예 | 아니요 | 결정하면 바로, 아니면 14일 뒤 삭제. 완주 카드·아바타 사진은 서버로 보내지 않음 |
| 사용자 콘텐츠 > 기타 사용자 콘텐츠 | 닉네임, 크루 이름, 소명 글, 친구 관계, 정해진 응원 5종 | 예 | 예 | 아니요 | |
| 식별자 > 사용자 ID | 계정 ID | 예 | 예 | 아니요 | |
| 식별자 > 기기 ID | 앱이 만든 기기 식별 값, 알림 토큰 | 예 | 예 | 아니요 | 광고 ID 아님 |
| 진단 > 충돌 데이터 | 앱 오류가 나면 오류 메시지와 위치(스택)를 서버로 보냄(세션당 최대 10건) | 예 | 예 | 아니요 | **Play 양식은 "수집 안 함"으로 되어 있어 맞출 필요** (아래 5번) |
| 구입 항목 > 구입 내역 | — | **아니요** | | | iOS 결제를 켜는 빌드부터 "예"로 바꿈 |
| 오디오 데이터 | — | 아니요 | | | 마이크 소리는 기기·Apple 음성 인식이 처리하고 앱은 보내거나 저장하지 않음 |
| 연락처, 검색·탐색 기록, 금융, 민감 정보, 광고 데이터, 사용 데이터 | — | 아니요 | | | 분석 SDK 없음 |

개인정보처리방침 URL: `https://share-run-challenge.web.app/privacy.html`
계정 삭제 안내: 앱 `설정 > 계정 삭제`, 웹 `https://share-run-challenge.web.app/account-deletion.html`

## 3. 연령 등급 설문 (예상 답변)

| 질문 | 답 |
|---|---|
| 만화·실사 폭력, 성적 콘텐츠, 공포, 비속어, 약물·음주·흡연 | 없음 |
| 의료·치료 정보 | 없음(진단·치료 기능 없음. 걸음·심박은 기록 확인용) |
| 도박, 사행성 | 없음. **확인:** 상금 대회·DIA가 "모의 도박"으로 읽히지 않는지. 1.0 iOS는 결제가 꺼져 있고 상금 대회 참가비는 앱 안 포인트(SHARE)입니다 |
| 사용자 생성 콘텐츠 | 있음(닉네임, 크루 이름). 신고·차단 기능 있음 |
| 무제한 웹 접근 | 없음(웹뷰는 정해진 안내·결제 페이지만) |
| 위치 공유 | 다른 이용자에게 경로·위치를 보여 주지 않음 |
| 예상 등급 | **4+ 또는 12+**. 사용자 생성 콘텐츠 때문에 12+를 권장. 가입 연령은 만 14세 이상 |

## 4. 심사 메모 (App Review Information)

**로그인 정보:** 테스트 계정이 **필요합니다.**
- 사용자 이름/암호 칸: 심사용 계정(대표님이 만든 Apple ID 또는 구글 계정)과 로그인 방법을 적습니다.
- 계정에 달리기 기록 1개 이상, 친구 1명 정도를 미리 만들어 두면 화면 확인이 쉽습니다.

**메모 칸에 붙일 글 (영어):**

> ShareRun is a walking and running challenge app. Users earn SHARE points for verified runs and steps, and the company donates on their behalf. There are no in-app purchases in this build.
>
> HealthKit: the iPhone app only READS step count to show today's steps and step-donation goals. It never writes to Health. The Apple Watch app reads heart rate, steps and distance during a workout and saves the finished running workout to Health (HKWorkoutSession).
>
> Location (When In Use): used only while the user records a run, to measure route and distance and to detect fake runs. Background location mode keeps the recording going when the screen turns off during a run; the blue location indicator is shown. We do not ask for "Always" location.
>
> Bluetooth: connects a standard BLE heart rate sensor during a run.
> Background fetch: used by the step-count keep-alive task (flutter_foreground_task) to refresh today's steps.
> Microphone and Speech Recognition: only when the user taps the mic to ask the in-app help bot (Snail Bot).
>
> Sign in: use the demo account above, or Sign in with Apple.

## 5. 수출 규정 (암호화)

- `Info.plist`에 `ITSAppUsesNonExemptEncryption = false`를 넣었습니다. 업로드할 때마다 묻지 않습니다.
- 근거: 앱은 표준 HTTPS(Firebase, 자체 서버)만 씁니다. 코드의 `crypto` 패키지는 결제 계정 값의 SHA-256 해시를 만드는 데만 쓰고, 데이터를 암호화하지 않습니다. 직접 만든 암호 알고리즘이 없습니다.
- App Store Connect에서 묻는다면: "앱이 암호화를 사용합니까?" → 예, "면제 대상(표준 암호화만 사용)" → 예. 프랑스 배포용 서류는 필요 없습니다.

## 6. 권한 문구 정리 (이번 PR)

iPhone 앱에 남긴 권한 문구와 쓰는 곳:

| 키 | 쓰는 곳 |
|---|---|
| `NSHealthShareUsageDescription` | Apple 건강에서 걸음 수 읽기(`health` 패키지, 읽기만) |
| `NSLocationWhenInUseUsageDescription` | 달리기 경로·거리(`geolocator`, 백그라운드 기록 포함) |
| `NSMotionUsageDescription` | 걸음 세기(`pedometer`, `sensors_plus`) |
| `NSBluetoothAlwaysUsageDescription` | 블루투스 심박 센서(`BleHeartRatePlugin.swift`) |
| `NSCameraUsageDescription` | 완주 카드 사진 찍기(`image_picker` 카메라) |
| `NSPhotoLibraryUsageDescription` | 아바타·완주 카드·소명 증빙 사진 고르기 |
| `NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription` | 달팽이봇 말하기(`speech_to_text`) |
| `NSFaceIDUsageDescription` | 결제 전 본인 확인(`local_auth`). iOS 결제는 꺼져 있지만 코드가 들어 있어 문구는 둠 |

- 문구는 한국어 기본(`Info.plist`)과 11개 언어 `InfoPlist.strings`(`ios/Runner/*.lproj`)에 있습니다. **번역은 원어민 검수 전**입니다.
- 지운 키: `NSLocationAlwaysAndWhenInUseUsageDescription`, `NSLocationAlwaysUsageDescription`(항상 위치를 요청하지 않음), `NSBluetoothPeripheralUsageDescription`(iOS 13부터 쓰지 않는 옛 키), 백그라운드 모드 `processing`(쓰는 코드 없음).
- `NSHealthUpdateUsageDescription`은 iPhone 앱에는 없습니다(쓰기 없음, PR #412). 워치 앱에는 있습니다(운동 저장).

## 7. 스토어 문구 (별도 작성 필요)

- 부제(30자), 키워드(100자), 프로모션 텍스트(170자), 설명문. Play 문구를 바탕으로 Apple Watch·Apple 건강 연동을 넣어 따로 씁니다.
- 스크린샷: 6.9인치 iPhone 필수. 워치 앱을 넣으면 Apple Watch 스크린샷도 필요합니다.
