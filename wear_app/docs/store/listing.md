# Wear OS 스토어 등록 초안

패키지 `com.sharerun.share_run_challenge`, 버전 `1.0.0+10001` (이번 초안에서 버전은 올리지 않음).
휴대폰 앱과 같은 Play 등록 정보에 Wear OS 폼 팩터를 붙이는 전제다. 아래 문장은 Wear OS 설명란에 넣는 초안이다.

고객에게 보이는 문장에는 기부처 이름을 넣지 않는다. 기부는 **기부 예정**으로만 적는다.
스크린샷의 숫자(6.40km, 36:48, 5:45/km, 08:17, 치타 골드)는 샘플이다. 실제 이용자 기록이 아니다.

## ko-KR

### 짧은 설명 (54/80)

6자리로 한 번 연결하면 휴대폰 없이 달리고, 기록은 Wi-Fi·LTE에서 올립니다. 기부 예정.

### 자세한 설명

```text
쉐어런 Wear OS 앱은 휴대폰 앱에 나온 6자리 코드를 시계에 한 번 입력하면, 그다음부터 휴대폰 없이 시계만으로 달릴 수 있습니다.

· 거리, 시간, 페이스와 GPS 경로를 시계에 기록합니다.
· 인터넷이 없어도 기록은 시계에 남고, Wi-Fi 또는 LTE가 연결되면 올립니다.
· 인증된 거리는 기부 예정입니다.
· 시계 화면의 타일(쉐어런 달리기)에서 달리기를 바로 시작할 수 있습니다.
```

## en-US

### Short description (76/80)

6-digit pair once. Watch runs alone, uploads on Wi-Fi or LTE. To be donated.

### Full description

```text
ShareRun for Wear OS runs on the watch after a one-time 6-digit pairing from the phone app. The phone is not required after that.

· The watch records distance, time, pace, and the GPS route.
· A run stays on the watch while offline and uploads when Wi-Fi or LTE is available.
· Verified distance is to be donated.
· The watch tile (ShareRun run) can start a run from the watch face.
```

## 그래픽

| 파일 | 용도 |
|---|---|
| `play-icon-512.png` | Play 등록 아이콘. 512×512, 32-bit PNG, 정사각. 모서리 둥글림과 그림자는 Play가 입힌다. |
| `screenshots/ko/*.png` | Wear OS 스크린샷 5장, 384×384, 1:1, 24-bit PNG(알파 없음). |
| `screenshots/en/*.png` | 같은 화면의 영어 문구. |

스크린샷은 `wear_app` 위젯을 384×384로 그려 만든 것이다. 기기 프레임, 원형 마스크, 설명 글자를 덧대지 않았다. 배경은 앱과 같은 검정이다.

| 파일 | 화면 | 대체 텍스트 (ko) | Alt text (en) |
|---|---|---|---|
| `01_start.png` | 시작, 티어 동물 | 시작 버튼과 치타 골드 등급 | Start button and Cheetah Gold tier |
| `02_countdown.png` | 3·2·1 | 시작 전 카운트다운 3 | Countdown showing 3 |
| `03_running.png` | 달리는 중 | 거리 6.40km, 시간 36:48, 페이스 5:45 | Distance 6.40 km, time 36:48, pace 5:45 |
| `04_route.png` | GPS 경로 | 이번 달리기의 경로 선 | GPS route line for the run |
| `05_summary.png` | 종료 요약 | 달린 거리, 시간, 평균 페이스와 경로 | Finished distance, time, average pace, and route |

달리는 중 화면이 그리는 큰 숫자는 거리·시간·페이스다. 심박은 기록에는 들어가지만 이 화면에는 숫자로 그리지 않으므로, 스크린샷에 심박 숫자를 넣지 않았다.

## 제출 전에 볼 것

공식 기준은 아래 페이지다.

- Wear OS 품질 요건 (WO-V, WO-P, WO-G): https://developer.android.com/docs/quality-guidelines/wear-app-quality
- 패키징·폼 팩터·거절 사유: https://developer.android.com/training/wearables/packaging
- 단독 앱 플래그: https://developer.android.com/training/wearables/apps/standalone-apps
- 스크린샷 크기·내용: https://support.google.com/googleplay/android-developer/answer/9866151
- 적응형 아이콘 안전 영역: https://developer.android.com/develop/ui/views/launch/icon_design_adaptive
- Play 아이콘 512 규격: https://developer.android.com/distribute/google-play/resources/icon-design-specifications

1. **폼 팩터.** Play Console에서 Wear OS 폼 팩터를 켜고, 워치 아티팩트를 그 트랙에 올린다. 버전 코드는 휴대폰 앱과 겹치면 안 된다. 워치 앱은 `10001`부터 따로 쓰고, 이 초안에서는 올리지 않는다. https://developer.android.com/training/wearables/packaging
2. **같은 패키지·서명 키 (WO-G7).** `com.sharerun.share_run_challenge`. 휴대폰 앱과 같은 업로드 키로 서명한다. https://developer.android.com/docs/quality-guidelines/wear-app-quality
3. **단독 실행.** `com.google.android.wearable.standalone` 은 이미 `true`다. `android.hardware.type.watch` 는 필수다 (`required="false"`로 바꾸지 않는다). https://developer.android.com/training/wearables/apps/standalone-apps
4. **스크린샷 (WO-G5).** 1:1, 최소 384×384, 앱 UI만. 프레임·마스크·투명 배경·UI에 없는 글자를 넣지 않는다. 이 폴더의 5장이 그 형식이다. 타일이 있으므로 가능하면 타일 화면도 한 장 더 넣는다. https://support.google.com/googleplay/android-developer/answer/9866151
5. **원형 화면 (WO-V16).** 글자와 버튼이 원 안에 있어야 한다. 작은 원(192dp)과 큰 원(227dp)에서 잘림이 없는지 기기 또는 에뮬레이터로 한 번 더 본다. https://developer.android.com/docs/quality-guidelines/wear-app-quality
6. **런처 아이콘.** `android:icon`과 `android:roundIcon`이 적응형 아이콘(전경 + 배경색)을 가리킨다. 그림에 글자를 넣지 않았고, 하트와 달리는 사람은 둥근 안전 영역 안에 있다. Play에 올리는 아이콘은 `play-icon-512.png`다. https://developer.android.com/develop/ui/views/launch/icon_design_adaptive
7. **설명 (WO-G2).** 주요 기능을 적는다. "Android Wear"라고 쓰지 않는다. 타일이 있으므로 타일을 언급한다. 한국어와 영어를 모두 둔다. 패키징 문서의 거절 사유에는 목록에 "Wear OS"가 없는 경우가 있으므로, 설명에 Wear OS를 넣는다. https://developer.android.com/training/wearables/packaging
8. **targetSdk·64비트 (WO-P1).** 새 앱은 targetSdk 34 이상이어야 하고, Wear OS 앱은 arm64-v8a를 포함해야 한다. 제출 빌드에서 둘 다 확인한다. https://developer.android.com/docs/quality-guidelines/wear-app-quality
9. **시작 화면 (WO-V13, WO-V15).** 앱 배경은 검정이다. 품질 기준은 시작 화면도 검정 위에 48dp 런처 아이콘이다. `res/drawable/launch_background.xml`은 아직 흰색이므로, 제출 전에 맞춘다. https://developer.android.com/docs/quality-guidelines/wear-app-quality
10. **로그인 (WO-P6).** 시계에서 아이디와 비밀번호를 받지 않는다. 휴대폰 앱이 보여 준 6자리만 입력한다. https://developer.android.com/docs/quality-guidelines/wear-app-quality
11. **기부 문장.** 스토어와 앱 모두 기부 예정만 쓴다. 기부처 이름, 금액이 이미 전달되었다는 표현은 넣지 않는다.
12. **스크린샷과 빌드가 같아야 한다.** 화면이 바뀌면 이 폴더의 그림을 위젯 테스트로 다시 그린 뒤 올린다. 다른 화면을 올리면 거절 사유가 된다. https://developer.android.com/training/wearables/packaging
