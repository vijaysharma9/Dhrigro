#!/usr/bin/env bash
# Run Daily Rashan on iOS Simulator or Android Emulator (no Docker).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/apps/daily_rashan"
export PATH="/opt/homebrew/bin:/opt/homebrew/opt/openjdk@17/bin:$HOME/Library/Android/sdk/emulator:$HOME/Library/Android/sdk/platform-tools:$PATH"
export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk@17}"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"

TARGET="${1:-ios}"   # ios | android | chrome
ENTRY="${2:-lib/main.dart}"

cd "$APP"
flutter pub get

if [[ "$TARGET" == "ios" ]]; then
  if [[ ! -d /Applications/Xcode.app ]]; then
    echo "Install Xcode from the App Store, then run:"
    echo "  sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer"
    echo "  sudo xcodebuild -runFirstLaunch"
    echo "  brew install cocoapods"
    exit 1
  fi
  open -a Simulator
  sleep 5
  cd ios && pod install && cd ..
  # iOS Simulator can use localhost for API on the same Mac
  flutter run -d ios -t "$ENTRY"
elif [[ "$TARGET" == "android" ]]; then
  flutter emulators --launch Pixel_3a_API_34_extension_level_7_arm64-v8a || true
  echo "Waiting for emulator..."
  adb wait-for-device
  # Android emulator: host machine is 10.0.2.2, not localhost
  flutter run -d android -t "$ENTRY" \
    --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
else
  flutter run -d chrome -t "$ENTRY" --web-port=8080
fi
