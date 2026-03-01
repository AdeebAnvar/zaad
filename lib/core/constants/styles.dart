import 'dart:math';

import 'package:flutter/material.dart';

import 'colors.dart';

class AppStyles {
  static TextStyle getExtraLightTextStyle({required double fontSize, Color? color, bool isCurrency = false}) {
    return TextStyle(
      fontSize: fontSize,
      fontFamily: 'Poppins',
      color: color ?? AppColors.textColor,
      fontWeight: FontWeight.w200,
    );
  }

  static TextStyle getLightTextStyle({required double fontSize, Color? color, bool isCurrency = false}) {
    return TextStyle(
      fontSize: fontSize,
      fontFamily: 'Poppins',
      color: color ?? AppColors.textColor,
      fontWeight: FontWeight.w300,
    );
  }

  static TextStyle getRegularTextStyle({required double fontSize, Color? color, bool isCurrency = false}) {
    return TextStyle(
      fontSize: fontSize,
      fontFamily: 'Poppins',
      color: color ?? AppColors.textColor,
      fontWeight: FontWeight.w400,
    );
  }

  static TextStyle getBoldTextStyle({required double fontSize, Color? color, bool isCurrency = false}) {
    return TextStyle(
      fontSize: fontSize,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w700,
      color: color ?? AppColors.textColor,
    );
  }

  static TextStyle getSemiBoldTextStyle({required double fontSize, Color? color, bool isCurrency = false}) {
    return TextStyle(
      fontSize: fontSize,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w600,
      color: color ?? AppColors.textColor,
    );
  }

  static TextStyle getMediumTextStyle({required double fontSize, Color? color, bool isCurrency = false}) {
    return TextStyle(
      fontSize: fontSize,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w500,
      color: color ?? AppColors.textColor,
    );
  }

  static ButtonStyle filledButton = TextButton.styleFrom(
      // padding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor: AppColors.primaryColor,
      foregroundColor: Colors.white,
      textStyle: AppStyles.getRegularTextStyle(fontSize: 12, color: Colors.white));
  static ButtonStyle outlinedButton = OutlinedButton.styleFrom(
      padding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      foregroundColor: AppColors.primaryColor,
      textStyle: AppStyles.getRegularTextStyle(fontSize: 12, color: AppColors.textColor),
      side: BorderSide(color: AppColors.textColor));

  static Color getButtonColor(Set<MaterialState> states) {
    if (states.contains(MaterialState.hovered)) {
      return Colors.transparent;
    }
    return AppColors.primaryColor;
  }

  static Color getTextColor(Set<MaterialState> states) {
    if (states.contains(MaterialState.hovered)) {
      return AppColors.primaryColor;
    }
    return Colors.transparent;
  }
}

/// Consistent screen and content padding across the app.
class AppPadding {
  static const double screen = 16;
  static const double screenHorizontal = 16;
  static const double screenVertical = 16;
  static const EdgeInsets screenAll = EdgeInsets.all(16);
  static const EdgeInsets screenSymmetric = EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  static const EdgeInsets content = EdgeInsets.fromLTRB(20, 16, 20, 16);
  static const EdgeInsets card = EdgeInsets.all(16);
}

class ScaleSize {
  static double textScaler(BuildContext context, {double maxTextScaleFactor = 2}) {
    final double width = MediaQuery.of(context).size.width;
    final double val = (width / 1400) * maxTextScaleFactor;
    return max(1, min(val, maxTextScaleFactor));
  }
}

// List of various text styles used within the app
