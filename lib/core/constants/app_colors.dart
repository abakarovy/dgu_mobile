import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primaryBlue = Color(0xFF003882);
  static const Color secondaryBlue = Color(0xFF1A4B8E);

  static const Color lightBlue = Color(0xFF2563EB);
  static const Color backgroundBlue = Color(0xFFEFF6FF);

  static const Color primaryGreen = Color(0xFF059669);
  static const Color backgroundGreen = Color(0xFFECFDF5);
  static const Color lightGreen = Color(0xFF10B981);

  static const Color surfaceLight = Color(0xFFF8FAFC);

  static const Color caption = Color(0xFF94A3B8);
  static const Color grey = Color(0xFF475569);
  static const Color lightGrey = Color(0xFFCBD5E1);
  static const Color backgroundSecondary = (Color(0xFFF1F5F9));

  static const Color onDark = Colors.white;

  static Color onDarkMuted(double opacity) => Colors.white.withValues(alpha: opacity);

  static Color onDarkSurface(double opacity) => Colors.white.withValues(alpha: opacity);
}
