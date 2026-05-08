class BranchModel {
  final int id;
  final String branchName;
  final String location;
  final String contactNo;
  final String? email;
  final String? socialMedia;
  final String vat;
  final dynamic vatPercent;
  final String? trnNumber;
  final String prefixInv;
  final String invoiceHeader;
  final String image;

  /// Cached path after download (empty when loaded from API only).
  final String localImage;
  final DateTime installationDate;
  final DateTime expiryDate;
  final int? openingCash;

  BranchModel({
    required this.id,
    required this.branchName,
    required this.location,
    required this.contactNo,
    required this.email,
    required this.socialMedia,
    required this.vat,
    required this.vatPercent,
    required this.trnNumber,
    required this.prefixInv,
    required this.invoiceHeader,
    required this.image,
    this.localImage = '',
    required this.installationDate,
    required this.expiryDate,
    required this.openingCash,
  });

  BranchModel copyWith({
    int? id,
    String? branchName,
    String? location,
    String? contactNo,
    String? email,
    String? socialMedia,
    String? vat,
    dynamic vatPercent,
    String? trnNumber,
    String? prefixInv,
    String? invoiceHeader,
    String? image,
    String? localImage,
    DateTime? installationDate,
    DateTime? expiryDate,
    int? openingCash,
  }) =>
      BranchModel(
        id: id ?? this.id,
        branchName: branchName ?? this.branchName,
        location: location ?? this.location,
        contactNo: contactNo ?? this.contactNo,
        email: email ?? this.email,
        socialMedia: socialMedia ?? this.socialMedia,
        vat: vat ?? this.vat,
        vatPercent: vatPercent ?? this.vatPercent,
        trnNumber: trnNumber ?? this.trnNumber,
        prefixInv: prefixInv ?? this.prefixInv,
        invoiceHeader: invoiceHeader ?? this.invoiceHeader,
        image: image ?? this.image,
        localImage: localImage ?? this.localImage,
        installationDate: installationDate ?? this.installationDate,
        expiryDate: expiryDate ?? this.expiryDate,
        openingCash: openingCash ?? this.openingCash,
      );

  factory BranchModel.fromJson(Map<String, dynamic> json) => BranchModel(
        id: (json["id"] as num?)?.toInt() ?? 0,
        branchName: json["branch_name"]?.toString() ?? '',
        location: json["location"]?.toString() ?? '',
        contactNo: json["contact_no"]?.toString() ?? '',
        email: json["email"]?.toString(),
        socialMedia: json["social_media"]?.toString(),
        vat: json["vat"]?.toString() ?? '',
        vatPercent: json["vat_percent"],
        trnNumber: json["trn_number"]?.toString(),
        prefixInv: json["prefix_inv"]?.toString() ?? '',
        invoiceHeader: json["invoice_header"]?.toString() ?? '',
        image: json["image"]?.toString() ?? '',
        localImage: '',
        installationDate:
            DateTime.tryParse(json["installation_date"]?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        expiryDate: DateTime.tryParse(json["expiry_date"]?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        openingCash: (json["opening_cash"] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "branch_name": branchName,
        "location": location,
        "contact_no": contactNo,
        "email": email,
        "social_media": socialMedia,
        "vat": vat,
        "vat_percent": vatPercent,
        "trn_number": trnNumber,
        "prefix_inv": prefixInv,
        "invoice_header": invoiceHeader,
        "image": image,
        "installation_date":
            "${installationDate.year.toString().padLeft(4, '0')}-${installationDate.month.toString().padLeft(2, '0')}-${installationDate.day.toString().padLeft(2, '0')}",
        "expiry_date": "${expiryDate.year.toString().padLeft(4, '0')}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.day.toString().padLeft(2, '0')}",
        "opening_cash": openingCash,
      };
}
