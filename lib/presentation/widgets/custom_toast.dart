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
    SnackBarPosition position = SnackBarPosition.top,
    VoidCallback? onVisible,
    BuildContext? context,
  }) {
    final overlayState = AppNavigator.navigatorKey.currentState?.overlay;
    _removeCurrentOverlay();

    _currentOverlay = OverlayEntry(
      builder: (context) => _AnimatedCornerToastOverlay(
        message: message,
        icon: _icons[type] ?? Icons.notifications_active_outlined,
        background: _backgroundColors[type] ?? AppColors.primaryColor,
        duration: duration,
        width: width,
        position: position,
        onTap: () {
          _removeCurrentOverlay();
          onTap?.call();
        },
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
    SnackBarPosition position = SnackBarPosition.top,
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
      position: position,
      onVisible: onVisible,
    );
  }

  static void showWarning({
    required String message,
    Duration? duration,
    VoidCallback? onTap,
    double? width,
    bool floating = false,
    SnackBarPosition position = SnackBarPosition.top,
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
      position: position,
      onVisible: onVisible,
    );
  }

  static void showInfo({
    required String message,
    Duration? duration,
    VoidCallback? onTap,
    double? width,
    bool floating = false,
    SnackBarPosition position = SnackBarPosition.top,
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
      position: position,
      onVisible: onVisible,
    );
  }

  /// Animated "Added to cart" confirmation (scale + fade).
  static void showAddedToCart({BuildContext? context}) {
    showSuccess(
      context: context,
      message: 'Added to cart',
      duration: const Duration(milliseconds: 1800),
      floating: true,
      position: SnackBarPosition.top,
    );
  }

  /// Same style as [showAddedToCart], for kitchen order save.
  static void showKotSaved({BuildContext? context}) {
    showSuccess(
      context: context,
      message: 'KOT saved',
      duration: const Duration(milliseconds: 1800),
      floating: true,
      position: SnackBarPosition.top,
    );
  }
}

class _AnimatedCornerToastOverlay extends StatefulWidget {
  const _AnimatedCornerToastOverlay({
    required this.message,
    required this.icon,
    required this.background,
    required this.duration,
    required this.position,
    this.width,
    this.onTap,
  });

  final String message;
  final IconData icon;
  final Color background;
  final Duration duration;
  final SnackBarPosition position;
  final double? width;
  final VoidCallback? onTap;

  @override
  State<_AnimatedCornerToastOverlay> createState() => _AnimatedCornerToastOverlayState();
}

class _AnimatedCornerToastOverlayState extends State<_AnimatedCornerToastOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0.16, -0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.96, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
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
    final isTop = widget.position == SnackBarPosition.top;
    final toastWidth = widget.width ?? (MediaQuery.sizeOf(context).width < 560 ? 300.0 : 340.0);

    return Positioned(
      top: isTop ? 18 : null,
      right: 18,
      bottom: isTop ? null : 18,
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacity.value,
              child: SlideTransition(
                position: _slide,
                child: Transform.scale(
                  scale: _scale.value,
                  child: Material(
                    color: Colors.transparent,
                    child: GestureDetector(
                      onTap: widget.onTap,
                      child: Container(
                        width: toastWidth,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: widget.background,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(widget.icon, color: Colors.white, size: 17),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                widget.message,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
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
            );
          },
        ),
      ),
    );
  }
}
