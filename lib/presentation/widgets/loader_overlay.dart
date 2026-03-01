import 'package:flutter/material.dart';
import 'package:pos/core/constants/colors.dart';

class LoaderOverlay {
  static OverlayEntry? _entry;

  static void show(BuildContext context, {String message = "Loading..."}) {
    if (_entry != null) return;

    _entry = OverlayEntry(
      builder: (_) => Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Container(color: Colors.black38),
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: AppColors.primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(message, style: TextStyle(color: AppColors.textColor, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_entry!);
  }

  static void hide() {
    _entry?.remove();
    _entry = null;
  }
}
