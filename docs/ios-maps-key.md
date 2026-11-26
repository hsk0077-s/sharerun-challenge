# iOS 지도 키 설정

iOS 앱의 Google Maps 키는 **저장소에 넣지 않습니다.** 예전에는 `ios/Runner/AppDelegate.swift`에 키 문자열이 그대로 들어 있었고, 지금은 빌드 설정에서 읽어 옵니다.

## 한눈에 보기

```
ios/Flutter/Secrets.xcconfig        (내 컴퓨터에만 있는 파일, git이 무시함)
  GOOGLE_MAPS_API_KEY = <키>
        │  Debug.xcconfig / Release.xcconfig 가 읽음 (이미 연결돼 있음)
        ▼
ios/Runner/Info.plist
  GMSApiKey = $(GOOGLE_MAPS_API_KEY)
        │  앱이 시작할 때
        ▼
ios/Runner/AppDelegate.swift
  GMSServices.provideAPIKey(...)
```

키가 비어 있으면 앱은 죽지 않고 지도만 비어 보입니다(Xcode 콘솔에 `GMSApiKey is not set` 경고).

## 설정 방법 (Mac에서)

1. `ios/Flutter/Secrets.xcconfig.example`을 같은 폴더에 `Secrets.xcconfig`로 복사합니다.
2. 파일을 열어 `GOOGLE_MAPS_API_KEY =` 뒤에 **iOS용 지도 키**를 붙입니다. 따옴표와 `//`가 들어가지 않게 합니다(xcconfig에서 `//`는 주석입니다).
3. Xcode에서 `ios/Runner.xcworkspace`를 열고 평소처럼 빌드합니다.
4. 확인: 지도 화면이 열리면 성공입니다. 비어 있으면 Xcode 콘솔의 `GMSApiKey is not set` 줄을 찾습니다.

`Secrets.xcconfig`는 `ios/.gitignore`에 들어 있어서 커밋되지 않습니다. 커밋되는 것은 `Secrets.xcconfig.example`뿐입니다.

## 키를 새로 받을 때 (Google Cloud 콘솔)

- iOS 전용 키를 따로 만듭니다. Android 키와 같이 쓰지 않습니다.
- **애플리케이션 제한**: iOS 앱 → 번들 ID `com.sharerun.share_run_challenge`(실제 번들 ID는 Xcode의 Runner 타깃에서 확인).
- **API 제한**: `Maps SDK for iOS`만 허용.
- 이전 키는 콘솔에서 폐기하거나 제한합니다. 키가 한 번 저장소에 올라갔으면 git 기록에 남으므로 코드에서 지우는 것만으로는 안전해지지 않습니다.

## 다른 곳

- Android 키는 `android/app/src/main/AndroidManifest.xml`(`com.google.android.geo.API_KEY`)에 있습니다. 이 PR에서는 바꾸지 않았습니다.
- 앱 안 지도 화면은 `GOOGLE_MAPS_API_KEY` 또는 `GOOGLE_MAPS_NATIVE_CONFIGURED` dart-define이 있어야 지도를 열려고 시도합니다(`lib/core/config/app_env.dart`). iOS에서 지도를 쓰려면 이 값도 빌드에 넘겨야 합니다.
- iOS 출시 전 점검 목록은 `docs/ios-readiness.md`를 보세요.
