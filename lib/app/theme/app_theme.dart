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
        appBarTheme: AppBarTheme(
          centerTitle: true,
          titleTextStyle: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            shadows: const [
              // Shadow(
              //   color: Colors.black,
              //   offset: Offset(0.35, 0),
              //   blurRadius: 0,
              // ),
            ],
          ),
          
        ),
        fontFamily: GoogleFonts.montserrat().fontFamily,
      );
}  