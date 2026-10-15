import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';
import '../bilesenler.dart';
import '../harita_pini.dart';
import '../kapsam.dart';
import '../model.dart';
import '../tema.dart';

class HaritaEkrani extends StatefulWidget {
  const HaritaEkrani({super.key});

  @override
  State<HaritaEkrani> createState() => _HaritaEkraniState();
}

class _HaritaEkraniState extends State<HaritaEkrani> with TickerProviderStateMixin {
  static const _baslangicZoom = 13.6;
  static const _tumunuGoster = 'tumu';

  final _harita = MapController();
  Set<Durum> _durumlar = Durum.values.toSet();
  Set<Kategori> _kategoriler = Kategori.values.toSet();
  bool _sadeceSon24 = false;
  AnimationController? _kameraAnimasyonu;
  Timer? _yuklemeZamanlayici;

  @override
  void dispose() {
    _yuklemeZamanlayici?.cancel();
    _kameraAnimasyonu?.dispose();
    _harita.dispose();
    super.dispose();
  }

  bool _son24(Ihbar i) => i.tarih?.isAfter(DateTime.now().subtract(const Duration(days: 1))) ?? false;

  /// Görünen alanın pinlerini çeker; kaydırma bitene kadar bekler.
  void _yukleZamanla([Duration gecikme = const Duration(milliseconds: 450)]) {
    _yuklemeZamanlayici?.cancel();
    _yuklemeZamanlayici = Timer(gecikme, () {
      if (!mounted) return;
      final b = _harita.camera.visibleBounds;
      DurumKapsami.oku(context).haritaYukle(Sinirlar(minLat: b.south, maxLat: b.north, minLng: b.west, maxLng: b.east));
    });
  }

  void _degistir(Durum d) {
    setState(() {
      if (_durumlar.contains(d)) {
        if (_durumlar.length > 1) _durumlar = {..._durumlar}..remove(d);
      } else {
        _durumlar = {..._durumlar, d};
      }
    });
  }

  /// Kamerayı yumuşakça yeni merkeze / yakınlığa taşır.
  void _git(LatLng hedef, double zoom) {
    final kamera = _harita.camera;
    final basMerkez = kamera.center;
    final basZoom = kamera.zoom;
    _kameraAnimasyonu?.dispose();
    final k = AnimationController(vsync: this, duration: KI.sureYavas);
    _kameraAnimasyonu = k;
    final egri = CurvedAnimation(parent: k, curve: Curves.easeInOut);
    egri.addListener(() {
      final t = egri.value;
      _harita.move(
        LatLng(
          basMerkez.latitude + (hedef.latitude - basMerkez.latitude) * t,
          basMerkez.longitude + (hedef.longitude - basMerkez.longitude) * t,
        ),
        basZoom + (zoom - basZoom) * t,
      );
    });
    k.forward();
  }

  void _yakinlas(double fark) {
    final kamera = _harita.camera;
    _git(kamera.center, (kamera.zoom + fark).clamp(3.0, 18.0));
  }

  void _konumumaGit() {
    final konum = KonumKapsami.oku(context);
    if (konum.izinVar && konum.konum != null) {
      _git(konum.konum!, 15);
    } else {
      if (!konum.izinVar) konum.izinIste();
      _git(varsayilanMerkez, _baslangicZoom);
    }
  }

  void _detayAc(Ihbar ih) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => IhbarDetayi(ihbar: ih),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    final durum = DurumKapsami.of(context);
    final konum = KonumKapsami.of(context);
    final pinler = durum.haritaIhbarlari.veri;
    final gorunen = pinler
        .where((i) => _durumlar.contains(i.durum) && _kategoriler.contains(i.kategori) && (!_sadeceSon24 || _son24(i)))
        .toList();
    final acik = pinler.where((i) => i.durum.acik).length;
    final son24 = pinler.where(_son24).length;

    return Stack(
      children: [
        FlutterMap(
          mapController: _harita,
          options: MapOptions(
            initialCenter: konum.konum ?? varsayilanMerkez,
            initialZoom: _baslangicZoom,
            minZoom: 5,
            maxZoom: 18,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
            onMapReady: () => _yukleZamanla(Duration.zero),
            onPositionChanged: (_, _) => _yukleZamanla(),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.tunakilic.kentihbar.flutter',
              tileBuilder: r.koyu ? darkModeTileBuilder : null,
            ),
            if (konum.konum != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: konum.konum!,
                    width: 24,
                    height: 24,
                    child: _KullaniciNoktasi(renk: r.birincil),
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                for (final ih in gorunen)
                  Marker(
                    key: ValueKey(ih.id),
                    point: ih.koordinat,
                    width: HaritaPini.boyut,
                    height: HaritaPini.boyut,
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () => _detayAc(ih),
                      child: HaritaPini(durum: ih.durum, tohum: ih.id.hashCode),
                    ),
                  ),
              ],
            ),
            const RichAttributionWidget(
              alignment: AttributionAlignment.bottomLeft,
              attributions: [TextSourceAttribution('OpenStreetMap katkıcıları'), TextSourceAttribution('CARTO')],
            ),
          ],
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(KI.space5, KI.space2, KI.space5, 0),
            child: _ust(r, durum, gorunen.length, acik, son24),
          ),
        ),
        Positioned(right: KI.space5, bottom: KI.space5, child: _kontroller(r)),
      ],
    );
  }

  // MARK: Üst panel

  Widget _ust(KIRenk r, UygulamaDurumu durum, int gorunenSayisi, int acik, int son24) {
    final yuklenen = durum.haritaIhbarlari;
    final tumKategoriler = _kategoriler.length == Kategori.values.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Kart(
          dolgu: 14,
          child: Row(
            children: [
              const IkonRozeti(ikon: Icons.map_outlined),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Canlı Harita', style: KIFont.kartBasligi.renk(r.metin)),
                    const SizedBox(height: 2),
                    Text(
                      yuklenen.hata != null
                          ? 'Yüklenemedi · dokunarak tekrar dene'
                          : gorunenSayisi == 0 && !yuklenen.yukleniyor
                          ? 'Bu bölgede kayıt yok'
                          : '$gorunenSayisi kayıt görüntüleniyor',
                      style: KIFont.govdeKucuk.renk(yuklenen.hata != null ? r.kritik : r.metinIkincil),
                    ),
                  ],
                ),
              ),
              if (yuklenen.yukleniyor)
                const SizedBox.square(dimension: 20, child: CircularProgressIndicator.adaptive(strokeWidth: 2))
              else if (yuklenen.hata != null)
                Basilabilir(
                  etiket: 'Tekrar dene',
                  onTap: () => _yukleZamanla(Duration.zero),
                  child: Icon(Icons.refresh_rounded, size: 24, color: r.birincilMetin),
                ),
            ],
          ),
        ),
        const SizedBox(height: KI.space3),
        Row(
          children: [
            Expanded(
              child: Basilabilir(
                onTap: () => setState(() {
                  _durumlar = {Durum.kritik, Durum.beklemede};
                  _sadeceSon24 = false;
                }),
                child: SayacHapi(tur: SayacTuru.acik, deger: acik, etiket: 'Açık'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Basilabilir(
                onTap: () => setState(() => _sadeceSon24 = !_sadeceSon24),
                child: SayacHapi(tur: SayacTuru.canli, deger: son24, etiket: 'Son 24s'),
              ),
            ),
          ],
        ),
        const SizedBox(height: KI.space3),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _degistir(Durum.cozuldu),
                child: FiltreCipi(
                  baslik: 'Çözülenler',
                  ikon: Icons.check_circle_outline_rounded,
                  secili: _durumlar.contains(Durum.cozuldu),
                ),
              ),
              const SizedBox(width: KI.space2),
              _menu(
                ogeler: [
                  for (final k in Kategori.values)
                    CheckedPopupMenuItem(value: k, checked: _kategoriler.contains(k), child: Text(k.ad)),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: _tumunuGoster, child: Text('Tümünü göster')),
                ],
                secildi: (k) => setState(() {
                  if (k is! Kategori) {
                    _kategoriler = Kategori.values.toSet();
                  } else if (_kategoriler.contains(k)) {
                    _kategoriler = {..._kategoriler}..remove(k);
                  } else {
                    _kategoriler = {..._kategoriler, k};
                  }
                }),
                cip: FiltreCipi(
                  baslik: tumKategoriler ? 'Kategori' : 'Kategori · ${_kategoriler.length}',
                  ikon: Icons.category_outlined,
                  secili: !tumKategoriler,
                ),
              ),
              const SizedBox(width: KI.space2),
              _menu(
                ogeler: [
                  for (final d in Durum.haritada)
                    CheckedPopupMenuItem(value: d, checked: _durumlar.contains(d), child: Text(d.ad)),
                ],
                secildi: (d) => _degistir(d as Durum),
                cip: FiltreCipi(
                  baslik: 'Durum',
                  ikon: Icons.tune_rounded,
                  secili: !Durum.haritada.every(_durumlar.contains),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: KI.space3),
        Row(
          children: [
            for (final d in Durum.haritada) ...[
              GestureDetector(
                onTap: () => _degistir(d),
                child: DurumGostergesi(durum: d, secili: _durumlar.contains(d)),
              ),
              const SizedBox(width: KI.space2),
            ],
          ],
        ),
      ],
    );
  }

  /// Bir çipe dokununca altında seçenek menüsü açar (SwiftUI `Menu`).
  Widget _menu({
    required List<PopupMenuEntry<Object>> ogeler,
    required ValueChanged<Object> secildi,
    required Widget cip,
  }) {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: () async {
            final kutu = context.findRenderObject()! as RenderBox;
            final ust = Overlay.of(context).context.findRenderObject()! as RenderBox;
            final konum = RelativeRect.fromRect(
              Rect.fromPoints(
                kutu.localToGlobal(Offset(0, kutu.size.height + 6), ancestor: ust),
                kutu.localToGlobal(kutu.size.bottomRight(Offset.zero), ancestor: ust),
              ),
              Offset.zero & ust.size,
            );
            final deger = await showMenu<Object>(
              context: context,
              position: konum,
              items: ogeler,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(KI.radiusMd)),
            );
            if (deger != null) secildi(deger);
          },
          child: cip,
        );
      },
    );
  }

  // MARK: Kontroller

  Widget _kontroller(KIRenk r) {
    return Column(
      children: [
        _haritaDugmesi(r, Icons.add_rounded, 'Yakınlaştır', () => _yakinlas(1)),
        const SizedBox(height: 10),
        _haritaDugmesi(r, Icons.remove_rounded, 'Uzaklaştır', () => _yakinlas(-1)),
        const SizedBox(height: 10),
        Basilabilir(
          etiket: 'Konumuma git',
          onTap: _konumumaGit,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: r.birincil,
              borderRadius: BorderRadius.circular(KI.radiusMd),
              boxShadow: maviYansima(r),
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(KI.radiusMd),
              gradient: yansimaIsigi,
            ),
            child: Icon(Icons.near_me_rounded, size: 22, color: r.onBirincil),
          ),
        ),
      ],
    );
  }

  Widget _haritaDugmesi(KIRenk r, IconData ikon, String etiket, VoidCallback eylem) {
    return Basilabilir(
      etiket: etiket,
      onTap: eylem,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: r.yuzey,
          borderRadius: BorderRadius.circular(KI.radiusMd),
          boxShadow: sertGolge(r),
        ),
        child: Icon(ikon, size: 24, color: r.metin),
      ),
    );
  }
}

/// Kullanıcının konumu: beyaz halkalı mavi nokta.
class _KullaniciNoktasi extends StatelessWidget {
  const _KullaniciNoktasi({required this.renk});

  final Color renk;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: renk,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [BoxShadow(color: renk.withValues(alpha: 0.35), blurRadius: 10, spreadRadius: 4)],
      ),
    );
  }
}

// MARK: - İhbar detayı

/// Pinde yalnızca özet bilgi var; açıklama, adres, tarih ve fotoğraf `/reports/public/{id}`'den gelir.
class IhbarDetayi extends StatefulWidget {
  const IhbarDetayi({super.key, required this.ihbar});

  final Ihbar ihbar;

  @override
  State<IhbarDetayi> createState() => _IhbarDetayiState();
}

class _IhbarDetayiState extends State<IhbarDetayi> {
  late Ihbar _ihbar = widget.ihbar;
  bool _yukleniyor = true;
  String? _hata;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    try {
      final tam = await DurumKapsami.oku(context).api.ihbar(widget.ihbar.id);
      if (mounted) setState(() => _ihbar = tam);
    } on ApiHatasi catch (e) {
      if (mounted) setState(() => _hata = e.mesaj);
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Future<void> _yolTarifi() async {
    final k = _ihbar.koordinat;
    final ad = Uri.encodeComponent(_ihbar.kategori.ad);
    final uri = Platform.isIOS
        ? Uri.parse('https://maps.apple.com/?daddr=${k.latitude},${k.longitude}&q=$ad')
        : Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${k.latitude},${k.longitude}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    final ih = _ihbar;
    final api = DurumKapsami.oku(context).api;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(KI.space5, 0, KI.space5, KI.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IkonRozeti(ikon: ih.kategori.ikon),
                const SizedBox(width: KI.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ih.baslik ?? ih.kategori.ad, style: KIFont.kartBasligi.renk(r.metin)),
                      const SizedBox(height: 2),
                      Text(
                        ih.adres ?? ih.belediyeAdi ?? (_yukleniyor ? 'Yükleniyor…' : 'Adres belirtilmedi'),
                        style: KIFont.govdeKucuk.renk(r.metinIkincil),
                      ),
                    ],
                  ),
                ),
                DurumRozeti(durum: ih.durum),
              ],
            ),
            if (ih.fotolar.isNotEmpty) ...[
              const SizedBox(height: KI.space4),
              ClipRRect(
                borderRadius: BorderRadius.circular(KI.radiusMd),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Image.network(
                    api.medyaAdresi(ih.fotolar.first),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => ColoredBox(
                      color: r.yuzeyUst,
                      child: Icon(Icons.broken_image_outlined, color: r.metinSoluk),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: KI.space4),
            if (_yukleniyor && ih.aciklama == null)
              const Yukleniyor(yukseklik: 48)
            else if (_hata != null)
              Row(
                children: [
                  Expanded(child: Text(_hata!, style: KIFont.govdeKucuk.renk(r.kritik))),
                  MetinDugme(baslik: 'Tekrar dene', onPressed: _yukle),
                ],
              )
            else if (ih.aciklama != null && ih.aciklama!.isNotEmpty)
              Text(ih.aciklama!, style: KIFont.govdeMetni.renk(r.metin)),
            if (ih.tarih != null) ...[
              const SizedBox(height: KI.space4),
              Text(goreliTarih(ih.tarih!), style: KIFont.altYazi.renk(r.metinSoluk)),
            ],
            const SizedBox(height: KI.space6),
            IkincilDugme(baslik: 'Yol tarifi al', ikon: Icons.directions_outlined, onPressed: _yolTarifi),
          ],
        ),
      ),
    );
  }
}
