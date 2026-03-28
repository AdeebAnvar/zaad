import 'package:flutter/material.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/presentation/widgets/custom_button.dart';
import 'package:pos/presentation/widgets/custom_outlined_button.dart';

Future<bool?> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String cancelText = 'Cancel',
  String confirmText = 'Confirm',
  Color? confirmBackgroundColor,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: AppStyles.getSemiBoldTextStyle(fontSize: 18)),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: AppStyles.getRegularTextStyle(fontSize: 14, color: AppColors.textColor),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CustomOutlinedButton(
                      width: 100,
                      text: cancelText,
                      onPressed: () => Navigator.pop(ctx, false),
                    ),
                    const SizedBox(width: 12),
                    CustomButton(
                      width: 110,
                      backgroundColor: confirmBackgroundColor ?? AppColors.primaryColor,
                      onPressed: () => Navigator.pop(ctx, true),
                      text: confirmText,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Single primary action (OK). Optional [titleRow] for icon + title.
Future<void> showAppMessageDialog(
  BuildContext context, {
  required String title,
  String? message,
  Widget? content,
  String okText = 'OK',
  Widget? titleRow,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titleRow ?? Text(title, style: AppStyles.getSemiBoldTextStyle(fontSize: 18)),
                if (message != null) ...[
                  const SizedBox(height: 12),
                  SelectableText(
                    message,
                    style: AppStyles.getRegularTextStyle(fontSize: 14, color: AppColors.textColor),
                  ),
                ],
                if (content != null) ...[
                  if (message != null) const SizedBox(height: 8) else const SizedBox(height: 12),
                  content,
                ],
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: CustomButton(
                    width: 100,
                    onPressed: () => Navigator.pop(ctx),
                    text: okText,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
