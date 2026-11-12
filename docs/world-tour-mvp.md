# World Tour MVP 1.1

GPS 인증을 통과한 러닝 거리를 가상 세계여행 미션 진행률로 쓰고, 완주하면 여권에 스탬프를 찍는다.
기존 러닝·인증·보상·스탬프 투어(`lib/features/stamp/`) 코드 위에 얹은 별도 기능이다.

## 규칙(확정)
- 첫 5개 미션은 처음부터 모두 열려 있다: 프랑스 에펠탑 1km, 인도 타지마할 2km, 일본 후지산 3km, 이집트 피라미드 5km, 미국 자유의 여신상 3km.
- 한 번의 인증 러닝은 사용자가 고른 미션 하나에만 반영된다(같은 러닝을 다른 미션에 붙이면 409).
- 반영 거리는 러닝 전체 거리(`distanceKm`)다. 하루 상한이 적용된 거리는 쓰지 않는다.
- 인정 조건: `activities/{id}`의 `userId == 본인`, `validationFinalized == true`, `jenaVerified == true`.
  `validate_run`과 부정 탐지는 읽기만 한다(수정 없음). **모의 위치 탐지는 이번 범위가 아니다.**
- 보상은 스탬프와 여권뿐이다. SHARE·DIA 등 화폐 지급과 결제는 없다.
- 이미 완주한 미션에는 새 러닝을 붙일 수 없다(409 `mission_completed`).

## 서버 (`backend/jena_ai`)
| 항목 | 위치 |
|---|---|
| 서비스 | `app/services/world_tour.py` (`attach`, `attach_in_txn`, `read_me`, `seed_missions`) |
| 모델 | `app/models/world_tour.py` |
| 라우트 | `POST /actions/world-tour/attach {mission_id, activity_id}`, `GET /actions/world-tour/me` (`app/routers/secured_action_router.py`에 추가만) |
| 테스트 | `tests/test_world_tour.py` |

Firestore (클라이언트 쓰기 전부 금지, 서버만 쓰기):
- `worldTourMissions/{missionId}`: title, countryCode, landmarkId, targetKm, order, active. 문서가 없으면 코드 상수(`MISSION_SEED`)를 쓴다.
- `users/{uid}/worldTour/{missionId}`: state(active|completed), progressKm, completedAt, stampId.
- `users/{uid}/worldTourRuns/{activityId}`: missionId, countedKm, linkedAt — **중복 방지 가드 문서**.

`attach`는 한 트랜잭션이다. 모든 읽기(활동·가드·진행·미션)를 먼저 하고 나서 쓴다.
가드 문서가 이미 있으면 같은 미션이면 저장된 결과를 그대로 돌려주고(멱등), 다른 미션이면 거부한다.
`crew_ranking`의 가드 문서 패턴을 따랐고 그 파일은 수정하지 않았다.

오류 코드(`detail`): `activity_not_found`(404), `activity_not_yours`(403), `run_not_finalized`(409, 나중에 재시도),
`run_not_verified`(422), `run_already_linked`(409), `mission_completed`(409), `mission_not_found`(404).

## 앱 (`lib/features/world_tour/`)
- 진입: 홈 화면 맨 위 `WorldTourEntryCard` 하나. 열 때 보류 중인 러닝을 다시 보낸다.
- 목록 → 상세 → 기존 러닝 화면(`/run-tracking`, `startRunWithPreflight` 그대로) → 도착 화면 / 여권.
- 러닝 화면 변경은 두 가지뿐이다: 미션이 있을 때만 작은 여행 진행 줄(`WorldTourRunChip`)을 보여 주고,
  검증이 끝나면 `WorldTourRunEnd.settle`로 attach를 호출한다. 미션 없이 시작한 러닝은 전과 똑같다.
- 앱을 껐다 켜도 복구: attach 전에 `shared_preferences`(`world_tour_pending_runs_v1`)에 `{uid, missionId, activityId}`를 먼저 적고,
  서버가 답하면(성공 또는 영구 거부) 지운다. 네트워크 오류·타임아웃·`run_not_finalized`는 남겨 두고 다음 홈 진입 때 다시 보낸다.
  서버가 멱등이라 중복 호출해도 안전하다. 7일이 지나거나 40번 실패한 항목은 버린다.
- 진행률·스탬프·여권은 서버 응답만 쓴다. 불러오지 못하면 숫자 없이 "다시 시도"만 보여 준다.
- 공유: 기존 `RunFinishImageShare.capture`·`shareImageFile`을 감싸 쓴다(기존 공유 코드 수정 없음).

## 배포가 필요한 항목 (이번 작업에서는 하지 않음)
1. 서버 배포: 새 라우트 2개와 `world_tour.py`.
2. `firestore.rules` 배포: 새 컬렉션 3개 규칙.
3. (선택) 미션 시드: 서버 코드 상수로도 동작한다. 콘솔에서 편집하려면 한 번 `world_tour.seed_missions(db)`를 실행한다.
4. 앱 출시. 서버가 먼저 배포돼야 앱의 World Tour 화면이 동작한다(서버가 없으면 "불러오지 못했어요"와 다시 시도만 보인다).

## 아직 필요한 그림 (지금은 단색 배경 + 아이콘 임시 카드)
직접 그린 일러스트만 쓴다. 저장소에 월드 빌리지 랜드마크 그림(에펠탑 낮, 후지산 등)은 없었다
(`assets/images/villages/`는 계절 풍경 사진 크기의 배경뿐). 에펠탑 야간 조명 그림은 쓰지 않는다.
- 랜드마크 일러스트 5장: 에펠탑(낮), 타지마할, 후지산, 피라미드, 자유의 여신상 (`WorldTourLandmarkArt`를 교체)
- 스탬프 5종(원형 도장)과 여권 표지
- 남녀 아바타: 저장소의 기존 `avatar_gender_male/female.png`를 썼다. 여행 포즈 버전이 필요하면 별도 그림.
