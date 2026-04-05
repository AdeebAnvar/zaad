import 'package:drift/drift.dart' show Value;
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/cart_repository.dart';
import 'package:pos/data/repository/order_repository.dart';
import 'package:pos/presentation/dine_in_log/dine_in_reference_utils.dart';

bool orderCanMoveBetweenLogs(Order order) {
  final s = order.status.toLowerCase();
  return s != 'completed' && s != 'cancelled' && s != 'delivered';
}

Future<String?> moveOrderToTakeAway({
  required OrderRepository orderRepo,
  required CartRepository cartRepo,
  required Order order,
  required String referenceNumber,
}) async {
  if (!orderCanMoveBetweenLogs(order)) {
    return 'Cannot move completed, delivered, or cancelled orders';
  }
  final ref = referenceNumber.trim();
  if (ref.isEmpty) return 'Enter a reference number';

  await cartRepo.updateCartOrderInfo(
    order.cartId,
    orderType: 'take_away',
    deliveryPartner: null,
  );

  await orderRepo.updateOrder(
    order.copyWith(
      orderType: const Value('take_away'),
      referenceNumber: Value(ref),
      deliveryPartner: const Value(null),
      driverId: const Value(null),
      driverName: const Value(null),
    ),
  );
  return null;
}

Future<String?> moveOrderToDelivery({
  required OrderRepository orderRepo,
  required CartRepository cartRepo,
  required Order order,
  required String deliveryPartner,
  required String contactNumber,
  required String customerName,
  String? email,
  String? gender,
  int? driverId,
  String? driverName,
  /// Partner / app order id (same as payment dialog); falls back to phone when empty.
  String? onlineOrderNumber,
}) async {
  if (!orderCanMoveBetweenLogs(order)) {
    return 'Cannot move completed, delivered, or cancelled orders';
  }
  final phone = contactNumber.trim();
  final name = customerName.trim();
  if (phone.isEmpty) return 'Enter contact number';
  if (name.isEmpty) return 'Enter customer name';

  final partner = deliveryPartner.trim();
  if (partner.isEmpty) return 'Select delivery type';

  final isNormal = partner.toUpperCase() == 'NORMAL';
  if (isNormal && (driverId == null || driverName == null || driverName.isEmpty)) {
    return 'Select a driver for Normal delivery';
  }

  final ref = (onlineOrderNumber != null && onlineOrderNumber.trim().isNotEmpty)
      ? onlineOrderNumber.trim()
      : phone;

  await cartRepo.updateCartOrderInfo(
    order.cartId,
    orderType: 'delivery',
    deliveryPartner: partner,
  );

  await orderRepo.updateOrder(
    order.copyWith(
      orderType: const Value('delivery'),
      deliveryPartner: Value(partner),
      referenceNumber: Value(ref),
      customerPhone: Value(phone),
      customerName: Value(name),
      customerEmail: Value(email?.trim()),
      customerGender: Value(gender),
      driverId: driverId != null ? Value(driverId) : const Value(null),
      driverName: driverName != null && driverName.isNotEmpty ? Value(driverName) : const Value(null),
      status: 'pending',
    ),
  );
  return null;
}

Future<String?> moveOrderToDineIn({
  required OrderRepository orderRepo,
  required CartRepository cartRepo,
  required Order order,
  required int floorId,
  required DiningTable table,
  required int pax,
}) async {
  if (!orderCanMoveBetweenLogs(order)) {
    return 'Cannot move completed, delivered, or cancelled orders';
  }
  if (pax < 1) return 'Enter a valid pax count';

  await cartRepo.updateCartOrderInfo(
    order.cartId,
    orderType: 'dine_in',
    deliveryPartner: null,
  );

  final ref = DineInRefParser.buildReference(floorId, table.code, pax);

  await orderRepo.updateOrder(
    order.copyWith(
      orderType: const Value('dine_in'),
      referenceNumber: Value(ref),
      deliveryPartner: const Value(null),
      driverId: const Value(null),
      driverName: const Value(null),
    ),
  );
  return null;
}
