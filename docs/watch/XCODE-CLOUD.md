# Apple Watch — Xcode Cloud 준비 (10/30)

이 문서는 SRC-7 6번 절 "Apple Watch 빌드·시뮬레이터 체크리스트"를 Xcode Cloud로 돌리기 위해 리눅스 박스에서 끝낼 수 있는 일(ci_scripts, 이 문서)과, 맥·Apple 계정이 있어야만 되는 일을 나눈 것이다. 코드는 바꾸지 않았다.

## 0. 가장 먼저 봐야 할 사실

이 저장소에는 **`ios/Runner.xcodeproj`, `ios/Runner.xcworkspace`, `ios/Podfile`이 없다.** `git ls-files ios`로 확인했다. `.metadata`의 `migration.platforms`에도 `root`와 `android`만 있고 `ios`가 없다. `watchos_app/README-XCODE-SETUP.md`는 "Xcode에서 `ios/Runner.xcworkspace` 열기"로 시작하지만, 그 파일이 지금 저장소에 없으므로 맥에서 먼저 만들어야 한다(아래 1번 참고). Xcode Cloud는 `.xcodeproj`/`.xcworkspace`가 있어야 워크플로를 만들 수 있으므로, 이 파일이 생기기 전에는 Xcode Cloud 쪽 설정 자체를 시작할 수 없다.

또 하나: `ios/Flutter/Generated.xcconfig`와 `ios/Flutter/flutter_export_environment.sh`가 지금 저장소에 커밋돼 있는데, 그 안의 경로가 윈도우 경로다(`C:\flutter\flutter_windows_3.44.3-stable\flutter`, `C:\src`). 이 두 파일은 평소 Flutter가 빌드할 때마다 다시 쓰는 파일이라, 맥에서 `flutter pub get`을 한 번만 돌리면 맥 경로로 다시 써진다. 손으로 고칠 필요는 없다.

## 1. 박스(여기)에서 끝낸 것

- `ios/ci_scripts/ci_post_clone.sh` — Xcode Cloud가 저장소를 clone한 뒤 자동으로 실행하는 훅. 하는 일:
  1. `.metadata`에 적힌 flutter revision(`c9a6c484230f8b5e408ec57be1ef71dee1e77020`, channel stable)으로 Flutter SDK를 받는다. 버전 숫자가 아니라 커밋 해시로 고정해서, "같은 SDK인지" 추측하지 않게 했다.
  2. `flutter precache --ios`, `flutter pub get`을 돌린다.
  3. `ios/Podfile`이 있으면 `pod install`을 돌린다. **지금은 그 파일이 없으므로 이 단계는 메시지만 찍고 넘어간다.** 맥에서 1번(아래)을 끝내고 `ios/Podfile`을 커밋해야 이 단계가 실제로 동작한다.
  - `ci_pre_xcodebuild.sh`, `ci_post_xcodebuild.sh`는 지금 필요한 일이 없어 만들지 않았다.
  - 문법 확인: `bash -n ios/ci_scripts/ci_post_clone.sh` 통과.

- 이 문서.

## 2. 서명 준비 목록 (저장소의 실제 값 기준)

| 항목 | 값 | 근거 / 상태 |
| --- | --- | --- |
| Runner Bundle ID | `com.sharerun.shareRunChallenge` | `lib/firebase_options.dart`의 `iosBundleId`, 워치 Info.plist의 `WKCompanionAppBundleIdentifier` |
| Watch App Bundle ID | `com.sharerun.shareRunChallenge.watchkitapp` | `watchos_app/README-XCODE-SETUP.md`에 적힌 계획값. **아직 어떤 `.xcodeproj`에도 실제로 들어가 있지 않다** — 1번 작업에서 타깃을 만들 때 이 값을 넣어야 한다. |
| App Group | 없음 | 코드에서 App Group 사용 흔적을 찾지 못했다(`group.` 패턴 검색 0건). 워치↔폰 통신은 `WatchConnectivity`(`WCSession`)만 쓰고, 공유 컨테이너를 쓰지 않는다. 지금 체크리스트에 App Group capability 추가는 필요 없다. |
| Runner capability | HealthKit, Background Modes(Location updates / Background fetch / Background processing / Uses Bluetooth LE accessories) | `ios/Runner/Runner.entitlements`에 HealthKit 이미 있음. `ios/Runner/Info.plist`의 `UIBackgroundModes` = `location, bluetooth-central, fetch, processing`. 각 모드의 Xcode Background Modes 체크박스 표현은 Apple의 표준 매핑을 따른 것이다. |
| Watch App capability | HealthKit, Background Modes(Workout Processing / Location updates) | `ios/ShareRunWatch Watch App/ShareRunWatch.entitlements`에 HealthKit 있음(`com.apple.developer.healthkit.access`는 빈 배열, 타입 제한 없음). `Info.plist`의 `UIBackgroundModes` = `workout-processing, location`. |
| Push Notifications | 필요 없음 | `pubspec.yaml`에 `firebase_messaging`이 있지만, `ios/Runner/AppDelegate.swift`에 APNs 등록 코드가 없고 push entitlement도 없다. iOS에서 아직 안 쓴다. |
| Sign in with Apple | 이번 작업과 무관 | `docs/watch-garmin-apple-review.md` 5번에 이미 "버튼이 화면에 연결 안 됨"으로 적혀 있다. 워치 빌드 서명에는 영향 없다. |
| 인증서 / 프로비저닝 | **확인 필요** | 두 Bundle ID 각각 App Store 배포용 프로비저닝이 있어야 한다. Xcode Cloud가 서명 인증서를 자동으로 만들어 관리하는지, 수동 프로파일을 올려야 하는지는 이 환경에 Xcode가 없어 지금 화면으로 확인하지 못했다. 맥에서 1번을 끝낸 뒤 Xcode의 서명 설정 화면에서 직접 보고 정할 것. |

## 3. 맥 / Apple 계정이 꼭 필요한 순서

번호는 순서다. 메뉴 이름이 아니라 "할 일"과 "확인 기준"으로 적었다. 확실하지 않은 조작은 **확인 필요**로 남겼다.

1. **iOS 플랫폼 파일 생성.** 맥에서 저장소를 받아 Flutter iOS 플랫폼 파일(`ios/Runner.xcodeproj`, `ios/Runner.xcworkspace`, `ios/Podfile`)을 만든다. 실행 전에 `ios/Runner/Info.plist`, `ios/Runner/Runner.entitlements`, `ios/ShareRunWatch Watch App/` 전체를 따로 복사해 둘 것 — Flutter 생성 도구가 기존 커스텀 Info.plist/entitlements를 기본값으로 되돌려 쓸 수 있다고 알려져 있다. 확인 기준: `ios/Runner.xcworkspace`가 생기고, 복사해 둔 파일과 새로 생긴 파일을 diff해서 커스텀 키(NSHealthShareUsageDescription 등)가 사라지지 않았는지 맞춰 넣는다.
2. **watchOS 타깃 연결.** `watchos_app/README-XCODE-SETUP.md`대로 `ShareRunWatch Watch App` 타깃을 `ios/Runner.xcworkspace`에 붙이고, 기존 Swift 파일 6개와 Info.plist·entitlements를 그 타깃에 연결한다. 확인 기준: 로컬에서 워치 시뮬레이터 스킴이 한 번 빌드된다.
3. **App ID 등록.** Apple Developer 계정에 Runner(`com.sharerun.shareRunChallenge`)와 Watch App(`com.sharerun.shareRunChallenge.watchkitapp`) 두 App ID를 만들고, 둘 다 HealthKit capability를 켠다. 확인 기준: 포털에 두 App ID가 보이고 HealthKit이 켜져 있다.
4. **서명 방식 확정.** 두 타깃의 서명(자동 관리 또는 수동 프로파일)을 정한다. 위 표의 "인증서/프로비저닝" 확인 필요 항목을 이 단계에서 직접 보고 채운다. 확인 기준: 로컬 실기기 또는 시뮬레이터 빌드가 서명 오류 없이 끝난다.
5. **커밋.** 1~4번에서 생기거나 바뀐 파일(`ios/Runner.xcodeproj`, `ios/Runner.xcworkspace`, `ios/Podfile`, 새 타깃 설정)을 커밋한다. 이 작업 박스는 push 권한이 없어 대표 쪽에서 직접 올려야 한다. 확인 기준: 원격 브랜치에 그 파일들이 보인다.
6. **Xcode Cloud 워크플로 생성.** App Store Connect에서 이 저장소를 Xcode Cloud 소스로 연결하고, `ios/Runner.xcworkspace`의 watchOS 테스트 스킴(`WatchFlushGateTests`가 들어있는 스킴)을 시뮬레이터 대상 "빌드 + 테스트"로 돌리는 워크플로를 하나 만든다. 확인 기준: 워크플로 실행 로그에 `ci_post_clone.sh`가 돌아간 기록이 보이고, `pub get`과 `pod install` 단계가 성공으로 끝난다(2번 단계에서 `ios/Podfile`이 생긴 뒤에만 `pod install`이 실제로 실행된다).
7. **환경변수 등록.** `JENA_BASE_URL`, `FIREBASE_API_KEY` 두 값을 워크플로의 환경변수로 등록한다(`FIREBASE_API_KEY`는 비밀로 표시). 이 값들이 Info.plist의 `$(JENA_BASE_URL)` / `$(FIREBASE_API_KEY)` 치환에 그대로 쓰이는지, 아니면 `ci_post_clone.sh`에서 `.xcconfig` 파일로 한 번 더 써줘야 하는지는 **확인 필요** — 이 환경에 Xcode가 없어 실제 빌드 세팅 화면으로 검증하지 못했다. 확인 기준: 빌드 로그에서 Watch App의 Info.plist에 그 두 키가 빈 값으로 들어가지 않았는지 본다.
8. **워크플로 1회 수동 실행.** 빌드 성공과 `WatchFlushGateTests` 통과를 확인한다. 확인 기준: SRC-7 6번 절 체크리스트 1번·10번이 "완료"로 바뀐다.
9. **손으로 확인할 나머지.** 체크리스트 2~9번(페어링, 비행기 모드 뒤 큐, 겹친 flush, 409/429/5xx 처리, 재검증 원장)은 Xcode Cloud 빌드 로그로 보지 못한다. 맥에 연결된 시뮬레이터 또는 실기기에서 직접 돌린다. 각 번호의 확인 기준은 `docs/debate/SRC-7-TOPICS.md` 6번 절 "Apple Watch 빌드·시뮬레이터 체크리스트" 목록에 이미 있다.

## 4. 이번에 하지 않은 것

- lib/ 화면 문구 번역 연결 — PR #351이 맡는다.
- DIA·원화 가격 변경 — 대표 판단 필요 항목으로 그대로 둔다.
- `ios/Runner.xcodeproj` 등 실제 Xcode 프로젝트 파일 생성 — 이 리눅스 박스에 Xcode가 없어 할 수 없다. 위 3절 1번이 맥에서 할 일이다.
