import 'package:flutter/material.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/presentation/settings/kitchen_settings_dialog.dart';
import 'package:pos/presentation/widgets/custom_scaffold.dart';

class PrinterSettingsScreen extends StatelessWidget {
  const PrinterSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Printer Settings',
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1000;
          // final panelWidth = isWide ? 980.0 : constraints.maxWidth;

          return SingleChildScrollView(
            // padding: AppPadding.screenAll,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const KitchenSettingsDialog(embedded: true),
              ),
            ),
          );
        },
      ),
    );
  }
}
