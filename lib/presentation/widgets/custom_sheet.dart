import 'package:flutter/material.dart';

class CustomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    double maxChildSize = 0.85,
    double minChildSize = 0.4,
    double initialChildSize = 0.5,
    bool expand = false,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          maxChildSize: maxChildSize,
          minChildSize: minChildSize,
          initialChildSize: initialChildSize,
          expand: expand,
          builder: (_, controller) {
            return Container(
              padding: padding,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                controller: controller,
                child: child,
              ),
            );
          },
        );
      },
    );
  }
}
