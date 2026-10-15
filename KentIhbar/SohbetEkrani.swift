import SwiftUI
import Lottie

struct SohbetMesaji: Identifiable, Equatable {
    let id = UUID()
    let metin: String
    let benden: Bool
}

/// Kent asistanı sohbeti. Şimdilik sunucuya bağlı değil: yanıtlar cihazdaki
/// `KentAsistani.yanit(_:)` kurallarından gelir.
struct SohbetEkrani: View {
    @Environment(\.dismiss) private var kapat

    @State private var mesajlar: [SohbetMesaji] = [
        SohbetMesaji(metin: "Merhaba! Ben Kent asistanı. Sorun bildirme, harita ya da belediye sıralaması hakkında sorabilirsin.", benden: false)
    ]
    @State private var taslak = ""
    @State private var yaziyor = false
    @FocusState private var odak: Bool

    private let oneriler = ["Nasıl ihbar ederim?", "İhbarım ne durumda?", "Sıralama nasıl hesaplanıyor?"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { kaydir in
                    ScrollView {
                        LazyVStack(spacing: KI.space3) {
                            LottieView(animation: .named("robot"))
                                .imageProvider(RobotKareleri.ortak)
                                .playing(loopMode: .loop)
                                .resizable()
                                .frame(width: 148, height: 120)
                                .padding(.top, KI.space2)
                                .accessibilityHidden(true)

                            ForEach(mesajlar) { m in
                                Balon(mesaj: m).id(m.id)
                            }
                            if yaziyor {
                                YaziyorBalonu().id("yaziyor")
                            }
                        }
                        .padding(.horizontal, KI.space4)
                        .padding(.bottom, KI.space3)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: mesajlar) { _, yeni in
                        withAnimation(KI.egriStandart) { kaydir.scrollTo(yeni.last?.id, anchor: .bottom) }
                    }
                    .onChange(of: yaziyor) { _, y in
                        if y { withAnimation(KI.egriStandart) { kaydir.scrollTo("yaziyor", anchor: .bottom) } }
                    }
                }

                if mesajlar.count == 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: KI.space2) {
                            ForEach(oneriler, id: \.self) { o in
                                Button { gonder(o) } label: { FiltreCipi(baslik: o) }
                                    .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, KI.space4)
                    }
                    .padding(.bottom, KI.space2)
                }

                giris
            }
            .background(KI.zemin)
            .navigationTitle("Kent Asistanı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { kapat() } label: {
                        Image(systemName: "xmark").font(.system(size: 15, weight: .semibold))
                    }
                    .accessibilityLabel("Kapat")
                }
            }
        }
    }

    private var giris: some View {
        HStack(spacing: KI.space2) {
            GirdiKutusu(odakta: odak, hap: true) {
                TextField("Bir şey sor…", text: $taslak, axis: .vertical)
                    .lineLimit(1...4)
                    .focused($odak)
                    .submitLabel(.send)
                    .onSubmit { gonder(taslak) }
            }
            Button { gonder(taslak) } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(KI.onBirincil)
                    .frame(width: 48, height: 48)
                    .background(bosMu ? KI.metinSoluk : KI.birincil, in: Circle())
            }
            .disabled(bosMu)
            .accessibilityLabel("Gönder")
        }
        .padding(.horizontal, KI.space4)
        .padding(.vertical, KI.space3)
        .background(KI.yuzey)
        .overlay(alignment: .top) { Rectangle().fill(KI.cizgi).frame(height: 1) }
    }

    private var bosMu: Bool { taslak.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    private func gonder(_ metin: String) {
        let t = metin.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, !yaziyor else { return }
        taslak = ""
        mesajlar.append(SohbetMesaji(metin: t, benden: true))
        yaziyor = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            yaziyor = false
            mesajlar.append(SohbetMesaji(metin: KentAsistani.yanit(t), benden: false))
        }
    }
}

/// Basit anahtar kelime kuralları — gerçek bir asistan servisi bağlanınca değiştirilecek.
enum KentAsistani {
    static func yanit(_ soru: String) -> String {
        let s = soru.lowercased(with: Locale(identifier: "tr_TR"))
        func var_(_ k: String...) -> Bool { k.contains { s.contains($0) } }
        if var_("ihbar", "bildir", "sorun", "nasıl") {
            return "Ana sayfadaki \"Sorun mu gördün?\" kartına ya da alttaki Bildir düğmesine dokun. Kategori seç, fotoğraf ekle; konumu otomatik alırız ve ihbarın ilgili belediyeye iletilir."
        }
        if var_("durum", "ne oldu", "takip") {
            return "Gönderdiğin ihbarları ana sayfadaki \"Bildirimlerim\" bölümünde Açık ve Çözülen olarak takip edebilirsin."
        }
        if var_("sıralama", "puan", "belediye") {
            return "Belediyeler çözüm hızı, vatandaş memnuniyeti ve aylık çözülen ihbar sayısına göre 100 üzerinden puanlanır. Sıralama sekmesinde ölçütü değiştirebilirsin."
        }
        if var_("harita", "yakın", "çevre") {
            return "Canlı Harita'da çevrendeki ihbarları durumlarına göre görebilirsin. Konum izni verirsen ilçene odaklanır."
        }
        if var_("merhaba", "selam") {
            return "Merhaba! Sana nasıl yardımcı olabilirim?"
        }
        return "Bunu henüz bilmiyorum. İhbar oluşturma, ihbar takibi, harita ve belediye sıralaması hakkında yardımcı olabilirim."
    }
}

private struct Balon: View {
    let mesaj: SohbetMesaji
    var body: some View {
        HStack {
            if mesaj.benden { Spacer(minLength: 48) }
            Text(mesaj.metin)
                .font(KIFont.govde(15))
                .foregroundStyle(mesaj.benden ? KI.onBirincil : KI.metin)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(mesaj.benden ? KI.birincil : KI.yuzey,
                            in: UnevenRoundedRectangle(topLeadingRadius: 18,
                                                       bottomLeadingRadius: mesaj.benden ? 18 : 6,
                                                       bottomTrailingRadius: mesaj.benden ? 6 : 18,
                                                       topTrailingRadius: 18))
                .shadow(color: .black.opacity(mesaj.benden ? 0 : 0.05), radius: 6, x: 0, y: 3)
            if !mesaj.benden { Spacer(minLength: 48) }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

/// Videodaki "•••" baloncuğu.
private struct YaziyorBalonu: View {
    @State private var faz = 0
    private let zaman = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()
    var body: some View {
        HStack {
            HStack(spacing: 5) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(KI.birincil.opacity(faz == i ? 1 : 0.35))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 40)
            .background(KI.yuzey, in: Capsule())
            Spacer()
        }
        .onReceive(zaman) { _ in faz = (faz + 1) % 3 }
        .accessibilityLabel("Asistan yazıyor")
    }
}
