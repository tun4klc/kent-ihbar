import SwiftUI

struct SiralamaEkrani: View {
    var yeniIhbar: () -> Void

    enum Olcut: String, CaseIterable, Identifiable {
        case genel = "Genel", enHizli = "En hızlı", memnuniyet = "Memnuniyet", aylik = "Aylık çözüm"
        var id: String { rawValue }
    }

    @EnvironmentObject private var konum: KonumYoneticisi
    @State private var arama = ""
    @State private var olcut: Olcut = .genel
    @State private var sehir: String? = nil
    @FocusState private var aramaOdak: Bool

    private var sehirler: [String] {
        Array(Set(OrnekVeri.belediyeler.map(\.sehir))).sorted { $0.compare($1, locale: Locale(identifier: "tr_TR")) == .orderedAscending }
    }

    private var liste: [Belediye] {
        var l = OrnekVeri.belediyeler
        if let sehir { l = l.filter { $0.sehir == sehir } }
        let q = arama.trimmingCharacters(in: .whitespaces)
        if !q.isEmpty {
            l = l.filter { $0.ad.localizedCaseInsensitiveContains(q) || $0.sehir.localizedCaseInsensitiveContains(q) }
        }
        switch olcut {
        case .genel: l.sort { $0.puan > $1.puan }
        case .enHizli: l.sort { $0.ortalamaGun < $1.ortalamaGun }
        case .memnuniyet: l.sort { $0.memnuniyet > $1.memnuniyet }
        case .aylik: l.sort { $0.aylikCozum > $1.aylikCozum }
        }
        return l
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KI.space5) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: KI.space1) {
                        Text("Belediye Sıralaması").font(KIFont.ekranBasligi).foregroundStyle(KI.metin)
                        Text("Çözüm hızı ve vatandaş memnuniyetine göre")
                            .font(KIFont.govdeKucuk)
                            .foregroundStyle(KI.metinIkincil)
                    }
                    Spacer()
                    ShareLink(item: "Kent İhbar ile belediyeleri çözüm hızına göre karşılaştır.") {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 19, weight: .medium))
                            .foregroundStyle(KI.metin)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Paylaş")
                }

                GirdiKutusu(odakta: aramaOdak, hap: true) {
                    Image(systemName: "magnifyingglass").foregroundStyle(KI.metinSoluk)
                    TextField("Belediye, ilçe veya şehir ara…", text: $arama)
                        .focused($aramaOdak)
                        .submitLabel(.search)
                    if !arama.isEmpty {
                        Button { arama = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(KI.metinSoluk)
                        }
                        .accessibilityLabel("Aramayı temizle")
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: KI.space2) {
                            ForEach(Olcut.allCases) { o in
                                Button { olcut = o } label: { FiltreCipi(baslik: o.rawValue, secili: olcut == o) }
                            }
                        }
                        .padding(.horizontal, KI.space5)
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: KI.space2) {
                            Button { sehir = nil } label: { FiltreCipi(baslik: "Tüm şehirler", secili: sehir == nil) }
                            ForEach(sehirler, id: \.self) { s in
                                Button { sehir = s } label: { FiltreCipi(baslik: s, secili: sehir == s) }
                            }
                        }
                        .padding(.horizontal, KI.space5)
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, -KI.space5)

                if liste.isEmpty {
                    BosDurum(baslik: "Henüz sıralama verisi yok",
                             aciklama: "Bu aramaya uyan belediye bulunamadı. Yeterli çözülmüş ihbar olunca belediyeler burada sıralanacak.",
                             eylemAdi: "Sorun bildir",
                             eylem: yeniIhbar)
                        .frame(maxWidth: .infinity)
                } else {
                    if liste.count >= 3 {
                        LiderlerPodyumu(liderler: Array(liste.prefix(3)), olcut: olcut)
                    }

                    let ilkSira = liste.count >= 3 ? 3 : 0
                    let kalan = Array(liste.dropFirst(ilkSira))
                    if !kalan.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(Array(kalan.enumerated()), id: \.element.id) { i, b in
                                SiralamaSatiri(sira: ilkSira + i + 1, belediye: b)
                                if i < kalan.count - 1 {
                                    Rectangle().fill(KI.cizgi).frame(height: 1)
                                }
                            }
                        }
                        .kart(dolgu: 0)
                        .clipShape(RoundedRectangle(cornerRadius: KI.radiusLg, style: .continuous))
                    }

                    if !konum.izinVar {
                        IzinBandi(ikon: "location.slash",
                                  metin: "Senin belediyen kaçıncı? Konum izni ver, hemen görelim.",
                                  eylemAdi: konum.reddedildi ? "Ayarlar" : "İzin ver",
                                  eylem: konum.izinIste)
                    }

                    Text("ÖRNEK VERİ")
                        .font(KIFont.govde(11, .yariKalin))
                        .tracking(0.5)
                        .foregroundStyle(KI.metinSoluk)
                }
            }
            .padding(.horizontal, KI.space5)
            .padding(.top, KI.space2)
            .padding(.bottom, KI.space8)
            .animation(KI.egriStandart, value: olcut)
            .animation(KI.egriStandart, value: sehir)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(KI.zemin)
    }
}

/// İlk üç belediye: ortada 1., solda 2., sağda 3. — Şehir İhbar'daki "Bu ayın liderleri" kartı.
private struct LiderlerPodyumu: View {
    let liderler: [Belediye]
    let olcut: SiralamaEkrani.Olcut

    private let altin = Color(acik: 0xFBBF24, koyu: 0xFBBF24)
    /// Beyaz avatarın üstünde iki temada da okunur kalan mavi.
    private let avatarMetin = Color(acik: 0x1D4ED8, koyu: 0x1D4ED8)

    private var olcutEtiketi: String {
        switch olcut {
        case .genel: return "Puan / 100"
        case .enHizli: return "Ort. çözüm"
        case .memnuniyet: return "Memnuniyet"
        case .aylik: return "Aylık çözüm"
        }
    }

    private func deger(_ b: Belediye) -> String {
        switch olcut {
        case .genel: return b.puan.turkce
        case .enHizli: return "\(b.ortalamaGun.turkce) gün"
        case .memnuniyet: return "%\(b.memnuniyet)"
        case .aylik: return b.aylikCozum.formatted(.number.locale(Locale(identifier: "tr_TR")))
        }
    }

    var body: some View {
        let sekil = RoundedRectangle(cornerRadius: KI.radiusLg, style: .continuous)
        VStack(spacing: KI.space4) {
            HStack {
                Text("Bu ayın liderleri").font(KIFont.kartBasligi)
                Spacer()
                Text(olcutEtiketi).font(KIFont.altYazi).opacity(0.8)
            }
            HStack(alignment: .bottom, spacing: 10) {
                sutun(liderler[1], sira: 2, avatar: 46, yukseklik: 70, dolgu: 0.16)
                sutun(liderler[0], sira: 1, avatar: 56, yukseklik: 96, dolgu: 0.24)
                sutun(liderler[2], sira: 3, avatar: 46, yukseklik: 56, dolgu: 0.12)
            }
        }
        .foregroundStyle(KI.maviBayaz)
        .padding([.horizontal, .top], KI.space4)
        .background { sekil.fill(KI.birincil); YansimaIsigi().clipShape(sekil) }
        .clipShape(sekil)
        .maviYansima()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Bu ayın liderleri: 1. \(liderler[0].kisaAd), 2. \(liderler[1].kisaAd), 3. \(liderler[2].kisaAd)")
    }

    private func sutun(_ b: Belediye, sira: Int, avatar: CGFloat, yukseklik: CGFloat, dolgu: Double) -> some View {
        VStack(spacing: 6) {
            if sira == 1 {
                Image(systemName: "crown.fill").font(.system(size: 18)).foregroundStyle(altin)
            }
            Text(b.basHarfler)
                .font(KIFont.baslik(sira == 1 ? 17 : 15))
                .foregroundStyle(avatarMetin)
                .frame(width: avatar, height: avatar)
                .background(Color.white, in: Circle())
                .overlay { if sira == 1 { Circle().stroke(altin, lineWidth: 3) } }
            Text(b.kisaAd).font(KIFont.govde(13, .kalin)).lineLimit(1).minimumScaleFactor(0.8)
            Text(deger(b)).font(KIFont.govde(12, .orta)).opacity(0.8)
            Text("\(sira)")
                .font(KIFont.baslik(sira == 1 ? 26 : 21))
                .frame(maxWidth: .infinity, minHeight: yukseklik, alignment: .top)
                .padding(.top, 10)
                .background(Color.white.opacity(dolgu),
                            in: UnevenRoundedRectangle(topLeadingRadius: KI.radiusMd, topTrailingRadius: KI.radiusMd))
        }
        .frame(maxWidth: .infinity)
    }
}
