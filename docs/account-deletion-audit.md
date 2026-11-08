# 계정 삭제 전수 점검 (코드 추적 결과)

작성일: 2026-11-08. 근거는 코드 읽기와 테스트용 가짜 DB 검증(`backend/jena_ai/tests/test_account_deletion_audit.py`, 12개)이다. **운영 데이터는 건드리지 않았다.** Android와 iOS는 같은 서버 삭제 경로(`POST /actions/account/delete`)를 쓰므로 아래 결과는 **Android에도 그대로 적용된다**(앱 쪽은 삭제 후 로그아웃·로컬 저장소 삭제·로그인 화면 이동: `settings_screen.dart:327-344`).

## 0. 이전 문서 정정
`docs/ios-apple-auth.md` 이전 판은 "다른 컬렉션을 지우는 코드는 찾지 못했다"고 적었는데 **틀렸다.** 2단계 정리가 있다: `ops_service.purge_user_data`/`purge_deleted_accounts`(`POST /ops/users/purge-deleted`, 하루 1회 Cloud Scheduler용 스크립트 `scripts/setup-cloud-scheduler.ps1`, 작업 이름 `src-purge-deleted-accounts-daily`). **실제 운영에 스케줄이 만들어져 돌고 있는지는 이 환경에서 확인할 수 없다(미확인, 대표님 확인).** 공개 문서(`site/privacy.html`, `site/account-deletion.html`)는 "활동 기록은 30일 이내 삭제, 결제·거래 기록 5년 보관"이라고 이미 적어 두었다. 이 기간들은 대표님이 정해 공개한 값이며 이 점검에서 새로 정하지 않았다.

## 1. 단계
1. **즉시(앱에서 삭제)** `delete_account`: 프로필 익명화 표시, 푸시 값 삭제, 잔액 0, 워치 기기 삭제, Firebase 로그인 계정 삭제, 로그인 수단 연결(`authIdentities`) 삭제 + 재가입 판별용 해시 보관.
2. **일 단위 정리** `purge_user_data`: 활동 기록, 하루 걸음·알림 등 일부 하위 컬렉션, 프로필 개인 필드를 삭제하고 `accountStatus: purged`.

## 2. 데이터별 표
범례: 삭제 / 남음 / 미확인. "정책" = 대표님 결정 필요.
| 데이터 | 위치 | 1단계 | 2단계 | 판단 |
|---|---|---|---|---|
| 로그인 계정 | Firebase Auth | 삭제 | – | 완료 |
| 로그인 수단 연결 | `authIdentities` | 삭제(해시 `rewardTombstones`만 남김) | – | 완료. 해시는 재가입 판별용 |
| 푸시 토큰 | `users.fcmToken` | 삭제 | – | 완료 |
| 워치 기기 | `users/*/watchDevices` | 삭제 | 삭제 | 완료 |
| 재화 잔액 | `users.wallet` | 0으로 | – | 완료 |
| 닉네임·이메일·표시 이름·성별·기기 종류 | `users` 필드 | **남음** | 삭제 | 삭제 후 최대 일 단위 정리 때까지 남음 |
| 활동(러닝) 기록 | `activities` (`userId`) | 남음 | 삭제 | 30일 이내 공지와 일치(정리가 실제로 도는 경우) |
| 하루 걸음(+폰 모델), 알림, 재방문 푸시 | `users/*/daily_metrics, notifications, retentionPushes` | 남음 | 삭제 | 위와 같음 |
| 로그인 기기 목록, 주운 다이아 상자 | `users/*/loginDevices, collectedDiamondBoxes` | 남음 | 삭제 | 위와 같음 |
| 상품 보유, 상금 응모권, 회사 상금 레이스 | `users/*/shopInventory, prizeTickets, companyPrizeRace` | 남음 | **남음** | 재화·상금 기록으로 보이나 보존 근거 여부는 **정책** |
| 재화 거래 내역 | `walletTransactions` | 남음 | 남음 | 거래 기록. 공지상 5년 보관(대표님 공지). 이용자 식별 필드가 남는 점은 **정책** |
| 구글 플레이 주문·구독, 환불 요청, 기부 장부 | `playPurchases`, `playSubscriptions`, `refundRequests`, `donationLedger` | 남음 | 남음 | 거래 기록. 5년 공지와 같은 취급인지는 **정책/법무** |
| 크루 가입 | `crews/*/members`, `joinRequests`, `crews/*/runs`, 사용자 `pendingCrewId` | **남음** | **남음** | **갭.** `delete_account`가 크루 탈퇴를 호출하지 않는다(코드 확인). 닉네임 필드는 정리 후 사라져 "러너"로 보인다. 크루장이 삭제하면 크루장 없는 크루가 생길 수 있음 → **정책 + 구현 필요**, 구현 전 보고 |
| 대회 참가·정산 | `tournaments/*/participants` 등 | 남음 | 남음 | 상금 정산 기록이면 보존 대상일 수 있음 → **정책** |
| 추천 코드·추천 관계·지급·심사 | `referralCodes`, `referrals`, `referralPayouts`, `referralReviews` | 남음 | 남음 | 보상 중복 방지에 필요한 면이 있어 **정책** |
| 신고, 이의 신청 | `reports`(문서 이름에 uid), `appeals`(닉네임 복사 포함 가능) | 남음 | 남음 | 이의 신청 증빙 사진(`appealProofs`)은 14일 TTL이지만 **TTL 정책이 실제로 설정돼 있는지 미확인** |
| 체험 기기, 보상 차단, 보안 로그 | `trialDevices`(기기 id→uid), `rewardBlocks`, `securityLog`(uid) | 남음 | 남음 | 부정 이용 방지 목적. 기간·범위는 **정책** |
| 일 단위 랭킹 등 파생 집계 | `daily_metrics` 외 월간 크루 랭킹 | 미확인 | 미확인 | 집계에 닉네임을 복사하는지 전수 확인하지 못함 |
| 파일(Storage) | – | – | – | 앱에 Firebase Storage 의존성 없음(`firebase_storage` 검색 결과 없음). 사진은 기기 안에만 있거나 이의 신청 시 Firestore에 base64로 14일 |
| 기기 안 데이터 | SharedPreferences 등 | 로컬 저장소 삭제 호출(`localAuthStore.clear`) | – | 걸음·설정 캐시까지 지워지는지는 미확인 |
| Apple 쪽 연결 | 사용자 Apple ID "앱 연결" | 남음 | 남음 | 토큰 취소 미구현(`docs/ios-apple-auth.md`) |

## 3. 부분 실패·재시도 (테스트로 확인)
- `delete_account`는 Firestore 익명화를 먼저 하고 Firebase 계정 삭제를 한다. 계정 삭제가 실패하면 500이 나고 **익명화와 로그인 연결 삭제가 어정쩡한 상태**로 남지만, **다시 호출하면 끝까지 된다**(같은 요청 두 번도 무해).
- 정리는 마지막에야 `purged`로 표시하므로 중간에 실패해도 다음 날 다시 처리된다. 확인됨.
- **수정함**: 일 단위 배치에서 한 계정이 실패하면 그 호출이 중단되어 **나머지 계정도 처리되지 않았다**(테스트로 재현). 계정별로 실패를 로그(식별자와 예외 종류만)로 남기고 다음 계정으로 넘어가도록 최소 수정했다. 실패한 계정은 `deleted`로 남아 다음 실행에서 다시 시도된다.
- 사소한 발견: `purge_user_data`의 `already_purged` 분기는 도달할 수 없다(이미 `purged`면 먼저 400을 낸다). 동작에 해는 없어 두었다.
- 한 번에 최대 50계정을 처리한다(`limit=50`). 하루 삭제가 50건을 넘으면 밀린다.

## 4. 결정이 필요한 것 (구현 전 보고)
1. 크루 탈퇴를 삭제에 포함할지, 크루장 삭제 시 크루를 어떻게 할지(양도/해산).
2. `walletTransactions`, 구매·구독·환불, 대회 정산, 추천 지급을 법정 보존 대상으로 볼지와, 보존할 때 이용자 식별 필드(uid, 닉네임 복사)를 가명 처리할지. **보존 기간은 법무 확인 사항이며 여기서 정하지 않았다.**
3. `shopInventory`, `prizeTickets`, `companyPrizeRace`를 정리에 넣을지.
4. 부정 이용 방지 기록(`trialDevices`, `rewardBlocks`, `securityLog`)의 보관 범위와 기간.
5. 1단계에서 닉네임·이메일도 바로 지울지(지금은 일 단위 정리 때까지 남음).
6. 일 단위 정리 스케줄이 운영에서 실제로 도는지 확인(대표님).
