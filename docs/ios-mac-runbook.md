# Mac 수령 후 iOS 작업 순서표 (11월 12일부터 약 7일)

목표는 **첫 빌드와 TestFlight 업로드**다. 일주일 안의 심사 통과는 약속하지 않는다.
이 문서의 명령은 한 번도 실행해 보지 않았다(Mac이 없음). 막히면 오류 원문을 기록하고 근거 없이 같은 시도를 반복하지 않는다.
점검 결과와 근거는 `docs/ios-readiness.md`.

## 0. 받기 전에 대표님이 정할 것 (필수)
1. Apple Developer Program 가입과 결제 여부(개인/법인). 가입 전에는 TestFlight 업로드가 불가능하다. 가입은 대표님만 할 수 있다.
2. 번들 ID `com.sharerun.shareRunChallenge`를 Apple Developer에 등록했는지, App Store Connect에 앱 레코드를 만들었는지.
3. 테스트용 iPhone이 있는지(없으면 HealthKit, 블루투스 센서, 푸시, 위치 백그라운드는 검증하지 못하고 시뮬레이터 확인과 빌드 업로드까지만).
4. Firebase에 iOS 앱을 등록하고 `GoogleService-Info.plist`를 받았는지. 구글 로그인 `REVERSED_CLIENT_ID`가 여기서 나온다.
5. APNs 인증 키(.p8)를 만들어 Firebase에 올렸는지(푸시를 1차에 포함할지도 결정).
6. 애플 로그인: 서버 `APPLE_CLIENT_ID` 설정과 `APPLE_LOGIN_ENABLED` 빌드 값을 켤지(소셜 로그인을 쓰므로 심사에는 필요).
7. 카카오·네이버 개발자 콘솔에 iOS 번들 ID 등록, 지도 API 키의 iOS 번들 ID 제한.
8. 암호 수출 규정 답변(`ITSAppUsesNonExemptEncryption`), iPad 포함 여부, 애플워치를 1차에서 뺄지(권장: 뺀다).
9. 심사용 로그인 방법(데모 계정).
10. 조카에게: 별도 macOS 사용자 계정 생성 동의, 기기 macOS 버전과 디스크 여유 확인.

## 1. 지켜야 할 규칙
- 조카의 Apple ID를 로그아웃하지 않는다. 조카 자료를 열거나 바꾸지 않는다. 우리 작업은 **우리가 만든 별도 macOS 사용자 계정**에서만 한다(조카가 동의한 뒤).
- 우리 Apple ID는 그 사용자 계정 안의 Xcode에만 로그인한다.
- 비밀(.p8 키, 인증서, `.env.release`, `GoogleService-Info.plist`)은 Git, 메신저, 보고서에 넣지 않는다. USB나 안전한 전송으로 옮기고, 반납 전에 지운다.
- 유료 가입·결제, 인증서·키 발급이나 폐기, App Store Connect 제출, 외부 설정 변경은 대표님 승인 뒤에만 한다.

## 2. 도착 직후 점검 (약 30분)
```bash
sw_vers                      # macOS 버전
xcodebuild -version          # Xcode가 설치돼 있으면 버전
df -h ~                      # 디스크 여유(Xcode와 시뮬레이터에 수십 GB 필요)
```
- **Apple의 현재 업로드 요건(최소 Xcode와 iOS SDK 버전)을 App Store Connect 공지에서 확인한다.** 이 값은 이 문서에 적지 않았다(미확인). 기기의 macOS가 그 Xcode를 못 돌리면 macOS 업그레이드가 필요하고, 이는 조카 기기 전체에 영향을 주므로 대표님과 조카의 동의가 필요하다. 동의가 없으면 업그레이드하지 않고 Codemagic 같은 빌드 서비스로 전환한다(7절).
- 이 점검에서 막히면(디스크, 버전) 여기서 멈추고 보고한다.

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

## 4. iOS 프로젝트 파일 만들기
저장소의 `ios/`에는 `Runner.xcodeproj`, `Podfile`, `Main.storyboard`가 없다. Flutter의 프로젝트 생성 명령을 iOS만 대상으로 실행하면 빠진 파일만 만들어진다(기존 파일은 덮어쓰지 않는다).
```bash
flutter create --platforms=ios --project-name share_run_challenge --org com.sharerun .
git status                      # 새로 생긴 파일만 보여야 한다. 기존 파일(Info.plist, AppDelegate.swift 등)이 바뀌었으면 git diff로 확인
```
- `Runner.xcodeproj`, `Podfile`, `Main.storyboard`, `Runner-Bridging-Header.h`가 생긴다.
- `Podfile` 첫 줄을 `platform :ios, '15.0'`으로(플러그인 최소가 15.0).
- `permission_handler`: 코드가 쓰는 권한(`Permission.photos`, `notification`, `locationWhenInUse`, `always`, `activityRecognition`)에 맞는 `PERMISSION_*=1`을 `Podfile`의 `post_install`에 넣는다(`permission_handler_apple` README 참고).
- PRODUCT_BUNDLE_IDENTIFIER가 **`com.sharerun.shareRunChallenge`**인지 확인한다.
```bash
cd ios && pod install --repo-update && cd ..
```
`pod install`이 오류를 내면 원문을 기록한다.

## 5. Xcode 설정 (`open ios/Runner.xcworkspace`)
1. Runner 타깃, Signing & Capabilities: Team은 **우리 Apple Developer 팀**(조카 아님). Bundle Identifier 확인.
2. Capabilities 추가: HealthKit, Push Notifications, Sign in with Apple, Background Modes(Location updates, Uses Bluetooth LE accessories, Background fetch, Remote notifications). 오디오 안내가 화면 꺼짐에서도 나와야 하면 Audio도(확인 후).
3. `Runner.entitlements`에 `com.apple.developer.applesignin`, `aps-environment`가 들어갔는지 확인(HealthKit은 이미 있음).
4. 다음 파일이 Runner 타깃에 포함됐는지 확인: `BleHeartRatePlugin.swift`, `WatchBridgePlugin.swift`(`AppDelegate.swift`가 쓴다).
5. `GoogleService-Info.plist`를 `ios/Runner`에 넣고 타깃에 포함한다. `Info.plist`에 `GIDClientID`와 `REVERSED_CLIENT_ID` URL 스킴을 추가한다(구글 로그인). 네이버 로그인 항목은 플러그인 README대로 추가한다.
6. 지도 키 제한 확인(콘솔), 지도가 나오는지 시뮬레이터에서 확인.
7. 워치 타깃은 1차에서 만들지 않는다. 넣을 때는 `watchos_app/README-XCODE-SETUP.md`.

## 6. 실행 순서와 일정
| 시점 | 할 일 | 끝났다는 기준 |
|---|---|---|
| D0 (11/12) | 2절 점검, 3절 환경, 4절 프로젝트 생성, `pod install` | `flutter doctor`에서 iOS 오류 없음, `pod install` 성공 |
| D1 오전 | 시뮬레이터 실행: `flutter run -d "iPhone" --dart-define-from-file=.env.release` | 앱이 뜬다. 첫 오류는 원문 기록 |
| D1 오후 | 서명 설정, 실기기 실행(개발자 모드 켠 iPhone): `flutter run --release -d <기기ID> --dart-define-from-file=.env.release` | 로그인 화면 표시 |
| D2 | 배포용 빌드: `flutter build ipa --release --dart-define-from-file=.env.release` (또는 Xcode Product > Archive). 대표님 승인 뒤 **TestFlight 업로드**(Transporter 앱 또는 Xcode Organizer) | App Store Connect에 빌드가 "처리 중"으로 뜸 |
| D3~D6 | 빌드·업로드 오류 수정, 권한 문구 11개 언어, `PrivacyInfo.xcprivacy`, 실기기 검증(위치 백그라운드, HealthKit, 블루투스, 푸시, 애플 로그인) | 항목별 체크, 수정은 작은 커밋으로 |
| D6 오후 | 최종 빌드 업로드, 인수인계서 작성 | 아래 8절 완료 |
| D7 | 정리와 반납 | 8절 체크리스트 모두 완료 |

업로드가 막히는 흔한 지점은 서명·프로비저닝, 누락된 아이콘/권한 문구, 수출 규정 질문, 개인정보 매니페스트다. 모두 오류 문구를 그대로 기록한다.

## 7. 반납 후 업데이트하는 방법 (Mac 없이)
- 1순위: Codemagic 같은 빌드 서비스(Flutter 지원). App Store Connect API 키를 서비스 비밀로 넣으면 서명과 업로드를 자동으로 한다. 요금제는 가입·결제라 대표님 승인 필요.
- 2순위: GitHub Actions macOS 러너(저장소가 private이면 사용 시간이 과금될 수 있음, 미확인) + 같은 API 키.
- 3순위: 필요할 때마다 클라우드 Mac(MacinCloud 등) 대여.
- 어느 쪽이든 인증서와 프로비저닝 프로파일을 대표님이 보관해야 하므로, 이번 대여 중 만든 배포 인증서(.p12)는 **암호와 함께 안전한 곳(비밀번호 관리자)에 백업한 뒤** Mac에서 지운다.

## 8. 반납 전 정리 체크리스트
- [ ] 우리 작업물 저장소에 푸시했는지 확인(비밀 파일 제외)
- [ ] Xcode > Settings > Accounts에서 **우리 Apple ID 제거**
- [ ] 키체인에서 우리 인증서·개인 키 삭제(백업 후)
- [ ] App Store Connect API 키(.p8): Mac에서 삭제. Apple 쪽 폐기는 대표님이 결정
- [ ] `.env.release`, `GoogleService-Info.plist`, 다운로드한 프로파일 삭제
- [ ] `~/dev`(Flutter, 저장소), Xcode DerivedData, 시뮬레이터 데이터, Pods 캐시 삭제
- [ ] 브라우저, GitHub, Firebase, Google 로그인 모두 로그아웃, 저장된 암호 삭제, Git 자격 증명 삭제
- [ ] 우리가 만든 macOS 사용자 계정 삭제(조카 동의 하에), 조카 계정과 자료는 손대지 않았는지 확인
- [ ] 인수인계서: 한 일, 실패한 일과 오류 원문, 남은 일, 다음 빌드 방법(7절)
