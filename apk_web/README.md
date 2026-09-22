# Kütüphane-i Şahsî Android APK

Bu klasör, yayındaki web kütüphanesini Android'in tarayıcı oturumunu paylaşan uygulama içi tarayıcı görünümünde açan ayrı bir Flutter projesidir. Aynı Google hesabıyla giriş yapıldığında kitaplar ve Firebase eşitlemesi web uygulamasındaki gibidir. Eski kök Flutter/SQLite projesi ayrı bir uygulamadır; bu APK onun yerel veritabanını kullanmaz.

## Ubuntu üzerinde derleme

1. Flutter (Dart ile birlikte), Android SDK ve JDK 17 kurun. `flutter doctor -v` içinde Android toolchain çalışır durumda olmalı; Android lisanslarını gerekirse `flutter doctor --android-licenses` ile onaylayın.
2. Depoyu indirin veya güncelleyin: `git clone https://github.com/fruko2/ozel-kutuphane.git` (zaten indirilmişse depoda `git pull`).
3. Depo kökünde `bash apk_web/build_app.sh` çalıştırın.
4. APK dosyası: `apk_web/build/app/outputs/flutter-apk/app-release.apk`.

Uygulama kimliği `com.qderm.kutuphane_web`. İlk açılışta uygulama içi tarayıcı kütüphaneyi yükler; kapatılırsa “Kütüphaneyi aç” düğmesiyle yeniden açılır. Bu paket yayındaki siteye, internet bağlantısına ve telefonda uygulama içi tarayıcı desteğine bağlıdır. Destek yoksa varsayılan tarayıcı açılır. Chrome Custom Tabs araç çubuğu görünebilir. Web sitesinin çevrimdışı çalışması veya tam ekran bağımsız Android deneyimi bu paketle garanti edilmez.

## Telefonda kontrol

- Google ile giriş yapıp aynı kitapları gördüğünüzü doğrulayın.
- Barkod okuyucunun kamerayı açtığını ve kitabı bulduğunu deneyin.
- Aynı ISBN'yi yeniden okuttuğunuzda yeni kayıt yerine mevcut eserin açıldığını doğrulayın.
- Yazar sayfasındaki biyografi ve eser adlarını kontrol edin.

Bu kaynaklar hazırlanmıştır; APK'nın çalışması için gerçek Android cihazda giriş ve kamera denemesi gerekir.

## Derleme yarıda kesilirse

`assembleRelease` sırasında 143 kodu işlemin SIGTERM ile, terminalde “Sinyal 9” görünmesi ise terminal işleminin SIGKILL ile sonlandığını gösterir. İkisi de tek başına bellek yetersizliğini kanıtlamaz. Betik Gradle belleğini ve eşzamanlı çalışan iş sayısını sınırlar. İlk derleme indirmeler nedeniyle uzun sürebilir; terminal açık kalmalıdır. İşlem yine kesilirse şu çıktıları paylaşın:

```bash
cd ~/ozel-kutuphane
free -h
swapon --show
df -h .
tail -n 60 apk_web/build_app.log
```

`git pull` ile güncel betiği aldıktan sonra yeniden `bash apk_web/build_app.sh` çalıştırabilirsiniz. Betik mevcut derleme önbelleğini silmez.
