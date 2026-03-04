import 'package:flutter/material.dart';

/// Локальные стили текста (Inter, Montserrat) без загрузки из интернета.
abstract final class AppTextStyle {
  static TextStyle inter({
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? height,
    Color? color,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      height: height,
      color: color,
      letterSpacing: letterSpacing,
      decoration: decoration,
    );
  }

  static TextStyle montserrat({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    List<Shadow>? shadows,
  }) {
    return TextStyle(
      fontFamily: 'Montserrat',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      shadows: shadows,
    );
  }
}
