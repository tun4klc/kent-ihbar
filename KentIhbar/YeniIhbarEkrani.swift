import SwiftUI
import PhotosUI
import CoreLocation

struct YeniIhbarEkrani: View {
    var baslangicKategori: Kategori?

    @EnvironmentObject private var durum: UygulamaDurumu
    @EnvironmentObject private var konum: KonumYoneticisi
    @Environment(\.dismiss) private var kapat

    @State private var kategori: Kategori?
    @State private var fotoSecimi: PhotosPickerItem?
    @State private var foto: UIImage?
    @State private var aciklama = ""
    @State private var gonderildi = false
    @FocusState private var aciklamaOdak: Bool

    private let sutunlar = [GridItem(.flexible(), spacing: KI.space3), GridItem(.flexible(), spacing: KI.space3)]
    private var gonderilebilir: Bool { kategori != nil && foto != nil }

    var body: some View {
        NavigationStack {
            Group {
                if gonderildi { basari } else { form }
            }
            .background(KI.zemin.ignoresSafeArea())
            .navigationTitle(gonderildi ? "" : "Yeni bildirim")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(gonderildi ? "Kapat" : "Vazgeç") { kapat() }
                        .foregroundStyle(KI.birincilMetin)
                }
            }
        }
        .onAppear { if kategori == nil { kategori = baslangicKategori } }
        .onChange(of: fotoSecimi) { _, yeni in
            Task {
                if let veri = try? await yeni?.loadTransferable(type: Data.self), let resim = UIImage(data: veri) {
                    withAnimation(KI.egriStandart) { foto = resim }
                }
            }
        }
    }

    // MARK: Form

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KI.space6) {
                bolum(1, "Ne gördün?") {
                    LazyVGrid(columns: sutunlar, spacing: KI.space3) {
                        ForEach(Kategori.allCases) { k in
                            Button { kategori = k } label: {
                                HStack(spacing: KI.space3) {
                                    Image(systemName: k.ikon).font(.system(size: 18, weight: .medium))
                                    Text(k.ad).font(KIFont.govde(14, .yariKalin)).lineLimit(1).minimumScaleFactor(0.8)
                                    Spacer(minLength: 0)
                                }
                                .foregroundStyle(kategori == k ? KI.birincilMetin : KI.metin)
                                .padding(.horizontal, KI.space4)
                                .frame(height: 52)
                                .background(kategori == k ? KI.birincilYumusak : KI.yuzey,
                                            in: RoundedRectangle(cornerRadius: KI.radiusMd, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: KI.radiusMd, style: .continuous)
                                    .stroke(kategori == k ? KI.birincil : KI.cizgi, lineWidth: 1.5))
                            }
                            .buttonStyle(BasmaOlcegi())
                        }
                    }
                }

                bolum(2, "Fotoğraf") {
                    PhotosPicker(selection: $fotoSecimi, matching: .images) {
                        ZStack {
                            if let foto {
                                Image(uiImage: foto)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 200)
                                    .clipped()
                                    .overlay(alignment: .bottomTrailing) {
                                        Label("Değiştir", systemImage: "arrow.triangle.2.circlepath")
                                            .font(KIFont.govde(13, .yariKalin))
                                            .foregroundStyle(KI.metin)
                                            .padding(.horizontal, 12).frame(height: 32)
                                            .background(KI.yuzey, in: Capsule())
                                            .padding(KI.space3)
                                    }
                            } else {
                                VStack(spacing: KI.space2) {
                                    IkonRozeti(ikon: "camera", boyut: 52)
                                    Text("Fotoğraf ekle").font(KIFont.dugme).foregroundStyle(KI.metin)
                                    Text("Sorunu net gösteren bir kare seç.")
                                        .font(KIFont.govdeKucuk).foregroundStyle(KI.metinIkincil)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                            }
                        }
                        .background(KI.yuzey)
                        .clipShape(RoundedRectangle(cornerRadius: KI.radiusLg, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: KI.radiusLg, style: .continuous)
                            .stroke(foto == nil ? KI.cizgiKontrol : Color.clear, style: StrokeStyle(lineWidth: 1.5, dash: [6, 5])))
                    }
                    .buttonStyle(.plain)
                }

                bolum(3, "Konum") {
                    HStack(spacing: KI.space3) {
                        IkonRozeti(ikon: "mappin.and.ellipse")
                        VStack(alignment: .leading, spacing: 2) {
                            Text(konum.izinVar ? "Bulunduğun konum" : "Bornova, İzmir (örnek)")
                                .font(KIFont.govde(15, .yariKalin)).foregroundStyle(KI.metin)
                            Text(konum.izinVar ? "GPS ile alındı" : "Konum izni verirsen tam yer otomatik alınır")
                                .font(KIFont.govde(13)).foregroundStyle(KI.metinIkincil)
                        }
                        Spacer(minLength: 0)
                        if !konum.izinVar {
                            Button("İzin ver", action: konum.izinIste)
                                .font(KIFont.govde(14, .kalin))
                                .foregroundStyle(KI.birincilMetin)
                        }
                    }
                    .kart(dolgu: KI.space4)
                }

                bolum(4, "Açıklama (isteğe bağlı)") {
                    GirdiKutusu(odakta: aciklamaOdak) {
                        TextField("Örn. Kavşakta derin çukur var", text: $aciklama)
                            .focused($aciklamaOdak)
                    }
                }

                Button {
                    gonder()
                } label: {
                    Label("Gönder", systemImage: "paperplane")
                }
                .buttonStyle(BirincilDugme())
                .disabled(!gonderilebilir)

                if !gonderilebilir {
                    Text(kategori == nil ? "Önce bir kategori seç." : "Göndermek için bir fotoğraf ekle.")
                        .font(KIFont.altYazi)
                        .foregroundStyle(KI.metinIkincil)
                        .frame(maxWidth: .infinity)
                        .padding(.top, -KI.space3)
                }
            }
            .padding(KI.space5)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func bolum<I: View>(_ no: Int, _ baslik: String, @ViewBuilder _ icerik: () -> I) -> some View {
        VStack(alignment: .leading, spacing: KI.space3) {
            HStack(spacing: KI.space2) {
                Text("\(no)")
                    .font(KIFont.govde(12, .kalin))
                    .foregroundStyle(KI.onBirincil)
                    .frame(width: 22, height: 22)
                    .background(KI.birincil, in: Circle())
                Text(baslik).font(KIFont.kartBasligi).foregroundStyle(KI.metin)
            }
            icerik()
        }
    }

    // MARK: Başarı

    private var basari: some View {
        VStack(spacing: KI.space4) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 84))
                .foregroundStyle(KI.cozuldu)
                .symbolEffect(.bounce, value: gonderildi)
            Text("İhbarın iletildi").font(KIFont.ekranBasligi).foregroundStyle(KI.metin)
            Text("Bornova Belediyesi'ne ulaştı. Durumu değiştiğinde sana haber vereceğiz.")
                .font(KIFont.govdeMetni)
                .foregroundStyle(KI.metinIkincil)
                .multilineTextAlignment(.center)
            DurumRozeti(durum: .beklemede)
            Spacer()
            Button("Tamam") { kapat() }
                .buttonStyle(BirincilDugme())
        }
        .padding(KI.space5)
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }

    private func gonder() {
        guard let kategori else { return }
        let yer = konum.konum ?? CLLocationCoordinate2D(latitude: OrnekVeri.bornova.latitude + Double.random(in: -0.008...0.008),
                                                        longitude: OrnekVeri.bornova.longitude + Double.random(in: -0.008...0.008))
        let yeni = Ihbar(kategori: kategori, durum: .beklemede,
                         aciklama: aciklama.isEmpty ? "Açıklama eklenmedi." : aciklama,
                         adres: konum.izinVar ? "Bulunduğun konum" : "Bornova, İzmir",
                         koordinat: yer, tarih: Date(), foto: foto, benim: true)
        durum.ihbarEkle(yeni)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { gonderildi = true }
    }
}
