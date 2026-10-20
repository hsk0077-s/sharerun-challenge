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

이 파일이 있으면 릴리스 빌드가 업로드 키로 서명하고, 없으면 예전처럼 디버그 키로 서명한다
(내 폰 테스트 빌드가 그대로 되도록).

## 2. 구글에 올리는 파일 만들기

```
flutter build appbundle --release --dart-define-from-file=.env
```

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
- **Health Connect**: 걸음, 심박, 거리, 운동, 활동 칼로리, 활동 강도 읽기. 화면이 꺼진 상태에서도
  걸음을 읽으므로 `READ_HEALTH_DATA_IN_BACKGROUND`가 남아 있다 → Play Console의
  "Health Connect 권한 선언"에서 이유를 써야 한다.
- **신체 활동**(`ACTIVITY_RECOGNITION`): 만보기. **센서**(`BODY_SENSORS`): 심박 센서 읽기(꼭 필요한지는 폰에서 확인 후 줄일 수 있음).
- **마이크**(`RECORD_AUDIO`): 달팽이봇 말하기(누를 때만 요청). **카메라**: 완주 카드 배경 사진.
- **foreground service**(건강·위치): 걸음과 달리기 기록이 꺼지지 않게 하는 지속 알림.
- 알림, 진동, 부팅 완료(알림 다시 예약), 생체 인증(결제 확인), 인터넷.

## 4. 공개 주소 만들기 (개인정보처리방침, 계정 삭제 안내)

구글은 누구나 열 수 있는 웹 주소를 요구한다. `site/` 폴더에 두 페이지 초안이 있다.

1. `site/privacy.html`, `site/account-deletion.html`의 `[대괄호]` 항목(회사명, 대표자, 주소, 문의 이메일, 처리 기한 등)을 채우고
   노란 "초안입니다" 상자를 지운다. `[확인]`이 붙은 문장은 실제와 맞는지 확인한다. 법무 검토를 받는다.
2. 올리기(한 번에 한 줄씩):
   ```
   firebase deploy --only hosting:web --project share-run-challenge
   ```
   주소는 `https://share-run-challenge.web.app/privacy.html` 과 `.../account-deletion.html` 이다.
   (기본 사이트 이름이 다르면 `firebase hosting:sites:list`로 확인해 `.firebaserc`의 `web` 값을 바꾼다.)
3. Play Console의 "앱 콘텐츠 → 개인정보처리방침"에 `privacy.html` 주소를, "데이터 보안 → 계정 삭제 URL"에 `account-deletion.html` 주소를 넣는다.
4. 앱 안의 개인정보 처리방침 화면과 내용이 같아야 한다.

## 5. 스토어에 필요한 것 (아직 안 됨)

- 앱 설명, 스크린샷, 아이콘, 콘텐츠 등급, 데이터 보안 양식, 앱 안 결제 상품 등록.
- 계정 삭제: 앱 안(마이 → 계정 삭제)은 이미 있고, 웹 안내는 위 4번에서 만든다.
