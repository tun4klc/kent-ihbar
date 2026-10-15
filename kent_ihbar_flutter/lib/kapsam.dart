import 'package:flutter/widgets.dart';

import 'konum.dart';
import 'model.dart';

/// Uygulama durumunu ağaca verir; dinleyen widget'lar değişince yeniden çizilir.
class DurumKapsami extends InheritedNotifier<UygulamaDurumu> {
  const DurumKapsami({super.key, required UygulamaDurumu durum, required super.child}) : super(notifier: durum);

  static UygulamaDurumu of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DurumKapsami>()!.notifier!;

  /// Yeniden çizime abone olmadan erişim (düğme eylemleri için).
  static UygulamaDurumu oku(BuildContext context) => context.getInheritedWidgetOfExactType<DurumKapsami>()!.notifier!;
}

class KonumKapsami extends InheritedNotifier<KonumYoneticisi> {
  const KonumKapsami({super.key, required KonumYoneticisi konum, required super.child}) : super(notifier: konum);

  static KonumYoneticisi of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KonumKapsami>()!.notifier!;

  static KonumYoneticisi oku(BuildContext context) => context.getInheritedWidgetOfExactType<KonumKapsami>()!.notifier!;
}
