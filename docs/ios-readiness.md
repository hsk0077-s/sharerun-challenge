# iOS(App Store) 준비 점검

점검일: 2026-11-08 (코드 기준 `origin/main` = 1.0.0+6). 11월 12일부터 일주일 빌릴 M2 맥북에서 첫 빌드와 TestFlight 업로드까지가 목표다. 심사 통과는 일주일 안에 약속하지 않는다.
**iOS 빌드는 한 번도 실행하지 않았다.** 아래는 코드와 설정을 읽은 결과다. 상태: 준비됨 / 미완료 / 막힘(대표님 결정·계정 필요) / 미확인.
Mac 실행 순서는 `docs/ios-mac-runbook.md`.

## 1. 프로젝트 기본
| 항목 | 상태 | 근거 |
|---|---|---|
| Xcode 프로젝트(`Runner.xcodeproj`), `Podfile`, `Main.storyboard` | 미완료 | `ios/`에 없음(`ios/Runner`에 `Info.plist`, `AppDelegate.swift`, 아이콘, `LaunchScreen.storyboard`만). `Info.plist`는 `UIMainStoryboardFile=Main`을 가리킨다. Mac에서 `flutter create --platforms=ios .`가 빠진 파일만 만든다(기존 파일은 덮어쓰지 않는다). 만든 뒤 `Info.plist`, `AppDelegate.swift`가 그대로인지 `git diff`로 확인 |
| Bundle ID | 준비됨(코드 쪽) / 미확인(Apple 등록) | `lib/firebase_options.dart`의 `iosBundleId: 'com.sharerun.shareRunChallenge'`, 워치 `Info.plist`의 `WKCompanionAppBundleIdentifier`. Android는 `com.sharerun.share_run_challenge`(`android/app/build.gradle.kts:100`). **iOS는 밑줄(_)을 쓸 수 없어** 이름이 다르다. 이 ID를 Apple Developer에 등록했는지는 모른다 |
| 최소 iOS 버전 | 준비됨(값 확정) | 플러그인 최소 요구 중 최댓값이 15.0(`firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_messaging`의 `Package.swift` `.iOS("15.0")`). Mac에서 Podfile/프로젝트를 15.0 이상으로 |
| 버전 번호 | 준비됨 | `pubspec.yaml` `1.0.0+6` → 마케팅 버전 1.0.0, 빌드 6. 이미 TestFlight에 올린 빌드가 있으면 빌드 번호를 올려야 한다(없을 것으로 보지만 미확인) |
| 앱 아이콘 | 준비됨 | `AppIcon.appiconset` 1024 포함, 알파 채널 없음(RGB) |
| 지원 기기 | 결정 필요 | `Info.plist`에 iPad 방향이 선언돼 있다. 아이폰 전용으로 두면 iPad 스크린샷·화면 검수를 생략할 수 있다 |
| 생성 파일 | 이 브랜치에서 정리 | `ios/Flutter/Generated.xcconfig`, `flutter_export_environment.sh`, `GeneratedPluginRegistrant.*`가 git에 있었고 안에 윈도우 경로(`C:\flutter…`)가 들어 있었다. 추적을 끊고 `.gitignore`에 넣었다(`flutter pub get`이 Mac에서 다시 만든다) |
| Flutter 버전 | 준비됨 | `pubspec.lock`이 `flutter >=3.44.0` 요구, 노트북은 3.44.3. Mac도 같은 버전으로 맞춘다 |

## 2. 서명·계정 (대표님 확인 필요)
| 항목 | 상태 | 근거 |
|---|---|---|
| Apple Developer Program 가입 | 미확인 | 코드로 알 수 없음. 개인과 법인 여부도 |
| Team ID, 인증서, 프로비저닝 | 미확인 | 저장소에 없음(있으면 안 됨) |
| App Store Connect 앱 레코드 | 미확인 | |
| 테스트용 iPhone(실기기) | 미확인 | HealthKit, 센서, 블루투스, 푸시는 시뮬레이터로 검증이 안 된다 |
| 암호 수출 규정 `ITSAppUsesNonExemptEncryption` | 미완료(소유자 판단) | `Info.plist`에 없음. 표준 HTTPS만 쓰면 `false`로 넣어 업로드 질문을 줄이지만, 법적 신고라서 대표님이 정한다 |

## 3. 기능별 (실제 쓰는 것만)
| 기능 | 상태 | 근거와 남은 일 |
|---|---|---|
| Firebase(인증, Firestore, 메시징) | 미완료 | `firebase_core ^4.11`, `firebase_auth`, `firebase_messaging`(`pubspec.yaml`). `GoogleService-Info.plist`가 저장소에 없다. iOS Firebase 앱을 만들었는지 미확인. `firebase_options.dart`의 iOS 값은 dart-define(`FIREBASE_*`)에서 온다 |
| 구글 로그인 | 미완료 | `google_sign_in ^7.2`. iOS는 `GIDClientID`와 `REVERSED_CLIENT_ID` URL 스킴이 `Info.plist`에 필요한데 없다. 값은 `GoogleService-Info.plist`에서 나온다(Firebase iOS 앱 등록 뒤) |
| 카카오 로그인·공유 | 부분 준비 | `Info.plist`에 `kakao{앱키}` URL 스킴과 `LSApplicationQueriesSchemes`(kakaotalk 등) 있음, `lib/main.dart:62` `KakaoSdk.init`. 카카오 개발자 콘솔에 iOS 번들 ID 등록 여부는 미확인 |
| 네이버 로그인 | 미완료 | `flutter_naver_login`. iOS는 URL 스킴과 클라이언트 설정(플러그인 README의 `Info.plist` 항목)이 필요한데 `Info.plist`에 없다. 네이버 콘솔의 iOS 설정도 미확인 |
| 애플 로그인 | 부분 준비 | 앱(`lib/data/firebase/auth_service.dart:98`)과 서버(`backend/jena_ai/app/services/identities.py:59-292`)에 코드가 있다. 하지만 `APPLE_LOGIN_ENABLED`가 꺼져 있으면 "준비 중"으로 보이고(`app_env.dart:160`), `Runner.entitlements`에 `com.apple.developer.applesignin`이 없다. 소셜 로그인(구글·카카오·네이버)을 쓰므로 애플 심사 지침 4.8상 켜야 한다. 서버 `APPLE_CLIENT_ID` 설정 여부는 미확인. *(2026-11-01 점검표의 "미구현"은 틀렸다. 코드는 있다)* |
| 푸시 알림 | 미완료 | `firebase_messaging`(`lib/data/firebase/push_notification_service.dart`). `Runner.entitlements`에 `aps-environment`가 없고 `UIBackgroundModes`에 `remote-notification`이 없다. Apple에서 APNs 인증 키를 만들어 Firebase에 올려야 한다(소유자) |
| 위치(달리기 거리) | 준비됨 | `geolocator`. `Info.plist`에 위치 사용 문구와 `UIBackgroundModes: location` |
| 건강 데이터(걸음 수) | 부분 준비 | `health ^13.3`, 앱은 걸음 수만 읽는다. `Runner.entitlements`에 `com.apple.developer.healthkit`, `NSHealthShareUsageDescription` 있음. **`NSHealthUpdateUsageDescription`은 앱이 쓰기를 안 하는데 남아 있고 내용도 맞지 않는다**(코드에 쓰기 없음). 삭제를 권장하지만 Mac에서 HealthKit 권한 창이 정상인지 보고 정한다. 실기기 필요 |
| 블루투스 심박 센서 | 준비됨(실기기 검증 필요) | `ios/Runner/BleHeartRatePlugin.swift`, `Info.plist`의 블루투스 문구와 `bluetooth-central` 모드 |
| 걸음 수 센서 | 준비됨 | `pedometer`, `NSMotionUsageDescription` |
| 달리기 중 백그라운드 | 확인 필요 | `flutter_foreground_task`를 쓴다(`lib/features/run_tracking/run_recording_foreground.dart`, `solo_pedometer_foreground.dart`). 이 플러그인 README는 iOS에서 `UIBackgroundModes: fetch`와 `BGTaskSchedulerPermittedIdentifiers`(`com.pravera.flutter_foreground_task.refresh`)를 요구하고, iOS에서는 앱이 백그라운드에서 15분마다 약 30초만 돈다. **이 브랜치에서 `BGTaskSchedulerPermittedIdentifiers`를 추가했다.** *(11/1 점검표의 "fetch, processing은 안 쓴다 → 삭제 권장"은 틀렸다. `fetch`는 이 플러그인이 쓴다. `processing`을 쓰는 코드는 못 찾았으나 지금은 그대로 둔다)* 위치 기록 자체는 `location` 모드로 유지된다 |
| 음성 안내(코치) | 확인 필요 | `flutter_tts`, `audioplayers`. 화면이 꺼진 상태에서 음성이 나와야 하면 `UIBackgroundModes: audio`가 필요할 수 있다. 실기기 검증 후 결정(미확인) |
| 음성 입력(미니봇) | 부분 준비 | `speech_to_text`. 마이크·음성 인식 문구가 "한글로", "한국어 음성"이라 11개 언어 앱과 맞지 않는다 |
| 사진·카메라 | 준비됨 | `image_picker`, `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` |
| 공유(인스타·카카오 등) | 준비됨(실기기 필요) | `AppDelegate.swift`가 인스타 스토리 등을 처리. iOS는 카카오 직접 이미지 공유 경로가 없다 |
| 지도 | 미확인 | `google_maps_flutter`. 키가 `AppDelegate.swift`에 직접 있고(값은 이 문서에 쓰지 않는다), iOS 번들 ID 제한이 걸려 있는지 미확인 |
| 인앱 결제 | 해당 없음(1.0) | `in_app_purchase` 패키지는 들어 있지만 `IN_APP_PURCHASES_ENABLED` 기본값이 꺼짐(`app_env.dart:128`). 1.0은 판매가 없다. 심사 메모에 "앱 내 판매 없음"을 적는다 |
| 광고 | 없음 | 광고 SDK 없음(`pubspec.yaml`, `lib` 검색 결과 없음) |
| Face ID | 준비됨 | `local_auth`, `NSFaceIDUsageDescription`(결제용, 1.0엔 결제가 꺼져 있음) |
| 애플워치 | 미완료, 1차 빌드 제외 권장 | 소스는 `ios/ShareRunWatch Watch App/`와 `watchos_app/`에 있으나 Xcode 타깃이 없다. 방법은 `watchos_app/README-XCODE-SETUP.md`. 워치 README의 `JENA_BASE_URL`에 옛 서버 주소가 보이므로 쓰기 전 현재 서버 주소로 바꿀 것(미확인) |

## 4. 심사 서류·문구
| 항목 | 상태 |
|---|---|
| `PrivacyInfo.xcprivacy` | 미완료. 앱 수집 데이터 답변(대표님)과 같이 작성. 플러그인 자체 매니페스트는 각 플러그인에 있음 |
| 권한 문구 현지화(`InfoPlist.strings` 11개 언어) | 미완료. 지금은 한국어뿐 |
| 심사용 로그인 | 막힘(결정). 소셜 로그인뿐이면 심사관이 못 들어간다. 데모 계정이나 이메일 로그인 필요 |
| 앱 프라이버시 답변, 스토어 문구(부제 30자, 키워드 100자) | 미완료. `docs/play-data-safety.md`를 바탕으로 |
| 개인정보 처리방침, 약관 | 있음(`site/`). iOS 이름·건강 데이터 문구 점검 필요(미확인) |

## 5. 이 브랜치(`chore/ios-prep`)에서 바꾼 것
1. `ios/Runner/Info.plist`: `BGTaskSchedulerPermittedIdentifiers` 추가(플러그인 README 요구). 다른 항목은 그대로.
2. `.gitignore`, 생성 파일 4개 추적 해제(위 "생성 파일").
3. 이 문서와 `docs/ios-mac-runbook.md`.
앱 코드(Dart), Android 파일은 바꾸지 않았다.

## 6. 검사 결과 (Linux 컨테이너, Windows 아님)
| 명령 | 결과 |
|---|---|
| `dart analyze lib test` | 오류 0, 경고 25, 정보 178(203건). 모두 기존 항목이고 이 브랜치가 만든 것은 없음 |
| `very_good test --exclude-tags golden`(CI와 같은 방식) | 1095개 모두 통과 |
| iOS 빌드, `xcodebuild`, `pod install` | **실행하지 않음**(Mac 필요) |
