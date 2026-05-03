import 'dart:math' as math;

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
    bool enableEntranceAnimation = true,
    bool compact = false,
  }) {
    final overlayState = AppNavigator.navigatorKey.currentState?.overlay;
    _removeCurrentOverlay();

    final icon = _icons[type] ?? Icons.notifications_active_outlined;
    final background = _backgroundColors[type] ?? AppColors.primaryColor;
    void dismiss() {
      _removeCurrentOverlay();
      onTap?.call();
    }

    _currentOverlay = OverlayEntry(
      builder: (context) => enableEntranceAnimation
          ? _AnimatedCornerToastOverlay(
              message: message,
              icon: icon,
              background: background,
              duration: duration,
              width: width,
              position: position,
              compact: compact,
              onTap: dismiss,
            )
          : _StaticCornerToastOverlay(
              message: message,
              icon: icon,
              background: background,
              width: width,
              position: position,
              compact: compact,
              onTap: dismiss,
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
    bool enableEntranceAnimation = true,
    bool compact = false,
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
      enableEntranceAnimation: enableEntranceAnimation,
      compact: compact,
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

  /// Kitchen order save — compact bottom pill above cart FAB.
  static void showKotSaved({BuildContext? context}) {
    showSuccess(
      context: context,
      message: 'KOT saved',
      duration: const Duration(milliseconds: 1800),
      floating: true,
      position: SnackBarPosition.bottom,
      compact: true,
    );
  }
}

/// Upper bound for toast width; short messages shrink via [Row] + text constraint (not full-bleed bar).
double _toastMaxWidth(BuildContext context, double? explicitWidth, {required bool compact}) {
  if (explicitWidth != null) return explicitWidth;
  final screenW = MediaQuery.sizeOf(context).width;
  final avail = screenW - _kToastHorizontalInset * 2;
  if (compact) {
    return avail.clamp(120.0, 240.0);
  }
  return avail.clamp(200.0, 340.0);
}

/// Side margins for toasts; scales slightly on very small widths.
const double _kToastHorizontalInset = 16;

/// Reserve space above typical bottom FAB / cart chip (dp).
double _toastBottomClearance(BuildContext context, {required bool compact}) {
  final shortest = MediaQuery.sizeOf(context).shortestSide;
  // Compact toasts sit slightly lower; still clear FAB / safe area.
  if (compact) {
    if (shortest < 600) return 76;
    if (shortest < 900) return 64;
    return 56;
  }
  if (shortest < 600) return 88;
  if (shortest < 900) return 72;
  return 64;
}

/// Below status bar + default toolbar so top toasts avoid app bars.
double _toastTopOffset(BuildContext context) {
  final mq = MediaQuery.of(context);
  return mq.padding.top + kToolbarHeight + 10;
}

/// Same layout as [_AnimatedCornerToastOverlay] but with no entrance animation.
class _StaticCornerToastOverlay extends StatelessWidget {
  const _StaticCornerToastOverlay({
    required this.message,
    required this.icon,
    required this.background,
    required this.position,
    this.width,
    this.compact = false,
    this.onTap,
  });

  final String message;
  final IconData icon;
  final Color background;
  final SnackBarPosition position;
  final double? width;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isTop = position == SnackBarPosition.top;
    final toastMax = _toastMaxWidth(context, width, compact: compact);

    if (isTop) {
      return Positioned(
        left: _kToastHorizontalInset,
        right: _kToastHorizontalInset,
        top: _toastTopOffset(context),
        child: Align(
          alignment: Alignment.topCenter,
          child: _CornerToastPill(
            message: message,
            icon: icon,
            background: background,
            maxWidth: toastMax,
            compact: compact,
            onTap: onTap,
          ),
        ),
      );
    }

    final bottom =
        MediaQuery.viewPaddingOf(context).bottom + _toastBottomClearance(context, compact: compact);
    return Positioned(
      left: _kToastHorizontalInset,
      right: _kToastHorizontalInset,
      bottom: bottom,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: _CornerToastPill(
          message: message,
          icon: icon,
          background: background,
          maxWidth: toastMax,
          compact: compact,
          onTap: onTap,
        ),
      ),
    );
  }
}

class _CornerToastPill extends StatelessWidget {
  const _CornerToastPill({
    required this.message,
    required this.icon,
    required this.background,
    required this.maxWidth,
    this.compact = false,
    this.onTap,
  });

  final String message;
  final IconData icon;
  final Color background;
  final double maxWidth;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final padH = compact ? 10.0 : 14.0;
    final padV = compact ? 6.0 : 11.0;
    final iconOuter = compact ? 22.0 : 28.0;
    final iconInner = compact ? 13.0 : 17.0;
    final gap = compact ? 8.0 : 10.0;
    final radius = compact ? 10.0 : 14.0;
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    final double fontSize = compact
        ? math.min(12.5, 11 + shortest * 0.003)
        : math.min(14.0, 12 + shortest * 0.008);
    final textMaxWidth =
        math.max(40.0, maxWidth - 2 * padH - iconOuter - gap);

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: compact ? 0.14 : 0.18),
                  blurRadius: compact ? 10 : 16,
                  offset: Offset(0, compact ? 4 : 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: iconOuter,
                  height: iconOuter,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: iconInner),
                  ),
                ),
                SizedBox(width: gap),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: textMaxWidth),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: compact ? 1.15 : 1.25),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
    this.compact = false,
    this.onTap,
  });

  final String message;
  final IconData icon;
  final Color background;
  final Duration duration;
  final SnackBarPosition position;
  final double? width;
  final bool compact;
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
    final fromTop = widget.position == SnackBarPosition.top;
    _slide = Tween<Offset>(
      begin: fromTop ? const Offset(0.16, -0.12) : const Offset(0, 0.12),
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
    final toastMax = _toastMaxWidth(context, widget.width, compact: widget.compact);

    Widget animatedPill() {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _opacity.value,
            child: SlideTransition(
              position: _slide,
              child: Transform.scale(
                scale: _scale.value,
                child: _CornerToastPill(
                  message: widget.message,
                  icon: widget.icon,
                  background: widget.background,
                  maxWidth: toastMax,
                  compact: widget.compact,
                  onTap: widget.onTap,
                ),
              ),
            ),
          );
        },
      );
    }

    if (isTop) {
      return Positioned(
        left: _kToastHorizontalInset,
        right: _kToastHorizontalInset,
        top: _toastTopOffset(context),
        child: Align(
          alignment: Alignment.topCenter,
          child: animatedPill(),
        ),
      );
    }

    final bottom =
        MediaQuery.viewPaddingOf(context).bottom + _toastBottomClearance(context, compact: widget.compact);
    return Positioned(
      left: _kToastHorizontalInset,
      right: _kToastHorizontalInset,
      bottom: bottom,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: animatedPill(),
      ),
    );
  }
}
