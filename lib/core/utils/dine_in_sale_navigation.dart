import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/app/routes.dart';
import 'package:pos/presentation/sale/cart_cubit/cart_cubit.dart';

/// After KOT or payment on the counter, return to the Dine In floor plan.
void schedulePopSaleScreenToDineIn(BuildContext context) {
  SchedulerBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    try {
      if (context.read<CartCubit>().orderType != 'dine_in') return;
    } catch (_) {
      return;
    }
    final nav = Navigator.of(context);
    nav.popUntil((route) {
      final n = route.settings.name;
      return n == Routes.dineIn || route.isFirst;
    });
  });
}
