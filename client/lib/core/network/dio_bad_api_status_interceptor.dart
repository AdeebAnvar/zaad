import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:pos/app/navigation.dart';
import 'package:pos/presentation/widgets/custom_toast.dart';

/// Shows a user-visible warning when tenant HTTP calls return **404** or **500**.
///
/// Throttled so burst failures (e.g. parallel sync) do not stack multiple toasts.
class DioBadApiStatusInterceptor extends Interceptor {
  DioBadApiStatusInterceptor._();

  static final DioBadApiStatusInterceptor instance = DioBadApiStatusInterceptor._();

  static DateTime? _lastToastAt;
  static const Duration _minGapBetweenToasts = Duration(seconds: 3);

  static const String _userMessage =
      'Failed to connect to the server. Check your connection and try again later.';

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final code = err.response?.statusCode;
    if (code == 404 || code == 500) {
      final now = DateTime.now();
      final last = _lastToastAt;
      if (last == null || now.difference(last) >= _minGapBetweenToasts) {
        _lastToastAt = now;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final nav = AppNavigator.navigatorKey.currentState;
          if (nav == null || !nav.mounted) return;
          CustomSnackBar.showWarning(
            message: _userMessage,
            duration: const Duration(seconds: 4),
            context: nav.context,
          );
        });
      }
    }
    handler.next(err);
  }
}
