import 'package:dio/dio.dart';
import 'package:pos/domain/models/api/auth/auth_api.dart';
import 'package:pos/domain/models/company_Data.dart';

import '../network_exceptions.dart';

class AuthRepository {
  final AuthApi api;

  AuthRepository(this.api);

  Future<String?> getSavedBaseUrl() => api.getSavedBaseUrl();

  Future<CompanyDataModel> connectToServer(String code) async {
    try {
      final connectMessage = await api.getBaseUrl(code);
      if (connectMessage != null && connectMessage.isNotEmpty) {
        throw NetworkExceptions(connectMessage);
      }

      final response = await api.getCompanyData();

      final companyData = CompanyDataModel.fromJson(response.data);

      return companyData;
    } catch (e) {
      throw _handleError(e);
    }
  }
}

Exception _handleError(dynamic e) {
  if (e is DioException) {
    return NetworkExceptions.fromDioError(e);
  } else {
    return NetworkExceptions("Unexpected error occurred");
  }
}
