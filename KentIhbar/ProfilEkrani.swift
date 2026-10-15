import SwiftUI

struct ProfilEkrani: View {
    @EnvironmentObject private var durum: UygulamaDurumu
    @State private var cikisOnayi = false

    private var surum: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Sürüm \(v)+\(b)"
    }

    private var benimIhbarlarim: Int { durum.ihbarlar.filter(\.benim).count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KI.space5) {
                Text("Profil").font(KIFont.ekranBasligi).foregroundStyle(KI.metin)

                profilKarti

                MenuGrubu(baslik: "Hızlı erişim") {
                    MenuSatiri(ikon: "questionmark.circle", baslik: "Sıkça sorulan sorular")
                    MenuSatiri(ikon: "globe", baslik: "Dil", deger: "Türkçe")
                    ShareLink(item: "Kent İhbar: şehrindeki sorunları fotoğraf ve konumla belediyene ilet.") {
                        MenuSatiri(ikon: "square.and.arrow.up", baslik: "Uygulamayı paylaş", ayiriciVar: false)
                    }
                    .buttonStyle(.plain)
                }

                MenuGrubu(baslik: "Yasal") {
                    MenuSatiri(ikon: "checkmark.shield", baslik: "Gizlilik ve KVKK")
                    MenuSatiri(ikon: "doc.text", baslik: "Kullanım koşulları", ayiriciVar: durum.uyeMi)
                    if durum.uyeMi {
                        Button { cikisOnayi = true } label: {
                            HStack(spacing: KI.space4) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 19, weight: .medium))
                                    .frame(width: 24)
                                Text("Çıkış yap").font(KIFont.dugme)
                                Spacer()
                            }
                            .foregroundStyle(KI.kritik)
                            .padding(.horizontal, KI.space4)
                            .frame(minHeight: 58)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text(surum).font(KIFont.altYazi).foregroundStyle(KI.metinSoluk)
            }
            .padding(.horizontal, KI.space5)
            .padding(.top, KI.space2)
            .padding(.bottom, KI.space8)
        }
        .background(KI.zemin)
        .confirmationDialog("Çıkış yapmak istiyor musun?", isPresented: $cikisOnayi, titleVisibility: .visible) {
            Button("Çıkış yap", role: .destructive) {
                withAnimation(.easeInOut(duration: KI.sureYavas)) { durum.oturum = .yok }
            }
        }
    }

    @ViewBuilder private var profilKarti: some View {
        if case .uye(let hedef) = durum.oturum {
            HStack(spacing: 14) {
                Text("T")
                    .font(KIFont.baslik(18))
                    .foregroundStyle(KI.birincilMetin)
                    .frame(width: 48, height: 48)
                    .background(KI.birincilYumusak, in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hoş geldin").font(KIFont.kartBasligi).foregroundStyle(KI.metin)
                    Text(hedef).font(KIFont.govdeKucuk).foregroundStyle(KI.metinIkincil)
                }
                Spacer()
                VStack(spacing: 0) {
                    Text("\(benimIhbarlarim)").font(KIFont.baslik(20)).foregroundStyle(KI.birincilMetin)
                    Text("İhbarım").font(KIFont.altYazi).foregroundStyle(KI.metinIkincil)
                }
            }
            .kart()
        } else {
            VStack(spacing: KI.space4) {
                HStack(spacing: 14) {
                    Image(systemName: "person")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(KI.birincilMetin)
                        .frame(width: 48, height: 48)
                        .background(KI.birincilYumusak, in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Misafir").font(KIFont.kartBasligi).foregroundStyle(KI.metin)
                        Text("İhbar oluşturmak ve takip etmek için giriş yap.")
                            .font(KIFont.govdeKucuk)
                            .foregroundStyle(KI.metinIkincil)
                    }
                    Spacer(minLength: 0)
                }
                Button("Giriş yap") {
                    withAnimation(.easeInOut(duration: KI.sureYavas)) { durum.oturum = .yok }
                }
                .buttonStyle(BirincilDugme())
            }
            .kart()
        }
    }
}
