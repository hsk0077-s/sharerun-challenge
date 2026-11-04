# 자랑 카드 이미지 저장소 (Firebase Storage)

워킹챌린지 "오늘의 목표 달성" 카카오톡 피드 카드의 1:1 이미지를 올리는 곳입니다.
**아래는 대표님이 직접 하는 절차입니다. 코드는 아무것도 적용하지 않았습니다.**

## 구조
- 경로: `share_cards/{무작위 32자}.png`. 경로에 사용자 ID와 날짜가 없습니다.
- 올린 사람은 파일의 사용자 지정 메타데이터 `uid`에만 있습니다(규칙이 확인).
- 규칙(`storage.rules`): 링크를 아는 사람은 읽기(get), 목록(list)은 모두 차단, 쓰기는 로그인한 본인만(PNG, 5MB 이하, 새 파일만), 삭제는 올린 사람만.
- 이미지는 걸음 수, 날짜, 등급 동물, 쉐어런 로고만 담습니다. 지도와 GPS는 없습니다.

## 1. 규칙 배포
```
firebase deploy --only storage
```
Firebase 콘솔 Storage가 시작돼 있어야 합니다(미확인). 배포 뒤 콘솔 Storage > 규칙에서 위 내용인지 확인하세요.

## 2. 30일 뒤 자동 삭제 (수명 주기 규칙)
먼저 **버킷 이름**을 확인합니다(Firebase 콘솔 Storage 상단의 `gs://…` 값).

기존 수명 주기 설정이 있는지 봅니다. 아래 적용은 버킷의 수명 주기 설정 **전체를 덮어씁니다.**
```
gcloud storage buckets describe gs://<버킷이름> --format="default(lifecycle_config)"
```
비어 있으면 적용합니다.
```
gcloud storage buckets update gs://<버킷이름> --lifecycle-file=docs/share-card-lifecycle.json
```
적용 확인:
```
gcloud storage buckets describe gs://<버킷이름> --format="default(lifecycle_config)"
```
- 규칙 내용: `share_cards/` 아래 파일을 만든 지 30일이 지나면 삭제합니다. 이미 있는 파일에도 적용되고, 삭제는 보통 하루 안팎에 일어납니다(즉시 아님).
- 콘솔로 하려면: Google Cloud 콘솔 > Cloud Storage > 버킷 > 수명 주기 > 규칙 추가 > 작업 "객체 삭제", 조건 "수명 30일" + "접두사 일치 `share_cards/`".

## 3. 함께 정리할 것
- 개인정보 처리방침과 Google Play 데이터 보안 양식: 공유 때 걸음 수가 들어간 이미지를 서버에 올리고 링크를 아는 누구나 볼 수 있다는 점, 30일 뒤 삭제된다는 점.
