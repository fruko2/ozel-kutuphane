# Ubuntu üzerinde APK derleme

Bu yöntem APK'yı doğrudan Ubuntu bilgisayarda üretir.

## Kaynağı ayrı klasöre alın

```bash
export PATH="$HOME/development/flutter/bin:$PATH"
cd "$HOME"
git clone -b native-android https://github.com/fruko2/ozel-kutuphane.git ozel-kutuphane-ubuntu
cd "$HOME/ozel-kutuphane-ubuntu"
chmod +x UBUNTU_KUR_VE_DERLE.sh
bash UBUNTU_KUR_VE_DERLE.sh
```

Betik Flutter/Java/Android ortamını denetler, Gradle bellek kullanımını sınırlar,
analiz ve testleri çalıştırır, ardından ARM64 release APK üretir.

APK çıktısı:

```text
~/ozel-kutuphane-ubuntu/dist/Kutuphane-i-Sahsi-v1.1.0-arm64.apk
```

Bir hata oluşursa:

```bash
tail -n 120 ~/ozel-kutuphane-ubuntu/ubuntu-derleme.log
```
