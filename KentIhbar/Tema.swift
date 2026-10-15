import SwiftUI
import UIKit
import CoreText

// MARK: - Renk yardımcıları

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: alpha)
    }
}

extension Color {
    /// Açık / koyu temaya göre değişen renk (Kent İhbar tasarım sistemi tokenları).
    init(acik: UInt32, koyu: UInt32) {
        self.init(UIColor { trait in
            UIColor(hex: trait.userInterfaceStyle == .dark ? koyu : acik)
        })
    }
}

// MARK: - Tokenlar (tasarım sistemindeki tokens.json ile birebir)

enum KI {
    // Zemin & yüzey
    static let zemin = Color(acik: 0xF8FAFC, koyu: 0x0B0F17)
    static let yuzey = Color(acik: 0xFFFFFF, koyu: 0x131B2E)
    static let yuzeyUst = Color(acik: 0xEEF2F8, koyu: 0x1B2540)
    static let cizgi = Color(acik: 0xE2E8F0, koyu: 0x26314D)
    static let cizgiKontrol = Color(acik: 0x7C8BA1, koyu: 0x5E6E8E)

    // Metin
    static let metin = Color(acik: 0x0F172A, koyu: 0xF8FAFC)
    static let metinIkincil = Color(acik: 0x475569, koyu: 0x94A3B8)
    static let metinSoluk = Color(acik: 0x64748B, koyu: 0x7D8BA6)

    // Marka
    static let maviRenk = Color(acik: 0x3F97FF, koyu: 0x3F97FF)
    static let maviBayaz = Color(acik: 0xFFFFFF, koyu: 0xFFFFFF)
    static let birincil = Color(acik: 0x2563EB, koyu: 0x3F97FF)
    static let birincilBasili = Color(acik: 0x1D4ED8, koyu: 0x6AAEFF)
    static let onBirincil = Color(acik: 0xFFFFFF, koyu: 0x0B0F17)
    static let birincilYumusak = Color(acik: 0xDBEAFE, koyu: 0x172554)
    static let birincilMetin = Color(acik: 0x1D4ED8, koyu: 0x93C5FD)
    static let vurgu = Color(acik: 0x0E7490, koyu: 0x06B6D4)
    static let vurguYumusak = Color(acik: 0xCFFAFE, koyu: 0x0A2A33)

    // Durum
    static let kritik = Color(acik: 0xB91C1C, koyu: 0xF87171)
    static let kritikYumusak = Color(acik: 0xFEE2E2, koyu: 0x3A1418)
    static let beklemede = Color(acik: 0xB45309, koyu: 0xFBBF24)
    static let beklemedeYumusak = Color(acik: 0xFEF3C7, koyu: 0x36290A)
    static let cozuldu = Color(acik: 0x047857, koyu: 0x34D399)
    static let cozulduYumusak = Color(acik: 0xD1FAE5, koyu: 0x0B2E24)
    static let onDurum = Color(acik: 0xFFFFFF, koyu: 0x0B0F17)
    static let odakHalkasi = Color(acik: 0x2563EB, koyu: 0x93C5FD)

    // Boşluk
    static let space1: CGFloat = 4
    static let space2: CGFloat = 8
    static let space3: CGFloat = 12
    static let space4: CGFloat = 16
    static let space5: CGFloat = 20
    static let space6: CGFloat = 24
    static let space8: CGFloat = 32

    // Köşe
    static let radiusSm: CGFloat = 10
    static let radiusMd: CGFloat = 14
    static let radiusLg: CGFloat = 20

    // Hareket
    static let sureHizli = 0.15
    static let sureOrta = 0.25
    static let sureYavas = 0.40
    static let egriStandart = Animation.timingCurve(0.2, 0, 0, 1, duration: 0.25)
    static let yay = Animation.spring(response: 0.35, dampingFraction: 0.6)
}

// MARK: - Tipografi (Lexend başlık, Figtree gövde)

enum KIFont {
    static let dosyalar = ["Lexend-Regular", "Lexend-SemiBold",
                           "Figtree-Regular", "Figtree-Medium", "Figtree-SemiBold", "Figtree-Bold"]

    /// Uygulama açılışında font dosyalarını kaydeder (Info.plist'e gerek kalmadan).
    static func kaydet() {
        for ad in dosyalar {
            if let url = Bundle.main.url(forResource: ad, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }

    static func baslik(_ boyut: CGFloat, kalin: Bool = true) -> Font {
        .custom(kalin ? "Lexend-SemiBold" : "Lexend-Regular", size: boyut)
    }

    enum Agirlik { case normal, orta, yariKalin, kalin }

    static func govde(_ boyut: CGFloat, _ agirlik: Agirlik = .normal) -> Font {
        let ad: String
        switch agirlik {
        case .normal: ad = "Figtree-Regular"
        case .orta: ad = "Figtree-Medium"
        case .yariKalin: ad = "Figtree-SemiBold"
        case .kalin: ad = "Figtree-Bold"
        }
        return .custom(ad, size: boyut)
    }

    // Tasarım sistemi stilleri
    static let ekranBasligi = baslik(28)
    static let bolumBasligi = baslik(20)
    static let kartBasligi = baslik(17)
    static let sayiBuyuk = baslik(32)
    static let govdeMetni = govde(16)
    static let govdeKucuk = govde(14)
    static let dugme = govde(16, .yariKalin)
    static let etiket = govde(13, .yariKalin)
    static let altYazi = govde(12, .orta)
}

// MARK: - Gölgeler

struct KartStili: ViewModifier {
    var dolgu: CGFloat
    var koseYaricap: CGFloat
    @Environment(\.colorScheme) private var sema

    func body(content: Content) -> some View {
        content
            .padding(dolgu)
            .background(KI.yuzey, in: RoundedRectangle(cornerRadius: koseYaricap, style: .continuous))
            .overlay {
                if sema == .dark {
                    RoundedRectangle(cornerRadius: koseYaricap, style: .continuous)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                }
            }
            .shadow(color: .black.opacity(sema == .dark ? 0.35 : 0.06),
                    radius: sema == .dark ? 12 : 9, x: 0, y: sema == .dark ? 8 : 6)
    }
}

struct SertGolge: ViewModifier {
    @Environment(\.colorScheme) private var sema
    func body(content: Content) -> some View {
        content.shadow(color: .black.opacity(sema == .dark ? 0.5 : 0.2), radius: 1, x: 3, y: 3)
    }
}

extension View {
    /// `yuzey` zemin + `golge-kart`
    func kart(dolgu: CGFloat = KI.space5, kose: CGFloat = KI.radiusLg) -> some View {
        modifier(KartStili(dolgu: dolgu, koseYaricap: kose))
    }

    /// Kullanıcı tanımlı `golge` tokenı — harita üzerindeki yüzen kontroller
    func sertGolge() -> some View { modifier(SertGolge()) }

    /// `mavi-yansima`: mavi dış parlama
    func maviYansima(_ aktif: Bool = true) -> some View {
        shadow(color: KI.maviRenk.opacity(aktif ? 0.40 : 0), radius: 12, x: 0, y: 10)
    }
}

/// Üst yarıda ince beyaz ışık — `mavi-yansima`nın yansıma katmanı.
struct YansimaIsigi: View {
    var body: some View {
        LinearGradient(stops: [.init(color: .white.opacity(0.22), location: 0),
                               .init(color: .white.opacity(0), location: 0.5)],
                       startPoint: .top, endPoint: .bottom)
            .allowsHitTesting(false)
    }
}
