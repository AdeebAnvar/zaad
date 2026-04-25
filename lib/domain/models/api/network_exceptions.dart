import 'package:dio/dio.dart';

class NetworkExceptions implements Exception {
  final String message;

  NetworkExceptions(this.message);

  factory NetworkExceptions.fromDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return NetworkExceptions("Connection timeout");
      case DioExceptionType.sendTimeout:
        return NetworkExceptions("Send timeout");
      case DioExceptionType.receiveTimeout:
        return NetworkExceptions("Receive timeout");
      case DioExceptionType.badResponse:
        return NetworkExceptions("Server error: ${e.response?.statusCode}");
      case DioExceptionType.cancel:
        return NetworkExceptions("Request cancelled");
      case DioExceptionType.connectionError:
        return NetworkExceptions("No internet connection");
      default:
        return NetworkExceptions("Unexpected error");
    }
  }
}
