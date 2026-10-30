#!/bin/bash
# Xcode Cloud post-clone 훅. ios/Runner.xcodeproj 또는 ios/Runner.xcworkspace 옆의
# ci_scripts/ 안에 있어야 Xcode Cloud가 이 파일을 실행한다.
#
# 전제: 이 저장소에는 아직 ios/Runner.xcodeproj, ios/Runner.xcworkspace, ios/Podfile이
# 없다(10/30 기준 확인). 맥에서 그 파일들을 만들고 커밋한 뒤에만 pod install 단계가
# 실제로 동작한다. docs/watch/XCODE-CLOUD.md 1번 참고.
set -euo pipefail

REPO_ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

# .metadata의 flutter revision과 맞춘다(channel: stable). 버전 숫자가 아니라
# 커밋 해시로 고정해 "같은 SDK인지" 추측하지 않게 한다.
FLUTTER_REVISION="c9a6c484230f8b5e408ec57be1ef71dee1e77020"
FLUTTER_ROOT="$HOME/flutter-sdk"

if [ ! -d "$FLUTTER_ROOT/.git" ]; then
  git clone --filter=blob:none https://github.com/flutter/flutter.git "$FLUTTER_ROOT"
fi

git -C "$FLUTTER_ROOT" fetch --tags origin
git -C "$FLUTTER_ROOT" checkout "$FLUTTER_REVISION"

export PATH="$FLUTTER_ROOT/bin:$PATH"

flutter precache --ios
flutter --version

cd "$REPO_ROOT"
flutter pub get

if [ -f "$REPO_ROOT/ios/Podfile" ]; then
  cd "$REPO_ROOT/ios"
  if ! command -v pod >/dev/null 2>&1; then
    gem install cocoapods --no-document
  fi
  pod install --repo-update
else
  echo "ios/Podfile 이 없다. 맥에서 Xcode 프로젝트를 먼저 생성하고 커밋해야 pod install이 돈다." >&2
fi
