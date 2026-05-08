import 'package:dio/dio.dart';

class NetworkExceptions implements Exception {
  final String message;

  NetworkExceptions(this.message);

  @override
  String toString() => message;

  factory NetworkExceptions.fromDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return NetworkExceptions('Connection timeout');
      case DioExceptionType.sendTimeout:
        return NetworkExceptions('Send timeout');
      case DioExceptionType.receiveTimeout:
        return NetworkExceptions('Receive timeout');
      case DioExceptionType.badCertificate:
        return NetworkExceptions(
          _withUnderlying('SSL/certificate problem (check HTTPS date, proxy, or MITM)', e),
        );
      case DioExceptionType.badResponse:
        return NetworkExceptions(_badResponseMessage(e));
      case DioExceptionType.cancel:
        return NetworkExceptions('Request cancelled');
      case DioExceptionType.connectionError:
        final msg = (e.message ?? '').toLowerCase();
        if (msg.contains('semaphore timeout')) {
          return NetworkExceptions(
            'Network timeout from Windows socket layer. Check internet/VPN/firewall and try again.',
          );
        }
        return NetworkExceptions(_withUnderlying('No internet connection', e));
      case DioExceptionType.unknown:
        return NetworkExceptions(_withUnderlying('Network request failed', e));
    }
  }
}

String _badResponseMessage(DioException e) {
  final code = e.response?.statusCode;
  final data = e.response?.data;
  if (data is Map) {
    final m = data['message'] ?? data['error'] ?? data['msg'];
    if (m != null && '$m'.trim().isNotEmpty) {
      return 'Server error${code != null ? ' ($code)' : ''}: $m';
    }
  }
  if (data is String && data.trim().isNotEmpty) {
    final t = data.trim();
    final short = t.length > 200 ? '${t.substring(0, 200)}…' : t;
    return 'Server error${code != null ? ' ($code)' : ''}: $short';
  }
  return 'Server error: ${code ?? 'unknown'}';
}

/// Prefer [DioException.error] (e.g. [SocketException]), then message — never a vague "Unexpected error".
String _withUnderlying(String headline, DioException e) {
  final err = e.error;
  if (err != null) {
    final s = err.toString().trim();
    if (s.isNotEmpty) {
      return '$headline: $s';
    }
  }
  final m = e.message?.trim();
  if (m != null && m.isNotEmpty) {
    return '$headline: $m';
  }
  return headline;
}
