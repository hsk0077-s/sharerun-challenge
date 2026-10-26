# 배포·콘솔 작업 체크리스트 (2026-10-26, main 95de3f2 기준)

공개 저장소 문서입니다. 키·토큰·비밀번호는 적지 않습니다.
"코드는 머지됨"과 "배포됨"은 다릅니다. 아래는 **머지됐지만 배포 여부를 확인해야 하는 것**입니다. 이미 배포했다면 건너뛰세요.

## 1. 배포 순서 원칙
- 추가만 하는 변경: Cloud Run → Firestore 규칙·Hosting → 앱.
- 닫는 변경(규칙으로 쓰기를 막는 등): Cloud Run → 앱 배포와 채택 → 규칙은 맨 마지막.
- 살아 있는 Cloud Run에 `--set-env-vars`를 쓰지 않습니다(기존 값이 지워짐). 값 추가는 `--update-env-vars`.

## 2. Cloud Run (`src-jena-ai`, `asia-northeast3`)
머지된 서버 변경. 한 번에 최신 main으로 배포하면 모두 포함됩니다.

| PR | 내용 | 배포 안 하면 |
|---|---|---|
| #302 | 연결 요청 횟수 제한 | 제한 없음(기존 상태) |
| #303 | 탈퇴 후 재가입 보상 중복 방지(rewardTombstones/rewardBlocks) | 재가입 보상 중복 가능 |
| #304 | 신고 관리자 API | 신고 조회 불가 |
| #306 | 하루 걸음 수 서버 저장 `/actions/daily-steps` | **새 앱의 걸음 저장이 실패**. 앱보다 먼저 배포 |
| #310·#314 | 인앱 결제 소비·계정 결합·테스트 구매 차단 | 결제 보강 미적용 |
| #323~#325 | 워치 연결: 워치 토큰 범위, 시각 검증, 기기 3대 제한·해제 | 워치 앱·휴대폰의 워치 목록 화면이 동작하지 않음 |

배포 뒤 확인: `/healthz` 응답, 로그에 시작 오류 없음.

## 3. Firestore 규칙
- #303이 새 컬렉션 2개(`rewardTombstones`, `rewardBlocks`)를 추가했습니다(여는 변경). Cloud Run 뒤에 `firebase deploy --only firestore:rules`.
- `daily_metrics` 클라이언트 쓰기 규칙은 **아직 닫지 않습니다**. 새 앱이 충분히 퍼진 뒤 마지막에 닫습니다.

## 4. Hosting (`site/`)
- #300, #301, #307: `firebase deploy --only hosting:web --project share-run-challenge`.
- 배포 전 `site/privacy.html`, `site/account-deletion.html`의 `[대괄호]` 항목(회사명·대표자·주소·문의 이메일 등)과 노란 초안 상자를 채우고 법무 검토. #307의 "운영자는 …사람이 직접 열람하지 않습니다" 문장이 실제 운영과 맞는지 확인.

## 5. 앱 빌드
### 휴대폰 앱
- 포함: #300, #301, #305, #306, #309, #310~#314(결제·Garmin 숨김), #325(워치 목록 화면).
- `flutter build appbundle --release --dart-define-from-file=.env.release` (자세한 방법은 `docs/play-release.md`). `pubspec.yaml`의 번호(+뒤)를 올린 뒤.
- 서버(2번)가 먼저 배포돼 있어야 합니다.

### 워치 앱 (`wear_app/`)
- 서버 #323~#325가 배포된 **뒤에** 올립니다(워치는 `started_at`·`ended_at`을 보내야 하고, 서버가 없으면 400).
- 빌드는 `wear_app/README.md`의 `--dart-define`(JENA_BASE_URL, FIREBASE_API_KEY) 필요. 버전 번호는 10001부터.
- GitHub Actions "Wear OS build"가 PR마다 분석·테스트·debug 빌드까지 확인합니다(실기기 동작은 별개).
- Play Console에서 Wear OS를 같은 패키지로 폼 팩터 트랙에 올리는 방식인지 먼저 확인.

## 6. 콘솔·계정 작업 (소유자만 가능)
- 카카오 개발자 콘솔: 동의항목에서 이메일 켜기(#301).
- Firebase/Kakao에 Play 앱 서명 SHA-1(업로드 키 + Play 서명 키) 등록, `google-services.json` 다시 받기.
- Google Maps API 키: Android 앱 제한(패키지 + SHA-1).
- 네이버 client secret 재발급(예전에 저장소에 올라간 값), 로컬에만 보관.
- Play Console: 개인정보처리방침 URL, 계정 삭제 URL, 데이터 보안 양식(위치·Health Connect·신체 활동·마이크·카메라, 워치 사용 시 워치 데이터), 콘텐츠 등급, 스토어 설명·스크린샷.
- Firebase App Check 적용 여부 결정(`docs/release-checklist.md`).

## 7. 실기기에서 눈으로 확인할 것
- 카카오 로그인 이메일 동의 창.
- Health Connect 권한 창이 걸음·심박 두 가지만 요청하는지.
- 재부팅 뒤 만보기가 저절로 시작되지 않는지.
- 설정·상점·마이 화면에 Coach+ 결제 항목이 없는지(`IN_APP_PURCHASES_ENABLED=false`).
- 워치: 6자리 코드 연결 → 달리기 → 올리기, 센서 권한 거부 시 앱이 죽지 않는지, 휴대폰에서 해제하면 워치가 연결을 지우는지, 4번째 워치 연결 시 안내.
- 워치 심박이 실제로 들어오는지(Wear OS 4 이상, 갤럭시 워치는 막힌 모델이 있을 수 있음).

## 8. 알려진 남은 일 (코드)
- (완료) 워치 갱신 토큰은 Android Keystore 키로 암호화해 저장(예전 평문 값은 읽을 때 자동 변환).
- 연결 요청 횟수 제한(#302)은 인스턴스 메모리 기준이라 재시작하면 초기화.
- `daily_metrics` 클라이언트 쓰기 닫기(앱 채택 후).
- (확인함) 걷기 보상 적립량 더하기 경로(`solo_pedometer_screen.dart`)는 출시 빌드에서 서버 잔액이 없으면 기기에서 더하지 않음(디버그 빌드에서만 로컬 적립). 걸음 수 저장도 앱은 서버 API만 사용 — 남은 것은 앱 채택 뒤 규칙 닫기뿐.
- Garmin 실연동, Apple 로그인(iOS)은 1.0 범위 밖(`docs/watch-garmin-apple-review.md`).
