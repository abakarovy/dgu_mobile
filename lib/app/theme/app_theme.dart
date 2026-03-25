import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

abstract final class AppTheme {
  /// Без ripple/splash на кнопках и интерактивных виджетах по всему приложению.
  static const ButtonStyle _noSplashButtonStyle = ButtonStyle(
    overlayColor: WidgetStatePropertyAll<Color>(Colors.transparent),
    splashFactory: NoSplash.splashFactory,
  );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        splashFactory: NoSplash.splashFactory,
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
        elevatedButtonTheme: const ElevatedButtonThemeData(style: _noSplashButtonStyle),
        filledButtonTheme: const FilledButtonThemeData(style: _noSplashButtonStyle),
        outlinedButtonTheme: const OutlinedButtonThemeData(style: _noSplashButtonStyle),
        textButtonTheme: const TextButtonThemeData(style: _noSplashButtonStyle),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            splashFactory: NoSplash.splashFactory,
            overlayColor: Colors.transparent,
          ),
        ),
        tabBarTheme: const TabBarThemeData(
          overlayColor: WidgetStatePropertyAll<Color>(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
        ),
      );
}
