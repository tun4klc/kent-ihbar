import SwiftUI
import Lottie

/// Sağ altta yaşayan asistan robotu (robot.json). Dokununca sohbet açılır.
struct AsistanRobotu: View {
    var ac: () -> Void
    @Environment(\.accessibilityReduceMotion) private var hareketAzalt
    @State private var suzul = false

    var body: some View {
        Button(action: ac) {
            Group {
                if hareketAzalt {
                    LottieView(animation: .named("robot"))
                        .imageProvider(RobotKareleri.ortak)
                        .playbackMode(.paused(at: .frame(0)))
                        .resizable()
                } else {
                    CanliRobot()
                }
            }
            .frame(width: 104, height: 84)
            .offset(y: suzul ? -3 : 2)
            .shadow(color: KI.maviRenk.opacity(0.22), radius: 10, x: 0, y: 8)
        }
        .buttonStyle(BasmaOlcegi())
        .accessibilityLabel("Kent asistanı ile sohbet et")
        .onAppear {
            guard !hareketAzalt else { return }
            withAnimation(.easeInOut(duration: 1.7).repeatForever(autoreverses: true)) { suzul = true }
        }
    }
}

// MARK: - Klipler

/// robot.json içindeki kare aralıkları (dosyadaki `markers` ile aynı).
/// Bekleme klipleri her seferinde farklı bir alt aralıktan, bazen geriye doğru oynatılır;
/// hareket klipleri art arda tekrar etmez. Böylece robot hep aynı sırayla hareket etmez.
private enum RobotKlibi: CaseIterable {
    case bekleme1, bekleme2, selam, yakinSelam, ikiEl, goz

    var aralik: ClosedRange<Int> {
        switch self {
        case .bekleme1: return 0...23
        case .bekleme2: return 195...227
        case .selam: return 24...49
        case .yakinSelam: return 60...113
        case .ikiEl: return 128...147
        case .goz: return 165...194
        }
    }
    var beklemeMi: Bool { self == .bekleme1 || self == .bekleme2 }
    static let hareketler: [RobotKlibi] = [.selam, .yakinSelam, .ikiEl, .goz]
}

private struct Oynatma: Equatable {
    var bas: CGFloat
    var son: CGFloat
    var hiz: CGFloat
}

/// Sıradaki oynatmayı seçer: bekleme → hareket → bekleme … ; son iki hareket tekrar edilmez.
private struct KlipSecici {
    private var sonHareketler: [RobotKlibi] = []
    private var siradaBekleme = true

    mutating func siradaki() -> Oynatma {
        defer { siradaBekleme.toggle() }
        if siradaBekleme {
            let k = Bool.random() ? RobotKlibi.bekleme1 : .bekleme2
            let r = k.aralik
            // Rastgele uzunlukta bir alt aralık, rastgele yönde
            let uzunluk = Int.random(in: max(10, r.count / 2)...r.count)
            let bas = Int.random(in: r.lowerBound...(r.upperBound - uzunluk + 1))
            let son = bas + uzunluk - 1
            let geri = Bool.random()
            return Oynatma(bas: CGFloat(geri ? son : bas), son: CGFloat(geri ? bas : son),
                           hiz: .random(in: 0.75...1.0))
        }
        let adaylar = RobotKlibi.hareketler.filter { !sonHareketler.suffix(2).contains($0) }
        let k = adaylar.randomElement() ?? .selam
        sonHareketler.append(k)
        return Oynatma(bas: CGFloat(k.aralik.lowerBound), son: CGFloat(k.aralik.upperBound),
                       hiz: .random(in: 0.9...1.1))
    }
}

/// İki Lottie katmanı: biri oynarken sıradaki klip diğerinde başlar ve 0,3 sn'de üstüne karışır.
private struct CanliRobot: View {
    @State private var secici = KlipSecici()
    @State private var katmanlar: [Oynatma] = [Oynatma(bas: 0, son: 23, hiz: 0.9), Oynatma(bas: 0, son: 0, hiz: 1)]
    @State private var onde = 0
    /// Aynı katmana aynı aralık iki kez gelirse Lottie yeniden başlatsın diye eklenen küçük fark.
    @State private var dokunus: [CGFloat] = [0, 0]

    var body: some View {
        ZStack {
            ForEach(0..<2, id: \.self) { i in
                let o = katmanlar[i]
                LottieView(animation: .named("robot"))
                    .imageProvider(RobotKareleri.ortak)
                    .playbackMode(.playing(.fromFrame(o.bas, toFrame: o.son + dokunus[i], loopMode: .playOnce)))
                    .animationSpeed(o.hiz)
                    .animationDidFinish { tamamlandi in
                        if tamamlandi && i == onde { sonraki() }
                    }
                    .resizable()
                    .opacity(i == onde ? 1 : 0)
            }
        }
    }

    private func sonraki() {
        let arka = 1 - onde
        katmanlar[arka] = secici.siradaki()
        dokunus[arka] = dokunus[arka] == 0 ? 0.001 : 0
        withAnimation(.easeInOut(duration: 0.3)) { onde = arka }
    }
}

// MARK: - Ortak kare önbelleği

/// robot.json'daki gömülü WebP kareleri bir kez çözer ve tüm Lottie görünümlerine aynı
/// görselleri verir. Yoksa her LottieView 228 kareyi ayrı ayrı açar (~50 MB/görünüm).
final class RobotKareleri: AnimationImageProvider, Equatable {
    static let ortak = RobotKareleri()
    static func == (a: RobotKareleri, b: RobotKareleri) -> Bool { a === b }
    private var onbellek: [String: CGImage] = [:]
    private let kilit = NSLock()

    func imageForAsset(asset: ImageAsset) -> CGImage? {
        kilit.lock(); defer { kilit.unlock() }
        if let g = onbellek[asset.id] { return g }
        guard asset.name.hasPrefix("data:"),
              let virgul = asset.name.firstIndex(of: ","),
              let veri = Data(base64Encoded: String(asset.name[asset.name.index(after: virgul)...])),
              let gorsel = UIImage(data: veri)?.cgImage
        else { return nil }
        onbellek[asset.id] = gorsel
        return gorsel
    }
}
