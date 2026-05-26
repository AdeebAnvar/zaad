/// Default cap for order log screens when not narrowed by search filters.
const int kOrderLogDefaultListLimit = 400;

/// Recent Sales list page size (DB pagination).
const int kRecentSalesPageSize = 20;

/// True when the user narrowed the list (no default row cap).
bool orderLogListIsNarrowed({
  String? invoiceNumber,
  String? referenceNumber,
  String? customerPhone,
  int? pickupToken,
  DateTime? startDate,
  DateTime? endDate,
}) {
  if (invoiceNumber != null && invoiceNumber.trim().isNotEmpty) return true;
  if (referenceNumber != null && referenceNumber.trim().isNotEmpty) return true;
  if (customerPhone != null && customerPhone.trim().isNotEmpty) return true;
  if (pickupToken != null) return true;
  if (startDate != null || endDate != null) return true;
  return false;
}

/// [kOrderLogDefaultListLimit] unless the user applied narrow search filters.
int? orderLogDefaultQueryLimit({
  String? invoiceNumber,
  String? referenceNumber,
  String? customerPhone,
  int? pickupToken,
  DateTime? startDate,
  DateTime? endDate,
}) =>
    orderLogListIsNarrowed(
      invoiceNumber: invoiceNumber,
      referenceNumber: referenceNumber,
      customerPhone: customerPhone,
      pickupToken: pickupToken,
      startDate: startDate,
      endDate: endDate,
    )
        ? null
        : kOrderLogDefaultListLimit;
