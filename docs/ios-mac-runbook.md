# Mac 수령 후 iOS 작업 순서표 (11월 12일부터 약 7일)

목표는 **첫 빌드와 TestFlight 업로드**다. 일주일 안의 심사 통과는 약속하지 않는다.
이 문서의 명령은 한 번도 실행해 보지 않았다(Mac이 없음). 막히면 오류 원문을 기록하고 근거 없이 같은 시도를 반복하지 않는다.
점검 결과와 근거는 `docs/ios-readiness.md`.

## 0. 일정과 이미 정해진 것 (2026-11-08 기준)
| 항목 | 상태 |
|---|---|
| Apple Developer Program 가입 | **11월 11일(수) 가입 예정**(대표님, 결제 포함). **가입(승인) 전에도 무료 Apple Account(Xcode의 Personal Team)로 대여 아이폰에 개발용 앱을 서명·설치해 실행할 수 있다(제한 있음, 0-3절).** TestFlight·App Store Connect 업로드, 푸시, Apple 로그인은 유료 가입이 필요하다 |
| 맥 | **M2 맥북, 11월 12일(목)부터 일주일 대여**(조카) |
| 아이폰 | **실제 아이폰을 11월 12일부터 일주일 대여**. 모델과 iOS 버전은 수령 당일 확인(아직 모름) |
| 기기 사용 규칙 | 조카의 허락을 받은 별도 macOS 사용자 계정만 쓴다(아래 1절) |
이미 답이 나온 질문(가입 여부, 테스트 아이폰 확보)은 위 표로 대체했다. 아직 답이 필요한 질문은 4절 끝의 "남은 질문"에 모았다.

## 0-1. 수요일(11/11) 가입 후, 맥을 받기 전에 할 일 (Mac 불필요, 순서대로)
| 순서 | 할 일 | 누가 | 분류 |
|---|---|---|---|
| 1 | Apple Developer Program 가입, 결제 | 대표님 | 승인 필요 |
| 2 | 가입 승인 상태 확인(승인에 시간이 걸릴 수 있음. 승인 전이면 아래 3~8번은 막힌다) | 대표님 | 계정 필요 |
| 3 | Certificates, Identifiers & Profiles > Identifiers에서 **앱 ID 등록: `com.sharerun.shareRunChallenge`** 후 Capability 체크: HealthKit, Push Notifications, Sign in with Apple, Background Modes 계열(필요 시) | 대표님 | 승인 필요 |
| 4 | App Store Connect > 앱 > 새 앱 만들기(이름 "쉐어런", 기본 언어, 번들 ID 선택, SKU) | 대표님 | 승인 필요 |
| 5 | Firebase 콘솔에서 **iOS 앱 추가**(번들 ID 동일) 후 `GoogleService-Info.plist` 내려받기. 안전한 곳에 보관(Git 금지). 구글 로그인용 `REVERSED_CLIENT_ID`, `CLIENT_ID`가 여기 있다 | 대표님 | 계정 필요 |
| 6 | 푸시를 1차에 넣을 경우: Apple에서 APNs 인증 키(.p8) 발급 > Firebase 프로젝트 설정 > 클라우드 메시징에 업로드. 키 파일은 안전한 곳에만 | 대표님 | 승인 필요 |
| 7 | 서버 Cloud Run 환경 변수 `APPLE_CLIENT_ID=com.sharerun.shareRunChallenge` 설정과 배포(애플 로그인을 켜기 전에). 비어 있으면 서버가 Apple 로그인 토큰을 503으로 거부한다(`identities.py`, 커밋 `2b5f32f`로 고침. 이전에는 audience를 확인하지 않고 통과시켰다) | 대표님 또는 서버 담당 | 승인 필요 |
| 8 | 카카오 개발자 콘솔 > 플랫폼 > iOS 번들 ID 등록. 네이버 개발자 센터 iOS 설정. 구글 지도 iOS 키 확인(`ios-readiness.md` 10절) | 대표님 | 계정 필요 |
| 9 | 결정: 애플 로그인을 1차에 켤지, iPad 포함 여부, 애플워치 1차 제외(권장), 암호 수출 규정 답변, 심사용 접근 방법(`ios-readiness.md` 3절) | 대표님 | 계정 필요(결정) |
| 10 | 수령 전에 제가 준비해 둘 것: 이 런북, `tool/ios/check_ios_config.py`, `InfoPlist.strings`, 시험표(`docs/ios-device-test-plan.md`). **발급·가입·결제·콘솔 설정 변경은 대표님만** | 참모 | 준비됨 |
가입 승인이 늦어져도 **맥에서 무료 Personal Team으로 서명하고 실기기 실행까지는 할 수 있다**(0-3절의 제한 안에서). 승인에 걸리는 시간은 확인하지 못했다(미확인). 승인 전에 막히는 것은 2·3·4·6·7번 중 Apple 포털이 필요한 일(앱 ID 등록, 앱 레코드, APNs 키)이고, 5번(Firebase iOS 앱)과 8번(카카오·네이버·지도 콘솔)은 Apple 가입과 무관하게 할 수 있다. 4번(앱 레코드)은 TestFlight 업로드 직전까지 미뤄도 된다.

## 0-2. 목요일(11/12) 맥·아이폰 수령 후 할 일 (순서대로, 막히면 멈추고 원문 기록)
| 순서 | 할 일 | 문서 |
|---|---|---|
| 1 | 조카의 허락으로 **별도 macOS 사용자 계정** 만들기. 조카 Apple ID·자료는 건드리지 않는다 | 1절 |
| 2 | 도착 직후 점검: macOS, Xcode, 디스크, **Apple의 당일 업로드 요건**, 아이폰 iOS와 Xcode 호환 | 2절 |
| 3 | 아이폰 개발자 모드·기기 신뢰는 **대표님 동의 후**(아이폰 소유자) | 2절 |
| 4 | 환경 설치(Flutter 3.44.3, CocoaPods, 저장소), `flutter pub get` | 3절 |
| 5 | 기준선 점검 `python3 tool/ios/check_ios_config.py` > iOS 프로젝트 생성 > 생성 후 diff와 재점검 | 4절 |
| 6 | Xcode: 서명(유료 승인 전이면 Personal Team. 푸시·Apple 로그인 Capability는 유료 팀에서만), Capability, `GoogleService-Info.plist`, `InfoPlist.strings`·`PrivacyInfo.xcprivacy` 연결, `pod install` | 5절 |
| 7 | **첫 실행 → 로그인 → 걸음·건강 권한 → 러닝·백그라운드 → 저장·동기화 → 배포 빌드**(시험표 `docs/ios-device-test-plan.md`) | 6-1절 |
| 8 | 개인정보 Privacy Report, 배포용 빌드, 대표님 승인 뒤 TestFlight 업로드 | 6절, `docs/ios-privacy-manifest.md` |
| 9 | 인수인계서 작성, 반납 전 정리(로컬 삭제와 원격 폐기 구분) | 8절 |
첫 이틀(11/12~13) 안에 7번의 첫 실행과 8번의 첫 업로드 시도까지 간다. 나머지는 오류 수정과 재검증에 쓴다.

## 0-3. 유료 가입 전·후에 할 수 있는 일 (Apple 공식 자료 기준)
출처: Apple "Compare memberships"(developer.apple.com/support/compare-memberships)와 "Supported capabilities (iOS)"(developer.apple.com/help/account/reference/supported-capabilities-ios), 2026-11-08에 읽은 내용. 능력 표의 "Apple Developer" 열(무료 계정, 배포 불가)을 무료 Personal Team으로 해석했다. 두 페이지가 이 대응을 직접 적어 놓지는 않았으므로 실제 Xcode에서 확인한다(미확인).
| 구분 | 무료 Apple Account (Personal Team) | 유료 Apple Developer Program |
|---|---|---|
| 내 기기에 개발용 설치·실행 | **가능.** Xcode에 Apple Account로 로그인하면 Personal Team으로 설치·테스트 | 가능 |
| 기기 제한 | App ID 10개(7일 뒤 만료), 기기 3대(7일 뒤 만료), **기기당 앱 3개**, 프로비저닝 프로파일은 **발급 7일 뒤 만료 → 다시 빌드·설치** | 별도 한도(이 문서에서는 확인하지 않음) |
| TestFlight, App Store Connect, App Store 배포 | **불가.** "developers can't distribute apps" | 가능 |
| Certificates, Identifiers & Profiles(포털) | 사용 불가("paid-program resource") | 가능 |
| Background modes(위치, 블루투스) | **가능** | 가능 |
| HealthKit | **가능** | 가능 |
| Push notifications | **불가** | 가능 |
| Sign in with Apple | **불가** | 가능 |
| Associated domains | 불가 | 가능 |
이 앱에 대입하면:
- **무료로 가능한 시험**: 로그인(구글·카카오·네이버는 Capability가 필요 없음. 구글은 Firebase iOS 앱 등록과 `GoogleService-Info.plist`가 필요하고 이는 Apple 가입과 무관), 위치와 백그라운드 위치, 블루투스 심박 센서, 모션 걸음 수, HealthKit 읽기, 지도, 카메라·사진, 알림 권한 창(로컬 알림), 러닝 기록 저장·동기화, 계정 삭제.
- **무료로 불가능한 시험**: 푸시 알림(APNs), Apple 로그인, TestFlight 업로드와 배포용 빌드의 업로드, 심사 제출.
- **무료 팀으로 서명할 때 주의**: `Runner.entitlements`에 Sign in with Apple(`com.apple.developer.applesignin`)이나 푸시(`aps-environment`)를 넣으면 프로비저닝이 실패한다. 이 두 Capability는 **유료 팀으로 바꾼 뒤에** 추가한다. 지금 저장소의 `Runner.entitlements`에는 HealthKit만 있어서 무료 팀에서 그대로 쓸 수 있다.
- 일주일 대여라 7일 만료는 거의 문제가 되지 않지만, 11/12 설치분은 11/19쯤 만료될 수 있다(프로파일 발급 시각 기준).
- 무료로 쌓은 서명 설정(번들 ID 자동 등록 등)이 나중에 유료 팀에서 같은 번들 ID를 등록할 때 충돌하는지는 확인하지 못했다(미확인). 유료 승인 뒤에는 Xcode에서 팀을 유료 팀으로 바꾸고 번들 ID를 다시 확인한다.

## 1. 지켜야 할 규칙
- 조카의 Apple ID를 로그아웃하지 않는다. 조카 자료를 열거나 바꾸지 않는다. 우리 작업은 **우리가 만든 별도 macOS 사용자 계정**에서만 한다(조카가 동의한 뒤).
- 우리 Apple ID는 그 사용자 계정 안의 Xcode에만 로그인한다.
- **아이폰은 대표님 소유가 아니라 대여한 기기다.** 개발자 모드 켜기와 "이 컴퓨터 신뢰", 개발용 앱 설치는 아이폰 소유자의 동의를 받은 뒤에 하고, 반납 전에 우리가 설치한 앱을 지운다. 그 기기의 Apple ID와 자료는 건드리지 않는다.
- 비밀(.p8 키, 인증서, `.env.release`, `GoogleService-Info.plist`)은 Git, 메신저, 보고서에 넣지 않는다. USB나 안전한 전송으로 옮기고, 반납 전에 지운다.
- 유료 가입·결제, 인증서·키 발급이나 폐기, App Store Connect 제출, 외부 설정 변경은 대표님 승인 뒤에만 한다.

## 2. 도착 직후 점검 (약 30분, 수령 당일)
```bash
sw_vers                                  # macOS 버전
uname -m                                 # arm64(M2) 확인
xcodebuild -version                      # Xcode가 설치돼 있으면 버전
xcrun --sdk iphoneos --show-sdk-version  # iOS SDK 버전
df -h ~                                  # 디스크 여유(Xcode, 시뮬레이터에 수십 GB 필요)
```
| 확인 | 판단 |
|---|---|
| **Apple의 현재 업로드 요건** | **수령 당일 Apple 공식 표(App Store Connect 업로드 요건, Xcode 릴리스 노트)에서 최소 Xcode와 iOS SDK 버전을 다시 확인한다.** 이 문서에는 값을 적지 않았다(미확인) |
| macOS가 그 Xcode를 지원하는가 | 지원하면 진행. 아니면 macOS 업그레이드가 필요한데, 이는 조카 기기 전체에 영향을 주므로 **대표님과 조카의 동의 없이 하지 않는다.** 동의가 없으면 7절(빌드 서비스)로 전환 |
| **아이폰 iOS 버전과 Xcode 호환** | 아이폰 설정 > 일반 > 정보에서 iOS 버전 확인. 설치된 Xcode가 그 iOS를 지원하는 기기 디버깅 버전인지 Xcode 릴리스 노트로 확인(미확인) |
| 디스크 여유 | 부족하면 시뮬레이터 런타임을 설치하지 않고 실기기 위주로 진행 |
| 별도 사용자 계정 | **조카의 허락을 받은 뒤** 우리 전용 macOS 사용자 계정을 만든다. 조카 계정에서 작업하지 않는다 |
| **아이폰 설정** | 개발자 모드 켜기, 이 컴퓨터 신뢰는 **아이폰 소유자(대표님) 동의 후** 진행한다. 개발자 모드는 재부팅을 한 번 요구한다 |
- 점검에서 막히면(디스크, 버전 불일치) 여기서 멈추고 오류 원문과 함께 보고한다.

## 3. 환경 만들기 (새 사용자 계정의 홈 안에서)
```bash
xcode-select --install                    # 이미 있으면 건너뜀. 관리자 암호가 필요하면 조카에게 요청
sudo xcodebuild -license accept           # 관리자 권한 필요
# Flutter는 노트북과 같은 3.44.3. 사용자 홈 아래에만 설치한다
git clone https://github.com/flutter/flutter.git -b 3.44.3 ~/dev/flutter
export PATH="$HOME/dev/flutter/bin:$PATH"
flutter --version                         # 3.44.3인지 확인
flutter doctor -v                         # Xcode, CocoaPods 항목 확인
sudo gem install cocoapods                # 또는 Homebrew가 있으면 brew install cocoapods
git clone https://github.com/hsk0077-s/sharerun-challenge.git ~/dev/sharerun
cd ~/dev/sharerun && git checkout chore/ios-prep   # 이 브랜치가 머지됐다면 main
flutter pub get
```
`flutter pub get`이 `ios/Flutter/Generated.xcconfig`, `GeneratedPluginRegistrant.*`를 새로 만든다(둘 다 git에서 제외했다).

## 4. iOS 프로젝트 파일 만들기 (기존 설정이 유실되지 않게)
저장소의 `ios/`에는 `Runner.xcodeproj`, `Podfile`, `Main.storyboard`가 없다. Flutter의 프로젝트 생성 명령을 iOS만 대상으로 실행하면 빠진 파일만 만들어지고 기존 파일은 덮어쓰지 않는 것으로 알고 있으나, 이번에는 **실제로 그런지 아래 순서로 확인**한다(미확인).

**4-1. 생성 전 보존** (작업 폴더가 깨끗한지 먼저 확인)
```bash
cd ~/dev/sharerun
git status --short                         # 비어 있어야 한다
cp -R ios ~/dev/ios-before-create          # 원본 보존(저장소 밖)
python3 tool/ios/check_ios_config.py       # 기준선: 통과 24, 실패 0, 건너뜀 4 가 나와야 한다
```

**4-2. 생성**
```bash
flutter create --platforms=ios --project-name share_run_challenge --org com.sharerun .
```

**4-3. 생성 후 diff 확인**
```bash
git status --short                         # 새 파일(??)만 있어야 한다. 기존 파일에 M 표시가 있으면 아래로
git diff --stat                            # 기존 파일 변경이 있는지
diff -ru ~/dev/ios-before-create/Runner ios/Runner | head -80    # Info.plist, AppDelegate.swift, entitlements가 그대로인지
python3 tool/ios/check_ios_config.py       # 실패 0 이어야 한다. 이제 '번들 ID' 항목도 검사된다
```
- 기존 파일이 바뀌었으면 **되돌리지 말고 먼저 `git diff`로 무엇이 바뀌었는지 기록**한다. 유실된 항목은 아래 4-4로 재적용한다.
- 생성이 만드는 `ios/Runner/GeneratedPluginRegistrant.*`, `ios/Flutter/Generated.xcconfig`는 `.gitignore`에 있어 커밋 대상이 아니다.

**4-4. 유실된 설정 재적용** (`check_ios_config.py`가 [실패]로 알려 주는 것만)
| 점검 항목 | 되살리는 방법 |
|---|---|
| 권한 문구, 카카오 URL 스킴, `LSApplicationQueriesSchemes`, 백그라운드 모드, `BGTaskSchedulerPermittedIdentifiers` | `~/dev/ios-before-create/Runner/Info.plist`와 새 `ios/Runner/Info.plist`를 비교해 빠진 키만 옮긴다. 통째로 덮어쓰지 않는다 |
| HealthKit entitlement | `ios/Runner/Runner.entitlements`를 원본으로 복구 후 Xcode Capabilities가 가리키는지 확인 |
| 번들 ID | Runner 타깃의 `PRODUCT_BUNDLE_IDENTIFIER`(Debug/Release/Profile 모두)를 **`com.sharerun.shareRunChallenge`**로. Apple Developer 등록 현황을 확인하기 전에는 다른 값으로 바꾸지 않는다(등록 전이면 등록부터) |
| `BleHeartRatePlugin.swift`, `WatchBridgePlugin.swift`가 타깃에 없음 | Xcode에서 Runner 타깃 Build Phases > Compile Sources에 추가 |

**4-5. 그 밖의 필수 설정**
- `Podfile` 첫 줄을 `platform :ios, '15.0'`으로(플러그인 최소가 15.0).
- `permission_handler`: 쓰는 권한(`photos`, `notification`, `location`/`always`, `activityRecognition`)에 맞는 `PERMISSION_*=1`을 `Podfile`의 `post_install`에 넣는다(`permission_handler_apple` README 참고).
- 프로젝트의 iOS 배포 타깃(`IPHONEOS_DEPLOYMENT_TARGET`)도 15.0 이상인지 `check_ios_config.py`로 확인.
```bash
cd ios && pod install --repo-update && cd ..
```
`pod install` 오류는 원문을 기록한다. SPM과 CocoaPods 중 무엇이 쓰이는지는 `flutter config`와 빌드 로그로 확인(미확인).

**남은 질문 (답이 필요한 것만)**
1. 번들 ID `com.sharerun.shareRunChallenge`를 쓸 것인가(밑줄 때문에 Android ID와 다르다). 기본은 이 값을 유지하고 임의로 바꾸지 않는다.
2. 푸시를 1차에 포함하는가(APNs 키 발급이 필요).
3. 애플 로그인을 1차에 켜는가(서버 `APPLE_CLIENT_ID` 필요).
4. iOS 지도 키: 현재 키를 쓸지, 새 키를 만들지.
5. 암호 수출 규정 답변, iPad 포함 여부, 워치 1차 제외 여부, 심사용 접근 방법.
6. 아이폰 모델과 iOS 버전(수령 당일 확인), 맥의 macOS와 Xcode 버전(수령 당일 확인).

## 5. Xcode 설정 (`open ios/Runner.xcworkspace`)
1. Runner 타깃, Signing & Capabilities: Team은 **우리 Apple Developer 팀**(조카 아님). Bundle Identifier 확인.
2. Capabilities 추가: HealthKit, Push Notifications, Sign in with Apple, Background Modes(Location updates, Uses Bluetooth LE accessories, Background fetch, Remote notifications). 오디오 안내가 화면 꺼짐에서도 나와야 하면 Audio도(확인 후).
3. `Runner.entitlements`에 `com.apple.developer.applesignin`, `aps-environment`가 들어갔는지 확인(HealthKit은 이미 있음).
4. 다음 파일이 Runner 타깃에 포함됐는지 확인: `BleHeartRatePlugin.swift`, `WatchBridgePlugin.swift`(`AppDelegate.swift`가 쓴다).
5. `GoogleService-Info.plist`를 `ios/Runner`에 넣고 타깃에 포함한다. `Info.plist`에 `GIDClientID`와 `REVERSED_CLIENT_ID` URL 스킴을 추가한다(구글 로그인). 네이버 로그인 항목은 플러그인 README대로 추가한다.
6. 지도 키 제한 확인(콘솔), 지도가 나오는지 시뮬레이터에서 확인.
6-1. `ios/Runner/<언어>.lproj/InfoPlist.strings` 11개를 Runner 타깃에 **Localized 변형 그룹**으로 추가한다(저장소에 파일은 이미 있고 아직 프로젝트에 연결돼 있지 않다). 기기 언어를 바꿔 권한 창이 그 언어로 나오는지 확인. `python3 tool/ios/check_ios_config.py`가 파일 11개와 키를 검사한다.
6-2. `PrivacyInfo.xcprivacy`: `docs/ios-privacy-manifest.md`의 초안과 근거 표를 보고, 사유 코드는 **그날 Apple 공식 표**에서 골라 넣는다(코드를 저장소 문서에서 가져오지 않는다). 필수 사유 API 후보는 `python3 tool/ios/scan_required_reason_apis.py`로 다시 확인.
7. 워치 타깃은 1차에서 만들지 않는다. 넣을 때는 `watchos_app/README-XCODE-SETUP.md`.

## 6. 실행 순서와 일정
| 시점 | 할 일 | 끝났다는 기준 |
|---|---|---|
| D0 (11/12) | 2절 점검, 3절 환경, 4절 프로젝트 생성, `pod install` | `flutter doctor`에서 iOS 오류 없음, `pod install` 성공 |
| D1 오전 | 시뮬레이터 실행: `flutter run -d "iPhone" --dart-define-from-file=.env.release` | 앱이 뜬다. 첫 오류는 원문 기록 |
| D1 오후 | 서명 설정(유료 승인 전이면 무료 Personal Team, 0-3절), 실기기 실행(개발자 모드 켠 iPhone): `flutter run --release -d <기기ID> --dart-define-from-file=.env.release` | 로그인 화면 표시 |
| D2 | 배포용 빌드: `flutter build ipa --release --dart-define-from-file=.env.release` (또는 Xcode Product > Archive). 대표님 승인 뒤 **TestFlight 업로드**(Transporter 앱 또는 Xcode Organizer) | App Store Connect에 빌드가 "처리 중"으로 뜸 |
| D3~D6 | 빌드·업로드 오류 수정, 권한 문구 11개 언어, `PrivacyInfo.xcprivacy`, 실기기 검증(위치 백그라운드, HealthKit, 블루투스, 푸시, 애플 로그인) | 항목별 체크, 수정은 작은 커밋으로 |
| D6 오후 | 최종 빌드 업로드, 인수인계서 작성 | 아래 8절 완료 |
| D7 | 정리와 반납 | 8절 체크리스트 모두 완료 |

업로드가 막히는 흔한 지점은 서명·프로비저닝, 누락된 아이콘/권한 문구, 수출 규정 질문, 개인정보 매니페스트다. 모두 오류 문구를 그대로 기록한다.

### 6-1. 실기기 검증 순서 (앞 단계가 안 되면 뒤로 가지 않고 원인부터)
1. **첫 실기기 실행**: 개발용으로 설치되고 앱이 뜬다.
2. **로그인**: 구글 → (켜졌다면) 애플 → 카카오 → 네이버. 안 되는 것은 아래 6-2에서 필요한 서비스 설정이 빠졌는지 먼저 본다.
3. **걸음 수·건강 권한**: 모션 권한과 HealthKit 읽기 권한 창이 뜨고 걸음 수가 홈에 나오는지.
4. **러닝·백그라운드**: 위치 권한 "항상 허용", 달리기 시작 후 화면을 끄고 거리가 계속 늘어나는지, 블루투스 심박 센서(있으면), 음성 안내가 화면이 꺼져도 나오는지(안 나오면 `audio` 모드 검토).
5. **저장·동기화**: 달리기 종료 후 결과가 서버에 저장되고 재설치 뒤에도 보이는지, 푸시 알림(켠 경우).
6. **배포 빌드**: `flutter build ipa --release …`가 성공하고, 대표님 승인 뒤 TestFlight 업로드.
각 단계의 결과를 날짜와 함께 기록한다(성공/실패와 오류 원문).

### 6-2. 서비스 설정 상태 (Mac에서 막히면 이 표부터 본다)
| 서비스 | 이미 있음 | 계정 확인 필요 | 발급·설정 승인 필요 |
|---|---|---|---|
| Firebase | Android 연동 | iOS 앱 등록, `GoogleService-Info.plist` | iOS 앱 추가 |
| 구글 로그인 | 앱 코드, 웹 클라이언트 ID(Android) | iOS 클라이언트 ID(`GIDClientID`, URL 스킴) | |
| 카카오 | 앱 키, `Info.plist` URL 스킴 | 콘솔 iOS 번들 ID | |
| 네이버 | Android 설정 | iOS 클라이언트 설정, 콘솔 | |
| 푸시 | Firebase 메시징 코드 | APNs 키가 Firebase에 있는지 | APNs 인증 키(.p8) 발급 |
| 애플 로그인 | 앱·서버 코드 | 서버 `APPLE_CLIENT_ID`, Firebase Apple 공급자 | Capability, 번들 ID 설정 |
| 지도 | 안드로이드 키 교체 완료(#385) | **iOS는 옛 키 그대로.** 어느 키를 쓸지, 번들 ID 제한 | 새 키를 만들 경우 |
| HealthKit | entitlement, 문구 | | 앱 ID에서 HealthKit 사용 설정 |

## 7. 반납 후 업데이트하는 방법 (Mac 없이)
- 1순위: Codemagic 같은 빌드 서비스(Flutter 지원). App Store Connect API 키를 서비스 비밀로 넣으면 서명과 업로드를 자동으로 한다. 요금제는 가입·결제라 대표님 승인 필요.
- 2순위: GitHub Actions macOS 러너(저장소가 private이면 사용 시간이 과금될 수 있음, 미확인) + 같은 API 키.
- 3순위: 필요할 때마다 클라우드 Mac(MacinCloud 등) 대여.
- 어느 쪽이든 인증서와 프로비저닝 프로파일을 대표님이 보관해야 하므로, 이번 대여 중 만든 배포 인증서(.p12)는 **암호와 함께 안전한 곳(비밀번호 관리자)에 백업한 뒤** Mac에서 지운다.

## 8. 반납 전 정리 체크리스트
**로컬 정리**와 **Apple 웹사이트(원격) 폐기**를 구분한다. **원격 폐기(인증서·키·프로파일·앱 ID 취소)는 이 작업에서 하지 않는다.** 폐기 여부는 대표님이 따로 결정한다.

**A. 인계(먼저, 안전한 곳으로)**
- [ ] 우리 작업물을 저장소 브랜치에 푸시했는지 확인. 비밀 파일(.p8, .p12, `.env.release`, `GoogleService-Info.plist`)을 커밋하지 않았는지 `git status --ignored`로 확인
- [ ] 배포 인증서(.p12)와 암호, App Store Connect API 키(.p8)와 키 ID는 **대표님의 비밀번호 관리자(안전한 곳)에 옮겨 두었는지** 확인. 어디에도 평문으로 남기지 않는다
- [ ] 인수인계서: 한 일, 실패한 일과 오류 원문, 남은 일, 다음 빌드 방법(7절), 서비스 설정 상태(6-2)

**B. 로컬 데이터 정리 (우리 macOS 사용자 계정 안에서만)**
- [ ] Xcode > Settings > Accounts에서 **우리 Apple ID 제거**
- [ ] 키체인에서 **우리가 가져온/만든 인증서와 개인 키 삭제**(위 A에서 백업이 확인된 뒤). 이것은 이 Mac에서의 삭제일 뿐 Apple 쪽 인증서는 그대로 유효하다
- [ ] `~/Library/MobileDevice/Provisioning Profiles`의 우리 프로파일, `.env.release`, `GoogleService-Info.plist`, 내려받은 키 파일 삭제
- [ ] `~/dev`(Flutter, 저장소), Xcode DerivedData, Archives, 시뮬레이터 데이터, CocoaPods 캐시 삭제
- [ ] 브라우저, GitHub, Firebase, Google, 카카오, 네이버 로그아웃과 저장된 암호·쿠키 삭제, Git 자격 증명 삭제
- [ ] 아이폰의 개발자 모드·신뢰한 컴퓨터를 원래대로 돌릴지 대표님과 정한다(아이폰은 대표님 소유)
- [ ] 우리가 만든 macOS 사용자 계정 삭제(조카 동의 하에). 조카 계정과 자료는 열거나 바꾸지 않았음을 확인

**C. 하지 않는 것(원격)**
- Apple Developer 웹사이트에서 인증서 Revoke, App ID 삭제, API 키 Revoke, 프로비저닝 프로파일 삭제, TestFlight 빌드 삭제. 필요하면 대표님이 결정해서 직접 한다.
- 키를 새로 발급하거나 외부 서비스 설정을 바꾸는 일.
