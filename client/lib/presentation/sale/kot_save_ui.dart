import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/constants/enums.dart';
import 'package:pos/core/utils/dine_in_sale_navigation.dart';
import 'package:pos/core/utils/error_dialog_utils.dart';
import 'package:pos/presentation/sale/cart_cubit/cart_cubit.dart';
import 'package:pos/presentation/sale/cart_cubit/kot_save_result.dart';
import 'package:pos/presentation/widgets/custom_toast.dart';

/// Snackbar, navigation, and deferred print-failure dialog after [KotSaveResult].
void completeKotSaveUi({
  required BuildContext parentContext,
  required KotSaveResult result,
  BuildContext? dialogContext,
  bool isModalBottomSheet = false,
  bool closeOnComplete = false,
  void Function(bool closed)? onCloseCart,
}) {
  if (dialogContext != null && dialogContext.mounted) {
    Navigator.of(dialogContext, rootNavigator: true).pop();
  }
  if (!parentContext.mounted) return;

  CustomSnackBar.showKotSaved(context: parentContext);

  if (isModalBottomSheet) {
    onCloseCart?.call(true);
  } else if (closeOnComplete && parentContext.mounted) {
    Navigator.of(parentContext).pop();
  }

  // Let the snackbar paint before navigation, print, or hub refresh work.
  SchedulerBinding.instance.addPostFrameCallback((_) {
    if (!parentContext.mounted) return;
    try {
      if (parentContext.read<CartCubit>().orderType == OrderType.dineIn) {
        schedulePopSaleScreenToDineIn(parentContext);
      }
    } catch (_) {
      /* CartCubit not in tree */
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
