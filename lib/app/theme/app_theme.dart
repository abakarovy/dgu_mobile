import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          surface: AppColors.surfaceLight,
        ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          titleTextStyle: AppTextStyle.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        fontFamily: 'Inter',
      );
}
