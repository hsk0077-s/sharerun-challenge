# iOS TestFlight 빌드 준비 (Mac 없이)

GitHub의 Mac 컴퓨터(Actions)가 쉐어런 iOS 앱을 만들어 TestFlight에 올립니다.
대표님은 **웹 브라우저만** 있으면 됩니다. 아래 순서대로 한 번만 준비하면, 그다음부터는 버튼 한 번으로 올라갑니다.

- 워크플로 파일: `.github/workflows/ios-testflight.yml`
- 앱 번들 ID: `com.sharerun.shareRunChallenge`, 워치 앱: `com.sharerun.shareRunChallenge.watchkitapp`
- Apple 팀 ID: `7C429Q46CL` (개인 계정 SANGKI HA)
- 결제 스위치(`IN_APP_PURCHASES_ENABLED`, `DIA_PACKS_ENABLED`, `SPONSORSHIP_ENABLED`)는 워크플로가 **항상 끈 채로** 빌드합니다. iOS는 이전 전까지 무료 앱입니다.

## 비용 한눈에

| 단계 | 비용 |
|---|---|
| Apple Developer Program 가입 | 연 99달러. 팀 ID가 있으니 이미 가입된 상태라면 **추가 비용 없음** |
| App Store Connect 앱 만들기, API 키 발급 | 무료 |
| GitHub Secrets 등록 | 무료 |
| GitHub Actions(Mac)로 빌드 | 이 저장소는 **공개(public)** 라서 무료. 저장소를 비공개로 바꾸면 Mac 사용 시간이 무료 한도에서 10배로 빠르게 차감되고, 넘으면 유료 |
| TestFlight 배포·테스터 초대 | 무료 |

---

## 1단계. App Store Connect에 앱 만들기 (무료)

이미 만들었다면 건너뜁니다.

1. https://appstoreconnect.apple.com 에 로그인합니다.
2. **앱** → 왼쪽 위 **+** → **신규 앱**.
3. 플랫폼 **iOS**, 이름 **쉐어런**, 기본 언어 **한국어**, 번들 ID는 목록에서 `com.sharerun.shareRunChallenge` 를 고릅니다.
   - 목록에 없으면 https://developer.apple.com/account/resources/identifiers 에서 **+** 로 같은 ID를 먼저 등록합니다. 이때 **HealthKit**, **Sign in with Apple**(쓸 경우)를 켭니다.
4. SKU는 아무 영문(예: `sharerun-ios`)이나 넣고 **생성**합니다.

## 2단계. App Store Connect API 키 발급 (무료)

이 키 하나로 빌드 서명과 업로드를 모두 합니다.

1. App Store Connect → **사용자 및 액세스** → **통합** 탭 → **App Store Connect API** → **팀 키**.
2. **+** (키 생성) → 이름 `GitHub Actions`, 액세스 **관리자(Admin)**.
   - 관리자 권한이어야 Mac 없이도 Apple이 배포 인증서와 프로파일을 자동으로 만들어 줍니다.
3. 만든 뒤 화면에서 세 가지를 적어 둡니다.
   - **Issuer ID** (표 위쪽, 긴 영문·숫자) → `APP_STORE_CONNECT_ISSUER_ID`
   - **키 ID** (10자리) → `APP_STORE_CONNECT_KEY_ID`
   - **API 키 다운로드** → `AuthKey_XXXXXXXXXX.p8` 파일. **딱 한 번만** 받을 수 있으니 안전한 곳에 보관합니다. → `APP_STORE_CONNECT_KEY_P8`
4. 이 파일은 저장소나 메신저에 올리지 않습니다.

## 3단계. 인증서·프로파일 (Mac 없이는 보통 필요 없음, 무료)

2단계에서 키를 **관리자**로 만들었다면 이 단계는 **건너뜁니다.** 빌드 때 Apple이 관리하는 배포 인증서와, 앱·워치 앱용 프로파일을 자동으로 만듭니다.

직접 만든 인증서를 꼭 쓰고 싶을 때만 아래 선택 Secrets를 넣습니다(만들려면 보통 Mac이 필요합니다).

- `IOS_DIST_CERT_P12`: Apple Distribution 인증서 `.p12` 파일을 base64로 바꾼 글자
- `IOS_DIST_CERT_PASSWORD`: 그 `.p12` 비밀번호
- `IOS_PROVISIONING_PROFILE`: App Store용 프로파일 `.mobileprovision` 을 base64로 바꾼 글자. 워치 앱 프로파일은 자동 서명이 만듭니다.

## 4단계. Firebase 설정 파일 받기 (무료)

1. https://console.firebase.google.com → 프로젝트 **share-run-challenge** → 톱니바퀴 **프로젝트 설정**.
2. **내 앱**에서 iOS 앱(`com.sharerun.shareRunChallenge`)을 고릅니다. 없으면 **앱 추가 → iOS** 로 같은 번들 ID를 등록합니다.
3. **GoogleService-Info.plist** 를 내려받습니다. → `GOOGLE_SERVICE_INFO_PLIST`

## 5단계. dart-define 값 준비 (무료)

Android 출시에 쓰는 `.env.release` 와 같은 이름을 JSON 한 덩어리로 만듭니다. 이름과 뜻은 `.env.release.example` 에 있습니다.

```json
{
  "JENA_BASE_URL": "https://…",
  "GOOGLE_WEB_CLIENT_ID": "…apps.googleusercontent.com"
}
```

- 결제 스위치 3개와 `LOCAL_DEV_MODE`, `USE_FIREBASE_EMULATOR` 는 넣지 않아도 됩니다. 넣어도 워크플로가 `false` 로 덮어씁니다.
- 네이버 값은 Android 전용이라 iOS에는 필요 없습니다.
- → `DART_DEFINES_JSON`

## 6단계. GitHub Secrets 등록 (무료)

1. https://github.com/hsk0077-s/sharerun-challenge → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**.
2. 아래 이름 그대로 하나씩 만듭니다. 값은 메모장에서 복사해 붙여 넣습니다.

| 이름 | 넣을 값 | 필수 |
|---|---|---|
| `APP_STORE_CONNECT_KEY_ID` | 2단계 키 ID | 필수 |
| `APP_STORE_CONNECT_ISSUER_ID` | 2단계 Issuer ID | 필수 |
| `APP_STORE_CONNECT_KEY_P8` | `.p8` 파일을 메모장으로 열어 `-----BEGIN PRIVATE KEY-----` 부터 끝까지 전부 | 필수 |
| `GOOGLE_SERVICE_INFO_PLIST` | `GoogleService-Info.plist` 를 메모장으로 열어 전체 내용 | 필수 |
| `DART_DEFINES_JSON` | 5단계 JSON 전체 | 필수 |
| `IOS_DIST_CERT_P12` | 3단계 참고 | 선택 |
| `IOS_DIST_CERT_PASSWORD` | 3단계 참고 | 선택 |
| `IOS_PROVISIONING_PROFILE` | 3단계 참고 | 선택 |

- `.p8` 과 `.plist` 는 내용을 그대로 붙여도 되고 base64로 바꿔 넣어도 됩니다(둘 다 받습니다).
- 이 저장소는 **공개**입니다. Secrets 값은 로그에 `***` 로 가려지지만, 값을 이슈·PR·커밋에 적으면 누구나 볼 수 있으니 절대 적지 않습니다.

## 7단계. Actions 탭에서 실행 (무료)

1. 저장소 → **Actions** → 왼쪽 **iOS TestFlight** → 오른쪽 **Run workflow**.
2. 브랜치 `main`, **TestFlight에 올린다** 체크 그대로 → **Run workflow**.
   - 처음에는 체크를 끄고 돌려 서명까지만 되는지 먼저 확인해도 됩니다.
3. 30~50분쯤 걸립니다. 초록 체크가 뜨면 끝입니다. 빨간 X면 실패한 단계를 눌러 마지막 줄을 보고 참모에게 알려 주세요.
4. 빌드 번호는 실행할 때마다 1씩 자동으로 올라갑니다(`github.run_number`). 버전 이름(예: 1.0.0)은 `pubspec.yaml` 을 따릅니다.

## 8단계. TestFlight에서 확인 (무료)

1. 업로드 후 10~30분 지나면 App Store Connect → 앱 → **TestFlight** 탭에 빌드가 보입니다.
2. 처음 한 번 **수출 규정 관련 문서(암호화)** 질문이 나옵니다. 쉐어런은 표준 HTTPS만 쓰므로 보통 "표준 암호화만 사용"을 고릅니다. 매번 묻지 않게 하려면 다음 PR에서 `Info.plist` 에 `ITSAppUsesNonExemptEncryption = false` 를 넣을 수 있습니다.
3. **내부 테스트** 그룹에 대표님 Apple ID를 넣으면 iPhone의 TestFlight 앱에서 바로 설치할 수 있습니다.

---

## 자주 막히는 곳

- **"No profiles for 'com.sharerun.shareRunChallenge.watchkitapp'"** — API 키가 관리자 권한이 아니거나, 번들 ID 등록이 안 된 경우입니다. 2단계 권한을 확인합니다.
- **"GoogleService-Info.plist 의 BUNDLE_ID가 앱과 다릅니다"** — 4단계에서 다른 앱의 파일을 받았습니다.
- **"DART_DEFINES_JSON 은 … JSON이어야 합니다"** — 쉼표·따옴표가 빠졌습니다. 값이 밖에 남지 않도록 온라인 검사 사이트에는 붙이지 말고, VS Code에서 `.json` 파일로 열어 빨간 줄이 없는지 확인합니다.
- **업로드에서 "bundle version must be higher"** — 같은 버전에 이미 더 큰 빌드 번호가 있습니다. `pubspec.yaml` 버전 이름을 올리거나 워크플로를 한 번 더 실행합니다.
