# iOS 개인정보 매니페스트(`PrivacyInfo.xcprivacy`) 준비

작성일: 2026-11-08. **iOS 빌드는 한 번도 실행하지 않았다.** 아래는 소스를 글자로 검색한 근거이고, 마지막 확인은 Mac에서 Xcode로 한다.
검색 도구: `python3 tool/ios/scan_required_reason_apis.py [--lines]` (`flutter pub get` 뒤에 실행. 사유 코드는 정하지 않는다).

## 1. 원칙과 출처
- Apple 문서 "Describing use of required reason API"(developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)와 범주별 사유 코드 표(같은 문서의 `NSPrivacyAccessedAPIType` 항목)를 **Apple 문서 데이터(JSON)로 직접 받아 읽었다(2026-11-08).** 사용자 화면으로는 본문이 비어 보였지만 문서 데이터에서 코드별 설명이 확인됐다.
- 문서 원문 요지: "If you use the API in your app's code, then you need to report the API in your app's privacy manifest file. If you use the API in your third-party SDK's code, then you need to report the API in your third-party SDK's privacy manifest file. Your third-party SDK can't rely on the privacy manifest files for apps that link the third-party SDK…" 그리고 "For each executable or dynamic library in an app that uses a required reason API, the bundle that includes the executable or dynamic library needs to include a privacy manifest file that reports the API."
- **사유 코드는 Apple 표의 허용 조건과 실제 코드 동작을 맞대어 보고, 맞는 것만 넣는다.** 맞는 것이 없으면 비운다.
- 개인정보 수집 데이터 종류(`NSPrivacyCollectedDataTypes`)는 App Store Connect "앱 개인정보" 답변과 같아야 하므로 대표님 확정이 필요하다.
- 검색 도구: `python3 tool/ios/scan_required_reason_apis.py [--lines]` (`flutter pub get` 뒤에 실행. 글자 검색이라 사유 코드는 정하지 않는다).

## 2. 앱 자체 코드 (확인함)
| 대상 | 필수 사유 API 사용 | 근거 |
|---|---|---|
| `ios/Runner`(`AppDelegate.swift`, `BleHeartRatePlugin.swift`, `WatchBridgePlugin.swift`) | **없음** | 스캔 결과 후보 0건 |
| 애플워치 앱(`ios/ShareRunWatch Watch App`) | UserDefaults | `WatchAccountManager.swift:13`, `WatchSyncQueue.swift:126`. 워치를 빌드에 넣을 때만 해당, 워치 타깃은 자기 매니페스트가 따로 필요. 키는 앱 전용(App Group 없음)이라 `CA92.1`에 맞는 것으로 보이나 워치를 넣을 때 다시 대조 |
→ 워치를 1차에서 빼면 앱 자체가 선언할 필수 사유 API는 없다.

## 3. 플러그인 — 사유 코드를 Apple 표와 대조한 결과
| 플러그인 | 자체 매니페스트 | 사용 | Apple 표와 대조 | 결과 |
|---|---|---|---|---|
| `flutter_foreground_task` 9.2.2 | 없음(최신 11.0.3도 없음) | UserDefaults(`ios/Classes/models/*.swift`: `UserDefaults.standard`에 플러그인이 정한 키 `BACKGROUND_SERVICE_ACTION`, `CALLBACK_HANDLE`, 알림 문구·옵션 등을 읽고 씀. App Group 없음) | **`CA92.1`** "Declare this reason to access user defaults to read and write information that is only accessible to the app itself." 이 코드는 시스템이나 다른 앱이 쓴 값을 읽지 않고, 다른 앱이 읽을 수 있게 쓰지도 않는다. `1C8F.1`(App Group)은 App Group이 없어 아님. `C56D.1`은 SDK가 앱을 위한 래퍼로만 접근하는 경우의 SDK 전용 코드라 앱에서 쓰지 않음 | **`CA92.1` 적용(앱 매니페스트에 준비함).** 단 Apple 문서는 SDK 자신의 매니페스트에 선언하라고 하므로 앱 쪽 선언이 검증을 통과시키는지는 업로드에서 확인(미해결 U2) |
| `pedometer` 4.2.0 | 없음(최신도 4.2.0, 없음) | 시스템 부팅 시간: `PedometerPlugin.swift:92-95` `systemUptime`으로 `dateOfLastReboot = now - systemUptime`을 계산하고 `CMPedometer.startUpdates(from: dateOfLastReboot)`의 **시작 시각**으로 넘김. 결과는 걸음 수 스트림으로만 앱에 전달 | `35F9.1` "measure the amount of time that has elapsed between events that occurred within the app or … enable timers": **아니다.** 두 사건 사이 경과 시간을 재거나 타이머를 만드는 용도가 아니라 걸음 집계 시작 시각을 정하는 용도다. `8FFB.1` "calculate absolute timestamps for events that occurred within your app, such as … UIKit or AVFAudio": **아니다.** 앱 내 이벤트의 절대 시각 계산이 아님. `3D61.1`(사용자가 보내는 버그 리포트): 아님. 또 `35F9.1`·`8FFB.1`은 "부팅 시간이나 거기서 파생한 정보를 기기 밖으로 보내면 안 된다"는 조건이 있는데, 이 값으로 정한 시작 시각 이후의 걸음 수는 서버로 올라가므로 "파생 정보" 해석이 갈릴 수 있다 | **맞는 사유 코드가 없다 → 비워 둠(미해결 U1)** |
| `firebase_auth` 6.5.4 | 없음 | `PigeonParser.m:47` `user.metadata.creationDate` | Firebase 사용자 객체의 가입 시각 속성이다. Apple 표의 파일 시간 정보 API(`creationDate` 등 파일 속성)가 아니다 | **오탐으로 판단.** Firebase iOS SDK 자체 매니페스트는 미확인(U3) |
| `device_info_plus`, `package_info_plus`, `sensors_plus`, `firebase_messaging`, `flutter_local_notifications`, `permission_handler_apple`, `shared_preferences_foundation` | 있음 | 위 범주의 API | 각 플러그인이 자기 매니페스트에서 선언 | 앱은 할 일 없음 |
| 그 밖의 플러그인(`health`, `flutter_tts`, `sign_in_with_apple`, `speech_to_text`, `audioplayers_darwin`, `firebase_core`, `cloud_firestore`, `flutter_naver_login`, `geolocator_apple`, `google_maps_flutter_ios`, `google_sign_in_ios`, `image_picker_ios`, `local_auth_darwin`, `kakao_*`) | 있음/없음 섞임 | 소스 검색 후보 0건 | | 선언할 API 없음 |
| Flutter 엔진, CocoaPods 바이너리 SDK(Firebase, Google Maps, Google Sign-In, Kakao 등) | 미확인 | 소스를 볼 수 없음 | | Mac의 Privacy Report로 확인(U3) |

## 4. 준비한 매니페스트: `ios/Runner/PrivacyInfo.xcprivacy`
| 키 | 값 | 근거 |
|---|---|---|
| `NSPrivacyTracking` | `false` | 광고·분석·어트리뷰션 SDK가 없다(`pubspec.yaml` 검색). "추적"의 법적 정의는 대표님이 최종 확인 |
| `NSPrivacyTrackingDomains` | 빈 배열 | 위와 같음 |
| `NSPrivacyAccessedAPITypes` | `UserDefaults` → `[CA92.1]` **만** | 3절 첫 행 |
| 넣지 않은 것 | `SystemBootTime`, `NSPrivacyCollectedDataTypes` | 앞의 것은 맞는 코드가 없고(U1), 뒤의 것은 앱 개인정보 답변과 맞춰 대표님 확정 필요(빈 배열은 "수집 없음"이라는 틀린 선언이 되어 키를 생략) |
이 파일은 **Xcode 프로젝트에 아직 연결돼 있지 않다**(Runner 타깃의 Copy Bundle Resources에 추가해야 효력이 있음, Mac 필요). `tool/ios/check_ios_config.py`가 사유 코드가 빈 범주, 근거 없는 범주가 없는지 검사한다.

### 미해결 항목 (정확히)
| # | 내용 | 다음 조치 | 누가 |
|---|---|---|---|
| **U1** | `pedometer`의 `systemUptime` 사용에 맞는 사유 코드가 Apple 표에 없다(위 3절). 업로드 때 "필수 사유 API 선언 누락"이 나올 수 있다 | (a) 업로드 검증 결과를 보고 판단. (b) 플러그인 저장소에 문의하거나 포크해 `systemUptime` 없이 당일 0시를 시작 시각으로 쓰도록 바꾸는 방법(앱 동작이 바뀌므로 걸음 수 시험 필요). (c) Apple에 `35F9.1` 해당 여부 문의 | 대표님 결정 후 참모 |
| **U2** | Apple 문서는 SDK가 자기 매니페스트에 선언해야 한다고 한다. 매니페스트가 없는 플러그인(`flutter_foreground_task`)의 API 사용을 앱 매니페스트에 선언하면 업로드 검증이 통과하는지는 문서로 확인되지 않았다 | Mac에서 첫 업로드(또는 Archive 검증) 결과로 확인. 막히면 플러그인에 `PrivacyInfo.xcprivacy`를 넣는 풀 리퀘스트 또는 포크 | 참모(Mac) |
| **U3** | Flutter 엔진과 바이너리 SDK의 매니페스트 | Archive > Generate Privacy Report | 참모(Mac) |
| **U4** | 워치 타깃을 넣게 되면 워치용 매니페스트 | 워치를 넣을 때 `CA92.1` 적합성 재대조. 참고: `WatchAccountManager.swift`가 갱신 토큰을 `UserDefaults`에 평문 저장한다(키체인이 더 안전). 별도 검토 | 워치를 넣을 때 |

## 5. 수집 데이터 종류 매핑 재료 (대표님 확정 필요)
`docs/play-data-safety.md` 2절 기준. Apple 분류 이름은 이 문서에서 단정하지 않는다(공식 표 확인 필요).
| 쉐어런이 다루는 것 | 서버로 가는가 | 비고 |
|---|---|---|
| 위치(러닝 경로, 정밀 위치) | 예(출발·도착 300m 제외 후) | 선택(거부해도 만보기 가능) |
| 걸음 수, 러닝 거리·시간·속도 | 예 | 하루 걸음은 서버 저장 |
| 심박수(블루투스 센서) | 예(검증 계산에 쓰고 원본 저장 안 함, 서버 확인 필요) | 선택, 별도 동의 |
| 이메일, 로그인 서비스 식별 값, 닉네임 | 예 | 로그인 필수 |
| 기기 식별 값, 푸시 토큰 | 예 | |
| 사진 | 이의 신청 증빙만 서버로 | 아바타·완주 카드 사진은 서버로 안 보냄 |
| 구매 정보 | 해당 없음(1.0 결제 비활성) | |
| 마이크 음성 | 수집 안 함(기기 음성 인식) | |

## 6. Mac에서 배포 전에 검증할 것 (Mac 필요)
1. `flutter build ipa --release …` 뒤 Xcode Organizer > Archive > **Generate Privacy Report**로 앱과 모든 SDK의 매니페스트를 합친 결과를 본다. 앱 쪽에 빠진 선언은 여기에 드러난다.
2. App Store Connect 업로드에서 "ITMS-91053(필수 사유 API 선언 누락)" 같은 경고가 나오면 오류 원문을 기록하고 해당 범주의 사유를 공식 표에서 골라 추가한다.
3. `tool/ios/scan_required_reason_apis.py`를 `pod install` 뒤 Pods 폴더에도 돌려 보고(경로를 바꿔 쓰면 됨) 바이너리가 아닌 소스 SDK의 후보를 더 찾는다.

## 7. U1(pedometer 부팅 시간) 대안과 최소 수정안 (조사 2026-11-08)
**현재 사용**: `pedometer` 4.2.0 `PedometerPlugin.swift:92-95`가 `systemUptime`으로 마지막 부팅 시각을 구해 `CMPedometer.startUpdates(from:)`의 시작 시각으로 쓴다. Apple 허용 사유(35F9.1, 8FFB.1, 3D61.1)와 맞지 않는다(3절). 임의 코드로 채우지 않는다.

**Archive 통과와 정책 적합성은 다르다**: 매니페스트에 `SystemBootTime`을 아무 코드로나 선언하면 업로드 검증(선언 누락 경고)은 통과할 수 있다. 그러나 그것은 사실과 다른 선언이므로 정책 적합이 아니다(이 판단은 위 사유 설명문과 코드를 대조한 해석이며 Apple의 검증 방식 자체는 미확인). 선언하지 않고 두면 업로드에서 경고/거부가 나올 수 있다 — 결과는 Mac의 첫 업로드에서만 알 수 있다(미실행).

**패키지 상황**: `pedometer` 4.2.0이 최신이고 자체 매니페스트가 없다. 더 새 버전 해결책은 없다.

**우리 앱이 이 값을 쓰는 방식**(코드 읽기): `solo_pedometer_engine.dart:157-166`은 구독 후 첫 이벤트 값을 기준(baseline)으로 삼아 이후 증가분만 쓰고, `today_steps.dart:60-97`도 첫 값을 기준으로 증가분을 계산하며 `raw < previousRaw`는 무시한다. 즉 **시작 시각 자체가 아니라 구독 중 값의 증가분**이 걸음 수가 된다. 단 `main.dart:153`(테스트 초기화)과 저장된 `stepOffset`은 절대값을 쓴다.

**최소 수정안(권장 순서)**
1. **플러그인 포크/패치**: `systemUptime` 3줄을 지우고 `startUpdates(from: Calendar.current.startOfDay(for: Date()))`(오늘 0시, 기기 시간대)로 바꾼다. `dependency_overrides`로 포크를 가리킨다. 부팅 시간 API를 아예 쓰지 않으므로 SystemBootTime 선언이 필요 없다. 걸음 집계가 증가분 기반이라 정확도는 유지될 것으로 보이나 **다음이 미확인이라 실기기 시험이 필요**하다: (a) 0시로 시작하면 구독 직후 누적 값이 바로 오는지(오지 않으면 첫 이벤트 기준이 늦어져 구독 직전 걸음이 빠짐), (b) 자정을 넘겨 구독이 유지될 때와 새 구독 때 값의 의미 변화, (c) `main.dart:153`·`stepOffset`처럼 절대값을 쓰는 곳(iOS 첫 출시라 과거 저장값은 없음). 시험표 `ios-device-test-plan.md`에 항목 추가 필요.
2. **앱 쪽 얇은 채널**: Runner에 CMPedometer 채널을 직접 구현(부팅 시간 없이). 수정 범위가 크고 Dart 쪽 교체까지 필요해 1번보다 무겁다.
3. **업로드 결과를 보고 결정**: 아무것도 바꾸지 않고 첫 업로드의 검증 결과를 확인. 경고가 나오면 1번.
대표님 결정이 필요한 것: 1번 진행 여부(포크 유지 부담 vs. 업로드 위험). 구현은 하지 않았다.

### 7-1. 검증 준비 (2026-11-08)
**현재 vs "오늘 0시" 후보의 차이**
| | 현재(부팅 시각 기준) | 후보(오늘 0시 기준) |
|---|---|---|
| CMPedometer 시작 시각 | 마지막 부팅 | 오늘 0시(앱의 하루는 KST 달력, 기기 시간대와 다를 수 있음 → 0시를 어느 시간대로 할지 결정 필요) |
| 원시 값 의미 | 부팅 이후 누적(재부팅 전까지 단조 증가) | 오늘 0시 이후 누적(새 구독이 자정 뒤면 작은 값에서 다시 시작) |
| 부팅 시간 API | 사용(사유 코드 없음) | 사용 안 함 |
| 앱의 걸음 계산 | 첫 이벤트를 기준으로 증가분 | 같음 → 값이 일정하게 이동하는 것은 영향 없음(테스트) |
| 위험 | – | 자정을 넘긴 스트림 뒤 새 구독의 값이 더 작으면 `TodaySteps`가 감소분을 무시해 **걸음이 멈춤**(테스트로 확인된 현재 동작). 후보 채택 시 "감소 → 기준 재설정" 규칙과 테스트가 필요 |
**테스트(Mac 없이, 완료)**: `test/features/pedometer/pedometer_start_anchor_scenarios_test.dart` 6개 통과 — 상수 이동 불변, 첫 이벤트가 기준, 같은 기준 재구독 무중복, 앱 재시작 상한, 자정 전환, 위험 시나리오 고정.
**Mac/실기기 필요(미실행)**: (1) 0시 기준 `startUpdates`의 첫 콜백이 즉시 누적 값을 주는지 (2) 재구독 직후 값 (3) 자정 통과 시 스트림 동작 (4) 시간대/서머타임 변경 (5) 앱 강제 종료 후 재시작의 중복 적립 (6) 포그라운드 서비스 격리(isolate)와 메인의 이중 구독. 항목은 `docs/ios-device-test-plan.md`에 추가했다. 근거 없는 사유 코드는 넣지 않았다.
