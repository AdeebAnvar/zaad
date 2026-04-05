import 'package:flutter/material.dart';

/// Hairline border, no drop shadow — for filter panels inside sheets or on desktop.
BoxDecoration filterPanelDecoration({Color? backgroundColor, double borderRadius = 14}) {
  return BoxDecoration(
    color: backgroundColor ?? Colors.white,
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(color: Colors.grey.shade200),
  );
}

/// Flat white sheet: no Material 3 surface tint, no shadow (wraps content in [Material]).
Future<T?> showModernModalBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext context) builder,
  bool isScrollControlled = true,
  bool useSafeArea = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: Colors.black.withValues(alpha: 0.38),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _ModernSheetSurface(
      child: builder(ctx),
    ),
  );
}

/// Rounded top, white fill, no elevation/tint (use as root of bottom sheet content).
class _ModernSheetSurface extends StatelessWidget {
  const _ModernSheetSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// Optional pill at top of filter sheets (place as first child inside scroll content).
class ModernSheetGrabHandle extends StatelessWidget {
  const ModernSheetGrabHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
