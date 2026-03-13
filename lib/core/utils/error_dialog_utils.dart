import 'package:flutter/material.dart';

/// Shows an error dialog with the given message or exception.
void showErrorDialog(BuildContext context, Object error) {
  String message = error.toString();
  // Strip "Exception: " prefix for cleaner display
  if (message.startsWith('Exception: ')) {
    message = message.substring(11);
  }
  if (!context.mounted) return;
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red),
          SizedBox(width: 8),
          Text('Error'),
        ],
      ),
      content: SelectableText(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
