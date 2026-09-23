#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

pkg update -y
pkg install -y git curl wget unzip zip openjdk-17 proot-distro

echo
echo "Redmi Note 13 Pro ARM64 cihazında doğrudan Flutter derlemesi yüksek bellek tüketir."
echo "Önerilen akış: Kaynakları Termux'tan GitHub'a gönderin; Build Android APK işlemi APK'yı üretir."
echo "Yerel Flutter ortamınız zaten çalışıyorsa: bash build_app.sh"

