import 'package:flutter/material.dart';
import 'package:pos/core/constants/colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color textColor;
  final double borderRadius;
  final EdgeInsets padding;
  final bool isLoading;
  final double? width;
  /// When true, no fixed width — button sizes to [text] (e.g. confirm dialogs). Ignored if [width] is set.
  final bool hugContent;
  /// Set to `0` for flat buttons (e.g. filter sheets — no shadow / M3 tint).
  final double elevation;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor = Colors.white,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.symmetric(vertical: 14),
    this.isLoading = false,
    this.width,
    this.hugContent = false,
    this.elevation = 2,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final effectiveWidth = width ?? (hugContent ? null : screenWidth * 0.9);
    final resolvedPadding = (hugContent && width == null)
        ? EdgeInsets.fromLTRB(22, padding.top, 22, padding.bottom)
        : padding;

    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.primaryColor,
        disabledBackgroundColor: backgroundColor?.withOpacity(0.6) ?? AppColors.primaryColor.withOpacity(0.6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: resolvedPadding,
        tapTargetSize: hugContent ? MaterialTapTargetSize.shrinkWrap : MaterialTapTargetSize.padded,
        elevation: elevation,
        shadowColor: elevation <= 0 ? Colors.transparent : null,
        surfaceTintColor: Colors.transparent,
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              text,
              textAlign: TextAlign.center,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    );

    if (effectiveWidth != null) {
      return SizedBox(width: effectiveWidth, child: button);
    }
    return button;
  }
}
