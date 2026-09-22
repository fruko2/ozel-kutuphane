#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v flutter >/dev/null 2>&1; then
  echo 'Flutter bulunamadı. Önce flutter doctor -v ile kurulumu kontrol edin.' >&2
  exit 1
fi
if ! command -v java >/dev/null 2>&1; then
  echo 'Java bulunamadı. JDK 17 ve Android SDK kurulumu gerekli.' >&2
  exit 1
fi

flutter create --platforms=android --org com.qderm --project-name kutuphane_web .
python3 scripts/configure_android.py
flutter pub get
flutter analyze --no-fatal-infos lib/main.dart
flutter build apk --release --target-platform android-arm64
echo "APK: $(pwd)/build/app/outputs/flutter-apk/app-release.apk"
