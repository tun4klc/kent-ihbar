# Kent İhbar

Mahalledeki sorunları (çukur, kırık lamba, çöp vb.) fotoğraf ve konumla ihbar etmeye yarayan SwiftUI iOS uygulaması.

## Gereksinimler

| Gereksinim | Sürüm |
|---|---|
| macOS | Xcode 16'yı çalıştırabilen bir sürüm (macOS 14.5 veya üstü) |
| Xcode | **16.0 veya üstü** (proje formatı Xcode 16 gerektirir) |
| iOS | **17.0 veya üstü** (simülatör ya da gerçek cihaz) |
| İnternet | İlk açılışta Swift paketini indirmek için |

Bağımlılık olarak yalnızca [Lottie](https://github.com/airbnb/lottie-spm) (4.6.1) kullanılıyor. Swift Package Manager ile otomatik indirildiği için CocoaPods ya da başka bir araç kurmanız gerekmez. API anahtarı veya `.env` dosyası da gerekmiyor.

## Kurulum ve çalıştırma

1. Repoyu indirin:
   ```bash
   git clone https://github.com/tun4klc/kent-ihbar.git
   cd kent-ihbar
   ```
   (ya da GitHub'da **Code → Download ZIP** ile indirip zip'i açın)
2. `KentIhbar.xcodeproj` dosyasını Xcode ile açın.
3. Xcode Lottie paketini kendiliğinden indirir. Bu birkaç dakika sürebilir; sol alttaki *Resolving Package Graph* işi bitene kadar bekleyin.
4. Üst çubuktan **KentIhbar** şemasını ve bir **iPhone simülatörü** seçin.
5. **⌘R** ile çalıştırın.

### Gerçek iPhone'da çalıştırmak için

1. Sol panelden **KentIhbar** projesini → **KentIhbar** hedefini → **Signing & Capabilities** sekmesini açın.
2. **Team** kısmından kendi Apple hesabınızı seçin (ücretsiz Apple ID yeterli).
3. **Bundle Identifier** değerini size özel bir değerle değiştirin, örneğin `com.adiniz.kentihbar`. Mevcut `com.tunakilic.kentihbar` başka bir hesaba kayıtlı olduğu için sizde imzalanmaz.
4. iPhone'u bağlayıp seçin ve çalıştırın. Cihazda ilk açılışta *Ayarlar → Genel → VPN ve Cihaz Yönetimi* menüsünden geliştiriciye güvenmeniz gerekebilir.

### Komut satırından derleme (isteğe bağlı)

```bash
xcodebuild -project KentIhbar.xcodeproj -scheme KentIhbar \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
```

## Notlar

- Uygulama konum izni ister. Simülatörde konumu **Features → Location** menüsünden ayarlayabilirsiniz.
- Fontlar (Figtree, Lexend) `KentIhbar/Fonts` klasöründe bulunur ve uygulama açılırken yüklenir. Ek bir kurulum gerekmez.

## Sorun giderme

- **"Missing package product 'Lottie'"**: *File → Packages → Reset Package Caches*, ardından *Resolve Package Versions*.
- **"Signing for KentIhbar requires a development team"**: Yukarıdaki *Gerçek iPhone'da çalıştırmak için* adımlarını uygulayın. Simülatörde bu hata çıkmaz.
- **Proje açılmıyor / "future Xcode version"**: Xcode'u 16 veya üstüne güncelleyin.
