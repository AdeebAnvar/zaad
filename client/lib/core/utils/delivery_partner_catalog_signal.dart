import 'package:flutter/foundation.dart';

/// Bumped when LAN hub applies delivery partners on SUB so open [ItemsCubit] re-filters.
class DeliveryPartnerCatalogSignal {
  DeliveryPartnerCatalogSignal._();

  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static void notifyPartnersChanged() {
    revision.value++;
  }
}
