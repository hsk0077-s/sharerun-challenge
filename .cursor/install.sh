#!/usr/bin/env bash
# Idempotent Cloud Agent bootstrap for Share Run Challenge.
# Sets up the Python FastAPI backend (backend/jena_ai) and the Flutter app.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

FLUTTER_VERSION="3.47.3"
FLUTTER_DIR="$HOME/flutter"

echo "==> Ensuring Flutter $FLUTTER_VERSION is installed"
if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  curl -L --retry 5 --fail -o /tmp/flutter.tar.xz \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
  rm -rf "$FLUTTER_DIR"
  tar -xf /tmp/flutter.tar.xz -C "$HOME"
  rm -f /tmp/flutter.tar.xz
fi

# Flutter ships as a git checkout; mark it safe and expose it on PATH for agent shells.
git config --global --add safe.directory "$FLUTTER_DIR" || true
sudo ln -sf "$FLUTTER_DIR/bin/flutter" /usr/local/bin/flutter
sudo ln -sf "$FLUTTER_DIR/bin/dart" /usr/local/bin/dart

export PATH="$FLUTTER_DIR/bin:$PATH"
flutter config --no-analytics >/dev/null 2>&1 || true

echo "==> Creating local .env (safe emulator/mock defaults) if missing"
[ -f .env ] || cp .env.example .env

echo "==> Installing backend Python dependencies"
python3 -m pip install --break-system-packages -q -r backend/jena_ai/requirements-dev.txt

echo "==> Fetching Flutter package dependencies"
flutter pub get

echo "==> Install complete"
