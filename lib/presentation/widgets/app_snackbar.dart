import 'package:flutter/material.dart';

/// Floating snack bar with horizontal margin that scales with viewport width.
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final w = MediaQuery.sizeOf(context).width;
  final horizontal = w < 360 ? 8.0 : w < 600 ? 16.0 : 24.0;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 16),
      backgroundColor: isError ? Colors.red.shade700 : null,
    ),
  );
}
