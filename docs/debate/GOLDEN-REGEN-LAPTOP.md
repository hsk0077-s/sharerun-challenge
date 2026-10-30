# 골든 7건 재생성 — 대표님 Windows 노트북 전용

이 문서는 대표님 노트북(원래 골든을 찍은 PC)의 PowerShell에서 그대로 따라 할 절차다. 이 리눅스 박스에서는 골든 PNG를 찍지 않았다(`git status`에 `test/**/goldens/*.png` 변경 없음). 근거는 `docs/debate/SRC-7-TOPICS.md`의 "16시 — 골든 7건은 Flutter 환경 차이다"다.

## 0. 범위 — 정확히 이 7건만

2026-10-29(15시·16시)와 2026-10-30 이 리눅스 박스에서 같은 7건이 실패했다. 테스트 파일은 4개, 테스트는 7개, PNG는 7개다.

| # | 테스트 파일 | 테스트 이름 | 골든 PNG | 이 리눅스의 diff(10/30) |
| --- | --- | --- | --- | --- |
| 1 | `test/core/theme/src_theme_test.dart` | `token showcase golden` | `test/core/theme/goldens/src_token_showcase.png` | 0.45% (944px) |
| 2 | `test/screens/home_tokens_test.dart` | `Home START golden` | `test/screens/goldens/home_screen_tokens.png` | 2.36% (7,762px) |
| 3 | `test/screens/home_tokens_test.dart` | `live Home tab golden` | `test/screens/goldens/home_dashboard_tokens.png` | 5.88% (19,349px) |
| 4 | `test/screens/lobby_my_tokens_test.dart` | `Lobby golden` | `test/screens/goldens/lobby_tokens.png` | 0.17% (556px) |
| 5 | `test/screens/lobby_my_tokens_test.dart` | `Tournament list golden` | `test/screens/goldens/tournament_list_tokens.png` | 29.41% (96,814px) |
| 6 | `test/screens/lobby_my_tokens_test.dart` | `My page golden` | `test/screens/goldens/my_page_tokens.png` | 24.71% (81,337px) |
| 7 | `test/screens/walking_tokens_test.dart` | `Walking challenge golden` | `test/screens/goldens/walking_challenge_tokens.png` | 1.44% (4,750px) |

#3의 5.88%(19,349px)는 15시·16시 보고의 5.73%(18,845px)와 약간 다르다. 같은 7건·같은 방향(실패)이고 **가정** 없이 이번 라운드에 직접 돌려 나온 수치라는 점만 적는다. 차이의 원인은 확인하지 않았다.

**건드리지 말 것**: `test/features/pedometer/walking_challenge_share_test.dart`의 `daily-goal brag card golden` (`test/features/pedometer/goldens/walking_daily_goal_brag.png`). 같은 `golden` 태그를 쓰지만 이 8번째 골든은 이 리눅스에서도 통과한다(10/30 확인). 위 4개 파일만 지정해서 돌리면 이 파일은 손대지 않는다.

## 1. Flutter 버전 확인

이 리눅스 박스는 `flutter --version` 결과가 `Flutter 3.47.8 • channel stable`, Framework revision `737ba8f885` (2026-10-22), Engine `cf636b1dfb`다. 저장소에 `.fvmrc`나 버전 고정 파일이 없고, `.github/workflows/*.yml`도 `channel: stable`만 쓰고 특정 버전을 박지 않는다.

노트북에서:

```powershell
flutter --version
```

- 노트북이 기존에 이 7개 골든을 찍었던 그 Flutter로 그대로 두는 것을 권한다. 골든은 "이 PC의 폰트 + 이 Flutter 엔진"의 렌더링을 기준으로 찍히므로, 버전을 리눅스의 3.47.8에 맞추는 것이 목적이 아니다.
- **확인 필요**: 노트북의 현재 `flutter --version`이 마지막으로 이 PNG들을 커밋한 시점(아래 `git log` 참고)과 같은 메이저 버전대인지는 대표님이 노트북에서 직접 봐야 안다. 크게 다르면(예: 2.x ↔ 3.x) 재생성 전에 판단이 필요하다 — 이 문서는 그 판단을 대신하지 않는다.

```powershell
git log -3 --date=short --format="%H %ad %s" -- test/screens/goldens/home_screen_tokens.png
```

## 2. 브랜치 체크아웃

```powershell
cd <저장소 경로>
git fetch origin
git checkout cursor/src7-locales-watch-debate-e266
git pull origin cursor/src7-locales-watch-debate-e266
git log --oneline -5
```

마지막 `git log`에 10/30 커밋(`t1_abuse`, `t2_price`, `t3_watch` 등 "src7 10/30:" 로 시작하는 메시지)이 보이는지 확인한다. 안 보이면 감독 스크립트가 아직 push하지 않은 것이니, 대표님께 push 여부를 먼저 확인한다.

```powershell
flutter pub get
```

## 3. 재현 확인 (덮어쓰기 전)

먼저 `--update-goldens` 없이 돌려서 위 표의 7건이 그대로 실패하는지 본다. 이 명령은 PNG를 바꾸지 않는다.

```powershell
flutter test --tags golden `
  test/core/theme/src_theme_test.dart `
  test/screens/home_tokens_test.dart `
  test/screens/lobby_my_tokens_test.dart `
  test/screens/walking_tokens_test.dart
```

- 7개 실패가 위 표와 같은 이름으로 나오면 다음 단계로 간다.
- 실패 개수나 이름이 다르면(예: 7개가 아니거나 다른 골든이 섞이면) 멈추고 브랜치·버전을 다시 확인한다. 추측으로 `--update-goldens`를 돌리지 않는다.

## 4. 이 7건만 `--update-goldens`

위와 똑같은 4개 파일 지정, `--update-goldens`만 추가한다. 다른 파일을 넣지 않아야 8번째 골든(`walking_challenge_share_test.dart`)이 그대로 남는다.

```powershell
flutter test --update-goldens --tags golden `
  test/core/theme/src_theme_test.dart `
  test/screens/home_tokens_test.dart `
  test/screens/lobby_my_tokens_test.dart `
  test/screens/walking_tokens_test.dart
```

## 5. 결과 확인

```powershell
flutter test --tags golden `
  test/core/theme/src_theme_test.dart `
  test/screens/home_tokens_test.dart `
  test/screens/lobby_my_tokens_test.dart `
  test/screens/walking_tokens_test.dart `
  test/features/pedometer/walking_challenge_share_test.dart
```

8개 전부(7건 + 8번째 `daily-goal brag card golden`) 통과해야 한다. 하나라도 실패하면 3번부터 다시 본다.

```powershell
git status
```

바뀐 파일이 정확히 아래 7개여야 한다:

```
test/core/theme/goldens/src_token_showcase.png
test/screens/goldens/home_screen_tokens.png
test/screens/goldens/home_dashboard_tokens.png
test/screens/goldens/lobby_tokens.png
test/screens/goldens/tournament_list_tokens.png
test/screens/goldens/my_page_tokens.png
test/screens/goldens/walking_challenge_tokens.png
```

`test/screens/failures/**`, `test/core/theme/failures/**`, `build/`, `.dart_tool/` 같은 테스트 부산물이 같이 나타나면 커밋하지 않는다(아래 6번).

## 6. 부산물 정리 (커밋 전)

```powershell
git status --porcelain
# test/screens/failures, test/core/theme/failures, build, .dart_tool 같은 캐시/실패 이미지가 보이면:
git clean -ndx test build .dart_tool   # 지울 목록만 먼저 본다
git clean -fdx test build .dart_tool   # 목록이 캐시·실패 이미지뿐임을 확인한 뒤 지운다
```

`test/screens/failures/walking_challenge_tokens_*.png` 4개는 이미 저장소에 커밋되어 있던 파일이다. 이번 작업으로 그 파일들이 바뀌지 않았으면 그대로 둔다(건드리지 않음).

## 7. 커밋

```powershell
git add `
  test/core/theme/goldens/src_token_showcase.png `
  test/screens/goldens/home_screen_tokens.png `
  test/screens/goldens/home_dashboard_tokens.png `
  test/screens/goldens/lobby_tokens.png `
  test/screens/goldens/tournament_list_tokens.png `
  test/screens/goldens/my_page_tokens.png `
  test/screens/goldens/walking_challenge_tokens.png
git commit -m "test: 골든 7건 재생성 (대표 PC, Flutter <노트북 flutter --version 결과>)"
```

커밋 메시지의 `<노트북 flutter --version 결과>`는 1번에서 확인한 버전 문자열로 채운다. push는 이 문서가 대신 정하지 않는다. 대표님이 평소 쓰는 방식대로 한다.
