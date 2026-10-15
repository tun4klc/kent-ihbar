import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Konum izni ve son bilinen konum.
class KonumYoneticisi extends ChangeNotifier with WidgetsBindingObserver {
  KonumYoneticisi() {
    WidgetsBinding.instance.addObserver(this);
    _yetkiyiOku();
  }

  LocationPermission _yetki = LocationPermission.unableToDetermine;
  LatLng? konum;

  bool get izinVar => _yetki == LocationPermission.whileInUse || _yetki == LocationPermission.always;
  bool get reddedildi => _yetki == LocationPermission.deniedForever;

  /// İzin isteğini sistem penceresiyle açar; reddedilmişse Ayarlar'a götürür.
  Future<void> izinIste() async {
    if (reddedildi) {
      await Geolocator.openAppSettings();
      return;
    }
    try {
      _yetki = await Geolocator.requestPermission();
    } catch (_) {
      return;
    }
    notifyListeners();
    if (izinVar) unawaited(_konumuAl());
  }

  /// Ayarlar'dan dönünce yetkiyi yeniden okur.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _yetkiyiOku();
  }

  Future<void> _yetkiyiOku() async {
    try {
      _yetki = await Geolocator.checkPermission();
    } catch (_) {
      return;
    }
    notifyListeners();
    if (izinVar && konum == null) unawaited(_konumuAl());
  }

  Future<void> _konumuAl() async {
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      konum = LatLng(p.latitude, p.longitude);
      notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

/// Koordinattan çözülen adres (ihbarın gideceği belediyeyi bulmak için).
class Adres {
  const Adres({this.il, this.ilce, this.tamAdres});

  final String? il;
  final String? ilce;
  final String? tamAdres;
}

/// Cihazın yerleşik geocoder'ı ile ters adres çözümleme; başarısızsa null.
Future<Adres?> adresBul(LatLng konum) async {
  String? dolu(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
  try {
    final yerler = await Geocoding().placemarkFromCoordinates(
      konum.latitude,
      konum.longitude,
      locale: const Locale('tr', 'TR'),
    );
    if (yerler.isEmpty) return null;
    final y = yerler.first;
    final il = dolu(y.administrativeArea);
    final ilce = dolu(y.subAdministrativeArea) ?? dolu(y.locality);
    final parcalar = [dolu(y.subLocality), dolu(y.thoroughfare) ?? dolu(y.street), ilce, il].whereType<String>();
    return Adres(il: il, ilce: ilce, tamAdres: parcalar.isEmpty ? null : parcalar.toSet().join(', '));
  } catch (_) {
    return null;
  }
}
