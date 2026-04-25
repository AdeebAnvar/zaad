import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DioClient {
  static Dio? _dio;

  static Future<Dio> getInstance() async {
    _dio ??= Dio();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String baseUrl = prefs.getString('baseUrl') ?? "";
    _dio!.options.baseUrl = baseUrl;

    _dio!.options.connectTimeout = const Duration(seconds: 30);
    _dio!.options.receiveTimeout = const Duration(seconds: 30);

    final hasPrettyLogger = _dio!.interceptors.any(
      (interceptor) => interceptor is PrettyDioLogger,
    );
    if (!hasPrettyLogger) {
      _dio!.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: true,
          error: true,
          compact: true,
          maxWidth: 90,
        ),
      );
    }

    return _dio!;
  }
}
