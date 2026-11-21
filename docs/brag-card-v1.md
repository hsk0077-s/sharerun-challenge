# 통합 자랑 카드 v1 (1단계)

러닝 종료 카드와 월드투어 도착 카드가 같은 틀을 씁니다. 코드는 `lib/features/brag_card/`에 있습니다.

## 틀

| 자리 | 내용 |
|---|---|
| 머리 | 쉐어런 로고 + 이름 (영문 표기는 ShareRun) |
| 본문 | 러닝 종료: 이번 기록 / 월드투어: 도착 스탬프 |
| 바닥 | 설치 QR + 짧은 한 줄 |

- 크기 1080×1920. 위·아래 280px는 안전 여백이라 이름·QR·기록은 그 안쪽에만 둡니다.
- 러닝 종료 카드의 테마 5색·내 사진·티어 배지·구간 그래프·기부 줄과 기존 Key는 그대로입니다.
- 러닝 종료 화면에 "QR 넣기" 스위치(기본 켜짐, 저장 안 함)가 있습니다. 끄면 바닥에는 한 줄만 남습니다. 월드투어 카드는 항상 QR이 들어갑니다.
- 카드에는 내 정보만 들어갑니다. 친구·크루·순위·상품·DIA·초대 보상 문구는 없습니다(테스트로 막음).
- 유료 잠금과 광고는 없습니다.

## QR

- 내용은 Play 스토어 주소 하나뿐입니다. 상수는 `brag_card_links.dart`의 `bragCardInstallUrl` 한 곳이고, My Page 초대 주소(`myPageInvitePlayStoreUrl`)와 같은 패키지 id를 씁니다.
- `https://play.google.com/store/apps/details?id=com.sharerun.share_run_challenge&referrer=utm_source%3Dsharerun_card%26utm_medium%3Dqr%26utm_campaign%3Dbrag_card_v1`
- `referrer` 값은 모든 사람에게 같은 캠페인 이름표입니다. uid, 닉네임, 초대 코드, 기기 정보는 넣지 않습니다.
- 패키지: `qr_flutter` 4.1.0 (BSD-3-Clause), 그 안에서 쓰는 `qr` 3.0.3 (BSD-3-Clause).

## 측정

### QR 설치
Play Console 획득 보고서의 UTM(referrer 파라미터) 집계로 봅니다. 코드도 개인 데이터도 필요 없고 집계만 됩니다.
Play Install Referrer API는 기기별 데이터라 이번에는 넣지 않았습니다.

### D7 / D28
- (가) 출시 전후 전체 재방문율 비교. 기존 `activities`의 완료일만 집계합니다. 새 수집은 없습니다.
- (나) "공유한 사람 vs 안 한 사람" 비교. 사람별 공유 기록이 새로 필요합니다.
  **하상기 님 동의 검토 필요 / Play 데이터 보안·개인정보처리방침 수정 필요**

### 공유 퍼널 이벤트
`ShareFunnelEvents`(`share_funnel_events.dart`)가 4개를 정의합니다. 기본 구현은 아무 데도 보내지 않는 no-op이고, 디버그 빌드에서만 `debugPrint` 합니다.

| 이벤트 | 값 | 호출 시점 |
|---|---|---|
| `brag_card_shown` | surface | 카드 화면이 열릴 때 |
| `brag_qr_included` | surface, included | 공유할 그림을 만들 때 |
| `brag_share_tapped` | surface, target | 공유 대상 앱을 열 때 |
| `brag_share_result` | surface, target, status | 공유가 끝났을 때 |

순서는 shown → qr_included → tapped → result 입니다. surface는 `run_finish` / `world_tour`, status는 `success` / `dismissed` / `unavailable` / `failed` 입니다.

- status는 share_plus `ShareResult.status`로 알 수 있는 만큼만 넣습니다. 플랫폼이 사용자 행동을 알려주지 않으면 `unavailable`이 옵니다. 기기별 정확도는 아직 실기기로 확인하지 않았습니다.
- Instagram 스토리·TikTok 직접 공유는 앱이 그림을 받았다는 뜻으로 `success`를 기록합니다. 실제 게시 여부는 알 수 없습니다.
- 실제로 보내는 구현(Firebase Analytics 등 SDK, 서버·Firestore 전송, 기기 저장, 광고 ID 사용)은 넣지 않았습니다.
  각각 **하상기 님 동의 검토 필요 / Play 데이터 보안·개인정보처리방침 수정 필요**입니다. (`docs/play-data-safety.md`는 현재 "분석·크래시 SDK 없음"으로 신고돼 있습니다.)

## 다음 단계에서 지킬 규칙 (지금 구현하지 않음)

- 러닝 1번은 월드투어와 앞으로 만들 '함께 목표'에 둘 다 반영됩니다.
- 같은 종류의 보상은 두 번 주지 않습니다. 보호 문서(guard doc) 방식은 `backend/jena_ai/app/services/world_tour.py`(10-16, 185-199행)의 `users/{uid}/worldTourRuns/{activityId}` 와 `crew_ranking.py`의 `crews/{id}/runs/{activity}` 를 따릅니다.
- 스탬프와 칭호는 항상 무료이고 팔지 않습니다. DIA를 초대 보상으로 쓰지 않습니다.

## 그림 자리표시 (장군 봇이 그릴 곳)

- 머리 로고: `assets/images/sharerun_logo.png` (파일만 바꾸면 됨) — `BragCardHeader`
- 월드투어 랜드마크 그림: `WorldTourLandmarkArt` — `world_tour_arrival_screen.dart`
- 월드투어 아바타: `WorldTourAvatar`
- 월드투어 스탬프 표시: 지금은 `Icons.verified` 자리표시
- QR 바닥 칸: 단색 흰 판. 꾸밈 그림 자리는 만들지 않음
