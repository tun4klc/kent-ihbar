import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'ekranlar/ana_kabuk.dart';
import 'ekranlar/giris_ekrani.dart';
import 'kapsam.dart';
import 'konum.dart';
import 'model.dart';
import 'tema.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(KentIhbarUygulamasi(durum: UygulamaDurumu()));
}

class KentIhbarUygulamasi extends StatefulWidget {
  const KentIhbarUygulamasi({super.key, required this.durum, this.konum});

  final UygulamaDurumu durum;

  /// Testlerde sahte konum yöneticisi verilebilir.
  final KonumYoneticisi? konum;

  @override
  State<KentIhbarUygulamasi> createState() => _KentIhbarUygulamasiState();
}

class _KentIhbarUygulamasiState extends State<KentIhbarUygulamasi> {
  late final KonumYoneticisi _konum = widget.konum ?? KonumYoneticisi();

  @override
  void dispose() {
    if (widget.konum == null) _konum.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DurumKapsami(
      durum: widget.durum,
      child: KonumKapsami(
        konum: _konum,
        child: MaterialApp(
          title: 'Kent İhbar',
          debugShowCheckedModeBanner: false,
          theme: kiTema(Brightness.light),
          darkTheme: kiTema(Brightness.dark),
          locale: const Locale('tr', 'TR'),
          supportedLocales: const [Locale('tr', 'TR')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const KokGorunum(),
        ),
      ),
    );
  }
}

class KokGorunum extends StatelessWidget {
  const KokGorunum({super.key});

  @override
  Widget build(BuildContext context) {
    final durum = DurumKapsami.of(context);
    return AnimatedSwitcher(
      duration: KI.sureYavas,
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      child: durum.girisGerekli ? const GirisEkrani(key: ValueKey('giris')) : const AnaKabuk(key: ValueKey('uygulama')),
    );
  }
}
