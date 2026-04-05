import 'package:flutter/material.dart';
import 'package:pos/core/constants/colors.dart';

/// Same outer chrome as [CustomTextField]: white fill, 12px radius, 1.5px divider border.
class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.labelText,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
  });

  final String labelText;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          width: 1.5,
          color: theme.dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: DropdownButtonHideUnderline(
          child: DropdownButtonFormField<T>(
            key: ValueKey<String>('${labelText}_${value?.toString() ?? 'null'}'),
            initialValue: value,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: labelText,
              labelStyle: TextStyle(
                color: AppColors.hintFontColor,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              isDense: true,
            ),
            items: items,
            onChanged: enabled ? onChanged : null,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textColor,
              fontWeight: FontWeight.w500,
            ),
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.hintFontColor),
          ),
        ),
      ),
    );
  }
}
