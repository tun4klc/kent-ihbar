import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'api.dart';
import 'kimlik.dart';
import 'konum.dart';
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

/// Bir listenin yüklenme durumu: veri, yükleniyor mu, son hata.
class Yuklenen<T> {
  Yuklenen(this.veri);

  T veri;
  bool yukleniyor = false;
  String? hata;
}

/// Uygulama durumu ve API verileri. Ekranlar [DurumKapsami] ile dinler.
class UygulamaDurumu extends ChangeNotifier {
  UygulamaDurumu({KentApi? api, KimlikSaglayici? kimlik})
    : api = api ?? KentApi(),
      kimlik = kimlik ?? FirebaseKimlik() {
    this.api.tokenYenile = _tokenYenile;
  }

  final KentApi api;
  final KimlikSaglayici kimlik;

  Oturum _oturum = const OturumYok();
  Kullanici? profil;

  final benimIhbarlarim = Yuklenen<List<Ihbar>>([]);
  final haritaIhbarlari = Yuklenen<List<Ihbar>>([]);

  /// Kullanıcının çevresindeki ihbarlar (ana sayfadaki "Genel durum").
  final cevre = Yuklenen<List<Ihbar>>([]);
  LatLng? _cevreMerkezi;

  int? belediyeSayisi;
  List<BelediyeKaydi>? _belediyeler;
  int _haritaIstegi = 0;

  Oturum get oturum => _oturum;
  set oturum(Oturum yeni) {
    _oturum = yeni;
    notifyListeners();
  }

  bool get girisGerekli => _oturum is OturumYok;
  bool get uyeMi => _oturum is OturumUye;

  // MARK: Başlangıç ve oturum

  /// Açılışta: genel veriler + Firebase'de kayıtlı kullanıcı varsa oturumu sessizce geri yükler.
  Future<void> baslat() async {
    unawaited(_belediyeSayisiniYukle());
    final telefon = kimlik.telefon;
    if (telefon == null) return;
    oturum = OturumUye(telefon);
    try {
      final idToken = await kimlik.idToken();
      if (idToken == null) return await _oturumuKapat();
      final s = await api.dogrula(idToken);
      // Profil formu yarım kaldıysa baştan giriş yapılır.
      if (!s.profilTamam) return await cikisYap();
      await _uyeVerileriniYukle();
    } on ApiHatasi catch (e) {
      if (e.yetkisiz) await _oturumuKapat();
    } on KimlikHatasi {
      await _oturumuKapat();
    }
  }

  Future<KodOturumu> kodGonder(String telefon, {int? yenidenGonderme}) =>
      kimlik.kodGonder(telefon, yenidenGonderme: yenidenGonderme);

  /// SMS kodunu doğrular ve backend JWT'sini alır. Profil eksikse false döner;
  /// o durumda [profilTamamla] çağrılana kadar oturum açılmaz.
  Future<bool> girisYap(KodOturumu kodOturumu, [String? kod]) async {
    final idToken = kodOturumu.otomatik ? await kimlik.idToken() : await kimlik.kodDogrula(kodOturumu, kod!);
    if (idToken == null) throw const KimlikHatasi('Giriş tamamlanamadı, tekrar dene.');
    final s = await api.dogrula(idToken);
    if (s.profilTamam) {
      oturum = OturumUye(kodOturumu.telefon);
      unawaited(_uyeVerileriniYukle().catchError((_) {}));
    }
    return s.profilTamam;
  }

  Future<void> profilTamamla({
    required String ad,
    required String soyad,
    String? eposta,
    required bool sozlesmeler,
    bool pazarlama = false,
  }) async {
    profil = await api.profilTamamla(
      ad: ad,
      soyad: soyad,
      eposta: eposta,
      sozlesmeler: sozlesmeler,
      pazarlama: pazarlama,
    );
    oturum = OturumUye(profil!.telefon ?? kimlik.telefon ?? '');
    unawaited(ihbarlarimiYukle());
  }

  Future<void> cikisYap() async {
    try {
      await api.cikis();
    } on ApiHatasi {
      // Sunucuya ulaşılamasa da yerelde çıkış yapılır.
    }
    await _oturumuKapat();
  }

  Future<void> _oturumuKapat() async {
    api.token = null;
    profil = null;
    benimIhbarlarim.veri = [];
    benimIhbarlarim.hata = null;
    try {
      await kimlik.cikis();
    } catch (_) {}
    oturum = const OturumYok();
  }

  /// JWT'nin süresi dolunca (401) Firebase'den taze idToken alıp yeniden doğrular.
  Future<String?> _tokenYenile() async {
    try {
      final idToken = await kimlik.idToken(yenile: true);
      if (idToken == null) return null;
      return (await api.dogrula(idToken)).token;
    } catch (_) {
      return null;
    }
  }

  Future<void> _uyeVerileriniYukle() async {
    await Future.wait([
      api.ben().then((p) {
        profil = p;
        notifyListeners();
      }),
      ihbarlarimiYukle(),
    ]);
  }

  // MARK: Veriler

  Future<void> _yukle<T>(Yuklenen<T> hedef, Future<T> Function() getir) async {
    hedef
      ..yukleniyor = true
      ..hata = null;
    notifyListeners();
    try {
      hedef.veri = await getir();
    } on ApiHatasi catch (e) {
      hedef.hata = e.mesaj;
    } finally {
      hedef.yukleniyor = false;
      notifyListeners();
    }
  }

  Future<void> ihbarlarimiYukle() async {
    if (api.token == null) return;
    await _yukle(benimIhbarlarim, () => api.ihbarlarim());
  }

  /// Haritanın görünen alanındaki pinler. Geç gelen eski yanıtlar atılır.
  Future<void> haritaYukle(Sinirlar s) async {
    final no = ++_haritaIstegi;
    haritaIhbarlari
      ..yukleniyor = true
      ..hata = null;
    notifyListeners();
    try {
      final l = await api.haritaPinleri(s);
      if (no == _haritaIstegi) haritaIhbarlari.veri = l;
    } on ApiHatasi catch (e) {
      if (no == _haritaIstegi) haritaIhbarlari.hata = e.mesaj;
    } finally {
      if (no == _haritaIstegi) {
        haritaIhbarlari.yukleniyor = false;
        notifyListeners();
      }
    }
  }

  /// Konumun ~5 km çevresindeki ihbarlar.
  Future<void> cevreYukle(LatLng merkez, {bool zorla = false}) async {
    if (!zorla && _cevreMerkezi != null && const Distance().as(LengthUnit.Meter, _cevreMerkezi!, merkez) < 500) {
      return;
    }
    _cevreMerkezi = merkez;
    await _yukle(cevre, () => api.haritaPinleri(Sinirlar.cevresi(merkez, 0.045)));
  }

  Future<void> _belediyeSayisiniYukle() async {
    try {
      belediyeSayisi = (await api.belediyeler(boyut: 1)).toplam;
      notifyListeners();
    } on ApiHatasi {
      // Sayı gösterilmez; kritik değil.
    }
  }

  /// Ana sayfadaki yukarı çekip yenileme.
  Future<void> yenile(LatLng? konum) =>
      Future.wait([_belediyeSayisiniYukle(), ihbarlarimiYukle(), if (konum != null) cevreYukle(konum, zorla: true)]);

  // MARK: Yeni ihbar

  /// Konumdan ilgili belediyeyi bulur: önce ilçe/il adıyla, olmazsa en yakın belediye merkezi.
  Future<BelediyeKaydi> belediyeBul(LatLng konum, Adres? adres) async {
    final tum = _belediyeler ??= await api.tumBelediyeler();
    if (tum.isEmpty) throw const ApiHatasi('Belediye listesi alınamadı.');
    var adaylar = tum;
    if (adres?.il != null) {
      final il = tum.where((b) => turkceKucuk(b.sehir) == turkceKucuk(adres!.il!)).toList();
      if (il.isNotEmpty) adaylar = il;
      if (adres!.ilce != null) {
        final ilce = turkceKucuk(adres.ilce!);
        for (final b in il) {
          if (turkceKucuk(b.ilce) == ilce || turkceKucuk(b.ad) == '$ilce belediyesi') return b;
        }
      }
    }
    const mesafe = Distance();
    return adaylar.reduce(
      (a, b) => mesafe.as(LengthUnit.Meter, a.konum, konum) <= mesafe.as(LengthUnit.Meter, b.konum, konum) ? a : b,
    );
  }

  Future<Ihbar> ihbarGonder({
    required Kategori kategori,
    required LatLng konum,
    String? aciklama,
    Uint8List? foto,
  }) async {
    final adres = await adresBul(konum);
    final belediye = await belediyeBul(konum, adres);
    final anahtarlar = [if (foto != null) await api.fotoYukle(foto)];
    final ihbar = await api.ihbarOlustur(
      kategori: kategori,
      lat: konum.latitude,
      lng: konum.longitude,
      belediyeId: belediye.id,
      baslik: kategori.ad,
      aciklama: aciklama,
      adres: adres?.tamAdres,
      sehir: adres?.il ?? belediye.sehir,
      ilce: adres?.ilce ?? belediye.ilce,
      belediyeAdi: belediye.ad,
      medyaAnahtarlari: anahtarlar,
    );
    benimIhbarlarim.veri = [ihbar, ...benimIhbarlarim.veri];
    notifyListeners();
    return ihbar;
  }
}

// MARK: - Durum & kategori

enum Durum {
  kritik,
  beklemede,
  cozuldu,
  reddedildi;

  /// Haritadaki filtrelerde gösterilenler.
  static const haritada = [kritik, beklemede, cozuldu];

  /// API durumu (PENDING, REVIEWING, ASSIGNED, RESOLVED, REJECTED, UNRATED) → uygulama durumu.
  /// Açık ihbarlar öncelikliyse ya da acil kategorideyse kritik sayılır.
  static Durum apidan(String? durum, {bool oncelikli = false, Kategori? kategori}) => switch (durum) {
    'RESOLVED' || 'UNRATED' => cozuldu,
    'REJECTED' => reddedildi,
    _ => (oncelikli || (kategori?.acil ?? false)) ? kritik : beklemede,
  };

  bool get acik => this == kritik || this == beklemede;

  String get ad => switch (this) {
    Durum.kritik => 'Kritik',
    Durum.beklemede => 'Beklemede',
    Durum.cozuldu => 'Çözüldü',
    Durum.reddedildi => 'Reddedildi',
  };

  Color renk(KIRenk r) => switch (this) {
    Durum.kritik => r.kritik,
    Durum.beklemede => r.beklemede,
    Durum.cozuldu => r.cozuldu,
    Durum.reddedildi => r.metinIkincil,
  };

  Color yumusak(KIRenk r) => switch (this) {
    Durum.kritik => r.kritikYumusak,
    Durum.beklemede => r.beklemedeYumusak,
    Durum.cozuldu => r.cozulduYumusak,
    Durum.reddedildi => r.yuzeyUst,
  };

  /// Renk körlüğü için her durum kendi ikonunu taşır.
  IconData get ikon => switch (this) {
    Durum.kritik => Icons.warning_rounded,
    Durum.beklemede => Icons.schedule_rounded,
    Durum.cozuldu => Icons.check_rounded,
    Durum.reddedildi => Icons.block_rounded,
  };
}

/// API'nin `/categories` listesiyle aynı sırada.
enum Kategori {
  yolCukuru('ROAD_POTHOLE', 'Yol Çukuru'),
  lamba('BROKEN_LIGHT', 'Bozuk Aydınlatma'),
  cop('GARBAGE', 'Çöp'),
  trafikKazasi('TRAFFIC_ACCIDENT', 'Trafik Kazası'),
  agac('FALLEN_TREE', 'Devrilmiş Ağaç'),
  su('WATER_LEAK', 'Su Kaçağı'),
  yangin('FIRE', 'Yangın'),
  diger('OTHER', 'Diğer');

  const Kategori(this.api, this.ad);

  final String api;
  final String ad;

  static Kategori apidan(String? kod) => values.firstWhere((k) => k.api == kod, orElse: () => diger);

  /// API'de `emergency: true` olanlar.
  bool get acil => this == trafikKazasi || this == yangin;

  IconData get ikon => switch (this) {
    Kategori.yolCukuru => Icons.warning_amber_rounded,
    Kategori.lamba => Icons.lightbulb_outline_rounded,
    Kategori.cop => Icons.delete_outline_rounded,
    Kategori.trafikKazasi => Icons.car_crash_outlined,
    Kategori.agac => Icons.park_outlined,
    Kategori.su => Icons.water_drop_outlined,
    Kategori.yangin => Icons.local_fire_department_outlined,
    Kategori.diger => Icons.grid_view_rounded,
  };

  /// Kategori kutusundaki ikon rengi (Şehir İhbar'daki renk ailesi, Kent İhbar tonlarında).
  Color renk(KIRenk r) => switch (this) {
    Kategori.yolCukuru => r.sec(0xC2410C, 0xFB923C),
    Kategori.lamba => r.sec(0xB45309, 0xFBBF24),
    Kategori.cop => r.sec(0x047857, 0x34D399),
    Kategori.trafikKazasi => r.kritik,
    Kategori.agac => r.sec(0x0F766E, 0x2DD4BF),
    Kategori.su => r.birincilMetin,
    Kategori.yangin => r.sec(0xBE123C, 0xFB7185),
    Kategori.diger => r.sec(0x6D28D9, 0xA78BFA),
  };

  Color yumusak(KIRenk r) => switch (this) {
    Kategori.yolCukuru => r.sec(0xFFEDD5, 0x3A2010),
    Kategori.lamba => r.sec(0xFEF3C7, 0x36290A),
    Kategori.cop => r.sec(0xD1FAE5, 0x0B2E24),
    Kategori.trafikKazasi => r.kritikYumusak,
    Kategori.agac => r.sec(0xCCFBF1, 0x0A2E2A),
    Kategori.su => r.birincilYumusak,
    Kategori.yangin => r.sec(0xFFE4E6, 0x3A1420),
    Kategori.diger => r.sec(0xEDE9FE, 0x221A40),
  };
}

// MARK: - API modelleri

DateTime? _tarih(Object? v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;
double _sayi(Object? v) => (v as num?)?.toDouble() ?? 0;

class Ihbar {
  const Ihbar({
    required this.id,
    required this.kategori,
    required this.durum,
    required this.koordinat,
    this.baslik,
    this.aciklama,
    this.adres,
    this.tarih,
    this.fotolar = const [],
    this.belediyeAdi,
    this.benim = false,
  });

  /// Hem `ReportResponse` hem de haritadaki `ReportMapPinResponse` ile çalışır.
  factory Ihbar.fromJson(Map<String, dynamic> j, {bool benim = false}) {
    final kategori = Kategori.apidan(j['category'] as String?);
    return Ihbar(
      id: j['id'].toString(),
      kategori: kategori,
      durum: Durum.apidan(j['status'] as String?, oncelikli: j['priority'] == true, kategori: kategori),
      koordinat: LatLng(_sayi(j['lat']), _sayi(j['lng'])),
      baslik: j['title'] as String?,
      aciklama: j['description'] as String?,
      adres: j['address'] as String?,
      tarih: _tarih(j['createdAt']),
      fotolar: [for (final u in (j['mediaUrls'] as List? ?? const [])) u.toString()],
      belediyeAdi: j['municipalityName'] as String?,
      benim: benim,
    );
  }

  final String id;
  final Kategori kategori;
  final Durum durum;
  final LatLng koordinat;
  final String? baslik;
  final String? aciklama;
  final String? adres;
  final DateTime? tarih;
  final List<String> fotolar;
  final String? belediyeAdi;
  final bool benim;

  /// Listelerde ikinci satır: adres, yoksa belediye.
  String get konumMetni => adres ?? belediyeAdi ?? 'Adres belirtilmedi';
}

class Kullanici {
  const Kullanici({this.ad, this.soyad, this.telefon, this.eposta, this.belediyeId});

  factory Kullanici.fromJson(Map<dynamic, dynamic> j) => Kullanici(
    ad: j['firstName'] as String?,
    soyad: j['lastName'] as String?,
    telefon: j['phone'] as String?,
    eposta: j['email'] as String?,
    belediyeId: j['activeMunicipalityId'] as String?,
  );

  final String? ad;
  final String? soyad;
  final String? telefon;
  final String? eposta;
  final String? belediyeId;

  String? get adSoyad {
    final s = [ad, soyad].whereType<String>().where((e) => e.isNotEmpty).join(' ');
    return s.isEmpty ? null : s;
  }
}

/// Belediye sıralaması satırı (`LeaderboardEntryResponse`).
class Belediye {
  const Belediye({
    this.id = '',
    required this.ad,
    required this.sehir,
    this.ortalamaGun,
    this.memnuniyet,
    required this.aylikCozum,
    required this.puan,
  });

  factory Belediye.fromJson(Map<String, dynamic> j) {
    final saat = (j['avgResolutionHours'] as num?)?.toDouble();
    final memnuniyet = (j['satisfactionScore'] as num?)?.toDouble();
    return Belediye(
      id: j['municipalityId']?.toString() ?? '',
      ad: j['name'] as String? ?? '',
      sehir: j['city'] as String? ?? '',
      ortalamaGun: saat == null || saat <= 0 ? null : saat / 24,
      memnuniyet: memnuniyet == null || memnuniyet <= 0 ? null : memnuniyet.round(),
      aylikCozum: (j['monthlyResolved'] as num?)?.toInt() ?? 0,
      puan: _sayi(j['score']),
    );
  }

  final String id;
  final String ad;
  final String sehir;

  /// Henüz çözülmüş ihbarı yoksa null.
  final double? ortalamaGun;
  final int? memnuniyet;
  final int aylikCozum;

  /// 0–100
  final double puan;

  /// "Nilüfer Belediyesi" → "Nilüfer"
  String get kisaAd => ad.replaceAll(' Belediyesi', '');

  /// "Nilüfer" → "Nİ"
  String get basHarfler => turkceBuyuk(kisaAd.characters.take(2).toString());
}

/// `/municipalities` kaydı; yeni ihbarın gideceği belediyeyi bulmak için.
class BelediyeKaydi {
  const BelediyeKaydi({
    required this.id,
    required this.ad,
    required this.ilce,
    required this.sehir,
    required this.konum,
  });

  factory BelediyeKaydi.fromJson(Map<String, dynamic> j) => BelediyeKaydi(
    id: j['id'].toString(),
    ad: j['name'] as String? ?? '',
    ilce: j['district'] as String? ?? '',
    sehir: j['city'] as String? ?? '',
    konum: LatLng(_sayi(j['lat']), _sayi(j['lng'])),
  );

  final String id;
  final String ad;
  final String ilce;
  final String sehir;
  final LatLng konum;
}

/// Harita sorgusu için enlem/boylam kutusu.
class Sinirlar {
  const Sinirlar({required this.minLat, required this.maxLat, required this.minLng, required this.maxLng});

  factory Sinirlar.cevresi(LatLng m, double derece) => Sinirlar(
    minLat: m.latitude - derece,
    maxLat: m.latitude + derece,
    minLng: m.longitude - derece,
    maxLng: m.longitude + derece,
  );

  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;
}

// MARK: - Sabitler

/// Konum yokken haritanın açıldığı yer.
const varsayilanMerkez = LatLng(38.4697, 27.2211);

/// API'deki 81 il (sıralamadaki şehir filtresi).
const iller = [
  'Adana',
  'Adıyaman',
  'Afyonkarahisar',
  'Ağrı',
  'Aksaray',
  'Amasya',
  'Ankara',
  'Antalya',
  'Ardahan',
  'Artvin',
  'Aydın',
  'Balıkesir',
  'Bartın',
  'Batman',
  'Bayburt',
  'Bilecik',
  'Bingöl',
  'Bitlis',
  'Bolu',
  'Burdur',
  'Bursa',
  'Çanakkale',
  'Çankırı',
  'Çorum',
  'Denizli',
  'Diyarbakır',
  'Düzce',
  'Edirne',
  'Elazığ',
  'Erzincan',
  'Erzurum',
  'Eskişehir',
  'Gaziantep',
  'Giresun',
  'Gümüşhane',
  'Hakkari',
  'Hatay',
  'Iğdır',
  'Isparta',
  'İstanbul',
  'İzmir',
  'Kahramanmaraş',
  'Karabük',
  'Karaman',
  'Kars',
  'Kastamonu',
  'Kayseri',
  'Kilis',
  'Kırıkkale',
  'Kırklareli',
  'Kırşehir',
  'Kocaeli',
  'Konya',
  'Kütahya',
  'Malatya',
  'Manisa',
  'Mardin',
  'Mersin',
  'Muğla',
  'Muş',
  'Nevşehir',
  'Niğde',
  'Ordu',
  'Osmaniye',
  'Rize',
  'Sakarya',
  'Samsun',
  'Siirt',
  'Sinop',
  'Sivas',
  'Şanlıurfa',
  'Şırnak',
  'Tekirdağ',
  'Tokat',
  'Trabzon',
  'Tunceli',
  'Uşak',
  'Van',
  'Yalova',
  'Yozgat',
  'Zonguldak',
];

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
