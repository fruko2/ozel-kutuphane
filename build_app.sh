#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

command -v flutter >/dev/null 2>&1 || { echo "Flutter PATH içinde bulunamadı." >&2; exit 1; }
command -v java >/dev/null 2>&1 || { echo "Java/JDK bulunamadı." >&2; exit 1; }

if [[ ! -d android ]]; then
  flutter create --platforms=android --org com.qderm --project-name kutuphane_i_sahsi .
fi

cp scripts/AndroidManifest.xml android/app/src/main/AndroidManifest.xml
flutter pub get
flutter analyze
flutter test test/isbn_test.dart
flutter build apk --release --target-platform android-arm64 --no-tree-shake-icons

APK="$PROJECT_DIR/build/app/outputs/flutter-apk/app-release.apk"
echo
echo "APK hazır: $APK"
ls -lh "$APK"

