# Play Console — Health Connect 권한 선언 (대응 문서)

2026-11-02 Play 정책 상태에 올라온 지적에 대한 대응 자료입니다.

> **Android용 헬스 커넥트 권한 정책: 과도한 데이터 액세스(최소 범위 위반)**
> - 앱이 현재 구현된 사용자 대상 기능을 지원하는 데 필요한 것보다 더 많은 헬스 커넥트 데이터 유형에 대한 액세스를 요청합니다.
> - 앱에 컴패니언 기기가 필요할 수 있어 헬스 커넥트 권한을 확인할 수 없습니다. 선언 양식에 앱 안에서 요청한 데이터 유형이 작동하는 모습을 보여 주는 **동영상 링크**를 제공해 주세요.
> - 적용일: 11월 2일

> **2026-11-02 갱신: 1.0.0+5부터 Health Connect 심박수(`READ_HEART_RATE`)를 요청하지 않는다.** 아래가 최종안이다. 이전 안(심박수 선언·시연 영상)은 폐기. 심박수는 블루투스 심박 센서(BLE)로 직접 받으며 Health Connect와 무관하다.

## 1. 요청 권한 (+5 기준)

| 권한 | 쓰는 곳 |
|---|---|
| `READ_STEPS` | 오늘 걸음 수 표시, 만보기 보상, 달리기 케이던스(걸음 수/분) 검증 |
| `android.permission.ACTIVITY_RECOGNITION` (Health Connect 아님, 런타임 권한) | 폰 센서 만보기(걸음 감지) |

선언 양식(Health Connect)에는 **Steps 하나만** 체크한다. 운동, 거리, 칼로리, 활동 강도, 심박수는 모두 해제.

## 2. 선언 문구 (최종안)

**Steps (READ_STEPS) — 영어(양식용)**
> ShareRun is a walking and running app. We read step counts from Health Connect only while the user is in the app, to (1) show today's step count, (2) grant in-app step rewards (SHARE points) for steps the user actually walked, and (3) check a run's cadence (steps per minute) to confirm it was made on foot and not in a vehicle. We read steps only; we do not write any data to Health Connect and we do not read in the background. Data is not used for advertising, sold, or shared with third parties. The app works without a companion device; steps can be shown with the phone alone.

**걸음 수 (READ_STEPS) — 한국어**
> 쉐어런은 걷기·달리기 앱입니다. 앱을 사용 중일 때만 Health Connect에서 걸음 수를 읽어 (1) 오늘 걸음 수 표시, (2) 실제로 걸은 걸음에 대한 앱 내 보상(SHARE) 지급, (3) 달리기 케이던스(분당 걸음 수)로 차량 이동이 아닌 직접 달린 기록인지 확인하는 데 씁니다. 읽기만 하며 쓰기와 백그라운드 읽기는 하지 않습니다. 광고·판매·제3자 제공에 쓰지 않습니다.

**ACTIVITY_RECOGNITION (확인 필요, 미확인)** — 이 권한이 Play Console 양식의 어느 항목에 해당하는지는 화면을 보고 정한다. 같은 목적(걸음 감지)으로 아래 문구를 쓴다.
> ShareRun uses the activity recognition permission only to count steps from the phone's step sensor while the user walks or runs, to show step counts and grant step rewards. It is not used for advertising or shared with third parties.

## 3. 시연 영상
걸음 수는 폰만으로 시연된다. 컴패니언 기기(워치)가 필요 없다. 필요하면 1분 영상: 앱 실행 → 연결 → 시스템 권한 창(걸음 수) → 허용 → 홈의 걸음 수 → 개인정보 처리방침. (미확인: 심사원이 영상을 요구하는지는 화면 안내에 따른다.)

## 4. 데이터 보안 양식
`docs/play-data-safety.md`(`claude/remove-hc-heartrate` 브랜치 PR)에서 Health Connect 행은 걸음 수만 남긴다. 건강 및 피트니스 항목에서 심박수를 지울지는 **BLE 심박 센서로 앱이 심박수를 처리하므로 대표 판단**이 필요하다. 앱이 심박수를 기기 밖으로 보내지 않고 저장하지 않으면 수집 아님으로 볼 수 있으나, 보수적으로는 "건강 정보 > 심박수(선택)" 유지가 안전하다. 미확인.

## 5. 포그라운드 서비스 선언
매니페스트에 `FOREGROUND_SERVICE_LOCATION`, `FOREGROUND_SERVICE_HEALTH`가 있다. 각각 설명과 영상이 필요하다.
- LOCATION: 달리기 중 화면이 꺼져도 경로 기록.
- HEALTH: 달리기 중 걸음·BLE 심박 수집 유지. `FOREGROUND_SERVICE_HEALTH`는 Health Connect 권한이 아니어도 신체 활동 추적 용도로 선언하는 유형이다. 다만 이 유형은 `ACTIVITY_RECOGNITION` 등 관련 런타임 권한이 필요하다(미확인: 최신 Play 요건은 콘솔 안내가 최종).
