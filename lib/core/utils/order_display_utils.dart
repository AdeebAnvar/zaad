import 'package:flutter/material.dart';
import 'package:pos/data/local/drift_database.dart';

/// Normalizes phone for loose matching (digits only).
String? normalizePhoneDigits(String? phone) {
  if (phone == null || phone.isEmpty) return null;
  return phone.replaceAll(RegExp(r'\D'), '');
}

/// DB `order_type` value: `take_away` | `dine_in` | `delivery`. Null/legacy → take away.
String orderTypeKey(Order order) => (order.orderType ?? 'take_away').toLowerCase();

/// Short label for UI chips and tables.
String orderTypeShortLabel(Order order) {
  switch (orderTypeKey(order)) {
    case 'dine_in':
      return 'Dine In';
    case 'delivery':
      return 'Delivery';
    case 'take_away':
    default:
      return 'Take Away';
  }
}

/// Upper tag style (legacy cards).
String orderTypeUpperTag(Order order) => orderTypeShortLabel(order).toUpperCase();

IconData orderTypeIcon(Order order) {
  switch (orderTypeKey(order)) {
    case 'dine_in':
      return Icons.restaurant;
    case 'delivery':
      return Icons.local_shipping_outlined;
    default:
      return Icons.shopping_bag_outlined;
  }
}

Color orderTypeColor(Order order) {
  switch (orderTypeKey(order)) {
    case 'dine_in':
      return const Color(0xFF7C4DFF);
    case 'delivery':
      return const Color(0xFF00897B);
    default:
      return const Color(0xFF1565C0);
  }
}

/// True when the order has any persisted customer fields for log cards / dialogs.
bool orderHasCustomerDetails(Order order) {
  final name = order.customerName?.trim();
  final phone = order.customerPhone?.trim();
  final email = order.customerEmail?.trim();
  final gender = order.customerGender?.trim();
  return (name != null && name.isNotEmpty) ||
      (phone != null && phone.isNotEmpty) ||
      (email != null && email.isNotEmpty) ||
      (gender != null && gender.isNotEmpty);
}

/// Name and phone when both exist (matches filter bar style); otherwise whichever is set.
String orderLogCustomerLabel(Order order) {
  final name = order.customerName?.trim();
  final phone = order.customerPhone?.trim();
  final hasName = name != null && name.isNotEmpty;
  final hasPhone = phone != null && phone.isNotEmpty;
  if (hasName && hasPhone) return '$name - $phone';
  if (hasPhone) return phone;
  if (hasName) return name;
  return '';
}

/// Maps Recent Sales filter dropdown values to DAO `orderType` parameter.
String? orderTypeFilterToDb(String? uiLabel) {
  if (uiLabel == null || uiLabel.isEmpty || uiLabel == 'All') return null;
  switch (uiLabel.trim()) {
    case 'Take Away':
      return 'take_away';
    case 'Dine In':
      return 'dine_in';
    case 'Delivery':
      return 'delivery';
    default:
      return null;
  }
}
