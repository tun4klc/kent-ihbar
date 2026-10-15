import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'tema.dart';

// MARK: - Oturum

sealed class Oturum {
  const Oturum();
}

class OturumYok extends Oturum {
  const OturumYok();
}

class OturumMisafir extends Oturum {
  const OturumMisafir();
}

class OturumUye extends Oturum {
  const OturumUye(this.telefon);
  final String telefon;
}

class UygulamaDurumu extends ChangeNotifier {
  Oturum _oturum = const OturumYok();
  final List<Ihbar> ihbarlar = OrnekVeri.ihbarlar();

  Oturum get oturum => _oturum;
  set oturum(Oturum yeni) {
    _oturum = yeni;
    notifyListeners();
  }

  bool get girisGerekli => _oturum is OturumYok;
  bool get uyeMi => _oturum is OturumUye;

  void ihbarEkle(Ihbar ihbar) {
    ihbarlar.insert(0, ihbar);
    notifyListeners();
  }
}

// MARK: - Durum & kategori

enum Durum {
  kritik,
  beklemede,
  cozuldu;

  String get ad => switch (this) {
    Durum.kritik => 'Kritik',
    Durum.beklemede => 'Beklemede',
    Durum.cozuldu => 'Çözüldü',
  };

  Color renk(KIRenk r) => switch (this) {
    Durum.kritik => r.kritik,
    Durum.beklemede => r.beklemede,
    Durum.cozuldu => r.cozuldu,
  };

  Color yumusak(KIRenk r) => switch (this) {
    Durum.kritik => r.kritikYumusak,
    Durum.beklemede => r.beklemedeYumusak,
    Durum.cozuldu => r.cozulduYumusak,
  };

  /// Renk körlüğü için her durum kendi ikonunu taşır.
  IconData get ikon => switch (this) {
    Durum.kritik => Icons.warning_rounded,
    Durum.beklemede => Icons.schedule_rounded,
    Durum.cozuldu => Icons.check_rounded,
  };
}

enum Kategori {
  yolCukuru,
  cop,
  lamba,
  su,
  park,
  diger;

  String get ad => switch (this) {
    Kategori.yolCukuru => 'Yol Çukuru',
    Kategori.cop => 'Çöp Birikintisi',
    Kategori.lamba => 'Bozuk Lamba',
    Kategori.su => 'Su Sızıntısı',
    Kategori.park => 'Park & Yeşil',
    Kategori.diger => 'Diğer',
  };

  IconData get ikon => switch (this) {
    Kategori.yolCukuru => Icons.warning_amber_rounded,
    Kategori.cop => Icons.delete_outline_rounded,
    Kategori.lamba => Icons.lightbulb_outline_rounded,
    Kategori.su => Icons.water_drop_outlined,
    Kategori.park => Icons.eco_outlined,
    Kategori.diger => Icons.grid_view_rounded,
  };

  /// Kategori kutusundaki ikon rengi (Şehir İhbar'daki renk ailesi, Kent İhbar tonlarında).
  Color renk(KIRenk r) => switch (this) {
    Kategori.yolCukuru => r.sec(0xC2410C, 0xFB923C),
    Kategori.cop => r.sec(0x047857, 0x34D399),
    Kategori.lamba => r.sec(0xB45309, 0xFBBF24),
    Kategori.su => r.birincilMetin,
    Kategori.park => r.sec(0x0F766E, 0x2DD4BF),
    Kategori.diger => r.sec(0x6D28D9, 0xA78BFA),
  };

  Color yumusak(KIRenk r) => switch (this) {
    Kategori.yolCukuru => r.sec(0xFFEDD5, 0x3A2010),
    Kategori.cop => r.sec(0xD1FAE5, 0x0B2E24),
    Kategori.lamba => r.sec(0xFEF3C7, 0x36290A),
    Kategori.su => r.birincilYumusak,
    Kategori.park => r.sec(0xCCFBF1, 0x0A2E2A),
    Kategori.diger => r.sec(0xEDE9FE, 0x221A40),
  };
}

int _sonId = 0;

class Ihbar {
  Ihbar({
    required this.kategori,
    required this.durum,
    required this.aciklama,
    required this.adres,
    required this.koordinat,
    required this.tarih,
    this.foto,
    this.benim = false,
  }) : id = ++_sonId;

  final int id;
  final Kategori kategori;
  final Durum durum;
  final String aciklama;
  final String adres;
  final LatLng koordinat;
  final DateTime tarih;
  final Uint8List? foto;
  final bool benim;
}

class Belediye {
  const Belediye({
    required this.ad,
    required this.sehir,
    required this.ortalamaGun,
    required this.memnuniyet,
    required this.aylikCozum,
    required this.puan,
    this.senin = false,
  });

  final String ad;
  final String sehir;
  final double ortalamaGun;
  final int memnuniyet;
  final int aylikCozum;
  final double puan;
  final bool senin;

  /// "Nilüfer Belediyesi" → "Nilüfer"
  String get kisaAd => ad.replaceAll(' Belediyesi', '');

  /// "Nilüfer" → "Nİ"
  String get basHarfler => turkceBuyuk(kisaAd.characters.take(2).toString());
}

// MARK: - Örnek veri

abstract final class OrnekVeri {
  static const bornova = LatLng(38.4697, 27.2211);

  static List<Ihbar> ihbarlar() {
    final simdi = DateTime.now();
    DateTime once(Duration d) => simdi.subtract(d);
    return [
      Ihbar(
        kategori: Kategori.yolCukuru,
        durum: Durum.kritik,
        aciklama: 'Kavşakta derin çukur, araçlar şerit değiştiriyor.',
        adres: 'Kazımdirik Mah., 372. Sk.',
        koordinat: const LatLng(38.4635, 27.2170),
        tarih: once(const Duration(hours: 3)),
      ),
      Ihbar(
        kategori: Kategori.lamba,
        durum: Durum.beklemede,
        aciklama: 'Parkın girişindeki iki lamba yanmıyor.',
        adres: 'Erzene Mah., Ankara Cd.',
        koordinat: const LatLng(38.4560, 27.2215),
        tarih: once(const Duration(hours: 20)),
      ),
      Ihbar(
        kategori: Kategori.cop,
        durum: Durum.beklemede,
        aciklama: 'Konteyner taşmış, üç gündür alınmadı.',
        adres: 'Mevlana Mah., 1736. Sk.',
        koordinat: const LatLng(38.4748, 27.2105),
        tarih: once(const Duration(hours: 50)),
      ),
      Ihbar(
        kategori: Kategori.su,
        durum: Durum.cozuldu,
        aciklama: 'Kaldırımdan sürekli su sızıyordu.',
        adres: 'Kızılay Mah., 6. Sk.',
        koordinat: const LatLng(38.4682, 27.2290),
        tarih: once(const Duration(days: 5)),
      ),
      Ihbar(
        kategori: Kategori.yolCukuru,
        durum: Durum.kritik,
        aciklama: 'Rögar kapağı yerinden çıkmış.',
        adres: 'Doğanlar Mah., Gazi Cd.',
        koordinat: const LatLng(38.4790, 27.2330),
        tarih: once(const Duration(hours: 6)),
      ),
      Ihbar(
        kategori: Kategori.lamba,
        durum: Durum.cozuldu,
        aciklama: 'Sokak lambası yanıp sönüyordu.',
        adres: 'Atatürk Mah., 115. Sk.',
        koordinat: const LatLng(38.4600, 27.2350),
        tarih: once(const Duration(days: 9)),
      ),
      Ihbar(
        kategori: Kategori.cop,
        durum: Durum.kritik,
        aciklama: 'Pazar yeri sonrası çöpler toplanmadı.',
        adres: 'Çamdibi Mah., 4. Sk.',
        koordinat: const LatLng(38.4530, 27.2080),
        tarih: once(const Duration(hours: 10)),
      ),
    ];
  }

  // Liste ve puanlar Şehir İhbar prototipinden (Ekim 2026).
  static const belediyeler = [
    Belediye(ad: 'Nilüfer Belediyesi', sehir: 'Bursa', ortalamaGun: 1.9, memnuniyet: 95, aylikCozum: 1180, puan: 96.2),
    Belediye(ad: 'Çankaya Belediyesi', sehir: 'Ankara', ortalamaGun: 2.2, memnuniyet: 93, aylikCozum: 1410, puan: 94.8),
    Belediye(
      ad: 'Kadıköy Belediyesi',
      sehir: 'İstanbul',
      ortalamaGun: 2.1,
      memnuniyet: 91,
      aylikCozum: 1240,
      puan: 93.1,
    ),
    Belediye(ad: 'Karşıyaka Belediyesi', sehir: 'İzmir', ortalamaGun: 2.6, memnuniyet: 90, aylikCozum: 690, puan: 91.7),
    Belediye(
      ad: 'Tepebaşı Belediyesi',
      sehir: 'Eskişehir',
      ortalamaGun: 2.8,
      memnuniyet: 89,
      aylikCozum: 620,
      puan: 90.4,
    ),
    Belediye(
      ad: 'Muratpaşa Belediyesi',
      sehir: 'Antalya',
      ortalamaGun: 3.0,
      memnuniyet: 87,
      aylikCozum: 780,
      puan: 88.9,
    ),
    Belediye(ad: 'Atakum Belediyesi', sehir: 'Samsun', ortalamaGun: 3.3, memnuniyet: 86, aylikCozum: 430, puan: 87.5),
    Belediye(
      ad: 'Şahinbey Belediyesi',
      sehir: 'Gaziantep',
      ortalamaGun: 3.6,
      memnuniyet: 83,
      aylikCozum: 910,
      puan: 85.2,
    ),
  ];
}

// MARK: - Türkçe biçimlendirme

/// 2.1 → "2,1"
String turkceOndalik(double d) => d.toStringAsFixed(1).replaceAll('.', ',');

/// 1410 → "1.410"
String turkceSayi(int n) {
  final s = n.abs().toString();
  final b = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return b.toString();
}

/// Türkçe kurallarıyla büyük harf (i → İ, ı → I).
String turkceBuyuk(String s) => s.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();

/// Türkçe kurallarıyla küçük harf (İ → i, I → ı).
String turkceKucuk(String s) => s.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();

/// "3 saat önce", "dün", "5 gün önce" …
String goreliTarih(DateTime t, [DateTime? simdi]) {
  final fark = (simdi ?? DateTime.now()).difference(t);
  if (fark.inSeconds < 60) return 'şimdi';
  if (fark.inMinutes < 60) return '${fark.inMinutes} dakika önce';
  if (fark.inHours < 24) return '${fark.inHours} saat önce';
  if (fark.inDays == 1) return 'dün';
  if (fark.inDays < 7) return '${fark.inDays} gün önce';
  if (fark.inDays < 14) return 'geçen hafta';
  if (fark.inDays < 30) return '${fark.inDays ~/ 7} hafta önce';
  return '${fark.inDays ~/ 30} ay önce';
}
