import SwiftUI
import Combine

// MARK: - Giriş

struct GirisEkrani: View {
    @EnvironmentObject private var durum: UygulamaDurumu

    enum Yontem: Hashable { case telefon, eposta }
    enum Alan: Hashable { case telefon, eposta }

    @State private var yontem: Yontem = .telefon
    @State private var telefon = ""
    @State private var eposta = ""
    @State private var dogrulamaGoster = false
    @State private var edevletUyari = false
    @FocusState private var odak: Alan?

    private var telefonRakam: String { telefon.filter(\.isNumber) }
    private var epostaGecerli: Bool {
        let p = eposta.split(separator: "@")
        return p.count == 2 && p[1].contains(".") && !p[0].isEmpty
    }
    private var gonderilebilir: Bool {
        yontem == .telefon ? telefonRakam.count == 10 : epostaGecerli
    }
    private var epostaHatali: Bool { !eposta.isEmpty && odak != .eposta && !epostaGecerli }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                KentIllustrasyonu()
                    .frame(height: 250)

                VStack(alignment: .leading, spacing: KI.space5) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Kent İhbar")
                            .font(KIFont.baslik(32))
                            .tracking(-0.6)
                            .foregroundStyle(KI.metin)
                        Text("Şehrini daha iyi bir yer yap.")
                            .font(KIFont.govde(15))
                            .foregroundStyle(KI.metinIkincil)
                    }

                    form

                    Button("Misafir olarak devam et") {
                        withAnimation(.easeInOut(duration: KI.sureYavas)) { durum.oturum = .misafir }
                    }
                    .buttonStyle(MetinDugme())
                    .frame(maxWidth: .infinity)

                    Text(yasalMetin)
                        .font(KIFont.govde(12, .orta))
                        .foregroundStyle(KI.metinIkincil)
                        .multilineTextAlignment(.center)
                        .tint(KI.birincilMetin)
                        .frame(maxWidth: .infinity)
                        .padding(.top, KI.space2)
                }
                .padding(.horizontal, KI.space5)
                .padding(.bottom, KI.space6)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(KI.zemin.ignoresSafeArea())
        .ignoresSafeArea(edges: .top)
        .navigationDestination(isPresented: $dogrulamaGoster) {
            DogrulamaEkrani(hedef: yontem == .telefon ? maskeliTelefon : eposta)
        }
        .alert("e-Devlet ile giriş", isPresented: $edevletUyari) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text("Bu prototipte e-Devlet entegrasyonu bağlı değil. Gerçek kullanım için Türkiye.gov.tr resmî entegrasyonu gerekir.")
        }
    }

    private var form: some View {
        VStack(spacing: KI.space4) {
            Segment(secenekler: [SegmentSecenegi(deger: Yontem.telefon, baslik: "Telefon", ikon: "phone"),
                                 SegmentSecenegi(deger: Yontem.eposta, baslik: "E-posta", ikon: "envelope")],
                    secili: $yontem)

            if yontem == .telefon {
                VStack(alignment: .leading, spacing: 6) {
                    AlanEtiketi(metin: "Telefon numarası")
                    GirdiKutusu(odakta: odak == .telefon) {
                        Text("+90").font(KIFont.govde(16, .yariKalin))
                        Rectangle().fill(KI.cizgi).frame(width: 1, height: 24)
                        TextField("5__ ___ __ __", text: $telefon)
                            .keyboardType(.numberPad)
                            .textContentType(.telephoneNumber)
                            .focused($odak, equals: .telefon)
                            .onChange(of: telefon) { _, yeni in
                                let bicimli = Self.bicimle(yeni)
                                if bicimli != yeni { telefon = bicimli }
                            }
                    }
                    Text("Doğrulama kodunu SMS ile göndereceğiz.")
                        .font(KIFont.altYazi).foregroundStyle(KI.metinIkincil)
                }
                .transition(.opacity)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    AlanEtiketi(metin: "E-posta")
                    GirdiKutusu(odakta: odak == .eposta, hata: epostaHatali) {
                        Image(systemName: "envelope").foregroundStyle(KI.metinSoluk)
                        TextField("ornek@eposta.com", text: $eposta)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($odak, equals: .eposta)
                    }
                    Text(epostaHatali ? "Geçerli bir e-posta adresi gir." : "Giriş bağlantısı ve kodu e-postana göndereceğiz.")
                        .font(KIFont.altYazi)
                        .foregroundStyle(epostaHatali ? KI.kritik : KI.metinIkincil)
                }
                .transition(.opacity)
            }

            Button("Kod gönder") {
                odak = nil
                dogrulamaGoster = true
            }
            .buttonStyle(BirincilDugme())
            .disabled(!gonderilebilir)

            Ayirici(metin: "veya")

            Button {
                edevletUyari = true
            } label: {
                Label("e-Devlet ile giriş yap", systemImage: "building.columns")
            }
            .buttonStyle(IkincilDugme())
        }
        .kart()
        .animation(KI.egriStandart, value: yontem)
    }

    private var yasalMetin: AttributedString {
        (try? AttributedString(markdown: "Devam ederek **[Kullanım koşulları](https://example.com/kosullar)** ve **[KVKK Aydınlatma Metni](https://example.com/kvkk)**'ni kabul etmiş olursun.")) ?? AttributedString("")
    }

    private var maskeliTelefon: String {
        let r = Array(telefonRakam)
        guard r.count == 10 else { return telefon }
        return "+90 \(String(r[0...2])) ••• •• \(String(r[8...9]))"
    }

    /// "5324182705" → "532 418 27 05"
    static func bicimle(_ girdi: String) -> String {
        let r = Array(girdi.filter(\.isNumber).prefix(10))
        var cikti = ""
        for (i, c) in r.enumerated() {
            if i == 3 || i == 6 || i == 8 { cikti.append(" ") }
            cikti.append(c)
        }
        return cikti
    }
}

// MARK: - Doğrulama kodu

struct DogrulamaEkrani: View {
    let hedef: String
    @EnvironmentObject private var durum: UygulamaDurumu
    @Environment(\.dismiss) private var kapat

    @State private var kod = ""
    @State private var kalan = 60
    @State private var hata = false
    @State private var salla: CGFloat = 0
    @FocusState private var odakta: Bool
    private let zamanlayici = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: KI.space5) {
            Button { kapat() } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(KI.metin)
                    .frame(width: 44, height: 44)
            }
            .padding(.leading, -10)
            .accessibilityLabel("Geri")

            VStack(alignment: .leading, spacing: KI.space2) {
                Text("Doğrulama kodu").font(KIFont.ekranBasligi).foregroundStyle(KI.metin)
                Text("\(hedef) için gönderdiğimiz 6 haneli kodu gir.")
                    .font(KIFont.govde(15))
                    .foregroundStyle(KI.metinIkincil)
            }

            ZStack {
                // Gerçek giriş: görünmez alan, SMS kodunu otomatik doldurur.
                TextField("", text: $kod)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .focused($odakta)
                    .opacity(0.01)
                    .onChange(of: kod) { _, yeni in
                        let temiz = String(yeni.filter(\.isNumber).prefix(6))
                        if temiz != yeni { kod = temiz }
                        hata = false
                        if temiz.count == 6 { dogrula() }
                    }
                HStack(spacing: 10) {
                    ForEach(0..<6, id: \.self) { i in kutu(i) }
                }
                .modifier(Sallanma(miktar: salla))
                .contentShape(Rectangle())
                .onTapGesture { odakta = true }
            }

            HStack {
                Text(hata ? "Kod hatalı, tekrar dene." : "Kod gelmedi mi?")
                    .font(KIFont.altYazi)
                    .foregroundStyle(hata ? KI.kritik : KI.metinIkincil)
                Spacer()
                Button(kalan > 0 ? "Tekrar gönder · 0:\(String(format: "%02d", kalan))" : "Tekrar gönder") {
                    kalan = 60
                }
                .buttonStyle(MetinDugme())
                .disabled(kalan > 0)
            }
            .padding(.top, -KI.space2)

            Text("Prototip: 000000 dışındaki herhangi bir 6 haneli kod kabul edilir.")
                .font(KIFont.altYazi)
                .foregroundStyle(KI.metinSoluk)

            Spacer()

            HStack(spacing: KI.space3) {
                Image(systemName: "checkmark.shield")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(KI.birincilMetin)
                Text("Kodu kimseyle paylaşma. Belediye çalışanları kodunu asla sormaz.")
                    .font(KIFont.govde(14, .orta))
                    .foregroundStyle(KI.metin)
            }
            .padding(KI.space4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(KI.birincilYumusak, in: RoundedRectangle(cornerRadius: KI.radiusLg, style: .continuous))

            Button("Doğrula") { dogrula() }
                .buttonStyle(BirincilDugme())
                .disabled(kod.count < 6)
        }
        .padding(.horizontal, KI.space5)
        .padding(.bottom, KI.space4)
        .background(KI.zemin.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .onAppear { odakta = true }
        .onReceive(zamanlayici) { _ in if kalan > 0 { kalan -= 1 } }
    }

    private func kutu(_ i: Int) -> some View {
        let rakamlar = Array(kod)
        let dolu = i < rakamlar.count
        let aktif = odakta && i == min(rakamlar.count, 5) && !dolu
        let sekil = RoundedRectangle(cornerRadius: KI.radiusMd, style: .continuous)
        return ZStack {
            if dolu {
                Text(String(rakamlar[i])).font(KIFont.baslik(22)).foregroundStyle(KI.metin)
                    .transition(.scale.combined(with: .opacity))
            } else if aktif {
                RoundedRectangle(cornerRadius: 1).fill(KI.birincil).frame(width: 2, height: 24)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 58)
        .background(sekil.fill(KI.yuzey))
        .overlay(sekil.stroke(hata ? KI.kritik : ((dolu || aktif) ? KI.birincil : KI.cizgiKontrol), lineWidth: 1.5))
        .background(sekil.stroke(KI.birincilYumusak, lineWidth: aktif ? 8 : 0))
        .animation(.easeOut(duration: KI.sureHizli), value: kod)
    }

    private func dogrula() {
        guard kod.count == 6 else { return }
        if kod == "000000" {
            hata = true
            withAnimation(.linear(duration: 0.35)) { salla += 1 }
            kod = ""
            return
        }
        odakta = false
        withAnimation(.easeInOut(duration: KI.sureYavas)) {
            durum.oturum = .uye(telefon: hedef)
        }
    }
}

struct Sallanma: GeometryEffect {
    var miktar: CGFloat
    var animatableData: CGFloat {
        get { miktar }
        set { miktar = newValue }
    }
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 8 * sin(miktar * .pi * 4), y: 0))
    }
}

// MARK: - Kent illüstrasyonu (tokenlardan çizilen kent planı)

struct KentIllustrasyonu: View {
    @State private var goster = false

    var body: some View {
        GeometryReader { geo in
            let s = geo.size.width / 390
            ZStack(alignment: .topLeading) {
                blok(KI.birincilYumusak, x: -20, y: 40, w: 150, h: 190, s: s, gecikme: 0)
                blok(KI.birincil, x: 146, y: -20, w: 96, h: 250, s: s, gecikme: 0.08)
                blok(KI.maviRenk, x: 258, y: 70, w: 152, h: 160, s: s, gecikme: 0.16)
                blok(KI.birincilYumusak, x: 258, y: -20, w: 72, h: 74, s: s, gecikme: 0.24)
                pin(x: 194, y: 200, r: 13, s: s, gecikme: 0.45)
                pin(x: 60, y: 96, r: 9, s: s, gecikme: 0.55)
                pin(x: 330, y: 180, r: 9, s: s, gecikme: 0.65)
            }
        }
        .clipped()
        .accessibilityHidden(true)
        .onAppear { goster = true }
    }

    private func blok(_ renk: Color, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, s: CGFloat, gecikme: Double) -> some View {
        RoundedRectangle(cornerRadius: 20 * s, style: .continuous)
            .fill(renk)
            .frame(width: w * s, height: h * s)
            .offset(x: x * s, y: (goster ? y : y + 80) * s)
            .opacity(goster ? 1 : 0)
            .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(gecikme), value: goster)
    }

    private func pin(x: CGFloat, y: CGFloat, r: CGFloat, s: CGFloat, gecikme: Double) -> some View {
        ZStack {
            Circle().fill(KI.zemin).frame(width: 2 * r * s, height: 2 * r * s)
            Circle().fill(KI.birincil).frame(width: 0.8 * r * s, height: 0.8 * r * s)
        }
        .offset(x: (x - r) * s, y: (goster ? y - r : y - r - 40) * s)
        .opacity(goster ? 1 : 0)
        .animation(.spring(response: 0.45, dampingFraction: 0.55).delay(gecikme), value: goster)
    }
}
