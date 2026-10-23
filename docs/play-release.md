# 구글 플레이 출시 준비

## 1. 업로드 키 만들기 (한 번만, 사용자 PC에서)

구글에 올리는 앱은 "업로드 키"로 서명해야 한다. 키 파일을 잃어버리면 앱 업데이트가 어려워지니
**두 곳 이상에 백업**하고, 파일과 비밀번호는 git·메신저에 올리지 않는다(`android/.gitignore`가 막아 둠).

```
keytool -genkey -v -keystore C:\keys\sharerun-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

`android/key.properties` 파일을 만든다(이 파일도 git에 올라가지 않는다).

```
storePassword=키 저장소 비밀번호
keyPassword=키 비밀번호
keyAlias=upload
storeFile=C:\\keys\\sharerun-upload.jks
```

`android/app/google-services.json`(Firebase 콘솔에서 받는 파일, git에는 올라가지 않음)도 있어야 한다.
없으면 `flutter build appbundle`이 멈춘다. 업로드 키 지문을 Firebase에 등록한 뒤에는 이 파일을 다시 받아 덮어쓴다.

이 파일이 있으면 릴리스 빌드가 업로드 키로 서명한다. 내 폰 시험용 빌드(`flutter run --release`,
`flutter build apk`)는 파일이 없으면 예전처럼 디버그 키로 서명한다. 그러나 **구글에 올리는 파일(AAB,
`flutter build appbundle`)은 파일이 없거나 항목이 빠져 있으면 빌드가 멈춘다**(디버그 키로 몰래
서명해 잘못 올리는 일을 막기 위해서).

## 2. 구글에 올리는 파일 만들기

출시용 설정은 개발용 `.env`와 **따로** 만든다. `.env.release.example`을 `.env.release`로 복사해 채운다
(`.env.release`는 git에 올라가지 않는다).

```
flutter build appbundle --release --dart-define-from-file=.env.release
```

`.env.release`에는 앱이 실제로 읽는 이름만 넣는다. 서버 전용 비밀(`OPS_ADMIN_SECRET`,
`PG_WEBHOOK_SECRET`)과 개발용 값(`LOCAL_DEV_MODE=true`, 에뮬레이터, 집 안 주소)은 넣지 않는다.
네이버 로그인 SDK는 매니페스트의 client id와 client secret을 읽는다. 이 값은 git에 두지 않는다.
`.env`와 `.env.release`에 아래 이름만 넣고, 값은 네이버 개발자 콘솔에서 받은 것을 로컬에만 적는다.
예전에 저장소에 올라갔던 secret은 네이버 콘솔에서 다시 발급한다.

```
NAVER_CLIENT_ID=
NAVER_CLIENT_SECRET=
```

폰에서 시험할 때:

```
flutter run --release --dart-define-from-file=.env
```

구글에 올리는 AAB는 위의 `flutter build appbundle --release --dart-define-from-file=.env.release`를 쓴다.
Gradle은 dart-define의 `NAVER_CLIENT_ID`, `NAVER_CLIENT_SECRET`을 먼저 읽고, 없으면 `android/naver.properties`
(같은 키 이름, git에 올라가지 않음), 그다음 프로젝트 루트 `.env`를 읽는다. 값이 비어 있어도 빌드는 된다.
앱 Dart 코드는 secret을 읽지 않는다.

빌드 전에 아래로 한 번 확인한다(아무것도 안 나와야 한다).
`NAVER_CLIENT_SECRET`만 예외다. 이것은 서버 비밀이 아니라 네이버 앱 SDK용 값이고, 위 파일에 로컬로만 둔다.

```
Select-String -Path .env.release -Pattern "OPS_ADMIN|PG_WEBHOOK|SECRET|UVICORN|EMULATOR_HOST|192\.168|127\.0\.0\.1" |
  Where-Object { $_.Line -notmatch '^\s*NAVER_CLIENT_SECRET=' }
```

앱 Dart 코드가 `String.fromEnvironment`로 읽는 이름은 `lib/core/config/app_env.dart`,
`lib/features/integrity/integrity_check.dart`, `lib/features/iap/models/coach_plus_product.dart`에 있다.
`.env` 파일 자체는 앱 에셋에 들어가지 않는다(`pubspec.yaml`의 assets에 없음).
다만 `--dart-define-from-file`로 넘긴 키는 빌드에 실리고, 네이버 키는 Android 매니페스트에도 들어간다.
그래서 네이버 secret은 git에는 없지만 출시 파일(AAB) 안에는 있다. 서버 비밀은 이 파일에 넣지 않는다.

결과: `build\app\outputs\bundle\release\app-release.aab`. Play Console에서 앱 서명은
"Play 앱 서명"을 켜고, 이 파일을 올린다. 버전은 `pubspec.yaml`의 `version: 이름+번호`에서 오며
올릴 때마다 번호(+뒤)가 커져야 한다.

## 3. 권한 정리 결과 (이번에 한 일)

지운 것(앱 코드가 쓰지 않음)
- `SCHEDULE_EXACT_ALARM` — 알림은 정확한 알람이 필요 없는 방식(`inexactAllowWhileIdle`)이다.
- `ACCESS_BACKGROUND_LOCATION` — 달리기 GPS는 위치 foreground service로 화면이 꺼져도 이어지고,
  "항상 허용"은 요청하지 않았다(워치 연결 화면의 요청도 뺐다).
- `BODY_SENSORS_BACKGROUND`, `HIGH_SAMPLING_RATE_SENSORS` — 쓰지 않음.
- 블루투스 5개와 블루투스 기능 선언 — 블루투스를 쓰는 코드가 없다(워치는 Health Connect로 읽는다).
- `READ_MEDIA_IMAGES`, `READ_EXTERNAL_STORAGE` — 사진 고르기는 시스템 사진 선택기로 하고 따로 권한을 받지 않는다.
- Health Connect 중 읽지 않는 것: 속도, 총 칼로리, 과거 기록, 운동 경로. 잘못된 이름
  `READ_ACTIVE_ENERGY_BURNED`와 중복 줄도 정리했다.

남긴 것과 구글 앱 콘텐츠 양식에서 설명해야 하는 것
- **위치**(`ACCESS_FINE/COARSE_LOCATION` + foreground service 위치): 달리기 경로·거리 기록과 부정 기록 방지.
- **Health Connect**: 앱을 쓰는 동안 걸음·심박을 읽는다. 화면이 꺼진 달리기는 건강 foreground service
  (`FOREGROUND_SERVICE_HEALTH`)로 이어진다. 1.0은 백그라운드에서 Health Connect를 읽지 않으므로
  `READ_HEALTH_DATA_IN_BACKGROUND`는 매니페스트에서 뺐다(`tools:node="remove"`). Play Console에
  백그라운드 건강 데이터 권한으로 선언하지 않는다.
- **신체 활동**(`ACTIVITY_RECOGNITION`): 만보기. 심박은 Health Connect로 읽으므로 `BODY_SENSORS`는 뺐다
  (라이브러리가 다시 넣지 못하게 `tools:node="remove"`).
- **마이크**(`RECORD_AUDIO`): 달팽이봇 말하기(누를 때만 요청). **카메라**: 완주 카드 배경 사진.
- **foreground service**(건강·위치): 걸음과 달리기 기록이 꺼지지 않게 하는 지속 알림.
- 알림, 진동, 부팅 완료(알림 다시 예약), 생체 인증(결제 확인), 인터넷.

## 4. 공개 주소 만들기 (이용약관, 개인정보처리방침, 계정 삭제 안내)

구글은 누구나 열 수 있는 웹 주소를 요구한다. `site/` 폴더에 페이지가 있다.
이용약관은 `site/terms.html`이고, 배포 뒤 주소는 `https://share-run-challenge.web.app/terms.html`이다.
앱의 약관 동의와 설정은 이 주소를 연다.

1. `site/privacy.html`, `site/account-deletion.html`의 `[대괄호]` 항목(회사명, 대표자, 주소, 문의 이메일, 처리 기한 등)을 채우고
   노란 "초안입니다" 상자를 지운다. `[확인]`이 붙은 문장은 실제와 맞는지 확인한다. 법무 검토를 받는다.
2. 올리기(한 번에 한 줄씩):
   ```
   firebase deploy --only hosting:web --project share-run-challenge
   ```
   주소는 `https://share-run-challenge.web.app/terms.html`, `.../privacy.html`,
   `.../account-deletion.html` 이다.
   (기본 사이트 이름이 다르면 `firebase hosting:sites:list`로 확인해 `.firebaserc`의 `web` 값을 바꾼다.)
3. Play Console의 "앱 콘텐츠 → 개인정보처리방침"에 `privacy.html` 주소를, "데이터 보안 → 계정 삭제 URL"에 `account-deletion.html` 주소를 넣는다.
4. 앱 안의 개인정보 처리방침 화면과 내용이 같아야 한다.

## 5. 스토어에 필요한 것 (아직 안 됨)

- 앱 설명, 스크린샷, 아이콘, 콘텐츠 등급, 데이터 보안 양식, 앱 안 결제 상품 등록.
- 계정 삭제: 앱 안(마이 → 계정 삭제)은 이미 있고, 웹 안내는 위 4번에서 만든다.
