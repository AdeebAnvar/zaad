import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pos/core/utils/dine_in_sale_navigation.dart';
import 'package:pos/core/utils/error_dialog_utils.dart';
import 'package:pos/presentation/sale/cart_cubit/payment_save_result.dart';

/// After Pay SUBMIT: callback, optional dine-in pop, deferred print-failure dialog.
void completePaymentSaveUi({
  required BuildContext parentContext,
  required PaymentSaveResult result,
  VoidCallback? onPaymentRecorded,
}) {
  onPaymentRecorded?.call();

  SchedulerBinding.instance.addPostFrameCallback((_) {
    if (parentContext.mounted) {
      schedulePopSaleScreenToDineIn(parentContext);
    }
  });

  unawaited(
    result.printFailures.then((printFailed) {
      if (parentContext.mounted && printFailed.isNotEmpty) {
        showPrintFailedDialog(parentContext, printFailed);
      }
    }),
  );
}
