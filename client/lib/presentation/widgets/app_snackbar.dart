import 'package:flutter/material.dart';
import 'package:pos/presentation/widgets/custom_toast.dart';

/// App-wide toast: uses [CustomSnackBar] (icon + colored banner), not Material [SnackBar].
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
  bool isWarning = false,
}) {
  if (isError) {
    CustomSnackBar.showError(message: message, floating: true);
  } else if (isWarning) {
    CustomSnackBar.showWarning(message: message, floating: true);
  } else {
    CustomSnackBar.showSuccess(message: message, floating: true);
  }
}
