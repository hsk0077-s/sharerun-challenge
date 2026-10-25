# 쉐어런 Apple Watch (`watchOS`) 단독·연동 앱 — 3분 Xcode 타깃 설정 가이드

갤럭시 워치 단독 앱(`wear_app/`)과 100% 동일한 5+1 화면 흐름 및 서버 API 규격(`/auth/watch-pair`, `/actions/runs/validate`, `/actions/daily-steps`)을 갖춘 **Apple Watch (`watchOS 9.0+` SwiftUI + HealthKit + WatchConnectivity)** 코드 패키지입니다.

---

## 1. 포함된 파일 구성 (`watchos_app/ShareRunWatch/` & `ios/ShareRunWatch Watch App/`)

| 파일 | 역할 | Wear OS (`wear_app/`) 대응 |
|---|---|---|
| `ShareRunWatchApp.swift` | `@main` 진입점, 앱 시작 시 `WatchConnectivity` 바인딩 및 오프라인 큐 자동 플러시 | `wear_app/lib/main.dart` |
| `WatchScreens.swift` | ⓪ 6자리 연결 숫자판(`WatchPairingView`) · ① 시작(`WatchStartView`) · ② 달리는 중 HUD(`WatchRunningView`) · ③ 일시정지/재개/종료(`WatchPausedView`) · ④ 실시간 대회 순위 알림(`WatchRankAlertView`) · ⑤ 완주 요약 및 대기열(`WatchSummaryView`) | `wear_app/lib/screens/watch_screens.dart` |
| `WorkoutManager.swift` | `HKWorkoutSession` + `HKLiveWorkoutBuilder`(실시간 심박 30~230 BPM 필터링, 걸음 수, 케이던스, 칼로리) + `CLLocationManager`(야외 GPS 거리 누적) | `wear_app/android/.../WatchTracker.kt` & `run_session.dart` |
| `WatchAccountManager.swift` | 휴대폰 6자리 페어링 코드(`POST /auth/watch-pair`) → Firebase Custom Token → `signInWithCustomToken` → ID/Refresh 토큰 관리 및 서명 요청 | `wear_app/lib/core/watch_account.dart` |
| `WatchSyncQueue.swift` | 오프라인 완주 기록 최대 50건(`POST /actions/runs/validate`, `source: "watch"`) + 일일 걸음 수(`POST /actions/daily-steps`, KST 날짜 키) 영구 대기열 | `wear_app/lib/core/sync_queue.dart` & `sync_uploader.dart` |
| `WatchConnectivityReceiver.swift` & `ios/Runner/WatchBridgePlugin.swift` | iPhone ↔ Apple Watch 실시간 토큰 전달(`companion_auth`), 대회 순위 알림(`rank_alert`), 오프라인 완주 백업 전송 | WatchConnectivity 전용 브리지 |
| `Info.plist` & `ShareRunWatch.entitlements` | `WKRunsIndependentlyOfCompanionApp = true`, `workout-processing` 백그라운드 모드, HealthKit 권한 선언 | `wear_app/android/app/src/main/AndroidManifest.xml` |

---

## 2. macOS / Codemagic에서 3분 만에 Xcode Target 연결하는 방법

1. **Xcode에서 `ios/Runner.xcworkspace` 열기**
2. **Watch App 타깃 추가 (최초 1회):**
   - 상단 메뉴 `File` → `New` → `Target...` → `watchOS` 탭 → **App** 선택.
   - **Product Name:** `ShareRunWatch`
   - **Bundle Identifier:** `com.sharerun.shareRunChallenge.watchkitapp`
   - **Watch App Launch Scene:** `Watch App for Existing iOS App` (`Runner`) 선택.
3. **소스 파일 연결:**
   - 생성된 기본 템플릿 파일 대신 `ios/ShareRunWatch Watch App/` (또는 `watchos_app/ShareRunWatch/`) 안의 Swift 파일 6개와 `Info.plist`, `ShareRunWatch.entitlements`를 `ShareRunWatch Watch App` 타깃에 포함시킵니다.
   - `Runner` 타깃에는 `ios/Runner/BleHeartRatePlugin.swift`와 `ios/Runner/WatchBridgePlugin.swift`를 포함시킵니다 (`AppDelegate.swift`에 이미 등록 완료).
4. **Signing & Capabilities 체크:**
   - `ShareRunWatch Watch App` 타깃 → `Signing & Capabilities`:
     - **HealthKit** 추가
     - **Background Modes** 추가 → `Workout processing`, `Location updates` 체크
5. **빌드 변수 주입 (`Build Settings` → `User-Defined` 또는 `.xcconfig`):**
   - `JENA_BASE_URL = https://src-jena-ai-518367733322.asia-northeast3.run.app`
   - `FIREBASE_API_KEY = <Firebase Web API Key>`
