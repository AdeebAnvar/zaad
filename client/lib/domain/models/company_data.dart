// To parse this JSON data, do
//
//     final companyData = companyDataFromJson(jsonString);
// To parse this JSON data, do
//
//     final companyDataModel = companyDataModelFromJson(jsonString);

import 'dart:convert';

import 'package:pos/domain/models/branch_model.dart';
import 'package:pos/domain/models/settings_model.dart';
import 'package:pos/domain/models/user_model.dart';

CompanyDataModel companyDataModelFromJson(String str) => CompanyDataModel.fromJson(json.decode(str));

String companyDataModelToJson(CompanyDataModel data) => json.encode(data.toJson());

class CompanyDataModel {
  final bool success;
  final String message;
  final Data data;
  final dynamic errors;

  CompanyDataModel({
    required this.success,
    required this.message,
    required this.data,
    required this.errors,
  });

  CompanyDataModel copyWith({
    bool? success,
    String? message,
    Data? data,
    dynamic errors,
  }) =>
      CompanyDataModel(
        success: success ?? this.success,
        message: message ?? this.message,
        data: data ?? this.data,
        errors: errors ?? this.errors,
      );

  factory CompanyDataModel.fromJson(Map<String, dynamic> json) => CompanyDataModel(
        success: json["success"] == true || json["success"]?.toString().toLowerCase() == 'true',
        message: json["message"]?.toString() ?? '',
        data: json["data"] is Map
            ? Data.fromJson(Map<String, dynamic>.from(json["data"] as Map))
            : Data(branch: const [], user: const [], settings: SettingsModel.empty()),
        errors: json["errors"],
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": data.toJson(),
        "errors": errors,
      };
}

class Data {
  final List<BranchModel> branch;
  final List<UserModel> user;
  final SettingsModel settings;

  Data({
    required this.branch,
    required this.user,
    required this.settings,
  });

  Data copyWith({
    List<BranchModel>? branch,
    List<UserModel>? user,
    SettingsModel? settings,
  }) =>
      Data(
        branch: branch ?? this.branch,
        user: user ?? this.user,
        settings: settings ?? this.settings,
      );

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        branch: (json["branch"] as List?)
                ?.map((x) => BranchModel.fromJson(Map<String, dynamic>.from(x as Map)))
                .toList() ??
            const [],
        user: (json["user"] as List?)
                ?.map((x) => UserModel.fromJson(Map<String, dynamic>.from(x as Map)))
                .toList() ??
            const [],
        settings: json["settings"] is Map
            ? SettingsModel.fromJson(Map<String, dynamic>.from(json["settings"] as Map))
            : SettingsModel.empty(),
      );

  Map<String, dynamic> toJson() => {
        "branch": List<dynamic>.from(branch.map((x) => x.toJson())),
        "user": List<dynamic>.from(user.map((x) => x.toJson())),
        "settings": settings.toJson(),
      };
}
