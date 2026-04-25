// To parse this JSON data, do
//
//     final companyData = companyDataFromJson(jsonString);

import 'dart:convert';

import 'package:pos/domain/models/branch_model.dart';
import 'package:pos/domain/models/settings_model.dart';
import 'package:pos/domain/models/user_model.dart';

CompanyDataModel companyDataFromJson(String str) => CompanyDataModel.fromJson(json.decode(str));

String companyDataToJson(CompanyDataModel data) => json.encode(data.toJson());

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
        success: json["success"],
        message: json["message"],
        data: Data.fromJson(json["data"]),
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
        branch: List<BranchModel>.from(json["branch"].map((x) => BranchModel.fromJson(x))),
        user: List<UserModel>.from(json["user"].map((x) => UserModel.fromJson(x))),
        settings: SettingsModel.fromJson(json["settings"]),
      );

  Map<String, dynamic> toJson() => {
        "branch": List<dynamic>.from(branch.map((x) => x.toJson())),
        "user": List<dynamic>.from(user.map((x) => x.toJson())),
        "settings": settings.toJson(),
      };
}
