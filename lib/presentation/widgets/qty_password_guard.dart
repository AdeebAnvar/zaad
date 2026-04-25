import 'package:flutter/material.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/core/settings/runtime_app_settings.dart';
import 'package:pos/presentation/widgets/custom_button.dart';
import 'package:pos/presentation/widgets/custom_textfield.dart';
import 'package:pos/presentation/widgets/custom_toast.dart';

/// Validates action against settings `qtyReducePassword`.
/// If no password is configured, allows action immediately.
Future<bool> requireQtyPassword(
  BuildContext context, {
  String actionLabel = 'continue',
}) async {
  final expected = RuntimeAppSettings.qtyReducePassword;
  if (expected.isEmpty) return true;

  final controller = TextEditingController();
  bool allowed = false;

  await showGeneralDialog<void>(
    context: context,
    barrierLabel: 'Qty Password',
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, color: AppColors.primaryColor, size: 32),
                const SizedBox(height: 8),
                Text(
                  'Enter qty password',
                  style: AppStyles.getBoldTextStyle(fontSize: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  'Password is required to $actionLabel.',
                  style: AppStyles.getRegularTextStyle(fontSize: 13, color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: controller,
                  labelText: 'Password',
                  obscureText: true,
                  onSubmitted: (_) {
                    final ok = controller.text.trim() == expected;
                    if (!ok) {
                      CustomSnackBar.showError(message: 'Invalid qty password');
                      return;
                    }
                    allowed = true;
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: actionLabel,
                        onPressed: () {
                          final ok = controller.text.trim() == expected;
                          if (!ok) {
                            CustomSnackBar.showError(message: 'Invalid qty password');
                            return;
                          }
                          allowed = true;
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      );
    },
    transitionBuilder: (_, animation, __, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: 0.92, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
          ),
          child: child,
        ),
      );
    },
  );

  controller.dispose();
  return allowed;
}

