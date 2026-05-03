import 'package:flutter/material.dart';
import 'package:pos/presentation/widgets/modern_bottom_sheet.dart';

class CustomSheet {
  /// Static filter sheet: fixed max height (no drag-to-resize). Content scrolls inside.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,

    /// Max height as a fraction of screen height.
    double maxChildSize = 0.85,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
  }) {
    return showModernModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        final resolved = padding.resolve(Directionality.of(sheetContext));
        final screenH = MediaQuery.sizeOf(sheetContext).height;
        final maxH = screenH * maxChildSize.clamp(0.25, 1.0);

        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH),
            child: SingleChildScrollView(
              padding: resolved,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ModernSheetGrabHandle(),
                  child,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
