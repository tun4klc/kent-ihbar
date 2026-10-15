import SwiftUI

@main
struct KentIhbarApp: App {
    @StateObject private var durum = UygulamaDurumu()

    init() {
        KIFont.kaydet()
    }

    var body: some Scene {
        WindowGroup {
            KokGorunum()
                .environmentObject(durum)
                .tint(KI.birincil)
        }
    }
}

struct KokGorunum: View {
    @EnvironmentObject private var durum: UygulamaDurumu

    var body: some View {
        ZStack {
            if durum.girisGerekli {
                NavigationStack { GirisEkrani() }
                    .transition(.opacity)
            } else {
                AnaKabuk()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: KI.sureYavas), value: durum.girisGerekli)
    }
}

#Preview("Giriş") {
    KokGorunum().environmentObject(UygulamaDurumu())
}

#Preview("Uygulama") {
    let d = UygulamaDurumu()
    d.oturum = .uye(telefon: "+90 532 ••• •• 05")
    return KokGorunum().environmentObject(d)
}
