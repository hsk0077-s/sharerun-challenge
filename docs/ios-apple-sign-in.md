# iPhone "Apple로 로그인" 설정 (대표님이 할 일)

App Store 심사 지침 4.8: 구글·카카오·네이버 같은 소셜 로그인을 주는 앱은 **Apple로 로그인**도 함께 줘야 합니다.
앱 코드는 준비됐습니다. iPhone에서는 Apple 로그인 버튼이 항상 켜집니다. 아래 콘솔 작업만 남았습니다.

## 어떻게 동작하나요 (한 번만 읽기)

1. iPhone에서 **Apple로 계속하기**를 누르면 Apple 창이 뜹니다(Face ID 등).
2. 앱은 Apple이 준 **신원 토큰**과 그때 만든 **일회용 번호(nonce)**를 쉐어런 서버(`/auth/apple/login`)로 보냅니다.
3. 서버가 Apple 공개키로 토큰을 확인하고, 다른 로그인과 같은 방식으로 쉐어런 계정을 찾거나 만듭니다. 그다음 Firebase 로그인용 토큰을 돌려줍니다.
4. 이름과 이메일은 **처음 로그인할 때만** Apple이 줍니다.
   - 이름은 닉네임 입력 칸에 **추천으로만** 채워 둡니다. 이용자가 바꿀 수 있고, 따로 저장하지 않습니다.
   - "나의 이메일 가리기"를 고르면 `…@privaterelay.appleid.com` 주소가 오고, 서버는 보통 이메일처럼 다룹니다.

그래서 **iPhone 로그인만이라면 Firebase의 Apple 로그인 설정은 꼭 필요하지 않습니다.** 서버가 Apple 토큰을 직접 확인하기 때문입니다. 안드로이드에서도 Apple 로그인을 열 때는 Firebase 설정이 필요합니다(아래 3단계).

---

## 1단계. Apple Developer에서 기능 켜기 (필수, 무료)

1. https://developer.apple.com/account/resources/identifiers 에 로그인합니다.
2. 목록에서 **com.sharerun.shareRunChallenge**를 누릅니다.
3. **Capabilities**에서 **Sign in with Apple**에 체크합니다. 옆의 **Edit**에서 **Enable as a primary App ID**를 고릅니다.
4. **Save**를 누릅니다. "프로파일이 무효가 된다"는 안내가 나와도 괜찮습니다. GitHub Actions의 자동 서명이 다음 빌드 때 새로 만듭니다.

앱의 `ios/Runner/Runner.entitlements`에는 `com.apple.developer.applesignin = Default`가 이미 들어 있습니다.

## 2단계. 서버에 번들 ID 알려 주기 (권장, 무료)

Cloud Run `src-jena-ai` 환경 변수에 `APPLE_CLIENT_ID = com.sharerun.shareRunChallenge`를 넣습니다.

- 넣으면 서버가 "쉐어런 앱을 위해 발급된 Apple 토큰인지"까지 확인합니다.
- 없어도 서명·만료·발급자는 확인하지만, 넣는 편이 안전합니다.
- 비밀값이 아닙니다.

## 3단계. Firebase 콘솔 Apple 로그인 (안드로이드에서도 열 때만)

iPhone만 쓸 거면 **건너뜁니다.**

안드로이드에서 Apple 로그인을 켤 때(`APPLE_LOGIN_ENABLED=true`)만 필요합니다. 안드로이드 앱이 Firebase 웹 로그인을 거치기 때문입니다.

1. Firebase 콘솔 → **Authentication** → **로그인 방법** → **Apple** → 사용 설정.
2. Apple Developer에서 **Services ID**(예: `com.sharerun.shareRunChallenge.signin`)를 만들고, Firebase가 알려 주는 반환 URL을 등록합니다.
3. 4단계의 키 정보(팀 ID, 키 ID, `.p8`)를 Firebase 화면에 넣습니다.

## 4단계. 탈퇴할 때 Apple 연결 끊기용 키 (권장, 무료)

Apple은 Apple 로그인을 제공하는 앱이 **계정 삭제 때 Apple 토큰도 해제(revoke)**하라고 요구합니다.

앱은 이렇게 준비돼 있습니다. iPhone에서 Apple이 연결된 계정을 삭제하면 "Apple 로그인 연결도 끊기 위해 Apple 확인을 한 번 더 받아요."라고 안내합니다. 그다음 Apple 창을 한 번 더 띄워 일회용 코드를 받아 서버로 보냅니다. 서버는 그 코드로 바로 해제합니다. Apple 토큰은 어디에도 저장하지 않습니다.

서버가 Apple에 해제를 요청하려면 **Sign in with Apple 키(.p8)**가 필요합니다.

1. https://developer.apple.com/account/resources/authkeys/list → **+**.
2. 이름 `ShareRun Sign in with Apple`, **Sign in with Apple** 체크 → **Configure**에서 Primary App ID `com.sharerun.shareRunChallenge` → 저장 → **Register**.
3. **Download**로 `AuthKey_XXXXXXXXXX.p8`을 받습니다. **한 번만** 받을 수 있습니다. **Key ID**(10자리)도 적어 둡니다.
4. Cloud Run `src-jena-ai`에 아래 값을 넣습니다. `.p8` 내용은 일반 환경 변수보다 **Secret Manager**에 넣고 연결하는 것을 권장합니다.

| 이름 | 값 |
|---|---|
| `APPLE_TEAM_ID` | `7C429Q46CL` |
| `APPLE_KEY_ID` | 위 Key ID |
| `APPLE_PRIVATE_KEY` | `.p8` 파일 내용 전체(`-----BEGIN PRIVATE KEY-----`부터) |
| `APPLE_CLIENT_ID` | `com.sharerun.shareRunChallenge` (2단계와 같음) |

- `.p8` 파일과 값은 저장소, 메신저, 이슈에 올리지 않습니다.
- 값이 없으면 **계정 삭제는 그대로 되고** 해제만 건너뜁니다(서버 로그 `not_configured`). 심사 전에 넣어 두기를 권장합니다.
- 웹 삭제 페이지(`account-deletion.html`)로 지울 때는 Apple 창을 띄울 수 없어 해제하지 않습니다. 이용자는 iPhone **설정 → Apple ID → 암호 및 보안 → Apple로 로그인**에서 직접 끊을 수 있습니다.

## 5단계. 확인 (TestFlight)

1. 새 TestFlight 빌드를 설치하고 로그인 화면에서 **Apple로 계속하기**를 누릅니다.
2. 처음이면 이름·이메일 공유 화면이 나옵니다. "나의 이메일 가리기"로도 한 번 해 봅니다.
3. 로그인 후 닉네임 칸에 이름이 추천으로 채워지는지 봅니다(처음 로그인 때만).
4. 설정 → 계정 삭제를 하고, Apple 확인 창이 한 번 더 뜨는지 봅니다. 서버 로그에서 `Apple revoke on account delete: revoked`를 확인합니다.

## 배포 순서

1. 이 PR 머지
2. 서버(Cloud Run) 재배포: nonce 확인과 해제 기능이 들어갑니다. 환경 변수(2·4단계)는 배포할 때 함께 넣습니다.
3. 1단계 Apple Developer 설정
4. TestFlight 빌드(Actions → iOS TestFlight)

서버를 먼저 배포해도 기존 앱에는 영향이 없습니다. nonce가 없는 옛 토큰도 받아 주고, 삭제 요청의 코드는 선택 항목입니다.
