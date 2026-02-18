import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF1A4B8E), surface: Color(0xFFF8FAFC)),
        appBarTheme: const AppBarTheme(centerTitle: true),
        fontFamily: GoogleFonts.montserrat().fontFamily,
      );
}  