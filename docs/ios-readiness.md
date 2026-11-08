# iOS(App Store) 준비 점검

점검일: 2026-11-08. 기준 코드: `main` `ac2e95e`(1.0.0+7) 위의 `chore/ios-prep`.
목표: 11월 12일부터 일주일 빌리는 M2 맥북과 아이폰으로 첫 실기기 실행, 배포용 빌드, TestFlight 업로드까지. 일주일 안의 심사 통과는 약속하지 않는다.
**iOS 빌드, `pod install`, Xcode 서명은 한 번도 실행하지 않았다(Mac 없음).** 이 문서는 코드와 설정을 읽은 결과다.
Mac에서 할 순서는 `docs/ios-mac-runbook.md`.

분류: **준비됨**(코드·문서로 끝남) / **Mac 필요** / **계정 필요**(대표님이 가진 계정이나 소유 정보 확인) / **승인 필요**(가입·결제·발급·폐기·제출) / **미확인**.

## 0. 버전·브랜치 정합 (확인함)
| 항목 | 내용 |
|---|---|
| 지난 보고의 "+6"과 출시본 "+7" | **단순 버전 차이**다. `main`은 11/4에 `ac2e95e`(#385, "1.0.0+7: 지도 API 키 교체")가 들어와 +7이 됐고, `chore/ios-prep`는 그 전(+6, `9e61d16`)에서 갈라졌다. 두 브랜치의 차이는 이 한 커밋뿐이며(`pubspec.yaml` 버전과 안드로이드 매니페스트 지도 키 2곳) 준비 브랜치에서 빠진 코드는 없다 |
| 조치 | `main`을 준비 브랜치에 일반 병합했다(병합 커밋 `eba16ed`, 강제 푸시 아님). 버전은 건드리지 않았다. 이제 준비 브랜치도 1.0.0+7 → iOS 마케팅 버전 1.0.0, 빌드 번호 7 |
| **새로 드러난 불일치** | #385는 **안드로이드 지도 키만** 교체했다. `ios/Runner/AppDelegate.swift`의 iOS 지도 키는 옛 키 그대로다(키 값은 적지 않음. 길이 39로 같고 SHA-256 앞 8자리가 달라 서로 다른 키임). iOS용으로 어느 키를 쓸지, 그 키에 iOS 번들 ID 제한을 걸었는지는 **계정 필요**. 이 문서는 키를 바꾸지 않았다 |

## 1. 생성 파일 Git 추적 제외 검증 (공식 템플릿과 대조)
Flutter 3.44.3 태그의 공식 iOS 템플릿 `.gitignore`(`packages/flutter_tools/templates/app/ios.tmpl/.gitignore`)를 받아 대조했다.
| 이 브랜치에서 뺀 파일 | 공식 템플릿 | 판정 |
|---|---|---|
| `ios/Flutter/Generated.xcconfig` | `Flutter/Generated.xcconfig` 있음 | 올바름. 내용에 윈도우 경로 `C:\flutter…`가 들어 있었다 |
| `ios/Flutter/flutter_export_environment.sh` | `Flutter/flutter_export_environment.sh` 있음 | 올바름 |
| `ios/Runner/GeneratedPluginRegistrant.h`, `.m` | `Runner/GeneratedPluginRegistrant.*` 있음 | 올바름(등록 파일 전체를 제외하는 것이 공식 기본이다). `flutter pub get`이 다시 만든다 |
| `ios/Flutter/ephemeral/` | `Flutter/ephemeral/` 있음 | 올바름(추적된 적은 없음) |
`.gitignore`에 같이 넣은 `ios/Pods/`, `ios/.symlinks/`, `xcuserdata`도 템플릿 항목(`**/Pods/`, `**/.symlinks/`, `xcuserdata`)과 같은 뜻이다. `ios/Podfile.lock`은 일부러 제외하지 않았다(앱은 커밋하는 것이 일반적). `GoogleService-Info.plist`는 Android의 `google-services.json`과 같은 취급으로 추가했다. 잘못된 변경은 찾지 못해 이 부분은 고치지 않았다.
참고: 템플릿에는 있고 저장소에는 없는 파일(`ios/Flutter/AppFrameworkInfo.plist`, `Debug.xcconfig`, `Release.xcconfig`, `Runner.xcodeproj`, `Podfile`, `Main.storyboard`, `Runner-Bridging-Header.h`)은 Mac에서 생성한다.

## 2. 플러그인별 iOS 요구사항
최소 iOS는 각 플러그인의 `podspec`/`Package.swift`를 읽은 값(`pubspec.lock` 버전 기준). 개인정보 매니페스트(`PrivacyInfo.xcprivacy`)는 플러그인 폴더에 파일이 있는지 확인한 결과다. 아래 "권한·Capability·서비스"는 코드 근거와 플러그인 README 기준이고, **Apple의 현재 공식 문서로 다시 확인하지 못한 것은 미확인**이라고 적었다.
| 플러그인 | 최소 iOS | 플러그인 개인정보 매니페스트 | 권한·Capability·외부 서비스 | 코드 근거 | 분류 |
|---|---|---|---|---|---|
| `firebase_core` 4.11, `firebase_auth` 6.5, `cloud_firestore` 6.6 | **15.0** | 없음(Firebase SDK 쪽 매니페스트 여부는 미확인) | `GoogleService-Info.plist`, Firebase에 iOS 앱 등록 | `lib/data/firebase/firebase_bootstrap.dart`, `lib/firebase_options.dart` | 계정 필요 |
| `firebase_messaging` 16.4 | 15.0 | 있음 | Push Notifications capability, Background Modes `remote-notification`, APNs 인증 키(.p8)를 Firebase에 등록, `aps-environment` entitlement | `lib/data/firebase/push_notification_service.dart` | Mac 필요(capability), 승인 필요(키 발급) |
| `google_sign_in` 7.2 (`google_sign_in_ios` 6.3) | 13.0 | 있음 | `Info.plist`의 `GIDClientID`와 `REVERSED_CLIENT_ID` URL 스킴(`GoogleService-Info.plist`에서) | `lib/data/firebase/auth_service.dart:34` | 계정 필요, Mac 필요 |
| `sign_in_with_apple` 8.1 | 확인 못 함(미확인, 플러그인 폴더 구조 다름) | 없음 | Sign in with Apple capability(`com.apple.developer.applesignin`), 서버 `APPLE_CLIENT_ID`(번들 ID) | 앱 `auth_service.dart:98`, 서버 `backend/jena_ai/app/services/identities.py:59-292`, 켜기 `app_env.dart:160` | Mac 필요, 계정 필요(서버 값) |
| `kakao_flutter_sdk_user`, `_share` 2.0.0 | (플러그인 폴더에 iOS 소스 없음, 미확인) | 없음 | `Info.plist`에 `kakao{앱키}` URL 스킴과 `LSApplicationQueriesSchemes`(이미 있음), 카카오 콘솔에 iOS 번들 ID 등록 | `lib/main.dart:62`, `ios/Runner/Info.plist` | 준비됨(`Info.plist`), 계정 필요(콘솔) |
| `flutter_naver_login` 2.1 | 13.0 | 있음 | `Info.plist`에 URL 스킴과 클라이언트 설정(플러그인 README), 네이버 콘솔 iOS 설정. `Info.plist`에 **아직 없음** | `lib/data/repositories/auth_repository.dart` | 계정 필요, Mac 필요 |
| `health` 13.3 | 14.0 | 없음 | HealthKit capability와 entitlement(**이미 있음**), `NSHealthShareUsageDescription`(있음). `NSHealthUpdateUsageDescription`은 있지만 앱이 쓰기를 안 함(코드에 쓰기 호출 없음) → 삭제 검토 | `ios/Runner/Runner.entitlements`, `health_data_service.dart`(걸음 수만 읽음) | 준비됨, 실기기 필요 |
| `geolocator` | 11.0 (`geolocator_apple` 2.3) | 있음 | 위치 문구 3종(**있음**), `UIBackgroundModes: location`(**있음**) | `Info.plist` | 준비됨, 실기기 필요 |
| `permission_handler` 12 (`_apple` 9.4) | 12.0 | 있음 | Podfile `post_install`의 `PERMISSION_*=1` 매크로(쓰는 권한만: photos, notification, location, always, activityRecognition) | `lib` 검색: `Permission.photos`, `notification`, `locationWhenInUse`, `always`, `activityRecognition` | Mac 필요 |
| `pedometer` 4.2 | 10.0 | 없음 | `NSMotionUsageDescription`(있음) | `lib/features/pedometer/` | 준비됨 |
| `sensors_plus` 7 | 12.0 | 있음 | `NSMotionUsageDescription` | | 준비됨 |
| `flutter_foreground_task` 9.2 | 8.0 | 없음 | `UIBackgroundModes: fetch`(**있음**), `BGTaskSchedulerPermittedIdentifiers`(**이 브랜치에서 추가**). iOS에서는 백그라운드 약 15분마다 30초만 동작(README) | `run_recording_foreground.dart`, `solo_pedometer_foreground.dart` | 준비됨, 실기기 필요 |
| `flutter_local_notifications` 17.2 | 8.0 | 있음 | 알림 권한은 런타임 요청 | `lib/core/notifications/` | 준비됨 |
| `speech_to_text` 7.4 | 13.0 | 없음 | 마이크, 음성 인식 문구(있음, 한국어 고정) | 미니봇 | 준비됨(문구 현지화는 Mac 필요) |
| `flutter_tts` 4.2, `audioplayers` 6.4 | 8.0, 13.0 | 없음 | 화면 꺼짐 중 음성 안내가 필요하면 `UIBackgroundModes: audio`(필요 여부 미확인) | `voice_coaching/` | 미확인 |
| `image_picker` | 13.0 | 있음 | 카메라·사진 문구(**있음**) | | 준비됨 |
| `local_auth` 3 | 13.0 | 있음 | `NSFaceIDUsageDescription`(있음). 1.0은 결제가 꺼져 있어 쓰는 곳이 거의 없음 | `lib/features/iap/payment_auth.dart` | 준비됨 |
| `in_app_purchase` | 13.0 | 있음 | StoreKit. App Store Connect 상품이 필요하지만 1.0은 판매가 꺼져 있음(`IN_APP_PURCHASES_ENABLED`, `app_env.dart:128`) | | 해당 없음(1.0) |
| `google_maps_flutter` (`_ios` 2.18) | 14.0 | 있음 | 지도 키(`AppDelegate.swift`의 `GMSServices.provideAPIKey`), 콘솔에서 iOS 번들 ID 제한 | 위 0절 | 계정 필요 |
| `share_plus` 12, `url_launcher`, `shared_preferences`, `webview_flutter`, `package_info_plus`, `flutter_timezone` | 11~13 | 대부분 있음 | 특별한 권한 없음 | | 준비됨 |
**최소 iOS는 15.0**(위 중 최댓값, Firebase). Podfile과 프로젝트의 배포 타깃을 15.0 이상으로 둔다.
앱 자체의 `PrivacyInfo.xcprivacy`(수집 데이터 종류, 접근 API 사유)는 아직 없다. 앱이 수집하는 데이터 종류와 App Store Connect 개인정보 답변이 서로 맞아야 해서 대표님 답변이 필요하다 → **계정 필요**. 참고용 초안은 `docs/play-data-safety.md`.
SPM과 CocoaPods 중 무엇으로 연결되는지는 3.44.3의 기본 설정에 따르며, 이 문서는 확인하지 못했다(미확인). `permission_handler`의 매크로 설정은 CocoaPods 경로 기준이다.

## 3. 애플 로그인 (App Store 심사 지침 4.8) — 실제 로그인 구조와 대조
- **지침 4.8의 요지**: 구글·페이스북 같은 서드파티·소셜 로그인으로 앱의 기본 계정을 만들거나 로그인하게 하면, 이름과 이메일만 수집하고, 이메일을 숨길 수 있고, 광고용 수집을 동의 없이 하지 않는 **동등한 로그인 옵션**도 함께 제공해야 한다. 예외는 (a) 회사 자체 계정으로만 가입·로그인하는 앱, (b) 교육·기업·업무용으로 기존 계정이 필요한 앱, (c) 정부·산업 지원 시민 ID, (d) 특정 서드파티 서비스용 클라이언트 앱 등이다. 이 요약은 제 기억에 의한 것이고 **현재 Apple 지침 원문으로 다시 확인해야 한다(미확인)**.
- **이 앱의 구조(코드)**: 로그인 화면에는 구글, 애플(꺼진 상태), 카카오, 네이버 버튼만 있다(`lib/screens/login_screen.dart`의 `GoogleSignInButton`, `AppleLoginButton`, `KakaoLoginButton`, `NaverLoginButton`). 이메일·비밀번호 로그인과 게스트 입장은 화면에서 쓰이지 않는다(`signInWithEmailPassword`는 `auth_service.dart`에만 있고 화면 호출이 없음). 서버는 소셜 신원으로 계정을 만든다. 따라서 "자체 계정만" 예외에는 해당하지 않는다.
- **판정**: 구글을 포함한 소셜 로그인으로 기본 계정을 만들기 때문에 4.8이 적용될 가능성이 높고, 현 구조에서는 애플 로그인이 가장 간단한 충족 방법이다. 다만 "무조건 필수"로 단정하지 않는다. 동등 옵션은 애플 로그인이 아니어도 위 조건을 모두 만족하면 된다고 알고 있으나, 그런 대체 수단은 현재 앱에 없다. 최종 판단은 심사관 몫이며 심사 메모로 설명할 수 있다.
- 켜는 데 필요한 것: (1) `Runner.entitlements`에 `com.apple.developer.applesignin`(Capability 추가, Mac 필요), (2) 빌드 때 `APPLE_LOGIN_ENABLED=true`, (3) 서버 `APPLE_CLIENT_ID`(앱 번들 ID) 설정과 Cloud Run 반영(계정 필요), (4) Firebase 콘솔에서 Apple 로그인 사용 설정(계정 필요, 이미 쓰는 구조인지 미확인).

## 4. 프로젝트 기본·서명·서류 상태
| 항목 | 분류 | 근거와 남은 일 |
|---|---|---|
| `Runner.xcodeproj`, `Podfile`, `Main.storyboard` | Mac 필요 | 저장소에 없음. `Info.plist`는 `UIMainStoryboardFile=Main`을 가리킨다. 생성 절차와 보존 확인은 런북 4절 |
| iOS 번들 ID | 계정 필요 | `com.sharerun.shareRunChallenge`(`lib/firebase_options.dart`, 워치 `Info.plist`). Android(`com.sharerun.share_run_challenge`, `android/app/build.gradle.kts:100`)와 다르다(iOS는 밑줄 불가). Apple에 등록했는지 미확인이라 **임의로 바꾸지 않는다** |
| Apple Developer Program | 승인 필요 | 11월 11일 가입 예정(대표님). 가입 전에는 서명·업로드 불가 |
| 팀 ID, 인증서, 프로비저닝, App Store Connect 앱 레코드 | 승인 필요 | 가입 뒤 발급·생성 |
| 테스트용 iPhone | 계정 필요 | 대여 예정(소유자 동의, iOS 버전 확인 필요) |
| 앱 아이콘 | 준비됨 | 1024 포함, 알파 채널 없음 |
| 지원 기기(iPad) | 계정 필요(결정) | `Info.plist`에 iPad 방향 선언. 아이폰 전용이면 iPad 스크린샷 생략 가능 |
| 암호 수출 규정 `ITSAppUsesNonExemptEncryption` | 승인 필요(법적 신고) | `Info.plist`에 없음. 대표님이 답한다 |
| 개인정보 매니페스트, 권한 문구 11개 언어(`InfoPlist.strings`) | Mac 필요 | 만들 수는 있으나 Xcode 타깃에 넣는 것은 Mac. 한국어 고정 문구(마이크, 음성)를 11개 언어로 |
| 심사용 로그인 방법 | 계정 필요(결정) | 소셜 로그인뿐이라 심사관이 못 들어간다 |
| 애플워치 | Mac 필요, 1차 제외 권장 | 소스는 있고 Xcode 타깃은 없음. `watchos_app/README-XCODE-SETUP.md`의 서버 주소가 옛 값일 수 있어 쓰기 전 확인(미확인) |
| 백그라운드 모드 | 준비됨 | `fetch`는 `flutter_foreground_task`가 쓴다. `processing`을 쓰는 코드는 못 찾았으나 그대로 둔다(제거는 Mac 실기기 검증 뒤 결정) |

## 5. 외부 서비스 설정 상태
| 서비스 | 이미 있음 | 계정 확인 필요 | 발급·설정 승인 필요 |
|---|---|---|---|
| Firebase 프로젝트 | Android 앱 연동 | iOS 앱 등록 여부, `GoogleService-Info.plist` | iOS 앱 추가 등록 |
| 구글 로그인 | 앱 코드, 웹 클라이언트 ID(Android) | iOS 클라이언트 ID(`GIDClientID`) | |
| 카카오 | 앱 키(소스), `Info.plist` URL 스킴 | 콘솔의 iOS 번들 ID 등록 | |
| 네이버 | Android 설정 | iOS 클라이언트 설정과 콘솔 | |
| 푸시(APNs) | Firebase 메시징 코드 | Firebase에 APNs 키 등록 여부 | APNs 인증 키(.p8) 발급 |
| 애플 로그인 | 앱·서버 코드 | 서버 `APPLE_CLIENT_ID`, Firebase Apple 공급자 | Capability와 번들 ID 설정 |
| 지도 | 안드로이드 키(#385), iOS는 옛 키 | iOS용 키 선택과 번들 ID 제한 | 키 새로 만들 경우 |
| HealthKit | entitlement, 문구 | | 앱 ID에 HealthKit 사용 설정 |

## 6. 이 브랜치에서 바꾼 것(코드·설정)과 이유
1. `ios/Runner/Info.plist`: `BGTaskSchedulerPermittedIdentifiers` 추가 — `flutter_foreground_task` README가 `fetch`와 함께 요구. 다른 키는 그대로.
2. `.gitignore`와 생성 파일 4개 추적 해제 — 위 1절(공식 템플릿과 일치).
3. `tool/ios/check_ios_config.py` 추가 — Mac에서 프로젝트를 만든 뒤 `Info.plist`, entitlements, URL 스킴, 백그라운드 모드, 번들 ID가 유실되지 않았는지 검사(비밀값 출력 없음). 지금 파일에서 통과 24, 실패 0, 건너뜀 4를 확인했고, 일부러 망가뜨린 복사본에서는 실패 4개를 잡는 것을 확인했다.
4. 이 문서와 런북. 앱 Dart 코드, Android 파일, 번들 ID는 바꾸지 않았다.

## 7. 분석·테스트 재실행 결과 (이 환경)
환경: Linux 컨테이너(Windows·Mac 아님), Flutter **3.44.3**(공식 `flutter_linux_3.44.3-stable.tar.xz`, 노트북과 같은 버전), Dart 3.12.2. 비교 대상 `main` `ac2e95e` + 이 브랜치.
| 명령 | 종료 결과 |
|---|---|
| `flutter pub get` | 성공. 의존성 7개가 `pubspec.lock`에서 달라졌으나 **커밋하지 않았다**(되돌림). 이 환경과 노트북의 해석 차이로 보임 |
| `flutter analyze lib test` | 종료 코드 1(정보 수준 때문). **오류 0, 경고 22, 정보 178(총 200건)** |
| `flutter test --exclude-tags golden --no-pub` | 아래 8절 |
| `python3 tool/ios/check_ios_config.py` | 통과 24, 실패 0, 건너뜀 4 |
| iOS 빌드, `pod install`, 서명, 시뮬레이터 | **실행하지 않음(Mac 필요)** |
지난 보고(Flutter 3.47.7)의 분석 203건(경고 25)과 이번 200건(경고 22)의 차이는 같은 코드에서 Flutter와 Dart 버전이 달라 경고 3건이 덜 나온 것으로 추정한다(원인 파일을 일일이 대조하지는 않았다). 오류는 양쪽 모두 0이고 정보 178건은 같다.
