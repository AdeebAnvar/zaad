import 'package:flutter/material.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/presentation/widgets/app_standard_dialog.dart';

/// Shows a popup listing printer(s) that failed; working printers still printed.
void showPrintFailedDialog(BuildContext context, List<String> failedPrinterLabels) {
  if (failedPrinterLabels.isEmpty || !context.mounted) return;
  final message = failedPrinterLabels.length == 1
      ? '${failedPrinterLabels.single} failed to print.'
      : 'The following printer(s) failed to print:\n${failedPrinterLabels.join('\n')}';
  showAppMessageDialog(
    context,
    title: '',
    titleRow: Row(
      children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.orange),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Printer(s) failed',
            style: AppStyles.getSemiBoldTextStyle(fontSize: 18),
          ),
        ),
      ],
    ),
    message: message,
  );
}

/// Shows an error dialog with the given message or exception.
void showErrorDialog(BuildContext context, Object error) {
  String message = error.toString();
  if (message.startsWith('Exception: ')) {
    message = message.substring(11);
  }
  if (!context.mounted) return;
  showAppMessageDialog(
    context,
    title: '',
    titleRow: Row(
      children: [
        const Icon(Icons.error_outline, color: Colors.red),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Error',
            style: AppStyles.getSemiBoldTextStyle(fontSize: 18),
          ),
        ),
      ],
    ),
    message: message,
  );
}
