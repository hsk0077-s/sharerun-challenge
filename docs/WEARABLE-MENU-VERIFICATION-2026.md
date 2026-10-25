# 2025–2026 워치·스마트밴드 브랜드별 실제 메뉴 문구 정밀 검증 보고서

- 점검 일자: 2026-10-25 KST
- 반영 파일: `lib/screens/wearable_brand_guide_sheet.dart`, `lib/screens/device_connection_screen.dart`, `lib/core/strings/app_strings.dart`
- 목적: 사용자가 브랜드 공식 앱을 **한국어** 또는 **영어**로 쓰더라도 길을 잃지 않도록 2025~2026 최신 버전의 실제 탭·버튼 명칭을 한·영 병기(`한국어(English)`)로 정밀 대조하여 반영함.

---

## 1. 브랜드별 실제 메뉴 경로 (Health Connect / Apple Health + BLE 심박 전송)

| 브랜드 / 기기 | 공식 앱 | Android `Health Connect` 실제 메뉴 경로 (한·영) | iOS `Apple 건강` 실제 메뉴 경로 (한·영) | 실시간 BLE 심박 전송 (`0x180D`) 메뉴 경로 |
|---|---|---|---|---|
| **샤오미 (Xiaomi)**<br>Mi Band 8/9/10, Redmi Watch, Xiaomi Watch | **Mi Fitness**<br>*(구형 미밴드는 Zepp Life)* | `프로필(Profile)` → `타사 데이터(Third-party data)` *(일부 버전: `프로필 → 설정 → 타사 데이터` 또는 `연결된 앱(Connected apps)`)* → `Health Connect(헬스 커넥트)` → 걸음 수·심박수 쓰기 허용 | `프로필(Profile)` → `타사 데이터(Third-party data)` → `건강(Health)` *(구형 Zepp Life는 `프로필 → 계정 추가(Add accounts) → 건강`)* | 기기/앱 `운동 설정(Workout settings)` 또는 워치 `설정 → 심박수 → 심박수 공유(Share heart rate / Heart rate broadcasting)` |
| **어메이즈핏 (Amazfit)**<br>Balance, T-Rex 3, Active, GTR/GTS, Bip | **Zepp** | `프로필(Profile)` → `타사 계정 연결(Third-party account linking / Add accounts)` → `Health Connect(헬스 커넥트)` → 걸음 수·심박수 쓰기 허용 | `프로필(Profile)` → `타사 계정 연결(Add accounts)` → `Apple 건강(Apple Health)` | 워치 `설정(Settings)` → `운동(Workout)` → `심박수 공유(Heart Rate Push / Broadcast)` |
| **가민 (Garmin)**<br>Forerunner 165/265/965, Fenix, Epix, Venu, Instinct | **Garmin Connect** | 하단 `더보기(More ···)` → `설정(Settings)` → `연결된 앱(Connected Apps)` → `헬스 커넥트(Health Connect)` *(Garmin → Health Connect 단방향 공식 지원)* | `더보기(More ···)` → `설정(Settings)` → `연결된 앱(Connected Apps)` → `Apple 건강(Apple Health)` | 워치 `UP(메뉴) 길게 누르기` → `건강 및 웰니스(Health & Wellness)` *(또는 `센서 및 액세서리(Sensors & Accessories)`)* → `손목 심박수(Wrist Heart Rate)` → `심박수 전송(Broadcast Heart Rate)` → `시작(Start)` |
| **핏빗 / 구글 (Fitbit / Google)**<br>Pixel Watch 1/2/3, Charge 6, Inspire 3, Versa/Sense | **Fitbit** | `오늘(Today)` 탭 좌측 상단 `기기 아이콘(Device icon)` → `연결 추가(Add connections)` → `Health Connect 설정(Set up Health Connect)` *(또는 우측 상단 `설정(⚙) → Health Connect → Health Connect와 동기화(Sync with Health Connect)`)* | iPhone `건강(Health)` 앱 또는 Google Health Connect / Fitbit 설정 | Pixel Watch: Health Connect 자동 연동 및 BLE 심박 프로필 지원 |
| **삼성 (Samsung)**<br>Galaxy Watch 4/5/6/7/Ultra, Galaxy Fit 3 | **Samsung Health** | 우측 상단 `더보기(⋮)` → `설정(Settings)` → `헬스 커넥트(Health Connect)` → `앱 권한(App permissions)` → `삼성 헬스(Samsung Health)` 걸음 수·심박수 허용 | — *(갤럭시 워치는 Android 전용)* | 갤럭시 워치 단독 앱(`wear_app` 6자리 페어링) 또는 Health Connect 연동 |
| **코로스 / 순토 (COROS · Suunto)**<br>PACE 3/Pro, APEX, VERTIX, Suunto Race/Vertical | **COROS · Suunto · Health Sync** | Android: `Health Sync` 앱 설치 → 원본 `COROS/Suunto` → 대상 `Health Connect` 선택 *(또는 워치 BLE 심박 브로드캐스트로 쉐어런에 직접 연결)* | `프로필(Profile)` → `설정(Settings)` → `타사 앱(Third-party Apps)` → `Apple 건강(Apple Health)` | COROS: 워치 백버튼 길게 → `심박수 브로드캐스트(Broadcast HR)`<br>Suunto: 운동 시작 전 옵션 또는 BLE HR 연결 |

---

## 2. Android OS 버전별 시스템 Health Connect 진입 경로 (CS 안내용)

1. **Android 14 / 15 / 16 이상 (운영체제 기본 내장):**
   - `설정(Settings)` → `보안 및 개인정보 보호(Security & privacy)` → `개인정보 보호(Privacy / Privacy controls)` → `헬스 커넥트(Health Connect)` → `앱 권한(App permissions)`
2. **Android 13 이하:**
   - Google Play 스토어에서 `Health Connect` 앱 설치 → `설정(Settings)` → `앱(Apps)` → `Health Connect` → `앱 권한(App permissions)`
