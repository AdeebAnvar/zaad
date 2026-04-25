import 'package:flutter/material.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/presentation/widgets/custom_button.dart';

/// Material 3 date picker with a clean white surface (no grey/surface tint).
Future<DateTime?> showLogFilterDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    builder: (context, child) {
      final base = Theme.of(context);
      final scheme = base.colorScheme.copyWith(
        surface: Colors.white,
        onSurface: AppColors.textColor,
        primary: AppColors.primaryColor,
        onPrimary: Colors.white,
      );
      return Theme(
        data: base.copyWith(
          colorScheme: scheme,
          dialogTheme: base.dialogTheme.copyWith(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
          ),
          datePickerTheme: DatePickerThemeData(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            headerForegroundColor: AppColors.textColor,
            headerHeadlineStyle: base.textTheme.headlineLarge?.copyWith(color: AppColors.textColor),
            weekdayStyle: base.textTheme.bodySmall?.copyWith(color: AppColors.hintFontColor),
            dayStyle: base.textTheme.bodyLarge?.copyWith(color: AppColors.textColor),
            yearStyle: base.textTheme.titleMedium?.copyWith(color: AppColors.textColor),
            dayForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return Colors.white;
              return AppColors.textColor;
            }),
            todayForegroundColor: WidgetStateProperty.all(AppColors.primaryColor),
            todayBackgroundColor: WidgetStateProperty.all(Colors.transparent),
            rangeSelectionBackgroundColor: AppColors.primaryColor.withValues(alpha: 0.12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        child: child!,
      );
    },
  );
}

/// Panel decoration for order / sales log filter strips: soft depth, no harsh shadow.
BoxDecoration logFilterPanelDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.divider.withValues(alpha: 0.85)),
    boxShadow: [
      BoxShadow(
        color: AppColors.textColor.withValues(alpha: 0.06),
        blurRadius: 24,
        offset: const Offset(0, 8),
        spreadRadius: -4,
      ),
    ],
  );
}

/// Column count and field widths for a responsive filter row.
class LogFilterLayout {
  LogFilterLayout(this.maxWidth) {
    final w = _safeWidth;
    if (w < 480) {
      _cols = 1;
    } else if (w < 720) {
      _cols = 2;
    } else if (w < 900) {
      _cols = 3;
    } else if (w < 1040) {
      _cols = 4;
    } else {
      _cols = 5;
    }
  }

  final double maxWidth;
  late final int _cols;
  double get _safeWidth => maxWidth.isFinite ? maxWidth : 360.0;

  int get columnCount => _cols;

  static const double _gap = 12;

  /// Text fields and similar controls.
  double get fieldWidth {
    if (_cols <= 1) return _safeWidth;
    final w = (_safeWidth - (_cols - 1) * _gap) / _cols;
    return w.clamp(140.0, 260.0);
  }

  /// Date and compact dropdowns: slightly tighter when multiple columns.
  double get compactFieldWidth {
    if (_cols <= 1) return _safeWidth;
    return fieldWidth.clamp(148.0, 210.0);
  }

  bool get stackActions => _safeWidth < 480;

  double get fullWidth => _safeWidth;
}

/// Header + body + optional footer for log filters.
class LogFilterShell extends StatelessWidget {
  const LogFilterShell({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.tune_rounded,
    required this.body,
    this.footer,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget body;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final boundedWidth = c.maxWidth.isFinite ? c.maxWidth : MediaQuery.sizeOf(context).width;
        final desktop = c.maxWidth >= 700;
        final compactDesktop = desktop && boundedWidth < 1100;
        final padH = desktop ? (compactDesktop ? 8.0 : 10.0) : 14.0;
        final padVTop = desktop ? (compactDesktop ? 5.0 : 6.0) : 14.0;
        final padVBottom = desktop ? (compactDesktop ? 6.0 : 8.0) : 14.0;
        final afterHeader = desktop ? (compactDesktop ? 4.0 : 6.0) : 14.0;
        final beforeFooter = desktop ? (compactDesktop ? 4.0 : 6.0) : 14.0;
        final iconBox = desktop ? 7.0 : 10.0;
        final titleSize = desktop ? 14.0 : 16.0;
        final subSize = desktop ? 12.0 : 12.5;
        final showSubtitle = subtitle != null && subtitle!.isNotEmpty && (!compactDesktop || boundedWidth >= 980);
        return Container(
          width: boundedWidth,
          padding: EdgeInsets.fromLTRB(padH, padVTop, padH, padVBottom),
          decoration: logFilterPanelDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: afterHeader),
              body,
              if (footer != null) ...[
                SizedBox(height: beforeFooter),
                Container(
                  padding: EdgeInsets.only(top: desktop ? 6 : 10),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppColors.divider.withValues(alpha: desktop ? 0.65 : 0.75),
                      ),
                    ),
                  ),
                  child: footer!,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Tappable date range control with label + value.
class LogFilterDateTile extends StatelessWidget {
  const LogFilterDateTile({
    super.key,
    required this.hint,
    this.value,
    required this.onTap,
    required this.width,
  });

  final String hint;
  final String? value;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 700;
    final vPad = desktop ? 7.5 : 11.0;
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: vPad),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider.withValues(alpha: 0.7)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColors.primaryColor.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hint,
                        style: AppStyles.getRegularTextStyle(fontSize: 10.5, color: AppColors.hintFontColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value == null || value!.isEmpty ? '—' : value!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppStyles.getMediumTextStyle(
                          fontSize: 13,
                          color: value == null || value!.isEmpty ? AppColors.hintFontColor : AppColors.textColor,
                        ),
                      ),
                    ],
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

class LogFilterActionButtons extends StatelessWidget {
  const LogFilterActionButtons({
    super.key,
    required this.onApply,
    this.onClear,
    this.applyLabel = 'Apply filters',
    this.clearLabel = 'Clear all',
    required this.layout,
  });

  final VoidCallback onApply;
  final VoidCallback? onClear;
  final String applyLabel;
  final String clearLabel;
  final LogFilterLayout layout;

  @override
  Widget build(BuildContext context) {
    if (layout.stackActions) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (onClear != null) ...[
            OutlinedButton(
              onPressed: onClear,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textColor,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                visualDensity: VisualDensity.compact,
                side: BorderSide(color: AppColors.divider.withValues(alpha: 0.9)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(clearLabel, style: AppStyles.getMediumTextStyle(fontSize: 13.5)),
            ),
            const SizedBox(width: 10),
          ],
          CustomButton(
            width: 136,
            onPressed: onApply,
            text: applyLabel,
            elevation: 0,
          ),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (onClear != null) ...[
          OutlinedButton(
            onPressed: onClear,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textColor,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              visualDensity: VisualDensity.compact,
              side: BorderSide(color: AppColors.divider.withValues(alpha: 0.9)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(clearLabel, style: AppStyles.getMediumTextStyle(fontSize: 13.5)),
          ),
          const SizedBox(width: 10),
        ],
        CustomButton(
          width: 136,
          onPressed: onApply,
          text: applyLabel,
          elevation: 0,
        ),
      ],
    );
  }
}
