import SwiftUI
import UIKit
import CoreLocation

// MARK: - Oturum

enum Oturum: Equatable {
    case yok
    case misafir
    case uye(telefon: String)
}

final class UygulamaDurumu: ObservableObject {
    @Published var oturum: Oturum = .yok
    @Published var ihbarlar: [Ihbar] = OrnekVeri.ihbarlar

    var girisGerekli: Bool { oturum == .yok }
    var uyeMi: Bool {
        if case .uye = oturum { return true }
        return false
    }

    func ihbarEkle(_ ihbar: Ihbar) {
        ihbarlar.insert(ihbar, at: 0)
    }
}

// MARK: - Durum & kategori

enum Durum: String, CaseIterable, Identifiable, Hashable {
    case kritik, beklemede, cozuldu
    var id: String { rawValue }

    var ad: String {
        switch self {
        case .kritik: return "Kritik"
        case .beklemede: return "Beklemede"
        case .cozuldu: return "Çözüldü"
        }
    }
    var renk: Color {
        switch self {
        case .kritik: return KI.kritik
        case .beklemede: return KI.beklemede
        case .cozuldu: return KI.cozuldu
        }
    }
    var yumusak: Color {
        switch self {
        case .kritik: return KI.kritikYumusak
        case .beklemede: return KI.beklemedeYumusak
        case .cozuldu: return KI.cozulduYumusak
        }
    }
    /// Renk körlüğü için her durum kendi ikonunu taşır.
    var ikon: String {
        switch self {
        case .kritik: return "exclamationmark.triangle.fill"
        case .beklemede: return "clock"
        case .cozuldu: return "checkmark"
        }
    }
}

enum Kategori: String, CaseIterable, Identifiable, Hashable {
    case yolCukuru, cop, lamba, su, park, diger
    var id: String { rawValue }

    var ad: String {
        switch self {
        case .yolCukuru: return "Yol Çukuru"
        case .cop: return "Çöp Birikintisi"
        case .lamba: return "Bozuk Lamba"
        case .su: return "Su Sızıntısı"
        case .park: return "Park & Yeşil"
        case .diger: return "Diğer"
        }
    }
    var ikon: String {
        switch self {
        case .yolCukuru: return "exclamationmark.triangle"
        case .cop: return "trash"
        case .lamba: return "lightbulb"
        case .su: return "drop"
        case .park: return "leaf"
        case .diger: return "square.grid.2x2"
        }
    }
    /// Kategori kutusundaki ikon rengi (Şehir İhbar'daki renk ailesi, Kent İhbar tonlarında).
    var renk: Color {
        switch self {
        case .yolCukuru: return Color(acik: 0xC2410C, koyu: 0xFB923C)
        case .cop: return Color(acik: 0x047857, koyu: 0x34D399)
        case .lamba: return Color(acik: 0xB45309, koyu: 0xFBBF24)
        case .su: return KI.birincilMetin
        case .park: return Color(acik: 0x0F766E, koyu: 0x2DD4BF)
        case .diger: return Color(acik: 0x6D28D9, koyu: 0xA78BFA)
        }
    }
    var yumusak: Color {
        switch self {
        case .yolCukuru: return Color(acik: 0xFFEDD5, koyu: 0x3A2010)
        case .cop: return Color(acik: 0xD1FAE5, koyu: 0x0B2E24)
        case .lamba: return Color(acik: 0xFEF3C7, koyu: 0x36290A)
        case .su: return KI.birincilYumusak
        case .park: return Color(acik: 0xCCFBF1, koyu: 0x0A2E2A)
        case .diger: return Color(acik: 0xEDE9FE, koyu: 0x221A40)
        }
    }
}

struct Ihbar: Identifiable {
    let id = UUID()
    var kategori: Kategori
    var durum: Durum
    var aciklama: String
    var adres: String
    var koordinat: CLLocationCoordinate2D
    var tarih: Date
    var foto: UIImage? = nil
    var benim = false
}

struct Belediye: Identifiable {
    let id = UUID()
    let ad: String
    let sehir: String
    let ortalamaGun: Double
    let memnuniyet: Int
    let aylikCozum: Int
    let puan: Double
    var senin: Bool = false

    /// "Nilüfer Belediyesi" → "Nilüfer"
    var kisaAd: String { ad.replacingOccurrences(of: " Belediyesi", with: "") }
    /// "Nilüfer" → "Nİ"
    var basHarfler: String { String(kisaAd.prefix(2)).uppercased(with: Locale(identifier: "tr_TR")) }
}

// MARK: - Örnek veri

enum OrnekVeri {
    static let bornova = CLLocationCoordinate2D(latitude: 38.4697, longitude: 27.2211)

    static let ihbarlar: [Ihbar] = {
        let simdi = Date()
        func k(_ lat: Double, _ lon: Double) -> CLLocationCoordinate2D { .init(latitude: lat, longitude: lon) }
        return [
            Ihbar(kategori: .yolCukuru, durum: .kritik, aciklama: "Kavşakta derin çukur, araçlar şerit değiştiriyor.",
                  adres: "Kazımdirik Mah., 372. Sk.", koordinat: k(38.4635, 27.2170), tarih: simdi.addingTimeInterval(-3 * 3600)),
            Ihbar(kategori: .lamba, durum: .beklemede, aciklama: "Parkın girişindeki iki lamba yanmıyor.",
                  adres: "Erzene Mah., Ankara Cd.", koordinat: k(38.4560, 27.2215), tarih: simdi.addingTimeInterval(-20 * 3600)),
            Ihbar(kategori: .cop, durum: .beklemede, aciklama: "Konteyner taşmış, üç gündür alınmadı.",
                  adres: "Mevlana Mah., 1736. Sk.", koordinat: k(38.4748, 27.2105), tarih: simdi.addingTimeInterval(-50 * 3600)),
            Ihbar(kategori: .su, durum: .cozuldu, aciklama: "Kaldırımdan sürekli su sızıyordu.",
                  adres: "Kızılay Mah., 6. Sk.", koordinat: k(38.4682, 27.2290), tarih: simdi.addingTimeInterval(-5 * 86400)),
            Ihbar(kategori: .yolCukuru, durum: .kritik, aciklama: "Rögar kapağı yerinden çıkmış.",
                  adres: "Doğanlar Mah., Gazi Cd.", koordinat: k(38.4790, 27.2330), tarih: simdi.addingTimeInterval(-6 * 3600)),
            Ihbar(kategori: .lamba, durum: .cozuldu, aciklama: "Sokak lambası yanıp sönüyordu.",
                  adres: "Atatürk Mah., 115. Sk.", koordinat: k(38.4600, 27.2350), tarih: simdi.addingTimeInterval(-9 * 86400)),
            Ihbar(kategori: .cop, durum: .kritik, aciklama: "Pazar yeri sonrası çöpler toplanmadı.",
                  adres: "Çamdibi Mah., 4. Sk.", koordinat: k(38.4530, 27.2080), tarih: simdi.addingTimeInterval(-10 * 3600))
        ]
    }()

    static let belediyeler: [Belediye] = [
        // Liste ve puanlar Şehir İhbar prototipinden (Ekim 2026).
        Belediye(ad: "Nilüfer Belediyesi", sehir: "Bursa", ortalamaGun: 1.9, memnuniyet: 95, aylikCozum: 1180, puan: 96.2),
        Belediye(ad: "Çankaya Belediyesi", sehir: "Ankara", ortalamaGun: 2.2, memnuniyet: 93, aylikCozum: 1410, puan: 94.8),
        Belediye(ad: "Kadıköy Belediyesi", sehir: "İstanbul", ortalamaGun: 2.1, memnuniyet: 91, aylikCozum: 1240, puan: 93.1),
        Belediye(ad: "Karşıyaka Belediyesi", sehir: "İzmir", ortalamaGun: 2.6, memnuniyet: 90, aylikCozum: 690, puan: 91.7),
        Belediye(ad: "Tepebaşı Belediyesi", sehir: "Eskişehir", ortalamaGun: 2.8, memnuniyet: 89, aylikCozum: 620, puan: 90.4),
        Belediye(ad: "Muratpaşa Belediyesi", sehir: "Antalya", ortalamaGun: 3.0, memnuniyet: 87, aylikCozum: 780, puan: 88.9),
        Belediye(ad: "Atakum Belediyesi", sehir: "Samsun", ortalamaGun: 3.3, memnuniyet: 86, aylikCozum: 430, puan: 87.5),
        Belediye(ad: "Şahinbey Belediyesi", sehir: "Gaziantep", ortalamaGun: 3.6, memnuniyet: 83, aylikCozum: 910, puan: 85.2)
    ]
}

extension Double {
    /// 2.1 → "2,1"
    var turkce: String {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.minimumFractionDigits = 1
        f.maximumFractionDigits = 1
        return f.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
