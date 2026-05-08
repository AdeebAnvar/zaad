import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:pos/domain/models/api/auth/auth_api.dart';
import 'package:pos/domain/models/company_data.dart';

import '../network_exceptions.dart';

class AuthRepository {
  final AuthApi api;

  AuthRepository(this.api);

  Future<String?> getSavedBaseUrl() => api.getSavedBaseUrl();

  Future<CompanyDataModel> connectToServer(String code) async {
    try {
      final connectMessage = await api.getBaseUrl(code);
      if (connectMessage != null) {
        throw NetworkExceptions(connectMessage);
      }

      final response = await api.getCompanyData();

      final companyData = CompanyDataModel.fromJson(_jsonBodyAsMap(response.data));

      return companyData;
    } catch (e) {
      throw _handleError(e);
    }
  }
}

/// Dio may return [Map], decoded JSON [String], or other types depending on content-type.
Map<String, dynamic> _jsonBodyAsMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  if (data is String) {
    final trimmed = data.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Empty company data response body');
    }
    final decoded = jsonDecode(trimmed);
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    throw FormatException('Company data JSON was not an object (got ${decoded.runtimeType})');
  }
  throw FormatException('Company data response was not JSON object (got ${data.runtimeType})');
}

Exception _handleError(dynamic e) {
  if (e is NetworkExceptions) {
    return e;
  }
  if (e is DioException) {
    return NetworkExceptions.fromDioError(e);
  }
  final message = _describeNonDioError(e);
  return NetworkExceptions(message);
}

String _describeNonDioError(Object? e) {
  if (e == null) {
    return 'Unknown error (null). Try again; if this repeats, restart the app.';
  }
  if (e is FormatException) {
    final m = e.message.trim();
    return m.isNotEmpty ? m : e.toString();
  }
  final s = e.toString().trim();
  return s.isNotEmpty ? s : e.runtimeType.toString();
}
