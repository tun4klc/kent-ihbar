# Kent İhbar — Flutter sürümü

SwiftUI uygulamasının (`../KentIhbar`) birebir Flutter karşılığı. Aynı ekranlar, renk tokenları, fontlar (Lexend + Figtree), robot animasyonu (`robot.json`) ve örnek veri kullanılıyor. Tek fark, iOS'un yanında Android'de de çalışması.

## Gereksinimler

| Gereksinim | Sürüm |
|---|---|
| Flutter | **3.47 veya üstü** (Dart 3.13+), stable kanal — bu sürümle test edildi |
| iOS için | macOS + Xcode 16 veya üstü, CocoaPods; iOS 15+ |
| Android için | Android Studio / Android SDK; Android 7.0 (API 24) ve üstü |
| İnternet | Paketleri indirmek ve harita karolarını yüklemek için |

API anahtarı ya da `.env` dosyası gerekmiyor. Harita karoları OpenStreetMap'ten anahtarsız olarak geliyor.

Kurulumu kontrol etmek için:

```bash
flutter doctor
```

## Kurulum ve çalıştırma

```bash
git clone https://github.com/tun4klc/kent-ihbar.git
cd kent-ihbar/kent_ihbar_flutter
flutter pub get
flutter run
```

`flutter run` açık bir simülatör, emülatör ya da bağlı bir cihaz bulamazsa önce birini açın:

- **iOS simülatörü:** `open -a Simulator`
- **Android emülatörü:** `flutter emulators --launch <ad>`. Listeyi görmek için önce `flutter emulators` komutunu çalıştırın.

Birden fazla cihaz bağlıysa `flutter devices` ile kimliği bulup `flutter run -d <kimlik>` ile seçin.

### Gerçek iPhone'da çalıştırma

1. `ios/Runner.xcworkspace` dosyasını Xcode ile açın.
2. **Runner** hedefinde **Signing & Capabilities** sekmesine gidin, **Team** kısmında kendi Apple hesabınızı seçin.
3. **Bundle Identifier** değerini size özel bir değerle değiştirin, örneğin `com.adiniz.kentihbar`.
4. Terminale dönüp `flutter run` çalıştırın.

## Testler

```bash
flutter analyze
flutter test
```

## Klasör yapısı

```
lib/
  main.dart            uygulama girişi, tema ve oturuma göre kök ekran
  tema.dart            renk/boşluk/köşe tokenları, tipografi, gölgeler, Kart
  model.dart           Oturum, Durum, Kategori, Ihbar, Belediye, örnek veri, Türkçe biçimlendirme
  konum.dart           konum izni ve son konum (geolocator)
  kapsam.dart          durumun widget ağacına verilmesi (InheritedNotifier)
  bilesenler.dart      ortak bileşenler (düğmeler, çipler, segment, girdi kutusu…)
  harita_pini.dart     süzülen, dönen, dalga yayan damla pin
  ekranlar/            giriş, ana kabuk, ana sayfa, harita, sıralama, profil, yeni ihbar, sohbet, robot
assets/                fontlar, robot.json, uygulama ikonu
tool/onizleme.dart     tek bir ekranı doğrudan açan geliştirme önizlemesi
```

Belirli bir ekranı giriş yapmadan açmak için (ekran görüntüsü almak gibi işler için):

```bash
flutter run -t tool/onizleme.dart --dart-define=EKRAN=harita --dart-define=KOYU=true
# EKRAN: giris | dogrulama | ana | harita | siralama | profil | yeni | sohbet
```

## Notlar

- Doğrulama ekranında `000000` dışındaki her 6 haneli kod kabul edilir. Prototip olduğu için gerçek bir SMS gönderilmez.
- Bundle ID / applicationId `com.tunakilic.kentihbar.flutter` olarak ayarlı. SwiftUI sürümünden (`com.tunakilic.kentihbar`) farklı olduğu için iki sürüm aynı cihazda birbirini ezmeden yan yana kurulabilir.
- Uygulama ikonunu değiştirdikten sonra `dart run flutter_launcher_icons` çalıştırın.
- Harita, SwiftUI sürümündeki Apple Maps yerine `flutter_map` ve OpenStreetMap ile çiziliyor. Böylece iki platformda da anahtar gerekmiyor.

## Sorun giderme

- **`CocoaPods not installed`**: `brew install cocoapods` (ya da `sudo gem install cocoapods`), ardından `cd ios && pod install`.
- **Android lisans uyarısı**: `flutter doctor --android-licenses` çalıştırıp lisansları kabul edin.
- **Harita gri görünüyor**: Cihazın internet bağlantısını kontrol edin. Karolar OpenStreetMap'ten indiriliyor.
- **Bağımlılık hatası**: `flutter clean && flutter pub get`.
