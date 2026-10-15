import SwiftUI
import MapKit

struct HaritaEkrani: View {
    @EnvironmentObject private var durum: UygulamaDurumu
    @EnvironmentObject private var konum: KonumYoneticisi

    private static let baslangic = MKCoordinateRegion(center: OrnekVeri.bornova,
                                                       span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))

    @State private var kamera: MapCameraPosition = .region(HaritaEkrani.baslangic)
    @State private var bolge: MKCoordinateRegion = HaritaEkrani.baslangic
    @State private var durumlar: Set<Durum> = Set(Durum.allCases)
    @State private var kategoriler: Set<Kategori> = Set(Kategori.allCases)
    @State private var sadeceSon24 = false
    @State private var secili: Ihbar?

    private var gorunen: [Ihbar] {
        durum.ihbarlar.filter { ih in
            durumlar.contains(ih.durum) && kategoriler.contains(ih.kategori) &&
            (!sadeceSon24 || ih.tarih > Date().addingTimeInterval(-86400))
        }
    }
    private var acik: Int { durum.ihbarlar.filter { $0.durum != .cozuldu }.count }
    private var son24: Int { durum.ihbarlar.filter { $0.tarih > Date().addingTimeInterval(-86400) }.count }

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $kamera) {
                UserAnnotation()
                ForEach(gorunen) { ih in
                    Annotation("", coordinate: ih.koordinat, anchor: .bottom) {
                        HaritaPini(durum: ih.durum, tohum: ih.id.hashValue)
                            .onTapGesture { secili = ih }
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .mapControls { MapCompass() }
            .onMapCameraChange(frequency: .onEnd) { baglam in bolge = baglam.region }
            .ignoresSafeArea(edges: .top)

            ust
                .padding(.horizontal, KI.space5)
                .padding(.top, KI.space2)
        }
        .overlay(alignment: .bottomTrailing) { kontroller.padding(KI.space5) }
        .sheet(item: $secili) { ih in
            IhbarDetayi(ihbar: ih)
                .presentationDetents([.height(320)])
                .presentationDragIndicator(.visible)
        }
        .animation(KI.egriStandart, value: durumlar)
        .animation(KI.egriStandart, value: kategoriler)
        .animation(KI.egriStandart, value: sadeceSon24)
    }

    // MARK: Üst panel

    private var ust: some View {
        VStack(spacing: KI.space3) {
            HStack(spacing: 14) {
                IkonRozeti(ikon: "map")
                VStack(alignment: .leading, spacing: 2) {
                    Text("Canlı Harita").font(KIFont.kartBasligi).foregroundStyle(KI.metin)
                    Text("Bornova · \(gorunen.count) kayıt görüntüleniyor")
                        .font(KIFont.govdeKucuk)
                        .foregroundStyle(KI.metinIkincil)
                        .contentTransition(.numericText())
                }
                Spacer(minLength: 0)
            }
            .kart(dolgu: 14)

            HStack(spacing: 10) {
                Button {
                    durumlar = [.kritik, .beklemede]
                    sadeceSon24 = false
                } label: { SayacHapi(tur: .acik, deger: acik, etiket: "Açık") }
                Button {
                    sadeceSon24.toggle()
                } label: { SayacHapi(tur: .canli, deger: son24, etiket: "Son 24s") }
            }
            .buttonStyle(BasmaOlcegi())

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: KI.space2) {
                    Button { degistir(.cozuldu) } label: {
                        FiltreCipi(baslik: "Çözülenler", ikon: "checkmark.circle", secili: durumlar.contains(.cozuldu))
                    }
                    Menu {
                        ForEach(Kategori.allCases) { k in
                            Button {
                                if kategoriler.contains(k) { kategoriler.remove(k) } else { kategoriler.insert(k) }
                            } label: {
                                Label(k.ad, systemImage: kategoriler.contains(k) ? "checkmark" : k.ikon)
                            }
                        }
                        Divider()
                        Button("Tümünü göster") { kategoriler = Set(Kategori.allCases) }
                    } label: {
                        FiltreCipi(baslik: kategoriler.count == Kategori.allCases.count ? "Kategori" : "Kategori · \(kategoriler.count)",
                                   ikon: "square.on.circle",
                                   secili: kategoriler.count != Kategori.allCases.count)
                    }
                    Menu {
                        ForEach(Durum.allCases) { d in
                            Button { degistir(d) } label: {
                                Label(d.ad, systemImage: durumlar.contains(d) ? "checkmark" : d.ikon)
                            }
                        }
                    } label: {
                        FiltreCipi(baslik: "Durum", ikon: "slider.horizontal.3", secili: durumlar.count != Durum.allCases.count)
                    }
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)

            HStack(spacing: KI.space2) {
                ForEach(Durum.allCases) { d in
                    Button { degistir(d) } label: { DurumGostergesi(durum: d, secili: durumlar.contains(d)) }
                        .buttonStyle(.plain)
                }
                Spacer(minLength: 0)
            }
        }
    }

    // MARK: Kontroller

    private var kontroller: some View {
        VStack(spacing: 10) {
            haritaDugmesi("plus", "Yakınlaştır") { yakinlas(0.5) }
            haritaDugmesi("minus", "Uzaklaştır") { yakinlas(2) }
            Button {
                if konum.izinVar {
                    withAnimation { kamera = .userLocation(fallback: .region(HaritaEkrani.baslangic)) }
                } else {
                    konum.izinIste()
                    withAnimation { kamera = .region(HaritaEkrani.baslangic) }
                }
            } label: {
                Image(systemName: "location.fill")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(KI.onBirincil)
                    .frame(width: 48, height: 48)
                    .background {
                        ZStack {
                            RoundedRectangle(cornerRadius: KI.radiusMd, style: .continuous).fill(KI.birincil)
                            YansimaIsigi().clipShape(RoundedRectangle(cornerRadius: KI.radiusMd, style: .continuous))
                        }
                    }
                    .maviYansima()
            }
            .buttonStyle(BasmaOlcegi())
            .accessibilityLabel("Konumuma git")
        }
    }

    private func haritaDugmesi(_ ikon: String, _ etiket: String, _ eylem: @escaping () -> Void) -> some View {
        Button(action: eylem) {
            Image(systemName: ikon)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(KI.metin)
                .frame(width: 48, height: 48)
                .background(KI.yuzey, in: RoundedRectangle(cornerRadius: KI.radiusMd, style: .continuous))
                .sertGolge()
        }
        .buttonStyle(BasmaOlcegi())
        .accessibilityLabel(etiket)
    }

    private func yakinlas(_ carpan: Double) {
        var yeni = bolge
        yeni.span = MKCoordinateSpan(latitudeDelta: min(max(bolge.span.latitudeDelta * carpan, 0.002), 40),
                                     longitudeDelta: min(max(bolge.span.longitudeDelta * carpan, 0.002), 40))
        withAnimation(.easeInOut(duration: KI.sureYavas)) { kamera = .region(yeni) }
        bolge = yeni
    }

    private func degistir(_ d: Durum) {
        if durumlar.contains(d) {
            if durumlar.count > 1 { durumlar.remove(d) }
        } else {
            durumlar.insert(d)
        }
    }
}

// MARK: - İhbar detayı

struct IhbarDetayi: View {
    let ihbar: Ihbar

    var body: some View {
        VStack(alignment: .leading, spacing: KI.space4) {
            HStack(spacing: KI.space3) {
                IkonRozeti(ikon: ihbar.kategori.ikon)
                VStack(alignment: .leading, spacing: 2) {
                    Text(ihbar.kategori.ad).font(KIFont.kartBasligi).foregroundStyle(KI.metin)
                    Text(ihbar.adres).font(KIFont.govdeKucuk).foregroundStyle(KI.metinIkincil)
                }
                Spacer()
                DurumRozeti(durum: ihbar.durum)
            }
            Text(ihbar.aciklama).font(KIFont.govdeMetni).foregroundStyle(KI.metin)
            Text(ihbar.tarih.formatted(.relative(presentation: .named).locale(Locale(identifier: "tr_TR"))))
                .font(KIFont.altYazi)
                .foregroundStyle(KI.metinSoluk)
            Spacer(minLength: 0)
            Button {
                let yer = MKMapItem(placemark: MKPlacemark(coordinate: ihbar.koordinat))
                yer.name = ihbar.kategori.ad
                yer.openInMaps()
            } label: { Label("Yol tarifi al", systemImage: "arrow.triangle.turn.up.right.diamond") }
                .buttonStyle(IkincilDugme())
        }
        .padding(KI.space5)
        .padding(.top, KI.space2)
        .background(KI.zemin)
    }
}
