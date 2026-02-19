import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          surface: AppColors.surfaceLight,
        ),
        appBarTheme: const AppBarTheme(centerTitle: true),
        fontFamily: GoogleFonts.montserrat().fontFamily,
      );
}  