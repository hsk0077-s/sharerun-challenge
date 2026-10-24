# 워치 단독 실행 · Garmin · Apple 로그인 점검 (2026-10-24, main c6553c7 기준)

공개 저장소 문서입니다. 키·토큰은 적지 않습니다.

## 1. 지금 코드에 있는 것 / 없는 것
| 항목 | 상태 | 근거 |
|---|---|---|
| 워치 단독 실행 앱(Wear OS) | **없음**. `android/`에 `app` 모듈 하나뿐이고, "워치 전용 앱 (예정) 미리 보기" 화면만 있음 | `android/settings.gradle.kts`, `lib/screens/device_connection_screen.dart:212` |
| 워치 → 서버 동기화 경로 | **없음**. 워치 데이터는 Health Connect를 거쳐 휴대폰 앱이 읽는 것뿐(걸음·심박) | `lib/features/run_tracking/services/health_data_service.dart` |
| Garmin 연동 | **모의 구현**. 실제 Garmin에 로그인하지 않음 | `lib/features/watch_link/services/garmin_cloud_oauth_adapter.dart` |
| Apple 로그인 | 버튼은 있으나 누르면 "준비 중" 안내만 나옴. `AuthService.signInWithApple()`은 만들어져 있으나 화면에서 호출하지 않음 | `lib/screens/login_screen.dart:417`, `lib/data/firebase/auth_service.dart:75` |

## 2. 이번에 찾아 고친 문제 (Garmin)
`external_oauth_webview.dart`(= `GarminAuthScreen`)는 **Garmin 이메일과 비밀번호를 앱 안에서 입력받고**, 부제는 "안전한 OAuth 2.0 공식 로그인 페이지입니다."(`app_strings.dart:136`)라고 말합니다. 하지만 실제로는 네트워크 호출 없이 `garmock_at_…` 가짜 토큰을 만들고 `isGarminConnected = true`로 표시합니다(`src_onboarding_controller.dart:1222`).
- 사용자를 속이는 문구이며, 타 서비스 비밀번호를 앱이 직접 받는 화면이라 Play 심사(기만적 행위, 인증 정보 수집)에 걸릴 수 있습니다.
- 조치: 출시 빌드에서는 Garmin 타일이 Suunto·Coros와 같이 "준비 중" 안내만 띄우고(`AppEnv.garminLinkEnabled`), 어댑터도 출시 빌드에서는 거부합니다. 디버그 빌드의 모의 동작은 개발용으로 유지.
- 실제 연동 때는 이메일·비밀번호 입력 화면을 없애고 Garmin의 공식 OAuth(브라우저 승인) 방식으로 새로 만들어야 합니다.

## 3. 워치 단독 실행(2단계) 설계 시 서버가 이미 막아 주는 것 / 추가할 것
이미 있는 것(근거 포함):
- 달리기 기록은 `activity_id` 문서 하나로 기록되고 같은 id 재전송은 중복 지급 없이 같은 결과를 돌려줌. 다른 사용자의 activity id는 거부(`secured_action_service.py` `_commit_validation_tx`, `userId != uid`).
- 하루 걸음 수는 `POST /actions/daily-steps`(#306)가 날짜 범위(오늘~35일 전), 1~30,000, Health 값과의 차이를 검사하고 지난 날은 줄어들지 않게 저장. 같은 날 폰·워치가 둘 다 올려도 **큰 값 하나**만 남으므로 합산 이중 지급이 없음.
- 달리기 입력 상한과 비현실적 페이스 거부(#290).

워치 단독 앱을 만들 때 추가해야 할 것:
1. **오프라인 기록의 시각 신뢰**: 워치가 오프라인에서 만든 기록의 시작·종료 시각은 기기 시계 값이라 조작될 수 있음. 서버는 "기록 종료 시각이 업로드 시각보다 미래가 아님, 너무 오래되지 않음(예: 7일)" 검사를 추가.
2. **기기 식별**: 워치에서 올린 기록임을 서버가 알 수 있게 `source`/`device` 필드를 두고, 계정당 워치 기기 수 상한을 둠(기존 로그인 기기 목록 기능 재사용 가능).
3. **재연결 시 한꺼번에 업로드**: 하루 여러 기록이 몰려 와도 기존 하루 보상 상한과 `activity_id` 중복 방지로 막히는지 서버 테스트로 고정(지금은 폰 단독 기준 테스트만 있음).
4. **심박**: 원본은 저장하지 않는 현 방침 유지. 워치가 보낸 심박 시계열도 검증 계산 후 폐기.
5. **인증**: 워치는 Firebase 토큰을 직접 들지 말고, 폰이 중계하거나 짧은 수명의 연결 토큰을 사용(토큰 탈취 시 피해 범위 축소).

## 4. Garmin 실연동 준비 체크리스트 (코드 밖 작업은 Grok/소유자)
- Garmin Connect Developer Program 신청·승인(비즈니스 용도 승인 필요), 사용 API 범위(활동·걸음) 결정.
- 콘솔: OAuth 클라이언트 등록, 콜백 URL(웹/앱 링크) 등록 — 비밀값은 서버 환경변수로만 보관(저장소에 넣지 않음).
- 서버: 토큰 교환·갱신은 서버가 수행하고 앱은 토큰을 받지 않음. 활동 수신은 Garmin 푸시/웹훅을 서버가 서명 검증 후 처리.
- 개인정보 처리방침과 Play 데이터 보안 양식에 Garmin 데이터 처리 추가.
- 기존 `WatchType.garmin` 값과 온보딩 `isGarminConnected` 상태는 실연동이 되기 전까지 사용자에게 "연결됨"으로 보이지 않게 유지.

## 5. Apple 로그인 (iOS Phase 2) 체크리스트
- 현재 앱은 Android 1.0만 대상. iOS 빌드를 내려면 Apple Developer 계정, App ID의 Sign in with Apple capability, Firebase 콘솔의 Apple 제공자 설정(서비스 ID, 키 ID, 팀 ID)이 필요(비밀 키는 콘솔에만 등록).
- 코드: `AuthService.signInWithApple()`을 로그인 화면 버튼에 연결하고, 서버의 계정 연결 흐름(`identities`)에 `apple` 제공자를 추가해야 같은 사람 계정 합치기 규칙이 적용됨. 지금 서버는 구글·카카오·네이버만 처리(`identities.py` `PROVIDERS`).
- 심사 규칙: iOS에서 다른 소셜 로그인을 제공하면 Apple 로그인도 함께 제공해야 하고, 계정 삭제 시 Apple 토큰 취소(revoke)도 필요.
- Android에서는 Apple 로그인을 보이지 않거나 "준비 중"으로 유지(현재 상태 그대로 안전).

## 6. 이번 PR에 포함하지 않은 것
- Wear OS 앱 자체와 서버의 시각 검증(위 3-1, 3-2, 3-3)은 설계만 정리했습니다. 구현 지시가 있으면 서버 변경부터 별도 PR로 진행합니다.
