import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../dio_client.dart';
import '../api_endpoints.dart';

class AuthApi {
  Future<void> getBaseUrl(String code) async {
    // final dio = DioClient.getInstance(baseUrl: ApiEndpoints.commonBaseUrl);

    // final response = await dio.get(
    //   ApiEndpoints.getBaseUrl,
    //   queryParameters: {"code": code},
    // );
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('baseUrl', ApiEndpoints.commonBaseUrl);

    // response.data['base_url'];
  }

  // STEP 2: Fetch company data
  Future<Response> getCompanyData() async {
    final dio = await DioClient.getInstance();

    return await dio.get(ApiEndpoints.getCompanyData);
  }
}
