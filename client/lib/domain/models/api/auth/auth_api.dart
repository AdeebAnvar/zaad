import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../dio_client.dart';
import '../api_endpoints.dart';

class AuthApi {
  Future<String?> getBaseUrl(String code) async {
    // Force this request to use the common host call only (ignore saved baseUrl).
    final dio = await DioClient.getInstance(overrideBaseUrl: ApiEndpoints.commonBaseUrl);

    final response = await dio.get(
      ApiEndpoints.commonBaseUrl,
      queryParameters: {"appid": code},
    );
    final raw = response.data;
    if (raw is! Map) {
      throw FormatException(
        'App lookup response was not a JSON object (got ${raw.runtimeType})',
      );
    }
    final data = Map<String, dynamic>.from(raw);
    if (data.containsKey('message')) {
      return '${data['message']}';
    }

    final url = data['url'];
    if (url == null || '$url'.trim().isEmpty) {
      throw const FormatException('Server response did not include tenant URL');
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('baseUrl', '$url');
    return null;
  }

  // STEP 2: Fetch company data
  Future<Response> getCompanyData() async {
    final dio = await DioClient.getInstance();

    return await dio.get(ApiEndpoints.getCompanyData);
  }

  /// Tenant REST root written by [getBaseUrl].
  Future<String?> getSavedBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString('baseUrl')?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }
}
