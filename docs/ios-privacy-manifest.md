# iOS 개인정보 매니페스트(`PrivacyInfo.xcprivacy`) 준비

작성일: 2026-11-08. **iOS 빌드는 한 번도 실행하지 않았다.** 아래는 소스를 글자로 검색한 근거이고, 마지막 확인은 Mac에서 Xcode로 한다.
검색 도구: `python3 tool/ios/scan_required_reason_apis.py [--lines]` (`flutter pub get` 뒤에 실행. 사유 코드는 정하지 않는다).

## 1. 원칙
- Apple은 앱과 앱이 쓰는 SDK가 "필수 사유 API"(UserDefaults, 파일 시간 정보, 시스템 부팅 시간, 디스크 여유 공간, 활성 키보드)를 쓰면 **사유를 선언**하라고 한다. SDK가 자기 매니페스트를 가지고 있으면 그 SDK는 거기서 선언한다.
- **사유 코드는 Apple 공식 표에서 사람이 고른다.** 이번 작업에서 공식 표 페이지(developer.apple.com의 "Describing use of required reason API")는 자바스크립트로 그려져 내용을 가져오지 못했다(미확인). 그래서 **사유 코드를 한 줄도 채우지 않았다.** 기억에 의한 후보는 적어 두지 않는다.
- 개인정보 수집 데이터 종류(`NSPrivacyCollectedDataTypes`)는 App Store Connect "앱 개인정보" 답변과 같아야 하므로 대표님 확정이 필요하다. 초안 재료는 `docs/play-data-safety.md`.

## 2. 앱 자체 코드 (확인함)
| 대상 | 필수 사유 API 사용 | 근거 |
|---|---|---|
| `ios/Runner`(`AppDelegate.swift`, `BleHeartRatePlugin.swift`, `WatchBridgePlugin.swift`) | **없음** | 스캔 결과 후보 0건 |
| 애플워치 앱(`ios/ShareRunWatch Watch App`) | UserDefaults | `WatchAccountManager.swift:13`, `WatchSyncQueue.swift:126` (`UserDefaults.standard`). 워치를 빌드에 넣을 때만 해당. 워치 타깃은 자기 매니페스트가 따로 필요 |
→ 워치를 1차에서 빼면 앱 자체가 선언할 필수 사유 API는 없다.

## 3. 플러그인 (`pubspec.lock` 버전, 스캔 결과)
| 플러그인 | 자체 매니페스트 | 후보 API | 판단 |
|---|---|---|---|
| `flutter_foreground_task` 9.2.2 | **없음** | UserDefaults 17곳(`ios/Classes/models/*.swift`) | **앱 쪽 선언 후보.** 사유 코드는 공식 표로 결정(미확인) |
| `pedometer` 4.2.0 | **없음** | 시스템 부팅 시간(`PedometerPlugin.swift:92`, `systemUptime`) | **앱 쪽 선언 후보.** 사유 코드 미확인 |
| `firebase_auth` 6.5.4 | 없음 | 파일 시간 정보 1곳(`PigeonParser.m:47`, `user.metadata.creationDate`) | **오탐으로 판단.** 파일이 아니라 Firebase 사용자 메타데이터의 가입 시각 속성이다. Firebase iOS SDK는 자체 매니페스트를 갖는 것으로 알고 있으나 **미확인(Mac에서 Privacy Report로 확인)** |
| `device_info_plus`, `package_info_plus`, `sensors_plus`, `firebase_messaging`, `flutter_local_notifications`, `permission_handler_apple`, `shared_preferences_foundation` | 있음 | 위 API 사용 | 각 플러그인이 선언. 앱은 할 일 없음 |
| `health`, `flutter_tts`, `sign_in_with_apple`, `speech_to_text`, `audioplayers_darwin`, `firebase_core`, `cloud_firestore`, `flutter_naver_login`, `geolocator_apple`, `google_maps_flutter_ios`, `google_sign_in_ios`, `image_picker_ios`, `local_auth_darwin`, `kakao_*` 외 | 있음/없음 섞임 | 후보 0건 | 선언할 API 없음 |
| Flutter 엔진(`Flutter.framework`) | 미확인 | — | 엔진이 자체 매니페스트를 포함하는지 이 환경(Linux)에서는 확인하지 못했다. Mac에서 `flutter build ipa` 뒤 Privacy Report로 확인 |
| CocoaPods로 받는 바이너리 SDK(Firebase, Google Maps, Google Sign-In, Kakao 등) | 미확인 | — | 소스가 없어 글자 검색이 불가. 마찬가지로 Privacy Report로 확인 |

## 4. 초안 (사유 코드는 비워 둠)
`NSPrivacyAccessedAPITypes`에는 위 두 범주만 후보로 올리고, **사유 코드 자리는 비워 둔 채 문서에만 둔다.** 사유 배열이 빈 항목을 그대로 두면 업로드 검증에서 거부될 수 있으므로 이 초안은 `ios/`에 넣지 않았다.
```text
NSPrivacyTracking            = false      (근거: 광고·분석 SDK 없음. pubspec.yaml에 analytics/ads/attribution 계열 없음)
NSPrivacyTrackingDomains     = []
NSPrivacyAccessedAPITypes:
  - NSPrivacyAccessedAPICategoryUserDefaults    <- flutter_foreground_task, 워치 앱을 넣을 때 워치 쪽
      NSPrivacyAccessedAPITypeReasons = [ ??? ]       # 공식 표 확인 후 사람이 입력
  - NSPrivacyAccessedAPICategorySystemBootTime  <- pedometer
      NSPrivacyAccessedAPITypeReasons = [ ??? ]       # 공식 표 확인 후 사람이 입력
NSPrivacyCollectedDataTypes = [ ... ]          # App Store Connect 답변과 맞춰 대표님이 확정(아래 5절)
```
`NSPrivacyTracking=false`의 근거는 이 앱에 광고·분석·어트리뷰션 SDK가 없다는 점(`pubspec.yaml`, 앞서 코드 검색)이다. 다만 "추적"의 법적 정의는 대표님이 최종 확인한다.

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
