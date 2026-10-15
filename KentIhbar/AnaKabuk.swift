import SwiftUI
import Combine
import CoreLocation
import UIKit

// MARK: - Konum

final class KonumYoneticisi: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var yetki: CLAuthorizationStatus
    @Published var konum: CLLocationCoordinate2D?
    private let yonetici: CLLocationManager

    override init() {
        let m = CLLocationManager()
        yonetici = m
        yetki = m.authorizationStatus
        super.init()
        yonetici.delegate = self
        yonetici.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    var izinVar: Bool { yetki == .authorizedWhenInUse || yetki == .authorizedAlways }
    var reddedildi: Bool { yetki == .denied || yetki == .restricted }

    /// İzin isteğini sistem penceresiyle açar; reddedilmişse Ayarlar'a götürür.
    func izinIste() {
        if reddedildi {
            if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
        } else {
            yonetici.requestWhenInUseAuthorization()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        yetki = manager.authorizationStatus
        if izinVar { manager.requestLocation() }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        konum = locations.last?.coordinate
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}

// MARK: - Sekmeler

enum Sekme: Hashable {
    case anaSayfa, harita, siralama, profil
}

struct AnaKabuk: View {
    @EnvironmentObject private var durum: UygulamaDurumu
    @StateObject private var konum = KonumYoneticisi()
    @State private var sekme: Sekme = .anaSayfa
    @State private var yeniIhbar = false
    @State private var onSeciliKategori: Kategori?
    @State private var sohbet = false

    var body: some View {
        ZStack {
            KI.zemin.ignoresSafeArea()
            switch sekme {
            case .anaSayfa:
                AnaSayfa(yeniIhbar: ihbarBaslat, haritayaGit: { sekmeSec(.harita) }, siralamayaGit: { sekmeSec(.siralama) })
            case .harita:
                HaritaEkrani()
            case .siralama:
                SiralamaEkrani(yeniIhbar: { ihbarBaslat(nil) })
            case .profil:
                ProfilEkrani()
            }
        }
        // Haritada sağ alt köşe harita kontrollerine ayrılmış.
        .overlay(alignment: .bottomTrailing) {
            if sekme != .harita {
                AsistanRobotu { sohbet = true }
                    .padding(.trailing, KI.space2)
                    .padding(.bottom, KI.space1)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AltMenu(sekme: $sekme, fab: { ihbarBaslat(nil) })
        }
        .environmentObject(konum)
        .sheet(isPresented: $yeniIhbar) {
            YeniIhbarEkrani(baslangicKategori: onSeciliKategori)
                .environmentObject(konum)
        }
        .sheet(isPresented: $sohbet) {
            SohbetEkrani()
                .presentationDragIndicator(.visible)
        }
    }

    private func sekmeSec(_ s: Sekme) {
        withAnimation(KI.egriStandart) { sekme = s }
    }

    /// Misafir yeni ihbar başlatırsa giriş ekranına yönlendirilir.
    private func ihbarBaslat(_ kategori: Kategori?) {
        if durum.uyeMi {
            onSeciliKategori = kategori
            yeniIhbar = true
        } else {
            withAnimation(.easeInOut(duration: KI.sureYavas)) { durum.oturum = .yok }
        }
    }
}

struct AltMenu: View {
    @Binding var sekme: Sekme
    var fab: () -> Void

    @Namespace private var ns
    @Environment(\.accessibilityReduceMotion) private var hareketiAzalt
    @State private var tiklama: [Sekme: Int] = [:]
    @State private var bildirTiklama = 0
    @State private var sallaTetik = 0
    private let sallaZamanlayici = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            sekmeDugmesi(.anaSayfa, "Ana Sayfa", "house", "house.fill")
            sekmeDugmesi(.harita, "Harita", "map", "map.fill")
            bildirDugmesi
            sekmeDugmesi(.siralama, "Sıralama", "chart.bar", "chart.bar.fill")
            sekmeDugmesi(.profil, "Profil", "person", "person.fill")
        }
        .padding(.top, 10)
        .padding(.bottom, 4)
        .background {
            KI.yuzey
                .ignoresSafeArea(edges: .bottom)
                .overlay(alignment: .top) { Rectangle().fill(KI.cizgi).frame(height: 1) }
        }
        .sensoryFeedback(.selection, trigger: sekme)
        .onReceive(sallaZamanlayici) { _ in
            if !hareketiAzalt { sallaTetik += 1 }
        }
    }

    // MARK: Sekme

    private func sekmeDugmesi(_ s: Sekme, _ baslik: String, _ ikon: String, _ doluIkon: String) -> some View {
        let aktif = sekme == s
        return Button {
            tiklama[s, default: 0] += 1
            withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) { sekme = s }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: aktif ? doluIkon : ikon)
                    .font(.system(size: 20, weight: .medium))
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.bounce.down, value: tiklama[s, default: 0])
                    .frame(width: 56, height: 32)
                    .background {
                        if aktif {
                            Capsule()
                                .fill(KI.birincilYumusak)
                                .matchedGeometryEffect(id: "aktifHap", in: ns)
                        }
                    }
                Text(baslik)
                    .font(KIFont.govde(12, .yariKalin))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(aktif ? KI.birincilMetin : KI.metinSoluk)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(SekmeBasma())
        .accessibilityAddTraits(aktif ? .isSelected : [])
    }

    // MARK: Bildir (ortadaki eylem)

    private var bildirDugmesi: some View {
        Button {
            bildirTiklama += 1
            fab()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "megaphone.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(KI.onBirincil)
                    .symbolEffect(.bounce.up, value: bildirTiklama)
                    .phaseAnimator([0.0, -14.0, 10.0, -6.0, 0.0], trigger: sallaTetik) { icerik, aci in
                        icerik.rotationEffect(.degrees(aci), anchor: .trailing)
                    } animation: { _ in .easeInOut(duration: 0.12) }
                    .frame(width: 56, height: 32)
                    .background {
                        ZStack {
                            Capsule().fill(KI.birincil)
                            YansimaIsigi().clipShape(Capsule())
                        }
                    }
                    .maviYansima()
                Text("Bildir")
                    .font(KIFont.govde(12, .kalin))
                    .foregroundStyle(KI.birincilMetin)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(SekmeBasma(olcek: 0.9))
        .sensoryFeedback(.impact(weight: .medium), trigger: bildirTiklama)
        .accessibilityLabel("Sorun bildir")
    }
}

/// Sekmelerde basınca hafif küçülme, bırakınca yaylanma.
struct SekmeBasma: ButtonStyle {
    var olcek: CGFloat = 0.92
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? olcek : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.55), value: configuration.isPressed)
    }
}
