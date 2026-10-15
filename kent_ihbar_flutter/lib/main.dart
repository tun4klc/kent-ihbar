import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'ekranlar/ana_kabuk.dart';
import 'ekranlar/giris_ekrani.dart';
import 'firebase_options.dart';
import 'kapsam.dart';
import 'konum.dart';
import 'model.dart';
import 'tema.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final secenekler = DefaultFirebaseOptions.currentPlatform;
  try {
    // iOS'ta GoogleService-Info.plist varsa seçenek vermeden de başlar.
    await Firebase.initializeApp(options: secenekler);
  } catch (e) {
    debugPrint('Firebase başlatılamadı, telefonla giriş kapalı: $e');
  }
  final durum = UygulamaDurumu();
  runApp(KentIhbarUygulamasi(durum: durum));
  unawaited(durum.baslat());
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
