#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

# Kütüphane-i Şahsî — Redmi Note 13 Pro / Termux ARM64 yerel APK derleyicisi.
# Derleme telefonda gerçekleşir; GitHub Actions veya başka bulut kullanılmaz.

APP_NAME="Kutuphane-i-Sahsi"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$PROJECT_DIR/termux-derleme.log"
ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$PREFIX/opt/android-sdk}"
ANDROID_HOME="$ANDROID_SDK_ROOT"
FLUTTER_HOME="${FLUTTER_HOME:-$PREFIX/opt/flutter}"
export ANDROID_SDK_ROOT ANDROID_HOME FLUTTER_HOME
export PATH="$FLUTTER_HOME/bin:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"
export PUB_CACHE="${PUB_CACHE:-$HOME/.pub-cache}"
export GRADLE_OPTS="-Dorg.gradle.daemon=false -Dorg.gradle.workers.max=1 -Dkotlin.compiler.execution.strategy=in-process"

say() { printf '\n[%s] %s\n' "$APP_NAME" "$*"; }
die() { printf '\nHATA: %s\n' "$*" >&2; exit 1; }

if [[ "${PREFIX:-}" != */com.termux/* ]]; then
  die "Bu betik yalnızca Android üzerindeki Termux içinde çalıştırılmalıdır."
fi

ARCH="$(uname -m)"
[[ "$ARCH" == "aarch64" ]] || die "ARM64/aarch64 cihaz gerekli. Algılanan mimari: $ARCH"

ANDROID_RELEASE="$(getprop ro.build.version.release 2>/dev/null || true)"
ANDROID_MAJOR="${ANDROID_RELEASE%%.*}"
if [[ "$ANDROID_MAJOR" =~ ^[0-9]+$ ]] && (( ANDROID_MAJOR >= 14 )); then
  die "Algılanan Android $ANDROID_RELEASE. Kullanılan Termux Flutter ARM64 dağıtımı Android 14+ ile uyumlu değil."
fi

case "$PROJECT_DIR" in
  /sdcard/*|/storage/*) die "Projeyi ortak depolamada derlemeyin. Önce ~/ozel-kutuphane klasörüne taşıyın." ;;
esac

FREE_KB="$(df -Pk "$HOME" | awk 'NR==2 {print $4}')"
if [[ "$FREE_KB" =~ ^[0-9]+$ ]] && (( FREE_KB < 7340032 )); then
  die "En az 7 GB boş alan gerekli. Termux ana diziminde yeterli boş alan görünmüyor."
fi

exec > >(tee -a "$LOG_FILE") 2>&1
trap 'printf "\nDerleme kesildi. Ayrıntı: %s\n" "$LOG_FILE" >&2' ERR

say "Android $ANDROID_RELEASE / $ARCH doğrulandı. Paketler hazırlanıyor."
pkg update -y
pkg install -y x11-repo
pkg install -y curl jq git unzip zip openjdk-17 clang cmake ninja make pkg-config

download_latest_deb() {
  local repo="$1"
  local name_pattern="$2"
  local output="$3"
  local url
  url="$(curl --fail --silent --show-error --location "https://api.github.com/repos/$repo/releases/latest" |
    jq -r --arg p "$name_pattern" '.assets[] | select(.name | test($p; "i")) | .browser_download_url' |
    head -n 1)"
  [[ -n "$url" && "$url" != "null" ]] || die "$repo için uygun .deb paketi bulunamadı."
  curl --fail --location --retry 3 --continue-at - --output "$output" "$url"
}

TMP_DIR="$(mktemp -d "$PREFIX/tmp/kutuphane-build.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

if ! command -v flutter >/dev/null 2>&1; then
  say "Termux ARM64 Flutter paketi indiriliyor."
  download_latest_deb "mumumusuc/termux-flutter" '^flutter_.*_(aarch64|arm64)\.deb$' "$TMP_DIR/flutter.deb"
  apt install -y "$TMP_DIR/flutter.deb"
fi

if [[ ! -d "$ANDROID_SDK_ROOT/build-tools" ]]; then
  say "Termux ARM64 Android SDK paketi indiriliyor (büyük dosyadır)."
  download_latest_deb "mumumusuc/termux-android-sdk" '^android-sdk_.*_(aarch64|arm64)\.deb$' "$TMP_DIR/android-sdk.deb"
  apt install -y "$TMP_DIR/android-sdk.deb"
fi

command -v flutter >/dev/null 2>&1 || die "Flutter kurulamadı."
[[ -d "$ANDROID_SDK_ROOT" ]] || die "Android SDK bulunamadı: $ANDROID_SDK_ROOT"

JAVA_BIN="$(readlink -f "$(command -v javac)")"
export JAVA_HOME="$(dirname "$(dirname "$JAVA_BIN")")"

say "Flutter ve Android SDK yapılandırılıyor."
flutter config --android-sdk "$ANDROID_SDK_ROOT"
flutter config --no-analytics
flutter precache --android

cd "$PROJECT_DIR"
if [[ ! -d android ]]; then
  say "Android platform dosyaları oluşturuluyor."
  flutter create --platforms=android --org com.qderm --project-name kutuphane_i_sahsi .
fi

AAPT2="$(find "$ANDROID_SDK_ROOT/build-tools" -type f -name aapt2 2>/dev/null | sort -V | tail -n 1)"
[[ -x "$AAPT2" ]] || die "ARM64 aapt2 bulunamadı. Android SDK paketini denetleyin."

GRADLE_PROPERTIES="$PROJECT_DIR/android/gradle.properties"
touch "$GRADLE_PROPERTIES"
sed -i \
  -e '/^org\.gradle\.jvmargs=/d' \
  -e '/^org\.gradle\.workers\.max=/d' \
  -e '/^org\.gradle\.parallel=/d' \
  -e '/^org\.gradle\.daemon=/d' \
  -e '/^kotlin\.compiler\.execution\.strategy=/d' \
  -e '/^android\.aapt2FromMavenOverride=/d' \
  "$GRADLE_PROPERTIES"
cat >> "$GRADLE_PROPERTIES" <<EOF
org.gradle.jvmargs=-Xmx2048m -XX:MaxMetaspaceSize=512m -Dfile.encoding=UTF-8
org.gradle.workers.max=1
org.gradle.parallel=false
org.gradle.daemon=false
kotlin.compiler.execution.strategy=in-process
android.aapt2FromMavenOverride=$AAPT2
android.useAndroidX=true
android.enableJetifier=true
EOF

MANIFEST="$PROJECT_DIR/android/app/src/main/AndroidManifest.xml"
if ! grep -q 'android.permission.CAMERA' "$MANIFEST"; then
  sed -i '/<manifest/a\    <uses-permission android:name="android.permission.CAMERA" />\n    <uses-permission android:name="android.permission.INTERNET" />' "$MANIFEST"
fi

command -v termux-wake-lock >/dev/null 2>&1 && termux-wake-lock || true

say "Bağımlılıklar alınıyor. İlk çalıştırma uzun sürebilir."
flutter pub get

say "Kod denetimi çalıştırılıyor."
flutter analyze --no-fatal-infos

say "Release APK telefonda ARM64 için derleniyor. Uygulamayı arka plana atmayın."
flutter build apk --release --target-platform android-arm64

APK="$PROJECT_DIR/build/app/outputs/flutter-apk/app-release.apk"
[[ -f "$APK" ]] || die "Derleme bitti fakat APK beklenen konumda bulunamadı."
FINAL_APK="$PROJECT_DIR/${APP_NAME}-arm64-release.apk"
cp -f "$APK" "$FINAL_APK"

if [[ -d /storage/emulated/0/Download ]]; then
  cp -f "$FINAL_APK" "/storage/emulated/0/Download/${APP_NAME}-arm64-release.apk" 2>/dev/null || true
fi
command -v termux-wake-unlock >/dev/null 2>&1 && termux-wake-unlock || true

say "APK yolu: $FINAL_APK"
if [[ -f "/storage/emulated/0/Download/${APP_NAME}-arm64-release.apk" ]]; then
  say "İndirmeler klasörüne de kopyalandı: /storage/emulated/0/Download/${APP_NAME}-arm64-release.apk"
fi
