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

## 3. 애플 로그인 (App Store 심사 지침 4.8) — 원문과 실제 로그인 구조 대조
**지침 4.8 원문**(2026-11-08에 developer.apple.com/app-store/review/guidelines 에서 확인한 영문 그대로):
> Apps that use a third-party or social login service (such as Facebook Login, Google Sign-In, Log in with X, Sign In with LinkedIn, Login with Amazon, or WeChat Login) to set up or authenticate the user's primary account with the app must also offer as an equivalent option another login service with the following features:
> * the login service limits data collection to the user's name and email address;
> * the login service allows users to keep their email address private as part of setting up their account; and
> * the login service does not collect interactions with your app for advertising purposes without consent.
>
> A user's primary account is the account they establish with your app for the purposes of identifying themselves, signing in, and accessing your features and associated services.
>
> Another login service is not required if:
> * Your app exclusively uses your company's own account setup and sign-in systems.
> * Your app is an alternative app marketplace, or an app distributed from an alternative app marketplace, that uses a marketplace-specific login for account, download, and commerce features.
> * Your app is an education, enterprise, or business app that requires the user to sign in with an existing education or enterprise account.
> * Your app uses a government or industry-backed citizen identification system or electronic ID to authenticate users.
> * Your app is a client for a specific third-party service and users are required to sign in to their mail, social media, or other third-party account directly to access their content.

**이 앱의 로그인 구조(코드)와 대조**
| 원문 조건 | 이 앱 | 근거 |
|---|---|---|
| 서드파티·소셜 로그인으로 **기본 계정**을 만들거나 인증하는가 | **예.** 로그인 화면은 구글, 애플(꺼짐), 카카오, 네이버뿐이고, 서버가 그 신원으로 쉐어런 계정을 만든다 | `lib/screens/login_screen.dart`의 `GoogleSignInButton`, `AppleLoginButton`, `KakaoLoginButton`, `NaverLoginButton`, `_startProvider` |
| 예외 1: 회사 자체 계정만 쓰는가 | **아니오.** 이메일·비밀번호 로그인은 서비스 클래스에만 있고 화면에서 호출하지 않으며(`signInWithEmailPassword` 호출처 없음), 게스트 입장도 없다 | `lib/data/firebase/auth_service.dart`, 화면 검색 결과 호출 0건 |
| 예외 2~4: 대안 마켓, 교육·기업 계정, 정부 ID | 해당 없음 | |
| 예외 5: 특정 서드파티 서비스의 클라이언트인가 | **아니오.** 카카오·네이버·구글의 콘텐츠를 보는 앱이 아니라 자체 서비스(걷기·달리기 챌린지) | |
| 동등한 다른 로그인 서비스가 있는가 | **아직 없음.** 애플 로그인 코드는 있지만 꺼져 있다(`APPLE_LOGIN_ENABLED` 기본값 꺼짐, `app_env.dart:160`) | `login_screen.dart:443`(꺼지면 "준비 중" 안내) |
**판정**: 현재 구조는 4.8이 적용되는 쪽이고 어떤 예외에도 해당하지 않는다. 따라서 **동등한 옵션이 없으면 4.8 지적이 나올 가능성이 높다.** 동등 옵션은 반드시 애플 로그인이어야 하는 것은 아니고 위 세 조건(이름·이메일만 수집, 이메일 숨기기, 동의 없는 광고용 수집 금지)을 만족하는 서비스면 된다. 지금 코드에 있고 가장 단순한 충족 수단이 애플 로그인이다. 최종 판정은 심사관 몫이다.

**애플 로그인을 켜는 데 필요한 작업**
| 구분 | 작업 | 분류 |
|---|---|---|
| 앱 | `Runner.entitlements`에 Sign in with Apple capability(`com.apple.developer.applesignin`) 추가 | Mac 필요 |
| 앱 | 빌드 값 `APPLE_LOGIN_ENABLED=true`(`.env.release`나 `--dart-define`). 켜면 `AppleLoginButton`이 `_onApple`로 연결됨 | 코드 변경 없음, 값만 |
| 앱 | iOS에서는 `SignInWithApple.getAppleIDCredential`로 identity token을 받아 서버에 보냄(`auth_service.dart:98-120`). 이메일 숨기기(릴레이 주소)로 이메일이 비어도 계정이 만들어지는지 실기기에서 확인 | Mac·실기기 |
| 서버 | Cloud Run 환경 변수 **`APPLE_CLIENT_ID`를 iOS 번들 ID `com.sharerun.shareRunChallenge`로 설정.** 비어 있으면 서버는 서명·만료·발급자만 확인하고 **audience(어느 앱용 토큰인지)를 확인하지 않는다**(`backend/jena_ai/app/services/identities.py:297-306`). 켜기 전에 반드시 설정 | 계정 필요(서버 배포) |
| 서버 | 로그인 처리 코드는 이미 있음(`identities.py:59-292`, 앱 `identity_api_client.dart` `appleLogin`) | 준비됨 |
| Apple 포털 | 번들 ID(App ID)에서 **Sign in with Apple** 사용 체크. iOS 네이티브 로그인만이면 Services ID와 키(.p8)는 필요 없음. Android의 웹 로그인(`signInWithProvider('apple.com')`, `auth_service.dart:98` 아래 분기)을 쓰려면 Services ID, Return URL, 키가 필요하고 Firebase에 등록(이미 했는지 미확인) | 승인 필요(포털 설정), 계정 필요 |
| Firebase 콘솔 | Authentication > 로그인 방법 > Apple 사용 설정(Android 경로가 쓰므로 이미 되어 있을 수 있음, 미확인) | 계정 필요 |
| 계정 삭제 | 앱 안 계정 삭제는 있다(`secured_action_api_client.dart:354`, 서버 `/actions/account/delete`, `secured_action_router.py:210`). 지침 5.1.1(v) 원문은 "앱이 계정 생성을 지원하면 앱 안에서 계정 삭제를 제공해야 한다"이다. **애플 로그인 사용자의 Apple 토큰 취소(revoke) 처리는 코드에 없다**(서버 검색 결과 없음). Apple이 이를 요구하는지와 방법은 Apple 개발자 문서에서 확인해야 한다(미확인). 필요하면 앱 키(.p8)로 만든 클라이언트 시크릿이 필요해 발급 승인이 따른다 | 미확인, 승인 필요 가능 |

**심사용 접근 방법 제안** (인증 우회, 공용 비밀번호 하드코딩 금지)
Apple 지침 원문(2.1): *"include demo account info (and turn on your back-end service!) if your app includes a login. If you are unable to provide a demo account due to legal or security obligations, you may include a built-in demo mode in lieu of a demo account with prior approval by Apple."* 그리고 제출 전 안내: *"Provide App Review with full access to your app. If your app includes account-based features, provide either an active demo account or fully-featured demo mode … Enable backend services so that they're live and accessible during review."*
1. **권장: 애플 로그인을 켠 뒤 심사관이 자기 Apple ID로 직접 가입**(별도 계정이 필요 없고 비밀번호가 없다). 심사 메모에 "처음 실행 > Apple로 계속하기"와 기능별 확인 방법, 서버가 켜져 있음, 걷기·달리기는 실제 움직임이 필요하므로 시연 영상 링크, 문의 연락처를 적는다. 가장 단순하고 인증 우회가 없다.
2. 심사관이 못 쓰는 상황을 대비한 **실제 계정 방식**: 앱에 이메일 로그인 화면이 없어 지금은 불가능하다. 하려면 정상 인증을 쓰는 로그인 수단을 새로 만드는 작업이라 별도 개발 결정이다(1차 범위 밖).
3. **하지 않는 것**: 앱에 내장한 시연 모드로 인증을 건너뛰는 방식(Apple의 사전 승인이 필요하고 보안상 위험), 코드에 박힌 공용 비밀번호나 서버의 "심사용 통과" 스위치.
4. TestFlight 내부 테스트는 심사가 필요 없으므로 위 문제는 **심사 제출 때**의 일이다.

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
| 권한 문구 11개 언어(`InfoPlist.strings`) | 준비됨(초안), Mac 필요(타깃 연결) | 파일은 만들었고 `check_ios_config.py`가 검사한다. 원어민 검수 전 |
| 개인정보 매니페스트(`PrivacyInfo.xcprivacy`) | 부분 준비, Mac 필요 | 앱 코드는 필수 사유 API 사용 0건, 플러그인 중 `flutter_foreground_task`(UserDefaults)와 `pedometer`(시스템 부팅 시간)가 자체 매니페스트 없이 사용. **사유 코드는 Apple 공식 표를 확인하지 못해 비워 둠.** 수집 데이터 종류는 대표님 확정 필요. 자세한 내용 `docs/ios-privacy-manifest.md` |
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
1. `ios/Runner/Info.plist`
   - `BGTaskSchedulerPermittedIdentifiers` 추가: `flutter_foreground_task` README 요구.
   - `CFBundleLocalizations` 11개 언어 추가: 권한 문구 현지화를 쓰려면 필요.
   - 마이크·음성·블루투스·사진 문구의 기본(한국어) 값을 새 ko 문구와 맞춤: "한글로", "한국어 음성" 표현 제거.
2. `ios/Runner/<언어>.lproj/InfoPlist.strings` 11개: 실제 요청하는 권한 문구 초안. 아직 Xcode 프로젝트에 연결되지 않았다(Mac 필요).
3. `.gitignore`와 생성 파일 4개 추적 해제(공식 템플릿과 일치, 1절).
4. `tool/ios/check_ios_config.py`: `Info.plist`, entitlements, URL 스킴, 백그라운드 모드, 번들 ID, 권한 문구 11개 언어를 점검(비밀값 출력 없음). 정상 파일에서 통과 69·실패 0·건너뜀 4, 일부러 망가뜨린 복사본에서는 실패를 잡는 것을 확인했다.
5. `tool/ios/scan_required_reason_apis.py`: 필수 사유 API를 쓰는 곳을 글자 검색(사유 코드는 정하지 않음).
6. 문서: 이 문서, `docs/ios-privacy-manifest.md`, `docs/ios-device-test-plan.md`, `docs/ios-mac-runbook.md`.
앱 Dart 코드, Android 파일, 번들 ID, 지도 키는 바꾸지 않았다. 개인정보 매니페스트 파일(`PrivacyInfo.xcprivacy`)은 사유 코드를 확인하지 못해 `ios/`에 넣지 않았다(`docs/ios-privacy-manifest.md`).

## 7. 분석·테스트 재실행 결과 (이 환경)
환경: Linux 컨테이너(Windows·Mac 아님), Flutter **3.44.3**(노트북과 같은 버전), Dart 3.12.2. 기준: `main` `ac2e95e` + 이 브랜치.
| 명령 | 종료 결과 |
|---|---|
| `flutter pub get` | 성공. `pubspec.lock`이 달라지지만 **커밋하지 않고 되돌렸다**(이 환경과 노트북의 해석 차이로 보임) |
| `flutter analyze lib test` | **종료 코드 1**(이슈가 있어서). 오류 0, 경고 22, 정보 178(총 200건). **전체 통과가 아니다** |
| `flutter test --exclude-tags golden --no-pub` | 1095개 모두 통과, 종료 코드 0 |
| `python3 tool/ios/check_ios_config.py` | 통과 69(권한 문구 파일 11개 포함), 실패 0, 건너뜀 4 |
| iOS 빌드, `pod install`, 서명, 시뮬레이터·실기기 | **실행하지 않음(Mac 필요)** |
- 지난 보고(Flutter 3.47.7)의 분석 203건(경고 25)과 차이 3건은 Flutter·Dart 버전 차이로 추정(개별 대조 안 함). 오류는 양쪽 0, 정보 178건 동일.
- 지난 "1,095개 통과"와 개수가 같다. 이 브랜치는 Dart를 바꾸지 않았고 병합한 #385는 매니페스트와 버전뿐이다. (PR #384 브랜치는 같은 명령으로 1140개였다. 새 테스트 45개 차이이며 이 브랜치와 무관.)

### 경고 22건 분류 (모두 **기존 문제**, 이 브랜치가 만든 것은 없음)
이 브랜치는 `.dart` 파일을 하나도 바꾸지 않았다(`git diff origin/main --name-only -- '*.dart'` = 0건). `main`과 같은 Dart 코드에서 나온 경고라 신규가 없다. 범위를 벗어난 일괄 수정은 하지 않았다.
| 종류(규칙) | 건수 | 위치 |
|---|---|---|
| `unused_import` | 7 | `lib/core/widgets/src_dashboard_bottom_nav.dart:5`, `lib/data/repositories/user_repository.dart:8`, `lib/screens/battle_pass_screen.dart:7`, `lib/screens/smart_watch_sync_screen.dart:3`, `lib/features/profile/widgets/my_village_hero.dart:3`, `test/features/shop/battle_pass_grant_test.dart:2`, `test/features/shop/accessory_purchase_test.dart:5` |
| `unused_element`(안 쓰는 함수·클래스) | 7 | `solo_pedometer_screen.dart:1016/1031/1224/2829`, `device_connection_screen.dart:554/601`, `my_page_screen.dart:411` |
| `unused_field` | 2 | `solo_pedometer_screen.dart:299/302` |
| `unused_element_parameter` | 3 | `challenge_lobby_screen.dart:518/519`, `solo_pedometer_screen.dart:2918` |
| `unnecessary_non_null_assertion` | 2 | `tournament_detail_screen.dart:168/184` |
| `override_on_non_overriding_member` | 1 | `store_screen.dart:690` |
정리는 동작을 건드리지 않는 작은 정리(미사용 import 삭제 등)로 따로 PR을 만드는 것이 안전하다. 이번 iOS 준비의 범위가 아니다.

## 8. 테스트 결과 (같은 환경, Flutter 3.44.3)
| 명령 | 종료 결과 |
|---|---|
| `flutter test --exclude-tags golden --no-pub` (CI와 같은 범위) | **1095개 모두 통과, 종료 코드 0**, 실패 원문 없음 |
- 골든 테스트(`golden` 태그)는 CI와 같이 제외했다(Linux와 Windows의 글꼴 차이로 로컬 비교가 어긋남).
- iOS 빌드, `pod install`, 서명, 시뮬레이터·실기기는 실행하지 않았다(Mac 필요).

## 9. 권한 문구와 기능이 맞지 않는 곳 (보고만, `Info.plist` 키는 지우지 않았다)
권한 문구 11개 언어 초안은 `ios/Runner/<언어>.lproj/InfoPlist.strings`(ko, en, ja, zh-Hant, es, pt-BR, de, fr, vi, th, id). **실제로 요청하는 권한 키만** 넣었다. 번역은 원어민 검수 전이다. Xcode 프로젝트가 생기면 `InfoPlist.strings`를 Runner 타깃에 변형 그룹(Localized)으로 추가해야 하고 이 파일들은 아직 어떤 프로젝트에도 연결돼 있지 않다(Mac 필요).
| 권한 키 | 실제 요청하는가 | 근거 | 판정 |
|---|---|---|---|
| `NSBluetoothAlwaysUsageDescription` | 예 | `ios/Runner/BleHeartRatePlugin.swift`(블루투스 심박 센서) | 유지, 11개 언어 |
| `NSHealthShareUsageDescription` | 예 | `health`로 걸음 수 읽기(`health_data_service.dart`) | 유지, 11개 언어 |
| `NSLocationWhenInUse…`, `NSLocationAlwaysAndWhenInUse…` | 예 | `geolocator`, 달리기 백그라운드 | 유지, 11개 언어 |
| `NSMotionUsageDescription` | 예 | `pedometer`, `sensors_plus` | 유지, 11개 언어 |
| `NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription` | 예 | `speech_to_text`(`lib/features/mini_bot/mini_bot_voice.dart:191`) | 유지. **옛 문구가 "한글로", "한국어 음성"이라 11개 언어 지원과 맞지 않아** 언어 중립 문구로 바꿨다(기본 `Info.plist`도 같이) |
| `NSCameraUsageDescription` | 예 | `ImageSource.camera`(`onboarding_run_result_screen.dart:521`) | 유지, 11개 언어 |
| `NSPhotoLibraryUsageDescription` | 예 | `ImageSource.gallery`(아바타 `avatar_choice_provider.dart:62`, 이의 신청 `appeal_center_screen.dart:158`, 완주 카드 배경) | 유지. 문구에 이의 신청 증빙을 추가 |
| `NSFaceIDUsageDescription` | **결제가 켜질 때만** | `local_auth`는 `payment_auth.dart:84`에서만 쓰이고 1.0은 결제가 꺼져 있다 | 키는 유지(결제를 켜면 필요). 1.0에서 쓰이지 않는 권한이라 심사에서 질문받을 수 있다 |
| `NSHealthUpdateUsageDescription` | **아니오** | 앱은 건강 데이터에 쓰기를 하지 않는다(쓰기 호출 없음). 문구도 "운동 목표 달성 기록을 연동"이라 실제 기능과 다르다 | **불필요한 권한 문구.** 지우는 것을 권장(Mac에서 HealthKit 권한 창이 정상인지 보고 결정). 11개 언어에는 넣지 않았다 |
| `NSBluetoothPeripheralUsageDescription` | 아니오 | iOS 13부터 쓰지 않는 옛 키, 최소 iOS 15 | 불필요. 지워도 된다고 판단하나 보고만 |
| `NSLocationAlwaysUsageDescription` | 아니오 | iOS 11 이전용 옛 키 | 불필요. 보고만 |
| 알림 권한 | 예(런타임) | `firebase_messaging`, `flutter_local_notifications` | `Info.plist` 문구 키가 없다. 시스템 창이 뜬다 |
| 백그라운드 모드 | `location`, `bluetooth-central`, `fetch` 사용. `processing`은 쓰는 코드를 못 찾음. `audio`는 필요 여부 미확인 | | `processing` 제거는 Mac 검증 뒤 결정 |

## 10. 지도 키 (iOS) — 교체하지 않았다
| 확인한 것 | 내용 |
|---|---|
| 키 위치 | `ios/Runner/AppDelegate.swift:11` `GMSServices.provideAPIKey(...)`. 값은 이 문서에 쓰지 않는다(길이 39, 앞 4자 `AIza`) |
| 쓰는 서비스 | **Maps SDK for iOS**(`google_maps_flutter_ios` 2.18.3, 최소 iOS 14). 지도를 쓰는 화면 6곳: `live_running_screen.dart`, `run_result_screen.dart`, `in_challenge_screen.dart`, `challenge_detail_screen.dart`, `stamp_tour_screen.dart`, `lib/features/map_crew/widgets/safe_map_panel.dart` |
| Android 키와의 관계 | #385 이후 **값이 다르다**(SHA-256 앞 8자리가 달라 서로 다른 키). 값이 다르다는 이유로 교체하지 않았다. iOS 키가 옛 프로젝트의 키인지, 지금도 유효한지는 이 환경에서 알 수 없다(미확인) |
| 보안 | 키가 첫 커밋부터 저장소에 평문으로 있다. 제한이 걸려 있다면 노출 피해가 작고, 제한이 없다면 교체와 주입 방식 변경이 필요하다 |
| **콘솔에서 대표님이 확인할 것(클릭 순서)** | ① Google Cloud 콘솔 > API 및 서비스 > 사용자 인증 정보에서 이 iOS 키를 키 문자열로 검색해 어느 프로젝트의 키인지 확인 ② 같은 프로젝트의 사용 설정된 API에 **Maps SDK for iOS**가 있는지(라이브러리에서 사용 설정) ③ 키 상세의 "API 제한"에 Maps SDK for iOS가 들어 있는지 ④ "애플리케이션 제한"이 "iOS 앱"이면 **번들 ID `com.sharerun.shareRunChallenge`**가 있는지, "없음"이면 제한 추가를 검토 ⑤ 결제 계정 연결 여부 ⑥ 이 키로 쓸지, 새 iOS 전용 키를 만들지 결정 |
| 실기기 확인 | 지도가 회색·베이지로 나오면 안드로이드에서 겪은 것과 같은 유형(키 제한, 서비스 미사용 설정)일 가능성이 높다. 시험표에 있다 |
