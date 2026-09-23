# Redmi Note 13 Pro üzerinde yerel APK derleme

Bu akış APK'yı telefonun kendi Android/Termux ortamında üretir. GitHub Actions veya başka bir bulut derleyici kullanılmaz.

## Bir defalık hazırlık

Termux'u F-Droid veya resmi GitHub sürümünden kurun. Ardından Termux'ta:

```bash
termux-setup-storage
pkg update -y
pkg install -y git
cd ~
git clone -b native-android https://github.com/fruko2/ozel-kutuphane.git ozel-kutuphane
cd ~/ozel-kutuphane
chmod +x TERMUX_KUR_VE_DERLE.sh
bash TERMUX_KUR_VE_DERLE.sh
```

Android depolama izni sorulduğunda izin verin. İlk kurulum Flutter, Android SDK ve Gradle bileşenlerini indireceği için uzun sürebilir ve birkaç GB alan kullanabilir.

## Sonraki derlemeler

```bash
cd ~/ozel-kutuphane
git pull
bash TERMUX_KUR_VE_DERLE.sh
```

APK çıktısı:

```text
~/ozel-kutuphane/Kutuphane-i-Sahsi-arm64-release.apk
```

Depolama izni verilmişse ikinci kopya:

```text
/storage/emulated/0/Download/Kutuphane-i-Sahsi-arm64-release.apk
```

Hata halinde son 100 satır:

```bash
tail -n 100 ~/ozel-kutuphane/termux-derleme.log
```
