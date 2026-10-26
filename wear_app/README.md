# 쉐어런 워치 전용 앱 (Wear OS) — `wear_app/`

휴대폰 앱(`lib/`, `android/`)과 **따로 빌드**하는 독립 프로젝트입니다. 루트 `analysis_options.yaml`이 이 폴더를 분석에서 빼 두었고, 루트 `flutter test`는 `test/`만 돌기 때문에 휴대폰 앱의 CI와 빌드에는 영향이 없습니다.

공개 저장소이므로 키스토어·서명 비밀번호·토큰은 이 폴더에 넣지 않습니다.

## 지금 들어 있는 것
| 구분 | 내용 | 상태 |
|---|---|---|
| 화면 | ⓪ 연결(6자리 숫자판, 원형 화면용) ① 시작 ② 달리는 중(페이스·심박·거리) ③ 일시정지/재개/종료 ④ 대회 순위 알림 ⑤ 완주 요약과 올리기 대기 수 | 구현, 위젯 테스트 있음 |
| 실제 센서 | `MainActivity.kt`의 `sharerun/watch_sensors` 채널. 심박(`TYPE_HEART_RATE`), 걸음(`TYPE_STEP_COUNTER`), GPS(`LocationManager`), 부분 WakeLock, 포그라운드 서비스(`TrackingService`). 센서가 없거나 권한이 없으면 그 값은 0으로 남고 만들어 내지 않는다 | 구현, 빌드 확인 |
| 러닝 상태 | 시작·일시정지(움직인 시간만 계산)·재개·종료, 비현실적 심박 무시, 일시정지 중 거리·걸음 무시 | 구현, 단위 테스트 있음 |
| 6자리 연결 | 휴대폰 앱이 `POST /actions/watch-pairing/code`로 만든 코드를 워치에서 입력 → `POST /auth/watch-pair` → Firebase 맞춤 토큰 → Firebase REST 로그인. 갱신 토큰만 앱 전용 저장소에 둔다 | 구현, 단위 테스트 있음 |
| 올리기 | 연결된 계정의 ID 토큰으로 `POST /actions/runs/validate`. 성공이거나 서버가 본문을 거부(400·409·413·422)하면 대기열에서 빼고, 네트워크·401·429·5xx는 남겨 다시 올림. 같은 `activity_id`는 서버가 한 번만 인정 | 구현, 단위 테스트 있음 |
| 오프라인 대기열 | 기록마다 한 번 만든 `activity_id`, 최대 50건, 앱 재시작 후 복원(걸음 수 포함) | 구현, 단위 테스트 있음 |

## 아직 없는 것
- **대회 순위 데이터**: ④ 화면은 값을 받아 그릴 뿐, 순위를 워치에서 계산하지 않습니다. 중계 경로가 아직 없습니다.
- **서버 쪽 남은 일**: 워치에는 자이로 점수가 없어 서버 필수 필드를 임시값(`kUnknownGyroScore`)으로 채웁니다. 케이던스 배열은 보내지 않고, 서버가 `device_info.watch_used`와 `total_steps`로 평균 케이던스를 계산합니다.
- **워치 개별 식별**: 워치는 처음 한 번 만든 고유 번호를 코드와 함께 보내고, 서버는 계정당 최대 3대까지만 연결을 허용합니다(같은 번호로 다시 연결하면 자리를 더 쓰지 않음, 가득 차면 409 `too_many_watches`). 휴대폰 화면에서 목록을 보고 한 대씩 해제할 수 있습니다.
- **이미 있는 서버 보호**: 워치 토큰은 기록 올리기·걸음 수 올리기 두 경로에서만 통하고, 올릴 때 `started_at`·`ended_at`이 꼭 있어야 하며(미래·7일보다 오래됨·앞뒤가 뒤집힘·달린 시간이 구간보다 김 → 400), 휴대폰에서 "연결된 워치 모두 해제"(또는 그 워치만 "해제")를 누르면 이 워치는 `watch_revoked`(401)를 받고 스스로 연결을 지웁니다.
- 연결 해제는 화면에 없습니다(저장소 삭제 또는 앱 데이터 삭제). 서버 쪽에서 코드가 한 번만 쓰이고 5분 뒤 만료됩니다.
- 앱 아이콘은 휴대폰 앱의 `ic_launcher.png`를 그대로 복사했습니다(적응형 아이콘 없음).
- 실제 시계에서의 정확도(GPS 거리, 심박 권한 동작)는 기기에서 확인하지 못했습니다.

## 매니페스트 요약 (`android/app/src/main/AndroidManifest.xml`)
- `android.hardware.type.watch` (워치 전용 기기)
- `com.google.android.wearable.standalone = true` (휴대폰 없이 동작)
- 권한: `BODY_SENSORS`, `ACTIVITY_RECOGNITION`, `ACCESS_FINE_LOCATION`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_HEALTH`, `FOREGROUND_SERVICE_LOCATION`, `WAKE_LOCK`, `POST_NOTIFICATIONS`, `INTERNET`
- 서비스: `TrackingService` (`health|location` 포그라운드)
- 패키지 이름: 휴대폰 앱과 같은 `com.sharerun.share_run_challenge`, 최소 API 30(Wear OS 3.0)

## 버전 코드 체계
- 휴대폰 앱은 `versionCode 1`부터 올라갑니다. 워치 앱은 **10001부터** 따로 올립니다(`pubspec.yaml`의 `version: 1.0.0+10001`). 휴대폰 앱이 1만 번대에 닿기 전까지 겹치지 않습니다.
- 같은 패키지 이름을 쓰므로 Play Console에서 Wear OS **폼 팩터 트랙**으로 따로 올리는 방식인지 먼저 확인해야 합니다(소유자/Grok 확인 항목).

## 빌드
```
cd wear_app
flutter pub get
flutter analyze
flutter test
flutter build apk --release   --dart-define=JENA_BASE_URL=https://<서버 주소>   --dart-define=FIREBASE_API_KEY=<Firebase 웹 API 키>
```
`JENA_BASE_URL`과 `FIREBASE_API_KEY`가 없는 빌드는 연결 단계에서 "서버 설정이 없는 빌드예요."를 보여 줍니다.

서명: `wear_app/android/key.properties`가 있으면 그 키로, 없으면 휴대폰 앱의 `android/key.properties`(업로드 키)로, 둘 다 없으면 debug 키로 서명합니다. 키 파일은 저장소에 올리지 않습니다.

## 파일 구조
```
lib/main.dart                  앱 시작과 화면 흐름(RunFlow)
lib/core/run_session.dart      러닝 상태·거리·심박·걸음·페이스 계산과 표시 형식
lib/core/sync_queue.dart       오프라인 대기열과 서버 본문 만들기
lib/core/sync_uploader.dart    대기열 저장과 서버에 올리기
lib/core/watch_account.dart    6자리 코드 연결, Firebase 토큰 갱신, 서명된 요청
lib/core/watch_platform.dart   센서·저장소 채널(Kotlin)과 시험용 가짜
lib/screens/watch_screens.dart 연결 + 5개 화면
android/.../WatchTracker.kt    심박·걸음·GPS 수집
android/.../TrackingService.kt 달리는 동안 켜 두는 포그라운드 서비스
test/                          단위·위젯 테스트
```
