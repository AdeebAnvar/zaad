import 'package:dio/dio.dart';

/// Set on [RequestOptions.extra] to skip [DioBadApiStatusInterceptor] user toasts
/// (e.g. item/branch image downloads that are not tenant REST API calls).
const String kSuppressBadApiStatusToast = 'suppress_bad_api_status_toast';

/// True for tenant REST calls (`/api/...`), false for media/storage URLs and flagged requests.
bool isTenantApiRequest(RequestOptions options) {
  if (options.extra[kSuppressBadApiStatusToast] == true) return false;
  final path = options.uri.path;
  if (path.contains('/api/')) return true;
  final relative = options.path;
  if (relative.contains('/api/')) return true;
  return false;
}
