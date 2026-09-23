#!/usr/bin/env bash
set -Eeuo pipefail

APP_NAME="Kutuphane-i-Sahsi"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$PROJECT_DIR/ubuntu-derleme.log"

say() { printf '\n[%s] %s\n' "$APP_NAME" "$*"; }
die() { printf '\nHATA: %s\n' "$*" >&2; exit 1; }

[[ "$(uname -s)" == "Linux" ]] || die "Bu betik Ubuntu/Linux içindir."
if [[ "${PREFIX:-}" == */com.termux/* ]]; then
  die "Termux algılandı. Ubuntu terminalinde çalıştırın."
fi

if ! command -v flutter >/dev/null 2>&1 && [[ -x "$HOME/development/flutter/bin/flutter" ]]; then
  export PATH="$HOME/development/flutter/bin:$PATH"
fi

command -v flutter >/dev/null 2>&1 || die "Flutter bulunamadı. Beklenen yol: $HOME/development/flutter/bin/flutter"
command -v java >/dev/null 2>&1 || die "Java/JDK bulunamadı. Önce: sudo apt install -y openjdk-17-jdk"

FREE_KB="$(df -Pk "$HOME" | awk 'NR==2 {print $4}')"
if [[ "$FREE_KB" =~ ^[0-9]+$ ]] && (( FREE_KB < 6291456 )); then
  die "En az 6 GB boş disk alanı bırakın."
fi

AVAILABLE_KB="$(awk '/MemAvailable:/ {print $2}' /proc/meminfo)"
SWAP_KB="$(awk '/SwapFree:/ {print $2}' /proc/meminfo)"
if (( AVAILABLE_KB + SWAP_KB < 2097152 )); then
  die "Kullanılabilir RAM + swap 2 GB altında. Açık uygulamaları kapatın veya swap alanını artırın."
fi

exec > >(tee "$LOG_FILE") 2>&1
trap 'printf "\nDerleme kesildi. Günlük: %s\n" "$LOG_FILE" >&2' ERR

cd "$PROJECT_DIR"
say "Flutter ve Java sürümleri"
flutter --version
java -version

say "Flutter Android ortamı denetleniyor"
flutter doctor -v || true

if [[ ! -d android ]]; then
  say "Android platform dosyaları oluşturuluyor"
  flutter create --platforms=android --org com.qderm --project-name kutuphane_i_sahsi .
fi

cp "$PROJECT_DIR/scripts/AndroidManifest.xml" "$PROJECT_DIR/android/app/src/main/AndroidManifest.xml"

GRADLE_PROPERTIES="$PROJECT_DIR/android/gradle.properties"
touch "$GRADLE_PROPERTIES"
sed -i \
  -e '/^org\.gradle\.jvmargs=/d' \
  -e '/^org\.gradle\.workers\.max=/d' \
  -e '/^org\.gradle\.parallel=/d' \
  -e '/^org\.gradle\.daemon=/d' \
  -e '/^kotlin\.compiler\.execution\.strategy=/d' \
  "$GRADLE_PROPERTIES"
cat >> "$GRADLE_PROPERTIES" <<'EOF'
org.gradle.jvmargs=-Xmx1536m -XX:MaxMetaspaceSize=512m -Dfile.encoding=UTF-8
org.gradle.workers.max=1
org.gradle.parallel=false
org.gradle.daemon=false
kotlin.compiler.execution.strategy=in-process
android.useAndroidX=true
android.enableJetifier=true
EOF

export GRADLE_OPTS="-Dorg.gradle.daemon=false -Dorg.gradle.workers.max=1"

say "Paketler alınıyor"
flutter pub get

say "Kod analizi"
flutter analyze --no-fatal-infos

say "Birim testleri"
flutter test

say "ARM64 release APK derleniyor"
flutter build apk --release --target-platform android-arm64 --no-tree-shake-icons

SOURCE_APK="$PROJECT_DIR/build/app/outputs/flutter-apk/app-release.apk"
[[ -f "$SOURCE_APK" ]] || die "APK beklenen konumda bulunamadı: $SOURCE_APK"

mkdir -p "$PROJECT_DIR/dist"
FINAL_APK="$PROJECT_DIR/dist/${APP_NAME}-v1.1.0-arm64.apk"
cp -f "$SOURCE_APK" "$FINAL_APK"

say "APK üretildi"
ls -lh "$FINAL_APK"
sha256sum "$FINAL_APK" | tee "$FINAL_APK.sha256"
printf '\nAPK: %s\n' "$FINAL_APK"
