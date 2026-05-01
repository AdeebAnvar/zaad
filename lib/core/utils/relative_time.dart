import 'package:intl/intl.dart';

/// Human-readable relative time (e.g. "2 seconds ago", "3 mins ago").
/// For very old timestamps, falls back to a fixed [DateFormat] string.
String formatRelativeTimeAgo(DateTime at, {DateTime? clock}) {
  final now = clock ?? DateTime.now();
  var diff = now.difference(at);
  if (diff.isNegative) {
    return DateFormat('dd MMM yyyy, HH:mm').format(at);
  }
  if (diff.inSeconds < 5) return 'Just now';
  if (diff.inSeconds < 60) {
    final s = diff.inSeconds;
    return '$s ${s == 1 ? 's' : 's'} ago';
  }
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return '$m ${m == 1 ? 'm' : 'm'} ago';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return '$h ${h == 1 ? 'hr' : 'hr'} ago';
  }
  if (diff.inDays < 7) {
    final d = diff.inDays;
    return '$d ${d == 1 ? 'day' : 'days'} ago';
  }
  return DateFormat('dd MMM yyyy, HH:mm').format(at);
}
