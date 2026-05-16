import 'package:flutter/material.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';

/// Shared input + dropdown styling for financial create popups.
class FinancialFormTheme {
  FinancialFormTheme._();

  static Widget wrap(BuildContext context, Widget child) {
    final base = Theme.of(context);
    final scheme = base.colorScheme.copyWith(
      primary: AppColors.primaryColor,
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: AppColors.textColor,
    );

    return Theme(
      data: base.copyWith(
        colorScheme: scheme,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          labelStyle: AppStyles.getMediumTextStyle(
            fontSize: 13,
            color: AppColors.primaryColor,
          ),
          floatingLabelStyle: AppStyles.getSemiBoldTextStyle(
            fontSize: 13,
            color: AppColors.primaryColor,
          ),
          hintStyle: AppStyles.getRegularTextStyle(
            fontSize: 14,
            color: AppColors.hintFontColor,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.divider.withValues(alpha: 0.95)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primaryColor, width: 1.6),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.red.shade400),
          ),
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          menuStyle: MenuStyle(
            backgroundColor: WidgetStateProperty.all(Colors.white),
            surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
            elevation: WidgetStateProperty.all(6),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          textStyle: AppStyles.getRegularTextStyle(fontSize: 14, color: AppColors.textColor),
        ),
      ),
      child: child,
    );
  }

  static InputDecoration fieldDecoration(String label) => InputDecoration(
        labelText: label,
      );
}
