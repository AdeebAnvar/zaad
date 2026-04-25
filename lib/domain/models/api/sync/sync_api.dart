import 'package:dio/dio.dart';
import '../dio_client.dart';
import '../api_endpoints.dart';

class SyncApi {
  /// Fetches pull/sync data. The backend is expected to support pagination via
  /// query parameters (e.g. `page`, `module`) when requesting one resource at a time;
  /// see [PullDataRepositoryImpl] and [ApiEndpoints].
  Future<Response> pullData([Map<String, dynamic>? queryParameters]) async {
    final dio = await DioClient.getInstance();
    return dio.get(
      ApiEndpoints.pullData,
      queryParameters: (queryParameters == null || queryParameters.isEmpty) ? null : queryParameters,
    );
  }

  Future<Response> pushData(Map<String, dynamic> body) async {
    final dio = await DioClient.getInstance();

    return await dio.post(
      ApiEndpoints.pushData,
      data: body,
    );
  }
}
