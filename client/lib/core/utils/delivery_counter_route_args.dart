import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/delivery_partner_repository.dart';

/// Counter route args for delivery sale / log edit — matches [DeliverySaleScreen] tiles.
class DeliveryCounterRouteArgs {
  const DeliveryCounterRouteArgs({
    required this.deliveryPartner,
    required this.deliveryServiceId,
  });

  final String deliveryPartner;
  final String deliveryServiceId;
}

/// Resolves `deliveryPartner` + `deliveryServiceId` for `/counter` (catalog filter).
Future<DeliveryCounterRouteArgs> resolveDeliveryCounterRouteArgs({
  required String? deliveryPartnerLabel,
  required DeliveryPartnerRepository partnerRepo,
}) async {
  final lbl = deliveryPartnerLabel?.trim();
  if (lbl == null || lbl.isEmpty) {
    return const DeliveryCounterRouteArgs(
      deliveryPartner: 'NORMAL',
      deliveryServiceId: 'NORMAL',
    );
  }

  if (lbl.toUpperCase() == 'NORMAL') {
    return const DeliveryCounterRouteArgs(
      deliveryPartner: 'NORMAL',
      deliveryServiceId: 'NORMAL',
    );
  }

  final asId = int.tryParse(lbl);
  if (asId != null) {
    final partners = await partnerRepo.getAll();
    for (final p in partners) {
      if (p.id == asId) {
        return DeliveryCounterRouteArgs(
          deliveryPartner: p.name,
          deliveryServiceId: '${p.id}',
        );
      }
    }
    return DeliveryCounterRouteArgs(
      deliveryPartner: lbl,
      deliveryServiceId: lbl,
    );
  }

  final partners = await partnerRepo.getAll();
  for (final p in partners) {
    if (p.name.trim().toLowerCase() == lbl.toLowerCase()) {
      return DeliveryCounterRouteArgs(
        deliveryPartner: p.name,
        deliveryServiceId: '${p.id}',
      );
    }
  }

  return DeliveryCounterRouteArgs(
    deliveryPartner: lbl,
    deliveryServiceId: lbl,
  );
}

Future<DeliveryCounterRouteArgs> resolveDeliveryCounterRouteArgsFromOrder({
  required Order order,
  required DeliveryPartnerRepository partnerRepo,
}) =>
    resolveDeliveryCounterRouteArgs(
      deliveryPartnerLabel: order.deliveryPartner,
      partnerRepo: partnerRepo,
    );
