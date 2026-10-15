import SwiftUI

// MARK: - Düğmeler

/// Ekranın tek birincil eylemi: `birincil` dolgu + `mavi-yansima` parlaması + üst ışık.
struct BirincilDugme: ButtonStyle {
    var tamGenislik = true
    @Environment(\.isEnabled) private var aktif

    func makeBody(configuration: Configuration) -> some View {
        let sekil = RoundedRectangle(cornerRadius: KI.radiusMd, style: .continuous)
        return configuration.label
            .font(KIFont.dugme)
            .foregroundStyle(aktif ? KI.onBirincil : KI.metinSoluk)
            .padding(.horizontal, KI.space5)
            .frame(maxWidth: tamGenislik ? .infinity : nil, minHeight: 52)
            .background {
                ZStack {
                    sekil.fill(aktif ? (configuration.isPressed ? KI.birincilBasili : KI.birincil) : KI.yuzeyUst)
                    if aktif { YansimaIsigi().clipShape(sekil) }
                }
            }
            .maviYansima(aktif)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: KI.sureHizli), value: configuration.isPressed)
    }
}

struct IkincilDugme: ButtonStyle {
    var tamGenislik = true
    func makeBody(configuration: Configuration) -> some View {
        let sekil = RoundedRectangle(cornerRadius: KI.radiusMd, style: .continuous)
        return configuration.label
            .font(KIFont.dugme)
            .foregroundStyle(KI.birincilMetin)
            .padding(.horizontal, KI.space5)
            .frame(maxWidth: tamGenislik ? .infinity : nil, minHeight: 52)
            .background(sekil.fill(KI.yuzey))
            .overlay(sekil.stroke(KI.birincil, lineWidth: 1.5))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: KI.sureHizli), value: configuration.isPressed)
    }
}

struct MetinDugme: ButtonStyle {
    @Environment(\.isEnabled) private var aktif
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(KIFont.dugme)
            .foregroundStyle(aktif ? KI.birincilMetin : KI.metinSoluk)
            .frame(minHeight: 44)
            .padding(.horizontal, KI.space3)
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

/// Alt menünün ortasındaki yükseltilmiş "Yeni bildirim" düğmesi.
struct FAB: View {
    var eylem: () -> Void
    var body: some View {
        Button(action: eylem) {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(KI.onBirincil)
                .frame(width: 64, height: 64)
                .background {
                    ZStack {
                        Circle().fill(KI.birincil)
                        YansimaIsigi().clipShape(Circle())
                    }
                }
                .maviYansima()
        }
        .buttonStyle(YayliBasma())
        .accessibilityLabel("Yeni bildirim")
    }
}

struct YayliBasma: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(KI.yay, value: configuration.isPressed)
    }
}

struct BasmaOlcegi: ButtonStyle {
    var olcek: CGFloat = 0.96
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? olcek : 1)
            .animation(.easeOut(duration: KI.sureHizli), value: configuration.isPressed)
    }
}

// MARK: - Kartlar

struct KategoriKutusu: View {
    let kategori: Kategori
    var eylem: () -> Void
    var body: some View {
        Button(action: eylem) {
            VStack(spacing: 10) {
                IkonRozeti(ikon: kategori.ikon, boyut: 48, renk: kategori.renk, zemin: kategori.yumusak)
                Text(kategori.ad)
                    .font(KIFont.etiket)
                    .foregroundStyle(KI.metin)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 96)
            .padding(.top, KI.space1)
            .kart(dolgu: KI.space3)
        }
        .buttonStyle(BasmaOlcegi())
    }
}

struct IkonRozeti: View {
    let ikon: String
    var boyut: CGFloat = 44
    var renk: Color = KI.birincilMetin
    var zemin: Color = KI.birincilYumusak
    var body: some View {
        Image(systemName: ikon)
            .font(.system(size: boyut * 0.45, weight: .medium))
            .foregroundStyle(renk)
            .frame(width: boyut, height: boyut)
            .background(zemin, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct IstatistikKarti: View {
    enum Tur { case acik, cozulen, belediye }
    let tur: Tur
    let deger: Int
    @State private var gosterilen = 0

    private var zemin: Color {
        switch tur { case .acik: return KI.birincilYumusak; case .cozulen: return KI.cozulduYumusak; case .belediye: return KI.beklemedeYumusak }
    }
    private var renk: Color {
        switch tur { case .acik: return KI.birincilMetin; case .cozulen: return KI.cozuldu; case .belediye: return KI.beklemede }
    }
    private var etiket: String {
        switch tur { case .acik: return "Açık"; case .cozulen: return "Çözülen"; case .belediye: return "Belediye" }
    }

    var body: some View {
        VStack(spacing: 2) {
            Text("\(gosterilen)")
                .font(KIFont.sayiBuyuk)
                .foregroundStyle(renk)
                .contentTransition(.numericText(value: Double(gosterilen)))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(etiket)
                .font(KIFont.govde(13, .orta))
                .foregroundStyle(KI.metinIkincil)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, KI.space4)
        .padding(.horizontal, KI.space2)
        .background(zemin, in: RoundedRectangle(cornerRadius: KI.radiusLg, style: .continuous))
        .onAppear { sayac(deger) }
        .onChange(of: deger) { _, yeni in sayac(yeni) }
    }

    private func sayac(_ hedef: Int) {
        withAnimation(.easeOut(duration: KI.sureYavas)) { gosterilen = hedef }
    }
}

/// Bir izin ya da eksik ayar yüzünden içerik gösterilemiyorsa üstte tek satırlık bant.
struct IzinBandi: View {
    let ikon: String
    let metin: String
    let eylemAdi: String
    var eylem: () -> Void
    var body: some View {
        HStack(spacing: KI.space3) {
            Image(systemName: ikon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(KI.beklemede)
            Text(metin)
                .font(KIFont.govde(14, .orta))
                .foregroundStyle(KI.metin)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(eylemAdi, action: eylem)
                .font(KIFont.govde(14, .kalin))
                .foregroundStyle(KI.birincilMetin)
        }
        .padding(KI.space4)
        .background(KI.beklemedeYumusak, in: RoundedRectangle(cornerRadius: KI.radiusLg, style: .continuous))
    }
}

// MARK: - Durum

struct DurumGostergesi: View {
    let durum: Durum
    var secili = true
    var body: some View {
        HStack(spacing: KI.space2) {
            Circle().fill(durum.renk).frame(width: 10, height: 10)
            Text(durum.ad).font(KIFont.etiket).foregroundStyle(KI.metin)
        }
        .padding(.horizontal, 14)
        .frame(height: 34)
        .background(KI.yuzey, in: Capsule())
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
        .opacity(secili ? 1 : 0.45)
    }
}

struct DurumRozeti: View {
    let durum: Durum
    var body: some View {
        Label(durum.ad, systemImage: durum.ikon)
            .font(KIFont.govde(12, .yariKalin))
            .foregroundStyle(durum.renk)
            .padding(.horizontal, 10)
            .frame(height: 26)
            .background(durum.yumusak, in: Capsule())
    }
}

/// Damla biçimli harita pini — renk + ikon (renk körlüğü için).
/// Havada süzülür, yerdeki gölgesi buna göre daralır, ara sıra kendi ekseninde 3B döner
/// ve ucundan zemine yayılan dalgalar çıkar. Her pin `tohum` ile kendi ritminde oynar.
struct HaritaPini: View {
    let durum: Durum
    var tohum: Int = 0
    @Environment(\.accessibilityReduceMotion) private var hareketAzalt
    @State private var belirdi = false

    var body: some View {
        Group {
            if hareketAzalt {
                sahne(t: 0)
            } else {
                TimelineView(.animation(minimumInterval: 1 / 30)) { baglam in
                    sahne(t: baglam.date.timeIntervalSinceReferenceDate)
                }
            }
        }
        .frame(width: 76, height: 76, alignment: .bottom)
        .scaleEffect(belirdi ? 1 : 0.2, anchor: .bottom)
        .opacity(belirdi ? 1 : 0)
        .onAppear { withAnimation(KI.yay.delay(Double((tohum & 0xFFFF) % 7) * 0.06)) { belirdi = true } }
        .accessibilityElement()
        .accessibilityLabel(durum.ad)
    }

    // MARK: Zamanlama

    /// 0…1 arası pin başına sabit sapma — pinler aynı anda hareket etmesin.
    private var sapma: Double { Double((tohum & 0xFFFF) % 997) / 997 }
    private var dalgaSuresi: Double { durum == .kritik ? 1.4 : 2.4 }

    private func sahne(t: Double) -> some View {
        let tt = t + sapma * 10
        let suzulme = hareketAzalt ? 0 : sin(tt * 2 * .pi / 2.6) * 4          // -4…4 pt
        let donus = hareketAzalt ? 0 : donusAcisi(tt)
        return ZStack(alignment: .bottom) {
            if !hareketAzalt {
                dalga(ilerleme: (tt / dalgaSuresi).truncatingRemainder(dividingBy: 1))
                dalga(ilerleme: (tt / dalgaSuresi + 0.5).truncatingRemainder(dividingBy: 1))
            }
            // Yer gölgesi: pin yükseldikçe küçülür ve soluklaşır
            Ellipse()
                .fill(.black.opacity(0.22 - suzulme * 0.012))
                .frame(width: 20 - suzulme * 0.9, height: 6 - suzulme * 0.25)
                .blur(radius: 1.5)
            govde
                .rotation3DEffect(.degrees(donus), axis: (x: 0, y: 1, z: 0), perspective: 0.55)
                .offset(y: -10 - suzulme)
        }
    }

    /// Her 5–8 sn'de bir, 0,9 sn süren tam tur; arada düz durur.
    private func donusAcisi(_ t: Double) -> Double {
        let periyot = 5 + sapma * 3
        let p = t.truncatingRemainder(dividingBy: periyot)
        let sure = 0.9
        guard p < sure else { return 0 }
        let x = p / sure
        let yumusak = x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2   // easeInOutCubic
        return yumusak * 360
    }

    // MARK: Parçalar

    private var damla: UnevenRoundedRectangle {
        UnevenRoundedRectangle(topLeadingRadius: 17, bottomLeadingRadius: 17,
                               bottomTrailingRadius: 3, topTrailingRadius: 17, style: .continuous)
    }

    private var govde: some View {
        ZStack {
            damla
                .fill(LinearGradient(colors: [durum.renk.opacity(0.85), durum.renk],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                // Hacim: üst-solda parlak ışık, alt-sağda koyu kenar
                .overlay(
                    damla.fill(RadialGradient(colors: [.white.opacity(0.55), .white.opacity(0)],
                                              center: UnitPoint(x: 0.28, y: 0.25), startRadius: 0, endRadius: 18))
                )
                .overlay(
                    damla.fill(LinearGradient(colors: [.clear, .black.opacity(0.22)],
                                              startPoint: .topLeading, endPoint: .bottomTrailing))
                )
                .overlay(damla.stroke(KI.yuzey, lineWidth: 2.5))
                .rotationEffect(.degrees(45))
            Image(systemName: durum.ikon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(KI.onDurum)
                .shadow(color: .black.opacity(0.25), radius: 0.5, x: 0, y: 0.5)
        }
        .frame(width: 34, height: 34)
        .shadow(color: durum.renk.opacity(0.45), radius: 6, x: 0, y: 4)
    }

    /// Zemine yatırılmış (perspektifli) halka: içten dışa büyür ve kaybolur.
    private func dalga(ilerleme: Double) -> some View {
        let boyut = 14 + ilerleme * (durum == .kritik ? 62 : 50)
        return Ellipse()
            .stroke(durum.renk.opacity((1 - ilerleme) * (durum == .kritik ? 0.9 : 0.6)),
                    lineWidth: 2.5 - ilerleme * 1.5)
            .background(Ellipse().fill(durum.renk.opacity((1 - ilerleme) * 0.12)))
            .frame(width: boyut, height: boyut * 0.38)
            .offset(y: boyut * 0.19 - 3)
    }
}

// MARK: - Filtre

struct FiltreCipi: View {
    let baslik: String
    var ikon: String? = nil
    var secili = false
    var body: some View {
        HStack(spacing: KI.space2) {
            if secili {
                Image(systemName: "checkmark").font(.system(size: 13, weight: .bold))
            } else if let ikon {
                Image(systemName: ikon).font(.system(size: 14, weight: .medium)).foregroundStyle(KI.metinIkincil)
            }
            Text(baslik).font(KIFont.govde(14, .yariKalin))
        }
        .foregroundStyle(secili ? KI.birincilMetin : KI.metin)
        .padding(.horizontal, KI.space4)
        .frame(height: 40)
        .background(secili ? KI.birincilYumusak : KI.yuzey,
                    in: RoundedRectangle(cornerRadius: KI.radiusMd, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: KI.radiusMd, style: .continuous)
                .stroke(secili ? Color.clear : KI.cizgi, lineWidth: 1.5)
        )
        .animation(.easeOut(duration: KI.sureHizli), value: secili)
    }
}

struct SayacHapi: View {
    enum Tur { case acik, canli }
    let tur: Tur
    let deger: Int
    let etiket: String
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: KI.space2) {
            Text("\(deger)").font(KIFont.baslik(22))
                .contentTransition(.numericText(value: Double(deger)))
            Text(etiket).font(KIFont.govde(14, .yariKalin))
            Spacer(minLength: 0)
        }
        .foregroundStyle(tur == .acik ? KI.birincilMetin : KI.vurgu)
        .padding(.horizontal, KI.space4)
        .padding(.vertical, KI.space3)
        .background(tur == .acik ? KI.birincilYumusak : KI.vurguYumusak,
                    in: RoundedRectangle(cornerRadius: KI.radiusLg, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Listeler

struct MenuGrubu<Icerik: View>: View {
    let baslik: String?
    @ViewBuilder var icerik: Icerik
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let baslik {
                Text(baslik).font(KIFont.baslik(15)).foregroundStyle(KI.metinIkincil)
            }
            VStack(spacing: 0) { icerik }
                .kart(dolgu: 0)
        }
    }
}

struct MenuSatiri: View {
    let ikon: String
    let baslik: String
    var deger: String? = nil
    var ayiriciVar = true
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: KI.space4) {
                Image(systemName: ikon)
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(KI.birincilMetin)
                    .frame(width: 24)
                Text(baslik).font(KIFont.dugme).foregroundStyle(KI.metin)
                Spacer()
                if let deger {
                    Text(deger).font(KIFont.govde(14, .orta)).foregroundStyle(KI.metinIkincil)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(KI.metinSoluk)
            }
            .padding(.horizontal, KI.space4)
            .frame(minHeight: 58)
            .contentShape(Rectangle())
            if ayiriciVar {
                Rectangle().fill(KI.cizgi).frame(height: 1).padding(.leading, 56)
            }
        }
    }
}

struct SiralamaSatiri: View {
    let sira: Int
    let belediye: Belediye
    var body: some View {
        HStack(spacing: KI.space3) {
            Group {
                if sira == 1 {
                    Text("1")
                        .font(KIFont.baslik(14))
                        .foregroundStyle(KI.onBirincil)
                        .frame(width: 28, height: 28)
                        .background(KI.birincil, in: Circle())
                } else {
                    Text("\(sira)").font(KIFont.baslik(16)).foregroundStyle(KI.metinIkincil)
                }
            }
            .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(belediye.senin ? "Senin ilçen · \(belediye.kisaAd)" : belediye.ad)
                    .font(KIFont.govde(15, .yariKalin))
                    .foregroundStyle(KI.metin)
                    .lineLimit(1)
                Text("\(belediye.sehir) · ort. \(belediye.ortalamaGun.turkce) gün")
                    .font(KIFont.govde(13))
                    .foregroundStyle(KI.metinIkincil)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(KI.yuzeyUst)
                        Capsule().fill(KI.birincil).frame(width: geo.size.width * CGFloat(belediye.puan) / 100)
                    }
                }
                .frame(height: 4)
                .padding(.top, 6)
            }

            VStack(alignment: .trailing, spacing: 0) {
                Text(belediye.puan.turkce).font(KIFont.baslik(18)).foregroundStyle(KI.birincilMetin)
                Text("/100").font(KIFont.govde(11, .orta)).foregroundStyle(KI.metinSoluk)
            }
        }
        .padding(.horizontal, KI.space4)
        .padding(.vertical, 14)
        .background(belediye.senin ? KI.birincilYumusak : Color.clear)
    }
}

/// Liste ya da harita boşken: neden boş olduğunu söyler ve tek bir sonraki adım sunar.
struct BosDurum: View {
    let baslik: String
    let aciklama: String
    var eylemAdi: String? = nil
    var eylem: () -> Void = {}
    @State private var goster = false

    var body: some View {
        VStack(spacing: KI.space3) {
            HStack(alignment: .bottom, spacing: 6) {
                blok(KI.birincilYumusak, 40, 72, 0)
                blok(KI.birincil, 32, 100, 0.08)
                blok(KI.maviRenk, 24, 48, 0.16)
            }
            .frame(height: 104, alignment: .bottom)
            .padding(.bottom, KI.space2)
            Text(baslik).font(KIFont.kartBasligi).foregroundStyle(KI.metin)
            Text(aciklama)
                .font(KIFont.govdeKucuk)
                .foregroundStyle(KI.metinIkincil)
                .multilineTextAlignment(.center)
            if let eylemAdi {
                Button(action: eylem) { Label(eylemAdi, systemImage: "plus") }
                    .buttonStyle(IkincilDugme(tamGenislik: false))
                    .padding(.top, KI.space2)
            }
        }
        .padding(.vertical, KI.space8)
        .padding(.horizontal, KI.space6)
        .onAppear { goster = true }
    }

    private func blok(_ renk: Color, _ g: CGFloat, _ y: CGFloat, _ gecikme: Double) -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(renk)
            .frame(width: g, height: goster ? y : 8)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(gecikme), value: goster)
    }
}

// MARK: - Giriş alanları

struct SegmentSecenegi<Deger: Hashable>: Identifiable {
    let deger: Deger
    let baslik: String
    let ikon: String
    var id: Deger { deger }
}

struct Segment<Deger: Hashable>: View {
    let secenekler: [SegmentSecenegi<Deger>]
    @Binding var secili: Deger
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 4) {
            ForEach(secenekler) { secenek in
                Button {
                    withAnimation(KI.egriStandart) { secili = secenek.deger }
                } label: {
                    Label(secenek.baslik, systemImage: secenek.ikon)
                        .font(KIFont.govde(14, .yariKalin))
                        .foregroundStyle(secili == secenek.deger ? KI.metin : KI.metinIkincil)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background {
                            if secili == secenek.deger {
                                RoundedRectangle(cornerRadius: KI.radiusSm, style: .continuous)
                                    .fill(KI.yuzey)
                                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                                    .matchedGeometryEffect(id: "secim", in: ns)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(KI.yuzeyUst, in: RoundedRectangle(cornerRadius: KI.radiusMd, style: .continuous))
    }
}

/// Giriş alanı kutusu — odakta `birincil` kenar + `birincil-yumusak` hale, hatada `kritik`.
struct GirdiKutusu<Icerik: View>: View {
    var odakta: Bool
    var hata: Bool = false
    var hap: Bool = false
    @ViewBuilder var icerik: Icerik

    var body: some View {
        let sekil = RoundedRectangle(cornerRadius: hap ? 26 : KI.radiusMd, style: .continuous)
        HStack(spacing: KI.space3) { icerik }
            .font(KIFont.govdeMetni)
            .foregroundStyle(KI.metin)
            .padding(.horizontal, KI.space4)
            .frame(height: 52)
            .background(sekil.fill(KI.yuzey))
            .overlay(sekil.stroke(hata ? KI.kritik : (odakta ? KI.birincil : (hap ? Color.clear : KI.cizgiKontrol)), lineWidth: 1.5))
            .background(sekil.stroke(KI.birincilYumusak, lineWidth: odakta && !hata ? 8 : 0))
            .shadow(color: .black.opacity(hap ? 0.06 : 0), radius: 9, x: 0, y: 6)
            .animation(.easeOut(duration: KI.sureOrta), value: odakta)
    }
}

struct AlanEtiketi: View {
    let metin: String
    var body: some View {
        Text(metin).font(KIFont.etiket).foregroundStyle(KI.metinIkincil)
    }
}

struct Ayirici: View {
    let metin: String
    var body: some View {
        HStack(spacing: KI.space3) {
            Rectangle().fill(KI.cizgi).frame(height: 1)
            Text(metin).font(KIFont.govde(13, .orta)).foregroundStyle(KI.metinSoluk)
            Rectangle().fill(KI.cizgi).frame(height: 1)
        }
    }
}
