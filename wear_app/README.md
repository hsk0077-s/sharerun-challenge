# 쉐어런 워치 전용 앱 (Wear OS) — `wear_app/`

휴대폰 앱(`lib/`, `android/`)과 **따로 빌드**하는 독립 프로젝트입니다. 루트 `analysis_options.yaml`이 이 폴더를 분석에서 빼 두었고, 루트 `flutter test`는 `test/`만 돌기 때문에 휴대폰 앱의 CI와 빌드에는 영향이 없습니다.

공개 저장소이므로 키스토어·서명 비밀번호·토큰은 이 폴더에 넣지 않습니다.

## 지금 들어 있는 것
| 구분 | 내용 | 상태 |
|---|---|---|
| 5개 화면 | ① 시작(`3km`, 탭해서 시작) ② 달리는 중(페이스 `5:42`, 심박 `♥ 148`, 거리 `1.8km`) ③ 일시정지/재개/종료 ④ 대회 순위 알림(`1위!`, `대회 2명 앞서요`) ⑤ 완주 요약(`3.00km · 5:38/km · 17분`)과 동기화 대기 수 | 화면·흐름 구현, 위젯 테스트 있음 |
| 러닝 상태 | 시작·일시정지(움직인 시간만 계산)·재개·종료, 비현실적 심박(30 미만, 230 초과) 무시, 달리는 중에만 거리·심박 기록 | 구현, 단위 테스트 있음 |
| 오프라인 대기열 | 기록마다 한 번 만든 `activity_id`로 중복 방지, 최대 50건, 앱 재시작 후 복원, 서버가 확정한 기록만 제거 | 구현, 단위 테스트 있음 |
| 서버 본문 | `POST /actions/validate-run`, `POST /actions/daily-steps` 필드 이름과 같은 본문 만들기 | 구현, 테스트 있음 |

## 아직 없는 것 (다음 단계)
- **센서 연결**: 실제 심박·걸음·위치 읽기와 러닝 중 포그라운드 서비스. 지금 화면은 값을 외부에서 받아 그리기만 합니다.
- **휴대폰으로 보내기**: 워치는 Firebase 토큰을 들고 있지 않습니다. 대기열은 Wear OS Data Layer 같은 방법으로 휴대폰 앱에 넘기고, **휴대폰 앱이 로그인된 계정으로** 서버에 올리는 구조가 안전합니다(토큰 탈취 시 피해 범위 축소). 아직 구현하지 않았습니다.
- **대회 순위 데이터**: ④ 화면은 휴대폰이 중계한 값을 그릴 뿐, 순위를 워치에서 계산하지 않습니다.
- **서버 쪽 남은 일** (`docs/watch-garmin-apple-review.md` 3절): 오프라인 기록의 시작·종료 시각 검증(미래/너무 오래된 값 거부), 워치 기기 식별과 계정당 개수 상한, 재연결 일괄 업로드의 하루 상한 테스트. 워치에는 자이로 점수가 없어 서버 필수 필드를 임시값(`kUnknownGyroScore`)으로 채우고 있으므로, 서버가 워치 단독 기록을 따로 다루게 되면 없앱니다.
- 앱 아이콘은 Flutter 기본 아이콘 자리표시자입니다(새 하트 로고 적용은 별도 결정).
- 이 환경에는 Android SDK가 없어 **빌드는 확인하지 못했습니다.** 분석(`flutter analyze`)과 테스트(11개)만 통과했습니다. 첫 빌드는 Android SDK가 있는 PC에서 해 주세요.

## 매니페스트 요약 (`android/app/src/main/AndroidManifest.xml`)
- `android.hardware.type.watch` (워치 전용 기기)
- `com.google.android.wearable.standalone = true` (휴대폰 없이 동작)
- 권한: `BODY_SENSORS`, `ACTIVITY_RECOGNITION`, `ACCESS_FINE_LOCATION`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_HEALTH`, `FOREGROUND_SERVICE_LOCATION`, `WAKE_LOCK`
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
flutter build apk --release   # Android SDK가 있는 PC에서
```
서명은 로컬에서 `android/key.properties`(저장소에 올리지 않음)로 설정하고, 휴대폰 앱과 같은 업로드 키를 쓸지는 소유자가 정합니다. 지금 `build.gradle.kts`는 debug 서명입니다.

## 파일 구조
```
lib/main.dart                  앱 시작과 화면 흐름(RunFlow)
lib/core/run_session.dart      러닝 상태·거리·심박·페이스 계산과 표시 형식
lib/core/sync_queue.dart       오프라인 대기열과 서버 본문 만들기
lib/screens/watch_screens.dart 5개 화면
test/                          단위·위젯 테스트
```
