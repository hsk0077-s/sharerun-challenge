# Apple 로그인: 토큰 흐름·취소·audience·배포 (iOS 준비)

작성일: 2026-11-08. **실제 Apple 서버로는 아무 요청도 보내지 않았다.** 토큰 취소, 키 발급, 배포 없음. 아래 형식은 Apple 공식 문서(DocC 데이터로 읽음)에서 확인했고, 실제 동작은 대표님이 진짜 토큰으로 시험하기 전까지 **미확인**이다.

## 1. 공식 근거 (2026-11-08 읽음)
| 주제 | URL |
|---|---|
| 토큰 취소 API (`POST https://appleid.apple.com/auth/revoke`, `client_id`/`client_secret`/`token`/`token_type_hint`=`access_token`\|`refresh_token`, 성공 HTTP 200) | https://developer.apple.com/documentation/signinwithapplerestapi/revoke-tokens |
| 토큰 발급·검증(`/auth/token`, 인증 코드는 1회용·5분, `client_id`는 App ID 또는 Services ID) | https://developer.apple.com/documentation/signinwithapplerestapi/generate-and-validate-tokens |
| client_secret JWT(ES256, 헤더 `kid`, `iss`=Team ID, `aud`=`https://appleid.apple.com`, `sub`=client_id, `exp`≤iat+15777000초) | https://developer.apple.com/documentation/accountorganizationaldatasharing/creating-a-client-secret |
| 사용자 검증·identity token(iss, aud, exp, nonce) | https://developer.apple.com/documentation/signinwithapple/verifying-a-user , …/receiving-a-users-identity-token |
| 서버 간 알림(consent-revoked, account-deleted 등) | https://developer.apple.com/documentation/signinwithapple/processing-changes-for-sign-in-with-apple-accounts |
| 심사 지침 5.1.1(v) 계정 삭제, 4.8, 2.1 | https://developer.apple.com/app-store/review/guidelines/ , https://developer.apple.com/help/app-review/guideline-reference/5-1-1-account-deletion/ |

## 2. `apple_revoke.py` 대조 결과
| 항목 | Apple 문서 | 코드 | 일치 |
|---|---|---|---|
| 주소 | `https://appleid.apple.com/auth/revoke` | 같음 | ✔ |
| 본문 형식 | 폼 필드 4개 | `application/x-www-form-urlencoded`, 같은 4개 | ✔ |
| 토큰 종류 | `access_token`, `refresh_token` | 둘만 허용(그 외는 요청 전에 거부) | ✔ |
| client_secret | ES256, `kid`, iss=Team ID, aud=appleid.apple.com, sub=client_id, 수명 ≤15777000초 | 같음, 수명 300초 | ✔ |
| client_id | Team ID가 아님 | 번들 ID/Services ID(테스트로 확인) | ✔ |
| 응답 | 200 성공 | 200만 성공으로 취급 | ✔ (이미 취소된 토큰에 대한 응답은 문서에서 확인 못 함, 미확인) |

결론: 이전 머리말의 "기억에 근거" 표시는 위 항목에 한해 해소했다. 그래도 **연결·배포하지 않은 상태**를 유지한다(취소할 토큰이 아직 없음, 3절). 테스트 15개(`tests/test_apple_revoke.py`)는 로컬 키와 가짜 HTTP만 쓴다. 실제 Apple 응답 시험은 대표님 몫.

## 3. 토큰 흐름 — 지금과 필요한 것
| 단계 | 지금 | 취소까지 가려면 |
|---|---|---|
| 획득 | iOS: `getAppleIDCredential`의 identity token만 서버로 보낸다. 인증 코드(`authorizationCode`)는 쓰지 않는다(`auth_service.dart:98-120`). Android: Firebase `signInWithProvider` | 앱이 `authorizationCode`도 보냄 → 서버가 `/auth/token`에서 교환(코드는 1회용·5분). Apple 키(.p8)·Team ID·Key ID 필요 |
| 보관 | 서버는 Apple 사용자 `sub`(`authIdentities`)만 저장 | refresh token 보관 방식은 **대표님 결정**: 5.1.1(v)에는 소셜 로그인 토큰을 기기 밖에 저장하지 말라는 문장이 있다. 대안(포럼의 Apple 직원 답변, 공식 문서 아님): 토큰이 없으면 계정 데이터를 삭제하고 사용자가 설정에서 직접 해제하도록 안내 |
| 취소 | 없음 | 계정 삭제 시 `apple_revoke.revoke_token` 호출(준비됨, 미연결) |
| 서버 간 알림 | 없음 | 엔드포인트 구현과 Apple 포털 URL 등록(승인 필요) |
| nonce | 앱이 nonce를 보내지 않음 | Apple 문서는 nonce를 쓰면 서버가 검증하라고 함. 현재는 재전송 방어가 약함. 개선하려면 앱·서버 변경 |

Android는 Firebase 경로라 Apple 토큰이 서버에 오지 않는다. 안드로이드에서 Apple 로그인한 계정의 Apple 쪽 취소는 별도 검토(미확인).

## 4. 익명화 후 남는 데이터 (코드 읽기: `secured_action_service.py:5113-5151`, `identities.py:802-813`)
**삭제·초기화됨**: `users/{uid}`의 `fcmToken`, 푸시 켜짐 값(false로), 지갑 잔액(0으로), `users/{uid}/watchDevices` 전부, Firebase Auth 사용자, `authIdentities`의 이 uid 문서(로그인 수단 연결).

**남음**:
- `users/{uid}` 문서 자체(`accountStatus`, 삭제 시각). 닉네임·이메일 등은 1단계 뒤에도 남고 일 단위 정리에서 지워진다.
- `rewardTombstones`의 SHA-256 해시(재가입 판별용, 원본 ID 아님).
- **정정**: 이전 판은 다른 컬렉션을 지우는 코드가 없다고 했으나 틀렸다. 일 단위 정리 `purge_user_data`가 활동 기록과 일부 하위 컬렉션, 프로필 개인 필드를 지운다. 무엇이 지워지고 무엇이 남는지는 `docs/account-deletion-audit.md` 표 참조.
- Apple 쪽: 토큰을 취소하지 않으므로 사용자의 Apple ID "앱 연결"에 쉐어런이 남는다.

Apple 지침은 "계정 기록과 관련 개인 데이터 삭제"를 요구한다(5.1.1). 위 남는 항목이 개인 데이터인지, 보관 기간을 어떻게 고지할지는 대표님·법무 결정이다. 이번 작업에서 삭제 코드는 바꾸지 않았다.

## 5. 서버 audience 검토 (`identities.verify_apple_id_token`)
| 경로 | 서버가 받는 토큰 | audience | 필요한 설정 |
|---|---|---|---|
| iOS 네이티브(`sign_in_with_apple`) | Apple identity token(iss `https://appleid.apple.com`) | Apple 문서상 `aud`=client_id. 네이티브 앱은 **앱의 App ID(번들 ID)**. 번들 ID가 유일한 정답이라고 단정하지 않는다(웹 로그인이면 Services ID) | `APPLE_CLIENT_ID` = 실제로 Apple에 등록한 App ID. 등록 전이라 `com.sharerun.shareRunChallenge`가 맞는지는 **미확인** |
| Android(`signInWithProvider('apple.com')`) | Firebase ID token(iss가 Apple 아님) | Firebase 프로젝트(`firebase_auth.verify_id_token`이 확인) | `APPLE_CLIENT_ID` 불필요 |
| 웹/Services ID 로그인 | 현재 앱에 없음 | Services ID | 쓰게 되면 다중 audience 지원 필요(**미구현**, 단일 값만) |

동작(수정 2b5f32f, 테스트 `tests/test_apple_audience.py` 8개): Apple 발급 토큰 + 올바른 audience → 허용 / 다른 audience → 401 / `APPLE_CLIENT_ID` 비었거나 없음 → 503 `apple_login_not_configured` / Firebase 경로·카카오·네이버·구글 → 영향 없음 / 로그에 토큰·sub 없음. 수정 전에는 설정이 비면 audience 검사를 건너뛰어 **다른 앱용 Apple 토큰도 통과**했다(재현함).

## 6. 배포 설정·순서·복구 (운영 서버는 건드리지 않았음)
1. (대표님) Apple 가입 후 App ID 등록 → 실제 번들 ID 확정.
2. (대표님) Cloud Run 서비스에 환경변수 `APPLE_CLIENT_ID=<확정된 번들 ID>` 추가.
3. 이 브랜치의 백엔드 배포. 순서가 바뀌어(코드 먼저, 변수 나중) 배포돼도 영향은 iOS Apple 토큰이 503으로 거부되는 것뿐이고, 앱은 `APPLE_LOGIN_ENABLED` 기본 꺼짐이라 지금 사용자 영향이 없다. Android·다른 로그인은 영향 없음(테스트).
4. 앱에서 `APPLE_LOGIN_ENABLED`를 켜는 빌드는 2·3이 끝난 뒤.
5. 복구: Cloud Run 이전 리비전으로 트래픽 되돌리기, 또는 커밋 2b5f32f를 되돌려 재배포. 변수 오타면 변수만 고쳐 새 리비전을 만든다.
6. 확인: TestFlight 빌드에서 Apple 로그인 성공, 잘못된 값일 때 503과 서버 로그 `APPLE_CLIENT_ID is not set`.

## 7. 남은 일
- 대표님: 토큰 보관 방식 결정, 익명화 범위 판단, Apple 키·서버 알림 URL(가입 뒤), 실토큰 시험.
- 참모(결정 후): 앱의 `authorizationCode` 전달, `/auth/token` 교환 도우미, 삭제 시 취소 연결, 서버 간 알림 엔드포인트, nonce.

## 8. 완성 설계: 하나의 흐름 (직접 Apple 경로 vs Firebase 경로)
**경로 구분**
| | 직접 Apple 경로 (iOS) | Firebase 경로 (Android) |
|---|---|---|
| 앱 | `SignInWithApple.getAppleIDCredential` → identity token(+ `authorizationCode`) | `signInWithProvider('apple.com')` → Firebase ID token |
| 서버 검증 | `_apple_claims`: Apple 공개키, iss, exp, **aud=`APPLE_CLIENT_ID`** | `firebase_auth.verify_id_token` (aud=Firebase 프로젝트), `firebase.identities["apple.com"]`가 Apple `sub` |
| 서버가 Apple 토큰을 가질 수 있나 | 예(코드 교환 시) | 아니오(Apple 토큰이 Firebase에 있음) |
| 토큰 취소 | 서버가 `/auth/revoke` 호출 가능 | Firebase 쪽 제공 기능을 쓰는 방식은 이 문서에서 조사하지 못함(미확인) |
참고: `auth_service.dart`의 `signInWithApple()`(Firebase 자격 증명 방식)은 호출하는 곳이 없다(검색 결과).

**공식 문장의 문맥 (5.1.1(v), 2026-11-08에 원문 확인)**: "An app may not store credentials or tokens to social networks off of the device and may only use such credentials or tokens to directly connect to the social network from the app itself while the app is in use." 이 문장은 같은 항목의 "Facebook, WeChat, Weibo, X 등" **소셜 네트워크 연결(프로필 가져오기, 공유)** 맥락에 있다. 같은 문서의 계정 삭제 FAQ는 Sign in with Apple 앱에 "Sign in with Apple REST API로 사용자 토큰을 취소"하라고 하며, 취소에는 서버가 `client_secret`으로 요청하므로 서버가 토큰을 가져야 한다. 두 문장의 관계(Apple 로그인에 소셜 네트워크 문장이 적용되는지)를 Apple이 직접 설명한 곳은 찾지 못했다 → **미확인**. 해석은 Apple 심사 질의(답변 기록 필요)나 법무 판단이 필요하고, 안전한 선택지는 아래 둘이다.
- A. 서버가 refresh token을 보관하지 않고 **계정 삭제 순간에만** 필요한 토큰을 확보: 삭제 화면에서 재로그인(Apple 인증 창)으로 새 `authorizationCode`를 받아 서버로 보내고, 서버가 코드 교환 → 즉시 취소. 토큰을 저장하지 않는다. (코드는 5분·1회용이라 삭제 직전에 받아야 함. 사용자 경험 변경이 있어 결정 필요)
- B. 로그인 때 코드를 교환해 refresh token을 암호화 보관하고 삭제 때 취소. 5.1.1(v) 문장과 충돌할 여지가 있어 위 A보다 위험.
권장은 A(저장 없음). 결정은 대표님.

**한 흐름 (A 기준)**
1. 로그인: 앱이 서버에서 `nonce`(무작위 raw)를 받고 `sha256-hex(raw)`를 Apple 요청의 `nonce`에 넣는다. Apple이 준 identity token을 raw nonce와 함께 서버로 보낸다. 서버: 서명·iss·exp·**aud(설정값)**·**`nonce_matches(claim, raw)`** 확인 후 nonce를 소모(1회용, 만료 있음). 현재 앱은 nonce를 보내지 않는다 → 도입하려면 앱·서버 변경.
2. 계정 삭제: 앱이 Apple 재인증으로 새 `authorizationCode`를 받아 삭제 요청에 포함. 서버: 로그인 계정 삭제·익명화와 별개로 `exchange_authorization_code`로 refresh token을 받고 `revoke_token`을 호출, 결과(성공/실패)만 기록. 취소 실패 시 삭제 자체를 막을지(재시도 유도) 허용할지는 결정 필요.
3. 서버 간 알림(consent-revoked, account-deleted): 엔드포인트 구현 + Apple 포털 등록. 한국 개발자는 **새 Services ID를 등록할 때** 서버 간 알림 엔드포인트를 제공해야 한다고 Apple FAQ에 있다. 네이티브 앱 ID만 쓰는지 Services ID가 필요한지에 따라 적용 여부가 달라진다 → 미확인.
**준비해 둔 코드와 테스트(설정·키 없이)**: `app/services/apple_flow.py`(`exchange_authorization_code`, `hash_nonce`, `nonce_matches`; 연결·배포 안 함)와 `tests/test_apple_flow.py` 12개. Apple이 nonce를 토큰에 그대로 넣는지는 실기기 시험 전까지 **미확인**.
