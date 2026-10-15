import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

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

  @override
  void dispose() {
    _kameraAnimasyonu?.dispose();
    _harita.dispose();
    super.dispose();
  }

  bool _son24(Ihbar i) => i.tarih.isAfter(DateTime.now().subtract(const Duration(days: 1)));

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
      _git(OrnekVeri.bornova, _baslangicZoom);
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
    final gorunen = durum.ihbarlar
        .where((i) => _durumlar.contains(i.durum) && _kategoriler.contains(i.kategori) && (!_sadeceSon24 || _son24(i)))
        .toList();
    final acik = durum.ihbarlar.where((i) => i.durum != Durum.cozuldu).length;
    final son24 = durum.ihbarlar.where(_son24).length;

    return Stack(
      children: [
        FlutterMap(
          mapController: _harita,
          options: const MapOptions(
            initialCenter: OrnekVeri.bornova,
            initialZoom: _baslangicZoom,
            minZoom: 3,
            maxZoom: 18,
            interactionOptions: InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
          ),
          children: [
            TileLayer(
              urlTemplate: r.koyu
                  ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                  : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              retinaMode: RetinaMode.isHighDensity(context),
              userAgentPackageName: 'com.tunakilic.kentihbar',
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
                      child: HaritaPini(durum: ih.durum, tohum: ih.id * 7919),
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
            child: _ust(r, gorunen.length, acik, son24),
          ),
        ),
        Positioned(right: KI.space5, bottom: KI.space5, child: _kontroller(r)),
      ],
    );
  }

  // MARK: Üst panel

  Widget _ust(KIRenk r, int gorunenSayisi, int acik, int son24) {
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
                      'Bornova · $gorunenSayisi kayıt görüntüleniyor',
                      style: KIFont.govdeKucuk.renk(r.metinIkincil),
                    ),
                  ],
                ),
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
                  for (final d in Durum.values)
                    CheckedPopupMenuItem(value: d, checked: _durumlar.contains(d), child: Text(d.ad)),
                ],
                secildi: (d) => _degistir(d as Durum),
                cip: FiltreCipi(
                  baslik: 'Durum',
                  ikon: Icons.tune_rounded,
                  secili: _durumlar.length != Durum.values.length,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: KI.space3),
        Row(
          children: [
            for (final d in Durum.values) ...[
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

class IhbarDetayi extends StatelessWidget {
  const IhbarDetayi({super.key, required this.ihbar});

  final Ihbar ihbar;

  Future<void> _yolTarifi() async {
    final k = ihbar.koordinat;
    final ad = Uri.encodeComponent(ihbar.kategori.ad);
    final uri = Platform.isIOS
        ? Uri.parse('https://maps.apple.com/?daddr=${k.latitude},${k.longitude}&q=$ad')
        : Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${k.latitude},${k.longitude}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(KI.space5, 0, KI.space5, KI.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IkonRozeti(ikon: ihbar.kategori.ikon),
                const SizedBox(width: KI.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ihbar.kategori.ad, style: KIFont.kartBasligi.renk(r.metin)),
                      const SizedBox(height: 2),
                      Text(ihbar.adres, style: KIFont.govdeKucuk.renk(r.metinIkincil)),
                    ],
                  ),
                ),
                DurumRozeti(durum: ihbar.durum),
              ],
            ),
            const SizedBox(height: KI.space4),
            Text(ihbar.aciklama, style: KIFont.govdeMetni.renk(r.metin)),
            const SizedBox(height: KI.space4),
            Text(goreliTarih(ihbar.tarih), style: KIFont.altYazi.renk(r.metinSoluk)),
            const SizedBox(height: KI.space6),
            IkincilDugme(baslik: 'Yol tarifi al', ikon: Icons.directions_outlined, onPressed: _yolTarifi),
          ],
        ),
      ),
    );
  }
}
