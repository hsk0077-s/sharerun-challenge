# iOS(App Store) 준비 점검 (애플 작업은 대기 중)

점검일: 2026-11-01. 애플 작업은 대표님 결정으로 대기 중이다. 시작할 때 이 문서를 기준으로 한다.

## 심사 전에 해결할 것
| # | 항목 | 상태 | 비고 |
|---|---|---|---|
| 1 | **Sign in with Apple** | 미구현, entitlement 없음 | 구글·카카오·네이버 로그인을 쓰는 앱은 지침 4.8에 따라 애플 로그인(또는 동등한 옵션)이 필요. 앱과 서버(계정 연결) 모두 바뀌는 작업. 애플 개발자 사이트의 Service ID와 키 발급은 대표님 |
| 2 | 개인정보 매니페스트 `PrivacyInfo.xcprivacy` | 없음 | Runner 타깃에 추가 필요 |
| 3 | 권한 안내 문구 현지화 | `Info.plist`가 한국어뿐 | 11개 언어 `InfoPlist.strings` 필요. 마이크·음성 문구는 "한글로", "한국어 음성"이라고 되어 있어 달팽이 도우미 11개 언어 지원과 맞지 않음 |
| 4 | `ITSAppUsesNonExemptEncryption` | 없음 | 표준 HTTPS만 쓰면 `false`로 넣어 업로드 때 질문 생략 |
| 5 | 심사용 로그인 방법 | 미정 | 소셜 로그인뿐이면 심사관이 들어갈 수 없다. 데모 계정이나 이메일 로그인 필요 |
| 6 | 백그라운드 모드 | `fetch`, `processing`이 선언되어 있으나 **코드에서 쓰지 않는다**(BGTaskScheduler, workmanager 등 없음) | 쓰지 않는 모드는 심사에서 지적(2.5.4)될 수 있어 **삭제 권장**. `location`, `bluetooth-central`은 달리기 기록과 심박 센서에 쓰이므로 심사 메모에 설명 |
| 7 | 스토어 설명문 | Play 기준 | 애플용(부제 30자, 키워드 100자, 프로모션 170자)과 Apple Watch·Apple 건강 소개를 따로 작성 |
| 8 | 앱 프라이버시 답변, 심사 메모 | 없음 | `docs/play-data-safety.md`를 바탕으로 작성 |
| 9 | iOS 프로젝트 파일 | 저장소에 `Runner.xcodeproj`, `Podfile` 없음 | Mac에서 `flutter create`로 만들되, HealthKit·Sign in with Apple·백그라운드 모드·워치 타깃 설정은 Xcode에서 해야 한다. 첫 설정은 클라우드 Mac 대여를 권장 |

## 필요한 것
- Apple Developer Program 가입(연 99달러, 승인에 하루~며칠)
- 클라우드 Mac(MacinCloud 등) 또는 빌드 서비스(Codemagic 등)
- 앱 서명 키, App Store Connect API 키, 스크린샷(시뮬레이터)

## 결정할 것
- 1.0에 애플워치 앱을 포함할지(심사 범위가 넓어진다)
- 심사관 로그인 방법

## 코드 쪽 준비 순서(제안)
1. 애플 로그인(앱+서버) 2. `PrivacyInfo.xcprivacy`, `InfoPlist.strings` 11개 언어, 수출 키, 불필요한 백그라운드 모드 삭제 3. 애플용 스토어 문구, 앱 프라이버시 답변, 심사 메모
