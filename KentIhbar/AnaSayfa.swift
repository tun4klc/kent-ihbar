import SwiftUI

/// Düzen Şehir Bildirim ana sayfasından: mavi üst alan (karşılama, "Sorun mu gördün?",
/// hızlı geçişler) → konum izni → genel durum → kategoriler → bildirimlerim.
struct AnaSayfa: View {
    var yeniIhbar: (Kategori?) -> Void
    var haritayaGit: () -> Void
    var siralamayaGit: () -> Void

    @EnvironmentObject private var durum: UygulamaDurumu
    @EnvironmentObject private var konum: KonumYoneticisi

    enum Filtre: Hashable { case tumu, acik, cozulen }
    @State private var filtre: Filtre = .tumu

    private let sutunlar = Array(repeating: GridItem(.flexible(), spacing: KI.space3), count: 3)

    private var acikSayisi: Int { konum.izinVar ? durum.ihbarlar.filter { $0.durum != .cozuldu }.count : 0 }
    private var cozulenSayisi: Int { konum.izinVar ? durum.ihbarlar.filter { $0.durum == .cozuldu }.count : 0 }

    private var bildirimlerim: [Ihbar] {
        let benim = durum.ihbarlar.filter(\.benim)
        switch filtre {
        case .tumu: return benim
        case .acik: return benim.filter { $0.durum != .cozuldu }
        case .cozulen: return benim.filter { $0.durum == .cozuldu }
        }
    }

    var body: some View {
        GeometryReader { geo in
        ScrollView {
            VStack(alignment: .leading, spacing: KI.space6) {
                ustAlan(ustBosluk: geo.safeAreaInsets.top)

                VStack(alignment: .leading, spacing: KI.space6) {
                    if !konum.izinVar {
                        izinKarti
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    VStack(alignment: .leading, spacing: KI.space3) {
                        Text("Genel durum").font(KIFont.bolumBasligi).foregroundStyle(KI.metin)
                        HStack(spacing: KI.space3) {
                            IstatistikKarti(tur: .acik, deger: acikSayisi)
                            IstatistikKarti(tur: .cozulen, deger: cozulenSayisi)
                            IstatistikKarti(tur: .belediye, deger: 1407)
                        }
                    }

                    VStack(alignment: .leading, spacing: KI.space3) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("Kategoriler").font(KIFont.bolumBasligi).foregroundStyle(KI.metin)
                            Spacer()
                            Button("Tümü") { yeniIhbar(nil) }
                                .font(KIFont.etiket)
                                .foregroundStyle(KI.birincilMetin)
                        }
                        LazyVGrid(columns: sutunlar, spacing: KI.space3) {
                            ForEach(Kategori.allCases) { k in
                                KategoriKutusu(kategori: k) { yeniIhbar(k) }
                            }
                        }
                    }

                    bildirimlerimBolumu
                }
                .padding(.horizontal, KI.space5)
            }
            .padding(.bottom, KI.space8)
            .animation(KI.egriStandart, value: konum.izinVar)
            .animation(KI.egriStandart, value: filtre)
        }
        .ignoresSafeArea(edges: .top)
        }
        .background(KI.zemin)
    }

    // MARK: Mavi üst alan

    /// `ustBosluk`: durum çubuğu yüksekliği — mavi zemin arkasına uzanır, içerik altında başlar.
    private func ustAlan(ustBosluk: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(UstAlanRenk.logo)
                    .frame(width: 38, height: 38)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                    .accessibilityHidden(true)
                Text("Merhaba").font(KIFont.baslik(22)).foregroundStyle(.white)
                Spacer()
                Image(systemName: "bell")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .camKutu(kose: KI.radiusMd)
                    .accessibilityLabel("Bildirimler")
            }

            Button { yeniIhbar(nil) } label: {
                HStack(spacing: KI.space3) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Sorun mu gördün?").font(KIFont.baslik(20)).foregroundStyle(.white)
                        Text("Fotoğraf çek, konumu al, saniyeler içinde birimlere ilet.")
                            .font(KIFont.govde(15))
                            .foregroundStyle(.white.opacity(0.9))
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(22)
                .frame(maxWidth: .infinity, alignment: .leading)
                .camKutu(kose: 18)
            }
            .buttonStyle(BasmaOlcegi())

            HStack(spacing: 10) {
                HizliGecis(ikon: "plus", baslik: "Yeni bildirim") { yeniIhbar(nil) }
                HizliGecis(ikon: "map", baslik: "Canlı harita", eylem: haritayaGit)
                HizliGecis(ikon: "chart.bar", baslik: "Sıralama", eylem: siralamayaGit)
            }
        }
        .padding(.horizontal, KI.space5)
        .padding(.top, ustBosluk + KI.space3)
        .padding(.bottom, KI.space6)
        .background(alignment: .bottom) {
            ZStack(alignment: .topTrailing) {
                LinearGradient(colors: [UstAlanRenk.ust, UstAlanRenk.alt], startPoint: .topLeading, endPoint: .bottomTrailing)
                // Şehir Bildirim'deki iç içe kontur süsü
                ZStack {
                    ForEach([300.0, 220.0, 140.0], id: \.self) { cap in
                        Circle().stroke(.white.opacity(0.12), lineWidth: 1.5).frame(width: cap, height: cap)
                    }
                }
                .offset(x: 110, y: 440)
                .accessibilityHidden(true)
            }
            // Durum çubuğunun ve yukarı çekmenin arkasını da mavi tutar.
            .padding(.top, -400)
            .clipped()
        }
    }

    // MARK: Konum izni

    private var izinKarti: some View {
        Button(action: konum.izinIste) {
            HStack(spacing: 14) {
                Image(systemName: konum.reddedildi ? "location.slash.fill" : "location.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(KI.onBirincil)
                    .frame(width: 34, height: 34)
                    .background(KI.birincil, in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(konum.reddedildi ? "Konum izni kapalı" : "Konum izni ver")
                        .font(KIFont.kartBasligi)
                        .foregroundStyle(KI.metin)
                    Text(konum.reddedildi ? "Ayarlar'dan açarak ilçendeki ihbarları gör." : "İlçendeki açık ihbarları gör.")
                        .font(KIFont.govdeKucuk)
                        .foregroundStyle(KI.metinIkincil)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(KI.birincilMetin)
            }
            .kart(dolgu: KI.space4, kose: KI.radiusLg)
        }
        .buttonStyle(BasmaOlcegi())
    }

    // MARK: Bildirimlerim

    private var bildirimlerimBolumu: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Bildirimlerim").font(KIFont.bolumBasligi).foregroundStyle(KI.metin)
            Segment(secenekler: [SegmentSecenegi(deger: Filtre.tumu, baslik: "Tümü", ikon: "tray"),
                                 SegmentSecenegi(deger: Filtre.acik, baslik: "Açık", ikon: "clock"),
                                 SegmentSecenegi(deger: Filtre.cozulen, baslik: "Çözülen", ikon: "checkmark")],
                    secili: $filtre)

            if bildirimlerim.isEmpty {
                BosDurum(baslik: "Henüz bildirimin yok",
                         aciklama: "Bildirdiğin sorunları buradan takip edebilirsin.")
                    .frame(maxWidth: .infinity)
                    .kart(dolgu: 0)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(bildirimlerim.enumerated()), id: \.element.id) { i, ih in
                        BildirimSatiri(ihbar: ih)
                        if i < bildirimlerim.count - 1 {
                            Rectangle().fill(KI.cizgi).frame(height: 1).padding(.leading, 72)
                        }
                    }
                }
                .kart(dolgu: 0)
            }
        }
    }
}

/// Mavi üst alanın renkleri — iki temada da üstündeki beyaz metin okunur kalır.
private enum UstAlanRenk {
    static let ust = Color(acik: 0x1D4ED8, koyu: 0x172554)
    static let alt = Color(acik: 0x3F97FF, koyu: 0x1D4ED8)
    static let logo = Color(acik: 0x1D4ED8, koyu: 0x1D4ED8)
}

private extension View {
    /// Mavi zemin üstünde yarı saydam "cam" kutu.
    func camKutu(kose: CGFloat) -> some View {
        let sekil = RoundedRectangle(cornerRadius: kose, style: .continuous)
        return background(.white.opacity(0.14), in: sekil)
            .overlay(sekil.stroke(.white.opacity(0.25), lineWidth: 1))
    }
}

private struct HizliGecis: View {
    let ikon: String
    let baslik: String
    var eylem: () -> Void

    var body: some View {
        Button(action: eylem) {
            VStack(alignment: .leading) {
                Image(systemName: ikon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(UstAlanRenk.logo)
                    .frame(width: 28, height: 28)
                    .background(Color.white, in: Circle())
                Spacer(minLength: 0)
                Text(baslik)
                    .font(KIFont.govde(14, .yariKalin))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(KI.space3)
            .frame(maxWidth: .infinity, minHeight: 88, maxHeight: 88, alignment: .leading)
            .camKutu(kose: KI.radiusMd)
        }
        .buttonStyle(BasmaOlcegi())
    }
}

private struct BildirimSatiri: View {
    let ihbar: Ihbar
    var body: some View {
        HStack(spacing: KI.space3) {
            IkonRozeti(ikon: ihbar.kategori.ikon, renk: ihbar.kategori.renk, zemin: ihbar.kategori.yumusak)
            VStack(alignment: .leading, spacing: 2) {
                Text(ihbar.kategori.ad).font(KIFont.govde(15, .yariKalin)).foregroundStyle(KI.metin)
                Text(ihbar.adres).font(KIFont.govde(13)).foregroundStyle(KI.metinIkincil).lineLimit(1)
            }
            Spacer(minLength: 0)
            DurumRozeti(durum: ihbar.durum)
        }
        .padding(.horizontal, KI.space4)
        .padding(.vertical, KI.space3)
    }
}

/// Fotoğraf → Konum → Gönder: dokunulmaz süreç göstergesi.
struct AdimGostergesi: View {
    private let adimlar = [("camera", "Fotoğraf"), ("mappin.and.ellipse", "Konum"), ("paperplane", "Gönder")]

    var body: some View {
        ZStack(alignment: .top) {
            Line()
                .stroke(KI.cizgi, style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                .frame(height: 2)
                .padding(.horizontal, 60)
                .padding(.top, 24)
            HStack(spacing: 0) {
                ForEach(Array(adimlar.enumerated()), id: \.offset) { i, adim in
                    VStack(spacing: KI.space2) {
                        Image(systemName: adim.0)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(KI.birincilMetin)
                            .frame(width: 48, height: 48)
                            .background(KI.birincilYumusak, in: Circle())
                            .overlay(alignment: .topTrailing) {
                                Text("\(i + 1)")
                                    .font(KIFont.govde(11, .kalin))
                                    .foregroundStyle(KI.onBirincil)
                                    .frame(width: 20, height: 20)
                                    .background(KI.birincil, in: Circle())
                                    .offset(x: 6, y: -2)
                            }
                        Text(adim.1).font(KIFont.etiket).foregroundStyle(KI.metin)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Üç adım: Fotoğraf, Konum, Gönder")
    }
}

struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return p
    }
}
