class SettingsModel {
  final String currency;
  final String decimalPoint;
  final String dateFormat;
  final String timeFormat;
  final String unitPrice;
  final String stockCheck;
  final String stockShow;
  final String settleCheckPending;
  final String deliverySale;
  final String apiKey;
  final String customProduct;
  final String language;
  final String staffPin;
  final String barcode;
  final String drawerPassword;
  final String paybackPassword;
  final String purchase;
  final String production;
  final String minimumStock;
  final String wastageUsage;
  final String wastageUsageZeroStock;
  final String customizeItem;
  final String printType;
  final String printLink;
  final String mainPrintType;
  final String mainPrintDetail;
  final String printImageInBill;
  final String printBranchNameInBill;
  final String dineInTableOrderCount;
  final String variation;
  final String qtyReducePassword;
  final String counterLoginLimit;

  SettingsModel({
    required this.currency,
    required this.decimalPoint,
    required this.dateFormat,
    required this.timeFormat,
    required this.unitPrice,
    required this.stockCheck,
    required this.stockShow,
    required this.settleCheckPending,
    required this.deliverySale,
    required this.apiKey,
    required this.customProduct,
    required this.language,
    required this.staffPin,
    required this.barcode,
    required this.drawerPassword,
    required this.paybackPassword,
    required this.purchase,
    required this.production,
    required this.minimumStock,
    required this.wastageUsage,
    required this.wastageUsageZeroStock,
    required this.customizeItem,
    required this.printType,
    required this.printLink,
    required this.mainPrintType,
    required this.mainPrintDetail,
    required this.printImageInBill,
    required this.printBranchNameInBill,
    required this.dineInTableOrderCount,
    required this.variation,
    required this.qtyReducePassword,
    required this.counterLoginLimit,
  });

  SettingsModel copyWith({
    String? currency,
    String? decimalPoint,
    String? dateFormat,
    String? timeFormat,
    String? unitPrice,
    String? stockCheck,
    String? stockShow,
    String? settleCheckPending,
    String? deliverySale,
    String? apiKey,
    String? customProduct,
    String? language,
    String? staffPin,
    String? barcode,
    String? drawerPassword,
    String? paybackPassword,
    String? purchase,
    String? production,
    String? minimumStock,
    String? wastageUsage,
    String? wastageUsageZeroStock,
    String? customizeItem,
    String? printType,
    String? printLink,
    String? mainPrintType,
    String? mainPrintDetail,
    String? printImageInBill,
    String? printBranchNameInBill,
    String? dineInTableOrderCount,
    String? variation,
    String? qtyReducePassword,
    String? counterLoginLimit,
  }) =>
      SettingsModel(
        currency: currency ?? this.currency,
        decimalPoint: decimalPoint ?? this.decimalPoint,
        dateFormat: dateFormat ?? this.dateFormat,
        timeFormat: timeFormat ?? this.timeFormat,
        unitPrice: unitPrice ?? this.unitPrice,
        stockCheck: stockCheck ?? this.stockCheck,
        stockShow: stockShow ?? this.stockShow,
        settleCheckPending: settleCheckPending ?? this.settleCheckPending,
        deliverySale: deliverySale ?? this.deliverySale,
        apiKey: apiKey ?? this.apiKey,
        customProduct: customProduct ?? this.customProduct,
        language: language ?? this.language,
        staffPin: staffPin ?? this.staffPin,
        barcode: barcode ?? this.barcode,
        drawerPassword: drawerPassword ?? this.drawerPassword,
        paybackPassword: paybackPassword ?? this.paybackPassword,
        purchase: purchase ?? this.purchase,
        production: production ?? this.production,
        minimumStock: minimumStock ?? this.minimumStock,
        wastageUsage: wastageUsage ?? this.wastageUsage,
        wastageUsageZeroStock: wastageUsageZeroStock ?? this.wastageUsageZeroStock,
        customizeItem: customizeItem ?? this.customizeItem,
        printType: printType ?? this.printType,
        printLink: printLink ?? this.printLink,
        mainPrintType: mainPrintType ?? this.mainPrintType,
        mainPrintDetail: mainPrintDetail ?? this.mainPrintDetail,
        printImageInBill: printImageInBill ?? this.printImageInBill,
        printBranchNameInBill: printBranchNameInBill ?? this.printBranchNameInBill,
        dineInTableOrderCount: dineInTableOrderCount ?? this.dineInTableOrderCount,
        variation: variation ?? this.variation,
        qtyReducePassword: qtyReducePassword ?? this.qtyReducePassword,
        counterLoginLimit: counterLoginLimit ?? this.counterLoginLimit,
      );

  factory SettingsModel.fromJson(Map<String, dynamic> json) => SettingsModel(
        currency: json["currency"],
        decimalPoint: json["decimal_point"],
        dateFormat: json["date_format"],
        timeFormat: json["time_format"],
        unitPrice: json["unit_price"],
        stockCheck: json["stock_check"],
        stockShow: json["stock_show"],
        settleCheckPending: json["settle_check_pending"],
        deliverySale: json["delivery_sale"],
        apiKey: json["api_key"],
        customProduct: json["custom_product"],
        language: json["language"],
        staffPin: json["staff_pin"],
        barcode: json["barcode"],
        drawerPassword: json["drawer_password"],
        paybackPassword: json["payback_password"],
        purchase: json["purchase"],
        production: json["production"],
        minimumStock: json["Minimum-stock"],
        wastageUsage: json["wastage-usage"],
        wastageUsageZeroStock: json["wastage-usage-zero-stock"],
        customizeItem: json["customize_item"],
        printType: json["print_type"],
        printLink: json["print_link"],
        mainPrintType: json["main_print_type"],
        mainPrintDetail: json["main_print_detail"],
        printImageInBill: json["print_image_in_bill"],
        printBranchNameInBill: json["print_branch_name_in_bill"],
        dineInTableOrderCount: json["dine_in_table_order_count"],
        variation: json["variation"],
        qtyReducePassword: json["qty_reduce_password"],
        counterLoginLimit: json["counter_login_limit"],
      );

  Map<String, dynamic> toJson() => {
        "currency": currency,
        "decimal_point": decimalPoint,
        "date_format": dateFormat,
        "time_format": timeFormat,
        "unit_price": unitPrice,
        "stock_check": stockCheck,
        "stock_show": stockShow,
        "settle_check_pending": settleCheckPending,
        "delivery_sale": deliverySale,
        "api_key": apiKey,
        "custom_product": customProduct,
        "language": language,
        "staff_pin": staffPin,
        "barcode": barcode,
        "drawer_password": drawerPassword,
        "payback_password": paybackPassword,
        "purchase": purchase,
        "production": production,
        "Minimum-stock": minimumStock,
        "wastage-usage": wastageUsage,
        "wastage-usage-zero-stock": wastageUsageZeroStock,
        "customize_item": customizeItem,
        "print_type": printType,
        "print_link": printLink,
        "main_print_type": mainPrintType,
        "main_print_detail": mainPrintDetail,
        "print_image_in_bill": printImageInBill,
        "print_branch_name_in_bill": printBranchNameInBill,
        "dine_in_table_order_count": dineInTableOrderCount,
        "variation": variation,
        "qty_reduce_password": qtyReducePassword,
        "counter_login_limit": counterLoginLimit,
      };
}
