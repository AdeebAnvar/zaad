import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/presentation/widgets/custom_button.dart';
import 'package:pos/presentation/widgets/custom_outlined_button.dart';
import 'package:pos/presentation/widgets/modern_bottom_sheet.dart';

/// Shared padding and width for all app dialogs (responsive).
class AppDialogLayout {
  AppDialogLayout._();

  static EdgeInsets insetPadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;
    final hPad = math.max(16.0, math.min(48.0, w * 0.04));
    final vPad = math.max(20.0, math.min(56.0, h * 0.05));
    return EdgeInsets.symmetric(horizontal: hPad, vertical: vPad);
  }

  /// Max width for standard dialogs (confirm, message, simple forms).
  static double maxContentWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final padded = w - 32;
    if (w <= 360) return math.max(260.0, padded);
    if (w <= 600) return math.min(480.0, padded);
    return math.min(520.0, padded);
  }

  /// Max height for scrollable dialog bodies.
  static double maxContentHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height * 0.88;

  /// Wider dialogs (order line items, reports).
  static double maxDetailContentWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final padded = w - 24;
    if (w > 1000) return math.min(760.0, padded);
    if (w > 700) return math.min(640.0, padded);
    return math.max(280.0, w * 0.96);
  }
}

/// White rounded dialog shell — use for custom content; matches app style.
class AppStandardDialog extends StatelessWidget {
  const AppStandardDialog({
    super.key,
    required this.child,
    this.title,
    this.actions,
  });

  final Widget child;
  final Widget? title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final maxH = math.min(640.0, h * 0.88);
    final maxW = AppDialogLayout.maxContentWidth(context);

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      insetPadding: AppDialogLayout.insetPadding(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: maxW,
        height: maxH,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null) ...[
                title!,
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: SingleChildScrollView(
                  child: child,
                ),
              ),
              if (actions != null && actions!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: actions!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Narrow: bottom sheet with optional [title] row; wide: [AppStandardDialog].
Future<T?> showAppAdaptiveSheetOrDialog<T>({
  required BuildContext context,
  required Widget child,
  Widget? title,
  List<Widget> Function(BuildContext dialogContext)? dialogActions,
  double sheetHeightFraction = 0.58,
  double breakpoint = 600,
}) {
  final useSheet = MediaQuery.sizeOf(context).width < breakpoint;
  if (useSheet) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final h = MediaQuery.sizeOf(ctx).height;
        return Material(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shadowColor: Colors.transparent,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
            child: SizedBox(
              height: h * sheetHeightFraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ModernSheetGrabHandle(),
                  if (title != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 4, 4),
                      child: Row(
                        children: [
                          Expanded(child: title),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                  if (title != null) Divider(height: 1, color: Colors.grey.shade200),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  return showDialog<T>(
    context: context,
    builder: (ctx) => AppStandardDialog(
      title: title,
      actions: dialogActions?.call(ctx),
      child: child,
    ),
  );
}

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
        insetPadding: AppDialogLayout.insetPadding(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: AppDialogLayout.maxContentWidth(context)),
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
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    CustomOutlinedButton(
                      width: 100,
                      text: cancelText,
                      onPressed: () => Navigator.pop(ctx, false),
                    ),
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
        insetPadding: AppDialogLayout.insetPadding(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: AppDialogLayout.maxContentWidth(context)),
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
