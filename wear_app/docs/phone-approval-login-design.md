# 폰 승인 방식 워치 로그인 — 설계와 필요한 변경 (아직 구현·배포하지 않음)

작성: 워치 2단계 작업(feat/watch-ui-phase2). **서버·Firebase·폰 앱 변경이 필요해서 이번 PR에는 넣지 않았다.** 아래 변경은 대표님 승인 전에는 만들거나 배포하지 않는다.

## 흐름 (런키퍼 방식)
1. 워치 "폰에서 로그인" → `POST /auth/watch-login/request` (로그인 전이라 인증 없음, IP당 제한). 본문 `{device_id, device_label}`. 서버가 `request_id`(무작위 128비트), `poll_secret`(워치만 아는 무작위 값; 서버는 해시만 저장), 짧은 확인 문구 `match_code`(예: 알파벳·숫자 4자)를 만들어 돌려준다. 유효 5분. 워치는 `match_code`를 화면에 보여 준다.
2. 폰 쉐어런 앱에 승인 요청이 뜬다: "워치(Wear OS)가 로그인을 요청했어요. 워치에 보이는 문구가 **K7P2**와 같은지 확인하세요. [허용] [거절]". 같은 문구를 두 화면에서 맞춰 보게 해, 다른 사람이 보낸 요청을 실수로 허용하지 않게 한다.
3. 폰 "허용" → `POST /actions/watch-login/{request_id}/approve`(로그인된 폰의 uid). 서버가 요청을 승인 상태로 바꾸고 **기존 6자리 방식과 똑같은 절차**로 워치 기기를 등록한다(`watch_pairing._register_device`: 워치는 한 대만, 기존 워치는 해제), 맞춤 토큰을 만든다(`provider: watch`, `wgen`, `wdev` 클레임 그대로).
4. 워치는 `POST /auth/watch-login/poll`(`{request_id, poll_secret}`)을 2초마다 부른다. 응답: `pending` / `denied` / `expired` / `approved`(+ `custom_token`, `nickname`). 승인 응답은 한 번만 주고 지운다. 이후는 기존과 같다(`signInWithCustomToken` → 갱신 토큰 저장, 만료 때만 다시 연결).
5. 6자리 코드 방식(`/auth/watch-pair`)은 그대로 둔다("코드로 연결" 예비 경로).

## 필요한 변경
| 위치 | 변경 | 비고 |
|---|---|---|
| 서버 `backend/jena_ai` | 엔드포인트 4개(request, poll, pending 목록, approve/deny), `watch_pairing.py`에 로그인 요청 문서와 승인 로직, 요청 제한(`rate_limit`) | 배포 필요 |
| Firestore | 새 컬렉션 `watchLoginRequests/{request_id}` = `{uid?, status, matchCode, pollSecretHash, deviceId, deviceLabel, expiresAt, createdAt}`. 보안 규칙은 클라이언트 접근 전부 거부(기존 `watchPairingCodes`와 같게). 만료 정리용 TTL 정책(`expiresAt`) | **콘솔/규칙 배포 필요** |
| 폰 앱(Flutter) | 승인 요청 목록·허용/거절 화면, 푸시 알림(요청이 오면 폰에 알림. 기존 FCM 경로 사용) 또는 앱이 열려 있을 때만 폴링 | 앱 출시 필요 |
| 워치 앱 | "폰에서 로그인" 버튼, 확인 문구 표시, 폴링 | 서버가 먼저 배포돼야 켤 수 있다(빌드 시 기능 스위치로 숨겨 두는 방식 권장) |

## 보안 판단
- `request_id`만 알아서는 토큰을 못 받는다(`poll_secret` 필요).
- 승인은 로그인된 폰만 할 수 있고, 확인 문구가 워치 화면과 같아야 한다고 안내한다.
- 요청·폴링은 IP당 제한, 5분 만료, 승인 응답 1회성, 기존 6자리 방식과 같은 기기 한 대 제한.
- 푸시 없이 앱이 열려 있을 때만 폴링하면 사용자가 폰 앱을 직접 열어야 해서 불편하다. 푸시를 쓰려면 폰 알림 권한과 서버의 푸시 전송 코드가 필요하다.

## 순서 제안
1) 대표님 승인 → 2) 서버 코드와 테스트(배포 없이) → 3) Firestore 규칙·TTL → 4) 서버 배포 → 5) 폰 앱 화면과 푸시 → 6) 워치 버튼(스위치 켜기).
