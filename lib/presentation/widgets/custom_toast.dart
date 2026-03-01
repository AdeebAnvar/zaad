import 'package:flutter/material.dart';
import 'package:pos/app/navigation.dart';
import 'package:pos/core/constants/colors.dart';

enum SnackBarType { success, error, warning, info }

enum SnackBarPosition { top, bottom }

class CustomSnackBar {
  static final Map<SnackBarType, Color> _backgroundColors = {
    SnackBarType.success: Colors.green.shade800,
    SnackBarType.error: Colors.red.shade800,
    SnackBarType.warning: Colors.orange.shade800,
    SnackBarType.info: Colors.blue.shade800,
  };

  static final Map<SnackBarType, IconData> _icons = {
    SnackBarType.success: Icons.check_circle_outline,
    SnackBarType.error: Icons.error_outline,
    SnackBarType.warning: Icons.warning_amber_outlined,
    SnackBarType.info: Icons.info_outline,
  };

  static OverlayEntry? _currentOverlay;

  static void _removeCurrentOverlay() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }

  static void show({
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
    double? width,
    bool floating = false,
    SnackBarPosition position = SnackBarPosition.bottom,
    VoidCallback? onVisible,
    BuildContext? context,
  }) {
    final overlayState = AppNavigator.navigatorKey.currentState?.overlay;
    _removeCurrentOverlay();

    _currentOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: position == SnackBarPosition.top ? (floating ? 100 : 0) : null,
        bottom: position == SnackBarPosition.bottom ? (floating ? 100 : 0) : null,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: floating ? 16.0 : 0,
                vertical: floating ? 8.0 : 0,
              ),
              child: GestureDetector(
                onTap: () {
                  _removeCurrentOverlay();
                  onTap?.call();
                },
                child: Container(
                  width: width,
                  margin: EdgeInsets.symmetric(
                    horizontal: floating ? 8.0 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: _backgroundColors[type],
                    borderRadius: BorderRadius.circular(floating ? 8 : 0),
                    boxShadow: floating
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _icons[type],
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlayState?.insert(_currentOverlay!);
    onVisible?.call();

    Future.delayed(duration, _removeCurrentOverlay);
  }

  static void showSuccess({
    required String message,
    Duration? duration,
    VoidCallback? onTap,
    double? width,
    bool floating = false,
    SnackBarPosition position = SnackBarPosition.bottom,
    VoidCallback? onVisible,
    BuildContext? context,
  }) {
    show(
      context: context ?? AppNavigator.navigatorKey.currentState!.context,
      message: message,
      type: SnackBarType.success,
      duration: duration ?? const Duration(seconds: 2),
      onTap: onTap,
      width: width,
      floating: floating,
      position: position,
      onVisible: onVisible,
    );
  }

  static void showError({
    required String message,
    Duration? duration,
    VoidCallback? onTap,
    double? width,
    bool floating = false,
    VoidCallback? onVisible,
    BuildContext? context,
  }) {
    show(
      context: context ?? AppNavigator.navigatorKey.currentState!.context,
      message: message,
      type: SnackBarType.error,
      duration: duration ?? const Duration(seconds: 4),
      onTap: onTap,
      width: width,
      floating: floating,
      onVisible: onVisible,
    );
  }

  static void showWarning({
    required String message,
    Duration? duration,
    VoidCallback? onTap,
    double? width,
    bool floating = false,
    VoidCallback? onVisible,
    BuildContext? context,
  }) {
    show(
      context: context ?? AppNavigator.navigatorKey.currentState!.context,
      message: message,
      type: SnackBarType.warning,
      duration: duration ?? const Duration(seconds: 3),
      onTap: onTap,
      width: width,
      floating: floating,
      onVisible: onVisible,
    );
  }

  static void showInfo({
    required String message,
    Duration? duration,
    VoidCallback? onTap,
    double? width,
    bool floating = false,
    VoidCallback? onVisible,
    BuildContext? context,
  }) {
    show(
      context: context ?? AppNavigator.navigatorKey.currentState!.context,
      message: message,
      type: SnackBarType.info,
      duration: duration ?? const Duration(seconds: 3),
      onTap: onTap,
      width: width,
      floating: floating,
      onVisible: onVisible,
    );
  }

  /// Animated "Added to cart" confirmation (scale + fade).
  static void showAddedToCart({BuildContext? context}) {
    final overlayState = AppNavigator.navigatorKey.currentState?.overlay;
    _removeCurrentOverlay();

    _currentOverlay = OverlayEntry(
      builder: (ctx) => const _AnimatedAddedToCartOverlay(),
    );
    overlayState?.insert(_currentOverlay!);
    Future.delayed(const Duration(milliseconds: 1800), _removeCurrentOverlay);
  }
}

class _AnimatedAddedToCartOverlay extends StatefulWidget {
  const _AnimatedAddedToCartOverlay();

  @override
  State<_AnimatedAddedToCartOverlay> createState() => _AnimatedAddedToCartOverlayState();
}

class _AnimatedAddedToCartOverlayState extends State<_AnimatedAddedToCartOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 100,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacity.value,
              child: Transform.scale(
                scale: _scale.value,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Added to cart',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
