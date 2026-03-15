import 'package:flutter/material.dart';

/// Shows a popup listing printer(s) that failed; working printers still printed.
void showPrintFailedDialog(BuildContext context, List<String> failedPrinterLabels) {
  if (failedPrinterLabels.isEmpty || !context.mounted) return;
  final message = failedPrinterLabels.length == 1
      ? '${failedPrinterLabels.single} failed to print.'
      : 'The following printer(s) failed to print:\n${failedPrinterLabels.join('\n')}';
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 8),
          Text('Printer(s) failed'),
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
